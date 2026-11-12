-- ShipController_LinearVelocity.lua
-- CLIENT SCRIPT - Uses LinearVelocity constraint for smooth physics
-- Place this in StarterCharacterScripts
-- Requires ShipNetworkManager.lua in ServerScriptService

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== SHIP CONTROLLER LOADING (LinearVelocity) ===")

-- Wait for RemoteEvents
local SetOwnershipEvent = ReplicatedStorage:WaitForChild("SetShipOwnership", 5)
local ResetOwnershipEvent = ReplicatedStorage:WaitForChild("ResetShipOwnership", 5)

if not SetOwnershipEvent or not ResetOwnershipEvent then
	warn("⚠️ NetworkOwnership RemoteEvents not found!")
	warn("   Make sure ShipNetworkManager is in ServerScriptService")
end

-- Configuration
local Config = {
	ShipTag = "Ship",

	-- Flight Physics
	MaxSpeed = 200,
	Acceleration = 50,
	Deceleration = 30,
	BoostMultiplier = 2,

	-- Rotation
	PitchSpeed = 2,
	YawSpeed = 2,
	RollSpeed = 3,
	RotationResponsiveness = 10,  -- Lowered from 20 to reduce jerky rotation

	-- Camera
	ThirdPersonDistance = 25,
	ThirdPersonHeight = 8,
	CockpitOffset = Vector3.new(0, 2, 0),
	LookAroundSpeed = 0.3,
	MaxLookAngle = 80,
}

local Player = Players.LocalPlayer
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

-- State
local CurrentShip = nil
local CurrentSeat = nil
local IsPiloting = false
local ShipData = {} -- Track ships
local OriginalJumpPower = Humanoid.JumpPower

-- Physics Objects (created per ship)
local LinearVelocity = nil
local AlignOrientation = nil

-- Input State
local Input = {
	Forward = 0,
	Right = 0,
	Up = 0,
	Pitch = 0,
	Yaw = 0,
	Roll = 0,
	Boost = false,
	LookX = 0,
	LookY = 0,
}

-- Camera State
local CameraMode = "ThirdPerson"
local LookOffset = CFrame.new()
local CurrentVelocity = Vector3.new(0, 0, 0)
local TargetRotation = CFrame.new()
local MouseDelta = Vector2.new(0, 0)

-- Setup a ship
local function setupShip(ship)
	if ShipData[ship] then return end

	print("========================================")
	print("Setting up ship:", ship.Name)

	-- Wait for PrimaryPart
	local maxWait = 5
	local waited = 0
	while not ship.PrimaryPart and waited < maxWait do
		task.wait(0.1)
		waited = waited + 0.1
	end

	if not ship.PrimaryPart then
		warn("⚠️ Ship missing PrimaryPart:", ship.Name)
		return
	end

	print("✓ Found PrimaryPart:", ship.PrimaryPart.Name)

	-- Find VehicleSeat
	local seat = ship:FindFirstChild("PilotSeat", true) or ship:FindFirstChildOfClass("VehicleSeat", true)

	if not seat then
		warn("⚠️ No VehicleSeat found in ship:", ship.Name)
		return
	end

	print("✓ Found VehicleSeat:", seat.Name)

	-- Disable default vehicle controls
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Disabled = false

	-- Setup ship physics properties
	for _, part in pairs(ship:GetDescendants()) do
		if part:IsA("BasePart") then
			if part == ship.PrimaryPart then
				-- PrimaryPart has mass and physics
				part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
				part.Massless = false
			else
				-- Other parts are massless to ensure rotation around center
				part.Massless = true
			end
		end
	end

	-- Create proximity prompt
	local prompt = ship.PrimaryPart:FindFirstChild("PilotPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PilotPrompt"
		prompt.ActionText = "Enter Cockpit"
		prompt.ObjectText = ship.Name
		prompt.MaxActivationDistance = 10
		prompt.HoldDuration = 0.5
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = ship.PrimaryPart
	end

	-- Connect prompt
	local promptConnection = prompt.Triggered:Connect(function(player)
		if player == Player then
			if not IsPiloting then
				print("Sitting player in seat...")
				seat:Sit(Humanoid)
			else
				-- Exit via standing up
				Humanoid.Sit = false
			end
		end
	end)

	-- Monitor seat occupancy
	local seatConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant and seat.Occupant.Parent == Character then
			enterShip(ship, seat)
		elseif CurrentShip == ship and IsPiloting then
			exitShip()
		end
	end)

	ShipData[ship] = {
		ship = ship,
		seat = seat,
		prompt = prompt,
		connections = {promptConnection, seatConnection}
	}

	print("✓ Ship ready:", ship.Name)
	print("========================================")
end

-- Cleanup ship
local function cleanupShip(ship)
	local data = ShipData[ship]
	if not data then return end

	if CurrentShip == ship then
		exitShip()
	end

	for _, conn in pairs(data.connections) do
		conn:Disconnect()
	end

	ShipData[ship] = nil
end

-- Input handling
local KeyBinds = {
	[Enum.KeyCode.W] = function(pressing) if IsPiloting then Input.Forward = pressing and 1 or 0 end end,
	[Enum.KeyCode.S] = function(pressing) if IsPiloting then Input.Forward = pressing and -1 or 0 end end,
	[Enum.KeyCode.A] = function(pressing) if IsPiloting then Input.Right = pressing and -1 or 0 end end,
	[Enum.KeyCode.D] = function(pressing) if IsPiloting then Input.Right = pressing and 1 or 0 end end,
	[Enum.KeyCode.Q] = function(pressing) if IsPiloting then Input.Roll = pressing and -1 or 0 end end,
	[Enum.KeyCode.E] = function(pressing) if IsPiloting then Input.Roll = pressing and 1 or 0 end end,
	[Enum.KeyCode.Space] = function(pressing) if IsPiloting then Input.Up = pressing and 1 or 0 end end,
	[Enum.KeyCode.LeftControl] = function(pressing) if IsPiloting then Input.Up = pressing and -1 or 0 end end,
	[Enum.KeyCode.LeftShift] = function(pressing) if IsPiloting then Input.Boost = pressing end end,
	[Enum.KeyCode.C] = function(pressing) 
		if pressing and IsPiloting then
			CameraMode = CameraMode == "ThirdPerson" and "Cockpit" or "ThirdPerson"
			if CurrentShip then
				CurrentShip:SetAttribute("CameraMode", CameraMode)
			end
		end
	end,
	[Enum.KeyCode.F] = function(pressing)
		if pressing and IsPiloting then
			-- Manual exit
			Humanoid.Sit = false
		end
	end,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if KeyBinds[input.KeyCode] then
		KeyBinds[input.KeyCode](true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if KeyBinds[input.KeyCode] then
		KeyBinds[input.KeyCode](false)
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if IsPiloting and input.UserInputType == Enum.UserInputType.MouseMovement then
		MouseDelta = Vector2.new(input.Delta.X, input.Delta.Y)
	end
end)

-- Enter ship
function enterShip(ship, seat)
	if IsPiloting then return end

	print("Entering ship:", ship.Name)

	CurrentShip = ship
	CurrentSeat = seat
	IsPiloting = true

	ship:SetAttribute("IsPiloted", true)
	ship:SetAttribute("CameraMode", "ThirdPerson")

	-- Disable jumping while piloting (so Space works for Up)
	OriginalJumpPower = Humanoid.JumpPower
	Humanoid.JumpPower = 0

	-- Request NetworkOwnership from server (server will also handle collision groups)
	if SetOwnershipEvent then
		SetOwnershipEvent:FireServer(ship)
		print("✓ Requested NetworkOwnership from server")
		task.wait(0.15) -- Wait for ownership transfer
	end

	-- CRITICAL: Make character follow ship smoothly by setting its NetworkOwnership
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart then
		pcall(function()
			HumanoidRootPart:SetNetworkOwner(Player)
		end)
	end

	-- Create physics constraints
	-- LinearVelocity for movement
	LinearVelocity = Instance.new("LinearVelocity")
	LinearVelocity.MaxForce = math.huge
	LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	LinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World

	local attachment = ship.PrimaryPart:FindFirstChild("VelocityAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "VelocityAttachment"
		attachment.Parent = ship.PrimaryPart
	end
	LinearVelocity.Attachment0 = attachment
	LinearVelocity.Parent = ship.PrimaryPart

	-- AlignOrientation for rotation
	AlignOrientation = Instance.new("AlignOrientation")
	AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AlignOrientation.MaxTorque = math.huge
	AlignOrientation.Responsiveness = Config.RotationResponsiveness
	AlignOrientation.RigidityEnabled = true  -- CRITICAL: Prevents rotation around a point

	local orientAttachment = ship.PrimaryPart:FindFirstChild("OrientationAttachment")
	if not orientAttachment then
		orientAttachment = Instance.new("Attachment")
		orientAttachment.Name = "OrientationAttachment"
		orientAttachment.WorldPosition = ship.PrimaryPart.Position  -- Center on PrimaryPart
		orientAttachment.Parent = ship.PrimaryPart
	end
	AlignOrientation.Attachment0 = orientAttachment
	AlignOrientation.Parent = ship.PrimaryPart
	AlignOrientation.CFrame = ship.PrimaryPart.CFrame

	TargetRotation = ship.PrimaryPart.CFrame
	CurrentVelocity = Vector3.new(0, 0, 0)

	-- Update prompt
	local data = ShipData[ship]
	if data and data.prompt then
		data.prompt.ActionText = "Exit Cockpit (F)"
	end

	print("✓ Entered ship successfully")
	print("Controls: WASD=Move, Space=Up, LCtrl=Down, Q/E=Roll, F=Exit")
	print("Ship PrimaryPart:", ship.PrimaryPart.Name)
	print("Ship AssemblyRootPart:", ship.PrimaryPart.AssemblyRootPart.Name)
	print("Ship Mass:", ship.PrimaryPart.AssemblyMass)
end

-- Exit ship
function exitShip()
	if not IsPiloting or not CurrentShip then return end

	print("Exiting ship:", CurrentShip.Name)

	local ship = CurrentShip

	IsPiloting = false
	ship:SetAttribute("IsPiloted", false)

	-- Restore jump
	Humanoid.JumpPower = OriginalJumpPower

	-- Remove physics constraints
	if LinearVelocity then
		LinearVelocity:Destroy()
		LinearVelocity = nil
	end
	if AlignOrientation then
		AlignOrientation:Destroy()
		AlignOrientation = nil
	end

	-- Stop ship
	CurrentVelocity = Vector3.new(0, 0, 0)
	ship.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	ship.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

	-- Reset NetworkOwnership
	if ResetOwnershipEvent then
		ResetOwnershipEvent:FireServer(ship)
	end

	-- Anchor ship
	task.wait(0.1)
	ship.PrimaryPart.Anchored = true

	-- Reset camera
	Camera.CameraType = Enum.CameraType.Custom

	-- Update prompt
	local data = ShipData[ship]
	if data and data.prompt then
		data.prompt.ActionText = "Enter Cockpit"
	end

	-- Reset input
	Input = {
		Forward = 0, Right = 0, Up = 0,
		Pitch = 0, Yaw = 0, Roll = 0,
		Boost = false, LookX = 0, LookY = 0,
	}

	CurrentShip = nil
	CurrentSeat = nil

	print("✓ Exited ship successfully")
end

-- Physics update
RunService.RenderStepped:Connect(function(dt)
	if not IsPiloting or not CurrentShip or not CurrentShip.PrimaryPart then return end
	if not LinearVelocity or not AlignOrientation then return end

	-- Handle rotation input from MOUSE - this controls where ship points
	Input.Pitch = -MouseDelta.Y * 0.05
	Input.Yaw = -MouseDelta.X * 0.05  -- REVERSED: negative inverts left/right
	MouseDelta = Vector2.new(0, 0)

	-- Deadzone - ignore tiny inputs that cause drift
	if math.abs(Input.Pitch) < 0.001 then Input.Pitch = 0 end
	if math.abs(Input.Yaw) < 0.001 then Input.Yaw = 0 end

	-- If no rotation input, re-sync TargetRotation to actual ship to prevent drift
	if Input.Pitch == 0 and Input.Yaw == 0 and Input.Roll == 0 then
		-- Gradually sync target to actual orientation to stop drift
		TargetRotation = TargetRotation:Lerp(CurrentShip.PrimaryPart.CFrame, 0.1)
	end

	-- Build rotation changes
	local pitchChange = CFrame.Angles(math.rad(Input.Pitch * Config.PitchSpeed), 0, 0)
	local yawChange = CFrame.Angles(0, math.rad(Input.Yaw * Config.YawSpeed), 0)
	local rollChange = CFrame.Angles(0, 0, math.rad(Input.Roll * Config.RollSpeed))

	-- Apply rotations in ship's local space (yaw, then pitch, then roll)
	TargetRotation = TargetRotation * yawChange * pitchChange * rollChange

	-- Apply rotation to ship via AlignOrientation
	AlignOrientation.CFrame = TargetRotation

	-- Handle movement - ship moves in direction it's facing
	local shipCFrame = CurrentShip.PrimaryPart.CFrame

	-- W/S controls forward/backward in ship's CURRENT direction
	-- A/D controls strafe left/right
	-- Space/LCtrl controls up/down
	local localInput = Vector3.new(Input.Right, Input.Up, -Input.Forward)

	local speedMultiplier = Input.Boost and Config.BoostMultiplier or 1
	local targetVelocity = Vector3.new(0, 0, 0)

	if localInput.Magnitude > 0 then
		-- Use ACTUAL ship orientation (not target) to avoid mismatch
		targetVelocity = (shipCFrame.Rotation * localInput).Unit * Config.MaxSpeed * speedMultiplier
		-- Smoothly accelerate
		CurrentVelocity = CurrentVelocity:Lerp(targetVelocity, Config.Acceleration * dt)
	else
		-- Smoothly decelerate to zero (not instant stop)
		CurrentVelocity = CurrentVelocity:Lerp(Vector3.new(0, 0, 0), Config.Deceleration * dt)
	end

	-- Apply via LinearVelocity constraint
	LinearVelocity.VectorVelocity = CurrentVelocity

	-- Update attributes
	CurrentShip:SetAttribute("Boosting", Input.Boost)
	CurrentShip:SetAttribute("Speed", CurrentVelocity.Magnitude)

	-- Update camera (now follows ship)
	updateCamera(dt)
end)

-- Camera update
function updateCamera(dt)
	if not IsPiloting or not CurrentShip then return end

	Camera.CameraType = Enum.CameraType.Scriptable

	local shipCFrame = CurrentShip.PrimaryPart.CFrame
	local targetCFrame

	if CameraMode == "ThirdPerson" then
		-- Camera should be BEHIND ship (negative Z in local space)
		-- and ABOVE it (positive Y)
		local offset = Vector3.new(0, Config.ThirdPersonHeight, Config.ThirdPersonDistance)

		-- Position camera behind and above ship in ship's local space
		local baseCFrame = shipCFrame * CFrame.new(offset)

		-- Camera looks at ship
		targetCFrame = CFrame.new(baseCFrame.Position, shipCFrame.Position)
		Camera.Focus = shipCFrame

	elseif CameraMode == "Cockpit" then
		local cockpitCFrame = shipCFrame * CFrame.new(Config.CockpitOffset)

		local lookX = math.clamp(Input.LookX, -Config.MaxLookAngle, Config.MaxLookAngle)
		local lookY = math.clamp(Input.LookY, -Config.MaxLookAngle, Config.MaxLookAngle)

		LookOffset = LookOffset:Lerp(CFrame.Angles(math.rad(lookY), math.rad(lookX), 0), 0.3)

		targetCFrame = cockpitCFrame * LookOffset
		Camera.Focus = cockpitCFrame * CFrame.new(0, 0, -10)
	end

	Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.3)
end

-- Look around
local IsLooking = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if IsPiloting and input.UserInputType == Enum.UserInputType.MouseButton2 then
		IsLooking = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		IsLooking = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		task.spawn(function()
			for i = 1, 10 do
				Input.LookX = Input.LookX * 0.8
				Input.LookY = Input.LookY * 0.8
				task.wait(0.02)
			end
			Input.LookX = 0
			Input.LookY = 0
		end)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if IsLooking and IsPiloting then
		Input.LookX = Input.LookX + MouseDelta.X * Config.LookAroundSpeed
		Input.LookY = Input.LookY + MouseDelta.Y * Config.LookAroundSpeed
	end
end)

-- Cleanup on death
Humanoid.Died:Connect(function()
	if IsPiloting then
		exitShip()
	end
end)

-- CollectionService integration
for _, ship in pairs(CollectionService:GetTagged(Config.ShipTag)) do
	setupShip(ship)
end

CollectionService:GetInstanceAddedSignal(Config.ShipTag):Connect(function(ship)
	print("New ship detected:", ship.Name)
	setupShip(ship)
end)

CollectionService:GetInstanceRemovedSignal(Config.ShipTag):Connect(function(ship)
	cleanupShip(ship)
end)

print("=== SHIP CONTROLLER READY (LinearVelocity) ===")
print("Ships detected:", #CollectionService:GetTagged(Config.ShipTag))
print("Create a VehicleSeat named 'PilotSeat' in each ship!")
print("Press F to exit ship")
print("====================================================")
