local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SwimmingFunctions = require(script.Parent:WaitForChild("SwimmingFunctions"))
local GetWaveSampleTickEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetWaveSampleTick")
local Draw = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Draw"))
local RunService = game:GetService("RunService")

local currentWater = SwimmingFunctions.currentWater

local shore =  Vector3.new(30.745, 81.519, -1628.331) --TODO this need to be per place

local speedMultiple = 0.0045 --0.0025	-- Smaller is faster wave movement, higher is slower
local maxDistance = 850 -- Distance in studs from character, to stop calculating bone position


local origPosTable = {}
local LocalPlayer = Players.LocalPlayer
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local hum = char:FindFirstChildOfClass("Humanoid")
local mouse = Players.LocalPlayer:GetMouse()

local antiGravForce = HRP.AssemblyMass * workspace.Gravity

function GerstnerWave3(SamplePosition ,Wavelength, Direction, Steepness, Gravity, SampleTick, Part, TransitionDistance)
	local k = (2 * math.pi) / Wavelength
	local a = Steepness/k

	local d = Direction.Unit
	local c = math.sqrt(Gravity / k)
	local f = k * d:Dot(Vector2.new(SamplePosition.X,SamplePosition.Z)) - c * SampleTick
	local cosF = math.cos(f)

	--Displacement Vectors
	local dX = (d.X * (a * cosF))
	local dY = a * math.sin(f)
	local dZ = ( d.Y * (a * cosF))
	return Vector3.new(dX, dY, dZ)
end

local totalBones = currentWater:GetChildren() --SwimmingFunctions.currentWater:GetChildren()

for _, bone in pairs(totalBones) do
	if bone:IsA("Bone") then
		origPosTable[bone] = bone.Position
	end
end


local player = game.Players.LocalPlayer

-- Setup wave movement connection
local skipCounter = 0
local SampleTick = 0
local bob = 0
local bobDirection = 1
local floating = false

--local char = player.Character
local rootPart = char:FindFirstChild("HumanoidRootPart")

local speed = 1150
local camera = game.Workspace.CurrentCamera
local plankYPositionOnSurface = -1 * math.huge

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)


function GetPointOnWave(closestBones, targetPoint)
	
	if (not closestBones) then
		return nil
	end
	
	if (#closestBones < 3) then
		return nil
	end
	
	local p1 = closestBones[1].WorldPosition
	local p2 = closestBones[2].WorldPosition
	local p3 = closestBones[3].WorldPosition

	-- calculate barycentric coordinates
	local v0 = p2 - p1
	local v1 = p3 - p1
	local v2 = targetPoint - p1

	local dot00 = v0:Dot(v0)
	local dot01 = v0:Dot(v1)
	local dot02 = v0:Dot(v2)
	local dot11 = v1:Dot(v1)
	local dot12 = v1:Dot(v2)

	local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
	local u = (dot11 * dot02 - dot01 * dot12) * invDenom
	local v = (dot00 * dot12 - dot01 * dot02) * invDenom

	-- check if target point is within triangle
	if u < 0 or v < 0 or u + v > 1 then 

		return Vector3.new(targetPoint.X,p1.Y,targetPoint.Z)
	end 

	-- calculate height using barycentric coordinates
	local height = p1.Y + u * (p2.Y - p1.Y) + v * (p3.Y - p1.Y)

	return Vector3.new(targetPoint.X,height,targetPoint.Z)
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
	SampleTick = GetWaveSampleTickEvent()
end)

local waveTable = {}
local tickResolution = 0.1  -- Adjust resolution as needed
local maxTicks = 1000  -- Ensure the range is sufficiently large
local precomputed = false

local function roundToNearestTenth(number)
	return math.floor(number * 10 + 0.5) / 10
end

function precomputeWaves(bones, maxTicks, tickResolution)
	local waveTable = {}
	for _, bone in pairs(bones) do
		if bone:IsA("Bone") then
			local boneWaveTable = {}
			local SamplePosition = bone.WorldPosition
			local distanceFromShore = (SamplePosition - Vector3.new(shore.X, SamplePosition.Y, SamplePosition.Z)).Magnitude

			local Wavelength, Direction, Steepness, Gravity
			if distanceFromShore < 200 then
				Wavelength, Direction, Steepness, Gravity = 50, Vector2.new(0, 1), .01, 1
			else
				Wavelength, Direction, Steepness, Gravity = 100, Vector2.new(1, 0), .05, 1
			end

			for nextTick = 0, maxTicks, 1 do
				local realTick = roundToNearestTenth(nextTick * tickResolution)
				local waveValue = GerstnerWave3(SamplePosition, Wavelength, Direction, Steepness, Gravity, realTick, shore, 10)
				boneWaveTable[nextTick] = waveValue
			end

			-- Ensure smooth transition by averaging the last and first values
			boneWaveTable[maxTicks + 1] = boneWaveTable[0]

			waveTable[bone] = boneWaveTable
		else
			--warn("Bone not a bone:", bone.Name)
		end
	end
	precomputed = true
	return waveTable
end

-- Precompute wave values for 20 seconds with a resolution of 0.01 seconds
local precomputedValues = precomputeWaves(totalBones, maxTicks, tickResolution)

local updateInterval =  1
local accumulatedTime = 0

local numberOfBonesHandled = 0



local sampleTickInterval = 0.1
local accumulatedTime = 0

RunService.RenderStepped:Connect(function(deltaTime)
	if not precomputed then
		return
	end

	accumulatedTime = accumulatedTime + deltaTime

	while accumulatedTime >= sampleTickInterval do
		accumulatedTime = accumulatedTime - sampleTickInterval
		SampleTick = SampleTick + 1
		if SampleTick > maxTicks then
			SampleTick = 0
		end
	end

	local hrpPos = char.HumanoidRootPart.Position
	local interpolationFactor = accumulatedTime / sampleTickInterval
	
	local closestBones = {}
	local closestDistances = {}
	
	for _, bone in pairs(totalBones) do
		local origPos = origPosTable[bone]
		if origPos then
			local boneDist = (hrpPos - bone.WorldPosition).Magnitude
			if boneDist <= maxDistance then
				local precomputedBone = precomputedValues[bone]
				if precomputedBone then
					local currentWave = precomputedBone[SampleTick]
					local nextTick = (SampleTick + 1) % (maxTicks + 1)
					local nextWave = precomputedBone[nextTick]

					-- Ensure smooth looping by interpolating with the first wave data point
					if nextTick == 0 then
						nextWave = precomputedBone[0] -- Adjust based on your data structure
					end

					if currentWave and nextWave then
						--bone.Position = origPos + currentWave:Lerp(nextWave, interpolationFactor)
						local interpolatedWave = currentWave:Lerp(nextWave, interpolationFactor)
						bone.Position = origPos + interpolatedWave
					end
				else
					warn("No precomputed values for bone:", bone)
				end
				
				-- Update closest bones
				if #closestBones < 3 then
					table.insert(closestBones, bone)
					table.insert(closestDistances, boneDist)
				else
					local maxDistanceIndex = 1
					for i, d in ipairs(closestDistances) do
						if d > closestDistances[maxDistanceIndex] then
							maxDistanceIndex = i
						end
					end
					if boneDist < closestDistances[maxDistanceIndex] then
						closestBones[maxDistanceIndex] = bone
						closestDistances[maxDistanceIndex] = boneDist
					end
				end
				
				
			end
		end
	end
	
	if (closestBones) then
		-- Update player's position on the wave using the closest bones
		SwimmingFunctions.playerExactPositionOnWave = GetPointOnWave(closestBones, hrpPos)
		
		if (SwimmingFunctions.playerExactPositionOnWave) then
			SwimmingFunctions.playerYPositionOnSurface = SwimmingFunctions.playerExactPositionOnWave.Y
		end
		
	end
	
end)