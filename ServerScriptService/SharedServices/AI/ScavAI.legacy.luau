-- ShipAI.server.lua
-- Ship AI state machine for enemy NPC ships in Sci Co
-- No Humanoid — uses LinearVelocity + AlignOrientation for physics

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local EnemySpawningConfig = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("EnemySpawningConfig"))
local EnemyCombatFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("EnemyCombatFunctions"))

----------------------------------------------------------------
-- CONTEXT
----------------------------------------------------------------
local ship = script.Parent
local primaryPart = ship.PrimaryPart
assert(primaryPart, "[ShipAI] Ship has no PrimaryPart!")

print("[ShipAI] Script started on:", ship.Name, "PrimaryPart:", primaryPart.Name)

local configId = ship:GetAttribute("ConfigId")
local spawnerCfg = (configId and EnemySpawningConfig.Spawners and EnemySpawningConfig.Spawners[configId]) or nil
local AIConfig = (spawnerCfg and spawnerCfg.AIConfig) or {}

local enemyDef = enemiesModule[ship.Name] or {}

local currentTarget = nil
local deathLocked = false

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
	PATROL_RADIUS        = AIConfig.PATROL_RADIUS or 200,
	PATROL_SPEED         = AIConfig.PATROL_SPEED or (enemyDef.PatrolSpeed or 200),
	-- How close to a waypoint before arcing toward the next one.
	-- Should be large enough that the turn starts before arrival.
	-- Increase for higher patrol speeds.
	PATROL_WAYPOINT_RADIUS = AIConfig.PATROL_WAYPOINT_RADIUS or 60,

	PURSUE_SPEED         = AIConfig.PURSUE_SPEED or (enemyDef.PursueSpeed or 300),
	ATTACK_SPEED         = AIConfig.ATTACK_SPEED or (enemyDef.AttackSpeed or 200),
	EVADE_SPEED          = AIConfig.EVADE_SPEED or (enemyDef.EvadeSpeed or 350),
	FLEE_SPEED           = AIConfig.FLEE_SPEED or (enemyDef.FleeSpeed or 400),
	FLEE_HEALTH_PERCENT  = AIConfig.FLEE_HEALTH_PERCENT or 0.2,

	ATTACK_RANGE         = AIConfig.ATTACK_RANGE or (enemyDef.AttackRange or 300),
	ATTACK_MIN_RANGE     = AIConfig.ATTACK_MIN_RANGE or (enemyDef.AttackMinRange or 80),
	PREFERRED_RANGE      = AIConfig.PREFERRED_RANGE or (enemyDef.PreferredRange or 150),

	SENSOR_RANGE         = AIConfig.SENSOR_RANGE or (enemyDef.SensorRange or 500),
	LOSE_TARGET_RANGE    = AIConfig.LOSE_TARGET_RANGE or 800,

	-- physics
	TURN_SPEED           = AIConfig.TURN_SPEED or 2,
	MAX_FORCE            = AIConfig.MAX_FORCE or 200000,

	-- steering smoothing — how fast the nose swings toward new direction
	-- lower = wider arcing turns, higher = snappier
	STEER_SMOOTH         = AIConfig.STEER_SMOOTH or 1.5,

	-- banking
	MAX_BANK_DEGREES     = AIConfig.MAX_BANK_DEGREES or 25,
	BANK_RESPONSE        = AIConfig.BANK_RESPONSE or 5,

	EVADE_DURATION       = AIConfig.EVADE_DURATION or 2.5,

	AI_TICK              = AIConfig.AI_TICK or 0.1,

	DEBUG                = true,
}

local function dprint(...)
	if CONFIG.DEBUG then print("[ShipAI]", ...) end
end

dprint("Config loaded. SensorRange:", CONFIG.SENSOR_RANGE, "PatrolSpeed:", CONFIG.PATROL_SPEED)

----------------------------------------------------------------
-- PHYSICS SETUP
----------------------------------------------------------------
pcall(function() primaryPart:SetNetworkOwner(nil) end)

for _, part in ipairs(ship:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = false
	end
end

local function ensureAttachment(parent, name)
	local a = parent:FindFirstChild(name)
	if a and a:IsA("Attachment") then return a end
	a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	return a
end

local shipAtt = ensureAttachment(primaryPart, "ShipAIAttachment")

local lv = Instance.new("LinearVelocity")
lv.Name = "ShipAI_LV"
lv.Attachment0 = shipAtt
lv.RelativeTo = Enum.ActuatorRelativeTo.World
lv.VectorVelocity = Vector3.zero
lv.MaxForce = CONFIG.MAX_FORCE
lv.Parent = primaryPart

local ao = Instance.new("AlignOrientation")
ao.Name = "ShipAI_AO"
ao.Attachment0 = shipAtt
ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
ao.Responsiveness = CONFIG.TURN_SPEED
ao.MaxTorque = math.huge
ao.RigidityEnabled = false
ao.Parent = primaryPart

local antiGrav = Instance.new("VectorForce")
antiGrav.Name = "ShipAI_AntiGrav"
antiGrav.Attachment0 = shipAtt
antiGrav.RelativeTo = Enum.ActuatorRelativeTo.World
antiGrav.Force = Vector3.new(0, workspace.Gravity * primaryPart.AssemblyMass, 0)
antiGrav.Parent = primaryPart

RunService.Heartbeat:Connect(function()
	if antiGrav.Parent and primaryPart.Parent then
		antiGrav.Force = Vector3.new(0, workspace.Gravity * primaryPart.AssemblyMass, 0)
	end
end)

dprint("Physics setup complete")

----------------------------------------------------------------
-- SMOOTHED STEERING
-- Ship nose gradually arcs toward desired direction rather than
-- snapping instantly. Gives banking something to measure over
-- multiple ticks and makes flight look natural.
----------------------------------------------------------------
local smoothedForward = Vector3.new(0, 0, -1)

local function updateSmoothedForward(targetDir: Vector3, dt: number): Vector3
	if targetDir.Magnitude < 0.01 then return smoothedForward end
	local alpha = 1 - math.exp(-CONFIG.STEER_SMOOTH * dt)
	local blended = smoothedForward + (targetDir.Unit - smoothedForward) * alpha
	if blended.Magnitude < 0.001 then return smoothedForward end
	smoothedForward = blended.Unit
	return smoothedForward
end

----------------------------------------------------------------
-- BANKING
-- Measures lateral change of smoothed forward each tick and
-- rolls the ship into the turn.
----------------------------------------------------------------
local currentBank = 0
local prevForward = Vector3.new(0, 0, -1)

local function faceDirectionBanked(dir: Vector3, dt: number)
	if dir.Magnitude < 0.01 then return end
	local forward = dir.Unit
	local up = Vector3.yAxis

	if math.abs(forward:Dot(up)) > 0.99 then
		up = Vector3.new(0, 0, 1)
	end

	local right = forward:Cross(up)
	if right.Magnitude < 0.01 then
		right = Vector3.new(1, 0, 0)
	else
		right = right.Unit
	end

	local lateralDot = (forward - prevForward):Dot(right)
	prevForward = forward

	local desiredBank = math.clamp(lateralDot * 40, -1, 1)
		* math.rad(CONFIG.MAX_BANK_DEGREES)

	local alpha = 1 - math.exp(-CONFIG.BANK_RESPONSE * dt)
	currentBank = currentBank + (desiredBank - currentBank) * alpha

	local correctedUp = right:Cross(forward).Unit
	local bankCF = CFrame.fromAxisAngle(forward, currentBank)
	local bankedUp = (bankCF * correctedUp).Unit
	local bankedRight = forward:Cross(bankedUp).Unit

	ao.CFrame = CFrame.fromMatrix(Vector3.zero, bankedRight, bankedUp, -forward)
end

----------------------------------------------------------------
-- MOVEMENT HELPERS
----------------------------------------------------------------
local function setVelocity(vel: Vector3)
	lv.VectorVelocity = vel
end

local function getShipPos()
	return primaryPart.Position
end

local function steerToward(targetPos: Vector3, speed: number, dt: number)
	local pos = getShipPos()
	local toTarget = targetPos - pos
	if toTarget.Magnitude < 1 then
		setVelocity(Vector3.zero)
		return
	end
	local dir = updateSmoothedForward(toTarget.Unit, dt)
	setVelocity(dir * speed)
	faceDirectionBanked(dir, dt)
end

local function steerStrafe(fromPos: Vector3, speed: number, sign: number, dt: number)
	local pos = getShipPos()
	local toEnemy = fromPos - pos
	if toEnemy.Magnitude < 0.01 then return end
	local forward = toEnemy.Unit
	local side = forward:Cross(Vector3.yAxis)
	if side.Magnitude < 0.01 then
		side = forward:Cross(Vector3.new(0, 0, 1))
	end
	local dir = updateSmoothedForward(side.Unit * sign, dt)
	setVelocity(dir * speed)
	faceDirectionBanked(forward, dt)
end

----------------------------------------------------------------
-- PLAYER SHIP POSITION HELPERS
-- PilotShipWeld: Part0 = HRP, Part1 = ship PrimaryPart directly
----------------------------------------------------------------
local function getPlayerTargetPosition(player)
	local char = player.Character
	if not char then return nil end
	local phrp = char:FindFirstChild("HumanoidRootPart")
	if not phrp then return nil end
	local weld = phrp:FindFirstChild("PilotShipWeld")
	if weld and weld:IsA("WeldConstraint") and weld.Part1 then
		dprint("Player", player.Name, "piloting, Part1:", weld.Part1.Name, "pos:", weld.Part1.Position)
		return weld.Part1.Position
	end
	dprint("Player", player.Name, "on foot, HRP pos:", phrp.Position)
	return phrp.Position
end

local function getPlayerTargetPart(player)
	local char = player.Character
	if not char then return nil end
	local phrp = char:FindFirstChild("HumanoidRootPart")
	if not phrp then return nil end
	local weld = phrp:FindFirstChild("PilotShipWeld")
	if weld and weld:IsA("WeldConstraint") and weld.Part1 then
		return weld.Part1
	end
	return phrp
end

----------------------------------------------------------------
-- STATE MACHINE
----------------------------------------------------------------
local states = {}
local currentState = nil

local function changeState(name: string)
	local nextState = states[name]
	assert(nextState, ("Unknown state: %s"):format(name))
	if currentState and currentState.OnExit then
		currentState.OnExit()
	end
	currentState = nextState
	dprint("STATE ->", name)
	if currentState.OnEnter then
		currentState.OnEnter()
	end
end

local rng = Random.new()
local startPos = getShipPos()

local function randomWaypoint()
	return startPos + Vector3.new(
		rng:NextNumber(-CONFIG.PATROL_RADIUS, CONFIG.PATROL_RADIUS),
		rng:NextNumber(-30, 30),
		rng:NextNumber(-CONFIG.PATROL_RADIUS, CONFIG.PATROL_RADIUS)
	)
end

----------------------------------------------------------------
-- THREAT SYSTEM
----------------------------------------------------------------
local threatTable = {}
local THREAT_SWITCH_THRESHOLD = 1.5
local THREAT_DECAY_RATE = 0.05
local THREAT_FORGET_TIME = 30
local THREAT_RESET_DISTANCE = 1200

local function updateThreat(player, damageDealt)
	if not player then return end
	local userId = player.UserId
	local now = os.time()

	if not threatTable[userId] then
		threatTable[userId] = { Player = player, Damage = 0, LastHit = now }
	end
	threatTable[userId].Damage = threatTable[userId].Damage + damageDealt
	threatTable[userId].LastHit = now

	local highestThreat, highestPlayer = 0, nil
	for uid, td in pairs(threatTable) do
		local pos = getPlayerTargetPosition(td.Player)
		if pos then
			local dist = (pos - getShipPos()).Magnitude
			if dist > THREAT_RESET_DISTANCE then
				threatTable[uid] = nil
				if currentTarget == td.Player then currentTarget = nil end
			elseif td.Damage > highestThreat then
				highestThreat = td.Damage
				highestPlayer = td.Player
			end
		end
	end

	if currentTarget ~= highestPlayer then
		local currentThreat = 0
		if currentTarget then
			local ct = threatTable[currentTarget.UserId]
			currentThreat = ct and ct.Damage or 0
		end
		if highestPlayer and highestThreat > currentThreat * THREAT_SWITCH_THRESHOLD then
			dprint("Threat switch ->", highestPlayer.Name)
			currentTarget = highestPlayer
			changeState("Pursue")
			return true
		end
	elseif not currentTarget and highestPlayer then
		dprint("Acquired target:", highestPlayer.Name)
		currentTarget = highestPlayer
		changeState("Pursue")
		return true
	end
	return false
end

local function decayThreat()
	local now = os.time()
	for uid, td in pairs(threatTable) do
		local isCurrentTarget = currentTarget and currentTarget.UserId == uid
		if not isCurrentTarget then
			threatTable[uid].Damage = td.Damage * (1 - THREAT_DECAY_RATE * CONFIG.AI_TICK)
			if (now - td.LastHit > THREAT_FORGET_TIME) or td.Damage < 1 then
				threatTable[uid] = nil
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	local uid = player.UserId
	if threatTable[uid] then
		threatTable[uid] = nil
		if currentTarget == player then
			currentTarget = nil
			local highestThreat, highestPlayer = 0, nil
			for _, td in pairs(threatTable) do
				if td.Damage > highestThreat then
					highestThreat = td.Damage
					highestPlayer = td.Player
				end
			end
			currentTarget = highestPlayer
		end
	end
end)

----------------------------------------------------------------
-- HIT DETECTION
----------------------------------------------------------------
local function checkHit()
	local hit = ship:GetAttribute("Hit")
	if not hit then return false end
	local hitByUserId = ship:GetAttribute("HitByUserId")
	local hitDamage = ship:GetAttribute("HitDamage")
	if not hitByUserId or not hitDamage then return false end
	local player = Players:GetPlayerByUserId(hitByUserId)
	if player then
		updateThreat(player, hitDamage)
		ship:SetAttribute("Hit", nil)
		ship:SetAttribute("HitByUserId", nil)
		ship:SetAttribute("HitDamage", nil)
		return true
	end
	return false
end

----------------------------------------------------------------
-- HULL HEALTH
----------------------------------------------------------------
local function getHullPercent()
	local maxHull = ship:GetAttribute("MaxHull") or 100
	local hull = ship:GetAttribute("Hull") or maxHull
	return hull / maxHull
end

----------------------------------------------------------------
-- PASSIVE SENSOR SCAN
----------------------------------------------------------------
local lastSensorScan = 0

local function scanForTargets()
	local now = os.clock()
	if now - lastSensorScan < 1.0 then return end
	lastSensorScan = now

	if currentTarget then return end

	local pos = getShipPos()
	for _, player in ipairs(Players:GetPlayers()) do
		local targetPos = getPlayerTargetPosition(player)
		if targetPos then
			local dist = (targetPos - pos).Magnitude
			dprint("Scan:", player.Name, "dist:", math.floor(dist), "/ range:", CONFIG.SENSOR_RANGE)
			if dist <= CONFIG.SENSOR_RANGE then
				dprint("Target acquired:", player.Name)
				currentTarget = player
				changeState("Pursue")
				return
			end
		end
	end
end

----------------------------------------------------------------
-- STATES
----------------------------------------------------------------

-- Patrol: continuous flight between random waypoints, never stopping.
-- Picks the next waypoint when close enough to start arcing toward it,
-- so turns are smooth and the ship never pauses mid-flight.
local patrolTarget = nil

states.Patrol = {
	Name = "Patrol",
	OnEnter = function()
		patrolTarget = randomWaypoint()
		dprint("Patrol -> first waypoint:", patrolTarget)
	end,
	OnUpdate = function(dt)
		local pos = getShipPos()
		local dist = (patrolTarget - pos).Magnitude

		-- When close enough, redirect toward a new waypoint without stopping.
		-- The smoothed steering handles the arc naturally.
		if dist < CONFIG.PATROL_WAYPOINT_RADIUS then
			patrolTarget = randomWaypoint()
			dprint("Patrol -> arcing to new waypoint:", patrolTarget)
		end

		steerToward(patrolTarget, CONFIG.PATROL_SPEED, dt)
	end,
	OnExit = function()
		setVelocity(Vector3.zero)
	end,
}

states.Pursue = {
	Name = "Pursue",
	OnEnter = function()
		dprint("Pursuing:", currentTarget and currentTarget.Name or "nil")
	end,
	OnUpdate = function(dt)
		if not currentTarget or not currentTarget.Character then
			currentTarget = nil
			changeState("Patrol")
			return
		end

		local targetPart = getPlayerTargetPart(currentTarget)
		if not targetPart then
			changeState("Patrol")
			return
		end

		local pos = getShipPos()
		local dist = (targetPart.Position - pos).Magnitude

		dprint("Pursue dist:", math.floor(dist), "/ attackRange:", CONFIG.ATTACK_RANGE)

		if dist > CONFIG.LOSE_TARGET_RANGE then
			dprint("Target out of range, returning to patrol")
			currentTarget = nil
			changeState("Patrol")
			return
		end

		if getHullPercent() <= CONFIG.FLEE_HEALTH_PERCENT then
			changeState("Flee")
			return
		end

		if dist <= CONFIG.ATTACK_RANGE then
			changeState("Attack")
			return
		end

		steerToward(targetPart.Position, CONFIG.PURSUE_SPEED, dt)
	end,
	OnExit = function()
		setVelocity(Vector3.zero)
	end,
}

local lastAttackTime = 0
local attackStrafeSign = 1
local lastStrafeChange = 0

states.Attack = {
	Name = "Attack",
	OnEnter = function()
		dprint("Attack started")
		lastAttackTime = 0
		attackStrafeSign = rng:NextInteger(0, 1) == 0 and 1 or -1
		lastStrafeChange = os.clock()
	end,
	OnUpdate = function(dt)
		if not currentTarget or not currentTarget.Character then
			currentTarget = nil
			changeState("Patrol")
			return
		end

		local targetPart = getPlayerTargetPart(currentTarget)
		if not targetPart then
			changeState("Patrol")
			return
		end

		local pos = getShipPos()
		local dist = (targetPart.Position - pos).Magnitude

		if getHullPercent() <= CONFIG.FLEE_HEALTH_PERCENT then
			changeState("Flee")
			return
		end

		if dist > CONFIG.LOSE_TARGET_RANGE then
			currentTarget = nil
			changeState("Patrol")
			return
		end

		if dist > CONFIG.ATTACK_RANGE then
			changeState("Pursue")
			return
		end

		if ship:GetAttribute("TakingFire") then
			ship:SetAttribute("TakingFire", nil)
			changeState("Evade")
			return
		end

		if os.clock() - lastStrafeChange > rng:NextNumber(1.5, 3.5) then
			attackStrafeSign = -attackStrafeSign
			lastStrafeChange = os.clock()
		end

		if dist < CONFIG.ATTACK_MIN_RANGE then
			-- Too close — back away while strafing
			local awayDir = (pos - targetPart.Position).Unit
			local side = awayDir:Cross(Vector3.yAxis).Unit * attackStrafeSign
			local desired = (awayDir * 0.6 + side * 0.4).Unit
			local dir = updateSmoothedForward(desired, dt)
			setVelocity(dir * CONFIG.ATTACK_SPEED)
			faceDirectionBanked((targetPart.Position - pos).Unit, dt)
		elseif dist > CONFIG.PREFERRED_RANGE then
			-- Close in while strafing
			local toTarget = (targetPart.Position - pos).Unit
			local side = toTarget:Cross(Vector3.yAxis).Unit * attackStrafeSign
			local desired = (toTarget * 0.7 + side * 0.3).Unit
			local dir = updateSmoothedForward(desired, dt)
			setVelocity(dir * CONFIG.ATTACK_SPEED)
			faceDirectionBanked(toTarget, dt)
		else
			-- In preferred range — pure strafe
			steerStrafe(targetPart.Position, CONFIG.ATTACK_SPEED * 0.6, attackStrafeSign, dt)
		end

		-- Fire on cooldown
		local attackCooldown = 1.0 / (enemyDef.AttackSpeed or 1.0)
		local now = os.clock()
		if now - lastAttackTime >= attackCooldown then
			lastAttackTime = now
			dprint("Firing at", currentTarget.Name, "dist:", math.floor(dist))
			local targetVel = targetPart.AssemblyLinearVelocity
			local bulletSpeed = enemyDef.BulletSpeed or 600
			local leadTime = dist / math.max(bulletSpeed, 1)
			local aimPos = targetPart.Position + targetVel * leadTime
			local firingPos = primaryPart.Position + primaryPart.CFrame.LookVector * 5
			EnemyCombatFunctions.HandleRanged(ship, aimPos, bulletSpeed, enemyDef.RangedAmmo, firingPos)
		end
	end,
	OnExit = function()
		setVelocity(Vector3.zero)
	end,
}

local evadeUntil = 0
local evadeDir = Vector3.zero

states.Evade = {
	Name = "Evade",
	OnEnter = function()
		dprint("Evading!")
		evadeUntil = os.clock() + CONFIG.EVADE_DURATION
		evadeDir = Vector3.new(
			rng:NextNumber(-1, 1),
			rng:NextNumber(-0.5, 0.5),
			rng:NextNumber(-1, 1)
		).Unit
	end,
	OnUpdate = function(dt)
		if os.clock() >= evadeUntil then
			if currentTarget and currentTarget.Character then
				changeState("Attack")
			else
				changeState("Patrol")
			end
			return
		end
		if getHullPercent() <= CONFIG.FLEE_HEALTH_PERCENT then
			changeState("Flee")
			return
		end
		local dir = updateSmoothedForward(evadeDir, dt)
		setVelocity(dir * CONFIG.EVADE_SPEED)
		faceDirectionBanked(dir, dt)
	end,
	OnExit = function()
		setVelocity(Vector3.zero)
	end,
}

states.Flee = {
	Name = "Flee",
	OnEnter = function()
		dprint("Fleeing! Hull:", math.floor(getHullPercent() * 100) .. "%")
	end,
	OnUpdate = function(dt)
		if getHullPercent() > CONFIG.FLEE_HEALTH_PERCENT + 0.1 then
			changeState("Attack")
			return
		end
		if not currentTarget or not currentTarget.Character then
			currentTarget = nil
			changeState("Patrol")
			return
		end
		local targetPart = getPlayerTargetPart(currentTarget)
		if targetPart then
			local awayDir = (getShipPos() - targetPart.Position).Unit
			local dir = updateSmoothedForward(awayDir, dt)
			setVelocity(dir * CONFIG.FLEE_SPEED)
			faceDirectionBanked(dir, dt)
		else
			currentTarget = nil
			changeState("Patrol")
		end
	end,
	OnExit = function()
		setVelocity(Vector3.zero)
	end,
}

----------------------------------------------------------------
-- ALIVE CHECK
----------------------------------------------------------------
local function checkAlive()
	if ship:GetAttribute("Dead") and not deathLocked then
		deathLocked = true
		dprint("Ship destroyed")
		setVelocity(Vector3.zero)
		lv:Destroy()
		ao:Destroy()
		antiGrav:Destroy()
		return false
	end
	return not deathLocked
end

----------------------------------------------------------------
-- BOOT
----------------------------------------------------------------
dprint("Booting state machine, startPos:", startPos)
changeState("Patrol")
dprint("Boot complete")

----------------------------------------------------------------
-- AI TICK LOOP
----------------------------------------------------------------
local lastTick = os.clock()

task.spawn(function()
	dprint("AI tick loop started")
	while checkAlive() and ship.Parent do
		local now = os.clock()
		local dt = now - lastTick
		lastTick = now

		pcall(function()
			if primaryPart:GetNetworkOwner() ~= nil then
				primaryPart:SetNetworkOwner(nil)
			end
		end)

		decayThreat()
		checkHit()
		scanForTargets()

		if currentState and currentState.OnUpdate then
			currentState.OnUpdate(dt)
		end

		task.wait(CONFIG.AI_TICK)
	end

	dprint("Ship AI loop ended")
	ship.PrimaryPart.Anchored = true
	Debris:AddItem(ship, 10)
end)