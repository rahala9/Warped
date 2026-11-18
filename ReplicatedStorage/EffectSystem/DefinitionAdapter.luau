-- Normalizes new effect metadata while legacy Type/Action definitions migrate.
local DefinitionAdapter = {}

function DefinitionAdapter.GetDuration(definition): number
	if typeof(definition.Duration) == "number" then
		return definition.Duration
	end
	local effect = definition.Effect
	if effect and typeof(effect.TimeInEffect) == "number" then
		return effect.TimeInEffect
	end
	return 0
end

function DefinitionAdapter.GetTickInterval(definition): number
	local interval = definition.TickInterval
	if typeof(interval) == "number" and interval > 0 then
		return interval
	end
	return 1
end

function DefinitionAdapter.GetStacking(definition)
	local stacking = definition.Stacking
	if typeof(stacking) ~= "table" then
		return { Mode = "Ignore", MaxStacks = 1 }
	end
	return {
		Mode = stacking.Mode or "Ignore",
		MaxStacks = math.max(1, stacking.MaxStacks or 1),
	}
end

function DefinitionAdapter.GetPresentation(definition)
	local presentation = definition.Presentation or {}
	local icon = presentation.Icon or {}
	return {
		Description = presentation.Description or definition.Description or definition.Name,
		ShowTimer = presentation.ShowTimer ~= false,
		ImageOffsetX = icon.OffsetX or definition.ImageOffsetX or 0,
		ImageOffsetY = icon.OffsetY or definition.ImageOffsetY or 0,
	}
end

return DefinitionAdapter
