-- PassiveWanderingAI.server.lua
-- AI with state machine + wandering + jump assist + THREAT-BASED TARGETING
-- Ground anim driven by Humanoid.Running (when enabled)
-- Air anim driven by Humanoid.StateChanged (Freefall/Landed/Jump)

--Roblox Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Players = game:GetService("Players")

--Definition Modules
local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local EnemySpawningConfig = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("EnemySpawningConfig"))
local EnemyCombatFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("EnemyCombatFunctions"))

--Modules
local Nav = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("Nav"))

------------------------------------------------------------------
-- CONTEXT
------------------------------------------------------------------
local npc = script.Parent
local humanoid: Humanoid = npc:WaitForChild("Humanoid")
local body = npc:WaitForChild("Body")
local hrp: BasePart = npc:WaitForChild("HumanoidRootPart")
local animationsFolder = npc:WaitForChild("Animations")

-- Safe read of AIConfig from ConfigId attribute
local configId = npc:GetAttribute("ConfigId")
local spawnerCfg = (configId and EnemySpawningConfig.Spawners and EnemySpawningConfig.Spawners[configId]) or nil
local AIConfig = (spawnerCfg and spawnerCfg.AIConfig) or {}

local currentTarget = nil

-- ========================================
-- THREAT SYSTEM
-- ========================================
local threatTable = {} -- [userId] = {Player = player, Damage = totalDamage, LastHit = timestamp}
local THREAT_SWITCH_THRESHOLD = 1.5 -- Must deal 1.5x more damage to steal aggro
local THREAT_DECAY_RATE = 0.05 -- Reduce threat by 5% per second  
local THREAT_FORGET_TIME = 30 -- Forget threat after 30 seconds of no hits
local THREAT_RESET_DISTANCE = 200 -- Clear threat if player gets this far away

------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------
local enemyDef = enemiesModule[npc.Name] or {}

local navHitboxSize = enemyDef.NavHitboxSize or Vector3.new(3, 5, 5)

local CONFIG = {
	-- wandering
	WANDER_RADIUS = AIConfig.WANDER_RADIUS or 100,
	MIN_IDLE_TIME = AIConfig.MIN_IDLE_TIME or 2.0,
	MAX_IDLE_TIME = AIConfig.MAX_IDLE_TIME or 2.0,
	MIN_LINGER_TIME = AIConfig.MIN_LINGER_TIME or 4.0,
	MAX_LINGER_TIME = AIConfig.MAX_LINGER_TIME or 10.0,
	MAX_WANDER_TIME = AIConfig.MAX_WANDER_TIME or 60.0,

	-- movement speed
	WALK_SPEED = enemyDef.WalkSpeed or 10,
	RUN_SPEED = enemyDef.RunSpeed or 14,

	-- Alarmed behavior
	ENABLE_ALARMED = AIConfig.ENABLE_ALARMED or false,
	ALARM_TRIGGER_DISTANCE = AIConfig.ALARM_TRIGGER_DISTANCE or 30,
	ALARM_STATE_FREQUENCY = AIConfig.ALARM_STATE_FREQUENCY or 2,
	ALARM_STATE_DISTANCE = AIConfig.ALARM_STATE_DISTANCE or 20,
	ALARM_STATE_COUNT_MAX = AIConfig.ALARM_STATE_COUNT_MAX or 3,

	-- Optional hooks (functions can live in AIConfig if you require+inject them; nil is fine)
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

		AGENT_RADIUS = (AIConfig.AGENT_RADIUS or navHitboxSize.X or 3),
		AGENT_HEIGHT = (AIConfig.AGENT_HEIGHT or navHitboxSize.Y or 5),
		AGENT_CAN_JUMP = true,
		AGENT_JUMP_HEIGHT = AIConfig.AGENT_JUMP_HEIGHT or 10,
		AGENT_MAX_SLOPE = AIConfig.AGENT_MAX_SLOPE or 30,

		ARRIVAL_DISTANCE = AIConfig.ARRIVAL_DISTANCE or 3.0,

		ENABLE_JUMP_OVER = (AIConfig.ENABLE_JUMP_OVER ~= false),
		OBSTACLE_CHECK_DISTANCE = AIConfig.OBSTACLE_CHECK_DISTANCE or 4.0,
		MAX_JUMP_OBSTACLE_HEIGHT = AIConfig.MAX_JUMP_OBSTACLE_HEIGHT or 4.0,
		JUMP_COOLDOWN = AIConfig.JUMP_COOLDOWN or 1.0,

		STUCK_REPATH_SECONDS = AIConfig.STUCK_REPATH_SECONDS or 3.5,
		MIN_PROGRESS_DISTANCE = AIConfig.MIN_PROGRESS_DISTANCE or 2.5,

		DEBUG = AIConfig.DEBUG or false,
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

local deathLocked = false


-- Create a collidable hitbox so walls block the NPC
do
	local hitbox = npc:FindFirstChild("NavHitbox")
	if not hitbox then
		hitbox = Instance.new("Part")
		hitbox.Name = "NavHitbox"
		hitbox.Size = navHitboxSize
		hitbox.Transparency = 1
		hitbox.CanCollide = true
		hitbox.CanTouch = false
		hitbox.CanQuery = false
		hitbox.Anchored = false
		hitbox.Massless = true
		hitbox.CFrame = hrp.CFrame
		hitbox.CollisionGroup  = "Helpers"
		hitbox.Parent = npc



		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hitbox
		weld.Part1 = hrp
		weld.Parent = hitbox
	end
end

-- Disable default Animate so it doesn't fight your tracks
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
	-- We set looped on idles later too, but doing it here doesn't hurt.
	return track
end

local Tracks = {
	Idle1     = loadAnim("Idle1"),
	Idle2     = loadAnim("Idle2"),
	Idle3     = loadAnim("Idle3"),
	Idle4     = loadAnim("Idle4"),
	Run       = loadAnim("Run"),
	Jump      = loadAnim("Jump"),
	Freefall  = loadAnim("Fall"),
	Landed    = loadAnim("Land"),
	Attack    = loadAnim("Attack"),
	Die    = loadAnim("Die"),
	WingsFlap = loadAnim("WingsFlap"),
	WingsIdle = loadAnim("WingsIdle"),
}

-- Priorities
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

-- Cancel active MoveTo + zero input
local function cancelHumanoidMove()
	local p = hrp.Position
	-- Cancels MoveTo by re-issuing to current pos
	pcall(function() humanoid:MoveTo(p) end)
	pcall(function() humanoid:Move(Vector3.zero) end)
end

-- Stop all playing tracks except keep (used to make Idle "win")
local function stopAllTracksExcept(keep: AnimationTrack?, fade: number?)
	fade = fade or 0.12
	for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
		if t ~= keep then
			pcall(function() t:Stop(fade) end)
		end
	end
end

-- Ground layer
local currentGroundTrack: AnimationTrack? = nil

local function playGround(track: AnimationTrack?, fade: number?, hardTakeover: boolean?)
	if not track then return end
	fade = fade or 0.15

	-- Ensure loop for idle/run style tracks
	if track.Priority == Enum.AnimationPriority.Idle or track.Priority == Enum.AnimationPriority.Movement then
		track.Looped = true
	end

	if currentGroundTrack == track then
		-- Reassert weight
		pcall(function() track:AdjustWeight(1, fade) end)
		return
	end

	if currentGroundTrack then
		pcall(function() currentGroundTrack:Stop(fade) end)
	end
	currentGroundTrack = track

	if hardTakeover then
		stopAllTracksExcept(track, fade)
	end

	dprint("[PassiveWanderingAI] Playing ground:", track.Name)
	pcall(function()
		track:Play(fade, 1, 1)
		track:AdjustWeight(1, fade)
	end)
end

-- Action layer
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

	-- ✅ Force replay OR different track
	if force or currentActionTrack ~= track then
		if currentActionTrack then
			pcall(function() currentActionTrack:Stop(fade) end)
		end
		currentActionTrack = track

		-- ✅ Reset to beginning for forced replays
		if force then
			pcall(function() track.TimePosition = 0 end)
		end

		pcall(function()
			track:Play(fade, 1, 1)
			track:AdjustWeight(1, fade)
		end)
	end

	if lockSeconds > 0 then
		actionLockUntil = os.clock() + lockSeconds
	end
end

local function stopAction(fade: number?)
	fade = fade or 0.12
	if currentActionTrack then
		pcall(function() currentActionTrack:Stop(fade) end)
	end
	currentActionTrack = nil
	actionLockUntil = 0
end

------------------------------------------------------------------
-- Nav
------------------------------------------------------------------
local nav = Nav.new(npc, humanoid, hrp, CONFIG.NAV)

-- If Nav folder missing, don't crash
local navFolder = workspace:FindFirstChild("Nav")
if navFolder then
	nav:SetLinksFromContainer(navFolder)
else
	warn("[PassiveWanderingAI] workspace.Nav not found; PathfindingLinks will not be registered.")
end

local rng = Random.new()
local startPos = hrp.Position

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
		-- pick a consistent idle (Idle1 fallback)
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
	return setmetatable({ Name = name, OnEnter = onEnter, OnUpdate = onUpdate, OnExit = onExit }, State)
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
local function updateThreat(player, damageDealt)
	if not player then return end

	local userId = player.UserId
	local now = os.time()

	if not threatTable[userId] then
		threatTable[userId] = {
			Player = player,
			Damage = 0,
			LastHit = now
		}
	end

	threatTable[userId].Damage = threatTable[userId].Damage + damageDealt
	threatTable[userId].LastHit = now

	dprint(string.format("[THREAT] %s dealt %.1f damage (total: %.1f)", 
		player.Name, damageDealt, threatTable[userId].Damage))

	-- Get highest threat player
	local highestThreat = 0
	local highestPlayer = nil

	for userId, threatData in pairs(threatTable) do
		-- Check distance - forget if too far
		local targetChar = threatData.Player.Character
		if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
			local dist = (targetChar.HumanoidRootPart.Position - hrp.Position).Magnitude
			if dist > THREAT_RESET_DISTANCE then
				dprint(string.format("[THREAT] %s too far (%.1f studs), clearing threat", threatData.Player.Name, dist))
				threatTable[userId] = nil
				if currentTarget == threatData.Player then
					currentTarget = nil
				end
			elseif threatData.Damage > highestThreat then
				highestThreat = threatData.Damage
				highestPlayer = threatData.Player
			end
		end
	end

	-- Switch target if someone else has significantly more threat
	if currentTarget ~= highestPlayer then
		local currentThreat = 0
		if currentTarget then
			local currentUserId = currentTarget.UserId
			currentThreat = (threatTable[currentUserId] and threatTable[currentUserId].Damage) or 0
		end

		-- Only switch if new player has THREAT_SWITCH_THRESHOLD times more damage
		if highestPlayer and highestThreat > currentThreat * THREAT_SWITCH_THRESHOLD then
			dprint(string.format("[THREAT SWITCH] %s -> %s (%.1f -> %.1f damage)",
				currentTarget and currentTarget.Name or "none",
				highestPlayer.Name,
				currentThreat,
				highestThreat))

			currentTarget = highestPlayer
			changeState("Pursue")
			return true
		end
	elseif not currentTarget and highestPlayer then
		-- No current target, pursue first attacker
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
		-- ✅ Only decay if we're NOT currently targeting this player
		local isCurrentTarget = (currentTarget and currentTarget.UserId == userId)

		if not isCurrentTarget then
			-- Decay threat over time for non-active targets
			threatTable[userId].Damage = threatData.Damage * (1 - THREAT_DECAY_RATE * CONFIG.AI_TICK)
		end

		-- Remove if threat too old or too low (only for non-active targets)
		if not isCurrentTarget then
			if (now - threatData.LastHit > THREAT_FORGET_TIME) or threatData.Damage < 1 then
				dprint(string.format("[THREAT] Forgot %s (threat: %.1f, age: %ds)", 
					threatData.Player.Name, threatData.Damage, now - threatData.LastHit))
				threatTable[userId] = nil
			end
		end
	end
end

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	if threatTable[userId] then
		dprint(string.format("[THREAT] Player left: %s", player.Name))
		threatTable[userId] = nil

		if currentTarget == player then
			currentTarget = nil
			dprint("[THREAT] Current target left, searching for new target")

			-- Find next highest threat target
			local highestThreat = 0
			local highestPlayer = nil

			for userId, threatData in pairs(threatTable) do
				if threatData.Damage > highestThreat then
					highestThreat = threatData.Damage
					highestPlayer = threatData.Player
				end
			end

			if highestPlayer then
				dprint(string.format("[THREAT] Switching to next target: %s (%.1f threat)", highestPlayer.Name, highestThreat))
				currentTarget = highestPlayer
			end
		end
	end
end)

------------------------------------------------------------------
-- Player hit check
------------------------------------------------------------------
function checkHit()
	local hit = npc:GetAttribute("Hit")
	if not hit then return false end

	local hitByUserId = npc:GetAttribute("HitByUserId")
	local hitDamage = npc:GetAttribute("HitDamage")

	if not hitByUserId or not hitDamage then return false end

	local player = Players:GetPlayerByUserId(hitByUserId)

	if player then
		updateThreat(player, hitDamage)
		-- Clear the hit attributes
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
		local char = player.Character
		local phrp = char and char:FindFirstChild("HumanoidRootPart")
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

-- Idle
local idleUntil = 0
local lastIdleChange = 0

states.Idle = State.new(
	"Idle",
	function()
		nav:Clear()

		-- Hard stop movement AND cancel any pending MoveTo
		cancelHumanoidMove()
		humanoid.WalkSpeed = 0
		humanoid.Jump = false

		-- Disable Running control while we manually play idle
		allowRunningControl = false

		idleUntil = os.clock() + rng:NextNumber(CONFIG.MIN_IDLE_TIME, CONFIG.MAX_IDLE_TIME)
		lastIdleChange = os.clock()

		stopAction(0.1)

		local whichIdle = rng:NextInteger(1, 4)
		local idleTrack = Tracks["Idle" .. tostring(whichIdle)] or Tracks.Idle1 or Tracks.Idle2 or Tracks.Idle3 or Tracks.Idle4
		playGround(idleTrack, 0.2, true) -- HARD TAKEOVER so idle wins

		if CONFIG.OnIdleStart then
			pcall(function()
				CONFIG.OnIdleStart(npc, Tracks, whichIdle)
			end)
		end
	end,
	function()
		-- rotate idle occasionally
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
		-- Restore movement
		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)

-- PickWander
states.PickWander = State.new(
	"PickWander",
	function()
		local raw = Nav.RandomPointInRadius(startPos, CONFIG.WANDER_RADIUS, rng)
		local grounded = nav:GetGroundedPosition(raw)
		if grounded then
			nav:SetTarget(grounded)
			changeState("Wander")
		else
			-- If we couldn't ground it, just idle again
			changeState("Idle")
		end
	end
)

-- Wander
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

-- Linger
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

-- Pursue State
local lastRepathAttempt = 0
local repathAttempts = 0
local MAX_REPATH_ATTEMPTS = 3
local pursueStartTime = 0

states.Pursue = State.new(
	"Pursue",
	function()
		dprint("Pursuing target:", currentTarget and currentTarget.Name or "nil")
		humanoid.WalkSpeed = CONFIG.RUN_SPEED
		allowRunningControl = true

		-- Reset repath tracking
		lastRepathAttempt = 0
		repathAttempts = 0
		pursueStartTime = os.clock()

		-- ✅ Set target ONCE on entering state
		if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
			local targetHRP = currentTarget.Character.HumanoidRootPart
			nav:SetTarget(targetHRP.Position)

			-- ❌ If path failed immediately, fall back to direct chase
			if not nav._targetPos then
				dprint("No path found on pursue start - will use direct chase")
			end
		end
	end,
	function()
		-- Check if we still have a valid target
		if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
			dprint("Lost target, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local targetHRP = currentTarget.Character.HumanoidRootPart
		local distance = (hrp.Position - targetHRP.Position).Magnitude

		-- ========================================
		-- ✅ COMBAT ROLE DECISION (OPTION 4)
		-- ========================================

		local isRanged = enemyDef.IsRanged or false
		local combatRole = enemyDef.CombatRole or "melee"  -- "melee", "ranged", or "hybrid"
		local meleeRange = enemyDef.MeleeRange or 5
		local rangedMinRange = enemyDef.RangedMinRange or 10
		local rangedMaxRange = enemyDef.RangedMaxRange or 50

		if isRanged then
			if combatRole == "melee" then
				-- Rush to melee, never use ranged
				if distance <= meleeRange then
					dprint("Entering melee attack (melee role)")
					changeState("AttackMelee")
					return
				end
				-- else: keep pursuing to get into melee range

			elseif combatRole == "ranged" then
				-- Stay at range, only melee if forced
				if distance <= meleeRange then
					dprint("Forced into melee attack (ranged role)")
					changeState("AttackMelee")  -- Forced into melee
					return
				elseif distance >= rangedMinRange and distance <= rangedMaxRange then
					dprint("Entering ranged attack (ranged role)")
					changeState("AttackRanged")
					return
				end
				-- else: keep pursuing to get into ranged zone

			elseif combatRole == "hybrid" then
				-- Uses both tactically - prefers melee but will use ranged
				if distance <= meleeRange then
					dprint("Entering melee attack (hybrid role)")
					changeState("AttackMelee")
					return
				elseif distance >= rangedMinRange and distance <= rangedMaxRange then
					-- Only stop for ranged if we've been pursuing for a bit
					local pursuingTime = os.clock() - pursueStartTime
					if pursuingTime > 2.0 then  -- Tried to close for 2 seconds
						dprint("Entering ranged attack after 2s pursuit (hybrid role)")
						changeState("AttackRanged")
						return
					end
					-- else: keep trying to get to melee
				end
			end
		else
			-- Melee-only enemy (original behavior)
			if distance <= meleeRange then
				dprint("Entering melee attack (melee-only)")
				changeState("AttackMelee")
				return
			end
		end

		-- ========================================
		-- PATHFINDING vs DIRECT CHASE
		-- ========================================

		if nav._targetPos then
			-- ✅ We have a valid path - use pathfinding
			local arrived = nav:Step()

			-- Check if target moved significantly
			local moved = (targetHRP.Position - nav._targetPos).Magnitude
			if moved > 10 then  -- Target moved 10+ studs
				nav:SetTarget(targetHRP.Position)

				-- If repath failed, track it
				if not nav._targetPos then
					repathAttempts = repathAttempts + 1
					lastRepathAttempt = os.clock()
					dprint(string.format("Repath failed (attempt %d/%d)", repathAttempts, MAX_REPATH_ATTEMPTS))
				end
			end

		else
			-- ❌ No path available - FALLBACK BEHAVIORS

			-- Option 1: Try to repath periodically (don't spam)
			if os.clock() - lastRepathAttempt > 2.0 and repathAttempts < MAX_REPATH_ATTEMPTS then
				dprint("Attempting repath...")
				nav:SetTarget(targetHRP.Position)
				repathAttempts = repathAttempts + 1
				lastRepathAttempt = os.clock()

				if nav._targetPos then
					dprint("Repath successful!")
					repathAttempts = 0  -- Reset on success
				end
			end

			-- Use this if pathfinding keeps failing OR for close targets
			if distance < 30 or repathAttempts >= MAX_REPATH_ATTEMPTS then
				dprint("Using direct chase (distance: " .. math.floor(distance) .. " studs)")
				humanoid:MoveTo(targetHRP.Position)
			end

			-- too far
			if distance > 100 and repathAttempts >= MAX_REPATH_ATTEMPTS then
				dprint("Target too far and unreachable - giving up")
				currentTarget = nil
				changeState("Idle")
				return
			end
		end
	end,
	function()
		nav:Clear()
		-- Reset tracking
		lastRepathAttempt = 0
		repathAttempts = 0
	end
)

-- AttackMelee State
local lastMeleeAttackTime = 0

states.AttackMelee = State.new(
	"AttackMelee",
	function()
		dprint("Melee attacking target:", currentTarget and currentTarget.Name or "nil")

		-- Cancel all movement
		cancelHumanoidMove()
		allowRunningControl = false
		humanoid.WalkSpeed = 0

		-- Reset attack timer so we attack immediately
		lastMeleeAttackTime = 0
	end,
	function()
		-- Check if we still have a valid target
		if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
			dprint("Lost target during melee attack, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local targetHRP = currentTarget.Character.HumanoidRootPart
		local distance = (hrp.Position - targetHRP.Position).Magnitude

		-- Check if target moved out of melee range
		local meleeRange = enemyDef.MeleeRange or 5
		if distance > meleeRange then
			dprint("Target left melee range, pursuing")
			changeState("Pursue")
			return
		end

		-- Face the target
		local lookAt = targetHRP.Position
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z))

		-- Get attack speed (attacks per second)
		local attackSpeed = enemyDef.MeleeAttackSpeed or enemyDef.AttackSpeed or 2.0
		local attackCooldown = 1.0 / attackSpeed

		-- Attack on cooldown
		local now = os.clock()
		if now - lastMeleeAttackTime >= attackCooldown then
			lastMeleeAttackTime = now

			-- Play melee attack animation
			if Tracks.Attack then
				Tracks.Attack.Looped = false
				playAction(Tracks.Attack, 0.05, 0, true)
			end

			dprint("Melee strike!")

			EnemyCombatFunctions.HandleMelee(npc, currentTarget.Character.HumanoidRootPart.Position, currentTarget)
		else
			-- While waiting for attack cooldown, play idle
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

-- AttackRanged State
local lastRangedAttackTime = 0

states.AttackRanged = State.new(
	"AttackRanged",
	function()
		dprint("Ranged attacking target:", currentTarget and currentTarget.Name or "nil")

		-- Cancel movement
		cancelHumanoidMove()
		allowRunningControl = false
		humanoid.WalkSpeed = 0

		-- Reset attack timer
		lastRangedAttackTime = 0
	end,
	function()
		-- Check if we still have a valid target
		if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") then
			dprint("Lost target during ranged attack, returning to idle")
			currentTarget = nil
			changeState("Idle")
			return
		end

		local targetHRP = currentTarget.Character.HumanoidRootPart
		local distance = (hrp.Position - targetHRP.Position).Magnitude

		local meleeRange = enemyDef.MeleeRange or 5
		local rangedMinRange = enemyDef.RangedMinRange or 10
		local rangedMaxRange = enemyDef.RangedMaxRange or 50

		-- Target too close - switch to melee or back up
		if distance < meleeRange then
			local combatRole = enemyDef.CombatRole or "melee"
			if combatRole == "ranged" then
				-- Ranged role - back up to maintain distance
				dprint("Target too close, backing up")
				local awayDir = (hrp.Position - targetHRP.Position).Unit
				local backupPos = hrp.Position + (awayDir * 5)
				humanoid.WalkSpeed = CONFIG.RUN_SPEED
				humanoid:MoveTo(backupPos)
				return
			else
				-- Switch to melee
				dprint("Target in melee range, switching to melee")
				changeState("AttackMelee")
				return
			end
		end

		-- Target too far - pursue
		if distance > rangedMaxRange then
			dprint("Target out of ranged range, pursuing")
			changeState("Pursue")
			return
		end

		-- Not in optimal range yet - keep waiting/repositioning
		--if distance < rangedMinRange then
		--	dprint("Too close for ranged, repositioning")
		--	local awayDir = (hrp.Position - targetHRP.Position).Unit
		--	local backupPos = hrp.Position + (awayDir * 3)
		--	humanoid.WalkSpeed = CONFIG.WALK_SPEED
		--	humanoid:MoveTo(backupPos)
		--	return
		--end

		-- ✅ In optimal ranged zone - attack!
		-- Stop any movement
		cancelHumanoidMove()
		humanoid.WalkSpeed = 0

		-- Face the target
		local lookAt = targetHRP.Position
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(lookAt.X, hrp.Position.Y, lookAt.Z))

		-- Get attack speed
		local attackSpeed = enemyDef.RangedAttackSpeed or enemyDef.AttackSpeed or 1.0
		local attackCooldown = 1.0 / attackSpeed

		-- Attack on cooldown
		local now = os.clock()
		if now - lastRangedAttackTime >= attackCooldown then
			lastRangedAttackTime = now

			-- Play ranged attack animation
			if Tracks.Attack then
				Tracks.Attack.Looped = false
				playAction(Tracks.Attack, 0.05, 0, true)
			end

			dprint(string.format("Ranged shot! (distance: %.1f)", distance))
			local enemyOffsetFiringPosition = Vector3.new(npc.PrimaryPart.Position.X,npc.PrimaryPart.Position.Y+2,npc.PrimaryPart.Position.Z)
			EnemyCombatFunctions.HandleRanged(npc, currentTarget.Character.HumanoidRootPart.Position + Vector3.new(0,2,0),1000,enemyDef.RangedAmmo,enemyOffsetFiringPosition)

		else
			-- While waiting for attack cooldown, play idle
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

-- Alarmed (optional)
if CONFIG.ENABLE_ALARMED then
	local alarmedStateCount = 0
	local lastAlarmedMove = 0

	states.Alarmed = State.new(
		"Alarmed",
		function()
			alarmedStateCount = alarmedStateCount + 1
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
				alarmedStateCount = alarmedStateCount + 1
				dprint("Alarmed! Count:", alarmedStateCount)

				local fleePos = Nav.RandomPointInRadius(hrp.Position, CONFIG.ALARM_STATE_DISTANCE, rng)
				local grounded = nav:GetGroundedPosition(fleePos)
				if grounded then
					nav:SetTarget(grounded)
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

--Held State (player has held it like for chicken npcs)
states.Held = State.new(
	"Held",
	function()
		dprint("Entering Held state")
		nav:Clear()

		cancelHumanoidMove()
		humanoid.WalkSpeed = 0
		humanoid.Jump = false

		-- ✅ Disable NavHitbox collision while held (prevents player getting stuck)
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

		-- ✅ Re-enable NavHitbox collision
		local navHitbox = npc:FindFirstChild("NavHitbox")
		if navHitbox then
			navHitbox.CanCollide = true
		end

		humanoid.WalkSpeed = CONFIG.WALK_SPEED
		allowRunningControl = true
	end
)


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
		-- move to last frame and freeze
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

	-- Prevent double-running
	if deathLocked then
		return false
	end
	deathLocked = true

	-- HARD GATE anything else that might restart animations
	allowRunningControl = false
	nav:Clear()

	-- Kill motion
	pcall(function() humanoid:Move(Vector3.zero) end)
	pcall(function() humanoid.WalkSpeed = 0 end)
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	-- Stop EVERY playing track (not just your tracked ones)
	stopAllTracks(0.05)

	-- Play die
	local die = Tracks.Die
	if die then
		die.Looped = false
		die.Priority = Enum.AnimationPriority.Action4 -- highest practical

		local reachedEndedMarker = false
		local markerConn

		-- Listen for an Animation Editor marker named "Ended"
		markerConn = die:GetMarkerReachedSignal("Ended"):Connect(function()
			reachedEndedMarker = true
			if markerConn then markerConn:Disconnect() end

			-- Freeze *right now* where the marker is placed
			pcall(function()
				die:AdjustSpeed(0)
				die:AdjustWeight(1, 0)
			end)
		end)

		-- play from start
		pcall(function()
			dprint("PLAY DIE ANIMATION")
			die.TimePosition = 0
			die:Play(0.05, 1, 1)
		end)

		-- Wait until marker reached (failsafe: if marker never fires, freeze at end anyway)
		local timeout = os.clock() + ((die.Length and die.Length > 0) and (die.Length + 0.75) or 6)
		while not reachedEndedMarker and os.clock() < timeout do
			task.wait(0.05)
		end

		-- If the marker didn't exist / didn't fire, fall back to freezing at end
		if not reachedEndedMarker then
			if markerConn then markerConn:Disconnect() end
			freezeTrackAtEnd(die)
		end
	end

	return false
end

local function CheckHeld()
	if npc:GetAttribute("HeldBy") and currentState.Name ~= "Held" then
		changeState("Held")
	end

end


------------------------------------------------------------------
-- Boot
------------------------------------------------------------------
changeState("Idle")

------------------------------------------------------------------
-- NPC-only AI tick (throttled)
------------------------------------------------------------------
local lastOwnerCheck = 0
task.spawn(function()
	while checkAlive() and npc.Parent do
		local now = os.clock()

		-- keep server ownership occasionally
		if now - lastOwnerCheck > 2 then
			lastOwnerCheck = now
			pcall(function()
				if hrp:GetNetworkOwner() ~= nil then
					hrp:SetNetworkOwner(nil)
				end
			end)
		end

		-- Decay threat over time
		decayThreat()

		checkForPlayers() --ALARM STATE CHANGE

		checkHit() --BEING ATTACKED
		
		CheckHeld() --BEING HELD BY PLAYER
		

		if currentState and currentState.OnUpdate then
			currentState.OnUpdate()
		end

		task.wait(CONFIG.AI_TICK)
	end

	dprint("DEAD")
	Debris:AddItem(npc, 10)
end)