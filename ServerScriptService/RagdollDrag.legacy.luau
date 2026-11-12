-- Custom skinned-mesh ragdoll dragging (Held-by-hand + dragged-on-floor)
-- NO R15 / R6 / Humanoid assumptions.
-- Adds:
--   (A) "Back-down" stabilizer: keeps Body +Z pointing toward ground (stays on back)
--   (B) Smooth start: ramp constraints in over a short time + cap velocity to avoid popping

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------
-- REQUIRED NAMES (CHANGE THESE TO MATCH YOUR RIGS)
--------------------------------------------------
local PLAYER_HAND_PART_NAME = "righthand"
local PLAYER_FACING_PART_NAME = "Root"

local RAGDOLL_ROOT_PART_NAME = "Body"
local RAGDOLL_LIMB_PART_NAME = "righthand"

--------------------------------------------------
-- TUNING
--------------------------------------------------
local HAND_BEHIND = -1
local HAND_SIDE   = -2
local HAND_DOWN   = 4.0

local LIMB_GRAB_LOCAL_OFFSET = Vector3.new(0, -0.9, 0)

local GROUND_BACK = 5.0
local GROUND_SIDE = 0.9
local GROUND_LIFT = 0.35

local RAY_UP   = 6
local RAY_DOWN = 50

local LIMB_FORCE_TARGET    = 140000
local LIMB_RESPONSE_TARGET = 70

local BODY_FORCE_TARGET    = 70000
local BODY_RESPONSE_TARGET = 10

local BODY_GRAB_LOCAL_OFFSET = Vector3.new(0, -2.0, 1.0)

local KEEP_BACK_DOWN = true
local BACK_DOWN_TORQUE = 9000
local BACK_DOWN_RESP   = 8
local BACK_DOWN_YAW_FOLLOWS_PLAYER = true

local SMOOTH_START = true
local START_ANCHOR_TIME = 0.15
local RAMP_TIME = 0.35
local MAX_ALIGN_VELOCITY = 40

--------------------------------------------------
-- Runtime state table (keyed by ragdoll model)
--------------------------------------------------
local DragState: {
	[Model]: {
		conn: RBXScriptConnection?,
		handHandle: BasePart?,
		groundHandle: BasePart?,
		backDownHandle: BasePart?,
	}
} = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function findPart(model: Model, name: string): BasePart?
	local inst = model:FindFirstChild(name, true)
	if inst and inst:IsA("BasePart") then
		return inst
	end
	return nil
end

local function getRagdollRoot(ragdoll: Model): BasePart?
	return findPart(ragdoll, RAGDOLL_ROOT_PART_NAME) or ragdoll.PrimaryPart
end

local function getRagdollLimb(ragdoll: Model): BasePart?
	return findPart(ragdoll, RAGDOLL_LIMB_PART_NAME)
end

local function getPlayerHand(character: Model): BasePart?
	return findPart(character, PLAYER_HAND_PART_NAME)
end

local function getPlayerFacingPart(character: Model, hand: BasePart): BasePart
	local facing = PLAYER_FACING_PART_NAME and findPart(character, PLAYER_FACING_PART_NAME)
	return facing or (character.PrimaryPart or hand)
end

-- FIX: anchor/unanchor ALL parts in the ragdoll
local function freezeIdle(ragdoll: Model, frozen: boolean)
	for _, part in ipairs(ragdoll:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = frozen
			if frozen then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

local function makeHandle(name: string): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Anchored = true
	p.Massless = true
	p.Parent = workspace
	return p
end

local function safeSet(inst: Instance, prop: string, value: any)
	pcall(function()
		(inst :: any)[prop] = value
	end)
end

local function createAlignPosition(part0: BasePart, part1: BasePart, name: string, maxForce: number, response: number)
	local a0 = Instance.new("Attachment")
	a0.Name = name .. "_A0"
	a0.Parent = part0

	local a1 = Instance.new("Attachment")
	a1.Name = name .. "_A1"
	a1.Parent = part1

	local ap = Instance.new("AlignPosition")
	ap.Name = name .. "_AlignPosition"
	ap.Attachment0 = a0
	ap.Attachment1 = a1
	ap.MaxForce = maxForce
	ap.Responsiveness = response
	ap.ApplyAtCenterOfMass = false
	ap.RigidityEnabled = false
	safeSet(ap, "MaxVelocity", MAX_ALIGN_VELOCITY)
	ap.Parent = part0

	return a0, a1, ap
end

local function createAlignOrientation(part0: BasePart, target: BasePart, name: string, maxTorque: number, response: number)
	local a0 = Instance.new("Attachment")
	a0.Name = name .. "_A0"
	a0.Parent = part0

	local a1 = Instance.new("Attachment")
	a1.Name = name .. "_A1"
	a1.Parent = target

	local ao = Instance.new("AlignOrientation")
	ao.Name = name .. "_AlignOrientation"
	ao.Attachment0 = a0
	ao.Attachment1 = a1
	ao.MaxTorque = maxTorque
	ao.Responsiveness = response
	ao.RigidityEnabled = false
	safeSet(ao, "ReactionTorqueEnabled", false)
	ao.Parent = part0

	return a0, a1, ao
end

local function destroyDragObjects(ragdoll: Model)
	for _, inst in ipairs(ragdoll:GetDescendants()) do
		if inst:IsA("AlignPosition") or inst:IsA("AlignOrientation") or inst:IsA("Attachment") then
			if inst.Name:find("^Drag") then
				inst:Destroy()
			end
		end
	end
end

--------------------------------------------------
-- Drag start/stop
--------------------------------------------------
local function startDragging(player: Player, ragdoll: Model)
	if ragdoll:GetAttribute("Dragging") then return end
	ragdoll:SetAttribute("Dragging", true)
	ragdoll:SetAttribute("DragPlayerUserId", player.UserId)

	local character = player.Character
	if not character then return end

	local hand = getPlayerHand(character)
	if not hand then
		warn("Player hand part not found: " .. PLAYER_HAND_PART_NAME)
		return
	end

	local body = getRagdollRoot(ragdoll)
	local limb = getRagdollLimb(ragdoll)
	if not (body and limb) then
		warn(("Ragdoll missing parts. Root=%s Limb=%s"):format(tostring(body), tostring(limb)))
		return
	end

	-- FIX: smooth start unanchors ALL parts
	if SMOOTH_START then
		for _, part in ipairs(ragdoll:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.Anchored = true
			end
		end
		task.delay(START_ANCHOR_TIME, function()
			if ragdoll and ragdoll.Parent then
				for _, part in ipairs(ragdoll:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
						part.Anchored = false
					end
				end
			end
		end)
	else
		freezeIdle(ragdoll, false)
	end

	local handHandle = makeHandle("RagdollHandHandle")
	local groundHandle = makeHandle("RagdollGroundHandle")
	local backDownHandle: BasePart? = nil

	if KEEP_BACK_DOWN then
		backDownHandle = makeHandle("RagdollBackDownHandle")
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, ragdoll }

	local facingPart = getPlayerFacingPart(character, hand)

	local limbA0, _, limbAlign = createAlignPosition(limb, handHandle, "DragLimbToHand", 10, 200)
	limbA0.Position = LIMB_GRAB_LOCAL_OFFSET

	local bodyA0, _, bodyAlign = createAlignPosition(body, groundHandle, "DragBodyToGround", 1, 1)
	bodyA0.Position = BODY_GRAB_LOCAL_OFFSET

	local backAO: AlignOrientation? = nil
	if KEEP_BACK_DOWN and backDownHandle then
		_, _, backAO = createAlignOrientation(body, backDownHandle, "DragBackDown", 10, 200)
	end

	local startTime = os.clock()
	local function applyRamp()
		if not SMOOTH_START then
			limbAlign.MaxForce = LIMB_FORCE_TARGET
			limbAlign.Responsiveness = LIMB_RESPONSE_TARGET
			bodyAlign.MaxForce = BODY_FORCE_TARGET
			bodyAlign.Responsiveness = BODY_RESPONSE_TARGET
			if backAO then
				backAO.MaxTorque = BACK_DOWN_TORQUE
				backAO.Responsiveness = BACK_DOWN_RESP
			end
			return
		end

		local t = math.clamp((os.clock() - startTime) / RAMP_TIME, 0, 1)
		t = t * t * (3 - 2 * t)

		limbAlign.MaxForce = LIMB_FORCE_TARGET * t
		limbAlign.Responsiveness = math.max(1, LIMB_RESPONSE_TARGET * t)

		bodyAlign.MaxForce = BODY_FORCE_TARGET * t
		bodyAlign.Responsiveness = math.max(1, BODY_RESPONSE_TARGET * t)

		if backAO then
			backAO.MaxTorque = BACK_DOWN_TORQUE * t
			backAO.Responsiveness = math.max(1, BACK_DOWN_RESP * t)
		end
	end

	local dragConn
	dragConn = RunService.Heartbeat:Connect(function()
		if not (ragdoll.Parent and character.Parent and handHandle.Parent and groundHandle.Parent) then
			if dragConn then dragConn:Disconnect() end
			return
		end

		applyRamp()

		if not (facingPart and facingPart.Parent) then
			facingPart = getPlayerFacingPart(character, hand)
		end

		local behind = -facingPart.CFrame.LookVector
		local right  = facingPart.CFrame.RightVector
		local _, yaw, _ = facingPart.CFrame:ToOrientation()

		local handPos =
			hand.Position
			+ behind * HAND_BEHIND
			+ right  * HAND_SIDE
			+ Vector3.new(0, -HAND_DOWN, 0)

		handHandle.CFrame = CFrame.new(handPos) * CFrame.Angles(0, yaw, 0)

		local base =
			facingPart.Position
			+ behind * GROUND_BACK
			+ right  * GROUND_SIDE

		local hit = workspace:Raycast(
			base + Vector3.new(0, RAY_UP, 0),
			Vector3.new(0, -RAY_DOWN, 0),
			rayParams
		)

		local groundY = hit and hit.Position.Y or (base.Y - 3)
		groundHandle.CFrame =
			CFrame.new(base.X, groundY + GROUND_LIFT, base.Z) * CFrame.Angles(0, yaw, 0)

		if KEEP_BACK_DOWN and backDownHandle then
			local pos = body.Position
			local forwardDown = Vector3.new(0, -1, 0)
			local yawRight = CFrame.Angles(0, yaw, 0).RightVector
			local rightDir = yawRight.Unit
			local upDir = rightDir:Cross(forwardDown).Unit
			rightDir = forwardDown:Cross(upDir).Unit

			local cf = CFrame.fromMatrix(pos, rightDir, upDir, -forwardDown)
			backDownHandle.CFrame = cf
		end
	end)

	DragState[ragdoll] = {
		conn = dragConn,
		handHandle = handHandle,
		groundHandle = groundHandle,
		backDownHandle = backDownHandle,
	}
end

local function stopDragging(player: Player, ragdoll: Model)
	if not ragdoll:GetAttribute("Dragging") then return end
	if ragdoll:GetAttribute("DragPlayerUserId") ~= player.UserId then return end

	ragdoll:SetAttribute("Dragging", false)
	ragdoll:SetAttribute("DragPlayerUserId", nil)

	destroyDragObjects(ragdoll)

	local state = DragState[ragdoll]
	if state then
		if state.conn then
			state.conn:Disconnect()
			state.conn = nil
		end
		if state.handHandle then
			state.handHandle:Destroy()
			state.handHandle = nil
		end
		if state.groundHandle then
			state.groundHandle:Destroy()
			state.groundHandle = nil
		end
		if state.backDownHandle then
			state.backDownHandle:Destroy()
			state.backDownHandle = nil
		end
		DragState[ragdoll] = nil
	end

	-- FIX: freeze ALL parts on stop
	freezeIdle(ragdoll, true)
end

--------------------------------------------------
-- ProximityPrompt hookup
--------------------------------------------------
for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "DragRagdollPrompt" then
		local ragdoll = prompt:FindFirstAncestorOfClass("Model")
		if ragdoll then
			-- FIX: freeze all parts on initial load
			task.delay(4, function()
				freezeIdle(ragdoll, true)
			end)

			prompt.Triggered:Connect(function(player)
				if ragdoll:GetAttribute("Dragging") then
					stopDragging(player, ragdoll)
				else
					startDragging(player, ragdoll)
				end
			end)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	for ragdoll, _ in pairs(DragState) do
		if ragdoll and ragdoll.Parent and ragdoll:GetAttribute("DragPlayerUserId") == player.UserId then
			stopDragging(player, ragdoll)
		end
	end
end)