local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage

local SwitchConfigurations = require(ServerScriptService.SharedModules.Switches)
local SwitchActionsFunctions = require(ServerScriptService.SharedFunctions.Switches.SwitchActionsFunctions)

local function isPlayerNearSwitch(player: Player, prompt: ProximityPrompt, maxDist: number): boolean
	local char = player.Character
	if not char then return false end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local terminalPos = prompt.Parent.Position
	if not terminalPos then return false end

	return (hrp.Position - terminalPos).Magnitude <= maxDist
end

function HandleUseSwitch(player, prompt)
	local switchId = prompt:GetAttribute("SwitchID") or prompt.Name
	local config = SwitchConfigurations.Switches[switchId]

	if not config then
		warn("No configuration found for switch:", switchId)
		return
	end

	--DisplayActionMessageEvent:FireClient(player, {"Hacking Terminal...", "Accessing System...", "Processing..."}, 2, playerTimeToHack)

	if not isPlayerNearSwitch(player, prompt, 10) then
		DisplayActionMessageEvent:FireClient(player, {""}, 1)
		return
	end

	DisplayActionMessageEvent:FireClient(player, config.messages, 3)

	local actionHandler = SwitchActionsFunctions[config.action]
	if actionHandler then
		actionHandler(config, player)
	else
		warn("No action handler found for:", config.action)
	end
end

local function onPromptTriggered(promptObject, player)
	if promptObject.ObjectText == "UseSwitch" then
		HandleUseSwitch(player, promptObject)
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)