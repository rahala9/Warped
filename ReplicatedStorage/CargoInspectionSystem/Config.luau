-- Shared presentation and server tuning for customs cargo inspections.

local offenseClasses = table.freeze({
	Restricted = table.freeze({
		FineMultiplier = 0.5,
	}),
	Illegal = table.freeze({
		FineMultiplier = 1,
	}),
	Capital = table.freeze({
		FineMultiplier = 2,
	}),
})

local enforcementPolicies = table.freeze({
	Civilian = table.freeze({
		Restricted = "Fine",
		Illegal = "Arrest",
		Capital = "Arrest",
	}),
	Corporate = table.freeze({
		Restricted = "Fine",
		Illegal = "Arrest",
		Capital = "Lethal",
	}),
	Military = table.freeze({
		Restricted = "Arrest",
		Illegal = "Arrest",
		Capital = "Lethal",
	}),
})

return table.freeze({
	ZoneType = "CargoInspection",
	RiskName = "Contraband",
	RemoteName = "CargoInspectionChanged",

	DefaultScannerStrength = 0.8,
	DefaultScanDelay = 1.5,
	PassedDisplayDuration = 4,
	DetectedDisplayDuration = 10,
	DefaultOffenseClass = "Restricted",
	DefaultEnforcementPolicy = "Civilian",
	DefaultJurisdiction = "Local Security",
	OffenseClasses = offenseClasses,
	EnforcementPolicies = enforcementPolicies,
	MinimumFine = 1,
	MaximumDetectionChance = 0.95,
})
