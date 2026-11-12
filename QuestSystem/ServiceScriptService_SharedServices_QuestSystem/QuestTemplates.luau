local Templates = {}
Templates.ById = {}

local function Register(id, def)
	Templates.ById[id] = def
end

function Templates.Get(id)
	return Templates.ById[id]
end

Register("TalkToNpc", {
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

Register("KillEnemies", {
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

Register("CollectItems", {
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

Register("ReachZone", {
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

Register("Signal", {
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

Register("InteractObject", {
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

Register("HasItem", {
	type = "CONDITION",
	defaults = {
		hidden = false,
		checkInterval = 0.5,
		predicate = "HasItemCount",
	},
	build = function(step)
		step.predicate = step.predicate or "HasItemCount"
		step.predicateArgs = step.predicateArgs or {
			itemId = step.itemId,
			amount = step.amount or 1,
		}
		return step
	end,
})

Register("StayInZone", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
		requiredSeconds = 5,
		predicate = "IsInZone",
		checkInterval = 0.1,
	},
	build = function(step)
		step.statefulKind = "StayInZone"
		step.predicate = step.predicate or "IsInZone"
		step.predicateArgs = step.predicateArgs or {
			zoneId = step.zoneId,
		}
		return step
	end,
})

Register("TimedObjective", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
		duration = 30,
	},
	build = function(step)
		step.statefulKind = "TimedObjective"
		return step
	end,
})

Register("Escort", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
	},
	build = function(step)
		step.statefulKind = "Escort"
		return step
	end,
})

Register("DefendArea", {
	type = "STATEFUL",
	defaults = {
		hidden = false,
		duration = 30,
	},
	build = function(step)
		step.statefulKind = "DefendArea"
		return step
	end,
})

Register("SequenceInteract", {
	type = "SEQUENCE",
	defaults = {
		hidden = false,
		event = "ObjectInteracted",
		resetOnWrong = false,
	},
	build = function(step)
		step.sequence = step.sequence or {}
		return step
	end,
})

return Templates