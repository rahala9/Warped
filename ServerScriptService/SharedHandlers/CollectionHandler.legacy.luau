local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionFunctions = require(ServerScriptService.Data.DataCollectionFunctions)
local ProximityPromptService = game:GetService("ProximityPromptService")
local GetCollections = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetCollections")

--Handle all proximity collection
local function onPromptTriggered(promptObject, player)
	
	if (promptObject:GetAttribute("CollectionItem")) then
		CollectionFunctions.Collect(player,promptObject:GetAttribute("CollectionItem"))
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

GetCollections.OnServerInvoke = function(player)
	
	return CollectionFunctions.GetCollections(player)
	
end

