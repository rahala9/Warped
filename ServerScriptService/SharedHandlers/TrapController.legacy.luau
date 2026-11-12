local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local tweenService = game:GetService("TweenService")
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local CollectionService = game:GetService("CollectionService")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)


function EnableStates(player,enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
end

function TriggerBearTrapOnEnemy(trap,enemy,player)

	----If player already has effect do nothing
	--if (EffectsFunctions.HasEffect(player,"Trapped")) then
	--	return
	--end

	CollectionService:RemoveTag(trap,"Trap")

	enemy.char.PrimaryPart.CFrame = CFrame.new(Vector3.new(trap.PrimaryPart.Position.X,enemy.char.PrimaryPart.Position.Y+.1,trap.PrimaryPart.Position.Z)) 
	enemy.char.PrimaryPart.Anchored = true


	local jaw1 = trap.BearTrapJaw1
	local jaw2 = trap.BearTrapJaw2
	local axel1 = jaw1.Axel1
	local axel2 = jaw2.Axel2

	local tweeningInformation = TweenInfo.new(

		.1, -- Length
		Enum.EasingStyle.Quad, -- Easing style of the TweenInfo
		Enum.EasingDirection.InOut, -- Easing direction of the TweenInfo
		0, -- Number of times the tween will repeat   
		false, -- Should the tween repeat?
		0 -- Delay between each tween  
	)


	local rotatedCFrame1 = CFrame.Angles(math.rad(70),0,0)
	local rotatedCFrame2 = CFrame.Angles(math.rad(-70),0,0)
	local Jaw1Tween = tweenService:Create(axel1,tweeningInformation,{CFrame = axel1.CFrame * rotatedCFrame1}	)
	local Jaw2Tween = tweenService:Create(axel2,tweeningInformation,{CFrame = axel2.CFrame * rotatedCFrame2}	)
	Jaw1Tween:Play()
	Jaw2Tween:Play()
	--Jaw1Tween.Completed:wait()		

	EffectsFunctions.AddEnemyEffect(player,enemy,"Bleed")
	EffectsFunctions.AddEnemyEffect(player,enemy,"Trapped")

	
	game.Debris:AddItem(trap, 10)	
end

function TriggerBearTrapOnPlayer(trap,player,owner)
	
	--If player already has effect do nothing
	if (EffectsFunctions.HasEffect(player,"Trapped")) then
		return
	end
	
	CollectionService:RemoveTag(trap,"Trap")
	
	player.Character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(trap.PrimaryPart.Position.X,player.Character.PrimaryPart.Position.Y+.1,trap.PrimaryPart.Position.Z))) 
	player.Character.PrimaryPart.Anchored = true
	player.Character.Humanoid.Sit = true
	EnableStates(player,false)

	local jaw1 = trap.BearTrapJaw1
	local jaw2 = trap.BearTrapJaw2
	local axel1 = jaw1.Axel1
	local axel2 = jaw2.Axel2

	local tweeningInformation = TweenInfo.new(

		.1, -- Length
		Enum.EasingStyle.Quad, -- Easing style of the TweenInfo
		Enum.EasingDirection.InOut, -- Easing direction of the TweenInfo
		0, -- Number of times the tween will repeat   
		false, -- Should the tween repeat?
		0 -- Delay between each tween  
	)


	local rotatedCFrame1 = CFrame.Angles(math.rad(70),0,0)
	local rotatedCFrame2 = CFrame.Angles(math.rad(-70),0,0)
	local Jaw1Tween = tweenService:Create(axel1,tweeningInformation,{CFrame = axel1.CFrame * rotatedCFrame1}	)
	local Jaw2Tween = tweenService:Create(axel2,tweeningInformation,{CFrame = axel2.CFrame * rotatedCFrame2}	)
	Jaw1Tween:Play()
	Jaw2Tween:Play()
	--Jaw1Tween.Completed:wait()		

	EffectsFunctions.AddEffect(player,"Bleed",ProgressFunctions.GetLevel(owner))
	EffectsFunctions.AddEffect(player,"Trapped",ProgressFunctions.GetLevel(owner))
	
	game.Debris:AddItem(trap, 10)	
end

local debounce = false
local delta = 0
local HEARTBEAT_FREQUENCY = .1
RunService.Heartbeat:Connect(function(step)
	

	if (delta < HEARTBEAT_FREQUENCY ) then
		delta = delta + step
		return
	else
		delta = 0
	end
		
	for _,trap in pairs(CollectionService:GetTagged("Trap")) do

		for i,player in pairs(game.Players:GetChildren()) do
			
			if((player.Character.PrimaryPart.Position - trap.PrimaryPart.Position).magnitude<4) then
				TriggerBearTrapOnPlayer(trap,player,game.Players[trap:GetAttribute("Owner")])
			end
		end
		
		for _,enm in pairs(enemyFunctions.GetEnemies()) do
			if (enm.char == nil) then
				continue
			end
			if (enm.char.PrimaryPart == nil) then
				continue
			end

			if((enm.char.PrimaryPart.Position - trap.PrimaryPart.Position).magnitude<4) then	

				TriggerBearTrapOnEnemy(trap,enm,game.Players[trap:GetAttribute("Owner")])
			end
		end
	end
end)
