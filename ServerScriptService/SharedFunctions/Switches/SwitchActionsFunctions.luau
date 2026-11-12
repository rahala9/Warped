-- ServerScriptService.SharedFunctions.Switches.SwitchActionsFunctions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local PowerService = require(ServerScriptService.SharedServices.PowerService)

local DoorFunctions = require(ServerScriptService.SharedFunctions.DoorFunctions)
local NPCRemoteControlFunctions = require(ServerScriptService.SharedFunctions.NPCRemoteControlFunctions)

local SwitchActions = {}
local SwitchRuntime = {}

local function getObjectFromPath(path)
	local parts = string.split(path, ".")
	local current

	local firstPart = parts[1]
	if firstPart == "game" then
		current = game
		table.remove(parts, 1)
	elseif firstPart == "workspace" then
		current = workspace
		table.remove(parts, 1)
	elseif firstPart == "ReplicatedStorage" then
		current = ReplicatedStorage
		table.remove(parts, 1)
	elseif firstPart == "ServerScriptService" then
		current = ServerScriptService
		table.remove(parts, 1)
	else
		current = workspace
	end

	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			warn("Could not find '" .. part .. "' in path:", path)
			return nil
		end
	end

	return current
end

local function getOrInitLeverState(config)
	local switchId = config.id or config.target or config.switchHandlePath
	local cached = SwitchRuntime[switchId]
	if cached then return cached end

	local leverHandle = getObjectFromPath(config.switchHandlePath)
	if not leverHandle then return nil end

	local leverHandleHinge = leverHandle.Parent:FindFirstChild("Hinge")
	if not leverHandleHinge then
		warn("Could not find Hinge next to lever handle:", config.switchHandlePath)
		return nil
	end

	local closedCFrame = leverHandleHinge.CFrame
	local openCFrame = closedCFrame * CFrame.Angles(math.rad(-180), 0, 0)

	cached = {
		Hinge = leverHandleHinge,
		ClosedCFrame = closedCFrame,
		OpenCFrame = openCFrame,
		IsTweening = false,
		CurrentTween = nil,
	}

	SwitchRuntime[switchId] = cached
	return cached
end

local function getClosestFloorIndexFromY(currentY, floors)
	local closestIndex = 1
	local closestDist = math.huge

	for i, floorPos in ipairs(floors) do
		local dist = math.abs(currentY - floorPos.Y)
		if dist < closestDist then
			closestDist = dist
			closestIndex = i
		end
	end

	return closestIndex
end

local function getPlatformModel(config)
	local target = getObjectFromPath(config.targetPath)
	if not target then
		warn("Could not find platform at path:", config.targetPath)
		return nil, nil
	end

	if target:IsA("Model") then
		return target, target.PrimaryPart
	end

	if target:IsA("BasePart") then
		local model = target:FindFirstAncestorOfClass("Model")
		return model, target
	end

	warn("Platform target is not a Model or BasePart:", config.targetPath)
	return nil, nil
end

local function getRootPart(model, fallbackPart)
	if model and model.PrimaryPart then
		return model.PrimaryPart
	end

	if fallbackPart and fallbackPart:IsA("BasePart") then
		if model then
			model.PrimaryPart = fallbackPart
		end
		return fallbackPart
	end

	if model then
		local part = model:FindFirstChildWhichIsA("BasePart", true)
		if part then
			model.PrimaryPart = part
			return part
		end
	end

	return nil
end

local function getOrInitPlatformState(config, platformModel)
	local key = config.targetPath
	local cached = SwitchRuntime[key]
	if cached then return cached end

	local currentY = platformModel:GetPivot().Position.Y

	cached = {
		CurrentFloor = getClosestFloorIndexFromY(currentY, config.floors),
		IsTweening = false,
		CurrentTween = nil,
	}

	SwitchRuntime[key] = cached
	return cached
end

local function tweenModelToY(model, targetY, moveTime)
	local startPivot = model:GetPivot()
	local startY = startPivot.Position.Y
	local targetPivot = startPivot + Vector3.new(0, targetY - startY, 0)

	local cfValue = Instance.new("CFrameValue")
	cfValue.Value = startPivot

	local connection = cfValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(cfValue.Value)
	end)

	local tween = TweenService:Create(cfValue, TweenInfo.new(
		moveTime,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
		), {
			Value = targetPivot
		})

	tween.Completed:Once(function()
		connection:Disconnect()
		cfValue:Destroy()
		model:PivotTo(targetPivot)
	end)

	tween:Play()
	return tween
end

local function preparePhysicsElevator(model, rootPart, config)
	-- Unanchor every part inside the elevator model.
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = false
		end
	end

	-- Warn if the moving elevator is accidentally welded to anchored world parts.
	for _, connectedPart in ipairs(rootPart:GetConnectedParts(true)) do
		if connectedPart.Anchored then
			warn("Elevator is connected to anchored part:", connectedPart:GetFullName())
		end
	end

	-- Set server ownership only on the root assembly part, safely.
	if not rootPart.Anchored then
		local ok, err = pcall(function()
			rootPart:SetNetworkOwner(nil)
		end)

		if not ok then
			warn("Could not set elevator network owner:", err)
		end
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local attachment = rootPart:FindFirstChild("ElevatorPhysicsAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "ElevatorPhysicsAttachment"
		attachment.Parent = rootPart
	end

	local alignPosition = rootPart:FindFirstChild("ElevatorAlignPosition")
	if not alignPosition then
		alignPosition = Instance.new("AlignPosition")
		alignPosition.Name = "ElevatorAlignPosition"
		alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPosition.Attachment0 = attachment
		alignPosition.ApplyAtCenterOfMass = true
		alignPosition.RigidityEnabled = false
		alignPosition.Parent = rootPart
	end

	alignPosition.Enabled = true
	alignPosition.MaxForce = config.maxForce or 100000000
	alignPosition.MaxVelocity = config.maxVelocity or config.speed or 12
	alignPosition.Responsiveness = config.responsiveness or 25

	local alignOrientation = rootPart:FindFirstChild("ElevatorAlignOrientation")
	if not alignOrientation then
		alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.Name = "ElevatorAlignOrientation"
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.Attachment0 = attachment
		alignOrientation.RigidityEnabled = false
		alignOrientation.Parent = rootPart
	end

	alignOrientation.Enabled = true
	alignOrientation.MaxTorque = config.maxTorque or 100000000
	alignOrientation.Responsiveness = config.orientationResponsiveness or 25
	alignOrientation.CFrame = rootPart.CFrame.Rotation

	return alignPosition, alignOrientation
end

local function physicsMoveModelToY(model, rootPart, targetY, config, onFinished)
	local alignPosition, alignOrientation = preparePhysicsElevator(model, rootPart, config)

	local currentPos = rootPart.Position
	local targetPosition = Vector3.new(currentPos.X, targetY, currentPos.Z)

	alignPosition.Position = targetPosition
	alignOrientation.CFrame = rootPart.CFrame.Rotation

	local tolerance = config.arrivalTolerance or 0.08
	local timeout = config.timeout or 12
	local startTime = os.clock()

	task.spawn(function()
		while true do
			local distance = (rootPart.Position - targetPosition).Magnitude
			local speed = rootPart.AssemblyLinearVelocity.Magnitude

			if distance <= tolerance and speed <= 0.35 then
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				alignPosition.Position = targetPosition
				break
			end

			if os.clock() - startTime > timeout then
				warn("Physics elevator timed out:", model:GetFullName())
				break
			end

			RunService.Heartbeat:Wait()
		end

		if onFinished then
			onFinished()
		end
	end)
end

local function movePlatform(config, direction)
	if not config.floors or #config.floors == 0 then
		warn("No floors configured for platform:", config.targetPath)
		return
	end

	local platformModel, targetPart = getPlatformModel(config)
	if not platformModel then return end

	local rootPart = getRootPart(platformModel, targetPart)
	if not rootPart then
		warn("No root part found for platform:", config.targetPath)
		return
	end

	local state = getOrInitPlatformState(config, platformModel)
	if state.IsTweening then return end

	local currentY = rootPart.Position.Y
	state.CurrentFloor = getClosestFloorIndexFromY(currentY, config.floors)

	local nextFloor = math.clamp(state.CurrentFloor + direction, 1, #config.floors)
	if nextFloor == state.CurrentFloor then return end

	local targetY = config.floors[nextFloor].Y
	local distance = math.abs(currentY - targetY)
	local speed = config.speed or 12
	local moveTime = config.moveTime or math.max(distance / speed, 0.25)

	state.IsTweening = true
	state.CurrentFloor = nextFloor

	local movementMode = config.movementMode or "Physics"

	if movementMode == "Tween" then
		local tween = tweenModelToY(platformModel, targetY, moveTime)
		state.CurrentTween = tween

		tween.Completed:Once(function()
			if state.CurrentTween == tween then
				state.CurrentTween = nil
			end
			state.IsTweening = false
		end)
	else
		physicsMoveModelToY(platformModel, rootPart, targetY, config, function()
			state.CurrentTween = nil
			state.IsTweening = false
		end)
	end
end

local function playTargetSound(obj, soundName)

	local sound = obj.PrimaryPart:FindFirstChild(soundName)
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

function SwitchActions.ToggleLaserTrap(config, player)
	local laserTrap = getObjectFromPath(config.targetPath)
	if not laserTrap then
		warn("Could not find laser trap at path:", config.targetPath)
		return
	end

	local killBlock = laserTrap:FindFirstChild("KillZone" .. config.target)
	if not killBlock then return end

	local leverState = nil
	if config.switchType == "TwoPositionLever" then
		leverState = getOrInitLeverState(config)
		if not leverState or leverState.IsTweening then return end
	end

	

	local enabled = laserTrap:GetAttribute("Enabled")

	if enabled then
		laserTrap:SetAttribute("Enabled", false)

		playTargetSound(laserTrap, "TargetDisabledSound")

		for _, laserBeam in pairs(laserTrap:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				laserBeam.PrimaryPart.Beam.Enabled = false
				laserBeam.PrimaryPart.Part.Transparency = 1
			end
		end

		if leverState then
			leverState.IsTweening = true

			local tween = TweenService:Create(
				leverState.Hinge,
				TweenInfo.new(0.4),
				{ CFrame = leverState.OpenCFrame }
			)

			leverState.CurrentTween = tween
			tween:Play()

			tween.Completed:Once(function()
				leverState.IsTweening = false
				if leverState.CurrentTween == tween then
					leverState.CurrentTween = nil
				end
			end)
		end
	else
		laserTrap:SetAttribute("Enabled", true)

		playTargetSound(laserTrap, "TargetEnabledSound")

		for _, laserBeam in pairs(laserTrap:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				laserBeam.PrimaryPart.Beam.Enabled = true
				laserBeam.PrimaryPart.Part.Transparency = 0.5
			end
		end

		if leverState then
			leverState.IsTweening = true

			local tween = TweenService:Create(
				leverState.Hinge,
				TweenInfo.new(0.4),
				{ CFrame = leverState.ClosedCFrame }
			)

			leverState.CurrentTween = tween
			tween:Play()

			tween.Completed:Once(function()
				leverState.IsTweening = false
				if leverState.CurrentTween == tween then
					leverState.CurrentTween = nil
				end
			end)
		end
	end
end

function SwitchActions.PlatformUp(config, player)
	movePlatform(config, 1)
end

function SwitchActions.PlatformDown(config, player)
	movePlatform(config, -1)
end

function SwitchActions.PowerCoreOn(config, player)
	movePlatform(config, -1)

	local powerCore = getObjectFromPath(config.targetPath)
	local switchOn = getObjectFromPath(config.switchOnPath)
	local switchOff = getObjectFromPath(config.switchOffPath)

	if not powerCore or not switchOn or not switchOff then
		warn("PowerCoreOn missing object")
		return
	end

	switchOn.Enabled = false
	switchOff.Enabled = false
	
	print("TEST POWER CORE PowerCoreOn switchOn and switchOff Enabled = false")

	task.defer(function()
		switchOff.Enabled = true
		print("TEST POWER CORE PowerCoreOn switchOff Enabled = true")
	end)

	--powerCore:SetAttribute("Enabled", true)
	PowerService.SetCoreEnabled(config.powerCoreId, true)
end

function SwitchActions.PowerCoreOff(config, player)
	movePlatform(config, 1)

	local powerCore = getObjectFromPath(config.targetPath)
	local switchOn = getObjectFromPath(config.switchOnPath)
	local switchOff = getObjectFromPath(config.switchOffPath)

	if not powerCore or not switchOn or not switchOff then
		warn("PowerCoreOff missing object")
		return
	end

	switchOn.Enabled = false
	switchOff.Enabled = false
	
	print("TEST POWER CORE PowerCoreOff switchOn and switchOff Enabled = false")

	task.defer(function()
		switchOn.Enabled = true
		print("TEST POWER CORE PowerCoreOff switchOn Enabled = true")
	end)

	--powerCore:SetAttribute("Enabled", false)
	PowerService.SetCoreEnabled(config.powerCoreId, false)
end

function SwitchActions.StartQuest(config, player)
	print("Started quest for player:", player.Name, config.questId)
end

return SwitchActions