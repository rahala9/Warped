local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReadInscriptionEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ReadInscription")


local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Name ~= "ReadInscription") then
		return
	end
	
	ReadInscriptionEvent:FireClient(player,promptObject:GetAttribute("Inscription"))
	
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)


