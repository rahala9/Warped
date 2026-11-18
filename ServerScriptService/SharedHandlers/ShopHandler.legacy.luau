-- ShopServer.lua
-- Place this as a Script inside ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local EffectQueryService = require(
	ServerScriptService:WaitForChild("EffectSystem"):WaitForChild("EffectQueryService")
)
local DialogService = require(
	ServerScriptService:WaitForChild("SharedServices"):WaitForChild("DialogSystem"):WaitForChild("DialogService")
)

local PURCHASE_REMOTE_NAME = "ShopPurchase"
local ACCESS_REMOTE_NAME = "RequestShopAccess"

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

local accessRemote = ReplicatedStorage:FindFirstChild(ACCESS_REMOTE_NAME)
if accessRemote and not accessRemote:IsA("RemoteFunction") then
	warn("ShopServer: " .. ACCESS_REMOTE_NAME .. " must be a RemoteFunction")
	accessRemote:Destroy()
	accessRemote = nil
end
if not accessRemote then
	accessRemote = Instance.new("RemoteFunction")
	accessRemote.Name = ACCESS_REMOTE_NAME
	accessRemote.Parent = ReplicatedStorage
end

accessRemote.OnServerInvoke = function(player, promptObject)
	if typeof(promptObject) ~= "Instance"
		or not promptObject:IsA("ProximityPrompt")
		or promptObject.Name ~= "Shop"
		or not promptObject:IsDescendantOf(workspace)
	then
		return false
	end

	local allowed, message = EffectQueryService.CanPerform(player, "Purchase")
	if not allowed then
		local npcName = promptObject:GetAttribute("NPCName")
		local displayName = promptObject:GetAttribute("ShopkeeperName")
			or npcName
			or "Shopkeeper"
		DialogService:ShowRestrictionDialog(player, npcName or "Shopkeeper", displayName, message)
		return false
	end
	return true
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
