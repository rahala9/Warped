local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReadNoteEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ReadNote")


local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Name ~= "ReadNote") then
		return
	end
	
	ReadNoteEvent:FireClient(player,promptObject:GetAttribute("Note"))
	
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)


