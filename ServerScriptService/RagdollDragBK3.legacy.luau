-- Custom skinned-mesh ragdoll dragging (Held-by-hand + dragged-on-floor)
-- NO R15 / R6 / Humanoid assumptions.
-- Uses 2 anchored handles:
--   1) HandHandle   -> follows player's custom hand part (looks like holding)
--   2) GroundHandle -> raycasted behind player (keeps body scraping)
-- Stores runtime refs in a Lua table (NOT on the Model).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--------------------------------------------------
-- REQUIRED NAMES (CHANGE THESE TO MATCH YOUR RIGS)
--------------------------------------------------
local PLAYER_HAND_PART_NAME = "righthand"   -- player grab point part name (custom rig)
local PLAYER_FACING_PART_NAME = "Root"      -- part that defines player facing (custom rig). If nil/not found, uses hand.

local RAGDOLL_ROOT_PART_NAME = "Body"       -- ragdoll root part you anchor when idle
local RAGDOLL_LIMB_PART_NAME = "righthand"   -- ragdoll limb part you "hold" (hand/forearm/upperarm part name)

--------------------------------------------------
-- TUNING
--------------------------------------------------
-- Hand handle offsets (relative to facing)
local HAND_BEHIND = 0.35     -- bigger = held point further behind
local HAND_SIDE   = 0     -- bigger = more to the right side
local HAND_DOWN   = 4.0      -- bigger = held point lower (THIS FIXES "hand too high")

-- Also adjust where on the ragdoll limb we "grab" (local to limb part)
local LIMB_GRAB_LOCAL_OFFSET = Vector3.new(0, -0.9, 0)  -- more negative Y = closer to wrist/lower on the part

-- Ground dragging
local GROUND_BACK = 5.0
local GROUND_SIDE = 0.9
local GROUND_LIFT = 0.35

-- Raycast
local RAY_UP   = 6
local RAY_DOWN = 50

-- Forces
local LIMB_FORCE    = 140000
local LIMB_RESPONSE = 70

local BODY_FORCE    = 70000
local BODY_RESPONSE = 10

-- Pull body from a low/trailing point so it scrapes
local BODY_GRAB_LOCAL_OFFSET = Vector3.new(0, -2.0, 1.0)

--------------------------------------------------
-- Runtime state table (keyed by ragdoll model)
--------------------------------------------------
local DragState: {
	[Model]: {
		conn: RBXScriptConnection?,
		handHandle: BasePart?,
		groundHandle: BasePart?,
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

local function freezeIdle(ragdoll: Model, frozen: boolean)
	local root = getRagdollRoot(ragdoll)
	if not root then return end

	root.Anchored = frozen
	if frozen then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
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
	ap.Parent = part0

	return a0, a1, ap
end

local function destroyDragObjects(ragdoll: Model)
	-- Destroys only our created attachments/aligns based on name prefix
	for _, inst in ipairs(ragdoll:GetDescendants()) do
		if inst:IsA("AlignPosition") or inst:IsA("Attachment") then
			local n = inst.Name
			if n:find("^Drag") then
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

	-- Wake ragdoll physics
	freezeIdle(ragdoll, false)
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero

	-- Handles
	local handHandle = makeHandle("RagdollHandHandle")
	local groundHandle = makeHandle("RagdollGroundHandle")

	-- Raycast params (avoid player + ragdoll)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, ragdoll }

	-- Update handles each frame
	local facingPart = getPlayerFacingPart(character, hand)
	local dragConn
	dragConn = RunService.Heartbeat:Connect(function()
		if not (ragdoll.Parent and character.Parent and handHandle.Parent and groundHandle.Parent) then
			if dragConn then dragConn:Disconnect() end
			return
		end

		-- Re-resolve facing part if it disappears/changes
		if not (facingPart and facingPart.Parent) then
			facingPart = getPlayerFacingPart(character, hand)
		end

		local behind = -facingPart.CFrame.LookVector
		local right  = facingPart.CFrame.RightVector
		local _, yaw, _ = facingPart.CFrame:ToOrientation()

		-- 1) Hand handle (held point near player's hand)
		local handPos =
			hand.Position
			+ behind * HAND_BEHIND
			+ right  * HAND_SIDE
			+ Vector3.new(0, -HAND_DOWN, 0)

		handHandle.CFrame = CFrame.new(handPos) * CFrame.Angles(0, yaw, 0)

		-- 2) Ground handle (behind player, clamped to floor)
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
	end)

	-- Limb -> hand (strong)
	local limbA0 = select(1, createAlignPosition(limb, handHandle, "DragLimbToHand", LIMB_FORCE, LIMB_RESPONSE))
	limbA0.Position = LIMB_GRAB_LOCAL_OFFSET

	-- Body -> ground (weaker)
	local bodyA0 = select(1, createAlignPosition(body, groundHandle, "DragBodyToGround", BODY_FORCE, BODY_RESPONSE))
	bodyA0.Position = BODY_GRAB_LOCAL_OFFSET

	-- Save runtime state
	DragState[ragdoll] = {
		conn = dragConn,
		handHandle = handHandle,
		groundHandle = groundHandle,
	}
end

local function stopDragging(player: Player, ragdoll: Model)
	if not ragdoll:GetAttribute("Dragging") then return end
	if ragdoll:GetAttribute("DragPlayerUserId") ~= player.UserId then return end

	ragdoll:SetAttribute("Dragging", false)
	ragdoll:SetAttribute("DragPlayerUserId", nil)

	-- Remove our align/attachments
	destroyDragObjects(ragdoll)

	-- Stop heartbeat + destroy handles
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
		DragState[ragdoll] = nil
	end

	-- Freeze again for performance
	freezeIdle(ragdoll, true)
end

--------------------------------------------------
-- ProximityPrompt hookup
--------------------------------------------------
for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "DragRagdollPrompt" then
		local ragdoll = prompt:FindFirstAncestorOfClass("Model")
		if ragdoll then
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
