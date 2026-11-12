local Players = game:GetService("Players")
local Debris =game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local CargoFolder = SharedClientAssets:WaitForChild("Cargo")

local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

local CargoDeliveryManager = {}

-- ── Config ────────────────────────────────────────────────────────────────────
local DEFAULT_CARGO_SLOTS = 4

-- ── State ─────────────────────────────────────────────────────────────────────
local playerJobs = {}
local jobConnections = {}  -- jobConnections[userId][jobId] = connection
local dockStatesRef = nil

-- ── Init ──────────────────────────────────────────────────────────────────────
function CargoDeliveryManager:Init(dockStates)
	dockStatesRef = dockStates
	print("[CargoDeliveryManager] Initialized.")
end

-- ── Internal Helpers ──────────────────────────────────────────────────────────
local function getJobs(userId)
	if not playerJobs[userId] then
		playerJobs[userId] = {}
	end
	return playerJobs[userId]
end

local function unclaimFromDock(dockId, jobId)
	if not dockStatesRef then return end
	local dock = dockStatesRef[dockId]
	if dock and dock.claimedJobs then
		dock.claimedJobs[jobId] = nil
		print(string.format("[CargoDeliveryManager] Job %d at dock '%s' returned to pool.",
			jobId, dockId))
	end
end

local function disconnectJob(userId, jobId)
	if jobConnections[userId] and jobConnections[userId][jobId] then
		jobConnections[userId][jobId]:Disconnect()
		jobConnections[userId][jobId] = nil
	end
end

-- ── Prune Expired Jobs ────────────────────────────────────────────────────────
function CargoDeliveryManager:PruneExpired(userId)
	local jobs = getJobs(userId)
	local now  = tick()
	local kept = {}

	for _, entry in ipairs(jobs) do
		if now < entry.expiresAt then
			table.insert(kept, entry)
		else
			unclaimFromDock(entry.dockId, entry.jobId)
			disconnectJob(userId, entry.jobId)
			print(string.format("[CargoDeliveryManager] Job '%s' expired for user %d.",
				entry.job and entry.job.cargoName or "?", userId))
		end
	end

	playerJobs[userId] = kept
end

-- ── Get Player's Ship Cargo Slots ─────────────────────────────────────────────
function CargoDeliveryManager:GetCargoSlots(player)
	if not dockStatesRef then return DEFAULT_CARGO_SLOTS end

	for _, dock in pairs(dockStatesRef) do
		if dock.spawnedShip and dock.spawnedBy == player.UserId then
			local slots = dock.spawnedShip:GetAttribute("CargoSlots")
			if slots and type(slots) == "number" and slots > 0 then
				return math.floor(slots)
			end
		end
	end

	return DEFAULT_CARGO_SLOTS
end

-- ── Check If Player Can Accept Another Job ────────────────────────────────────
function CargoDeliveryManager:CanAcceptJob(player)
	self:PruneExpired(player.UserId)
	local slots  = self:GetCargoSlots(player)
	local active = #getJobs(player.UserId)

	if active >= slots then
		return false, string.format(
			"Cargo hold full. (%d/%d slots used.) Deliver your current jobs first.",
			active, slots
		)
	end

	return true, nil
end

function GetFreeCargoSlot(dockId)
	
	local dock = workspace.Areas.StarhopStation.Docks[dockId]
	
	for _, cargoSlot in pairs(dock.SpawnAnchor:GetChildren()) do
		if (not cargoSlot:GetAttribute("Occupied")) then
			return cargoSlot
		end
	end
end

-- ── Add a Job ─────────────────────────────────────────────────────────────────
function CargoDeliveryManager:AddJob(player, dockId, jobId, job)
	self:PruneExpired(player.UserId)

	local expiresAt = tick() + (job.timeLimit * 60)
	table.insert(getJobs(player.UserId), {
		dockId    = dockId,
		jobId     = jobId,
		expiresAt = expiresAt,
		job       = job,
	})

	print(string.format("[CargoDeliveryManager] User %d accepted '%s' → expires in %d min.",
		player.UserId, job.cargoName, job.timeLimit))

	-- Spawn cargo model
	local cargoModel = CargoFolder:FindFirstChild(job.cargoModel)
	if cargoModel then
		cargoModel = cargoModel:Clone()
		local cargoSlot = GetFreeCargoSlot(dockId)
		if (not cargoSlot) then
			warn("No free cargo slot available for dockId:", dockId)
			return
		end
		cargoSlot:SetAttribute("Occupied", true)
		cargoModel:PivotTo(cargoSlot.WorldCFrame)
		cargoModel.PrimaryPart:SetAttribute("OwnerName", player.Name)
		cargoModel.PrimaryPart:SetAttribute("OwnerId", player.UserId)
		cargoModel.PrimaryPart:SetAttribute("CargoSlot", cargoSlot.Name)
		cargoModel.PrimaryPart:SetAttribute("CargoDockId", dockId)
		cargoModel.PrimaryPart:SetAttribute("CargoJobId", jobId)
		cargoModel.PrimaryPart.HUD.Frame.CargoNameLabel.Text = job.cargoName
		cargoModel.PrimaryPart.HUD.Frame.OwnerNameLabel.Text = player.Name
		cargoModel.Parent = workspace
	end

	-- Connect zone delivery check
	Zones:OnLoaded(job.zoneName, function(zone)
		local connection
		connection = zone:OnPlayerEntered(function(enteredPlayer)
			if enteredPlayer ~= player then return end

			-- Find this specific job in the player's active list
			local jobs = getJobs(player.UserId)
			local matchedEntry = nil
			for _, entry in ipairs(jobs) do
				if entry.dockId == dockId and entry.jobId == jobId then
					matchedEntry = entry
					break
				end
			end

			-- Job not found (already delivered, expired, or cancelled)
			if not matchedEntry then
				disconnectJob(player.UserId, jobId)
				return
			end

			-- Check job hasn't expired
			if tick() >= matchedEntry.expiresAt then
				print(string.format("[CargoDeliveryManager] Job '%s' expired for %s on arrival.",
					job.cargoName, player.Name))
				self:RemoveJob(player, dockId, jobId, true)
				disconnectJob(player.UserId, jobId)
				return
			end

			-- Calculate reward with time bonus
			local timeLeft  = matchedEntry.expiresAt - tick()
			local timeBonus = math.floor((timeLeft / (job.timeLimit * 60)) * job.payout * 0.2)
			local totalReward = job.payout + timeBonus

			MessagePlayerEvent:FireClient(player, "Delivered "..job.cargoName.." Time Bonus: ₵"..timeBonus)

			InventoryFunctions.AddMoney(player,totalReward)

			-- Clean up cargo model
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj:IsA("Model") and obj.PrimaryPart then
					if obj.PrimaryPart:GetAttribute("OwnerId") == player.UserId
						and obj.PrimaryPart:GetAttribute("CargoJobId") == jobId then
						Debris:AddItem(obj,10)
						InventoryFunctions.RemoveTempHoldLive(player,obj.Name,obj) 
					end
				end
			end
			
			self:RemoveJob(player, dockId, jobId, false)
			disconnectJob(player.UserId, jobId)
		end)

		-- Store the connection keyed by userId + jobId
		if not jobConnections[player.UserId] then
			jobConnections[player.UserId] = {}
		end
		jobConnections[player.UserId][jobId] = connection
	end)
end

-- ── Remove a Job (complete or cancel) ────────────────────────────────────────
function CargoDeliveryManager:RemoveJob(player, dockId, jobId, unclaim)
	self:PruneExpired(player.UserId)
	local jobs = getJobs(player.UserId)
	local kept = {}

	for _, entry in ipairs(jobs) do
		if entry.dockId == dockId and entry.jobId == jobId then
			if unclaim then
				unclaimFromDock(dockId, jobId)
			end
		else
			table.insert(kept, entry)
		end
	end

	playerJobs[player.UserId] = kept
end

-- ── Get Active Jobs ───────────────────────────────────────────────────────────
function CargoDeliveryManager:GetActiveJobs(player)
	self:PruneExpired(player.UserId)
	local jobs   = getJobs(player.UserId)
	local result = {}
	local now    = tick()

	for _, entry in ipairs(jobs) do
		table.insert(result, {
			dockId    = entry.dockId,
			jobId     = entry.jobId,
			job       = entry.job,
			expiresAt = entry.expiresAt,
			timeLeft  = math.max(0, math.floor(entry.expiresAt - now)),
		})
	end

	return result
end

-- ── Slot Info (for UI) ────────────────────────────────────────────────────────
function CargoDeliveryManager:GetSlotInfo(player)
	self:PruneExpired(player.UserId)
	local slots     = self:GetCargoSlots(player)
	local used      = #getJobs(player.UserId)
	local remaining = math.max(0, slots - used)

	return {
		cargoSlots     = slots,
		slotsUsed      = used,
		slotsRemaining = remaining,
	}
end

-- ── Player Cleanup ────────────────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	-- Disconnect all zone listeners
	if jobConnections[userId] then
		for _, conn in pairs(jobConnections[userId]) do
			conn:Disconnect()
		end
		jobConnections[userId] = nil
	end

	-- Return all active jobs to their dock pools
	local jobs = getJobs(userId)
	for _, entry in ipairs(jobs) do
		unclaimFromDock(entry.dockId, entry.jobId)
	end

	playerJobs[userId] = nil
	print(string.format("[CargoDeliveryManager] Cleaned up jobs for user %d.", userId))
end)

return CargoDeliveryManager