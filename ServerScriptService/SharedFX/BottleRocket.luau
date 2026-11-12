-- Localization
local Random = Random.new()

-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService('RunService')
local Debris = game:GetService('Debris')
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local attacksModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks")) 

local Replicator =  ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local Hitbox = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("HitBox"))
local MockPart = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("MockPart"))
local Bezier = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("Bezier"))
local EffectItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("FX")
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local GetWeaponSourceEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetWeaponSource")
local launchSound = EffectItems.Rocket.bottlerocket_launch
local explodeSound = EffectItems.Rocket.bottlerocket_explode

function HandleHit(Projectile,Player,Position,Connection,eSound)
	eSound:Play()
	Projectile:Destroy()
	Replicator:FireAllClients({'BottleRocket', 'Impact'}, Position)
	Connection:Disconnect()
	

	if (Player.Character:FindFirstChild("BottleRocket")) then
		Player.Character.BottleRocket.Firework.Transparency = 0
	end
	
end

return function(Player: Player, Target: Target, weapon, attack,ToolTransformedWorldCFrame, ...)
	local Character = Player.Character
	local PrimaryPart = Character.PrimaryPart

	local Connection
	
	local weaponSource = GetWeaponSourceEvent:InvokeClient(Player)
	
	if  (weaponSource == nil) then
		weaponSource = Player.Character.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["BottleRocketHandle"]["FireworkHandle"].TransformedWorldCFrame
	end
	
	
	local Projectile = MockPart('BottleRocket', weaponSource)

	local lSound = launchSound:Clone()
	lSound.Parent = Projectile
	
	Debris:AddItem(lSound,20)
	
	local eSound = explodeSound:Clone()
	eSound.Parent = workspace --Projectile
	
	Debris:AddItem(eSound,20)

	Replicator:FireAllClients({'BottleRocket', 'Projectile'}, Projectile)
	
	if (Player.Character:FindFirstChild("BottleRocket")) then
		Player.Character.BottleRocket.Firework.Transparency = 1
	end
		
	local Elapsed = 0
	local Angles = {
		CFrame.new(math.random(10, 20), 0, 0),
		CFrame.new(math.random(-20, -10), 0, 0),
		CFrame.new(0, math.random(5, 10), 0)
	}
	
	-- Motion
	local Start = Projectile.CFrame
	local End = Target --Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 50)
	local Midpoint = (Start:Lerp(End, 0.3) * Angles[math.random(#Angles)]).Position
	local Midpoint1 = (Start:Lerp(End, 0.6) * Angles[math.random(#Angles)]).Position
	local HitPart = nil
	
	lSound:Play()

	local Connection; Connection = RunService.Stepped:Connect(function(_, Delta)
		Elapsed += Delta * 1.5
		
		
		local straight_length = 10
		local dir = (End.Position - Start.Position).Unit
		local straight_end = Start.Position + straight_length * dir
		local Curve = nil

		local distance_straight = (straight_end - Start.Position).Magnitude
		local distance_curve = (End.Position - straight_end).Magnitude

		local total_distance = distance_straight + distance_curve
		local speed = 50 -- adjust this as needed

		if Elapsed <= distance_straight/speed then
			Curve = Start.Position + dir * speed * Elapsed
		elseif Elapsed <= (distance_straight + distance_curve)/speed then
			local t = (Elapsed - distance_straight/speed) / ((distance_curve)/speed)
			Curve = Bezier.CubicBezier(t, straight_end, Midpoint, Midpoint1, End.Position)
		end
		
		--End of path
		if (not Curve) then
			
			HandleHit(Projectile,Player,Projectile.Position,Connection,eSound)

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
	
		if (Elapsed > 3) then
			HandleHit(Projectile,Player,Projectile.Position,Connection,eSound)
		end
		
	
		local list = {}
		for _, v in pairs(game:GetService("Players"):GetPlayers()) do
			table.insert(list, v.Character)
		end

		table.insert(list,workspace.Zones)
		table.insert(list,workspace.Terrain)
		table.insert(list,Projectile)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = list
		params.FilterType = Enum.RaycastFilterType.Exclude
		
		local direction = (End.Position - Start.Position).Unit --Projectile.CFrame.LookVector * 5
		local Raycast = workspace:Raycast(Projectile.Position, direction*5, params)

		if Raycast then
			HitPart = Raycast.Instance

			if HitPart ~= nil then -- Test if we hit something
				
				HandleHit(Projectile,Player,Raycast.Position,Connection,eSound)
				
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
		
		if (Curve) then
			-- Calculate projectile direction vector
			local dir = Curve - Projectile.Position
			dir = dir.Unit

			-- Set projectile's CFrame to new CFrame
			Projectile.CFrame = CFrame.new(Curve, Curve + dir) * CFrame.fromOrientation(-math.pi / 2, 0, 0)
			Projectile.Position = Curve
		end
		
		
		
	end)
end