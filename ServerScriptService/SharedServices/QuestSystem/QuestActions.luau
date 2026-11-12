--[[
	QuestActions
	Registry of side-effect actions triggered by quest lifecycle events
	(onStart, onComplete, onFail, onReveal, rewards, step.onComplete).

	Each action receives (context, actionDef) where:
		context.player       = Player instance
		context.questId      = current quest id
		context.stepId       = current step id (nil for quest-level actions)
		context.questService = QuestService instance

	To add a new action:
		QuestActions.Register("MyAction", function(context, action)
			-- do stuff
		end)

	Then use it in a quest definition:
		onComplete = {
			{ type = "MyAction", someParam = "value" },
		}
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local QuestActions = {}
QuestActions._registry = {}

--- Per-player spawned actor tracking
local SpawnedActors = {} -- [Player] = { [actorKey] = Instance }

local function getActorBucket(player)
	local bucket = SpawnedActors[player]
	if not bucket then
		bucket = {}
		SpawnedActors[player] = bucket
	end
	return bucket
end

function QuestActions.Register(actionType, fn)
	QuestActions._registry[actionType] = fn
end

function QuestActions.Run(context, actionList)
	if not actionList then
		return
	end

	for _, action in ipairs(actionList) do
		local fn = QuestActions._registry[action.type]
		if not fn then
			warn("[QuestActions] Unknown action type:", action.type)
		else
			local ok, err = pcall(fn, context, action)
			if not ok then
				warn("[QuestActions] Error in action", action.type, ":", err)
			end
		end
	end
end

function QuestActions.GetSpawnedActor(player, actorKey)
	local bucket = SpawnedActors[player]
	return bucket and bucket[actorKey] or nil
end

------------------------------------------------------------------------
-- Built-in actions
------------------------------------------------------------------------

QuestActions.Register("SpawnActor", function(context, action)
	local folder = ServerStorage:FindFirstChild("QuestActors")
	if not folder then
		warn("[QuestActions] Missing ServerStorage.QuestActors folder")
		return
	end

	local template = folder:FindFirstChild(action.actorTemplate)
	if not template then
		warn("[QuestActions] Missing actor template:", action.actorTemplate)
		return
	end

	local actor = template:Clone()
	actor.Name = action.actorName or template.Name

	local parent = Workspace:FindFirstChild(action.parentName or "") or Workspace
	actor.Parent = parent

	if actor:IsA("Model") then
		local pivot = action.cframe or CFrame.new(action.position or Vector3.zero)
		actor:PivotTo(pivot)
	elseif actor:IsA("BasePart") then
		actor.CFrame = action.cframe or CFrame.new(action.position or Vector3.zero)
	end

	local bucket = getActorBucket(context.player)
	bucket[action.actorKey or actor.Name] = actor
end)

QuestActions.Register("DestroyActor", function(context, action)
	local bucket = getActorBucket(context.player)
	local actor = bucket[action.actorKey]
	if actor then
		if actor.Parent then
			actor:Destroy()
		end
		bucket[action.actorKey] = nil
	end
end)

QuestActions.Register("Toast", function(context, action)
	context.questService:SendToast(context.player, {
		text = action.text or "",
		kind = action.kind or "Info",
	})
end)

QuestActions.Register("EmitSignal", function(context, action)
	context.questService:EmitEvent(context.player, "QuestSignal", {
		signal = action.signal,
		questId = context.questId,
		stepId = context.stepId,
	})
end)

QuestActions.Register("SetQuestFlag", function(context, action)
	context.questService:SetFlag(context.player, action.flag, action.value ~= false)
end)

QuestActions.Register("StartQuest", function(context, action)
	context.questService:StartQuest(context.player, action.questId)
end)

QuestActions.Register("CompleteQuest", function(context, action)
	context.questService:ForceCompleteQuest(context.player, action.questId)
end)

QuestActions.Register("GiveReward", function(context, action)
	-- HOOK: Replace this with your actual reward system
	print(("[QuestReward] %s -> %s x%s"):format(
		context.player.Name,
		tostring(action.rewardId),
		tostring(action.amount or 1)
		))
end)

QuestActions.Register("CallServiceMethod", function(context, action)
	local qs = context.questService
	local services = qs.Services or {}
	local service = services[action.serviceName]
	if not service then
		warn("[QuestActions] Missing service:", action.serviceName)
		return
	end

	local method = service[action.method]
	if type(method) ~= "function" then
		warn("[QuestActions] Missing method:", action.serviceName, ".", action.method)
		return
	end

	method(service, context.player, action.args)
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	local bucket = SpawnedActors[player]
	if bucket then
		for _, actor in pairs(bucket) do
			if actor and actor.Parent then
				actor:Destroy()
			end
		end
	end
	SpawnedActors[player] = nil
end)

return QuestActions
