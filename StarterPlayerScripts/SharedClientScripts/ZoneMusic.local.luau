--[[
	ZoneMusic.lua
	Place in: StarterPlayer > StarterPlayerScripts (LocalScript)

	Plays ambient music when the local player enters a zone that has
	a "Music" attribute (string, e.g. "rbxassetid://123456789").
	Crossfades between tracks when moving between zones.
	Fades out when leaving all music zones.

	Set the attribute on your zone folders in Studio:
		ZoneFolder > Music = "rbxassetid://123456789"

	Optional attributes:
		MusicVolume = 0.5    (default 0.5)
		MusicFadeIn = 1.5    (seconds, default 1.5)
		MusicFadeOut = 1.5   (seconds, default 1.5)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneService = require(ReplicatedStorage.SharedModules.ZoneService)

local player = Players.LocalPlayer
local currentSound = nil
local currentZoneKey = nil

local function stopCurrent(fadeOut)
	if not currentSound then return end

	local s = currentSound
	currentSound = nil
	currentZoneKey = nil

	local tween = TweenService:Create(s, TweenInfo.new(fadeOut or 1.5), { Volume = 0 })
	tween:Play()
	tween.Completed:Connect(function()
		s:Stop()
		s:Destroy()
	end)
end

local function parseMusicIds(musicAttr)
	local ids = {}
	for id in string.gmatch(musicAttr, "[^,]+") do
		local trimmed = id:match("^%s*(.-)%s*$")
		if trimmed and trimmed ~= "" then
			table.insert(ids, trimmed)
		end
	end
	return ids
end

local function pickRandom(list)
	return list[math.random(1, #list)]
end

local function playMusic(soundId, volume, fadeIn)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	currentSound = sound
	TweenService:Create(sound, TweenInfo.new(fadeIn or 1.5), { Volume = volume or 0.5 }):Play()
end

local function wireZoneMusic(folder)
	local musicAttr = folder:GetAttribute("Music")
	if not musicAttr then return end

	local musicIds = parseMusicIds(musicAttr)
	if #musicIds == 0 then return end

	local zoneKey = folder:GetAttribute("ZoneKey") or folder.Name
	local volume = folder:GetAttribute("MusicVolume") or 0.5
	local fadeIn = folder:GetAttribute("MusicFadeIn") or 1.5
	local fadeOut = folder:GetAttribute("MusicFadeOut") or 1.5

	-- Find the zone object — it may not exist yet if ZoneLoader hasn't
	-- processed this folder, so look it up from ZoneService's active list
	local function findZone()
		for _, zone in ipairs(ZoneService.ActiveZones) do
			if zone.Folder == folder then
				return zone
			end
		end
		return nil
	end

	local function attach(zone)
		zone:OnPlayerEntered(function(p)
			if p ~= player then return end
			if currentZoneKey == zoneKey then return end

			stopCurrent(fadeOut)
			currentZoneKey = zoneKey
			playMusic(pickRandom(musicIds), volume, fadeIn)
		end)

		zone:OnPlayerExited(function(p)
			if p ~= player then return end
			if currentZoneKey ~= zoneKey then return end

			stopCurrent(fadeOut)
		end)
	end

	-- Zone might already be loaded
	local zone = findZone()
	if zone then
		attach(zone)
		return
	end

	-- Zone not loaded yet — poll briefly until ZoneLoader creates it
	task.spawn(function()
		local attempts = 0
		while attempts < 50 do
			task.wait(0.1)
			attempts += 1
			zone = findZone()
			if zone then
				attach(zone)
				return
			end
		end
		warn("[ZoneMusic] Zone never loaded for music folder:", zoneKey)
	end)
end

-- Wire up existing tagged folders
for _, folder in ipairs(CollectionService:GetTagged("ZoneFolder")) do
	wireZoneMusic(folder)
end

-- Handle zones that stream in later
CollectionService:GetInstanceAddedSignal("ZoneFolder"):Connect(wireZoneMusic)
