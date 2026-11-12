-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Debris = game:GetService('Debris')

-- Assets
local Assets = ReplicatedStorage.Assets
local Replicator = ReplicatedStorage.Logic.Remotes.Replicator

-- Modules
local Logic = ReplicatedStorage.Logic
local ServerModules = ServerStorage.Modules

local Libary = require(Logic.Modules.Library)
local Hitbox = require(ServerModules.Hitbox)
local MockPart = require(ServerModules.MockPart)

return function(Player: Player, ...)
	local Character = Player.Character
	local PrimaryPart = Character.PrimaryPart

end