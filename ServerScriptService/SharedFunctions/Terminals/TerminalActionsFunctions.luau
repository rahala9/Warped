-- ServerScriptService.Systems.TerminalActions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DoorFunctions = require(ServerScriptService.SharedFunctions.DoorFunctions)
local TeleporterFunctions = require(ServerScriptService.SharedFunctions.TeleporterFunctions)
local NPCRemoteControlFunctions = require(ServerScriptService.SharedFunctions.NPCRemoteControlFunctions)

local TerminalActions = {}

-- Helper function to get object from path
local function getObjectFromPath(path)
	local parts = string.split(path, ".")
	local current

	-- Handle the first part specially (could be game, workspace, ReplicatedStorage, etc.)
	local firstPart = parts[1]
	if firstPart == "game" then
		current = game
		table.remove(parts, 1) -- Remove "game" from the path
	elseif firstPart == "workspace" then
		current = workspace
		table.remove(parts, 1) -- Remove "workspace" from the path
	elseif firstPart == "ReplicatedStorage" then
		current = game:GetService("ReplicatedStorage")
		table.remove(parts, 1)
	elseif firstPart == "ServerScriptService" then
		current = game:GetService("ServerScriptService")
		table.remove(parts, 1)
	else
		-- If no service specified, assume it's starting from workspace
		current = workspace
	end

	-- Navigate through the remaining parts
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then 
			warn("Could not find '" .. part .. "' in path:", path)
			return nil 
		end
	end

	return current
end

function TerminalActions.ToggleSlidingDoor(config, player)
	local slidingDoor = getObjectFromPath(config.targetPath)
	if not slidingDoor then 
		warn("Could not find sliding door at path:", config.targetPath)
		return 
	end
	
	DoorFunctions.SlideDoor(slidingDoor)
end

function TerminalActions.OpenTeleporterControls(config, player)

	TeleporterFunctions.OpenTeleporter(player, config.onSuccess.targetPath, config.locations)
end

function TerminalActions.OpenHackedTeleporterControls(configonSuccess, player)
	TeleporterFunctions.OpenTeleporter(player, configonSuccess.targetPath, configonSuccess.hackedLocations)
end

function TerminalActions.TakeControlRobot(config, player)
	
	local npc = getObjectFromPath(config.targetPath)
	
	if npc:GetAttribute("RemoteControlled") then
		warn(("[NPCControlPrompt] %s already being controlled"):format(npc.Name))
		return
	end
	
	NPCRemoteControlFunctions.grantControl(player,npc)
end


-- Action: Toggle Laser Door
function TerminalActions.ToggleLaserDoor(config, player)
	local laserDoor = getObjectFromPath(config.targetPath)
	if not laserDoor then 
		warn("Could not find laser door at path:", config.targetPath)
		return 
	end

	local laserBeamWall = laserDoor:FindFirstChild("LaserBeamWall")

	if not laserBeamWall then return end
	
	laserDoor:SetAttribute("Enabled", false)

	-- Disable lasers
	for _, laserBeam in pairs(laserBeamWall:GetChildren()) do
		if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
			laserBeam.PrimaryPart.Beam.Enabled = false
			laserBeam.PrimaryPart.Part.Transparency = 1
		end
	end

	-- Re-enable after duration
	task.delay(config.duration or 5, function()
		for _, laserBeam in pairs(laserBeamWall:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				laserBeam.PrimaryPart.Beam.Enabled = true
				laserBeam.PrimaryPart.Part.Transparency = 0.5
			end
		end

		laserDoor:SetAttribute("Enabled", true)
	end)
end

-- Action: Give Data
function TerminalActions.GiveData(config, player)
	--TODO

	print("Gave data to player:", player.Name, config.dataId)
end

-- Action: Start Quest
function TerminalActions.StartQuest(config, player)
	--TODO
	print("Started quest for player:", player.Name, config.questId)
end

-- Action: Disable Security
function TerminalActions.DisableSecurity(config, player)
	local securityZone = getObjectFromPath(config.targetPath)
	if not securityZone then return end

	-- Disable cameras, alarms, etc.
	--for _, child in pairs(securityZone:GetDescendants()) do
	--	if child:IsA("Model") and (child.Name == "Camera" or child.Name == "Alarm") then
	--		child:SetAttribute("Disabled", true)
	--	end
	--end

	-- Re-enable after duration
	--task.delay(config.duration or 30, function()
	--	for _, child in pairs(securityZone:GetDescendants()) do
	--		if child:IsA("Model") and (child.Name == "Camera" or child.Name == "Alarm") then
	--			child:SetAttribute("Disabled", false)
	--		end
	--	end
	--end)
	
	print("Disabled Security")
end

return TerminalActions