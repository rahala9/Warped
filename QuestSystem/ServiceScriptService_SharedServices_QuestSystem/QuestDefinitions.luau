local Definitions = {}

Definitions.Quests = {
	----------------------------------------------------------------
	-- 1) BASIC STORY QUEST
	-- Event-driven objectives, hidden reveal, mixed flow
	----------------------------------------------------------------
	FirstContact = {
		id = "FirstContact",
		title = "First Contact",
		description = "Investigate the strange signal near camp.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = {},
			flags = {},
		},

		onStart = {
			{
				type = "Toast",
				text = "New quest: First Contact",
				kind = "QuestStart",
			},
			{
				type = "SpawnActor",
				actorTemplate = "MysteriousScout",
				actorKey = "ScoutActor",
				parentName = "NPCs",
				position = Vector3.new(0, 5, 0),
			},
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Coins", amount = 50 },
			{ type = "GiveReward", rewardId = "XP", amount = 25 },
		},

		onComplete = {
			{ type = "DestroyActor", actorKey = "ScoutActor" },
			{ type = "StartQuest", questId = "RestoreTheRelay" },
		},

		steps = {
			{
				id = "TalkScout",
				title = "Talk to the Scout",
				description = "Speak with the mysterious scout.",
				template = "TalkToNpc",
				npcId = "Scout01",
				hidden = false,
				prerequisites = {},
				orderGroup = "Intro",
			},

			{
				id = "ReachCrashSite",
				title = "Investigate the crash site",
				description = "Head to the crash site in the woods.",
				template = "ReachZone",
				zoneId = "CrashSite",
				hidden = false,
				prerequisites = { "TalkScout" },
				orderGroup = "Investigation",
			},

			{
				id = "CollectResidue",
				title = "Collect odd residue",
				description = "Gather strange residue from the wreckage.",
				template = "CollectItems",
				itemId = "OddResidue",
				goal = 3,
				hidden = false,
				prerequisites = { "ReachCrashSite" },
				group = "Clues",
			},

			{
				id = "DefeatCrawlers",
				title = "Defeat lurking creatures",
				description = "Eliminate the creatures around the wreck.",
				template = "KillEnemies",
				enemyType = "NightCrawler",
				goal = 4,
				hidden = false,
				prerequisites = { "ReachCrashSite" },
				group = "Clues",
			},

			{
				id = "ReportBack",
				title = "Report back",
				description = "Return to the scout with what you found.",
				template = "TalkToNpc",
				npcId = "Scout01",
				hidden = true,
				prerequisites = {},
				unlockWhen = {
					type = "GROUP_ANY",
					group = "Clues",
					count = 2,
				},
				onReveal = {
					{
						type = "Toast",
						text = "Return to the scout.",
						kind = "QuestUpdate",
					},
				},
			},
		},
	},

	----------------------------------------------------------------
	-- 2) PURE EVENT COUNTER QUEST
	----------------------------------------------------------------
	RestoreTheRelay = {
		id = "RestoreTheRelay",
		title = "Restore the Relay",
		description = "Bring the relay station back online.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "FirstContact" },
		},

		onStart = {
			{
				type = "Toast",
				text = "The relay station is offline.",
				kind = "Info",
			},
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Coins", amount = 75 },
		},

		onComplete = {
			{ type = "StartQuest", questId = "PowerRouting" },
		},

		steps = {
			{
				id = "FindFuse",
				title = "Find a replacement fuse",
				description = "Search nearby crates for a usable fuse.",
				template = "CollectItems",
				itemId = "RelayFuse",
				goal = 1,
				hidden = false,
			},
			{
				id = "InstallFuse",
				title = "Install the fuse",
				description = "Insert the fuse into the relay housing.",
				template = "InteractObject",
				objectId = "RelayFuseSocket",
				prerequisites = { "FindFuse" },
				hidden = false,
			},
			{
				id = "ActivateRelay",
				title = "Activate the relay",
				description = "Use the control panel to start the relay.",
				template = "InteractObject",
				objectId = "RelayControlPanel",
				prerequisites = { "InstallFuse" },
				hidden = false,
				onComplete = {
					{
						type = "EmitSignal",
						signal = "RelayOnline",
					},
				},
			},
		},
	},

	----------------------------------------------------------------
	-- 3) SEQUENCE QUEST
	-- Good for hacking, rituals, puzzle orders, multi-console flow
	----------------------------------------------------------------
	PowerRouting = {
		id = "PowerRouting",
		title = "Power Routing",
		description = "Route power through the consoles in the correct order.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "RestoreTheRelay" },
		},

		rewards = {
			{ type = "GiveReward", rewardId = "XP", amount = 50 },
		},

		onComplete = {
			{ type = "StartQuest", questId = "EmergencyEvac" },
		},

		steps = {
			{
				id = "RoutePower",
				title = "Route power correctly",
				description = "Activate Alpha, then Beta, then Gamma.",
				type = "SEQUENCE",
				hidden = false,

				sequence = {
					{
						event = "ObjectInteracted",
						match = { objectId = "ConsoleAlpha" },
						progressText = "Alpha activated",
					},
					{
						event = "ObjectInteracted",
						match = { objectId = "ConsoleBeta" },
						progressText = "Beta activated",
					},
					{
						event = "ObjectInteracted",
						match = { objectId = "ConsoleGamma" },
						progressText = "Gamma activated",
					},
				},

				resetOnWrongEvent = true,
				wrongEventFilter = {
					event = "ObjectInteracted",
					matchAny = {
						{ objectId = "ConsoleAlpha" },
						{ objectId = "ConsoleBeta" },
						{ objectId = "ConsoleGamma" },
					},
				},

				onComplete = {
					{
						type = "Toast",
						text = "Power routing successful.",
						kind = "ObjectiveComplete",
					},
				},
			},
		},
	},

	----------------------------------------------------------------
	-- 4) CONDITION QUEST
	-- Useful for inventory/reputation/flags/world state
	----------------------------------------------------------------
	FieldPromotion = {
		id = "FieldPromotion",
		title = "Field Promotion",
		description = "Prove yourself worthy of a field promotion.",
		category = "Side",
		questChain = "FactionSciCo",
		autoStart = false,
		repeatable = false,

		requires = {
			flags = { "JoinedSciCo" },
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Credits", amount = 150 },
			{ type = "SetQuestFlag", flag = "HasFieldPromotion", value = true },
		},

		steps = {
			{
				id = "ReachRequiredRep",
				title = "Reach reputation 10",
				description = "Earn enough reputation with Sci Co.",
				type = "CONDITION",
				hidden = false,

				condition = {
					kind = "ReputationAtLeast",
					faction = "SciCo",
					amount = 10,
				},
			},
			{
				id = "HaveClearanceBadge",
				title = "Obtain a clearance badge",
				description = "Acquire a field clearance badge.",
				type = "CONDITION",
				hidden = false,

				condition = {
					kind = "InventoryHasItem",
					itemId = "FieldClearanceBadge",
					amount = 1,
				},
			},
			{
				id = "ReportToSupervisor",
				title = "Report to your supervisor",
				description = "Speak to Supervisor Hale.",
				template = "TalkToNpc",
				npcId = "SupervisorHale",
				hidden = true,
				unlockWhen = {
					type = "ALL_OF_STEPS",
					steps = { "ReachRequiredRep", "HaveClearanceBadge" },
				},
			},
		},
	},

	----------------------------------------------------------------
	-- 5) STATEFUL ESCORT QUEST
	----------------------------------------------------------------
	EmergencyEvac = {
		id = "EmergencyEvac",
		title = "Emergency Evac",
		description = "Escort the wounded technician to the shuttle pad.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "PowerRouting" },
		},

		onStart = {
			{
				type = "SpawnActor",
				actorTemplate = "WoundedTechnician",
				actorKey = "EscortTech",
				parentName = "NPCs",
				position = Vector3.new(145, 6, -30),
			},
		},

		rewards = {
			{ type = "GiveReward", rewardId = "XP", amount = 100 },
			{ type = "GiveReward", rewardId = "MedTokens", amount = 1 },
		},

		onComplete = {
			{ type = "DestroyActor", actorKey = "EscortTech" },
			{ type = "StartQuest", questId = "HoldThePad" },
		},

		onFail = {
			{
				type = "Toast",
				text = "The technician did not survive.",
				kind = "QuestFail",
			},
			{ type = "DestroyActor", actorKey = "EscortTech" },
		},

		steps = {
			{
				id = "EscortTechnician",
				title = "Escort the technician",
				description = "Keep the technician alive until they reach the shuttle pad.",
				type = "STATEFUL",
				template = "Escort",
				hidden = false,

				stateful = {
					handler = "EscortActor",
					actorKey = "EscortTech",
					destinationZoneId = "ShuttlePad",
					failIfActorDestroyed = true,
					failIfSignal = "EscortTechDied",
					completeOnSignal = "EscortTechReachedPad",
				},
			},
		},
	},

	----------------------------------------------------------------
	-- 6) STATEFUL DEFEND QUEST
	----------------------------------------------------------------
	HoldThePad = {
		id = "HoldThePad",
		title = "Hold the Pad",
		description = "Defend the shuttle pad until extraction is complete.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "EmergencyEvac" },
		},

		onStart = {
			{
				type = "Toast",
				text = "Hold the line until extraction finishes.",
				kind = "QuestStart",
			},
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Credits", amount = 200 },
			{ type = "GiveReward", rewardId = "XP", amount = 150 },
		},

		steps = {
			{
				id = "DefendPad",
				title = "Defend the shuttle pad",
				description = "Survive the enemy assault and keep the pad secure.",
				type = "STATEFUL",
				template = "Defend",
				hidden = false,

				stateful = {
					handler = "DefendObjective",
					duration = 60,
					objectiveId = "ShuttlePadBeacon",
					failIfSignal = "PadBeaconDestroyed",
					completeOnSignal = "PadDefenseComplete",
				},
			},
		},

		onComplete = {
			{ type = "StartQuest", questId = "TimedOverride" },
		},
	},

	----------------------------------------------------------------
	-- 7) TIMED STATEFUL QUEST
	----------------------------------------------------------------
	TimedOverride = {
		id = "TimedOverride",
		title = "Timed Override",
		description = "Override the blast doors before the lockout finishes.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "HoldThePad" },
		},

		onStart = {
			{
				type = "Toast",
				text = "You have 45 seconds to override the doors.",
				kind = "QuestStart",
			},
		},

		onFail = {
			{
				type = "Toast",
				text = "Door override failed.",
				kind = "QuestFail",
			},
		},

		rewards = {
			{ type = "GiveReward", rewardId = "XP", amount = 125 },
		},

		steps = {
			{
				id = "OverrideDoors",
				title = "Override the doors",
				description = "Use the emergency panel before time runs out.",
				type = "STATEFUL",
				template = "TimedInteract",
				hidden = false,

				stateful = {
					handler = "TimedInteract",
					duration = 45,
					successEvent = "ObjectInteracted",
					successMatch = { objectId = "EmergencyDoorPanel" },
				},
			},
		},

		onComplete = {
			{ type = "StartQuest", questId = "TruthOrCoverup" },
		},
	},

	----------------------------------------------------------------
	-- 8) BRANCH FLAG SETUP QUEST
	----------------------------------------------------------------
	TruthOrCoverup = {
		id = "TruthOrCoverup",
		title = "Truth or Coverup",
		description = "Decide what to do with the crash evidence.",
		category = "Story",
		questChain = "MainStory",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "TimedOverride" },
		},

		steps = {
			{
				id = "ChooseTruth",
				title = "Deliver the evidence to the scout",
				description = "Give the evidence to the scout.",
				template = "Signal",
				signal = "ChoseTruthRoute",
				group = "BranchChoice",
				hidden = false,
				onComplete = {
					{ type = "SetQuestFlag", flag = "TruthRoute", value = true },
				},
			},
			{
				id = "ChooseCoverup",
				title = "Deliver the evidence to Command",
				description = "Turn the evidence over to Command instead.",
				template = "Signal",
				signal = "ChoseCoverupRoute",
				group = "BranchChoice",
				hidden = false,
				onComplete = {
					{ type = "SetQuestFlag", flag = "CoverupRoute", value = true },
				},
			},
			{
				id = "FinalizeChoice",
				title = "Commit to your choice",
				description = "Your decision is made.",
				type = "CONDITION",
				hidden = true,
				unlockWhen = {
					type = "GROUP_ANY",
					group = "BranchChoice",
					count = 1,
				},
				condition = {
					kind = "AnyFlagTrue",
					flags = { "TruthRoute", "CoverupRoute" },
				},
			},
		},

		onComplete = {
			{ type = "StartQuest", questId = "TruthRouteQuest" },
			{ type = "StartQuest", questId = "CoverupRouteQuest" },
		},
	},

	----------------------------------------------------------------
	-- 9) BRANCHED FOLLOWUP: TRUTH ROUTE
	-- Only actually start/appear if flag gating allows it
	----------------------------------------------------------------
	TruthRouteQuest = {
		id = "TruthRouteQuest",
		title = "Whistleblower",
		description = "Help expose what really happened.",
		category = "Story",
		questChain = "TruthRoute",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "TruthOrCoverup" },
			flags = { "TruthRoute" },
		},

		rewards = {
			{ type = "GiveReward", rewardId = "XP", amount = 200 },
		},

		steps = {
			{
				id = "MeetScout",
				title = "Meet the scout",
				description = "Find the scout at the overlook.",
				template = "TalkToNpc",
				npcId = "Scout01",
			},
			{
				id = "UploadData",
				title = "Upload the evidence",
				description = "Use the uplink terminal.",
				template = "InteractObject",
				objectId = "UplinkTerminal",
				prerequisites = { "MeetScout" },
			},
		},
	},

	----------------------------------------------------------------
	-- 10) BRANCHED FOLLOWUP: COVERUP ROUTE
	----------------------------------------------------------------
	CoverupRouteQuest = {
		id = "CoverupRouteQuest",
		title = "Loose Ends",
		description = "Help Command erase the evidence.",
		category = "Story",
		questChain = "CoverupRoute",
		autoStart = false,
		repeatable = false,

		requires = {
			completedQuests = { "TruthOrCoverup" },
			flags = { "CoverupRoute" },
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Credits", amount = 300 },
		},

		steps = {
			{
				id = "MeetCommander",
				title = "Meet Command",
				description = "Report to Commander Voss.",
				template = "TalkToNpc",
				npcId = "CommanderVoss",
			},
			{
				id = "DestroyEvidence",
				title = "Destroy the evidence",
				description = "Use the incinerator controls.",
				template = "InteractObject",
				objectId = "EvidenceIncinerator",
				prerequisites = { "MeetCommander" },
			},
		},
	},

	----------------------------------------------------------------
	-- 11) REPEATABLE SIDE QUEST
	----------------------------------------------------------------
	CullingContract = {
		id = "CullingContract",
		title = "Culling Contract",
		description = "Thin out local hostiles for a contractor.",
		category = "Repeatable",
		questChain = "Contracts",
		autoStart = false,
		repeatable = true,
		repeatCooldown = 300,

		requires = {
			flags = { "UnlockedContractsBoard" },
		},

		rewards = {
			{ type = "GiveReward", rewardId = "Credits", amount = 100 },
		},

		steps = {
			{
				id = "EliminateTargets",
				title = "Eliminate hostiles",
				description = "Defeat 8 Scrap Hounds.",
				template = "KillEnemies",
				enemyType = "ScrapHound",
				goal = 8,
			},
		},
	},
}

return Definitions