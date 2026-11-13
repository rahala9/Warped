local ServerProjectileVisibility = {}
local RunService = game:GetService("RunService")

local hiddenShotIds = {}
local trackedParts = {}

local function restore(part)
	local state = trackedParts[part]
	if not state then
		return
	end

	if part.Parent then
		part.LocalTransparencyModifier = state.Transparency
		for effect, wasEnabled in pairs(state.Effects) do
			if effect.Parent then
				effect.Enabled = wasEnabled
			end
		end
	end
	trackedParts[part] = nil
end

local function update(part)
	local shotId = part:GetAttribute("PresentationShotId")
	if not shotId or not hiddenShotIds[shotId] then
		restore(part)
		return
	end

	if not trackedParts[part] then
		local effects = {}
		for _, descendant in ipairs(part:GetDescendants()) do
			if descendant:IsA("Trail") or descendant:IsA("Beam") then
				effects[descendant] = descendant.Enabled
				descendant.Enabled = false
			end
		end
		trackedParts[part] = {
			Transparency = part.LocalTransparencyModifier,
			Effects = effects,
		}
	end
	part.LocalTransparencyModifier = 1
end

local function observe(part)
	if not part:IsA("BasePart") then
		return
	end
	part:GetAttributeChangedSignal("PresentationShotId"):Connect(function()
		update(part)
	end)
	update(part)
end

function ServerProjectileVisibility.Initialize()
	local sharedItems = workspace:WaitForChild("SharedWorkspaceItems")
	local laserFolder = sharedItems:WaitForChild("LaserBulletsFolder")
	for _, child in ipairs(laserFolder:GetChildren()) do
		observe(child)
	end
	laserFolder.ChildAdded:Connect(observe)
	RunService.RenderStepped:Connect(function()
		for part, state in pairs(trackedParts) do
			if part.Parent then
				part.LocalTransparencyModifier = 1
				for effect in pairs(state.Effects) do
					if effect.Parent and effect.Enabled then
						effect.Enabled = false
					end
				end
			else
				trackedParts[part] = nil
			end
		end
	end)
end

function ServerProjectileVisibility.HideShot(shotId, lifetime)
	hiddenShotIds[shotId] = true

	local sharedItems = workspace:FindFirstChild("SharedWorkspaceItems")
	local laserFolder = sharedItems and sharedItems:FindFirstChild("LaserBulletsFolder")
	if laserFolder then
		for _, child in ipairs(laserFolder:GetChildren()) do
			update(child)
		end
	end

	task.delay(lifetime, function()
		hiddenShotIds[shotId] = nil
		for part in pairs(trackedParts) do
			update(part)
		end
	end)
end

return ServerProjectileVisibility
