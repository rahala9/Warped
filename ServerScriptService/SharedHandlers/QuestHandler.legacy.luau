local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local QuestsDef = require(ServerScriptService.Data.Templates.Quests)
local GetHoverText = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetHoverText")
local GetQuests = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetQuests")
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)
local ProximityPromptService = game:GetService("ProximityPromptService")
local TrackQuestEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TrackQuest")
local InventoryItemChangedEvent = game.ServerStorage:WaitForChild("InventorySystem"):WaitForChild("InventoryItemChanged")	
local RemoveQuestEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveQuest")

RemoveQuestEvent.Event:Connect(function(player,questName)

	if (not QuestFunctions.IsQuestComplete(player,questName)) then
		QuestFunctions.RemoveQuest(player,questName)
	end

end)

GetHoverText.OnServerInvoke = function(player,modelName)
	if (QuestsDef[player.Name] == nil) then
		return
	end
	
	local quest,quest_step = QuestFunctions.GetObjectQuestStep(player,modelName)
	if (quest_step ~= nil) then
		if (InventoryFunctions.CheckItem(player,quest_step.Object,quest_step.Amount)) then
			return {Text="Quest: "..quest.Name.." put "..quest_step.Amount.." "..quest_step.Object, Color = Color3.new(.5, 1, .5)}
		else
			return {Text="Quest: "..quest.Name.." put "..quest_step.Amount.." "..quest_step.Object, Color = Color3.new(1, .5, .5)}
		end
	end
		
	return nil
end

GetQuests.OnServerInvoke = function(player,typeQuest)
	
	if (typeQuest == "PlayerQuests") then
		return QuestFunctions.GetQuests(player)
	elseif (typeQuest == "AvailableQuests") then
		return QuestFunctions.GetPlayerAvailableQuests(player)
	end
	
	return nil
end

TrackQuestEvent.OnServerEvent:Connect(function(player,questName)
	QuestFunctions.ToggleTracked(player,questName)
end)

--Handle all proximity quest targets like for Put or Search type quests
local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Parent == nil) then
		return
	end
	
	if (promptObject:GetAttribute("QuestTarget")) then
		QuestFunctions.HandleQuest(player,promptObject)
	elseif (promptObject.Parent:GetAttribute("QuestTrigger") ~= nil) then
		QuestFunctions.HandleQuestTrigger(player,promptObject)
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)


InventoryItemChangedEvent.Event:Connect(function(player,inventoryItem,amount)
	QuestFunctions.UpdateQuestStepAmount(player,inventoryItem,amount)
end)

