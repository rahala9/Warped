local TerminalConfigurations = {}

-- Define terminal types and their behaviors
TerminalConfigurations.Terminals = {
	
	["MOP-E7_1Terminal"] = {
		terminalType = "RobotControl",
		difficulty = "Average",
		hackTime = nil, -- uses default based on player stats
		onSuccess = {
			action = "TakeControlRobot",
			targetPath = "workspace.Areas.StarhopStation.MOP-E7_1",
			messages = {"Successfully Took Control of MOP-E7_1"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}}
			}
		}
	},
	
	["LaserDoor1Terminal"] = {
		terminalType = "DoorControl",
		difficulty = "Average",
		hackTime = nil, -- uses default based on player stats
		onSuccess = {
			action = "ToggleLaserDoor",
			targetPath = "workspace.Areas.StarhopStation.TEST.LaserDoor1",
			duration = 5, -- door stays open for 5 seconds
			messages = {"Successfully Disabled Door"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}}
			}
		}
	},
	
	["SlidingDoor1Terminal"] = {
		terminalType = "DoorControl",
		difficulty = "Hard",
		hackTime = nil, -- uses default based on player stats
		onSuccess = {
			action = "ToggleSlidingDoor", --ToggleLaserDoor",
			targetPath = "workspace.Areas.StarhopStation.TEST.SlidingDoor", --"workspace.LaserDoor1",
			duration = 5, -- door stays open for 5 seconds
			messages = {"Successfully Disabled Door"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}}
			}
		}
	},
	
	["TeleporterTESTTerminal"] = {
		terminalType = "TeleporterControl",
		difficulty = "Hard",
		useAction = "OpenTeleporterControls",
		hackTime = nil, -- uses default based on player stats
		locations = {
			{ id = "Commissary", name = "Commissary", description = "Food level" },
			{ id = "Hangar", name = "Hangar Bay", description = "Docking level" }
		},
		hackedLocations = {
			{ id = "Commissary", name = "Commissary", description = "Food level" },
			{ id = "Hangar", name = "Hangar Bay", description = "Docking level" },
			{ id = "HighSecurityLevelB", name = "High Security Level B", description = "Ring Level High Security Hallway" }
		},
		onSuccess = {
			action = "OpenHackedTeleporterControls",
			targetPath = "workspace.Areas.StarhopStation.TEST.Teleporter",
			duration = 5, -- door stays open for 5 seconds
			messages = {"Successfully Hacked Terminal"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}}
			}
		}
	},
	
	["Teleporter1Terminal"] = {
		terminalType = "TeleporterControl",
		difficulty = "Hard",
		useAction = "OpenTeleporterControls",
		hackTime = nil, -- uses default based on player stats
		locations = {
			{ id = "Commissary", name = "Commissary", description = "Food level" },
			{ id = "Hangar", name = "Hangar Bay", description = "Docking level" }
		},
		onSuccess = {
			action = "OpenHackedTeleporterControls",
			targetPath = "workspace.Areas.StarhopStation.Teleporters.Teleporter",
			hackedLocations = {
				{ id = "Commissary", name = "Commissary", description = "Food level" },
				{ id = "Hangar", name = "Hangar Bay", description = "Docking level" },
				{ id = "HighSecurityLevelB", name = "High Security Level B", description = "Ring Level High Security Hallway" }
			},
			duration = 5, -- door stays open for 5 seconds
			messages = {"Successfully Hacked Terminal"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}}
			}
		}
	},

	["DataTerminal1"] = {
		terminalType = "DataAccess",
		difficulty = "Hard",
		onSuccess = {
			action = "GiveData",
			dataId = "SciCoSecretFiles",
			messages = {"Data downloaded successfully", "Check your inventory"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 180, message = "System compromised!", effects = {"AlertSecurity", "LockdownArea"}},
				Severe = {duration = 90, message = "Trace initiated! Lockout: 90s", effects = {"AlertSecurity"}},
				Average = {duration = 45, message = "Access denied! Lockout: 45s", effects = {}},
				Marginal = {duration = 20, message = "Failed! Lockout: 20s", effects = {}}
			}
		}
	},

	["QuestTerminal1"] = {
		terminalType = "QuestGiver",
		difficulty = "Easy",
		onSuccess = {
			action = "StartQuest",
			questId = "InvestigateOoze",
			messages = {"New mission received", "Check your quest log"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 60, message = "Terminal damaged!", effects = {}},
				Severe = {duration = 30, message = "Connection lost! Lockout: 30s", effects = {}},
				Average = {duration = 15, message = "Failed! Lockout: 15s", effects = {}},
				Marginal = {duration = 10, message = "Try again! Lockout: 10s", effects = {}}
			}
		}
	},

	["SecurityTerminal1"] = {
		terminalType = "SecurityControl",
		difficulty = "VeryHard",
		onSuccess = {
			action = "DisableSecurity",
			targetPath = "workspace.SecurityZone1",
			duration = 30, -- security disabled for 30 seconds
			messages = {"Security systems disabled", "You have 30 seconds"}
		},
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 300, message = "ALERT! Intruder detected!", effects = {"AlertSecurity", "SpawnGuards", "Kill"}},
				Severe = {duration = 120, message = "Security breach! Lockout: 120s", effects = {"AlertSecurity", "SpawnGuards"}},
				Average = {duration = 60, message = "Failed! Lockout: 60s", effects = {"AlertSecurity"}},
				Marginal = {duration = 30, message = "Failed! Lockout: 30s", effects = {}}
			}
		}
	}
}

return TerminalConfigurations