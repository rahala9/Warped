---- ServerScriptService/TrafficService.lua
---- Same logic, with auditing. + smoother parking (no snap) + vehicle pool support
---- FIX #1: AlignOrientation uses TwoAttachment mode (Attachment1 = goalAtt). Do NOT drive AlignOri.CFrame anymore.
---- Facing: uses TrafficFront attachment on the vehicle root. NO LookVector used.
---- UPDATE: Smooth turns (deadzone + max turn rate + optional near-node blend)

--local RunService = game:GetService("RunService")
--local ServerScriptService = game:GetService("ServerScriptService")
--local ShieldFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("ShieldFunctions"))

--local DOME = workspace:WaitForChild("Areas")
--	:WaitForChild("StarhopStation")
--	:WaitForChild("DomeShield"):WaitForChild("ShieldHitBox") :: BasePart

--local DOME_MARGIN = 1

--local TrafficService = {}
--TrafficService.__index = TrafficService

------------------------------------------------------------------
---- DEBUG
------------------------------------------------------------------
--local DEBUG = false
--local AUDIT_EVERY = 1.0

--local function dprint(...)
--	if DEBUG then
--		print("[TrafficService]", ...)
--	end
--end

--local function dwarn(...)
--	if DEBUG then
--		warn("[TrafficService]", ...)
--	end
--end

------------------------------------------------------------------
---- smoother park settings
------------------------------------------------------------------
--local SETTLE_TIME_DEFAULT = 0.75
--local SNAP_EPSILON_DEFAULT = 0.25
--local ARRIVAL_SPEED_DEFAULT = 0.75

------------------------------------------------------------------
---- NEW: smooth turning settings
------------------------------------------------------------------
--local FACE_DEADZONE_DIR = 0.06         -- below this, keep previous yaw
--local FACE_MAX_TURN_RATE = 2.5         -- radians/sec
--local FACE_BLEND_DIST = 6.0            -- within this distance, blend toward node yaw (if faceMovementDirection true)

------------------------------------------------------------------
---- types
------------------------------------------------------------------
--export type NodeRef = Attachment | BasePart | CFrame
--export type EffectFn = (t: number, strength: number, vehicleState: any) -> CFrame

--export type VehiclePool = {
--	storage: Folder,
--	spawnParent: Instance?,
--}

--export type VehicleConfig = {
--	nodes: { NodeRef },
--	pauseTimes: { number }?,
--	defaultPause: number?,
--	mode: "loop" | "pingpong"?,
--	anchorWhilePaused: boolean?,

--	startSpeed: number?,
--	cruiseSpeed: number?,
--	accelTime: number?,
--	arrivalDistance: number?,
--	moveTimeout: number?,

--	maxForce: number?,
--	posResponsiveness: number?,
--	oriResponsiveness: number?,
--	maxAngularVelocity: number?,

--	leaveEffectTime: number?,
--	enterEffectTime: number?,
--	leaveEffect: EffectFn?,
--	enterEffect: EffectFn?,

--	settleTime: number?,
--	snapEpsilon: number?,
--	arrivalSpeed: number?,

--	vehiclePool: VehiclePool?,

--	faceMovementDirection: boolean?, -- if true, vehicle rotates to face travel direction

--	onEnter: ((model: Model, nodeIndex: number) -> ())?,
--	onLeave: ((model: Model, nodeIndex: number) -> ())?,
--}

--type VehicleState = {
--	id: number,
--	model: Model,
--	root: BasePart,
--	cfg: VehicleConfig,

--	truckAtt: Attachment,
--	goalPart: BasePart,
--	goalAtt: Attachment,
--	alignPos: AlignPosition,
--	alignOri: AlignOrientation,

--	nodeIndex: number,
--	dir: number,
--	moving: boolean,
--	pausedUntil: number,

--	targetPos: Vector3,
--	targetRot: CFrame,
--	basePos: Vector3,
--	moveStartT: number,

--	leaveEffectStartT: number?,
--	enterEffectStartT: number?,

--	_lastAuditT: number?,
--	_lastFaceRot: CFrame?,

--	-- NEW: yaw state for smooth turning
--	_lastYaw: number?,
--}

------------------------------------------------------------------
---- internal registry
------------------------------------------------------------------
--local _nextId = 1
--local _vehicles: { [number]: VehicleState } = {}
--local _hbConn: RBXScriptConnection? = nil

------------------------------------------------------------------
---- utility
------------------------------------------------------------------
--local function clamp01(x: number): number
--	return math.max(0, math.min(1, x))
--end

--local function lerp(a: number, b: number, t: number): number
--	return a + (b - a) * t
--end

--local function setAnchored(model: Model, anchored: boolean)
--	for _, d in ipairs(model:GetDescendants()) do
--		if d:IsA("BasePart") then
--			d.Anchored = anchored
--		end
--	end
--end

--local function isAnyPartUnanchored(model: Model): boolean
--	for _, d in ipairs(model:GetDescendants()) do
--		if d:IsA("BasePart") and not d.Anchored then
--			return true
--		end
--	end
--	return false
--end

--local function killVelocities(root: BasePart)
--	root.AssemblyLinearVelocity = Vector3.zero
--	root.AssemblyAngularVelocity = Vector3.zero
--end

--local function getNodeCFrame(node: NodeRef): CFrame
--	if typeof(node) == "CFrame" then
--		return node
--	end
--	if typeof(node) == "Instance" then
--		if node:IsA("Attachment") then
--			return node.WorldCFrame
--		elseif node:IsA("BasePart") then
--			return node.CFrame
--		end
--	end
--	error("Invalid node type. Use Attachment, BasePart, or CFrame.")
--end

------------------------------------------------------------------
---- NEW: angle helpers (smooth turning)
------------------------------------------------------------------
--local function wrapAngle(a: number): number
--	local pi = math.pi
--	a = (a + pi) % (2 * pi)
--	if a < 0 then a += 2 * pi end
--	return a - pi
--end

--local function stepYaw(current: number, target: number, dt: number, maxRate: number): number
--	local diff = wrapAngle(target - current)
--	local maxStep = maxRate * dt
--	if diff > maxStep then diff = maxStep end
--	if diff < -maxStep then diff = -maxStep end
--	return current + diff
--end

--local function lerpAngle(a: number, b: number, t: number): number
--	local diff = wrapAngle(b - a)
--	return a + diff * t
--end

---- IMPORTANT: your facing convention in this script is "+Z is front"
---- If dir = (0,0,1), yaw should be 0.
--local function yawFromDirXZ_forPlusZ(dir: Vector3): number
--	local d = Vector3.new(dir.X, 0, dir.Z)
--	if d.Magnitude < 1e-6 then
--		return 0
--	end
--	d = d.Unit
--	return math.atan2(d.X, d.Z)
--end

--local function yawFromCFramePlusZ(cf: CFrame, fallback: number?): number
--	-- extract the world +Z axis without LookVector:
--	local z = cf:VectorToWorldSpace(Vector3.new(0, 0, 1))
--	local flat = Vector3.new(z.X, 0, z.Z)
--	if flat.Magnitude < 1e-6 then
--		return fallback or 0
--	end
--	return yawFromDirXZ_forPlusZ(flat.Unit)
--end

------------------------------------------------------------------
---- Front-facing helpers (NO LookVector)
---- Rule: use TrafficFront attachment on root; its +Z axis is the "front".
---- Optional: set model attribute TrafficFrontFlipZ=true to flip 180° for vehicles that are backwards.
------------------------------------------------------------------
--local function getFrontAttachment(root: BasePart): Attachment?
--	local a = root:FindFirstChild("TrafficFront")
--	if a and a:IsA("Attachment") then
--		return a
--	end
--	return nil
--end

--local function getFlipZ(model: Model): boolean
--	local v = model:GetAttribute("TrafficFrontFlipZ")
--	if v == nil and model.PrimaryPart then
--		v = model.PrimaryPart:GetAttribute("TrafficFrontFlipZ")
--	end
--	return v == true
--end

--local function yawGoalRotFromDir(dir: Vector3): CFrame
--	local d = Vector3.new(dir.X, 0, dir.Z)
--	if d.Magnitude < 1e-6 then
--		return CFrame.identity
--	end
--	d = d.Unit

--	-- Build basis with +Z along travel direction
--	local z = d
--	local up = Vector3.yAxis
--	if math.abs(up:Dot(z)) > 0.98 then
--		up = Vector3.xAxis
--	end
--	local x = up:Cross(z).Unit
--	local y = z:Cross(x).Unit
--	return CFrame.fromMatrix(Vector3.zero, x, y, z)
--end

--local function faceTravelWithFrontAttachment(frontLocal: CFrame, travelDir: Vector3, flipZ: boolean): CFrame
--	local goalRot = yawGoalRotFromDir(travelDir)

--	local effectiveFront = frontLocal
--	if flipZ then
--		effectiveFront = frontLocal * CFrame.Angles(0, math.pi, 0)
--	end

--	-- Want: rootRot * effectiveFront == goalRot
--	return goalRot * effectiveFront:Inverse()
--end

------------------------------------------------------------------
---- vehicle pool helpers
------------------------------------------------------------------
--local function getRandomVehicleFromPool(pool: VehiclePool): Model
--	local vehicles = pool.storage:GetChildren()

--	local validVehicles = {}
--	for _, v in ipairs(vehicles) do
--		if v:IsA("Model") and v.PrimaryPart then
--			table.insert(validVehicles, v)
--		end
--	end

--	if #validVehicles == 0 then
--		error("No valid vehicles in pool: " .. pool.storage:GetFullName())
--	end

--	local chosen = validVehicles[math.random(1, #validVehicles)]
--	local clone = chosen:Clone()
--	clone.Parent = pool.spawnParent or workspace
--	dprint("Spawned vehicle from pool:", clone.Name)
--	return clone
--end

--local function cleanupVehicle(model: Model)
--	dprint("Cleaning up vehicle:", model.Name)
--	model:Destroy()
--end

------------------------------------------------------------------
---- default wobble effect (unchanged, because you said this version was stable)
------------------------------------------------------------------
--local function defaultWobbleEffect(t: number, strength: number, state: VehicleState): CFrame
--	local cfg = state.cfg
--	local wobbleRadiusStuds = (cfg :: any).wobbleRadiusStuds or 1.8
--	local wobbleHeightStuds = (cfg :: any).wobbleHeightStuds or 0.25
--	local wobbleRotDegrees  = (cfg :: any).wobbleRotDegrees  or 2.5
--	local wobbleSpeed       = (cfg :: any).wobbleSpeed       or 1.4

--	local tt = t * wobbleSpeed
--	local sx1 = math.sin(tt * 1.7)
--	local sx2 = math.sin(tt * 2.9)
--	local sz1 = math.sin(tt * 1.3)
--	local sz2 = math.sin(tt * 2.3)
--	local sy  = math.sin(tt * 2.1)

--	local wobbleX = (sx1 * 0.7 + sx2 * 0.3) * wobbleRadiusStuds * strength
--	local wobbleZ = (sz1 * 0.7 + sz2 * 0.3) * wobbleRadiusStuds * strength
--	local wobbleY = sy * wobbleHeightStuds * strength

--	local pitch = math.rad((sz1 * 0.6 + sz2 * 0.4) * wobbleRotDegrees * strength)
--	local roll  = math.rad((sx1 * 0.6 + sx2 * 0.4) * wobbleRotDegrees * strength)

--	return CFrame.new(wobbleX, wobbleY, wobbleZ) * CFrame.Angles(pitch, 0, roll)
--end

------------------------------------------------------------------
---- ensure goals folder
------------------------------------------------------------------
--local function getGoalsFolder(): Folder
--	local f = workspace:FindFirstChild("_TrafficGoals")
--	if f and f:IsA("Folder") then return f end
--	f = Instance.new("Folder")
--	f.Name = "_TrafficGoals"
--	f.Parent = workspace
--	return f
--end

------------------------------------------------------------------
---- build machinery
------------------------------------------------------------------
--local function buildVehicleState(model: Model, cfg: VehicleConfig): VehicleState
--	assert(model.PrimaryPart, "Model.PrimaryPart is required")

--	local root = model.PrimaryPart

--	local truckAtt = root:FindFirstChild("TrafficTruckAttachment") :: Attachment
--	if not truckAtt then
--		truckAtt = Instance.new("Attachment")
--		truckAtt.Name = "TrafficTruckAttachment"
--		truckAtt.Parent = root
--	end

--	local goalsFolder = getGoalsFolder()

--	local goalPart = Instance.new("Part")
--	goalPart.Name = "Goal_" .. model.Name
--	goalPart.Size = Vector3.one
--	goalPart.Transparency = 1
--	goalPart.CanCollide = false
--	goalPart.CanTouch = false
--	goalPart.CanQuery = false
--	goalPart.Anchored = true
--	goalPart.Parent = goalsFolder

--	local goalAtt = Instance.new("Attachment")
--	goalAtt.Name = "TrafficGoalAttachment"
--	goalAtt.Parent = goalPart

--	local alignPos = Instance.new("AlignPosition")
--	alignPos.Name = "TrafficAlignPosition"
--	alignPos.Attachment0 = truckAtt
--	alignPos.Attachment1 = goalAtt
--	alignPos.ApplyAtCenterOfMass = true
--	alignPos.ReactionForceEnabled = false
--	alignPos.RigidityEnabled = false
--	alignPos.MaxForce = cfg.maxForce or 2e6
--	alignPos.Responsiveness = cfg.posResponsiveness or 10
--	alignPos.Enabled = false
--	alignPos.Parent = root

--	local alignOri = Instance.new("AlignOrientation")
--	alignOri.Name = "TrafficAlignOrientation"
--	alignOri.Attachment0 = truckAtt
--	alignOri.Attachment1 = goalAtt
--	alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
--	alignOri.ReactionTorqueEnabled = false
--	alignOri.RigidityEnabled = false
--	alignOri.MaxTorque = cfg.maxForce or 2e6
--	alignOri.MaxAngularVelocity = cfg.maxAngularVelocity or 8
--	alignOri.Responsiveness = cfg.oriResponsiveness or 10
--	alignOri.Enabled = false
--	alignOri.Parent = root

--	local id = _nextId
--	_nextId += 1

--	local st: VehicleState = {
--		id = id,
--		model = model,
--		root = root,
--		cfg = cfg,

--		truckAtt = truckAtt,
--		goalPart = goalPart,
--		goalAtt = goalAtt,
--		alignPos = alignPos,
--		alignOri = alignOri,

--		nodeIndex = 1,
--		dir = 1,
--		moving = false,
--		pausedUntil = 0,

--		targetPos = Vector3.zero,
--		targetRot = CFrame.identity,
--		basePos = Vector3.zero,
--		moveStartT = 0,

--		_lastAuditT = 0,
--		_lastFaceRot = nil,

--		_lastYaw = nil,
--	}

--	return st
--end

------------------------------------------------------------------
---- dome helper
------------------------------------------------------------------
--local function getSphereRadius(dome: BasePart): number
--	return math.max(dome.Size.X, dome.Size.Y, dome.Size.Z) * 0.5
--end

--local function isVehicleRightOutsideDome(vehicle: Model, dome: BasePart, margin: number)
--	margin = margin or 10

--	local center = dome.Position
--	local radius = getSphereRadius(dome)

--	local boxCF, boxSize = vehicle:GetBoundingBox()
--	local half = boxSize * 0.5

--	local localCenter = boxCF:PointToObjectSpace(center)
--	local clampedLocal = Vector3.new(
--		math.clamp(localCenter.X, -half.X, half.X),
--		math.clamp(localCenter.Y, -half.Y, half.Y),
--		math.clamp(localCenter.Z, -half.Z, half.Z)
--	)

--	local closestPoint = boxCF:PointToWorldSpace(clampedLocal)
--	local toVehicle = closestPoint - center
--	local dist = toVehicle.Magnitude

--	if dist > radius and dist <= radius + margin then
--		local normal = toVehicle.Unit
--		local hitPoint = center + normal * radius
--		return true, dist - radius, hitPoint, normal
--	end

--	return false, dist - radius, nil, nil
--end

------------------------------------------------------------------
---- scheduling
------------------------------------------------------------------
--local function getPause(cfg: VehicleConfig, nodeIndex: number): number
--	local pauseTimes = cfg.pauseTimes
--	if pauseTimes and pauseTimes[nodeIndex] ~= nil then
--		return pauseTimes[nodeIndex]
--	end
--	return cfg.defaultPause or 0
--end

--local function advanceIndex(st: VehicleState)
--	local n = #st.cfg.nodes
--	if n <= 1 then return end

--	local mode = st.cfg.mode or "loop"
--	local nextIndex = st.nodeIndex + st.dir

--	if mode == "loop" then
--		if nextIndex > n then nextIndex = 1 end
--		if nextIndex < 1 then nextIndex = n end
--		st.nodeIndex = nextIndex
--		return
--	end

--	-- pingpong
--	if nextIndex > n then
--		st.dir = -1
--		st.nodeIndex = n - 1
--	elseif nextIndex < 1 then
--		st.dir = 1
--		st.nodeIndex = 2
--	else
--		st.nodeIndex = nextIndex
--	end
--end

------------------------------------------------------------------
---- park / begin move
------------------------------------------------------------------
--local function parkAtCurrentNode(st: VehicleState, reason: string?)
--	local cfg = st.cfg
--	local nodeCF = getNodeCFrame(cfg.nodes[st.nodeIndex])

--	-- If using pool and back at node 1, swap vehicle
--	if cfg.vehiclePool and st.nodeIndex == 1 and reason == "arrive" then
--		local oldModel = st.model
--		local newModel = getRandomVehicleFromPool(cfg.vehiclePool)
--		newModel:PivotTo(nodeCF)

--		st.model = newModel
--		st.root = newModel.PrimaryPart
--		st._lastFaceRot = nil
--		st._lastYaw = nil

--		local truckAtt = st.root:FindFirstChild("TrafficTruckAttachment") :: Attachment
--		if not truckAtt then
--			truckAtt = Instance.new("Attachment")
--			truckAtt.Name = "TrafficTruckAttachment"
--			truckAtt.Parent = st.root
--		end
--		st.truckAtt = truckAtt

--		st.alignPos.Attachment0 = truckAtt
--		st.alignOri.Attachment0 = truckAtt
--		st.alignPos.Parent = st.root
--		st.alignOri.Parent = st.root

--		st.alignPos.Attachment1 = st.goalAtt
--		st.alignOri.Attachment1 = st.goalAtt

--		cleanupVehicle(oldModel)
--	end

--	-- snap goal part to node
--	st.goalPart.CFrame = nodeCF

--	-- Keep yaw state consistent with node at park
--	st._lastYaw = yawFromCFramePlusZ(nodeCF.Rotation, st._lastYaw)

--	st.moving = false
--	st.pausedUntil = os.clock() + getPause(cfg, st.nodeIndex)

--	local anchorPaused = (cfg.anchorWhilePaused ~= false)

--	if anchorPaused then
--		local settleTime = cfg.settleTime
--		if settleTime == nil then settleTime = SETTLE_TIME_DEFAULT end

--		local snapEps = cfg.snapEpsilon
--		if snapEps == nil then snapEps = SNAP_EPSILON_DEFAULT end

--		setAnchored(st.model, false)
--		st.alignPos.Enabled = true
--		st.alignOri.Enabled = true
--		st.root.AssemblyAngularVelocity *= 0.25

--		if settleTime > 0 then
--			task.delay(settleTime, function()
--				if st.moving then return end

--				setAnchored(st.model, true)
--				st.alignPos.Enabled = false
--				st.alignOri.Enabled = false
--				killVelocities(st.root)

--				local pivot = st.model:GetPivot()
--				local errPos = (pivot.Position - nodeCF.Position).Magnitude
--				if errPos > snapEps then
--					st.model:PivotTo(nodeCF)
--				end
--			end)
--		else
--			setAnchored(st.model, true)
--			st.alignPos.Enabled = false
--			st.alignOri.Enabled = false
--			killVelocities(st.root)

--			local errPos = (st.model:GetPivot().Position - nodeCF.Position).Magnitude
--			if errPos > snapEps then
--				st.model:PivotTo(nodeCF)
--			end
--		end
--	else
--		setAnchored(st.model, false)
--		st.alignPos.Enabled = true
--		st.alignOri.Enabled = true
--		killVelocities(st.root)
--	end

--	if cfg.onEnter then
--		cfg.onEnter(st.model, st.nodeIndex)
--	end

--	if (cfg.enterEffectTime or 0) > 0 then
--		st.enterEffectStartT = os.clock()
--	else
--		st.enterEffectStartT = nil
--	end

--	dprint("Park", "id", st.id, "node", st.nodeIndex, "reason", reason or "-")
--end

--local function beginMoveToNext(st: VehicleState)
--	local cfg = st.cfg
--	local n = #cfg.nodes

--	if n <= 1 then
--		dwarn("beginMoveToNext: only 1 node; staying put. id=" .. st.id)
--		st.pausedUntil = os.clock() + (cfg.defaultPause or 1)
--		return
--	end

--	if cfg.onLeave then
--		cfg.onLeave(st.model, st.nodeIndex)
--	end

--	local fromIndex = st.nodeIndex
--	advanceIndex(st)
--	local toIndex = st.nodeIndex

--	local targetCF = getNodeCFrame(cfg.nodes[toIndex])
--	st.targetPos = targetCF.Position
--	st.targetRot = targetCF.Rotation

--	setAnchored(st.model, false)
--	killVelocities(st.root)

--	-- start goal at current vehicle pivot to avoid yank
--	st.goalPart.CFrame = st.model:GetPivot()
--	st.basePos = st.goalPart.Position

--	-- Initialize yaw from current goal orientation (stable start)
--	st._lastYaw = yawFromCFramePlusZ(st.goalPart.CFrame.Rotation, st._lastYaw)

--	st.moveStartT = os.clock()
--	st.leaveEffectStartT = os.clock()
--	st._lastAuditT = st.moveStartT

--	st.alignPos.Enabled = true
--	st.alignOri.Enabled = true

--	st.moving = true

--	local dist = (st.targetPos - st.basePos).Magnitude
--	dprint("BeginMove", "id", st.id, "from", fromIndex, "to", toIndex, "dist", string.format("%.2f", dist))
--end

------------------------------------------------------------------
---- moving update
------------------------------------------------------------------
--local function updateVehicleMoving(st: VehicleState, dt: number)
--	local cfg = st.cfg
--	local now = os.clock()
--	local elapsed = now - st.moveStartT

--	local moveTimeout = cfg.moveTimeout or 120
--	if elapsed > moveTimeout then
--		dwarn("Timeout", "id", st.id, "elapsed", string.format("%.2f", elapsed))
--		parkAtCurrentNode(st, "timeout")
--		return
--	end

--	local outside, _, hitPoint, normal = isVehicleRightOutsideDome(st.model, DOME, 5)
--	if outside and hitPoint and normal then
--		ShieldFunctions.PlacePatchOnDome(DOME.Parent, DOME.Parent.Shield, hitPoint, normal, CFrame.Angles(0, math.pi, 0))

--		local ripple = ShieldFunctions.ShieldRipple.new({
--			model = DOME.Parent.ShieldVisual,
--			visibleTransparency = 0,
--			hiddenTransparency = 1,
--			ringDelay = 0.07,
--			fadeInTime = 0.10,
--			holdTime = 0.05,
--			fadeOutTime = 0.18,
--		})
--		ripple:Rip()
--	end

--	local accelTime = cfg.accelTime or 2.5
--	local startSpeed = cfg.startSpeed or 2
--	local cruiseSpeed = cfg.cruiseSpeed or 12

--	local accelT = clamp01(elapsed / math.max(0.001, accelTime))
--	local speed = lerp(startSpeed, cruiseSpeed, accelT)

--	st.alignPos.MaxVelocity = speed * 1.25

--	local delta = st.targetPos - st.basePos
--	local dist = delta.Magnitude

--	local arrivalDist = cfg.arrivalDistance or 1.0
--	local arrivalSpeed = cfg.arrivalSpeed or ARRIVAL_SPEED_DEFAULT

--	if dist <= arrivalDist and st.root.AssemblyLinearVelocity.Magnitude <= arrivalSpeed then
--		dprint("Arrive", "id", st.id, "node", st.nodeIndex, "elapsed", string.format("%.2f", elapsed))
--		parkAtCurrentNode(st, "arrive")
--		return
--	end

--	-- SAFE normalize
--	local EPS = 1e-3
--	local moveDir = Vector3.zero
--	if dist > EPS then
--		local step = math.min(speed * dt, dist)
--		moveDir = delta / dist
--		st.basePos = st.basePos + moveDir * step
--	else
--		st.basePos = st.targetPos
--		if st.root.AssemblyLinearVelocity.Magnitude > 0.1 then
--			moveDir = st.root.AssemblyLinearVelocity.Unit
--		end
--	end

--	-- effects
--	local leaveTime = cfg.leaveEffectTime or 1.0
--	local leaveEffect = cfg.leaveEffect or defaultWobbleEffect

--	local strength = 0
--	if leaveTime > 0 then
--		local t = now - (st.leaveEffectStartT or now)
--		strength = (t <= leaveTime) and 1 or 0
--	end

--	local effectCF = CFrame.identity
--	if strength > 0 and leaveEffect then
--		effectCF = leaveEffect(elapsed, strength, st)
--	end

--	-- orientation for goalPart (TwoAttachment AlignOrientation reads goalAtt.WorldCFrame)
--	local orientationRot: CFrame

--	if cfg.faceMovementDirection then
--		local travel = Vector3.new(moveDir.X, 0, moveDir.Z)

--		-- 1) compute desired travel yaw (deadzone)
--		local desiredYaw = st._lastYaw or yawFromCFramePlusZ(st.goalPart.CFrame.Rotation, 0)

--		if travel.Magnitude >= FACE_DEADZONE_DIR then
--			desiredYaw = yawFromDirXZ_forPlusZ(travel.Unit)
--		end

--		-- 2) optionally blend toward node yaw as we get close to the node
--		local nodeYaw = yawFromCFramePlusZ(st.targetRot, desiredYaw)
--		local tBlend = 0
--		if FACE_BLEND_DIST > 0 then
--			tBlend = 1 - math.clamp(dist / FACE_BLEND_DIST, 0, 1) -- 0 far, 1 near
--		end
--		local blendedYaw = lerpAngle(desiredYaw, nodeYaw, tBlend)

--		-- 3) limit turn rate (this is the main "smooth turns" fix)
--		if st._lastYaw == nil then
--			st._lastYaw = blendedYaw
--		else
--			st._lastYaw = stepYaw(st._lastYaw, blendedYaw, dt, FACE_MAX_TURN_RATE)
--		end

--		-- 4) build a smooth travelDir from yaw and solve using TrafficFront
--		local smoothDir = Vector3.new(math.sin(st._lastYaw), 0, math.cos(st._lastYaw))

--		local frontAtt = getFrontAttachment(st.root)
--		if frontAtt then
--			local flipZ = getFlipZ(st.model)
--			orientationRot = faceTravelWithFrontAttachment(frontAtt.CFrame, smoothDir, flipZ)
--			st._lastFaceRot = orientationRot
--		else
--			-- if no TrafficFront, fall back to node rotation
--			orientationRot = st.targetRot
--			st._lastFaceRot = orientationRot
--		end
--	else
--		-- original behavior: face node rotation
--		orientationRot = st.targetRot
--		st._lastYaw = yawFromCFramePlusZ(orientationRot, st._lastYaw)
--		st._lastFaceRot = orientationRot
--	end

--	st.goalPart.CFrame = CFrame.new(st.basePos) * orientationRot * effectCF

--	if DEBUG and now - (st._lastAuditT or 0) >= AUDIT_EVERY then
--		st._lastAuditT = now
--		dprint(
--			"MoveAudit",
--			"id", st.id,
--			"node", st.nodeIndex,
--			"dist", string.format("%.2f", dist),
--			"speed", string.format("%.2f", speed),
--			"rootPos", tostring(st.root.Position),
--			"goalPos", tostring(st.goalPart.Position),
--			"linVel", string.format("%.2f", st.root.AssemblyLinearVelocity.Magnitude),
--			"posEnabled", st.alignPos.Enabled,
--			"oriEnabled", st.alignOri.Enabled
--		)

--		if not isAnyPartUnanchored(st.model) then
--			dwarn("MoveAudit: model is fully anchored (won't move). id=", st.id)
--		end
--	end
--end

------------------------------------------------------------------
---- heartbeat
------------------------------------------------------------------
--local function ensureHeartbeat()
--	if _hbConn then return end

--	_hbConn = RunService.Heartbeat:Connect(function(dt)
--		local now = os.clock()

--		for _, st in pairs(_vehicles) do
--			if st.moving then
--				updateVehicleMoving(st, dt)
--			else
--				if now >= st.pausedUntil then
--					beginMoveToNext(st)
--				end
--			end
--		end
--	end)

--	dprint("Heartbeat started")
--end

------------------------------------------------------------------
---- Public API
------------------------------------------------------------------
--function TrafficService.Register(model: Model?, cfg: VehicleConfig): number
--	assert(cfg and cfg.nodes and #cfg.nodes >= 1, "cfg.nodes must contain at least 1 node")

--	if not cfg.mode then cfg.mode = "loop" end
--	if cfg.anchorWhilePaused == nil then cfg.anchorWhilePaused = true end
--	if not cfg.leaveEffect then cfg.leaveEffect = defaultWobbleEffect end
--	if cfg.leaveEffectTime == nil then cfg.leaveEffectTime = 1.0 end
--	if cfg.defaultPause == nil then cfg.defaultPause = 0 end
--	if cfg.faceMovementDirection == nil then cfg.faceMovementDirection = false end

--	local actualModel = model
--	if not actualModel then
--		assert(cfg.vehiclePool, "Must provide either a model or vehiclePool")
--		actualModel = getRandomVehicleFromPool(cfg.vehiclePool)

--		local nodeCF = getNodeCFrame(cfg.nodes[1])
--		actualModel:PivotTo(nodeCF)
--	end

--	local st = buildVehicleState(actualModel, cfg)
--	_vehicles[st.id] = st

--	dprint("Register", "id", st.id, "model", actualModel:GetFullName(), "nodes", #cfg.nodes)

--	parkAtCurrentNode(st, "register")
--	ensureHeartbeat()
--	return st.id
--end

--function TrafficService.Unregister(id: number)
--	local st = _vehicles[id]
--	if not st then return end

--	dprint("Unregister", "id", id, "model", st.model.Name)

--	pcall(function() st.alignPos:Destroy() end)
--	pcall(function() st.alignOri:Destroy() end)
--	pcall(function() st.goalPart:Destroy() end)

--	_vehicles[id] = nil
--end

--function TrafficService.GetState(id: number)
--	return _vehicles[id]
--end

--return TrafficService
