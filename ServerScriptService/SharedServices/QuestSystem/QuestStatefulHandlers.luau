--[[
	QuestStatefulHandlers
	Sub-handler registry for STATEFUL-type quest steps.

	These are the "inner" handlers that give STATEFUL steps their specific
	behavior (escort an NPC, defend a point, timed interact, etc.).

	Each sub-handler is a table with optional methods:
		:start(ctx)                – called once when the stateful step begins
		:update(ctx, dt)           – called every tick while step is active
		:onEvent(ctx, event, pay)  – called when an event fires while step is active
		:isComplete(ctx)           – return true when the step should complete
		:isFailed(ctx)             – return true, reason when the step/quest should fail

	ctx is the same context table from QuestStepHandlers:
		ctx.player, ctx.questId, ctx.stepId, ctx.stepDef, ctx.stepState, ctx.questService

	The stateful runtime data is at ctx.stepState.stateful:
		.started, .startedAt, .elapsed, .data (free-form table for handler state)

	Step definitions reference sub-handlers via:
		stateful = { handler = "TimedInteract", duration = 45, ... }

	To add a new sub-handler:
		QuestStatefulHandlers.Register("MyHandler", {
			start = function(self, ctx) ... end,
			update = function(self, ctx, dt) ... end,
			isComplete = function(self, ctx) return false end,
			isFailed = function(self, ctx) return false end,
		})
]]

local QuestActions = require(script.Parent.QuestActions)

local QuestStatefulHandlers = {}
QuestStatefulHandlers._registry = {}

function QuestStatefulHandlers.Register(handlerName, handler)
	QuestStatefulHandlers._registry[handlerName] = handler
end

function QuestStatefulHandlers.Get(handlerName)
	return QuestStatefulHandlers._registry[handlerName]
end

------------------------------------------------------------------------
-- TimedInteract
-- Player must interact with a specific object before time runs out.
-- stateful = { handler = "TimedInteract", duration = 45,
--              successEvent = "ObjectInteracted",
--              successMatch = { objectId = "SomePanel" } }
------------------------------------------------------------------------
QuestStatefulHandlers.Register("TimedInteract", {
	start = function(_self, ctx)
		local data = ctx.stepState.stateful.data
		data.succeeded = false
		data.duration = ctx.stepDef.stateful.duration or 30
	end,

	onEvent = function(_self, ctx, eventName, payload)
		local cfg = ctx.stepDef.stateful
		local data = ctx.stepState.stateful.data

		local successEvent = cfg.successEvent or "ObjectInteracted"
		if eventName == successEvent then
			local QuestUtil = require(script.Parent.Parent.SharedModules and script.Parent.Parent.SharedModules.Quests and script.Parent.Parent.SharedModules.Quests.QuestUtil or script.Parent.QuestUtil)
			-- Inline require fallback
			local ok = true
			if cfg.successMatch then
				local QU = require(game:GetService("ReplicatedStorage").SharedModules.Quests.QuestUtil)
				ok = QU.Matches(payload, cfg.successMatch)
			end
			if ok then
				data.succeeded = true
			end
		end
	end,

	isComplete = function(_self, ctx)
		return ctx.stepState.stateful.data.succeeded == true
	end,

	isFailed = function(_self, ctx)
		local data = ctx.stepState.stateful.data
		local elapsed = ctx.stepState.stateful.elapsed or 0
		local duration = data.duration or 30

		if not data.succeeded and elapsed >= duration then
			return true, "Time expired"
		end
		return false
	end,
})

------------------------------------------------------------------------
-- EscortActor
-- Escort a spawned actor to a destination zone.
-- stateful = { handler = "EscortActor", actorKey = "...",
--              destinationZoneId = "...",
--              failIfSignal = "...", completeOnSignal = "..." }
------------------------------------------------------------------------
QuestStatefulHandlers.Register("EscortActor", {
	start = function(_self, ctx)
		local data = ctx.stepState.stateful.data
		data.reachedDestination = false
		data.actorDied = false
	end,

	onEvent = function(_self, ctx, eventName, payload)
		local cfg = ctx.stepDef.stateful
		local data = ctx.stepState.stateful.data

		if eventName == "QuestSignal" and payload then
			if cfg.completeOnSignal and payload.signal == cfg.completeOnSignal then
				data.reachedDestination = true
			end
			if cfg.failIfSignal and payload.signal == cfg.failIfSignal then
				data.actorDied = true
			end
		end
	end,

	update = function(_self, ctx, _dt)
		local cfg = ctx.stepDef.stateful
		local data = ctx.stepState.stateful.data

		-- Also check if actor was destroyed externally
		if cfg.failIfActorDestroyed and cfg.actorKey then
			local actor = QuestActions.GetSpawnedActor(ctx.player, cfg.actorKey)
			if not actor or not actor.Parent then
				data.actorDied = true
			end
		end
	end,

	isComplete = function(_self, ctx)
		return ctx.stepState.stateful.data.reachedDestination == true
	end,

	isFailed = function(_self, ctx)
		if ctx.stepState.stateful.data.actorDied then
			return true, "Escort target was lost"
		end
		return false
	end,
})

------------------------------------------------------------------------
-- DefendObjective
-- Defend a point for a duration. Fails if a signal fires.
-- stateful = { handler = "DefendObjective", duration = 60,
--              objectiveId = "...",
--              failIfSignal = "...", completeOnSignal = "..." }
------------------------------------------------------------------------
QuestStatefulHandlers.Register("DefendObjective", {
	start = function(_self, ctx)
		local data = ctx.stepState.stateful.data
		data.objectiveDestroyed = false
		data.duration = ctx.stepDef.stateful.duration or 60
	end,

	onEvent = function(_self, ctx, eventName, payload)
		local cfg = ctx.stepDef.stateful
		local data = ctx.stepState.stateful.data

		if eventName == "QuestSignal" and payload then
			if cfg.failIfSignal and payload.signal == cfg.failIfSignal then
				data.objectiveDestroyed = true
			end
			if cfg.completeOnSignal and payload.signal == cfg.completeOnSignal then
				data.completedEarly = true
			end
		end
	end,

	isComplete = function(_self, ctx)
		local data = ctx.stepState.stateful.data
		if data.completedEarly then
			return true
		end

		local elapsed = ctx.stepState.stateful.elapsed or 0
		return elapsed >= (data.duration or 60)
	end,

	isFailed = function(_self, ctx)
		if ctx.stepState.stateful.data.objectiveDestroyed then
			return true, "Objective was destroyed"
		end
		return false
	end,
})

return QuestStatefulHandlers
