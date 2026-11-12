local ServerScriptService = game:GetService("ServerScriptService")
local Data = require(ServerScriptService.Data.Data)
local GamePasses = require(game.ServerScriptService.Data.Templates.GamePasses) --generic defs
local MarketplaceService = game:GetService("MarketplaceService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local Players = game:GetService("Players")
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")

local functions = {}

local DEATH_RAT_GROUPIE_PASS = 19678577

function functions.GetGamePasses(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.GamePasses
end

function functions.AddGamePass(player,gamePassId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("GamePassFunctions - AddGamePass player:"..player.Name.." gamePass:"..gamePassId)

	profile.Data.GamePasses[gamePassId]=true

	functions.AwardGamePass(player,gamePassId)
end

function functions.AwardGamePass(player,gamePassId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("GamePassFunctions - AwardGamePass player:"..player.Name.." gamePass:"..gamePassId)

	--loop through Awards and give out type of awards 
	for i, reward in pairs(GamePasses[gamePassId].Reward) do
		if (reward.Type == "Money") then
			InventoryFunctions.AddMoney(player,reward.Amount)
		end

		if (reward.Type == "Experience") then
			ProgressFunctions.AddXP(player,reward.Amount)
		end

		if (reward.Type == "Item") then
			InventoryFunctions.AddItem(player,reward.Name,reward.Amount)
		elseif (reward.Type == "BuildItem") then
			InventoryFunctions.AddBuildItem(player,reward.Name)
		end
	end
end

function functions.HandleGamePass(player,gamePassId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("TEST GAMEPASSES 4",gamePassId)

	local hasGamePass = false

	-- Check if the player has Death Rat Groupie pass (19678577)
	local success, message = pcall(function()
		hasGamePass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)

	--Logger.Debug("TEST GAMEPASSES 5 hasGamePass",hasGamePass)
	-- If there's an error, issue a warning and exit the function
	if not success then
		warn("Error while checking if player has pass: " .. tostring(message))
		return
	end

	if hasGamePass == true then
		functions.AddGamePass(player,gamePassId)
	else
		MarketplaceService:PromptGamePassPurchase(player, gamePassId)
	end

end

function functions.HandleGamePasses(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for id, pass in pairs(profile.Data.GamePasses) do
		functions.HandleGamePass(player,id)
	end

end

function onProfileLoaded(player)
	--Logger.Debug("GamePassFunctions onProfileLoaded")
	functions.HandleGamePasses(player)
end

local function onPromptGamePassPurchaseFinished(player, purchasedPassID, purchaseSuccess)

	if purchaseSuccess == true then
		--Logger.Debug("TEST GAMEPASSES 7:"..player.Name .. " purchased the game pass with ID " .. purchasedPassID)

		functions.HandleGamePass(player,purchasedPassID)

	else
		--Logger.Debug("TEST GAMEPASSES 8:"..player.Name .. " FAILED purchase for gamepass with ID " .. purchasedPassID)

	end
end

-- Connect "PromptGamePassPurchaseFinished" events to the "onPromptGamePassPurchaseFinished()" function
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptGamePassPurchaseFinished)

ProfileLoadedEvent.Event:Connect(onProfileLoaded)


return functions