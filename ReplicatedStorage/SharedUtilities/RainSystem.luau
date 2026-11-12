-- RainSystem.lua
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local Zone = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("ZoneLoader"))

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local emitterRainTemplate = workspace:WaitForChild("TerrainParts"):WaitForChild("Weather"):WaitForChild("Rain"):WaitForChild("RAIN")
local emitterSplashTemplate = workspace:WaitForChild("TerrainParts"):WaitForChild("Weather"):WaitForChild("Rain"):WaitForChild("SPLASH")
local emitterRippleTemplate = workspace:WaitForChild("TerrainParts"):WaitForChild("Weather"):WaitForChild("Rain"):WaitForChild("RIPPLE")

local RainSystem = {}

-- Config
local CHECK_INTERVAL = 1
local RAIN_HEIGHT_OFFSET = Vector3.new(0, 20, 0)
local RAINCOVER_TAG = "RainCover"
local INDOOR_TAG = "Indoors"

local playerRainPart
local cameraRainPart
local playerEmitter
local cameraEmitter
local activeIndoorZone = nil
local indoorZones = {}
local ambientEmitters = {} -- ambient emitters around building when indoors

local splashParts = {}
local splashEmitters = {}
local splashOffsets = {}
local numSplashes = 1 --8
local splashRadius = 8

local windowRainOffsets = {
	Vector3.new(15, 20, 0),
	Vector3.new(-15, 20, 0),
	Vector3.new(0, 20, 15),
	Vector3.new(0, 20, -15),
}

for i = 1, numSplashes do
	local angle = (math.pi * 2) * (i / numSplashes)
	local offset = Vector3.new(math.cos(angle) * splashRadius, 0, math.sin(angle) * splashRadius)
	table.insert(splashOffsets, offset)

	local part = Instance.new("Part")
	part.Size = Vector3.new(40, 1, 40)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Name = "RainSplashPart"
	part.Parent = workspace

	local emitter = emitterSplashTemplate:Clone()
	emitter.Enabled = false
	emitter.Parent = part

	local emitterR = emitterRippleTemplate:Clone()
	emitterR.Enabled = false
	emitterR.Parent = part

	table.insert(splashParts, part)
	table.insert(splashEmitters, emitter)
	table.insert(splashEmitters, emitterR)
end

local function createRainPart(name)
	local part = Instance.new("Part")
	part.Size = Vector3.new(40, 1, 40)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Name = name
	part.Parent = workspace

	local emitter = emitterRainTemplate:Clone()
	emitter.Enabled = false
	emitter.Parent = part

	return part, emitter
end

local function isOutdoors(position)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = CollectionService:GetTagged(RAINCOVER_TAG)
	params.FilterType = Enum.RaycastFilterType.Include
	params.IgnoreWater = true

	local result = workspace:Raycast(position, Vector3.new(0, 100, 0), params)
	return result == nil
end

local function createAmbientEmitter(position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 1, 5)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position

	local emitter = emitterRainTemplate:Clone()
	emitter.Enabled = true
	emitter.Parent = part

	part.Parent = workspace
	return part
end

--local function setupIndoorZones()
--	for _, zonePart in ipairs(CollectionService:GetTagged(INDOOR_TAG)) do
--		local zone = Zone.new(zonePart)

--		zone.playerEntered:Connect(function(p)
--			if p == player then
--				activeIndoorZone = zone

--				-- Spawn ambient emitters around the zone
--				local zoneCenter = zone:getPosition()
--				local emitters = {}

--				for _, offset in ipairs(windowRainOffsets) do
--					table.insert(emitters, createAmbientEmitter(zoneCenter + offset))
--				end

--				ambientEmitters[zone] = emitters
--			end
--		end)

--		zone.playerExited:Connect(function(p)
--			if p == player then
--				activeIndoorZone = nil

--				-- Clean up ambient emitters
--				local emitters = ambientEmitters[zone]
--				if emitters then
--					for _, part in ipairs(emitters) do
--						part:Destroy()
--					end
--					ambientEmitters[zone] = nil
--				end
--			end
--		end)

--		table.insert(indoorZones, zone)
--	end
--end

function RainSystem.Stop()
	local rainSound = workspace:FindFirstChild("RainSound")
	
	if(rainSound) then
		rainSound:Destroy()
	end
	
end
function RainSystem.Start()
	playerRainPart, playerEmitter = createRainPart("PlayerRain")
	cameraRainPart, cameraEmitter = createRainPart("CameraRain")
	setupIndoorZones()
	
	local sound = Instance.new("Sound")
	sound.Name = "RainSound"
	sound.SoundId = "rbxassetid://9064263922"--"rbxassetid://3981355300" -- Thunder clap
	
	sound.Looped = true
	sound.Volume = .2
	sound.Parent = workspace
	sound:Play()
	sound.TimePosition = 30

	RunService.RenderStepped:Connect(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			playerRainPart.Position = root.Position + RAIN_HEIGHT_OFFSET
		end
		cameraRainPart.Position = camera.CFrame.Position + RAIN_HEIGHT_OFFSET

		local rayParams = RaycastParams.new()
		
		-- Build dynamic exclusion list
		local ignoreList = { player.Character }
		for _, splashPart in ipairs(splashParts) do
			table.insert(ignoreList, splashPart)
		end

		
		
		rayParams.FilterDescendantsInstances = ignoreList
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		if root then
			for i, offset in ipairs(splashOffsets) do
				local origin = root.Position + offset + Vector3.new(0, 5, 0)
				local result = workspace:Raycast(origin, Vector3.new(0, -20, 0), rayParams)
				if result then
					splashParts[i].Position = result.Position + Vector3.new(0, 0.05, 0)
				else
					splashParts[i].Position = root.Position + offset
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			local char = player.Character or player.CharacterAdded:Wait()
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local isRainingOnPlayer = activeIndoorZone == nil and isOutdoors(root.Position)
				playerEmitter.Enabled = isRainingOnPlayer

				for _, emitter in ipairs(splashEmitters) do
					emitter.Enabled = isRainingOnPlayer
				end
			end

			cameraEmitter.Enabled = isOutdoors(camera.CFrame.Position)
			task.wait(CHECK_INTERVAL)
		end
	end)
end

return RainSystem
