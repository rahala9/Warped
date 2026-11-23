-- Shared tuning for cargo risks. Cargo jobs opt in with 0-1 severity values,
-- for example: risks = { Fragile = 0.35 }. Keep gameplay decisions on the
-- server; this module is replicated so clients can consistently label risks.

return {
	Stability = {
		Maximum = 100,
		RecoveryDelay = 2.5,
		WalkRecoveryPerSecond = 2,
		IdleRecoveryPerSecond = 5,
		MountedRecoveryPerSecond = 4,
		FreeRecoveryPerSecond = 3,
		-- Sprinting is an emergency burst, not an efficient delivery strategy.
		-- This is the average before the variable multiplier and instability
		-- bursts below are applied.
		RunDamagePerSecond = 12,
		RunVariation = {
			RateChangeIntervalMin = 0.6,
			RateChangeIntervalMax = 1.8,
			RateMultiplierMin = 0.65,
			RateMultiplierMax = 1.35,
			BurstChancePerSecond = 0.12,
			BurstCooldown = 0.75,
			BurstDamageMin = 3,
			BurstDamageMax = 8,
			-- Both reach their full multiplier as stability approaches zero.
			LowStabilityBurstChanceMultiplier = 2.5,
			LowStabilityBurstDamageMultiplier = 2,
		},
		WalkSpeedThreshold = 1,
		RunSpeedThreshold = 20,

		-- A sudden carrier velocity change above this value counts as an impact.
		ImpactThreshold = 10,
		ImpactDamageScale = 2,
		ImpactCooldown = 0.75,
		FreeImpactThreshold = 12,
		FreeImpactDamageScale = 2.75,
		FreeImpactCooldown = 0.6,
		FreeReleaseGrace = 0.25,

		-- Mounted cargo breaks when the ship begins touching an external object
		-- while moving at or above this speed. Slow docking contact is ignored.
		ShipCollisionBreaks = true,
		ShipCollisionMinimumSpeed = 6,

		-- Only risks listed here receive or display stability. Reaching zero is
		-- irreversible for the current cargo even though ordinary handling stress
		-- can recover before that threshold.
		RiskTypes = {
			Fragile = {
				Label = "FRAGILE STABILITY",
				ZeroAction = "FailContract",
				ZeroMessage = "Fragile cargo was broken.",
			},
			ContainedCreature = {
				Label = "CREATURE RESTRAINT",
				ZeroAction = "Message",
				ZeroMessage = "The creature inside the cargo has broken free!",
			},
		},
	},

	Biohazardous = {
		MaximumContainment = 100,
		-- Careful walking preserves containment for a short local delivery.
		-- Running degrades it quickly enough to expose the carrier to the more
		-- dangerous leak stages during the same trip.
		WalkContainmentLossPerSecond = 4,
		RunContainmentLossPerSecond = 8,
		ImpactThreshold = 10,
		ImpactContainmentScale = 1.2,
		ShipCollisionContainmentDamage = 50,

		-- Even apparently sealed cargo leaks a little. Exposure rates are meter
		-- units per second before the Biohazard meter's natural recovery.
		Stages = {
			{ MinimumContainment = 76, Label = "SEALED?", ExposureRate = 2 },
			{ MinimumContainment = 41, Label = "SEEPING", ExposureRate = 4 },
			{ MinimumContainment = 16, Label = "LEAKING", ExposureRate = 7.5 },
			{ MinimumContainment = 1, Label = "CRITICAL", ExposureRate = 13 },
			{ MinimumContainment = 0, Label = "RUPTURED", ExposureRate = 23 },
		},
		ExposureRadius = 22,
		MountedExposureMultiplier = 0.75,
	},
}
