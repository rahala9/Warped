local TerminalConfigurations = {}

TerminalConfigurations.HackingMessages = {
	[0] = {
		"Pressing buttons with confidence...",
		"Trying PASSWORD123...",
		"Asking the terminal nicely...",
		"Checking underneath the keyboard...",
		"Looking for the ANY key...",
		"Turning Caps Lock off... just in case...",
		"Guessing admin / admin...",
		"Jiggling a suspicious cable...",
		"Blaming the network...",
		"Clicking ACCEPT without reading...",
		"Searching memory for that one tutorial...",
		"Pretending that beep was good...",
		"Typing faster to look qualified...",
		"Checking whether it is plugged in...",
		"Running totally_safe_hack.exe...",
		"Closing seventeen unexpected popups...",
		"Trying the password backwards...",
		"Wiping fingerprints off the screen...",
		"Waiting to see if it fixes itself...",
		"That warning light was probably already on...",
		"Pounding keys randomly...",
		"Becoming one with the terminal...",
		"Tapping the non-touch screen wildly...",
		"Cursing at the terminal...",
	},
	[1] = {
		"Opening beginner intrusion guide...",
		"Scanning for the obvious port...",
		"Running a copied bypass script...",
		"Trying the default credentials...",
		"Reading the error message this time...",
		"Searching for an unsecured service...",
		"Patching together a basic exploit...",
		"Checking the tutorial comments...",
		"Attempting a standard authentication bypass...",
		"Please don't trigger the alarm...",
	},
	[2] = {
		"Enumerating access services...",
		"Testing credential hashes...",
		"Spoofing terminal authorization...",
		"Probing security boundaries...",
		"Mapping active network ports...",
		"Injecting a controlled payload...",
		"Analyzing authentication traffic...",
		"Bypassing the user-access layer...",
		"Suppressing basic security alerts...",
		"Cleaning up obvious traces...",
	},
	[3] = {
		"Mapping security architecture...",
		"Cracking the access cipher...",
		"Escalating privileges...",
		"Redirecting audit logs...",
		"Isolating the security daemon...",
		"Spoofing trusted system traffic...",
		"Building a temporary access tunnel...",
		"Intercepting countermeasure calls...",
		"Rewriting authorization tokens...",
		"Closing the intrusion route...",
	},
	[4] = {
		"Predicting countermeasure cycles...",
		"Ghosting intrusion telemetry...",
		"Subverting the security kernel...",
		"Mirroring trusted credentials...",
		"Neutralizing active trace routines...",
		"Reconstructing the encryption state...",
		"Spoofing hardware-level authority...",
		"Redirecting defensive processes...",
		"Editing the live security model...",
		"Sealing the breach behind me...",
	},
	[5] = {
		"Countermeasures anticipated.",
		"Root authority assumed.",
		"Security telemetry rewritten.",
		"Encryption model solved.",
		"Trace routines neutralized.",
		"System trust acquired.",
		"Defenses redirected.",
		"Access is inevitable.",
		"The terminal never saw me.",
		"No trace remains.",
	},
}

local function laserDoorTerminal(targetPath)
	local doorAction = {
		action = "ToggleLaserDoor",
		targetPath = targetPath,
		duration = 5,
		messages = {"Successfully Disabled Door"},
	}
	return {
		terminalType = "DoorControl",
		difficulty = "Average",
		hackTime = nil,
		useAction = "ToggleLaserDoor",
		useConfig = doorAction,
		requiresAuthorization = true,
		onSuccess = doorAction,
		onFailure = {
			lockouts = {
				Catastrophic = {duration = 120, message = "CRITICAL FAILURE!", effects = {"Kill"}},
				Severe = {duration = 60, message = "Severe failure! Lockout: 60s", effects = {"AlertSecurity", "ElectricShock"}},
				Average = {duration = 30, message = "Failed! Lockout: 30s", effects = {"AlertSecurity"}},
				Marginal = {duration = 15, message = "Failed! Lockout: 15s", effects = {}},
			},
		},
	}
end

-- Define terminal types and their behaviors
TerminalConfigurations.Terminals = {
	["LaserDoorTerminal"] = laserDoorTerminal(nil),
	
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
	
	["LaserDoor1Terminal"] = laserDoorTerminal("workspace.Areas.StarhopStation.TEST.LaserDoor1"),
	["LaserDoor2Terminal"] = laserDoorTerminal("workspace.Areas.StarhopStation.TEST.LaserDoor2"),

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
