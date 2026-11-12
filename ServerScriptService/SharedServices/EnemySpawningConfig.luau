--[[
	EnemySpawningConfig.lua
	
	Data-driven configuration for enemy spawning zones.
	Each spawner defines what enemies spawn, how many, and AI behavior.
]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local function chickenFlapFly(root)
	if not root or not root:IsA("BasePart") then return end

	local attachment = root:FindFirstChild("ChickenFlightAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "ChickenFlightAttachment"
		attachment.Parent = root
	end

	local flapForce = Instance.new("VectorForce")
	flapForce.Attachment0 = attachment
	flapForce.RelativeTo = Enum.ActuatorRelativeTo.World
	flapForce.ApplyAtCenterOfMass = true
	flapForce.Name = "ChickenFlapForce"
	flapForce.Force = Vector3.zero
	flapForce.Parent = root

	local startTime = tick()
	local totalDuration = 4
	local flapDuration = 0.4
	local glideDuration = 3

	local mass = root.AssemblyMass
	local gravity = workspace.Gravity
	local antiGravity = Vector3.new(0, mass * gravity, 0)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local now = tick()
		local elapsed = now - startTime

		if elapsed > totalDuration then
			connection:Disconnect()
			flapForce:Destroy()
			return
		end

		if elapsed < flapDuration then
			local flap = Vector3.new(
				math.random(-150, 150),
				math.random(500, 600),
				math.random(-150, 150)
			)
			flapForce.Force = flap
		elseif elapsed < flapDuration + glideDuration then
			flapForce.Force = antiGravity * 0.8
		else
			local flutter = Vector3.new(
				math.random(-130, 130),
				math.random(50, 100),
				math.random(-130, 130)
			)
			flapForce.Force = flutter
		end
	end)

	Debris:AddItem(flapForce, totalDuration + 0.5)
end

local function getOrLoadTrack(npc, animName)
	local storageKey = "_ChickenTrack_" .. animName
	local existingTrack = npc:GetAttribute(storageKey)

	-- Check if we have a stored track reference
	if existingTrack then
		local success, track = pcall(function()
			return npc:FindFirstChild(storageKey, true)
		end)
		if success and track and track:IsA("AnimationTrack") then
			return track
		end
	end

	-- Load new track and store reference
	local animObj = npc.Animations:FindFirstChild(animName)
	if not animObj then return nil end

	local animator = npc.Humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end

	local track = animator:LoadAnimation(animObj)

	-- Store reference in ObjectValue for persistence
	local objValue = Instance.new("ObjectValue")
	objValue.Name = storageKey
	objValue.Value = track
	objValue.Parent = npc

	return track
end

-- Now update ChickenAnimations to use this:
local ChickenAnimations = {}

ChickenAnimations.OnIdleStart = function(npc, tracks, whichIdle)
	if tracks.WingsFlap and tracks.WingsIdle then
		if whichIdle == 4 then
			-- Idle4 uses flapping wings
			tracks.WingsIdle:Stop()
			tracks.WingsFlap:Play()
		else
			-- All other idles use idle wings
			tracks.WingsFlap:Stop()
			tracks.WingsIdle:Play()
		end
	end
end

ChickenAnimations.OnIdleUpdate = function(npc, tracks, currentTime, whichIdle)
	-- Just handle wing animation based on which idle is playing
	if tracks.WingsFlap and tracks.WingsIdle then
		if whichIdle == 4 then
			tracks.WingsIdle:Stop()
			tracks.WingsFlap:Play()
		else
			tracks.WingsFlap:Stop()
			tracks.WingsIdle:Play()
		end
	end
end

ChickenAnimations.OnWalkStart = function(npc, tracks)
	-- Walking uses idle wings (not flapping)
	if tracks.WingsFlap and tracks.WingsIdle then
		tracks.WingsFlap:Stop()
		tracks.WingsIdle:Play()
	end
end

ChickenAnimations.OnRunStart = function(npc, tracks)
	-- Running uses idle wings (not flapping)
	ChickenAnimations.OnWalkStart(npc, tracks)
end

ChickenAnimations.OnAlarmedStart = function(npc, tracks)
	-- Alarmed uses flapping wings
	if tracks.WingsFlap and tracks.WingsIdle then
		tracks.WingsIdle:Stop()
		tracks.WingsFlap:Play()
	end

	local alarmedCount = npc:GetAttribute("ChickenAlarmedCount") or 0
	npc:SetAttribute("ChickenAlarmedCount", alarmedCount + 1)

	if alarmedCount >= 3 then
		chickenFlapFly(npc.HumanoidRootPart)
		npc:SetAttribute("ChickenAlarmedCount", 0)
	end
end

ChickenAnimations.OnJumpStart = function(npc, tracks)
	-- Alarmed uses flapping wings
	if tracks.WingsFlap and tracks.WingsIdle then
		tracks.WingsIdle:Stop()
		tracks.WingsFlap:Play()
	end

end

local EnemySpawningConfig = {}

--[[
	Spawner Template:
	{
		SpawnerId = "unique_identifier",
		SpawnPoint = Vector3.new(...),  -- Where enemies spawn
		HomePoint = Vector3.new(...),   -- Where enemies return to
		
		-- Spawn Control
		MaxAlive = 10,                  -- Max concurrent enemies
		RespawnInterval = 20,           -- Seconds between spawn attempts
		CollectionTag = "TagName",      -- For tracking spawned enemies
		
		-- Enemy Pool
		EnemyPool = {
			{Type = "Chicken", Weight = 70},  -- 70% chance
			{Type = "Chick", Weight = 30}     -- 30% chance
		},
		
		-- AI Configuration
		AIType = "PassiveWandering",    -- Which AI module to use
		AIConfig = {                    -- AI-specific settings
			PlayerNearbyDistance = 5,
			AlarmStateDistance = Vector2.new(5, 10),
			AlarmStateFrequency = 1,
			PatrolWaypoints = {},       -- Optional patrol points
			PatrolCycleNode = 1,
		},
		
		-- Enemy Overrides (applied to all spawned enemies)
		EnemyOverrides = {
			flip = true,
			-- Any other enemy properties to override
		},
		
		-- Custom State Conditions (optional)
		CustomConditions = {
			Idle = {"BeingAttacked", "GotBored", "PlayerNearby"},
			Pursue = {"WithinRange", "TargetDead"},
			Attack = {"OutsideRange", "TargetDead"},
			-- etc.
		}
	}
]]

-- Example Spawner Configurations
EnemySpawningConfig.Spawners = {

	-- Chicken Farm Spawner
	ChickenSpawn1 = {
		SpawnerId = "ChickenSpawn1",
		SpawnPoint = Vector3.new(358.047, 3.255, 1625.347),
		HomePoint = Vector3.new(358.047, 3.255, 1625.347),

		MaxAlive = 1,
		RespawnInterval = 30,
		InitialSpawnCount = 1, --5
		CollectionTag = "ChickenSpawn1",

		EnemyPool = {
			{Type = "Chicken", Weight = 100}
		},

		AIType = "PassiveWandering",
		AIConfig = {
			PlayerNearbyDistance = 5,
			AlarmStateDistance = Vector2.new(5, 10),
			AlarmStateFrequency = 1,
			DEBUG = true,                -- Both state AND path debugging
			WANDER_RADIUS = 30,
			ENABLE_ALARMED = true,
			ALARM_TRIGGER_DISTANCE = 25,
			ALARM_STATE_FREQUENCY = 1.5,
			ALARM_STATE_DISTANCE = 30,
			ALARM_STATE_COUNT_MAX = 4,
			OnIdleUpdate = ChickenAnimations.OnIdleUpdate,
			OnWalkStart = ChickenAnimations.OnWalkStart,
			OnRunStart = ChickenAnimations.OnRunStart,
			OnAlarmedStart = ChickenAnimations.OnAlarmedStart,
			OnJumpStart = ChickenAnimations.OnJumpStart,
		},

		EnemyOverrides = {
			flip = true,
		}
	},
	MonkeySpawn1 = {
		SpawnerId = "MonkeySpawn1",
		SpawnPoint = Vector3.new(358.047, 3.255, 1615.347),
		HomePoint = Vector3.new(358.047, 3.255, 1615.347),

		MaxAlive = 1, --5
		RespawnInterval = 30,
		InitialSpawnCount = 1, --5
		CollectionTag = "MonkeySpawn1",

		EnemyPool = {
			{Type = "SpaceMonkey", Weight = 100}
		},

		AIType = "PassiveWandering",
		AIConfig = {
			PlayerNearbyDistance = 5,
			AlarmStateDistance = Vector2.new(5, 10),
			AlarmStateFrequency = 1,
			DEBUG = true,                -- Both state AND path debugging
			WANDER_RADIUS = 100,
			ENABLE_ALARMED = false,
		},

		EnemyOverrides = {
			flip = true,
		}
	},
	ZAP09FSpawn1 = {
		SpawnerId = "ZAP09FSpawn1",
		SpawnPoint = Vector3.new(-12.5, 6.609, 1463.5),
		HomePoint = Vector3.new(-12.5, 6.609, 1463.5),

		MaxAlive = 3, --5
		RespawnInterval = 30,
		InitialSpawnCount = 3, --5
		CollectionTag = "ZAP09FSpawn1",

		EnemyPool = {
			{Type = "ZAP-09-F", Weight = 100}
		},

		AIType = "PassiveWandering",
		AIConfig = {
			PlayerNearbyDistance = 5,
			AlarmStateDistance = Vector2.new(5, 10),
			AlarmStateFrequency = 1,
			DEBUG = true,                -- Both state AND path debugging
			WANDER_RADIUS = 100,
			ENABLE_ALARMED = false,
			AGENT_CAN_JUMP = false,
			AGENT_JUMP_HEIGHT = 0,
			ENABLE_JUMP_OVER = false,
			AGENT_MAX_SLOPE = 0,
			RANGED_LOST_SHOOTABLE_GRACE = 1.25,
			AGENT_RADIUS = 4,
			AGENT_HEIGHT = 7.5,
			DEBUG_RANGED_FIRE_ORIGIN = false,
		},

		EnemyOverrides = {
			flip = true,
		}
	},
	--MOPE7Spawn1 = {
	--	SpawnerId = "MOPE7Spawn1",
	--	SpawnPoint = Vector3.new(58.742, 6, 1672.24),
	--	HomePoint = Vector3.new(58.742, 6, 1672.24),

	--	MaxAlive = 1, --5
	--	RespawnInterval = 30,
	--	InitialSpawnCount = 1, --5
	--	CollectionTag = "MOPE7Spawn1",

	--	EnemyPool = {
	--		{Type = "MOP-E7", Weight = 100}
	--	},

	--	AIType = "CleaningRobot",
	--	AIConfig = {
	--		PlayerNearbyDistance = 5,
	--		AlarmStateDistance = Vector2.new(5, 10),
	--		AlarmStateFrequency = 1,
	--		DEBUG = false,                -- Both state AND path debugging
	--		WANDER_RADIUS = 1000,
	--		ENABLE_ALARMED = false,
	--		ENABLE_JUMP_OVER = false,
	--		AGENT_CAN_JUMP = true, 
	--		AGENT_JUMP_HEIGHT = 5,
	--		ARRIVAL_DISTANCE = 5,
	--	},

	--	EnemyOverrides = {
	--		flip = true,
	--	}
	--},
	--ScavSpawn1 = {
	--	SpawnerId = "ScavSpawn1",
	--	SpawnPoint = Vector3.new(-1587.789, 219.524, -103.527),
	--	HomePoint = Vector3.new(-1587.789, 219.524, -103.527),

	--	MaxAlive = 1, --5
	--	RespawnInterval = 30,
	--	InitialSpawnCount = 1, --5
	--	CollectionTag = "ScavSpawn1",
	--	AdditionalTags = {"SensorTarget"},

	--	EnemyPool = {
	--		{Type = "ScavReconShip", Weight = 100}
	--	},

	--	AIType = "Scav",
	--	AIConfig = {
	--		DEBUG = true,                -- Both state AND path debugging
	--		PATROL_RADIUS = 1000,
	--	},

	--	EnemyOverrides = {
	--		flip = true,
	--	}
	--},

	---- Guard Post Spawner (example for future use)
	--GuardPost1 = {
	--	SpawnerId = "GuardPost1",
	--	SpawnPoint = Vector3.new(100, 5, 200),
	--	HomePoint = Vector3.new(100, 5, 200),

	--	MaxAlive = 4,
	--	RespawnInterval = 60,
	--	CollectionTag = "GuardSpawn1",

	--	EnemyPool = {
	--		{Type = "SecurityGuard", Weight = 80},
	--		{Type = "EliteGuard", Weight = 20}
	--	},

	--	AIType = "PassiveGuard",
	--	AIConfig = {
	--		GuardRadius = 20,
	--		AlertRadius = 30,
	--		ReturnToPostTimeout = 10,
	--	},

	--	EnemyOverrides = {
	--		aggression = 0.8,
	--	}
	--},

	---- Patrol Route Spawner (example)
	--PatrolRoute1 = {
	--	SpawnerId = "PatrolRoute1",
	--	SpawnPoint = Vector3.new(-1265, 2.692, -4009),
	--	HomePoint = Vector3.new(-1265, 2.692, -4009),

	--	MaxAlive = 3,
	--	RespawnInterval = 120,
	--	CollectionTag = "PatrolSpawn1",

	--	EnemyPool = {
	--		{Type = "Drone", Weight = 100}
	--	},

	--	AIType = "Patrol",
	--	AIConfig = {
	--		PatrolWaypoints = {
	--			Vector3.new(-1265.315, 2.692, -4009.447),
	--			Vector3.new(-1241.968, 2.692, -4005.442),
	--			Vector3.new(-1225.751, 2.692, -3987.658),
	--			Vector3.new(-1222.636, 2.692, -3953.673),
	--			Vector3.new(-1254.389, 2.692, -3930.802),
	--		},
	--		PatrolCycleNode = 1,
	--		PauseAtWaypoint = 3, -- seconds
	--	},

	--	CustomConditions = {
	--		Patrol = {"BeingAttacked", "PlayerNearby"},
	--		Idle = {"BeingAttacked"},
	--	}
	--},

	---- Hunting Pack Spawner (example)
	--HuntingPack1 = {
	--	SpawnerId = "HuntingPack1",
	--	SpawnPoint = Vector3.new(300, 10, 300),
	--	HomePoint = Vector3.new(300, 10, 300),

	--	MaxAlive = 6,
	--	RespawnInterval = 45,
	--	CollectionTag = "HunterSpawn1",

	--	EnemyPool = {
	--		{Type = "Wolf", Weight = 70},
	--		{Type = "AlphaWolf", Weight = 30}
	--	},

	--	AIType = "Hunting",
	--	AIConfig = {
	--		PackBehavior = true,
	--		HuntingRadius = 100,
	--		DetectionRange = 50,
	--	}
	--}
}

-- Helper function to get weighted random enemy type
function EnemySpawningConfig.GetRandomEnemyType(enemyPool)
	local totalWeight = 0
	for _, entry in ipairs(enemyPool) do
		totalWeight = totalWeight + entry.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, entry in ipairs(enemyPool) do
		cumulative = cumulative + entry.Weight
		if roll <= cumulative then
			return entry.Type
		end
	end

	-- Fallback to first entry
	return enemyPool[1].Type
end

-- Validate spawner configuration
function EnemySpawningConfig.ValidateConfig(config)
	assert(config.SpawnerId, "Spawner missing SpawnerId")
	assert(config.SpawnPoint, "Spawner missing SpawnPoint")
	assert(config.HomePoint, "Spawner missing HomePoint")
	assert(config.MaxAlive, "Spawner missing MaxAlive")
	assert(config.RespawnInterval, "Spawner missing RespawnInterval")
	assert(config.CollectionTag, "Spawner missing CollectionTag")
	assert(config.EnemyPool and #config.EnemyPool > 0, "Spawner missing or empty EnemyPool")
	assert(config.AIType, "Spawner missing AIType")
	return true
end

return EnemySpawningConfig