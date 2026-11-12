
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local GetTimeOfDayEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDay")
local GetTimeOfDayServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDayServer")

local StormSystem = require(ServerScriptService:WaitForChild("SharedModules"):WaitForChild("StormSystem"))


local WorldChangeEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("WorldChangeEvent")
local DayNightChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DayNightChangeEvent")


local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local timeChangeInterval =  .0002 --.005 --.01 --fire every 2.5 seconds
local step_counter = 0 
local worldTime = 12

local Lighting = game:GetService("Lighting")

local Terrain = workspace.Terrain

Terrain.WaterColor = Color3.fromRGB(48, 167, 222) --80,180,220        -- Bright bluish lake color
Terrain.WaterTransparency = 0.6                           -- Fairly clear but still visible
Terrain.WaterReflectance = 0.05                           -- Low reflectivity for a calm look
Terrain.WaterWaveSize = 0.05                              -- Gentle wave pattern
Terrain.WaterWaveSpeed = 2                                -- Mild movement, not distracting


local worldTime = 6



local partsOfDay = {
	["SUNRISE"]="SUNRISE",
	["DAYTIME"]="DAYTIME",
	["SUNSET"]="SUNSET",
	["NIGHT"]="NIGHT",
	
}

local currentPartOfDay = -1



-- Constants for time progression
local DAY_LENGTH = 24
local SUNRISE_START = 6
local SUNRISE_END = 8
local SUNSET_START = 18
local SUNSET_END = 20
local HALF_NIGHT = 21 --9pm
local NIGHT = 23

-- Define color gradients for different times of day
local MorningColors = {
	Color3.fromRGB(232, 221, 172), -- Sunrise, early morning
	Color3.fromRGB(255, 247, 189), -- Mid-morning
	Color3.fromRGB(255, 229, 153), -- Late morning
}
local AfternoonColors = {
	Color3.fromRGB(255, 215, 0), -- Mid-afternoon
	Color3.fromRGB(242, 161, 34), -- Late afternoon
}
local EveningColors = {
	Color3.fromRGB(162, 92, 0), -- Early evening
	Color3.fromRGB(56, 40, 29), -- Night
}

wait(10)
--TODO only storm some of the time , maybe 1 5th of nights or even less
--StormSystem.StartStorm()

local currentPartOfDay = SUNRISE_START
local function changeTimeOfDay() 
	worldTime = worldTime + timeChangeInterval --.0005 --.0005 --.01

	Lighting:SetMinutesAfterMidnight(60*worldTime)

	if (worldTime>24) then
		worldTime = 0
	end
	
	--Logger.Debug("TEST WORLD TIME:",worldTime)
	
	if (currentPartOfDay ~= SUNRISE_START) and (worldTime >= SUNRISE_START) and (worldTime < SUNRISE_END) then
		currentPartOfDay = SUNRISE_START
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
		Logger.Debug("TEST WorldHandler changeTimeOfDay currentPartOfDay:",currentPartOfDay)
		
		StormSystem.StopStorm()
		
	elseif (currentPartOfDay ~= SUNRISE_END) and (worldTime >= SUNRISE_END) and (worldTime < SUNSET_START) then
		currentPartOfDay = SUNRISE_END
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
		--Logger.Debug("TEST OFFICE changeTimeOfDay currentPartOfDay:",currentPartOfDay)
	elseif (currentPartOfDay ~= SUNSET_START) and (worldTime >= SUNSET_START) and (worldTime < SUNSET_END) then
		currentPartOfDay = SUNSET_START
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
		
		Logger.Debug("TEST WorldHandler changeTimeOfDay currentPartOfDay:",currentPartOfDay)

		
		
	elseif (currentPartOfDay ~= SUNSET_END) and (worldTime >= SUNSET_END) and (worldTime < HALF_NIGHT) then
		currentPartOfDay = SUNSET_END
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
	
		
	elseif (currentPartOfDay ~= HALF_NIGHT) and (worldTime >= HALF_NIGHT) and (worldTime < NIGHT)  then
		currentPartOfDay = HALF_NIGHT
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
		--Logger.Debug("TEST OFFICE changeTimeOfDay currentPartOfDay:",currentPartOfDay)
	elseif (currentPartOfDay ~= NIGHT) and ((worldTime >= NIGHT) or (worldTime >= 0 and worldTime <= SUNRISE_START)) then
		currentPartOfDay = NIGHT
		WorldChangeEvent:Fire("Fall",false,currentPartOfDay)
		--Logger.Debug("TEST OFFICE changeTimeOfDay currentPartOfDay:",currentPartOfDay)
	end
	
	
	
end

function lerp(start, goal, alpha)
	return start + (goal - start) * alpha
end

function updateLighting()
	changeTimeOfDay()
	local timeOfDay = Lighting.ClockTime
	
	if (not timeOfDay) then
		return
	end
	
	local brightness, ambient, outdoorAmbient = 0, Color3.new(0), Color3.new(0)
	
	--Logger.Debug("TEST LIGHTING timeOfDay:",timeOfDay)
	-- Sunrise
	if timeOfDay >= SUNRISE_START and timeOfDay < SUNRISE_END then
		--Logger.Debug("TEST LIGHTING SUNRISE timeOfDay:",timeOfDay)
		local progress = (timeOfDay - SUNRISE_START) / (SUNRISE_END - SUNRISE_START)
		brightness = lerp(0.3, 1, progress)
		ambient = EveningColors[2]:Lerp(MorningColors[1], progress)
		outdoorAmbient = EveningColors[2]:Lerp(MorningColors[1], progress)
		-- Daytime
	elseif timeOfDay >= SUNRISE_END and timeOfDay < SUNSET_START then
		--Logger.Debug("TEST LIGHTING DAAYTIME timeOfDay:",timeOfDay)
		brightness = 1
		ambient = MorningColors[2]
		outdoorAmbient = MorningColors[2]
		-- Sunset
	elseif timeOfDay >= SUNSET_START and timeOfDay < SUNSET_END then
		--Logger.Debug("TEST LIGHTING SUNSET timeOfDay:",timeOfDay)
		local progress = (timeOfDay - SUNSET_START) / (SUNSET_END - SUNSET_START)
		brightness = lerp(1, 0.3, progress)
		ambient = AfternoonColors[2]:Lerp(EveningColors[1], progress)
		outdoorAmbient = AfternoonColors[2]:Lerp(EveningColors[1], progress)
		-- Nighttime
	else
		--Logger.Debug("TEST LIGHTING NIGHTTIME timeOfDay:",timeOfDay)
		brightness = 0.3
		ambient = EveningColors[2]
		outdoorAmbient = EveningColors[2]
	end

	Lighting.Brightness = brightness
	Lighting.Ambient = ambient
	Lighting.OutdoorAmbient = outdoorAmbient
end

-- Update lighting every second
RunService.Heartbeat:Connect(updateLighting)

DayNightChangeEvent.OnServerEvent:Connect(function(player)
	
	--TODO SECURITY Remove Player1 and check UserId instead
	if (player.UserId == 1490918058 or player.Name == "LittleSharkyZ" or player.Name == "Player1") then
		
	else
		return
	end
	
	if (worldTime > 16) or (worldTime < 6) then
		worldTime = 12
		changeTimeOfDay()
	else
		worldTime = 2
		changeTimeOfDay()
	end
end)


GetTimeOfDayEvent.OnServerInvoke = function(player)

	return worldTime,currentPartOfDay
end

GetTimeOfDayServerEvent.OnInvoke = function(player)

	return worldTime,currentPartOfDay
end

-- Optionally, initialize the lighting based on the current time
updateLighting()

Logger.Debug("Day/night cycle script initialized!")
