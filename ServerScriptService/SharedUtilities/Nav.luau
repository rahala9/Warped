--// ServerScriptService/SharedUtilities/Nav.lua
-- Pathfinding + utility helpers for Monkey AI (server-side)
-- MoveToFinished-driven stepping + timeout-based recovery
-- + Visual debugging of the computed path (waypoints + segments)

local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local MonkeyNav = {}
MonkeyNav.__index = MonkeyNav

export type Config = {
	USE_PATHFINDING: boolean,
	PATH_RECOMPUTE_COOLDOWN: number,

	-- path agent
	AGENT_RADIUS: number,
	AGENT_HEIGHT: number,
	AGENT_CAN_JUMP: boolean,
	AGENT_JUMP_HEIGHT: number,
	AGENT_MAX_SLOPE: number,

	-- arrival + wander
	ARRIVAL_DISTANCE: number,

	-- obstacle hop assist
	ENABLE_JUMP_OVER: boolean,
	OBSTACLE_CHECK_DISTANCE: number,
	MAX_JUMP_OBSTACLE_HEIGHT: number,
	JUMP_COOLDOWN: number,

	-- MoveTo-based progression / recovery
	MOVETO_TIMEOUT_SECONDS: number?,

	-- Optional: progress-based repath as backup
	USE_PROGRESS_STUCK_CHECK: boolean?,
	STUCK_REPATH_SECONDS: number?,
	MIN_PROGRESS_DISTANCE: number?,

	-- goal timeout
	GOAL_TIMEOUT_BASE: number?,
	GOAL_TIMEOUT_PER_STUD: number?,
	GOAL_TIMEOUT_MIN: number?,
	GOAL_TIMEOUT_MAX: number?,

	-- skip tuning
	SKIP_MAX_WALK_UP: number?,
	SKIP_MAX_WALK_DOWN: number?,

	-- debug
	DEBUG: boolean,

	DEBUG_PATH_LIFETIME: number?,
	DEBUG_PATH_PARENT: Instance?,
}

type Nav = {
	Model: Model,
	Humanoid: Humanoid,
	HRP: BasePart,
	Config: Config,

	_lastPathCompute: number,
	_lastJumpTime: number,

	_waypoints: { any }?,
	_wpIndex: number,
	_targetPos: Vector3?,

	_raycastParams: RaycastParams,

	_lastProgressPos: Vector3,
	_lastProgressTime: number,

	_moveToConn: RBXScriptConnection?,
	_waitingForMoveTo: boolean,
	_moveToDeadline: number,
	_lastMoveTarget: Vector3?,

	_goalStartTime: number,
	_goalStartPos: Vector3?,
	_goalTimeout: number,
	_repathAttempts: number,
	_maxRepathAttempts: number,

	_wpAttemptCount: number,
	_wpAttemptStartTime: number,
	_wpTimeout: number,
	_maxWpAttempts: number,

	_debugFolder: Folder?,

	_links: { any }?,
}

local function dprint(cfg: Config, ...)
	if cfg.DEBUG then
		print("[MonkeyNav]", ...)
	end
end

-- -------------------------
-- Debug drawing helpers
-- -------------------------

function MonkeyNav:_getDebugFolder(): Folder
	if self._debugFolder and self._debugFolder.Parent then
		return self._debugFolder
	end

	local parent = self.Config.DEBUG_PATH_PARENT or workspace
	local f = Instance.new("Folder")
	f.Name = ("MonkeyPathDebug_%s"):format(self.Model.Name)
	f.Parent = parent
	self._debugFolder = f
	return f
end

function MonkeyNav:_clearDebug()
	if self._debugFolder then
		self._debugFolder:Destroy()
		self._debugFolder = nil
	end
end

function MonkeyNav:_drawSphere(pos: Vector3, color: Color3, name: string, lifetime: number)
	if typeof(pos) ~= "Vector3" then
		return
	end

	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(0.6, 0.6, 0.6)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.CFrame = CFrame.new(pos)
	p.Parent = self:_getDebugFolder()
	Debris:AddItem(p, lifetime)
end

function MonkeyNav:_drawSegment(a: Vector3, b: Vector3, color: Color3, name: string, lifetime: number)
	if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
		return
	end

	local segFolder = self:_getDebugFolder()

	local p0 = Instance.new("Part")
	p0.Name = name .. "_A"
	p0.Transparency = 1
	p0.Size = Vector3.new(0.2, 0.2, 0.2)
	p0.Anchored = true
	p0.CanCollide = false
	p0.CanTouch = false
	p0.CanQuery = false
	p0.CFrame = CFrame.new(a)
	p0.Parent = segFolder

	local p1 = Instance.new("Part")
	p1.Name = name .. "_B"
	p1.Transparency = 1
	p1.Size = Vector3.new(0.2, 0.2, 0.2)
	p1.Anchored = true
	p1.CanCollide = false
	p1.CanTouch = false
	p1.CanQuery = false
	p1.CFrame = CFrame.new(b)
	p1.Parent = segFolder

	local att0 = Instance.new("Attachment")
	att0.Parent = p0

	local att1 = Instance.new("Attachment")
	att1.Parent = p1

	local beam = Instance.new("Beam")
	beam.Name = name .. "_Beam"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = true
	beam.Width0 = 0.12
	beam.Width1 = 0.12
	beam.Color = ColorSequence.new(color)
	beam.LightEmission = 1
	beam.Parent = segFolder

	Debris:AddItem(p0, lifetime)
	Debris:AddItem(p1, lifetime)
	Debris:AddItem(beam, lifetime)
end

function MonkeyNav:_drawPath(waypoints: { any }?, reason: string)
	if not self.Config.DEBUG then return end
	if not waypoints or #waypoints == 0 then return end

	self:_clearDebug()

	local lifetime = self.Config.DEBUG_PATH_LIFETIME or 8
	local prev: Vector3? = nil

	dprint(self.Config, ("Drawing path (%s), waypoints=%d"):format(reason, #waypoints))

	for i, wp in ipairs(waypoints) do
		local pos: Vector3 = wp.Position
		local action = wp.Action

		local col = Color3.fromRGB(0, 255, 0)

		if action == Enum.PathWaypointAction.Jump then
			col = Color3.fromRGB(255, 255, 0)
		elseif action == Enum.PathWaypointAction.Custom then
			col = Color3.fromRGB(255, 140, 0)
		end

		self:_drawSphere(pos + Vector3.new(0, 0.5, 0), col, ("WP_%02d"):format(i), lifetime)

		if prev then
			self:_drawSegment(
				prev + Vector3.new(0, 0.5, 0),
				pos + Vector3.new(0, 0.5, 0),
				Color3.fromRGB(255, 255, 255),
				("SEG_%02d"):format(i - 1),
				lifetime
			)
		end

		prev = pos
	end
end

-- -------------------------
-- Constructor
-- -------------------------

function MonkeyNav.new(model: Model, humanoid: Humanoid, hrp: BasePart, config: Config): Nav
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	params.IgnoreWater = true

	local self = setmetatable({
		Model = model,
		Humanoid = humanoid,
		HRP = hrp,
		Config = config,

		_lastPathCompute = 0,
		_lastJumpTime = 0,

		_waypoints = nil,
		_wpIndex = 1,
		_targetPos = nil,

		_raycastParams = params,

		_lastProgressPos = hrp.Position,
		_lastProgressTime = os.clock(),

		_moveToConn = nil,
		_waitingForMoveTo = false,
		_moveToDeadline = 0,
		_lastMoveTarget = nil,

		_goalStartTime = 0,
		_goalStartPos = nil,
		_goalTimeout = 15,
		_repathAttempts = 0,
		_maxRepathAttempts = 3,

		_wpAttemptCount = 0,
		_wpAttemptStartTime = 0,
		_wpTimeout = 5.0,
		_maxWpAttempts = 2,

		_debugFolder = nil,
		_links = {},
	}, MonkeyNav)

	self._moveToConn = humanoid.MoveToFinished:Connect(function(reached: boolean)
		if not self._waitingForMoveTo then
			return
		end

		self._waitingForMoveTo = false

		if reached then
			self._wpIndex += 1
		end
	end)

	return self
end

-- -------------------------
-- Utility helpers
-- -------------------------

function MonkeyNav.RandomPointInRadius(origin: Vector3, radius: number, rng: Random): Vector3
	local theta = rng:NextNumber(0, math.pi * 2)
	local r = math.sqrt(rng:NextNumber()) * radius
	local offset = Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
	return origin + offset
end

function MonkeyNav:GetGroundedPosition(pos: Vector3): Vector3?
	if typeof(pos) ~= "Vector3" then
		warn("[MonkeyNav] GetGroundedPosition called with invalid pos:", pos, debug.traceback())
		return nil
	end

	-- Starts above the requested point and searches downward.
	-- 16/120 is safer than 8/50 for players who are jumping, falling, or standing on taller platforms.
	local rayOrigin = pos + Vector3.new(0, 16, 0)
	local rayDir = Vector3.new(0, -120, 0)

	local hit = workspace:Raycast(rayOrigin, rayDir, self._raycastParams)
	if not hit then
		if self.Config.DEBUG then
			warn("[MonkeyNav] GetGroundedPosition no hit. pos=", pos, "rayOrigin=", rayOrigin)
		end
		return nil
	end

	local standY = hit.Position.Y + self.Humanoid.HipHeight + 0.5
	return Vector3.new(pos.X, standY, pos.Z)
end

function MonkeyNav:GetGroundedPositionExclude(pos: Vector3, excludeInstances: { Instance }?): Vector3?
	if typeof(pos) ~= "Vector3" then
		warn("[MonkeyNav] GetGroundedPositionExclude called with invalid pos:", pos, debug.traceback())
		return nil
	end

	local rayOrigin = pos + Vector3.new(0, 60, 0)
	local rayDir = Vector3.new(0, -300, 0)

	local params = self._raycastParams

	if excludeInstances and #excludeInstances > 0 then
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true

		local filter = { self.Model }
		for _, inst in ipairs(excludeInstances) do
			table.insert(filter, inst)
		end

		params.FilterDescendantsInstances = filter
	end

	local hit = workspace:Raycast(rayOrigin, rayDir, params)
	if not hit then
		if self.Config.DEBUG then
			warn("[MonkeyNav] GetGroundedPositionExclude no hit. pos=", pos)
		end
		return nil
	end

	local standY = hit.Position.Y + self.Humanoid.HipHeight + 0.5
	return Vector3.new(pos.X, standY, pos.Z)
end

function MonkeyNav:_computePath(toPos: Vector3, force: boolean?): { any }?
	if typeof(toPos) ~= "Vector3" then
		warn("[MonkeyNav] _computePath called with invalid toPos:", toPos, debug.traceback())
		return nil
	end

	if not self.HRP or not self.HRP.Parent then
		warn("[MonkeyNav] _computePath failed because HRP is missing/destroyed")
		return nil
	end

	local now = os.clock()

	if not force and (now - self._lastPathCompute < self.Config.PATH_RECOMPUTE_COOLDOWN) then
		return nil
	end

	self._lastPathCompute = now

	local path = PathfindingService:CreatePath({
		AgentRadius = self.Config.AGENT_RADIUS,
		AgentHeight = self.Config.AGENT_HEIGHT,
		AgentCanJump = self.Config.AGENT_CAN_JUMP,
		AgentJumpHeight = self.Config.AGENT_JUMP_HEIGHT,
		AgentMaxSlope = self.Config.AGENT_MAX_SLOPE,
	})

	local ok, err = pcall(function()
		path:ComputeAsync(self.HRP.Position, toPos)
	end)

	if not ok then
		warn("[MonkeyNav] ComputeAsync errored:", err, "Start:", self.HRP.Position, "Goal:", toPos)
		return nil
	end

	dprint(self.Config, "PathStatus:", path.Status.Name, "Start:", self.HRP.Position, "Goal:", toPos)

	if path.Status ~= Enum.PathStatus.Success then
		dprint(self.Config, "Path failed:", path.Status.Name)
		return nil
	end

	local wps = path:GetWaypoints()

	if not wps or #wps == 0 then
		dprint(self.Config, "Path succeeded but returned no waypoints")
		return nil
	end

	self:_drawPath(wps, "ComputeAsync")
	return wps
end

function MonkeyNav:SetTarget(toPos: Vector3): boolean
	if typeof(toPos) ~= "Vector3" then
		warn("[MonkeyNav] SetTarget called with invalid toPos:", toPos, debug.traceback())
		self:Clear()
		return false
	end

	if not self.HRP or not self.HRP.Parent then
		warn("[MonkeyNav] SetTarget failed because HRP is missing/destroyed")
		self:Clear()
		return false
	end

	self._targetPos = toPos

	if self.Config.DEBUG then
		print("TEST NAV SetTarget:", toPos, debug.traceback())
	end

	self._goalStartTime = os.clock()
	self._goalStartPos = self.HRP.Position

	local dist = (toPos - self._goalStartPos).Magnitude

	local base = self.Config.GOAL_TIMEOUT_BASE or 3.0
	local perStud = self.Config.GOAL_TIMEOUT_PER_STUD or 0.25
	local minT = self.Config.GOAL_TIMEOUT_MIN or 6.0
	local maxT = self.Config.GOAL_TIMEOUT_MAX or 25.0

	local t = base + dist * perStud
	self._goalTimeout = math.clamp(t, minT, maxT)

	if self.Config.DEBUG then
		print(("[MonkeyNav] Goal dist=%.1f timeout=%.2fs"):format(dist, self._goalTimeout))
	end

	self._wpIndex = 1

	self._lastProgressPos = self.HRP.Position
	self._lastProgressTime = os.clock()

	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil

	self._repathAttempts = 0

	self._wpAttemptCount = 0
	self._wpAttemptStartTime = os.clock()

	if self.Config.DEBUG then
		local marker = Instance.new("Part")
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Size = Vector3.new(0.3, 20, 0.3)
		marker.Material = Enum.Material.Neon
		marker.Color = Color3.fromRGB(255, 0, 255)
		marker.CFrame = CFrame.new(toPos)
		marker.Parent = workspace
		Debris:AddItem(marker, 2)
	end

	if self.Config.USE_PATHFINDING then
		self._waypoints = self:_computePath(toPos, false)

		if not self._waypoints or #self._waypoints == 0 then
			dprint(self.Config, "No path to target; clearing target.")
			self:Clear()

			if self.Config.DEBUG then
				self:_clearDebug()
				local lifetime = self.Config.DEBUG_PATH_LIFETIME or 8
				self:_drawSphere(toPos + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 0, 0), "UNREACHABLE_TARGET", lifetime)
			end

			return false
		end
	else
		self._waypoints = {
			{
				Position = toPos,
				Action = Enum.PathWaypointAction.Walk,
			},
		}
	end

	return true
end

function MonkeyNav:Clear()
	self._waypoints = nil
	self._wpIndex = 1
	self._targetPos = nil

	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil

	self:_clearDebug()
end

function MonkeyNav:_recover(reason: string)
	dprint(self.Config, "RECOVER:", reason)

	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil

	if self._targetPos and self.Config.USE_PATHFINDING then
		self._repathAttempts += 1
		self._lastPathCompute = 0

		local newWps = self:_computePath(self._targetPos, true)

		if newWps and #newWps > 0 then
			self._waypoints = newWps
			self._wpIndex = 1
			self._wpAttemptCount = 0
			self._wpAttemptStartTime = os.clock()
			return
		end
	end

	self._wpIndex += 1
	self._wpAttemptCount = 0
	self._wpAttemptStartTime = os.clock()
end

-- -------------------------
-- Obstacle hop assist
-- -------------------------

function MonkeyNav:_tryJumpOverObstacle(nextPos: Vector3)
	if not self.Config.ENABLE_JUMP_OVER then return end
	if typeof(nextPos) ~= "Vector3" then return end

	if self.Humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	local st = self.Humanoid:GetState()
	if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
		return
	end

	local now = os.clock()
	if now - self._lastJumpTime < self.Config.JUMP_COOLDOWN then
		return
	end

	local toTarget = nextPos - self.HRP.Position
	if toTarget.Magnitude < 1 then return end

	local dir = toTarget.Unit
	local origin = self.HRP.Position + Vector3.new(0, 2, 0)

	local forwardHit = workspace:Raycast(origin, dir * self.Config.OBSTACLE_CHECK_DISTANCE, self._raycastParams)
	if not forwardHit then return end

	local probeTop = forwardHit.Position + Vector3.new(0, self.Config.MAX_JUMP_OBSTACLE_HEIGHT + 2, 0)

	local downHit = workspace:Raycast(
		probeTop,
		Vector3.new(0, -(self.Config.MAX_JUMP_OBSTACLE_HEIGHT + 6), 0),
		self._raycastParams
	)

	local obstacleTopY = downHit and downHit.Position.Y or forwardHit.Position.Y
	local approxHeight = obstacleTopY - self.HRP.Position.Y

	if approxHeight <= (self.Config.MAX_JUMP_OBSTACLE_HEIGHT + 0.5) then
		self._lastJumpTime = now
		self.Humanoid.Jump = true
		dprint(self.Config, "Forced hop, approx obstacle height:", approxHeight)
	end
end

-- -------------------------
-- Optional: progress-based stuck recovery
-- -------------------------

function MonkeyNav:_maybeProgressRepath()
	if not self.Config.USE_PROGRESS_STUCK_CHECK then
		return
	end

	if not self._targetPos or not self.Config.USE_PATHFINDING then
		return
	end

	local now = os.clock()
	local moved = (self.HRP.Position - self._lastProgressPos).Magnitude
	local minProgress = self.Config.MIN_PROGRESS_DISTANCE or 2.5
	local stuckSeconds = self.Config.STUCK_REPATH_SECONDS or 3.5

	if moved >= minProgress then
		self._lastProgressPos = self.HRP.Position
		self._lastProgressTime = now
		return
	end

	if (now - self._lastProgressTime) >= stuckSeconds then
		dprint(self.Config, "Progress-stuck -> repath")

		self._lastPathCompute = 0

		local newWps = self:_computePath(self._targetPos, true)
		if newWps and #newWps > 0 then
			self._waypoints = newWps
			self._wpIndex = 1
		end

		self._lastProgressTime = now
		self._lastProgressPos = self.HRP.Position

		self._waitingForMoveTo = false
		self._moveToDeadline = 0
		self._lastMoveTarget = nil
	end
end

-- -------------------------
-- MoveTo timeout recovery
-- -------------------------

function MonkeyNav:_handleMoveToTimeout()
	if not self._waitingForMoveTo then
		return
	end

	if self._lastMoveTarget and (self._lastMoveTarget - self.HRP.Position).Magnitude <= self.Config.ARRIVAL_DISTANCE then
		self._waitingForMoveTo = false
		self._wpIndex += 1
		return
	end

	if os.clock() <= self._moveToDeadline then
		return
	end

	dprint(self.Config, "MoveTo timeout -> repath/skip")

	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil

	if self._targetPos and self.Config.USE_PATHFINDING then
		self._lastPathCompute = 0

		local newWps = self:_computePath(self._targetPos, true)

		if newWps and #newWps > 0 then
			self._waypoints = newWps
			self._wpIndex = 1
			self._wpAttemptCount = 0
			self._wpAttemptStartTime = os.clock()
			return
		end
	end

	self._wpIndex += 1
	self._wpAttemptCount = 0
	self._wpAttemptStartTime = os.clock()
end

function MonkeyNav:SetLinksFromContainer(container: Instance)
	if not container then
		warn("[MonkeyNav] SetLinksFromContainer called with nil")
		self._links = {}
		return
	end

	local links = {}

	for _, inst in ipairs(container:GetDescendants()) do
		if inst:IsA("PathfindingLink") then
			local a0 = inst.Attachment0
			local a1 = inst.Attachment1

			if a0 and a1 and a0:IsA("Attachment") and a1:IsA("Attachment") then
				table.insert(links, {
					a0 = a0,
					a1 = a1,
					link = inst,
				})
			else
				warn("[MonkeyNav] PathfindingLink missing Attachment0/Attachment1:", inst:GetFullName(), a0, a1)
			end
		end
	end

	self._links = links
end

function MonkeyNav:_resolveLinkOtherEnd(fromPos: Vector3?, snapRadius: number?): (Vector3?, number?)
	if typeof(fromPos) ~= "Vector3" then
		if self.Config.DEBUG then
			warn("[MonkeyNav] _resolveLinkOtherEnd called with invalid fromPos:", fromPos)
		end
		return nil, nil
	end

	snapRadius = (typeof(snapRadius) == "number" and snapRadius) or 6

	if not self._links or #self._links == 0 then
		return nil, nil
	end

	local bestOther: Vector3? = nil
	local bestDist = snapRadius
	local bestIndex: number? = nil

	for i, link in ipairs(self._links) do
		local a0 = link.a0
		local a1 = link.a1

		if a0 and a1 and a0.Parent and a1.Parent then
			local p0 = a0.WorldPosition
			local p1 = a1.WorldPosition

			local d0 = (p0 - fromPos).Magnitude
			local d1 = (p1 - fromPos).Magnitude

			if d0 < bestDist then
				bestDist = d0
				bestOther = p1
				bestIndex = i
			end

			if d1 < bestDist then
				bestDist = d1
				bestOther = p0
				bestIndex = i
			end
		end
	end

	return bestOther, bestIndex
end

function MonkeyNav:_nearestLinkGoal(pos: Vector3, radius: number): Vector3?
	if not self._links then return nil end

	local bestGoal = nil
	local bestDist = radius

	for _, link in ipairs(self._links) do
		if link.start and link.goal then
			local d = (link.start.WorldPosition - pos).Magnitude
			if d < bestDist then
				bestDist = d
				bestGoal = link.goal.WorldPosition
			end
		end
	end

	return bestGoal
end

local function yawLookAt(fromPos: Vector3, toPos: Vector3): CFrame
	local flat = Vector3.new(toPos.X, fromPos.Y, toPos.Z)
	return CFrame.lookAt(fromPos, flat)
end

function MonkeyNav:_ballisticJumpTo(goalPos: Vector3, flightTime: number): boolean
	if not self.HRP or not self.HRP.Parent then return false end
	if typeof(goalPos) ~= "Vector3" then return false end

	flightTime = math.clamp(flightTime or 0.6, 0.25, 1.25)

	pcall(function()
		self.HRP:SetNetworkOwner(nil)
	end)

	local startPos = self.HRP.Position
	local g = workspace.Gravity

	local delta = goalPos - startPos
	local vx = delta.X / flightTime
	local vz = delta.Z / flightTime
	local vy = (delta.Y + 0.5 * g * (flightTime * flightTime)) / flightTime

	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local faceCF = yawLookAt(self.HRP.Position, goalPos)
	self.Model:PivotTo(faceCF)

	self.HRP.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)

	return true
end

function MonkeyNav:_customLinkJump(fromWpPos: Vector3)
	local goalPos, _idx = self:_resolveLinkOtherEnd(self.HRP.Position, 12)

	if not goalPos then
		warn("TEST PATHFINDING _jump: could not resolve bidirectional link near", fromWpPos)
		return false
	end

	local t = 0.65
	self:_ballisticJumpTo(goalPos + Vector3.new(0, 0.2, 0), t)

	self._waitingForMoveTo = false
	self._wpIndex += 1
	self._lastMoveTarget = nil

	return true
end

local function sameTarget(a: Vector3?, b: Vector3?): boolean
	if not a or not b then return false end
	return (a - b).Magnitude < 0.25
end

local function isSpecial(wp)
	return wp.Action == Enum.PathWaypointAction.Jump or wp.Action == Enum.PathWaypointAction.Custom
end

local function hasSpecialBetween(waypoints, i, j)
	for k = i, j do
		if isSpecial(waypoints[k]) then
			return true
		end
	end

	return false
end

function MonkeyNav:_canDirectSkip(fromPos: Vector3, toPos: Vector3): boolean
	if not self._raycastParams then
		return true
	end

	local baseFrom = fromPos + Vector3.new(0, 1.8, 0)
	local baseTo = toPos + Vector3.new(0, 1.8, 0)

	local dir = baseTo - baseFrom
	local dist = dir.Magnitude

	if dist <= 0.05 then
		return true
	end

	local unit = dir / dist

	local hit1 = workspace:Raycast(baseFrom, unit * dist, self._raycastParams)
	if hit1 then
		return false
	end

	local lowFrom = fromPos + Vector3.new(0, 0.6, 0)
	local lowTo = toPos + Vector3.new(0, 0.6, 0)
	local lowDir = lowTo - lowFrom
	local lowDist = lowDir.Magnitude

	if lowDist > 0.05 then
		local hit2 = workspace:Raycast(lowFrom, lowDir, self._raycastParams)
		if hit2 then
			return false
		end
	end

	local mid = (fromPos + toPos) * 0.5
	local midLow = mid + Vector3.new(0, 0.6, 0)

	local backA = (fromPos + Vector3.new(0, 0.6, 0)) - midLow
	local backB = (toPos + Vector3.new(0, 0.6, 0)) - midLow

	if backA.Magnitude > 0.05 then
		local hitA = workspace:Raycast(midLow, backA, self._raycastParams)
		if hitA then
			return false
		end
	end

	if backB.Magnitude > 0.05 then
		local hitB = workspace:Raycast(midLow, backB, self._raycastParams)
		if hitB then
			return false
		end
	end

	return true
end

function MonkeyNav:_advanceSkippableWaypoints()
	if not self._waypoints then return end
	if self._wpIndex >= #self._waypoints then return end

	local waypoints = self._waypoints
	local i = self._wpIndex

	if isSpecial(waypoints[i]) then
		return
	end

	local fromPos = self.HRP.Position

	local maxLookahead = math.min(i + 4, #waypoints)
	local minSkipDist = 1.0

	local maxWalkUp = self.Config.SKIP_MAX_WALK_UP or 2.5
	local maxWalkDown = self.Config.SKIP_MAX_WALK_DOWN or 8.0

	for j = maxLookahead, i + 1, -1 do
		local wpj = waypoints[j]

		if not isSpecial(wpj) then
			if not hasSpecialBetween(waypoints, i, j) then
				local toPos = wpj.Position
				local d = (toPos - fromPos).Magnitude

				if d >= minSkipDist then
					local dy = toPos.Y - fromPos.Y

					if dy <= maxWalkUp and dy >= -maxWalkDown then
						if self:_canDirectSkip(fromPos, toPos) then
							self._wpIndex = j
							return
						end
					end
				end
			end
		end
	end
end

function MonkeyNav:Step(): boolean
	if not self._waypoints or #self._waypoints == 0 then
		return true
	end

	if self._goalStartTime > 0 and self._goalTimeout > 0 then
		if (os.clock() - self._goalStartTime) > self._goalTimeout then
			dprint(self.Config, "GOAL TIMEOUT -> clearing target")
			self:Clear()
			return true
		end
	end

	self:_maybeProgressRepath()

	self:_handleMoveToTimeout()

	if self._waitingForMoveTo then
		return false
	end

	if self._wpIndex > #self._waypoints then
		return true
	end

	self:_advanceSkippableWaypoints()

	local wp = self._waypoints[self._wpIndex]
	if not wp then
		self:Clear()
		return true
	end

	local wpPos: Vector3 = wp.Position

	if self._lastMoveTarget and not sameTarget(self._lastMoveTarget, wpPos) then
		self._wpAttemptCount = 0
		self._wpAttemptStartTime = os.clock()
	end

	if (os.clock() - self._wpAttemptStartTime) > self._wpTimeout then
		self._wpAttemptCount += 1

		if self._wpAttemptCount >= self._maxWpAttempts then
			self:_recover("Waypoint timeout/max attempts")
		else
			self:_recover("Waypoint timeout -> repath")
		end

		return false
	end

	if self.Config.DEBUG then
		self:_drawSphere(
			wpPos,
			Color3.fromRGB(0, 255, 255),
			"ACTIVE_WP",
			0.2
		)
	end

	if wp.Action == Enum.PathWaypointAction.Jump then
		if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
			self:_ballisticJumpTo(wpPos + Vector3.new(0, 0.2, 0), 0.65)
			self._wpIndex += 1
			self._waitingForMoveTo = false
			self._lastMoveTarget = nil
			return false
		end
	end

	if wp.Action == Enum.PathWaypointAction.Custom then
		if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
			self:_customLinkJump(wpPos)
			self._waitingForMoveTo = false
			self._lastMoveTarget = nil
			return false
		end
	end

	self._lastMoveTarget = wpPos
	self._waitingForMoveTo = true

	local timeout = self.Config.MOVETO_TIMEOUT_SECONDS

	if typeof(timeout) ~= "number" or timeout <= 0 then
		timeout = 2.5
	end

	self._moveToDeadline = os.clock() + timeout

	self.Humanoid:MoveTo(wpPos)

	return false
end

return MonkeyNav