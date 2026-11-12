-- ServerScriptService.Systems.ScannerActions
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DoorFunctions = require(ServerScriptService.SharedFunctions.DoorFunctions)

local ScannerActions = {}

-- Helper to resolve target (relative to scanner or absolute path)
local function resolveTarget(scannerModel, targetPath)
	if not targetPath then return nil end

	-- If it starts with a service name, use absolute path
	if targetPath:match("^workspace%.") or targetPath:match("^game%.") then
		-- Use the getObjectFromPath from TerminalActions
		local parts = string.split(targetPath:gsub("^workspace%.", ""), ".")
		local current = workspace
		for _, part in ipairs(parts) do
			current = current:FindFirstChild(part)
			if not current then return nil end
		end
		return current
	end

	-- Otherwise, relative to scanner model
	return scannerModel:FindFirstChild(targetPath)
end

-- Action: Slide Door
function ScannerActions.SlideDoor(config, player, scannerModel)
	local door = resolveTarget(scannerModel, config.targetPath)
	if door then
		DoorFunctions.SlideDoor(door)
	else
		warn("SlideDoor: Could not find door:", config.targetPath)
	end
end

-- Action: Disable Laser Wall
function ScannerActions.DisableLaserWall(config, player, scannerModel)
	local laserWall = resolveTarget(scannerModel, config.targetPath)
	if not laserWall then 
		warn("DisableLaserWall: Could not find laser wall:", config.targetPath)
		return 
	end

	local beamWall = laserWall:FindFirstChild("LaserBeamWall")
	local killBlock = beamWall and beamWall:FindFirstChild("Kill")

	if not beamWall or not killBlock then 
		warn("DisableLaserWall: Missing LaserBeamWall or Kill block")
		return 
	end

	-- Disable lasers
	for _, laserBeam in pairs(beamWall:GetChildren()) do
		if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
			local pp = laserBeam.PrimaryPart
			if pp then
				pp.Beam.Enabled = false
				pp.Part.Transparency = 1
			end
		end
	end
	killBlock.CanTouch = false

	-- Re-enable after duration
	local duration = config.duration or 5
	task.delay(duration, function()
		for _, laserBeam in pairs(beamWall:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				local pp = laserBeam.PrimaryPart
				if pp then
					pp.Beam.Enabled = true
					pp.Part.Transparency = 0.5
				end
			end
		end
		killBlock.CanTouch = true
	end)
end

-- Action: Lock Door
function ScannerActions.LockDoor(config, player, scannerModel)
	local door = resolveTarget(scannerModel, config.targetPath)
	if door then
		door:SetAttribute("Locked", true)
	end
end

-- Action: Alert Security
function ScannerActions.AlertSecurity(config, player, scannerModel)
	print("SECURITY ALERT: Unauthorized scan detected at", scannerModel:GetFullName())
	-- Wire up to your security system
end

-- Action: Trigger Lockdown
function ScannerActions.TriggerLockdown(config, player, scannerModel)
	print("LOCKDOWN TRIGGERED at", scannerModel:GetFullName())
	-- Lock all nearby doors, activate alarms, etc.
end

-- Action: Give Access
function ScannerActions.GiveAccess(config, player, scannerModel)
	local accessFolder = player:FindFirstChild("AccessLevels")
	if not accessFolder then
		accessFolder = Instance.new("Folder")
		accessFolder.Name = "AccessLevels"
		accessFolder.Parent = player
	end

	local accessMarker = Instance.new("BoolValue")
	accessMarker.Name = config.accessLevel or "GenericAccess"
	accessMarker.Value = true
	accessMarker.Parent = accessFolder

	print("Granted access:", config.accessLevel, "to", player.Name)
end

-- Action: Deny Access
function ScannerActions.DenyAccess(config, player, scannerModel)
	print("Access denied for", player.Name, "at", scannerModel:GetFullName())
	-- Could log incident, etc.
end

-- Action: Play Announcement
function ScannerActions.PlayAnnouncement(config, player, scannerModel)
	local soundId = config.soundId
	if not soundId then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = scannerModel
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- Action: Multi Action (execute multiple actions)
function ScannerActions.MultiAction(config, player, scannerModel)
	if not config.actions then return end

	for _, actionConfig in ipairs(config.actions) do
		local actionHandler = ScannerActions[actionConfig.action]
		if actionHandler then
			actionHandler(actionConfig, player, scannerModel)
		else
			warn("MultiAction: Unknown action:", actionConfig.action)
		end
	end
end

return ScannerActions