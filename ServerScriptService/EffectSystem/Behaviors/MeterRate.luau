local ServerScriptService = game:GetService("ServerScriptService")

local PlayerMeterService = require(
	ServerScriptService:WaitForChild("PlayerMeterSystem"):WaitForChild("PlayerMeterService")
)

local MeterRate = {}

function MeterRate.OnApply(context, behavior)
	PlayerMeterService.Init()
	local sourceKey = string.format("Effect:%s:%d", context.EffectName, context.BehaviorIndex)
	PlayerMeterService.SetRateSource(
		context.Player,
		behavior.Meter,
		sourceKey,
		(behavior.RatePerSecond or 0) * context.SourceLevel
	)

	if behavior.AmountOnApply and behavior.AmountOnApply ~= 0 then
		PlayerMeterService.Add(
			context.Player,
			behavior.Meter,
			behavior.AmountOnApply * context.SourceLevel
		)
	end

	return {
		Meter = behavior.Meter,
		SourceKey = sourceKey,
	}
end

function MeterRate.OnRemove(context, _behavior, state)
	if state then
		PlayerMeterService.RemoveRateSource(context.Player, state.Meter, state.SourceKey)
	end
end

return MeterRate
