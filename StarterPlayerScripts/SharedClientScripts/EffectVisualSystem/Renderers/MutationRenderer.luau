local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("MutationSystem"):WaitForChild("Config"))
local assets = ReplicatedStorage:WaitForChild("SharedClientAssets")

local MutationRenderer = {}
local active = {}

local HEAD_ACCESSORY_TYPES = {
	[Enum.AccessoryType.Hat] = true,
	[Enum.AccessoryType.Hair] = true,
	[Enum.AccessoryType.Face] = true,
	[Enum.AccessoryType.Eyebrow] = true,
	[Enum.AccessoryType.Eyelash] = true,
}

local function getConfiguredBone(character: Model): Bone?
	local current: Instance? = character:FindFirstChild("HumanoidRootPart")
	for _, name in ipairs(Config.NeckBonePath) do
		current = current and current:FindFirstChild(name)
		if not current then
			return nil
		end
	end
	return if current and current:IsA("Bone") then current else nil
end

local function getCharacterHeadPart(character: Model): BasePart?
	for _, name in ipairs(Config.CharacterHeadPartNames) do
		local candidate = character:FindFirstChild(name)
		if candidate and candidate:IsA("BasePart") then
			return candidate
		end
	end
	return nil
end

local function getPivot(container: PVInstance): CFrame
	return if container:IsA("Model") then container:GetPivot() else container.CFrame
end

local function setPivot(container: PVInstance, cframe: CFrame)
	if container:IsA("Model") then
		container:PivotTo(cframe)
	else
		container.CFrame = cframe
	end
end

local function isHiddenName(name: string): boolean
	if Config.HiddenPartNames[string.lower(name)] then
		return true
	end
	local lowerName = string.lower(name)
	for _, prefix in ipairs(Config.HiddenPartPrefixes) do
		if string.sub(lowerName, 1, #prefix) == string.lower(prefix) then
			return true
		end
	end
	return false
end

local function collectOriginalHeadParts(character: Model)
	local result = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and isHiddenName(child.Name) then
			result[child] = child.LocalTransparencyModifier
		elseif Config.HideHeadAccessories and child:IsA("Accessory")
			and HEAD_ACCESSORY_TYPES[child.AccessoryType] then
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				result[handle] = handle.LocalTransparencyModifier
			end
		end
	end
	return result
end

local function prepareClone(clone: PVInstance)
	local instances = if clone:IsA("BasePart") then { clone } else clone:GetDescendants()
	local transparencies = {}
	for _, instance in ipairs(instances) do
		if instance:IsA("BasePart") then
			transparencies[instance] = instance.Transparency
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanTouch = false
			instance.CanQuery = false
			instance.Massless = true
		end
	end
	return transparencies
end

local function restoreOriginalHead(state)
	for part, transparency in pairs(state.hiddenParts) do
		if part.Parent then
			part.LocalTransparencyModifier = transparency
		end
	end
end

function MutationRenderer.Stop(character: Model)
	local state = active[character]
	if not state then
		return
	end
	active[character] = nil
	if state.connection then
		state.connection:Disconnect()
	end
	restoreOriginalHead(state)
	if state.clone.Parent then
		state.clone:Destroy()
	end
end

function MutationRenderer.Start(character: Model, _parent: Instance, _payload)
	MutationRenderer.Stop(character)

	local template = assets:FindFirstChild(Config.AssetName)
	if not template or (not template:IsA("Model") and not template:IsA("BasePart")) then
		warn("[MutationSystem] Missing or unsupported asset at ReplicatedStorage.SharedClientAssets." .. Config.AssetName)
		return nil
	end

	local neckBone = getConfiguredBone(character)
	local characterHead = getCharacterHeadPart(character)
	if not neckBone or not characterHead then
		warn("[MutationSystem] Character is missing the configured Neck bone or head reference:", character:GetFullName())
		return nil
	end

	local clone = template:Clone() :: PVInstance
	clone.Name = character.Name .. "_MutationFlyhead"
	clone.Parent = character

	local mount = clone:FindFirstChild(Config.MountAttachmentName, true)
	if mount and not mount:IsA("Attachment") then
		warn("[MutationSystem] " .. Config.MountAttachmentName .. " exists but is not an Attachment")
		mount = nil
	end
	if not mount and not Config.AllowPivotFallback then
		warn("[MutationSystem] Flyhead requires an Attachment named " .. Config.MountAttachmentName)
		clone:Destroy()
		return nil
	elseif not mount then
		warn("[MutationSystem] Flyhead has no " .. Config.MountAttachmentName
			.. "; using its model pivot as the temporary mount")
	end

	local cloneTransparencies = prepareClone(clone)
	local mountFromPivot = if mount
		then getPivot(clone):ToObjectSpace(mount.WorldCFrame)
		else Config.FallbackMountFromPivot
	local headFromNeck = neckBone.WorldCFrame:ToObjectSpace(characterHead.CFrame)
	local hiddenParts = collectOriginalHeadParts(character)
	for part in pairs(hiddenParts) do
		part.LocalTransparencyModifier = 1
	end

	local state = {
		clone = clone,
		cloneTransparencies = cloneTransparencies,
		hiddenParts = hiddenParts,
		connection = nil,
	}
	active[character] = state

	local function update()
		if active[character] ~= state or not character.Parent or not clone.Parent
			or not neckBone.Parent or (mount and not mount.Parent) then
			MutationRenderer.Stop(character)
			return
		end

		-- Reassert the hide because Roblox's camera controller can rewrite
		-- LocalTransparencyModifier when entering or leaving first person.
		for part in pairs(hiddenParts) do
			if part.Parent then
				part.LocalTransparencyModifier = 1
			end
		end
		-- The Flyhead is client-rendered, so mirror the real head's server-driven
		-- fade. This keeps it from floating visibly if an already-mutated player
		-- uses the teleporter again.
		for part, originalTransparency in pairs(cloneTransparencies) do
			if part.Parent then
				part.Transparency = math.max(originalTransparency, characterHead.Transparency)
			end
		end

		local targetHead = neckBone.WorldCFrame * headFromNeck * Config.AlignmentOffset
		setPivot(clone, targetHead * mountFromPivot:Inverse())
	end

	update()
	state.connection = RunService.PreRender:Connect(update)
	if Config.Debug then
		print("[MutationSystem] Started Flyhead mutation for", character:GetFullName())
	end
	return clone
end

return MutationRenderer
