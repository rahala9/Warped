-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')
local ServerScriptService = game:GetService("ServerScriptService")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

local Replicator =  ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local MockPart = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("MockPart"))
local Bezier = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("Bezier"))

local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local attacksModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks")) 

local list = {}
--for _, v in pairs(game:GetService("Players"):GetPlayers()) do
--	table.insert(list, v.Character)
--end

table.insert(list,workspace.Zones)
--table.insert(list,workspace.Terrain)

return function(Player: Player, Target: Target, weapon, attack, ...)
	local Character = Player.Character
	local PrimaryPart = Character.PrimaryPart
	local HitPart = nil
	
	local Elapsed = 0
	
	if (Target == nil) then
		return
	end
	
	for _,enm in pairs(enemyFunctions.GetEnemies()) do

		local distance = (enm.root.Position - Target.Position).magnitude

		if (distance < 10) then
			enemyFunctions.HandleBodyPartHit(Player, enm,weapon,attack)
		end
	end
	
	Replicator:FireAllClients({'JacksLantern', 'Impact'}, Target.Position)

end