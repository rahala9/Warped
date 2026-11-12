--[[
	QuestService
	Server-side quest orchestrator. This is the main entry point.

	Responsibilities:
		- Manages per-player quest state (active, completed, flags)
		- Expands quest definitions via templates at startup
		- Routes events to the correct step handlers
		- Manages step prerequisites, unlockWhen gates, and hidden reveals
		- Drives the Heartbeat tick loop for stateful/condition steps
		- Handles quest lifecycle (start, complete, fail, abandon)
		- Broadcasts state to clients

	This module does NOT contain step-type-specific logic.
	All step behavior is delegated to QuestStepHandlers.
	All condition evaluation is delegated to QuestConditions.
	All side effects are delegated to QuestActions.

	Usage:
		local QuestService = require(path.to.QuestService)
		QuestService:Init()

		-- From your game systems, emit events:
		QuestService:EmitEvent(player, "EnemyKilled", { enemyType = "NightCrawler" })
		QuestService:EmitEvent(player, "NpcTalked", { npcId = "Scout01" })

		-- Wire external systems:
		QuestService.GetItemCount = function(self, player, itemId) ... end
		QuestService.GetReputation = function(self, player, faction) ... end

		-- Expose additional services for conditions/actions:
		QuestService.Services = { ZoneService = myZoneService, ... }
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local QuestUtil = require(ReplicatedStorage.SharedModules.Quests.QuestUtil)
local QuestRemotes = require(ReplicatedStorage.SharedModules.Quests.QuestRemotes)

local Definitions = require(script.Parent.QuestDefinitions)
local Templates = require(script.Parent.QuestTemplates)
local Actions = require(script.Parent.QuestActions)
local StepHandlers = require(script.Parent.QuestStepHandlers)
local Conditions = require(script.Parent.QuestConditions)

-- ProfileService cached profiles
local Data = require(ServerScriptService:WaitForChild("Data"):WaitForChild("Data"))

local QuestService = {}
QuestService.__index = QuestService

--- External service references. Set these after Init to wire up
--- inventory, reputation, zone checks, etc.
QuestService.Services = {}

------------------------------------------------------------------------
-- Internal state
------------------------------------------------------------------------
local PlayerData = {}        -- [Player] = { active, completed, flags }
local ExpandedQuestDefs = {} -- [questId] = expanded definition

local QuestStateChanged      -- RemoteEvent
local QuestToast             -- RemoteEvent
local GetQuestSnapshotRF     -- RemoteFunction

local CONDITION_TICK_INTERVAL = 0.5 -- seconds between condition re-evaluations

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function deepCopy(value)
	return QuestUtil.DeepCopy(value)
end

local function getQuestDef(questId)
	return ExpandedQuestDefs[questId]
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
	assert(finalStep.type, ("Quest step '%s' missing type"):format(tostring(finalStep.id)))

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

-- Expand all definitions at module load time
for questId, def in pairs(Definitions.Quests or {}) do
	ExpandedQuestDefs[questId] = expandQuestDef(def)
end

------------------------------------------------------------------------
-- Runtime step state factory
------------------------------------------------------------------------

local function createRuntimeStep(stepDef)
	local stepState = {
		id = stepDef.id,
		type = stepDef.type,
		revealed = not stepDef.hidden,
		completed = false,
		failed = false,

		-- Display fields — so the client can render without needing definitions
		title = stepDef.title or stepDef.id,
		description = stepDef.description,
		goal = stepDef.goal or 1,
		group = stepDef.group,
		prerequisites = stepDef.prerequisites or {},

		progress = 0,
		lastUpdatedAt = QuestUtil.Now(),

		-- SEQUENCE fields
		sequenceIndex = 1,
		sequenceProgressText = nil,

		-- STATEFUL fields (populated by handler Init)
		stateful = nil,
	}

	return stepState
end

------------------------------------------------------------------------
-- Context builder
------------------------------------------------------------------------

local function buildActionContext(questService, player, questId, stepId)
	return {
		player = player,
		questId = questId,
		stepId = stepId,
		questService = questService,
		services = questService.Services,
	}
end

local function buildStepContext(questService, player, questId, stepDef, stepState)
	return {
		player = player,
		questId = questId,
		stepId = stepDef.id,
		stepDef = stepDef,
		stepState = stepState,
		questService = questService,
		services = questService.Services,
	}
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

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

--- Stub: override with your inventory system
function QuestService:GetItemCount(_player, _itemId)
	return 0
end

--- Stub: override with your reputation system
function QuestService:GetReputation(_player, _faction)
	return 0
end

------------------------------------------------------------------------
-- Quest lifecycle
------------------------------------------------------------------------

function QuestService:BuildNewQuestState(questId)
	local def = getQuestDef(questId)
	assert(def, ("Missing quest definition: %s"):format(tostring(questId)))

	local questState = {
		id = questId,
		status = "Active",
		startedAt = QuestUtil.Now(),
		completedAt = nil,
		failedAt = nil,

		-- Display fields — so the client can render without needing definitions
		title = def.title or questId,
		description = def.description,
		category = def.category,

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
	if not data or not def or not def.repeatable then
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
	return QuestUtil.Now() < (completedAt + cooldown)
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

	-- Initialize all step handlers
	local def = getQuestDef(questId)
	for _, stepDef in ipairs(def.steps) do
		local stepState = questState.steps[stepDef.id]
		local handler = StepHandlers.Get(stepDef.type)
		if handler and handler.Init then
			local ctx = buildStepContext(self, player, questId, stepDef, stepState)
			local ok, err = pcall(handler.Init, handler, ctx)
			if not ok then
				warn("[QuestService] Step Init error:", questId, stepDef.id, err)
			end
		end
	end

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

function QuestService:FailQuest(player, questId, reason)
	local data = PlayerData[player]
	local questState = self:GetQuestState(player, questId)
	local def = getQuestDef(questId)

	if not data or not questState or not def then
		return
	end

	questState.status = "Failed"
	questState.failedAt = QuestUtil.Now()
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
	questState.completedAt = QuestUtil.Now()

	data.active[questId] = nil
	data.completed[questId] = {
		completedAt = QuestUtil.Now(),
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

------------------------------------------------------------------------
-- Step prerequisite and unlock evaluation
------------------------------------------------------------------------

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

	warn("[QuestService] Unknown unlockWhen type:", unlockWhen.type)
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

------------------------------------------------------------------------
-- Reveal / refresh / completion check
------------------------------------------------------------------------

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
			stepState.lastUpdatedAt = QuestUtil.Now()
			self:RunActions(player, questId, stepDef.id, stepDef.onReveal)
		end
	end
end

function QuestService:IsQuestComplete(_player, questId)
	local questState = self:GetQuestState(_player, questId)
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
	if not questState then
		return
	end

	self:RevealEligibleSteps(player, questId)

	if self:IsQuestComplete(player, questId) then
		self:CompleteQuest(player, questId)
	end
end

------------------------------------------------------------------------
-- Event routing — the core pipeline
------------------------------------------------------------------------

function QuestService:EmitEvent(player, eventName, payload)
	local data = self:GetPlayerData(player)
	if not data then
		return
	end

	-- Snapshot active quest IDs to avoid mutation-during-iteration.
	-- CompleteQuest/FailQuest nil out data.active[questId], and onComplete
	-- actions can start new quests that add to data.active.
	local activeIds = QuestUtil.SnapshotKeys(data.active)

	for _, questId in ipairs(activeIds) do
		local questState = data.active[questId]
		local def = getQuestDef(questId)

		if questState and def and questState.status == "Active" then
			for _, stepDef in ipairs(def.steps) do
				local stepState = questState.steps[stepDef.id]
				if stepState and stepState.revealed and not stepState.completed and not stepState.failed then
					local handler = StepHandlers.Get(stepDef.type)
					if handler and handler.OnEvent then
						local ctx = buildStepContext(self, player, questId, stepDef, stepState)
						local ok, err = pcall(handler.OnEvent, handler, ctx, eventName, payload)
						if not ok then
							warn("[QuestService] OnEvent error:", questId, stepDef.id, err)
						end
					end
				end
			end

			-- After processing events, check for reveals and completion
			if data.active[questId] then -- quest may have been failed by a handler
				self:RefreshQuest(player, questId)
			end
		end
	end

	self:BroadcastState(player)
end

------------------------------------------------------------------------
-- Tick loop
------------------------------------------------------------------------

function QuestService:Tick(dt)
	for _, player in ipairs(Players:GetPlayers()) do
		local data = self:GetPlayerData(player)
		if data then
			local activeIds = QuestUtil.SnapshotKeys(data.active)

			for _, questId in ipairs(activeIds) do
				local questState = data.active[questId]
				local def = getQuestDef(questId)

				if questState and def and questState.status == "Active" then
					-- Update all revealed, incomplete steps via their handlers
					for _, stepDef in ipairs(def.steps) do
						local stepState = questState.steps[stepDef.id]
						if stepState and stepState.revealed and not stepState.completed and not stepState.failed then
							local handler = StepHandlers.Get(stepDef.type)
							if handler and handler.Update then
								local ctx = buildStepContext(self, player, questId, stepDef, stepState)
								local ok, err = pcall(handler.Update, handler, ctx, dt)
								if not ok then
									warn("[QuestService] Update error:", questId, stepDef.id, err)
								end
							end
						end
					end

					-- Refresh after updates (reveals + completion check)
					if data.active[questId] then
						self:RefreshQuest(player, questId)
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Player lifecycle
------------------------------------------------------------------------

function QuestService:LoadPlayer(player)
	local profile = Data[player]
	if not profile then
		warn("[QuestService] No profile found for", player.Name, "— skipping quest load")
		return
	end

	-- Read directly from the profile's Data table.
	-- ProfileService auto-saves, so mutations to these tables persist automatically.
	local profileData = profile.Data
	profileData.QuestActive = profileData.QuestActive or {}
	profileData.QuestCompleted = profileData.QuestCompleted or {}
	profileData.QuestFlags = profileData.QuestFlags or {}

	PlayerData[player] = {
		active = profileData.QuestActive,
		completed = profileData.QuestCompleted,
		flags = profileData.QuestFlags,
	}

	-- Reconcile saved quest states against current definitions.
	-- Patches in any fields that were added since the quest was first started,
	-- removes steps that no longer exist, and adds new steps from the definition.
	for questId, questState in QuestUtil.SafePairs(PlayerData[player].active) do
		local def = getQuestDef(questId)
		if not def then
			-- Quest definition was removed — drop it
			warn("[QuestService] Removing orphaned quest:", questId)
			PlayerData[player].active[questId] = nil
			continue
		end

		-- Reconcile quest-level display fields
		questState.title = def.title or questId
		questState.description = def.description
		questState.category = def.category

		-- Build a set of current definition step IDs
		local defStepIds = {}
		for _, stepDef in ipairs(def.steps) do
			defStepIds[stepDef.id] = true
		end

		-- Remove saved steps that no longer exist in the definition
		for stepId in pairs(questState.steps) do
			if not defStepIds[stepId] then
				questState.steps[stepId] = nil
			end
		end

		-- Rebuild stepOrder from current definition order
		questState.stepOrder = {}
		for _, stepDef in ipairs(def.steps) do
			table.insert(questState.stepOrder, stepDef.id)
		end

		-- Reconcile each step
		for _, stepDef in ipairs(def.steps) do
			local stepState = questState.steps[stepDef.id]
			if not stepState then
				-- New step added to definition — create fresh state
				questState.steps[stepDef.id] = createRuntimeStep(stepDef)
			else
				-- Patch display fields from current definition
				stepState.title = stepDef.title or stepDef.id
				stepState.description = stepDef.description
				stepState.goal = stepDef.goal or 1
				stepState.group = stepDef.group
				stepState.prerequisites = stepDef.prerequisites or {}
				stepState.type = stepDef.type

				-- If definition changed a step to hidden and it hasn't been
				-- completed yet, hide it again. RevealEligibleSteps will
				-- re-reveal it when its unlockWhen conditions are met.
				if stepDef.hidden and not stepState.completed then
					stepState.revealed = false
				end
			end
		end
	end

	-- Auto-start any quests flagged for it
	for questId, def in pairs(ExpandedQuestDefs) do
		if def.autoStart then
			self:StartQuest(player, questId)
		end
	end

	-- Refresh any quests that were active when the player last saved
	for questId in QuestUtil.SafePairs(PlayerData[player].active) do
		self:RefreshQuest(player, questId)
	end

	self:BroadcastState(player)
end

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function QuestService:Init()
	QuestRemotes.Init()
	QuestStateChanged = QuestRemotes.GetRemoteEvent("QuestStateChanged")
	QuestToast = QuestRemotes.GetRemoteEvent("QuestToast")
	GetQuestSnapshotRF = QuestRemotes.GetRemoteFunction("GetQuestSnapshot")

	-- Client can request full state on demand (handles late joins, reconnects)
	GetQuestSnapshotRF.OnServerInvoke = function(player)
		return self:GetPlayerData(player)
	end

	-- Wait for ProfileService to finish loading before initializing quests.
	-- ProfileLoaded fires after LoadProfileAsync + Reconcile completes.
	local ProfileLoadedEvent = game.ServerStorage
		:WaitForChild("SharedServerEvents")
		:WaitForChild("ProfileLoaded")

	ProfileLoadedEvent.Event:Connect(function(player)
		self:LoadPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- No save needed — ProfileService auto-saves and handles release.
		-- Just clean up our in-memory reference.
		PlayerData[player] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		self:Tick(dt)
	end)
end

return setmetatable({}, QuestService)
