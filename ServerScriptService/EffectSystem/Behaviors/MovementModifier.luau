local ServerScriptService = game:GetService("ServerScriptService")
local MovementModifierService = require(
	ServerScriptService:WaitForChild("EffectSystem"):WaitForChild("MovementModifierService")
)

local MovementModifier = {}

function MovementModifier.OnApply(context, behavior)
	local sourceKey = string.format("Effect:%s:%d", context.EffectName, context.BehaviorIndex)
	local scale = behavior.ScaleWithSourceLevel == false and 1 or context.SourceLevel
	MovementModifierService.Add(context.Player, sourceKey, {
		Operation = behavior.Operation,
		Value = (behavior.Value or 0) * scale,
	})
	return sourceKey
end

function MovementModifier.OnRemove(context, _behavior, sourceKey)
	if sourceKey then MovementModifierService.Remove(context.Player, sourceKey) end
end

return MovementModifier
