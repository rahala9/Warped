local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Actions = {}
Actions.ById = {}

local SpawnedActorsByPlayer = {}

local function getBucket(player)
	local bucket = SpawnedActorsByPlayer[player]
	if not bucket then
		bucket = {}
		SpawnedActorsByPlayer[player] = bucket
	end
	return bucket
end

function Actions.Register(actionId, fn)
	Actions.ById[actionId] = fn
end

function Actions.Run(context, actionList)
	for _, action in ipairs(actionList or {}) do
		local fn = Actions.ById[action.type]
		if not fn then
			warn("[QuestActions] Missing action:", action.type)
		else
			local ok, err = pcall(fn, context, action)
			if not ok then
				warn("[QuestActions] Action failed:", action.type, err)
			end
		end
	end
end

function Actions.GetSpawnedActor(player, actorKey)
	local bucket = SpawnedActorsByPlayer[player]
	return bucket and bucket[actorKey] or nil
end

Actions.Register("SpawnActor", function(context, action)
	local folder = ServerStorage:FindFirstChild("QuestActors")
	if not folder then
		warn("[QuestActions] Missing ServerStorage.QuestActors")
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

	local bucket = getBucket(context.player)
	bucket[action.actorKey or actor.Name] = actor
end)

Actions.Register("DestroyActor", function(context, action)
	local bucket = getBucket(context.player)
	local actor = bucket[action.actorKey]
	if actor then
		if actor.Parent then
			actor:Destroy()
		end
		bucket[action.actorKey] = nil
	end
end)

Actions.Register("Toast", function(context, action)
	context.questService:SendToast(context.player, {
		text = action.text or "",
		kind = action.kind or "Info",
	})
end)

Actions.Register("EmitSignal", function(context, action)
	context.questService:EmitEvent(context.player, "QuestSignal", {
		signal = action.signal,
		questId = context.questId,
		stepId = context.stepId,
	})
end)

Actions.Register("SetQuestFlag", function(context, action)
	context.questService:SetFlag(context.player, action.flag, action.value ~= false)
end)

Actions.Register("StartQuest", function(context, action)
	context.questService:StartQuest(context.player, action.questId)
end)

Actions.Register("CompleteQuest", function(context, action)
	context.questService:ForceCompleteQuest(context.player, action.questId)
end)

Actions.Register("GiveReward", function(context, action)
	-- Hook your own currency / inventory / XP system here
	print(("[QuestReward] %s -> %s x%s"):format(
		context.player.Name,
		tostring(action.rewardId),
		tostring(action.amount or 1)
		))
end)

Actions.Register("CallServiceMethod", function(context, action)
	local services = context.services or {}
	local service = services[action.serviceName]
	if not service then
		warn("[QuestActions] Missing service:", action.serviceName)
		return
	end

	local method = service[action.method]
	if type(method) ~= "function" then
		warn("[QuestActions] Missing service method:", action.serviceName, action.method)
		return
	end

	method(service, context.player, action.args)
end)

game.Players.PlayerRemoving:Connect(function(player)
	SpawnedActorsByPlayer[player] = nil
end)

return Actions