-- Listens for lightning strike events and spawns animated lightning on the client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LightningStrikeRemote = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("LightningStrikeRemote")
local StormSystemRemote = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("StormSystemRemote")
local player = game.Players.LocalPlayer
local RainSystem = require(game.ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("RainSystem"))

-- Assuming you have a copy of LightningBolt stored in ReplicatedStorage or imported another way
local LightningBolt = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("LightningBolt"))

LightningStrikeRemote.OnClientEvent:Connect(function(target,startPos, endPos)

	local bolt = LightningBolt.new(target,startPos, endPos, 10)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	
	
end)

StormSystemRemote.OnClientEvent:Connect(function(state)

	if (state == "Started") then
		RainSystem.Start()
	elseif (state == "Stopped") then
		RainSystem.Stop()
	end

end)