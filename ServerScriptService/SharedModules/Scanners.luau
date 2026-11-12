-- ServerScriptService.Configs.ScannerConfigurations
local ScannerConfigurations = {}

ScannerConfigurations.ScanType = table.freeze({
	Weapon = 1,
	IllicitItem = 2,
	SpeciesAllowed = 3,
})

ScannerConfigurations.Species = table.freeze({
	Human = 1,
	Bleeper = 2,
})

-- Scanner configurations
ScannerConfigurations.Scanners = {
	["Scanner1"] = {
		scanTypes = {ScannerConfigurations.ScanType.Weapon, ScannerConfigurations.ScanType.IllicitItem},
		allowedSpecies = {ScannerConfigurations.Species.Human, ScannerConfigurations.Species.Bleeper},
		travel = 10,
		tweenTime = 1,

		onPass = {
			action = "SlideDoor",
			targetPath = "ScannerDoor",
			messages = {"Access granted"}
		},

		onFail = {
			action = "AlertSecurity",
			messages = {"Scan failed."},  -- fallback generic message
			effects = {"LockDoor", "AlertGuards"},

			-- per scan type specific messages
			failMessages = {
				Weapon      = {"Weapon detected!", "Please surrender your weapon."},
				IllicitItem = {"Contraband detected!", "Security has been alerted."},
				SpeciesAllowed = {"Species not permitted.", "Access denied."},
			}
		},
	},
	["Scanner2"] = {
		scanTypes = {ScannerConfigurations.ScanType.Weapon, ScannerConfigurations.ScanType.IllicitItem},
		allowedSpecies = {ScannerConfigurations.Species.Human, ScannerConfigurations.Species.Bleeper},
		travel = 10,
		tweenTime = 1,

		onPass = {
			action = "SlideDoor",
			targetPath = "ScannerDoor",
			messages = {"Access granted"}
		},

		onFail = {
			action = "AlertSecurity",
			messages = {"Scan failed."},  -- fallback generic message
			effects = {"LockDoor", "AlertGuards"},

			-- per scan type specific messages
			failMessages = {
				Weapon      = {"Weapon detected!", "Please surrender your weapon."},
				IllicitItem = {"Contraband detected!", "Security has been alerted."},
				SpeciesAllowed = {"Species not permitted.", "Access denied."},
			}
		},
	},
}

return ScannerConfigurations