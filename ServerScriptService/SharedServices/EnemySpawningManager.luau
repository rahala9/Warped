--[[
	EnemySpawningManager.lua
	
	SINGLE unified spawner manager that:
	- Reads spawner configurations from EnemySpawningConfig
	- Manages all spawners with ONE heartbeat
	- No need for separate "System" class
	
	Much simpler: Config → Manager → Done
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local EnemySpawningManager = {}
EnemySpawningManager.__index = EnemySpawningManager

-- Singleton instance
local _instance = nil

-- Module dependencies
local enemyModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemy"))
local spawningConfig = require(script.Parent:WaitForChild("EnemySpawningConfig"))

-- AI Module Registry
local AIModules = {
	PassiveWandering = script.Parent.AI.PassiveWanderingAI, --require(script.Parent.AI.PassiveWanderingAI),
	CleaningRobot = script.Parent.AI.CleaningRobotAI,
	Scav = script.Parent.AI.ScavAI,
	-- Add more AI types as you create them:
	-- PassiveWanderingNav = require(script.Parent.AI.PassiveWanderingAI_MonkeyNav),
	-- Patrol = require(script.Parent.AI.PatrolAI),
	-- PassiveGuard = require(script.Parent.AI.PassiveGuardAI),
	-- Hunting = require(script.Parent.AI.HuntingAI),
}

--[[
	Get or create the singleton manager instance
	@return Manager instance
]]
function EnemySpawningManager.GetInstance()
	if not _instance then
		_instance = EnemySpawningManager.new()
	end
	return _instance
end

--[[
	Create a new spawner manager (private - use GetInstance instead)
]]
function EnemySpawningManager.new()
	local self = setmetatable({}, EnemySpawningManager)

	-- Active spawners (indexed by SpawnerId)
	self.spawners = {}

	-- Manager state
	self.isRunning = false
	self.heartbeatConnection = nil

	-- Global limits
	self.globalMaxEnemies = math.huge  -- No limit by default
	self.globalEnemyCount = 0

	-- Statistics
	self.stats = {
		totalSpawned = 0,
		activeSpawners = 0,
	}

	return self
end

--[[
	Individual spawner data structure
]]
local function createSpawner(config)
	return {
		-- Config
		config = config,
		spawnerId = config.SpawnerId,

		-- State
		isRunning = true,
		spawnTimer = 0,
		numEnemies = 0,
		spawnedEnemies = {},

		-- Collection tracking connections
		enemyAddedConnection = nil,
		enemyRemovedConnection = nil,
	}
end

--[[
	Initialize a spawner from configuration
	@param config - Spawner configuration from EnemySpawningConfig
	@return Spawner data or nil if invalid
]]
function EnemySpawningManager:_initializeSpawner(config)
	-- Validate
	spawningConfig.ValidateConfig(config)

	-- Create spawner data
	local spawner = createSpawner(config)

	-- Set up CollectionService tracking
	local tag = config.CollectionTag

	spawner.enemyAddedConnection = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		spawner.numEnemies = spawner.numEnemies + 1
	end)

	spawner.enemyRemovedConnection = CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		spawner.numEnemies = spawner.numEnemies - 1

		-- Clean up from tracking table
		for i, enemy in ipairs(spawner.spawnedEnemies) do
			if enemy.char == instance or not instance.Parent then
				table.remove(spawner.spawnedEnemies, i)
				break
			end
		end
	end)

	return spawner
end

--[[
	Spawn a single enemy for a specific spawner
	@param spawner - Spawner data
	@return The spawned enemy instance or nil
]]
function EnemySpawningManager:_spawnEnemy(spawner)
	local config = spawner.config

	-- Check if at max capacity
	if spawner.numEnemies >= config.MaxAlive then
		return nil
	end

	-- Get enemy type from pool
	local enemyType = spawningConfig.GetRandomEnemyType(config.EnemyPool)

	-- Create enemy
	local enemy = enemyModule.newEnemy(
		enemyType,
		config.SpawnPoint,
		config.CollectionTag,
		config.AdditionalTags
	)
	
	-- Apply base configuration
	enemy.home = config.HomePoint
	enemy.spawn = config.SpawnPoint
	enemy.altLocation1 = config.HomePoint
	enemy.altLocation2 = config.HomePoint
	enemy.altLocation3 = config.HomePoint

	-- Apply enemy overrides
	if config.EnemyOverrides then
		for key, value in pairs(config.EnemyOverrides) do
			enemy[key] = value
		end
	end

	-- Initialize AI
	self:_initializeAI(enemy, config)

	-- Track this enemy
	table.insert(spawner.spawnedEnemies, enemy)

	return enemy
end

--[[
	Initialize and configure AI for an enemy
	@param enemy - The enemy instance
	@param config - Spawner configuration
]]
function EnemySpawningManager:_initializeAI(enemy, config)
	-- Get the appropriate AI module
	local AIModule = AIModules[config.AIType]

	if not AIModule then
		warn(string.format(
			"Unknown AI type '%s' for spawner '%s'",
			config.AIType,
			config.SpawnerId
			))
		return
	end

	local aiScript = AIModule:Clone()
	aiScript.Parent = enemy.char
	aiScript.Disabled = false
	-- Create AI instance
	--enemy.AI = AIModule.new(enemy)

	---- Apply AI configuration
	--if config.AIConfig then
	--	for key, value in pairs(config.AIConfig) do
	--		if enemy.AI[key] ~= nil then
	--			enemy.AI[key] = value
	--		end
	--	end
	--end

	---- Apply custom state conditions
	--if config.CustomConditions then
	--	enemy.AI:SetConditions(config.CustomConditions)
	--end

	---- Apply custom condition transitions
	--if config.CustomTransitions then
	--	for _, transition in ipairs(config.CustomTransitions) do
	--		enemy.AI:SetConditionTransition(
	--			transition.StateName,
	--			transition.ConditionName,
	--			transition.TransitionState
	--		)
	--	end
	--end

	---- Start the AI
	--enemy.AI:Start()
end

--[[
	Register a spawner from config
	@param configKey - Key in EnemySpawningConfig.Spawners table
	@return Spawner data
]]
function EnemySpawningManager:RegisterSpawner(configKey)
	local config = spawningConfig.Spawners[configKey]

	if not config then
		warn("EnemySpawningManager: Unknown spawner config:", configKey)
		return nil
	end

	-- Check for duplicate
	if self.spawners[config.SpawnerId] then
		warn("EnemySpawningManager: Spawner already registered:", config.SpawnerId)
		return self.spawners[config.SpawnerId]
	end

	-- Initialize spawner
	local spawner = self:_initializeSpawner(config)
	self.spawners[config.SpawnerId] = spawner
	self.stats.activeSpawners = self.stats.activeSpawners + 1

	-- Spawn initial enemy if configured
	for i = 1, config.InitialSpawnCount or 0 do
		self:_spawnEnemy(spawner)
	end

	-- Start manager if not running
	if not self.isRunning then
		self:Start()
	end

	return spawner
end

--[[
	Register multiple spawners at once
	@param configKeys - Array of config keys
]]
function EnemySpawningManager:RegisterSpawners(configKeys)
	for _, key in ipairs(configKeys) do
		self:RegisterSpawner(key)
	end
end

--[[
	Register ALL spawners from config
]]
function EnemySpawningManager:RegisterAllSpawners()
	for key, _ in pairs(spawningConfig.Spawners) do
		self:RegisterSpawner(key)
	end
end

--[[
	Unregister a spawner
	@param spawnerId - Spawner ID to remove
	@param cleanup - Whether to cleanup enemies (default: false)
]]
function EnemySpawningManager:UnregisterSpawner(spawnerId, cleanup)
	local spawner = self.spawners[spawnerId]
	if not spawner then
		return
	end

	-- Disconnect collection tracking
	if spawner.enemyAddedConnection then
		spawner.enemyAddedConnection:Disconnect()
	end
	if spawner.enemyRemovedConnection then
		spawner.enemyRemovedConnection:Disconnect()
	end

	-- Cleanup enemies if requested
	if cleanup then
		self:_cleanupSpawnerEnemies(spawner)
	end

	-- Remove from registry
	self.spawners[spawnerId] = nil
	self.stats.activeSpawners = self.stats.activeSpawners - 1

	-- Stop manager if no spawners left
	if self.stats.activeSpawners == 0 then
		self:Stop()
	end
end

--[[
	Update all spawners (called by heartbeat)
	@param deltaTime - Time since last frame
]]
function EnemySpawningManager:_update(deltaTime)
	self.globalEnemyCount = 0

	for spawnerId, spawner in pairs(self.spawners) do
		-- Update global count
		self.globalEnemyCount = self.globalEnemyCount + spawner.numEnemies

		-- Skip if paused
		if not spawner.isRunning then
			continue
		end

		-- Update spawn timer
		spawner.spawnTimer = spawner.spawnTimer + deltaTime

		-- Check if it's time to spawn
		if spawner.spawnTimer >= spawner.config.RespawnInterval then
			spawner.spawnTimer = 0

			-- Check local limit
			if spawner.numEnemies >= spawner.config.MaxAlive then
				continue
			end

			-- Check global limit
			if self.globalEnemyCount >= self.globalMaxEnemies then
				continue
			end

			-- Spawn enemy
			local enemy = self:_spawnEnemy(spawner)
			if enemy then
				self.stats.totalSpawned = self.stats.totalSpawned + 1
			end
		end
	end
end

--[[
	Start the spawner manager
]]
function EnemySpawningManager:Start()
	if self.isRunning then
		return
	end

	self.isRunning = true

	-- Single heartbeat for ALL spawners
	self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)

	print("[EnemySpawningManager] Started with", self.stats.activeSpawners, "spawners")
end

--[[
	Stop the spawner manager
]]
function EnemySpawningManager:Stop()
	if not self.isRunning then
		return
	end

	self.isRunning = false

	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
	end

	print("[EnemySpawningManager] Stopped")
end

--[[
	Pause a specific spawner
	@param spawnerId - Spawner to pause
]]
function EnemySpawningManager:PauseSpawner(spawnerId)
	local spawner = self.spawners[spawnerId]
	if spawner then
		spawner.isRunning = false
	end
end

--[[
	Resume a specific spawner
	@param spawnerId - Spawner to resume
]]
function EnemySpawningManager:ResumeSpawner(spawnerId)
	local spawner = self.spawners[spawnerId]
	if spawner then
		spawner.isRunning = true
	end
end

--[[
	Pause all spawners
]]
function EnemySpawningManager:PauseAll()
	for _, spawner in pairs(self.spawners) do
		spawner.isRunning = false
	end
end

--[[
	Resume all spawners
]]
function EnemySpawningManager:ResumeAll()
	for _, spawner in pairs(self.spawners) do
		spawner.isRunning = true
	end
end

--[[
	Cleanup enemies for a specific spawner
	@param spawner - Spawner data
]]
function EnemySpawningManager:_cleanupSpawnerEnemies(spawner)
	for _, enemy in ipairs(spawner.spawnedEnemies) do
		if enemy.AI and enemy.AI.Stop then
			enemy.AI:Stop()
		end

		if enemy.char and enemy.char.Parent then
			enemy.char:Destroy()
		end
	end

	spawner.spawnedEnemies = {}
	spawner.numEnemies = 0
end

--[[
	Cleanup all enemies from a specific spawner
	@param spawnerId - Spawner ID
]]
function EnemySpawningManager:CleanupSpawner(spawnerId)
	local spawner = self.spawners[spawnerId]
	if spawner then
		self:_cleanupSpawnerEnemies(spawner)
	end
end

--[[
	Cleanup all enemies from all spawners
]]
function EnemySpawningManager:CleanupAll()
	for _, spawner in pairs(self.spawners) do
		self:_cleanupSpawnerEnemies(spawner)
	end
end

--[[
	Set global enemy limit
	@param limit - Maximum total enemies across all spawners
]]
function EnemySpawningManager:SetGlobalLimit(limit)
	self.globalMaxEnemies = limit or math.huge
end

--[[
	Get a spawner by ID
	@param spawnerId - Spawner identifier
	@return Spawner data or nil
]]
function EnemySpawningManager:GetSpawner(spawnerId)
	return self.spawners[spawnerId]
end

--[[
	Get spawner status
	@param spawnerId - Spawner identifier
	@return Status table
]]
function EnemySpawningManager:GetSpawnerStatus(spawnerId)
	local spawner = self.spawners[spawnerId]
	if not spawner then
		return nil
	end

	return {
		SpawnerId = spawner.spawnerId,
		IsRunning = spawner.isRunning,
		NumEnemies = spawner.numEnemies,
		MaxAlive = spawner.config.MaxAlive,
		SpawnTimer = spawner.spawnTimer,
		RespawnInterval = spawner.config.RespawnInterval,
		TimeUntilNextSpawn = math.max(0, spawner.config.RespawnInterval - spawner.spawnTimer)
	}
end

--[[
	Get manager statistics
	@return Stats table
]]
function EnemySpawningManager:GetStats()
	return {
		ActiveSpawners = self.stats.activeSpawners,
		TotalEnemies = self.globalEnemyCount,
		GlobalLimit = self.globalMaxEnemies,
		TotalSpawned = self.stats.totalSpawned,
		IsRunning = self.isRunning,
	}
end

--[[
	Print status of all spawners
]]
function EnemySpawningManager:PrintStatus()
	print("\n=== Enemy Spawner Manager Status ===")
	print("Active Spawners:", self.stats.activeSpawners)
	print("Total Enemies:", self.globalEnemyCount, "/", self.globalMaxEnemies)
	print("Running:", self.isRunning)
	print("\nSpawner Details:")

	for spawnerId, spawner in pairs(self.spawners) do
		local status = self:GetSpawnerStatus(spawnerId)
		print(string.format(
			"  %s: %d/%d enemies | Next spawn: %.1fs | Running: %s",
			spawnerId,
			status.NumEnemies,
			status.MaxAlive,
			status.TimeUntilNextSpawn,
			status.IsRunning and "Yes" or "No"
			))
	end
	print("=====================================\n")
end

--[[
	Destroy the manager and cleanup everything
]]
function EnemySpawningManager:Destroy()
	self:Stop()

	for spawnerId, _ in pairs(self.spawners) do
		self:UnregisterSpawner(spawnerId, true)
	end

	self.spawners = {}
	self.stats.activeSpawners = 0

	if _instance == self then
		_instance = nil
	end
end

return EnemySpawningManager