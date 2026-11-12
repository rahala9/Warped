-- ServerScriptService.Systems.TerminalEffects
local TerminalEffects = {}

function TerminalEffects.Kill(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
end

function TerminalEffects.AlertSecurity(terminalPosition)

	-- TODO spawn guards, trigger alarms, etc.
	print("SECURITY ALERT at position:", terminalPosition)
end

function TerminalEffects.ElectricShock(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:TakeDamage(25)
		end
	end
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