-- SectorTracker.client.lua
-- Tracks player sector using pure math - no physical parts!
-- Place in StarterPlayer.StarterCharacterScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Load the spatial partition system
local SpatialPartition = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("SectorSystem"))

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Current sector tracking
local currentSector = nil

-- Check interval
local CHECK_INTERVAL = 0.5
local lastCheck = 0

-- Monitor position and detect sector changes
RunService.Heartbeat:Connect(function()
	local now = tick()
	if (now - lastCheck) < CHECK_INTERVAL then return end
	lastCheck = now

	if not humanoidRootPart or not humanoidRootPart.Parent then return end

	local position = humanoidRootPart.Position
	local sectorCoords = SpatialPartition.WorldToSector(position)

	-- Detect sector change
	if sectorCoords ~= currentSector then
		if sectorCoords then
			-- Entered new sector
			local sectorName = SpatialPartition.FormatSector(sectorCoords)
			local sectorCenter = SpatialPartition.SectorToWorld(sectorCoords)
			local distance = (position - sectorCenter).Magnitude

			print(string.format("📍 %s", sectorName))
			print(string.format("   Distance from center: %.0f studs", distance))

		elseif currentSector then
			-- Left grid
			print("📍 Left sector grid")
		end

		currentSector = sectorCoords
	end
end)

-- Startup message
print("[SectorTracker] Math-based sector tracking active")
SpatialPartition.VisualizeGrid()