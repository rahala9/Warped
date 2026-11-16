return {
	Enabled = true,
	Debug = true,
	Provider = "SlicedCrew",

	EffectLifetime = 60,
	PlaneMergeTolerance = 0.08,
	MaximumPlanes = 8,
	CutGap = 0.5,
	RuntimeFolderName = "_LaserSliceRuntime",

	Dynamic = {
		SliceEquipment = true,
		EnablePhysics = false,
		PhysicsDelay = 3,
		MinimumFallVelocity = 1.5,
		MaximumFallVelocity = 4,
		MaximumAngularVelocity = 2.5,
		CollisionFidelity = Enum.CollisionFidelity.Hull,
		RenderFidelity = Enum.RenderFidelity.Precise,
	},

	Baked = {
		DefaultTemplate = "Default",
		TemplateFolderName = "BakedTemplates",
	},

	SlicedCrew = {
		AssetFolderName = "SharedClientAssets",
		TemplateName = "SlicedCrew",
		PivotOffset = CFrame.identity,
		AlignBoundingBoxCenter = true,
		PhysicsDelay = 0.25,
		MinimumScatterSpeed = 2.25,
		MaximumScatterSpeed = 4.25,
		MinimumUpwardVelocity = 0.75,
		MaximumUpwardVelocity = 2.25,
		MaximumAngularVelocity = 3.5,
		SettleEnabled = true,
		SettlePollInterval = 0.15,
		SettleStillTime = 1.0,
		SettleLinearSpeed = 0.35,
		SettleAngularSpeed = 0.5,
		SettleGroundProbeDistance = 0.6,
		SettleMonitorDuration = 45,
		FaceSurface = Enum.NormalId.Front,
		FacePixelsPerStud = 100,
	},
}
