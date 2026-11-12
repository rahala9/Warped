local ServerScriptService = game:GetService("ServerScriptService")
local Data = require(ServerScriptService.Data.Data)
local Subscriptions = require(game.ServerScriptService.Data.Templates.Subscriptions) --generic defs
local MarketplaceService = game:GetService("MarketplaceService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local Players = game:GetService("Players")
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")

local functions = {}

local WAY_OF_THE_NINJA_SUBSCRIPTION = "EXP-3869814489491439731"

function functions.GetSubscriptions(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Subscriptions
end

function functions.AddSubscription(player,subscriptionId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("SubscriptionFunctions - AddSubscription player:"..player.Name.." subscription Name:"..profile.Data.Subscriptions[subscriptionId].Name)

	profile.Data.Subscriptions[subscriptionId] = true

	functions.AwardSubscription(player,subscriptionId)
end

function functions.RemoveSubscription(player,subscriptionId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	functions.RevokeSubscription(player,subscriptionId)

	profile.Data.Subscriptions[subscriptionId] = nil
end

function functions.AwardSubscription(player,subscriptionId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("SubscriptionFunctions - AwardSubscription player:"..player.Name.." subscription Name:"..profile.Data.Subscriptions[subscriptionId].Name)

	--loop through Awards and give out type of awards 
	for i, reward in pairs(profile.Data.Subscriptions[subscriptionId].Reward) do
		if (reward.Type == "Money") then
			InventoryFunctions.AddMoney(player,reward.Amount)
		end

		if (reward.Type == "Experience") then
			ProgressFunctions.AddXP(player,reward.Amount)
		end

		if (reward.Type == "Item") then
			InventoryFunctions.AddItem(player,reward.Name,reward.Amount)
		end
	end
end

function functions.RevokeSubscription(player,subscriptionId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("SubscriptionFunctions - RevokeSubscription player:"..player.Name.." subscription Name:"..profile.Data.Subscriptions[subscriptionId].Name)

	--loop through Awards and give out type of awards 
	for i, reward in pairs(profile.Data.Subscriptions[subscriptionId].Reward) do

		--Only durable goods are removed
		if (reward.Type == "Item") then
			InventoryFunctions.RemoveItem(player,reward.Name)
		end
	end
end

function functions.HandleSubscriptions(player)

	--Logger.Debug("SubscriptionFunctions - HandleSubscriptions player:"..player.Name)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for i, sub in pairs(profile.Data.Subscriptions) do
		functions.HandleSubscription(player,sub.Id)
	end
end

function functions.HandleSubscription(player,subscriptionId)
	--Logger.Debug("SubscriptionFunctions - HandleSubscription player:"..player.Name)

	local success, response = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, subscriptionId)
	end)

	if not success then
		warn(`Error while checking if player has subscription: {response}`)
		return
	end

	if response.IsSubscribed then
		functions.AddSubscription(player,subscriptionId)
	else
		functions.RemoveSubscription(player,subscriptionId)
	end
end

function onProfileLoaded(player)
	--Logger.Debug("SubscriptionFunctions - onProfileLoaded player:"..player.Name)
	functions.HandleSubscriptions(player)
end

local function onUserSubscriptionStatusChanged(player: Player, subscriptionId: string)
	--Logger.Debug("SubscriptionFunctions - onUserSubscriptionStatusChanged player:"..player.Name)
	functions.HandleSubscription(player,subscriptionId)
end

Players.UserSubscriptionStatusChanged:Connect(onUserSubscriptionStatusChanged)

ProfileLoadedEvent.Event:Connect(onProfileLoaded)

--Logger.Debug("PROFILE LOADED CONNECTED for subscription functions")


return functions