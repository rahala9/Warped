--// ServerScriptService/MonkeyAI/MonkeyNav.lua
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
	MOVETO_TIMEOUT_SECONDS: number,

	-- Optional: if you still want progress-based repath as a backup
	USE_PROGRESS_STUCK_CHECK: boolean?,
	STUCK_REPATH_SECONDS: number,
	MIN_PROGRESS_DISTANCE: number,

	-- debug
	DEBUG: boolean,

	-- NEW debug visual settings (optional)
	DEBUG_PATH_LIFETIME: number?, -- seconds
	DEBUG_PATH_PARENT: Instance?, -- where to put debug folder (default: workspace)
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
	_goalTimeout: number,
	_repathAttempts: number,
	_maxRepathAttempts: number,

	_wpAttemptCount: number,
	_wpAttemptStartTime: number,
	_wpTimeout: number,
	_maxWpAttempts: number,

	_debugFolder: Folder?,

	_links: { { start: Attachment, goal: Attachment } }?,
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
	-- Beam requires attachments
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

	-- Refresh folder each time so you only see the latest path
	self:_clearDebug()

	local lifetime = self.Config.DEBUG_PATH_LIFETIME or 8
	local prev: Vector3? = nil

	dprint(self.Config, ("Drawing path (%s), waypoints=%d"):format(reason, #waypoints))

	for i, wp in ipairs(waypoints) do
		local pos: Vector3 = wp.Position
		local action = wp.Action

		-- Color code waypoint types
		local col = Color3.fromRGB(0, 255, 0) -- green walk
		if action == Enum.PathWaypointAction.Jump then
			col = Color3.fromRGB(255, 255, 0) -- yellow jump
		end

		self:_drawSphere(pos + Vector3.new(0, 0.5, 0), col, ("WP_%02d"):format(i), lifetime)

		if prev then
			self:_drawSegment(prev + Vector3.new(0, 0.5, 0), pos + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 255, 255), ("SEG_%02d"):format(i - 1), lifetime)
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
		_goalTimeout = 15,          -- default; override in config if you want
		_repathAttempts = 0,
		_maxRepathAttempts = 3,     -- default

		_wpAttemptCount = 0,
		_wpAttemptStartTime = 0,
		_wpTimeout = 5.0,           -- seconds trying same wp
		_maxWpAttempts = 2,         -- attempts before skip/repath


		_debugFolder = nil,
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
	local r = math.sqrt(rng:NextNumber()) * radius -- uniform disk
	local offset = Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
	return origin + offset
end

function MonkeyNav:GetGroundedPosition(pos: Vector3): Vector3?
	local rayOrigin = pos + Vector3.new(0, 8, 0) --WAS 60
	local rayDir = Vector3.new(0, -50, 0) --WAS -300
	local hit = workspace:Raycast(rayOrigin, rayDir, self._raycastParams)
	if not hit then
		return nil
	end

	-- Target HRP center at correct standing height
	local standY = hit.Position.Y + self.Humanoid.HipHeight + 0.5
	return Vector3.new(pos.X, standY, pos.Z)
end

function MonkeyNav:GetGroundedPositionExclude(pos: Vector3, excludeInstances: {Instance}?): Vector3?
	local rayOrigin = pos + Vector3.new(0, 60, 0)
	local rayDir = Vector3.new(0, -300, 0)

	local params = self._raycastParams
	if excludeInstances and #excludeInstances > 0 then
		params = RaycastParams.new()
		params.FilterType = self._raycastParams.FilterType
		params.IgnoreWater = self._raycastParams.IgnoreWater
		params:AddToFilter(excludeInstances)
	end

	local hit = workspace:Raycast(rayOrigin, rayDir, params)
	if not hit then
		return nil
	end

	local standY = hit.Position.Y + self.Humanoid.HipHeight + 0.5
	return Vector3.new(pos.X, standY, pos.Z)
end



function MonkeyNav:_computePath(toPos: Vector3, force: boolean?): { any }?
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

	path:ComputeAsync(self.HRP.Position, toPos)
	dprint(self.Config, "PathStatus:", path.Status.Name, "Start:", self.HRP.Position, "Goal:", toPos)
	if path.Status ~= Enum.PathStatus.Success then
		dprint(self.Config, "Path failed:", path.Status.Name)
		return nil
	end

	local wps = path:GetWaypoints()
	self:_drawPath(wps, "ComputeAsync")
	return wps
end

function MonkeyNav:SetTarget(toPos: Vector3)
	if typeof(toPos) ~= "Vector3" then
		warn("[MonkeyNav] SetTarget called with invalid toPos:", toPos, debug.traceback())
		return
	end
	
	self._targetPos = toPos
	
	print("TEST NAV SetTarget:",toPos,debug.traceback())
	
	self._goalStartTime = os.clock()
	self._goalStartPos = self.HRP.Position

	local dist = (toPos - self._goalStartPos).Magnitude

	local base = (self.Config.GOAL_TIMEOUT_BASE or 3.0)
	local perStud = (self.Config.GOAL_TIMEOUT_PER_STUD or 0.25)
	local minT = (self.Config.GOAL_TIMEOUT_MIN or 6.0)
	local maxT = (self.Config.GOAL_TIMEOUT_MAX or 25.0)

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

	self._goalStartTime = os.clock()
	self._repathAttempts = 0

	self._wpAttemptCount = 0
	self._wpAttemptStartTime = os.clock()


	local marker = Instance.new("Part")
	marker.Anchored = true
	marker.CanCollide = false
	marker.Size = Vector3.new(0.3,20,0.3)
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(255,0,255) -- magenta = candidate
	marker.CFrame = CFrame.new(toPos)
	marker.Parent = workspace
	game:GetService("Debris"):AddItem(marker, 2)

	if self.Config.USE_PATHFINDING then
		self._waypoints = self:_computePath(toPos,false)
		if not self._waypoints or #self._waypoints == 0 then
			-- Path failed: do NOT attempt a straight-line fallback (it ignores obstacles)
			dprint(self.Config, "No path to target; clearing target.")
			self:Clear()

			-- Optional debug marker (red) so you can see the failed target
			if self.Config.DEBUG then
				self:_clearDebug()
				local lifetime = self.Config.DEBUG_PATH_LIFETIME or 8
				self:_drawSphere(toPos + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 0, 0), "UNREACHABLE_TARGET", lifetime)
			end
			return
		end
	else
		self._waypoints = { { Position = toPos, Action = Enum.PathWaypointAction.Walk } }
	end
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

	-- Hard reset move/wait state so we don't get stuck "waiting"
	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil

	-- Option A: repath to final target
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

	-- Option B: if repath fails, skip this waypoint (or clear goal)
	self._wpIndex += 1
	self._wpAttemptCount = 0
	self._wpAttemptStartTime = os.clock()
end


-- -------------------------
-- Obstacle hop assist
-- -------------------------

function MonkeyNav:_tryJumpOverObstacle(nextPos: Vector3)
	if not self.Config.ENABLE_JUMP_OVER then return end

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
-- Optional: progress-based stuck (fallback only)
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

	if moved >= self.Config.MIN_PROGRESS_DISTANCE then
		self._lastProgressPos = self.HRP.Position
		self._lastProgressTime = now
		return
	end

	if (now - self._lastProgressTime) >= self.Config.STUCK_REPATH_SECONDS then
		dprint(self.Config, "Progress-stuck -> repath")
		self._lastPathCompute = 0
		self._waypoints = self:_computePath(self._targetPos) or self._waypoints
		self._wpIndex = 1
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
		local newWps = self:_computePath(self._targetPos)
		if newWps and #newWps > 0 then
			self._waypoints = newWps
			self._wpIndex = 1
			return
		end
	end

	self._wpIndex += 1
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

	--if self.Config.DEBUG then
	--	print(("[MonkeyNav] Registered %d PathfindingLinks from %s"):format(#links, container:GetFullName()))
	--	for i, l in ipairs(links) do
	--		print(("  #%d %s a0=%s a1=%s"):format(
	--			i,
	--			l.link:GetFullName(),
	--			l.a0:GetFullName(),
	--			l.a1:GetFullName()
	--			))
	--	end
	--end
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

		-- attachments can be nil if streaming / deleted / not replicated yet
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
		local d = (link.start.WorldPosition - pos).Magnitude
		if d < bestDist then
			bestDist = d
			bestGoal = link.goal.WorldPosition
		end
	end

	return bestGoal
end

local RunService = game:GetService("RunService")

local function yawLookAt(fromPos: Vector3, toPos: Vector3): CFrame
	local flat = Vector3.new(toPos.X, fromPos.Y, toPos.Z)
	return CFrame.lookAt(fromPos, flat)
end

--function MonkeyNav:_repathToTarget()
--	print("TEST PATHFINDING  REPATH AFTER JUMP")
--	if not self._targetPos or not self.Config.USE_PATHFINDING then return end
--	self._lastPathCompute = 0
--	local wps = self:_computePath(self._targetPos)
--	if wps and #wps > 0 then
--		self._waypoints = wps
--		self._wpIndex = 1
--	end
--end


-- Launch HRP so it lands near goalPos after flightTime seconds
function MonkeyNav:_ballisticJumpTo(goalPos: Vector3, flightTime: number): boolean
	if not self.HRP or not self.HRP.Parent then return false end
	if typeof(goalPos) ~= "Vector3" then return false end

	flightTime = math.clamp(flightTime or 0.6, 0.25, 1.25)

	-- Must have server ownership for reliable velocity control
	pcall(function() self.HRP:SetNetworkOwner(nil) end)

	local startPos = self.HRP.Position
	local g = workspace.Gravity

	local delta = goalPos - startPos
	local vx = delta.X / flightTime
	local vz = delta.Z / flightTime
	local vy = (delta.Y + 0.5 * g * (flightTime * flightTime)) / flightTime

	-- Kick to jumping state (helps animation/state + prevents odd friction)
	self.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	local faceCF = yawLookAt(self.HRP.Position, goalPos)
	self.Model:PivotTo(faceCF) -- rotates whole rig to face goal

	-- Apply velocity
	self.HRP.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)

	return true
end

--function MonkeyNav:_repathToTargetSafely()
--	if not self._targetPos then return end

--	-- wait to be grounded
--	local deadline = os.clock() + 2
--	while self.Humanoid.FloorMaterial == Enum.Material.Air and os.clock() < deadline do
--		task.wait(0.05)
--	end

--	-- bypass cooldown just for this repath
--	self._lastPathCompute = 0

--	-- call SetTarget but prevent "Clear on fail"
--	local savedTarget = self._targetPos
--	local oldWaypoints = self._waypoints
--	self:SetTarget(savedTarget)

--	-- If SetTarget cleared because of a transient failure, restore old plan
--	if not self._targetPos and oldWaypoints then
--		self._targetPos = savedTarget
--		self._waypoints = oldWaypoints
--		self._wpIndex = 1
--	end
--end

-- -------------------------
-- Step along current target
-- Returns true when arrived at final destination
-- -------------------------
function MonkeyNav:_customLinkJump(fromWpPos: Vector3)
	-- Use the waypoint position for direction inference (more reliable than HRP position)
	local goalPos, idx = self:_resolveLinkOtherEnd(self.HRP.Position, 12)

	if not goalPos then
		warn("TEST PATHFINDING _jump: could not resolve bidirectional link near", fromWpPos)
		return false
	end

	--if self.Config.DEBUG then
	--	dprint(self.Config, "Custom link jump using link#", linkIndex, "from", fromWpPos, "to", goalPos)
	--end

	local t = 0.65
	self:_ballisticJumpTo(goalPos + Vector3.new(0, 0.2, 0), t)

	-- Advance and do not issue MoveTo this tick
	self._waitingForMoveTo = false
	self._wpIndex += 1
	self._lastMoveTarget = nil

	return true
end


local function sameTarget(a: Vector3?, b: Vector3?): boolean
	if not a or not b then return false end
	return (a - b).Magnitude < 0.25
end


----------------------------------------------------------------
-- NEW: skip helpers (drop these near your other locals/helpers)
----------------------------------------------------------------

local function isSpecial(wp)
	return wp.Action == Enum.PathWaypointAction.Jump or wp.Action == Enum.PathWaypointAction.Custom
end

-- Don’t allow skipping past any Jump/Custom in the segment [i..j]
local function hasSpecialBetween(waypoints, i, j)
	for k = i, j do
		if isSpecial(waypoints[k]) then
			return true
		end
	end
	return false
end

-- robust LOS check that won’t “shoot over” a ledge:
-- we raycast from multiple heights + a “midpoint” ray to detect corner cuts.
function MonkeyNav:_canDirectSkip(fromPos: Vector3, toPos: Vector3): boolean
	-- If you have no ray params for some reason, default to allow
	if not self._raycastParams then
		return true
	end

	-- Use a little lift above HRP to avoid floor hits
	local baseFrom = fromPos + Vector3.new(0, 1.8, 0)
	local baseTo   = toPos   + Vector3.new(0, 1.8, 0)

	local dir = baseTo - baseFrom
	local dist = dir.Magnitude
	if dist <= 0.05 then
		return true
	end

	local unit = dir / dist

	-- 1) Straight LOS at “chest” height
	local hit1 = workspace:Raycast(baseFrom, unit * dist, self._raycastParams)
	if hit1 then
		return false
	end

	-- 2) Lower LOS (catches low walls/ledges)
	local lowFrom = fromPos + Vector3.new(0, 0.6, 0)
	local lowTo   = toPos   + Vector3.new(0, 0.6, 0)
	local lowDir = lowTo - lowFrom
	local lowDist = lowDir.Magnitude
	if lowDist > 0.05 then
		local hit2 = workspace:Raycast(lowFrom, lowDir, self._raycastParams)
		if hit2 then
			return false
		end
	end

	-- 3) Midpoint “corner cut” check:
	-- cast from the midpoint back toward each end at low height.
	-- This helps catch situations where one straight ray misses a corner edge.
	local mid = (fromPos + toPos) * 0.5
	local midLow = mid + Vector3.new(0, 0.6, 0)

	local backA = (fromPos + Vector3.new(0, 0.6, 0)) - midLow
	local backB = (toPos   + Vector3.new(0, 0.6, 0)) - midLow

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

----------------------------------------------------------------
-- UPDATED: _advanceSkippableWaypoints
-- - Never skip past Jump/Custom
-- - Don’t skip onto big vertical deltas (prevents “walk to platform top”)
-- - Raycast checks to avoid cutting corners / going through walls
----------------------------------------------------------------
function MonkeyNav:_advanceSkippableWaypoints()
	if not self._waypoints then return end
	if self._wpIndex >= #self._waypoints then return end

	local waypoints = self._waypoints
	local i = self._wpIndex

	-- Don’t skip if current waypoint is special
	if isSpecial(waypoints[i]) then
		return
	end

	local fromPos = self.HRP.Position

	-- Tuneables (safe defaults)
	local maxLookahead = math.min(i + 4, #waypoints)
	local minSkipDist = 1.0

	-- “walkable step” gate: don’t skip to elevated points that likely require Jump/Link
	-- (Roblox humanoids can only step up small ledges; adjust if needed)
	local maxWalkUp = (self.Config.SKIP_MAX_WALK_UP or 2.5)
	local maxWalkDown = (self.Config.SKIP_MAX_WALK_DOWN or 8.0) -- down is usually ok, but keep sane

	for j = maxLookahead, i + 1, -1 do
		local wpj = waypoints[j]

		-- only consider skipping to non-special targets
		if not isSpecial(wpj) then
			-- never skip over any special waypoint between i..j
			if not hasSpecialBetween(waypoints, i, j) then
				local toPos = wpj.Position
				local d = (toPos - fromPos).Magnitude

				if d >= minSkipDist then
					-- vertical gate (prevents your “index 5 on platform is Walk” issue)
					local dy = toPos.Y - fromPos.Y
					if dy <= maxWalkUp and dy >= -maxWalkDown then
						-- LOS + corner/cut checks
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

	-- Overall goal watchdog
	if self._goalStartTime > 0 and self._goalTimeout > 0 then
		if (os.clock() - self._goalStartTime) > self._goalTimeout then
			dprint(self.Config, "GOAL TIMEOUT -> clearing target")
			self:Clear()
			return true -- treat as "done" so AI can pick a new goal
		end
	end

	self:_maybeProgressRepath()

	self:_handleMoveToTimeout()
	if self._waitingForMoveTo then
		return false
	end

	if self._wpIndex > #self._waypoints then
		--print("TEST PATHFINDING REACHED END...DONE")
		return true
	end

	self:_advanceSkippableWaypoints()

	local wp = self._waypoints[self._wpIndex]
	local wpPos: Vector3 = wp.Position

	-- Waypoint watchdog reset when waypoint changes
	if self._lastMoveTarget and not sameTarget(self._lastMoveTarget, wpPos) then
		self._wpAttemptCount = 0
		self._wpAttemptStartTime = os.clock()
	end

	-- If we've been working on same waypoint too long, recover
	if (os.clock() - self._wpAttemptStartTime) > self._wpTimeout then
		self._wpAttemptCount += 1
		if self._wpAttemptCount >= self._maxWpAttempts then
			self:_recover("Waypoint timeout/max attempts")
		else
			-- try a repath once before skipping
			self:_recover("Waypoint timeout -> repath")
		end
		return false
	end


	--print("TEST PATHFINDING  MOVE TO", wpPos, "INDEX", self._wpIndex, "WP ACTION", wp.Action, "WAITING", self._waitingForMoveTo, "TARGET", self._targetPos, "LASTMOVE", self._lastMoveTarget, "")

	-- draw current target waypoint in bright color
	self:_drawSphere(
		self._waypoints[self._wpIndex].Position,
		Color3.fromRGB(0, 255, 255), -- cyan
		"ACTIVE_WP",
		0.2
	)

	-- JUMP waypoint
	if wp.Action == Enum.PathWaypointAction.Jump then
		if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
			self:_ballisticJumpTo(wpPos + Vector3.new(0, 0.2, 0), 0.65)
			-- IMPORTANT: advance and do NOT issue MoveTo this tick
			self._wpIndex += 1
			self._waitingForMoveTo = false
			self._lastMoveTarget = nil
			return false
		end
	end

	-- CUSTOM link waypoint
	if wp.Action == Enum.PathWaypointAction.Custom then
		if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
			-- IMPORTANT: _customLinkJump should advance wpIndex itself or we do it here
			self:_customLinkJump(wpPos)
			-- DO NOT issue MoveTo this tick
			self._waitingForMoveTo = false
			self._lastMoveTarget = nil
			return false
		end
	end

	--self:_tryJumpOverObstacle(wpPos)

	self._lastMoveTarget = wpPos
	self._waitingForMoveTo = true

	local timeout = self.Config.MOVETO_TIMEOUT_SECONDS
	if typeof(timeout) ~= "number" or timeout <= 0 then
		timeout = 2.5
	end
	self._moveToDeadline = os.clock() + timeout

	--if self._lastMoveTarget and sameTarget(self._lastMoveTarget, wpPos) then
	--	-- already moving to this wp; just wait
	--	self._waitingForMoveTo = true
	--	return false
	--end

	self.Humanoid:MoveTo(wpPos)

	return false
end

return MonkeyNav
