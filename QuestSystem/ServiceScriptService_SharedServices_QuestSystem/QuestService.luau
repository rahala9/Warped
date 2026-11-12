local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuestUtil = require(ReplicatedStorage.SharedModules.Quests.QuestUtil)
local QuestRemotes = require(ReplicatedStorage.SharedModules.Quests.QuestRemotes)

local Definitions = require(script.Parent.QuestDefinitions)
local Templates = require(script.Parent.QuestTemplates)
local Actions = require(script.Parent.QuestActions)
local Persistence = require(script.Parent.QuestPersistence)
local StatefulHandlers = require(script.Parent.QuestStatefulHandlers)

local QuestService = {}
QuestService.__index = QuestService

local PlayerData = {}
local ExpandedQuestDefs = {}

local QuestStateChanged
local QuestToast

local function now()
	return os.time()
end

local function deepCopy(value)
	return QuestUtil.DeepCopy(value)
end

local function getQuestDef(questId)
	return ExpandedQuestDefs[questId]
end

local function safePairs(tbl)
	if type(tbl) ~= "table" then
		return next, {}, nil
	end
	return pairs(tbl)
end

local function buildActionContext(self, player, questId, stepId)
	return {
		player = player,
		questId = questId,
		stepId = stepId,
		questService = self,
	}
end

local function createRuntimeStep(stepDef)
	local stepState = {
		id = stepDef.id,
		type = stepDef.type,
		revealed = not stepDef.hidden,
		completed = false,
		failed = false,

		progress = 0,
		lastUpdatedAt = now(),

		sequenceIndex = 1,
		sequenceProgressText = nil,

		stateful = nil,
	}

	if stepDef.type == "STATEFUL" then
		stepState.stateful = {
			started = false,
			startedAt = nil,
			elapsed = 0,
			data = {},
		}
	end

	return stepState
end

local function mergeDefaults(target, defaults)
	for k, v in pairs(defaults or {}) do
		if target[k] == nil then
			target[k] = deepCopy(v)
		end
	end
end

local function expandTemplate(stepDef)
	local finalStep = deepCopy(stepDef)

	if finalStep.template then
		local template = Templates.Get(finalStep.template)
		assert(template, ("Missing quest template: %s"):format(tostring(finalStep.template)))

		mergeDefaults(finalStep, template.defaults)
		finalStep.type = finalStep.type or template.type

		if template.build then
			finalStep = template.build(finalStep)
		end
	end

	assert(finalStep.id, "Quest step missing id")
	assert(finalStep.type, ("Quest step %s missing type"):format(tostring(finalStep.id)))

	return finalStep
end

local function expandQuestDef(def)
	local quest = deepCopy(def)

	quest.requires = quest.requires or {}
	quest.steps = quest.steps or {}
	quest.stepMap = {}

	for index, stepDef in ipairs(quest.steps) do
		local expanded = expandTemplate(stepDef)
		expanded._index = index
		quest.steps[index] = expanded
		quest.stepMap[expanded.id] = expanded
	end

	return quest
end

for questId, def in pairs(Definitions.Quests or {}) do
	ExpandedQuestDefs[questId] = expandQuestDef(def)
end

function QuestService:GetPlayerData(player)
	return PlayerData[player]
end

function QuestService:GetQuestState(player, questId)
	local data = PlayerData[player]
	if not data then
		return nil
	end
	return data.active[questId]
end

function QuestService:GetCompletedQuestData(player, questId)
	local data = PlayerData[player]
	if not data then
		return nil
	end
	return data.completed[questId]
end

function QuestService:SendToast(player, toast)
	if QuestToast then
		QuestToast:FireClient(player, toast)
	end
end

function QuestService:BroadcastState(player)
	local data = PlayerData[player]
	if not data then
		return
	end

	if QuestStateChanged then
		QuestStateChanged:FireClient(player, data)
	end
end

function QuestService:SetFlag(player, flag, value)
	local data = PlayerData[player]
	if not data then
		return
	end

	data.flags[flag] = value
	self:BroadcastState(player)
end

function QuestService:GetFlag(player, flag)
	local data = PlayerData[player]
	if not data then
		return nil
	end

	return data.flags[flag]
end

function QuestService:RunActions(player, questId, stepId, actionList)
	if not actionList then
		return
	end

	Actions.Run(buildActionContext(self, player, questId, stepId), actionList)
end

function QuestService:BuildNewQuestState(questId)
	local def = getQuestDef(questId)
	assert(def, ("Missing quest definition: %s"):format(tostring(questId)))

	local questState = {
		id = questId,
		status = "Active",
		startedAt = now(),
		completedAt = nil,
		failedAt = nil,

		steps = {},
		stepOrder = {},

		metadata = {
			repeatCount = 0,
		},
	}

	for _, stepDef in ipairs(def.steps) do
		questState.steps[stepDef.id] = createRuntimeStep(stepDef)
		table.insert(questState.stepOrder, stepDef.id)
	end

	return questState
end

function QuestService:IsQuestOnRepeatCooldown(player, questId)
	local data = PlayerData[player]
	local def = getQuestDef(questId)
	if not data or not def then
		return false
	end

	if not def.repeatable then
		return false
	end

	local completedData = data.completed[questId]
	if not completedData then
		return false
	end

	local cooldown = def.repeatCooldown or 0
	if cooldown <= 0 then
		return false
	end

	local completedAt = completedData.completedAt or 0
	return now() < (completedAt + cooldown)
end

function QuestService:CanStartQuest(player, questId)
	local data = PlayerData[player]
	local def = getQuestDef(questId)

	if not data or not def then
		return false, "Missing data or quest definition"
	end

	if data.active[questId] then
		return false, "Quest already active"
	end

	if not def.repeatable and data.completed[questId] then
		return false, "Quest already completed"
	end

	if def.repeatable and self:IsQuestOnRepeatCooldown(player, questId) then
		return false, "Quest on cooldown"
	end

	local requires = def.requires or {}

	for _, requiredQuestId in ipairs(requires.completedQuests or {}) do
		if not data.completed[requiredQuestId] then
			return false, ("Missing required quest: %s"):format(requiredQuestId)
		end
	end

	for _, requiredFlag in ipairs(requires.flags or {}) do
		if not data.flags[requiredFlag] then
			return false, ("Missing required flag: %s"):format(requiredFlag)
		end
	end

	return true
end

function QuestService:StartQuest(player, questId)
	local canStart, reason = self:CanStartQuest(player, questId)
	if not canStart then
		return false, reason
	end

	local data = PlayerData[player]
	local questState = self:BuildNewQuestState(questId)

	if data.completed[questId] and getQuestDef(questId).repeatable then
		questState.metadata.repeatCount = (data.completed[questId].repeatCount or 0) + 1
	end

	data.active[questId] = questState

	local def = getQuestDef(questId)
	self:RunActions(player, questId, nil, def.onStart)

	self:RefreshQuest(player, questId)
	self:BroadcastState(player)

	return true
end

function QuestService:AbandonQuest(player, questId)
	local data = PlayerData[player]
	if not data or not data.active[questId] then
		return false
	end

	data.active[questId] = nil
	self:BroadcastState(player)
	return true
end

function QuestService:ForceCompleteQuest(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not def then
		return
	end

	if not questState then
		local ok = self:StartQuest(player, questId)
		if not ok then
			return
		end
		questState = self:GetQuestState(player, questId)
	end

	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		stepState.revealed = true
		stepState.completed = true
		stepState.failed = false
		stepState.progress = stepDef.goal or 1
	end

	self:CompleteQuest(player, questId)
end

function QuestService:FailQuest(player, questId, reason)
	local data = PlayerData[player]
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not data or not questState or not def then
		return
	end

	questState.status = "Failed"
	questState.failedAt = now()
	questState.failReason = reason

	self:RunActions(player, questId, nil, def.onFail)

	data.active[questId] = nil
	self:BroadcastState(player)
end

function QuestService:CompleteQuest(player, questId)
	local data = PlayerData[player]
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not data or not questState or not def then
		return
	end

	questState.status = "Completed"
	questState.completedAt = now()

	data.active[questId] = nil
	data.completed[questId] = {
		completedAt = now(),
		repeatCount = questState.metadata.repeatCount or 0,
	}

	self:RunActions(player, questId, nil, def.rewards)
	self:RunActions(player, questId, nil, def.onComplete)

	self:SendToast(player, {
		text = ("Quest complete: %s"):format(def.title),
		kind = "QuestComplete",
		questId = questId,
	})

	self:BroadcastState(player)
end

function QuestService:AreStepPrerequisitesComplete(player, questId, stepDef)
	local questState = self:GetQuestState(player, questId)
	if not questState then
		return false
	end

	for _, prereqStepId in ipairs(stepDef.prerequisites or {}) do
		local prereqState = questState.steps[prereqStepId]
		if not prereqState or not prereqState.completed then
			return false
		end
	end

	return true
end

function QuestService:EvaluateUnlockWhen(player, questId, unlockWhen)
	if not unlockWhen then
		return true
	end

	local data = PlayerData[player]
	local questState = self:GetQuestState(player, questId)
	if not data or not questState then
		return false
	end

	if unlockWhen.type == "GROUP_ANY" then
		local count = 0
		for _, stepDef in ipairs(getQuestDef(questId).steps) do
			if stepDef.group == unlockWhen.group then
				local stepState = questState.steps[stepDef.id]
				if stepState and stepState.completed then
					count += 1
				end
			end
		end
		return count >= (unlockWhen.count or 1)
	end

	if unlockWhen.type == "ALL_OF_STEPS" then
		for _, stepId in ipairs(unlockWhen.steps or {}) do
			local stepState = questState.steps[stepId]
			if not stepState or not stepState.completed then
				return false
			end
		end
		return true
	end

	if unlockWhen.type == "ANY_FLAG_TRUE" then
		for _, flag in ipairs(unlockWhen.flags or {}) do
			if data.flags[flag] then
				return true
			end
		end
		return false
	end

	if unlockWhen.type == "QUEST_COMPLETED" then
		return data.completed[unlockWhen.questId] ~= nil
	end

	return false
end

function QuestService:IsStepUnlocked(player, questId, stepDef)
	local questState = self:GetQuestState(player, questId)
	if not questState then
		return false
	end

	local stepState = questState.steps[stepDef.id]
	if not stepState or stepState.completed or stepState.failed then
		return false
	end

	if not self:AreStepPrerequisitesComplete(player, questId, stepDef) then
		return false
	end

	if not self:EvaluateUnlockWhen(player, questId, stepDef.unlockWhen) then
		return false
	end

	return true
end

function QuestService:RevealEligibleSteps(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not questState or not def then
		return
	end

	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		if stepState and not stepState.revealed and self:IsStepUnlocked(player, questId, stepDef) then
			stepState.revealed = true
			stepState.lastUpdatedAt = now()
			self:RunActions(player, questId, stepDef.id, stepDef.onReveal)
		end
	end
end

function QuestService:IsQuestComplete(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not questState or not def then
		return false
	end

	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		if not stepState or not stepState.completed then
			return false
		end
	end

	return true
end

function QuestService:RefreshQuest(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not questState or not def then
		return
	end

	self:RevealEligibleSteps(player, questId)
	self:EvaluateConditionSteps(player, questId)
	self:StartEligibleStatefulSteps(player, questId)

	if self:IsQuestComplete(player, questId) then
		self:CompleteQuest(player, questId)
	end
end

function QuestService:AdvanceEventCounterStep(player, questId, stepDef, stepState, amount)
	if stepState.completed or stepState.failed then
		return
	end

	stepState.progress += amount or 1
	stepState.lastUpdatedAt = now()

	local goal = stepDef.goal or 1
	if stepState.progress >= goal then
		stepState.progress = goal
		stepState.completed = true
		self:RunActions(player, questId, stepDef.id, stepDef.onComplete)
		self:SendToast(player, {
			text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
			kind = "ObjectiveComplete",
			questId = questId,
			stepId = stepDef.id,
		})
	end
end

function QuestService:DoesPayloadMatch(payload, matchTable)
	if not matchTable then
		return true
	end
	return QuestUtil.Matches(payload, matchTable)
end

function QuestService:CanConsumeEventForEventCounter(stepDef, stepState, eventName, payload)
	if stepState.completed or stepState.failed or not stepState.revealed then
		return false
	end

	if stepDef.type ~= "EVENT_COUNTER" then
		return false
	end

	if stepDef.event ~= eventName then
		return false
	end

	if not self:DoesPayloadMatch(payload, stepDef.match) then
		return false
	end

	return true
end

function QuestService:HandleSequenceStepEvent(player, questId, stepDef, stepState, eventName, payload)
	if stepState.completed or stepState.failed or not stepState.revealed then
		return
	end

	if stepDef.type ~= "SEQUENCE" then
		return
	end

	local sequence = stepDef.sequence or {}
	local currentIndex = stepState.sequenceIndex or 1
	local currentEntry = sequence[currentIndex]

	if not currentEntry then
		return
	end

	local matchedCurrent = (currentEntry.event == eventName) and self:DoesPayloadMatch(payload, currentEntry.match)

	if matchedCurrent then
		stepState.progress = currentIndex
		stepState.sequenceProgressText = currentEntry.progressText
		stepState.sequenceIndex = currentIndex + 1
		stepState.lastUpdatedAt = now()

		if stepState.sequenceIndex > #sequence then
			stepState.completed = true
			self:RunActions(player, questId, stepDef.id, stepDef.onComplete)
			self:SendToast(player, {
				text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
				kind = "ObjectiveComplete",
				questId = questId,
				stepId = stepDef.id,
			})
		end

		return
	end

	if stepDef.resetOnWrongEvent and stepDef.wrongEventFilter then
		local filter = stepDef.wrongEventFilter
		if filter.event == eventName then
			local shouldReset = false

			if filter.matchAny then
				for _, candidate in ipairs(filter.matchAny) do
					if self:DoesPayloadMatch(payload, candidate) then
						shouldReset = true
						break
					end
				end
			elseif self:DoesPayloadMatch(payload, filter.match) then
				shouldReset = true
			end

			if shouldReset then
				stepState.sequenceIndex = 1
				stepState.progress = 0
				stepState.sequenceProgressText = nil
				stepState.lastUpdatedAt = now()
			end
		end
	end
end

function QuestService:EvaluateConditionDefinition(player, conditionDef)
	if not conditionDef then
		return false
	end

	if type(conditionDef) == "function" then
		local ok, result = pcall(conditionDef, player, self:GetPlayerData(player))
		return ok and result == true
	end

	local data = self:GetPlayerData(player)
	if not data then
		return false
	end

	if conditionDef.kind == "FlagTrue" then
		return data.flags[conditionDef.flag] == true
	end

	if conditionDef.kind == "AnyFlagTrue" then
		for _, flag in ipairs(conditionDef.flags or {}) do
			if data.flags[flag] == true then
				return true
			end
		end
		return false
	end

	if conditionDef.kind == "InventoryHasItem" then
		if self.GetItemCount then
			local count = self:GetItemCount(player, conditionDef.itemId)
			return count >= (conditionDef.amount or 1)
		end
		return false
	end

	if conditionDef.kind == "ReputationAtLeast" then
		if self.GetReputation then
			local rep = self:GetReputation(player, conditionDef.faction)
			return rep >= (conditionDef.amount or 0)
		end
		return false
	end

	if conditionDef.kind == "QuestCompleted" then
		return data.completed[conditionDef.questId] ~= nil
	end

	return false
end

function QuestService:EvaluateConditionSteps(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not questState or not def then
		return
	end

	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		if stepDef.type == "CONDITION" and stepState and stepState.revealed and not stepState.completed and not stepState.failed then
			local met = self:EvaluateConditionDefinition(player, stepDef.condition)
			if met then
				stepState.completed = true
				stepState.progress = 1
				stepState.lastUpdatedAt = now()
				self:RunActions(player, questId, stepDef.id, stepDef.onComplete)
				self:SendToast(player, {
					text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
					kind = "ObjectiveComplete",
					questId = questId,
					stepId = stepDef.id,
				})
			end
		end
	end
end

function QuestService:StartEligibleStatefulSteps(player, questId)
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not questState or not def then
		return
	end

	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		if stepDef.type == "STATEFUL" and stepState and stepState.revealed and not stepState.completed and not stepState.failed then
			local runtime = stepState.stateful
			if runtime and not runtime.started then
				local handlerName = stepDef.stateful and stepDef.stateful.handler
				local handler = handlerName and StatefulHandlers.Get(handlerName)

				runtime.started = true
				runtime.startedAt = now()
				runtime.elapsed = 0

				if handler and handler.start then
					local ok, err = pcall(handler.start, handler, {
						player = player,
						questId = questId,
						stepId = stepDef.id,
						stepDef = stepDef,
						stepState = stepState,
						questService = self,
					})
					if not ok then
						warn("[QuestService] Stateful start error:", questId, stepDef.id, err)
					end
				end
			end
		end
	end
end

function QuestService:UpdateStatefulStep(player, questId, stepDef, stepState, dt)
	local runtime = stepState.stateful
	if not runtime or not runtime.started or stepState.completed or stepState.failed then
		return
	end

	runtime.elapsed += dt
	stepState.lastUpdatedAt = now()

	local handlerName = stepDef.stateful and stepDef.stateful.handler
	local handler = handlerName and StatefulHandlers.Get(handlerName)

	if handler and handler.update then
		local ok, err = pcall(handler.update, handler, {
			player = player,
			questId = questId,
			stepId = stepDef.id,
			stepDef = stepDef,
			stepState = stepState,
			questService = self,
			dt = dt,
		})
		if not ok then
			warn("[QuestService] Stateful update error:", questId, stepDef.id, err)
		end
	end

	if handler and handler.isFailed then
		local ok, failed, failReason = pcall(handler.isFailed, handler, {
			player = player,
			questId = questId,
			stepId = stepDef.id,
			stepDef = stepDef,
			stepState = stepState,
			questService = self,
		})
		if ok and failed then
			self:FailQuest(player, questId, failReason or ("Stateful step failed: " .. stepDef.id))
			return
		end
	end

	if handler and handler.isComplete then
		local ok, complete = pcall(handler.isComplete, handler, {
			player = player,
			questId = questId,
			stepId = stepDef.id,
			stepDef = stepDef,
			stepState = stepState,
			questService = self,
		})
		if ok and complete then
			stepState.completed = true
			stepState.progress = 1
			self:RunActions(player, questId, stepDef.id, stepDef.onComplete)
			self:SendToast(player, {
				text = ("Objective complete: %s"):format(stepDef.title or stepDef.id),
				kind = "ObjectiveComplete",
				questId = questId,
				stepId = stepDef.id,
			})
			return
		end
	end
end

function QuestService:HandleStatefulEvent(player, questId, stepDef, stepState, eventName, payload)
	if stepDef.type ~= "STATEFUL" or not stepState.revealed or stepState.completed or stepState.failed then
		return
	end

	local runtime = stepState.stateful
	if not runtime or not runtime.started then
		return
	end

	local handlerName = stepDef.stateful and stepDef.stateful.handler
	local handler = handlerName and StatefulHandlers.Get(handlerName)

	if handler and handler.onEvent then
		local ok, err = pcall(handler.onEvent, handler, {
			player = player,
			questId = questId,
			stepId = stepDef.id,
			stepDef = stepDef,
			stepState = stepState,
			questService = self,
			eventName = eventName,
			payload = payload,
		})
		if not ok then
			warn("[QuestService] Stateful onEvent error:", questId, stepDef.id, err)
		end
	end
end

function QuestService:EmitEvent(player, eventName, payload)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	for questId, questState in safePairs(data.active) do
		local def = getQuestDef(questId)
		if def and questState.status == "Active" then
			for _, stepDef in ipairs(def.steps) do
				local stepState = questState.steps[stepDef.id]
				if stepState and stepState.revealed and not stepState.completed and not stepState.failed then
					if self:CanConsumeEventForEventCounter(stepDef, stepState, eventName, payload) then
						self:AdvanceEventCounterStep(player, questId, stepDef, stepState, payload and payload.amount or 1)
					end

					if stepDef.type == "SEQUENCE" then
						self:HandleSequenceStepEvent(player, questId, stepDef, stepState, eventName, payload)
					end

					if stepDef.type == "STATEFUL" then
						self:HandleStatefulEvent(player, questId, stepDef, stepState, eventName, payload)
					end
				end
			end

			self:RefreshQuest(player, questId)
		end
	end

	self:BroadcastState(player)
end

function QuestService:Tick(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local data = self:GetPlayerData(player)
		if data then
			local activeQuestIds = {}
			for questId in safePairs(data.active) do
				table.insert(activeQuestIds, questId)
			end

			for _, questId in ipairs(activeQuestIds) do
				local questState = self:GetQuestState(player, questId)
				local def = getQuestDef(questId)

				if questState and def and questState.status == "Active" then
					self:StartEligibleStatefulSteps(player, questId)

					for _, stepDef in ipairs(def.steps) do
						local stepState = questState.steps[stepDef.id]
						if stepDef.type == "STATEFUL" and stepState and stepState.revealed and not stepState.completed and not stepState.failed then
							self:UpdateStatefulStep(player, questId, stepDef, stepState, dt)
						end
					end

					self:EvaluateConditionSteps(player, questId)
					self:RevealEligibleSteps(player, questId)

					if self:IsQuestComplete(player, questId) then
						self:CompleteQuest(player, questId)
					end
				end
			end
		end
	end
end

function QuestService:GetQuestSnapshot(player)
	return self:GetPlayerData(player)
end

function QuestService:LoadPlayer(player)
	local data = Persistence.Load(player) or {}

	data.active = data.active or {}
	data.completed = data.completed or {}
	data.flags = data.flags or {}

	PlayerData[player] = data

	for questId, def in pairs(ExpandedQuestDefs) do
		if def.autoStart then
			self:StartQuest(player, questId)
		end
	end

	for questId in safePairs(data.active) do
		self:RefreshQuest(player, questId)
	end

	self:BroadcastState(player)
end

function QuestService:SavePlayer(player)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	Persistence.Save(player, data)
end

function QuestService:GetItemCount(player, itemId)
	-- Override or replace this with your inventory system
	return 0
end

function QuestService:GetReputation(player, faction)
	-- Override or replace this with your reputation system
	return 0
end

function QuestService:Init()
	QuestRemotes.Init()
	QuestStateChanged = QuestRemotes.GetRemoteEvent("QuestStateChanged")
	QuestToast = QuestRemotes.GetRemoteEvent("QuestToast")

	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:SavePlayer(player)
		PlayerData[player] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		self:Tick(dt)
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:SavePlayer(player)
		end
	end)
end

return setmetatable({}, QuestService)