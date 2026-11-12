-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Remote Events
local AttributesChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AttributesChanged")


local PlayerInfo = {
	Attributes = {},
}

AttributesChangedEvent.OnClientEvent:Connect(function(attributes)
	PlayerInfo.Attributes = attributes
end)

return PlayerInfo
