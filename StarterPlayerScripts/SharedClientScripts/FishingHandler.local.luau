local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
--local castRemoteFunction = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CastRemote")
local tool = nil
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local tweenService = game:GetService("TweenService")
local CastEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Cast")
local FishBiteEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FishBite")
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))
local animations = ReplicatedStorage:WaitForChild("SharedAnimations")
local FishingCasting = animations:WaitForChild("FishingCasting")
local FishingIdle = animations:WaitForChild("FishingIdle")
local FishingReeling = animations:WaitForChild("FishingReeling")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inventoryGUI = playerGui:WaitForChild("SharedGUI"):WaitForChild("VacpacGui")
local fishingGUI = playerGui:WaitForChild("SharedGUI"):WaitForChild("FishingGui")
local tackleBoxGui = inventoryGUI.TackleBox
local FishingUpdateEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FishingUpdate")
local TweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)

local reelTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)



local MouseLoc = nil
local MouseTarget = nil

local WaterLevel = -32

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

fishingState = FishingStates.NONE

local fishTarget = nil
local Attach0 = Instance.new("Attachment", workspace.Terrain)
local Attach1 = Instance.new("Attachment", workspace.Terrain)

local waterAttachments = {}

-- Documentation: devforum.roblox.com/t/modeling-a-projectiles-motion/176677
-- Full credits to EgoMoose: roblox.com/users/2155311

local PlayerS = game:GetService('Players')
local plr = PlayerS.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local Hum = char:WaitForChild('Humanoid')
local RootPart = Hum.RootPart
local Mouse = plr:GetMouse()
Mouse.TargetFilter = workspace.Zones.LakeInWater
local tip = nil
local bobber = nil
local hook = nil
local RunS = game:GetService('RunService')
local Heartbeat = RunS.Heartbeat

local fishingCastingTrack = Hum:LoadAnimation(FishingCasting)
local fishingIdleTrack = Hum:LoadAnimation(FishingIdle)
local fishingReelingTrack = Hum:LoadAnimation(FishingReeling)

local CFrame_New = CFrame.new
local Vector3_New = Vector3.new

local T = 1;

local Gravity = Vector3_New(0, -workspace.Gravity, 0)

local Beam = nil
local HeartbeatConnection = nil
local BobberTouchedConnection = nil
local bobberSplash = Vector3.new(0,0,0)

plr.CharacterAdded:Connect(function(character)
	char = character
	Hum = char:WaitForChild('Humanoid')
	RootPart = Hum.RootPart
end)

local function BeamProjectile_Func(V0, X0, T1)
	-- calculate the bezier points
	local C = 0.5*0.5*0.5;
	local P3 = 0.5*Gravity*T1*T1 + V0*T1 + X0;
	local P2 = P3 - (Gravity*T1*T1 + V0*T1)/3;
	local P1 = (C*Gravity*T1*T1 + 0.5*V0*T1 + X0 - C*(X0+P3))/(3*C) - P2;

	-- the curve sizes
	local Curve0 = (P1 - X0).magnitude;
	local Curve1 = (P2 - P3).magnitude;

	-- build the world CFrames for the attachments
	local B = (X0 - P3).unit;
	local R1 = (P1 - X0).unit;
	local U1 = R1:Cross(B).unit;
	local R2 = (P2 - P3).unit;
	local U2 = R2:Cross(B).unit;
	B = U1:Cross(R1).unit;

	local CF1 = CFrame_New(
		X0.x, X0.y, X0.z,
		R1.x, U1.x, B.x,
		R1.y, U1.y, B.y,
		R1.z, U1.z, B.z
	)

	local CF2 = CFrame_New(
		P3.x, P3.y, P3.z,
		R2.x, U2.x, B.x,
		R2.y, U2.y, B.y,
		R2.z, U2.z, B.z
	)

	return Curve0, -Curve1, CF1, CF2;
end

local function getMouseTarget()
	local mouseLocation = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local rayOrigin = mouseRay.Origin
	local rayDirection = mouseRay.Direction * 1000 -- Ray length

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace.Zones}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		if (raycastResult.Material == Enum.Material.Water) then
			return raycastResult.Instance
		else
			return nil
		end
		
	else
		return nil
	end
end

local function getMouseHitPosition()
	local mouseLocation = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local rayOrigin = mouseRay.Origin
	local rayDirection = mouseRay.Direction * 1000 -- Ray length

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace.Zones}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		return raycastResult.Position
	else
		return nil
	end
end

local function Beam_Func()

	if not toolEquipped
	then
		return
	end

	if not (fishingState == FishingStates.NONE) then
		Beam.Transparency = NumberSequence.new(1)
		return
	end
	
	local mouseTarget = getMouseTarget()
	
	if not mouseTarget then

		Beam.Transparency = NumberSequence.new(1)
		return
	end

	Beam.Transparency = NumberSequence.new(0.3)

	local tipHandle = char.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
	local X0 = bobber.Position --char.HumanoidRootPart.CFrame * Vector3_New(0, 0, 0) --tipHandle.TransformedCFrame.Position-- * Vector3.new(0, 2, -2)

	local V0 = (getMouseHitPosition() - X0 - 0.5*Gravity*T*T)/T;

	local Curve0, Curve1, CF1, CF2 = BeamProjectile_Func(V0, X0, T);
	Beam.CurveSize0 = Curve0;
	Beam.CurveSize1 = Curve1;
	-- convert world space CFrames to be relative to the attachment parent
	Attach0.CFrame = Attach0.Parent.CFrame:inverse() * CF1;
	Attach1.CFrame = Attach1.Parent.CFrame:inverse() * CF2;	
end



function GetPointOnWave(closestBones, targetPoint)
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

local closestBones = {}
local closestDistances = {}
local function SetBobberOnWave()
	
	closestBones = {}
	closestDistances = {}
	
	for bone, bonePosition in pairs(waterAttachments) do
		local boneDist = (bonePosition - bobber.Position).Magnitude
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
	
	
	bobber.Position = GetPointOnWave(closestBones, bobber.Position)
	
	--TODO maybe replace with stayonsurface
	--TODO stayonsurface then slowly move to position of closesBones[1] then attach
	bobber.RigidConstraint.Attachment0 = bobber.BobberAttachment
	bobber.RigidConstraint.Attachment1 = closestBones[1]
	
end


local function SetBobberToClosestWaterPoint()
	
	
	bobber.Anchored = true
	bobber.Velocity = Vector3.new(0,0,0)
	
	bobber.Position = Vector3.new(bobber.Position.X,WaterLevel,bobber.Position.Z)
	
	--loop through waterAttchments to find bone closest to bobber position then attach bobber to the bone
	local closestBone = nil
	local closestDistance = 99999
	for bone, bonePosition in pairs(waterAttachments) do
		local distance = (bonePosition - bobber.Position).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestBone = bone
		end
	end

	--Attach bobber to closest water point (bone)
	--bobber.RigidConstraint.Attachment0 = bobber.BobberAttachment
	--bobber.RigidConstraint.Attachment1 = closestBone
	
	--bobber.Anchored = false
	
end

local function HandleBobberLanding()
	if ((fishingState == FishingStates.CASTING)) then
		
		ChangeState(FishingStates.LANDING)

		--anchor bobber
		--bobber.Anchored = true

		bobber.Velocity = Vector3.new(0,0,0)
		hook.Velocity = Vector3.new(0,0,0)
		--SetBobberOnWave()
		--SetBobberToClosestWaterPoint()
		--bobber.Position = Vector3.new(bobber.Position.X,otherPart.Position.Y+otherPart.Size.Y/2,bobber.Position.Z)	
		--bobberSplash = Vector3.new(bobber.Position.X,otherPart.Position.Y+otherPart.Size.Y/2,bobber.Position.Z)

		--local weights = 20
		--bobber.lineToHook.Length = weights --depends on weights to get lower/larger fish

		--TODO update this constantly if player just moves but not when they reel in
		local tipHandle = char.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
		local magnitude = (bobber.Position - tipHandle.TransformedWorldCFrame.Position).Magnitude
		tip.line2.Length = magnitude+1

		tip.Beam.Transparency =  NumberSequence.new(1)
		tip.line2.Visible = true

		-- and lower hook line
		--local hookLineTweenProperties = {Length = 20;}
		--local hookLineTweenInformation = TweenInfo.new(2, Enum.EasingStyle.Bounce,Enum.EasingDirection.Out, 0,false, 0 )	
		--local hookLineTween = tweenService:Create(bobber.lineToHook,hookLineTweenInformation,hookLineTweenProperties)
		--hookLineTween:Play()
		--hookLineTween.Completed:wait()


		--local oldBobby = bobber:FindFirstChild("bobby")
		--if oldBobby then
		--	oldBobby:Destroy()
		--end



		--local bobby = Instance.new("BodyPosition")
		--bobby.Name = "bobby"
		--bobby.MaxForce = Vector3.new(10,10,10)
		--bobby.Position = bobber.Position
		--bobby.Parent = bobber

		--hook.Position = Vector3.new(bobber.Position.X,bobber.Position.Y-weights,bobber.Position.Z)
		--hook.Anchored = true

		local density = 1
		local friction = .1
		local elasticity = 1
		local frictionWeight = 1
		local elasticityWeight = 1

		-- Construct new PhysicalProperties and set
		local physProperties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
		tip.hook.CustomPhysicalProperties = physProperties

		local bait = Instance.new("Part")
		bait.Shape = Enum.PartType.Ball
		bait.Size = Vector3.new(18,18,18) --size of bait effects chance of fish getting caught
		bait.Transparency = 1
		bait.Name = "bait"
		bait.Anchored = true
		bait.Parent = hook
		bait.Position = tip.hook.Position
		bait.CanCollide = false
		bait.Massless = true


		ChangeState(FishingStates.WAITING)



	end
end

local function HandleHeartbeat()
	
	--Check if bobber is below workspace.Plane.FishingArea
	if (bobber.Position.Y < WaterLevel) then
		
		if (fishingState == FishingStates.CASTING) then
			ChangeState(FishingStates.LANDING)
			--SetBobberOnWave()
			CastEvent:FireServer(fishingState,bobber.Position)
		end
		
		--HandleBobberLanding()
		
		
	end

	Beam_Func()
end

--local function Reset()
	
--	if (bobber) then
--		local oldBobby = bobber:FindFirstChild("BP")
--		if oldBobby then

--			oldBobby:Destroy()
--		end

--		--bobber.lineToHook.Length = 3
--	end
	
--	--if (bobber) then
--	--	local oldBobby = bobber:FindFirstChild("bobby")
--	--	if oldBobby then

--	--		oldBobby:Destroy()
--	--	end

--	--	bobber.lineToHook.Length = 1
--	--end

--	local density = .01
--	local friction = .1
--	local elasticity = 1
--	local frictionWeight = 1
--	local elasticityWeight = 1
	
--	bobber.Velocity = Vector3.new(0,0,0)
--	hook.Velocity = Vector3.new(0,0,0)

--	-- Construct new PhysicalProperties and set
	
--	if (tip and tip.hook) then
--		local physProperties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
--		tip.hook.CustomPhysicalProperties = physProperties
--	end

--end

CastEvent.OnClientEvent:Connect(function(state)
	if (state == FishingStates.NONE) then
		ChangeState(FishingStates.NONE)
		
	elseif (state == FishingStates.WAITING) then
		PlayerState.ChangeState(PlayerState.States.FishingIdle)

		ChangeState(FishingStates.WAITING)
	end
end)

local function Cast(player,mouse_pos)
	
	local tool = player.Character:FindFirstChild("FishingPole")

	if (not tool) then
		warn("FishingPole not found for player:",player.Name)
		return
	end

	local tip = tool.FishingPoleTip
	local bobber =  tip.bobber
	
	--TODO do on server side
	--addBobber(player,bobber, bobber.CFrame.Position)

	local hook = tip.hook
	hook.Anchored = false

	hook:SetAttribute("Owner",player.Name)

	local T = 1

	if (not tip) then
		return
	end

	tip.Beam.Transparency = NumberSequence.new(0)
	tip.line2.Visible = false

	local g = Vector3.new(0, -game.Workspace.Gravity, 0);
	local tipHandle = player.Character.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
	local x0 = bobber.Position --char.HumanoidRootPart.CFrame * Vector3_New(0, 0, 0) --tipHandle.TransformedCFrame.Position-- * Vector3.new(0, 2, -2)

	player.Character.HumanoidRootPart.Anchored = true

	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	--NEW TEST PROPS
	--bobber.CanCollide = false
	--bobber:SetNetworkOwner(player.Character)
	bobber.CanCollide = true;

	bobber.Anchored = true --Only for non velocity physics handling, otherwise remove
	--END NEW TEST PROPS


	-- calculate the v0 needed to reach mouse.Hit.p

	local v0 = (mouse_pos - x0 - 0.5*g*T*T)/T;

	--extend rope to target
	local magnitude = (bobber.Position - mouse_pos).Magnitude
	--print(magnitude)
	
	tip.line2.Length = magnitude*.05

	local tweeningInformation = TweenInfo.new(

		.1, -- Length
		Enum.EasingStyle.Bounce, -- Easing style of the TweenInfo
		Enum.EasingDirection.Out, -- Easing direction of the TweenInfo
		0, -- Number of times the tween will repeat   
		false, -- Should the tween repeat?
		0 -- Delay between each tween  
	)
	local partProperties = {
		Length = magnitude;
	}

	--tip.Beam.Transparency = NumberSequence.new(0)
	--tip.line2.Visible = true

	local Tween = tweenService:Create(tip.line2,tweeningInformation,partProperties)
	Tween:Play()

	-- have the ball travel that path
	--bobber.Velocity = v0;
	local nt = 0;
	while (nt < T*2) do
		bobber.CFrame = CFrame.new(0.5*g*nt*nt + v0*nt + x0);
		hook.CFrame = CFrame.new(0.5*g*nt*nt + v0*nt + x0);
		if (bobber.Position.Y < WaterLevel) then
			tip.Beam.Transparency = NumberSequence.new(1)
			tip.line2.Visible = true
			break
		end
		nt = nt + RunService.RenderStepped:Wait();
	end

	
	fishingGUI.Frame.Hook.Visible = true

	--bobber.CanCollide = true;

end

local pullLeftStart = false
local pullRightStart = false
local pullTween = nil

local function HandlePulling(actionName, userInputState, input)

	if (userInputState == Enum.UserInputState.Begin) then
		if ((fishingState == FishingStates.WAITING) or (fishingState == FishingStates.PULLINGLEFT) or (fishingState == FishingStates.PULLINGRIGHT)) then

			if (actionName == "PullLeft") then
				--PlayerState.ChangeState(PlayerState.States.FishingPullLeft)

				ChangeState(FishingStates.PULLINGLEFT)

				local targetPos = Mouse.Hit.p
				
				if (not pullLeftStart) then
					pullLeftStart = true
					fishingGUI.Frame.ReelIndicator.Position = UDim2.new(.3,0,.1,0)

					pullTween = TweenService:Create(fishingGUI.Frame.ReelIndicator, reelTweenInfo, {Position = UDim2.new(.1,0,.1,0);})

					pullTween:Play()

				else
					pullLeftStart = false
					pullTween:Cancel()
				end

				CastEvent:FireServer(fishingState,targetPos,time())

				return Enum.ContextActionResult.Pass
				
			else
				--PlayerState.ChangeState(PlayerState.States.FishingPullRight)

				ChangeState(FishingStates.PULLINGRIGHT)

				local targetPos = Mouse.Hit.p
				
				if (not pullRightStart) then
					pullRightStart = true
					fishingGUI.Frame.ReelIndicator.Position = UDim2.new(.1,0,.1,0)
					
					pullTween = TweenService:Create(fishingGUI.Frame.ReelIndicator, reelTweenInfo, {Position = UDim2.new(.3,0,.1,0);})

					pullTween:Play()

				else
					pullRightStart = false
					pullTween:Cancel()
				end

				CastEvent:FireServer(fishingState,targetPos,time())

				return Enum.ContextActionResult.Pass
			end
		end
	end

	return Enum.ContextActionResult.Pass
end

local function HandleReeling(actionName, userInputState, input)

	if (userInputState == Enum.UserInputState.Begin) then
		if (fishingState == FishingStates.WAITING) then
			
			PlayerState.ChangeState(PlayerState.States.FishingReeling)

			ChangeState(FishingStates.REELING)

			local targetPos = Mouse.Hit.p

			--Cast(targetPos)
			CastEvent:FireServer(fishingState,targetPos)

			return Enum.ContextActionResult.Pass
		end
	end
	
	return Enum.ContextActionResult.Pass
end

local function HandleAction(actionName, userInputState, input)
	
	if (userInputState == Enum.UserInputState.Begin) then
		
		if (not player.Character) then
			return
		end

		if(tackleBoxGui.ItemSlots.Slots.Rod.ItemName.Text == "") then
			GuiMessageFunctions.DisplayOnScreenMessage("Tacklebox missing Rod")
			return
		end

		if(tackleBoxGui.ItemSlots.Slots.Slot1.ItemName.Text == "") then
			GuiMessageFunctions.DisplayOnScreenMessage("Tacklebox missing Bait")
			return
		end

		if(tackleBoxGui.ItemSlots.Slots.Slot2.ItemName.Text == "") then
			GuiMessageFunctions.DisplayOnScreenMessage("Tacklebox missing Hook")
			return
		end

		if(tackleBoxGui.ItemSlots.Slots.Slot3.ItemName.Text == "") then
			GuiMessageFunctions.DisplayOnScreenMessage("Tacklebox missing Line")
			return
		end

		local tool = player.Character:FindFirstChild("FishingPole")

		if (not tool) then
			warn("FishingPole not found for player:",player.Name)
			return
		end
		
		if (fishingState == FishingStates.NONE) then

			if (fishTarget)
			then
				return
			end

			local mouseTarget = getMouseTarget()


			if(not mouseTarget) then
				return
			end


			local fishingCastingTrackConnection = nil
			local fishingStartCastingTrackConnection = nil

			ChangeState(FishingStates.CASTING)

			local targetPos = getMouseHitPosition()
			
			fishingStartCastingTrackConnection = PlayerState.States.FishingCasting.Animation:GetMarkerReachedSignal("StartCast"):Connect(function()

				--CastEvent:FireServer(fishingState,targetPos)
				Cast(plr,targetPos)

				if (fishingStartCastingTrackConnection) then
					fishingStartCastingTrackConnection:Disconnect()
				end
			end)

			
			fishingCastingTrackConnection = PlayerState.States.FishingCasting.Animation:GetMarkerReachedSignal("EndCast"):Connect(function()

				PlayerState.ChangeState(PlayerState.States.FishingIdle)

				if (fishingCastingTrackConnection) then
					fishingCastingTrackConnection:Disconnect()
				end
			end)

			PlayerState.ChangeState(PlayerState.States.FishingCasting)

		end
	end
	
	return Enum.ContextActionResult.Pass
end


local function SetupFishing()
	tool = plr.Character:FindFirstChild("FishingPole")
	
	if (not tool) then
		warn("FishingPole not found for player:",plr.Name)
		return
	end
	
	tip = tool.FishingPoleTip
	bobber =  tip.bobber
	hook = tip.hook
	
	--NEW
	bobber.Anchored = true
	hook.Anchored = true

	bobber.Position = char.HumanoidRootPart.Position --tipHandle.TransformedCFrame.Position --tip.Position
	hook.Position = char.HumanoidRootPart.Position
	
	bobber.Anchored = false
	hook.Anchored = false
	
	--tip.line2.Enabled = true
	--bobber.lineToHook.Enabled = true
	--NEW
	
	MouseLoc = tool:WaitForChild("MouseLoc")
	MouseTarget = tool:WaitForChild("MouseTarget")
	
	Beam = Instance.new("Beam", workspace.Terrain)
	Beam.Width0 = .4
	Beam.Width1 = .4
	local colorSequence = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)), -- green
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)), -- red
	}
	)
	Beam.Color = colorSequence
	Beam.Attachment0, Beam.Attachment1 = Attach0, Attach1

	game:GetService("ContextActionService"):BindAction("HandleAction", HandleAction, false, Enum.KeyCode.R)
	game:GetService("ContextActionService"):BindAction("HandleReeling", HandleReeling, false, Enum.KeyCode.S)
	game:GetService("ContextActionService"):BindAction("PullLeft", HandlePulling, false, Enum.KeyCode.A)
	game:GetService("ContextActionService"):BindAction("PullRight", HandlePulling, false, Enum.KeyCode.D)
	
	fishingGUI.Enabled = true

	
	HeartbeatConnection = Heartbeat:Connect(HandleHeartbeat)
end

local function EndFishing()
	
	fishingGUI.Enabled = false
	fishingGUI.Frame.Hook.Visible = false
	fishingGUI.Frame.HookWithFish.Visible = false

	game:GetService("ContextActionService"):UnbindAction("HandleAction")
	game:GetService("ContextActionService"):UnbindAction("HandleReeling")
	game:GetService("ContextActionService"):UnbindAction("PullLeft")
	game:GetService("ContextActionService"):UnbindAction("PullRight")


	tool = nil
	tip = nil
	bobber = nil
	MouseLoc = nil
	MouseTarget = nil
	
	if (Beam) then
		Beam:Destroy()
	end
	
	Beam = nil
	
	--if (Attach0) then
	--	Attach0:Destroy()
	--	Attach0 = nil
	--end
	
	--if (Attach1) then
	--	Attach1:Destroy()
	--	Attach1 = nil
	--end
	
	if (HeartbeatConnection) then
		HeartbeatConnection:Disconnect()
	end
	
	if (BobberTouchedConnection) then
		BobberTouchedConnection:Disconnect()
	end
	
	--Reset()
	
	plr.Character.HumanoidRootPart.Anchored = false
	
	CastEvent:FireServer(FishingStates.NONE,nil)
	
	if (PlayerState.InWater) then
		--PlayerState.ChangeState(PlayerState.States.SurfaceSwimmingIdle)
	else
		PlayerState.ChangeState(PlayerState.States.Idle)
	end
	

	ChangeState(FishingStates.NONE)
	
	plr.Character.HumanoidRootPart.Anchored = false
	plr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	plr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	plr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	plr.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
end

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName,slot)
	if (toolName == "FishingPole") then
		toolEquipped = true
		SetupFishing()
	else
		toolEquipped = false
		EndFishing()
	end
end)




function ChangeState(state)

	Logger.Debug("TEST FISHING STATE CHANGE FROM:"..fishingState.." to: "..state)
	fishingState = state

end

FishBiteEvent.OnClientEvent:Connect(function()
	fishingGUI.Frame.Hook.Visible = false
	fishingGUI.Frame.HookWithFish.Visible = true
end)

FishingUpdateEvent.OnClientEvent:Connect((function(fishPositionX,fishPositionY,currentFishDirection)
	if (currentFishDirection == 1) then
		fishingGUI.Frame.HookWithFishRight.Visible = true
		fishingGUI.Frame.HookWithFish.Visible = false
		
		local tween = TweenService:Create(fishingGUI.Frame.HookWithFishRight, tweenInfo, {Position = UDim2.new(0,fishPositionX,0,fishPositionY);})

		tween:Play()
	else
		fishingGUI.Frame.HookWithFish.Visible = true
		fishingGUI.Frame.HookWithFishRight.Visible = false
		
		local tween = TweenService:Create(fishingGUI.Frame.HookWithFish, tweenInfo, {Position = UDim2.new(0,fishPositionX,0,fishPositionY);})
		
		tween:Play()
	end
	
		

end))

--local function Cast(mouse_pos)
	
--	if (not tip) then
--		return
--	end
	
--	local g = Vector3.new(0, -game.Workspace.Gravity, 0);
--	local tipHandle = char.HumanoidRootPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"]["mixamorig:RightForeArm"]["mixamorig:RightHand"]["FishingPoleHandle"]["FishingPoleTipHandle"]
--	local x0 = bobber.Position --char.HumanoidRootPart.CFrame * Vector3_New(0, 0, 0) --tipHandle.TransformedCFrame.Position-- * Vector3.new(0, 2, -2)
	
--	--char.HumanoidRootPart.Anchored = true
--	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
--	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
--	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
--	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	
--	--NEW TEST PROPS
--	--bobber.CanCollide = false
--	bobber:SetNetworkOwner(plr)

--	--END NEW TEST PROPS

	
--	-- calculate the v0 needed to reach mouse.Hit.p

--	local v0 = (mouse_pos - x0 - 0.5*g*T*T)/T;
	
--	--extend rope to target
--	local magnitude = (bobber.Position - mouse_pos).Magnitude
--	--print(magnitude)

--	tip.line2.Length = magnitude*.05
	
--	--tip.line2.Length = 10
	
--	--TODO REMOVE
--	--magnitude = 20

--	local tweeningInformation = TweenInfo.new(

--		.1, -- Length
--		Enum.EasingStyle.Bounce, -- Easing style of the TweenInfo
--		Enum.EasingDirection.Out, -- Easing direction of the TweenInfo
--		0, -- Number of times the tween will repeat   
--		false, -- Should the tween repeat?
--		0 -- Delay between each tween  
--	)
--	local partProperties = {
--		Length = magnitude;
--	}

--	tip.Beam.Transparency = NumberSequence.new(0)
--	tip.line2.Visible = true

--	local Tween = tweenService:Create(tip.line2,tweeningInformation,partProperties)
--	Tween:Play()


	
--	-- have the ball travel that path
--	bobber.Velocity = v0;
--	--bobber.CFrame = CFrame.new(x0);
--	--bobber.CanCollide = true;
--	--bobber.Parent = game.Workspace;
--end