local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("StatusEffectZoneSystem"):WaitForChild("Config"))
local EffectsDef = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects"))
local Zones = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ZoneLoader"))

local StatusEffectZoneService = {}

local effectsFunctions
local initialized = false
local boundFolders = {}
local activeClaims = {} -- [Folder] = { [Player] = effectName }

local function sourceFor(folder: Instance): string
	return Config.SourcePrefix .. tostring(folder:GetAttribute("ZoneKey") or folder.Name)
end

local function effectNameFor(folder: Instance): string?
	local effectName = folder:GetAttribute("EffectName")
	if typeof(effectName) ~= "string" or effectName == "" then
		warn("[StatusEffectZoneSystem] EffectName must be a non-empty string on", folder:GetFullName())
		return nil
	end
	if not EffectsDef[effectName] then
		warn("[StatusEffectZoneSystem] Unknown EffectName", effectName, "on", folder:GetFullName())
		return nil
	end
	return effectName
end

local function sourceLevelFor(folder: Instance): number
	local sourceLevel = folder:GetAttribute("SourceLevel")
	if typeof(sourceLevel) == "number" then
		return sourceLevel
	end
	return Config.Defaults.SourceLevel
end

local function removeOnExitFor(folder: Instance): boolean
	local configured = folder:GetAttribute("RemoveOnExit")
	if typeof(configured) == "boolean" then
		return configured
	end
	return Config.Defaults.RemoveOnExit
end

local function exitZone(player: Player, folder: Instance)
	local claims = activeClaims[folder]
	local effectName = claims and claims[player]
	if not effectName then
		return
	end
	claims[player] = nil

	if removeOnExitFor(folder) and player.Parent then
		effectsFunctions.RemoveEffect(player, effectName, sourceFor(folder))
	end

	if Config.Debug then
		print("[StatusEffectZoneSystem] Player exited", player.Name, folder:GetFullName(), effectName)
	end
end

local function enterZone(player: Player, folder: Instance)
	if folder:GetAttribute("Enabled") == false then
		return
	end
	local effectName = effectNameFor(folder)
	if not effectName then
		return
	end

	local claims = activeClaims[folder]
	if claims[player] then
		return
	end
	claims[player] = effectName

	effectsFunctions.AddEffect(player, effectName, sourceLevelFor(folder), sourceFor(folder))
	if Config.Debug then
		print("[StatusEffectZoneSystem] Applied", effectName, "to", player.Name, "from", folder:GetFullName())
	end
end

local function bindZone(zone, folder: Instance)
	if boundFolders[folder] then
		return
	end
	boundFolders[folder] = true
	activeClaims[folder] = {}

	local detectionMode = folder:GetAttribute("DetectionMode")
	if detectionMode == nil then
		detectionMode = Config.Defaults.DetectionMode
	end
	if detectionMode ~= "Center" and detectionMode ~= "Ground" then
		warn("[StatusEffectZoneSystem] Invalid DetectionMode; using Center on", folder:GetFullName())
		detectionMode = "Center"
	end
	zone:SetDetectionMode(detectionMode)

	zone:OnPlayerEntered(function(player)
		enterZone(player, folder)
	end)
	zone:OnPlayerExited(function(player)
		exitZone(player, folder)
	end)

	folder:GetAttributeChangedSignal("Enabled"):Connect(function()
		if folder:GetAttribute("Enabled") ~= false then
			return
		end
		local claims = activeClaims[folder]
		if not claims then
			return
		end
		for player in pairs(claims) do
			exitZone(player, folder)
		end
	end)

	folder.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end
		local claims = activeClaims[folder]
		if claims then
			for player in pairs(claims) do
				exitZone(player, folder)
			end
		end
		activeClaims[folder] = nil
		boundFolders[folder] = nil
	end)

	if Config.Debug then
		print("[StatusEffectZoneSystem] Bound", folder:GetFullName())
	end
end

function StatusEffectZoneService.Init(newEffectsFunctions)
	assert(typeof(newEffectsFunctions) == "table", "StatusEffectZoneService.Init expects the effects functions table")
	if initialized then
		return
	end
	initialized = true
	effectsFunctions = newEffectsFunctions

	Zones:OnTypeLoaded(Config.ZoneType, bindZone)
	Players.PlayerRemoving:Connect(function(player)
		for _, claims in pairs(activeClaims) do
			claims[player] = nil
		end
	end)
end

return StatusEffectZoneService
