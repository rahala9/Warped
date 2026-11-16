local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("EffectVisualSystem"):WaitForChild("Config"))
local settings = Config.ElectricShock
local assets = ReplicatedStorage:WaitForChild("SharedClientAssets")

local ElectricShockRenderer = {}
local active = {}

local function getConfiguredSound(path): Sound?
	local current: Instance = ReplicatedStorage
	for _, childName in ipairs(path) do
		local child = current:FindFirstChild(childName)
		if not child then
			return nil
		end
		current = child
	end
	return if current:IsA("Sound") then current else nil
end

function ElectricShockRenderer.PlayElectrocutedSound(parent: Instance): Sound?
	local path = settings.ElectrocutedSoundPath
	local source = if typeof(path) == "table" then getConfiguredSound(path) else nil
	if not source then
		warn("[EffectVisualSystem] Configured Electrocuted Sound is missing or is not a Sound:",
			if typeof(path) == "table" then table.concat(path, ".") else "<path not configured>")
		return nil
	end
	if source.SoundId == "" then
		warn("[EffectVisualSystem] SharedClientAssets.Sounds.Electric.Electrocuted has no SoundId")
		return nil
	end

	local previous = parent:FindFirstChild("ElectricShockElectrocutedSound")
	if previous and previous:IsA("Sound") then
		previous:Stop()
		previous:Destroy()
	end

	local sound = source:Clone()
	sound.Name = "ElectricShockElectrocutedSound"
	sound.Looped = false
	sound.Playing = false
	sound.Volume = math.max(sound.Volume, settings.ElectrocutedMinimumVolume or 1.5)
	sound.RollOffMaxDistance = math.max(sound.RollOffMaxDistance, settings.ElectrocutedRollOffMaxDistance or 70)
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 30)
	if Config.Debug then
		print("[EffectVisualSystem] Playing Electrocuted sound from", source:GetFullName(),
			"on", parent:GetFullName(), sound.SoundId)
	end
	return sound
end

local function duckNearbyCableSounds(origin: Vector3)
	local originals = {}
	local radius = settings.CableSoundDuckRadius or 18
	local factor = settings.CableSoundDuckFactor or 0.12
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if not descendant:IsA("Sound")
			or not string.match(descendant.Name, "^CableElectricSpark[3-8]$") then
			continue
		end
		local emitter = descendant.Parent
		local worldPosition
		if emitter and emitter:IsA("Attachment") then
			worldPosition = emitter.WorldPosition
		elseif emitter and emitter:IsA("BasePart") then
			worldPosition = emitter.Position
		end
		if worldPosition and (worldPosition - origin).Magnitude <= radius then
			originals[descendant] = descendant.Volume
			descendant.Volume *= factor
		end
	end
	return originals
end

local function restoreCableSounds(originals)
	for sound, volume in pairs(originals or {}) do
		if sound.Parent then
			sound.Volume = volume
		end
	end
end

local function allParts(container: Instance)
	local result = {}
	if container:IsA("BasePart") then
		table.insert(result, container)
	end
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(result, descendant)
		end
	end
	return result
end

local function findBone(container: Instance, name: string): Bone?
	local found = container:FindFirstChild(name, true)
	if found and found:IsA("Bone") then
		return found
	end
	return nil
end

local function buildBonePairs(character: Model, skeleton: Instance)
	local characterBones = {}
	local characterBoneCount = 0
	for _, descendant in ipairs(character:GetDescendants()) do
		-- During the live effect the clone is parented beneath the character.
		-- Never let its identically named bones replace the source character
		-- bones in this lookup table.
		if descendant:IsA("Bone") and not descendant:IsDescendantOf(skeleton) then
			characterBoneCount += 1
			characterBones[descendant.Name] = descendant
		end
	end

	local pairs = {}
	local skeletonBoneCount = 0
	for _, descendant in ipairs(skeleton:GetDescendants()) do
		if descendant:IsA("Bone") then
			skeletonBoneCount += 1
			local characterBone = characterBones[descendant.Name]
			if characterBone and characterBone ~= descendant then
				table.insert(pairs, {
					skeleton = descendant,
					character = characterBone,
				})
			end
		end
	end
	return pairs, characterBoneCount, skeletonBoneCount
end

local function copyBonePose(bonePairs)
	-- Both meshes use the exact Warped bind rig. Bone.Transform is parent-local,
	-- so direct copying preserves animation and IK without hierarchy feedback.
	for _, pair in ipairs(bonePairs) do
		if pair.skeleton.Parent and pair.character.Parent then
			pair.skeleton.Transform = pair.character.Transform
		end
	end
end

function ElectricShockRenderer.TrackPose(skeleton: Instance, bonePairs)
	copyBonePose(bonePairs)
	local connection
	connection = RunService.PreRender:Connect(function()
		if not skeleton.Parent then
			connection:Disconnect()
			return
		end
		copyBonePose(bonePairs)
	end)
	return connection
end

function ElectricShockRenderer.SuppressCharacterShadows(character: Model, effectOwner: Instance)
	if settings.CastShadows ~= false then
		return function() end
	end

	local originals = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and not descendant:IsDescendantOf(effectOwner) then
			originals[descendant] = descendant.CastShadow
			descendant.CastShadow = false
		end
	end

	local restored = false
	local function restore()
		if restored then
			return
		end
		restored = true
		for part, castShadow in pairs(originals) do
			if part.Parent then
				part.CastShadow = castShadow
			end
		end
	end

	effectOwner.Destroying:Connect(restore)
	return restore
end

local function chooseRoot(container: PVInstance): BasePart?
	if container:IsA("BasePart") then
		return container
	end
	if container:IsA("Model") and container.PrimaryPart then
		return container.PrimaryPart
	end
	for _, name in ipairs({ "ElectricSkeleton", "HumanoidRootPart", "RootPart", "Skeleton" }) do
		local candidate = container:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then
			if container:IsA("Model") then
				container.PrimaryPart = candidate
			end
			return candidate
		end
	end
	local first = container:FindFirstChildWhichIsA("BasePart", true)
	if first and container:IsA("Model") then
		container.PrimaryPart = first
	end
	return first
end

local function prepareAssembly(container: PVInstance, root: BasePart)
	for _, part in ipairs(allParts(container)) do
		part.Transparency = 0
		part.CastShadow = settings.CastShadows ~= false
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		if part ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "ElectricSkeletonWeld"
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = root
		end
	end
end

function ElectricShockRenderer.CreateSkeleton(character: Model, parent: Instance)
	local asset = assets:FindFirstChild("Skeleton")
	if not asset or (not asset:IsA("Model") and not asset:IsA("BasePart")) then
		warn("[EffectVisualSystem] ReplicatedStorage.SharedClientAssets.Skeleton is missing or unsupported")
		return nil
	end

	local model = asset:Clone() :: PVInstance
	model.Name = character.Name .. "_ElectricSkeleton"
	model.Parent = parent

	local root = chooseRoot(model)
	local characterRoot = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not root or not characterRoot or not characterRoot:IsA("BasePart") then
		model:Destroy()
		return nil
	end

	-- Align the identical bind rigs once by their authored Root bones. Animated
	-- pose data remains a separate parent-local Transform copy below.
	local skeletonRootBone = findBone(model, "Root")
	local characterRootBone = findBone(character, "Root")
	if skeletonRootBone and characterRootBone then
		local desiredRoot = characterRootBone.WorldCFrame * (settings.AlignmentOffset or CFrame.identity)
		local delta = desiredRoot * skeletonRootBone.WorldCFrame:Inverse()
		model:PivotTo(delta * model:GetPivot())
	else
		warn("[EffectVisualSystem] Exact Root bone alignment unavailable; using HumanoidRootPart fallback")
		local delta = characterRoot.CFrame * root.CFrame:Inverse()
		model:PivotTo(delta * model:GetPivot())
	end

	prepareAssembly(model, root)
	local bonePairs, characterBoneCount, skeletonBoneCount = buildBonePairs(character, model)
	copyBonePose(bonePairs)

	if #bonePairs == 0 then
		warn(("[EffectVisualSystem] No exact matching bones for %s (character=%d, skeleton=%d)"):format(
			character:GetFullName(),
			characterBoneCount,
			skeletonBoneCount
		))
	elseif Config.Debug then
		print(("[EffectVisualSystem] Electric skeleton matched %d/%d exact bones (character has %d)"):format(
			#bonePairs,
			skeletonBoneCount,
			characterBoneCount
		))
	end

	return model, root, characterRoot, bonePairs
end

local function setShockVisible(state, isOn: boolean)
	for part, original in pairs(state.bodyParts) do
		if part.Parent then
			part.LocalTransparencyModifier = if isOn
				then math.max(original, settings.BodyTransparency)
				else original
		end
	end
	for decal, original in pairs(state.decals) do
		if decal.Parent then
			decal.Transparency = if isOn
				then math.max(original, settings.BodyTransparency)
				else original
		end
	end
	for _, part in ipairs(state.skeletonParts) do
		if part.Parent then
			part.LocalTransparencyModifier = if isOn then settings.SkeletonTransparency else 1
		end
	end
	if state.highlight.Parent then
		state.highlight.Enabled = isOn
	end
	if state.light.Parent then
		state.light.Enabled = isOn
		state.light.Brightness = settings.LightBrightness * (0.75 + math.random() * 0.5)
	end
end

function ElectricShockRenderer.Stop(character: Model)
	local state = active[character]
	if not state then
		return
	end
	active[character] = nil
	state.running = false
	if state.poseConnection then
		state.poseConnection:Disconnect()
		state.poseConnection = nil
	end
	for part, original in pairs(state.bodyParts) do
		if part.Parent then
			part.LocalTransparencyModifier = original
		end
	end
	for decal, original in pairs(state.decals) do
		if decal.Parent then
			decal.Transparency = original
		end
	end
	if state.sound and state.sound.Parent then
		state.sound:Stop()
		state.sound:Destroy()
	end
	restoreCableSounds(state.duckedCableSounds)
	if state.model.Parent then
		state.model:Destroy()
	end
end

function ElectricShockRenderer.Start(character: Model, _parent: Instance, _payload)
	ElectricShockRenderer.Stop(character)
	local model, root, characterRoot, bonePairs = ElectricShockRenderer.CreateSkeleton(character, character)
	if not model then
		return nil
	end
	ElectricShockRenderer.SuppressCharacterShadows(character, model)
	-- Only duck ambience for the client whose own character is being shocked.
	-- Other players still hear the spatial electrocution cue normally.
	local duckedCableSounds = if character == Players.LocalPlayer.Character
		then duckNearbyCableSounds(characterRoot.Position)
		else {}
	-- Keep the spatial cue on the real character root and retain it in the
	-- effect state so Stop can silence it immediately on zone exit.
	local electrocutedSound = ElectricShockRenderer.PlayElectrocutedSound(characterRoot)

	local followWeld = Instance.new("WeldConstraint")
	followWeld.Name = "ElectricSkeletonFollow"
	followWeld.Part0 = root
	followWeld.Part1 = characterRoot
	followWeld.Parent = root

	local light = root:FindFirstChildWhichIsA("PointLight", true)
	if not light then
		light = Instance.new("PointLight")
		light.Name = "ElectricShockLight"
		light.Parent = root
	end
	light.Color = settings.LightColor
	light.Range = settings.LightRange
	light.Shadows = true

	local highlight = Instance.new("Highlight")
	highlight.Name = "ElectricSkeletonHighlight"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = settings.LightColor
	highlight.FillTransparency = settings.HighlightFillTransparency
	highlight.OutlineColor = Color3.fromRGB(225, 252, 255)
	highlight.OutlineTransparency = settings.HighlightOutlineTransparency
	highlight.Parent = model

	local state = {
		model = model,
		light = light,
		highlight = highlight,
		skeletonParts = allParts(model),
		bodyParts = {},
		decals = {},
		bonePairs = bonePairs,
		duckedCableSounds = duckedCableSounds,
		sound = electrocutedSound,
		running = true,
	}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsDescendantOf(model) then
			continue
		elseif descendant:IsA("BasePart") then
			state.bodyParts[descendant] = descendant.LocalTransparencyModifier
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			state.decals[descendant] = descendant.Transparency
		end
	end
	active[character] = state
	state.poseConnection = ElectricShockRenderer.TrackPose(model, state.bonePairs)

	task.spawn(function()
		local isOn = true
		while state.running and active[character] == state and character.Parent do
			setShockVisible(state, isOn)
			local minimumTime = if isOn then settings.MinimumVisibleTime else settings.MinimumHiddenTime
			local maximumTime = if isOn then settings.MaximumVisibleTime else settings.MaximumHiddenTime
			isOn = not isOn
			task.wait(minimumTime + math.random() * (maximumTime - minimumTime))
		end
		if active[character] == state then
			ElectricShockRenderer.Stop(character)
		end
	end)
	return model
end

return ElectricShockRenderer
