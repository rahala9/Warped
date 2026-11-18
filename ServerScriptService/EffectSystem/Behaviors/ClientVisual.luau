local ServerScriptService = game:GetService("ServerScriptService")

local EffectVisualService = require(
	ServerScriptService:WaitForChild("EffectVisualSystem"):WaitForChild("EffectVisualService")
)

local ClientVisual = {}

function ClientVisual.OnApply(context, behavior)
	EffectVisualService.Start(context.Player, behavior.EffectName or context.EffectName, {
		Source = context.RuntimeEffect.Effect.Source,
		SourceLevel = context.SourceLevel,
	})
	return behavior.EffectName or context.EffectName
end

function ClientVisual.OnRemove(context, _behavior, visualName)
	EffectVisualService.Stop(context.Player, visualName or context.EffectName)
end

return ClientVisual
