-- ServerScriptService.Systems.TerminalActions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DoorFunctions = require(ServerScriptService.SharedFunctions.DoorFunctions)
local TeleporterFunctions = require(ServerScriptService.SharedFunctions.TeleporterFunctions)
local NPCRemoteControlFunctions = require(ServerScriptService.SharedFunctions.NPCRemoteControlFunctions)
local LaserDoorService = require(ServerScriptService.SharedServices.LaserDoorService)

local TerminalActions = {}

-- Helper function to get object from path
local function getObjectFromPath(path)
	if typeof(path) ~= "string" or path == "" then
		return nil
	end

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

local function getTerminalTarget(prompt)
	local current = prompt and prompt.Parent
	while current and current ~= workspace do
		-- Only inspect the current ancestor. A recursive search from a shared
		-- parent could accidentally select a neighboring terminal's target.
		local reference = current:FindFirstChild("TerminalTarget")
		if reference and reference:IsA("ObjectValue") then
			local value = reference.Value
			if value and value.Parent then
				return value
			end
		end

		current = current.Parent
	end

	return nil
end

local function resolveTerminalTarget(config, prompt)
	return getTerminalTarget(prompt) or getObjectFromPath(config.targetPath)
end

function TerminalActions.ToggleSlidingDoor(config, player, prompt)
	local slidingDoor = resolveTerminalTarget(config, prompt)
	if not slidingDoor then 
		warn("Could not find TerminalTarget or sliding door at path:", config.targetPath)
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
function TerminalActions.ToggleLaserDoor(config, player, prompt)
	-- Physical terminals can link their controlled instance through a generic
	-- ObjectValue. Existing configured paths remain supported as a fallback.
	local laserDoor = resolveTerminalTarget(config, prompt)
	if not laserDoor then 
		warn("Could not find TerminalTarget or laser door at path:", config.targetPath)
		return 
	end

	LaserDoorService:DisableFor(laserDoor, config.duration or 5)
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
