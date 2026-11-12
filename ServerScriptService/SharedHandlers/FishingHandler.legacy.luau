local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CastEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Cast")
local tweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local Players = game:GetService("Players")
local FishBiteServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FishBiteServer")
local FishingUpdateEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FishingUpdate")


--CastEvent:FireServer("ExitChairDown",game:GetService("Players").LocalPlayer:GetMouse().Hit.p)

local rand = Random.new(os.time())

FishingStates = {
	NONE = "NONE",
	CASTING = "CASTING",
	LANDING = "LANDING",
	WAITING = "WAITING",
	PULLINGLEFT = "PULLINGLEFT",
	PULLINGRIGHT = "PULLINGRIGHT",
	REELING = "REELING",
	CATCH   = "CATCH"
}

--fishPostionX is -10 to 10 (all way left  to all way right)
-- when at -10 or 10 player loses 1 line strength
-- each time fish changes direction (10% chance) player loses Hook Strength
--when fishPosition is 0 then the  player can reel in
--fishPositionY = 0 to 5 - when it is 5 you caught the fish
--anytime your lineStrength or hookStrength reaches 0 then you lose fish.
--fishStrengthMin
--fishStrengthMax
--poleStrength
--lineStrength
--hookStrength


local Hooks = {}
Hooks.__index = Hooks
Hooks.TAG_NAME = "Hook"
local hookIndex = 0

function Hooks.new(hook,player,poleStrength,lineStrength,hookStrength)
	local self = {}

	setmetatable(self, Hooks)

	hookIndex = hookIndex + 1
	
	self.ID = hookIndex
	self.part = hook
	self.player = player
	self.tag = "Hook"
	self.fishPositionX = 128
	self.fishPositionY = 150
	self.fishStrengthMin = 0
	self.fishStrengthMax = 0
	self.poleStrength = poleStrength
	self.lineStrength = lineStrength
	self.hookStrength = hookStrength
	self.currentFishDirection = 1
	self.currentPull = 0 
	self.currentPullStartTime = 0
	self.currentPullStopTime = 0
	self.hasFish = false

	return self
end

local hooks = {}

local function onTagAdded(instance)
	
	local owner = instance:GetAttribute("Owner")
	--Logger.Debug("TEST FISHING onTagAdded owner:",owner)
	local player = Players:FindFirstChild(owner)
	local tackleBox = InventoryFunctions.GetTackleBox(player)		
	
	local poleStrength = 0
	
	if (tackleBox.Rod) then
		if (itemsmodule[tackleBox.Rod]) then
			poleStrength = itemsmodule[tackleBox.Rod].Strength
		end
	end
	
	local lineStrength = 0

	if (tackleBox.Line) then
		if (itemsmodule[tackleBox.Line]) then
			lineStrength = itemsmodule[tackleBox.Line].Strength	
		end
	end

	local hookStrength = 0

	if (tackleBox.Hook) then
		if (itemsmodule[tackleBox.Hook]) then
			hookStrength = itemsmodule[tackleBox.Hook].Strength	
		end
	end
	
	local newHook = Hooks.new(instance,player,poleStrength,lineStrength,hookStrength)
	
	if (owner) then
		hooks[owner] = newHook
	end

end

local function onTagRemoved(instance)

	local owner = instance:GetAttribute("Owner")
	if (owner) then
		hooks[owner] = nil
	end
end

-- Connect to the tag added event
CollectionService:GetInstanceAddedSignal("Hook"):Connect(onTagAdded)

-- Connect to the tag removed event
CollectionService:GetInstanceRemovedSignal("Hook"):Connect(onTagRemoved)

local function Cast(player,mouse_pos)
	
	--if (not player.Character) then
	--	return
	--end
	
	--local tool = player.Character:FindFirstChild("FishingPole")

	--if (not tool) then
	--	warn("FishingPole not found for player:",player.Name)
	--	return
	--end

	--local tip = tool.FishingPoleTip
	--local bobber =  tip.bobber
	
	
	--local poleStrength = tool:GetAttribute("PoleStrength")
	--local tackleBox = InventoryFunctions.GetTackleBox(player)		
	
	
	--local lineStrength = 0
	
	--if (tackleBox.Line) then
	--	lineStrength = itemsmodule[tackleBox.Line].Strength	
	--end
	
	--local hookStrength = 0

	--if (tackleBox.Hook) then
	--	hookStrength = itemsmodule[tackleBox.Hook].Strength	
	--end
	
	----addBobber(player,bobber, bobber.CFrame.Position,poleStrength,lineStrength,hookStrength)
	
	--local hook = tip.hook
	
	--hook:SetAttribute("Owner",player.Name)
	
	--local T = 1
	
	
	--if (not tip) then
	--	return
	--end
	
	--tip.Beam.Transparency = NumberSequence.new(0)
	--tip.line2.Visible = false

	--local g = Vector3.new(0, -game.Workspace.Gravity, 0);
	--local tipHandle = player.Character.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
	--local x0 = bobber.Position --char.HumanoidRootPart.CFrame * Vector3_New(0, 0, 0) --tipHandle.TransformedCFrame.Position-- * Vector3.new(0, 2, -2)

	--player.Character.HumanoidRootPart.Anchored = true
	--player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	--player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	--player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	--player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	----NEW TEST PROPS
	----bobber.CanCollide = false
	--bobber:SetNetworkOwner(player.Character)
	--bobber.CanCollide = true;

	--bobber.Anchored = true --Only for non velocity physics handling, otherwise remove
	----END NEW TEST PROPS


	---- calculate the v0 needed to reach mouse.Hit.p

	--local v0 = (mouse_pos - x0 - 0.5*g*T*T)/T;

	----extend rope to target
	--local magnitude = (bobber.Position - mouse_pos).Magnitude
	----print(magnitude)

	--tip.line2.Length = magnitude*.05

	--local tweeningInformation = TweenInfo.new(

	--	.1, -- Length
	--	Enum.EasingStyle.Bounce, -- Easing style of the TweenInfo
	--	Enum.EasingDirection.Out, -- Easing direction of the TweenInfo
	--	0, -- Number of times the tween will repeat   
	--	false, -- Should the tween repeat?
	--	0 -- Delay between each tween  
	--)
	--local partProperties = {
	--	Length = magnitude;
	--}

	----tip.Beam.Transparency = NumberSequence.new(0)
	----tip.line2.Visible = true

	--local Tween = tweenService:Create(tip.line2,tweeningInformation,partProperties)
	--Tween:Play()

	---- have the ball travel that path
	----bobber.Velocity = v0;
	--local nt = 0;
	--while (nt < T*2) do
	--	bobber.CFrame = CFrame.new(0.5*g*nt*nt + v0*nt + x0);
	--	nt = nt + RunService.RenderStepped:Wait();
	--end
	
	
	

	----bobber.CanCollide = true;

end

function SurfaceForce(on,HRP)
	local BP = HRP:FindFirstChild("BP")
	
	if on then
		
		
		
		if (BP ~= nil) then return BP end

		BP = Instance.new("BodyPosition")
		BP.Name = "BP"
		BP.MaxForce = Vector3.new(0,0,0) --Vector3.new(0, HRP.AssemblyMass * workspace.Gravity,0) --Vector3.new(0, workspace.Gravity, 0) * playerMass* 1.6
		BP.Position = Vector3.new(0, 0, 0)
		BP.P = 400
		BP.D = 100 --10
		BP.Parent = HRP

		return BP

	else
		if BP then
			BP:Destroy()
			BP = nil
		end

	end
end

function ReelForce(on,HRP)

	local ReelForce = HRP:FindFirstChild("ReelForce")

	if on then
		if (ReelForce ~= nil) then return ReelForce end

		ReelForce = Instance.new('AlignPosition')
		ReelForce.Mode = Enum.PositionAlignmentMode.OneAttachment
		ReelForce.Name = "ReelForce"
		ReelForce.Parent = HRP
		ReelForce.Position =HRP.CFrame.Position
		ReelForce.Attachment0 = HRP.BobberAttachment


		return ReelForce
	else
		if (ReelForce) then
			ReelForce:Destroy()
			ReelForce = nil
		end

		return ReelForce

	end
end                           

function StayOnSurface(YOffset,bobber,hook)


	local force = SurfaceForce(true,bobber)
	force.MaxForce = Vector3.new(0, (bobber.AssemblyMass + hook.AssemblyMass + hook.Weights.AssemblyMass) * workspace.Gravity * 3,0)
	--Logger.Debug("CHANGING BP POSITION YOffset:  playerPositionTotalDisplacement.Y:",YOffset,playerPositionTotalDisplacement.Y)
	--force.Position =  Vector3.new(0, functions.currentWater.Position.Y + functions.playerPositionTotalDisplacement.Y + YOffset, 0)

	--if (playerExactPositionOnWave) then
	--	force.Position = Vector3.new(0,playerExactPositionOnWave.Y+YOffset,0)
	--else
	
	
	force.Position = Vector3.new(0,-31,0) --was -32
	--end



	--Logger.Debug("StayOnSurface: ", functions.currentWater.Position.Y,functions.playerPositionTotalDisplacement.Y,YOffset)

end

local function Landing(player,targetPos)

	if (not player.Character) then
		return
	end

	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end

	local tip = tool.FishingPoleTip
	local bobber =  tip.bobber
	local hook = tip.hook	

	bobber.Velocity = Vector3.new(0,0,0)
	hook.Velocity = Vector3.new(0,0,0)
	hook:SetAttribute("Owner",player.Name)
	
	
	bobber.Anchored = true
	bobber.Massless = false
	local density = 2
	local friction = 2
	local elasticity = 0
	local frictionWeight = 5
	local elasticityWeight = 0

	-- Construct new PhysicalProperties and set
	local physProperties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
	bobber.CustomPhysicalProperties = physProperties
	
	
	local weights = Instance.new("Part")
	weights.Size = Vector3.new(1,1,1)
	--Part.Transparency = 1
	weights.Name = "Weights"

	local weld = Instance.new("WeldConstraint")
	weld.Enabled = true
	weld.Part0 = hook
	weld.Part1 = weights
	weld.Parent = hook
	weights.Position = hook.Position
	weights.CanCollide = false
	density = 500
	friction = 7000
	elasticity = 1
	frictionWeight = 7000
	elasticityWeight = 1
	local physProperties2 = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
	weights.CustomPhysicalProperties = physProperties2
	weights.Parent = hook
	weights.Velocity = Vector3.new(0,0,0)
	weights.Transparency = 1
	--weights.Anchored = true
	
	bobber.Anchored = false
	bobber.Position = Vector3.new(targetPos.X,-31.8,targetPos.Z)
	
	StayOnSurface(0,bobber,hook)
	
	hook.CFrame = bobber.CFrame
	hook.CFrame = CFrame.new(Vector3.new(bobber.CFrame.Position.X,bobber.CFrame.Position.Y-3,bobber.CFrame.Position.Z))
	weights.CFrame = hook.CFrame

	--TODO update this constantly if player just moves but not when they reel in
	local tipHandle = player.Character.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
	local magnitude = (bobber.Position - tipHandle.TransformedWorldCFrame.Position).Magnitude
	tip.line2.Length = magnitude+1

	tip.Beam.Transparency =  NumberSequence.new(1)
	tip.line2.Visible = true	
	
	CollectionService:AddTag(hook, "Hook")
	
	CastEvent:FireClient(player,FishingStates.WAITING)
end

local function Reset(player)
	
	if (not player.Character) then
		return
	end

	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end

	local tip = tool.FishingPoleTip
	local bobber =  tip.bobber
	local hook = tip.hook	
	
	if (hook) then
		local oldWeights = hook:FindFirstChild("Weights")
		if oldWeights then
			oldWeights:Destroy()
		end
	end
	
	if (bobber) then
		local oldBobby = bobber:FindFirstChild("BP")
		if oldBobby then
			oldBobby:Destroy()
		end

		--bobber.lineToHook.Length = 3
	end

	bobber.Velocity = Vector3.new(0,0,0)
	hook.Velocity = Vector3.new(0,0,0)

	-- Construct new PhysicalProperties and set

	if (tip and tip.hook) then
		
		local density = .7
		local friction = .3
		local elasticity = .5
		local frictionWeight = 1
		local elasticityWeight = 1
		
		
		bobber.Massless = true
		local physProperties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
		bobber.CustomPhysicalProperties = physProperties
		
		
		local density = .01
		local friction = .1
		local elasticity = 1
		local frictionWeight = 1
		local elasticityWeight = 1
		
		local physProperties2 = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
		tip.hook.CustomPhysicalProperties = physProperties2
	end
	
	player.Character.HumanoidRootPart.Anchored = false
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)

end

local function MoveBobberTowardPlayer(player,bobber)
	local ReelForce = ReelForce(true,bobber)

	if (not ReelForce) then
		return
	end

	local playerPosition =  player.Character.HumanoidRootPart.Position
	local directionToPlayer = (playerPosition - bobber.Position).Unit
	local targetPosition = bobber.CFrame.Position + directionToPlayer * 10
	targetPosition = Vector3.new(targetPosition.X,bobber.CFrame.Position.Y,targetPosition.Z)
	
	local testPart = Instance.new("Part")
	testPart.Name = "MoveBobberTowardPlayer"
	testPart.Anchored = true
	testPart.Position = targetPosition
	testPart.Size = Vector3.new(0.5,0.5,0.5)
	testPart.Parent = workspace
	testPart.CanCollide = false
	testPart.BrickColor = BrickColor.Yellow()


	--local direction = (targetPosition - bobber.Position).Unit
	--direction = Vector3.new(direction.X,bobber.CFrame.Position.Y,direction.Z)
	--local speed = 5 -- Adjust the speed as needed

	--Would have to set this over and over
	--local dragCoefficient = 0.05
	--local drag = -1 * (ReelForce.Velocity * dragCoefficient)

	--ReelForce.Velocity = (direction * speed) --+ drag
	--targetPosition = Vector3.new(targetPosition.X,bobber.CFrame.Position.Y,targetPosition.Z)
	ReelForce.Position = (targetPosition) 

end

local function PullLeft(player,pullTime)
	if (not player.Character) then
		return
	end
	
	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end
	
	if (not hooks[player.Name]) then
		warn("hooks not found for player:",player.Name)
		return
	end
	
	--hooks[player.Name].currentPull = hooks[player.Name].currentPull - hooks[player.Name].poleStrength
	
	if (hooks[player.Name].currentPullStartTime == 0) then
		hooks[player.Name].currentPullStartTime = pullTime
		hooks[player.Name].currentPull = 0
		return
	else
		hooks[player.Name].currentPullStopTime = pullTime
		
		local diff = hooks[player.Name].currentPullStopTime - hooks[player.Name].currentPullStartTime
		
		if (diff >= .5) and (diff <= 1) then
			--Perfect hit
			hooks[player.Name].currentPull = -1 * (hooks[player.Name].poleStrength + 5) --rand:NextNumber(1,hooks[player.Name].poleStrength+5)
		elseif (diff < .2 ) then
			hooks[player.Name].currentPull = -1 * (hooks[player.Name].poleStrength) --rand:NextNumber(1,hooks[player.Name].poleStrength)
		elseif (diff < .5 ) then
			hooks[player.Name].currentPull = -1 * (hooks[player.Name].poleStrength + 3) -- rand:NextNumber(1,hooks[player.Name].poleStrength+3)
		elseif (diff > 1 ) then
			hooks[player.Name].currentPull = -1 * (hooks[player.Name].poleStrength) --rand:NextNumber(1,hooks[player.Name].poleStrength)
		end
		
		hooks[player.Name].currentPullStartTime = 0
		hooks[player.Name].currentPullStopTime = 0
		
	end
	
end

local function PullRight(player)
	if (not player.Character) then
		return
	end

	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end

	if (not hooks[player.Name]) then
		warn("hooks not found for player:",player.Name)
		return
	end

	hooks[player.Name].currentPull = hooks[player.Name].currentPull + hooks[player.Name].poleStrength

end

local function Reel(player)
	
	if (not player.Character) then
		return
	end
	
	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end
	
	local tip = tool.FishingPoleTip
	local bobber =  tip.bobber
	local hook = tip.hook	
		
	local oldBait = hook:FindFirstChild("bait")
	if oldBait then
		oldBait:Destroy()
	end
	
	--local weights = hook:FindFirstChild("Weights")
	--if weights then
	--	weights.Anchored = false
	--end

	--tip:SetNetworkOwner(nil)
	
	hook.Anchored = false  
	bobber.Anchored = false
	bobber.RigidConstraint.Enabled = false
	player.Character.HumanoidRootPart.Anchored = true
	
	MoveBobberTowardPlayer(player,bobber)
	
	tip.line2.WinchSpeed = 50
	tip.line2.WinchForce = 0 --100 --1250
	tip.line2.WinchTarget = tip.line2.Length - 10
	tip.line2.WinchEnabled = true	
	
	--local bobberDistanceFromPlayer = (bobber.Position - player.Character.HumanoidRootPart.Position).Magnitude

	--if (tip.line2.Length <= (bobberDistanceFromPlayer+1)) then
		
	--	--TODO maybe only unanchor or anything below once the line has been pulled once and is tight. so first just subtract 1 from line then next pull does winch and unanchor
	--	hook.Anchored = false  
	--	bobber.Anchored = false
	--	bobber.RigidConstraint.Enabled = false

		
	--	tip.line2.WinchSpeed = 50
	--	tip.line2.WinchForce = 100 --1250
	--	tip.line2.WinchTarget = tip.line2.Length - 10
	--	tip.line2.WinchEnabled = true	
	--else
		
	--end
	
	
	--tip.line2.Length = tip.line2.Length -1
	
	if (tip.line2.Length <=2) then
		tip.line2.WinchEnabled = false
		tip.line2.Length = 0
		Reset(player)
		CastEvent:FireClient(player,FishingStates.NONE)
	else
		task.delay(2,function()
			CastEvent:FireClient(player,FishingStates.WAITING)
		end)
		
	end
end

--Really onClick
local function onCast(player,state,mouse_pos,pullTime)
	
	
	if (state == FishingStates.CASTING) then
		--Cast(player,mouse_pos)
	elseif (state == FishingStates.PULLINGLEFT) then
		if (hooks[player.Name]) then
			if(hooks[player.Name].hasFish ~= true) then
				return
			end
		end
		PullLeft(player,pullTime)
	elseif (state == FishingStates.PULLINGRIGHT) then
		if (hooks[player.Name]) then
			if(hooks[player.Name].hasFish ~= true) then
				return
			end
		end
		PullRight(player,pullTime)
	elseif (state == FishingStates.REELING) then
		if (hooks[player.Name]) then
			if(hooks[player.Name].hasFish ~= true) then
				return
			end
		end
		Reel(player)
	elseif (state == FishingStates.LANDING) then
		Landing(player,mouse_pos)
	elseif (state == FishingStates.NONE) then
		Reset(player)
	end
	
	
	
end

CastEvent.OnServerEvent:Connect(onCast)

FishBiteServerEvent.Event:Connect(function(targetPlayer)
	if (hooks[targetPlayer.Name]) then
		hooks[targetPlayer.Name].hasFish = true
	end
end)

local hookUpdatesFrequency = 1

local lastHookCheck = os.time()


local function updateHooks()
	
	local currentTime = os.time()
	if (currentTime - lastHookCheck) < hookUpdatesFrequency then
		return
	end
	
	lastHookCheck = currentTime
	
	for _, hook in pairs(hooks) do
		if (hook.hasFish) then
			
			--local rodStrength = rand:NextNumber(0,10)
			local fishStrength = rand:NextNumber(1,6)
			
			local movement = fishStrength + hook.currentPull
			hook.currentPull = 0
			
			--if fishStrength is greater than currentPull then fish movement is positive and will go in direction of current fish direction
			
			--Default Fishing headin right position is 128,150
			local changeX = (movement*hook.currentFishDirection)
			hook.fishPositionX = hook.fishPositionX + (changeX*10)

			if (hook.player) then
				FishingUpdateEvent:FireClient(hook.player,hook.fishPositionX,hook.fishPositionY,hook.currentFishDirection)
			end
			
			
		end
	end
end

RunService.Heartbeat:Connect(updateHooks)