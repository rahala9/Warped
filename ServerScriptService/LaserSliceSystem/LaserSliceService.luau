-- Compatibility adapter for older callers. New death effects are registered and
-- dispatched by DeathEffectSystem.DeathEffectService.
local ServerScriptService = game:GetService("ServerScriptService")

local DeathEffectService = require(
	ServerScriptService:WaitForChild("DeathEffectSystem"):WaitForChild("DeathEffectService")
)

return {
	RenderDeath = function(player: Player, context)
		return DeathEffectService.RenderDeath(player, context)
	end,
}
