-- ShopServer.lua
-- Place this as a Script inside ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local PURCHASE_REMOTE_NAME = "ShopPurchase"

-- ============================================================
-- PLAYER CURRENCY (replace with your own DataStore solution)
-- ============================================================
local playerCredits = {}  -- [player] = number

Players.PlayerAdded:Connect(function(player)
	-- Grant starting credits. Replace with DataStore load as needed.
	playerCredits[player] = 1000
	print(player.Name .. " joined with " .. playerCredits[player] .. " credits.")
end)

Players.PlayerRemoving:Connect(function(player)
	-- Save to DataStore here if needed
	playerCredits[player] = nil
end)

-- ============================================================
-- REMOTE SETUP
-- ============================================================
local purchaseRemote = ReplicatedStorage:FindFirstChild(PURCHASE_REMOTE_NAME)
if not purchaseRemote then
	purchaseRemote = Instance.new("RemoteEvent")
	purchaseRemote.Name = PURCHASE_REMOTE_NAME
	purchaseRemote.Parent = ReplicatedStorage
end

-- ============================================================
-- PURCHASE HANDLER
-- ============================================================
purchaseRemote.OnServerEvent:Connect(function(player, order)
	-- Validate order is a table
	if type(order) ~= "table" then
		warn("ShopServer: Invalid order from " .. player.Name)
		return
	end

	local credits = playerCredits[player]
	if not credits then
		warn("ShopServer: No credit record for " .. player.Name)
		return
	end


	for _, line in ipairs(order) do
		local itemId = line.id
		local qty    = tonumber(line.qty)

		if not itemId or not qty then
			warn("ShopServer: Malformed order line from " .. player.Name)
			return
		end

		-- Clamp qty to reasonable range
		qty = math.floor(math.clamp(qty, 0, 99))

		if not itemsmodule[itemId] then
			warn("ShopServer: Unknown item id " .. tostring(itemId) .. " from " .. player.Name)
			return
		end

		if qty > 0 then
			InventoryFunctions.BuyItem(player,itemId,qty)
		end
	end

end)

print("ShopServer running. Listening for purchase events.")