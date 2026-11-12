--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--Remote Events
local sendinv = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SendInv")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local MoneyUpdatedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MoneyUpdated")
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local InventoryItemChangedEvent = game.ServerStorage:WaitForChild("InventorySystem"):WaitForChild("InventoryItemChanged")	
local CraftingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CraftingChanged")
local CookingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CookingChanged")
local RemoveQuestEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveQuest")
local SellingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SellingChanged")
local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")

--Functions
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local CharacterFunctions = require(ServerScriptService.Data.DataCharacterFunctions)
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local CollectionFunctions = require(ServerScriptService.Data.DataCollectionFunctions)
local EquipmentFunctions = require(ReplicatedStorage:WaitForChild("SharedFunctions"):WaitForChild("EquipmentFunctions"))

local ReplicatedStorageSharedModules = ReplicatedStorage:WaitForChild("SharedModules")
--Definition Modules

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))


--local sources = {
--	require(ReplicatedStorageSharedModules:WaitForChild("Items")),
--	require(ReplicatedStorageSharedModules:WaitForChild("Weapons")),
--	require(ReplicatedStorageSharedModules:WaitForChild("Ammo")),
--}

--local itemsmodule = {}

--local function merge(sourceTable)
--	for id, def in pairs(sourceTable) do
--		if functions.GetItemDef(id] then
--			warn(("[Items.Registry] Duplicate item id '%s' found. Keeping first."):format(id))
--		else
--			functions.GetItemDef(id] = def
--		end
--	end
--end

--for _, src in ipairs(sources) do
--	merge(src)
--end


local Recipes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CraftingRecipes"))
local CookingRecipes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CookingRecipes2"))
local QuestsDef = require(ServerScriptService.Data.Templates.Quests)

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)

local functions = {}

local ItemTypeToInventorySectionMap = {
	["Weapon"]="Weapon",
	["Artifact"]="Weapon",
	["Ammo"]="Weapon",
	["OffHand"]="Weapon",
	["Tool"]="Tool",
	["Consumable"]="Consumable",
	["Clothing"]="Clothing",
	["Material"]="Material",
	["Access"]="Access",
	["Info"]="Info",
	["Misc"]="Misc",
	["PowerSource"]="Misc",
	["Disk"]="Misc",
	["Heal"]="Misc",
	["Trash"]="Misc",
	["TempHold"]="",
	["Money"]="Misc"

}

ProfileLoadedEvent.Event:Connect(function (player)
	MoneyUpdatedEvent:FireClient(player,functions.GetTotalMoney(player))

	functions.LoadPlayerClothing(player)

end)

function functions.DeepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = functions.DeepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

function functions.GetItemBaseName(itemId)
	local itemPieces = string.split(itemId,"_")
	local itemName = itemPieces[1]
	return itemName
end

function functions.GetItemDef(itemId)

	local itemName = functions.GetItemBaseName(itemId)

	--Check if we have the item
	if itemsmodule[itemName] then

		return itemsmodule[itemName]

	end

	return nil
end

function functions.GetTotalMoney(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Money
end

function functions.AddMoney(player,amount)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (not amount) then
		warn("DataInventoryFunctions.AddMoney. amount is nil")
		return
	end

	profile.Data.Money = profile.Data.Money + amount

	MoneyUpdatedEvent:FireClient(player,profile.Data.Money,amount)
end

function functions.RemoveMoney(player,amount)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if ((profile.Data.Money - amount) < 0) then
		profile.Data.Money = 0
	else
		profile.Data.Money = profile.Data.Money - amount
	end

	MoneyUpdatedEvent:FireClient(player,profile.Data.Money,-amount)

end

local function UpdateInventoryUI(player)
	sendinv:FireClient(player)
end

function functions.GetItemTotal(player,itemId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local totalAmount = 0

	if (profile.Data.Inventory["Items"][itemId]) then
		totalAmount += profile.Data.Inventory["Items"][itemId].Amount
	end

	--If Item is a container then loop through and apply all effects
	for key,item in pairs(profile.Data.Inventory["Items"]) do
		if (functions.GetItemDef(item.Name) and functions.GetItemDef(item.Name).SubType == "Container") then
			for containerItemKey,containerItem in pairs(profile.Data.Inventory["Items"][key].Contains) do
				if (containerItemKey == itemId) then
					totalAmount += containerItem.Amount
				end
			end
		end
	end


	return totalAmount
end

function functions.MoveItemToSelling(player,itemId,sellingSlot,amount)		
	local profile = Data[player]
	if (profile == nil) then return nil end


	if (profile.Data.Inventory["Items"][itemId] == nil) then
		warn("DataInventoryFunctions-MoveItemToSelling no item found for itemId:",itemId)
		UpdateInventoryUI(player)
		return
	end

	--Check that the container slot is empty or same item

	local item = profile.Data.Inventory["Items"][itemId]

	--Check that this item can be sold (Trade)
	if (functions.GetItemDef(itemId).Trade == false) then
		MessagePlayerEvent:FireClient(player,"Cannot sell: "..functions.GetItemDef(itemId).DisplayName)
		UpdateInventoryUI(player)
		return
	end

	if (amount == nil) then
		amount = 1
	end

	--1. We have this item in some slot. Add to the amount and for the slot of the current existing item
	--2. We don't have this item at all. Add to target slot
	--3. There is an existing different item. Move it back to backpack and set this one in target slot


	if (profile.Data.Inventory["Selling"][itemId]) then
		--We have the same item so just add to it
		--TODO make sure this amount won't go over max

		local newSellingItem = {}
		newSellingItem.Name = itemId
		newSellingItem.Slot = profile.Data.Inventory["Selling"][itemId].Slot
		newSellingItem.Amount = profile.Data.Inventory["Selling"][itemId].Amount + amount

		if (profile.Data.Inventory["Selling"][itemId]["Price"]) then
			newSellingItem.Price = profile.Data.Inventory["Selling"][itemId].Price
		end

		profile.Data.Inventory["Selling"][itemId] = functions.DeepCopy(newSellingItem)

		--Remove Item from inventory
		functions.RemoveItem(player,itemId,amount,true)

	else

		--The slot doesn't have the same item but does it have a different item
		local itemToReplaceId,itemToReplace = functions.GetSellingItemBySlot(player,sellingSlot)

		if (itemToReplace) then

			profile.Data.Inventory["Selling"][itemId] = nil
			functions.AddItem(player,itemToReplaceId,itemToReplace.Amount,false) --TODO What if there is not space
		end

		local newSellingItem = {}
		newSellingItem.Name = itemId
		newSellingItem.Slot = sellingSlot
		newSellingItem.Amount = amount

		profile.Data.Inventory["Selling"][itemId] = functions.DeepCopy(newSellingItem)

		--Remove Item from inventory
		functions.RemoveItem(player,itemId,amount,true)


	end

	SellingChangedEvent:FireClient(player,"Update",player,profile.Data.Inventory["Selling"])

	InventoryItemChangedEvent:Fire(player,itemId,1)

	UpdateInventoryUI(player)

end

function functions.FindEmptyOverflowContainerSlot(player,itemId)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local emptySlots ={
		true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true
	}

	--profile.Data.Inventory["ItemSlots"][inventorySection]={SlotNumber=1,ItemName="Bat"}
	for _,slotItem in pairs(profile.Data.Inventory["Overflow"].Contains ) do

		if (not slotItem.Slot) then
			warn("DataInventoryFunctions.FindEmptySlot no slotItem.Slot found for item Name:",slotItem.Name)
			return nil
		end

		emptySlots[slotItem.Slot]=false
	end

	for slot,slotIsEmpty in pairs(emptySlots) do
		if (slotIsEmpty) then

			if (slot <= 4) then
				return slot
			else
				return nil
			end

		end
	end
end


--function functions.FindEmptyContainerSlot(player,itemId,containerId,containerName)
--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	local emptySlots ={
--		true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true
--	}

--	--profile.Data.Inventory["ItemSlots"][inventorySection]={SlotNumber=1,ItemName="Bat"}
--	for _,slotItem in pairs(profile.Data.Inventory["Items"][containerId].Contains ) do

--		if (not slotItem.Slot) then
--			warn("DataInventoryFunctions.FindEmptySlot no slotItem.Slot found for item Name:",slotItem.Name)
--			return nil
--		end

--		emptySlots[slotItem.Slot]=false
--	end

--	for slot,slotIsEmpty in pairs(emptySlots) do
--		if (slotIsEmpty) then

--			if (slot <= functions.GetItemDef(containerName].ContainerSlots) then
--				return slot
--			else
--				return nil
--			end

--		end
--	end
--end

--function functions.AddItemToContainer(player,itemId,containerId,container,amount)

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	if (profile.Data.Inventory["Items"][containerId].Contains == nil) then
--		--Add Contains if not present
--		profile.Data.Inventory["Items"][containerId].Contains={}
--		--Had no items so add it to Slot1
--		local newContainerItem = {}
--		newContainerItem.Name = itemId
--		newContainerItem.Slot = 1
--		newContainerItem.Amount = amount
--		profile.Data.Inventory["Items"][containerId].Contains[itemId] = functions.DeepCopy(newContainerItem)
--		return true
--	end

--	for key,item in pairs(profile.Data.Inventory["Items"][containerId].Contains) do
--		local newContainerItem = {}
--		newContainerItem.Name = itemId
--		newContainerItem.Slot = tonumber(item.Slot)

--		--Does container already have some of this item?
--		if (key == itemId) then
--			--We have the same item so just add to it
--			--TODO make sure this amount won't go over max
--			newContainerItem.Amount = profile.Data.Inventory["Items"][containerId].Contains[itemId].Amount + amount
--			profile.Data.Inventory["Items"][containerId].Contains[itemId] = functions.DeepCopy(newContainerItem)
--			return true
--		end
--	end

--	--we had items but not our item, so now see if there is a slot open

--	local slot = functions.FindEmptyContainerSlot(player,itemId,containerId,container.Name)

--	if (slot) then
--		local newContainerItem = {}
--		newContainerItem.Name = itemId
--		newContainerItem.Slot = tonumber(slot)
--		newContainerItem.Amount = amount
--		profile.Data.Inventory["Items"][containerId].Contains[itemId] = functions.DeepCopy(newContainerItem)
--		return true
--	else
--		MessagePlayerEvent:FireClient(player,"Must have a container that can hold: "..functions.GetItemDef(itemId].NeedToContain)
--		return false
--	end	

--end

function functions.GetContainerForType(player,itemNeedToContain)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--loop through items
	for key,item in pairs(profile.Data.Inventory.Items) do
		if (functions.GetItemDef(item.Name).SubType == "Container") then
			if (functions.GetItemDef(item.Name).AllowedToContain == itemNeedToContain) then
				return key,item
			end
		end
	end

	return nil
end

--function functions.BuyItemForContainer(player,itemName)
--	if (functions.HasEnoughMoney(player,functions.GetItemDef(itemName]["Value"])) then

--		local containerId,container = functions.GetContainerForType(player,functions.GetItemDef(itemName].NeedToContain)

--		if (container ~= nil) then

--			local success = functions.AddItemToContainer(player,itemName,containerId,container,1)
--			if (success) then
--				functions.RemoveMoney(player,functions.GetItemDef(itemName]["Value"])
--			end
--		else
--			MessagePlayerEvent:FireClient(player,"Must have a container that can hold: "..functions.GetItemDef(itemName].NeedToContain)
--		end

--	else
--		MessagePlayerEvent:FireClient(player,"Not enough money")
--	end	


--end

function functions.BuyItem(player,itemName,amount)
	--TODO check inventory space

	if (functions.HasEnoughMoney(player,functions.GetItemDef(itemName)["Value"])) then

		--If the item needs a container that can hold solid then the backpack itself is good enough
		if (functions.GetItemDef(itemName).NeedToContain and functions.GetItemDef(itemName).NeedToContain ~= "Solid") then
			--functions.BuyItemForContainer(player,itemName)
			return false
		else

			if (functions.AddItem(player,itemName,amount)) then
				functions.RemoveMoney(player,functions.GetItemDef(itemName)["Value"])
				return true
			else
				return false
			end
		end

	else
		MessagePlayerEvent:FireClient(player,"Not enough money")
		return false
	end	
end

function functions.AddItemToOverflowContainer(player,itemId,itemName,amount,item)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Overflow"].Contains == {}) then

		--Add Contains if not present
		profile.Data.Inventory["Overflow"].Contains={}
		--Had no items so add it to Slot1
		local newContainerItem = {}
		newContainerItem.Name = itemName
		newContainerItem.Slot = 1
		newContainerItem.Amount = amount

		if (functions.GetItemDef(itemName).SubType == "Container") then
			if (item and item["Contains"] and item["Contains"] ~= nil) then
				newContainerItem.Contains = functions.DeepCopy(item["Contains"])
			else
				newContainerItem.Contains = {}
			end	
		end

		if (functions.GetItemDef(item.Name).Type == "Weapon") then
			newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(item.Name)["WeaponAttacks"])
		end

		profile.Data.Inventory["Overflow"].Contains[itemId] = functions.DeepCopy(newContainerItem)

		if ((functions.OverflowCount(player) == 1) and (functions.GetItemDef(itemName).Type ~= "Consumable")) then
			--This is the first item to make us overflow so add slow effect but not for liquid

			EffectsFunctions.AddEffect(player,"Slow",10)
		end

		UpdateInventoryUI(player)
		return true
	end

	for key,item in pairs(profile.Data.Inventory["Overflow"].Contains) do
		local newContainerItem = {}
		newContainerItem.Name = itemName
		newContainerItem.Slot = tonumber(item.Slot)
		newContainerItem.Amount = amount

		if (functions.GetItemDef(itemName).SubType == "Container") then
			if (item and item["Contains"] and item["Contains"] ~= nil) then
				newContainerItem.Contains = functions.DeepCopy(item["Contains"])
			else
				newContainerItem.Contains = {}
			end	
		end

		if (functions.GetItemDef(item.Name).Type == "Weapon") then
			newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(item.Name)["WeaponAttacks"])
		end

		--Does container already have some of this item?
		if (key == itemId) then
			--We have the same item so just add to it
			--TODO make sure this amount won't go over max
			newContainerItem.Amount = profile.Data.Inventory["Overflow"].Contains[itemId].Amount + amount

			profile.Data.Inventory["Overflow"].Contains[itemId] = functions.DeepCopy(newContainerItem)

			if ((functions.OverflowCount(player) == 1) and (functions.GetItemDef(itemName).Type ~= "Consumable")) then
				--This is the first item to make us overflow so add slow effect
				EffectsFunctions.AddEffect(player,"Slow",10)
			end

			UpdateInventoryUI(player)
			return true
		end
	end

	--we had items but not our item, so now see if there is a slot open

	local slot = functions.FindEmptyOverflowContainerSlot(player,itemId)

	if (slot) then
		local newContainerItem = {}
		newContainerItem.Name = itemName
		newContainerItem.Slot = tonumber(slot)
		newContainerItem.Amount = amount
		if (functions.GetItemDef(itemName).SubType == "Container") then
			if (item and item["Contains"] and item["Contains"] ~= nil) then
				newContainerItem.Contains = functions.DeepCopy(item["Contains"])
			else
				newContainerItem.Contains = {}
			end	
		end

		if (functions.GetItemDef(item.Name).Type == "Weapon") then
			newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(item.Name)["WeaponAttacks"])
		end

		profile.Data.Inventory["Overflow"].Contains[itemId] = functions.DeepCopy(newContainerItem)

		if ((functions.OverflowCount(player) == 1) and (functions.GetItemDef(itemName).Type ~= "Consumable")) then
			--This is the first item to make us overflow so add slow effect
			EffectsFunctions.AddEffect(player,"Slow",10)
		end

		UpdateInventoryUI(player)
		return true
	else
		MessagePlayerEvent:FireClient(player,"Overflow Container is full. Items lost")
		return false
	end	
end

function functions.BuyItemForContainer(player,itemName,amount)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (amount == nil) then
		amount = 1
	end

	if (functions.HasEnoughMoney(player,functions.GetItemDef(itemName)["Value"]*amount)) then

		--Clear overflow container
		profile.Data.Inventory["Overflow"].Contains = {}

		functions.RemoveMoney(player,functions.GetItemDef(itemName)["Value"]*amount)

		local newContainerItem = {}
		newContainerItem.Name = itemName
		newContainerItem.Amount = amount

		functions.AddItemToOverflowContainer(player,itemName,itemName,amount,newContainerItem)

		return true
	else
		MessagePlayerEvent:FireClient(player,"Not enough money")
		return false
	end	
end

--function functions.BuyBuildItem(player,itemName)

--	if (functions.HasMaxOfBuildItem(player, itemName)) then
--		MessagePlayerEvent:FireClient(player,"You have too many of this item")
--		return
--	end

--	if (functions.HasEnoughMoney(player,buildItems[itemName]["Value"])) then
--		functions.RemoveMoney(player,buildItems[itemName]["Value"])
--		functions.AddBuildItem(player,itemName)

--	else
--		MessagePlayerEvent:FireClient(player,"Not enough money")
--	end	
--end

--function functions.BuySwimItem(player,itemName)

--	if (functions.HasSwimItem(player, itemName)) then
--		MessagePlayerEvent:FireClient(player,"You have too many of this item")
--		return
--	end

--	if (functions.HasEnoughMoney(player,swimItems[itemName]["Value"])) then
--		functions.RemoveMoney(player,swimItems[itemName]["Value"])
--		functions.AddSwimItem(player,itemName)

--	else
--		MessagePlayerEvent:FireClient(player,"Not enough money")
--	end	
--end

function functions.IsObjectQuestStep(player,modelName)
	for i, quest in pairs(QuestsDef[player.Name]) do
		for i, quest_step in pairs(quest.Steps) do

			if(quest_step.Type == "Put") then
				if(quest_step.Destination == modelName) then
					return quest_step
				end
			else
				return nil
			end
		end
	end
end

local function RemoveItem(player,itemId)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Inventory["Items"][itemId]=nil	
end

function functions.LoadPlayerClothing(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Head"] ~= nil) then
		EquipmentFunctions.Equip(player,"Head",profile.Data.Inventory["Head"].Name)
	end

	if (profile.Data.Inventory["Back"] ~= nil) then
		
		EquipmentFunctions.Equip(player,"Back",profile.Data.Inventory["Back"].Name)
	end

	if (profile.Data.Inventory["Face"] ~= nil) then
		EquipmentFunctions.Equip(player,"Face",profile.Data.Inventory["Face"].Name)
	end
	
	if (profile.Data.Inventory["Chest"] ~= nil) then
		EquipmentFunctions.Equip(player,"Chest",profile.Data.Inventory["Chest"].Name)
	end
	
	if (profile.Data.Inventory["Legs"] ~= nil) then
		EquipmentFunctions.Equip(player,"Legs",profile.Data.Inventory["Legs"].Name)
	end
	
	if (profile.Data.Inventory["Shoulder"] ~= nil) then
		EquipmentFunctions.Equip(player,"Shoulder",profile.Data.Inventory["Shoulder"].Name)
	end
	
	if (profile.Data.Inventory["Forearm"] ~= nil) then
		EquipmentFunctions.Equip(player,"Forearm",profile.Data.Inventory["Forearm"].Name)
	end

end

function functions.MoveItemToToolbelt(player,itemId,slotOnToolbelt:string)

	local itemName = functions.GetItemBaseName(itemId)

	if not functions.HasItem(player,itemId,1) then
		return
	end

	--if (functions.GetItemDef(itemName].Type ~= "Tool") then
	--	MessagePlayerEvent:FireClient(player,itemName.. " cannot be equipped here")
	--	return
	--end

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (slotOnToolbelt == nil) then return nil end

	--Move any tool already in that slot
	if (profile.Data.Inventory["Tools"][slotOnToolbelt] ~= nil) then
		--TODO maybe do something else but for now just don't allow this
		return
	end

	functions.AddTool(player,itemId,slotOnToolbelt)

	local itemInInventory = profile.Data.Inventory["Items"][itemId]

	if (itemInInventory ~= nil) then
		--remove new from inv
		if itemInInventory.Amount == functions.GetItemDef(itemName)["Amount"] then
			itemInInventory.Amount = itemInInventory.Amount - functions.GetItemDef(itemName)["Amount"]
			RemoveItem(player,itemId)
		else
			itemInInventory.Amount = itemInInventory.Amount - functions.GetItemDef(itemName)["Amount"]
		end
	end

	UpdateInventoryUI(player)
end

--containerType = "Items" or "Tools"
function functions.GetContainerTotalAmount(containerContents)

	local total = 0

	for itemId,slotItem in pairs(containerContents) do

		total += slotItem.Amount
	end

	return total
end

function functions.GetContainerItemBySlot(player,containerId:string,containerSlot:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (not profile.Data.Inventory["Items"][containerId]) then
		warn("DataInventoryFunctions.GetContainerItemBySlot container for containerId not found:",containerId)
		return nil,nil
	end

	for itemId,slotItem in pairs(profile.Data.Inventory["Items"][containerId].Contains) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)

		if (tostring(slotItem.Slot) == tostring(containerSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.GetSellingItemBySlot(player,sellingSlot:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for itemId,slotItem in pairs(profile.Data.Inventory["Selling"]) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)

		if (tostring(slotItem.Slot) == tostring(sellingSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.GetSuitcaseItemBySlot(player,suitcaseSlot:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for itemId,slotItem in pairs(profile.Data.Inventory["Suitcase"]) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)

		if (tostring(slotItem.Slot) == tostring(suitcaseSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.GetItemBySlot(player,slot:string,targetInventorySection:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for itemId,slotItem in pairs(profile.Data.Inventory["Items"]) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)

		local inventorySection = ItemTypeToInventorySectionMap[slotItemDef.Type]

		if (inventorySection ~= targetInventorySection) then

			continue
		end

		if (tostring(slotItem.Slot) == slot) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.SetItemSlot(player,itemId, slot:number)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Items"][itemId]) then
		profile.Data.Inventory["Items"][itemId].Slot = tonumber(slot)
	end

	return nil
end

function functions.NextContainerId(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local nextContainerId = profile.Data.NextContainerId

	profile.Data.NextContainerId += 1

	return nextContainerId

end

function functions.FindEmptySlot(player, item, targetSlot)
	local profile = Data[player]
	if profile == nil then return nil end

	local inventorySection = ItemTypeToInventorySectionMap[item.Type]
	if not inventorySection then
		warn("FindEmptySlot: no inventorySection for item Type:", item.Type)
		return nil
	end

	local MAX_SLOTS = 16
	local emptySlots = table.create(MAX_SLOTS, true)

	for _, slotItem in pairs(profile.Data.Inventory["Items"]) do
		local slotItemDef = functions.GetItemDef(slotItem.Name)
		if not slotItemDef then
			warn("FindEmptySlot: unknown item def:", slotItem.Name)
			-- continue
		else
			local slotItemType = slotItemDef.Type
			local slotItemInventorySection = ItemTypeToInventorySectionMap[slotItemType]
			if not slotItemInventorySection then
				warn("FindEmptySlot: no inventorySection for slot item Type:", slotItemType)
				-- continue
			else
				local idx = tonumber(slotItem.Slot)
				if not idx then
					warn("FindEmptySlot: slot not numeric for item:", slotItem.Name, "value:", tostring(slotItem.Slot))
					-- continue
				elseif slotItemInventorySection == inventorySection then
					if idx >= 1 and idx <= MAX_SLOTS then
						emptySlots[idx] = false
					else
						warn("FindEmptySlot: slot out of range:", idx)
					end
				end
			end
		end
	end

	-- Prefer a requested slot if it's actually empty
	if targetSlot ~= nil then
		local t = tonumber(targetSlot)
		if t and t >= 1 and t <= MAX_SLOTS and emptySlots[t] then
			return t
		end
	end

	-- Return first empty slot (use ipairs to stay on numeric array)
	for i, isEmpty in ipairs(emptySlots) do
		if isEmpty then
			return i
		end
	end

	return nil
end


function functions.AddNonStackItem(player,itemName,reportItem)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local numberOfItem = functions.NextContainerId(player)

	local itemId = itemName.."_"..(numberOfItem+1)

	local newContainerItem = {}
	newContainerItem.Name = itemName
	newContainerItem.Slot = 1
	newContainerItem.Amount = 1
	if (functions.GetItemDef(itemName).SubType == "Container") then
		newContainerItem.Contains = functions.DeepCopy(functions.GetItemDef(itemName)["Contains"])
	end

	local itemSlotNumber = functions.FindEmptySlot(player,functions.GetItemDef(itemName))

	if (not itemSlotNumber) then
		MessagePlayerEvent:FireClient(player,"Adding "..functions.GetItemDef(itemName).DisplayName.." to overflow container: ",itemName,functions.GetItemDef(itemName).Name)

		functions.AddItemToOverflowContainer(player,itemId,itemName,1,newContainerItem)
		UpdateInventoryUI(player)
		return
	end

	newContainerItem.Slot = itemSlotNumber

	profile.Data.Inventory["Items"][itemId] = functions.DeepCopy(newContainerItem)

	InventoryItemChangedEvent:Fire(player,itemName,1)

	UpdateInventoryUI(player)

	if (reportItem) then
		MessagePlayerEvent:FireClient(player,"+1 "..functions.GetItemDef(itemName).DisplayName,itemName,functions.GetItemDef(itemName).Name)
	end

end

function functions.AddItem(player,itemName,amount,reportItem,targetSlot) --TODO usse reportItem??

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (amount == nil) then
		amount = 1 
	end

	if (reportItem == nil) then
		reportItem = true
	end

	--Logger.Debug("TEST AddItem Slot itemId,targetSlot:",itemName,targetSlot)

	--Logger.Debug("..............AddItem.................:"..itemName.." amount:"..amount)


	if (functions.GetItemDef(itemName) == nil) then
		warn("InventoryFunctions - AddItem: Item does not exist:"..itemName)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false
	end

	if (functions.GetItemDef(itemName)["Stacks"] ~= nil and functions.GetItemDef(itemName).Stacks == false) then
		functions.AddNonStackItem(player,itemName,reportItem)
		return true
	end

	--Do not add an item to inventory if it is a tool already on toolbelt
	if (functions.GetItemDef(itemName).Type == "Tool" and functions.HasTool(player, itemName)) then
		warn("InventoryFunctions - AddItem: Tried to add item that is still in toolbelt:"..itemName)
		return false
	end


	--Get amount of this item in other slots
	local otherSlotAmounts = 0

	if (profile.Data.Inventory["Weapon"] ~= nil and profile.Data.Inventory["Weapon"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	if (profile.Data.Inventory["OffHand"] ~= nil and profile.Data.Inventory["OffHand"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	if (profile.Data.Inventory["Artifact"] ~= nil and profile.Data.Inventory["Artifact"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	if (profile.Data.Inventory["Head"] ~= nil and profile.Data.Inventory["Head"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	if (profile.Data.Inventory["Back"] ~= nil and profile.Data.Inventory["Back"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	if (profile.Data.Inventory["Accessory"] ~= nil and profile.Data.Inventory["Accessory"].Name == itemName) then
		otherSlotAmounts = otherSlotAmounts + 1
	end

	--TODO must add to count from all other slots , toolbelt, weapon,offhand,head,back,accessory

	CollectionFunctions.Collect(player,itemName)

	--Add item. If item is already in inventory then add to item amount
	if (profile.Data.Inventory["Items"][itemName]) then
		profile.Data.Inventory["Items"][itemName].Name=itemName

		if ((profile.Data.Inventory["Items"][itemName].Amount + otherSlotAmounts + functions.GetItemDef(itemName)["Amount"]) <= functions.GetItemDef(itemName)["Limit"]) then
			profile.Data.Inventory["Items"][itemName].Amount=profile.Data.Inventory["Items"][itemName].Amount + (functions.GetItemDef(itemName)["Amount"]*amount) 
		else
			MessagePlayerEvent:FireClient(player,"You have too many of this item",functions.GetItemDef(itemName).Name)
			return false
		end

	else

		--TODO this does not count containers
		if ((otherSlotAmounts + functions.GetItemDef(itemName)["Amount"]) <= functions.GetItemDef(itemName)["Limit"]) then

			local itemSlotNumber = functions.FindEmptySlot(player,functions.GetItemDef(itemName),targetSlot)

			if (not itemSlotNumber) then
				MessagePlayerEvent:FireClient(player,"Adding "..itemName.." overflow container: ",itemName,functions.GetItemDef(itemName).Name)

				local newContainerItem = {}
				newContainerItem.Name = itemName
				newContainerItem.Amount = functions.GetItemDef(itemName)["Amount"]

				functions.AddItemToOverflowContainer(player,itemName,itemName,amount,newContainerItem)
				UpdateInventoryUI(player)
				return true
			end

			profile.Data.Inventory["Items"][itemName] = {}
			profile.Data.Inventory["Items"][itemName].Name = itemName --functions.DeepCopy(functions.GetItemDef(itemName]) -- create new item based on item def
			profile.Data.Inventory["Items"][itemName].Amount = functions.GetItemDef(itemName)["Amount"]*amount	
			profile.Data.Inventory["Items"][itemName].Slot = itemSlotNumber --slot number for this item types inventory section

			if (functions.GetItemDef(itemName)["Contains"]) then
				profile.Data.Inventory["Items"][itemName].Contains = functions.GetItemDef(itemName)["Contains"]
			end

			if (functions.GetItemDef(itemName).Type == "Weapon") then
				profile.Data.Inventory["Items"][itemName].WeaponAttacks = functions.DeepCopy(functions.GetItemDef(itemName)["WeaponAttacks"])
			end
		else
			MessagePlayerEvent:FireClient(player,"You have too many of this item",functions.GetItemDef(itemName).Name)
			return false
		end

	end

	--profile.Data.Progress.XP = profile.Data.Progress.XP + 5


	InventoryItemChangedEvent:Fire(player,itemName,profile.Data.Inventory["Items"][itemName].Amount)


	UpdateInventoryUI(player)

	if (reportItem) then
		MessagePlayerEvent:FireClient(player,"+"..amount.." "..functions.GetItemDef(itemName).DisplayName,functions.GetItemDef(itemName).Name)
	end

	return true

end

--function functions.PlayerOwnsEnoughItem(player,itemName)

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	if (not ((buildItems[itemName].Type == "Tents") or (buildItems[itemName].Type == "Other") or (buildItems[itemName].Type == "Gardening"))) then
--		warn("InventoryFunctions - PlayerOwnsEnoughItem: buildItemType does not exist:"..buildItems[itemName].Type)
--		MessagePlayerEvent:FireClient(player,"Warning 756: buildItemType does not exist:"..buildItems[itemName].Type.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return
--	end

--	local itemIndex = functions.GetBuildItemIndex(player,itemName)

--	--Check if we even had the item
--	if (itemIndex == -1) then
--		return false
--	end

--	local count = 0
--	for _,item in pairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetChildren()) do
--		if (item.Name == itemName) then
--			count = count + 1
--		end
--	end

--	if ((count >= profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][itemIndex].Amount)) then
--		return false
--	else
--		return true
--	end
--end

--function functions.GetBuildItemIndex(player, itemName)
--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	for i,v in pairs(profile.Data.Inventory["BuildItems"][buildItems[itemName].Type]) do
--		if (buildItems[itemName].Type == "Tents") then
--			if (v == itemName) then
--				return i
--			end
--		else
--			if (v.Name == itemName) then
--				return i
--			end
--		end
--	end

--	return -1
--end

--function functions.HasBuildItem(player, itemName)

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	for i,v in pairs(profile.Data.Inventory["BuildItems"][buildItems[itemName].Type]) do
--		if (buildItems[itemName].Type == "Tents") then
--			if (v == itemName) then
--				return true,i
--			end
--		else
--			if (v.Name == itemName) then
--				return true,i
--			end
--		end

--	end

--	return false,-1
--end

--function functions.HasSwimItem(player, itemName)

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	for i,swimItemName in pairs(profile.Data.Inventory["SwimItems"]) do

--		if (swimItemName == itemName) then
--			return true,i
--		end
--	end

--	return false,-1
--end

--function functions.PlayerHasReachedBuildLimit(player, itemName)

--	if (buildItems[itemName] == nil) then
--		warn("InventoryFunctions - PlayerHasReachedBuildLimit: Item does not exist:"..itemName)
--		MessagePlayerEvent:FireClient(player,"Warning 757: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return
--	end

--	local count = 0
--	for _,item in pairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetChildren()) do
--		if (item.Name == itemName) then
--			count = count + 1
--		end
--	end

--	return (count >= buildItems[itemName].Limit)

--end

--function functions.AddBuildItem(player,itemName) --TODO usse reportItem??

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	if (buildItems[itemName] == nil) then
--		warn("InventoryFunctions - AddBuildItem: Item does not exist:"..itemName)
--		MessagePlayerEvent:FireClient(player,"Warning 756: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return
--	end

--	if (not ((buildItems[itemName].Type == "Tents") or (buildItems[itemName].Type == "Other") or (buildItems[itemName].Type == "Gardening"))) then
--		warn("InventoryFunctions - AddBuildItem: buildItemType does not exist:"..buildItems[itemName].Type)
--		MessagePlayerEvent:FireClient(player,"Warning 756: buildItemType does not exist:"..buildItems[itemName].Type.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return
--	end


--	--Add item. If item is already in inventory then add to item amount unless Tents which always just has 1 amount
--	if (functions.HasBuildItem(player, itemName)) then

--		local itemIndex = functions.GetBuildItemIndex(player, itemName)

--		if (buildItems[itemName].Type == "Tents") then
--			--Cannot add more than one of same tent
--			return
--		else
--			if (not functions.HasMaxOfBuildItem(player, itemName)) then

--				profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][itemIndex].Amount=profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][itemIndex].Amount + 1
--			end
--		end

--	else
--		if (buildItems[itemName].Type == "Tents") then
--			table.insert(profile.Data.Inventory["BuildItems"][buildItems[itemName].Type],itemName)
--		else
--			local power = buildItems[itemName].Power

--			if (power == nil) then
--				power = 0
--			end
--			table.insert(profile.Data.Inventory["BuildItems"][buildItems[itemName].Type],{Name=itemName,Amount=1,Power=power})
--		end
--	end

--	--profile.Data.Progress.XP = profile.Data.Progress.XP + 5

--	UpdateInventoryUI(player)

--	MessagePlayerEvent:FireClient(player,"+1 "..buildItems[itemName].DisplayName)
--end

--function functions.AddSwimItem(player,itemName) --TODO usse reportItem??

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	if (swimItems[itemName] == nil) then
--		warn("InventoryFunctions - AddSwimItem: Item does not exist:"..itemName)
--		MessagePlayerEvent:FireClient(player,"Warning 756: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return
--	end

--	--Add item. If item is already in inventory then add to item amount unless Tents which always just has 1 amount
--	if (not functions.HasSwimItem(player, itemName)) then

--		if (swimItems[itemName].Type == "Toy") then
--			table.insert(profile.Data.Inventory["SwimItems"].Toys,{Name=itemName})
--		else
--			table.insert(profile.Data.Inventory["SwimItems"].Boats,{Name=itemName})
--		end


--	end

--	MessagePlayerEvent:FireClient(player,"+1 "..swimItems[itemName].DisplayName)
--end

--function functions.GetPowerSourcePower(player,itemName)
--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	local hasBuildItem,index = functions.HasBuildItem(player, itemName)
--	if (hasBuildItem) then
--		return profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][index].Power
--	end
--end

--function functions.UpdateBuildItemPowerSource(player,itemName,power)
--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	local hasBuildItem,index = functions.HasBuildItem(player, itemName)
--	if (hasBuildItem) then
--		profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][index].Power = power
--	end

--end

function functions.HasRequiredTool(player, objectRequiring)


	local requiredTool = objectRequiring:GetAttribute("RequiredTool")

	--If the objectRequiring is not even requiring an object then return we have what we need
	if ((requiredTool == nil) or (requiredTool == "")) then
		return true
	end

	local heldTool = StatesFunctions.GetCurrentTool(player)

	if (heldTool == requiredTool) then
		return true

	else

		if (objectRequiring:GetAttribute("RequiredToolHidden")) then

			MessagePlayerEvent:FireClient(player,"You wonder what tool might work on this")
		else
			MessagePlayerEvent:FireClient(player,"Must be holding "..functions.GetItemDef(requiredTool).DisplayName.." or equivalent",requiredTool)
		end


		return false
	end


end

function functions.HasRequiredItem(player, objectRequiring)


	local requiredItem = objectRequiring:GetAttribute("RequiredItem")
	local requiredItemAmount = objectRequiring:GetAttribute("RequiredItemAmount")

	--If the objectRequiring is not even requiring an object then return we have what we need
	if ((requiredItem == nil) or (requiredItem == "")) then
		return true
	end

	if (requiredItemAmount == nil) then
		requiredItemAmount = 1
	end

	local hasItem, usedItemName,containerId = functions.HasItem(player,requiredItem,requiredItemAmount,true,true)

	if (hasItem) then

		if (not functions.GetItemDef(usedItemName)) then
			warn("DataInventoryFunctions.HasRequiredItem item not found usedItemName:",usedItemName)
			return false	
		end

		if (functions.GetItemDef(usedItemName).Type ~= "Tool") then
			if (functions.GetItemDef(usedItemName).Type ~= "Access") or (functions.GetItemDef(usedItemName).SubType == "Lockpick") then
				if (containerId) then

					functions.RemoveItemFromContainer(player,containerId,requiredItem,requiredItemAmount,true)
				else
					functions.RemoveItem(player,requiredItem,requiredItemAmount)
				end
			end
		end

		return true

	else
		MessagePlayerEvent:FireClient(player,"Must have "..requiredItemAmount.." "..functions.GetItemDef(requiredItem).DisplayName.." or equivalent",requiredItem)

		--TODO offer purchase of required item

		return false
	end


end

--Returns true if player has enough of item or equivalent if orEquivalent is set
--and returns item type
function functions.HasItem(player,itemId,amount,includeToolbelt, orEquivalent)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemId == "" or itemId == nil) then
		return false,nil
	end

	local itemName = functions.GetItemBaseName(itemId)

	if (amount == nil) then
		amount = 1 
	end

	if (functions.GetItemDef(itemName) == nil) then
		warn("InventoryFunctions - AddItem: Item does not exist:"..itemName)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false,nil
	end

	--If item is a tool then there will only be 1
	if (functions.GetItemDef(itemName).Type == "Tool") then
		amount = 1
	end

	--Add item. If item is already in inventory then add to item amount

	if (includeToolbelt) then	

		if (functions.HasTool(player,itemId)) then
			return true,itemId
		elseif (profile.Data.Inventory["Items"][itemId]) then
			if (profile.Data.Inventory["Items"][itemId].Amount >= amount) then
				--We have enough of the item
				return true,itemId	
			end
		end
	elseif (profile.Data.Inventory["Items"][itemId]) then
		if (profile.Data.Inventory["Items"][itemId].Amount >= amount) then
			--We have enough of the item
			return true,itemId	
		end
	end

	--Check containers
	for itemToCheckContainerId,itemToCheckContainer in pairs(profile.Data.Inventory["Items"]) do
		if (functions.GetItemDef(itemToCheckContainer.Name) and functions.GetItemDef(itemToCheckContainer.Name).SubType == "Container") then
			if (itemToCheckContainer.Contains[itemId]) then
				if (itemToCheckContainer.Contains[itemId].Amount >= amount) then
					return true,itemId,itemToCheckContainerId
				end

			end
		end
	end

	--If we got here we don't yet have enough of the item so check for equal item if we need to or return not found
	if (orEquivalent and functions.GetItemDef(itemName).EqualItems ~= nil) then

		for _,equalItem in pairs(functions.GetItemDef(itemName).EqualItems) do

			--This is our current temp hold item. If only 1 is needed we are good
			if (functions.IsTempTool(player, equalItem) and (amount == 1)) then
				return true,equalItem
			end

			local hasItem, usedItemName = functions.HasItem(player,equalItem,amount,true,false)

			if (hasItem) then
				return true,usedItemName
			end
		end
	end


	return false,itemId

end

function functions.HasWeaponEquipped(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == "" or itemName == nil) then
		return false
	end

	if (functions.GetItemDef(itemName) == nil) then
		warn("InventoryFunctions - AddItem: Item does not exist:"..itemName)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false
	end

	if (profile.Data.Inventory["Weapon"] ~= nil and profile.Data.Inventory["Weapon"].Name == itemName)
	then
		return true
	else
		return false
	end
end

function functions.HasOffHandEquipped(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == "" or itemName == nil) then
		return false
	end

	if (functions.GetItemDef(itemName) == nil) then
		warn("InventoryFunctions - AddItem: Item does not exist:"..itemName)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false
	end

	if (profile.Data.Inventory["OffHand"] ~= nil and profile.Data.Inventory["OffHand"].Name == itemName)
	then
		return true
	else
		return false
	end
end

function functions.HasArtifactEquipped(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == "" or itemName == nil) then
		return false
	end

	if (functions.GetItemDef(itemName) == nil) then
		warn("InventoryFunctions - HasArtifactEquipped: Item does not exist:"..itemName)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false
	end

	if (profile.Data.Inventory["Artifact"] ~= nil and profile.Data.Inventory["Artifact"].Name == itemName)
	then
		return true
	else
		return false
	end
end

--function functions.HasMaxOfBuildItem(player, itemName)

--	local profile = Data[player]
--	if (profile == nil) then return nil end

--	if (buildItems[itemName] == nil) then
--		warn("InventoryFunctions - HasMaxOfBuildItem: Item does not exist:"..itemName)
--		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemName.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
--		return false
--	end

--	local itemIndex = functions.GetBuildItemIndex(player, itemName)

--	--Does player have any of this item?
--	if (itemIndex ~= -1) then

--		if (buildItems[itemName].Type == "Tents") then
--			return true
--		else
--			--Does player have the maximum amount of this item
--			if (profile.Data.Inventory["BuildItems"][buildItems[itemName].Type][itemIndex].Amount >= buildItems[itemName].Limit) then
--				return true
--			end
--		end

--	end

--	return false
--end

function functions.HasEnoughMoney(player, cost)
	if (functions.GetTotalMoney(player) >= cost) then
		return true
	else
		return false
	end
end

function format_thousand(v)
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos)
		.. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
		.. string.sub(string.format("%.2f", v - math.floor(v)), 2)
end

--Add commas and 2 place decimals for currency
function functions.FormatCurrency(number)
	return "$"..format_thousand(number)
end

function functions.DropItem(player,itemId)

	functions.RemoveItem(player,itemId)

	local itemName = functions.GetItemBaseName(itemId)

	--Place item on ground in world near player
	local newitem = game.ServerStorage.SharedServerItems.DroppedItems:FindFirstChild(itemName):Clone()

	newitem.Parent = workspace.UserDroppedItems
	newitem.Anchored = true
	local hrp = game.Workspace[player.Name].HumanoidRootPart
	if hrp then
		local dropDistance = 4
		local startPos = hrp.Position + hrp.CFrame.LookVector * dropDistance + Vector3.new(0,5,0)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {player.Character, workspace.UserDroppedItems}
		params.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(startPos, Vector3.new(0,-20,0), params)

		local dropPos = startPos
		if result then
			dropPos = result.Position + Vector3.new(0,newitem.Size.Y/2,0)
		end

		newitem.Parent = workspace.UserDroppedItems
		newitem.Anchored = true
		newitem.CanCollide = false
		newitem.Position = dropPos
	end
		
	newitem.CanCollide = false;

	--Add prompy proxy to allow pickup of item
	local proxyPrompt = Instance.new("ProximityPrompt")
	proxyPrompt.Name = "Pickup"..itemName
	proxyPrompt.ActionText = "Pickup"
	proxyPrompt.ObjectText = itemName
	proxyPrompt.HoldDuration = 1
	proxyPrompt.Style = Enum.ProximityPromptStyle.Custom
	proxyPrompt.MaxActivationDistance = 7
	proxyPrompt.RequiresLineOfSight = false
	proxyPrompt.Parent = newitem

	--Add dropped item to debris for clean up
	Debris:AddItem(newitem, 30)

end

function functions.HandleConsumedItem(player,itemId,containerId)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if functions.GetItemDef(itemId).ConsumeEffects then
		for key,value in pairs(functions.GetItemDef(itemId).ConsumeEffects) do

			if (key == "AddItem") then
				functions.AddItem(player,value)
			else
				EffectsFunctions.AddEffect(player,key,value)
			end

		end
	end

	if (containerId) then
		functions.RemoveItemFromContainer(player,containerId,itemId,1)
	else
		functions.RemoveItem(player,itemId,1)
	end

end

function functions.ConsumeItem(player,itemId)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check that we have item
	if profile.Data.Inventory["Items"][itemId] or profile.Data.Inventory["Tools"][itemId] then

		local item = profile.Data.Inventory["Items"][itemId] or profile.Data.Inventory["Tools"][itemId]
		local itemName = functions.GetItemBaseName(itemId)
		
		--If Item is a container then loop through and apply all effects
		if (functions.GetItemDef(itemName) and functions.GetItemDef(itemName).SubType == "Container") then
			for key,item in pairs(item.Contains) do
				if (functions.GetItemDef(item.Name).Type == "Consumable") then
					functions.HandleConsumedItem(player,item.Name,itemId)
				end
			end

		else
			if (functions.GetItemDef(itemName).Traits.Consumable) then
				functions.HandleConsumedItem(player,itemId)
			end

		end

	end

end

function functions.IsArmorLoadTooHigh(player,newItem)

	local profile = Data[player]
	if (profile == nil) then return true end

	local futureArmorLoad = 0
	local allowedArmorLoad = 5 + AttributesFunctions.GetOomph(player)

	--Add armor load of new item and subtract any armor load of armor that will be replaced by new item
	if (functions.GetItemDef(newItem).SubType == "Back" ) then

		futureArmorLoad = futureArmorLoad + functions.GetItemDef(newItem).ArmorLoad

		if (profile.Data.Inventory["Back"] ~= nil) then
			futureArmorLoad = futureArmorLoad - functions.GetItemDef(profile.Data.Inventory["Back"].Name).ArmorLoad
		end

	elseif (functions.GetItemDef(newItem).SubType == "Head" ) then

		futureArmorLoad = futureArmorLoad + functions.GetItemDef(newItem).ArmorLoad

		if (profile.Data.Inventory["Head"] ~= nil) then
			futureArmorLoad = futureArmorLoad - functions.GetItemDef(profile.Data.Inventory["Head"].Name).ArmorLoad
		end

	elseif (functions.GetItemDef(newItem).SubType == "Accessory" ) then

		futureArmorLoad = futureArmorLoad + functions.GetItemDef(newItem).ArmorLoad

		if (profile.Data.Inventory["Accessory"] ~= nil) then
			futureArmorLoad = futureArmorLoad - functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).ArmorLoad
		end
	end

	return futureArmorLoad > allowedArmorLoad

end



function functions.CalculateTotalAttribute(player,Attribute)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local totalAttribute = 0


	if (profile.Data.Inventory["Weapon"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).Attributes ~= nil) then
		totalAttribute = totalAttribute + (functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).Attributes[Attribute] or 0)
	end

	if (profile.Data.Inventory["Back"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Back"].Name).Attributes ~= nil) then
		totalAttribute = totalAttribute + (functions.GetItemDef(profile.Data.Inventory["Back"].Name).Attributes[Attribute] or 0)
	end

	if (profile.Data.Inventory["Head"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Head"].Name).Attributes ~= nil) then
		totalAttribute = totalAttribute + (functions.GetItemDef(profile.Data.Inventory["Head"].Name).Attributes[Attribute] or 0)
	end

	if (profile.Data.Inventory["Accessory"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Attributes ~= nil) then
		totalAttribute = totalAttribute + (functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Attributes[Attribute] or 0)
	end

	if (profile.Data.Inventory["OffHand"] ~= nil and functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Attributes ~= nil) then
		totalAttribute = totalAttribute + (functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Attributes[Attribute] or 0)
	end

	return totalAttribute

end

function functions.CalculateTotalArmor(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local totalArmor = 0

	if (profile.Data.Inventory["Back"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Back"].Name).Armor ~= nil) then
		totalArmor = totalArmor + functions.GetItemDef(profile.Data.Inventory["Back"].Name).Armor
	end

	if (profile.Data.Inventory["Head"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Head"].Name).Armor ~= nil) then
		totalArmor = totalArmor + functions.GetItemDef(profile.Data.Inventory["Head"].Name).Armor
	end

	if (profile.Data.Inventory["Accessory"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Armor ~= nil) then
		totalArmor = totalArmor + functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Armor
	end

	if (profile.Data.Inventory["OffHand"] ~= nil and functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Armor ~= nil) then
		totalArmor = totalArmor + functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Armor
	end

	return totalArmor

end

function functions.EquipItem2(player,itemName,destinationType)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local tempItem = {}
	tempItem.Name = itemName
	tempItem.Slot = 1
	tempItem.Amount = 1

	if (profile.Data.Inventory["Items"][itemName].Amount > 1) then
		profile.Data.Inventory["Items"][itemName].Amount -= 1
	else
		if (functions.GetItemDef(itemName).Type ~= "Weapon"  or functions.GetItemDef(itemName).WeaponAmmo ~= itemName) then
			profile.Data.Inventory["Items"][itemName] = nil
		end
	end

	--If we already have an item in this slot then swap
	if (profile.Data.Inventory[destinationType] ~= nil) then
		if functions.GetItemDef(itemName).SubType == "Back" then
			if (next(profile.Data.Inventory["VacpacExtra"].Contains) ~= nil) then
				MessagePlayerEvent:FireClient(player,"1 Empty vacpac before equipping a new one")
				return
			end
		end
		
		local success = functions.UnequipItem(player,profile.Data.Inventory[destinationType].Name)
		if (not success) then
			return
		end
	end

	if (functions.GetItemDef(itemName).Type == "Weapon") then
		tempItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(itemName)["WeaponAttacks"])
	end

	print("TEST DRAGG EquipItem2 itemName:tempItem:destinationType:",itemName,tempItem,destinationType	)
	profile.Data.Inventory[destinationType] = tempItem
end

--TODO allow equiping item from container.
function functions.EquipItem(player,itemName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check that we have item
	if profile.Data.Inventory["Items"][itemName] then


		if (functions.GetItemDef(itemName).Type == "Weapon" ) then
			if (functions.GetItemDef(itemName).SubType == "Melee" or functions.GetItemDef(itemName).SubType == "Ranged") then

				functions.EquipItem2(player,itemName,"Weapon")

			elseif (functions.GetItemDef(itemName).SubType == "OffHand") then

				functions.EquipItem2(player,itemName,"OffHand")

				ToolFunctions.AddToolToLeftHand(player,itemName)

			else
				warn("Subtype not found for weapon:",itemName)
				UpdateInventoryUI(player)
				return
			end
		elseif(functions.GetItemDef(itemName).Type == "Artifact") then

			functions.EquipItem2(player,itemName,"Artifact")

			--Do this each time we bring the artifact out instead of when it is first equipped
			--ToolFunctions.AddArtifact(player,itemName)

			--ToolFunctions.AddToolToLeftHand(player,itemName) --Shall attach to root and float to right side

		elseif (functions.GetItemDef(itemName).Type == "Clothing" ) then

			--Move inventory around
			if (functions.GetItemDef(itemName).SubType == "Back" ) then

				if (next(profile.Data.Inventory["VacpacExtra"].Contains) ~= nil) then
					MessagePlayerEvent:FireClient(player,"2 Empty vacpac before equipping a new one")
					return
				end

				functions.EquipItem2(player,itemName,"Back")

				EquipmentFunctions.Equip(player,"Back",itemName)

			elseif (functions.GetItemDef(itemName).SubType == "Head" ) then

				functions.EquipItem2(player,itemName,"Head")

				EquipmentFunctions.Equip(player,"Head",itemName)
			
			elseif (functions.GetItemDef(itemName).SubType == "Face" ) then

				functions.EquipItem2(player,itemName,"Face")

				EquipmentFunctions.Equip(player,"Face",itemName)
			
			elseif (functions.GetItemDef(itemName).SubType == "Chest" ) then

				functions.EquipItem2(player,itemName,"Chest")

				EquipmentFunctions.Equip(player,"Chest",itemName)

			elseif (functions.GetItemDef(itemName).SubType == "Legs" ) then

				functions.EquipItem2(player,itemName,"Legs")

				EquipmentFunctions.Equip(player,"Legs",itemName)
				
			elseif (functions.GetItemDef(itemName).SubType == "Forearm" ) then

				functions.EquipItem2(player,itemName,"Forearm")

				EquipmentFunctions.Equip(player,"Forearm",itemName)

			else
				warn("Subtype not found for clothing:",itemName)
				UpdateInventoryUI(player)
				return
			end

			--Set Armor
			AttributesFunctions.SetMaxArmor(player,functions.CalculateTotalArmor(player))			

		else
			MessagePlayerEvent:FireClient(player,functions.GetItemDef(itemName).DisplayName.. " cannot be equipped here")
			UpdateInventoryUI(player)
			return
		end

		--Handle any effects
		if (functions.GetItemDef(itemName)["Effects"]) then
			for effectToAddName,v in pairs(functions.GetItemDef(itemName)["Effects"]) do
				EffectsFunctions.AddEffect(player,effectToAddName)
			end
		end

		--Handle any attribute bonuses
		if (functions.GetItemDef(itemName)["Attributes"]) then
			for attributeToAddName,v in pairs(functions.GetItemDef(itemName)["Attributes"]) do
				if (attributeToAddName == "CriticalHitChance") then
					AttributesFunctions.SetCriticalHitChance(player,functions.CalculateTotalAttribute(player,"CriticalHitChance"))
				elseif (attributeToAddName == "CriticalHitDamage") then
					AttributesFunctions.SetCriticalHitDamage(player,functions.CalculateTotalAttribute(player,"CriticalHitDamage"))
				end

			end
		end

		UpdateInventoryUI(player)
	end

end

function functions.ExchangeSlots(player,itemName,itemType)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have a slot to move this item into
	local itemSlotNumber = functions.FindEmptySlot(player,functions.GetItemDef(itemName))
	if (not itemSlotNumber) then
		MessagePlayerEvent:FireClient(player,"No room to unequip")
		return
	end

	if (profile.Data.Inventory["Items"][itemName]) then
		profile.Data.Inventory["Items"][itemName].Amount += 1
	else
		profile.Data.Inventory["Items"][itemName] = functions.DeepCopy(profile.Data.Inventory[itemType])
		profile.Data.Inventory["Items"][itemName].Slot = itemSlotNumber
	end

	profile.Data.Inventory[itemType] = nil

end

function functions.UnequipItem(player,itemName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check that we have item

	if (functions.GetItemDef(itemName).Type == "Weapon" ) then
		if (functions.GetItemDef(itemName).SubType == "Melee" or functions.GetItemDef(itemName).SubType == "Ranged") then

			functions.ExchangeSlots(player,itemName,"Weapon")

		elseif (functions.GetItemDef(itemName).SubType == "OffHand") then

			functions.ExchangeSlots(player,itemName,"OffHand")

		end	

		--We are removing this item from the toolbelt so it can no longer be the held tool except for clothing

		ToolFunctions.RemoveToolFromHand(player,itemName)
		StatesFunctions.SetCurrentTool(player,nil)
		CurrentHeldToolChangedEvent:FireClient(player,"","")


	elseif (functions.GetItemDef(itemName).Type == "Clothing" ) then
		if (functions.GetItemDef(itemName).SubType == "Back" ) then


			if (next(profile.Data.Inventory["VacpacExtra"].Contains) ~= nil) then
				MessagePlayerEvent:FireClient(player,"3 Empty vacpac before equipping a new one")
				UpdateInventoryUI(player)
				return false
			end

			functions.ExchangeSlots(player,itemName,"Back")

			EquipmentFunctions.Unequip(player,"Back",itemName)

		elseif (functions.GetItemDef(itemName).SubType == "Head" ) then

			functions.ExchangeSlots(player,itemName,"Head")

			EquipmentFunctions.Unequip(player,"Head",itemName)

		end

		--Set Armor
		AttributesFunctions.SetMaxArmor(player,functions.CalculateTotalArmor(player))

	end

	--Handle any wear effects removal
	if (functions.GetItemDef(itemName)["WearEffects"]) then
		for effectToRemoveName,v in pairs(functions.GetItemDef(itemName)["WearEffects"]) do
			EffectsFunctions.RemoveEffect(player,effectToRemoveName)
		end
	end

	UpdateInventoryUI(player)
	
	return true

end

--For updating an item if their attack names or stats changed for example
function functions.UpdateItem(player,itemName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if profile.Data.Inventory["Items"][itemName] then
		functions.RemoveItem(player,itemName)
	end

	if (profile.Data.Inventory["Weapon"] == itemName) then
		functions.UnequipItem(player,profile.Data.Inventory["Weapon"].Name) 
		functions.RemoveItem(player,itemName)
		functions.AddItem(player,itemName)
		functions.EquipItem(player,itemName)
	else
		functions.RemoveItem(player,itemName)
		functions.AddItem(player,itemName)
	end

	UpdateInventoryUI(player)
end

function functions.OverflowCount(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local count = 0
	for key,item in pairs(profile.Data.Inventory["Overflow"].Contains) do
		count += 1
	end

	return count
end

function functions.RemoveItemFromOverflow(player,itemId)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if profile.Data.Inventory["Overflow"]["Contains"] and profile.Data.Inventory["Overflow"].Contains[itemId] then

		profile.Data.Inventory["Overflow"].Contains[itemId]=nil

		if (functions.OverflowCount(player) <= 0) then
			EffectsFunctions.RemoveEffect(player,"Slow")
		end

		UpdateInventoryUI(player)

	end

end

function functions.GetContainer(player,containerId)
	local containerIsInToolbelt = false

	local profile = Data[player]
	if (profile == nil) then return nil end

	local item = profile.Data.Inventory["Items"][containerId]

	--If not in items, check tools
	if (not item) then
		item = profile.Data.Inventory["Tools"][containerId]
		containerIsInToolbelt = true
	end

	return item,containerIsInToolbelt
end

function functions.ContainerHasItem(player,containerId,containerItemId)
	local container,containerIsInToolbelt = functions.GetContainer(player,containerId)

	if (not container) then
		return false
	else
		return container.Contains[containerItemId] or false
	end

end

function functions.GetFirstItemInContainer(player,containerId)

	local container = functions.GetContainer(player,containerId)

	if (not container) then
		return nil
	end

	for key, item in pairs(container.Contains) do
		return key
	end

	return nil
end

function functions.RemoveItemFromContainer(player,containerId,containerItemId,amount,display)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local itemToRemove = nil
	local container = nil
	local containerIsInToolbelt = false

	if (containerId == "Trading") then
		local trading = StatesFunctions.GetTrading(player)
		if (trading) then
			itemToRemove = trading.Items[containerItemId]
		end
	else
		container,containerIsInToolbelt = functions.GetContainer(player,containerId)

		if (container) then
			itemToRemove = container.Contains[containerItemId]
		else
			return
		end

	end


	if itemToRemove then

		--Default is to remove all
		if (amount == nil) or (amount == -1) then
			if (container.Contains[containerItemId]) then
				amount = itemToRemove.Amount
			end
		end

		--Check if we need to remove the item since it is the last one
		--or if we need to decrement the amount, but do not remove more than
		--we even have
		if amount >= itemToRemove.Amount then
			itemToRemove.Amount = 0

			if (containerId == "Trading") then
				local trading = StatesFunctions.GetTrading(player)
				if (trading) then
					trading.Items[containerItemId] = nil
				end
			else
				if (containerIsInToolbelt) then
					profile.Data.Inventory["Tools"][containerId].Contains[containerItemId]=nil	
				else
					profile.Data.Inventory["Items"][containerId].Contains[containerItemId]=nil	
				end

				if (display) then
					MessagePlayerEvent:FireClient(player,"-"..amount.." "..functions.GetItemDef(itemToRemove.Name).DisplayName,itemToRemove.Name)
				end
			end
		else
			itemToRemove.Amount = itemToRemove.Amount - amount
			if (display) then
				MessagePlayerEvent:FireClient(player,"-"..amount.." "..functions.GetItemDef(itemToRemove.Name).DisplayName,itemToRemove.Name)
			end
		end

	end

	if (containerId == "Trading") then
		StatesFunctions.UpdateTrading(player)
	end

	UpdateInventoryUI(player)
end

function functions.IsTempTool(player, itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["TempHold"] and (profile.Data.Inventory["TempHold"].Name == itemName)) then
		return true
	end

	return false

end

function functions.CleanCrafting(player,itemName)
	local craftingContents = StatesFunctions.GetCrafting(player)

	if (craftingContents[itemName]) then

		StatesFunctions.SetCraftingItem(player,itemName,nil)
	end
end

--Remove item but consider it may be in a container.  remove amount anywhere you find it
function functions.RemoveItemFromAll(player,itemId,amountToRemove,doNotDisplay)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local totalAvailable = functions.GetItemTotal(player,itemId)
	if (totalAvailable < amountToRemove) then
		MessagePlayerEvent:FireClient(player,"Not enough to remove of:",itemId)
		return false
	end

	local amountRemoved = 0

	--First remove any from main inventory
	if (profile.Data.Inventory["Items"][itemId]) then

		if (profile.Data.Inventory["Items"][itemId].Amount >= amountToRemove) then

			profile.Data.Inventory["Items"][itemId].Amount -= amountToRemove

			if (profile.Data.Inventory["Items"][itemId].Amount <= 0) then
				profile.Data.Inventory["Items"][itemId] = nil
			end

			--We have removed enough of item
			return true
		else
			--Amount in inventory is less than we need.  remove it all and move on
			amountRemoved = profile.Data.Inventory["Items"][itemId].Amount
			profile.Data.Inventory["Items"][itemId] = nil
		end
	end

	local amountRemaining = amountToRemove-amountRemoved

	--If Item is a container then loop through and apply all effects
	for key,item in pairs(profile.Data.Inventory["Items"]) do
		if (functions.GetItemDef(item.Name) and functions.GetItemDef(item.Name).SubType == "Container") then
			for containerItemKey,containerItem in pairs(profile.Data.Inventory["Items"][key].Contains) do
				if (containerItemKey == itemId) then

					amountRemaining = amountToRemove-amountRemoved

					if (containerItem.Amount >= amountRemaining) then
						profile.Data.Inventory["Items"][key].Contains[containerItemKey].Amount -= amountRemaining

						if (profile.Data.Inventory["Items"][key].Contains[containerItemKey].Amount <= 0) then
							profile.Data.Inventory["Items"][key].Contains[containerItemKey] = nil
						end

						--We have removed enough of item
						return true

					else
						--Amount in container is less than we need.  remove it all and move on
						amountRemoved += containerItem.Amount
						profile.Data.Inventory["Items"][key].Contains[containerItemKey] = nil
					end
				end
			end
		end
	end

	return false
end


function functions.RemoveItem(player,itemId,amount,doNotDisplay,doNotUpdateUI)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local itemName = functions.GetItemBaseName(itemId)

	--Check if we have the item

	local hasItem,itemId,itemToCheckContainerId = functions.HasItem(player,itemId,amount,true)

	local itemFromToolbelt = false

	if hasItem then

		--Get the item based on the itemName
		local item = nil

		if (itemToCheckContainerId) then
			item = profile.Data.Inventory["Items"][itemToCheckContainerId].Contains[itemId]
		else
			item = profile.Data.Inventory["Items"][itemId]
		end
		
		--If item is not there then check toolbelt
		if (not item) then
			itemFromToolbelt = true

			item = functions.GetTool(player,itemId)
		end
		
		if (not item) then
			warn("DataInventoryFunctions.RemoveItem item not found anywhere:",itemId)
		end

		--Default is to remove all
		if (amount == nil) or (amount == -1) then
			amount = item.Amount
		end

		--Check if we need to remove the item since it is the last one
		--or if we need to decrement the amount, but do not remove more than
		--we even have
		if amount >= item.Amount then
			item.Amount = 0

			if  (itemFromToolbelt) then
				functions.RemoveTool(player,itemId) --TODO This may need to actually be model from itemDef
			else
				profile.Data.Inventory["Items"][itemId]=nil
			end
			

			functions.CleanCrafting(player,itemId)

		else
			item.Amount = item.Amount - amount
		end

		if (doNotDisplay ~= true) then
			MessagePlayerEvent:FireClient(player,"-"..amount.." "..functions.GetItemDef(item.Name).DisplayName,itemId)
		end

	elseif functions.IsTempTool(player, itemId) then
		functions.RemoveTempHold(player,itemId)

	end

	if (doNotUpdateUI ~= true) then
		UpdateInventoryUI(player)
	end

end

function functions.CheckItem(player,itemName,amount)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory["Items"][itemName] then

		--Get the item based on the itemName
		local item = profile.Data.Inventory["Items"][itemName]

		if (item.Amount >= amount) then
			return true
		else
			return false
		end
	end

	if (profile.Data.Inventory["TempHold"] and (profile.Data.Inventory["TempHold"].Name == itemName)) then
		return true
	end

	return false
end

function functions.GetInventory(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Inventory
end

function functions.GetItems(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Inventory["Items"]
end


function functions.GetItemFromContainer(player,itemId,containerId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (containerId == "Trading") then
		local trading = StatesFunctions.GetTrading(player)
		if (trading) then
			return trading.Items[itemId]
		end
	end

	local container = profile.Data.Inventory["Items"][containerId]

	--Check if we have the containerId
	if container then
		return container.Contains[itemId]
	end

	return nil
end

function functions.GetItem(player,itemId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory["Items"][itemId] then

		return profile.Data.Inventory["Items"][itemId]

	end

	return nil
end

function functions.GetItemFromOutsideContainer(player,itemId,containerType)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory[containerType]["Contains"] and profile.Data.Inventory[containerType].Contains[itemId] then

		return profile.Data.Inventory[containerType].Contains[itemId]

	end

	return nil
end

function functions.GetWeapon(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory["Weapon"] ~= nil and profile.Data.Inventory["Weapon"].Name == itemName then

		return profile.Data.Inventory["Weapon"]

	end

	return nil
end

function functions.GetOffHandItem(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Inventory["OffHand"]
end

function functions.GetOffHand(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory["OffHand"] ~= nil and profile.Data.Inventory["OffHand"].Name == itemName then

		return profile.Data.Inventory["OffHand"]

	end

	return nil
end

function functions.GetArtifact(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check if we have the item
	if profile.Data.Inventory["Artifact"] ~= nil and profile.Data.Inventory["Artifact"].Name == itemName then

		return profile.Data.Inventory["Artifact"]

	end

	return nil
end

function functions.UpdateLastUsed(player, itemName, keycode, lastUsed)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Weapon"].Name ~= itemName) then
		return
	end

	--Check if we have the item
	if profile.Data.Inventory["Weapon"] then

		profile.Data.Inventory["Weapon"].WeaponAttacks[keycode.Name].LastUsed = lastUsed

	end
end

function functions.TimeElapsedSinceLastUse(player, itemName, keycode)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Weapon"].Name ~= itemName) then
		return
	end

	--Check if we have the item
	if profile.Data.Inventory["Weapon"] then

		return os.time() - profile.Data.Inventory["Weapon"].WeaponAttacks[keycode.Name].LastUsed

	end

	return 0
end


function functions.AddTool(player,itemId,slotOnToolbelt:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (slotOnToolbelt == nil) then return nil end

	local item = profile.Data.Inventory["Items"][itemId]

	local contains =item.Contains or {}

	profile.Data.Inventory["Tools"][itemId] = {Name=itemId,Amount=1,Slot=tostring(slotOnToolbelt),Contains=contains}

end

function functions.AddTempHold(player,itemName,itemModel,fromQuest)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == nil) then 
		warn("DataInventoryFunctions.AddTempHold itemName was nil")
		return nil 
	end

	profile.Data.Inventory["TempHold"]={Name = itemName,FromQuest = fromQuest}

	ToolFunctions.RemoveToolFromHand(player,StatesFunctions.GetCurrentTool(player))
	ToolFunctions.AddToolToHand(player,itemName,itemModel)	
	StatesFunctions.SetCurrentTool(player,itemName)
	StatesFunctions.SetCurrentToolSlotNumber(player,"Temp")
	CurrentHeldToolChangedEvent:FireClient(player,itemName,"Temp")

	UpdateInventoryUI(player)

end

function functions.RemoveTempHold(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == nil) then 
		warn("DataInventoryFunctions.RemoveTempHold itemName was nil")
		return nil 
	end

	if (profile.Data.Inventory["TempHold"] == nil) then 
		warn("DataInventoryFunctions.RemoveTempHold TempHold already nil")
		return nil 
	end

	if (profile.Data.Inventory["TempHold"].FromQuest) then
		RemoveQuestEvent:Fire(player,profile.Data.Inventory["TempHold"].FromQuest)
	end

	profile.Data.Inventory["TempHold"]=nil

	ToolFunctions.RemoveToolFromHand(player,itemName)
	StatesFunctions.SetCurrentTool(player,"")
	StatesFunctions.SetCurrentToolSlotNumber(player,"")
	CurrentHeldToolChangedEvent:FireClient(player,"","Nine")

	UpdateInventoryUI(player)

end

function functions.AddTempHoldLive(player,itemName,itemModel)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == nil) then 
		warn("DataInventoryFunctions.AddTempHold itemName was nil")
		return nil 
	end

	profile.Data.Inventory["TempHold"]={Name = itemName,FromQuest = nil}

	ToolFunctions.RemoveToolFromHand(player,StatesFunctions.GetCurrentTool(player))
	ToolFunctions.AddLiveObjectToHand(player,itemName,itemModel)	
	StatesFunctions.SetCurrentTool(player,itemName)
	StatesFunctions.SetCurrentToolSlotNumber(player,"Nine")
	CurrentHeldToolChangedEvent:FireClient(player,itemName,"Nine")

	UpdateInventoryUI(player)

end

function functions.RemoveTempHoldLive(player,itemName,itemModel)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == nil) then 
		warn("DataInventoryFunctions.AddTempHold itemName was nil")
		return nil 
	end

	profile.Data.Inventory["TempHold"]=nil

	ToolFunctions.RemoveToolFromHand(player,itemName)
	ToolFunctions.RemoveLiveObjectFromHand(player,itemName,itemModel)	
	StatesFunctions.SetCurrentTool(player,"")
	StatesFunctions.SetCurrentToolSlotNumber(player,"")
	CurrentHeldToolChangedEvent:FireClient(player,"","Nine")

	UpdateInventoryUI(player)

end


function functions.PlaceTempHold(player,itemName,placeAttachment)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemName == nil) then 
		warn("DataInventoryFunctions.AddTempHold itemName was nil")
		return nil 
	end

	if (profile.Data.Inventory["TempHold"] == nil) then
		return
	end


	local newitem = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Tools"):FindFirstChild(itemName):Clone()
	newitem.Anchored = true
	newitem.CFrame = placeAttachment.WorldCFrame
	newitem.Parent = placeAttachment.Parent

	--functions.RemoveTempHold(player,itemName)

end

function functions.HasItemType(player,itemType,ignoreCanNotRemoveItems,excludedSubTypes)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (itemsmodule.ItemTypes[itemType] == nil) then
		warn("InventoryFunctions - HasItemType: ItemType does not exist:"..itemType)
		MessagePlayerEvent:FireClient(player,"Warning 755: Item does not exist:"..itemType.." \nPlease report this to the support team along with the warning number",nil,false,nil,nil,nil,10)
		return false
	end
	
	if (not excludedSubTypes) then
		excludedSubTypes = {}
	end

	--Check all tools
	for _,tool in pairs(profile.Data.Inventory["Tools"]) do
		if (functions.GetItemDef(tool.Name).Type == itemType) then
			if (ignoreCanNotRemoveItems and not functions.GetItemDef(tool.Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
				return true
			end
		end
	end
	
	if (profile.Data.Inventory["Weapon"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).CanNotRemove) then
			return true
		end
	end
	
	if (profile.Data.Inventory["OffHand"] ~= nil and functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
			return true
		end
	end

	if (profile.Data.Inventory["Artifact"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Artifact"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Artifact"].Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
			return true
		end
	end

	if (profile.Data.Inventory["Head"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Head"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Head"].Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
			return true
		end
	end
	
	if (profile.Data.Inventory["Back"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Back"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Back"].Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
			return true
		end
	end
	
	if (profile.Data.Inventory["Accessory"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Type == itemType) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
			return true
		end
	end
	
	--Check items and containers
	for itemId,item in pairs(profile.Data.Inventory["Items"]) do
		if (functions.GetItemDef(item.Name) and functions.GetItemDef(item.Name).SubType == "Container") then
			
			if (table.find(functions.GetItemDef(item.Name).Traits,"Concealment")) then
				continue
			end
			
			for containerItemId,containerItem in pairs(item.Contains) do
				if (functions.GetItemDef(containerItem.Name).Type == itemType) then
					if (ignoreCanNotRemoveItems and not functions.GetItemDef(containerItem.Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
						return true
					end
				end
			end
		
		else
			if (functions.GetItemDef(item.Name).Type == itemType) then
				if (ignoreCanNotRemoveItems and not functions.GetItemDef(item.Name).CanNotRemove and not table.find(excludedSubTypes,item.SubType)) then
					return true
				end
			end
		end
	end

	return false

end

function functions.HasIllicitItem(player,ignoreCanNotRemoveItems)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Check all tools
	for _,tool in pairs(profile.Data.Inventory["Tools"]) do
		if (functions.GetItemDef(tool.Name).Illicit) then
			if (ignoreCanNotRemoveItems and not functions.GetItemDef(tool.Name).CanNotRemove) then
				return true
			end
		end
	end

	if (profile.Data.Inventory["Weapon"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Weapon"].Name).CanNotRemove) then
			return true
		end
	end

	if (profile.Data.Inventory["OffHand"] ~= nil and functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["OffHand"].Name).CanNotRemove) then
			return true
		end
	end

	if (profile.Data.Inventory["Artifact"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Artifact"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Artifact"].Name).CanNotRemove) then
			return true
		end
	end

	if (profile.Data.Inventory["Head"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Head"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Head"].Name).CanNotRemove) then
			return true
		end
	end

	if (profile.Data.Inventory["Back"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Back"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Back"].Name).CanNotRemove) then
			return true
		end
	end

	if (profile.Data.Inventory["Accessory"] ~= nil and functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).Illicit) then
		if (ignoreCanNotRemoveItems and not functions.GetItemDef(profile.Data.Inventory["Accessory"].Name).CanNotRemove) then
			return true
		end
	end

	--Check items and containers
	for itemId,item in pairs(profile.Data.Inventory["Items"]) do
		if (functions.GetItemDef(item.Name) and functions.GetItemDef(item.Name).SubType == "Container") then
			
			if (table.find(functions.GetItemDef(item.Name).Traits,"Concealment")) then
				continue
			end
			
			for containerItemId,containerItem in pairs(item.Contains) do
				if (functions.GetItemDef(containerItem.Name).Illicit) then
					if (ignoreCanNotRemoveItems and not functions.GetItemDef(containerItem.Name).CanNotRemove) then
						return true
					end
				end
			end

		else
			if (functions.GetItemDef(item.Name).Illicit) then
				if (ignoreCanNotRemoveItems and not functions.GetItemDef(item.Name).CanNotRemove) then
					return true
				end
			end
		end
	end

	return false

end

function functions.HasTool(player,toolName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Add item. If item is already in inventory then add to item amount

	if (profile.Data.Inventory["Tools"][toolName]) then
		return true
	end
	--for _,tool in pairs(profile.Data.Inventory["Tools"]) do
	--	if (tool == toolName) then
	--		return true
	--	end
	--end
	
	local itemName = functions.GetItemBaseName(toolName)

	if (functions.GetItemDef(itemName) and functions.GetItemDef(itemName).Type == "TempHold") then
		if (profile.Data.Inventory["TempHold"] and (profile.Data.Inventory["TempHold"].Name == itemName)) then
			return true
		end
	end


	return false
end

function functions.GetTool(player,toolName)

	if (not functions.HasTool(player,toolName)) then
		return nil
	end

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Add item. If item is already in inventory then add to item amount

	--for index,tool in pairs(profile.Data.Inventory["Tools"]) do
	--	if (tool == toolName) then
	--		return profile.Data.Inventory["Tools"][index]
	--	end
	--end

	return profile.Data.Inventory["Tools"][toolName]
end

function functions.RemoveTool(player,itemId)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local toolToRemove = profile.Data.Inventory["Tools"][itemId]

	local currentTool = StatesFunctions.GetCurrentTool(player)

	if (toolToRemove and (currentTool == toolToRemove.Name)) then
		ToolFunctions.RemoveToolFromHand(player,functions.GetItemBaseName(toolToRemove.Name))
		StatesFunctions.SetCurrentTool(player,nil)
		CurrentHeldToolChangedEvent:FireClient(player,"","")
	end

	profile.Data.Inventory["Tools"][itemId] = nil

end

function functions.OpenTreasure(player,rarity, maxlevel)

	local profile = Data[player]
	if (profile == nil) then return nil end


end

--CRAFTING FUNCTIONS
function functions.GetCraftingItemBySlot(player,craftingSlot:string)

	for itemId,slotItem in pairs(StatesFunctions.GetCrafting(player)) do

		if (tostring(slotItem.Slot) == tostring(craftingSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end


function functions.GetFullfilledRecipe(player)

	local craftingContents = StatesFunctions.GetCrafting(player)
	local toolNeeded
	local haveTool = false

	local neededNilSpotsCount = 0
	local totalPossibleFilledSlots = 3

	for recipeName,recipe in pairs(Recipes.GetRecipes()) do
		neededNilSpotsCount = 0

		if (recipe.Item1 ~= nil) then			
			if (craftingContents[recipe.Item1.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item2 ~= nil) then
			if (craftingContents[recipe.Item2.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item3 ~= nil) then
			if (craftingContents[recipe.Item3.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Tool ~= nil) then
			toolNeeded = recipe.Tool
			--TODO check inventory for tool . will be circular dependency so all this needs moved to inventory functions
			if(functions.HasItem(player,recipe.Tool)) then
				haveTool = true
			else	
				haveTool = false
			end
		end

		local craftingContentsCount = 0
		for _ in pairs(craftingContents) do
			craftingContentsCount = craftingContentsCount + 1
		end
		local currentNilSpots = totalPossibleFilledSlots-craftingContentsCount

		if (currentNilSpots ~= neededNilSpotsCount) then
			return nil,nil,nil
		end


		return recipeName,toolNeeded,haveTool

	end

	return nil,nil,nil
end

function functions.ClearCrafting(player)
	StatesFunctions.ClearCrafting(player)
	CraftingChangedEvent:FireClient(player,{},nil,nil,false)
end

function functions.CraftItem(player)
	--Find a complete recipe and craft it if it is complete
	local craftingContents = StatesFunctions.GetCrafting(player)
	local toolNeeded
	local haveTool = false

	local neededNilSpotsCount = 0
	local totalPossibleFilledSlots = 3

	for recipeName,recipe in pairs(Recipes.GetRecipes()) do
		neededNilSpotsCount = 0

		if (recipe.Item1 ~= nil) then			
			if (craftingContents[recipe.Item1.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item2 ~= nil) then
			if (craftingContents[recipe.Item2.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item3 ~= nil) then
			if (craftingContents[recipe.Item3.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Tool ~= nil) then
			toolNeeded = recipe.Tool
			--TODO check inventory for tool . will be circular dependency so all this needs moved to inventory functions
			if(functions.HasItem(player,recipe.Tool)) then
				haveTool = true
			else	
				haveTool = false
			end
		end

		local craftingContentsCount = 0
		for _ in pairs(craftingContents) do
			craftingContentsCount = craftingContentsCount + 1
		end
		local currentNilSpots = totalPossibleFilledSlots-craftingContentsCount

		if (currentNilSpots ~= neededNilSpotsCount) then
			return
		end

		--We got this far then we have everything for this recipe so craft it
		functions.ClearCrafting(player)

		--remove the amount needed from each item in inventory
		if (recipe.Item1 ~= nil) then
			functions.RemoveItem(player,recipe.Item1.Name,recipe.Item1.AmountNeeded)
		end
		if (recipe.Item2 ~= nil) then
			functions.RemoveItem(player,recipe.Item2.Name,recipe.Item2.AmountNeeded)
		end
		if (recipe.Item3 ~= nil) then
			functions.RemoveItem(player,recipe.Item3.Name,recipe.Item3.AmountNeeded)
		end

		functions.AddItem(player,recipeName,recipe.Amount)

		return

	end

	return
end

--COOKING FUNCTIONS
function functions.GetCookingItemBySlot(player,cookingSlot:string)

	for itemId,slotItem in pairs(StatesFunctions.GetCooking(player)) do

		if (tostring(slotItem.Slot) == tostring(cookingSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.DoesCookingContentsContainType(player, itemType)
	for itemId,item in pairs(StatesFunctions.GetCooking(player)) do
		if (functions.GetItemDef(itemId).SubType == itemType) then
			return item
		end
	end

	return nil
end

function functions.HasEverythingForCookingRecipe(player, recipeName)
	local cookingContents = StatesFunctions.GetCooking(player) -- Table of { [itemName] = {Amount = N}, ... }
	local recipes = CookingRecipes.GetRecipes()
	local recipe = recipes[recipeName]
	if not recipe then return false end

	local itemCounts = {}
	local typeCounts = {}

	-- Flatten the player's cooking contents into item and type totals
	for itemName, data in pairs(cookingContents) do
		itemCounts[itemName] = (itemCounts[itemName] or 0) + data.Amount

		local itemData = functions.GetItemDef(itemName)
		if itemData and itemData.SubType then
			local typeName = itemData.SubType
			typeCounts[typeName] = (typeCounts[typeName] or 0) + data.Amount
		end
	end

	-- Check all required ingredients
	for _, req in ipairs(recipe.Ingredients or {}) do
		if req.Item then
			local have = itemCounts[req.Item] or 0
			if have < req.Amount then
				return false
			end
		elseif req.Type then
			local have = typeCounts[req.Type] or 0
			if have < req.Amount then
				return false
			end
		end
	end

	return true
end

function functions.GetFullfilledCookingRecipe(player)

	local cookingContents = StatesFunctions.GetCooking(player)
	local toolNeeded
	local haveTool = false

	local neededNilSpotsCount = 0
	local totalPossibleFilledSlots = 4

	for recipeName,recipe in pairs(CookingRecipes.GetRecipes()) do
		neededNilSpotsCount = 0

		if (recipe.Item1 ~= nil) then

			if (cookingContents[recipe.Item1.Name] == nil) then
				continue
			end		

		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item2 ~= nil) then
			if (cookingContents[recipe.Item2.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item3 ~= nil) then
			if (cookingContents[recipe.Item3.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		if (recipe.Item4 ~= nil) then
			if (cookingContents[recipe.Item4.Name] == nil) then
				continue
			end
		else
			neededNilSpotsCount = neededNilSpotsCount + 1
		end

		local cookingContentsCount = 0
		for _ in pairs(cookingContents) do
			cookingContentsCount = cookingContentsCount + 1
		end
		local currentNilSpots = totalPossibleFilledSlots-cookingContentsCount

		if (currentNilSpots ~= neededNilSpotsCount) then
			continue --return nil,nil,nil
		end


		return recipeName

	end

	return nil,nil,nil
end

function functions.GetFullfilledCookingRecipe2(player)

	local itemCount = {}
	local typeCount = {}

	local cookingIngredients = StatesFunctions.GetCooking(player)

	print("TEST NEW COOKING cookingIngredients:",cookingIngredients)
	for itemName, item in pairs(cookingIngredients) do

		print("TEST NEW COOKING cookingIngredients item:",item)

		itemCount[itemName] = (itemCount[itemName] or 0) + item.Amount
		local itemType = functions.GetItemDef(itemName).IngredientType
		if itemType then
			typeCount[itemType] = (typeCount[itemType] or 0) + item.Amount 
		end
	end

	local bestMatch = nil
	local bestProgress = nil
	local bestMatchRatio = 0
	local isFullMatch = false

	for _, recipe in pairs(CookingRecipes.GetRecipes()) do
		local progress = {}
		local totalNeeded = 0
		local totalHave = 0
		local fullMatch = true

		for _, req in ipairs(recipe.Ingredients) do
			print("TEST NEW COOKING checking recipe:",recipe.Name,recipe.Ingredients)
			local have = 0
			local label = ""

			if req.Item then
				have = itemCount[req.Item] or 0
				label = req.Item
			elseif req.Type then
				have = typeCount[req.Type] or 0
				label = "Any " .. req.Type
			end

			table.insert(progress, {
				Label = label,
				Have = have,
				Need = req.Amount
			})

			if have < req.Amount then
				fullMatch = false
			end

			totalNeeded += req.Amount
			totalHave += math.min(have, req.Amount)
		end

		local matchRatio = totalHave / totalNeeded

		print("TEST NEW COOKING checking recipe:",fullMatch,matchRatio,bestMatchRatio)

		print("TEST NEW COOKING itemCount, typeCount:",itemCount,typeCount)
		if fullMatch or matchRatio > bestMatchRatio then
			bestMatch = recipe
			bestProgress = progress
			bestMatchRatio = matchRatio
			isFullMatch = fullMatch
		end
	end

	if bestMatch then
		print("TEST NEW COOKING GetFullfilledCookingRecipe2 bestMatch found:",bestMatch)
		return bestMatch, bestProgress, isFullMatch
	end

	print("TEST NEW COOKING GetFullfilledCookingRecipe2 returning Nil")
	return nil, nil, false
end

function functions.ClearCooking(player)
	StatesFunctions.ClearCooking(player)
	CookingChangedEvent:FireClient(player,{},nil,nil,false)

	local fryingPan = player.Character:FindFirstChild("FryingPan")

	if (not fryingPan) then
		return
	end
	for cookingItemName,cookingItem in pairs(fryingPan:GetChildren()) do
		if (cookingItem:IsA("MeshPart") and cookingItem:GetAttribute("Ingredient")) then
			cookingItem.Transparency = 1
		end
	end
end

function functions.SetupCooking(player,recipeName)

	if (not recipeName) then
		MessagePlayerEvent:FireClient("Cooking failed. Recipe missing")
		return
	end

	if ( not functions.HasEverythingForCookingRecipe(player,recipeName)) then
		MessagePlayerEvent:FireClient("Cooking failed. Missing ingredients while setting up cooking")
		functions.ClearCooking(player)
		return
	end

	local recipes = CookingRecipes.GetRecipes()
	local cookingRecipe = recipes[recipeName]

	if (cookingRecipe.RequiredItem == nil) then

		local cooked = functions.CookItem(player,recipeName,nil)

		if (cooked) then
			functions.AddItem(player,recipeName)
		end

		return
	else

	end


	--TODO place actual world items in frying pan and trigger heating
	local fryingPan = player.Character:FindFirstChild("FryingPan")

	if (not fryingPan) then
		functions.ClearCooking(player)
		return
	end

	local cookingContents = StatesFunctions.GetCooking(player)

	for cookingItemName,_ in pairs(cookingContents) do
		local cookingObject = fryingPan:FindFirstChild(cookingItemName)

		if (cookingObject) then
			cookingObject.Transparency = 0
		end

	end

	functions.CookItem(player,recipeName,fryingPan)

end

function functions.CookItem(player, recipeName, fryingPan)
	if not functions.HasEverythingForCookingRecipe(player, recipeName) then
		MessagePlayerEvent:FireClient(player, "Cooking failed. Missing ingredients while cooking item:",recipeName)
		functions.ClearCooking(player)
		return false
	end

	local recipes = CookingRecipes.GetRecipes()
	local recipe = recipes[recipeName]
	if not recipe then
		MessagePlayerEvent:FireClient(player, "Invalid recipe")
		return false
	end

	local cookingContents = StatesFunctions.GetCooking(player) -- e.g. {["Carrot"]={Amount=1}, ["Shiitake"]={Amount=2}}
	local itemsUsed = {} -- { ["Carrot"] = 1, ["Shiitake"] = 2 }

	-- Prepare type info
	local typeLookup = {}
	for itemName, _ in pairs(cookingContents) do
		local itemData = functions.GetItemDef(itemName)
		if itemData and itemData.SubType then
			typeLookup[itemName] = itemData.SubType
		end
	end

	-- Try to satisfy recipe requirements using what's in cookingContents
	for _, req in ipairs(recipe.Ingredients or {}) do
		local amountLeft = req.Amount

		if req.Item then
			if (cookingContents[req.Item] and cookingContents[req.Item].Amount >= amountLeft) then
				itemsUsed[req.Item] = (itemsUsed[req.Item] or 0) + amountLeft
			else
				MessagePlayerEvent:FireClient(player, "Cooking Failed (Missing " .. req.Item .. ")")
				return false
			end
		elseif req.Type then
			-- Search cookingContents for any item of the correct type
			for itemName, data in pairs(cookingContents) do
				if typeLookup[itemName] == req.Type and amountLeft > 0 then
					local take = math.min(amountLeft, data.Amount)
					itemsUsed[itemName] = (itemsUsed[itemName] or 0) + take
					amountLeft -= take
				end
			end
			if amountLeft > 0 then
				MessagePlayerEvent:FireClient(player, "Cooking Failed (Not enough " .. req.Type .. ")")
				return false
			end
		end
	end

	-- Actually remove those exact items
	for itemName, amount in pairs(itemsUsed) do
		local success = functions.RemoveItemFromAll(player, itemName, amount)
		if not success then
			MessagePlayerEvent:FireClient(player, "Cooking Failed (Inventory error)")
			return false
		end
	end

	if fryingPan then
		fryingPan:SetAttribute("RecipeName", recipeName)
		-- You can also do fryingPan:SetAttribute("Servings", recipe.Servings)
	end

	functions.ClearCooking(player)
	return true
end

function functions.GetTradingItemBySlot(player,tradingSlot:string)

	for itemId,slotItem in pairs(StatesFunctions.GetTrading(player).Items) do

		if (tostring(slotItem.Slot) == tostring(tradingSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end


function functions.RequestTrading(requestingPlayer,acceptingPlayer)
	StatesFunctions.SetRequestTrading(acceptingPlayer,requestingPlayer)
end


function functions.AcceptTrading(acceptingPlayer,requestingPlayer)
	StatesFunctions.SetAcceptTrading(acceptingPlayer,requestingPlayer)
end

function functions.MoveItemToTrading(player,itemId,tradingSlot,amount)		


	local tradingContents = StatesFunctions.GetTrading(player)

	if (not tradingContents.OtherPlayer) then
		return
	end

	if (not functions.GetItemDef(itemId) or not functions.GetItemDef(itemId).Trade) then
		MessagePlayerEvent:FireClient(player,"Cannot trade:"..itemId)
		return
	end


	if (not tradingSlot) then
		tradingSlot = 1
	end


	local newTradingItem = {}
	newTradingItem.Name = itemId
	newTradingItem.Slot = tonumber(tradingSlot)


	if (tradingContents.Items[itemId]) then
		--We have the same item so just add to it
		--TODO make sure this amount won't go over max
		newTradingItem.Amount = tradingContents.Items[itemId].Amount + amount
		newTradingItem.Slot = tradingContents.Items[itemId].Slot
		StatesFunctions.SetTradingItem(player,itemId,functions.DeepCopy(newTradingItem))

	else
		--The slot doesn't have the same item so overide whatever item is there or blank slot

		local itemToReplaceId,itemToReplace = functions.GetTradingItemBySlot(player,tradingSlot)

		if (itemToReplace) then
			StatesFunctions.SetTradingItem(player,itemToReplaceId,nil)
		end

		newTradingItem.Amount = amount
		StatesFunctions.SetTradingItem(player,itemId,functions.DeepCopy(newTradingItem))
	end
end

function functions.MoveItemToCrafting(player,itemId,craftingSlot,amount)		

	local craftingContents = StatesFunctions.GetCrafting(player)

	if (not craftingSlot) then
		craftingSlot = 1
	end


	local newCraftingItem = {}
	newCraftingItem.Name = itemId
	newCraftingItem.Slot = tonumber(craftingSlot)


	if (craftingContents[itemId] and craftingContents[itemId].Slot == tonumber(craftingSlot)) then
		--We have the same item so just add to it
		--TODO make sure this amount won't go over max
		newCraftingItem.Amount = craftingContents[itemId].Amount + amount
		StatesFunctions.SetCraftingItem(player,itemId,functions.DeepCopy(newCraftingItem))

	else
		--The slot doesn't have the same item so overide whatever item is there or blank slot

		local itemToReplaceId,itemToReplace = functions.GetCraftingItemBySlot(player,craftingSlot)

		if (itemToReplace) then
			craftingContents[itemToReplaceId] = nil
		end

		newCraftingItem.Amount = amount
		StatesFunctions.SetCraftingItem(player,itemId,functions.DeepCopy(newCraftingItem))
	end

	local fullfilledRecipe,toolNeeded,haveTool = functions.GetFullfilledRecipe(player)

	CraftingChangedEvent:FireClient(player,craftingContents,fullfilledRecipe,toolNeeded,haveTool)

end

function functions.MoveItemToCooking(player,itemId,cookingSlot,amount)		

	local cookingContents = StatesFunctions.GetCooking(player)

	if (not cookingSlot) then
		cookingSlot = 1
	end


	local newCookingItem = {}
	newCookingItem.Name = itemId
	newCookingItem.Slot = tonumber(cookingSlot)

	--For cooking we will just set the amount to max amount available in all player's containers
	local totalAmountAvailable = functions.GetItemTotal(player,itemId)

	if (cookingContents[itemId] and cookingContents[itemId].Slot == tonumber(cookingSlot)) then
		--We have the same item so just add to it
		--TODO make sure this amount won't go over max
		newCookingItem.Amount = totalAmountAvailable
		StatesFunctions.SetCookingItem(player,itemId,functions.DeepCopy(newCookingItem))

	else
		--The slot doesn't have the same item so overide whatever item is there or blank slot

		local itemToReplaceId,itemToReplace = functions.GetCookingItemBySlot(player,cookingSlot)

		if (itemToReplace) then
			cookingContents[itemToReplaceId] = nil
		end

		newCookingItem.Amount = totalAmountAvailable
		StatesFunctions.SetCookingItem(player,itemId,functions.DeepCopy(newCookingItem))
	end

	local fullfilledRecipe,progress,full = functions.GetFullfilledCookingRecipe2(player)

	if fullfilledRecipe then
		print("TEST NEW COOKING Matched Recipe:", fullfilledRecipe.Name)
		for _, p in ipairs(progress) do
			print(p.Label .. ": " .. p.Have .. "/" .. p.Need)
		end
		if full then
			print("TEST NEW COOKING Ready to Cook!")
			CookingChangedEvent:FireClient(player,cookingContents,fullfilledRecipe.Name)
		else
			print("TEST NEW COOKING More ingredients needed!")
			CookingChangedEvent:FireClient(player,cookingContents,nil)
		end
	else
		print("TEST NEW COOKING Custom Recipe")
		CookingChangedEvent:FireClient(player,cookingContents,nil)
	end



end

function functions.MoveItemToPower(player,itemId,amount)		

	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Inventory.Power = profile.Data.Inventory.Power + amount

	functions.RemoveItem(player,itemId,amount,true)

	UpdateInventoryUI(player)

end

function functions.GetSelling(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Selling"]) then
		return profile.Data.Inventory.Selling
	else
		return nil
	end 
end

function functions.UpdateSellingPrice(player,itemId,price)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Inventory["Selling"] and profile.Data.Inventory["Selling"][itemId]) then
		profile.Data.Inventory["Selling"][itemId].Price = price
		SellingChangedEvent:FireClient(player,"Update",player,profile.Data.Inventory["Selling"])
	end
end

function functions.RemoveSellingItem(player,itemId,amount)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (not profile.Data.Inventory["Selling"][itemId]) then
		return
	end

	if ((profile.Data.Inventory["Selling"][itemId].Amount - amount) <= 0) then
		profile.Data.Inventory["Selling"][itemId] = nil
	else
		profile.Data.Inventory["Selling"][itemId].Amount = profile.Data.Inventory["Selling"][itemId].Amount - amount

	end

end

function functions.BuyPlayersItem(player,storeOwner,itemId,totalPrice,amount)
	local storeOwnersItems = functions.GetSelling(storeOwner)

	if (not storeOwnersItems) then
		MessagePlayerEvent:FireClient(player,"Store temporarily unavailable")
		SellingChangedEvent:FireClient(player,"Update",storeOwner,storeOwnersItems)
		return
	end

	if (not storeOwnersItems[itemId]) then
		MessagePlayerEvent:FireClient(player,"Item no longer available")
		SellingChangedEvent:FireClient(player,"Update",storeOwner,storeOwnersItems)
		return
	end

	amount = tonumber(amount)
	local totalCost = tonumber(storeOwnersItems[itemId].Price) * amount

	if (totalCost ~= tonumber(totalPrice)) then
		MessagePlayerEvent:FireClient(player,"Price has changed")
		SellingChangedEvent:FireClient(player,"Update",storeOwner,storeOwnersItems)
		return
	end

	if (not functions.HasEnoughMoney(player,totalCost)) then
		MessagePlayerEvent:FireClient(player,"You do not have enough money")
		return
	end

	if (storeOwnersItems[itemId].Amount < amount) then
		MessagePlayerEvent:FireClient(player,"There is not enough of that item to buy "..amount)
		return
	end

	functions.RemoveMoney(player,totalCost)
	functions.AddMoney(storeOwner,totalCost)
	functions.RemoveSellingItem(storeOwner,itemId,amount)
	functions.AddItem(player,itemId,amount) --TODO if this fails then put in overflow

	local playerSellingItems = functions.GetSelling(player)
	storeOwnersItems = functions.GetSelling(storeOwner)
	SellingChangedEvent:FireClient(player,"Update",storeOwner,storeOwnersItems)
	SellingChangedEvent:FireClient(storeOwner,"Update",player,storeOwnersItems)


end

------NEW MORE GENERIC HANDLERS FOR ITEM MOVEMENT BETWEEN CONTAINERS AND BACKPACK

function functions.FindEmptyContainerSlot(player,itemId,destinationContainer,numberOfContainerSlots,targetInventorySection:string)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local emptySlots ={
		true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true
	}

	--profile.Data.Inventory["ItemSlots"][inventorySection]={SlotNumber=1,ItemName="Bat"}
	for _,slotItem in pairs(destinationContainer ) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)
		local inventorySection = ItemTypeToInventorySectionMap[slotItemDef.Type]

		if (targetInventorySection and (inventorySection ~= targetInventorySection)) then
			continue
		end

		if (not slotItem.Slot) then
			warn("DataInventoryFunctions.FindEmptySlot no slotItem.Slot found for item Name:",slotItem.Name)
			return nil
		end

		emptySlots[slotItem.Slot]=false
	end

	for slot,slotIsEmpty in pairs(emptySlots) do
		if (slotIsEmpty) then

			if (slot <= numberOfContainerSlots) then
				return slot
			else
				continue --return nil
			end

		end
	end

	return nil
end

function functions.AddItemToSuitcase(player,itemName,slot)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local newContainerItem = {}
	newContainerItem.Name = itemName
	newContainerItem.Amount = 1
	newContainerItem.Slot = slot

	local itemId = itemName

	if (functions.GetItemDef(itemName).SubType == "Container") then

		local numberOfItem = functions.NextContainerId(player)

		itemId = itemName.."_"..(numberOfItem+1)

		newContainerItem.Contains = functions.DeepCopy(functions.GetItemDef(itemName)["Contains"])

	end

	profile.Data.Inventory["Suitcase"].Contains[itemId] = functions.DeepCopy(newContainerItem)

end


function functions.GetContainerItemBySlot2(player,destinationContainer,destinationContainerSlot,targetInventorySection:string)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (not destinationContainer) then
		warn("DataInventoryFunctions.GetContainerItemBySlot2 destinationContainer nil")
		return nil,nil
	end

	for itemId,slotItem in pairs(destinationContainer) do

		local slotItemDef = functions.GetItemDef(slotItem.Name)
		local inventorySection = ItemTypeToInventorySectionMap[slotItemDef.Type]

		if (targetInventorySection and (inventorySection ~= targetInventorySection)) then
			continue
		end

		if (tostring(slotItem.Slot) == tostring(destinationContainerSlot)) then
			return itemId,slotItem
		end
	end

	return nil,nil
end

function functions.MoveItem(player,sourceContainerItemId,amount,fromArea,toArea,sourceContainerId,sourceSlot,destinationContainerId,destinationContainerSlot)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local sourceContainer = nil
	local destinationContainer = nil
	local destinationContainerAllowedToContain = "Solid" --Default to solid. all backpack,trading,crafting etc. (crafting may need to change)
	local destinationContainerCapacity = 0
	local destinationContainerCurrentAmount = 0
	local targetInventorySection = nil
	local removeTool = false

	--Is this contain drop area a container on a tool
	if (toArea == "Container" and functions.GetItemDef(destinationContainerId) and functions.GetItemDef(destinationContainerId).Type == "Tool") then
		toArea = "ToolContainer"
	end


	if (fromArea == "Backpack") then
		sourceContainer = profile.Data.Inventory["Items"]
	elseif (fromArea == "Weapon") or (fromArea == "OffHand") or (fromArea == "Accessory") or (fromArea == "Back") or (fromArea == "Head") then
		return functions.UnequipItem(player,sourceContainerItemId)
	elseif (fromArea == "Container") then

		if (profile.Data.Inventory["Items"][sourceContainerId]) then
			sourceContainer = profile.Data.Inventory["Items"][sourceContainerId].Contains
		else
			warn("DataInventoryFunctions.MoveItem container not found")
		end
	elseif (fromArea == "Suitcase") then

		if (profile.Data.Inventory["Suitcase"].Contains) then
			sourceContainer = profile.Data.Inventory["Suitcase"].Contains
		else
			warn("DataInventoryFunctions.MoveItem Suitcase not found")
		end	
	elseif (fromArea == "Overflow") then

		if (profile.Data.Inventory["Overflow"].Contains) then
			sourceContainer = profile.Data.Inventory["Overflow"].Contains
		else
			warn("DataInventoryFunctions.MoveItem Overflow not found")
		end	
	elseif (fromArea == "VacpacExtra") then

		if (profile.Data.Inventory["VacpacExtra"].Contains) then
			sourceContainer = profile.Data.Inventory["VacpacExtra"].Contains
		else
			warn("DataInventoryFunctions.MoveItem VacpacExtra not found")
		end	
	elseif (fromArea == "Toolbelt") then

		if (profile.Data.Inventory["Tools"]) then
			sourceContainer = profile.Data.Inventory["Tools"]
			removeTool = true
		else
			warn("DataInventoryFunctions.MoveItem Tools not found")
		end	
	elseif (fromArea == "TradingComplete") then

		local trading = StatesFunctions.GetTrading(player)

		sourceContainer = trading.Items
	end

	--Handle amount
	if (amount == -1) then
		--Move all of the item
		amount = sourceContainer[sourceContainerItemId].Amount
	end

	if (toArea == "Backpack") then
		destinationContainer = profile.Data.Inventory["Items"]
		local itemName = sourceContainer[sourceContainerItemId].Name
		itemName = functions.GetItemBaseName(itemName)
		
		local itemType = functions.GetItemDef(itemName).Type
		targetInventorySection = ItemTypeToInventorySectionMap[itemType] 
	elseif (toArea == "Container") then

		if (profile.Data.Inventory["Items"][destinationContainerId]) then

			if (profile.Data.Inventory["Items"][destinationContainerId].Contains == nil) then
				profile.Data.Inventory["Items"][destinationContainerId].Contains = {}
			end

			destinationContainer = profile.Data.Inventory["Items"][destinationContainerId].Contains
			destinationContainerAllowedToContain = functions.GetItemDef(profile.Data.Inventory["Items"][destinationContainerId].Name).AllowedToContain
			destinationContainerCapacity = functions.GetItemDef(profile.Data.Inventory["Items"][destinationContainerId].Name).Capacity
			destinationContainerCurrentAmount = functions.GetContainerTotalAmount(destinationContainer)
		else
			warn("DataInventoryFunctions.MoveItem Container toArea item not found")
		end
	elseif (toArea == "ToolContainer") then

		if (profile.Data.Inventory["Tools"][destinationContainerId]) then

			if (profile.Data.Inventory["Tools"][destinationContainerId].Contains == nil) then
				profile.Data.Inventory["Tools"][destinationContainerId].Contains = {}
			end

			destinationContainer = profile.Data.Inventory["Tools"][destinationContainerId].Contains
			destinationContainerAllowedToContain = functions.GetItemDef(profile.Data.Inventory["Tools"][destinationContainerId].Name).AllowedToContain
			destinationContainerCapacity = functions.GetItemDef(profile.Data.Inventory["Tools"][destinationContainerId].Name).Capacity
			destinationContainerCurrentAmount = functions.GetContainerTotalAmount(destinationContainer)
		else
			warn("DataInventoryFunctions.MoveItem Container toArea item not found")
		end
	elseif (toArea == "Suitcase") then

		if (profile.Data.Inventory["Suitcase"].Contains == nil) then
			profile.Data.Inventory["Suitcase"].Contains = {}
		end

		destinationContainer = profile.Data.Inventory["Suitcase"].Contains
	elseif (toArea == "VacpacExtra") then

		if (profile.Data.Inventory["VacpacExtra"].Contains == nil) then
			profile.Data.Inventory["VacpacExtra"].Contains = {}
		end

		destinationContainer = profile.Data.Inventory["VacpacExtra"].Contains
	elseif (toArea == "LostAndFound") then
		--Items are only added to lost and found when they are removed / thrown away and are no rarer than Common
	elseif (toArea == "Overflow") then

		--Cannot move to the overflow
		return
	end

	functions.MoveItem2(player,sourceContainerItemId,sourceContainer,sourceSlot,destinationContainer,destinationContainerSlot,amount,destinationContainerAllowedToContain,targetInventorySection,removeTool,destinationContainerCapacity,destinationContainerCurrentAmount)		

	if (fromArea == "TradingComplete") then
		StatesFunctions.UpdateTrading(player)
	end	
end

function functions.MoveItem2(player,sourceContainerItemId,sourceContainer,sourceSlot,destinationContainer,destinationContainerSlot,amount,destinationContainerAllowedToContain,targetInventorySection,removeTool,destinationContainerCapacity,destinationContainerCurrentAmount)		
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("TEST MOVE ITEM 2:",sourceContainerItemId,sourceContainer,sourceSlot,destinationContainer,destinationContainerSlot,amount,destinationContainerAllowedToContain,targetInventorySection,removeTool)

	if (sourceContainer == nil) then
		warn("DataInventoryFunctions-MoveItem sourceContainer nil")
		UpdateInventoryUI(player)
		return
	end

	if (destinationContainer == nil) then
		warn("DataInventoryFunctions-MoveItem destinationContainer nil")
		UpdateInventoryUI(player)
		return
	end

	--Check that the source container even has the item they are trying to move and amount they want to move
	if (sourceContainer[sourceContainerItemId] == nil) then
		warn("DataInventoryFunctions-MoveItem sourceContainer does not contain sourceContainerItemId")
		UpdateInventoryUI(player)
		return
	end

	--Check that the source container has enough of the item
	if (sourceContainer[sourceContainerItemId] and sourceContainer[sourceContainerItemId].Amount < amount) then
		warn("DataInventoryFunctions-MoveItem sourceContainer does not contain enough of sourceContainerItemId")
		UpdateInventoryUI(player)
		return
	end

	local item = sourceContainer[sourceContainerItemId]

	local itemName = functions.GetItemBaseName(item.Name)

	--Check that container can take this type of item or specifically this item (like as in RussianDolls)
	if (destinationContainerAllowedToContain and (destinationContainerAllowedToContain ~= functions.GetItemDef(itemName).NeedToContain) and (destinationContainerAllowedToContain ~= item.Name)) then
		MessagePlayerEvent:FireClient(player,"Must have a container that can hold: "..functions.GetItemDef(itemName).NeedToContain)
		UpdateInventoryUI(player)
		return
	end

	if (destinationContainerCapacity > 0 ) and ((amount + destinationContainerCurrentAmount) > destinationContainerCapacity) then
		MessagePlayerEvent:FireClient(player,"Container cannot hold that much more")
		UpdateInventoryUI(player)
		return
	end

	if (amount == nil) then
		amount = 1
	end

	--If source container and destination container are same just switch whole stack slots
	if (sourceContainer == destinationContainer) then
		local itemToReplaceId,itemToReplace = functions.GetContainerItemBySlot2(player,destinationContainer,destinationContainerSlot,targetInventorySection)

		if (itemToReplace) then
			itemToReplace.Slot = tonumber(sourceSlot)
			sourceContainer[sourceContainerItemId].Slot = destinationContainerSlot
		else 
			sourceContainer[sourceContainerItemId].Slot = destinationContainerSlot
		end

		UpdateInventoryUI(player)
		return
	end

	--1. We have this item in some slot. Add to the amount and for the slot of the current existing item
	--2. We don't have this item at all. Add to target slot
	--3. There is an existing different item. Move it back to backpack and set this one in target slot

	if (destinationContainer[sourceContainerItemId]) then -- and profile.Data.Inventory["Items"][containerId].Contains[itemId].Slot == tonumber(containerSlot)
		--We have the same item so just add to it

		local newContainerItem = {}
		newContainerItem.Name = item.Name
		newContainerItem.Amount = destinationContainer[sourceContainerItemId].Amount + amount

		--Add in the slot that has the same item
		newContainerItem.Slot = destinationContainer[sourceContainerItemId].Slot

		--Make sure we move all inner contents of a container that is being moved as well
		if (functions.GetItemDef(itemName).SubType == "Container") then
			if (item["Contains"] and item["Contains"] ~= nil) then
				newContainerItem.Contains = functions.DeepCopy(item["Contains"])
			else
				newContainerItem.Contains = {}
			end	
		end

		if (functions.GetItemDef(itemName).Type == "Weapon") then
			newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(itemName)["WeaponAttacks"])
		end

		destinationContainer[sourceContainerItemId] = functions.DeepCopy(newContainerItem)

		--Are we moving all of this item
		if (sourceContainer[sourceContainerItemId].Amount == amount) then
			if (removeTool) then
				functions.RemoveTool(player,sourceContainerItemId)
			else
				sourceContainer[sourceContainerItemId] = nil
			end
		else
			sourceContainer[sourceContainerItemId].Amount -= amount
		end

	else

		--The slot doesn't have the same item but does it have a different item
		local itemToReplaceId,itemToReplace = functions.GetContainerItemBySlot2(player,destinationContainer,destinationContainerSlot,targetInventorySection)

		if (itemToReplace) then

			local amountToReplace = destinationContainer[itemToReplaceId].Amount


			--TODO First see if we can move this item to another slot in same container
			local emptySlot = functions.FindEmptyContainerSlot(player,itemToReplaceId,destinationContainer,16,targetInventorySection)

			if (emptySlot) then
				local newContainerItem = {}
				newContainerItem.Name = itemToReplace.Name
				newContainerItem.Slot = tonumber(emptySlot)
				newContainerItem.Amount = amountToReplace

				--Make sure we move all inner contents of a container that is being moved as well
				if (functions.GetItemDef(itemToReplace.Name).SubType == "Container") then
					if (itemToReplace["Contains"] and itemToReplace["Contains"] ~= nil) then
						newContainerItem.Contains = functions.DeepCopy(itemToReplace["Contains"])
					else
						newContainerItem.Contains = {}
					end	
				end

				if (functions.GetItemDef(itemName).Type == "Weapon") then
					newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(itemName)["WeaponAttacks"])
				end

				destinationContainer[itemToReplaceId] = functions.DeepCopy(newContainerItem)

			else
				--Move item replacing to overflow
				local slot = functions.FindEmptyOverflowContainerSlot(player,itemToReplaceId)
				if (slot) then
					destinationContainer[itemToReplaceId] = nil

					functions.AddItemToOverflowContainer(player,itemToReplaceId,itemToReplace.Name,amountToReplace,itemToReplace)
				else
					MessagePlayerEvent:FireClient(player,"Overflow Container is full. Items would be lost")
					return
				end
			end

		end

		local newContainerItem = {}
		newContainerItem.Name = item.Name
		newContainerItem.Slot = tonumber(destinationContainerSlot)
		newContainerItem.Amount = amount

		--Make sure we move all inner contents of a container that is being moved as well
		if (functions.GetItemDef(itemName).SubType == "Container") then
			if (item["Contains"] and item["Contains"] ~= nil) then
				newContainerItem.Contains = functions.DeepCopy(item["Contains"])
			else
				newContainerItem.Contains = {}
			end	
		end

		if (functions.GetItemDef(item.Name).Type == "Weapon") then
			newContainerItem.WeaponAttacks = functions.DeepCopy(functions.GetItemDef(itemName)["WeaponAttacks"])
		end

		destinationContainer[sourceContainerItemId] = functions.DeepCopy(newContainerItem)

		--Are we moving all of this item
		if (sourceContainer[sourceContainerItemId].Amount == amount) then
			if (removeTool) then
				functions.RemoveTool(player,sourceContainerItemId)
			else
				sourceContainer[sourceContainerItemId] = nil
			end
		else
			sourceContainer[sourceContainerItemId].Amount -= amount
		end

	end

	InventoryItemChangedEvent:Fire(player,sourceContainerItemId,amount)

	UpdateInventoryUI(player)

end

return functions