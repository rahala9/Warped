local Config = {}

Config.SystemVersion = "2026.11.13.5"
Config.AuditEnabled = true
Config.Enabled = true
Config.EnterOnEquip = false
Config.ToggleActionName = "ToggleFirstPerson"
Config.ToggleInputs = {
	Enum.KeyCode.V,
	Enum.KeyCode.ButtonR3,
}
Config.EmergencyExitKey = Enum.KeyCode.F8

Config.FieldOfView = 75
Config.EquipBuildDelay = 0.15
Config.BuildRetryInterval = 0.1
Config.BuildTimeout = 2
Config.ExitOnZoomOut = true
Config.RenderStepName = "WarpedFirstPersonViewmodel"
Config.RenderPriority = Enum.RenderPriority.Camera.Value + 1

-- MuzzleOffset is the desired position of the cloned weapon's Muzzle relative
-- to the camera. Each weapon can override these values below or by defining a
-- FirstPerson table directly on its item definition.
Config.DefaultWeapon = {
	Enabled = true,
	MuzzleOffset = CFrame.new(0.65, -0.55, -3),
	Responsiveness = 24,
	SwayDegreesPerPixel = 0.035,
	MaxSwayDegrees = 3,
	BobFrequency = 9,
	BobHorizontal = 0,
	BobVertical = 0,
	RecoilDegrees = 1.4,
	RecoilBack = 0.045,
	RecoilRecovery = 8,
}

-- Start with shared defaults. Add only the values that differ for a weapon.
-- These offsets can be tuned without changing controller or viewmodel code.
Config.Weapons = {
	SciCoP92 = {
		MuzzleOffset = CFrame.new(0.7, -0.62, -3.8),
	},
	SciCo00Zero = {
		MuzzleOffset = CFrame.new(0.55, -0.5, -2.4),
	},
	Splatifier9000 = {
		MuzzleOffset = CFrame.new(0.75, -0.65, -4.2),
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

function Config.ResolveWeapon(weaponName, weaponDefinition)
	local resolved = {}
	mergeInto(resolved, Config.DefaultWeapon)
	mergeInto(resolved, Config.Weapons[weaponName])

	-- Item data is the final authority, allowing a weapon to carry its own
	-- first-person tuning without adding weapon-specific controller branches.
	if weaponDefinition and weaponDefinition.FirstPerson == false then
		resolved.Enabled = false
	elseif weaponDefinition then
		mergeInto(resolved, weaponDefinition.FirstPerson)
	end

	return resolved
end

return Config
