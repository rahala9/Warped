--[[
	DialogConditions
	Evaluates conditions that control which dialog roots and options are shown.

	Reuses the same context pattern as QuestConditions. Register new condition
	kinds here for dialog-specific checks.

	context contains:
		context.player       = Player instance
		context.questService = QuestService (for quest state, flags, items, rep)
]]

local DialogConditions = {}
DialogConditions._registry = {}

function DialogConditions.Register(kind, fn)
	DialogConditions._registry[kind] = fn
end

--- Evaluate a single condition: { kind = "...", ... }
function DialogConditions.Evaluate(context, conditionDef)
	if not conditionDef then
		return true
	end

	local kind = conditionDef.kind
	if not kind then
		warn("[DialogConditions] Condition missing 'kind' field")
		return false
	end

	local fn = DialogConditions._registry[kind]
	if not fn then
		warn("[DialogConditions] Unknown condition kind:", kind)
		return false
	end

	local ok, result = pcall(fn, context, conditionDef)
	if not ok then
		warn("[DialogConditions] Error evaluating", kind, ":", result)
		return false
	end

	return result == true
end

--- Evaluate an array of conditions (all must pass)
function DialogConditions.EvaluateAll(context, conditions)
	if not conditions or #conditions == 0 then
		return true
	end

	for _, cond in ipairs(conditions) do
		if not DialogConditions.Evaluate(context, cond) then
			return false
		end
	end

	return true
end

------------------------------------------------------------------------
-- Built-in conditions
------------------------------------------------------------------------

DialogConditions.Register("HasQuestActive", function(context, args)
	local qs = context.questService
	local state = qs:GetQuestState(context.player, args.questId)
	return state ~= nil and state.status == "Active"
end)

DialogConditions.Register("HasQuestCompleted", function(context, args)
	local qs = context.questService
	local data = qs:GetCompletedQuestData(context.player, args.questId)
	return data ~= nil
end)

DialogConditions.Register("HasQuestNotStarted", function(context, args)
	local qs = context.questService
	local active = qs:GetQuestState(context.player, args.questId)
	local completed = qs:GetCompletedQuestData(context.player, args.questId)
	return active == nil and completed == nil
end)

DialogConditions.Register("FlagTrue", function(context, args)
	return context.questService:GetFlag(context.player, args.flag) == true
end)

DialogConditions.Register("FlagFalse", function(context, args)
	return context.questService:GetFlag(context.player, args.flag) ~= true
end)

DialogConditions.Register("AnyFlagTrue", function(context, args)
	for _, flag in ipairs(args.flags or {}) do
		if context.questService:GetFlag(context.player, flag) == true then
			return true
		end
	end
	return false
end)

DialogConditions.Register("HasItem", function(context, args)
	local count = context.questService:GetItemCount(context.player, args.itemId)
	return count >= (args.amount or 1)
end)

DialogConditions.Register("ReputationAtLeast", function(context, args)
	local rep = context.questService:GetReputation(context.player, args.faction)
	return rep >= (args.amount or 0)
end)

DialogConditions.Register("ReputationLessThan", function(context, args)
	local rep = context.questService:GetReputation(context.player, args.faction)
	return rep < (args.amount or 0)
end)

DialogConditions.Register("QuestStepCompleted", function(context, args)
	local qs = context.questService
	local questState = qs:GetQuestState(context.player, args.questId)
	if not questState then return false end
	local stepState = questState.steps[args.stepId]
	return stepState and stepState.completed == true
end)

return DialogConditions
