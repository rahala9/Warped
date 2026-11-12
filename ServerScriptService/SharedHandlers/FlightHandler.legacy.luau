-- ServerScriptService/SharedHandlers/FlightHandler.lua (ShipPilotDock.server.lua)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")
local ExitShip = Remotes:FindFirstChild("ExitShip")

-- Create ExitShip remote if it doesn't exist
if not ExitShip then
	ExitShip = Instance.new("RemoteEvent")
	ExitShip.Name = "ExitShip"
	ExitShip.Parent = Remotes
end

local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

local SHIP_TAG = "SpaceShip"
local GROUP_SHIP = "Ship"
local GROUP_PLAYER = "Players"

-- NOTE: FallenPartsDestroyHeight must be set manually in Studio!
-- Go to Workspace properties and set FallenPartsDestroyHeight to -10000 or lower
-- This prevents ships from being destroyed when diving in space

local function ensureCollisionGroups()
	pcall(function() PhysicsService:RegisterCollisionGroup(GROUP_SHIP) end)
	pcall(function() PhysicsService:RegisterCollisionGroup(GROUP_PLAYER) end)

	PhysicsService:CollisionGroupSetCollidable(GROUP_SHIP, GROUP_PLAYER, false)
end

local function setCollisionGroupRecursive(model: Model, groupName: string)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = groupName
		end
	end
end

local function unanchorModel(model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
		end
	end
end

-- IMPORTANT: remove any constraints that connect the ship to the world/dock
local function breakExternalConstraints(ship: Model)
	local function isInShip(inst: Instance?): boolean
		return inst ~= nil and inst:IsDescendantOf(ship)
	end

	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("RigidConstraint") then
			local p0 = d.Part0
			local p1 = d.Part1
			if (p0 and not isInShip(p0)) or (p1 and not isInShip(p1)) then
				d:Destroy()
			end
		elseif d:IsA("Motor6D") then
			local p0 = d.Part0
			local p1 = d.Part1
			if (p0 and not isInShip(p0)) or (p1 and not isInShip(p1)) then
				d:Destroy()
			end
		end
	end
end

-- Remove ALL internal WeldConstraints to prevent jitter
local function removeAllInternalWelds(ship: Model)
	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("WeldConstraint") then
			d:Destroy()
		end
	end
end

-- Create proper internal welds for ship rigidity
local function weldShipPartsTogetherProperly(ship: Model)
	if not ship.PrimaryPart then 
		warn("[ShipPilot] Ship has no PrimaryPart - cannot weld parts together")
		return 
	end

	local primaryPart = ship.PrimaryPart

	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("BasePart") and d ~= primaryPart then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "ShipInternalWeld"
			weld.Part0 = primaryPart
			weld.Part1 = d
			weld.Parent = primaryPart
		end
	end

	print(("[ShipPilot] Created internal welds for ship: %s"):format(ship.Name))
end

-- Debug helper: will tell you instantly if something is still anchored
local function warnAnchoredParts(ship: Model)
	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("BasePart") and d.Anchored then
			warn("[ShipPilot] Anchored part still in ship:", d:GetFullName())
		end
	end
end

-- Optional debug: detect if ship is multiple assemblies (often causes buzzing)
local function countAssemblies(ship: Model): number
	local roots = {}
	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("BasePart") then
			local root = d.AssemblyRootPart
			if root then
				roots[root] = true
			end
		end
	end
	local n = 0
	for _ in pairs(roots) do n += 1 end
	return n
end

-- Set physics properties properly for flight
local function setShipPhysicsForFlight(ship: Model)
	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = true
			d.CanTouch = false
			d.CanQuery = false

			if d ~= ship.PrimaryPart then
				d.Massless = true
			else
				d.Massless = false
			end
		end
	end
end

-- Only set network ownership on the assembly root (PrimaryPart)
local function setModelNetworkOwner(model: Model, player: Player?)
	if not model then return end
	if not model.PrimaryPart then 
		warn("[Network] No PrimaryPart to set ownership on!")
		return 
	end

	pcall(function()
		model.PrimaryPart:SetNetworkOwner(player)
	end)

	-- task.wait is safe here because we are always called inside task.spawn
	task.wait(0.1)
	local success, owner = pcall(function()
		return model.PrimaryPart:GetNetworkOwner()
	end)

	if success then
		if owner ~= player then
			warn("[Network] Failed to set ownership! Owner is:", owner, "Expected:", player)
		else
			print("[Network] Successfully set ownership to:", player)
		end
	else
		warn("[Network] Could not verify ownership")
	end
end

local function findPrompt(ship: Model): ProximityPrompt?
	local p = ship:FindFirstChild("PilotShip", true)
	return (p and p:IsA("ProximityPrompt")) and p or nil
end

local function unweldShipFromPlayer(player: Player)
	print("TEST UNWELD [FlightHandler Server] unweldShipFromPlayer")
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local weld = hrp:FindFirstChild("PilotShipWeld")
	if weld and weld:IsA("WeldConstraint") then
		weld:Destroy()
	end
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local ShipState: {[Model]: {
	pilot: Player?,
	promptConn: RBXScriptConnection?,
}} = {}

---------------------------------------------------------------------
-- Helper: cleanly exit a player from a ship
-- Used by both ExitShip remote and PlayerRemoving
local function doExitShip(player: Player, ship: Model)
	local st = ShipState[ship]
	if not st or st.pilot ~= player then return end

	st.pilot = nil
	StatesFunctions.SetCurrentShip(player, nil)

	-- Revoke client's physics ownership FIRST
	-- Now server controls the ship, client can't fight our velocity zero
	pcall(function()
		ship.PrimaryPart:SetNetworkOwner(nil) -- nil = server owns it
	end)

	-- Small wait for ownership transfer to take effect
	task.delay(0.1, function()
		if ship.PrimaryPart then
			ship.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
			ship.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
			for _, part in ipairs(ship:GetDescendants()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.Anchored = true
				end
			end
		end

		local prompt = findPrompt(ship)
		if prompt then prompt.Enabled = true end
	end)

	-- These happen immediately
	unweldShipFromPlayer(player)
	pcall(function() SetPilotedShip:FireClient(player, nil) end)
end---------------------------------------------------
-- Tag hookup — connection made ONCE here, never recreated
---------------------------------------------------------------------
local function SetupShip(inst: Instance)
	if not inst:IsA("Model") then return end
	if ShipState[inst] then return end

	local p = findPrompt(inst)
	if not p then
		warn("[ShipPilot] No PilotShip ProximityPrompt found in:", inst.Name)
		return
	end

	ShipState[inst] = { pilot = nil, promptConn = nil }

	-- FIX 1: Disable prompt immediately on the main thread before any yield
	-- FIX 2: Guard with st.pilot so a second trigger while entering is ignored
	-- FIX 3: Wrap all logic in task.spawn so Triggered returns instantly,
	--         preventing Roblox from locking the prompt into a broken cooldown state
	ShipState[inst].promptConn = p.Triggered:Connect(function(player: Player)
		local st = ShipState[inst]

		-- Guard: already has a pilot, ignore
		if not st or st.pilot then return end

		-- FIX 1: Disable prompt immediately on main thread before any yields
		p.Enabled = false

		-- FIX 3: Spawn so Triggered callback returns instantly
		task.spawn(function()
			if not inst.PrimaryPart then
				p.Enabled = true
				return
			end

			local enterSpot = inst.PrimaryPart:FindFirstChild("enter")
			local char = player.Character
			if not (char and enterSpot) then
				-- Failed to enter — re-enable prompt
				p.Enabled = true
				return
			end

			-- 0) Remove external dock constraints
			breakExternalConstraints(inst)

			-- 1) Remove ALL existing internal welds (prevents conflicts)
			removeAllInternalWelds(inst)

			-- 2) Unanchor everything
			unanchorModel(inst)

			-- 3) Create proper internal welds (ship parts → PrimaryPart)
			-- CRITICAL: This must happen BEFORE physics settle to prevent parts falling
			weldShipPartsTogetherProperly(inst)

			-- 4) Set physics properties (massless non-primary parts, etc.)
			setShipPhysicsForFlight(inst)

			-- IMPORTANT: Add temporary anti-gravity force during client handoff
			if inst.PrimaryPart then
				inst.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
				inst.PrimaryPart.AssemblyAngularVelocity = Vector3.zero

				local tempHold = Instance.new("BodyVelocity")
				tempHold.Name = "TempHold"
				tempHold.Velocity = Vector3.zero
				tempHold.MaxForce = Vector3.new(50000, 50000, 50000)
				tempHold.Parent = inst.PrimaryPart

				task.delay(0.5, function()
					if tempHold and tempHold.Parent then
						tempHold:Destroy()
						print("[ShipPilot] Removed temporary hold - client forces active")
					end
				end)
			end

			-- Give physics a frame to settle (safe inside task.spawn)
			task.wait(0.1)

			local assemblies = countAssemblies(inst)
			if assemblies > 1 then
				warn(("[ShipPilot] Ship still has %d assemblies after welding. This will cause jitter!"):format(assemblies))
			else
				print("[ShipPilot] Ship is properly welded as single assembly")
			end

			warnAnchoredParts(inst)

			-- 5) Set network ownership BEFORE client takes control
			-- (task.wait inside setModelNetworkOwner is safe here since we are in task.spawn)
			setModelNetworkOwner(inst, player)

			-- Re-confirm prompt is still disabled after all async work above
			p.Enabled = false

			-- 6) Move player to entrance
			char:PivotTo(enterSpot.WorldCFrame)

			-- 7) Set collision groups (ship can't collide with player, but CAN collide with world)
			ensureCollisionGroups()
			setCollisionGroupRecursive(inst, GROUP_SHIP)

			-- 8) Tell client to start flying (client creates the player→ship weld)
			st.pilot = player
			StatesFunctions.SetCurrentShip(player, inst)
			SetPilotedShip:FireClient(player, inst)

			local currentTool = StatesFunctions.GetCurrentTool(player)
			if currentTool then
				pcall(function()
					InventoryFunctions.UnequipItem(player, currentTool)
				end)
			end

			-- Monitor network ownership while flying
			task.spawn(function()
				while inst.Parent and ShipState[inst] and ShipState[inst].pilot == player do
					task.wait(1)

					local success, owner = pcall(function()
						return inst.PrimaryPart:GetNetworkOwner()
					end)

					if success and owner ~= player then
						warn("[NETWORK] Ship network owner changed!")
						warn("[NETWORK] Current owner:", owner)
						warn("[NETWORK] Expected:", player)
						warn("[NETWORK] Ship:", inst.Name)
					end
				end
			end)

			-- Monitor ship position for Asteroids-style wraparound
			task.spawn(function()
				local WORLD_RADIUS = 40000

				print("[WRAPAROUND] Started monitoring for ship:", inst.Name, "Pilot:", player.Name)

				while inst.Parent and ShipState[inst] and ShipState[inst].pilot == player do
					if inst.PrimaryPart then
						local pos = inst.PrimaryPart.Position
						local distanceFromCenter = pos.Magnitude

						if distanceFromCenter > WORLD_RADIUS then
							local direction = pos.Unit
							local newPos = -direction * (WORLD_RADIUS * 0.95)

							warn("[WRAPAROUND] Ship wrapped around! Distance:", distanceFromCenter)
							warn("[WRAPAROUND] Old pos:", pos)
							warn("[WRAPAROUND] New pos:", newPos)

							inst.PrimaryPart.CFrame = CFrame.new(newPos) * inst.PrimaryPart.CFrame.Rotation
						end
					end

					task.wait(0.1)
				end

				print("[WRAPAROUND] Stopped monitoring for ship:", inst.Name)
			end)
		end)
	end)

	print("[ShipPilot] SetupShip complete:", inst.Name)
end

local function TeardownShip(inst: Instance)
	if not inst:IsA("Model") then return end
	local st = ShipState[inst]
	if not st then return end

	if st.promptConn then
		st.promptConn:Disconnect()
	end
	ShipState[inst] = nil
end

for _, inst in ipairs(CollectionService:GetTagged(SHIP_TAG)) do
	SetupShip(inst)
end
CollectionService:GetInstanceAddedSignal(SHIP_TAG):Connect(SetupShip)
CollectionService:GetInstanceRemovedSignal(SHIP_TAG):Connect(TeardownShip)

---------------------------------------------------------------------
-- Player leaving
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	for ship, st in pairs(ShipState) do
		if st.pilot == player then
			doExitShip(player, ship)
		end
	end
end)

---------------------------------------------------------------------
-- Client-requested exit
---------------------------------------------------------------------
ExitShip.OnServerEvent:Connect(function(player, ship)
	if not ship or not ship:IsA("Model") then return end
	doExitShip(player, ship)
end)