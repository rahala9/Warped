local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ZoneService = require(ReplicatedStorage.SharedModules.ZoneService)

local ZoneRegistry = {}
ZoneRegistry._zones = {}          -- [zoneKey] = zoneObject
ZoneRegistry._listeners = {}      -- [zoneKey] = {callbacks...}

-- Quest event integration (server only)
local QuestService = nil
if RunService:IsServer() then
	-- Defer the require so ZoneLoader can be required before QuestService:Init()
	task.defer(function()
		local ok, result = pcall(function()
			return require(game:GetService("ServerScriptService")
				:WaitForChild("SharedServices")
				:WaitForChild("QuestSystem")
				:WaitForChild("QuestService"))
		end)
		if ok then
			QuestService = result
		end
	end)
end

local function getZoneKey(folder)
	return folder:GetAttribute("ZoneKey") or folder.Name
end

function ZoneRegistry:Get(zoneKey)
	return self._zones[zoneKey]
end

function ZoneRegistry:OnLoaded(zoneKey, callback)
	self._listeners[zoneKey] = self._listeners[zoneKey] or {}
	table.insert(self._listeners[zoneKey], callback)
	-- If already loaded, fire immediately
	local existing = self._zones[zoneKey]
	if existing then
		callback(existing)
	end
end

local function fireLoaded(zoneKey, zone)
	local list = ZoneRegistry._listeners[zoneKey]
	if not list then return end
	for _, cb in ipairs(list) do
		cb(zone)
	end
end

-- Determine which player owns an item (customize to your game)
local function getItemOwner(item)
	-- Check for an OwnerUserId attribute (set by your pickup/carry system)
	local ownerUserId = item:GetAttribute("OwnerUserId")
	if ownerUserId then
		return Players:GetPlayerByUserId(ownerUserId)
	end

	-- Check if item is parented under a player's character
	local ancestor = item.Parent
	while ancestor do
		local player = Players:GetPlayerFromCharacter(ancestor)
		if player then
			return player
		end
		ancestor = ancestor.Parent
	end

	return nil
end

local function wireQuestEvents(zone, zoneKey)
	if not RunService:IsServer() then return end

	-- Fire quest event when a player enters the zone
	zone:OnPlayerEntered(function(player)
		if QuestService then
			QuestService:EmitEvent(player, "ZoneEntered", {
				zoneId = zoneKey,
			})
		end
	end)

	-- Fire quest event when a tracked item enters the zone
	zone:OnItemEntered(function(item)
		if not QuestService then return end

		local owner = getItemOwner(item)
		if not owner then return end

		QuestService:EmitEvent(owner, "ItemEnteredZone", {
			itemId = item:GetAttribute("ItemId") or item.Name,
			zoneId = zoneKey,
		})
	end)
end

local function tryLoadFolder(folder)
	local zoneKey = getZoneKey(folder)
	if ZoneRegistry._zones[zoneKey] then return end

	local ok, zoneOrErr = pcall(function()
		return ZoneService:CreateZoneFromFolder(folder)
	end)

	if not ok then
		warn("Zone load failed:", zoneKey, zoneOrErr)
		return
	end

	ZoneRegistry._zones[zoneKey] = zoneOrErr

	-- Wire up quest events for this zone
	wireQuestEvents(zoneOrErr, zoneKey)

	fireLoaded(zoneKey, zoneOrErr)

	if RunService:IsServer() then
		print("[Server] Loaded zone:", zoneKey)
	else
		print("[Client] Loaded zone:", zoneKey)
	end
end

local function unloadFolder(folder)
	local zoneKey = getZoneKey(folder)
	local zone = ZoneRegistry._zones[zoneKey]
	if not zone then return end
	if zone.Destroy then zone:Destroy() end
	ZoneRegistry._zones[zoneKey] = nil
	if RunService:IsServer() then
		print("[Server] Unloaded zone:", zoneKey)
	else
		print("[Client] Unloaded zone:", zoneKey)
	end
end

-- Discover via tag
for _, folder in ipairs(CollectionService:GetTagged("ZoneFolder")) do
	tryLoadFolder(folder)
end
CollectionService:GetInstanceAddedSignal("ZoneFolder"):Connect(tryLoadFolder)
CollectionService:GetInstanceRemovedSignal("ZoneFolder"):Connect(unloadFolder)

return ZoneRegistry
