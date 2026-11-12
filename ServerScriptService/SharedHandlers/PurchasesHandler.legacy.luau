local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ProximityPromptService = game:GetService("ProximityPromptService")
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local buyRequest = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("BuyGamePassOrSubscription")
local buyItemEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("BuyItem")
local GamePassFunctions = require(ServerScriptService.Data.DataGamePassFunctions)
local SubscriptionFunctions = require(ServerScriptService.Data.DataSubscriptionFunctions)
local gumsballsLoot = require(ReplicatedStorage:WaitForChild("Loot"):WaitForChild("GumballsLoot"))
local Debris = game:GetService("Debris")

local R = Random.new(os.time())

local function GetRandomItem(weightedItems)
	local sum = 0
	for _,v in pairs(weightedItems) do
		sum = sum + v.Rarity
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(weightedItems) do
		rand = rand - v.Rarity
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

local function HandleDispenser(promptObject)
	local amount = promptObject:GetAttribute("Amount")
	if (amount) then

		amount = amount -1

		promptObject:SetAttribute("Amount",amount)

		if (amount <= 0) then
			promptObject.Enabled = false
			promptObject.Parent.Transparency = 1
			for _, childItem in ipairs(promptObject.Parent:GetDescendants()) do

				if childItem:IsA('BasePart') or childItem:IsA('MeshPart') or childItem:IsA('Texture')  then
					childItem.Transparency = 1					
				end
			end

		end

	end
end

buyItemEvent.OnServerEvent:Connect(function(player,itemName)
	InventoryFunctions.BuyItem(player,itemName)
end)

local function onPromptTriggered(promptObject, player)
	if (promptObject.Name == "AddToCart") then
		
		if (promptObject.Enabled == false) or (promptObject:GetAttribute("Amount") and promptObject:GetAttribute("Amount") == 0) then
			return
		end
		
		if(InventoryFunctions.AddItemToCart(player,promptObject:GetAttribute("Item"))) then
			HandleDispenser(promptObject)
		end
		
	elseif (promptObject.Name == "BuyItem") then
		
		if (promptObject:GetAttribute("RemoveItem")) then
			if (promptObject.Parent.Parent:IsA("Model")) then
				Debris:AddItem(promptObject.Parent.Parent,1)
			else
				Debris:AddItem(promptObject.Parent,1)
			end
		end
		
		if (InventoryFunctions.BuyItem(player,promptObject:GetAttribute("Item"))) then
			
			HandleDispenser(promptObject)
		end	
		
	elseif (promptObject.Name == "BuyItemForContainer") then

		if (InventoryFunctions.BuyItemForContainer(player,promptObject:GetAttribute("Item"),promptObject:GetAttribute("BuyAmount"))) then
			HandleDispenser(promptObject)
		end	
		
	elseif (promptObject.Name == "BuyGumball") then
		
		--TODO randomly pick gumball weighted by rarity
		
		local gumball = GetRandomItem(gumsballsLoot)
		
		InventoryFunctions.BuyItem(player,gumball.Name)		
	

	elseif (promptObject.Name == "Give10DollarTip") then

		game:GetService("MarketplaceService"):PromptProductPurchase(player, "1928722222")
	elseif (promptObject.Name == "Give50DollarTip") then

		game:GetService("MarketplaceService"):PromptProductPurchase(player, "1928723019")
	elseif (promptObject.Name == "Give100DollarTip") then

		game:GetService("MarketplaceService"):PromptProductPurchase(player, "1928723303")
	elseif (promptObject.Name == "Give300DollarTip") then

		game:GetService("MarketplaceService"):PromptProductPurchase(player, "1928723668")

	elseif (promptObject.Name == "BuyGamepass") then

		local itemName = promptObject.Parent.Name

		if (itemsmodule[itemName].ProductId ~= nil) then
			GamePassFunctions.HandleGamePass(player,itemsmodule[itemName].ProductId)
		end
	end
	

end


buyRequest.OnServerInvoke = function(player,gamepassId,subscriptionId)
	
	if (gamepassId) then
		GamePassFunctions.HandleGamePass(player,gamepassId)
	elseif(subscriptionId) then
		SubscriptionFunctions.HandleSubscription(player,subscriptionId)
	end
	
	return true --TODO return actual from Handle functions

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

