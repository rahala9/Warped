local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ToxicBeanStalk = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("ToxicBeanStalk")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ObbyFunctions = require(ServerScriptService:WaitForChild("SharedFunctions"):WaitForChild("ObbyFunctions"))
local RunService = game:GetService("RunService")

local windMillAxel = workspace:WaitForChild("Areas"):WaitForChild("GrumpyRoosterFarms"):WaitForChild("Windmill"):WaitForChild("Body"):WaitForChild("Axel")
local blades = workspace:WaitForChild("Areas"):WaitForChild("GrumpyRoosterFarms"):WaitForChild("Windmill"):WaitForChild("Body"):WaitForChild("Blades")
local bladeMotor = blades:WaitForChild("HingeConstraint")

local debounce = false
local function onPromptTriggered(promptObject, player)
	
	if (promptObject.Name == "PourFertilizer") then
		
		if (debounce) then
			debounce = false
			return
		end

		debounce = true
		
		ObbyFunctions.GrowVine()
		
	end

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

local baseCFrame = CFrame.new(windMillAxel.Position)
local baseBladesCFrame = CFrame.new(blades.Position)

local currentAngle = 0 -- Start at 0 degrees

local angleIndex = 1
local angles = {0,300,100,260,180}

local function getNextAngle()
	
	if ((angleIndex + 1)  <= #angles) then
		angleIndex = angleIndex + 1
	else
		angleIndex = 1
	end
	
	return angles[angleIndex]
	
end

local function rotateToNext()
	local nextAngle = getNextAngle()

	local tween = TweenService:Create(
		windMillAxel.AlignOrientation,
		TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ CFrame = baseCFrame * CFrame.Angles(0, math.rad(nextAngle), 0) }
	)

	tween:Play()

	tween.Completed:Wait()
	currentAngle = nextAngle
	
	local BladesAngel = math.random(0, 359)
	
	bladeMotor.TargetAngle = BladesAngel
	
	--local tween2 = TweenService:Create(
	--	blades,
	--	TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	--	{ CFrame = baseCFrame * CFrame.Angles(0, 0, math.rad(BladesAngel)) }
	--)
	
	--tween2:Play()
	
	-- Start next rotation after small pause
	task.wait(2)
	rotateToNext()
end

rotateToNext()