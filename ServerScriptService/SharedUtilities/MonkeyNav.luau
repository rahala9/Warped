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

	-- obstacle hop assist (optional)
	ENABLE_JUMP_OVER: boolean,
	OBSTACLE_CHECK_DISTANCE: number,
	MAX_JUMP_OBSTACLE_HEIGHT: number,
	JUMP_COOLDOWN: number,

	-- MoveTo-based progression / recovery
	MOVETO_TIMEOUT_SECONDS: number,

	-- Optional: progress-based repath as a backup
	USE_PROGRESS_STUCK_CHECK: boolean?,
	STUCK_REPATH_SECONDS: number,
	MIN_PROGRESS_DISTANCE: number,

	-- goal timeout scaling
	GOAL_TIMEOUT_BASE: number?,
	GOAL_TIMEOUT_PER_STUD: number?,
	GOAL_TIMEOUT_MIN: number?,
	GOAL_TIMEOUT_MAX: number?,

	-- skip tuning (optional)
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

	-- kickoff watchdog
	_lastMoveIssueTime: number,
	_lastMoveIssuePos: Vector3,

	_goalStartTime: number,
	_goalTimeout: number,

	_repathAttempts: number,
	_maxRepathAttempts: number,

	_debugFolder: Folder?,
	_links: { { a0: Attachment, a1: Attachment, link: PathfindingLink } }?,

	_notGroundedStartTime: number?,
}

local function dprint(cfg: Config, ...)
	if cfg.DEBUG then
		print("[MonkeyNav]", ...)
	end
end

local function flatXZ(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function distXZ(a: Vector3, b: Vector3): number
	return (flatXZ(a) - flatXZ(b)).Magnitude
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
			col = Color3.fromRGB(0, 255, 255)
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

		_lastMoveIssueTime = 0,
		_lastMoveIssuePos = hrp.Position,

		_goalStartTime = 0,
		_goalTimeout = 15,

		_repathAttempts = 0,
		_maxRepathAttempts = 3,

		_debugFolder = nil,
		_links = {},

		_notGroundedStartTime = nil,
	}, MonkeyNav)

	-- IMPORTANT: Only advance waypoint index when we were actually waiting for that MoveTo
	self._moveToConn = humanoid.MoveToFinished:Connect(function(reached: boolean)
		if not self._waitingForMoveTo then return end
		self._waitingForMoveTo = false

		local tgt = self._lastMoveTarget
		self._lastMoveTarget = nil
		self._moveToDeadline = 0

		-- reached=true means Roblox believes it arrived
		if reached then
			self._wpIndex += 1
			return
		end

		-- reached=false can happen for tiny obstacles; count it if we're close in XZ
		if tgt and distXZ(self.HRP.Position, tgt) <= (self.Config.ARRIVAL_DISTANCE or 3.0) then
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

-- NOTE: This is still useful for picking a random wander target,
-- but do NOT use it to override path waypoint heights.
function MonkeyNav:GetGroundPoint(pos: Vector3): Vector3?
	local rayOrigin = pos + Vector3.new(0, 60, 0)
	local rayDir = Vector3.new(0, -300, 0)
	local hit = workspace:Raycast(rayOrigin, rayDir, self._raycastParams)
	if not hit then return nil end
	return Vector3.new(pos.X, hit.Position.Y, pos.Z)
end

function MonkeyNav:GetGroundedPosition(pos: Vector3): Vector3?
	return self:GetGroundPoint(pos)
end

function MonkeyNav:GetGroundedPositionOrFallback(pos: Vector3, fallback: Vector3): Vector3
	return self:GetGroundPoint(pos) or fallback
end

function MonkeyNav:_isGroundedRay(): boolean
	local origin = self.HRP.Position
	local maxDown = (self.Humanoid.HipHeight + 6)
	local hit = workspace:Raycast(origin, Vector3.new(0, -maxDown, 0), self._raycastParams)
	return hit ~= nil
end

-- ✅ FIX: MoveTo target should be the waypoint position directly.
-- Do NOT raycast “ground Y” here because many floors in games have CanQuery=false.
function MonkeyNav:_computeMoveToForWaypoint(wpPos: Vector3): Vector3
	return wpPos
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
	self._targetPos = toPos

	self._goalStartTime = os.clock()
	local dist = (toPos - self.HRP.Position).Magnitude

	local base = (self.Config.GOAL_TIMEOUT_BASE or 3.0)
	local perStud = (self.Config.GOAL_TIMEOUT_PER_STUD or 0.25)
	local minT = (self.Config.GOAL_TIMEOUT_MIN or 6.0)
	local maxT = (self.Config.GOAL_TIMEOUT_MAX or 25.0)
	self._goalTimeout = math.clamp(base + dist * perStud, minT, maxT)

	if self.Config.DEBUG then
		print(("[MonkeyNav] Goal dist=%.1f timeout=%.2fs"):format(dist, self._goalTimeout))
	end

	self._wpIndex = 1
	self._lastProgressPos = self.HRP.Position
	self._lastProgressTime = os.clock()

	self._waitingForMoveTo = false
	self._moveToDeadline = 0
	self._lastMoveTarget = nil
	self._lastMoveIssueTime = 0
	self._lastMoveIssuePos = self.HRP.Position

	self._repathAttempts = 0
	self._notGroundedStartTime = nil

	if self.Config.USE_PATHFINDING then
		self._waypoints = self:_computePath(toPos, true)
		if not self._waypoints or #self._waypoints == 0 then
			dprint(self.Config, "No path to target; clearing target.")
			self:Clear()
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
	self._lastMoveIssueTime = 0
	self._lastMoveIssuePos = self.HRP.Position

	self._notGroundedStartTime = nil

	self:_clearDebug()
end

-- -------------------------
-- Skip helpers
-- -------------------------

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
	local baseFrom = fromPos + Vector3.new(0, 1.8, 0)
	local baseTo = toPos + Vector3.new(0, 1.8, 0)

	local dir = baseTo - baseFrom
	if dir.Magnitude <= 0.05 then return true end

	local hit1 = workspace:Raycast(baseFrom, dir, self._raycastParams)
	if hit1 then return false end

	local lowFrom = fromPos + Vector3.new(0, 0.6, 0)
	local lowTo = toPos + Vector3.new(0, 0.6, 0)
	local lowDir = lowTo - lowFrom
	if lowDir.Magnitude > 0.05 then
		local hit2 = workspace:Raycast(lowFrom, lowDir, self._raycastParams)
		if hit2 then return false end
	end

	return true
end

function MonkeyNav:_advanceSkippableWaypoints()
	if not self._waypoints then return end
	if self._wpIndex >= #self._waypoints then return end

	local waypoints = self._waypoints
	local i = self._wpIndex
	if isSpecial(waypoints[i]) then return end

	local fromPos = self.HRP.Position
	local maxLookahead = math.min(i + 4, #waypoints)

	local maxWalkUp = (self.Config.SKIP_MAX_WALK_UP or 2.5)
	local maxWalkDown = (self.Config.SKIP_MAX_WALK_DOWN or 8.0)

	for j = maxLookahead, i + 1, -1 do
		local wpj = waypoints[j]
		if not isSpecial(wpj) and not hasSpecialBetween(waypoints, i, j) then
			local toPos = wpj.Position
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

-- -------------------------
-- Progress stuck check (optional)
-- -------------------------

function MonkeyNav:_maybeProgressRepath()
	if not self.Config.USE_PROGRESS_STUCK_CHECK then return end
	if not self._targetPos or not self.Config.USE_PATHFINDING then return end

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
	if not self._waitingForMoveTo then return end

	local tgt = self._lastMoveTarget
	if tgt and distXZ(self.HRP.Position, tgt) <= (self.Config.ARRIVAL_DISTANCE or 3.0) then
		self._waitingForMoveTo = false
		self._lastMoveTarget = nil
		self._moveToDeadline = 0
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
			return
		end
	end

	self._wpIndex += 1
end

-- -------------------------
-- Link registration (PathfindingLink support)
-- -------------------------

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
				warn("[MonkeyNav] PathfindingLink missing Attachment0/Attachment1:", inst:GetFullName())
			end
		end
	end

	self._links = links
end

function MonkeyNav:_resolveLinkOtherEnd(fromPos: Vector3?, snapRadius: number?): (Vector3?, number?)
	if typeof(fromPos) ~= "Vector3" then
		return nil, nil
	end

	snapRadius = snapRadius or 6
	if not self._links or #self._links == 0 then
		return nil, nil
	end

	local bestOther = nil
	local bestDist = snapRadius
	local bestIndex = nil

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


-- -------------------------
-- Step along current target
-- Returns true when arrived
-- -------------------------

function MonkeyNav:Step(): boolean
	if self.Config.DEBUG then
		print(string.format(
			"[Step] ENTER - wp=%d/%d waiting=%s pos=(%.2f,%.2f,%.2f)",
			self._wpIndex or 0,
			self._waypoints and #self._waypoints or 0,
			tostring(self._waitingForMoveTo),
			self.HRP.Position.X, self.HRP.Position.Y, self.HRP.Position.Z
			))
	end

	if not self._waypoints or #self._waypoints == 0 then
		return true
	end

	-- Goal watchdog
	if self._goalStartTime > 0 and self._goalTimeout > 0 then
		if (os.clock() - self._goalStartTime) > self._goalTimeout then
			dprint(self.Config, "GOAL TIMEOUT -> clearing target")
			self:Clear()
			return true
		end
	end

	self:_maybeProgressRepath()
	self:_handleMoveToTimeout()

	-- While waiting, do NOT declare done, just keep waiting / watchdog will handle timeouts.
	if self._waitingForMoveTo then
		-- kickoff watchdog: if MoveTo was issued but HRP hasn't moved soon, re-issue
		local tgt = self._lastMoveTarget
		if tgt then
			local now = os.clock()
			local moved = (self.HRP.Position - self._lastMoveIssuePos).Magnitude
			local sinceIssue = now - (self._lastMoveIssueTime or 0)

			if sinceIssue >= 0.25 and moved < 0.20 then
				self._lastMoveIssueTime = now
				self._lastMoveIssuePos = self.HRP.Position
				self.Humanoid:MoveTo(tgt)
				self._moveToDeadline = now + (self.Config.MOVETO_TIMEOUT_SECONDS or 2.5)

				if self.Config.DEBUG then
					print(string.format(
						"[Step] MoveTo kickoff retry -> (%.1f,%.1f,%.1f)",
						tgt.X, tgt.Y, tgt.Z
						))
				end
			end
		end

		return false
	end

	-- If index beyond last waypoint, only count as done if we're actually near the target in XZ
	if self._wpIndex > #self._waypoints then
		if self._targetPos and distXZ(self.HRP.Position, self._targetPos) > (self.Config.ARRIVAL_DISTANCE or 3.0) then
			-- We advanced index too far (or got a bad MoveToFinished). Hold and repath next tick if needed.
			if self.Config.DEBUG then
				print("[Step] Index past end but not near target -> repath on next tick")
			end
			if self.Config.USE_PATHFINDING then
				self._lastPathCompute = 0
				local newWps = self:_computePath(self._targetPos, true)
				if newWps and #newWps > 0 then
					self._waypoints = newWps
					self._wpIndex = 1
				end
			end
			return false
		end

		if self.Config.DEBUG then
			print("[Step] Done (near target)")
		end
		return true
	end

	-- Grounding grace (only used to avoid issuing MoveTo while truly airborne)
	local groundedNow = self:_isGroundedRay()
	if not groundedNow then
		if not self._notGroundedStartTime then
			self._notGroundedStartTime = os.clock()
		end
		local waited = os.clock() - self._notGroundedStartTime
		if waited < 0.20 then
			return false
		end
	else
		self._notGroundedStartTime = nil
	end

	-- ✅ FIX: Only do skip-advance right before we actually MoveTo (and only when not waiting)
	self:_advanceSkippableWaypoints()

	local wp = self._waypoints[self._wpIndex]
	local wpPos: Vector3 = wp.Position
	local movePos = self:_computeMoveToForWaypoint(wpPos)

	if self.Config.DEBUG then
		local actionName = (wp and wp.Action and wp.Action.Name) or "nil"
		print(string.format(
			"[Step] Targeting wp#%d action=%s wp=(%.1f,%.1f,%.1f) move=(%.1f,%.1f,%.1f) distXZ=%.1f",
			tonumber(self._wpIndex) or -1,
			tostring(actionName),
			wpPos.X, wpPos.Y, wpPos.Z,
			movePos.X, movePos.Y, movePos.Z,
			distXZ(self.HRP.Position, movePos)
			))
	end

	-- Issue MoveTo
	self.Humanoid:MoveTo(movePos)

	self._lastMoveIssueTime = os.clock()
	self._lastMoveIssuePos = self.HRP.Position

	self._waitingForMoveTo = true
	self._lastMoveTarget = movePos
	self._moveToDeadline = os.clock() + (self.Config.MOVETO_TIMEOUT_SECONDS or 2.5)

	return false
end

return MonkeyNav
