--[[
	QuestStepHandlers
	Registry of step-type handlers. QuestService delegates ALL per-step logic here.

	Each handler is a table with these methods:
		:Init(ctx)                 – called once when quest starts, set up runtime state
		:OnEvent(ctx, event, pay)  – called on EmitEvent, return true if step state changed
		:Update(ctx, dt)           – called every Tick, return true if step state changed
		:IsComplete(ctx)           – return true if step should auto-complete
		:IsFailed(ctx)             – return true + reason if step/quest should fail

	ctx (context) contains:
		ctx.player        Player
		ctx.questId       string
		ctx.stepId        string
		ctx.stepDef       table   (the expanded definition)
		ctx.stepState     table   (the mutable runtime state)
		ctx.questService  QuestService

	To register a new handler:
		QuestStepHandlers.Register("MY_TYPE", {
			Init = function(self, ctx) ... end,
			OnEvent = function(self, ctx, eventName, payload) ... end,
			Update = function(self, ctx, dt) ... end,
		})

	Then use `type = "MY_TYPE"` in your step definitions or templates.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestUtil = require(ReplicatedStorage.SharedModules.Quests.QuestUtil)

local QuestStepHandlers = {}
QuestStepHandlers._registry = {}

function QuestStepHandlers.Register(stepType, handler)
	QuestStepHandlers._registry[stepType] = handler
end

function QuestStepHandlers.Get(stepType)
	return QuestStepHandlers._registry[stepType]
end

------------------------------------------------------------------------
-- Helper: mark a step complete (used by multiple handlers)
------------------------------------------------------------------------
local function markComplete(ctx)
	local stepState = ctx.stepState
	local stepDef = ctx.stepDef
	if stepState.completed then
		return
	end

	stepState.completed = true
	stepState.progress = stepDef.goal or stepState.progress or 1
	stepState.lastUpdatedAt = QuestUtil.Now()

	ctx.questService:RunActions(ctx.player, ctx.questId, ctx.stepId, stepDef.onComplete)
	ctx.questService:SendToast(ctx.player, {
		text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
		kind = "ObjectiveComplete",
		questId = ctx.questId,
		stepId = ctx.stepId,
	})
end

------------------------------------------------------------------------
-- EVENT_COUNTER
-- Listens for a specific event name + payload match, increments progress.
------------------------------------------------------------------------
QuestStepHandlers.Register("EVENT_COUNTER", {
	Init = function(_self, ctx)
		ctx.stepState.progress = ctx.stepState.progress or 0
	end,

	OnEvent = function(_self, ctx, eventName, payload)
		local stepDef = ctx.stepDef
		local stepState = ctx.stepState
		if stepState.completed then
			return false
		end

		if stepDef.event ~= eventName then
			return false
		end

		if not QuestUtil.Matches(payload, stepDef.match) then
			return false
		end

		local amount = (payload and payload.amount) or 1
		local goal = stepDef.goal or 1
		stepState.progress = math.min((stepState.progress or 0) + amount, goal)
		stepState.lastUpdatedAt = QuestUtil.Now()

		if stepState.progress >= goal then
			markComplete(ctx)
		end

		return true
	end,

	Update = function(_self, _ctx, _dt)
		return false
	end,
})

------------------------------------------------------------------------
-- SEQUENCE
-- Ordered series of event matches. Optionally resets on wrong input.
------------------------------------------------------------------------
QuestStepHandlers.Register("SEQUENCE", {
	Init = function(_self, ctx)
		ctx.stepState.sequenceIndex = ctx.stepState.sequenceIndex or 1
		ctx.stepState.progress = ctx.stepState.progress or 0
	end,

	OnEvent = function(_self, ctx, eventName, payload)
		local stepDef = ctx.stepDef
		local stepState = ctx.stepState
		if stepState.completed then
			return false
		end

		local sequence = stepDef.sequence or {}
		local currentIndex = stepState.sequenceIndex or 1
		local expected = sequence[currentIndex]
		if not expected then
			return false
		end

		-- Check if this event matches the current expected entry
		local expectedEvent = expected.event or stepDef.event
		if eventName ~= expectedEvent then
			return false
		end

		if QuestUtil.Matches(payload, expected.match) then
			-- Correct input — advance
			stepState.sequenceIndex = currentIndex + 1
			stepState.progress = currentIndex
			stepState.sequenceProgressText = expected.progressText
			stepState.lastUpdatedAt = QuestUtil.Now()

			if currentIndex >= #sequence then
				markComplete(ctx)
			end
			return true
		end

		-- Wrong input — check if we should reset
		if stepDef.resetOnWrongEvent and stepDef.wrongEventFilter then
			local filter = stepDef.wrongEventFilter
			if filter.event == eventName then
				local shouldReset = false

				if filter.matchAny then
					for _, candidate in ipairs(filter.matchAny) do
						if QuestUtil.Matches(payload, candidate) then
							shouldReset = true
							break
						end
					end
				elseif QuestUtil.Matches(payload, filter.match) then
					shouldReset = true
				end

				if shouldReset then
					stepState.sequenceIndex = 1
					stepState.progress = 0
					stepState.sequenceProgressText = nil
					stepState.lastUpdatedAt = QuestUtil.Now()
					return true
				end
			end
		end

		return false
	end,

	Update = function(_self, _ctx, _dt)
		return false
	end,
})

------------------------------------------------------------------------
-- CONDITION
-- Polled periodically. Completes when a QuestConditions predicate is met.
-- Step definition must include: condition = { kind = "...", ... }
-- Optional: checkInterval (seconds, default 0.5)
------------------------------------------------------------------------
QuestStepHandlers.Register("CONDITION", {
	Init = function(_self, ctx)
		ctx.stepState.progress = ctx.stepState.progress or 0
		ctx.stepState._conditionElapsed = 0
	end,

	OnEvent = function(_self, _ctx, _eventName, _payload)
		return false
	end,

	Update = function(_self, ctx, dt)
		local stepState = ctx.stepState
		if stepState.completed then
			return false
		end

		-- Throttle evaluation
		stepState._conditionElapsed = (stepState._conditionElapsed or 0) + dt
		local interval = ctx.stepDef.checkInterval or 0.5
		if stepState._conditionElapsed < interval then
			return false
		end
		stepState._conditionElapsed = 0

		local QuestConditions = require(script.Parent.QuestConditions)
		local met = QuestConditions.Evaluate(ctx, ctx.stepDef.condition)

		if met then
			stepState.progress = 1
			markComplete(ctx)
			return true
		end

		return false
	end,
})

------------------------------------------------------------------------
-- STATEFUL
-- Long-running steps with custom sub-handlers (escort, defend, timed).
-- Step definition must include: stateful = { handler = "HandlerName", ... }
-- Sub-handlers are registered separately via QuestStatefulHandlers.
------------------------------------------------------------------------
QuestStepHandlers.Register("STATEFUL", {
	Init = function(_self, ctx)
		local stepState = ctx.stepState
		stepState.stateful = stepState.stateful or {
			started = false,
			startedAt = nil,
			elapsed = 0,
			data = {},
		}
	end,

	OnEvent = function(_self, ctx, eventName, payload)
		local runtime = ctx.stepState.stateful
		if not runtime or not runtime.started then
			return false
		end

		local QuestStatefulHandlers = require(script.Parent.QuestStatefulHandlers)
		local handlerName = ctx.stepDef.stateful and ctx.stepDef.stateful.handler
		local handler = handlerName and QuestStatefulHandlers.Get(handlerName)

		if handler and handler.onEvent then
			local ok, err = pcall(handler.onEvent, handler, ctx, eventName, payload)
			if not ok then
				warn("[QuestStepHandlers] Stateful onEvent error:", ctx.questId, ctx.stepId, err)
			end
		end

		return false
	end,

	Update = function(_self, ctx, dt)
		local stepState = ctx.stepState
		local runtime = stepState.stateful
		if not runtime then
			return false
		end

		local QuestStatefulHandlers = require(script.Parent.QuestStatefulHandlers)
		local handlerName = ctx.stepDef.stateful and ctx.stepDef.stateful.handler
		local handler = handlerName and QuestStatefulHandlers.Get(handlerName)

		-- Auto-start on first eligible update
		if not runtime.started then
			runtime.started = true
			runtime.startedAt = QuestUtil.Now()
			runtime.elapsed = 0

			if handler and handler.start then
				local ok, err = pcall(handler.start, handler, ctx)
				if not ok then
					warn("[QuestStepHandlers] Stateful start error:", ctx.questId, ctx.stepId, err)
				end
			end
		end

		runtime.elapsed += dt
		stepState.lastUpdatedAt = QuestUtil.Now()

		-- Delegate update
		if handler and handler.update then
			local ok, err = pcall(handler.update, handler, ctx, dt)
			if not ok then
				warn("[QuestStepHandlers] Stateful update error:", ctx.questId, ctx.stepId, err)
			end
		end

		-- Check failure
		if handler and handler.isFailed then
			local ok, failed, failReason = pcall(handler.isFailed, handler, ctx)
			if ok and failed then
				ctx.questService:FailQuest(
					ctx.player,
					ctx.questId,
					failReason or ("Stateful step failed: " .. ctx.stepId)
				)
				return true
			end
		end

		-- Check completion
		if handler and handler.isComplete then
			local ok, complete = pcall(handler.isComplete, handler, ctx)
			if ok and complete then
				markComplete(ctx)
				return true
			end
		end

		return false
	end,
})

return QuestStepHandlers
