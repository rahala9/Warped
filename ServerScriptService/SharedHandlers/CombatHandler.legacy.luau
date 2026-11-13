--Roblox Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--Remote Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local MessagePlayerEvent = Remotes:WaitForChild("MessagePlayer")
local UpdateStaminaEvent = Remotes:WaitForChild("UpdateStamina")
local NoAmmoEvent = Remotes:WaitForChild("NoAmmo")
local Replicator = Remotes:WaitForChild("Replicator")
local PlayerStateChangeEvent = Remotes:WaitForChild("PlayerStateChange")
local WeaponEnergyEvent = Remotes:FindFirstChild("WeaponEnergy")
if not WeaponEnergyEvent then
	WeaponEnergyEvent = Instance.new("RemoteEvent")
	WeaponEnergyEvent.Name = "WeaponEnergy"
	WeaponEnergyEvent.Parent = Remotes
end
local ProjectilePresentationEvent = Remotes:FindFirstChild("ProjectilePresentation")
if not ProjectilePresentationEvent then
	ProjectilePresentationEvent = Instance.new("RemoteEvent")
	ProjectilePresentationEvent.Name = "ProjectilePresentation"
	ProjectilePresentationEvent.Parent = Remotes
end

--Functions
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local ShieldFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("ShieldFunctions"))
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local CombatFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("CombatFunctions"))
local PlayerMovementFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("PlayerMovementFunctions"))
local WeaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

--Definition Modules
local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local attacksModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks"))

--Assets
local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local EffectItems = SharedClientAssets:WaitForChild("FX")

local BoltOnWoodSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("BoltOnWood")
local BoltOnMetalSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("BoltOnMetal")
local GlassBreakSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("BulletGlass")
local EggSplatSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("EggSplat")
local FleshSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("EggSplat")

local FireLaserSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("FireLaser")
local LaserRecoSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("LaserRecoMetal")
local ShieldHitSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("ShieldHit")

local GrassFX = SharedClientAssets:WaitForChild("VFX"):WaitForChild("Grass")
local DirtFX = SharedClientAssets:WaitForChild("VFX"):WaitForChild("Dirt")
local PoisonGas = SharedClientAssets:WaitForChild("VFX"):WaitForChild("PoisonGas")

--Modules
local ImpactDecalsService = require(ServerScriptService.SharedServices:WaitForChild("ImpactDecalsService"))
local FastCast = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("FastCastRedux"))
local PartCacheModule = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("PartCache"))

--Gui

--Context and Actions

--Initialization
local defaultHitSound = BoltOnWoodSoundFX

--////////////////////////////////////////////////////////////////
-- Ammo config
--////////////////////////////////////////////////////////////////
local ammo = {
	["Rock"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Rock"), Stick = false, Trail = true},
	["NoAmmo"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Rock"), Stick = false},
	["Dart"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Dart"), Stick = true, BreakableMaterials = {["None"] = true}, Rotate = true},
	["Laser"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Laser"), Stick = false, Destroy = true, BreakableMaterials = {["Wood"] = true,["Concrete"] = true, ["Metal"] = true, ["Glass"]=true}, Rotate = false, Gravity = Vector3.new(0, 0, 0),DefaultSoundFX = BoltOnMetalSoundFX, SoundFXOnFlesh = FleshSoundFX, SoundFXOnGlass = GlassBreakSoundFX, FireSoundFX = FireLaserSoundFX, RecoSoundFX = LaserRecoSoundFX},
	["Harpoon"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Harpoon"), Stick = true, StickOffset = 1.5, RotateStickTwo = true, BreakableMaterials = {["None"] = true}, Rotate = false, Gravity = Vector3.new(0, 0, 0), Ripple = true, Splash = true, Rope = true},
	["Bolt"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Bolt"), Stick = true, RotateStickTwo = true, DefaultSoundFX = BoltOnWoodSoundFX, SoundFXOnWood = BoltOnWoodSoundFX, SoundFXOnMetal = BoltOnMetalSoundFX, BreakableMaterials = {["Glass"] = true}},
	["Glue"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Glue"), Stick = true, RotateStickOne = true},
	["Egg"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Egg"), Stick = true, RotateStickThree = true, DefaultSoundFX = EggSplatSoundFX, Trail = true},
	["Shuriken"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Shuriken"), Stick = true, RotateStickThree = true, DefaultSoundFX = BoltOnWoodSoundFX, SoundFXOnWood = BoltOnWoodSoundFX, SoundFXOnMetal = BoltOnMetalSoundFX, BreakableMaterials = {["Glass"] = true}, Trail = true},
	["LawnDart"] = {Item = SharedClientAssets:WaitForChild("Ammo"):WaitForChild("LawnDart"), Stick = true, Rotate = false, RotateStickThree = true, BreakableMaterials = {["Glass"] = true}},
}

--////////////////////////////////////////////////////////////////
-- FastCast settings
--////////////////////////////////////////////////////////////////
local DEBUG = false
local BULLET_MAXDIST = 1000
local BULLET_GRAVITY = Vector3.new(0, -workspace.Gravity * 0.5, 0)
local MIN_BULLET_SPREAD_ANGLE = 1
local MAX_BULLET_SPREAD_ANGLE = 4

-- bounce tuning
local SPEED_LOSS = 0.75
local MIN_SPEED  = 120
local EPSILON    = 0.05 -- studs, push the ray off the surface

local RNG = Random.new()
local TAU = math.pi * 2

FastCast.DebugLogging = false
FastCast.VisualizeCasts = false

--////////////////////////////////////////////////////////////////
-- Workspace folders / PartCaches (shared OK)
--////////////////////////////////////////////////////////////////
local SharedWorkspaceItems = workspace:WaitForChild("SharedWorkspaceItems")

local DartBulletsFolder = SharedWorkspaceItems:FindFirstChild("DartBulletsFolder")
local LaserBulletsFolder = SharedWorkspaceItems:FindFirstChild("LaserBulletsFolder")
local HarpoonBulletsFolder = SharedWorkspaceItems:FindFirstChild("HarpoonBulletsFolder")
local BoltBulletsFolder = SharedWorkspaceItems:FindFirstChild("BoltBulletsFolder")
local RockBulletsFolder = SharedWorkspaceItems:FindFirstChild("RockBulletsFolder")
local GlueBulletsFolder = SharedWorkspaceItems:FindFirstChild("GlueBulletsFolder")
local EggBulletsFolder = SharedWorkspaceItems:FindFirstChild("EggBulletsFolder")
local ShurikenBulletsFolder = SharedWorkspaceItems:FindFirstChild("ShurikenBulletsFolder")
local LawnDartBulletsFolder = SharedWorkspaceItems:FindFirstChild("LawnDartBulletsFolder")
local HelperPartsFolder = workspace:WaitForChild("HelperParts")
local BuildBlockersFolder = workspace:WaitForChild("BuildBlockers")

local BulletFolders = {
	["Dart"] = DartBulletsFolder,
	["Laser"] = LaserBulletsFolder,
	["Harpoon"] = HarpoonBulletsFolder,
	["Rock"] = RockBulletsFolder,
	["Glue"] = GlueBulletsFolder,
	["Bolt"] = BoltBulletsFolder,
	["LawnDart"] = LawnDartBulletsFolder,
	["Egg"] = EggBulletsFolder,
	["Shuriken"] = ShurikenBulletsFolder,
}

local DartPartProvider = PartCacheModule.new(ammo["Dart"].Item, 100, DartBulletsFolder)
local LaserPartProvider = PartCacheModule.new(ammo["Laser"].Item, 20, LaserBulletsFolder)
local HarpoonPartProvider = PartCacheModule.new(ammo["Harpoon"].Item, 100, HarpoonBulletsFolder)
local BoltPartProvider = PartCacheModule.new(ammo["Bolt"].Item, 100, BoltBulletsFolder)
local RockPartProvider = PartCacheModule.new(ammo["Rock"].Item, 100, RockBulletsFolder)
local GluePartProvider = PartCacheModule.new(ammo["Glue"].Item, 100, GlueBulletsFolder)
local EggPartProvider = PartCacheModule.new(ammo["Egg"].Item, 100, EggBulletsFolder)
local ShurikenPartProvider = PartCacheModule.new(ammo["Shuriken"].Item, 100, ShurikenBulletsFolder)
local LawnDartPartProvider = PartCacheModule.new(ammo["LawnDart"].Item, 100, LawnDartBulletsFolder)

local PartProviders = {
	["Dart"] = DartPartProvider,
	["Laser"] = LaserPartProvider,
	["Harpoon"] = HarpoonPartProvider,
	["Rock"] = RockPartProvider,
	["Glue"] = GluePartProvider,
	["Bolt"] = BoltPartProvider,
	["LawnDart"] = LawnDartPartProvider,
	["Egg"] = EggPartProvider,
	["Shuriken"] = ShurikenPartProvider,
}

ImpactDecalsService.Init({
	folderName = "ImpactDecals",
	hitPoolSize = 120,
	ricoPoolSize = 80,
})


local Caster = FastCast.new()
local NextPresentationShotId = 0

--////////////////////////////////////////////////////////////////
-- Per-player container
--////////////////////////////////////////////////////////////////
local PerPlayer = {} -- [userId] = { CanFire = true, Track = nil, Energy = {} }

local function GetPP(player)
	local uid = player.UserId
	local pp = PerPlayer[uid]
	if not pp then
		pp = { CanFire = true, Track = nil, Energy = {} }
		PerPlayer[uid] = pp
	end
	return pp
end

local function GetEnergyState(player, weapon)
	local config = WeaponInfo.GetEnergyConfig(weapon)
	if not config then
		return nil, nil
	end

	local pp = GetPP(player)
	local now = os.clock()
	local state = pp.Energy[weapon.Name]
	if not state then
		state = {
			Value = config.Capacity,
			LastUpdate = now,
			LastUse = -math.huge,
		}
		pp.Energy[weapon.Name] = state
	end

	state.Value = math.min(state.Value, config.Capacity)
	local recoveryStart = math.max(state.LastUpdate, state.LastUse + config.RecoveryDelay)
	if now > recoveryStart and state.Value < config.Capacity then
		state.Value = math.min(config.Capacity, state.Value + ((now - recoveryStart) * config.RecoveryRate))
	end
	state.LastUpdate = now

	return state, config
end

local function SendEnergyState(player, weapon, depleted)
	local state, config = GetEnergyState(player, weapon)
	if not state then
		return
	end

	WeaponEnergyEvent:FireClient(player, {
		WeaponName = weapon.Name,
		Energy = state.Value,
		Capacity = config.Capacity,
		Cost = config.Cost,
		RecoveryRate = config.RecoveryRate,
		RecoveryDelay = config.RecoveryDelay,
		RecoveryDelayRemaining = math.max(0, (state.LastUse + config.RecoveryDelay) - os.clock()),
		Color = config.Color,
		Depleted = depleted == true,
	})
end

local function TryConsumeEnergy(player, weapon)
	local state, config = GetEnergyState(player, weapon)
	if not state then
		return true
	end

	if state.Value + 0.001 < config.Cost then
		SendEnergyState(player, weapon, true)
		return false
	end

	local now = os.clock()
	state.Value = math.max(0, state.Value - config.Cost)
	state.LastUse = now
	state.LastUpdate = now
	SendEnergyState(player, weapon, false)
	return true
end

WeaponEnergyEvent.OnServerEvent:Connect(function(player, action, weaponName)
	if action ~= "Request" or type(weaponName) ~= "string" then
		return
	end

	if StatesFunctions.GetCurrentTool(player) ~= weaponName then
		return
	end

	local weapon = itemsmodule[weaponName]
	if WeaponInfo.IsEnergyWeapon(weapon) then
		SendEnergyState(player, weapon, false)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PerPlayer[player.UserId] = nil
end)

--////////////////////////////////////////////////////////////////
-- FX modules preload
--////////////////////////////////////////////////////////////////
local FXModules = {}
for _, mod in ipairs(ServerScriptService.SharedFX:GetChildren()) do
	if mod:IsA("ModuleScript") and mod.Name ~= "FXTemplate" then
		FXModules[mod.Name] = require(mod)
	end
end

local R = Random.new()

--////////////////////////////////////////////////////////////////
-- Helpers: per-shot RaycastParams + per-shot FastCast Behavior
--////////////////////////////////////////////////////////////////
local function MakeRayParamsForPlayer(player)
	local params = RaycastParams.new()
	params.IgnoreWater = true
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.CollisionGroup = "Ammo"
	params.FilterDescendantsInstances = {
		player.Character,
		DartBulletsFolder, LaserBulletsFolder, RockBulletsFolder, BoltBulletsFolder, EggBulletsFolder,
		HarpoonBulletsFolder, ShurikenBulletsFolder, LawnDartBulletsFolder, GlueBulletsFolder,
		HelperPartsFolder, BuildBlockersFolder,
		workspace:FindFirstChild("Zones"),
	}
	return params
end

local function MakeBehaviorForShot(rayParams, weaponAmmo)
	local b = FastCast.newBehavior()
	b.RaycastParams = rayParams
	b.MaxDistance = BULLET_MAXDIST
	b.AutoIgnoreContainer = false
	b.CanPierceFunction = CanRayPierce
	b.Acceleration = (ammo[weaponAmmo] and ammo[weaponAmmo].Gravity) or BULLET_GRAVITY

	if weaponAmmo ~= "NoAmmo" then
		b.CosmeticBulletProvider = PartProviders[weaponAmmo]
		b.CosmeticBulletContainer = BulletFolders[weaponAmmo]
	end

	return b
end

--////////////////////////////////////////////////////////////////
-- Sound helpers (FIXED: clone + parent locally)
--////////////////////////////////////////////////////////////////
local function PlaySoundAt(soundTemplate: Sound?, parent: Instance?)
	if not soundTemplate or not parent then return end
	local soundFx = soundTemplate:Clone()
	soundFx.Parent = parent
	soundFx:Play()
	local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
	print("LASER SOUND FX TIME:",lifetime)
	Debris:AddItem(soundFx, lifetime)
end

local function PlayFireSound(ammoDef, parent)
	if ammoDef and ammoDef.FireSoundFX then
		PlaySoundAt(ammoDef.FireSoundFX, parent)
	end
end

local function PlayRecoSound(ammoDef, parent)
	if ammoDef and ammoDef.RecoSoundFX then
		PlaySoundAt(ammoDef.RecoSoundFX, parent)
	end
end

local function MakeParticleFX(position, normal)
	-- intentionally blank
end

local function spawner(func, ...)
	local co = coroutine.wrap(func)
	co(...)
end

local function Reflect(surfaceNormal, bulletDirUnit)
	return bulletDirUnit - (2 * bulletDirUnit:Dot(surfaceNormal) * surfaceNormal)
end

--////////////////////////////////////////////////////////////////
-- Pierce (FIXED: decides bounce vs final)
-- Return true  => FastCast fires RayPierced (we treat as bounce)
-- Return false => FastCast fires RayHit     (we treat as final impact)
--////////////////////////////////////////////////////////////////
function CanRayPierce(cast, rayResult, segmentVelocity)
	local hitPart = rayResult.Instance
	if hitPart and CollectionService:HasTag(hitPart, "Shield") then
		-- mark so HandleHit can do shield-specific logic if you want
		cast.UserData.HitShield = true
		return false -- IMPORTANT: forces "final hit" path (RayHit), no ricochet
	end
	
	if (hitPart and hitPart.Parent and hitPart.Parent:GetAttribute("Breakable")) then
		return false
	end
	
	cast.UserData.Hits = (cast.UserData.Hits or 0) + 1

	-- IMPORTANT: check the *next* speed (after loss). If too slow, stop here (final hit).
	local nextSpeed = segmentVelocity.Magnitude * SPEED_LOSS
	if nextSpeed < MIN_SPEED then
		return false
	end

	-- Otherwise, allow continuation (bounce)
	return true
end

--////////////////////////////////////////////////////////////////
-- Hit effects / sounds
--////////////////////////////////////////////////////////////////
local function HandlePoisonGas(player, hitPart)
	local gas = PoisonGas:Clone()
	gas.Position = hitPart.Position
	gas.CanCollide = false
	gas.Anchored = true
	gas.Parent = workspace
	gas.PoisonGasSource:Emit(25)

	spawner(function()
		local enemiesSnapshot = enemyFunctions.GetEnemies()

		for _, enemy in pairs(enemiesSnapshot) do
			local distance = (enemy.root.Position - gas.Position).Magnitude
			if distance < 20 then
				EffectsFunctions.AddEnemyEffect(player, enemy, "Poison")
			end
		end

		for _, ply in pairs(Players:GetChildren()) do
			if ply.Character and ply.Character.PrimaryPart then
				if (ply.Character.PrimaryPart.Position - gas.Position).Magnitude < 20 then
					EffectsFunctions.AddEffect(ply, "Poison", ProgressFunctions.GetLevel(player))
				end
			end
		end
	end)

	Debris:AddItem(gas, 5)
end

local function HandleHitEffects(player, hitPart, hitPoint, hitMaterial)
	if hitPart:GetAttribute("HitEffect_Unanchor") then
		hitPart.Anchored = false
	end
	if hitPart:GetAttribute("HitEffect_DebrisModel") then
		if hitPart.Parent and hitPart.Parent:IsA("Model") then
			Debris:AddItem(hitPart.Parent, 5)
		end
	end
	if hitPart:GetAttribute("HitEffect_Invis") then
		hitPart.Transparency = 1
	end
	if hitPart:GetAttribute("HitEffect_SizeSmall") then
		hitPart.Size = Vector3.new(1, 1, 1)
		hitPart.Massless = true
	end
	if hitPart:GetAttribute("HitEffect_Destroy") then
		hitPart:Destroy()
	end
	if hitPart:GetAttribute("HitEffect_PoisonGas") then
		HandlePoisonGas(player, hitPart)
	end
	if hitPart:GetAttribute("HitEffect_SibRopeShorten") then
		hitPart.Parent.RopeConstraint.Length = hitPart.Parent.RopeConstraint.Length / 2
		hitPart.Parent.RopeConstraint.Restitution = .2
	end

	if hitPart:IsA("Terrain") then
		local terrainFX
		if hitMaterial == Enum.Material.LeafyGrass then
			terrainFX = GrassFX:Clone()
		elseif hitMaterial == Enum.Material.Ground then
			terrainFX = DirtFX:Clone()
		end

		if terrainFX then
			terrainFX.Position = hitPoint
			terrainFX.Parent = workspace
			terrainFX.FX:Emit(100)
			Debris:AddItem(terrainFX, 2)
		end
	end
end

local function HandleHitSoundFx(hitPart, cosmeticBulletObject)
	local hitSound = hitPart:FindFirstChild("HitSound")
	if hitSound then
		hitSound:Play()
		return
	end
	
	print("PLAY FINAL HIT SOUND")
		
	if (CollectionService:HasTag(hitPart,"Shield")) then
		local soundFx = ShieldHitSoundFX:Clone()
		soundFx.Parent = hitPart
		soundFx:Play()
		local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
		Debris:AddItem(soundFx, lifetime)
		return
	end

	local ammoName = cosmeticBulletObject and cosmeticBulletObject.Name
	if not ammoName or not ammo[ammoName] then
		local soundFx = defaultHitSound:Clone()
		soundFx.Parent = hitPart
		soundFx:Play()
		local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
		Debris:AddItem(soundFx, lifetime)
		return
	end

	if (hitPart:GetAttribute("Material") == "Wood") or (hitPart.Parent and hitPart.Parent:GetAttribute("Material") == "Wood") then
		
		if (hitPart and hitPart.Parent and hitPart.Parent:GetAttribute("Breakable")) then
			return
		end
		
		local s = ammo[ammoName].SoundFXOnWood or ammo[ammoName].DefaultSoundFX
		if s then
			local soundFx = s:Clone()
			soundFx.Parent = hitPart
			soundFx:Play()
			local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
			Debris:AddItem(soundFx, lifetime)
			return
		end
	elseif (hitPart:GetAttribute("Material") == "Metal") or (hitPart.Parent and hitPart.Parent:GetAttribute("Material") == "Metal") then
		local s = ammo[ammoName].SoundFXOnMetal or ammo[ammoName].DefaultSoundFX
		if s then
			local soundFx = s:Clone()
			soundFx.Parent = hitPart
			soundFx:Play()
			local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
			Debris:AddItem(soundFx, lifetime)
			return
		end
	elseif (hitPart:GetAttribute("Material") == "Glass") or (hitPart.Parent and hitPart.Parent:GetAttribute("Material") == "Glass") then
		local s = ammo[ammoName].SoundFXOnGlass or ammo[ammoName].DefaultSoundFX
		if s then
			local soundFx = s:Clone()
			soundFx.Parent = hitPart
			soundFx:Play()
			local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
			Debris:AddItem(soundFx, lifetime)
			return
		end
	elseif (hitPart:GetAttribute("Material") == "Flesh") or (hitPart.Parent and hitPart.Parent:GetAttribute("Material") == "Flesh") then
		local s = ammo[ammoName].SoundFXOnFlesh or ammo[ammoName].DefaultSoundFX
		if s then
			local soundFx = s:Clone()
			soundFx.Parent = hitPart
			soundFx:Play()
			local lifetime = math.max(0.25, (soundFx.TimeLength > 0 and soundFx.TimeLength) or 1)
			Debris:AddItem(soundFx, lifetime)
			return
		end
	end

	local use = ammo[ammoName].DefaultSoundFX or defaultHitSound
	local soundFx = use:Clone()
	soundFx.Parent = hitPart
	soundFx:Play()
	Debris:AddItem(soundFx, 3)
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

	local splat = cosmetic:FindFirstChild("Splat")
	if splat then splat.Transparency = 1 end

	provider:ReturnPart(cosmetic)
end

--////////////////////////////////////////////////////////////////
-- HandleHit (FIXED: no ricochet sound here; no drop behavior on bounces)
-- pierced == true  => bounce impact (RayPierced)
-- pierced == false => final impact  (RayHit)
--////////////////////////////////////////////////////////////////
local function HandleHit(cast, raycastResult, cosmeticBulletObject, pierced, hitDir)
	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	print("TEST HIT hitPart:",hitPart.Name,hitPart,hitPart.CanQuery)
	local player = cast.UserData.Player
	local weaponAmmo = cast.UserData.WeaponAmmo

	if cosmeticBulletObject then
		local tr = cosmeticBulletObject:FindFirstChild("Trail")
		if tr then tr.Enabled = false end

		-- FINAL-only stick/destroy/drop logic
		if (not pierced) and ammo[cosmeticBulletObject.Name] and ammo[cosmeticBulletObject.Name].Stick then
			if cosmeticBulletObject:GetAttribute("HasSplat") then
				cosmeticBulletObject.CFrame = CFrame.new(hitPoint, hitPoint + normal)
				cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal * -0.9)
				cosmeticBulletObject.Transparency = 1
				cosmeticBulletObject.Splat.Transparency = 0
				cosmeticBulletObject.Splat.CFrame = cosmeticBulletObject.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
				cosmeticBulletObject.Splat.Position = cosmeticBulletObject.Splat.Position + (normal)
			else
				cosmeticBulletObject.CFrame = CFrame.new(hitPoint, hitPoint + normal)
				if ammo[cosmeticBulletObject.Name].StickOffset then
					cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal * 1.5)
				else
					cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal * 0.5)
				end
			end

			if ammo[cosmeticBulletObject.Name].Ripple and cosmeticBulletObject:FindFirstChild("WaterFXAttachment") then
				cosmeticBulletObject.WaterFXAttachment.RIPPLE.Enabled = false
			end
			if ammo[cosmeticBulletObject.Name].Splash and cosmeticBulletObject:FindFirstChild("WaterFXAttachment") then
				cosmeticBulletObject.WaterFXAttachment.SPLASH.Enabled = false
			end

		elseif (not pierced) and ammo[cosmeticBulletObject.Name] and ammo[cosmeticBulletObject.Name].Destroy then
			-- Final hit for destroy-ammo: effects + final hit sound, then return to cache immediately
			HandleHitEffects(player, hitPart, hitPoint, raycastResult.Material)
			HandleHitSoundFx(hitPart, cosmeticBulletObject)

			local provider = cast.UserData.PartProvider
			if provider then
				ReturnBullet(cosmeticBulletObject, provider)
			else
				cosmeticBulletObject:Destroy()
			end
			cosmeticBulletObject = nil

		elseif (not pierced) then
			-- Final hit for non-stick/non-destroy: let it fall / collide
			cosmeticBulletObject.Anchored = false
			cosmeticBulletObject.CanCollide = true
		end

		-- Shared effects; sound ONLY on final hit (non-destroy path)
		if cosmeticBulletObject then
			HandleHitEffects(player, hitPart, hitPoint, raycastResult.Material)

			if not pierced then
				HandleHitSoundFx(hitPart, cosmeticBulletObject)
			end

			-- Orientation (keep as you had)
			local rotatedCFrame
			if ammo[cosmeticBulletObject.Name].RotateStickOne then
				rotatedCFrame = CFrame.Angles(math.rad(-90), math.rad(-90), 0)
			elseif ammo[cosmeticBulletObject.Name].RotateStickTwo then
				rotatedCFrame = CFrame.Angles(0, math.rad(180), 0)
			elseif ammo[cosmeticBulletObject.Name].RotateStickThree then
				rotatedCFrame = CFrame.Angles(0, 0, 0)
			else
				rotatedCFrame = CFrame.Angles(0, math.rad(-90), 0)
			end
			cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
		end
	end
	
	if (CollectionService:HasTag(hitPart,"Shield")) then

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
	else
		--print("TEST HIT:",hitPart)
		

	end

	-- Enemy/env logic (unchanged)
	if hitPart and hitPart.Parent then
		local enemy = enemyFunctions.GetEnemy(hitPart.Parent)
		if enemy then
			-- Prevent the same projectile/cast from damaging the same enemy more than once,
			-- including after ricochets.
			cast.UserData.HitEnemies = cast.UserData.HitEnemies or {}

			local enemyKey =
				enemy.id
				or enemy.enemyId
				or enemy.model
				or enemy.root
				or hitPart.Parent

			if not cast.UserData.HitEnemies[enemyKey] then
				cast.UserData.HitEnemies[enemyKey] = true

				enemyFunctions.HandleBodyPartHit(
					player,
					enemy,
					cast.UserData.WeaponName,
					attacksModule[cast.UserData.AttackName],
					0,
					hitPart,
					hitPart:GetAttribute("Critical"),
					hitPart:GetAttribute("CriticalName")
				)

				MakeParticleFX(hitPoint, normal)
			else
				if DEBUG then
					print("[CombatHandler] Ignored duplicate enemy hit from same cast:", enemyKey)
				end
			end
		end
	end
end

--////////////////////////////////////////////////////////////////
-- Ranged firing (unchanged except fire/reco sound now parented to bullet)
--////////////////////////////////////////////////////////////////
local function Fire(player, origin, directionInput, heldTool, weapon, keycode, mouseHit, HeldToolHandle)
	local directionalCF = CFrame.new(Vector3.new(), directionInput)

	local direction
	local attackCfg = weapon.WeaponAttacks[keycode.Name]
	local attackName = attackCfg and attackCfg.Name
	local attack = attackName and attacksModule[attackName]

	--if attack and attack.MinSpreadAngle ~= nil then
	local distance = (origin - mouseHit).Magnitude
	local isMoving = PlayerMovementFunctions.IsPlayerMoving(player)
	local minSpreadAngle,maxSpreadAngle = CombatFunctions.CalculateSpreadAngles(player, weapon, distance, isMoving)
	
	print("TEST DAMAGE ACCURACY:",minSpreadAngle,maxSpreadAngle)
		direction =
			(directionalCF
				* CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU))
			* CFrame.fromOrientation(math.rad(RNG:NextNumber(minSpreadAngle, maxSpreadAngle)), 0, 0)
			).LookVector
	--end

	local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local modifiedBulletVelocity = (direction * weapon.WeaponAmmoSpeed)

	local rayParams = MakeRayParamsForPlayer(player)
	local behavior = MakeBehaviorForShot(rayParams, weapon.WeaponAmmo)

	local simBullet = Caster:Fire(origin, direction, modifiedBulletVelocity, behavior)
	NextPresentationShotId += 1
	local presentationShotId = NextPresentationShotId
	local presentationCosmetic = simBullet.RayInfo and simBullet.RayInfo.CosmeticBulletObject
	if presentationCosmetic and WeaponInfo.IsEnergyWeapon(weapon) then
		presentationCosmetic:SetAttribute("PresentationShooterUserId", player.UserId)
		presentationCosmetic:SetAttribute("PresentationShotId", presentationShotId)
	end
	if WeaponInfo.IsEnergyWeapon(weapon) then
		ProjectilePresentationEvent:FireAllClients(
			player,
			weapon.Name,
			origin,
			direction,
			weapon.WeaponAmmoSpeed,
			weapon.WeaponMaxDistance,
			presentationShotId
		)
	else
		-- The shooter still needs a server-confirmed event for recoil even when
		-- this presentation system has no muzzle effect for the damage type.
		ProjectilePresentationEvent:FireClient(player, player, weapon.Name, origin, direction)
	end

	simBullet.UserData.Player = player
	simBullet.UserData.WeaponName = weapon
	simBullet.UserData.AttackName = itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name
	simBullet.UserData.PartProvider = behavior.CosmeticBulletProvider
	simBullet.UserData.WeaponAmmo = weapon.WeaponAmmo

	if weapon.WeaponAmmo ~= "NoAmmo" then
		local cosmetic = simBullet.RayInfo and simBullet.RayInfo.CosmeticBulletObject
		if cosmetic then
			if ammo[weapon.WeaponAmmo].Trail and cosmetic:FindFirstChild("Trail") then
				cosmetic.Trail.Enabled = true
			end

			if ammo[weapon.WeaponAmmo].Rope and cosmetic:FindFirstChild("RopeConstraint") then
				local rope = cosmetic.RopeConstraint
				local distance = (origin - mouseHit).Magnitude
				rope.Attachment0 = rope.Parent.RopeEnd
				rope.Attachment1 = HeldToolHandle.RopeStart
				rope.Length = distance
			end

			if ammo[weapon.WeaponAmmo].Ripple and cosmetic:FindFirstChild("WaterFXAttachment") then
				cosmetic.WaterFXAttachment.RIPPLE.Enabled = StatesFunctions.GetUnderWater(player)
			end

			if ammo[weapon.WeaponAmmo].Splash and cosmetic:FindFirstChild("WaterFXAttachment") then
				cosmetic.WaterFXAttachment.SPLASH.Enabled = StatesFunctions.GetUnderWater(player)
			end

			-- FIX: fire sound is cloned + played from the bullet
			PlayFireSound(ammo[weapon.WeaponAmmo], cosmetic)
		else
			-- fallback (rare): play from workspace if bullet didn't exist
			PlayFireSound(ammo[weapon.WeaponAmmo], workspace)
		end
	end
end

--////////////////////////////////////////////////////////////////
-- FastCast event hooks (FIXED: sound routing)
--////////////////////////////////////////////////////////////////
local function OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	-- FINAL HIT only
	if ( not cast.UserData.HitShield) then
		
		local hitPart = raycastResult.Instance
		if (hitPart and hitPart.Parent) then
						
			if (not hitPart.Parent:GetAttribute("Breakable")) and (not hitPart.Parent:GetAttribute("EnemyID")) then
				ImpactDecalsService.SpawnHit(raycastResult, cast.UserData.WeaponAmmo, {
					parentMode = "hitPart",
				})
			end
		end
	end
	
	HandleHit(cast, raycastResult, cosmeticBulletObject, false, segmentVelocity.Unit)
end

local function OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	-- BOUNCE HIT only (no final hit sound inside HandleHit)
	ImpactDecalsService.SpawnRicochet(raycastResult, cast.UserData.WeaponAmmo, {
		parentMode = "hitPart",
	})
	HandleHit(cast, raycastResult, cosmeticBulletObject, true, segmentVelocity.Unit)

	-- ricochet sound here (bounce-only)
	if cosmeticBulletObject and ammo[cosmeticBulletObject.Name] then
		PlayRecoSound(ammo[cosmeticBulletObject.Name], cosmeticBulletObject)
	end

	local normal = raycastResult.Normal
	local inDir  = segmentVelocity.Unit
	local outDir = Reflect(normal, inDir)

	local newSpeed = segmentVelocity.Magnitude * SPEED_LOSS
	-- (If it ever gets here below min, it means CanRayPierce returned true anyway; this is a safety clamp)
	if newSpeed < MIN_SPEED then
		newSpeed = MIN_SPEED
	end

	cast:SetVelocity(outDir * newSpeed)
	cast:SetPosition(raycastResult.Position + outDir * EPSILON)
end

local function OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if cosmeticBulletObject == nil then return end

	local bulletLength = cosmeticBulletObject.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))

	if ammo[cosmeticBulletObject.Name] and ammo[cosmeticBulletObject.Name].Rotate then
		local rotatedCFrame = CFrame.Angles(0, math.rad(90), 0)
		cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
	end
end

local function OnRayTerminated(cast)
	local player = cast.UserData.Player
	local cosmeticBullet = cast.RayInfo and cast.RayInfo.CosmeticBulletObject
	local provider = cast.UserData.PartProvider

	if cosmeticBullet ~= nil then
		cosmeticBullet:SetAttribute("PresentationShooterUserId", nil)
		cosmeticBullet:SetAttribute("PresentationShotId", nil)
		if ammo[cosmeticBullet.Name] and ammo[cosmeticBullet.Name].Destroy then
			if provider then
				ReturnBullet(cosmeticBullet, provider)
			else
				cosmeticBullet:Destroy()
			end
		else
			task.delay(10, function()
				if cosmeticBullet and cosmeticBullet.Parent then
					if ammo[cosmeticBullet.Name] and ammo[cosmeticBullet.Name].Ripple and cosmeticBullet:FindFirstChild("WaterFXAttachment") then
						cosmeticBullet.WaterFXAttachment.RIPPLE.Enabled = StatesFunctions.GetUnderWater(player)
					end

					if ammo[cosmeticBullet.Name] and ammo[cosmeticBullet.Name].Splash and cosmeticBullet:FindFirstChild("WaterFXAttachment") then
						cosmeticBullet.WaterFXAttachment.SPLASH.Enabled = StatesFunctions.GetUnderWater(player)
					end

					cosmeticBullet.CanCollide = true
					cosmeticBullet.Anchored = false

					task.wait(2)

					if ammo[cosmeticBullet.Name] and ammo[cosmeticBullet.Name].Ripple and cosmeticBullet:FindFirstChild("WaterFXAttachment") then
						cosmeticBullet.WaterFXAttachment.RIPPLE.Enabled = false
					end

					if ammo[cosmeticBullet.Name] and ammo[cosmeticBullet.Name].Splash and cosmeticBullet:FindFirstChild("WaterFXAttachment") then
						cosmeticBullet.WaterFXAttachment.SPLASH.Enabled = false
					end

					cosmeticBullet.CanCollide = false
					cosmeticBullet.Anchored = true

					if provider then
						ReturnBullet(cosmeticBullet, provider)
					else
						cosmeticBullet:Destroy()
					end
				end
			end)
		end
	end
end

Caster.RayHit:Connect(OnRayHit)
Caster.RayPierced:Connect(OnRayPierced)
Caster.LengthChanged:Connect(OnRayUpdated)
Caster.CastTerminating:Connect(OnRayTerminated)

--////////////////////////////////////////////////////////////////
-- NOTE:
-- Everything below here is your original input/combat handling.
-- Keep it as-is from your file (unchanged).
--////////////////////////////////////////////////////////////////

--////////////////////////////////////////////////////////////////
-- Combat helpers (unchanged)
--////////////////////////////////////////////////////////////////
local function HandleAutoMelee(player, weapon, keycode, mouseHit, heldToolName)
	local character = player.Character
	if not character then return end

	local attack = attacksModule[weapon.WeaponAttacks[keycode.Name].Name]

	local handle = ToolFunctions.GetToolHandle(player, heldToolName)
	if not handle then return end

	local HeldToolTransformedWorldCFrame = handle.TransformedWorldCFrame
	local origin = HeldToolTransformedWorldCFrame.p

	local down = -handle.TransformedWorldCFrame.UpVector
	local tipPosition = (origin - down)
	local direction = (tipPosition - origin).Unit * 10

	local list = {
		player.Character,
		DartBulletsFolder, LaserBulletsFolder, RockBulletsFolder, BoltBulletsFolder, EggBulletsFolder,
		HarpoonBulletsFolder, ShurikenBulletsFolder, LawnDartBulletsFolder, GlueBulletsFolder,
		HelperPartsFolder, BuildBlockersFolder,
	}
	table.insert(list, workspace:FindFirstChild("Zones"))
	table.insert(list, workspace.Terrain)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = list
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true

	local Raycast = workspace:Raycast(origin, direction, params)
	if Raycast then
		local HitPart = Raycast.Instance
		if HitPart and HitPart.Parent then
			local enemy = enemyFunctions.GetEnemy(HitPart.Parent)
			if enemy then
				enemyFunctions.HandleBodyPartHit(player, enemy, weapon, attack)
			end
			enemyFunctions.HandleEnvironmentalTarget(player, HitPart.Parent)
		end
	end

	if attack.SoundFX ~= nil then
		local weaponItem = character:FindFirstChild(weapon.Name)
		if weaponItem then
			local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
			if soundFX and (not soundFX.IsPlaying) then
				soundFX:Play()
			end
		end
	end

	if WeaponInfo.UsesAmmo(weapon) then
		InventoryFunctions.RemoveItem(player, weapon.WeaponAmmo, 1, true)
	end
end

local function HandleVFX(player, weapon, keycode)
	if not itemsmodule[weapon.Name]["VFX"] then
		return
	end

	local hand = itemsmodule[weapon.Name].Hand
	if hand == nil then
		hand = "Right"
	end

	local character = player.Character
	if not character then return end

	local leftHand = character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"]
	local rightHand = character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

	if hand == "Left" then
		if leftHand[weapon.Model .. "Handle"] and leftHand[weapon.Model .. "Handle"][weapon.Name .. "Particles"] then
			leftHand[weapon.Model .. "Handle"][weapon.Name .. "Particles"]:Emit(10)
		end
	elseif hand == "Right" then
		if rightHand[weapon.Model .. "Handle"] then
			if weapon.Name == "DeathRay" and rightHand[weapon.Model .. "Handle"].Attachment then
				spawner(function()
					rightHand[weapon.Model .. "Handle"].Attachment[weapon.Name .. "Particles1"]:Emit(300)
					task.wait(.1)
					rightHand[weapon.Model .. "Handle"].Attachment[weapon.Name .. "Particles2"]:Emit(1000)
					task.wait(.1)
					rightHand[weapon.Model .. "Handle"].Attachment[weapon.Name .. "Particles2"]:Emit(1000)
					task.wait(.1)
					rightHand[weapon.Model .. "Handle"].Attachment[weapon.Name .. "Particles2"]:Emit(1000)
					task.wait(.1)
					rightHand[weapon.Model .. "Handle"].Attachment[weapon.Name .. "Particles2"]:Emit(1000)
				end)
			elseif rightHand[weapon.Model .. "Handle"][weapon.Name .. "Particles"] then
				rightHand[weapon.Model .. "Handle"][weapon.Name .. "Particles"]:Emit(10)
			end
		end
	elseif hand == "Both" then
		if leftHand[weapon.Model .. "LeftHandle"] and leftHand[weapon.Model .. "LeftHandle"][weapon.Name .. "Particles"] then
			leftHand[weapon.Model .. "LeftHandle"][weapon.Name .. "Particles"]:Emit(10)
		end
		if rightHand[weapon.Model .. "RightHandle"] and rightHand[weapon.Model .. "RightHandle"][weapon.Name .. "Particles"] then
			rightHand[weapon.Model .. "RightHandle"][weapon.Name .. "Particles"]:Emit(10)
		end
	end
end

local function HandleMelee(player, weapon, keycode)
	local character = player.Character
	if not character then return end

	local attack = attacksModule[weapon.WeaponAttacks[keycode.Name].Name]
	PlayerStateChangeEvent:FireClient(player, "Attacking", attack)

	if attack.SoundFX ~= nil then
		local weaponItem = character:FindFirstChild(weapon.Name)
		if weaponItem then
			local soundFX = weaponItem:FindFirstChild(attack.Name)
			if soundFX then
				soundFX:Play()
			end
		end
	end

	HandleVFX(player, weapon, keycode)

	local numberOfTargets = 0

	for _, enemy in pairs(enemyFunctions.GetEnemies()) do
		local distance = (enemy.root.Position - player.Character.PrimaryPart.Position).Magnitude
		if distance < (enemy.hitRange) then
			local npcToCharacter = (character.HumanoidRootPart.Position - enemy.root.Position).Unit
			local npcLook = character.HumanoidRootPart.CFrame.LookVector
			local dotProduct = npcToCharacter:Dot(npcLook)

			if dotProduct < .3 then
				numberOfTargets += 1

				if attack.MultiTarget ~= nil then
					if numberOfTargets >= attack.MultiTarget then
						return
					end

					enemyFunctions.HandleBodyPartHit(player, enemy, weapon, attack)
					if attack.Effect and attack.Effect ~= "" then
						EffectsFunctions.AddEnemyEffect(player, enemy, attack.Effect, weapon, attack)
					end
				else
					enemyFunctions.HandleBodyPartHit(player, enemy, weapon, attack)
					if attack.Effect and attack.Effect ~= "" then
						EffectsFunctions.AddEnemyEffect(player, enemy, attack.Effect, weapon, attack)
					end
					return
				end
			end
		end
	end

	for _, envTarget in pairs(CollectionService:GetTagged("EnvironmentalTarget")) do
		local distance = (envTarget.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
		if distance < 10 then
			enemyFunctions.HandleEnvironmentalTarget(player, envTarget)
		end
	end
end

local function HandleFX(player, weapon, keycode, target, ToolTransformedWorldCFrame)
	local fxFunc = FXModules[weapon.Name]
	if fxFunc then
		local Data = {}
		fxFunc(
			player,
			CFrame.new(target),
			weapon,
			attacksModule[itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name],
			ToolTransformedWorldCFrame,
			Data
		)
	else
		Replicator:FireAllClients(weapon.Name)
	end
end

local function HandleArtifact(player, weapon, keycode, target)
	HandleFX(player, weapon, keycode, target)
end

local function HandleTrap(player, weapon, keycode)
	-- TODO
end

--////////////////////////////////////////////////////////////////
-- Ranged wrapper (unchanged, uses Fire() already defined above)
--////////////////////////////////////////////////////////////////
local function HandleRanged(player, weapon, keycode, mouseHit, heldToolName, ToolTransformedWorldCFrame, HeldToolHandle)
	local pp = GetPP(player)
	if not pp.CanFire then
		return
	end
	pp.CanFire = false

	if itemsmodule[weapon.Name].FX then
		HandleFX(player, weapon, keycode, mouseHit, ToolTransformedWorldCFrame)
		pp.CanFire = true
		return
	end

	if itemsmodule[weapon.Name].VFX then
		HandleVFX(player, weapon, keycode)
	end

	local origin = ToolTransformedWorldCFrame.p
	local direction = (mouseHit - origin).Unit

	if weapon.WeaponAttacks[keycode.Name].Multishot ~= nil then
		for _ = 1, weapon.WeaponAttacks[keycode.Name].Multishot do
			Fire(player, origin, direction, player.Character[heldToolName], weapon, keycode, mouseHit, HeldToolHandle)

			if WeaponInfo.UsesAmmo(weapon) then
				InventoryFunctions.RemoveItem(player, weapon.WeaponAmmo, 1, true, true)
			end
		end
	else
		Fire(player, origin, direction, player.Character[heldToolName], weapon, keycode, mouseHit, HeldToolHandle)

		if WeaponInfo.UsesAmmo(weapon) then
			InventoryFunctions.RemoveItem(player, weapon.WeaponAmmo, 1, true, true)
		end
	end

	pp.CanFire = true
end

--////////////////////////////////////////////////////////////////
-- Input handling (unchanged)
--////////////////////////////////////////////////////////////////
local playerLastAttack = {} -- [userId] = os.time()

ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerInput").OnServerEvent:Connect(function(player, keycode, mouseHit, ToolTransformedWorldCFrame)
	local heldToolName = StatesFunctions.GetCurrentTool(player)
	if heldToolName == "" then
		return
	end

	local item = itemsmodule[heldToolName]
	if item == nil then
		warn("CombatHandler.PlayerInput item not found: ", heldToolName)
		return
	end

	if (keycode == Enum.KeyCode.R) or (keycode == Enum.KeyCode.F) or (keycode == Enum.KeyCode.G) then
		if (item.Type ~= "Weapon" and item.Type ~= "OffHand" and item.Type ~= "Artifact") then
			return
		end

		if WeaponInfo.UsesAmmo(item)
			and not InventoryFunctions.HasItem(player, itemsmodule[item.Name].WeaponAmmo, 1, true, true)
		then
			NoAmmoEvent:FireClient(player, true)
			return
		end

		local elapsedTime = os.clock() - StatesFunctions.GetLastFireTime(player)
		local weaponspeed = item.WeaponSpeed
		local fireRateTime = 10 / weaponspeed

		if elapsedTime < fireRateTime then
			return
		end

		local nowTime = os.time()
		local uid = player.UserId

		if item.Type == "Weapon" then
			if (not InventoryFunctions.HasWeaponEquipped(player, heldToolName) or (itemsmodule[heldToolName].Type ~= "Weapon")) then
				return
			end

			if InventoryFunctions.TimeElapsedSinceLastUse(player, heldToolName, keycode) < attacksModule[item.WeaponAttacks[keycode.Name].Name].Cooldown then
				return
			end

			if item.SubType == "Ranged" and WeaponInfo.IsEnergyWeapon(item) then
				if not TryConsumeEnergy(player, item) then
					return
				end
			end

			StatesFunctions.SetLastFireTime(player, os.clock())
			InventoryFunctions.UpdateLastUsed(player, heldToolName, keycode, nowTime)
			playerLastAttack[uid] = nowTime

			local character = player.Character
			if not character then return end

			local attack = attacksModule[item.WeaponAttacks[keycode.Name].Name]

			if item.SubType == "Melee" then
				if not item.Auto then
					HandleMelee(player, item, keycode)
				else
					if keycode == Enum.KeyCode.R then
						if attack.SoundFX ~= nil then
							local weaponItem = character:FindFirstChild(item.Name)
							if weaponItem then
								local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
								if soundFX and (not soundFX.IsPlaying) then
									soundFX:Play()
								end
							end
						end
					elseif keycode == Enum.KeyCode.F then
						if attack.SoundFX ~= nil then
							local weaponItem = character:FindFirstChild(item.Name)
							if weaponItem then
								local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
								if soundFX and soundFX.IsPlaying then
									soundFX:Stop()
								end
							end
						end
					elseif keycode == Enum.KeyCode.G then
						HandleAutoMelee(player, item, keycode, mouseHit, heldToolName)
					end
				end

			elseif item.SubType == "Ranged" then
				local HeldToolHandle = ToolFunctions.GetToolHandle(player, heldToolName)
				HandleRanged(player, item, keycode, mouseHit, heldToolName, ToolTransformedWorldCFrame, HeldToolHandle)

			elseif item.SubType == "Trap" then
				HandleTrap(player, item, keycode)
			end

		elseif item.Type == "OffHand" then
			if (not InventoryFunctions.HasOffHandEquipped(player, heldToolName) or (itemsmodule[heldToolName].Type ~= "OffHand")) then
				return
			end

		elseif item.Type == "Artifact" then
			HandleArtifact(player, item, keycode, mouseHit)
		end

		StatesFunctions.RemoveStamina(player, 1)
		UpdateStaminaEvent:FireClient(player, StatesFunctions.GetStamina(player), 100)
	end
end)
