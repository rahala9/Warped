local lightningModel = workspace:WaitForChild("TerrainParts"):WaitForChild("Weather"):WaitForChild("Bolt")
local Debris = game:GetService("Debris")
local clouds = workspace:WaitForChild("TerrainParts"):WaitForChild("Weather"):WaitForChild("Clouds")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PartCache = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("PartCache"):WaitForChild("PartCache"))
local player = game.Players.LocalPlayer
local LightningStrikeRemote = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("LightningStrikeRemote")
local Lighting = game:GetService("Lighting")
local fireTemplate = Instance.new("Part")
fireTemplate.Name = "FirePart"
fireTemplate.Anchored = true
fireTemplate.CanCollide = false
fireTemplate.CanTouch = false
fireTemplate.Transparency = 1
fireTemplate.Size = Vector3.new(0.5, 0.5, 0.5) -- small footprint

local fire = Instance.new("Fire")
fire.Size = 4
fire.Heat = 10
fire.Parent = fireTemplate

local FireCache = PartCache.new(fireTemplate, 10)
FireCache:SetCacheParent(workspace.Terrain)

local function getSortedBoltParts(model)
	local parts = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	-- Sort by Y position (or change to Z if bolt is horizontal)
	table.sort(parts, function(a, b)
		return a.Position.Y > b.Position.Y
	end)

	return parts
end

local function animateLightningBolt(model, delayTime, stepSize)
	local parts = getSortedBoltParts(model)
	local total = #parts

	for i = 1, total, stepSize or 1 do
		for j = 0, (stepSize or 1) - 1 do
			local part = parts[i + j]
			if part then
				part.Transparency = 0
			end
		end
		task.wait(delayTime or 0.02)
	end

	-- Optional: auto fade out
	task.delay(0.5, function()
		for _, part in ipairs(parts) do
			part.Transparency = 1
		end
	end)
end

function createGrowingFire(hitPart, worldHitPosition)

	local firePart = FireCache:GetPart()
	firePart.Position = worldHitPosition
	firePart.Parent = workspace.Terrain

	-- Optionally grow fire over time
	task.delay(5, function()
		FireCache:ReturnPart(firePart)
	end)

end

local function handleLightningImpact(startPos, endPos)
	local direction = (endPos - startPos)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {lightningModel,clouds}

	local result = workspace:Raycast(startPos, direction, rayParams)

	if result and result.Instance then
		--print("Lightning hit:", result.Instance:GetFullName())
		
		createGrowingFire(result.Instance, result.Position)
		
	end
end

local LightningBolt = {}
LightningBolt.__index = LightningBolt

local function getPlayerFromPart(part)
	if not part then return nil end
	local character = part:FindFirstAncestorOfClass("Model")
	if character then
		return game.Players:GetPlayerFromCharacter(character)
	end
	return nil
end

function LightningBolt.new(target,startPos, endPos, PartCount)
	local self = setmetatable({}, LightningBolt)
	
	local direction = (endPos - startPos).Unit

	-- Use this matrix to rotate Y+ to face toward the direction
	local right = Vector3.new(1, 0, 0)
	if math.abs(direction:Dot(right)) > 0.99 then
		right = Vector3.new(0, 0, 1) -- pick alternate axis if nearly aligned
	end
	right = direction:Cross(right).Unit
	local back = right:Cross(direction).Unit
	local up = direction
	
	local nearness = (endPos - player.Character.HumanoidRootPart.CFrame.Position).Magnitude
	
	if (nearness < 50) then
		
		print("Lightning was near")
		
		local lightningStrikeSound = workspace:FindFirstChild("LightningStrikeSound")

		if (lightningStrikeSound) then
			lightningStrikeSound:Play()
		else
			local sound = Instance.new("Sound")
			sound.Name = "LightningStrikeSound"
			sound.SoundId = "rbxassetid://6734393210"--"rbxassetid://3981355300" -- Thunder clap
			sound.Looped = false
			--sound.Volume = .2
			sound.Parent = workspace
			sound:Play()
		end
	else
		
		local whichLightning = math.random(0,3)
		
		print("Lightning was far")
		
		local soundId = "6767192500"
		
		if (whichLightning > 2) then
			soundId = "9120021267"
		elseif (whichLightning > 1) then
			soundId = "6767192500"
		else
			soundId = "9120021237"
		end
		
		local rollingThunderSound = workspace:FindFirstChild("RollingThunderSound")

		if (rollingThunderSound) then
			rollingThunderSound:Play()
		else
			local sound = Instance.new("Sound")
			sound.Name = "RollingThunderSound"
			sound.SoundId = "rbxassetid://"..soundId --"rbxassetid://3981355300" -- Thunder clap
			sound.Looped = false
			--sound.Volume = .2
			sound.Parent = workspace
			sound:Play()
		end
	end	

	-- Set PrimaryPartCFrame
	local cf = CFrame.fromMatrix(endPos, right, up) -- Y+ is aligned to 'up' (the bolt direction)
	lightningModel:SetPrimaryPartCFrame(cf)
	
	animateLightningBolt(lightningModel, .001,3)
	
	task.spawn(function()
		
		-- Save original values
		local originalAmbient = Lighting.Ambient
		local originalOutdoor = Lighting.OutdoorAmbient
		local originalBrightness = Lighting.Brightness
		-- Flash to white/gray
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness = 10
		
		task.wait(0.1)
		-- Restore
		Lighting.Ambient = originalAmbient
		Lighting.OutdoorAmbient = originalOutdoor
		
		Lighting.Brightness = originalBrightness
	end)
	
	--print("LightningBolt target: ",target)
	
	--if (typeof(target) == "Instance" and target.Name == "HumanoidRootPart") then
		
	--	local targetPlayer = getPlayerFromPart(target)
		
	--	if (targetPlayer) then
	--		--I got hit so set effect
	--		if (targetPlayer == player) then
	--			LightningStrikeRemote:FireServer("HitPlayer")
	--		end
	--	else
	--		if (target:GetAttribute("HasLightningResult")) then
	--			local lightningResult = target:FindFirstChild("LightningResult")

	--			if (lightningResult) then
	--				lightningResult.Transparency = 0
	--				local body = target.Parent:FindFirstChild("Body")
	--				if (body) then
	--					body.Transparency = 1
	--					Debris:AddItem(target.Parent,30)
	--				end

	--			end
	--		end
	--	end
		
	--else
	--	handleLightningImpact(startPos, endPos)
	--end
	
	if (target.type == "terrainTarget") then
		handleLightningImpact(startPos, endPos)
	end
	

	return self
end


return LightningBolt