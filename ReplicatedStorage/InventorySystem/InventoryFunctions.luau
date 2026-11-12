--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events

--Functions

local InventorySystem = ReplicatedStorage:WaitForChild("InventorySystem")
local ItemDefs = InventorySystem:WaitForChild("ItemDefs")

--Definition Modules
local sources = {
	require(InventorySystem:WaitForChild("Items")),
	require(ItemDefs:WaitForChild("Weapons")),
	require(ItemDefs:WaitForChild("Ammo")),
	require(ItemDefs:WaitForChild("Info")),
}

local functions = {}

local itemsmodule = {}

local function merge(sourceTable)
	for id, def in pairs(sourceTable) do
		if itemsmodule[id] then
			warn(("[Items.Registry] Duplicate item id '%s' found. Keeping first."):format(id))
		else
			itemsmodule[id] = def
		end
	end
end

for _, src in ipairs(sources) do
	merge(src)
end

function functions.GetImageMap()

	--Check if we have the item
	if itemsmodule.ImageMap then

		return itemsmodule.ImageMap

	end

	return nil
end

function functions.GetItemDef(itemId)

	--Handle container or non stackable unique custom ids
	local itemPieces = string.split(itemId,"_")
	local itemName = itemPieces[1]

	--Check if we have the item
	if itemsmodule[itemName] then

		return itemsmodule[itemName]

	end

	return nil
end

function functions.HasItemDef(itemId)

	--Check if we have the item
	if itemsmodule[itemId] then

		return true

	end

	return false
end

function functions.GetOffHandItem(playerInventory,player)

	return playerInventory["OffHand"]
end



function functions.HasItem(playerInventory,itemId,amount,includeToolbelt)

	if (amount == nil) then
		amount = 1
	end

	if (playerInventory["Items"][itemId] ~= nil) then
		return true,playerInventory["Items"][itemId].Amount,itemId,nil
	end

	if (includeToolbelt and playerInventory["Tools"][itemId]) then
		return true,1,itemId,nil
	end

	if (includeToolbelt and playerInventory["Weapon"].Name) then
		return true,1,itemId,nil
	end

	--Check containers
	for itemToCheckContainerId,itemToCheckContainer in pairs(playerInventory["Items"]) do
		if (itemsmodule[itemToCheckContainer.Name] and itemsmodule[itemToCheckContainer.Name].SubType == "Container") then
			if (itemToCheckContainer.Contains[itemId]) then
				if (itemToCheckContainer.Contains[itemId].Amount >= amount) then
					return true,itemToCheckContainer.Contains[itemId].Amount,itemId,itemToCheckContainerId
				end

			end
		end
	end
end


return functions