--[[
	ShipNodeMovement - Server Script (Physics-Based, Multi-Route)
	
	Moves spaceships along routes defined by Attachments on a Part.
	Supports multiple routes, each with its own ship pool, mode, and speed.
	
	SETUP:
	------
	1. Place in ServerScriptService.
	2. Workspace.TrafficNodes.TrafficCenter — anchored Part with Attachments.
	   Each attachment's YELLOW ARROW = heading the ship faces on arrival.
	3. Ship templates in ServerStorage. Can be a single Model or a Folder
	   of Models (one is chosen randomly each loop).
	4. Configure ROUTES table below.
]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DockManager = require(ServerScriptService:WaitForChild("SharedServices").DockManager)

-- Shield entry: require ShieldFunctions for dome ripple on entry
local ShieldFunctions = require(
	ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("ShieldFunctions")
)

-- Dome shield hitbox — ships trigger a ripple when passing through
local DOME = workspace:WaitForChild("Areas")
	:WaitForChild("StarhopStation")
	:WaitForChild("DomeShield"):WaitForChild("ShieldHitBox") :: BasePart
local DOME_MARGIN = 5  -- studs outside dome to detect entry

----------------------------------------------------------------------
-- ROUTES
-- Each route defines: nodes, ship source, mode, and speed.
--
-- ships: path in ServerStorage to a single Model OR a Folder of Models.
--        If a Folder, a random ship is chosen each time it restarts at node 1.
--
-- mode: "loop"     — after last node, go directly to first node
--       "pingpong" — after last node, reverse through nodes back to first
--
-- nodes: ordered list of { "AttachmentName", pauseSeconds }
--        or just "AttachmentName" for default pause
--
-- speed: studs per second (optional, default 50)
----------------------------------------------------------------------
local ROUTES = {
	{
		routeName  = "FoodTruckRoute1",
		shipName = "NanoBytes",
		ships = {"SharedServerItems", "FoodTrucks"},  -- Folder: random pick each loop
		mode  = "pingpong",                                -- "loop" or "pingpong"
		speed = 50,
		type = "FOOD",
		nodes = {
			{ "FoodTrucks1Home",              2 },
			{ "PrimeStationDockingEntry1",  1 },
			{ "PrimeStationDockingBay1",    10 },
		},
	},
	{
		routeName  = "FoodTruckRoute2",
		shipName = "HumanFood",
		ships = {"SharedServerItems", "FoodTrucks2"},  -- Folder: random pick each loop
		mode  = "pingpong",                                -- "loop" or "pingpong"
		speed = 50,
		type = "FOOD",
		nodes = {
			{ "FoodTrucks2Home",              2 },
			{ "PrimeStationDockingEntry2",  1 },
			{ "PrimeStationDockingBay2",    10 },
		},
	},
	{
		routeName  = "CargoTruckRoute1",
		shipName = nil,
		ships = {"SharedServerItems", "FoodTrucks2"},  -- Folder: random pick each loop
		mode  = "pingpong",                                -- "loop" or "pingpong"
		speed = 50,
		type = "CARGO",
		dock = "Dock1",
		nodes = {
			{ "FoodTrucks2Home",              2 },
			{ "StarhopStationDock1Entry",  1 },
			{ "StarhopStationDock1",    20 },
		},
	},
	-- Example: single ship, pingpong mode
	-- {
	-- 	name  = "PatrolRoute",
	-- 	ships = {"SharedServerItems", "PatrolShip"},  -- single Model
	-- 	mode  = "pingpong",
	-- 	speed = 30,
	-- 	nodes = {
	-- 		{ "PatrolA", 3 },
	-- 		{ "PatrolB", 2 },
	-- 		{ "PatrolC", 3 },
	-- 	},
	-- },
}

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------
local DEFAULT_SPEED           = 50
local DEFAULT_PAUSE           = 1.0
local NODE_ARRIVE_DIST        = 12
local NODE_FOLDER_PATH        = {"TrafficNodes", "TrafficCenter"}

-- AlignPosition
local POS_RESPONSIVENESS      = 10
local POS_MAX_FORCE           = math.huge
local POS_MAX_VELOCITY        = 60

-- AlignOrientation  
local ORI_RESPONSIVENESS      = 5
local ORI_MAX_TORQUE          = math.huge

-- Docking: switch to CFrame lerp within this distance
local DOCK_DIST               = 30      -- studs from node to start docking
local DOCK_LERP_SPEED         = 3       -- lerp alpha multiplier per second (higher = faster dock)

-- Wobble effect during travel (applied to physics target, not CFrame)
local WOBBLE_RADIUS_STUDS     = 2 --1.8     -- lateral wobble radius
local WOBBLE_HEIGHT_STUDS     = 0.25    -- vertical wobble amplitude
local WOBBLE_ROT_DEGREES      = 5 --2.5     -- pitch/roll wobble in degrees
local WOBBLE_SPEED            = 2 --1.4     -- time multiplier for wobble oscillation
local WOBBLE_DURATION         = 3.0 --2.0     -- seconds after leaving a node that wobble plays

----------------------------------------------------------------------
-- STATES
----------------------------------------------------------------------
local State = {
	TRAVELING = "Traveling",
	DOCKING   = "Docking",
	ARRIVING  = "Arriving",
	DOCKED    = "Docked",
}

----------------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------------

local RNG = Random.new()

local function resolvePath(root: Instance, path: {string}): Instance?
	local current = root
	for _, name in path do
		current = current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

local function yawFromDirection(dir: Vector3): CFrame
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.001 then
		return CFrame.new()
	end
	return CFrame.lookAt(Vector3.zero, flat.Unit, Vector3.yAxis)
end

local function yawAngleBetween(cfA: CFrame, cfB: CFrame): number
	local lookA = cfA.LookVector
	local lookB = cfB.LookVector
	local dot = lookA.X * lookB.X + lookA.Z * lookB.Z
	dot = math.clamp(dot, -1, 1)
	return math.acos(dot)
end

----------------------------------------------------------------------
-- WOBBLE EFFECT
-- Sinusoidal position + rotation offsets applied during travel.
-- Returns a CFrame offset to apply to the target position/rotation.
----------------------------------------------------------------------

local function computeWobble(elapsed: number, strength: number): CFrame
	local tt = elapsed * WOBBLE_SPEED
	local sx1 = math.sin(tt * 1.7)
	local sx2 = math.sin(tt * 2.9)
	local sz1 = math.sin(tt * 1.3)
	local sz2 = math.sin(tt * 2.3)
	local sy  = math.sin(tt * 2.1)

	local wobbleX = (sx1 * 0.7 + sx2 * 0.3) * WOBBLE_RADIUS_STUDS * strength
	local wobbleZ = (sz1 * 0.7 + sz2 * 0.3) * WOBBLE_RADIUS_STUDS * strength
	local wobbleY = sy * WOBBLE_HEIGHT_STUDS * strength

	local pitch = math.rad((sz1 * 0.6 + sz2 * 0.4) * WOBBLE_ROT_DEGREES * strength)
	local roll  = math.rad((sx1 * 0.6 + sx2 * 0.4) * WOBBLE_ROT_DEGREES * strength)

	return CFrame.new(wobbleX, wobbleY, wobbleZ) * CFrame.Angles(pitch, 0, roll)
end

----------------------------------------------------------------------
-- DOME / SHIELD ENTRY DETECTION
-- Checks if a ship's bounding box is just outside the dome sphere.
-- If so, triggers a shield ripple + patch effect.
----------------------------------------------------------------------

local function getSphereRadius(dome: BasePart): number
	return math.max(dome.Size.X, dome.Size.Y, dome.Size.Z) * 0.5
end

local function checkDomeEntry(ship: Model)
	local center = DOME.Position
	local radius = getSphereRadius(DOME)

	local boxCF, boxSize = ship:GetBoundingBox()
	local half = boxSize * 0.5

	local localCenter = boxCF:PointToObjectSpace(center)
	local clampedLocal = Vector3.new(
		math.clamp(localCenter.X, -half.X, half.X),
		math.clamp(localCenter.Y, -half.Y, half.Y),
		math.clamp(localCenter.Z, -half.Z, half.Z)
	)

	local closestPoint = boxCF:PointToWorldSpace(clampedLocal)
	local toVehicle = closestPoint - center
	local dist = toVehicle.Magnitude

	-- Ship is just outside the dome surface
	if dist > radius and dist <= radius + DOME_MARGIN then
		local normal = toVehicle.Unit
		local hitPoint = center + normal * radius

		-- Place a patch on the dome
		pcall(function()
			ShieldFunctions.PlacePatchOnDome(
				DOME.Parent, DOME.Parent.Shield,
				hitPoint, normal,
				CFrame.Angles(0, math.pi, 0)
			)
		end)

		-- Trigger ripple effect
		pcall(function()
			local ripple = ShieldFunctions.ShieldRipple.new({
				model = DOME.Parent.ShieldVisual,
				visibleTransparency = 0,
				hiddenTransparency = 1,
				ringDelay = 0.07,
				fadeInTime = 0.10,
				holdTime = 0.05,
				fadeOutTime = 0.18,
			})
			ripple:Rip()
		end)

		return true
	end

	return false
end

----------------------------------------------------------------------
-- NODE COLLECTION
----------------------------------------------------------------------

local function collectNodes(nodePart: BasePart, nodeList)
	local nodes = {}
	for _, entry in nodeList do
		local name, pause
		if type(entry) == "table" then
			name = entry[1]
			pause = entry[2] or DEFAULT_PAUSE
		else
			name = entry
			pause = DEFAULT_PAUSE
		end

		local att = nodePart:FindFirstChild(name)
		if att and att:IsA("Attachment") then
			local yellowArrow = att.WorldAxis
			local yawCF = yawFromDirection(yellowArrow)
			table.insert(nodes, {
				Position = att.WorldPosition,
				YawCFrame = yawCF,
				Name = name,
				Pause = pause,
			})
		else
			warn("[ShipNode] Attachment '" .. name .. "' not found, skipping.")
		end
	end
	return nodes
end

----------------------------------------------------------------------
-- SHIP POOL
-- Resolves the ship source path. If it's a Folder, returns all
-- valid Models. If it's a single Model, returns {model}.
----------------------------------------------------------------------

local function resolveShipTemplates(shipPath: {string}): {Model}
	local target = resolvePath(ServerStorage, shipPath)
	if not target then
		warn("[ShipNode] Ship source not found: ServerStorage." .. table.concat(shipPath, "."))
		return {}
	end

	if target:IsA("Model") and target.PrimaryPart then
		return { target }
	end

	-- It's a Folder (or container) — collect all valid Models
	local templates = {}
	for _, child in target:GetChildren() do
		if child:IsA("Model") and child.PrimaryPart then
			table.insert(templates, child)
		end
	end
	return templates
end

local function pickRandomTemplate(templates: {Model}): Model?
	if #templates == 0 then return nil end
	return templates[RNG:NextInteger(1, #templates)]
end

----------------------------------------------------------------------
-- SHIP HELPERS
----------------------------------------------------------------------

local function computeFrontOffset(ship: Model): CFrame
	local primary = ship.PrimaryPart
	if not primary then return CFrame.new() end

	local frontAtt: Attachment? = primary:FindFirstChild("FrontAttachment")
	if not frontAtt then return CFrame.new() end

	local localYellow = frontAtt.Axis
	local flat = Vector3.new(localYellow.X, 0, localYellow.Z)
	if flat.Magnitude < 0.001 then return CFrame.new() end
	flat = flat.Unit

	local angle = math.atan2(flat.X, -flat.Z)
	return CFrame.Angles(0, -angle, 0)
end



----------------------------------------------------------------------
-- CONSTRAINT SETUP
----------------------------------------------------------------------

local function setupConstraints(primaryPart: BasePart, speed: number)
	-- Use the FrontAttachment as the reference point for POSITIONING
	local posAtt = primaryPart:FindFirstChild("FrontAttachment")
	if not posAtt then
		posAtt = Instance.new("Attachment")
		posAtt.Name = "MoverAttachment"
		posAtt.Parent = primaryPart
	end

	local alignPos = Instance.new("AlignPosition")
	alignPos.Name = "MoverAlignPosition"
	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPos.Attachment0 = posAtt
	alignPos.Responsiveness = POS_RESPONSIVENESS
	alignPos.MaxForce = POS_MAX_FORCE
	alignPos.MaxVelocity = math.max(speed, POS_MAX_VELOCITY)
	alignPos.Position = posAtt.WorldPosition
	alignPos.Parent = primaryPart

	-- Separate attachment for ORIENTATION with no local rotation
	-- (FrontAttachment has its own rotation which would add an unwanted offset)
	local oriAtt = Instance.new("Attachment")
	oriAtt.Name = "MoverOriAttachment"
	oriAtt.Parent = primaryPart

	local alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "MoverAlignOrientation"
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = oriAtt
	alignOri.Responsiveness = ORI_RESPONSIVENESS
	alignOri.MaxTorque = ORI_MAX_TORQUE
	alignOri.CFrame = primaryPart.CFrame - primaryPart.CFrame.Position
	alignOri.Parent = primaryPart

	local gravAtt = Instance.new("Attachment")
	gravAtt.Name = "AntiGravAttachment"
	gravAtt.Parent = primaryPart

	local antiGrav = Instance.new("VectorForce")
	antiGrav.Name = "AntiGravity"
	antiGrav.Attachment0 = gravAtt
	antiGrav.RelativeTo = Enum.ActuatorRelativeTo.World
	antiGrav.ApplyAtCenterOfMass = true
	antiGrav.Force = Vector3.new(0, primaryPart.AssemblyMass * workspace.Gravity, 0)
	antiGrav.Parent = primaryPart

	return alignPos, alignOri, antiGrav
end

----------------------------------------------------------------------
-- ANCHORING HELPERS
----------------------------------------------------------------------

local function anchorShip(ship: Model, alignPos, alignOri, antiGrav)
	local primary = ship.PrimaryPart
	primary.AssemblyLinearVelocity = Vector3.zero
	primary.AssemblyAngularVelocity = Vector3.zero
	alignPos.Enabled = false
	alignOri.Enabled = false
	antiGrav.Enabled = false
	primary.Anchored = true
end

local function unanchorShip(ship: Model, alignPos, alignOri, antiGrav)
	local primary = ship.PrimaryPart
	alignPos.Position = primary.Position
	alignOri.CFrame = primary.CFrame - primary.CFrame.Position
	alignPos.Enabled = true
	alignOri.Enabled = true
	antiGrav.Force = Vector3.new(0, primary.AssemblyMass * workspace.Gravity, 0)
	antiGrav.Enabled = true
	primary.Anchored = false
	primary.AssemblyLinearVelocity = Vector3.zero
	primary.AssemblyAngularVelocity = Vector3.zero
end

----------------------------------------------------------------------
-- ROUTE MOVER
-- Manages one active ship on one route. Handles ship swapping at node 1.
----------------------------------------------------------------------

local function PickShipName()
	local names = {"The Adequate","Sea Biscuit","Terms & Conditions","The Wayward Pearl","The Black Peril","Profit Margin",
		"Totally Normal","The Millennial Falcon","Alienated","Total Recoil","Terminal Velocity","Total Re-haul","Star Chores",
		"The Perishable","The Redacted","Freight Night","Thriller Killer","The Void","Footnote","The Negligent","Lightspeed",
		"The Near Miss","Hound Dog","Miner Setback","Haul Pass","The Load Bearer","Dead Weight","Pilot Error","Crash Course",
		"Flight Risk","Pier Pressure","Slip Up","Stellar Performance","Maximum Effort","Mass Effect","Over Board","Dead Reckoning",
		"Point of No Return","Fixed Course","Grounded","Lost Cause","Course Correction","To Err is Human","nil","Fools Gold",
		"Friendly Fire","Overkill","Cease Fire","The Skeleton Crew","Patch Job","Loophole","Stardust","The Moon","The Gate"
	}
	
	-- Pick a random name from the list
	return names[math.random(1, #names)]
end

local RouteMover = {}
RouteMover.__index = RouteMover

function RouteMover.new(routeConfig, nodes, templates)
	local self = setmetatable({}, RouteMover)

	self.RouteName = routeConfig.routeName or "Unnamed"
	self.ShipName = routeConfig.shipName or PickShipName()
	self.Nodes = nodes
	self.Templates = templates
	self.Mode = routeConfig.mode or "loop"
	self.Speed = routeConfig.speed or DEFAULT_SPEED
	self.Direction = 1          -- 1 = forward, -1 = reverse (pingpong)
	self.CurrentIndex = 1
	self.TargetIndex = 2
	self.State = State.DOCKED
	self.Active = true
	self.Type = routeConfig.type or "FOOD"
	self.Dock = routeConfig.dock or "Dock1"

	-- Travel tracking for wobble + dome
	self.TravelStartTime = 0        -- os.clock() when travel began
	self.DomeTriggered = false       -- prevent repeated dome triggers per leg
	self.WobbleActive = false        -- only wobble when leaving/arriving at last node

	-- Spawn initial ship
	self:SpawnShip()

	-- Start after first node's pause
	local firstNode = nodes[1]
	task.delay(firstNode.Pause, function()
		if self.State ~= State.DOCKED then return end
		if self.Ship and self.Ship.Parent then
			unanchorShip(self.Ship, self.AlignPosition, self.AlignOrientation, self.AntiGravity)
			self.State = State.TRAVELING
			self.TravelStartTime = os.clock()
			self.DomeTriggered = false
			self.WobbleActive = (self.CurrentIndex == #self.Nodes) or (self.TargetIndex == #self.Nodes)
			print(("[ShipNode][%s] TRAVELING toward '%s'"):format(self.RouteName, self.Nodes[self.TargetIndex].Name))
		end
	end)

	return self
end

function RouteMover:SpawnShip()
	-- Destroy old ship if exists
	if self.Ship and self.Ship.Parent then
		self.Ship:Destroy()
	end

	local template = pickRandomTemplate(self.Templates)
	if not template then
		warn(("[ShipNode][%s] No valid ship templates!"):format(self.RouteName))
		self.Active = false
		return
	end

	local ship = template:Clone()
	ship.Parent = workspace
	self.Ship = ship

	local primary = ship.PrimaryPart
	if primary.Anchored then
		primary.Anchored = false
	end

	self.FrontOffset = computeFrontOffset(ship)

	local alignPos, alignOri, antiGrav = setupConstraints(primary, self.Speed)
	self.AlignPosition = alignPos
	self.AlignOrientation = alignOri
	self.AntiGravity = antiGrav

	-- Place so the FrontAttachment aligns with the node position.
	-- First set orientation, then figure out where PrimaryPart needs to be
	-- so that FrontAttachment.WorldPosition == node.Position.
	local node = self.Nodes[self.CurrentIndex]
	local startOri = node.YawCFrame * self.FrontOffset
	-- Set orientation first
	primary.CFrame = CFrame.new(primary.Position) * startOri
	-- Now compute offset: where FrontAttachment is vs where we want it
	local frontAtt = primary:FindFirstChild("FrontAttachment")
	if frontAtt then
		local currentAttPos = frontAtt.WorldPosition
		local offset = node.Position - currentAttPos
		primary.CFrame = primary.CFrame + offset
	else
		primary.CFrame = CFrame.new(node.Position) * startOri
	end
	anchorShip(ship, alignPos, alignOri, antiGrav)

	print(("[ShipNode][%s] Spawned '%s' at '%s'"):format(self.RouteName, ship.Name, node.Name))
end

function RouteMover:GetNextIndex(): number?
	local nextIdx = self.CurrentIndex + self.Direction

	if self.Mode == "loop" then
		if nextIdx > #self.Nodes then
			return 1
		elseif nextIdx < 1 then
			return #self.Nodes
		end
		return nextIdx

	elseif self.Mode == "pingpong" then
		if nextIdx > #self.Nodes then
			-- Reverse direction, go to second-to-last (don't repeat last)
			self.Direction = -1
			nextIdx = #self.Nodes - 1
			if nextIdx < 1 then nextIdx = 1 end
			return nextIdx
		elseif nextIdx < 1 then
			-- Reverse direction, go to second (don't repeat first)
			self.Direction = 1
			nextIdx = 2
			if nextIdx > #self.Nodes then nextIdx = #self.Nodes end
			return nextIdx
		end
		return nextIdx
	end

	return nil
end

function RouteMover:IsAtFirstNode(): boolean
	return self.CurrentIndex == 1 and self.Direction == 1
end

function RouteMover:IsAtFinalNode(): boolean
	return self.CurrentIndex == #self.Nodes
end

function RouteMover:Update(dt: number)
	if not self.Active then return end

	local ship = self.Ship
	if not ship or not ship.PrimaryPart or not ship.Parent then
		self.Active = false
		return
	end
	local primary = ship.PrimaryPart

	------------------------------------------------------------
	-- TRAVELING
	------------------------------------------------------------
	if self.State == State.TRAVELING then
		self.AntiGravity.Force = Vector3.new(0, primary.AssemblyMass * workspace.Gravity, 0)

		local targetNode = self.Nodes[self.TargetIndex]
		local targetPos = targetNode.Position
		local now = os.clock()
		local travelElapsed = now - self.TravelStartTime

		-- Wobble: only when leaving from or heading to the last node
		local wobbleStrength = 0
		if self.WobbleActive and travelElapsed < WOBBLE_DURATION then
			wobbleStrength = 1
		end

		local wobbleOffset = CFrame.identity
		if wobbleStrength > 0 then
			wobbleOffset = computeWobble(travelElapsed, wobbleStrength)
		end

		-- Apply wobble to the position target
		local wobbledTargetPos = targetPos + wobbleOffset.Position
		self.AlignPosition.Position = wobbledTargetPos

		local frontAtt = primary:FindFirstChild("FrontAttachment")
		local shipPos = frontAtt and frontAtt.WorldPosition or primary.Position
		local toTarget = targetPos - shipPos  -- use un-wobbled target for direction/distance
		local distance = toTarget.Magnitude

		local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z)
		if flatDir.Magnitude > 1 then
			local travelOri = yawFromDirection(flatDir) * self.FrontOffset
			-- Apply wobble rotation to orientation
			self.AlignOrientation.CFrame = travelOri * (wobbleOffset - wobbleOffset.Position)
		end

		-- Dome/Shield entry check (once per travel leg)
		if not self.DomeTriggered then
			if checkDomeEntry(ship) then
				self.DomeTriggered = true
				print(("[ShipNode][%s] Shield entry triggered!"):format(self.RouteName))
			end
		end

		-- Audit: print distance periodically (every ~0.5s worth of frames)
		if not self._auditTimer then self._auditTimer = 0 end
		self._auditTimer += dt
		if self._auditTimer > 0.5 then
			self._auditTimer = 0
			local vel = primary.AssemblyLinearVelocity
			--print(("[ShipNode][%s] TRAVEL dist=%.1f vel=%.1f attPos=%s nodePos=%s"):format(
			--	self.RouteName, distance, vel.Magnitude,
			--	tostring(Vector3.new(math.round(shipPos.X*10)/10, math.round(shipPos.Y*10)/10, math.round(shipPos.Z*10)/10)),
			--	tostring(Vector3.new(math.round(targetPos.X*10)/10, math.round(targetPos.Y*10)/10, math.round(targetPos.Z*10)/10))
			--	))
		end

		-- Switch to docking when close enough
		if distance < DOCK_DIST then
			local targetOri = targetNode.YawCFrame * self.FrontOffset

			-- 1. Save where ship actually is right now
			local savedCF = primary.CFrame

			-- 2. Temporarily move PrimaryPart to node position with target orientation
			--    so we can read where FrontAttachment ends up
			primary.CFrame = CFrame.new(targetPos) * targetOri
			local attAtTarget = frontAtt and frontAtt.WorldPosition or targetPos

			-- 3. Compute correction: shift needed so FrontAttachment == nodePos
			local correction = targetPos - attAtTarget
			local dockCF = CFrame.new(targetPos + correction) * targetOri

			-- 4. Restore ship to where it was before the temp move
			primary.CFrame = savedCF

			self.DockTargetCF = dockCF

			-- 5. Anchor and disable physics, then start lerp from current position
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
			self.AlignPosition.Enabled = false
			self.AlignOrientation.Enabled = false
			self.AntiGravity.Enabled = false
			primary.Anchored = true

			self.State = State.DOCKING
			self._dockCleanCF = nil  -- reset so it picks up current CFrame on first frame
			self._auditTimer = 0

			print(("[ShipNode][%s] DOCKING at '%s' | dist=%.1f | correction=%s"):format(
				self.RouteName, targetNode.Name, distance,
				tostring(Vector3.new(math.round(correction.X*10)/10, math.round(correction.Y*10)/10, math.round(correction.Z*10)/10))
				))
			print(("[ShipNode][%s]   primaryTarget=%s | nodePos=%s"):format(
				self.RouteName,
				tostring(Vector3.new(math.round(dockCF.Position.X*10)/10, math.round(dockCF.Position.Y*10)/10, math.round(dockCF.Position.Z*10)/10)),
				tostring(Vector3.new(math.round(targetPos.X*10)/10, math.round(targetPos.Y*10)/10, math.round(targetPos.Z*10)/10))
				))
		end

		------------------------------------------------------------
		-- DOCKING: CFrame lerp to exact position, anchored (no physics)
		------------------------------------------------------------
	elseif self.State == State.DOCKING then
		local targetNode = self.Nodes[self.TargetIndex]
		local dockCF = self.DockTargetCF

		-- Track the clean (non-wobbled) lerp position separately
		-- so wobble doesn't corrupt convergence
		if not self._dockCleanCF then
			self._dockCleanCF = primary.CFrame
		end
		local alpha = math.clamp(DOCK_LERP_SPEED * dt, 0, 1)
		self._dockCleanCF = self._dockCleanCF:Lerp(dockCF, alpha)

		local displayCF = self._dockCleanCF

		-- Apply wobble during docking at last node, fading out as we get closer
		if self.WobbleActive then
			local cleanDist = (self._dockCleanCF.Position - dockCF.Position).Magnitude
			local wobbleFade = math.clamp((cleanDist - 1) / (DOCK_DIST - 1), 0, 1)
			if wobbleFade > 0 then
				local now = os.clock()
				local elapsed = now - self.TravelStartTime
				local wobbleOff = computeWobble(elapsed, wobbleFade)
				displayCF = self._dockCleanCF * wobbleOff
			end
		end

		primary.CFrame = displayCF

		-- Check convergence using the CLEAN lerp, not the wobbled display
		local frontAtt = primary:FindFirstChild("FrontAttachment")
		local shipPos = frontAtt and frontAtt.WorldPosition or primary.Position
		local cleanFrontDiff = (self._dockCleanCF.Position - dockCF.Position).Magnitude
		local posDiff = cleanFrontDiff  -- use clean distance for convergence
		local cfDiff = cleanFrontDiff

		-- Audit
		if not self._auditTimer then self._auditTimer = 0 end
		self._auditTimer += dt
		if self._auditTimer > 0.3 then
			self._auditTimer = 0
			print(("[ShipNode][%s] DOCK lerp alpha=%.3f attDist=%.2f cfDist=%.2f attPos=%s"):format(
				self.RouteName, alpha, posDiff, cfDiff,
				tostring(Vector3.new(math.round(shipPos.X*10)/10, math.round(shipPos.Y*10)/10, math.round(shipPos.Z*10)/10))
				))
		end

		if posDiff < 0.5 then
			-- Snap to exact and anchor
			primary.CFrame = dockCF
			primary.Anchored = true

			local finalFrontAtt = primary:FindFirstChild("FrontAttachment")
			local finalPos = finalFrontAtt and finalFrontAtt.WorldPosition or primary.Position
			print(("[ShipNode][%s] DOCKED at '%s' | finalAttPos=%s | nodePos=%s | error=%.3f"):format(
				self.RouteName, targetNode.Name,
				tostring(Vector3.new(math.round(finalPos.X*10)/10, math.round(finalPos.Y*10)/10, math.round(finalPos.Z*10)/10)),
				tostring(Vector3.new(math.round(targetNode.Position.X*10)/10, math.round(targetNode.Position.Y*10)/10, math.round(targetNode.Position.Z*10)/10)),
				(finalPos - targetNode.Position).Magnitude
				))

			self.CurrentIndex = self.TargetIndex
			local nextIdx = self:GetNextIndex()
			if not nextIdx then
				self.Active = false
				print(("[ShipNode][%s] Route complete."):format(self.RouteName))
				return
			end
			self.TargetIndex = nextIdx
			self.State = State.DOCKED
			
			if self.Type == "CARGO" and self:IsAtFinalNode() then
				print("TEST FINAL NODE DOCKING")
				DockManager.dockNPCShip(self.Dock,self.ShipName,self.Ship,self.Nodes[self.CurrentIndex].Pause)
			end

			print(("[ShipNode][%s] DOCKED at '%s' for %.1fs, next: '%s'"):format(
				self.RouteName, targetNode.Name, targetNode.Pause, self.Nodes[nextIdx].Name))

			task.delay(targetNode.Pause, function()
				-- Guard: only proceed if still DOCKED (prevents double-fire)
				if self.State ~= State.DOCKED then return end

				if self:IsAtFirstNode() and #self.Templates > 1 then
					print(("[ShipNode][%s] Back at start — picking new ship"):format(self.RouteName))
					self:SpawnShip()
				end

				if self.Ship and self.Ship.Parent then
					unanchorShip(self.Ship, self.AlignPosition, self.AlignOrientation, self.AntiGravity)
					self.State = State.TRAVELING
					if self.Type == "CARGO" and self:IsAtFinalNode() then
						DockManager.undockNPCShip(self.Dock, true)
					end
					self.TravelStartTime = os.clock()
					self.DomeTriggered = false
					-- Wobble only when leaving from or heading to last node
					self.WobbleActive = (self.CurrentIndex == #self.Nodes) or (self.TargetIndex == #self.Nodes)
					print(("[ShipNode][%s] TRAVELING toward '%s'"):format(self.RouteName, self.Nodes[self.TargetIndex].Name))
				end
			end)
		end

		------------------------------------------------------------
		-- DOCKED
		------------------------------------------------------------
	elseif self.State == State.DOCKED then
		-- Anchored, nothing to do
		
	end
end

----------------------------------------------------------------------
-- INIT
----------------------------------------------------------------------

local function initialize()
	local nodePart = resolvePath(workspace, NODE_FOLDER_PATH)
	if not nodePart then
		warn("[ShipNode] Node part not found: Workspace." .. table.concat(NODE_FOLDER_PATH, "."))
		return {}
	end

	local movers = {}

	for _, routeConfig in ROUTES do
		local nodes = collectNodes(nodePart, routeConfig.nodes)
		if #nodes < 2 then
			warn(("[ShipNode] Route '%s' has fewer than 2 nodes, skipping."):format(routeConfig.name or "?"))
			continue
		end

		local templates = resolveShipTemplates(routeConfig.ships)
		if #templates == 0 then
			warn(("[ShipNode] Route '%s' has no valid ship templates, skipping."):format(routeConfig.name or "?"))
			continue
		end

		print(("[ShipNode] Route '%s' | %d nodes | %d ships | mode: %s | speed: %d"):format(
			routeConfig.name or "?", #nodes, #templates, routeConfig.mode or "loop", routeConfig.speed or DEFAULT_SPEED))
		for i, node in nodes do
			print(("  %d: %s (pause %.1fs)"):format(i, node.Name, node.Pause))
		end
		for _, t in templates do
			print(("  Ship template: '%s'"):format(t.Name))
		end

		local mover = RouteMover.new(routeConfig, nodes, templates)
		table.insert(movers, mover)
	end

	return movers
end

task.wait()
local movers = initialize()

--DockManager.dockNPCShip("Dock1", "CKN7_ChickenHawk")
--DockManager.undockNPCShip("Dock1")

RunService.Heartbeat:Connect(function(dt)
	for _, mover in movers do
		mover:Update(dt)
	end
end)

print(("[ShipNode] System running with %d route(s)."):format(#movers))