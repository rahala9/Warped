return {
	Enabled = true,
	Debug = true,
	RuntimeFolderName = "_DeathEffectRuntime",

	Effects = {
		LaserSlice = {
			Lifetime = 60,
		},
		Disintegrate = {
			Lifetime = 20,
			-- Kept at 100% while the effect is being tested. Set this to 0.2 for
			-- a 20% chance once the presentation is approved.
			LaserWeaponChance = 1,
			DustColor = Color3.fromRGB(128, 119, 105),
			DustPileColor = Color3.fromRGB(104, 96, 85),
			ParticleCountPerPart = 36,
			ParticleBurstCount = 3,
			ParticleBurstInterval = 0.16,
			MaximumEmitters = 20,
			DustPilePieceCount = 20,
			BonePileWidth = 3.4,
			SkullMaximumSize = 1.25,
			SkullUpwardVelocity = 4.5,
			SkullHorizontalVelocity = 0.75,
		},
		Electrocuted = {
			Lifetime = 20,
			-- Electrocution is an x-ray overlay on the falling character. Unlike
			-- slicing/disintegration, it does not replace the character model.
			HideCharacter = false,
			-- Kept at 100% while the effect is being tested.
			ElectricWeaponChance = 1,
			ElectricStatusChance = 1,
			FlashDuration = 0.65,
			LightBrightness = 2.5,
			LightRange = 7,
		},
	},
}
