local Config = {
	MaxOxygen = 100,
	DrainPerSecond = 2,
	RecoveryPerSecond = 12,
	SuffocationDamagePerSecond = 10,
	SuffocationDamageInterval = 1,
	UpdateInterval = 0.25,

	-- These zones contain breathable atmosphere. Add future station, planet,
	-- or pressurized-area zone keys here.
	AtmosphereZoneKeys = {
		"StarhopStationZone",
	},

	Attributes = {
		Current = "Oxygen",
		Maximum = "MaxOxygen",
		InVacuum = "InVacuum",
		AtmosphereOverride = "InAtmosphere",
	},

	UI = {
		Name = "OxygenBar",
		Position = UDim2.new(0, 79, 1, -97),
		Size = UDim2.fromOffset(117, 14),
		ZIndex = 98,
		FillColor = Color3.fromRGB(20, 145, 225),
		GradientDark = Color3.fromRGB(5, 55, 115),
		GradientBright = Color3.fromRGB(45, 205, 255),
	},
}

return Config
