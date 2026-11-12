local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)


local balloon = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("balloon")

local function HandleTakeItem(promptObject, player)
	if (promptObject:GetAttribute("RemoveItem"))  then
		local object = promptObject.Parent
		object:Destroy()
	end

	local effect = nil
	local item = promptObject:GetAttribute("Item")
	if (item ~= nil) then
		InventoryFunctions.AddItem(player,item)
		--MessagePlayerEvent:FireClient(player,"Got the "..item,item)

		local effect = promptObject:GetAttribute("Effect")

		if (effect ~= nil) then
			EffectsFunctions.AddEffect(player,effect,1)
		end

	else
		warn("TakeItemHandler TakeItem prompt without Item Attribute:",promptObject)
	end
end

local function HandleBalloonPlacement(promptObject, player)
	local item = balloon:Clone()

	item.RopeConstraint.Attachment1 = promptObject.Parent
	item.PrimaryPart.Position = Vector3.new(promptObject.Parent.WorldPosition.X,promptObject.Parent.WorldPosition.Y+2,promptObject.Parent.WorldPosition.Z)
	item.Parent = workspace
end

local function HandlePoisonGasBalloonPlacement(promptObject, player)
	local item = balloon:Clone()
	
	item.PrimaryPart:SetAttribute("HitEffect_PoisonGas",true)

	item.RopeConstraint.Attachment1 = promptObject.Parent
	item.PrimaryPart.Position = Vector3.new(promptObject.Parent.WorldPosition.X,promptObject.Parent.WorldPosition.Y+2,promptObject.Parent.WorldPosition.Z)
	item.Parent = workspace
end

local function HandlePlaceItem(promptObject, player)
	local heldToolName = StatesFunctions.GetCurrentTool(player)

	if (heldToolName == "Balloon") then
		HandleBalloonPlacement(promptObject, player)
	elseif (heldToolName == "PoisonGasBalloon") then
		HandlePoisonGasBalloonPlacement(promptObject, player)
	end
	
end

local function HandleTakeAmmo(promptObject, player)
	local ammoId = promptObject:GetAttribute("ammo")
	local amount = promptObject:GetAttribute("amount")
	
	if (ammoId and amount) then
		InventoryFunctions.AddItem(player,ammoId,amount)
	end
	
end

local function HandleDispenser(promptObject)
	local amount = promptObject:GetAttribute("Amount")
	if (amount and amount > 0) then

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

local function HandleTakeItemForContainer(promptObject,player)
	
	local newContainerItem = {}
	newContainerItem.Name = promptObject:GetAttribute("Item")
	newContainerItem.Amount = 1
	if(InventoryFunctions.AddItemToOverflowContainer(player,newContainerItem.Name,newContainerItem.Name,1,newContainerItem)) then
		HandleDispenser(promptObject)
	end
end

local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "TakeItem") or (promptObject.Name == "TakeOneItem")  then
		HandleTakeItem(promptObject, player)
		return
	elseif (promptObject.Name == "PlaceItem") then
		HandlePlaceItem(promptObject, player)
		return
	elseif (promptObject.Name == "TakeAmmo") then
		HandleTakeAmmo(promptObject,player)
		return		
	elseif (promptObject.Name == "TakeItemForContainer") then
		HandleTakeItemForContainer(promptObject,player)
		return		
	end
	
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)