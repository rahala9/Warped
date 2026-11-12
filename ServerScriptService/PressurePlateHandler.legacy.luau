--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")


--Remote Events
--local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")
--local SpawnEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("Spawn")
--local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
--local WorldChangeEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("WorldChangeEvent")
--local RunActEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RunAct")

--Functions
--local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
--local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
--local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
--local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)

--Definition Modules
--local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
--local ZoneDefinitions = require(ReplicatedStorage.SharedModules.ZoneDefinitions)

--Objects

--Modules
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)
local PPC = require(ReplicatedStorage.SharedModules.PressurePlateController)


Zones:OnLoaded("PressurePlate1", function(zone)
	zone:SetDetectionMode("Ground")

	local plate = PPC.new({ 
		Name = "PressurePlate1", 
		Zone = zone, 
		Mode = "Hold", -- "Momentary"
		RequiredCount = 1, 
		Cooldown = 0.25, 
		Debug = true, })

	local plateModel = zone.Folder and zone.Folder.Parent
	local innerPlate = plateModel and plateModel:FindFirstChild("InnerPlate")
	
	local laserDoor1 = workspace.Areas.StarhopStation.TEST:FindFirstChild("LaserDoor1")
	
	if not innerPlate then
		warn("PressurePlate1 missing InnerPlate at", plateModel and plateModel:GetFullName())
		return
	end
	
	if not laserDoor1 then
		warn("PressurePlate1 missing laserWall at workspace")
		return
	end
	
	local laserBeamWall = laserDoor1:FindFirstChild("LaserBeamWall")
	if not laserBeamWall then
		warn("PressurePlate1 missing laserBeamWall at workspace")
		return
	end
	
	local laserDoor1KillBlock = laserBeamWall:FindFirstChild("Kill")
	

	local upCFrame = innerPlate.CFrame
	local downCFrame = upCFrame * CFrame.new(0, -0.5, 0)

	local currentTween: Tween? = nil
	local desiredPressed = false

	local function playTo(targetCFrame: CFrame)
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end

		currentTween = TweenService:Create(
			innerPlate,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = targetCFrame }
		)

		currentTween:Play()
		currentTween.Completed:Wait()
	end

	local function updateVisual()
		-- Snap intent at call-time
		local target = desiredPressed and downCFrame or upCFrame

		-- If already basically there, skip
		if (innerPlate.CFrame.Position - target.Position).Magnitude < 0.001 then
			return
		end

		-- Protect against errors so we never get "stuck"
		local ok, err = pcall(function()
			playTo(target)
		end)
		if not ok then
			warn("PressurePlate tween error:", err)
		end
	end
	
	local function ToggleLaserWall()
		for _,laserBeam in pairs(laserBeamWall:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				laserBeam.PrimaryPart.Beam.Enabled = not desiredPressed
				laserBeam.PrimaryPart.Part.Transparency = desiredPressed and 1 or .5
			end
		end
		
		laserDoor1KillBlock.CanTouch = not desiredPressed
		
	end

	plate.OnActivated:Connect(function()
		desiredPressed = true
		print("TEST PressurePlate1 Activated")
		updateVisual()
		ToggleLaserWall()
	end)

	plate.OnDeactivated:Connect(function()
		desiredPressed = false
		print("TEST PressurePlate1 Deactivated")
		updateVisual()
		ToggleLaserWall()
	end)
end)

Zones:OnLoaded("PressurePlate2", function(zone)
	zone:SetDetectionMode("Ground")
	
	

	local plate = PPC.new({ 
		Name = "PressurePlate2", 
		Zone = zone, 
		Mode = "Hold", -- "Momentary"
		RequiredCount = 1, 
		Cooldown = 0.25, 
		Debug = true, })

	local plateModel = zone.Folder and zone.Folder.Parent
	local innerPlate = plateModel and plateModel:FindFirstChild("InnerPlate")
	local laserDoor1 =  workspace.Areas.StarhopStation.TEST:FindFirstChild("LaserDoor1")
	local deadIntern =  workspace.Areas.StarhopStation.TEST:FindFirstChild("DeadIntern")
	
	plate:TrackItem(deadIntern)

	if not innerPlate then
		warn("PressurePlate2 missing InnerPlate at", plateModel and plateModel:GetFullName())
		return
	end

	if not laserDoor1 then
		warn("PressurePlate2 missing laserWall at workspace")
		return
	end

	local laserBeamWall = laserDoor1:FindFirstChild("LaserBeamWall")
	if not laserBeamWall then
		warn("PressurePlate2 missing laserBeamWall at workspace")
		return
	end

	local laserDoor1KillBlock = laserBeamWall:FindFirstChild("Kill")

	local upCFrame = innerPlate.CFrame
	local downCFrame = upCFrame * CFrame.new(0, -0.5, 0)

	local currentTween: Tween? = nil
	local desiredPressed = false

	local function playTo(targetCFrame: CFrame)
		if currentTween then
			currentTween:Cancel()
			currentTween = nil
		end

		currentTween = TweenService:Create(
			innerPlate,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = targetCFrame }
		)

		currentTween:Play()
		currentTween.Completed:Wait()
	end

	local function updateVisual()
		-- Snap intent at call-time
		local target = desiredPressed and downCFrame or upCFrame

		-- If already basically there, skip
		if (innerPlate.CFrame.Position - target.Position).Magnitude < 0.001 then
			return
		end

		-- Protect against errors so we never get "stuck"
		local ok, err = pcall(function()
			playTo(target)
		end)
		if not ok then
			warn("PressurePlate2 tween error:", err)
		end
	end


	local function ToggleLaserWall()
		for _,laserBeam in pairs(laserBeamWall:GetChildren()) do
			if laserBeam:IsA("Model") and laserBeam.Name == "LaserBeam" then
				laserBeam.PrimaryPart.Beam.Enabled = not desiredPressed
				laserBeam.PrimaryPart.Part.Transparency = desiredPressed and 1 or .5
			end
		end

		laserDoor1KillBlock.CanTouch = not desiredPressed

	end


	--zone.OnItemEntered:Connect(function()
	--	print("TEST PressurePlate2 Item Entered")
	--	desiredPressed = true
	--	print("TEST PressurePlate2 Activated")
	--	updateVisual()
	--	ToggleLaserWall()desiredPressed = true
	--	print("TEST PressurePlate2 Activated")
	--	updateVisual()
	--	ToggleLaserWall()
	--end)	

	plate.OnActivated:Connect(function()
		desiredPressed = true
		print("TEST PressurePlate2 Activated")
		updateVisual()
		ToggleLaserWall()
	end)

	plate.OnDeactivated:Connect(function()
		desiredPressed = false
		print("TEST PressurePlate2 Deactivated")
		updateVisual()
		ToggleLaserWall()
	end)
end)

Zones:OnLoaded("TrapDoor1", function(zone)

	zone:SetDetectionMode("Ground")

	local plate = PPC.new({
		Name = "PressurePlate1",
		Zone = zone,
		Mode = "Hold",         -- "Momentary"
		RequiredCount = 1,
		Cooldown = 0.25,
		Debug = true,
	})
	
	local plateModel = zone.Folder and zone.Folder.Parent
	local innerPlate = plateModel and plateModel:FindFirstChild("InnerPlate")

	if not innerPlate then
		warn("TrapDoor1 missing InnerPlate at", plateModel and plateModel:GetFullName())
		return
	end

	plate.OnActivated:Connect(function(ctx)
		-- open door / enable prompt / start quest step
		print("TEST TrapDoor1 Activated")

		innerPlate.Transparency = 1
		innerPlate.CanCollide = false
		
	end)

	plate.OnDeactivated:Connect(function(ctx)
		-- close door (only meaningful for Hold mode)
		print("TEST TrapDoor1 Deactivated")
		
		task.delay(2,function()

			innerPlate.Transparency = 0
			innerPlate.CanCollide = true
			
		end)
	end)
end)