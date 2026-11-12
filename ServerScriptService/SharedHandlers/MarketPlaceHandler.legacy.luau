local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

-- Data store for tracking purchases that were successfully processed
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

-- Table setup containing product IDs and functions for handling purchases
local productFunctions = {}

-- ProductId 1197745501 for 100 log
productFunctions[1197745501] = function(receipt, player)
	InventoryFunctions.AddItem(player,"Log",100)
	return true
end
-- ProductId 1197745439 for 100 rocks
productFunctions[1197745439] = function(receipt, player)
	InventoryFunctions.AddItem(player,"Rock",100)
	return true
end

productFunctions[1924530131] = function(receipt, player)
	InventoryFunctions.AddItem(player,"ScrapMetal",20)
	return true
end

-- ProductId 1228880627 for Tent8/Teepee
productFunctions[1228880627] = function(receipt, player)
	InventoryFunctions.AddBuildItem(player,"Tent8","Tents")
	return true
end

-- ProductId 1941947093 for Tent12/Tree House
productFunctions[1941947093] = function(receipt, player)
	InventoryFunctions.AddBuildItem(player,"Tent12","Tents")
	return true
end


-- ProductId 1229492184 for BearStatue
productFunctions[1229492184] = function(receipt, player)
	InventoryFunctions.AddBuildItem(player,"BearStatue","Other")
	return true
end

--ProductId 1928722222 for 10 robux tip
productFunctions[1928722222] = function(receipt, player)
	MessagePlayerEvent:FireClient(player,"Thanks")
	return true
end

--ProductId 1928723019 for 50 robux tip
productFunctions[1928723019] = function(receipt, player)
	MessagePlayerEvent:FireClient(player,"Thanks. That's Awesome")
	return true
end

--ProductId 1928723303 for 100 robux tip
productFunctions[1928723303] = function(receipt, player)
	MessagePlayerEvent:FireClient(player,"Wow that is so much. Thank You!!!!")
	return true
end

--ProductId 1928723668 for 300 robux tip
productFunctions[1928723668] = function(receipt, player)
	MessagePlayerEvent:FireClient(player,"You are amazing!!!  This will help a lot.")
	return true
end





-- The core 'ProcessReceipt' callback function
local function processReceipt(receiptInfo)

	-- Determine if the product was already granted by checking the data store  
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false
	local success, errorMessage = pcall(function()
		purchased = purchaseHistoryStore:GetAsync(playerProductKey)
	end)
	-- If purchase was recorded, the product was already granted
	if success and purchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	-- Find the player who made the purchase in the server
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- The player probably left the game
		-- If they come back, the callback will be called again
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Look up handler function from 'productFunctions' table above
	local handler = productFunctions[receiptInfo.ProductId]

	-- Call the handler function and catch any errors
	local success, result = pcall(handler, receiptInfo, player)
	if not success or not result then
		warn("Error occurred while processing a product purchase")
		--Logger.Debug("\nProductId:", receiptInfo.ProductId)
		--Logger.Debug("\nPlayer:", player)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Record transaction in data store so it isn't granted again
	local success, errorMessage = pcall(function()
		purchaseHistoryStore:SetAsync(playerProductKey, true)
	end)
	if not success then
		error("Cannot save purchase data: " .. errorMessage)
	end

	-- IMPORTANT: Tell Roblox that the game successfully handled the purchase
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Set the callback; this can only be done once by one script on the server! 
MarketplaceService.ProcessReceipt = processReceipt
