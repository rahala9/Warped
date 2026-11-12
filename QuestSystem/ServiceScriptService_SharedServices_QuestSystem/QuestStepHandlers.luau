local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestUtil = require(ReplicatedStorage.SharedModules.Quests.QuestUtil)
local Predicates = require(script.Parent.QuestPredicates)

local Handlers = {}

local function completeStep(questService, player, questId, stepDef, stepState)
	if stepState.completed then
		return
	end

	stepState.completed = true
	stepState.progress = stepDef.goal or stepState.progress or 1

	questService:RunStepActions(player, questId, stepDef.id, stepDef.onComplete)
	questService:SendToast(player, {
		text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
		kind = "ObjectiveComplete",
	})
end

Handlers.EVENT_COUNTER = {}

function Handlers.EVENT_COUNTER.Init(_questService, _player, _questId, stepDef, stepState)
	stepState.progress = stepState.progress or 0
	stepState.goal = stepDef.goal or 1
end

function Handlers.EVENT_COUNTER.OnEvent(questService, player, questId, stepDef, stepState, eventName, payload)
	if stepState.completed or not stepState.revealed then
		return false
	end

	if stepDef.event ~= eventName then
		return false
	end

	if not QuestUtil.Matches(payload, stepDef.match) then
		return false
	end

	local amount = (payload and payload.amount) or 1
	stepState.progress = math.min((stepState.progress or 0) + amount, stepDef.goal or 1)

	if stepState.progress >= (stepDef.goal or 1) then
		completeStep(questService, player, questId, stepDef, stepState)
	end

	return true
end

function Handlers.EVENT_COUNTER.Update()
	return false
end

Handlers.CONDITION = {}

function Handlers.CONDITION.Init(_questService, _player, _questId, stepDef, stepState)
	stepState.progress = stepState.progress or 0
	stepState._conditionElapsed = stepState._conditionElapsed or 0
end

function Handlers.CONDITION.OnEvent()
	return false
end

function Handlers.CONDITION.Update(questService, player, questId, stepDef, stepState, dt)
	if stepState.completed or not stepState.revealed then
		return false
	end

	stepState._conditionElapsed += dt
	local interval = stepDef.checkInterval or 0.5
	if stepState._conditionElapsed < interval then
		return false
	end
	stepState._conditionElapsed = 0

	local ok = Predicates.Evaluate(stepDef.predicate, {
		player = player,
		questService = questService,
		services = questService.Services,
		questId = questId,
		stepId = stepDef.id,
	}, stepDef.predicateArgs)

	if ok then
		stepState.progress = 1
		completeStep(questService, player, questId, stepDef, stepState)
		return true
	end

	return false
end

Handlers.SEQUENCE = {}

function Handlers.SEQUENCE.Init(_questService, _player, _questId, stepDef, stepState)
	stepState.sequenceIndex = stepState.sequenceIndex or 1
	stepState.progress = stepState.progress or 0
	stepState.goal = #(stepDef.sequence or {})
end

function Handlers.SEQUENCE.OnEvent(questService, player, questId, stepDef, stepState, eventName, payload)
	if stepState.completed or not stepState.revealed then
		return false
	end

	local sequence = stepDef.sequence or {}
	local currentIndex = stepState.sequenceIndex or 1
	local currentExpected = sequence[currentIndex]
	if not currentExpected then
		return false
	end

	local expectedEvent = currentExpected.event or stepDef.event
	if eventName ~= expectedEvent then
		return false
	end

	if QuestUtil.Matches(payload, currentExpected.match) then
		stepState.sequenceIndex = currentIndex + 1
		stepState.progress = currentIndex

		if currentIndex >= #sequence then
			completeStep(questService, player, questId, stepDef, stepState)
		end

		return true
	end

	if stepDef.resetOnWrong then
		stepState.sequenceIndex = 1
		stepState.progress = 0
		return true
	end

	return false
end

function Handlers.SEQUENCE.Update()
	return false
end

Handlers.STATEFUL = {}

function Handlers.STATEFUL.Init(questService, player, questId, stepDef, stepState)
	stepState.runtime = stepState.runtime or {}
	stepState.progress = stepState.progress or 0

	local kind = stepDef.statefulKind

	if kind == "StayInZone" then
		stepState.runtime.timeInside = stepState.runtime.timeInside or 0

	elseif kind == "TimedObjective" then
		stepState.runtime.elapsed = stepState.runtime.elapsed or 0

	elseif kind == "Escort" then
		stepState.runtime.destinationReached = stepState.runtime.destinationReached or false
		stepState.runtime.failed = stepState.runtime.failed or false
		stepState.runtime.actorKey = stepDef.actorKey
		stepState.runtime.destinationZoneId = stepDef.destinationZoneId
		stepState.runtime.failSignal = stepDef.failSignal
		stepState.runtime.completeSignal = stepDef.completeSignal

	elseif kind == "DefendArea" then
		stepState.runtime.elapsed = stepState.runtime.elapsed or 0
		stepState.runtime.failed = stepState.runtime.failed or false
	end

	if stepDef.onStateStart and not stepState.runtime.started then
		stepState.runtime.started = true
		questService:RunStepActions(player, questId, stepDef.id, stepDef.onStateStart)
	end
end

function Handlers.STATEFUL.OnEvent(questService, player, questId, stepDef, stepState, eventName, payload)
	if stepState.completed or not stepState.revealed then
		return false
	end

	local kind = stepDef.statefulKind
	local changed = false

	if kind == "Escort" then
		if eventName == "QuestSignal" and payload then
			if stepDef.completeSignal and payload.signal == stepDef.completeSignal then
				stepState.runtime.destinationReached = true
				changed = true
			end

			if stepDef.failSignal and payload.signal == stepDef.failSignal then
				stepState.runtime.failed = true
				changed = true
			end
		end

	elseif kind == "DefendArea" then
		if eventName == "QuestSignal" and payload then
			if stepDef.failSignal and payload.signal == stepDef.failSignal then
				stepState.runtime.failed = true
				changed = true
			end
		end
	end

	return changed
end

function Handlers.STATEFUL.Update(questService, player, questId, stepDef, stepState, dt)
	if stepState.completed or not stepState.revealed then
		return false
	end

	local kind = stepDef.statefulKind

	if kind == "StayInZone" then
		local inside = Predicates.Evaluate(stepDef.predicate, {
			player = player,
			questService = questService,
			services = questService.Services,
			questId = questId,
			stepId = stepDef.id,
		}, stepDef.predicateArgs)

		if inside then
			stepState.runtime.timeInside += dt
		else
			stepState.runtime.timeInside = 0
		end

		local required = stepDef.requiredSeconds or 5
		stepState.progress = math.clamp(stepState.runtime.timeInside, 0, required)

		if stepState.runtime.timeInside >= required then
			completeStep(questService, player, questId, stepDef, stepState)
			return true
		end

	elseif kind == "TimedObjective" then
		stepState.runtime.elapsed += dt
		local duration = stepDef.duration or 30
		stepState.progress = math.clamp(stepState.runtime.elapsed, 0, duration)

		if stepState.runtime.elapsed >= duration then
			completeStep(questService, player, questId, stepDef, stepState)
			return true
		end

	elseif kind == "Escort" then
		if stepState.runtime.failed then
			if not stepState.failed then
				stepState.failed = true
				questService: