local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerHitEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")
local DeathEffectConfig = require(
	ReplicatedStorage:WaitForChild("DeathEffectSystem"):WaitForChild("Config")
)

local DamageOverTime = {}

local function getDeathChance(behavior)
	if typeof(behavior.DeathEffectChance) == "number" then
		return behavior.DeathEffectChance
	end
	local effectConfig = behavior.DeathEffect and DeathEffectConfig.Effects[behavior.DeathEffect]
	local chanceKey = behavior.DeathEffectChanceKey
	if effectConfig and chanceKey and typeof(effectConfig[chanceKey]) == "number" then
		return effectConfig[chanceKey]
	end
	return nil
end

function DamageOverTime.OnTick(context, behavior)
	local damage = (behavior.Damage or 0) * context.SourceLevel
	if damage <= 0 then
		return
	end

	local hitContext
	if behavior.DamageType or behavior.DeathEffect then
		hitContext = {
			Effect = behavior.DeathEffect,
			Chance = getDeathChance(behavior),
			Source = context.RuntimeEffect.Effect.Source or context.EffectName,
			SourceType = "StatusEffect",
			DamageType = behavior.DamageType,
		}
	end
	PlayerHitEvent:Fire(context.Player, damage, nil, context.EffectName, hitContext)
end

return DamageOverTime
