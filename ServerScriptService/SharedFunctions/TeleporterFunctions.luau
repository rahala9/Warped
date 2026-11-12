local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local OpenTeleporterGuiEvent = Remotes:WaitForChild("OpenTeleporterGui")

local TeleporterFunctions = {}

function TeleporterFunctions.OpenTeleporter(player, teleporterPath, locations)
	OpenTeleporterGuiEvent:FireClient(player,teleporterPath, locations)
end

return TeleporterFunctions