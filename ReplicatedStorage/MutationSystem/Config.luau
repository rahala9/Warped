return {
	AssetName = "Flyhead",
	MountAttachmentName = "MutationMount",
	AllowPivotFallback = true,
	FallbackMountFromPivot = CFrame.identity,
	CharacterHeadPartNames = { "head", "face" },
	NeckBonePath = { "Root", "Hips", "Spine_01", "Spine_02", "Spine_03", "Neck" },
	AlignmentOffset = CFrame.identity,
	HiddenPartNames = {
		head = true,
		face = true,
		scalp = true,
		skull = true,
	},
	HiddenPartPrefixes = { "hair" },
	HideHeadAccessories = true,
	Debug = true,
}
