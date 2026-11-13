local Config = {}

Config.SystemVersion = "2026.11.13.7"
Config.Enabled = true
Config.AuditEnabled = true

Config.Default = {
	Enabled = true,
	Color = Color3.fromRGB(80, 225, 255),
	MuzzleEffectOffset = CFrame.identity,
	FlashDuration = 0.065,
	FlashSize = 0.34,
	FlashExpansion = 1.8,
	LightBrightness = 3.5,
	LightRange = 8,
	StreakDuration = 0.055,
	StreakLength = 3.5,
	MaximumStreakLength = 10,
	StreakWidth = 0.075,
	ProjectileLength = 0.9,
	ProjectileWidth = 0.06,
}

-- Presentation is keyed by damage type so newly added weapons inherit a
-- suitable effect without weapon-name branches in the controller.
Config.DamageTypes = {
	Laser = {
		Color = Color3.fromRGB(255, 55, 45),
		FlashDuration = 0.1,
		FlashSize = 0.24,
		FlashExpansion = 1.6,
		LightBrightness = 3,
		LightRange = 6,
		StreakLength = 0,
		MaximumStreakLength = 0,
		ProjectileLength = 1.1,
		ProjectileWidth = 0.045,
	},
	Plasma = {
		Color = Color3.fromRGB(210, 75, 255),
		FlashSize = 0.42,
		StreakWidth = 0.1,
	},
	Electric = {
		Color = Color3.fromRGB(255, 230, 60),
		StreakLength = 2.5,
	},
	ParticleBeam = {
		Color = Color3.fromRGB(100, 255, 190),
		StreakLength = 4.5,
	},
	Cryo = {
		Color = Color3.fromRGB(120, 190, 255),
		FlashSize = 0.4,
	},
}

local function mergeInto(target, source)
	if type(source) ~= "table" then
		return
	end

	for key, value in pairs(source) do
		target[key] = value
	end
end

function Config.Resolve(weaponDefinition)
	if not weaponDefinition then
		return nil
	end

	local damageType = weaponDefinition.DamageType
	local damageSettings = Config.DamageTypes[damageType]
	if not damageSettings then
		return nil
	end

	local resolved = {}
	mergeInto(resolved, Config.Default)
	mergeInto(resolved, damageSettings)
	mergeInto(resolved, weaponDefinition.ProjectilePresentation)

	-- Cover roughly the first 25 ms of travel. This prevents very fast bolts
	-- from first rendering with an empty gap after replication, while keeping
	-- slower energy projectiles visually compact.
	local projectileSpeed = weaponDefinition.WeaponAmmoSpeed
	if type(projectileSpeed) == "number" then
		resolved.StreakLength = math.clamp(
			math.max(resolved.StreakLength, projectileSpeed * 0.025),
			resolved.StreakLength,
			resolved.MaximumStreakLength
		)
	end
	return resolved
end

return Config
