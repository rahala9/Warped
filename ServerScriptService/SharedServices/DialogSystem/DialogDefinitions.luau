--[[
	DialogDefinitions
	All NPC dialog trees live here. Pure data, no logic.

	Structure:
		Each dialog is keyed by npcId and contains a tree of nodes.
		The "root" node is the entry point when a player talks to the NPC.
		Multiple root nodes can exist with conditions — first matching root wins.

	Node fields:
		id            – unique node id within this dialog
		npcText       – what the NPC says (string or array of strings for multi-line)
		options       – array of player response options:
			text      – what the player can say
			nextNode  – node id to go to when selected (nil = end dialog)
			conditions – optional array of conditions that must be met to show this option
			actions   – optional array of actions to run when selected
		conditions    – optional array of conditions for this node to be reachable
		actions       – optional array of actions to run when this node is entered

	Conditions use the same format as QuestConditions:
		{ kind = "HasQuestActive", questId = "FirstContact" }
		{ kind = "HasQuestCompleted", questId = "FirstContact" }
		{ kind = "FlagTrue", flag = "MetTheScout" }
		{ kind = "HasItem", itemId = "OozeContainer", amount = 1 }

	Actions use the same format as QuestActions:
		{ type = "StartQuest", questId = "FirstContact" }
		{ type = "SetQuestFlag", flag = "MetTheScout", value = true }
		{ type = "GiveReward", rewardId = "Credits", amount = 50 }
		{ type = "EmitQuestEvent", event = "NpcTalked", payload = { npcId = "Scout01" } }

	Example dialog with quest integration:
		An NPC offers a quest if the player hasn't started it,
		acknowledges progress if it's active,
		and thanks the player if it's complete.
]]

local Definitions = {}

Definitions.Dialogs = {

	------------------------------------------------------------------------
	-- EXAMPLE: Quest-giving NPC
	------------------------------------------------------------------------
	BotShopOwner = {
		npcId = "BotShopOwner",
		displayName = "Bot Shop Owner",

		-- Multiple roots — first one whose conditions pass is used.
		-- Put more specific conditions first, fallback last.
		roots = {
			{
				id = "root_quest_complete",
				conditions = {
					{ kind = "HasQuestCompleted", questId = "FirstContact" },
				},
				nodeId = "thanks",
			},
			{
				id = "root_quest_active",
				conditions = {
					{ kind = "HasQuestActive", questId = "FirstContact" },
				},
				nodeId = "inprogress",
			},
			{
				id = "root_default",
				-- No conditions = always matches (fallback)
				nodeId = "greeting",
			},
		},

		nodes = {
			greeting = {
				id = "greeting",
				npcText = "Hey... you're not supposed to be out here. I picked up a weird signal from the crash site. Interested?",
				options = {
					{
						text = "Tell me more.",
						nextNode = "quest_offer",
					},
					{
						text = "Not right now.",
						nextNode = nil, -- ends dialog
					},
				},
			},

			quest_offer = {
				id = "quest_offer",
				npcText = "Something crashed in the woods. Sci Co doesn't want anyone poking around, which means it's worth poking around. I need someone to check it out. You in?",
				options = {
					{
						text = "I'm in. [Accept Quest]",
						nextNode = "quest_accepted",
						actions = {
							{ type = "StartQuest", questId = "FirstContact" },
						},
					},
					{
						text = "Sounds dangerous. Pass.",
						nextNode = "quest_declined",
					},
				},
			},

			quest_accepted = {
				id = "quest_accepted",
				npcText = "Good. Head to the crash site and see what you can find. Watch out for crawlers — they've been agitated lately.",
				actions = {
					{ type = "EmitQuestEvent", event = "NpcTalked", payload = { npcId = "Scout01" } },
				},
				options = {
					{
						text = "On it.",
						nextNode = nil,
					},
				},
			},

			quest_declined = {
				id = "quest_declined",
				npcText = "Your loss. Come find me if you change your mind.",
				options = {
					{
						text = "[Leave]",
						nextNode = nil,
					},
				},
			},

			inprogress = {
				id = "inprogress",
				npcText = "Still working on it? The crash site is out in the woods. Don't come back empty-handed.",
				actions = {
					{ type = "EmitQuestEvent", event = "NpcTalked", payload = { npcId = "Scout01" } },
				},
				options = {
					{
						text = "I'm on it.",
						nextNode = nil,
					},
				},
			},

			thanks = {
				id = "thanks",
				npcText = "You actually pulled it off. Not bad for an intern. I'll be in touch.",
				actions = {
					{ type = "EmitQuestEvent", event = "NpcTalked", payload = { npcId = "Scout01" } },
				},
				options = {
					{
						text = "[Leave]",
						nextNode = nil,
					},
				},
			},
		},
	},

	------------------------------------------------------------------------
	-- EXAMPLE: Simple NPC with branching conversation
	------------------------------------------------------------------------
	BotShopOwner2 = {
		npcId = "BotShopOwner2",
		displayName = "Bot Shop Owner",

		roots = {
			{
				id = "root_default",
				nodeId = "greeting",
			},
		},

		nodes = {
			greeting = {
				id = "greeting",
				npcText = "What'll it be?",
				options = {
					{
						text = "What's the word around here?",
						nextNode = "gossip",
					},
					{
						text = "Know anyone hiring?",
						nextNode = "jobs",
					},
					{
						text = "Nothing. Just passing through.",
						nextNode = nil,
					},
				},
			},

			gossip = {
				id = "gossip",
				npcText = "Word is something big went down on the lower decks. Sci Co locked the whole section. Nobody in, nobody out.",
				options = {
					{
						text = "Interesting. Thanks.",
						nextNode = nil,
					},
					{
						text = "Know anyone hiring?",
						nextNode = "jobs",
					},
				},
			},

			jobs = {
				id = "jobs",
				npcText = "Check the contracts board by the docking bay. Always someone looking for expendable labor.",
				actions = {
					{ type = "SetQuestFlag", flag = "KnowsAboutContractsBoard", value = true },
				},
				options = {
					{
						text = "Thanks for the tip.",
						nextNode = nil,
					},
				},
			},
		},
	},
	
	Ghavek = {
		npcId = "Ghavek",
		displayName = "Ghavek",

		roots = {
			{
				id = "root_unknown",
				conditions = {
					{ kind = "ReputationLessThan", faction = "DarkMatterPlumbing", amount = 10  },
				},
				nodeId = "special_greeting",
			},
			{
				id = "root_default",
				-- No conditions = always matches (fallback)
				nodeId = "greeting",
			},
		},

		nodes = {
			greeting = {
				id = "greeting",
				npcText = "Whadda ya want",
				options = {
					{
						text = "What's the word around here?",
						nextNode = "gossip",
					},
					{
						text = "Nothing. Just passing through.",
						nextNode = nil,
					},
				},
			},
			special_greeting = {
				id = "special_greeting",
				npcText = "You shouldn't be here kid.",
				options = {
					{
						text = "Ok no problem. I'm leaving",
						nextNode = nil,
					},
				},
			},
			gossip = {
				id = "gossip",
				npcText = "Word is something big went down on the lower decks. Sci Co locked the whole section. Nobody in, nobody out.",
				options = {
					{
						text = "Interesting. Thanks.",
						nextNode = nil,
					},
					{
						text = "Know anyone hiring?",
						nextNode = "jobs",
					},
				},
			},

		},
	},
}

return Definitions
