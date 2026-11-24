-- ServerScriptService.Systems.TerminalEffects
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerHitEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)

local TerminalEffects = {}

function TerminalEffects.Kill(player)
	-- Reuse the same status/VFX/audio path as cable hazards, while preserving
	-- the terminal's existing lethal damage rather than relying on status ticks.
	EffectsFunctions.AddEffect(player, "ElectricShock", 1, "TerminalCriticalFailure")
	PlayerHitEvent:Fire(player, 9999999999, nil, "ElectricShock", {
		Effect = "Electrocuted",
		Chance = 1,
		Source = "Terminal critical failure",
		SourceType = "Terminal",
		DamageType = "Electric",
	})
end

function TerminalEffects.AlertSecurity(terminalPosition)

	-- TODO spawn guards, trigger alarms, etc.
	print("SECURITY ALERT at position:", terminalPosition)
end

function TerminalEffects.ElectricShock(player)
	PlayerHitEvent:Fire(player, 25, nil, "Electric")
end

function TerminalEffects.SpawnGuards(terminalPosition)
	-- TODO Spawn guard NPCs near the terminal
	print("Spawning guards at:", terminalPosition)
end

function TerminalEffects.LockdownArea(terminalPosition)
	-- Lock all doors in the area
	print("Area lockdown initiated at:", terminalPosition)
end

return TerminalEffects
