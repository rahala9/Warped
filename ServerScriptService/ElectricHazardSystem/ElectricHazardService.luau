local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Zones = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ZoneLoader"))

local DEFAULT_EFFECT = "ElectricShock"
local DEFAULT_SOURCE_LEVEL = 1
local REFRESH_INTERVAL = 1
local HAZARD_SIZE = Vector3.new(3, 3, 3)

local ElectricHazardService = {}

local effectsFunctions
local initialized = false
local activeTokens = {}

local function createZoneForAttachment(attachment: Attachment)
	local existing = attachment:FindFirstChild("CableElectricHazardZone")
	if existing and not existing:IsA("Folder") then
		warn("[ElectricHazardSystem] CableElectricHazardZone must be a Folder under", attachment:GetFullName())
		return nil
	end

	local worldPosition = attachment.WorldCFrame.Position
	local folder = existing or Instance.new("Folder")
	folder.Name = "CableElectricHazardZone"
	folder:SetAttribute("ZoneKey", attachment:GetFullName() .. ":ElectricHazard")
	folder:SetAttribute("ZoneType", "ElectricHazard")
	if folder:GetAttribute("EffectName") == nil then folder:SetAttribute("EffectName", DEFAULT_EFFECT) end
	if folder:GetAttribute("SourceLevel") == nil then folder:SetAttribute("SourceLevel", DEFAULT_SOURCE_LEVEL) end
	if folder:GetAttribute("RemoveOnExit") == nil then folder:SetAttribute("RemoveOnExit", true) end
	if folder:GetAttribute("Enabled") == nil then folder:SetAttribute("Enabled", true) end
	folder.Parent = attachment

	local oldBounds = folder:FindFirstChild("HazardBounds")
	local bounds = if oldBounds and oldBounds:IsA("BasePart") then oldBounds else Instance.new("Part")
	bounds.Name = "HazardBounds"
	bounds.Size = HAZARD_SIZE
	bounds.CFrame = CFrame.new(worldPosition)
	bounds.Anchored = true
	bounds.CanCollide = false
	bounds.CanTouch = false
	bounds.CanQuery = false
	bounds.Transparency = 1
	bounds.Parent = folder

	-- Tag only after the folder is complete so ZoneLoader never observes an
	-- empty zone. This does not read or change any particle/light properties.
	CollectionService:AddTag(folder, "ZoneFolder")
	print(("[ElectricHazardSystem] Created 3x3x3 zone at %s for %s"):format(
		tostring(worldPosition),
		attachment:GetFullName()
	))
	return folder
end

local function ensureZoneForSparkMarker(instance: Instance)
	if instance.Name ~= "CableElectricSparks" or not instance:IsA("ParticleEmitter") then
		return
	end
	local attachment = instance.Parent
	if attachment and attachment:IsA("Attachment") and attachment:IsDescendantOf(workspace) then
		createZoneForAttachment(attachment)
	end
end

local function ensureExistingCableZones()
	for _, instance in ipairs(workspace:GetDescendants()) do
		ensureZoneForSparkMarker(instance)
	end
end

local function sourceFor(folder: Instance): string
	return "ElectricHazard:" .. tostring(folder:GetAttribute("ZoneKey") or folder.Name)
end

local function removeEffect(player: Player, folder: Instance)
	if effectsFunctions and player.Parent then
		effectsFunctions.RemoveEffect(
			player,
			folder:GetAttribute("EffectName") or DEFAULT_EFFECT,
			sourceFor(folder)
		)
	end
end

local function stopPlayer(player: Player, folder: Instance)
	local byFolder = activeTokens[folder]
	if byFolder then
		byFolder[player] = nil
	end
	if folder:GetAttribute("RemoveOnExit") ~= false then
		removeEffect(player, folder)
	end
end

local function startPlayer(player: Player, folder: Instance)
	activeTokens[folder] = activeTokens[folder] or {}
	if activeTokens[folder][player] then
		return
	end

	local token = {}
	activeTokens[folder][player] = token

	task.spawn(function()
		local wasEnabled = false
		while folder.Parent
			and player.Parent
			and activeTokens[folder]
			and activeTokens[folder][player] == token
		do
			local enabled = folder:GetAttribute("Enabled") ~= false
			if enabled then
				local sourceLevel = folder:GetAttribute("SourceLevel")
				if typeof(sourceLevel) ~= "number" then
					sourceLevel = DEFAULT_SOURCE_LEVEL
				end
				effectsFunctions.AddEffect(
					player,
					folder:GetAttribute("EffectName") or DEFAULT_EFFECT,
					sourceLevel,
					sourceFor(folder)
				)
			elseif wasEnabled then
				removeEffect(player, folder)
			end
			wasEnabled = enabled
			task.wait(REFRESH_INTERVAL)
		end
	end)
end

local function bindZone(zone, folder: Instance)
	if folder:GetAttribute("ElectricHazardBound") then
		return
	end
	folder:SetAttribute("ElectricHazardBound", true)
	activeTokens[folder] = activeTokens[folder] or {}

	-- A 3-stud-high zone around the cable is below the HumanoidRootPart, so
	-- test the character's ground contact instead of its center.
	zone:SetDetectionMode("Ground")

	zone:OnPlayerEntered(function(player)
		print("[ElectricHazardSystem] Player entered", player.Name, folder:GetFullName())
		startPlayer(player, folder)
	end)
	zone:OnPlayerExited(function(player)
		stopPlayer(player, folder)
	end)

	folder.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end
		local byFolder = activeTokens[folder]
		if byFolder then
			for player in pairs(byFolder) do
				stopPlayer(player, folder)
			end
		end
		activeTokens[folder] = nil
	end)

	print("[ElectricHazardSystem] Bound", folder:GetFullName())
end

function ElectricHazardService.Init(newEffectsFunctions)
	assert(typeof(newEffectsFunctions) == "table", "ElectricHazardService.Init expects the effects functions table")
	if initialized then
		return
	end
	initialized = true
	effectsFunctions = newEffectsFunctions

	Zones:OnTypeLoaded("ElectricHazard", bindZone)
	ensureExistingCableZones()
	workspace.DescendantAdded:Connect(function(instance)
		-- Defer one step so a newly cloned Attachment can finish parenting.
		task.defer(ensureZoneForSparkMarker, instance)
	end)
	Players.PlayerRemoving:Connect(function(player)
		for folder, byFolder in pairs(activeTokens) do
			if byFolder[player] then
				stopPlayer(player, folder)
			end
		end
	end)
end

return ElectricHazardService
