--[[
    DockManager_Server.lua
    Place in: ServerScriptService

    Dock states:
      empty      → player can deploy their own ship
      playerShip → player owns the ship, can only undock it (no cargo runs)
      npcShip    → NPC cargo vessel, shows cargo contracts to any nearby player

    To dock an NPC ship from another script:
        local DockManager = require(game.ServerScriptService.DockManager_Server)
        DockManager.dockNPCShip("Dock_01", "CargoHauler_MK2")
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── Dependencies ──────────────────────────────────────────────────────────────
local CargoDeliveryManager = require(game.ServerScriptService:WaitForChild("SharedServices"):WaitForChild("CargoDeliveryManager"))

-- ── Folder References ─────────────────────────────────────────────────────────
local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local ShipsFolder        = SharedClientAssets:WaitForChild("Ships")

-- ── Remotes Setup ─────────────────────────────────────────────────────────────
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes"):FindFirstChild("DockRemotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "DockRemotes"
	Remotes.Parent = ReplicatedStorage
end

local function getOrMakeRemote(className, name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local RF_GetDockState    = getOrMakeRemote("RemoteFunction", "GetDockState")
local RF_GetOwnedShips   = getOrMakeRemote("RemoteFunction", "GetOwnedShips")
local RF_SpawnShip       = getOrMakeRemote("RemoteFunction", "SpawnShip")
local RF_DespawnShip     = getOrMakeRemote("RemoteFunction", "DespawnShip")
local RF_GetCargoJobs    = getOrMakeRemote("RemoteFunction", "GetCargoJobs")
local RF_AcceptCargoJob  = getOrMakeRemote("RemoteFunction", "AcceptCargoJob")
local RF_GetPlayerCargo  = getOrMakeRemote("RemoteFunction", "GetPlayerCargo")
local RE_OpenDockUI      = getOrMakeRemote("RemoteEvent",    "OpenDockUI")

-- ── Dock Registry ─────────────────────────────────────────────────────────────
--[[
    dockStates[dockId] = {
        model        = Model,
        spawnAnchor  = Part,
        spawnedShip  = Model | nil,
        spawnedBy    = userId | nil,
        isNPCShip    = bool,
        claimedJobs  = table,   -- { [jobId] = true }
        cachedJobs   = table | nil,
        dockedAt     = number | nil,
        dockDuration = number | nil,
    }
]]
local dockStates = {}

-- Give CargoDeliveryManager a reference to dockStates so it can unclaim jobs
CargoDeliveryManager:Init(dockStates)

-- ── Rarity Weights ────────────────────────────────────────────────────────────
local RARITY_WEIGHT = {
	Common    = 50,
	Uncommon  = 30,
	Rare      = 15,
	Epic      = 4,
	Legendary = 1,
}

-- ── Cargo Generation Data ─────────────────────────────────────────────────────
local CARGO_TYPES = {
	-- ── Common ────────────────────────────────────────────────────────────────
	{ name = "Recycled Hull Scrap",          baseValue = 10,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Quantum Ore",                  baseValue = 80,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Biosynth Fibers",              baseValue = 40,  danger = 0.1, rarity = "Common",    contraband = false, cargoModel = "Cargo4" },
	{ name = "Medipacks (Grade C)",          baseValue = 30,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Dehydrated Ration Packs",      baseValue = 15,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Office Supply Crates",         baseValue = 12,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Synthetic Coffee Beans",       baseValue = 20,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Scrap Electronics",            baseValue = 18,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Structural Alloy Sheets",      baseValue = 22,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Expired Vouchers",             baseValue = 2,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Somebody's Lunch",             baseValue = 5,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Motivational Posters (Bulk)",  baseValue = 8,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Unsolicited Surveys",          baseValue = 3,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Novelty Gravity Globes",       baseValue = 12,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Generic Brand Nutrients",      baseValue = 10,  danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Commemorative Plaques",        baseValue = 7,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Discontinued Uniforms",        baseValue = 6,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },
	{ name = "Participation Certificates",   baseValue = 1,   danger = 0.0, rarity = "Common",    contraband = false, cargoModel = "Cargo1" },

	-- ── Uncommon ──────────────────────────────────────────────────────────────
	{ name = "Nano-Lube Canisters",          baseValue = 35,  danger = 0.2, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Starship Fuel Pods",           baseValue = 90,  danger = 0.2, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Corporate Docs",               baseValue = 45,  danger = 0.3, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Cooling Fluid Drums",          baseValue = 40,  danger = 0.1, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo3" },
	{ name = "Atmospheric Filters",          baseValue = 38,  danger = 0.0, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Data Storage Cores",           baseValue = 55,  danger = 0.2, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Thermal Gel Packs",            baseValue = 42,  danger = 0.2, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Pressurized Gas Canisters",    baseValue = 48,  danger = 0.3, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Whispral Sand Crawler",        baseValue = 60,  danger = 0.3, rarity = "Uncommon",  contraband = true, cargoModel = "Cargo2"  },
	{ name = "Someone's Personal Effects",   baseValue = 30,  danger = 0.0, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Unverified Antiques",          baseValue = 55,  danger = 0.0, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Aggressively Loud Speakers",   baseValue = 40,  danger = 0.1, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Second-Hand Clones (Parts)",   baseValue = 65,  danger = 0.3, rarity = "Uncommon",  contraband = true, cargoModel = "Cargo2"  },
	{ name = "Unlabeled Barrels",            baseValue = 50,  danger = 0.0, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo3" },
	{ name = "Defective Escape Pods",        baseValue = 45,  danger = 0.0, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },
	{ name = "Slightly Haunted Hardware",    baseValue = 60,  danger = 0.7, rarity = "Uncommon",  contraband = false, cargoModel = "Cargo2" },

	-- ── Rare ──────────────────────────────────────────────────────────────────
	{ name = "Cryo-Cells",                   baseValue = 120, danger = 0.3, rarity = "Rare",      contraband = false, cargoModel = "Cargo1" },
	{ name = "Contraband Spice",             baseValue = 250, danger = 0.5, rarity = "Rare",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Contraband Pirate Radios",     baseValue = 275, danger = 0.6, rarity = "Rare",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Unlicensed Energy",   		 baseValue = 200, danger = 0.4, rarity = "Rare",      contraband = true, cargoModel = "Cargo3"  },
	{ name = "Stolen Corp Prototypes",       baseValue = 220, danger = 0.5, rarity = "Rare",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Memory Wipe Kits",             baseValue = 180, danger = 0.4, rarity = "Rare",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Void Moth Larva",              baseValue = 160, danger = 0.2, rarity = "Rare",      contraband = true, cargoModel = "Cargo4"  },
	{ name = "Miragi Venom Serpent",         baseValue = 300, danger = 0.7, rarity = "Rare",      contraband = true, cargoModel = "Cargo4"  },
	{ name = "Yabis VII Core Samples",       baseValue = 115, danger = 0.0, rarity = "Rare",      contraband = false, cargoModel = "Cargo3" },
	{ name = "Evidence (Unspecified)",       baseValue = 180, danger = 0.3, rarity = "Rare",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "The Wrong Shipment",           baseValue = 200, danger = 0.7, rarity = "Rare",      contraband = false, cargoModel = "Cargo1" },
	{ name = "Slightly Alive Cargo",         baseValue = 220, danger = 0.7, rarity = "Rare",      contraband = true, cargoModel = "Cargo4"  },

	-- ── Epic ──────────────────────────────────────────────────────────────────
	{ name = "RadioactiveCore",              baseValue = 100, danger = 0.8, rarity = "Epic",      contraband = false, cargoModel = "Cargo1" },
	{ name = "Unregistered AI Cores",        baseValue = 400, danger = 0.6, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Forged Identity Chips",        baseValue = 350, danger = 0.7, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Keth Razorback",               baseValue = 450, danger = 0.8, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Crystalline Parasite",         baseValue = 380, danger = 0.9, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "Someone Important's Brain",    baseValue = 400, danger = 0.5, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },
	{ name = "A Very Angry Crate",           baseValue = 350, danger = 0.8, rarity = "Epic",      contraband = false, cargoModel = "Cargo1" },
	{ name = "The Exception (Form 7-C)",     baseValue = 300, danger = 0.0, rarity = "Epic",      contraband = false, cargoModel = "Cargo1" },
	{ name = "Plausible Deniability Docs",   baseValue = 420, danger = 0.7, rarity = "Epic",      contraband = true, cargoModel = "Cargo1"  },

	-- ── Legendary ─────────────────────────────────────────────────────────────
	{ name = "Dark Matter Vials",                   baseValue = 500, danger = 1.0, rarity = "Legendary", contraband = false, cargoModel = "Cargo1" },
	{ name = "Ooze-Touched Specimen",               baseValue = 600, danger = 1.0, rarity = "Legendary", contraband = true, cargoModel = "Cargo4"  },
	{ name = "Mechanica Robotic Titan Parts",        baseValue = 580, danger = 0.6, rarity = "Legendary", contraband = true, cargoModel = "Cargo1"  },
	{ name = "Stolen Artifacts From Planet Forge",   baseValue = 550, danger = 0.3, rarity = "Legendary", contraband = true, cargoModel = "Cargo1"  },
	{ name = "Jar of Warped Time from Planet Lag",   baseValue = 525, danger = 0.1, rarity = "Legendary", contraband = false, cargoModel = "Cargo1" },
}

-- ── Weighted Cargo Pool ───────────────────────────────────────────────────────
local weightedCargoPool = {}
for _, cargo in ipairs(CARGO_TYPES) do
	local w = RARITY_WEIGHT[cargo.rarity] or 1
	for _ = 1, w do
		table.insert(weightedCargoPool, cargo)
	end
end

local LOCAL_DESTINATIONS = {
	{ name = "Station Commissary",      zoneName = "Commissary" },
	{ name = "Docking Bay 1 Warehouse", zoneName = "DockingBay1Warehouse" },
	{ name = "The Mess Hall",      zoneName = "MessHall" },
	{ name = "The Cargo Rat",           zoneName = "TheCargoRat"      },
}

local NON_LOCAL_DESTINATIONS = {
	{ name = "Mining Outpost Delta (Rock Bottom)",  zoneName = "AsteroidOutpostDelta" },
	{ name = "Orbital Refinery MK-9",   zoneName = "AsteroidOutpostDelta" },
	{ name = "Whispral (Planet)",        zoneName = "Whispral"             },
	{ name = "Keth Prime Colony",        zoneName = "AsteroidOutpostDelta" },
	{ name = "The Void Fringe",          zoneName = "AsteroidOutpostDelta" },
	{ name = "Nexus Hub Station",        zoneName = "Whispral"             },
}

-- ── Player Owned Ships ────────────────────────────────────────────────────────
local function getOwnedShips(player)
	local ships = {}
	for _, child in ipairs(ShipsFolder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(ships, child.Name)
		end
	end
	return ships
end

-- ── Zone Distance Lookup ──────────────────────────────────────────────────────
local ZonesFolder = workspace:WaitForChild("Zones")

local function getZonePosition(zoneName)
	local zone = ZonesFolder:FindFirstChild(zoneName)
	if not zone then
		warn("[DockManager] Zone not found: " .. tostring(zoneName))
		return nil
	end

	if zone:IsA("BasePart") then
		return zone.Position
	elseif zone:IsA("Model") then
		if zone.PrimaryPart then
			return zone.PrimaryPart.Position
		end
		local bp = zone:FindFirstChildWhichIsA("BasePart", true)
		return bp and bp.Position or nil
	else
		local center = zone:FindFirstChild("CenterPart")
		if center and center:IsA("BasePart") then
			return center.Position
		end
	end

	warn("[DockManager] Could not resolve position for zone: " .. zoneName)
	return nil
end

-- ── Payout Calculation ────────────────────────────────────────────────────────
local BASE_VALUE_PCT       = 0.005
local DISTANCE_RATE        = 0.0020
local DANGER_DISTANCE_RATE = 0.0035
local LOCAL_DISTANCE       = 800
local NEARBY_DISTANCE      = 5000
local DISTANT_THRESHOLD    = 1000
local DISTANCE_EXPONENT    = 1.1

local function applyDistanceCurve(distance)
	local normalized = distance / DISTANT_THRESHOLD
	return DISTANT_THRESHOLD * math.pow(normalized, DISTANCE_EXPONENT)
end

local function calculatePayout(totalValue, danger, distance)
	local basePayout    = totalValue * BASE_VALUE_PCT
	local curved        = applyDistanceCurve(distance)
	local dangerBonus   = danger * curved * DANGER_DISTANCE_RATE
	local distanceBonus = curved * DISTANCE_RATE
	local fuzz          = 0.92 + math.random() * 0.16
	return math.max(math.floor((basePayout + dangerBonus + distanceBonus) * fuzz), 1)
end

-- ── Destination Shuffle Helper ────────────────────────────────────────────────
local function pickUniqueDestinations(pool, count)
	local shuffled = {}
	for _, v in ipairs(pool) do table.insert(shuffled, v) end

	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local picked = {}
	for i = 1, math.min(count, #shuffled) do
		table.insert(picked, shuffled[i])
	end
	return picked
end

-- ── Cargo Job Generation ──────────────────────────────────────────────────────
local function generateCargoJobs(dockId, anchorPos)
	math.randomseed(tick() + #dockId)

	local jobs       = {}
	local usedCargos = {}

	local localDests    = pickUniqueDestinations(LOCAL_DESTINATIONS, 3)
	local nonLocalDests = pickUniqueDestinations(NON_LOCAL_DESTINATIONS, 3)

	local allDests = {}
	for _, d in ipairs(localDests)    do table.insert(allDests, d) end
	for _, d in ipairs(nonLocalDests) do table.insert(allDests, d) end

	for i, dest in ipairs(allDests) do
		local cargo    = weightedCargoPool[math.random(#weightedCargoPool)]
		local attempts = 0
		while usedCargos[cargo.name] and attempts < 20 do
			cargo    = weightedCargoPool[math.random(#weightedCargoPool)]
			attempts += 1
		end
		usedCargos[cargo.name] = true

		local zonePos  = getZonePosition(dest.zoneName)
		local distance = 0
		if anchorPos and zonePos then
			distance = (zonePos - anchorPos).Magnitude
		else
			warn("[DockManager] Could not calculate distance for dest: " .. dest.name)
		end

		local distanceLabel
		if distance < LOCAL_DISTANCE then
			distanceLabel = "Local"
		elseif distance < NEARBY_DISTANCE then
			distanceLabel = "Nearby"
		else
			distanceLabel = "Distant"
		end

		local quantity   = math.random(1, 20)
		local totalValue = cargo.baseValue * quantity
		local payout     = calculatePayout(totalValue, cargo.danger, distance)

		local timeLimit = distanceLabel == "Local"  and math.random(5,  15)
			or distanceLabel == "Nearby" and math.random(15, 40)
			or math.random(40, 90)

		table.insert(jobs, {
			id            = i,
			cargoName     = cargo.name,
			quantity      = quantity,
			cargoValue    = totalValue,
			danger        = cargo.danger,
			rarity        = cargo.rarity,
			contraband    = cargo.contraband,
			cargoModel    = cargo.cargoModel,
			destination   = dest.name,
			zoneName      = dest.zoneName,
			distance      = math.floor(distance),
			distanceLabel = distanceLabel,
			payout        = payout,
			timeLimit     = timeLimit,
		})
	end

	return jobs
end

-- ── NPC Ship Docking ──────────────────────────────────────────────────────────
local function dockNPCShip(dockId, shipName, existingShip, dockTime)
	local dock = dockStates[dockId]
	if not dock then
		warn("[DockManager] dockNPCShip: Dock '" .. tostring(dockId) .. "' not registered.")
		return false
	end
	if dock.spawnedShip then
		warn("[DockManager] dockNPCShip: Dock '" .. dockId .. "' is already occupied.")
		return false
	end

	local ship

	if existingShip then
		ship = existingShip
		if shipName then
			ship.Name = shipName
			if ship:FindFirstChild("HUD") then
				ship.HUD.NameFrame.NameLabel.Text = shipName
			end
		end
	else
		local template = ShipsFolder:FindFirstChild(shipName)
		if not template then
			warn("[DockManager] dockNPCShip: Ship '" .. shipName .. "' not found in Ships folder.")
			return false
		end

		ship        = template:Clone()
		ship.Name   = shipName
		ship.Parent = workspace
	end

	if ship.PrimaryPart then
		ship:SetPrimaryPartCFrame(dock.spawnAnchor.CFrame + Vector3.new(0, ship.PrimaryPart.Size.Y / 2, 0))
	else
		local bp = ship:FindFirstChildWhichIsA("BasePart", true)
		if bp then bp.CFrame = dock.spawnAnchor.CFrame + Vector3.new(0, 10, 0) end
	end

	dock.shipName     = shipName
	dock.spawnedShip  = ship
	dock.spawnedBy    = nil
	dock.isNPCShip    = true
	dock.claimedJobs  = {}
	dock.cachedJobs   = nil
	dock.dockedAt     = tick()
	dock.dockDuration = dockTime or 0

	print("[DockManager] NPC ship '" .. shipName .. "' docked at '" .. dockId .. "'.")
	return true
end

-- ── NPC Ship Undocking ────────────────────────────────────────────────────────
local function undockNPCShip(dockId, doNotDestroy)
	local dock = dockStates[dockId]
	if not dock then
		warn("[DockManager] undockNPCShip: Dock '" .. tostring(dockId) .. "' not registered.")
		return false
	end
	if not dock.spawnedShip then
		warn("[DockManager] undockNPCShip: Dock '" .. dockId .. "' has no ship to undock.")
		return false
	end
	if not dock.isNPCShip then
		warn("[DockManager] undockNPCShip: Ship at '" .. dockId .. "' is a player ship, not an NPC ship.")
		return false
	end

	if not doNotDestroy then
		dock.spawnedShip:Destroy()
	end

	dock.spawnedShip  = nil
	dock.spawnedBy    = nil
	dock.isNPCShip    = false
	dock.claimedJobs  = {}
	dock.cachedJobs   = nil
	dock.dockedAt     = nil
	dock.dockDuration = nil

	print("[DockManager] NPC ship undocked from '" .. dockId .. "'.")
	return true
end

-- ── Dock Registration ─────────────────────────────────────────────────────────
local function registerDock(dockModel)
	local dockId = dockModel:GetAttribute("DockId")
	if not dockId then return end
	if dockStates[dockId] then return end

	local spawnAnchor = dockModel:FindFirstChild("SpawnAnchor", true)
	if not spawnAnchor then
		warn("[DockManager] Dock '" .. dockId .. "' is missing a SpawnAnchor part.")
		return
	end

	dockStates[dockId] = {
		model        = dockModel,
		spawnAnchor  = spawnAnchor,
		spawnedShip  = nil,
		spawnedBy    = nil,
		isNPCShip    = false,
		claimedJobs  = {},
		cachedJobs   = nil,
		dockedAt     = nil,
		dockDuration = nil,
	}

	local prompt = dockModel:FindFirstChild("ManageDock", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(player)
			RE_OpenDockUI:FireClient(player, dockId)
		end)
	else
		warn("[DockManager] Dock '" .. dockId .. "' has no ProximityPrompt named 'ManageDock'.")
	end

	print("[DockManager] Registered dock: " .. dockId)
end

-- Scan existing workspace
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("Model") and obj:GetAttribute("DockId") then
		registerDock(obj)
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") and obj:GetAttribute("DockId") then
		registerDock(obj)
	end
end)

-- ── Remote Handlers ───────────────────────────────────────────────────────────

RF_GetDockState.OnServerInvoke = function(player, dockId)
	local dock = dockStates[dockId]
	if not dock then return nil, "Dock not found." end

	local slotInfo = CargoDeliveryManager:GetSlotInfo(player)

	return {
		dockId         = dockId,
		hasShip        = dock.spawnedShip ~= nil,
		shipName       = dock.shipName,
		isNPCShip      = dock.isNPCShip,
		ownedByMe      = dock.spawnedBy == player.UserId,
		claimedJobs    = dock.claimedJobs,
		dockDuration   = dock.dockDuration or 0,
		dockedAt       = dock.dockedAt or 0,
		cargoSlots     = slotInfo.cargoSlots,
		slotsUsed      = slotInfo.slotsUsed,
		slotsRemaining = slotInfo.slotsRemaining,
	}
end

RF_GetOwnedShips.OnServerInvoke = function(player)
	return getOwnedShips(player)
end

RF_SpawnShip.OnServerInvoke = function(player, dockId, shipName)
	local dock = dockStates[dockId]
	if not dock then return false, "Dock not found." end
	if dock.spawnedShip then return false, "A ship is already docked here." end

	local template = ShipsFolder:FindFirstChild(shipName)
	if not template then return false, "Ship '" .. shipName .. "' not found." end

	local owned  = getOwnedShips(player)
	local ownsIt = false
	for _, s in ipairs(owned) do
		if s == shipName then ownsIt = true break end
	end
	if not ownsIt then return false, "You don't own that ship." end

	local ship  = template:Clone()
	ship.Name   = shipName
	ship.Parent = workspace

	if ship.PrimaryPart then
		ship:SetPrimaryPartCFrame(dock.spawnAnchor.CFrame)
	else
		local bp = ship:FindFirstChildWhichIsA("BasePart", true)
		if bp then bp.CFrame = dock.spawnAnchor.CFrame end
	end

	dock.spawnedShip = ship
	dock.spawnedBy   = player.UserId
	dock.isNPCShip   = false
	dock.cachedJobs  = nil

	return true, "Ship deployed successfully."
end

RF_DespawnShip.OnServerInvoke = function(player, dockId)
	local dock = dockStates[dockId]
	if not dock then return false, "Dock not found." end
	if not dock.spawnedShip then return false, "No ship is docked here." end
	if dock.isNPCShip then return false, "That's an NPC vessel — you can't undock it." end
	if dock.spawnedBy ~= player.UserId then return false, "That's not your ship." end

	dock.spawnedShip:Destroy()
	dock.spawnedShip = nil
	dock.spawnedBy   = nil
	dock.isNPCShip   = false
	dock.cachedJobs  = nil

	return true, "Ship undocked."
end

RF_GetCargoJobs.OnServerInvoke = function(player, dockId)
	local dock = dockStates[dockId]
	if not dock then return nil, "Dock not found." end
	if not dock.spawnedShip then return nil, "No ship is docked." end
	if not dock.isNPCShip then return nil, "This is not a cargo vessel." end

	if not dock.cachedJobs then
		local anchorPos = dock.spawnAnchor and dock.spawnAnchor.Position or nil
		dock.cachedJobs = generateCargoJobs(dockId, anchorPos)
	end

	-- Prune expired jobs so the pool is current before filtering
	CargoDeliveryManager:PruneExpired(player.UserId)

	local available = {}
	for _, job in ipairs(dock.cachedJobs) do
		if not dock.claimedJobs[job.id] then
			table.insert(available, job)
		end
	end

	return available
end

RF_AcceptCargoJob.OnServerInvoke = function(player, dockId, jobId)
	local dock = dockStates[dockId]
	if not dock then return false, "Dock not found." end
	if not dock.spawnedShip then return false, "No ship is docked." end
	if not dock.isNPCShip then return false, "This is not a cargo vessel." end
	if not dock.cachedJobs then return false, "No jobs available." end
	if dock.claimedJobs[jobId] then return false, "That contract has already been claimed." end

	-- Check cargo slot availability via CargoDeliveryManager
	local canAccept, slotErr = CargoDeliveryManager:CanAcceptJob(player)
	if not canAccept then return false, slotErr end

	local job = nil
	for _, j in ipairs(dock.cachedJobs) do
		if j.id == jobId then job = j break end
	end
	if not job then return false, "Job not found." end

	-- Claim on the dock
	dock.claimedJobs[jobId] = true

	-- Register with CargoDeliveryManager (handles expiry + slot tracking)
	CargoDeliveryManager:AddJob(player, dockId, jobId, job)

	-- TODO: Add cargo to ship, enable HUD, set owner attribute
	return true, "Job accepted! Deliver " .. job.cargoName
		.. " to " .. job.destination
		.. " for §" .. tostring(job.payout) .. "."
end

-- Returns the player's active cargo jobs with time remaining
RF_GetPlayerCargo.OnServerInvoke = function(player)
	return CargoDeliveryManager:GetActiveJobs(player)
end

print("[DockManager] Server initialized.")

-- ── Module exports ────────────────────────────────────────────────────────────
return {
	dockNPCShip            = dockNPCShip,
	undockNPCShip          = undockNPCShip,
	getDockStates          = function() return dockStates end,
	cargoDeliveryManager   = CargoDeliveryManager,
}