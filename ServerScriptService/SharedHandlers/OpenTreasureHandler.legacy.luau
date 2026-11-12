local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local QuestsDef = require(ServerScriptService.Data.Templates.Quests)
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)
local ProximityPromptService = game:GetService("ProximityPromptService")


--Handle all proximity quest targets like for Put or Search type quests
local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Name ~= "OpenTreasure") then
		return
	end
	
	if (promptObject.Parent:GetAttribute("TreasureRarity") ~= nil) then
			
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
