local ReplicatedStorage = game:GetService("ReplicatedStorage")
local animations = ReplicatedStorage:WaitForChild("SharedAnimations")
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)
local ZoneDefinitions = require(ReplicatedStorage.SharedModules.ZoneDefinitions)
local tweenService = game:GetService("TweenService")
local localPlayer = game.Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
--local showCartGuiEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ShowCart")
local UpdateZoneEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateZone")	

local PlayerState = require(script.Parent:WaitForChild("SharedClientScripts"):WaitForChild("PlayerStateFunctions"))



--local slideZone = Zone.new(workspace.Zones["Slide"])
--local outhouseZone = Zone.new(workspace.Zones["Outhouse"])
--local lakeInWaterZone = Zone.new(workspace.Zones["LakeInWater"])
--local LeviathanBunkerZone = Zone.new(workspace.Zones["LeviathanBunker"])
--local gasStationZone = Zone.new(workspace.Zones["Gas Station"])
--local grumpyRoosterFarmsZone = Zone.new(workspace.Zones["Grumpy Rooster Farms"])

--lakeInWaterZone:setAccuracy("High")

--local zones = {["Slide"]={},["Outhouse"]={},["LakeCheckWater"]={},["LakeInWater"]={},["LeviathanBunker"]={},["Gas Station"]={},["Grumpy Rooster Farms"]={}} --LakeInWater was not included so may need removed

--zones["Slide"].Animation = nil
--zones["Slide"].AnimationSpeed = 1
--zones["Slide"].Animation2 = nil
--zones["Slide"].Animation2Speed = 1
--zones["Slide"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["Slide"].Store = false

--zones["Grumpy Rooster Farms"].Animation = nil
--zones["Grumpy Rooster Farms"].AnimationSpeed = 1
--zones["Grumpy Rooster Farms"].Animation2 = nil
--zones["Grumpy Rooster Farms"].Animation2Speed = 1
--zones["Grumpy Rooster Farms"].MinLevel = 3
--zones["Grumpy Rooster Farms"].MaxLevel = 5
--zones["Grumpy Rooster Farms"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["Grumpy Rooster Farms"].Store = false

--zones["Outhouse"].Animation = nil
--zones["Outhouse"].AnimationSpeed = 1
--zones["Outhouse"].Animation2 = nil
--zones["Outhouse"].Animation2Speed = 1
--zones["Outhouse"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["Outhouse"].Store = false

--zones["LakeCheckWater"].Animation = nil
--zones["LakeCheckWater"].AnimationSpeed = 1
--zones["LakeCheckWater"].Animation2 = nil
--zones["LakeCheckWater"].Animation2Speed = 1
--zones["LakeCheckWater"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["LakeCheckWater"].Store = false

--zones["LakeInWater"].Animation = nil
--zones["LakeInWater"].AnimationSpeed = 1
--zones["LakeInWater"].Animation2 = nil
--zones["LakeInWater"].Animation2Speed = 1
--zones["LakeInWater"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["LakeInWater"].Store = false

--zones["LeviathanBunker"].Animation = nil
--zones["LeviathanBunker"].AnimationSpeed = 1
--zones["LeviathanBunker"].Animation2 = nil
--zones["LeviathanBunker"].Animation2Speed = 1
--zones["LeviathanBunker"].Sound = nil --workspace.Zones["Outhouse"]:FindFirstChild("Sound") --TODO move all sounds to a folder
--zones["LeviathanBunker"].Store = false

--zones["Gas Station"].Animation = workspace.QuestGivers.GasStationClerk.AnimationController:LoadAnimation(animations.HipHop1)
--zones["Gas Station"].AnimationSpeed = .5
--zones["Gas Station"].Sound = workspace.Zones["Gas Station"]:FindFirstChild("Sound")
--zones["Gas Station"].NPC =  workspace.QuestGivers:WaitForChild("GasStationClerk")
--zones["Gas Station"].NPCRightArmOriginalCFrame = zones["Gas Station"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame
--zones["Gas Station"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame = zones["Gas Station"].NPCRightArmOriginalCFrame * CFrame.Angles(math.rad(-70),0,0)
--zones["Gas Station"].NPCLeftArmOriginalCFrame = zones["Gas Station"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame
--zones["Gas Station"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame = zones["Gas Station"].NPCLeftArmOriginalCFrame * CFrame.Angles(math.rad(-70),0,0)
--zones["Gas Station"].Store = true

ZoneDefinitions["GasStation"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame = workspace.QuestGivers:WaitForChild("GasStationClerk").PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame * CFrame.Angles(math.rad(-70),0,0)
ZoneDefinitions["GasStation"].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame = workspace.QuestGivers:WaitForChild("GasStationClerk").PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame * CFrame.Angles(math.rad(-70),0,0)

local LABEL_DURATION = 3
local FADE_INFO = TweenInfo.new(1)

local areaLabel = Instance.new("TextLabel")
areaLabel.BackgroundTransparency = 1
--areaLabel.Position = UDim2.new(0, 0, 0, -100)
areaLabel.Size = UDim2.new(1, 0, 0.08, 0)
areaLabel.Font = Enum.Font.Garamond
areaLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
areaLabel.TextTransparency = 1
areaLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
areaLabel.TextStrokeTransparency = 1
areaLabel.TextScaled = true
areaLabel.TextWrapped = true
areaLabel.Name = "ZoneTitle"
areaLabel.Parent = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui")

local function DisplayZone(zone)
	--Fade in Sound

	if (ZoneDefinitions[zone].Sound ~= nil) then
		local originalVolume = ZoneDefinitions[zone].Sound.Volume
		ZoneDefinitions[zone].Sound.Volume = 0
		ZoneDefinitions[zone].Sound:Resume()
		tweenService:Create(ZoneDefinitions[zone].Sound, FADE_INFO, {Volume = originalVolume}):Play()
	end

	if (ZoneDefinitions[zone].Animation ~= nil) then

		if (ZoneDefinitions[zone].NPC) then
			ZoneDefinitions[zone].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame = ZoneDefinitions[zone].NPCRightArmOriginalCFrame
			ZoneDefinitions[zone].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame = ZoneDefinitions[zone].NPCLeftArmOriginalCFrame
		end

		ZoneDefinitions[zone].Animation:Play()
		ZoneDefinitions[zone].Animation:AdjustSpeed(ZoneDefinitions[zone].AnimationSpeed)
	end

	if (ZoneDefinitions[zone].Animation2 ~= nil) then
		ZoneDefinitions[zone].Animation2:Play()
		ZoneDefinitions[zone].Animation2:AdjustSpeed(ZoneDefinitions[zone].Animation2Speed)
	end

	areaLabel.Text  = ZoneDefinitions[zone].DisplayName
	if (ZoneDefinitions[zone].MinLevel ~= nil) then
		areaLabel.Text  = areaLabel.Text.." Level:"..ZoneDefinitions[zone].MinLevel.." - "..ZoneDefinitions[zone].MaxLevel
	end
	areaLabel.Visible = true

	--fade in zone label
	tweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 0, TextStrokeTransparency = 0.3}):Play()

	task.delay(1.5,function()
		tweenService:Create(areaLabel, FADE_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end)

	if(ZoneDefinitions[zone].Store == true) then
		showCartGuiEvent:Fire(true)
	end
end

local function EndDisplayZone(zone)
	if (ZoneDefinitions[zone].Animation ~= nil) then
		ZoneDefinitions[zone].Animation:Stop()

		if (ZoneDefinitions[zone].NPC) then
			if (ZoneDefinitions[zone].NPC.PrimaryPart) then
				ZoneDefinitions[zone].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame = ZoneDefinitions[zone].NPCRightArmOriginalCFrame * CFrame.Angles(math.rad(-70),0,0)
				ZoneDefinitions[zone].NPC.PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame = ZoneDefinitions[zone].NPCLeftArmOriginalCFrame * CFrame.Angles(math.rad(-70),0,0)
			end
		end
	end

	if (ZoneDefinitions[zone].Animation2 ~= nil) then
		ZoneDefinitions[zone].Animation2:Stop()
	end

	if (ZoneDefinitions[zone].Sound ~= nil) then
		ZoneDefinitions[zone].Sound:Stop()
	end

	if(ZoneDefinitions[zone].Store == true) then
		showCartGuiEvent:Fire(false)
	end

end

Zones.Outhouse:OnPlayerEntered(function(player)
	DisplayZone("Outhouse")
end)

Zones.Outhouse:OnPlayerExited(function(player)
	EndDisplayZone("Outhouse")
end)

Zones.GrumpyRoosterFarms:OnPlayerEntered(function(player)
	DisplayZone("GrumpyRoosterFarms")
end)

Zones.GrumpyRoosterFarms:OnPlayerExited(function(player)
	EndDisplayZone("GrumpyRoosterFarms")
end)

Zones.CampWhisperingWoods:OnPlayerEntered(function(player)
	DisplayZone("CampWhisperingWoods")
end)

Zones.CampWhisperingWoods:OnPlayerExited(function(player)
	EndDisplayZone("CampWhisperingWoods")
end)

Zones.Slide:OnPlayerEntered(function(player)
	PlayerState.InSlideZone = true	
end)

Zones.Slide:OnPlayerExited(function(player)
	PlayerState.InSlideZone = false	
end)

Zones.LakeInWater:OnPlayerEntered(function(player)
	PlayerState.InWaterZone = true	
end)

Zones.LakeInWater:OnPlayerExited(function(player)
	PlayerState.InWaterZone = false	
end)

Zones.LeviathanBunker:OnPlayerEntered(function(player)
	DisplayZone("LeviathanBunker")

	PlayerState.InLeviathanBunker = true			

end)

Zones.LeviathanBunker:OnPlayerExited(function(player)
	EndDisplayZone("LeviathanBunker")

	PlayerState.InLeviathanBunker = false			
end)

Zones.GasStation:OnPlayerEntered(function(player)
	DisplayZone("GasStation")
end)

Zones.GasStation:OnPlayerExited(function(player)
	EndDisplayZone("GasStation")
end)

UpdateZoneEvent.OnClientEvent:Connect(function(zoneFolder,zoneStatus)
	for _, part in pairs(zoneFolder:GetChildren()) do
		if (part:IsA("BasePart")) then
			part.CanCollide = zoneStatus
		end
	end
end)








