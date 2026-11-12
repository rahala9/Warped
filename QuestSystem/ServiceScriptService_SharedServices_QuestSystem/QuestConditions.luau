local Players = game:GetService("Players")

local Conditions = {}
Conditions.ById = {}

local function register(id, fn)
	Conditions.ById[id] = fn
end

function Conditions.Evaluate(predicateId, context, args)
	local fn = Conditions.ById[predicateId]
	if not fn then
		warn("[QuestConditions] Missing predicate:", predicateId)
		return false
	end

	local ok, result = pcall(fn, context, args or {})
	if not ok then
		warn("[QuestConditions] Predicate error:", predicateId, result)
		return false
	end

	return result == true
end

register("HasQuestFlag", function(context, args)
	local value = context.questService:GetFlag(context.player, args.flag)
	if args.equals ~= nil then
		return value == args.equals
	end
	return value == true
end)

register("IsInZone", function(context, args)
	local zoneService = context.services and context.services.ZoneService
	if not zoneService or not zoneService.IsPlayerInZone then
		return false
	end
	return zoneService:IsPlayerInZone(context.player, args.zoneId)
end)

register("HasItemCount", function(context, args)
	local inventoryService = context.services and context.services.InventoryService
	if not inventoryService or not inventoryService.GetItemCount then
		return false
	end

	local count = inventoryService:GetItemCount(context.player, args.itemId)
	return count >= (args.amount or 1)
end)

register("ActorAlive", function(context, args)
	local actor = context.questService:GetSpawnedActor(context.player, args.actorKey)
	return actor ~= nil and actor.Parent ~= nil
end)

register("AlwaysTrue", function()
	return true
end)

return Conditions