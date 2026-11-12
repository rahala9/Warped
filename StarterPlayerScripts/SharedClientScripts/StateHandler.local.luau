--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")


--Remote Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local CurrentHeldToolChangedEvent = Remotes:WaitForChild("CurrentHeldToolChanged")
local UseToolEvent = Remotes:WaitForChild("UseTool")
--local WaterChangeEvent = Remotes:WaitForChild("WaterChange")
local ActionEvent = Remotes:WaitForChild("Action")
local PlaceObjectEvent = Remotes:WaitForChild("PlaceObject")
local EquipItemEvent = Remotes:WaitForChild("EquipItem")
local ToolActionEvent = Remotes:WaitForChild("ToolAction") --Runs after tool animation is done or action event in animation is done
local HoldToolEvent = Remotes:WaitForChild("HoldTool")
local PlayEmoteEvent = Remotes:WaitForChild("LocalPlayEmote")
local SitEvent = Remotes:WaitForChild("Sit")
local LedgeEvent = Remotes:WaitForChild("Ledge")
local PlayerStateChangeEvent = Remotes:WaitForChild("PlayerStateChange")
local SwimmingEvent = Remotes:WaitForChild("Swimming")

--Functions
local SwimmingFunctions = require(script.Parent:WaitForChild("SwimmingFunctions"))
local SpaceFlightFunctions = require(script.Parent:WaitForChild("SpaceFlightFunctions"))
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local attacksModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks"))

--Assets
local player = game.Players.LocalPlayer
local splash = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("VFX"):WaitForChild("Splash")

--Modules
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local RayVisualizer = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("RayVisualizer"))
local LedgeGrab = require(script.Parent:WaitForChild("LedgeGrab"))
local RightHUDManager = require(script.Parent:WaitForChild("RightHUDManager"))
local JetpackManager = require(script.Parent:WaitForChild("JetpackManager"))

--Gui
local playerGui = player:WaitForChild("PlayerGui")
local swimmingGui = playerGui:WaitForChild("SharedGUI"):WaitForChild("SwimGui")
local swimItems = swimmingGui:WaitForChild("SwimItems")
local swimActionFrame = swimItems:WaitForChild("ActionFrame")
local toolActionGui = playerGui:WaitForChild("SharedGUI"):WaitForChild("ToolActionGui")
local InputRoot = playerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")

--Context and Actions
local MovementContext = InputRoot:WaitForChild("MovementContext")
local SprintAction = MovementContext:WaitForChild("SprintAction")
local CrawlAction = MovementContext:WaitForChild("CrawlAction")
local SlideAction = MovementContext:WaitForChild("SlideAction")
local RollAction = MovementContext:WaitForChild("RollAction")

--Initialization
local ledgeGrab = LedgeGrab.new()
local PlayerMouse = player:GetMouse()
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

ledgeGrab:SetCharacter(char)
--RayVisualizer.Enable()

local attackingAnimations = {}

local FREEZE_ACTION = "freezeMovement"
local CLIMB_ACTION = "LedgeClimb"
local DROP_ACTION  = "LedgeDrop"

local baseJumpPower = nil
local RUNNING_JUMP_POWER_MULTIPLIER = 1.5

local justEnteredWater = false
local onSkateboard = false
local currentSpeed = 0
local CheckParams = RaycastParams.new()

local CheckInWaterParams = RaycastParams.new()
CheckInWaterParams.FilterDescendantsInstances = {workspace.Terrain,workspace.TerrainParts}
CheckInWaterParams.FilterType = Enum.RaycastFilterType.Include

local CheckInWaterTerrainParams = RaycastParams.new()
CheckInWaterTerrainParams.FilterDescendantsInstances = {workspace.Terrain}
CheckInWaterTerrainParams.FilterType = Enum.RaycastFilterType.Include
CheckInWaterTerrainParams.IgnoreWater = true

local CheckInWaterTerrainAndWaterParams = RaycastParams.new()
CheckInWaterTerrainAndWaterParams.FilterDescendantsInstances = {workspace.Terrain}
CheckInWaterTerrainAndWaterParams.FilterType = Enum.RaycastFilterType.Include

isSprintAnimationRunning = false
isWalkingAnimationRunning = false
isIdleTrackAnimationRunning = false

local function GetKeysPressed()
	local result = {}
	local keysPressed = game:GetService("UserInputService"):GetKeysPressed()
	for _, key in keysPressed do
		table.insert(result, key.KeyCode)
	end
	return result
end

local originalHipHeight = humanoid.HipHeight

local function ResolveDesiredWalkSpeed()
	if PlayerState.IsSwimming then return PlayerState.WalkSpeed end
	if PlayerState.Crawling then return PlayerState.CrawlSpeed end
	if PlayerState.Crouching then return PlayerState.CrawlSpeed end
	if PlayerState.IsSprinting then return PlayerState.RunSpeed end
	if PlayerState.Sliding then return PlayerState.SlideSpeed end
	if PlayerState.Rolling then return PlayerState.RollSpeed end
	return PlayerState.WalkSpeed
end

local function UpdateHumanoid()
	humanoid.WalkSpeed = ResolveDesiredWalkSpeed()
	if PlayerState.Crawling then
		humanoid.HipHeight = PlayerState.CrawlingHeight
	elseif PlayerState.Sliding then
		humanoid.HipHeight = PlayerState.CrawlingHeight
	else
		humanoid.HipHeight = PlayerState.NormalHeight
	end
end


function LeaveWater()
	SwimmingFunctions.StopSwimming(humanoid,HRP)
	--Lighting.ColorCorrection.TintColor = Color3.new(1,1,1)
	PlayerState.ChangeIsSwimmingState(false)
	SwimmingFunctions.UnbindControl()
	justEnteredWater = false
	PlayerState.InWater = false
	PlayerState.ChangeState(PlayerState.States.Idle)
	player.Character.Humanoid.HipHeight = SwimmingFunctions.originalHipHeight
	HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	ActionEvent:FireServer("InWater",false)
	ActionEvent:FireServer("UnderWater",false)
	if (PlayerState.CurrentTool and itemsmodule[PlayerState.CurrentTool] and itemsmodule[PlayerState.CurrentTool].Type ~= "TempHold") then
		HoldToolEvent:FireServer("")
	end
end

local function HandleRocket()
	PlaceObjectEvent:FireServer("Rocket")
end

local function HandleTool(toolName,action)
	if (PlayerState.CurrentTool == "Rocket") and (action == "Set") then
		HandleRocket()
	end
end

local function UseTool(actionName, userInputState, input)
	if (userInputState == Enum.UserInputState.Begin) then
		PlayerState.States.UsingToolAction = actionName
		PlayerState.ChangeState(PlayerState.States.UsingTool)
		local itemPieces = string.split(PlayerState.CurrentTool,"_")
		local itemName = itemPieces[1]
		if (itemsmodule[itemName].DeferAction) then return end
		UseToolEvent:FireServer(actionName)
		HandleTool()
	end
	return Enum.ContextActionResult.Pass
end

local function ClimbAction()
	if ledgeGrab:IsHanging() then
		ledgeGrab:HandleInput("Climb", humanoid, HRP, PlayerState)
	end
end

local function DropAction()
	if ledgeGrab:IsHanging() then
		ledgeGrab:HandleInput("Drop", humanoid, HRP, PlayerState)
	end
end

UIS.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		ClimbAction()
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		DropAction()
	end
end)

SprintAction.Released:Connect(function()
	PlayerState.IsSprinting = false
	humanoid.WalkSpeed = PlayerState.WalkSpeed
end)

SprintAction.Pressed:Connect(function()
	if (humanoid.WalkSpeed < 16) then return end
	if (PlayerState.InWater) then return end
	if (PlayerState.CarryingTempHold) then return end
	if (((humanoid:GetState() == Enum.HumanoidStateType.Running) or (humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics)) and humanoid.MoveDirection.Magnitude > 0) then
		if (PlayerState.Crawling or PlayerState.Crouching) then return end
		ContextActionService:UnbindAction(FREEZE_ACTION)
		PlayerState.IsSprinting = true
		humanoid.WalkSpeed = PlayerState.RunSpeed
	end
end)

CrawlAction.Released:Connect(function()
	if (PlayerState.CurrentState == PlayerState.States.Sliding) then return end
	if PlayerState.CurrentState == PlayerState.States.HoldingEdge then
		ledgeGrab:HandleInput("Drop", humanoid, HRP, PlayerState)
		return
	end
	if (PlayerState.Crawling) then
		PlayerState.Crawling = false
		PlayerState.Crouching = false
		UpdateHumanoid()
	elseif (PlayerState.Crouching) then
		PlayerState.Crawling = true
		PlayerState.Crouching = false
	else
		PlayerState.Crawling = false
		PlayerState.Crouching = true
	end
end)

SlideAction.Released:Connect(function()
	if (PlayerState.CurrentState == PlayerState.States.Sliding) then return end
	if (PlayerState.IsSprinting) then
		PlayerState.Sliding = true
		PlayerState.IsSprinting = false
		PlayerState.ChangeState(PlayerState.States.Sliding)
		UpdateHumanoid()
	end
end)

RollAction.Released:Connect(function()
	if (PlayerState.CurrentState == PlayerState.States.Rolling) then return end
	if (PlayerState.IsSprinting) then
		PlayerState.Rolling = true
		PlayerState.IsSprinting = false
		PlayerState.ChangeState(PlayerState.States.Rolling)
		UpdateHumanoid()
	end
end)

local heightOfFalling = 0
local heightOfLanding
local fallDistance = 0

function CheckIdle()
	if (PlayerState.CurrentState == PlayerState.States.HoldingEdge) then return end
	if (not PlayerState.InWater and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing and humanoid.MoveDirection.Magnitude <= 0) then
		if (PlayerState.CurrentToolState == PlayerState.ToolStates.NoTool) then
			PlayerState.ChangeState(PlayerState.States.Idle)
		else
			PlayerState.ChangeState(PlayerState.States.Idle)
		end
		fallDistance = 0
	end
end

function CheckWalking()
	if (not PlayerState.IsSprinting and humanoid:GetState() == Enum.HumanoidStateType.Running or humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics) and humanoid.MoveDirection.Magnitude > 0 then
		PlayerState.ChangeState(PlayerState.States.Walking)
		UpdateHumanoid()
	end
end

function CheckRunning()
	if (PlayerState.IsSprinting and humanoid:GetState() == Enum.HumanoidStateType.Running or humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics) and humanoid.MoveDirection.Magnitude > 0 then
		PlayerState.ChangeState(PlayerState.States.Running)
		UpdateHumanoid()
	end
end

function CheckPushing()
	if not table.find(GetKeysPressed(), Enum.KeyCode.E) then return end
	local rayOrigin = HRP.Position
	local rayDirection = HRP.CFrame.LookVector * 5
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if result and result.Instance then
		PlayerState.ChangeState(PlayerState.States.Pushing)
		if (result.Instance:GetAttribute("Pushable")) then
			PlayerState.LastPushedObject = result.Instance
			ActionEvent:FireServer("PushObject",result.Instance,rayDirection.Unit)
		end
	end
end

function CheckDonePushing()
	if not table.find(GetKeysPressed(), Enum.KeyCode.E) then
		if (PlayerState.LastPushedObject) then
			ActionEvent:FireServer("StopPushObject",PlayerState.LastPushedObject)
		end
		PlayerState.ChangeState(PlayerState.States.Idle)
		return
	end
	local rayOrigin = HRP.Position
	local rayDirection = HRP.CFrame.LookVector * 5
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	if (not result) or (not result.Instance) then
		ActionEvent:FireServer("StopPushObject",PlayerState.LastPushedObject)
		PlayerState.ChangeState(PlayerState.States.Idle)
	end
end

function CheckCrawling()
	if (PlayerState.Crawling) then
		if (PlayerState.CurrentState ~= PlayerState.States.Crawling and humanoid.MoveDirection.Magnitude > 0) then
			print("TEST CRAWL CHANGE STATE Crawling")
			PlayerState.ChangeState(PlayerState.States.Crawling)
		elseif (PlayerState.CurrentState ~= PlayerState.States.CrawlingIdle and humanoid.MoveDirection.Magnitude <= 0) then
			print("TEST CRAWL CHANGE STATE CrawlingIdle")
			PlayerState.ChangeState(PlayerState.States.CrawlingIdle)
		end
		UpdateHumanoid()
	end
end

function CheckCrouching()
	if (PlayerState.Crouching) then
		if (PlayerState.CurrentState ~= PlayerState.States.Crouching and humanoid.MoveDirection.Magnitude > 0) then
			PlayerState.ChangeState(PlayerState.States.Crouching)
		elseif (PlayerState.CurrentState ~= PlayerState.States.CrouchingIdle and humanoid.MoveDirection.Magnitude <= 0) then
			PlayerState.ChangeState(PlayerState.States.CrouchingIdle)
		end
		UpdateHumanoid()
	end
end

function CheckJumping()
	if (not PlayerState.IsSprinting and humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
		PlayerState.ChangeState(PlayerState.States.Jumping)
	end
end

function CheckRunningJump()
	if (PlayerState.IsSprinting and humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
		PlayerState.ChangeState(PlayerState.States.RunningJump)
	end
end

function CheckClimbing()
	if (humanoid:GetState() == Enum.HumanoidStateType.Climbing and humanoid.MoveDirection.Magnitude > 0) then
		PlayerState.ChangeState(PlayerState.States.Climbing)
	end
end

function CheckClimbingIdle()
	if (humanoid:GetState() == Enum.HumanoidStateType.Climbing and humanoid.MoveDirection.Magnitude <= 0) then
		PlayerState.ChangeState(PlayerState.States.ClimbingIdle)
	end
end

function CheckFalling()
	if (PlayerState.CurrentState == PlayerState.States.HoldingEdge) then return end
	if (not PlayerState.InWater and humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
		if (PlayerState.CurrentState ~= PlayerState.States.Falling) then
			heightOfFalling = char.HumanoidRootPart.CFrame.Position.Y
		end
		PlayerState.ChangeState(PlayerState.States.Falling)
	end
end

function CheckLanded()
	if (PlayerState.CurrentState == PlayerState.States.HoldingEdge) then return end
	if(humanoid:GetState() == Enum.HumanoidStateType.Landed) or (humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding) or (humanoid:GetState() == Enum.HumanoidStateType.Running) then
		if (fallDistance == 0) then
			heightOfLanding = HRP.CFrame.Position.Y
			fallDistance = heightOfFalling - heightOfLanding
			--TODO if above certain distance change animation
			--TODO if above certain distance change to roll if user has pressed W/forward
			--TODO calculate fall damage and reducing if doing roll
			heightOfFalling = 0
			heightOfLanding = 0
		end
		PlayerState.ChangeState(PlayerState.States.Idle)
	end
end

local function handleDive(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		PlayerState.ChangeState(PlayerState.States.DivingIntoWater)
	elseif inputState == Enum.UserInputState.End then
		if (PlayerState.Diving) then
			PlayerState.CurrentState.Animation:AdjustSpeed(0)
		end
	end
end

function StartDiving()
	game:GetService("ContextActionService"):BindAction("RotateDive", handleDive, false, Enum.KeyCode.W)
	PlayerState.Diving = true
	PlayerState.ChangeState(PlayerState.States.DivingIntoWater)
end

local function convertScale(value)
	local distanceFromPerfect = value / 1.874
	if (distanceFromPerfect > 1) then return 1
	elseif(distanceFromPerfect >= .95) then return 10
	else return math.floor(distanceFromPerfect * 10)
	end
end

function StopDiving(diveDepth)
	if (not PlayerState.Diving) then return end
	local orignal_value = PlayerState.CurrentState.Animation.TimePosition
	local score = convertScale(orignal_value)
	if (diveDepth == 0) then score = 0
	elseif (diveDepth < 10) then score = 1
	elseif (score > 6 and diveDepth < 30) then score = score - 1
	end
	PlayerState.Diving = false
	game:GetService("ContextActionService"):UnbindAction("RotateDive")
end

function CheckStopDiving(startDiveTime)
	local characterOffset = 100
	local backOffset = char.HumanoidRootPart.CFrame.LookVector * -2
	local rayOrigin = Vector3.new(char.HumanoidRootPart.CFrame.Position.X,char.HumanoidRootPart.CFrame.Position.Y + characterOffset,char.HumanoidRootPart.CFrame.Position.Z) + backOffset
	local rayDirection = Vector3.new(0,-1000,0)
	local Raycast = workspace:Raycast(rayOrigin, rayDirection, CheckInWaterParams)
	if Raycast then
		local HitPart = Raycast.Instance
		if (HitPart ~= nil) then
			if (not HitPart:GetAttribute("Water") and (Raycast.Material ~= Enum.Material.Water)) then
				if (Raycast.Position.Y > SwimmingFunctions.waterY) then
					StopDiving(0)
					PlayerState.ChangeState(PlayerState.States.Idle)
				end
			end
		end
	end
	local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainParams)
	if (DepthRaycast) then
		local HitPart = DepthRaycast.Instance
		local posFromWater = SwimmingFunctions.waterY - DepthRaycast.Position.Y
		local hitPartBelowWater = posFromWater > 0
		local depthOfWater = math.abs(posFromWater)
		local distanceToWaterBottom = char.HumanoidRootPart.CFrame.Position.Y - DepthRaycast.Position.Y
		if ((depthOfWater > 5)) then
			if (distanceToWaterBottom < 4) then
				PlayerState.ChangeState(PlayerState.States.StopDiving)
				StopDiving(depthOfWater)
				task.delay(1,function() PlayerState.ChangeState(PlayerState.States.UnderwaterSwimmingIdle) end)
			else
				if (hitPartBelowWater and PlayerState.InWater) then
					PlayerState.ChangeState(PlayerState.States.StopDiving)
					StopDiving(depthOfWater)
					task.delay(1,function() PlayerState.ChangeState(PlayerState.States.UnderwaterSwimmingIdle) end)
				end
			end
		else
			Logger.Debug("TEST DIVE IN SHALLOW")
			StopDiving(depthOfWater)
			PlayerState.ChangeState(PlayerState.States.SurfaceSwimming)
			ActionEvent:FireServer("UnderWater",false)
		end
	end
end

function CheckUnderwaterSwimming()
	if (HRP.Position.Y <= SwimmingFunctions.waterY - 4) then
		if humanoid.MoveDirection.Magnitude > 0 then
			StopDiving()
			SwimmingFunctions.EnableStates(false,humanoid)
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			SwimmingFunctions.SwimControlForce(true,HRP)
			SwimmingFunctions.SwimStabilityForce(true,HRP)
			HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			Lighting.ColorCorrection.TintColor = Color3.fromRGB(106, 196, 255)
			swimmingGui.Enabled = false
			PlayerState.ChangeState(PlayerState.States.UnderwaterSwimming)
			ActionEvent:FireServer("UnderWater",true)
		end
	end
end

function CheckUnderwaterWalkingIdle()
	if humanoid.MoveDirection.Magnitude <= 0 then
		PlayerState.ChangeState(PlayerState.States.UnderwaterWalkingIdle)
	end
end

function CheckUnderwaterWalking()
	if (PlayerState.DistanceFromWaterBottom < 6) then
		if workspace.CurrentCamera.CFrame.lookVector.Y <= -.9 then
			if table.find(GetKeysPressed(), Enum.KeyCode.W) then
				SwimmingFunctions.StopSwimming(humanoid,HRP)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
				SwimmingFunctions.UnbindControl()
				justEnteredWater = false
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
				PlayerState.ChangeState(PlayerState.States.UnderwaterWalking)
			end
		end
	end
end

function CheckUnderwaterSwimmingIdle()
	if (SwimmingFunctions.waterY > HRP.Position.Y + 4) then
		if humanoid.MoveDirection.Magnitude <= 0 then
			StopDiving()
			Lighting.ColorCorrection.TintColor = Color3.fromRGB(106, 196, 255)
			PlayerState.ChangeState(PlayerState.States.UnderwaterSwimmingIdle)
			ActionEvent:FireServer("UnderWater",true)
		end
	end
end

function CheckSurfaceSwimming(height)
	if (SwimmingFunctions.waterY - HRP.Position.Y < height) then
		if humanoid.MoveDirection.Magnitude > 0 then
			HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			Lighting.ColorCorrection.TintColor = Color3.new(1,1,1)
			PlayerState.ChangeState(PlayerState.States.SurfaceSwimming)
			ActionEvent:FireServer("UnderWater",false)
		end
	end
end

function CheckSurfaceSwimmingIdle(height)
	if (SwimmingFunctions.waterY - HRP.Position.Y < height) then
		if humanoid.MoveDirection.Magnitude <= 0 then
			HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			Lighting.ColorCorrection.TintColor = Color3.new(1,1,1)
			PlayerState.ChangeState(PlayerState.States.SurfaceSwimmingIdle)
			ActionEvent:FireServer("UnderWater",false)
		end
	end
end

function CheckDiving()
	if workspace.CurrentCamera.CFrame.lookVector.Y <= -.9 then
		if table.find(GetKeysPressed(), Enum.KeyCode.W) then
			if (char.PrimaryPart:GetAttribute("InTube") == true) then return end
			SwimmingFunctions.DiveUnderSurface(-2,HRP)
			task.delay(2,function() SwimmingFunctions.SurfaceForce(false,HRP) end)
			PlayerState.ChangeState(PlayerState.States.Diving)
		end
	end
end

function CheckJumpOutOfWater()
	if table.find(GetKeysPressed(), Enum.KeyCode.Space) then
		SwimmingFunctions.StopSwimming(humanoid,HRP)
		PlayerState.ChangeState(PlayerState.States.Jumping)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

function CheckEnteringWater()
	if (PlayerState.InWater) then
		PlayerState.ChangeState(PlayerState.States.EnteringWater)
	end
end

RunService.RenderStepped:Connect(function()

	if (PlayerState.CurrentState == PlayerState.States.Idle) then
		CheckWalking()
		CheckRunning()
		CheckJumping()
		CheckFalling()
		CheckCrawling()
		CheckCrouching()
		CheckClimbing()
		CheckClimbingIdle()
	elseif (PlayerState.CurrentState == PlayerState.States.Walking) then
		CheckIdle()
		CheckRunning()
		CheckJumping()
		CheckFalling()
		CheckClimbing()
		CheckClimbingIdle()
		CheckCrawling()
		CheckCrouching()
		CheckPushing()
	elseif (PlayerState.CurrentState == PlayerState.States.Pushing) then
		CheckIdle()
		CheckJumping()
		CheckFalling()
		CheckClimbing()
		CheckClimbingIdle()
		CheckCrawling()
		CheckCrouching()
		CheckDonePushing()
	elseif (PlayerState.CurrentState == PlayerState.States.Running) then
		CheckIdle()
		CheckWalking()
		CheckRunningJump()
		CheckFalling()
		CheckClimbing()
		CheckClimbingIdle()
		CheckCrawling()
		CheckCrouching()
	elseif (PlayerState.CurrentState == PlayerState.States.CheckHUD) then
		CheckWalking()
		CheckRunning()
		CheckJumping()
		CheckFalling()
		CheckCrawling()
		CheckCrouching()
	elseif (PlayerState.CurrentState == PlayerState.States.Crawling) then
		if (not PlayerState.Crawling) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
			CheckCrouching()
		else
			CheckCrawling()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.Crouching) then
		if (not PlayerState.Crouching) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
			CheckCrawling()
		else
			CheckCrouching()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.CrawlingIdle) then
		if (not PlayerState.Crawling) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
			CheckCrouching()
		else
			CheckCrawling()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.CrouchingIdle) then
		if (not PlayerState.Crouching) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
			CheckCrawling()
		else
			CheckCrouching()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.Rolling) then
		if (not PlayerState.Rolling) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.Sliding) then
		if (not PlayerState.Sliding) then
			CheckIdle()
			CheckWalking()
			CheckRunningJump()
			CheckFalling()
			CheckClimbing()
			CheckClimbingIdle()
			CheckRunning()
		end
	elseif (PlayerState.CurrentState == PlayerState.States.Flying) then
		-- flight handler placeholder
	elseif (PlayerState.CurrentState == PlayerState.States.Floating) then
		CheckIdle()
		CheckWalking()
		CheckRunningJump()
		CheckClimbing()
		CheckClimbingIdle()
		CheckRunning()
	elseif (PlayerState.CurrentState == PlayerState.States.Jumping) then
		ledgeGrab:Check(humanoid, HRP, PlayerState)
		CheckIdle()
		CheckFalling()
		CheckEnteringWater()
	elseif (PlayerState.CurrentState == PlayerState.States.DoubleJump) then
		ledgeGrab:Check(humanoid, HRP, PlayerState)
		CheckIdle()
		CheckLanded()
		CheckEnteringWater()
	elseif (PlayerState.CurrentState == PlayerState.States.Jetpacking) then
		-- JetpackManager handles thrust and orientation via Heartbeat
		ledgeGrab:Check(humanoid, HRP, PlayerState)
		CheckIdle()
		CheckLanded()
		CheckEnteringWater()
	elseif (PlayerState.CurrentState == PlayerState.States.RunningJump) then
		ledgeGrab:Check(humanoid, HRP, PlayerState)
		CheckIdle()
		CheckRunning()
		CheckWalking()
	elseif (PlayerState.CurrentState == PlayerState.States.Climbing) then
		CheckIdle()
		CheckClimbingIdle()
		CheckJumping()
		CheckWalking()
		CheckRunning()
	elseif (PlayerState.CurrentState == PlayerState.States.ClimbingIdle) then
		CheckIdle()
		CheckClimbing()
		CheckJumping()
	elseif (PlayerState.CurrentState == PlayerState.States.Falling) then
		ledgeGrab:Check(humanoid, HRP, PlayerState)
		CheckLanded()
		CheckEnteringWater()
		CheckClimbing()
		CheckClimbingIdle()
	elseif (PlayerState.CurrentState == PlayerState.States.HoldingEdge) then
		--NOTHING RIGHT NOW
	elseif (PlayerState.CurrentState == PlayerState.States.UsingTool) then
		if (PlayerState.CurrentToolState.AnimationUsing and (not PlayerState.CurrentToolState.AnimationUsing.IsPlaying)) then
			CheckIdle()
			CheckWalking()
			CheckRunning()
			CheckJumping()
		end
	elseif ((PlayerState.CurrentState == PlayerState.States.DivingIntoWater)) then
		if (not justEnteredWater and HRP.Position.Y <= SwimmingFunctions.waterY) then
			justEnteredWater = true
			local newSplash = splash:Clone()
			newSplash.Position = Vector3.new(HRP.Position.X,SwimmingFunctions.waterY+3,HRP.Position.Z)
			newSplash.Parent = workspace
			newSplash.Attachment.WaterSplashEmitter:Emit(1)
			game.Debris:AddItem(newSplash,3)
		end
		CheckStopDiving(os.time())
	elseif (PlayerState.CurrentState == PlayerState.States.EnteringWater) then
		if humanoid.MoveDirection.Magnitude == 0 then SwimmingFunctions.Surface(HRP) end
		CheckUnderwaterSwimming()
		CheckUnderwaterSwimmingIdle()
		CheckSurfaceSwimming(1)
		CheckSurfaceSwimmingIdle(1)
	elseif (PlayerState.CurrentState == PlayerState.States.UnderwaterSwimming) then
		SwimmingFunctions.SwimHandler(char,humanoid,HRP)
		CheckSurfaceSwimming(4)
		CheckSurfaceSwimmingIdle(4)
		CheckUnderwaterSwimmingIdle()
	elseif(PlayerState.CurrentState == PlayerState.States.UnderwaterWalking) then
		if workspace.CurrentCamera.CFrame.lookVector.Y >= .3 then
			if table.find(GetKeysPressed(), Enum.KeyCode.W) then
				SwimmingFunctions.EnableStates(false,humanoid)
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				SwimmingFunctions.SwimControlForce(true,HRP)
				SwimmingFunctions.SwimStabilityForce(true,HRP)
				HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				PlayerState.ChangeState(PlayerState.States.UnderwaterSwimming)
			end
		end
		CheckUnderwaterWalkingIdle()
	elseif(PlayerState.CurrentState == PlayerState.States.UnderwaterWalkingIdle) then
		if workspace.CurrentCamera.CFrame.lookVector.Y >= .3 then
			if table.find(GetKeysPressed(), Enum.KeyCode.W) then
				SwimmingFunctions.EnableStates(false,humanoid)
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				SwimmingFunctions.SwimControlForce(true,HRP)
				SwimmingFunctions.SwimStabilityForce(true,HRP)
				HRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				PlayerState.ChangeState(PlayerState.States.UnderwaterSwimming)
			end
		end
		if humanoid.MoveDirection.Magnitude > 0 then
			PlayerState.ChangeState(PlayerState.States.UnderwaterWalking)
		end
	elseif (PlayerState.CurrentState == PlayerState.States.UnderwaterSwimmingIdle) then
		SwimmingFunctions.SwimControlForce(false,HRP)
		SwimmingFunctions.TreadWater(HRP)
		if (char and char.Humanoid) then char.Humanoid.HipHeight = SwimmingFunctions.originalHipHeight end
		CheckUnderwaterSwimming()
		CheckSurfaceSwimming(4)
		CheckSurfaceSwimmingIdle(4)
	elseif (PlayerState.CurrentState == PlayerState.States.SurfaceSwimming) then
		SwimmingFunctions.EnableStates(true,humanoid)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		SwimmingFunctions.SwimControlForce(false,HRP)
		SwimmingFunctions.SwimStabilityForce(false,HRP)
		SwimmingFunctions.StayOnSurface(SwimmingFunctions.SurfaceSwimmingYOffset,HRP)
		CheckSurfaceSwimmingIdle(4)
		CheckDiving()
		CheckIdle()
	elseif (PlayerState.CurrentState == PlayerState.States.SurfaceSwimmingIdle) then
		SwimmingFunctions.EnableStates(true,humanoid)
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		SwimmingFunctions.SwimControlForce(false,HRP)
		SwimmingFunctions.SwimStabilityForce(false,HRP)
		SwimmingFunctions.StayOnSurface(SwimmingFunctions.SurfaceSwimmingIdleYOffset,HRP)
		CheckSurfaceSwimming(4)
		CheckDiving()
	elseif (PlayerState.CurrentState == PlayerState.States.Diving) then
		char.Humanoid.HipHeight = SwimmingFunctions.originalHipHeight
		CheckUnderwaterSwimming()
	elseif (PlayerState.CurrentState == PlayerState.States.HoldingWaterEdge) then
		-- placeholder
	elseif (PlayerState.CurrentState == PlayerState.States.StartingSkating) then
		humanoid.PlatformStand = true
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		PlayerState.ChangeState(PlayerState.States.RidingSkateboard)
	elseif (PlayerState.CurrentState == PlayerState.States.RidingSkateboard) then
		-- skateboard handler placeholder
	elseif (PlayerState.CurrentState == PlayerState.States.KnockedDown) then
		-- knocked down placeholder
	elseif (PlayerState.CurrentState == PlayerState.States.Attacking) then
		if (PlayerState.InWater) then
			if (not PlayerState.CurrentState.Animation.IsPlaying) then
				PlayerState.ChangeState(PlayerState.States.UnderwaterSwimmingIdle,false)
			end
		else
			if (not PlayerState.CurrentState.Animation.IsPlaying) then
				PlayerState.ChangeState(PlayerState.States.Idle,false)
			end
		end
	end

end)


local function onJumpRequest()
	if (PlayerState.CurrentState == PlayerState.States.Running) then
		humanoid.JumpPower = baseJumpPower * RUNNING_JUMP_POWER_MULTIPLIER
		task.delay(0.1, function()
			humanoid.JumpPower = baseJumpPower
		end)
	end
end

local function characterAdded(newCharacter)

	char = newCharacter
	HRP = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")

	JetpackManager.Init(char, humanoid, HRP, PlayerState)

	PlayerState.Init(player)
	CheckIdle()

	humanoid = newCharacter:WaitForChild("Humanoid")

	baseJumpPower = humanoid.JumpPower

	ledgeGrab:SetCharacter(char)
end

if char then
	characterAdded(char)
end

player.CharacterAdded:connect(characterAdded)
UserInputService.JumpRequest:connect(onJumpRequest)

humanoid.Running:Connect(function(speed)
	currentSpeed = speed
end)

ToolActionEvent.Event:Connect(function(toolName,action)
	if (not PlayerState.CurrentTool) then return end
	if (not itemsmodule[PlayerState.CurrentTool]) then return end
	if (not itemsmodule[PlayerState.CurrentTool].DeferAction) then return end
	UseToolEvent:FireServer("UseTool",action)
	HandleTool(toolName,action)
end)

PlayEmoteEvent.Event:Connect(function(emoteName,playSound)
	PlayerState.PlayEmote(PlayerState.States[emoteName],true)
end)

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName,slot)
	PlayerState.CurrentTool = toolName
	if (toolName == "") then
		toolName = "NoTool"
	else
		local itemPieces = string.split(toolName,"_")
		toolName = itemPieces[1]
	end
	if (itemsmodule[PlayerState.CurrentTool] and itemsmodule[PlayerState.CurrentTool].Type == "TempHold") then
		PlayerState.CarryingTempHold = true
	else
		PlayerState.CarryingTempHold = false
	end
	if (toolName == "NoTool") or (slot == "WeaponSlot") or (slot == "One") then
		game:GetService("ContextActionService"):UnbindAction("UseTool")
		game:GetService("ContextActionService"):UnbindAction("UseTool2")
		toolActionGui.Enabled = false
		toolActionGui.MainFrame.Actions["2"].Visible = false
	else
		game:GetService("ContextActionService"):BindAction("UseTool", UseTool, false, Enum.KeyCode.R,Enum.UserInputType.MouseButton1)
		if (itemsmodule[toolName].ToolAction1) then
			toolActionGui.Enabled = true
			toolActionGui.MainFrame.Actions["1"].ImageRectOffset = Vector2.new(itemsmodule[toolName].ImageOffsetX,itemsmodule[toolName].ImageOffsetY)
			toolActionGui.MainFrame.Actions["1"].Image = itemsmodule["ImageMap"]["Tool"]
			toolActionGui.MainFrame.Actions["1"].ImageRectSize = Vector2.new(64,64)
			toolActionGui.MainFrame.Actions["1"].ActionName.Text = itemsmodule[toolName].ToolAction1
		else
			toolActionGui.Enabled = false
		end
		if (itemsmodule[toolName].ToolAction2) then
			game:GetService("ContextActionService"):BindAction("UseTool2", UseTool, false, Enum.KeyCode.F)
			toolActionGui.MainFrame.Actions["2"].Visible = true
			toolActionGui.MainFrame.Actions["2"].ImageRectOffset = Vector2.new(itemsmodule[toolName].ImageOffsetX,itemsmodule[toolName].ImageOffsetY)
			toolActionGui.MainFrame.Actions["2"].Image = itemsmodule["ImageMap"]["Tool"]
			toolActionGui.MainFrame.Actions["2"].ImageRectSize = Vector2.new(64,64)
			toolActionGui.MainFrame.Actions["2"].ActionName.Text = itemsmodule[toolName].ToolAction2
		end
	end
	if (PlayerState.ToolStates[toolName] == nil) then return end
	PlayerState.ChangeToolState(PlayerState.ToolStates[toolName],toolName)
end)

SitEvent.Event:Connect(function(SitState)
	if (PlayerState.States[SitState]) then
		PlayerState.ChangeState(PlayerState.States[SitState])
	end
end)

PlayerStateChangeEvent.OnClientEvent:Connect(function(NewState,attack,deferAttack,keyCode,hitPosition,amount,arg1,arg2,arg3,arg4)
	if (NewState == "KnockedDown") then
		PlayerState.ChangeState(PlayerState.States.KnockedDown)
	elseif (NewState == "Standing") then
		PlayerState.ChangeState(PlayerState.States.Idle)
	elseif (NewState == "Respawn") then
		LeaveWater()
		PlayerState.ChangeState(PlayerState.States.Jumping)
		player.Character.Humanoid.Jump = true
	elseif (NewState == "Death") then
		PlayerState.ChangeState(PlayerState.States.Death)
	elseif (NewState == "Movement") then
		PlayerState.WalkSpeed = amount
	elseif (NewState == "Float") then
		if (arg3) then
			if (typeof(arg4) == "Vector3" and arg4.Y > 0) then
				print("TEST DO NOT FLOAT")
				return
			end
		end
		print("TEST Float event called:",arg1,arg2)
		PlayerState.FloatForce(true,HRP,arg1)
		PlayerState.ChangeState(PlayerState.States.Floating)
		task.delay(arg2, function()
			print("TEST Float event ended:",arg1,arg2)
			PlayerState.FloatForce(false,HRP,arg1)
			PlayerState.ChangeState(PlayerState.States.Falling)
		end)
	elseif (NewState == "Attacking") then
		if (attack == nil) then return end
		if (PlayerState.AttackAnimations[attack.Animation] == nil) then return end
		PlayerState.States.Attacking.Animation = PlayerState.AttackAnimations[attack.Animation]
		PlayerState.States.Attacking.AnimationSpeed = attack.AnimationSpeed
		PlayerState.ChangeState(PlayerState.States.Attacking,deferAttack,keyCode,hitPosition)
	end
end)


function CheckInWater()
	local landY = 0
	local characterOffset = 100
	local Raycast = workspace:Raycast(Vector3.new(char.HumanoidRootPart.CFrame.Position.X,char.HumanoidRootPart.CFrame.Position.Y + characterOffset,char.HumanoidRootPart.CFrame.Position.Z), Vector3.new(0,-1000,0), CheckInWaterParams)
	if Raycast then
		local HitPart = Raycast.Instance
		if (HitPart ~= nil) then
			local distanceFromWater = char.HumanoidRootPart.CFrame.Position.Y - SwimmingFunctions.waterY
			local waterSurfaceOffset = 3
			local distanceFromLand = landY - Raycast.Position.Y
			if (HitPart:GetAttribute("Water") or (Raycast.Material == Enum.Material.Water)) then
				local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainParams)
				if (DepthRaycast) then
					local depthOfWater = SwimmingFunctions.waterY - DepthRaycast.Position.Y
					local distanceToWaterBottom = char.HumanoidRootPart.CFrame.Position.Y - DepthRaycast.Position.Y
					PlayerState.DistanceFromWaterBottom = distanceToWaterBottom
					if (char.HumanoidRootPart.CFrame.Position.Y <= (SwimmingFunctions.waterY + waterSurfaceOffset)) and (depthOfWater > 5) then
						return true,distanceFromWater
					end
				end
			elseif (PlayerState.InWater and (char.HumanoidRootPart.CFrame.Position.Y < SwimmingFunctions.waterY + waterSurfaceOffset)) then
				return true, 0
			elseif (PlayerState.InWater and (HitPart:GetAttribute("OnWater") or Raycast.Material == Enum.Material.Water)) then
				local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainParams)
				if (DepthRaycast) then
					local depthOfWater = SwimmingFunctions.waterY - DepthRaycast.Position.Y
					local distanceToWaterBottom = char.HumanoidRootPart.CFrame.Position.Y - DepthRaycast.Position.Y
					PlayerState.DistanceFromWaterBottom = distanceToWaterBottom
					if (depthOfWater > 5) then return true,distanceFromWater
					else return false,distanceFromWater
					end
				end
				return true, 0
			elseif (not PlayerState.InWater and (HitPart:GetAttribute("OnWater") or Raycast.Material == Enum.Material.Water) and (Raycast.Position.Y > char.HumanoidRootPart.CFrame.Position.Y)) then
				local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainAndWaterParams)
				if (DepthRaycast) then
					HitPart = DepthRaycast.Instance
					if (HitPart:GetAttribute("Water") or Raycast.Material == Enum.Material.Water) then
						return true,0
					end
				end
			end
		end
	end
	return false, 0
end

function CheckBelowPlayer()
	local landY = 0
	local characterOffset = 100
	local backOffset = char.HumanoidRootPart.CFrame.LookVector * -1
	local rayOrigin = Vector3.new(char.HumanoidRootPart.CFrame.Position.X,char.HumanoidRootPart.CFrame.Position.Y + characterOffset,char.HumanoidRootPart.CFrame.Position.Z) + backOffset
	local rayDirection = Vector3.new(0,-1000,0)
	RayVisualizer.UpdateRay(rayOrigin, rayDirection)
	local Raycast = workspace:Raycast(rayOrigin, rayDirection, CheckInWaterParams)
	if Raycast then
		local HitPart = Raycast.Instance
		if (HitPart ~= nil) then
			local distanceFromWater = char.HumanoidRootPart.CFrame.Position.Y - SwimmingFunctions.waterY
			if (HitPart:GetAttribute("Water") or (Raycast.Material == Enum.Material.Water)) then
				local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainParams)
				if (DepthRaycast) then
					local depthOfWater = SwimmingFunctions.waterY - DepthRaycast.Position.Y
					if (depthOfWater > 5) then return true,distanceFromWater end
				end
			end
		end
	end
	return false, 0
end

function CheckForSlide() end

function HandleAboveWater()
	if ((PlayerState.IsSwimming) or (PlayerState.CurrentState == PlayerState.States.DivingIntoWater)) then return end
	local waterBelow, distanceFromWater = CheckBelowPlayer()
end

function HandleInWater()
	if (not char or not char.HumanoidRootPart) then return end
	local distanceFromWater = math.abs(char.HumanoidRootPart.CFrame.Position.Y - SwimmingFunctions.waterY)
	if (PlayerState.IsSwimming and distanceFromWater > 10) then
		if (not PlayerState.UnderwaterWalking) then
			local DepthRaycast = workspace:Raycast(char.HumanoidRootPart.CFrame.Position, Vector3.new(0,-1000,0), CheckInWaterTerrainParams)
			if (DepthRaycast) then
				PlayerState.DistanceFromWaterBottom = char.HumanoidRootPart.CFrame.Position.Y - DepthRaycast.Position.Y
			end
		end
		return
	end
	local inWater, distanceFromWater = CheckInWater()
	if (PlayerState.InWater ~= inWater) then
		ActionEvent:FireServer("InWater",inWater)
	end
	PlayerState.InWater = inWater
	if (inWater) then
		if (PlayerState.IsSwimming) then return end
		SwimmingFunctions.originalHipHeight = player.Character.Humanoid.HipHeight
		if (distanceFromWater <= 1) then
			if (not PlayerState.Diving) then
				PlayerState.ChangeState(PlayerState.States.SurfaceSwimming)
				ActionEvent:FireServer("UnderWater",false)
			end
		else
			return
		end
		if (PlayerState.CurrentTool and itemsmodule[PlayerState.CurrentTool] and itemsmodule[PlayerState.CurrentTool].Type ~= "TempHold") then
			HoldToolEvent:FireServer("")
		end
		PlayerState.ChangeIsSwimmingState(true)
		SwimmingFunctions.BindControl()
		SwimmingFunctions.SwimControl(PlayerMouse)
	else
		if (not PlayerState.IsSwimming) then return end
		LeaveWater()
	end
end

local tweeningInformation = TweenInfo.new(20, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)

function GatherWater(actionName, userInputState, input)
	if (userInputState == Enum.UserInputState.Begin) then
		ActionEvent:FireServer("GatherWater")
	end
end

CheckIdle()

local step_counter = 0
local timeChangeInterval = .05

RunService.Heartbeat:Connect(function(step)

	JetpackManager.Update(step)

	step_counter = step_counter + step
	if step_counter >= timeChangeInterval then
		step_counter = 0

		if (not PlayerState.InWaterZone) then
			HandleAboveWater()
		end

		if (PlayerState.InWaterZone) then
			HandleInWater()
			local distanceFromWater = (char.HumanoidRootPart.CFrame.Position.Y - SwimmingFunctions.waterY)
			if ((distanceFromWater < 5) and (distanceFromWater > 1)) then
				if (PlayerState.CurrentState ~= PlayerState.States.SurfaceSwimming) then
					swimmingGui.Enabled = true
					swimActionFrame.Visible = true
					game:GetService("ContextActionService"):BindAction("GatherWater", GatherWater, false, Enum.KeyCode.R)
				end
			else
				swimActionFrame.Visible = false
				game:GetService("ContextActionService"):UnbindAction("GatherWater")
			end
		else
			swimActionFrame.Visible = false
			game:GetService("ContextActionService"):UnbindAction("GatherWater")
		end
	end
end)


local debounce = false

LedgeEvent.OnClientEvent:Connect(function(LedgeState,serverStartTime)
	if (not PlayerState.States[LedgeState]) then return end
	if (serverStartTime) then
		local dt = serverStartTime - workspace:GetServerTimeNow()
		if dt > 0 then task.wait(dt) end
	end
	PlayerState.ChangeState(PlayerState.States[LedgeState])
end)