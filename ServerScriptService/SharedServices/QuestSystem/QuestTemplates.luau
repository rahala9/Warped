--[[
	QuestTemplates
	Registry of step templates that expand shorthand step definitions into
	fully-typed step definitions that QuestStepHandlers can process.

	Each template has:
		type      – the step type (EVENT_COUNTER, SEQUENCE, CONDITION, STATEFUL)
		defaults  – default field values merged into the step
		build(step) – optional transform function, returns the modified step

	To add a new template:
		QuestTemplates.Register("MyTemplate", {
			type = "EVENT_COUNTER",
			defaults = { event = "SomeEvent", goal = 1 },
			build = function(step)
				step.match = step.match or { thingId = step.thingId }
				return step
			end,
		})

	Then use in a quest definition:
		{ id = "DoThing", template = "MyTemplate", thingId = "Widget01" }
]]

local QuestTemplates = {}
QuestTemplates._registry = {}

function QuestTemplates.Register(id, def)
	QuestTemplates._registry[id] = def
end

function QuestTemplates.Get(id)
	return QuestTemplates._registry[id]
end

------------------------------------------------------------------------
-- EVENT_COUNTER templates
------------------------------------------------------------------------

QuestTemplates.Register("TalkToNpc", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "NpcTalked",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "NpcTalked"
		step.goal = step.goal or 1
		step.match = step.match or { npcId = step.npcId }
		return step
	end,
})

QuestTemplates.Register("KillEnemies", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "EnemyKilled",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "EnemyKilled"
		step.goal = step.goal or 1
		step.match = step.match or { enemyType = step.enemyType }
		return step
	end,
})

QuestTemplates.Register("CollectItems", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "ItemCollected",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "ItemCollected"
		step.goal = step.goal or 1
		step.match = step.match or { itemId = step.itemId }
		return step
	end,
})

QuestTemplates.Register("ReachZone", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "ZoneEntered",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "ZoneEntered"
		step.goal = 1
		step.match = step.match or { zoneId = step.zoneId }
		return step
	end,
})

QuestTemplates.Register("BringItemToZone", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "ItemEnteredZone",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "ItemEnteredZone"
		step.goal = step.goal or 1
		step.match = step.match or {
			itemId = step.itemId,
			zoneId = step.zoneId,
		}
		return step
	end,
})

QuestTemplates.Register("Signal", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "QuestSignal",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "QuestSignal"
		step.goal = 1
		step.match = step.match or { signal = step.signal }
		return step
	end,
})

QuestTemplates.Register("InteractObject", {
	type = "EVENT_COUNTER",
	defaults = {
		event = "ObjectInteracted",
		goal = 1,
		hidden = false,
	},
	build = function(step)
		step.event = step.event or "ObjectInteracted"
		step.goal = step.goal or 1

		if not step.match then
			step.match = {}
			if step.objectId ~= nil then
				step.match.objectId = step.objectId
			end
			if step.objectType ~= nil then
				step.match.objectType = step.objectType
			end
			if step.toolId ~= nil then
				step.match.toolId = step.toolId
			end
		end

		return step
	end,
})

------------------------------------------------------------------------
-- CONDITION templates
------------------------------------------------------------------------

QuestTemplates.Register("HasItem", {
	type = "CONDITION",
	defaults = {
		hidden = false,
		checkInterval = 0.5,
	},
	build = function(step)
		-- Build a proper condition table that QuestConditions understands
		step.condition = step.condition or {
			kind = "InventoryHasItem",
			itemId = step.itemId,
			amount = step.amount or 1,
		}
		return step
	end,
})

------------------------------------------------------------------------
-- STATEFUL templates
------------------------------------------------------------------------

QuestTemplates.Register("Escort", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
	},
	build = function(step)
		-- Ensure stateful config block exists with proper handler name
		step.stateful = step.stateful or {
			handler = "EscortActor",
			actorKey = step.actorKey,
			destinationZoneId = step.destinationZoneId,
			failIfActorDestroyed = step.failIfActorDestroyed,
			failIfSignal = step.failIfSignal,
			completeOnSignal = step.completeOnSignal,
		}
		step.stateful.handler = step.stateful.handler or "EscortActor"
		return step
	end,
})

QuestTemplates.Register("Defend", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
		duration = 30,
	},
	build = function(step)
		step.stateful = step.stateful or {
			handler = "DefendObjective",
			duration = step.duration or 30,
			objectiveId = step.objectiveId,
			failIfSignal = step.failIfSignal,
			completeOnSignal = step.completeOnSignal,
		}
		step.stateful.handler = step.stateful.handler or "DefendObjective"
		return step
	end,
})

QuestTemplates.Register("TimedInteract", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
	},
	build = function(step)
		step.stateful = step.stateful or {
			handler = "TimedInteract",
			duration = step.duration or 30,
			successEvent = step.successEvent or "ObjectInteracted",
			successMatch = step.successMatch,
		}
		step.stateful.handler = step.stateful.handler or "TimedInteract"
		return step
	end,
})

------------------------------------------------------------------------
-- SEQUENCE templates
------------------------------------------------------------------------

QuestTemplates.Register("SequenceInteract", {
	type = "SEQUENCE",
	defaults = {
		hidden = false,
		event = "ObjectInteracted",
	},
	build = function(step)
		step.sequence = step.sequence or {}
		return step
	end,
})

return QuestTemplates
