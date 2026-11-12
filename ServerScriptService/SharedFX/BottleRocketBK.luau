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

return function(Player: Player, Target: Target, weapon, attack, ...)
	local Character = Player.Character
	local PrimaryPart = Character.PrimaryPart
	local HitPart = nil
	
	local Elapsed = 0
	
	if (Target == nil) then
		return
	end
		
		local Angles = {
			CFrame.new(math.random(1, 2), 0, 0),
			CFrame.new(math.random(-2, -1), 0, 0),
			CFrame.new(0, math.random(1, 2), 0)
		
		--CFrame.new(math.random(10, 20), 0, 0),
		--CFrame.new(math.random(-20, -10), 0, 0),
		--CFrame.new(0, math.random(5, 10), 0)
		}
		
	local Projectile = MockPart('BottleRocket', Player.Character.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"].TransformedWorldCFrame)
		Replicator:FireAllClients({'BottleRocket', 'Projectile'}, Projectile)
		
		local Start = Projectile.CFrame
		local End = Target
		local Midpoint = (Start:Lerp(End, 0.3) * Angles[math.random(#Angles)]).Position
		local Midpoint1 = (Start:Lerp(End, 0.6) * Angles[math.random(#Angles)]).Position
		
		local Connection; Connection = RunService.Stepped:Connect(function(_, Delta)
			Elapsed += Delta * 1.5
			
			local Curve = Bezier.CubicBezier(Elapsed, Start.Position, Midpoint, Midpoint1, End.Position)
		
			--If the projectile is at the end then destroy it
			if ((Projectile.Position - End.Position).Magnitude < 2) then
				Projectile:Destroy()
				Replicator:FireAllClients({'BottleRocket', 'Impact'}, End.Position)
				Connection:Disconnect()
				
					--At the end so see if original target enemy is within range of impact.
				for _,enm in pairs(enemyFunctions.GetEnemies()) do

					local distance = (enm.root.Position - End.Position).magnitude

					--TODO this may need to be based on length of weapon
					if (distance < 4) then
						enemyFunctions.HandleBodyPartHit(Player, enm,weapon,attack)
					end
				end
			
				return
			end
		
			--If this projectile is going too far then destroy it.
			if (Elapsed >= 2) and (Target ~= nil) then

				Projectile:Destroy()
				Connection:Disconnect()
				return
			end
		
			--TODO PERFORMANCE  should this be running list inside here or on some module to not always get this
			local list = {}
			for _, v in pairs(game:GetService("Players"):GetPlayers()) do
				table.insert(list, v.Character)
			end
		
			table.insert(list,workspace.Zones)
			table.insert(list,workspace.Terrain)
			--TODO add to list all HelperPart tagged items
		
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = list
			params.FilterType = Enum.RaycastFilterType.Exclude

			local Raycast = workspace:Raycast(Projectile.Position, Projectile.CFrame.LookVector * 5, params)
			
			if Raycast then
			HitPart = Raycast.Instance
			
				if HitPart ~= nil then -- Test if we hit something
										
					Projectile:Destroy()
					Replicator:FireAllClients({'BottleRocket', 'Impact'}, Raycast.Position)
					Connection:Disconnect()
				
					--Check for enemy
					if (HitPart.Parent ~= nil and (HitPart.Parent:IsA("Model"))) then
						local enemyID = HitPart.Parent:GetAttribute("EnemyID")

						local enemy = enemyFunctions.GetEnemyByID(enemyID)

						if (enemy ~= nil) then
							enemyFunctions.HandleBodyPartHit(Player, enemy,weapon,attack)
						end
					end
				end
			end
			
			
			Projectile.Position = Curve
			

						
			
		end)
end