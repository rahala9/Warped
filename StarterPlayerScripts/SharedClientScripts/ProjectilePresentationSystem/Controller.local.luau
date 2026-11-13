local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent:WaitForChild("Config"))
local MuzzleEffects = require(script.Parent:WaitForChild("MuzzleEffects"))
local PredictedProjectile = require(script.Parent:WaitForChild("PredictedProjectile"))
local ServerProjectileVisibility = require(script.Parent:WaitForChild("ServerProjectileVisibility"))
local Items = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local WeaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SharedRemotes")

local didAuditShot = false

local function audit(message, ...)
	if Config.AuditEnabled then
		print(string.format("[ProjectilePresentationSystem %s] %s", Config.SystemVersion, message), ...)
	end
end

local function getMuzzleSource(weaponName): (CFrame?, string, Instance?)
	if player:GetAttribute("FirstPersonActive") then
		local presentationSource = WeaponInfo.GetPresentationWeaponSource(weaponName)
		if presentationSource then
			return presentationSource,
				"first-person viewmodel",
				WeaponInfo.GetPresentationWeaponSourceInstance(weaponName)
		end
	end

	local worldSource = WeaponInfo.GetFiringPosition(player, weaponName)
	return worldSource, "third-person world weapon", WeaponInfo.GetWeaponSourceInstance()
end

local function presentReplicatedShot(shooter, weaponName, origin, direction, speed, maxDistance, shotId)
	if not Config.Enabled
		or typeof(origin) ~= "Vector3"
		or typeof(direction) ~= "Vector3"
		or direction.Magnitude < 0.01
	then
		return
	end

	local weaponDefinition = Items[weaponName]
	local settings = Config.Resolve(weaponDefinition)
	if not settings or settings.Enabled == false then
		return
	end

	local unitDirection = direction.Unit
	local muzzleCFrame = CFrame.lookAt(origin, origin + unitDirection)
	local sourceName = "third-person world weapon"
	local muzzleInstance = nil
	if shooter == player then
		muzzleCFrame, sourceName, muzzleInstance = getMuzzleSource(weaponName)
		if not muzzleCFrame then
			return
		end
	end

	MuzzleEffects.Emit(
		muzzleCFrame,
		muzzleCFrame.Position + unitDirection * settings.StreakLength,
		settings,
		muzzleInstance
	)

	if shooter == player
		and player:GetAttribute("FirstPersonActive")
		and type(speed) == "number"
		and type(maxDistance) == "number"
		and type(shotId) == "number"
	then
		local predictedLifetime = (maxDistance / math.max(speed, 1)) + 0.25
		ServerProjectileVisibility.HideShot(shotId, predictedLifetime)
		local projectileMuzzleCFrame = muzzleCFrame
			* (settings.MuzzleEffectOffset or CFrame.identity)
		PredictedProjectile.Emit(
			projectileMuzzleCFrame,
			origin,
			unitDirection,
			speed,
			maxDistance,
			settings,
			player.Character
		)
	end

	if shooter == player and not didAuditShot then
		didAuditShot = true
		audit("first confirmed energy shot presented", weaponName, sourceName, muzzleCFrame.Position)
	end
end

audit("controller started")
task.spawn(ServerProjectileVisibility.Initialize)

task.spawn(function()
	local ProjectilePresentationEvent = remotes:WaitForChild("ProjectilePresentation", 10)
	if ProjectilePresentationEvent then
		ProjectilePresentationEvent.OnClientEvent:Connect(presentReplicatedShot)
	else
		warn(string.format(
			"[ProjectilePresentationSystem %s] ProjectilePresentation remote was not created",
			Config.SystemVersion
		))
	end
end)
