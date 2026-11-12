local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCacheModule = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("PartCache"))
local FastCast = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("FastCastRedux"))

local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local attacksModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks"))
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local EnemyFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("EnemyFunctions"))
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local CombatFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("CombatFunctions"))

local enemyCombat = {}

--////////////////////////////////////////////////////////////////
-- AMMO CONFIG
--////////////////////////////////////////////////////////////////

local AmmoFolder = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Ammo")

local ammo = {
	["Spore"] = {
		Item = AmmoFolder:WaitForChild("Spore"),
		Stick = false,
		Trail = false,
		Destroy = false,
		Gravity = Vector3.new(0, -workspace.Gravity * 0.5, 0),
	},

	["Rock"] = {
		Item = AmmoFolder:WaitForChild("Rock"),
		Stick = false,
		Trail = true,
		Destroy = false,
		Gravity = Vector3.new(0, -workspace.Gravity * 0.5, 0),
	},

	["Egg"] = {
		Item = AmmoFolder:WaitForChild("Egg"),
		Stick = true,
		RotateStickThree = true,
		Trail = true,
		Destroy = false,
		Gravity = Vector3.new(0, -workspace.Gravity * 0.5, 0),
	},

	["MonkeyWrench"] = {
		Item = AmmoFolder:WaitForChild("MonkeyWrench"),
		Stick = false,
		RotateStickThree = false,
		Trail = true,
		Destroy = false,
		Gravity = Vector3.new(0, -workspace.Gravity * 0.5, 0),
	},

	["Laser"] = {
		Item = AmmoFolder:WaitForChild("Laser"),
		Stick = false,
		Trail = false,
		Destroy = true,

		-- Lasers should not arc downward like physical ammo.
		Gravity = Vector3.zero,

		-- Return to cache almost immediately after hit/termination.
		ReturnDelay = 0.05,
	},
}

--////////////////////////////////////////////////////////////////
-- FASTCAST SETTINGS
--////////////////////////////////////////////////////////////////

local DEBUG = false
local BULLET_MAXDIST = 1000

local RNG = Random.new()
local TAU = math.pi * 2

FastCast.DebugLogging = false
FastCast.VisualizeCasts = false

--////////////////////////////////////////////////////////////////
-- WORKSPACE FOLDERS
--////////////////////////////////////////////////////////////////

local EnemiesBulletFolders = workspace:WaitForChild("SharedWorkspaceItems"):WaitForChild("EnemiesBulletFolders")

local SporeBulletsFolder = EnemiesBulletFolders:FindFirstChild("SporeBulletFolder")
local RockBulletsFolder = EnemiesBulletFolders:FindFirstChild("RockBulletFolder")
local EggBulletsFolder = EnemiesBulletFolders:FindFirstChild("EggBulletFolder")
local MonkeyWrenchBulletsFolder = EnemiesBulletFolders:FindFirstChild("MonkeyWrenchBulletFolder")
local LaserBulletsFolder = EnemiesBulletFolders:FindFirstChild("LaserBulletFolder")

local HelperPartsFolder = workspace:WaitForChild("HelperParts")
local BuildBlockersFolder = workspace:WaitForChild("BuildBlockers")

local BulletFolders = {
	["Spore"] = SporeBulletsFolder,
	["Rock"] = RockBulletsFolder,
	["Egg"] = EggBulletsFolder,
	["MonkeyWrench"] = MonkeyWrenchBulletsFolder,
	["Laser"] = LaserBulletsFolder,
}

--////////////////////////////////////////////////////////////////
-- PART CACHES
--////////////////////////////////////////////////////////////////

local SporePartProvider = PartCacheModule.new(ammo["Spore"].Item, 100, SporeBulletsFolder)
local RockPartProvider = PartCacheModule.new(ammo["Rock"].Item, 100, RockBulletsFolder)
local EggPartProvider = PartCacheModule.new(ammo["Egg"].Item, 100, EggBulletsFolder)
local MonkeyWrenchPartProvider = PartCacheModule.new(ammo["MonkeyWrench"].Item, 100, MonkeyWrenchBulletsFolder)
local LaserPartProvider = PartCacheModule.new(ammo["Laser"].Item, 100, LaserBulletsFolder)

local PartProviders = {
	["Spore"] = SporePartProvider,
	["Rock"] = RockPartProvider,
	["Egg"] = EggPartProvider,
	["MonkeyWrench"] = MonkeyWrenchPartProvider,
	["Laser"] = LaserPartProvider,
}

--////////////////////////////////////////////////////////////////
-- CASTER
--////////////////////////////////////////////////////////////////

local Caster = FastCast.new()

--////////////////////////////////////////////////////////////////
-- HELPERS
--////////////////////////////////////////////////////////////////

local function warnMissingAmmo(ammoName)
	warn("[EnemyCombatFunctions] Missing ammo config/provider/folder for ammo:", ammoName)
end

local function getAmmoDefFromCastOrPart(cast, cosmeticBulletObject)
	local ammoName = cast and cast.UserData and cast.UserData.AmmoName

	if ammoName and ammo[ammoName] then
		return ammo[ammoName], ammoName
	end

	if cosmeticBulletObject and ammo[cosmeticBulletObject.Name] then
		return ammo[cosmeticBulletObject.Name], cosmeticBulletObject.Name
	end

	return nil, ammoName or (cosmeticBulletObject and cosmeticBulletObject.Name) or nil
end

local function resetCosmeticPhysics(cosmetic)
	if not cosmetic then return end

	cosmetic.Anchored = true
	cosmetic.CanCollide = false
	cosmetic.CanTouch = false
	cosmetic.CanQuery = false
	cosmetic.AssemblyLinearVelocity = Vector3.zero
	cosmetic.AssemblyAngularVelocity = Vector3.zero
end

local function setCosmeticHidden(cosmetic)
	if not cosmetic then return end

	cosmetic.Transparency = 1
	cosmetic.LocalTransparencyModifier = 1

	local tr = cosmetic:FindFirstChild("Trail")
	if tr then
		tr.Enabled = false
	end
end

local function setCosmeticVisible(cosmetic)
	if not cosmetic then return end

	cosmetic.Transparency = 0
	cosmetic.LocalTransparencyModifier = 0
end

--////////////////////////////////////////////////////////////////
-- PIERCE
--////////////////////////////////////////////////////////////////

local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

local function CanRayPierce(cast, rayResult, segmentVelocity)
	local hitPart = rayResult.Instance

	if hitPart and hitPart:GetAttribute("Pierce") then
		return true
	end

	return false
end

--////////////////////////////////////////////////////////////////
-- PER-SHOT RAY PARAMS / BEHAVIOR
--////////////////////////////////////////////////////////////////

local function MakeRayParamsForEnemy(enemy)
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		enemy,

		SporeBulletsFolder,
		RockBulletsFolder,
		EggBulletsFolder,
		MonkeyWrenchBulletsFolder,
		LaserBulletsFolder,

		HelperPartsFolder,
		BuildBlockersFolder,
		workspace:FindFirstChild("Zones"),
	}

	return params
end

local function MakeBehaviorForShot(rayParams, ammoName)
	local ammoDef = ammo[ammoName]
	local provider = PartProviders[ammoName]
	local folder = BulletFolders[ammoName]

	if not ammoDef or not provider or not folder then
		warnMissingAmmo(ammoName)
		return nil
	end

	local b = FastCast.newBehavior()
	b.RaycastParams = rayParams
	b.MaxDistance = BULLET_MAXDIST
	b.AutoIgnoreContainer = false
	b.CanPierceFunction = CanRayPierce
	b.Acceleration = ammoDef.Gravity or Vector3.new(0, -workspace.Gravity * 0.5, 0)

	b.CosmeticBulletProvider = provider
	b.CosmeticBulletContainer = folder

	return b
end

local function InitCosmeticForShot(simBullet, origin, direction, ammoName)
	local cosmetic = simBullet.RayInfo and simBullet.RayInfo.CosmeticBulletObject
	if not cosmetic then return end

	local ammoDef = ammo[ammoName]
	local folder = BulletFolders[ammoName]

	cosmetic.Parent = folder

	resetCosmeticPhysics(cosmetic)
	setCosmeticVisible(cosmetic)

	cosmetic.CFrame = CFrame.new(origin, origin + direction)

	local tr = cosmetic:FindFirstChild("Trail")
	if tr then
		tr.Enabled = (ammoDef and ammoDef.Trail) or false
	end
end

--////////////////////////////////////////////////////////////////
-- FIRE
--////////////////////////////////////////////////////////////////

local function Fire(enemy, origin, directionInput, distance, ammoName, weapon)
	if typeof(origin) ~= "Vector3" then
		warn("[EnemyCombatFunctions] Fire called with invalid origin:", origin)
		return
	end

	if typeof(directionInput) ~= "Vector3" or directionInput.Magnitude <= 0 then
		warn("[EnemyCombatFunctions] Fire called with invalid direction:", directionInput)
		return
	end

	if not ammo[ammoName] or not PartProviders[ammoName] or not BulletFolders[ammoName] then
		warnMissingAmmo(ammoName)
		return
	end

	local directionalCF = CFrame.new(Vector3.new(), directionInput)

	local attackName = enemiesModule[enemy.Name] and enemiesModule[enemy.Name].RangeAttack
	local isMoving = false

	local minSpreadAngle, maxSpreadAngle = CombatFunctions.CalculateSpreadAngles(enemy, weapon, distance, isMoving)

	if DEBUG then
		print("TEST Enemy Ranged Weapons minSpreadAngle:", minSpreadAngle, "maxSpreadAngle:", maxSpreadAngle)
	end

	local direction =
		(directionalCF
			* CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU))
			* CFrame.fromOrientation(math.rad(RNG:NextNumber(minSpreadAngle, maxSpreadAngle)), 0, 0)
		).LookVector

	local ammoSpeed = weapon.WeaponAmmoSpeed or 300
	local modifiedBulletVelocity = direction * ammoSpeed

	local rayParams = MakeRayParamsForEnemy(enemy)
	local behavior = MakeBehaviorForShot(rayParams, ammoName)

	if not behavior then
		return
	end

	local simBullet = Caster:Fire(origin, direction, modifiedBulletVelocity, behavior)

	simBullet.UserData.Enemy = enemy
	simBullet.UserData.WeaponName = weapon
	simBullet.UserData.AttackName = attackName
	simBullet.UserData.PartProvider = behavior.CosmeticBulletProvider
	simBullet.UserData.WeaponAmmo = weapon.WeaponAmmo
	simBullet.UserData.AmmoName = ammoName

	InitCosmeticForShot(simBullet, origin, direction, ammoName)
end

--////////////////////////////////////////////////////////////////
-- PUBLIC API
--////////////////////////////////////////////////////////////////

local CanFire = true -- still global; make per-enemy later if needed

function enemyCombat.HandleRanged(enemy, targetPlayerPosition, speed, ammoName, enemyOffsetFiringPosition)
	if not CanFire then
		return
	end

	CanFire = false

	if not enemy or not enemy.PrimaryPart then
		CanFire = true
		return
	end

	if typeof(targetPlayerPosition) ~= "Vector3" then
		warn("[EnemyCombatFunctions] HandleRanged invalid targetPlayerPosition:", targetPlayerPosition)
		CanFire = true
		return
	end

	local origin = enemy.PrimaryPart.Position

	if typeof(enemyOffsetFiringPosition) == "Vector3" then
		origin = enemyOffsetFiringPosition
	end

	local delta = targetPlayerPosition - origin

	if delta.Magnitude <= 0.01 then
		CanFire = true
		return
	end

	local direction = delta.Unit
	local distance = delta.Magnitude

	local enemyDef = enemiesModule[enemy.Name]
	local weapon = enemyDef and itemsmodule[enemyDef.Weapon]

	if not weapon then
		warn("[EnemyCombatFunctions] Missing weapon for enemy:", enemy.Name, enemyDef and enemyDef.Weapon)
		CanFire = true
		return
	end

	if not ammoName then
		warn("[EnemyCombatFunctions] Missing ammoName for enemy:", enemy.Name)
		CanFire = true
		return
	end

	Fire(enemy, origin, direction, distance, ammoName, weapon)

	CanFire = true
end

local function pickWeightedAttack(attacks)
	if not attacks or #attacks == 0 then
		return nil
	end

	local total = 0

	for _, a in ipairs(attacks) do
		local w = tonumber(a.RarityPercentage) or 0

		if w > 0 then
			total += w
		end
	end

	if total <= 0 then
		return nil
	end

	local roll = math.random() * total
	local acc = 0

	for _, a in ipairs(attacks) do
		local w = tonumber(a.RarityPercentage) or 0

		if w > 0 then
			acc += w

			if roll <= acc then
				return a
			end
		end
	end

	return attacks[#attacks]
end

function enemyCombat.HandleMelee(enemy, targetPlayerPosition, EnemyTarget)
	local enemyDef = enemiesModule[enemy.Name]

	if not enemyDef or not enemyDef.Attacks then
		warn("[EnemyCombatFunctions] Missing melee attacks for enemy:", enemy.Name)
		return
	end

	local attack = pickWeightedAttack(enemyDef.Attacks)

	if not attack then
		warn("[EnemyCombatFunctions] Could not pick melee attack for enemy:", enemy.Name)
		return
	end

	EnemyFunctions.EnemyMeleeAttack(enemy, attack.Name, EnemyTarget)
end

--////////////////////////////////////////////////////////////////
-- HIT / UPDATE / TERMINATE
--////////////////////////////////////////////////////////////////

local function HandleHit(cast, raycastResult, cosmeticBulletObject, pierced)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal

	local ammoDef, ammoName = getAmmoDefFromCastOrPart(cast, cosmeticBulletObject)

	-- Ignore non-humanoid hits for damage, but still clean up cosmetic.
	local hitHumanoidCharacter =
		hitPart
		and hitPart.Parent
		and hitPart.Parent:FindFirstChildOfClass("Humanoid")

	if cosmeticBulletObject then
		local tr = cosmeticBulletObject:FindFirstChild("Trail")
		if tr then
			tr.Enabled = false
		end

		if ammoDef and ammoDef.Destroy then
			-- Energy/laser behavior:
			-- Do NOT become physical.
			-- Do NOT collide.
			-- Do NOT fall.
			resetCosmeticPhysics(cosmeticBulletObject)
			setCosmeticHidden(cosmeticBulletObject)
		else
			if ((not pierced) and ammoDef and ammoDef.Stick) then
				resetCosmeticPhysics(cosmeticBulletObject)
				cosmeticBulletObject.CFrame = CFrame.new(hitPoint, hitPoint + normal)
				cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal * 0.5)
			else
				-- Physical projectile behavior only.
				cosmeticBulletObject.Anchored = false
				cosmeticBulletObject.CanCollide = true
				cosmeticBulletObject.CanTouch = false
				cosmeticBulletObject.CanQuery = false
			end

			local rotatedCFrame

			if ammoDef and ammoDef.RotateStickOne then
				rotatedCFrame = CFrame.Angles(math.rad(-90), math.rad(-90), 0)
			elseif ammoDef and ammoDef.RotateStickTwo then
				rotatedCFrame = CFrame.Angles(0, math.rad(180), 0)
			elseif ammoDef and ammoDef.RotateStickThree then
				rotatedCFrame = CFrame.Angles(0, 0, 0)
			else
				rotatedCFrame = CFrame.Angles(0, math.rad(-90), 0)
			end

			cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
		end
	end

	if not hitHumanoidCharacter then
		return
	end

	local enemy = cast.UserData.Enemy
	local enemyKey = enemy and enemy.Name
	local enemyDef = enemyKey and enemiesModule[enemyKey]

	if enemyDef and enemyDef.RangeAttack then
		local attack = attacksModule[enemyDef.RangeAttack]

		EnemyFunctions.EnemyRangedAttack(enemy, attack, hitPart.Parent)

		if attack and attack.Effect then
			local player = game:GetService("Players"):GetPlayerFromCharacter(hitPart.Parent)

			if player then
				EffectsFunctions.AddEffect(player, attack.Effect, 1)
			end
		end
	end
end

local function OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	HandleHit(cast, raycastResult, cosmeticBulletObject, false)
end

local function OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	HandleHit(cast, raycastResult, cosmeticBulletObject, true)
	cast:SetPosition(raycastResult.Position)
end

local function OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if cosmeticBulletObject == nil then return end

	local ammoDef = nil

	if cast and cast.UserData and cast.UserData.AmmoName then
		ammoDef = ammo[cast.UserData.AmmoName]
	end

	ammoDef = ammoDef or ammo[cosmeticBulletObject.Name]

	resetCosmeticPhysics(cosmeticBulletObject)

	local bulletLength = cosmeticBulletObject.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)

	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))

	local tr = cosmeticBulletObject:FindFirstChild("Trail")
	if tr then
		tr.Enabled = (ammoDef and ammoDef.Trail) or false
	end

	if ammoDef and ammoDef.Rotate then
		local rotatedCFrame = CFrame.Angles(0, math.rad(90), 0)
		cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
	end
end

local function OnRayTerminated(cast)
	local cosmeticBullet = cast.RayInfo and cast.RayInfo.CosmeticBulletObject
	if not cosmeticBullet then return end

	local provider = cast.UserData and cast.UserData.PartProvider
	if not provider then return end

	local ammoDef = nil

	if cast.UserData and cast.UserData.AmmoName then
		ammoDef = ammo[cast.UserData.AmmoName]
	end

	ammoDef = ammoDef or ammo[cosmeticBullet.Name]

	local delayTime = 3

	if ammoDef and ammoDef.Destroy then
		delayTime = ammoDef.ReturnDelay or 0.05
	end

	task.delay(delayTime, function()
		if cosmeticBullet and cosmeticBullet.Parent then
			resetCosmeticPhysics(cosmeticBullet)

			local tr = cosmeticBullet:FindFirstChild("Trail")
			if tr then
				tr.Enabled = false
			end

			-- Hide before returning so cached projectiles do not flash in old positions.
			setCosmeticHidden(cosmeticBullet)

			provider:ReturnPart(cosmeticBullet)
		end
	end)
end

Caster.RayHit:Connect(OnRayHit)
Caster.RayPierced:Connect(OnRayPierced)
Caster.LengthChanged:Connect(OnRayUpdated)
Caster.CastTerminating:Connect(OnRayTerminated)

return enemyCombat