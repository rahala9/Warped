local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))

local functions = {
	BP = nil,
	BV = nil,
	BG = nil,
	waterY = -32, -- same as waterY.  Was -1 * math.huge,
	playerPositionTotalDisplacement = Vector3.new(0,0,0),
	CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0},
	lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0},
	SPEED = 0,
	currentWater = nil,
	originalHipHeight = 4,
	SurfaceSwimmingYOffset = 1, --1.3, --1.5
	SurfaceSwimmingIdleYOffset = -1, -- -.5
}

--functions.currentWater = ReplicatedStorage.WaterParts:WaitForChild("Water"):WaitForChild("Plane"):Clone()
--functions.currentWater.Parent = workspace

--TODO attach buoy and other surface floating items
--3031
--local buoy = workspace:WaitForChild("Areas"):WaitForChild("Lake"):WaitForChild("Buoy")
--buoy:SetPrimaryPartCFrame(functions.currentWater["3031"].WorldCFrame)
--buoy.PrimaryPart.WaterRigidConstraint.Attachment1 = functions.currentWater["3031"]


--local lilly6 = ReplicatedStorage:WaitForChild("Lillies"):WaitForChild("Lillies1"):Clone()
--lilly6:SetPrimaryPartCFrame(functions.currentWater["3090"].WorldCFrame)
--lilly6.PrimaryPart.WaterRigidConstraint.Attachment1 = functions.currentWater["3090"]
--lilly6.Parent = workspace:WaitForChild("Areas"):WaitForChild("Lake"):WaitForChild("SurfaceItems")

--local lilly8 = ReplicatedStorage:WaitForChild("Lillies"):WaitForChild("Lillies1"):Clone()
--lilly8:SetPrimaryPartCFrame(functions.currentWater["3028"].WorldCFrame)
--lilly8.PrimaryPart.WaterRigidConstraint.Attachment1 = functions.currentWater["3028"]
--lilly8.Parent = workspace:WaitForChild("Areas"):WaitForChild("Lake"):WaitForChild("SurfaceItems")


--local lilly10 = ReplicatedStorage:WaitForChild("Lillies"):WaitForChild("Lillies1"):Clone()
--lilly10:SetPrimaryPartCFrame(functions.currentWater["2972"].WorldCFrame)
--lilly10.PrimaryPart.WaterRigidConstraint.Attachment1 = functions.currentWater["2972"]
--lilly10.Parent = workspace:WaitForChild("Areas"):WaitForChild("Lake"):WaitForChild("SurfaceItems")

--currentWater:SetNetworkOwner(nil)

local SaltWaterDensity = 1025 --kg/m^3
local LakeWaterDensity = 1000 --kg/m^3
local AverageHumanVolume = 0.062 --m^3

function functions.GetCurrentWater()
	return functions.currentWater
end

function functions.EnableStates(enabled,humanoid)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) --Always false
end

function functions.Align(on,HRP)

	if on then
		if (functions.AP ~= nil) then return functions.AP end

		functions.AP = Instance.new("AlignPosition")
		functions.AP.Position = Vector3.new(0, 0, 0)
		functions.AP.RigidityEnabled = false
		functions.AP.MaxForce = math.huge
		functions.AP.Responsiveness = 50 -- increase for snappier movement
		functions.AP.ApplyAtCenterOfMass = true
		functions.AP.Parent = HRP

		return functions.AP

	else
		if functions.AP then
			functions.AP:Destroy()
			functions.AP = nil
		end

	end
end

function functions.SurfaceForce(on,HRP)

	if on then
		if (functions.BP ~= nil) then return functions.BP end

		functions.BP = Instance.new("BodyPosition")
		functions.BP.MaxForce = Vector3.new(0,0,0) --Vector3.new(0, HRP.AssemblyMass * workspace.Gravity,0) --Vector3.new(0, workspace.Gravity, 0) * playerMass* 1.6
		functions.BP.Position = Vector3.new(0, 0, 0)
		functions.BP.P = 400
		functions.BP.D = 10
		functions.BP.Parent = HRP

		return functions.BP

	else
		if functions.BP then
			functions.BP:Destroy()
			functions.BP = nil
		end

	end
end

function functions.SwimControlForce(on,HRP)

	if on then
		if (functions.BV ~= nil) then return end

		functions.BV = Instance.new('BodyVelocity')
		functions.BV.Parent = HRP
		functions.BV.velocity = Vector3.new(0, 0, 0)
		
		--local mass = HRP.AssemblyMass
		--local hoverForce = mass * 196.2
		--local swimUpForce = hoverForce + 500 
		
		functions.BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

	else
		if (functions.BV) then
			functions.BV.velocity = Vector3.new(0, 0, 0)
			HRP.Velocity = Vector3.new(0, 0, 0)
			functions.BV:Destroy()
			functions.BV = nil
		end

	end
end

function functions.SwimStabilityForce(on,HRP)

	if on then
		if (functions.BG ~= nil) then return end

		functions.BG = Instance.new('BodyGyro')
		functions.BG.P = 9e4
		functions.BG.Parent = HRP
		functions.BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		functions.BG.cframe = HRP.CFrame

	else
		if (functions.BG) then
			functions.BG:Destroy()
			functions.BG = nil
		end
	end
end

function functions.TreadWater(HRP)
	local force = functions.SurfaceForce(true,HRP)
	force.MaxForce = Vector3.new(0, SaltWaterDensity * AverageHumanVolume * workspace.Gravity,0) --force.MaxForce = Vector3.new(0, HRP.AssemblyMass * workspace.Gravity * 1.25,0)
	force.Position = HRP.Position
end

function functions.Surface(HRP)

	--BV.velocity = Vector3.new(BV.velocity.X, .5,BV.velocity.Z)

	local force = functions.SurfaceForce(true,HRP)
	force.MaxForce = Vector3.new(0, SaltWaterDensity * AverageHumanVolume * workspace.Gravity,0) --force.MaxForce = Vector3.new(0, HRP.AssemblyMass * workspace.Gravity * 1.25,0)
	force.Position = Vector3.new(0, functions.waterY + functions.playerPositionTotalDisplacement.Y -.5, 0)
	--HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0) --prevents drifting inside water			
end

function functions.StayOnSurface(YOffset,HRP)


	local force = functions.SurfaceForce(true,HRP)
	force.MaxForce = Vector3.new(0, HRP.AssemblyMass * workspace.Gravity * 3,0)

	--force.Position =  Vector3.new(0, functions.waterY + functions.playerPositionTotalDisplacement.Y + YOffset, 0)
	
	if (functions.playerExactPositionOnWave) then
		force.Position = Vector3.new(0,functions.playerExactPositionOnWave.Y+YOffset,0)
	else
		force.Position = Vector3.new(0,functions.waterY+YOffset,0) --force.Position = Vector3.new(0,functions.currentWater.Position.Y+YOffset,0)
	end
	
end

function functions.DiveUnderSurface(YOffset,HRP)


	local force = functions.SurfaceForce(true,HRP)
	force.MaxForce = Vector3.new(0, workspace.Gravity * 3,0)

	force.Position = Vector3.new(0,functions.waterY+YOffset,0)

end

local HoldingEdge = nil

function SetEdge(edge,HRP)

	local closestEdge = nil

	for i, v in pairs(edge:GetChildren()) do 
		if v:IsA('Attachment') then 
			if (closestEdge == nil) then
				closestEdge = v
			else
				local distanceCurrentClosestEdge = (HRP.CFrame.Position - closestEdge.WorldCFrame.Position).Magnitude
				local distanceNewEdge = (HRP.CFrame.Position - v.WorldCFrame.Position).Magnitude

				if (distanceNewEdge < distanceCurrentClosestEdge) then
					closestEdge = v
				end
			end
		end 
	end

	HoldingEdge = closestEdge
end

function GetPositionInFrontOfPlayer(offset,HRP)
	local playerPos = HRP.Position
	local playerRot = HRP.Rotation
	local frontPosition =  playerPos + HRP.CFrame.LookVector * 3
	return frontPosition
end

function CheckNearEdge(char,HRP)
	--Do we have the edge of something in front of us?

	local checkPosition = HRP.CFrame * CFrame.new(Vector3.new(0,5,-3))

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {char}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local Raycast = workspace:Raycast(checkPosition.Position, Vector3.new(0,-500,0), params)

	if Raycast then
		local HitPart = Raycast.Instance

		if (HitPart ~= nil) then

			if (HitPart:GetAttribute("EdgeGrab")) then

				--Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
				functions.SetEdge(HitPart)

				if (HoldingEdge) then
					HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)	


					local offset = Vector3.new(0, 0, -3) -- you can change this offset as per your requirement
					local attachmentPos = HoldingEdge.WorldCFrame.Position + Vector3.new(0,-1.1,0)
					local newHumanoidPos = attachmentPos + HoldingEdge.WorldCFrame.lookVector * offset

					local weld = Instance.new("WeldConstraint")
					weld.Name = "EdgeWeld"
					weld.Part0 = HRP
					weld.Part1 = HoldingEdge.Parent


					functions.SurfaceForce(false,HRP)
					HRP.CFrame = CFrame.new(newHumanoidPos, attachmentPos)
					weld.Parent = HRP

					--TweenService:Create(HRP, tweenInfo, {CFrame = CFrame.new(newHumanoidPos, attachmentPos)}):Play()

				end

				--functions.HoldEdge()
				--ChangeState(States.HoldingEdge)



			else
				Logger.WarnWithTrace("EdgeTest Found something else not edge")
			end

		end

	end

end

local SWIM_SPEED = .5
local BOOST_SPEED = 1

local swimSpeed = SWIM_SPEED
local keyDown = nil
local keyUp = nil

local function SwimFast(actionName, userInputState, input) 	

	if (userInputState == Enum.UserInputState.Begin) then

		--to unfreeze
		--ContextActionService:UnbindAction(FREEZE_ACTION)

		swimSpeed = BOOST_SPEED

	elseif(userInputState == Enum.UserInputState.End) then
		swimSpeed = SWIM_SPEED
	end
end

function functions.BindControl()
	game:GetService("ContextActionService"):BindAction("SwimFast", SwimFast, false, Enum.KeyCode.LeftShift)
end

function functions.UnbindControl()
	game:GetService("ContextActionService"):UnbindAction("SwimFast", SwimFast, false, Enum.KeyCode.LeftShift)
end

function functions.SwimControl(mouse)
	Logger.Debug("SwimmingFunctions.SwimControl called")
	
	if (PlayerState.IsSprinting) then
		swimSpeed = BOOST_SPEED
	else
		swimSpeed = SWIM_SPEED
	end
	
	if (game.UserInputService:IsKeyDown(Enum.KeyCode.W)) then
		functions.CONTROL.F = swimSpeed
	else
		functions.CONTROL.F = 0
	end

	keyDown = mouse.KeyDown:Connect(function(KEY)
		if KEY:lower() == 'w' then
			functions.CONTROL.F = swimSpeed
		elseif KEY:lower() == 's' then
			functions.CONTROL.B = - swimSpeed
		elseif KEY:lower() == 'a' then
			functions.CONTROL.L = - swimSpeed
		elseif KEY:lower() == 'd' then 
			functions.CONTROL.R = swimSpeed
		--elseif QEfly and KEY:lower() == 'e' then
		--	functions.CONTROL.Q = swimSpeed*2
		--elseif QEfly and KEY:lower() == 'q' then
		--	functions.CONTROL.E = -swimSpeed*2
		end
		pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
	end)
	keyUp = mouse.KeyUp:Connect(function(KEY)
		if KEY:lower() == 'w' then
			functions.CONTROL.F = 0
		elseif KEY:lower() == 's' then
			functions.CONTROL.B = 0
		elseif KEY:lower() == 'a' then
			functions.CONTROL.L = 0
		elseif KEY:lower() == 'd' then
			functions.CONTROL.R = 0
		elseif KEY:lower() == 'e' then
			functions.CONTROL.Q = 0
		elseif KEY:lower() == 'q' then
			functions.CONTROL.E = 0
		end
	end)
end

function functions.StopSwimming(humanoid,HRP)
	if (keyDown) then
		keyDown:Disconnect()
	end
	if (keyUp) then
		keyUp:Disconnect()
	end
	
	functions.EnableStates(true,humanoid)

	functions.SurfaceForce(false,HRP)
	functions.SwimControlForce(false,HRP)
	functions.SwimStabilityForce(false,HRP)
	
	humanoid.PlatformStand = false
	
end

function functions.SwimHandler(char,humanoid,HRP)

	char.Humanoid.HipHeight = functions.originalHipHeight	

	if humanoid then
		humanoid.PlatformStand = true
	end
	if functions.CONTROL.L + functions.CONTROL.R ~= 0 or functions.CONTROL.F + functions.CONTROL.B ~= 0 or functions.CONTROL.Q + functions.CONTROL.E ~= 0 then
		functions.SPEED = 50 * swimSpeed
	elseif not (functions.CONTROL.L + functions.CONTROL.R ~= 0 or functions.CONTROL.F + functions.CONTROL.B ~= 0 or functions.CONTROL.Q + functions.CONTROL.E ~= 0) and functions.SPEED ~= 0 then
		functions.SPEED = 0
	end

	if (functions.BV ~= nil) then
		if (functions.CONTROL.L + functions.CONTROL.R) ~= 0 or (functions.CONTROL.F + functions.CONTROL.B) ~= 0 or (functions.CONTROL.Q + functions.CONTROL.E) ~= 0 then
			functions.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (functions.CONTROL.F + functions.CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(functions.CONTROL.L + functions.CONTROL.R, (functions.CONTROL.F + functions.CONTROL.B + functions.CONTROL.Q + functions.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * functions.SPEED
			functions.lCONTROL = {F = functions.CONTROL.F, B = functions.CONTROL.B, L = functions.CONTROL.L, R = functions.CONTROL.R}
		elseif (functions.CONTROL.L + functions.CONTROL.R) == 0 and (functions.CONTROL.F + functions.CONTROL.B) == 0 and (functions.CONTROL.Q + functions.CONTROL.E) == 0 and functions.SPEED ~= 0 then
			functions.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (functions.lCONTROL.F + functions.lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(functions.lCONTROL.L + functions.lCONTROL.R, (functions.lCONTROL.F + functions.lCONTROL.B + functions.CONTROL.Q + functions.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * functions.SPEED
		else
			--BV.velocity = Vector3.new(0, 0, 0)
		end

		local dragCoefficient = 0.05
		local drag = -1 * (functions.BV.velocity * dragCoefficient)
		local newVelocity = functions.BV.velocity + drag
		
		-- Clamp vertical velocity to avoid strong downward collisions
		if (functions.CONTROL.Q + functions.CONTROL.E) == 0 then
			newVelocity = Vector3.new(newVelocity.X, math.clamp(newVelocity.Y, -7, 7), newVelocity.Z)
		end
		
		--Logger.Debug("SwimmingFunctions.SwimHandler setting velocity to:",newVelocity)
		functions.BV.velocity = newVelocity

	end

	if (functions.BG ~= nil) then
		functions.BG.cframe = functions.BG.cframe:Lerp(workspace.CurrentCamera.CoordinateFrame,.1)
	end

	--if (functions.SPEED == 0) then

	--	functions.SwimControlForce(false,HRP)

	--	functions.Surface()--BV.velocity = Vector3.new(0, 10, 0)

	--else
	--	functions.SwimControlForce(true,HRP)

	--end



end


return functions