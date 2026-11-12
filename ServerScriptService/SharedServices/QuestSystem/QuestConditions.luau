--[[
	QuestConditions
	Registry of predicate functions used by CONDITION steps and unlockWhen gates.
	
	Each condition receives (context, args) where:
		context.player       = the Player instance
		context.questService = the QuestService (for flags, player data, etc.)
		context.questId      = current quest id
		context.stepId       = current step id (may be nil for quest-level checks)
	
	To add a new condition:
		QuestConditions.Register("MyCondition", function(context, args)
			return someBooleanCheck
		end)
	
	Then reference it in a quest definition:
		condition = { kind = "MyCondition", someParam = 42 }
]]

local QuestConditions = {}
QuestConditions._registry = {}

function QuestConditions.Register(kind, fn)
	QuestConditions._registry[kind] = fn
end

--- Evaluate a condition definition table: { kind = "...", ...args }
--- Returns true/false. Never errors — bad predicates return false + warn.
function QuestConditions.Evaluate(context, conditionDef)
	if not conditionDef then
		return false
	end

	-- Support raw functions for quick prototyping
	if type(conditionDef) == "function" then
		local ok, result = pcall(conditionDef, context)
		return ok and result == true
	end

	local kind = conditionDef.kind
	if not kind then
		warn("[QuestConditions] Condition missing 'kind' field")
		return false
	end

	local fn = QuestConditions._registry[kind]
	if not fn then
		warn("[QuestConditions] Unknown condition kind:", kind)
		return false
	end

	local ok, result = pcall(fn, context, conditionDef)
	if not ok then
		warn("[QuestConditions] Error evaluating", kind, ":", result)
		return false
	end

	return result == true
end

------------------------------------------------------------------------
-- Built-in conditions
------------------------------------------------------------------------

QuestConditions.Register("FlagTrue", function(context, args)
	return context.questService:GetFlag(context.player, args.flag) == true
end)

QuestConditions.Register("AnyFlagTrue", function(context, args)
	for _, flag in ipairs(args.flags or {}) do
		if context.questService:GetFlag(context.player, flag) == true then
			return true
		end
	end
	return false
end)

QuestConditions.Register("AllFlagsTrue", function(context, args)
	for _, flag in ipairs(args.flags or {}) do
		if context.questService:GetFlag(context.player, flag) ~= true then
			return false
		end
	end
	return true
end)

QuestConditions.Register("InventoryHasItem", function(context, args)
	local count = context.questService:GetItemCount(context.player, args.itemId)
	return count >= (args.amount or 1)
end)

QuestConditions.Register("ReputationAtLeast", function(context, args)
	local rep = context.questService:GetReputation(context.player, args.faction)
	return rep >= (args.amount or 0)
end)

QuestConditions.Register("QuestCompleted", function(context, args)
	local data = context.questService:GetPlayerData(context.player)
	return data and data.completed[args.questId] ~= nil
end)

QuestConditions.Register("AlwaysTrue", function()
	return true
end)

return QuestConditions
