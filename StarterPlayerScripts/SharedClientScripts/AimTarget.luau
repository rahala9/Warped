local AimTarget = {}

local DEFAULT_DISTANCE = 900

local function appendIfPresent(instances, instance)
	if instance then
		table.insert(instances, instance)
	end
end

function AimTarget.GetScreenPoint(mouse): Vector2
	return Vector2.new(mouse.X, mouse.Y)
end

function AimTarget.GetTarget(
	camera: Camera,
	screenPoint: Vector2,
	character: Model?,
	distance: number?
): (Vector3, RaycastResult?)
	local exclusions = {}

	appendIfPresent(exclusions, character)
	appendIfPresent(exclusions, workspace:FindFirstChild("Zones"))
	appendIfPresent(exclusions, workspace:FindFirstChild("BuildBlockers"))
	appendIfPresent(exclusions, workspace:FindFirstChild("HelperParts"))

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = exclusions
	raycastParams.IgnoreWater = true

	local unitRay = camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local maxDistance = distance or DEFAULT_DISTANCE
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * maxDistance, raycastParams)

	if result then
		return result.Position, result
	end

	return unitRay.Origin + unitRay.Direction * maxDistance, nil
end

return AimTarget
