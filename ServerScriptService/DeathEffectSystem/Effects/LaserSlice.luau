local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LaserSliceSystem"):WaitForChild("Config"))

local LaserSlice = {}

local function sanitizePlanes(rawPlanes, character: Model)
	local planes = {}
	if typeof(rawPlanes) ~= "table" then
		return planes
	end

	local characterCFrame, characterSize = character:GetBoundingBox()
	local minY = characterCFrame.Position.Y - characterSize.Y * 0.6
	local maxY = characterCFrame.Position.Y + characterSize.Y * 0.6
	for _, value in ipairs(rawPlanes) do
		if typeof(value) == "number" and value >= minY and value <= maxY then
			local duplicate = false
			for _, existing in ipairs(planes) do
				if math.abs(existing - value) <= Config.PlaneMergeTolerance then
					duplicate = true
					break
				end
			end
			if not duplicate then
				table.insert(planes, value)
			end
		end
	end

	table.sort(planes)
	while #planes > Config.MaximumPlanes do
		table.remove(planes)
	end
	return planes
end

function LaserSlice.BuildPayload(_player: Player, character: Model, context)
	if not Config.Enabled then
		return nil
	end

	local planes = sanitizePlanes(context.SlicePlanes, character)
	if #planes == 0 and typeof(context.ContactPlaneY) == "number" then
		planes = sanitizePlanes({ context.ContactPlaneY }, character)
	end
	if #planes == 0 then
		return nil
	end

	return {
		SlicePlanes = planes,
		TemplateKey = context.TemplateKey,
		Source = context.Source,
	}
end

return LaserSlice
