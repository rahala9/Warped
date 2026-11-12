local ServerScriptService = game:GetService("ServerScriptService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local DialogFunctions = require(ServerScriptService.SharedFunctions.DialogFunctions)

local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Name == "TalkTo") then
		local NPC = promptObject.Parent.Parent.Name
		DialogFunctions.HandleDialog(player,NPC)
	end	

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
