local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.SharedModules.OxygenSystem.Config)
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

local PlayerHitEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")
local Attributes = Config.Attributes

local atmosphereZones = {}
local loadedAtmosphereZoneCount = 0
local suffocationElapsed = {}

for _, zoneKey in ipairs(Config.AtmosphereZoneKeys) do
	Zones:OnLoaded(zoneKey, function(zone)
		if atmosphereZones[zoneKey] then
			return
		end

		atmosphereZones[zoneKey] = zone
		loadedAtmosphereZoneCount += 1
	end)
end

local function initializePlayer(player)
	player:SetAttribute(Attributes.Maximum, Config.MaxOxygen)

	if player:GetAttribute(Attributes.Current) == nil then
		player:SetAttribute(Attributes.Current, Config.MaxOxygen)
	end

	player:SetAttribute(Attributes.InVacuum, false)
end

local function hasAtmosphereOverride(player, character)
	return player:GetAttribute(Attributes.AtmosphereOverride) == true
		or character:GetAttribute(Attributes.AtmosphereOverride) == true
end

local function isInAtmosphere(player, character, rootPart)
	if hasAtmosphereOverride(player, character) then
		return true
	end

	-- The current flight system treats the pilot position as being inside the
	-- ship. Oxygen begins draining after the player exits into EVA, not while
	-- they are seated in a functioning cockpit.
	if StatesFunctions.GetCurrentShip(player) then
		return true
	end

	-- Fail safe while zone streaming/registration is still starting. A missing
	-- zone must never suffocate every player in the server.
	if loadedAtmosphereZoneCount == 0 then
		return true
	end

	for _, zone in pairs(atmosphereZones) do
		if zone:IsInside(rootPart.Position) then
			return true
		end
	end

	return false
end

local function updatePlayer(player, dt)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	if character:GetAttribute("Dead") == true then
		return
	end

	local maximum = player:GetAttribute(Attributes.Maximum) or Config.MaxOxygen
	local current = math.clamp(player:GetAttribute(Attributes.Current) or maximum, 0, maximum)
	local inVacuum = not isInAtmosphere(player, character, rootPart)

	if player:GetAttribute(Attributes.InVacuum) ~= inVacuum then
		player:SetAttribute(Attributes.InVacuum, inVacuum)
	end

	if inVacuum then
		local nextOxygen = math.max(0, current - Config.DrainPerSecond * dt)
		if nextOxygen ~= current then
			player:SetAttribute(Attributes.Current, nextOxygen)
		end

		if nextOxygen <= 0 then
			local damageElapsed = (suffocationElapsed[player] or 0) + dt
			if damageElapsed >= Config.SuffocationDamageInterval then
				PlayerHitEvent:Fire(
					player,
					Config.SuffocationDamagePerSecond * damageElapsed,
					nil,
					"Suffocation"
				)
				damageElapsed = 0
			end
			suffocationElapsed[player] = damageElapsed
		else
			suffocationElapsed[player] = 0
		end
	else
		suffocationElapsed[player] = 0
		local nextOxygen = math.min(maximum, current + Config.RecoveryPerSecond * dt)
		if nextOxygen ~= current then
			player:SetAttribute(Attributes.Current, nextOxygen)
		end
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	initializePlayer(player)
end
Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(function(player)
	suffocationElapsed[player] = nil
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
