local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)

local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "OpenMailbox") then
		MessagePlayerEvent:FireClient(player,"HEY THAT'S ILLEGAL!")
	elseif (promptObject.Name == "OpenYourMailbox") then
		--TODO check for any mail left by anybody or NPC
	end
	
	
	
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)