return {
	Debug = true,
	RuntimeFolderName = "_EffectVisualRuntime",
	ElectricShock = {
		-- This asset is authored on the exact player bind rig. Root alignment
		-- therefore needs no hand-tuned positional correction.
		AlignmentOffset = CFrame.identity,
		-- Disable both character and x-ray skeleton shadows during the effect.
		-- Set this to true to restore the normal shadowed presentation.
		CastShadows = false,
		-- Keep the skeleton visible for most of each pulse. The previous equal
		-- on/off flicker and 58% body fade made it disappear into the character.
		BodyTransparency = 0.45,
		SkeletonTransparency = 0,
		MinimumVisibleTime = 0.22,
		MaximumVisibleTime = 0.38,
		MinimumHiddenTime = 0.04,
		MaximumHiddenTime = 0.08,
		HighlightFillTransparency = 0.78,
		HighlightOutlineTransparency = 0.12,
		LightColor = Color3.fromRGB(90, 225, 255),
		LightBrightness = 1.5,
		LightRange = 6,
		-- Let the sustained electrocution cue read clearly over the cable's
		-- frequent one-shot spark sounds without stopping the cable effect.
		ElectrocutedMinimumVolume = 1.5,
		ElectrocutedRollOffMaxDistance = 70,
		ElectrocutedSoundPath = { "SharedClientAssets", "Sounds", "Electric", "Electrocuted " },
		CableSoundDuckFactor = 0.12,
		CableSoundDuckRadius = 18,
	},
}
