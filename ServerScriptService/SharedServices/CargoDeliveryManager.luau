local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local CargoFolder = SharedClientAssets:WaitForChild("Cargo")
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ShipFunctions = require(ServerScriptService.Data.DataShipFunctions)
local CargoRiskService = require(
	ServerScriptService:WaitForChild("CargoRiskSystem"):WaitForChild("CargoRiskService")
)
local CargoRiskConfig = require(
	ReplicatedStorage:WaitForChild("CargoRiskSystem"):WaitForChild("Config")
)
local ContrabandInspectionService = require(
	ServerScriptService:WaitForChild("CargoInspectionSystem"):WaitForChild("ContrabandInspectionService")
)
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

local CargoDeliveryManager = {}

local MAX_ACTIVE_CARGO_CONTRACTS = 4
local SHIP_OWNER_ATTRIBUTE = "OwnerUserId"
local CARGO_ATTACHMENT_NAME = "CargoAttachment"

local playerJobs = {}
local jobTracking = {}
local dockStatesRef = nil
local configuredPrompts = setmetatable({}, { __mode = "k" })
local cargoInteractionLocked = setmetatable({}, { __mode = "k" })

local function jobKey(dockId, jobId)
	return tostring(dockId) .. ":" .. tostring(jobId)
end

local function getJobs(userId)
	if not playerJobs[userId] then
		playerJobs[userId] = {}
	end
	return playerJobs[userId]
end

local function isCargoAttachment(instance)
	return instance:IsA("Attachment")
		and (instance.Name:sub(1, #CARGO_ATTACHMENT_NAME) == CARGO_ATTACHMENT_NAME
			or instance:GetAttribute("CargoSlot") == true)
end

local function getCargoAttachments(ship)
	local attachments = {}
	if not ship or not ship:IsA("Model") or not ship.PrimaryPart then return attachments end

	-- Cargo mounts intentionally live directly beneath PrimaryPart. Do not scan
	-- the entire ship, where unrelated cockpit/weapon attachments also exist.
	for _, child in ipairs(ship.PrimaryPart:GetChildren()) do
		if isCargoAttachment(child) then
			table.insert(attachments, child)
		end
	end
	table.sort(attachments, function(a, b)
		if a.Name == b.Name then return false end
		return a.Name < b.Name
	end)
	return attachments
end

local function getAttachmentCargo(attachment)
	local loadedCargo = attachment and attachment:FindFirstChild("LoadedCargo")
	if loadedCargo and loadedCargo:IsA("ObjectValue") then
		local cargo = loadedCargo.Value
		if cargo and cargo:IsA("Model") and cargo:IsDescendantOf(workspace) then return cargo end
		loadedCargo.Value = nil
	end
	return nil
end

local function getMountedCargo(ship)
	for _, attachment in ipairs(getCargoAttachments(ship)) do
		local cargo = getAttachmentCargo(attachment)
		if cargo then return cargo end
	end
	return nil
end

local function updateShipPrompt(ship)
	local hasCargo = false
	for _, attachment in ipairs(getCargoAttachments(ship)) do
		local attachmentHasCargo = getAttachmentCargo(attachment) ~= nil
		hasCargo = hasCargo or attachmentHasCargo
		local prompt = attachment:FindFirstChild("LoadCargo")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.ActionText = attachmentHasCargo and "Unload Cargo" or "Load Cargo"
			prompt.KeyboardKeyCode = attachmentHasCargo and Enum.KeyCode.Q or Enum.KeyCode.R
		end
	end
	ship:SetAttribute("CargoLoaded", hasCargo)
end

local function findNearestFreeAttachment(ship, worldPosition)
	local nearest = nil
	local nearestDistance = math.huge
	for _, attachment in ipairs(getCargoAttachments(ship)) do
		if not getAttachmentCargo(attachment) then
			local distance = (attachment.WorldPosition - worldPosition).Magnitude
			if distance < nearestDistance then
				nearest = attachment
				nearestDistance = distance
			end
		end
	end
	return nearest
end

local function setCargoPhysics(cargo, mounted)
	for _, descendant in ipairs(cargo:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = not mounted
			descendant.CanTouch = not mounted
			descendant.CanQuery = true
			descendant.Massless = mounted
		end
	end
end

local function getCargoPrompt(cargo)
	if not cargo or not cargo.PrimaryPart then return nil end
	return cargo.PrimaryPart:FindFirstChild("TakeTempHoldLive")
		or cargo.PrimaryPart:FindFirstChild("DropTempHoldLive")
end

local function findCarriedJobCargo(player)
	for _, entry in ipairs(getJobs(player.UserId)) do
		local cargo = entry.cargoModel
		if cargo and cargo.Parent and cargo:GetAttribute("HeldBy") == player.Name then return cargo end
	end
	return nil
end

local function clearMountedCargo(cargo)
	if not cargo then return end
	local shipReference = cargo:FindFirstChild("MountedShip")
	local ship = shipReference and shipReference:IsA("ObjectValue") and shipReference.Value or nil
	local constraint = cargo.PrimaryPart and cargo.PrimaryPart:FindFirstChild("CargoMountConstraint")
	if constraint then constraint:Destroy() end
	if shipReference then shipReference:Destroy() end
	cargo:SetAttribute("MountedToShip", nil)
	cargo:SetAttribute("MountedShipOwnerUserId", nil)

	if ship and ship.Parent then
		for _, attachment in ipairs(getCargoAttachments(ship)) do
			local loadedCargo = attachment:FindFirstChild("LoadedCargo")
			if loadedCargo and loadedCargo:IsA("ObjectValue") and loadedCargo.Value == cargo then
				loadedCargo.Value = nil
			end
		end
		updateShipPrompt(ship)
	end
end

local function mountCargo(player, ship, cargo)
	if not ShipFunctions.OwnsShip(player, ship.Name) then
		return false, "You do not own this ship."
	end
	local ownerUserId = ship:GetAttribute(SHIP_OWNER_ATTRIBUTE)
	if ownerUserId and ownerUserId ~= player.UserId then return false, "You do not own this ship." end
	ship:SetAttribute(SHIP_OWNER_ATTRIBUTE, player.UserId)
	ship:SetAttribute("OwnerName", player.Name)
	if not cargo or cargo:GetAttribute("HeldBy") ~= player.Name then
		return false, "Carry one of your active delivery crates to load it."
	end
	if cargo:GetAttribute("OwnerUserId") ~= player.UserId then
		return false, "That cargo does not belong to you."
	end

	local cargoPart = cargo.PrimaryPart
	if not cargoPart then return false, "The cargo model has no PrimaryPart." end
	local attachment = findNearestFreeAttachment(ship, cargoPart.Position)
	if not attachment then return false, "All of this ship's cargo mounts are occupied." end

	InventoryFunctions.RemoveTempHoldLive(player, cargo.Name, cargo)
	cargo:SetAttribute("MountedToShip", ship.Name)
	cargo:SetAttribute("MountedShipOwnerUserId", player.UserId)
	setCargoPhysics(cargo, true)

	local cargoAttachment = cargoPart:FindFirstChild("CargoMountAttachment")
	if not cargoAttachment then
		cargoAttachment = Instance.new("Attachment")
		cargoAttachment.Name = "CargoMountAttachment"
		cargoAttachment.Parent = cargoPart
	end
	-- CargoAttachment points outward from this ship on its +Z side. Put the
	-- mount on the cargo's -Z face so its center is offset outside the hull.
	cargoAttachment.CFrame = CFrame.new(0, 0, -cargoPart.Size.Z * 0.5)
	cargoPart.CFrame = attachment.WorldCFrame * cargoAttachment.CFrame:Inverse()

	local constraint = Instance.new("RigidConstraint")
	constraint.Name = "CargoMountConstraint"
	constraint.Attachment0 = attachment
	constraint.Attachment1 = cargoAttachment
	constraint.Parent = cargoPart

	local shipReference = Instance.new("ObjectValue")
	shipReference.Name = "MountedShip"
	shipReference.Value = ship
	shipReference.Parent = cargo

	local loadedCargo = attachment:FindFirstChild("LoadedCargo")
	if not loadedCargo then
		loadedCargo = Instance.new("ObjectValue")
		loadedCargo.Name = "LoadedCargo"
		loadedCargo.Parent = attachment
	end
	loadedCargo.Value = cargo

	local cargoPrompt = getCargoPrompt(cargo)
	if cargoPrompt then cargoPrompt.Enabled = false end
	updateShipPrompt(ship)
	return true, "Cargo loaded."
end

local function unmountCargo(player, ship, cargo)
	if not ShipFunctions.OwnsShip(player, ship.Name)
		or ship:GetAttribute(SHIP_OWNER_ATTRIBUTE) ~= player.UserId
	then
		return false, "You do not own this ship."
	end
	if not cargo then return false, "No cargo is loaded." end
	if cargo:GetAttribute("OwnerUserId") ~= player.UserId then
		return false, "That cargo does not belong to you."
	end

	clearMountedCargo(cargo)
	local cargoPrompt = getCargoPrompt(cargo)
	if cargoPrompt then
		cargoPrompt.Name = "DropTempHoldLive"
		cargoPrompt.ActionText = "Drop"
		cargoPrompt.Style = Enum.ProximityPromptStyle.Custom
		cargoPrompt.KeyboardKeyCode = Enum.KeyCode.Q
		cargoPrompt.Enabled = true
	end
	InventoryFunctions.AddTempHoldLive(player, cargo.Name, cargo)
	return true, "Cargo unloaded."
end

function CargoDeliveryManager:ConfigureShip(ship)
	if not ship or not ship:IsA("Model") then return false end

	local attachments = getCargoAttachments(ship)
	if #attachments == 0 then
		warn("[CargoDeliveryManager] Player ship has no CargoAttachment:", ship:GetFullName())
		return false
	end

	ship:SetAttribute("PhysicalCargoSlots", #attachments)
	for _, attachment in ipairs(attachments) do
		local cargoAttachment = attachment
		local loadedCargo = cargoAttachment:FindFirstChild("LoadedCargo")
		if not loadedCargo then
			loadedCargo = Instance.new("ObjectValue")
			loadedCargo.Name = "LoadedCargo"
			loadedCargo.Parent = cargoAttachment
		end

		local prompt = cargoAttachment:FindFirstChild("LoadCargo")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "LoadCargo"
			prompt.ObjectText = ship.Name .. " Cargo Mount"
			prompt.HoldDuration = 0.35
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = cargoAttachment
		end
		-- Let Roblox choose the best on-screen cargo mount for each key. With
		-- AlwaysShow, every free mount rendered an identical R prompt at once.
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.Enabled = true

		if configuredPrompts[prompt] then continue end
		configuredPrompts[prompt] = true
		prompt.Triggered:Connect(function(triggeringPlayer)
			-- Changing Q/Unload into R/Load during the same input can otherwise
			-- cause a second activation and immediately remount the cargo.
			if cargoInteractionLocked[ship] then return end
			cargoInteractionLocked[ship] = true
			task.delay(0.6, function()
				cargoInteractionLocked[ship] = nil
			end)

			local ownerUserId = ship:GetAttribute(SHIP_OWNER_ATTRIBUTE)
			if not ShipFunctions.OwnsShip(triggeringPlayer, ship.Name) then
				MessagePlayerEvent:FireClient(triggeringPlayer, "You do not own this ship.")
				return
			end
			if ownerUserId and ownerUserId ~= triggeringPlayer.UserId then
				MessagePlayerEvent:FireClient(triggeringPlayer, "You do not own this ship.")
				return
			end
			if not ownerUserId then
				ship:SetAttribute(SHIP_OWNER_ATTRIBUTE, triggeringPlayer.UserId)
				ship:SetAttribute("OwnerName", triggeringPlayer.Name)
			end

			local cargo = getAttachmentCargo(cargoAttachment)
			local _, message
			if cargo then
				_, message = unmountCargo(triggeringPlayer, ship, cargo)
			else
				_, message = mountCargo(triggeringPlayer, ship, findCarriedJobCargo(triggeringPlayer))
			end
			MessagePlayerEvent:FireClient(triggeringPlayer, message)
		end)
	end

	updateShipPrompt(ship)
	return true
end

function CargoDeliveryManager:ConfigurePlayerShip(player, ship)
	if not ship or not ship:IsA("Model") then return false end
	ship:SetAttribute(SHIP_OWNER_ATTRIBUTE, player.UserId)
	ship:SetAttribute("OwnerName", player.Name)
	return self:ConfigureShip(ship)
end

function CargoDeliveryManager:ShipHasCargo(ship)
	return getMountedCargo(ship) ~= nil
end

function CargoDeliveryManager:SetCargoPromptEnabled(ship, enabled)
	for _, attachment in ipairs(getCargoAttachments(ship)) do
		local prompt = attachment:FindFirstChild("LoadCargo")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = enabled == true
		end
	end
end

function CargoDeliveryManager:Init(dockStates)
	dockStatesRef = dockStates
	print("[CargoDeliveryManager] Initialized.")
end

local function unclaimFromDock(dockId, jobId)
	if not dockStatesRef then return end
	local dock = dockStatesRef[dockId]
	if dock and dock.claimedJobs then dock.claimedJobs[jobId] = nil end
end

local function disconnectTracking(userId, dockId, jobId, cargo)
	local userTracking = jobTracking[userId]
	local key = jobKey(dockId, jobId)
	local tracking = userTracking and userTracking[key]
	if not tracking then return end
	if tracking.zone and cargo then tracking.zone:UntrackItem(cargo) end
	if tracking.itemConnection then tracking.itemConnection:Disconnect() end
	if tracking.loadedConnection then tracking.loadedConnection:Disconnect() end
	userTracking[key] = nil
	if not next(userTracking) then jobTracking[userId] = nil end
end

local function releaseDockSlot(cargo)
	if not cargo or not cargo.PrimaryPart then return end
	local cargoPart = cargo.PrimaryPart
	local dockId = cargoPart:GetAttribute("CargoDockId")
	local slotName = cargoPart:GetAttribute("CargoSlot")
	if not dockId or not slotName then return end

	local areas = workspace:FindFirstChild("Areas")
	local station = areas and areas:FindFirstChild("StarhopStation")
	local docks = station and station:FindFirstChild("Docks")
	local dock = docks and docks:FindFirstChild(dockId)
	local spawnAnchor = dock and dock:FindFirstChild("SpawnAnchor")
	local slot = spawnAnchor and spawnAnchor:FindFirstChild(slotName)
	if slot then slot:SetAttribute("Occupied", false) end
	cargoPart:SetAttribute("CargoDockId", nil)
	cargoPart:SetAttribute("CargoSlot", nil)
end

local function cleanupCargo(player, entry)
	local cargo = entry.cargoModel
	if not cargo then return end
	CargoRiskService:Unregister(cargo)
	ContrabandInspectionService:Unregister(cargo)
	disconnectTracking(entry.userId, entry.dockId, entry.jobId, cargo)
	releaseDockSlot(cargo)
	clearMountedCargo(cargo)

	if cargo.Parent and cargo:GetAttribute("HeldBy") and player then
		pcall(function()
			InventoryFunctions.RemoveTempHoldLive(player, cargo.Name, cargo)
		end)
	end
	if cargo.Parent then cargo:Destroy() end
	entry.cargoModel = nil
end

local function removeEntry(userId, dockId, jobId)
	local kept = {}
	for _, entry in ipairs(getJobs(userId)) do
		if entry.dockId ~= dockId or entry.jobId ~= jobId then table.insert(kept, entry) end
	end
	playerJobs[userId] = kept
end

function CargoDeliveryManager:PruneExpired(userId)
	local now = workspace:GetServerTimeNow()
	local player = Players:GetPlayerByUserId(userId)
	local kept = {}
	for _, entry in ipairs(getJobs(userId)) do
		if now < entry.expiresAt then
			table.insert(kept, entry)
		else
			cleanupCargo(player, entry)
			unclaimFromDock(entry.dockId, entry.jobId)
			if player then
				MessagePlayerEvent:FireClient(player, "Cargo contract expired: " .. entry.job.cargoName)
			end
		end
	end
	playerJobs[userId] = kept
end

function CargoDeliveryManager:GetCargoSlots(player)
	return MAX_ACTIVE_CARGO_CONTRACTS
end

function CargoDeliveryManager:CanAcceptJob(player)
	self:PruneExpired(player.UserId)
	local slots = self:GetCargoSlots(player)
	local active = #getJobs(player.UserId)
	if active >= slots then
		return false, string.format("Cargo capacity full. (%d/%d jobs active.)", active, slots)
	end
	return true, nil
end

local function getFreeCargoSlot(dockId)
	local areas = workspace:FindFirstChild("Areas")
	local station = areas and areas:FindFirstChild("StarhopStation")
	local docks = station and station:FindFirstChild("Docks")
	local dock = docks and docks:FindFirstChild(dockId)
	local spawnAnchor = dock and dock:FindFirstChild("SpawnAnchor")
	if not spawnAnchor then return nil end
	for _, cargoSlot in ipairs(spawnAnchor:GetChildren()) do
		if cargoSlot:IsA("Attachment") and not cargoSlot:GetAttribute("Occupied") then return cargoSlot end
	end
	return nil
end

local function findEntry(userId, dockId, jobId)
	for _, entry in ipairs(getJobs(userId)) do
		if entry.dockId == dockId and entry.jobId == jobId then return entry end
	end
	return nil
end

local function failEntry(player, entry, reason, requestedFine)
	if not findEntry(player.UserId, entry.dockId, entry.jobId) then return 0 end
	local actualFine = 0
	if typeof(requestedFine) == "number" and requestedFine > 0 then
		actualFine = math.min(math.ceil(requestedFine), InventoryFunctions.GetTotalMoney(player) or 0)
		if actualFine > 0 then InventoryFunctions.RemoveMoney(player, actualFine) end
	end

	local fineText = actualFine > 0 and string.format(" Fine: ₵%d.", actualFine) or ""
	MessagePlayerEvent:FireClient(
		player,
		"Cargo contract failed: " .. entry.job.cargoName .. ". " .. reason .. fineText,
		nil,
		nil,
		nil,
		nil,
		nil,
		10
	)
	cleanupCargo(player, entry)
	removeEntry(player.UserId, entry.dockId, entry.jobId)
	unclaimFromDock(entry.dockId, entry.jobId)
	return actualFine
end

local function getRiskPreservation(cargo, riskName)
	if not cargo then return 1 end
	if riskName == "Fragile" then
		-- Stability is a binary threshold: surviving fragile cargo earns its
		-- entire premium regardless of how close it came to breaking.
		return 1
	elseif riskName == "Biohazardous" then
		local containment = cargo:GetAttribute("CargoContainment")
		if typeof(containment) == "number" then
			return math.clamp(containment / CargoRiskConfig.Biohazardous.MaximumContainment, 0, 1)
		end
	end

	-- Event risks such as Contraband retain their premium if the job survives
	-- their failure condition and reaches the destination.
	return 1
end

local function calculatePreservedRiskPremium(job, cargo)
	if typeof(job.riskPremiums) ~= "table" then
		return math.round((job.riskPremium or 0) * getRiskPreservation(cargo, "Fragile"))
	end

	local preserved = 0
	for riskName, premium in pairs(job.riskPremiums) do
		if typeof(premium) == "number" then
			preserved += premium * getRiskPreservation(cargo, riskName)
		end
	end
	return math.round(preserved)
end

local function completeJob(player, entry)
	if not findEntry(player.UserId, entry.dockId, entry.jobId) then return end
	if workspace:GetServerTimeNow() >= entry.expiresAt then
		CargoDeliveryManager:PruneExpired(player.UserId)
		return
	end

	local job = entry.job
	local riskPremium = job.riskPremium or 0
	local basePayout = if job.safePayout ~= nil
		then job.safePayout + (job.distancePayout or 0)
		else math.max(job.payout - riskPremium, 1)
	local preservedRiskPremium = calculatePreservedRiskPremium(job, entry.cargoModel)
	local adjustedPayout = basePayout + preservedRiskPremium
	local timeLeft = entry.expiresAt - workspace:GetServerTimeNow()
	local remainingFraction = math.clamp(timeLeft / (job.timeLimit * 60), 0, 1)
	local timeBonus = math.max(math.round(remainingFraction * adjustedPayout * 0.2), 1)
	local totalReward = adjustedPayout + timeBonus
	InventoryFunctions.AddMoney(player, totalReward)
	local riskBreakdown = riskPremium > 0
		and string.format(", preserved risk premium ₵%d/₵%d", preservedRiskPremium, riskPremium)
		or ""
	MessagePlayerEvent:FireClient(player, string.format(
		"Delivered %s — ₵%d (base ₵%d%s, time bonus ₵%d)",
		job.cargoName,
		totalReward,
		basePayout,
		riskBreakdown,
		timeBonus
	))

	cleanupCargo(player, entry)
	removeEntry(player.UserId, entry.dockId, entry.jobId)
end

function CargoDeliveryManager:AddJob(player, dockId, jobId, job)
	self:PruneExpired(player.UserId)
	local template = CargoFolder:FindFirstChild(job.cargoModel)
	if not template or not template:IsA("Model") or not template.PrimaryPart then
		return false, "Cargo template is missing or has no PrimaryPart."
	end
	local cargoSlot = getFreeCargoSlot(dockId)
	if not cargoSlot then return false, "No cargo pickup slot is currently available." end

	local cargo = template:Clone()
	cargo.Name = job.cargoModel
	cargo.Parent = workspace
	cargo:PivotTo(cargoSlot.WorldCFrame)
	cargoSlot:SetAttribute("Occupied", true)

	local key = jobKey(dockId, jobId)
	cargo:SetAttribute("OwnerUserId", player.UserId)
	cargo:SetAttribute("CargoJobKey", key)
	cargo.PrimaryPart:SetAttribute("OwnerName", player.Name)
	cargo.PrimaryPart:SetAttribute("OwnerId", player.UserId)
	cargo.PrimaryPart:SetAttribute("OwnerUserId", player.UserId)
	cargo.PrimaryPart:SetAttribute("CargoSlot", cargoSlot.Name)
	cargo.PrimaryPart:SetAttribute("CargoDockId", dockId)
	cargo.PrimaryPart:SetAttribute("CargoJobId", jobId)
	cargo.PrimaryPart:SetAttribute("CargoJobKey", key)

	local hud = cargo.PrimaryPart:FindFirstChild("HUD")
	local frame = hud and hud:FindFirstChild("Frame")
	local cargoLabel = frame and frame:FindFirstChild("CargoNameLabel")
	local ownerLabel = frame and frame:FindFirstChild("OwnerNameLabel")
	if cargoLabel then cargoLabel.Text = job.cargoName end
	if ownerLabel then ownerLabel.Text = player.Name end

	local entry = {
		userId = player.UserId,
		dockId = dockId,
		jobId = jobId,
		expiresAt = workspace:GetServerTimeNow() + (job.timeLimit * 60),
		job = job,
		cargoModel = cargo,
	}
	table.insert(getJobs(player.UserId), entry)

	jobTracking[player.UserId] = jobTracking[player.UserId] or {}
	local tracking = {}
	jobTracking[player.UserId][key] = tracking
	tracking.loadedConnection = Zones:OnLoaded(job.zoneName, function(zone)
		tracking.zone = zone
		zone:TrackItem(cargo)
		tracking.itemConnection = zone:OnItemEntered(function(enteredItem)
			if enteredItem == cargo then completeJob(player, entry) end
		end)
	end)

	CargoRiskService:Register(player, cargo, job, function(reason)
		failEntry(player, entry, reason)
	end)
	ContrabandInspectionService:Register(player, cargo, job, function(result)
		return failEntry(player, entry, result.reason, result.fine)
	end)
	return true
end

function CargoDeliveryManager:RemoveJob(player, dockId, jobId, unclaim)
	local entry = findEntry(player.UserId, dockId, jobId)
	if not entry then return end
	cleanupCargo(player, entry)
	removeEntry(player.UserId, dockId, jobId)
	if unclaim then unclaimFromDock(dockId, jobId) end
end

function CargoDeliveryManager:CancelJob(player, dockId, jobId)
	local entry = findEntry(player.UserId, dockId, jobId)
	if not entry then return false, "That cargo contract is no longer active." end

	local cargoName = entry.job.cargoName
	cleanupCargo(player, entry)
	removeEntry(player.UserId, dockId, jobId)
	unclaimFromDock(dockId, jobId)
	MessagePlayerEvent:FireClient(player, "Cargo contract cancelled: " .. cargoName)
	return true, "Contract cancelled."
end

function CargoDeliveryManager:GetActiveJobs(player)
	self:PruneExpired(player.UserId)
	local now = workspace:GetServerTimeNow()
	local result = {}
	for _, entry in ipairs(getJobs(player.UserId)) do
		table.insert(result, {
			dockId = entry.dockId,
			jobId = entry.jobId,
			job = entry.job,
			expiresAt = entry.expiresAt,
			timeLeft = math.max(0, math.floor(entry.expiresAt - now)),
			cargoStability = entry.cargoModel and entry.cargoModel:GetAttribute("CargoStability") or nil,
			cargoStabilityLabel = entry.cargoModel and entry.cargoModel:GetAttribute("CargoStabilityLabel") or nil,
			cargoStabilityTriggered = entry.cargoModel and entry.cargoModel:GetAttribute("CargoStabilityTriggered") == true or false,
			cargoContainment = entry.cargoModel and entry.cargoModel:GetAttribute("CargoContainment") or nil,
			cargoContainmentState = entry.cargoModel and entry.cargoModel:GetAttribute("CargoContainmentState") or nil,
			cargoBroken = entry.cargoModel and entry.cargoModel:GetAttribute("CargoBroken") == true or false,
			cargoState = entry.cargoModel and (entry.cargoModel:GetAttribute("MountedToShip") and "Mounted"
				or entry.cargoModel:GetAttribute("HeldBy") and "Carried" or "Waiting") or "Missing",
		})
	end
	return result
end

function CargoDeliveryManager:GetSlotInfo(player)
	self:PruneExpired(player.UserId)
	local slots = self:GetCargoSlots(player)
	local used = #getJobs(player.UserId)
	return {
		cargoSlots = slots,
		slotsUsed = used,
		slotsRemaining = math.max(0, slots - used),
	}
end

Players.PlayerRemoving:Connect(function(player)
	local jobs = table.clone(getJobs(player.UserId))
	for _, entry in ipairs(jobs) do
		cleanupCargo(nil, entry)
		unclaimFromDock(entry.dockId, entry.jobId)
	end
	playerJobs[player.UserId] = nil
	jobTracking[player.UserId] = nil
end)

return CargoDeliveryManager
