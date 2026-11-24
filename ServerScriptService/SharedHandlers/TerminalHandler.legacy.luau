local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage
local MessagePlayerEvent = ReplicatedStorage.SharedRemotes.MessagePlayer

local ActionFunctions = require(ServerScriptService.SharedFunctions.ActionFunctions)
local TerminalConfigurations = require(ServerScriptService.SharedModules.Terminals)
local TerminalActionsFunctions = require(ServerScriptService.SharedFunctions.Terminals.TerminalActionsFunctions)
local TerminalEffectsFunctions = require(ServerScriptService.SharedFunctions.Terminals.TerminalEffectsFunctions)
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)

local PlayerLockouts = {}  -- {[player] = {[terminalId] = lockoutUntil}}
local MINIMUM_HACK_DURATION = 0.75
local MAXIMUM_HACK_MESSAGES = 4
local SECONDS_PER_HACK_MESSAGE = 1.5

local function getHackingPresentation(player, duration)
	local skillLevel = math.clamp(
		math.floor(tonumber(AttributesFunctions.GetSkill(player, "Hacking")) or 0),
		0,
		5
	)
	local source = TerminalConfigurations.HackingMessages[skillLevel]
	if not source or #source == 0 then
		return {"Hacking Terminal..."}, duration
	end

	local shuffled = table.clone(source)
	for index = #shuffled, 2, -1 do
		local swapIndex = math.random(1, index)
		shuffled[index], shuffled[swapIndex] = shuffled[swapIndex], shuffled[index]
	end

	local messageCount = math.clamp(
		math.floor(duration / SECONDS_PER_HACK_MESSAGE) + 1,
		1,
		math.min(MAXIMUM_HACK_MESSAGES, #shuffled)
	)
	local messages = table.create(messageCount)
	for index = 1, messageCount do
		messages[index] = shuffled[index]
	end

	return messages, duration / messageCount
end

local function getInheritedAttribute(instance, attributeName)
	local current = instance
	while current and current ~= workspace do
		local value = current:GetAttribute(attributeName)
		if value ~= nil then
			return value
		end
		current = current.Parent
	end
	return nil
end

local function getTerminalId(prompt)
	local current = prompt
	while current and current ~= workspace do
		local terminalId = current:GetAttribute("TerminalID")
		if typeof(terminalId) == "string" and terminalId ~= "" then
			return terminalId
		end
		current = current.Parent
	end
	return prompt.Name
end

local function reportMissingConfig(player, terminalId)
	DisplayActionMessageEvent:FireClient(player, {
		"TERMINAL UNAVAILABLE",
		"Terminal configuration was not found.",
	}, 3)
	warn("No configuration found for terminal:", terminalId)
end

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
	
	local terminalId = getTerminalId(prompt)
	local config = TerminalConfigurations.Terminals[terminalId]

	if not config then
		reportMissingConfig(player, terminalId)
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
	
	if config.requiresAuthorization then
		local requiredItem = getInheritedAttribute(prompt, "RequiredItem")
			or config.requiredItem
		local requiredAmount = getInheritedAttribute(prompt, "RequiredItemAmount")
			or config.requiredItemAmount
			or 1

		if typeof(requiredItem) ~= "string" or requiredItem == "" then
			DisplayActionMessageEvent:FireClient(player, {
				"ACCESS DENIED",
				"No authorized keycard accepted. Use hack access.",
			}, 3)
			warn("Authorized terminal is missing RequiredItem:", prompt:GetFullName())
			return
		end

		local hasItem = InventoryFunctions.HasItem(player, requiredItem, requiredAmount, true, true)
		if not hasItem then
			local itemDef = InventoryFunctions.GetItemDef(requiredItem)
			local displayName = itemDef and itemDef.DisplayName or requiredItem
			MessagePlayerEvent:FireClient(
				player,
				string.format("Access denied. Requires %d %s.", requiredAmount, displayName),
				requiredItem
			)
			return
		end
	end

	local useActionHandler = TerminalActionsFunctions[config.useAction]
	if useActionHandler then
		useActionHandler(config.useConfig or config, player, prompt)
	else
		DisplayActionMessageEvent:FireClient(player, {
			"TERMINAL UNAVAILABLE",
			"This terminal has no configured use action.",
		}, 3)
		warn("No use action handler found for:", config.useAction)
	end
end

function HandleHackTerminal(player, prompt)
	local terminalId = getTerminalId(prompt)
	local config = TerminalConfigurations.Terminals[terminalId]

	if not config then
		reportMissingConfig(player, terminalId)
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
	local playerTimeToHack = math.max(
		config.hackTime or ActionFunctions.GetTimeForAction(player, ActionFunctions.ActionTypes.Hacking, difficulty),
		MINIMUM_HACK_DURATION
	)
	local hackingMessages, hackingMessageDelay = getHackingPresentation(player, playerTimeToHack)

	DisplayActionMessageEvent:FireClient(player, hackingMessages, hackingMessageDelay, playerTimeToHack)

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
				actionHandler(config.onSuccess, player, prompt)
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
