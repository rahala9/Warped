local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("PlayerMeterSystem"):WaitForChild("Config"))
local PlayerHitEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")

local PlayerMeterService = {}

local initialized = false
local rateSources = {}

local function getDefinition(meterName: string)
	local definition = Config.Meters[meterName]
	assert(definition, string.format("Unknown player meter %q", tostring(meterName)))
	return definition
end

local function initializeMeter(player: Player, definition)
	player:SetAttribute(definition.MaximumAttribute, definition.Maximum)
	if player:GetAttribute(definition.CurrentAttribute) == nil then
		player:SetAttribute(definition.CurrentAttribute, definition.Default)
	end
end

local function initializePlayer(player: Player)
	for _, definition in pairs(Config.Meters) do
		initializeMeter(player, definition)
	end
end

local function resetSpawnMeters(player: Player)
	for _, definition in pairs(Config.Meters) do
		if definition.ResetOnSpawn then
			player:SetAttribute(definition.CurrentAttribute, definition.Default)
		end
	end
end

local function initializeAndBindPlayer(player: Player)
	initializePlayer(player)
	player.CharacterAdded:Connect(function()
		resetSpawnMeters(player)
	end)
end

local function getPlayerSources(player: Player)
	local sources = rateSources[player]
	if not sources then
		sources = {}
		rateSources[player] = sources
	end
	return sources
end

function PlayerMeterService.Get(player: Player, meterName: string): (number, number)
	local definition = getDefinition(meterName)
	local maximum = tonumber(player:GetAttribute(definition.MaximumAttribute)) or definition.Maximum
	local current = tonumber(player:GetAttribute(definition.CurrentAttribute)) or definition.Default
	return math.clamp(current, 0, maximum), maximum
end

function PlayerMeterService.Set(player: Player, meterName: string, value: number): number
	local definition = getDefinition(meterName)
	local maximum = tonumber(player:GetAttribute(definition.MaximumAttribute)) or definition.Maximum
	local nextValue = math.clamp(value, 0, maximum)
	player:SetAttribute(definition.CurrentAttribute, nextValue)
	return nextValue
end

function PlayerMeterService.Add(player: Player, meterName: string, amount: number): number
	local current = PlayerMeterService.Get(player, meterName)
	return PlayerMeterService.Set(player, meterName, current + amount)
end

function PlayerMeterService.SetRateSource(player: Player, meterName: string, sourceKey: string, ratePerSecond: number)
	getDefinition(meterName)
	assert(typeof(sourceKey) == "string" and sourceKey ~= "", "Meter rate sourceKey must be a non-empty string")
	assert(typeof(ratePerSecond) == "number", "Meter rate must be a number")

	local sources = getPlayerSources(player)
	local meterSources = sources[meterName]
	if not meterSources then
		meterSources = {}
		sources[meterName] = meterSources
	end
	meterSources[sourceKey] = ratePerSecond
end

function PlayerMeterService.RemoveRateSource(player: Player, meterName: string, sourceKey: string)
	local sources = rateSources[player]
	local meterSources = sources and sources[meterName]
	if meterSources then
		meterSources[sourceKey] = nil
		if next(meterSources) == nil then
			sources[meterName] = nil
		end
	end
end

local function updatePlayer(player: Player, dt: number)
	local playerSources = rateSources[player]
	for meterName, definition in pairs(Config.Meters) do
		local positiveSourceRate = 0
		local otherSourceRate = 0
		local meterSources = playerSources and playerSources[meterName]
		if meterSources then
			for _, rate in pairs(meterSources) do
				if rate > 0 then
					positiveSourceRate += rate
				else
					otherSourceRate += rate
				end
			end
		end

		local protection = 0
		if definition.ProtectionAttribute then
			protection = math.clamp(tonumber(player:GetAttribute(definition.ProtectionAttribute)) or 0, 0, 1)
		end

		local totalRate = (definition.BaseRatePerSecond or 0)
			+ otherSourceRate
			+ positiveSourceRate * (1 - protection)
		local current, maximum = PlayerMeterService.Get(player, meterName)
		if totalRate ~= 0 then
			local nextValue = math.clamp(current + totalRate * dt, 0, maximum)
			if math.abs(nextValue - current) > 0.0001 then
				player:SetAttribute(definition.CurrentAttribute, nextValue)
			end
			current = nextValue
		end

		local healthDamage = definition.HealthDamage
		if healthDamage and current >= healthDamage.Threshold then
			local damageRange = maximum - healthDamage.Threshold
			local severity = if damageRange > 0
				then math.clamp((current - healthDamage.Threshold) / damageRange, 0, 1)
				else 1
			local damagePerSecond = healthDamage.MinimumPerSecond
				+ (healthDamage.MaximumPerSecond - healthDamage.MinimumPerSecond) * severity
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid
				and humanoid.Health > 0
				and character:GetAttribute("Dead") ~= true
			then
				PlayerHitEvent:Fire(player, damagePerSecond * dt, nil, "Biohazard")
			end
		end
	end
end

function PlayerMeterService.Init()
	if initialized then
		return
	end
	initialized = true

	for _, player in ipairs(Players:GetPlayers()) do
		initializeAndBindPlayer(player)
	end
	Players.PlayerAdded:Connect(initializeAndBindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		rateSources[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < Config.UpdateInterval then
			return
		end

		local step = elapsed
		elapsed = 0
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayer(player, step)
		end
	end)
end

return PlayerMeterService
