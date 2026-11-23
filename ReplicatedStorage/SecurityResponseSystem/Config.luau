return table.freeze({
	IncidentRemoteName = "SecurityIncidentChanged",
	SurrenderRemoteName = "SurrenderSecurityIncident",
	DefaultArrestDuration = 120,
	DefaultLethalDuration = 180,
	DefaultCustodyDuration = 180,
	CustodyDoorOpenDuration = 30,
	UpdateInterval = 1,
	SurrenderKey = Enum.KeyCode.J,

	-- Guard integration. Spawned NPCs opt in with GuardTag and use an exact
	-- jurisdiction match so unrelated enemies never receive security targets.
	GuardTag = "SecurityGuard",
	GuardJurisdictionAttribute = "SecurityJurisdiction",
	GuardTargetAttribute = "SecurityTargetUserId",
	GuardResponseAttribute = "SecurityTargetResponse",
	DefaultGuardJurisdiction = "Local Security",
	GuardDispatchRadius = 250,
	GuardArrestDistance = 7,
	GuardUpdateInterval = 0.25,
})
