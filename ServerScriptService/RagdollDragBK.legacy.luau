-- Ragdoll dragging with ProximityPrompt
-- Goal: ragdoll is "frozen" (anchored root) when idle for performance,
-- and when dragged it is pulled BEHIND the player and kept on/near the FLOOR via a ground-raycasted handle.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Drag feel tuning
local DRAG_BACK_DISTANCE = 5          -- studs behind player (positive Z in HRP space)
local DRAG_SIDE_OFFSET   = 1.2        -- to the player's right (looks like holding an arm)
local DRAG_FLOOR_LIFT     = 0.6        -- how high above ground the handle sits
local HANDLE_RAYCAST_UP   = 6          -- raycast start above desired handle position
local HANDLE_RAYCAST_DOWN = 40         -- raycast length downward

local LIMB_RESPONSIVENESS = 25
local LIMB_MAX_FORCE      = 90000

-- optional "keep body low/trailing" (helps stop body from swinging up)
local BODY_FLOOR_ENABLED        = true
local BODY_FLOOR_RESPONSIVENESS = 10
local BODY_FLOOR_MAX_FORCE      = 60000
local BODY_A0_LOCAL_OFFSET      = Vector3.new(0, -2.0, 1.0) -- pull from low + slightly back on Body

-- Utility: choose ragdoll root (anchored when idle)
local function getRootPart(ragdoll: Model): BasePart?
	return ragdoll:FindFirstChild("Body", true) or ragdoll.PrimaryPart
end

-- Utility: choose what limb we "grab"
local function getDragLimbPart(ragdoll: Model): BasePart?
	-- Change these names to match your rig parts.
	-- Preference: hand -> forearm -> upper arm
	return ragdoll:FindFirstChild("RightHand", true)
		or ragdoll:FindFirstChild("Hand_R", true)
		or ragdoll:FindFirstChild("RightLowerArm", true)
		or ragdoll:FindFirstChild("LowerArm_R", true)
		or ragdoll:FindFirstChild("RightArm", true)
		or ragdoll:FindFirstChild("Arm_R", true)
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

-- Create an ANCHORED handle in workspace; we will move it every frame to ground behind player
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
	alignPos.ApplyAtCenterOfMass = false -- IMPORTANT: helps keep it from "lifting" the whole body
	alignPos.RigidityEnabled = false
	alignPos.Parent = part0

	return a0, a1, alignPos
end

local function destroyIfExists(parent: Instance, name: string)
	local obj = parent:FindFirstChild(name)
	if obj then obj:Destroy() end
end

local function startDragging(player: Player, ragdoll: Model)
	if ragdoll:GetAttribute("Dragging") then return end
	ragdoll:SetAttribute("Dragging", true)
	ragdoll:SetAttribute("DragPlayerUserId", player.UserId)

	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local body = getRootPart(ragdoll)
	if not body then return end

	local limb = getDragLimbPart(ragdoll)
	if not limb then
		warn(("Ragdoll %s has no drag limb part (RightHand/RightArm etc.)."):format(ragdoll.Name))
		return
	end

	-- Unfreeze (physics on)
	freezeIdle(ragdoll, false)

	-- zero velocities to reduce pop when waking
	body.AssemblyLinearVelocity = Vector3.zero
	body.AssemblyAngularVelocity = Vector3.zero

	-- Create anchored handle and drive it to ground behind player
	local handle = makeDragHandle()

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, ragdoll }

	local dragConn
	dragConn = RunService.Heartbeat:Connect(function()
		if not hrp.Parent or not ragdoll.Parent or not handle.Parent then
			if dragConn then dragConn:Disconnect() end
			return
		end

		-- Position behind player in HRP space
		local desiredCF = hrp.CFrame * CFrame.new(DRAG_SIDE_OFFSET, 0, DRAG_BACK_DISTANCE)
		local origin = desiredCF.Position + Vector3.new(0, HANDLE_RAYCAST_UP, 0)
		local dir = Vector3.new(0, -HANDLE_RAYCAST_DOWN, 0)

		local hit = workspace:Raycast(origin, dir, rayParams)
		local groundY = hit and hit.Position.Y or (desiredCF.Position.Y - 3)

		-- Place handle on/near ground
		local pos = Vector3.new(desiredCF.Position.X, groundY + DRAG_FLOOR_LIFT, desiredCF.Position.Z)

		-- Keep handle facing player's yaw (prevents "orbiting" weirdness)
		local _, yaw, _ = hrp.CFrame:ToOrientation()
		handle.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	end)

	-- Attach limb to handle
	local limbA0, limbA1, limbAlign = createAlignPosition(limb, handle, "DragLimb", LIMB_MAX_FORCE, LIMB_RESPONSIVENESS)

	-- Optional: keep body low and trailing (helps it scrape instead of swinging)
	local bodyA0, bodyA1, bodyAlign
	if BODY_FLOOR_ENABLED then
		bodyA0, bodyA1, bodyAlign = createAlignPosition(body, handle, "DragBodyFloor", BODY_FLOOR_MAX_FORCE, BODY_FLOOR_RESPONSIVENESS)
		bodyA0.Position = BODY_A0_LOCAL_OFFSET
	end

	-- Store refs on the model for cleanup (safe pattern)
	ragdoll:SetAttribute("DragHandleName", handle.Name)
	ragdoll._dragConn = dragConn
	ragdoll._dragHandle = handle
end

local function stopDragging(player: Player, ragdoll: Model)
	if not ragdoll:GetAttribute("Dragging") then return end
	if ragdoll:GetAttribute("DragPlayerUserId") ~= player.UserId then return end

	ragdoll:SetAttribute("Dragging", false)
	ragdoll:SetAttribute("DragPlayerUserId", nil)

	local body = getRootPart(ragdoll)
	local limb = getDragLimbPart(ragdoll)

	-- Remove align objects from limb/body
	if limb then
		destroyIfExists(limb, "DragLimb_AlignPosition")
		destroyIfExists(limb, "DragLimb_A0")
	end

	if body then
		destroyIfExists(body, "DragBodyFloor_AlignPosition")
		destroyIfExists(body, "DragBodyFloor_A0")
	end

	-- Disconnect heartbeat + destroy handle (also destroys its A1 attachments)
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

-- Hook up all ragdoll prompts
for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") and prompt.Name == "DragRagdollPrompt" then
		local ragdoll = prompt:FindFirstAncestorOfClass("Model")
		if ragdoll then
			-- Freeze after spawn settle
			task.defer(function()
				task.wait(0.1)
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

-- Safety: stop drag if player leaves
Players.PlayerRemoving:Connect(function(player)
	for _, ragdoll in ipairs(workspace:GetChildren()) do
		if ragdoll:IsA("Model") and ragdoll:GetAttribute("DragPlayerUserId") == player.UserId then
			stopDragging(player, ragdoll)
		end
	end
end)
