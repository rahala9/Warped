-- PassiveWanderingAI.server.lua
-- AI with state machine + wandering + THREAT-BASED TARGETING
-- Fixes:
-- 1) Ranged enemies keep attacking airborne/jetpack targets if LOS + range are valid.
-- 2) Pursue uses grounded target positions for pathfinding.
-- 3) Failed pathfinding does not automatically drop aggro for ranged enemies.
-- 4) Wander target picking rejects huge vertical floor changes.
-- 5) State update errors are caught so the AI does not silently freeze.
-- 6) Ranged enemies use a grace period before leaving AttackRanged when LOS/range flickers.
-- 7) Ranged animation modes:
--    "Loop"   = keep Attack animation looping while in AttackRanged, fire on cooldown.
--    "Marker" = play Attack once per shot, fire when animation marker is reached, with fallback.
-- 8) Fix stale currentActionTrack so ranged attack animation restarts after death/respawn/re-engage.
-- 9) Ranged shots fire from Muzzle / FirePoint if found.
-- 10) Optional debug markers show exact ranged shot origin + orientation.

------------------------------------------------------------------
-- Roblox Services
------------------------------------------------------------------
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

------------------------------------------------------------------
-- Definition Modules
------------------------------------------------------------------
local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local EnemySpawningConfig = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("EnemySpawningConfig"))
local EnemyCombatFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("EnemyCombatFunctions"))

------------------------------------------------------------------
-- Modules
------------------------------------------------------------------
local Nav = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("Nav"))

------------------------------------------------------------------
-- CONTEXT
------------------------------------------------------------------
local npc = script.Parent
local humanoid: Humanoid = npc:WaitForChild("Humanoid")
local body = npc:WaitForChild("Body")
local hrp: BasePart = npc:WaitForChild("HumanoidRootPart")
local animationsFolder = npc:WaitForChild("Animations")

local configId = npc:GetAttribute("ConfigId")
local spawnerCfg = (configId and EnemySpawningConfig.Spawners and EnemySpawningConfig.Spawners[configId]) or nil
local AIConfig = (spawnerCfg and spawnerCfg.AIConfig) or {}

local currentTarget: Player? = nil

------------------------------------------------------------------
-- THREAT SYSTEM
------------------------------------------------------------------
local threatTable = {} -- [userId] = { Player = player, Damage = totalDamage, LastHit = timestamp }

local THREAT_SWITCH_THRESHOLD = AIConfig.THREAT_SWITCH_THRESHOLD or 1.5
local THREAT_DECAY_RATE = AIConfig.THREAT_DECAY_RATE or 0.05
local THREAT_FORGET_TIME = AIConfig.THREAT_FORGET_TIME or 30
local THREAT_RESET_DISTANCE = AIConfig.THREAT_RESET_DISTANCE or 200

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
local enemyDef = enemiesModule[npc.Name] or {}

local navHitboxSize = enemyDef.NavHitboxSize or Vector3.new(3, 5, 3)

local CONFIG = {
	-- wandering
	WANDER_RADIUS = AIConfig.WANDER_RADIUS or 100,
	MIN_IDLE_TIME = AIConfig.MIN_IDLE_TIME or 2.0,
	MAX_IDLE_TIME = AIConfig.MAX_IDLE_TIME or 2.0,
	MIN_LINGER_TIME = AIConfig.MIN_LINGER_TIME or 4.0,
	MAX_LINGER_TIME = AIConfig.MAX_LINGER_TIME or 10.0,
	MAX_WANDER_TIME = AIConfig.MAX_WANDER_TIME or 60.0,

	WANDER_PICK_TRIES = AIConfig.WANDER_PICK_TRIES or 12,
	WANDER_MAX_DROP_FROM_HOME = AIConfig.WANDER_MAX_DROP_FROM_HOME or 8,
	WANDER_MAX_RISE_FROM_HOME = AIConfig.WANDER_MAX_RISE_FROM_HOME or 8,

	-- ranged combat smoothing
	RANGED_LOST_SHOOTABLE_GRACE = AIConfig.RANGED_LOST_SHOOTABLE_GRACE
		or enemyDef.RANGED_LOST_SHOOTABLE_GRACE
		or enemyDef.RangedLostShootableGrace
		or 1.25,

	-- ranged animation behavior
	RANGED_ANIMATION_MODE = AIConfig.RANGED_ANIMATION_MODE or enemyDef.RangedAnimationMode or "Loop",
	RANGED_FIRE_MARKER = AIConfig.RANGED_FIRE_MARKER or enemyDef.RangedFireMarker or "Fire",
	RANGED_FIRE_FALLBACK_DELAY = AIConfig.RANGED_FIRE_FALLBACK_DELAY or enemyDef.RangedFireFallbackDelay,
	RANGED_FIRE_FALLBACK_PERCENT = AIConfig.RANGED_FIRE_FALLBACK_PERCENT or enemyDef.RangedFireFallbackPercent or 0.35,

	-- optional muzzle search names
	RANGED_MUZZLE_NAMES = enemyDef.RangedMuzzleNames or AIConfig.RANGED_MUZZLE_NAMES or {
		"Muzzle",
		"MuzzleAttachment",
		"FirePoint",
		"FirePointAttachment",
	},

	-- ranged origin/orientation debug
	DEBUG_RANGED_FIRE_ORIGIN = AIConfig.DEBUG_RANGED_FIRE_ORIGIN
		or enemyDef.DebugRangedFireOrigin
		or false,

	DEBUG_RANGED_FIRE_ORIGIN_LIFETIME = AIConfig.DEBUG_RANGED_FIRE_ORIGIN_LIFETIME
		or enemyDef.DebugRangedFireOriginLifetime
		or 3.0,

	DEBUG_RANGED_FIRE_ORIGIN_LENGTH = AIConfig.DEBUG_RANGED_FIRE_ORIGIN_LENGTH
		or enemyDef.DebugRangedFireOriginLength
		or 8.0,

	-- movement speed
	WALK_SPEED = enemyDef.WalkSpeed or 10,
	RUN_SPEED = enemyDef.RunSpeed or 14,

	-- Alarmed behavior
	ENABLE_ALARMED = AIConfig.ENABLE_ALARMED or false,
	ALARM_TRIGGER_DISTANCE = AIConfig.ALARM_TRIGGER_DISTANCE or 30,
	ALARM_STATE_FREQUENCY = AIConfig.ALARM_STATE_FREQUENCY or 2,
	ALARM_STATE_DISTANCE = AIConfig.ALARM_STATE_DISTANCE or 20,
	ALARM_STATE_COUNT_MAX = AIConfig.ALARM_STATE_COUNT_MAX or 3,

	-- Optional hooks
	OnIdleStart = AIConfig.OnIdleStart or nil,
	OnIdleUpdate = AIConfig.OnIdleUpdate or nil,
	OnWalkStart = AIConfig.OnWalkStart or nil,
	OnWalkUpdate = AIConfig.OnWalkUpdate or nil,
	OnRunStart = AIConfig.OnRunStart or nil,
	OnRunUpdate = AIConfig.OnRunUpdate or nil,
	OnAlarmedStart = AIConfig.OnAlarmedStart or nil,
	OnJumpStart = AIConfig.OnJumpStart or nil,
	OnDieStart = AIConfig.OnDieStart or nil,

	-- nav + jump assist
	NAV = {
		USE_PATHFINDING = (AIConfig.USE_PATHFINDING ~= false),
		PATH_RECOMPUTE_COOLDOWN = AIConfig.PATH_RECOMPUTE_COOLDOWN or 1.2,

		-- AgentRadius is radius, not full width.
		AGENT_RADIUS = AIConfig.AGENT_RADIUS or ((navHitboxSize.X or 3) * 0.5),
		AGENT_HEIGHT = AIConfig.AGENT_HEIGHT or navHitboxSize.Y or 5,

		-- Default false prevents random ledge/jump behavior unless explicitly enabled.
		AGENT_CAN_JUMP = (AIConfig.AGENT_CAN_JUMP == true),
		AGENT_JUMP_HEIGHT = AIConfig.AGENT_JUMP_HEIGHT or 4,
		AGENT_MAX_SLOPE = AIConfig.AGENT_MAX_SLOPE or 30,

		ARRIVAL_DISTANCE = AIConfig.ARRIVAL_DISTANCE or 3.0,

		ENABLE_JUMP_OVER = (AIConfig.ENABLE_JUMP_OVER == true),
		OBSTACLE_CHECK_DISTANCE = AIConfig.OBSTACLE_CHECK_DISTANCE or 4.0,
		MAX_JUMP_OBSTACLE_HEIGHT = AIConfig.MAX_JUMP_OBSTACLE_HEIGHT or 2.5,
		JUMP_COOLDOWN = AIConfig.JUMP_COOLDOWN or 1.0,

		MOVETO_TIMEOUT_SECONDS = AIConfig.MOVETO_TIMEOUT_SECONDS or 2.5,

		USE_PROGRESS_STUCK_CHECK = (AIConfig.USE_PROGRESS_STUCK_CHECK ~= false),
		STUCK_REPATH_SECONDS = AIConfig.STUCK_REPATH_SECONDS or 3.5,
		MIN_PROGRESS_DISTANCE = AIConfig.MIN_PROGRESS_DISTANCE or 2.5,

		GOAL_TIMEOUT_BASE = AIConfig.GOAL_TIMEOUT_BASE or 3.0,
		GOAL_TIMEOUT_PER_STUD = AIConfig.GOAL_TIMEOUT_PER_STUD or 0.25,
		GOAL_TIMEOUT_MIN = AIConfig.GOAL_TIMEOUT_MIN or 6.0,
		GOAL_TIMEOUT_MAX = AIConfig.GOAL_TIMEOUT_MAX or 25.0,

		SKIP_MAX_WALK_UP = AIConfig.SKIP_MAX_WALK_UP or 2.5,
		SKIP_MAX_WALK_DOWN = AIConfig.SKIP_MAX_WALK_DOWN or 3.0,
		MAX_SAFE_DROP = AIConfig.MAX_SAFE_DROP or 5.0,

		DEBUG = AIConfig.DEBUG or false,
		DEBUG_PATH_LIFETIME = AIConfig.DEBUG_PATH_LIFETIME or 8,
	},

	-- air/land anim behavior
	LAND_HOLD_TIME = AIConfig.LAND_HOLD_TIME or 0.25,

	-- AI tick rate
	AI_TICK = AIConfig.AI_TICK or 0.15,

	DEBUG = AIConfig.DEBUG or false,
}

local function dprint(...)
	if CONFIG.DEBUG then
		print("[PassiveWanderingAI]", ...)
	end
end

------------------------------------------------------------------
-- NPC hardening
------------------------------------------------------------------
if npc.PrimaryPart == nil then
	npc.PrimaryPart = hrp
end

pcall(function()
	hrp:SetNetworkOwner(nil)
end)

humanoid.AutoRotate = true
humanoid.UseJumpPower = false
humanoid.JumpHeight = 10

body.Massless = true
body.CanCollide = false

hrp.CanCollide = false

local deathLocked = false

do
	local hitbox = npc:FindFirstChild("NavHitbox")

	if not hitbox then
		hitbox = Instance.new("Part")
		hitbox.Name = "NavHitbox"
		hitbox.Size = navHitboxSize
		hitbox.Transparency = AIConfig.DEBUG_NAVHITBOX and 0.5 or 1
		hitbox.Color = Color3.fromRGB(255, 0, 0)
		hitbox.CanCollide = true
		hitbox.CanTouch = false
		hitbox.CanQuery = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = hrp.CFrame
		hitbox.CollisionGroup = "Helpers"
		hitbox.Parent = npc

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hitbox
		weld.Part1 = hrp
		weld.Parent = hitbox
	else
		hitbox.CanCollide = true
		hitbox.CanTouch = false
		hitbox.CanQuery = false
		hitbox.Massless = true
		hitbox.Transparency = AIConfig.DEBUG_NAVHITBOX and 0.5 or hitbox.Transparency
	end
end

local animateScript = npc:FindFirstChild("Animate")
if animateScript then
	animateScript.Disabled = true
end

------------------------------------------------------------------
-- Animations
------------------------------------------------------------------
local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")

local function loadAnim(name: string): AnimationTrack?
	local animObj = animationsFolder:FindFirstChild(name)

	if not animObj or not animObj:IsA("Animation") then
		warn(("[PassiveWanderingAI] Missing Animation %q under %s.Animations"):format(name, npc.Name))
		return nil
	end

	local track = animator:LoadAnimation(animObj)
	return track
end

local Tracks = {
	Idle1 = loadAnim("Idle1"),
	Idle2 = loadAnim("Idle2"),
	Idle3 = loadAnim("Idle3"),
	Idle4 = loadAnim("Idle4"),
	Run = loadAnim("Run"),
	Jump = loadAnim("Jump"),
	Freefall = loadAnim("Fall"),
	Landed = loadAnim("Land"),
	Attack = loadAnim("Attack"),
	Die = loadAnim("Die"),
	WingsFlap = loadAnim("WingsFlap"),
	WingsIdle = loadAnim("WingsIdle"),
}

for k, t in pairs(Tracks) do
	if t then
		if k:find("^Idle") then
			t.Priority = Enum.AnimationPriority.Idle
			t.Looped = true
		elseif k == "Run" then
			t.Priority = Enum.AnimationPriority.Movement
			t.Looped = true
		elseif k == "WingsFlap" or k == "WingsIdle" then
			t.Priority = Enum.AnimationPriority.Action2
			t.Looped = true
		else
			t.Priority = Enum.AnimationPriority.Action
			t.Looped = false
		end
	end
end

local function cancelHumanoidMove()
	local p = hrp.Position

	pcall(function()
		humanoid:MoveTo(p)
	end)

	pcall(function()
		humanoid:Move(Vector3.zero)
	end)
end

local function stopAllTracksExcept(keep: AnimationTrack?, fade: number?)
	fade = fade or 0.12

	for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
		if t ~= keep then
			pcall(function()
				t:Stop(fade)
			end)
		end
	end
end

local currentGroundTrack: AnimationTrack? = nil

local function playGround(track: AnimationTrack?, fade: number?, hardTakeover: boolean?)
	if not track then return end

	fade = fade or 0.15

	if track.Priority == Enum.AnimationPriority.Idle or track.Priority == Enum.AnimationPriority.Movement then
		track.Looped = true
	end

	if currentGroundTrack == track then
		pcall(function()
			track:AdjustWeight(1, fade)
		end)
		return
	end

	if currentGroundTrack then
		pcall(function()
			currentGroundTrack:Stop(fade)
		end)
	end

	currentGroundTrack = track

	if hardTakeover then
		stopAllTracksExcept(track, fade)
	end

	dprint("Playing ground:", track.Name)

	pcall(function()
		track:Play(fade, 1, 1)
		track:AdjustWeight(1, fade)
	end)
end

local currentActionTrack: AnimationTrack? = nil
local actionLockUntil = 0

local function playAction(track: AnimationTrack?, fade: number?, lockSeconds: number?, force: boolean?)
	if not track then return end

	fade = fade or 0.10
	lockSeconds = lockSeconds or 0
	force = force or false

	if os.clock() < actionLockUntil and currentActionTrack and currentActionTrack ~= track then
		return
	end

	if currentActionTrack == track then
		if force then
			pcall(function()
				track.TimePosition = 0
			end)
		end

		if not track.IsPlaying then
			pcall(function()
				track:Play(fade, 1, 1)
				track:AdjustWeight(1, fade)
			end)
		else
			pcall(function()
				track:AdjustWeight(1, fade)
			end)
		end

		if lockSeconds > 0 then
			actionLockUntil = os.clock() + lockSeconds
		end

		return
	end

	if currentActionTrack then
		pcall(function()
			currentActionTrack:Stop(fade)
		end)
	end

	currentActionTrack = track

	if force then
		pcall(function()
			track.TimePosition = 0
		end)
	end

	pcall(function()
		track:Play(fade, 1, 1)
		track:AdjustWeight(1, fade)
	end)

	if lockSeconds > 0 then
		actionLockUntil = os.clock() + lockSeconds
	end
end

local function stopAction(fade: number?)
	fade = fade or 0.12

	if currentActionTrack then
		pcall(function()
			currentActionTrack:Stop(fade)
		end)
	end

	currentActionTrack = nil
	actionLockUntil = 0
end

------------------------------------------------------------------
-- Nav
------------------------------------------------------------------
local nav = Nav.new(npc, humanoid, hrp, CONFIG.NAV)

local navFolder = workspace:FindFirstChild("Nav")
if navFolder then
	nav:SetLinksFromContainer(navFolder)
else
	warn("[PassiveWanderingAI] workspace.Nav not found; PathfindingLinks will not be registered.")
end

local rng = Random.new()
local startPos = hrp.Position

------------------------------------------------------------------
-- Shared target helpers
------------------------------------------------------------------
local function getTargetHRP(player: Player?): BasePart?
	if not player then
		return nil
	end

	local char = player.Character
	if not char then
		return nil
	end

	local targetHRP = char:FindFirstChild("HumanoidRootPart")

	if targetHRP and targetHRP:IsA("BasePart") then
		return targetHRP
	end

	return nil
end

local function getPursueTargetPosition(player: Player?): Vector3?
	local targetHRP = getTargetHRP(player)

	if not targetHRP then
		return nil
	end

	local rawPos = targetHRP.Position

	if rawPos.Y > 1000 or rawPos.Y < -500 then
		warn("[PassiveWanderingAI] Weird target HRP position:", player.Name, rawPos)
		return nil
	end

	local grounded = nav:GetGroundedPosition(rawPos)

	if not grounded then
		if CONFIG.DEBUG then
			warn("[PassiveWanderingAI] Could not ground pursue target:", player.Name, rawPos)
		end
		return nil
	end

	return grounded
end

local function setNavTargetSafe(pos: Vector3?): boolean
	if typeof(pos) ~= "Vector3" then
		return false
	end

	local ok = nav:SetTarget(pos)

	if ok == true then
		return true
	end

	if ok == false then
		return false
	end

	return nav._targetPos ~= nil
end

local function getGroundedWanderPosition(raw: Vector3): Vector3?
	local grounded = nav:GetGroundedPosition(raw)

	if not grounded then
		return nil
	end

	local dy = grounded.Y - startPos.Y

	if dy < -CONFIG.WANDER_MAX_DROP_FROM_HOME or dy > CONFIG.WANDER_MAX_RISE_FROM_HOME then
		if CONFIG.DEBUG then
			warn("[PassiveWanderingAI] Rejected wander point on different floor:", grounded, "dy:", dy)
		end
		return nil
	end

	return grounded
end

local function hasLineOfSightToTarget(targetHRP: BasePart): boolean
	if not targetHRP then
		return false
	end

	local targetChar = currentTarget and currentTarget.Character
	if not targetChar then
		return false
	end

	local origin = hrp.Position + Vector3.new(0, enemyDef.RangedOriginHeight or 2, 0)
	local goal = targetHRP.Position + Vector3.new(0, enemyDef.RangedTargetHeight or 2, 0)
	local direction = goal - origin

	if direction.Magnitude <= 0.1 then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { npc }

	local hit = workspace:Raycast(origin, direction, params)

	if not hit then
		return true
	end

	if hit.Instance and hit.Instance:IsDescendantOf(targetChar) then
		return true
	end

	return false
end

local function canUseRangedAgainstTarget(targetHRP: BasePart): boolean
	if not targetHRP then
		return false
	end

	if not enemyDef.IsRanged then
		return false
	end

	local combatRole = enemyDef.CombatRole or "melee"
	if combatRole ~= "ranged" and combatRole ~= "hybrid" then
		return false
	end

	local delta = targetHRP.Position - hrp.Position
	local horizontalDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local verticalDistance = math.abs(delta.Y)
	local directDistance = delta.Magnitude

	local rangedMaxRange = enemyDef.RangedMaxRange or 50
	local rangedMinRange = enemyDef.RangedMinRange or 0

	local verticalRange = enemyDef.RangedVerticalRange or rangedMaxRange
	local absoluteMaxRange = enemyDef.RangedAbsoluteMaxRange or math.max(rangedMaxRange, verticalRange)

	if horizontalDistance < rangedMinRange then
		return false
	end

	if horizontalDistance > rangedMaxRange then
		return false
	end

	if verticalDistance > verticalRange then
		return false
	end

	if directDistance > absoluteMaxRange then
		return false
	end

	return hasLineOfSightToTarget(targetHRP)
end

------------------------------------------------------------------
-- Running event animation control
------------------------------------------------------------------
local lastRunSpeed = 0
local allowRunningControl = true

humanoid.Running:Connect(function(speed)
	if deathLocked then return end

	lastRunSpeed = speed

	if not allowRunningControl then
		return
	end

	local st = humanoid:GetState()

	if st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping then
		return
	end

	if speed > 1 then
		playGround(Tracks.Run, 0.10, false)
	else
		playGround(Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4, 0.15, false)
	end
end)

------------------------------------------------------------------
-- Air handling
------------------------------------------------------------------
humanoid.StateChanged:Connect(function(_, newState)
	if deathLocked then return end

	if newState == Enum.HumanoidStateType.Freefall then
		playAction(Tracks.Freefall, 0.05, 0)

	elseif newState == Enum.HumanoidStateType.Jumping then
		if Tracks.Jump then
			playAction(Tracks.Jump, 0.05, 0)
		end

		if CONFIG.OnJumpStart then
			pcall(function()
				CONFIG.OnJumpStart(npc, Tracks)
			end)
		end

	elseif newState == Enum.HumanoidStateType.Landed then
		playAction(Tracks.Landed, 0.05, CONFIG.LAND_HOLD_TIME)

		task.delay(CONFIG.LAND_HOLD_TIME, function()
			local st = humanoid:GetState()

			if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then
				stopAction(0.1)

				if allowRunningControl then
					if lastRunSpeed > 1 then
						playGround(Tracks.Run, 0.10, false)
					else
						playGround(Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4, 0.15, false)
					end
				end
			end
		end)
	end
end)

------------------------------------------------------------------
-- State machine
------------------------------------------------------------------
local State = {}
State.__index = State

function State.new(name: string, onEnter, onUpdate, onExit)
	return setmetatable({
		Name = name,
		OnEnter = onEnter,
		OnUpdate = onUpdate,
		OnExit = onExit,
	}, State)
end

local states = {}
local currentState: any = nil

local function changeState(name: string)
	local nextState = states[name]
	assert(nextState, ("Unknown state: %s"):format(name))

	if currentState and currentState.OnExit then
		currentState.OnExit()
	end

	currentState = nextState
	dprint("STATE ->", currentState.Name)

	if currentState.OnEnter then
		currentState.OnEnter()
	end
end

------------------------------------------------------------------
-- THREAT SYSTEM FUNCTIONS
------------------------------------------------------------------
local function updateThreat(player: Player?, damageDealt: number)
	if not player then return end

	local userId = player.UserId
	local now = os.time()

	if not threatTable[userId] then
		threatTable[userId] = {
			Player = player,
			Damage = 0,
			LastHit = now,
		}
	end

	threatTable[userId].Damage += damageDealt
	threatTable[userId].LastHit = now

	dprint(string.format("[THREAT] %s dealt %.1f damage (total: %.1f)",
		player.Name,
		damageDealt,
		threatTable[userId].Damage
		))

	local highestThreat = 0
	local highestPlayer = nil

	for uid, threatData in pairs(threatTable) do
		local targetHRP = getTargetHRP(threatData.Player)

		if targetHRP then
			local dist = (targetHRP.Position - hrp.Position).Magnitude

			if dist > THREAT_RESET_DISTANCE then
				dprint(string.format("[THREAT] %s too far (%.1f studs), clearing threat", threatData.Player.Name, dist))
				threatTable[uid] = nil

				if currentTarget == threatData.Player then
					currentTarget = nil
				end
			elseif threatData.Damage > highestThreat then
				highestThreat = threatData.Damage
				highestPlayer = threatData.Player
			end
		else
			threatTable[uid] = nil
		end
	end

	if currentTarget ~= highestPlayer then
		local currentThreat = 0

		if currentTarget then
			local currentUserId = currentTarget.UserId
			currentThreat = (threatTable[currentUserId] and threatTable[currentUserId].Damage) or 0
		end

		if highestPlayer and highestThreat > currentThreat * THREAT_SWITCH_THRESHOLD then
			dprint(string.format("[THREAT SWITCH] %s -> %s (%.1f -> %.1f damage)",
				currentTarget and currentTarget.Name or "none",
				highestPlayer.Name,
				currentThreat,
				highestThreat
				))

			currentTarget = highestPlayer
			changeState("Pursue")
			return true
		end
	elseif not currentTarget and highestPlayer then
		dprint(string.format("[THREAT] Acquired target: %s (%.1f damage)", highestPlayer.Name, highestThreat))
		currentTarget = highestPlayer
		changeState("Pursue")
		return true
	end

	return false
end

local function decayThreat()
	local now = os.time()

	for userId, threatData in pairs(threatTable) do
		local isCurrentTarget = currentTarget and currentTarget.UserId == userId

		if not isCurrentTarget then
			threatData.Damage = threatData.Damage * (1 - THREAT_DECAY_RATE * CONFIG.AI_TICK)

			if (now - threatData.LastHit > THREAT_FORGET_TIME) or threatData.Damage < 1 then
				dprint(string.format("[THREAT] Forgot %s (threat: %.1f, age: %ds)",
					threatData.Player.Name,
					threatData.Damage,
					now - threatData.LastHit
					))

				threatTable[userId] = nil
			end
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId

	if threatTable[userId] then
		dprint(string.format("[THREAT] Player left: %s", player.Name))
		threatTable[userId] = nil

		if currentTarget == player then
			currentTarget = nil
			dprint("[THREAT] Current target left, searching for new target")

			local highestThreat = 0
			local highestPlayer = nil

			for _, threatData in pairs(threatTable) do
				if threatData.Damage > highestThreat then
					highestThreat = threatData.Damage
					highestPlayer = threatData.Player
				end
			end

			if highestPlayer then
				dprint(string.format("[THREAT] Switching to next target: %s (%.1f threat)", highestPlayer.Name, highestThreat))
				currentTarget = highestPlayer
				changeState("Pursue")
			end
		end
	end
end)

------------------------------------------------------------------
-- Player hit check
------------------------------------------------------------------
local function checkHit()
	local hit = npc:GetAttribute("Hit")
	if not hit then return false end

	local hitByUserId = npc:GetAttribute("HitByUserId")
	local hitDamage = npc:GetAttribute("HitDamage")

	if not hitByUserId or not hitDamage then
		return false
	end

	local player = Players:GetPlayerByUserId(hitByUserId)

	if player then
		updateThreat(player, hitDamage)

		npc:SetAttribute("Hit", nil)
		npc:SetAttribute("HitByUserId", nil)
		npc:SetAttribute("HitDamage", nil)

		return true
	end

	return false
end

------------------------------------------------------------------
-- Player alarm check
------------------------------------------------------------------
local lastPlayerCheck = 0

local function checkForPlayers()
	if not CONFIG.ENABLE_ALARMED then return end

	local now = os.clock()

	if now - lastPlayerCheck < 0.5 then return end
	lastPlayerCheck = now

	if currentState and currentState.Name == "Alarmed" then return end
	if currentState and currentState.Name == "Held" then return end

	for _, player in ipairs(Players:GetPlayers()) do
		local phrp = getTargetHRP(player)

		if phrp then
			local dist = (phrp.Position - hrp.Position).Magnitude

			if dist <= CONFIG.ALARM_TRIGGER_DISTANCE then
				changeState("Alarmed")
				return
			end
		end
	end
end

------------------------------------------------------------------
-- STATES
------------------------------------------------------------------

local idleUntil = 0
local lastIdleChange = 0

states.Idle = State.new(
	"Idle",

	function()
		nav:Clear()
		cancelHumanoidMove()

		humanoid.WalkSpeed = 0
		humanoid.Jump = false

		allowRunningControl = false

		idleUntil = os.clock() + rng:NextNumber(CONFIG.MIN_IDLE_TIME, CONFIG.MAX_IDLE_TIME)
		lastIdleChange = os.clock()

		stopAction(0.1)

		local whichIdle = rng:NextInteger(1, 4)
		local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4

		playGround(idleTrack, 0.2, true)

		if CONFIG.OnIdleStart then
			pcall(function()
				CONFIG.OnIdleStart(npc, Tracks, whichIdle)
			end)
		end
	end,

	function()
		if os.clock() - lastIdleChange > 5 then
			lastIdleChange = os.clock()

			local whichIdle = rng:NextInteger(1, 4)
			local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4

			playGround(idleTrack, 0.2, true)

			if CONFIG.OnIdleUpdate then
				pcall(function()
					CONFIG.OnIdleUpdate(npc, Tracks, os.clock(), whichIdle)
				end)
			end
		end

		if os.clock() >= idleUntil then
			changeState("PickWander")
		end
	end,

	function()
		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

states.PickWander = State.new(
	"PickWander",

	function()
		local chosen = nil

		for _ = 1, CONFIG.WANDER_PICK_TRIES do
			local raw = Nav.RandomPointInRadius(startPos, CONFIG.WANDER_RADIUS, rng)
			local grounded = getGroundedWanderPosition(raw)

			if grounded then
				chosen = grounded
				break
			end
		end

		if chosen and setNavTargetSafe(chosen) then
			changeState("Wander")
		else
			changeState("Idle")
		end
	end
)

local lingerUntil = 0
local wanderEnteredAt = 0

states.Wander = State.new(
	"Wander",

	function()
		wanderEnteredAt = os.clock()
		humanoid.WalkSpeed = CONFIG.RUN_SPEED
		allowRunningControl = true

		if CONFIG.OnRunStart then
			pcall(function()
				CONFIG.OnRunStart(npc, Tracks)
			end)
		end
	end,

	function()
		if CONFIG.OnRunUpdate then
			pcall(function()
				CONFIG.OnRunUpdate(npc, Tracks, os.clock())
			end)
		end

		local arrived = nav:Step()

		if arrived then
			nav:Clear()
			lingerUntil = os.clock() + rng:NextNumber(CONFIG.MIN_LINGER_TIME, CONFIG.MAX_LINGER_TIME)
			changeState("Linger")
			return
		end

		if os.clock() - wanderEnteredAt > CONFIG.MAX_WANDER_TIME then
			dprint("Wander watchdog fired -> resetting")
			nav:Clear()
			changeState("Idle")
		end
	end
)

local lastLingerChange = 0

states.Linger = State.new(
	"Linger",

	function()
		nav:Clear()
		cancelHumanoidMove()

		humanoid.WalkSpeed = 0
		humanoid.Jump = false

		allowRunningControl = false
		lastLingerChange = os.clock()

		stopAction(0.1)

		local whichIdle = rng:NextInteger(1, 4)
		local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4

		playGround(idleTrack, 0.2, true)

		if CONFIG.OnIdleStart then
			pcall(function()
				CONFIG.OnIdleStart(npc, Tracks, whichIdle)
			end)
		end
	end,

	function()
		if os.clock() - lastLingerChange > 5 then
			lastLingerChange = os.clock()

			local whichIdle = rng:NextInteger(1, 4)
			local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4

			playGround(idleTrack, 0.2, true)

			if CONFIG.OnIdleUpdate then
				pcall(function()
					CONFIG.OnIdleUpdate(npc, Tracks, os.clock(), whichIdle)
				end)
			end
		end

		if os.clock() >= lingerUntil then
			changeState("Idle")
		end
	end,

	function()
		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

------------------------------------------------------------------
-- Pursue State
------------------------------------------------------------------
local lastRepathAttempt = 0
local repathAttempts = 0
local MAX_REPATH_ATTEMPTS = AIConfig.MAX_REPATH_ATTEMPTS or 3
local pursueStartTime = 0

local PURSUE_REPATH_INTERVAL = AIConfig.PURSUE_REPATH_INTERVAL or 1.0
local PURSUE_REPATH_MOVE_DISTANCE = AIConfig.PURSUE_REPATH_MOVE_DISTANCE or 8
local DIRECT_CHASE_DISTANCE = AIConfig.DIRECT_CHASE_DISTANCE or 30
local GIVE_UP_DISTANCE = AIConfig.GIVE_UP_DISTANCE or 120

states.Pursue = State.new(
	"Pursue",

	function()
		dprint("Pursuing target:", currentTarget and currentTarget.Name or "nil")

		humanoid.WalkSpeed = CONFIG.RUN_SPEED
		allowRunningControl = true

		lastRepathAttempt = 0
		repathAttempts = 0
		pursueStartTime = os.clock()

		local targetHRP = getTargetHRP(currentTarget)

		if targetHRP and canUseRangedAgainstTarget(targetHRP) then
			dprint("Pursue start: target is already shootable, switching to ranged")
			changeState("AttackRanged")
			return
		end

		local targetPos = getPursueTargetPosition(currentTarget)

		if targetPos then
			local ok = setNavTargetSafe(targetPos)

			if not ok then
				repathAttempts += 1
				lastRepathAttempt = os.clock()
				dprint("No path found on pursue start - will retry/direct chase")
			end
		else
			dprint("No valid grounded target on pursue start")
			lastRepathAttempt = os.clock()
		end
	end,

	function()
		local targetHRP = getTargetHRP(currentTarget)

		if not targetHRP then
			dprint("Lost target, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local rawTargetPos = targetHRP.Position
		local distance = (hrp.Position - rawTargetPos).Magnitude

		local isRanged = enemyDef.IsRanged or false
		local combatRole = enemyDef.CombatRole or "melee"
		local meleeRange = enemyDef.MeleeRange or 5

		if isRanged then
			if combatRole == "melee" then
				if distance <= meleeRange then
					dprint("Entering melee attack (melee role)")
					changeState("AttackMelee")
					return
				end

			elseif combatRole == "ranged" then
				if distance <= meleeRange then
					dprint("Forced into melee attack (ranged role)")
					changeState("AttackMelee")
					return
				end

				if canUseRangedAgainstTarget(targetHRP) then
					dprint("Entering ranged attack (ranged role)")
					changeState("AttackRanged")
					return
				end

			elseif combatRole == "hybrid" then
				if distance <= meleeRange then
					dprint("Entering melee attack (hybrid role)")
					changeState("AttackMelee")
					return
				end

				if canUseRangedAgainstTarget(targetHRP) then
					local pursuingTime = os.clock() - pursueStartTime

					if pursuingTime > 0.75 then
						dprint("Entering ranged attack because target is shootable")
						changeState("AttackRanged")
						return
					end
				end
			end
		else
			if distance <= meleeRange then
				dprint("Entering melee attack (melee-only)")
				changeState("AttackMelee")
				return
			end
		end

		local now = os.clock()
		local groundedTargetPos = getPursueTargetPosition(currentTarget)

		if nav._targetPos then
			local arrived = nav:Step()
			local shouldRepath = false

			-- Only repath if we arrived at the old goal, or the target moved enough.
			-- Do NOT repath just because time passed.
			if arrived then
				shouldRepath = true
			end

			if groundedTargetPos then
				local moved = (groundedTargetPos - nav._targetPos).Magnitude

				if moved > PURSUE_REPATH_MOVE_DISTANCE and (now - lastRepathAttempt) >= PURSUE_REPATH_INTERVAL then
					shouldRepath = true
				end
			end

			if shouldRepath then
				lastRepathAttempt = now

				if groundedTargetPos then
					local ok = setNavTargetSafe(groundedTargetPos)

					if ok then
						repathAttempts = 0
					else
						repathAttempts += 1
						dprint(string.format("Repath failed (attempt %d/%d)", repathAttempts, MAX_REPATH_ATTEMPTS))
					end
				else
					repathAttempts += 1
					dprint("Repath skipped; grounded target was invalid")
				end
			end
		else
			if (now - lastRepathAttempt) > 1.0 and repathAttempts < MAX_REPATH_ATTEMPTS then
				lastRepathAttempt = now
				repathAttempts += 1

				dprint(string.format("Attempting repath (%d/%d)...", repathAttempts, MAX_REPATH_ATTEMPTS))

				if groundedTargetPos then
					local ok = setNavTargetSafe(groundedTargetPos)

					if ok then
						dprint("Repath successful!")
						repathAttempts = 0
					else
						dprint("Repath failed")
					end
				else
					dprint("Cannot repath; grounded target position invalid")
				end
			end

			if repathAttempts >= MAX_REPATH_ATTEMPTS and canUseRangedAgainstTarget(targetHRP) then
				dprint("Path failed, but ranged LOS is valid - attacking instead of giving up")
				changeState("AttackRanged")
				return
			end

			if distance < DIRECT_CHASE_DISTANCE or repathAttempts >= MAX_REPATH_ATTEMPTS then
				dprint("Using direct chase (distance: " .. math.floor(distance) .. " studs)")
				humanoid.WalkSpeed = CONFIG.RUN_SPEED
				humanoid:MoveTo(rawTargetPos)
			end

			if distance > GIVE_UP_DISTANCE and repathAttempts >= MAX_REPATH_ATTEMPTS then
				if canUseRangedAgainstTarget(targetHRP) then
					dprint("Target unreachable by path, but ranged LOS is valid - attacking upward")
					changeState("AttackRanged")
					return
				end

				dprint("Target too far and unreachable - giving up")
				currentTarget = nil
				changeState("Idle")
				return
			end
		end
	end,

	function()
		nav:Clear()
		lastRepathAttempt = 0
		repathAttempts = 0
	end
)

------------------------------------------------------------------
-- AttackMelee State
------------------------------------------------------------------
local lastMeleeAttackTime = 0

states.AttackMelee = State.new(
	"AttackMelee",

	function()
		dprint("Melee attacking target:", currentTarget and currentTarget.Name or "nil")

		cancelHumanoidMove()
		allowRunningControl = false
		humanoid.WalkSpeed = 0

		lastMeleeAttackTime = 0
	end,

	function()
		local targetHRP = getTargetHRP(currentTarget)

		if not targetHRP then
			dprint("Lost target during melee attack, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local distance = (hrp.Position - targetHRP.Position).Magnitude
		local meleeRange = enemyDef.MeleeRange or 5

		if distance > meleeRange then
			dprint("Target left melee range, pursuing")
			changeState("Pursue")
			return
		end

		local lookAt = targetHRP.Position
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z))

		local attackSpeed = enemyDef.MeleeAttackSpeed or enemyDef.AttackSpeed or 2.0
		local attackCooldown = 1.0 / attackSpeed

		local now = os.clock()

		if now - lastMeleeAttackTime >= attackCooldown then
			lastMeleeAttackTime = now

			if Tracks.Attack then
				Tracks.Attack.Looped = false
				playAction(Tracks.Attack, 0.05, 0, true)
			end

			dprint("Melee strike!")
			EnemyCombatFunctions.HandleMelee(npc, targetHRP.Position, currentTarget)
		else
			if not Tracks.Attack or not Tracks.Attack.IsPlaying then
				playGround(Tracks.Idle1, 0.15, false)
			end
		end
	end,

	function()
		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

------------------------------------------------------------------
-- AttackRanged State
------------------------------------------------------------------
local lastRangedAttackTime = 0
local rangedLostShootableSince: number? = nil

local rangedMarkerConn: RBXScriptConnection? = nil
local pendingRangedShot = false
local rangedShotToken = 0

local function createRangedDebugPart(name: string, size: Vector3, cf: CFrame, color: Color3, lifetime: number)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = 0.15

	local folder = workspace:FindFirstChild("HelperParts") or workspace
	part.Parent = folder

	Debris:AddItem(part, lifetime)

	return part
end

local function debugRangedFireOrigin(origin: Vector3, targetPosition: Vector3, sourceName: string?)
	if not CONFIG.DEBUG_RANGED_FIRE_ORIGIN then
		return
	end

	local delta = targetPosition - origin

	if delta.Magnitude <= 0.01 then
		return
	end

	local lifetime = CONFIG.DEBUG_RANGED_FIRE_ORIGIN_LIFETIME or 3.0
	local length = CONFIG.DEBUG_RANGED_FIRE_ORIGIN_LENGTH or 8.0
	local direction = delta.Unit
	local cf = CFrame.new(origin, origin + direction)

	-- Green cube = exact shot origin.
	createRangedDebugPart(
		"DEBUG_EnemyLaser_ORIGIN_" .. tostring(sourceName or "Unknown"),
		Vector3.new(0.45, 0.45, 0.45),
		CFrame.new(origin),
		Color3.fromRGB(0, 255, 0),
		lifetime
	)

	-- Red bar = final shot direction toward the target.
	createRangedDebugPart(
		"DEBUG_EnemyLaser_DIRECTION",
		Vector3.new(0.16, 0.16, length),
		cf * CFrame.new(0, 0, -(length * 0.5)),
		Color3.fromRGB(255, 0, 0),
		lifetime
	)

	-- Yellow cube = forward tip of the shot direction.
	createRangedDebugPart(
		"DEBUG_EnemyLaser_FORWARD_TIP",
		Vector3.new(0.35, 0.35, 0.35),
		cf * CFrame.new(0, 0, -length),
		Color3.fromRGB(255, 255, 0),
		lifetime
	)

	-- Blue vertical bar = world-up reference at the origin, to make orientation easier to read.
	createRangedDebugPart(
		"DEBUG_EnemyLaser_UP_REFERENCE",
		Vector3.new(0.12, 1.5, 0.12),
		CFrame.new(origin + Vector3.new(0, 0.75, 0)),
		Color3.fromRGB(0, 170, 255),
		lifetime
	)

	print(
		("[RANGED ORIGIN DEBUG] npc=%s source=%s origin=(%.2f, %.2f, %.2f) target=(%.2f, %.2f, %.2f) dir=(%.3f, %.3f, %.3f) distance=%.2f")
			:format(
				npc.Name,
				tostring(sourceName or "Unknown"),
				origin.X, origin.Y, origin.Z,
				targetPosition.X, targetPosition.Y, targetPosition.Z,
				direction.X, direction.Y, direction.Z,
				delta.Magnitude
			)
	)
end

local function getRangedFireOrigin(): (Vector3, string)
	for _, muzzleName in ipairs(CONFIG.RANGED_MUZZLE_NAMES) do
		local muzzle = npc:FindFirstChild(muzzleName, true)

		if muzzle then
			if muzzle:IsA("Attachment") then
				return muzzle.WorldPosition, muzzle:GetFullName()
			elseif muzzle:IsA("BasePart") then
				return muzzle.Position, muzzle:GetFullName()
			end
		end
	end

	return npc.PrimaryPart.Position + Vector3.new(0, enemyDef.RangedOriginHeight or 2, 0), "PrimaryPartHeightFallback"
end

local function fireRangedShot(targetHRP: BasePart, distance: number)
	if not targetHRP then
		return
	end

	local enemyOffsetFiringPosition, fireSourceName = getRangedFireOrigin()
	local targetPosition = targetHRP.Position + Vector3.new(0, enemyDef.RangedTargetHeight or 2, 0)

	dprint(string.format("Ranged shot! (distance: %.1f, source: %s)", distance, tostring(fireSourceName)))

	debugRangedFireOrigin(enemyOffsetFiringPosition, targetPosition, fireSourceName)

	EnemyCombatFunctions.HandleRanged(
		npc,
		targetPosition,
		enemyDef.RangedProjectileSpeed or 1000,
		enemyDef.RangedAmmo,
		enemyOffsetFiringPosition
	)
end

local function disconnectRangedMarker()
	if rangedMarkerConn then
		rangedMarkerConn:Disconnect()
		rangedMarkerConn = nil
	end
end

local function getRangedFallbackDelay()
	if CONFIG.RANGED_FIRE_FALLBACK_DELAY then
		return CONFIG.RANGED_FIRE_FALLBACK_DELAY
	end

	if Tracks.Attack and Tracks.Attack.Length and Tracks.Attack.Length > 0 then
		return math.clamp(
			Tracks.Attack.Length * CONFIG.RANGED_FIRE_FALLBACK_PERCENT,
			0.1,
			1.25
		)
	end

	return 0.35
end

local function playRangedMarkerAttack(targetHRP: BasePart, distance: number)
	if not targetHRP then
		return
	end

	if not Tracks.Attack then
		fireRangedShot(targetHRP, distance)
		return
	end

	rangedShotToken += 1
	local thisToken = rangedShotToken

	pendingRangedShot = true
	disconnectRangedMarker()

	local markerName = CONFIG.RANGED_FIRE_MARKER or "Fire"
	local fallbackDelay = getRangedFallbackDelay()

	rangedMarkerConn = Tracks.Attack:GetMarkerReachedSignal(markerName):Connect(function()
		if thisToken ~= rangedShotToken then
			return
		end

		if not pendingRangedShot then
			return
		end

		if not currentState or currentState.Name ~= "AttackRanged" then
			return
		end

		pendingRangedShot = false

		local freshTargetHRP = getTargetHRP(currentTarget)
		if freshTargetHRP then
			local freshDistance = (hrp.Position - freshTargetHRP.Position).Magnitude
			fireRangedShot(freshTargetHRP, freshDistance)
		end
	end)

	Tracks.Attack.Looped = false
	playAction(Tracks.Attack, 0.05, 0, true)

	task.delay(fallbackDelay, function()
		if thisToken ~= rangedShotToken then
			return
		end

		if not pendingRangedShot then
			return
		end

		if not currentState or currentState.Name ~= "AttackRanged" then
			return
		end

		pendingRangedShot = false

		if CONFIG.DEBUG then
			warn(("[PassiveWanderingAI] Ranged marker %q did not fire; using fallback shot after %.2fs."):format(
				markerName,
				fallbackDelay
				))
		end

		local freshTargetHRP = getTargetHRP(currentTarget)
		if freshTargetHRP then
			local freshDistance = (hrp.Position - freshTargetHRP.Position).Magnitude
			fireRangedShot(freshTargetHRP, freshDistance)
		end
	end)
end

states.AttackRanged = State.new(
	"AttackRanged",

	function()
		dprint("Ranged attacking target:", currentTarget and currentTarget.Name or "nil")

		cancelHumanoidMove()
		allowRunningControl = false
		humanoid.WalkSpeed = 0

		lastRangedAttackTime = 0
		rangedLostShootableSince = nil
		pendingRangedShot = false
		rangedShotToken += 1
		disconnectRangedMarker()

		local mode = CONFIG.RANGED_ANIMATION_MODE or "Loop"

		if Tracks.Attack then
			if mode == "Loop" then
				Tracks.Attack.Looped = true
				playAction(Tracks.Attack, 0.05, 0, false)

			elseif mode == "Marker" then
				Tracks.Attack.Looped = false
			end
		end
	end,

	function()
		local targetHRP = getTargetHRP(currentTarget)

		if not targetHRP then
			dprint("Lost target during ranged attack, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local distance = (hrp.Position - targetHRP.Position).Magnitude
		local meleeRange = enemyDef.MeleeRange or 5
		local combatRole = enemyDef.CombatRole or "melee"

		if distance < meleeRange then
			if combatRole == "ranged" then
				dprint("Target too close, backing up")

				local flatDelta = Vector3.new(
					hrp.Position.X - targetHRP.Position.X,
					0,
					hrp.Position.Z - targetHRP.Position.Z
				)

				if flatDelta.Magnitude > 0.1 then
					local awayDir = flatDelta.Unit
					local backupPos = hrp.Position + (awayDir * 5)

					humanoid.WalkSpeed = CONFIG.RUN_SPEED
					humanoid:MoveTo(backupPos)
				end

				return
			else
				dprint("Target in melee range, switching to melee")
				changeState("AttackMelee")
				return
			end
		end

		local shootable = canUseRangedAgainstTarget(targetHRP)

		if shootable then
			rangedLostShootableSince = nil
		else
			if not rangedLostShootableSince then
				rangedLostShootableSince = os.clock()
			end

			local lostFor = os.clock() - rangedLostShootableSince

			if lostFor < CONFIG.RANGED_LOST_SHOOTABLE_GRACE then
				dprint(("Target briefly not shootable; holding ranged for %.2fs"):format(lostFor))

				cancelHumanoidMove()
				humanoid.WalkSpeed = 0

				local lookAt = targetHRP.Position
				hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z))

				if CONFIG.RANGED_ANIMATION_MODE == "Loop" and Tracks.Attack then
					Tracks.Attack.Looped = true
					playAction(Tracks.Attack, 0.05, 0, false)
				elseif not Tracks.Attack or not Tracks.Attack.IsPlaying then
					playGround(Tracks.Idle1, 0.15, false)
				end

				return
			end

			dprint("Target not shootable after grace period, pursuing")
			rangedLostShootableSince = nil
			pendingRangedShot = false
			rangedShotToken += 1
			disconnectRangedMarker()

			changeState("Pursue")
			return
		end

		cancelHumanoidMove()
		humanoid.WalkSpeed = 0

		local lookAt = targetHRP.Position
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z))

		local attackSpeed = enemyDef.RangedAttackSpeed or enemyDef.AttackSpeed or 1.0
		local attackCooldown = 1.0 / attackSpeed
		local now = os.clock()

		local mode = CONFIG.RANGED_ANIMATION_MODE or "Loop"

		if mode == "Loop" then
			if Tracks.Attack then
				Tracks.Attack.Looped = true
				playAction(Tracks.Attack, 0.05, 0, false)
			end

			if now - lastRangedAttackTime >= attackCooldown then
				lastRangedAttackTime = now
				fireRangedShot(targetHRP, distance)
			end

		elseif mode == "Marker" then
			if now - lastRangedAttackTime >= attackCooldown then
				lastRangedAttackTime = now
				playRangedMarkerAttack(targetHRP, distance)
			end

			if not Tracks.Attack or not Tracks.Attack.IsPlaying then
				playGround(Tracks.Idle1, 0.15, false)
			end

		else
			if now - lastRangedAttackTime >= attackCooldown then
				lastRangedAttackTime = now
				fireRangedShot(targetHRP, distance)
			end
		end
	end,

	function()
		rangedLostShootableSince = nil
		pendingRangedShot = false
		rangedShotToken += 1
		disconnectRangedMarker()

		stopAction(0.1)

		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

------------------------------------------------------------------
-- Alarmed
------------------------------------------------------------------
if CONFIG.ENABLE_ALARMED then
	local alarmedStateCount = 0
	local lastAlarmedMove = 0

	states.Alarmed = State.new(
		"Alarmed",

		function()
			alarmedStateCount += 1
			lastAlarmedMove = os.clock()

			humanoid.WalkSpeed = CONFIG.RUN_SPEED * 1.5
			allowRunningControl = true

			dprint("Alarmed! Count:", alarmedStateCount)

			if CONFIG.OnAlarmedStart then
				pcall(function()
					CONFIG.OnAlarmedStart(npc, Tracks)
				end)
			end
		end,

		function()
			local now = os.clock()

			if (now - lastAlarmedMove) >= CONFIG.ALARM_STATE_FREQUENCY then
				alarmedStateCount += 1
				dprint("Alarmed! Count:", alarmedStateCount)

				local fleePos = Nav.RandomPointInRadius(hrp.Position, CONFIG.ALARM_STATE_DISTANCE, rng)
				local grounded = nav:GetGroundedPosition(fleePos)

				if grounded then
					setNavTargetSafe(grounded)
				end

				lastAlarmedMove = now
			end

			nav:Step()

			if alarmedStateCount >= CONFIG.ALARM_STATE_COUNT_MAX then
				nav:Clear()
				alarmedStateCount = 0
				changeState("Idle")
			end
		end,

		function()
			humanoid.WalkSpeed = CONFIG.WALK_SPEED
		end
	)
end

------------------------------------------------------------------
-- Held State
------------------------------------------------------------------
local lastHeldChange = 0

states.Held = State.new(
	"Held",

	function()
		dprint("Entering Held state")

		nav:Clear()
		cancelHumanoidMove()

		humanoid.WalkSpeed = 0
		humanoid.Jump = false

		local navHitbox = npc:FindFirstChild("NavHitbox")
		if navHitbox then
			navHitbox.CanCollide = false
		end

		allowRunningControl = false
		lastHeldChange = os.clock()

		stopAction(0.1)

		local heldIdle = Tracks.Idle4 or Tracks.Idle1
		playGround(heldIdle, 0.2, true)

		if CONFIG.OnIdleStart then
			pcall(function()
				CONFIG.OnIdleStart(npc, Tracks, 4)
			end)
		end
	end,

	function()
		if os.clock() - lastHeldChange > 5 then
			lastHeldChange = os.clock()

			local whichIdle = rng:NextInteger(1, 4)
			local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1

			playGround(idleTrack, 0.2, true)

			if CONFIG.OnIdleUpdate then
				pcall(function()
					CONFIG.OnIdleUpdate(npc, Tracks, os.clock(), whichIdle)
				end)
			end
		end

		if not npc:GetAttribute("HeldBy") then
			changeState("Idle")
		end
	end,

	function()
		local navHitbox = npc:FindFirstChild("NavHitbox")
		if navHitbox then
			navHitbox.CanCollide = true
		end

		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

------------------------------------------------------------------
-- Death handling
------------------------------------------------------------------
local function stopAllTracks(fade)
	fade = fade or 0.1

	for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
		pcall(function()
			tr:Stop(fade)
		end)
	end

	currentGroundTrack = nil
	currentActionTrack = nil
end

local function freezeTrackAtEnd(track)
	if not track then return end

	pcall(function()
		local len = track.Length

		if len and len > 0 then
			track.TimePosition = math.max(0, len - 0.03)
		end

		track:AdjustSpeed(0)
	end)
end

local function checkAlive()
	if not npc:GetAttribute("Dead") then
		return true
	end

	if deathLocked then
		return false
	end

	deathLocked = true

	allowRunningControl = false
	nav:Clear()

	pcall(function()
		humanoid:Move(Vector3.zero)
	end)

	pcall(function()
		humanoid.WalkSpeed = 0
	end)

	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	stopAllTracks(0.05)

	local die = Tracks.Die

	if die then
		die.Looped = false
		die.Priority = Enum.AnimationPriority.Action4

		local reachedEndedMarker = false
		local markerConn

		markerConn = die:GetMarkerReachedSignal("Ended"):Connect(function()
			reachedEndedMarker = true

			if markerConn then
				markerConn:Disconnect()
			end

			pcall(function()
				die:AdjustSpeed(0)
				die:AdjustWeight(1, 0)
			end)
		end)

		pcall(function()
			dprint("PLAY DIE ANIMATION")
			die.TimePosition = 0
			die:Play(0.05, 1, 1)
		end)

		local timeout = os.clock() + ((die.Length and die.Length > 0) and (die.Length + 0.75) or 6)

		while not reachedEndedMarker and os.clock() < timeout do
			task.wait(0.05)
		end

		if not reachedEndedMarker then
			if markerConn then
				markerConn:Disconnect()
			end

			freezeTrackAtEnd(die)
		end
	end

	return false
end

local function CheckHeld()
	if npc:GetAttribute("HeldBy") and currentState and currentState.Name ~= "Held" then
		changeState("Held")
	end
end

------------------------------------------------------------------
-- Boot
------------------------------------------------------------------
changeState("Idle")

------------------------------------------------------------------
-- NPC-only AI tick
------------------------------------------------------------------
local lastOwnerCheck = 0

task.spawn(function()
	while checkAlive() and npc.Parent do
		local now = os.clock()

		if now - lastOwnerCheck > 2 then
			lastOwnerCheck = now

			pcall(function()
				if hrp:GetNetworkOwner() ~= nil then
					hrp:SetNetworkOwner(nil)
				end
			end)
		end

		decayThreat()

		checkForPlayers()
		checkHit()
		CheckHeld()

		if currentState and currentState.OnUpdate then
			local ok, err = pcall(function()
				currentState.OnUpdate()
			end)

			if not ok then
				warn("[PassiveWanderingAI] State update error in", currentState and currentState.Name or "nil", err)
				nav:Clear()
				currentTarget = nil
				changeState("Idle")
			end
		end

		task.wait(CONFIG.AI_TICK)
	end

	dprint("DEAD")
	Debris:AddItem(npc, 10)
end)