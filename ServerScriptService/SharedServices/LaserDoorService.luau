local LaserDoorService = {}

-- A generation per door prevents an older delayed close from overriding a
-- newer terminal hack or custody release.
local generations = setmetatable({}, { __mode = "k" })

local function setBeamModelEnabled(beamModel, enabled)
	local primaryPart = beamModel.PrimaryPart
	if not primaryPart then return end

	local beam = primaryPart:FindFirstChildWhichIsA("Beam", true)
	if beam then beam.Enabled = enabled end

	local visiblePart = primaryPart:FindFirstChild("Part")
	if visiblePart and visiblePart:IsA("BasePart") then
		visiblePart.Transparency = enabled and 0.5 or 1
	end
end

function LaserDoorService:SetEnabled(laserDoor, enabled)
	if not laserDoor or not laserDoor.Parent then return false end
	laserDoor:SetAttribute("Enabled", enabled)

	local laserBeamWall = laserDoor:FindFirstChild("LaserBeamWall")
	if not laserBeamWall then return false end

	local killBlock = laserBeamWall:FindFirstChild("Kill")
	if killBlock and killBlock:IsA("BasePart") then
		killBlock.CanTouch = enabled
	end

	for _, child in ipairs(laserBeamWall:GetChildren()) do
		if child:IsA("Model") and child.Name == "LaserBeam" then
			setBeamModelEnabled(child, enabled)
		end
	end

	return true
end

function LaserDoorService:DisableFor(laserDoor, duration)
	if not self:SetEnabled(laserDoor, false) then return false end
	local generation = (generations[laserDoor] or 0) + 1
	generations[laserDoor] = generation

	task.delay(math.max(tonumber(duration) or 0, 0), function()
		if generations[laserDoor] ~= generation then return end
		generations[laserDoor] = nil
		self:SetEnabled(laserDoor, true)
	end)
	return true
end

return LaserDoorService
