-- Read-only policy/query surface for systems that consume active effects.
-- Effect application remains owned by DataEffectsFunctions.
local EffectQueryService = {}

local activeByPlayer = setmetatable({}, { __mode = "k" })

local function getPlayerEffects(player, create)
	local effects = activeByPlayer[player]
	if not effects and create then
		effects = {}
		activeByPlayer[player] = effects
	end
	return effects
end

local function actionMatches(behavior, actionName: string): boolean
	if behavior.Action == actionName then
		return true
	end
	for _, candidate in ipairs(behavior.Actions or {}) do
		if candidate == actionName then
			return true
		end
	end
	return false
end

function EffectQueryService.TrackEffect(player, effectName, runtimeEffect, definition)
	getPlayerEffects(player, true)[effectName] = {
		RuntimeEffect = runtimeEffect,
		Definition = definition,
	}
end

function EffectQueryService.UntrackEffect(player, effectName, runtimeEffect)
	local effects = getPlayerEffects(player, false)
	local active = effects and effects[effectName]
	if active and active.RuntimeEffect == runtimeEffect then
		effects[effectName] = nil
	end
end

function EffectQueryService.ClearPlayer(player)
	activeByPlayer[player] = nil
end

function EffectQueryService.HasEffect(player, effectName: string): boolean
	local effects = getPlayerEffects(player, false)
	return effects ~= nil and effects[effectName] ~= nil
end

function EffectQueryService.HasBehavior(player, behaviorType: string, actionName: string?): boolean
	local effects = getPlayerEffects(player, false)
	for _, active in pairs(effects or {}) do
		for _, behavior in ipairs(active.Definition.Behaviors or {}) do
			if behavior.Type == behaviorType
				and (actionName == nil or actionMatches(behavior, actionName))
			then
				return true
			end
		end
	end
	return false
end

function EffectQueryService.CanPerform(player, actionName: string)
	local effects = getPlayerEffects(player, false)
	for effectName, active in pairs(effects or {}) do
		for _, behavior in ipairs(active.Definition.Behaviors or {}) do
			if behavior.Type == "Restriction" and actionMatches(behavior, actionName) then
				return false,
					behavior.Message or "You cannot do that while this effect is active.",
					effectName
			end
		end
	end
	return true
end

return EffectQueryService
