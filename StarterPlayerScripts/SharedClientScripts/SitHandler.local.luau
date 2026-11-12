local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local SitEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Sit")
local SitServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SitServer")

local LocalPlayer = Players.LocalPlayer

local function setPromptUiState(prompt, occupied)
	if prompt.Name == "Sit" then
		prompt.ActionText = occupied and "Stand" or "Sit"
		--prompt.KeyboardKeyCode = occupied and Enum.KeyCode.Q or Enum.KeyCode.E
	elseif prompt.Name == "Sleep" then
		prompt.ActionText = occupied and "Wake" or "Sleep"
	end
end

local function onPromptTriggered(promptObject, player)
	if player ~= LocalPlayer then
		return
	end

	if promptObject.Name ~= "Sit" and promptObject.Name ~= "Sleep" then
		return
	end

	-- Let the server own the true state; client just mirrors expected UI.
	local owner = promptObject:GetAttribute("Owner")
	local occupiedByLocalPlayer = (owner == LocalPlayer.Name)

	-- Because PromptTriggered fires before replication settles sometimes,
	-- flip to the expected next state locally for responsiveness.
	setPromptUiState(promptObject, not occupiedByLocalPlayer)
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

SitServerEvent.OnClientEvent:Connect(function(animationName)
	SitEvent:Fire(animationName)
end)