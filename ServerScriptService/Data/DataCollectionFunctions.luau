--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions

--Definition Modules
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)



local functions = {}

local collections ={
	["Mushrooms"]={
		Total=11
	},
	["PhoneNumbers"]={
		Total=7
	},
	["TradingCards"]={
		Total=3
	},
	["KeyChains"]={
		Total=4
	},
}

function functions.GetCollections(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Collections

end


function functions.IsCollectionComplete(player,collectionName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--Loop through collection items and see if item is set to true in Collections
	for _,collectionItem in itemsmodule do
		--if (collectionItem.Type ~= "Collection") then
		--	continue
		--end

		if (collectionItem["Collection"] == nil) then
			continue
		end


		if (collectionItem.Collection == collectionName) then
			if ((profile.Data.Collections[collectionName] == nil) or (profile.Data.Collections[collectionName][collectionItem.Name] ~= true) ) then
				return false
			end
		end
	end

	return true

	--See if this was part of quest and if is complete then call to handle quest
end

function functions.Collect(player,itemName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local collectionItemName = itemName
	local collectionName = itemsmodule[collectionItemName].Collection

	if (not collectionName) then
		return
	end

	if (not collections[collectionName]) then
		return
	end

	if (not profile.Data.Collections[collectionName]) then
		profile.Data.Collections[collectionName]={}
	end

	if (not profile.Data.Collections[collectionName][collectionItemName]) then
		local current = 0
		for _ in pairs(profile.Data.Collections[collectionName]) do
			current = current + 1
		end
		current = current + 1  -- Add 1 for the new item being added

		local total = collections[collectionName].Total
		--message,requiredItemName,keepOn,posX,posY,textColor,fadeTime
		MessagePlayerEvent:FireClient(player,itemsmodule[itemName].DisplayName.." added to "..collectionName.." collection "..current.."/"..total,itemName,nil,nil,nil,nil,5)

		if(functions.IsCollectionComplete(player,collectionName)) then
			MessagePlayerEvent:FireClient(player,"You completed the "..collectionName.." collection!",itemName,nil,nil,nil,nil,5)
		end

	end

	profile.Data.Collections[collectionName][collectionItemName] = true

end

return functions