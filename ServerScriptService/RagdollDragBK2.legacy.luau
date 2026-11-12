-- Ragdoll dragging with ProximityPrompt (Option A: hand-driven handle)
-- - Idle: anchor ragdoll root ("Body") for performance
-- - Dragging: create an ANCHORED handle in workspace
--   and update it every Heartbeat to be near the PLAYER'S HAND, but clamped to the FLOOR via raycast.
-- - Pull the ragdoll by aligning the ragdoll limb (hand/arm) to that handle.
-- - Optional: add a weak "keep body low/trailing" pull so the body scrapes instead of swinging up.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Feel tuning
local DRAG_BACK_DISTANCE = 1.5        -- how far behind the player's hand (along -LookVector)
local DRAG_SIDE_OFFSET   = 0.6        -- sideways offset from hand (along RightVector)
local DRAG_FLOOR_LIFT    = 0.1        -- how high above ground the handle sits

local HANDLE_RAYCAST_UP   = 6
local HANDLE_RAYCAST_DOWN = 40

local LIMB_RESPONSIVENESS = 100
local LIMB_MAX_FORCE      = 90000

-- Optional body "floor/trail" pull
local BODY_FLOOR_ENABLED        = true
local BODY_FLOOR_RESPONSIVENESS = 10
local BODY_FLOOR_MAX_FORCE      = 60000
local BODY_A0_LOCAL_OFFSET      = Vector3.new(0, -2.0, 1.0) -- pull from low + slightly back on Body

-- ---------- Helpers ----------

local function getRootPart(ragdoll: Model): BasePart?
	return ragdoll:FindFirstChild("Body", true) or ragdoll.PrimaryPart
end

-- Pick which ragdoll limb you "grab"
local function getDragLimbPart(ragdoll: Model): BasePart?
	-- Update these to match your ragdoll part names.
	return ragdoll:FindFirstChild("rightleg", true)
		--or ragdoll:FindFirstChild("Hand_R", true)
		--or ragdoll:FindFirstChild("RightLowerArm", true)
		--or ragdoll:FindFirstChild("LowerArm_R", true)
		--or ragdoll:FindFirstChild("RightArm", true)
		--or ragdoll:FindFirstChild("Arm_R", true)
end

-- Get player's right-hand-ish part
local function getPlayerHandPart(character: Model): BasePart?
	-- R15
	local rh = character:FindFirstChild("RightHand")
	if rh and rh:IsA("BasePart") then return rh end

	-- R6 fallback
	local r6 = character:FindFirstChild("Right Arm")
	if r6 and r6:IsA("BasePart") then return r6 end

	-- last resort
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end

	return nil
end

local function freezeIdle(ragdoll: Model, frozen: boolean)
	local root = getRootPart(ragdoll)
	if not root then return end

	root.Anchored = frozen
	if frozen then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

local function makeDragHandle(): BasePart
	local handle = Instance.new("Part")
	handle.Name = "RagdollDragHandle"
	handle.Size = Vector3.new(0.5, 0.5, 0.5)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Anchored = true
	handle.Massless = true
	handle.Parent = workspace
	return handle
end

local function createAlignPosition(part0: BasePart, part1: BasePart, namePrefix: string, maxForce: number, responsiveness: number)
	local a0 = Instance.new("Attachment")
	a0.Name = namePrefix .. "_A0"
	a0.Parent = part0

	local a1 = Instance.new("Attachment")
	a1.Name = namePrefix .. "_A1"
	a1.Parent = part1

	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = namePrefix .. "_AlignPosition"
	alignPos.Attachment0 = a0
	alignPos.Attachment1 = a1
	alignPos.Responsiveness = responsiveness
	alignPos.MaxForce = maxForce
	alignPos.ApplyAtCenterOfMass = false -- IMPORTANT for "dragging" feel
	alignPos.RigidityEnabled = false
	alignPos.Parent = part0

	return a0, a1, alignPos
end

local function destroyIfExists(parent: Instance, name: string)
	local obj = parent:FindFirstChild(name)
	if obj then obj:Destroy() end
end

-- ---------- Drag logic ----------

local function startDragging(player: Player, ragdoll: Model)
	if ragdoll:GetAttribute("Dragging") then return end
	ragdoll:SetAttribute("Dragging", true)
	ragdoll:SetAttribute("DragPlayerUserId", player.UserId)

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not (hrp and hrp:IsA("BasePart")) then return end

	local handPart = getPlayerHandPart(character)
	if not handPart then return end

	local body = getRootPart(ragdoll)
	if not body then return end

	local limb = getDragLimbPart(ragdoll)
	if not limb then
		warn(("Ragdoll %s has no drag limb part (RightHand/RightArm etc.)."):format(ragdoll.Name))
		return
	end

	-- Unfreeze ragdoll for physics
	freezeIdle(ragdoll, false)

	-- Reduce pop on wake
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero

	local handle = makeDragHandle()

	-- Raycast params (avoid hitting player + ragdoll)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, ragdoll }

	-- Update handle each frame to be near HAND but clamped to ground
	local dragConn
	dragConn = RunService.Heartbeat:Connect(function()
		if not (ragdoll.Parent and character.Parent and handle.Parent) then
			if dragConn then dragConn:Disconnect() end
			return
		end

		-- Base direction from player's facing
		local behindDir = -hrp.CFrame.LookVector
		local rightDir = hrp.CFrame.RightVector

		-- Start from the player's hand position
		local basePos = handPart.Position
			+ behindDir * DRAG_BACK_DISTANCE
			+ rightDir * DRAG_SIDE_OFFSET

		-- Raycast down to find ground
		local origin = basePos + Vector3.new(0, HANDLE_RAYCAST_UP, 0)
		local dir = Vector3.new(0, -HANDLE_RAYCAST_DOWN, 0)
		local hit = workspace:Raycast(origin, dir, rayParams)

		local groundY = hit and hit.Position.Y or (basePos.Y - 3)
		local finalPos = Vector3.new(basePos.X, groundY + DRAG_FLOOR_LIFT, basePos.Z)

		-- Keep yaw aligned with player so "behind" stays consistent
		local _, yaw, _ = hrp.CFrame:ToOrientation()
		handle.CFrame = CFrame.new(finalPos) * CFrame.Angles(0, yaw, 0)
	end)

	-- Pull the ragdoll's grabbed limb to the handle
	local limbA0, limbA1, limbAlign = createAlignPosition(limb, handle, "DragLimb", LIMB_MAX_FORCE, LIMB_RESPONSIVENESS)

	-- Optional: keep body low/trailing so it scrapes
	if BODY_FLOOR_ENABLED then
		local bodyA0, bodyA1, bodyAlign = createAlignPosition(body, handle, "DragBodyFloor", BODY_FLOOR_MAX_FORCE, BODY_FLOOR_RESPONSIVENESS)
		bodyA0.Position = BODY_A0_LOCAL_OFFSET
	end

	-- Store for cleanup
	ragdoll._dragConn = dragConn
	ragdoll._dragHandle = handle
	ragdoll:SetAttribute("DragHandleName", handle.Name)
end

local function stopDragging(player: Player, ragdoll: Model)
	if not ragdoll:GetAttribute("Dragging") then return end
	if ragdoll:GetAttribute("DragPlayerUserId") ~= player.UserId then return end

	ragdoll:SetAttribute("Dragging", false)
	ragdoll:SetAttribute("DragPlayerUserId", nil)

	local body = getRootPart(ragdoll)
	local limb = getDragLimbPart(ragdoll)

	-- Remove align objects
	if limb then
		destroyIfExists(limb, "DragLimb_AlignPosition")
		destroyIfExists(limb, "DragLimb_A0")
	end

	if body then
		destroyIfExists(body, "DragBodyFloor_AlignPosition")
		destroyIfExists(body, "DragBodyFloor_A0")
	end

	-- Disconnect + destroy handle
	if ragdoll._dragConn then
		ragdoll._dragConn:Disconnect()
		ragdoll._dragConn = nil
	end
	if ragdoll._dragHandle then
		ragdoll._dragHandle:Destroy()
		ragdoll._dragHandle = nil
	end

	-- Freeze again for performance
	freezeIdle(ragdoll, true)
end

-- ---------- ProximityPrompt hookup ----------

for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "DragRagdollPrompt" then
		local ragdoll = prompt:FindFirstAncestorOfClass("Model")
		if ragdoll then
			task.defer(function()
				task.wait(4)
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
	for _, ragdoll in ipairs(workspace:GetChildren()) do
		if ragdoll:IsA("Model") and ragdoll:GetAttribute("DragPlayerUserId") == player.UserId then
			stopDragging(player, ragdoll)
		end
	end
end)
