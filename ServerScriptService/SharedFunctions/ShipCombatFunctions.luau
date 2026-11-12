-- ShipCombatHandler.server.lua
-- FIXED: validate client muzzles using ship bounds, not server muzzle world position
-- UPDATED: lag compensation using fireTime + client ship linear velocity

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local ShieldFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("ShieldFunctions"))
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local AsteroidMiningFunctions = require(ReplicatedStorage.SharedFunctions:WaitForChild("AsteroidMiningFunctions"))


local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local FireLaserSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("FireLaser")
local LaserRecoSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("LaserRecoMetal")
local ShieldHitSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("ShieldHit")

local ImpactDecalsService = require(ServerScriptService.SharedServices:WaitForChild("ImpactDecalsService"))
local FastCast = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("FastCastRedux"))
local PartCacheModule = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("PartCache"))

--////////////////////////////////////////////////////////////////
-- CONFIG
--////////////////////////////////////////////////////////////////
local AIM_AT_TARGET = false

-- If client's ship pose is wildly different, ignore it
local MAX_CLIENT_CFRAME_ERROR = 150

-- How far outside ship bounds we allow a muzzle local position (studs)
local MUZZLE_BOUNDS_PADDING = 60

-- Lag compensation clamp (seconds). Typical remote delay is <0.2; clamp avoids spikes.
local MAX_LAG_COMP_DT = 0.35

--////////////////////////////////////////////////////////////////
-- Weapons / Ammo
--////////////////////////////////////////////////////////////////

local ShipWeapons = {
	["Small Laser Cannon"] = {
		DamageType = "Laser",
		WeaponType = "ShipLaserCannon",
		BaseDamage = 15,
		Tier = 1,
		Speed = 1500,
		FireRate = 0.2,
		MaxDistance = 2000,
		Spread = 2,
		SoundFX = { Fire = FireLaserSoundFX, Reco = LaserRecoSoundFX },
	},
	["Medium Laser Cannon"] = {
		DamageType = "Laser",
		WeaponType = "ShipLaserCannon",
		BaseDamage = 30,
		Tier = 1,
		Speed = 1600,
		FireRate = 0.4,
		MaxDistance = 2500,
		Spread = 1.5,
		SoundFX = { Fire = FireLaserSoundFX, Reco = LaserRecoSoundFX },
	},
}

local ShipAmmo = {
	["Laser"] = {
		Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("ShipSmallLaser"),
		Destroy = true,
		Gravity = Vector3.new(0, 0, 0),
		Trail = true,
	},
}

--////////////////////////////////////////////////////////////////
-- Workspace / Cache
--////////////////////////////////////////////////////////////////
local SharedWorkspaceItems = workspace:WaitForChild("SharedWorkspaceItems")
local ShipLaserBulletsFolder = SharedWorkspaceItems:FindFirstChild("ShipLaserBulletsFolder")
if not ShipLaserBulletsFolder then
	ShipLaserBulletsFolder = Instance.new("Folder")
	ShipLaserBulletsFolder.Name = "ShipLaserBulletsFolder"
	ShipLaserBulletsFolder.Parent = SharedWorkspaceItems
end

local ShipLaserPartProvider = PartCacheModule.new(ShipAmmo["Laser"].Item, 50, ShipLaserBulletsFolder)

--////////////////////////////////////////////////////////////////
-- FastCast setup
--////////////////////////////////////////////////////////////////
FastCast.DebugLogging = false
FastCast.VisualizeCasts = false

local ShipCaster = FastCast.new()
local RNG = Random.new()
local TAU = math.pi * 2

--////////////////////////////////////////////////////////////////
-- Per-ship state
--////////////////////////////////////////////////////////////////
local ShipState = {}

local function GetWeaponFirePoints(ship, weaponName)
	local firePoints = {}
	local weaponPattern = weaponName:gsub(" ", "")

	for _, desc in ipairs(ship:GetDescendants()) do
		if desc:IsA("Attachment") and desc.Name:find(weaponPattern) then
			table.insert(firePoints, desc)
		end
	end

	table.sort(firePoints, function(a, b)
		return a.Name < b.Name
	end)

	if #firePoints == 0 then
		warn("[ShipCombat] No fire points found for weapon:", weaponName)
	end

	return firePoints
end

local function GetShipWeapons(ship)
	local weapons = {}
	local weaponConfig = ship:FindFirstChild("WeaponConfiguration")

	if weaponConfig then
		for _, child in ipairs(weaponConfig:GetChildren()) do
			if child:IsA("StringValue") then
				table.insert(weapons, { Name = child.Value, Slot = child.Name })
			end
		end
	else
		table.insert(weapons, { Name = "Small Laser Cannon", Slot = "Primary" })
	end

	return weapons
end

local function PlaySoundAt(soundTemplate, parent)
	if not soundTemplate or not parent then return end
	local soundFx = soundTemplate:Clone()
	soundFx.Parent = parent
	soundFx:Play()
	local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
	Debris:AddItem(soundFx, lifetime)
end

local function MakeRayParamsForShip(ship)
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		ship,
		ShipLaserBulletsFolder,
		workspace:FindFirstChild("HelperParts"),
		workspace:FindFirstChild("BuildBlockers"),
		workspace:FindFirstChild("Zones"),
	}
	return params
end

local function MakeBehaviorForShipWeapon(rayParams, weaponDef)
	local b = FastCast.newBehavior()
	b.RaycastParams = rayParams
	b.MaxDistance = weaponDef.MaxDistance
	b.AutoIgnoreContainer = false
	b.Acceleration = ShipAmmo[weaponDef.DamageType].Gravity
	b.CosmeticBulletProvider = ShipLaserPartProvider
	b.CosmeticBulletContainer = ShipLaserBulletsFolder
	return b
end

local function ReturnBullet(cosmetic, provider)
	if not cosmetic or not provider then return end
	cosmetic.Transparency = 0
	cosmetic.Anchored = true
	cosmetic.CanCollide = false
	cosmetic.AssemblyLinearVelocity = Vector3.zero
	cosmetic.AssemblyAngularVelocity = Vector3.zero

	local tr = cosmetic:FindFirstChild("Trail")
	if tr then tr.Enabled = false end

	provider:ReturnPart(cosmetic)
end

-- Hit callbacks (unchanged)
local function OnShipRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal

	print("TEST HIT hitPart:",hitPart)
	local ship = cast.UserData.Ship
	local pilot = cast.UserData.Pilot
	local weaponDef = cast.UserData.WeaponDef

	if hitPart and hitPart.Parent and CollectionService:HasTag( hitPart.Parent,"Asteroid") then
		print("TEST HIT Asteroid hitPart:",hitPart)
		if (hitPart.Parent:IsA("Model")) then
			hitPart.Parent.FX.Position = hitPoint
			local Dust = hitPart.Parent.FX.Dust
			local Rock = hitPart.Parent.FX.Rock
			
			Dust:Emit(1000)
			Rock:Emit(20)
			
			AsteroidMiningFunctions.DestroyAsteroid(hitPart.Parent)
		end
		
	end

	if hitPart and CollectionService:HasTag(hitPart, "Shield") then
		print("TEST HIT A SHIELD hitPart:",hitPart)
		PlaySoundAt(ShieldHitSoundFX, hitPart)
		
		local provider = cast.UserData.PartProvider
		if provider then
			ReturnBullet(cosmeticBulletObject, provider)
		else
			cosmeticBulletObject:Destroy()
		end
		cosmeticBulletObject = nil

		print("TEST HIT A SHIELD ground combat hitPart:",hitPart)
		ShieldFunctions.PlacePatchOnDome(hitPart.Parent, hitPart.Parent.Shield,hitPoint,normal,CFrame.Angles(0, math.pi, 0))	
		

		local ripple = ShieldFunctions.ShieldRipple.new({
			model = hitPart.Parent.ShieldVisual,
			visibleTransparency = 0,
			hiddenTransparency = 1, -- or omit to revert to original per-part
			ringDelay = 0.07,
			fadeInTime = 0.10,
			holdTime = 0.05,
			fadeOutTime = 0.18,
		})

		-- on hit:
		ripple:Rip()
	end

	if hitPart and hitPart.Parent then
		local enemy = enemyFunctions.GetEnemy(hitPart.Parent)
		if enemy then
			if (enemy.type == "Ship") then
				enemyFunctions.HandleShipHit(
					pilot,
					enemy,
					weaponDef
				)

			else
				if enemy and pilot then
					enemyFunctions.HandleBodyPartHit(
						pilot,
						enemy,
						{Name = weaponDef.Name or "Ship Weapon", WeaponDamage = weaponDef.Damage},
						{Name = "ShipWeapon", Damage = weaponDef.Damage}
					)
				end
			end

		end
		
		enemyFunctions.HandleEnvironmentalTarget(pilot, hitPart.Parent, nil, normal, hitPoint, segmentVelocity.Unit)
	end

	if cosmeticBulletObject then ReturnBullet(cosmeticBulletObject, ShipLaserPartProvider) end
end

local function OnShipRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if not cosmeticBulletObject then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
end

local function OnShipRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo and cast.RayInfo.CosmeticBulletObject
	if cosmeticBullet then
		ReturnBullet(cosmeticBullet, ShipLaserPartProvider)
	end
end

ShipCaster.RayHit:Connect(OnShipRayHit)
ShipCaster.LengthChanged:Connect(OnShipRayUpdated)
ShipCaster.CastTerminating:Connect(OnShipRayTerminated)

--////////////////////////////////////////////////////////////////
-- Ship-bounds validation for client muzzle locals
--////////////////////////////////////////////////////////////////
local function GetShipLocalBounds(ship)
	local _, size = ship:GetBoundingBox()
	local half = size * 0.5
	return Vector3.new(
		half.X + MUZZLE_BOUNDS_PADDING,
		half.Y + MUZZLE_BOUNDS_PADDING,
		half.Z + MUZZLE_BOUNDS_PADDING
	)
end

local function IsLocalPosWithinBounds(localPos, halfExtents)
	return math.abs(localPos.X) <= halfExtents.X
		and math.abs(localPos.Y) <= halfExtents.Y
		and math.abs(localPos.Z) <= halfExtents.Z
end

--////////////////////////////////////////////////////////////////
-- NEW: lag compensation prediction (linear only)
--////////////////////////////////////////////////////////////////
local function PredictShipCFrameLinear(clientCF, linVel, dt)
	-- Keep rotation from clientCF, translate forward in world space by linVel*dt
	local pos = clientCF.Position
	local rotOnly = clientCF - pos
	return CFrame.new(pos + (linVel * dt)) * rotOnly
end

--////////////////////////////////////////////////////////////////
-- Fire ship weapon
--////////////////////////////////////////////////////////////////
local function FireShipWeapon(ship, pilot, weaponName, targetPosition, clientShipCFrame, clientMuzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
	local st = ShipState[ship]
	if not st then
		st = { LastFireTime = 0, Pilot = pilot }
		ShipState[ship] = st
	end

	local weaponDef = ShipWeapons[weaponName]
	if not weaponDef then return end

	local nowTick = tick()
	if (nowTick - st.LastFireTime) < weaponDef.FireRate then return end
	st.LastFireTime = nowTick

	if not ship.PrimaryPart then return end

	-- sanity client ship pose
	if clientShipCFrame then
		local dist = (clientShipCFrame.Position - ship.PrimaryPart.Position).Magnitude
		if dist > MAX_CLIENT_CFRAME_ERROR then
			clientShipCFrame = nil
			clientMuzzlesLocalCF = nil
			fireTime = nil
			shipLinVel = nil
		end
	end

	-- Lag-compensated ship pose (predict forward to "server now")
	local predictedShipCFrame = clientShipCFrame
	if clientShipCFrame and fireTime and shipLinVel then
		local serverNow = workspace:GetServerTimeNow()
		local dt = serverNow - fireTime
		if dt < 0 then dt = 0 end
		if dt > MAX_LAG_COMP_DT then dt = MAX_LAG_COMP_DT end
		predictedShipCFrame = PredictShipCFrameLinear(clientShipCFrame, shipLinVel, dt)
	end

	local firePoints = GetWeaponFirePoints(ship, weaponName)
	if #firePoints == 0 then return end

	local halfExtents = GetShipLocalBounds(ship)

	for i, firePoint in ipairs(firePoints) do
		local origin = firePoint.WorldPosition

		-- Prefer client reconstructed muzzle using PREDICTED ship pose
		if predictedShipCFrame and clientMuzzlesLocalCF and typeof(clientMuzzlesLocalCF[i]) == "CFrame" then
			local localCF = clientMuzzlesLocalCF[i]
			local localPos = localCF.Position

			if IsLocalPosWithinBounds(localPos, halfExtents) then
				local candidateCF = predictedShipCFrame * localCF
				origin = candidateCF.Position
			end
		end

		-- Direction
		local direction
		if AIM_AT_TARGET and targetPosition then
			local delta = targetPosition - origin
			direction = (delta.Magnitude > 0.01) and delta.Unit or ship.PrimaryPart.CFrame.LookVector
		else
			-- Forward firing: use predicted pose if available, else server pose
			direction = (predictedShipCFrame and predictedShipCFrame.LookVector) or ship.PrimaryPart.CFrame.LookVector
		end

		-- Spread
		local spreadAngle = math.rad(weaponDef.Spread or 2)
		local directionalCF = CFrame.new(Vector3.new(), direction)
		direction = (directionalCF
			* CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU))
			* CFrame.fromOrientation(math.rad(RNG:NextNumber(-spreadAngle, spreadAngle)), 0, 0)
		).LookVector

		local rayParams = MakeRayParamsForShip(ship)
		local behavior = MakeBehaviorForShipWeapon(rayParams, weaponDef)

		local bulletVelocity = direction * weaponDef.Speed

		local simBullet = ShipCaster:Fire(origin, direction, bulletVelocity, behavior)
		simBullet.UserData.Ship = ship
		simBullet.UserData.Pilot = pilot
		simBullet.UserData.WeaponDef = weaponDef

		local cosmetic = simBullet.RayInfo and simBullet.RayInfo.CosmeticBulletObject
		if cosmetic then
			cosmetic.CFrame = CFrame.new(origin, origin + direction)
			cosmetic.AssemblyLinearVelocity = Vector3.zero
			cosmetic.AssemblyAngularVelocity = Vector3.zero
			cosmetic.Anchored = true

			cosmetic.Transparency = 0
			cosmetic.Material = Enum.Material.Neon
			cosmetic.Color = Color3.new(1, 0, 0)
			cosmetic.CastShadow = false

			local ammoConfig = ShipAmmo[weaponDef.DamageType]
			if ammoConfig and ammoConfig.Trail then
				local tr = cosmetic:FindFirstChild("Trail")
				if tr then tr.Enabled = true end
			end
		end

		if weaponDef.SoundFX and weaponDef.SoundFX.Fire then
			PlaySoundAt(weaponDef.SoundFX.Fire, firePoint.Parent or workspace)
		end
	end
end

--////////////////////////////////////////////////////////////////
-- Public API
--////////////////////////////////////////////////////////////////
local ShipCombat = {}

-- UPDATED SIGNATURE: includes fireTime/vels
function ShipCombat.Fire(ship, pilot, weaponSlot, targetPosition, clientShipCFrame, clientMuzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
	if not ship or not ship:IsA("Model") then return end

	local weapons = GetShipWeapons(ship)

	local weaponName
	for _, weapon in ipairs(weapons) do
		if weapon.Slot == weaponSlot or weaponSlot == "Primary" then
			weaponName = weapon.Name
			break
		end
	end
	if not weaponName then weaponName = "Small Laser Cannon" end

	FireShipWeapon(ship, pilot, weaponName, targetPosition, clientShipCFrame, clientMuzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
end

workspace.DescendantRemoving:Connect(function(desc)
	if desc:IsA("Model") and ShipState[desc] then
		ShipState[desc] = nil
	end
end)

return ShipCombat
