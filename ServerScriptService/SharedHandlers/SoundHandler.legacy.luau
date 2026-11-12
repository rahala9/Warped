--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local PlaySoundEvent = SharedRemotes:WaitForChild("PlaySound")

--Assets

PlaySoundEvent.OnServerEvent:Connect(function(player,soundId, parent, playAllClients, volume, maxDistance)
	
	if (playAllClients) then
		PlaySoundEvent:FireAllClients(soundId, parent, volume, maxDistance)
	end
	
end)
