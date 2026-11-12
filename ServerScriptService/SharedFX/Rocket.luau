-- BottleRocket server attack function

-- Localization
local Random = Random.new()

-- Services
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")
local Debris              = game:GetService("Debris")

-- Modules
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local enemiesModule  = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local itemsmodule    = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local attacksModule  = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks"))

local Hitbox         = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("HitBox"))
local MockPart       = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("MockPart"))
local Bezier         = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("Bezier"))
local ToolFunctions  = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))

-- Remotes / assets
local Replicator  = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local EffectItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("FX")

local launchSound  = EffectItems.Rocket.bottlerocket_launch
local explodeSound = EffectItems.Rocket.bottlerocket_explode

-- Main exported function
return function(Player: Player, Target: CFrame, weapon, attack, ToolTransformedWorldCFrame, ...)
	local Character   = Player.Character
	if not Character then return end

	local PrimaryPart = Character.PrimaryPart
	if not PrimaryPart then return end

	-- Create server-side projectile part (for logic & raycasts)
	local weaponSource = ToolTransformedWorldCFrame
	local Projectile   = MockPart("BottleRocket", weaponSource)

	if not Projectile then
		warn("BottleRocket: MockPart returned nil")
		return
	end

	-- Sounds on the projectile
	local lSound = launchSound:Clone()
	lSound.Parent = Projectile
	Debris:AddItem(lSound, 20)

	local eSound = explodeSound:Clone()
	eSound.Parent = Projectile
	Debris:AddItem(eSound, 20)

	-- Hide BottleRocket tool mesh while firing (if present)
	local BottleRocketTool = Character:FindFirstChild("BottleRocket")
	if BottleRocketTool then
		BottleRocketTool.Firework.Transparency = 1
	end

	----------------------------------------------------------------
	-- PATH PARAMETERS (these will be sent to the client)
	----------------------------------------------------------------
	local Elapsed = 0
	local Angles  = {
		CFrame.new(math.random(10, 20), 0, 0),
		CFrame.new(math.random(-20, -10), 0, 0),
		CFrame.new(0, math.random(5, 10), 0)
	}

	local Start    = Projectile.CFrame           -- CFrame
	local End      = Target                      -- CFrame (target)
	local Midpoint = (Start:Lerp(End, 0.3) * Angles[math.random(#Angles)]).Position
	local Midpoint1 = (Start:Lerp(End, 0.6) * Angles[math.random(#Angles)]).Position

	-- 🔁 Broadcast path data to all clients (no Instances, just Vector3s)
	Replicator:FireAllClients(
		{ "BottleRocket", "Projectile" },
		Start.Position,
		End.Position,
		Midpoint,
		Midpoint1
	)

	----------------------------------------------------------------
	-- SERVER-SIDE MOTION + HIT LOGIC (unchanged in spirit)
	----------------------------------------------------------------
	lSound:Play()

	local Connection
	Connection = RunService.Stepped:Connect(function(_, Delta)
		Elapsed += Delta * 1.5

		local straight_length = 10
		local dir = (End.Position - Start.Position).Unit
		local straight_end = Start.Position + straight_length * dir
		local Curve = nil

		local distance_straight = (straight_end - Start.Position).Magnitude
		local distance_curve    = (End.Position - straight_end).Magnitude
		local total_distance    = distance_straight + distance_curve
		local speed             = 50

		if Elapsed <= distance_straight / speed then
			Curve = Start.Position + dir * speed * Elapsed
		elseif Elapsed <= (distance_straight + distance_curve) / speed then
			local t = (Elapsed - distance_straight / speed) / (distance_curve / speed)
			Curve = Bezier.CubicBezier(t, straight_end, Midpoint, Midpoint1, End.Position)
		end

		-- End of path (no more curve)
		if not Curve then
			Projectile:Destroy()
			Replicator:FireAllClients({ "BottleRocket", "Impact" }, End.Position)
			Connection:Disconnect()
			eSound:Play()

			if BottleRocketTool then
				BottleRocketTool.Firework.Transparency = 0
			end

			-- Check enemies near the end point
			for _, enm in pairs(enemyFunctions.GetEnemies()) do
				local distance = (enm.root.Position - End.Position).Magnitude
				if distance < 4 then
					enemyFunctions.HandleBodyPartHit(Player, enm, weapon, attack)
				end
			end

			return
		end

		-- Raycast ahead along path to hit something early
		local list = {}
		for _, v in pairs(game:GetService("Players"):GetPlayers()) do
			if v.Character then
				table.insert(list, v.Character)
			end
		end

		table.insert(list, workspace.Zones)
		table.insert(list, workspace.Terrain)
		table.insert(list, Projectile)
		table.insert(list, workspace.UserDroppedItems)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = list
		params.FilterType = Enum.RaycastFilterType.Exclude

		local direction = (End.Position - Start.Position).Unit
		local Raycast = workspace:Raycast(Projectile.Position, direction * 5, params)

		if Raycast then
			local HitPart = Raycast.Instance
			if HitPart then
				Projectile:Destroy()
				Replicator:FireAllClients({ "BottleRocket", "Impact" }, Raycast.Position)
				Connection:Disconnect()
				eSound:Play()

				if BottleRocketTool then
					BottleRocketTool.Firework.Transparency = 0
				end

				-- Enemy hit check
				if HitPart.Parent and HitPart.Parent:IsA("Model") then
					local enemyID = HitPart.Parent:GetAttribute("EnemyID")
					local enemy   = enemyFunctions.GetEnemyByID(enemyID)

					if enemy then
						enemyFunctions.HandleBodyPartHit(Player, enemy, weapon, attack)
					end
				end
			end
		end

		-- Move the server projectile along the curve
		if Curve then
			local dirVec = (Curve - Projectile.Position)
			if dirVec.Magnitude > 0 then
				dirVec = dirVec.Unit
			else
				dirVec = direction
			end

			Projectile.CFrame = CFrame.new(Curve, Curve + dirVec) * CFrame.fromOrientation(-math.pi / 2, 0, 0)
			Projectile.Position = Curve
		end
	end)
end
