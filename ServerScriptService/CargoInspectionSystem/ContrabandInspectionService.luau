local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("CargoInspectionSystem"):WaitForChild("Config"))
local Zones = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ZoneLoader"))

local dockRemotes = ReplicatedStorage:WaitForChild("SharedRemotes"):FindFirstChild("DockRemotes")
if not dockRemotes then
	dockRemotes = Instance.new("Folder")
	dockRemotes.Name = "DockRemotes"
	dockRemotes.Parent = ReplicatedStorage.SharedRemotes
end

local inspectionChanged = dockRemotes:FindFirstChild(Config.RemoteName)
if not inspectionChanged then
	inspectionChanged = Instance.new("RemoteEvent")
	inspectionChanged.Name = Config.RemoteName
	inspectionChanged.Parent = dockRemotes
end

local enforcementRequested = script.Parent:FindFirstChild("EnforcementRequested")
if not enforcementRequested then
	enforcementRequested = Instance.new("BindableEvent")
	enforcementRequested.Name = "EnforcementRequested"
	enforcementRequested.Parent = script.Parent
end

local SecurityResponseService = require(
	ServerScriptService:WaitForChild("SecurityResponseSystem"):WaitForChild("SecurityResponseService")
)
SecurityResponseService:Init(enforcementRequested)

local ContrabandInspectionService = {}
local tracked = {} -- [cargo Model] = state
local inspectionZones = {} -- [zone] = source folder

local function getContrabandSeverity(job)
	local risks = job and job.risks
	if typeof(risks) ~= "table" then return nil end
	local severity = risks[Config.RiskName]
	if typeof(severity) ~= "number" or severity <= 0 then return nil end
	return math.clamp(severity, 0, 1)
end

local function numberAttribute(instance, name, fallback)
	local value = instance and instance:GetAttribute(name)
	return typeof(value) == "number" and value or fallback
end

local function inspectionId(folder)
	return tostring(
		folder:GetAttribute("InspectionId")
			or folder:GetAttribute("ZoneKey")
			or folder.Name
	)
end

local function stringAttribute(instance, name, fallback)
	local value = instance and instance:GetAttribute(name)
	return typeof(value) == "string" and value ~= "" and value or fallback
end

local function enforcementFor(state, source)
	local offenseClass = state.job.contrabandClass or Config.DefaultOffenseClass
	if not Config.OffenseClasses[offenseClass] then offenseClass = Config.DefaultOffenseClass end

	local policyName = stringAttribute(
		source,
		"EnforcementPolicy",
		Config.DefaultEnforcementPolicy
	)
	local policy = Config.EnforcementPolicies[policyName]
	if not policy then
		policyName = Config.DefaultEnforcementPolicy
		policy = Config.EnforcementPolicies[policyName]
	end

	return {
		offenseClass = offenseClass,
		policy = policyName,
		response = policy[offenseClass] or "Fine",
		jurisdiction = stringAttribute(source, "Jurisdiction", Config.DefaultJurisdiction),
		fineMultiplier = math.max(numberAttribute(
			source,
			"FineMultiplier",
			Config.OffenseClasses[offenseClass].FineMultiplier
		), 0),
	}
end

local function getHoldingCFrame(source)
	local holdingPoint = source and source:FindFirstChild("HoldingPoint", true)
	if holdingPoint and holdingPoint:IsA("Attachment") then
		return holdingPoint.WorldCFrame
	elseif holdingPoint and holdingPoint:IsA("BasePart") then
		return holdingPoint.CFrame * CFrame.new(0, holdingPoint.Size.Y * 0.5 + 3, 0)
	end
	return nil
end

local function getHoldingDoor(source)
	local holdingDoor = source and source:FindFirstChild("HoldingDoor", true)
	if holdingDoor and holdingDoor:IsA("ObjectValue") then
		return holdingDoor.Value
	elseif holdingDoor and (holdingDoor:IsA("Model") or holdingDoor:IsA("BasePart")) then
		return holdingDoor
	end
	return nil
end

local function getHoldingCellGroup(source)
	local groupReference = source and source:FindFirstChild("HoldingCellGroup", true)
	if groupReference and groupReference:IsA("ObjectValue") then
		return groupReference.Value
	elseif groupReference and (groupReference:IsA("Folder") or groupReference:IsA("Model")) then
		return groupReference
	end
	return nil
end

local function getHoldingCells(source)
	local group = getHoldingCellGroup(source)
	if not group then return nil end

	local cells = {}
	for _, cell in ipairs(group:GetChildren()) do
		if cell:IsA("Folder") or cell:IsA("Model") then
			local holdingPoint = cell:FindFirstChild("HoldingPoint", true)
			local holdingDoor = cell:FindFirstChild("HoldingDoor", true)
			local door = holdingDoor and holdingDoor:IsA("ObjectValue") and holdingDoor.Value
				or holdingDoor
			if (holdingPoint and (holdingPoint:IsA("Attachment") or holdingPoint:IsA("BasePart")))
				and (door and (door:IsA("Model") or door:IsA("BasePart")))
			then
				table.insert(cells, {
					cell = cell,
					holdingPoint = holdingPoint,
					holdingDoor = door,
				})
			end
		end
	end
	return #cells > 0 and cells or nil
end

local function fireState(state, status, details)
	if not state.player.Parent then return end
	details = details or {}
	details.status = status
	details.cargoName = state.job.cargoName
	inspectionChanged:FireClient(state.player, details)
end

local function playDetectionAlarm(folder, player)
	folder:SetAttribute("LastDetectionUserId", player.UserId)
	folder:SetAttribute("LastDetectionAt", workspace:GetServerTimeNow())
	local alarm = folder:FindFirstChild("Alarm", true)
	if alarm and alarm:IsA("Sound") then alarm:Play() end
end

local function resolveDetection(state, sourceId, source, chance)
	if tracked[state.cargo] ~= state or not state.cargo.Parent or not state.player.Parent then return false end
	local enforcement = enforcementFor(state, source)
	local requestedFine = enforcement.fineMultiplier > 0 and math.max(
		Config.MinimumFine,
		math.ceil((state.job.payout or 1) * enforcement.fineMultiplier)
	) or 0
	if source then playDetectionAlarm(source, state.player) end

	enforcementRequested:Fire({
		player = state.player,
		cargo = state.cargo,
		cargoName = state.job.cargoName,
		jobKey = state.cargo:GetAttribute("CargoJobKey"),
		inspectionId = sourceId,
		offenseClass = enforcement.offenseClass,
		policy = enforcement.policy,
		response = enforcement.response,
		jurisdiction = enforcement.jurisdiction,
		holdingCFrame = getHoldingCFrame(source),
		holdingDoor = getHoldingDoor(source),
		holdingCells = getHoldingCells(source),
		custodyDuration = source and source:GetAttribute("CustodyDuration"),
	})

	local reason = enforcement.response == "Fine"
		and "Contraband detected and confiscated."
		or string.format(
			"Contraband detected and confiscated. %s response requested by %s.",
			enforcement.response,
			enforcement.jurisdiction
		)
	local actualFine = state.onDetected({
		reason = reason,
		fine = requestedFine,
		inspectionId = sourceId,
		offenseClass = enforcement.offenseClass,
		response = enforcement.response,
		jurisdiction = enforcement.jurisdiction,
	})
	fireState(state, "Detected", {
		inspectionId = sourceId,
		detectionChance = chance,
		fine = actualFine or requestedFine,
		offenseClass = enforcement.offenseClass,
		response = enforcement.response,
		jurisdiction = enforcement.jurisdiction,
	})
	return true
end

local function beginZoneInspection(state, zone, folder)
	if tracked[state.cargo] ~= state then return end
	local sourceId = inspectionId(folder)
	if state.inspectedBy[sourceId] then return end
	state.inspectedBy[sourceId] = true

	local strength = math.clamp(
		numberAttribute(folder, "ScannerStrength", Config.DefaultScannerStrength),
		0,
		1
	)
	local chance = math.clamp(state.severity * strength, 0, Config.MaximumDetectionChance)
	local delaySeconds = math.max(numberAttribute(folder, "ScanDelay", Config.DefaultScanDelay), 0)
	fireState(state, "Scanning", {
		inspectionId = sourceId,
		duration = delaySeconds,
		detectionChance = chance,
	})

	task.delay(delaySeconds, function()
		if tracked[state.cargo] ~= state or not state.cargo.Parent then return end
		if math.random() < chance then
			resolveDetection(state, sourceId, folder, chance)
		else
			fireState(state, "Passed", {
				inspectionId = sourceId,
				detectionChance = chance,
			})
		end
	end)
end

local function bindZone(zone, folder)
	if inspectionZones[zone] then return end
	inspectionZones[zone] = folder
	for cargo in pairs(tracked) do zone:TrackItem(cargo) end
	zone:OnItemEntered(function(item)
		local state = tracked[item]
		if state then beginZoneInspection(state, zone, folder) end
	end)
end

Zones:OnTypeLoaded(Config.ZoneType, bindZone)

function ContrabandInspectionService:Register(player, cargo, job, onDetected)
	self:Unregister(cargo)
	local severity = getContrabandSeverity(job)
	if not severity then return false end

	local state = {
		player = player,
		cargo = cargo,
		job = job,
		severity = severity,
		onDetected = onDetected,
		inspectedBy = {},
	}
	tracked[cargo] = state
	cargo:SetAttribute("CargoContrabandSignature", severity)
	cargo:SetAttribute("CargoContrabandClass", job.contrabandClass or Config.DefaultOffenseClass)
	for zone in pairs(inspectionZones) do zone:TrackItem(cargo) end
	return true
end

function ContrabandInspectionService:Unregister(cargo)
	if not tracked[cargo] then return end
	tracked[cargo] = nil
	for zone in pairs(inspectionZones) do zone:UntrackItem(cargo) end
end

function ContrabandInspectionService:HasCarriedContrabandCargo(player)
	for cargo, state in pairs(tracked) do
		if state.player == player and cargo.Parent and cargo:GetAttribute("HeldBy") == player.Name then
			return true
		end
	end
	return false
end

function ContrabandInspectionService:ResolveCarriedDetection(player, sourceId, sourceModel)
	for cargo, state in pairs(tracked) do
		if state.player == player and cargo.Parent and cargo:GetAttribute("HeldBy") == player.Name then
			sourceId = tostring(sourceId)
			if state.inspectedBy[sourceId] then return false end
			state.inspectedBy[sourceId] = true
			return resolveDetection(state, sourceId, sourceModel, 1)
		end
	end
	return false
end

Players.PlayerRemoving:Connect(function(player)
	for cargo, state in pairs(tracked) do
		if state.player == player then ContrabandInspectionService:Unregister(cargo) end
	end
end)

return ContrabandInspectionService
