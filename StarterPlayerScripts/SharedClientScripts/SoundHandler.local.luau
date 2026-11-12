--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local PlaySoundEvent = SharedRemotes:WaitForChild("PlaySound")

--Assets
local Sounds = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Sounds")

PlaySoundEvent.OnClientEvent:Connect(function(soundId, parent, volume, maxDistance)

	if not parent or not parent.Parent then return end

	-- Don't stack the same sound if it's already playing
	local fullId = soundId
	for _, existing in ipairs(parent:GetChildren()) do
		if existing:IsA("Sound") and existing.SoundId == fullId and existing.IsPlaying then
			return
		end
	end

	local sound = Instance.new("Sound")
	sound.SoundId = fullId
	sound.Volume = volume or 1
	sound.RollOffMaxDistance = maxDistance or 40
	sound.Parent = parent
	sound:Play()
	game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
	

end)
