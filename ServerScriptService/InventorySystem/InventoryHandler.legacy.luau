--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--Remote Events
local AddToolEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AddTool")
local EquipItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("EquipItem")
local RemoveItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveItem")
local MoveItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MoveItem")
local TradingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TradingChanged")
local sendinv = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SendInv")
local ConsumeItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ConsumeItem")
local hasItem = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("HasItem")
local CraftItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CraftItem")
local CookItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CookItem")
local TradeCompleteEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TradeComplete")
local SellingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SellingChanged")
local RemoveItemFromServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveItemFromServer")
local UpdateClientInventoryUIEvent = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("UpdateClientInventoryUI")

--Functions
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets

--Modules


RemoveItemFromServerEvent.Event:Connect(function(player,itemId)
	
	if (InventoryFunctions.HasWeaponEquipped(player,itemId)) then
		InventoryFunctions.UnequipItem(player,itemId)
	end
	
	InventoryFunctions.RemoveItem(player,itemId)

end)
local Players = game:GetService("Players")

local function UpdateInventoryUI(player)
	--Logger.Debug("InventoryHandler UpdateInventoryUI sendinv:FireClient")
	sendinv:FireClient(player)
end

UpdateClientInventoryUIEvent.OnServerEvent:Connect(function(player)
	--Logger.Debug("replicatedStorage.UpdateClient.OnServerEvent UpdateInventoryUI")
	UpdateInventoryUI(player)
end)

--Update players inventory on join/death
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid").Died:Connect(function()
			player.CharacterAdded:Wait()

			UpdateInventoryUI(player)	
		end)
	end)
end)

--Player clicked on an Item
--SECURITY ISSUE.  Removed this.  TODO need to have dropped items get a proximity detector that is handled server side.
--AddItemEvent.OnServerEvent:Connect(function(player,item)
--		InventoryFunctions.AddItem(player,item.Name)
--		item:Destroy()
--end)

--Player chose to drop item
--DropItemEvent.OnServerEvent:Connect(function(player,itemname)
	
--	InventoryFunctions.DropItem(player,itemname)

--end)

ConsumeItemEvent.OnServerEvent:Connect(function(player,itemId)

	InventoryFunctions.ConsumeItem(player,itemId)

end)

print("InventoryHandler started")
EquipItemEvent.OnServerEvent:Connect(function(player,itemname,unequip)
	
	print("TEST DRAGG Server Received EquipItem request: itemname:",itemname)
	if (unequip) then
		InventoryFunctions.UnequipItem(player,itemname)
	else
		print("TEST DRAGG Server Calling EquipItem request: itemname:",itemname)
		InventoryFunctions.EquipItem(player,itemname)
	end
	

end)
print("InventoryHandler hooked EquipItemEvent")

RemoveItemEvent.OnServerEvent:Connect(function(player,itemId,containerId,fromArea,removeAmount)
	print("TEST ITEM REMOVAL RemoveItemEvent.OnServerEvent itemId:",itemId," containerId:",containerId," fromArea:",containerId,fromArea," removeAmount:",removeAmount)
	if (containerId) then
		InventoryFunctions.RemoveItemFromContainer(player,containerId,itemId,removeAmount)
	elseif (fromArea == "Overflow")	 then
		InventoryFunctions.RemoveItemFromOverflow(player,itemId)
	else
		InventoryFunctions.RemoveItem(player,itemId,removeAmount)
	end
	
end)

local function GetItems(player)

	return InventoryFunctions.GetItems(player)
end

game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory").OnServerInvoke = function(player)
	return InventoryFunctions.GetInventory(player)
end

AddToolEvent.OnServerEvent:Connect(function(player,item,slotOnToolbelt:string)
	
	InventoryFunctions.MoveItemToToolbelt(player,item,slotOnToolbelt)			
end)

MoveItemEvent.OnServerEvent:Connect(function(player,action,sourceContainerItemId,amount,fromArea,toArea,sourceContainerId,sourceSlot:number,destinationContainerId,destinationContainerSlot:number)
	
	--Data integrity conversations
	amount = tonumber(amount)
	sourceSlot = tonumber(sourceSlot)
	destinationContainerSlot = tonumber(destinationContainerSlot)
	
	if (action == "MoveItem") then
		--Logger.Debug("TEST OVERFLOWERROR:",sourceContainerItemId,amount,fromArea,toArea,sourceContainerId,sourceSlot,destinationContainerId,destinationContainerSlot)
		InventoryFunctions.MoveItem(player,sourceContainerItemId,amount,fromArea,toArea,sourceContainerId,sourceSlot,destinationContainerId,destinationContainerSlot)	
	elseif (action == "ToCrafting") then
		InventoryFunctions.MoveItemToCrafting(player,sourceContainerItemId,destinationContainerSlot,amount)
	elseif (action == "ToPower") then
		InventoryFunctions.MoveItemToPower(player,sourceContainerItemId,amount)
	elseif (action == "ToCooking") then
		InventoryFunctions.MoveItemToCooking(player,sourceContainerItemId,destinationContainerSlot,amount)
	elseif (action == "ToTrading") then
		InventoryFunctions.MoveItemToTrading(player,sourceContainerItemId,destinationContainerSlot,amount)	
	elseif (action == "ToSelling") then
		InventoryFunctions.MoveItemToSelling(player,sourceContainerItemId,destinationContainerSlot,amount)	
	elseif (action == "ToTackleBox") then
		InventoryFunctions.MoveItemToTackleBox(player,sourceContainerItemId,destinationContainerSlot,amount)	
	elseif (action == "ToWallet") then
		if (InventoryFunctions.HasItem(player,sourceContainerItemId)) then
			local walletItem = InventoryFunctions.GetItem(player,sourceContainerItemId)
			if (tostring(walletItem.Slot) == tostring(sourceSlot)) then
				InventoryFunctions.AddMoney(player,itemsmodule[sourceContainerItemId].Value)
				InventoryFunctions.RemoveItem(player,sourceContainerItemId,1,true)
			end
		end

	else
		warn("InventoryHandler.MoveItemEvent Event Handler No Action found for:",action)
	end		
end)

TradingChangedEvent.OnServerEvent:Connect(function(player,action,otherPlayer,money)
	if (action == "Request") then
		StatesFunctions.SetRequestTrading(player,otherPlayer)
	elseif (action == "AcceptRequest") then
		StatesFunctions.AcceptTrading(player,otherPlayer)
	elseif (action == "DeclineRequest") then
		StatesFunctions.DeclineTrading(player,otherPlayer)
	elseif (action == "CancelTrade") then
		StatesFunctions.CancelTrading(player)
	elseif (action == "MoneyUpdate") then
		StatesFunctions.MoneyUpdate(player,money)
	elseif (action == "AcceptTrade") then
		StatesFunctions.AcceptTrade(player,true)		--InventoryFunctions.AddMoney(player,States[otherPlayer.Name].Trading.Money)
		--InventoryFunctions.AddMoney(otherPlayer,States[player.Name].Trading.Money)
	elseif (action == "UnAcceptTrade") then
		StatesFunctions.AcceptTrade(player,false)
	elseif (action == "ClearTrading") then
		StatesFunctions.ClearTrading(player)
	else
		warn("InventoryHandler.TradingChangedEvent Event Handler No Action found for:",action)
	end		
end)

SellingChangedEvent.OnServerEvent:Connect(function(player,action,storeOwnerName,itemId,price,amount)
	local storeOwner = nil

	if (storeOwnerName and Players[storeOwnerName]) then
		storeOwner = Players[storeOwnerName]
	end
	
	if (action == "Open") then
		
		local storeItems = InventoryFunctions.GetSelling(storeOwner)
		
		if (not storeOwner) then
			return
		end
		
		SellingChangedEvent:FireClient(player,"Open",storeOwner,storeItems)
	elseif (action == "UpdatePrice") then
		InventoryFunctions.UpdateSellingPrice(player,itemId,price)
	elseif (action == "Buy") then
		InventoryFunctions.BuyPlayersItem(player,storeOwner,itemId,price,amount)
	else
		warn("InventoryHandler.SellingChangedEvent Event Handler No Action found for:",action)
	end		
end)

CraftItemEvent.OnServerEvent:Connect(function(player,action)
	if (action == "Clear") then
		InventoryFunctions.ClearCrafting(player)
	elseif (action == "Craft") then
		InventoryFunctions.CraftItem(player)
	end
		
end)

CookItemEvent.OnServerEvent:Connect(function(player,action,arg1)
	if (action == "Clear") then
		InventoryFunctions.ClearCooking(player)
	elseif (action == "SetupCooking") then
		InventoryFunctions.SetupCooking(player,arg1)
	elseif (action == "Cook") then
		InventoryFunctions.CookItem(player,arg1)
	end

end)



TradeCompleteEvent.Event:Connect(function(player,otherPlayer,playerMoney,otherPlayerMoney,playersItemsToRemove,otherPlayersItemsToRemove)
	InventoryFunctions.AddMoney(player,otherPlayerMoney)
	InventoryFunctions.AddMoney(otherPlayer,playerMoney)
	InventoryFunctions.RemoveMoney(player,playerMoney)
	InventoryFunctions.RemoveMoney(otherPlayer,otherPlayerMoney)
	
	for itemId,item in pairs(playersItemsToRemove) do
		InventoryFunctions.RemoveItem(player,itemId,item.Amount)
	end
	
	for itemId,item in pairs(otherPlayersItemsToRemove) do
		InventoryFunctions.RemoveItem(otherPlayer,itemId,item.Amount)
	end
	
end)



hasItem.OnServerInvoke = function(player,itemName)
	return InventoryFunctions.HasItem(player,itemName,1,true,true)
end
