local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestService = require(script.Parent.Parent.QuestSystem.QuestService)
local DialogService = require(script.Parent.DialogService)
local ProximityPromptService = game:GetService("ProximityPromptService")
local DialogRemotes = require(ReplicatedStorage.SharedModules.Dialog:WaitForChild("DialogRemotes"))

DialogRemotes.Init()
DialogService:Init(QuestService)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "TalkToNPC" then
		DialogService:RequestDialog(player, prompt:GetAttribute("NPCName"))
	end
end)