local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage

local ActionFunctions = require(ServerScriptService.SharedFunctions.ActionFunctions)
local TerminalConfigurations = require(ServerScriptService.SharedModules.Terminals)
local TerminalActionsFunctions = require(ServerScriptService.SharedFunctions.Terminals.TerminalActionsFunctions)
local TerminalEffectsFunctions = require(ServerScriptService.SharedFunctions.Terminals.TerminalEffectsFunctions)

local PlayerLockouts = {}  -- {[player] = {[terminalId] = lockoutUntil}}

local function isPlayerNearTerminal(player: Player, prompt: ProximityPrompt, maxDist: number): boolean
	local char = player.Character
	if not char then return false end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local terminalPos = prompt.Parent.Position
	if not terminalPos then return false end

	return (hrp.Position - terminalPos).Magnitude <= maxDist
end

function HandleUseTerminal(player, prompt)
	-- For basic "use" interactions (reading info, etc.)
	print("Player used terminal:", prompt.Name)
	-- Could display terminal info, logs, etc.
	
	local terminalId = prompt:GetAttribute("TerminalID") or prompt.Name
	local config = TerminalConfigurations.Terminals[terminalId]

	if not config then
		warn("No configuration found for terminal:", terminalId)
		return
	end
	
	-- Initialize player lockouts if needed
	if not PlayerLockouts[player] then
		PlayerLockouts[player] = {}
	end

	-- Check if player is locked out from THIS terminal
	local lockoutUntil = PlayerLockouts[player][terminalId] or 0
	local currentTime = os.time()

	if currentTime < lockoutUntil then
		local remainingTime = lockoutUntil - currentTime
		DisplayActionMessageEvent:FireClient(player, {"You're locked out for " .. remainingTime .. " seconds"}, 3)
		return
	end
	
	local useActionHandler = TerminalActionsFunctions[config.useAction]
	if useActionHandler then
		useActionHandler(config, player)
	else
		warn("No use action handler found for:", config.useAction)
	end
end

function HandleHackTerminal(player, prompt)
	local terminalId = prompt:GetAttribute("TerminalID") or prompt.Name
	local config = TerminalConfigurations.Terminals[terminalId]

	if not config then
		warn("No configuration found for terminal:", terminalId)
		return
	end

	-- Initialize player lockouts if needed
	if not PlayerLockouts[player] then
		PlayerLockouts[player] = {}
	end

	-- Check if player is locked out from THIS terminal
	local lockoutUntil = PlayerLockouts[player][terminalId] or 0
	local currentTime = os.time()

	if currentTime < lockoutUntil then
		local remainingTime = lockoutUntil - currentTime
		DisplayActionMessageEvent:FireClient(player, {"You're locked out for " .. remainingTime .. " seconds"}, 3)
		return
	end

	local difficulty = ActionFunctions.Difficulty[config.difficulty] or ActionFunctions.Difficulty.Average
	local playerTimeToHack = config.hackTime or ActionFunctions.GetTimeForAction(player, ActionFunctions.ActionTypes.Hacking, difficulty)

	DisplayActionMessageEvent:FireClient(player, {"Hacking Terminal...", "Accessing System...", "Processing..."}, 2, playerTimeToHack)

	task.delay(playerTimeToHack, function()
		if not isPlayerNearTerminal(player, prompt, 10) then
			DisplayActionMessageEvent:FireClient(player, {""}, 1)
			return
		end

		local hackResult = ActionFunctions.AttemptAction(player, ActionFunctions.ActionTypes.Hacking, difficulty)

		if hackResult.success then
			-- Execute success action
			DisplayActionMessageEvent:FireClient(player, config.onSuccess.messages, 3)

			local actionHandler = TerminalActionsFunctions[config.onSuccess.action]
			if actionHandler then
				actionHandler(config.onSuccess, player)
			else
				warn("No action handler found for:", config.onSuccess.action)
			end

		else
			-- Handle failure
			local failureConfig = config.onFailure.lockouts[hackResult.degree]

			if failureConfig then
				DisplayActionMessageEvent:FireClient(player, {failureConfig.message}, 3)

				-- Apply lockout
				if failureConfig.duration > 0 then
					PlayerLockouts[player][terminalId] = currentTime + failureConfig.duration
				end

				-- Apply effects
				for _, effect in ipairs(failureConfig.effects) do
					local effectHandler = TerminalEffectsFunctions[effect]
					if effectHandler then
						effectHandler(player, prompt.Parent.Position)
					else
						warn("No effect handler found for:", effect)
					end
				end
			end
		end
	end)
end

-- Cleanup when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	PlayerLockouts[player] = nil
end)

local function onPromptTriggered(promptObject, player)
	if promptObject.Name == "UseTerminal" then
		HandleUseTerminal(player, promptObject)
	elseif promptObject.Name == "HackTerminal" then
		HandleHackTerminal(player, promptObject)
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)