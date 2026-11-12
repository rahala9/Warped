--[[
    DockManager_Client.lua
    Place in: StarterPlayer > StarterPlayerScripts  (LocalScript)
    Three dock states handled:
      isNPCShip  → show cargo contracts UI
      hasShip (player's own) → show undock-only panel
      empty  → show ship fleet selection UI
]]
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))

-- ── Bindable for HUD refresh ──────────────────────────────────────────────────
-- CargoHUD listens to this to immediately refresh when a job is accepted
local cargoJobAccepted = ReplicatedStorage:FindFirstChild("CargoJobAccepted")
if not cargoJobAccepted then
	cargoJobAccepted = Instance.new("BindableEvent")
	cargoJobAccepted.Name   = "CargoJobAccepted"
	cargoJobAccepted.Parent = ReplicatedStorage
end

-- ── Remotes ───────────────────────────────────────────────────────────────────
local Remotes           = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DockRemotes")
local RE_OpenDockUI     = Remotes:WaitForChild("OpenDockUI")
local RF_GetDockState   = Remotes:WaitForChild("GetDockState")
local RF_GetOwnedShips  = Remotes:WaitForChild("GetOwnedShips")
local RF_SpawnShip      = Remotes:WaitForChild("SpawnShip")
local RF_DespawnShip    = Remotes:WaitForChild("DespawnShip")
local RF_GetCargoJobs   = Remotes:WaitForChild("GetCargoJobs")
local RF_AcceptCargoJob = Remotes:WaitForChild("AcceptCargoJob")

-- ── UI Module ─────────────────────────────────────────────────────────────────
local DockUI = require(script.Parent:WaitForChild("DockManagerUI"))

-- ── Main Handler ──────────────────────────────────────────────────────────────
RE_OpenDockUI.OnClientEvent:Connect(function(dockId)
	local state, err = RF_GetDockState:InvokeServer(dockId)
	if not state then
		warn("[DockManager Client] Could not get dock state:", err)
		return
	end

	-- ── Case 1: NPC cargo ship is docked → show cargo contracts ───────────────
	if state.isNPCShip then
		local jobs, jobErr = RF_GetCargoJobs:InvokeServer(dockId)
		if not jobs then
			DockUI:ShowNotification("✗ Could not fetch cargo jobs: " .. tostring(jobErr), false)
			return
		end

		-- Calculate seconds remaining before ship departs
		local timeRemaining = 0
		if state.dockDuration and state.dockDuration > 0
			and state.dockedAt and state.dockedAt > 0 then
			timeRemaining = math.max(0, math.floor(
				state.dockDuration - (tick() - state.dockedAt)
				))
		end

		DockUI:ShowCargoUI({
			dockId         = dockId,
			shipName       = state.shipName,
			jobs           = jobs,
			timeRemaining  = timeRemaining,
			slotsRemaining = state.slotsRemaining or 0,
			cargoSlots     = state.cargoSlots or 1,
			onAccept = function(jobId)
				local ok, msg = RF_AcceptCargoJob:InvokeServer(dockId, jobId)
				DockUI:ShowNotification(ok and "✓ " .. msg or "✗ " .. msg, ok)
				if ok then
					-- Notify CargoHUD to refresh immediately
					cargoJobAccepted:Fire()
					task.delay(1.5, function() DockUI:Close() end)
				end
			end,
			onClose = function() DockUI:Close() end,
		})

		-- ── Case 2: Player's own ship is docked → undock only ────────────────────
	elseif state.hasShip then
		local canUndock = state.ownedByMe
		DockUI:ShowOccupiedUI({
			dockId    = dockId,
			shipName  = state.shipName,
			ownedByMe = canUndock,
			onDespawn = canUndock and function()
				local ok, msg = RF_DespawnShip:InvokeServer(dockId)
				DockUI:ShowNotification(ok and "✓ " .. msg or "✗ " .. msg, ok)
				if ok then task.delay(1.5, function() DockUI:Close() end) end
			end or nil,
			onClose = function() DockUI:Close() end,
		})

		-- ── Case 3: Dock is empty → show ship fleet selection ────────────────────
	else
		local ships = RF_GetOwnedShips:InvokeServer()
		DockUI:ShowShipSelectUI({
			dockId  = dockId,
			ships   = ships,
			onSpawn = function(shipName)
				local ok, msg = RF_SpawnShip:InvokeServer(dockId, shipName)
				DockUI:ShowNotification(ok and "✓ " .. msg or "✗ " .. msg, ok)
				if ok then task.delay(1.5, function() DockUI:Close() end) end
			end,
			onClose = function() DockUI:Close() end,
		})
	end
end)