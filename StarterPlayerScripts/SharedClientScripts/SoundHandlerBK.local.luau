local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSoundEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlaySound")

playSoundEvent.OnClientEvent:Connect(function()
	
end)