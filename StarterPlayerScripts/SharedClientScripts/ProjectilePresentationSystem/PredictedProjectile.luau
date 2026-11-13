local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local PredictedProjectile = {}

local function effectParent(): Instance
	return workspace:FindFirstChild("SharedWorkspaceItems") or workspace
end

function PredictedProjectile.Emit(
	muzzleCFrame,
	serverOrigin,
	serverDirection,
	speed,
	maxDistance,
	settings,
	character
)
	if speed <= 0 or maxDistance <= 0 then
		return
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	local excludedInstances = {}
	if character then
		table.insert(excludedInstances, character)
	end

	-- Match the server's intent and never let a replicated cosmetic projectile
	-- become the predicted projectile's immediate raycast hit at the muzzle.
	local sharedItems = workspace:FindFirstChild("SharedWorkspaceItems")
	if sharedItems then
		for _, child in ipairs(sharedItems:GetChildren()) do
			if child.Name:match("BulletsFolder$") then
				table.insert(excludedInstances, child)
			end
		end
	end
	for _, name in ipairs({"HelperParts", "BuildBlockers", "Zones"}) do
		local instance = workspace:FindFirstChild(name)
		if instance then
			table.insert(excludedInstances, instance)
		end
	end
	rayParams.FilterDescendantsInstances = excludedInstances

	local unitDirection = serverDirection.Unit
	local rayResult = workspace:Raycast(serverOrigin, unitDirection * maxDistance, rayParams)
	local authoritativeEnd = rayResult and rayResult.Position
		or (serverOrigin + unitDirection * maxDistance)

	local startPosition = muzzleCFrame.Position
	local visualOffset = authoritativeEnd - startPosition
	local visualDistance = visualOffset.Magnitude
	if visualDistance < 0.05 then
		return
	end

	local visualDirection = visualOffset.Unit
	local projectileLength = math.min(settings.ProjectileLength, visualDistance)
	local startCenter = startPosition + visualDirection * (projectileLength * 0.5)
	local endCenter = authoritativeEnd - visualDirection * (projectileLength * 0.5)

	local projectile = Instance.new("Part")
	projectile.Name = "LocalPredictedEnergyProjectile"
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanQuery = false
	projectile.CanTouch = false
	projectile.CastShadow = false
	projectile.Material = Enum.Material.Neon
	projectile.Color = settings.Color
	projectile.Size = Vector3.new(
		settings.ProjectileWidth,
		settings.ProjectileWidth,
		projectileLength
	)
	projectile.CFrame = CFrame.lookAt(startCenter, startCenter + visualDirection)
	projectile.Parent = effectParent()

	local duration = visualDistance / speed
	TweenService:Create(
		projectile,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{CFrame = CFrame.lookAt(endCenter, endCenter + visualDirection)}
	):Play()
	Debris:AddItem(projectile, duration + 0.05)
end

return PredictedProjectile
