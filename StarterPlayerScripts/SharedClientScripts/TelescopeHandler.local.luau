local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local checkTelescopepTarget = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CheckTelescopeTarget")
local hasItem = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("HasItem")
local tweenService = game:GetService("TweenService")
local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))

local camera = workspace.CurrentCamera

local player = Players.LocalPlayer

local mouse = game.Players.LocalPlayer:GetMouse()

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local initialFieldOfView = camera.FieldOfView
local initialCameraPosition = camera.CFrame
local isZoomed = false
local inTween = false
local target

local CurrentPlayer = game.Players.LocalPlayer
local playerGui = CurrentPlayer:WaitForChild("PlayerGui")
local telescopeGui = playerGui:WaitForChild("SharedGUI"):WaitForChild("TelescopeGui")
local char = CurrentPlayer.Character or CurrentPlayer.CharacterAdded:Wait()

local messageFrame = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("MessageFrame")
local message = messageFrame:WaitForChild("GraphicFrame"):WaitForChild("message")

local humanoid = char:WaitForChild("Humanoid")
--character:WaitForChild("HumanoidRootPart")
local initialWalkSpeed = humanoid.WalkSpeed
local initialJumpPower = humanoid.JumpPower

local cameraAngleX = 0
local cameraAngleY = 0

local zoomDistance = 0
local telescopeSource


local FADE_INFO = TweenInfo.new(3)

--function MouseWheel( name, state, input )
--	if input.Position.Z == 1 then
--		Logger.Debug("Mouse wheel scrolled forward")
--		
--		camera.FieldOfView = camera.FieldOfView - 1
--	else
--		Logger.Debug("Mouse wheel scrolled backward")
--		camera.FieldOfView = camera.FieldOfView + 1
--	end
--end

CurrentPlayer.CharacterAdded:Connect(function(character)
	char = character
	humanoid = char:WaitForChild("Humanoid")
end)

function MouseWheelKey( name, inputState, input )
	
	if inputState == Enum.UserInputState.Begin then

		if name=="forward" then
			camera.FieldOfView = camera.FieldOfView - 1

			zoomDistance = zoomDistance + 1
		else
			camera.FieldOfView = camera.FieldOfView + 1
			zoomDistance = zoomDistance - 1
		end
	end
	
end


local function moveInput(Action, inputState, inputObject)
	
	if (telescopeSource == nil) then
		return
	end
	
	--if not isZoomed then return end

	if inputState == Enum.UserInputState.Change then
		cameraAngleX = math.clamp(cameraAngleX-UserInputService:GetMouseDelta().X*0.4, -90, 90)
		cameraAngleY = math.clamp(cameraAngleY-UserInputService:GetMouseDelta().Y*0.4, -75, 75)
		local camPosition = telescopeSource.CFrame:ToWorldSpace(CFrame.new(0, 0, -2))
		local camRotation = camPosition * CFrame.Angles(0, math.rad(cameraAngleX), 0) * CFrame.Angles(math.rad(cameraAngleY), 0, 0)
		target = camRotation:ToWorldSpace(CFrame.new(0, 0, -20))
		camera.CFrame = CFrame.new(camRotation.Position, target.Position)
		camera.Focus = CFrame.new(target.Position)
	end
end


local function zoomOut(Action, inputState, inputObject)
	if inTween == true then return end
	
	telescopeGui.Enabled = false
	inTween = true
	
	--Reset zoom distance
	zoomDistance = 0

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	local tween = TweenService:Create(camera, tweenInfo, {CFrame=initialCameraPosition, FieldOfView=initialFieldOfView})
	tween.Completed:Connect(function()
		--ContextActionService:UnbindAction("MoveInput", moveInput, false, Enum.UserInputType.MouseMovement)
		ContextActionService:UnbindAction("zoomOut", zoomOut, false,  Enum.KeyCode.Q)
		--ContextActionService:UnbindAction("MouseWheel", MouseWheel, false, Enum.UserInputType.MouseWheel)
		ContextActionService:UnbindAction("forward", MouseWheelKey, false, Enum.KeyCode.Equals)
		ContextActionService:UnbindAction("backward", MouseWheelKey, false, Enum.KeyCode.Minus)

		--ContextActionService:SetTitle("ScopeInOut", "+")
		camera.CameraType = Enum.CameraType.Custom
		humanoid.WalkSpeed = initialWalkSpeed
		humanoid.JumpPower = initialJumpPower
		isZoomed = false
		inTween = false
	end)
	tween:Play()
end

local function zoomIn(prompt)
	if inTween == true then return end
	
	telescopeSource = prompt.Parent
	telescopeGui.Enabled = true
	inTween = true
	
	initialCameraPosition = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	-- Rotate root part CFrame according to camera direction
	local faceToward = camera.CFrame:Lerp(telescopeSource.CFrame, 1.1)
	telescopeSource.CFrame = CFrame.new(telescopeSource.CFrame.Position, Vector3.new(faceToward.Position.X, telescopeSource.Position.Y, faceToward.Position.Z))
	target = telescopeSource.CFrame:ToWorldSpace(CFrame.new(0, 2, -20))
	cameraAngleX, cameraAngleY = 0, 0
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	task.wait(0.05)
	local camPosition = telescopeSource.CFrame:ToWorldSpace(CFrame.new(0, 2, -2))
	camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
	local tween = TweenService:Create(camera, tweenInfo, {CFrame=camPosition, FieldOfView=12})
	tween.Completed:Connect(function()
		--ContextActionService:BindAction("MoveInput", moveInput, false, Enum.UserInputType.MouseMovement)

		ContextActionService:BindAction("zoomOut", zoomOut, false, Enum.KeyCode.Q)
		--ContextActionService:BindAction("MouseWheel", MouseWheel, false, Enum.UserInputType.MouseWheel)
	
		ContextActionService:BindAction("forward", MouseWheelKey, false, Enum.KeyCode.Equals)
		ContextActionService:BindAction("backward", MouseWheelKey, false, Enum.KeyCode.Minus)
		
		camera.Focus = CFrame.new(target.Position)
		isZoomed = true
		inTween = false
	end)
	tween:Play()
end

local bounce = false

ProximityPromptService.PromptTriggered:Connect(function(prompt, inputType)
	if (prompt.Name ~= "UseTelescope") then
		return
	end
	
	if (bounce)  then
		return
	end
		
	bounce = true

	zoomIn(prompt)
	
	bounce = false

end)


local messagesAlreadyDisplayed = {}
local showingMessage = false


--mouse.WheelForward:Connect(function()

--	--camera.FieldOfView = camera.FieldOfView - 1
--end)

mouse.Move:Connect(function()
	
	if (isZoomed) then
		local position = mouse.Hit.p
		local target = mouse.Target
		mouse.TargetFilter = workspace:WaitForChild("BuildBlockers")

		if (target ~= nil) then
			
			--Check if our target is a valid comment or quest trigger
			local message = checkTelescopepTarget:InvokeServer(target.Name,zoomDistance)
			
			if ((message ~= "") and (messagesAlreadyDisplayed[message]==nil)) then
				telescopeGui:WaitForChild("TargetFound").Visible = true
				
				messagesAlreadyDisplayed[message]=""
				showingMessage = true
				
				for c in string.gmatch(message,".") do 
					telescopeGui:WaitForChild("Comments").Text = telescopeGui:WaitForChild("Comments").Text..c
					task.wait(.05)
				end
				
				task.wait(2)
				
				telescopeGui:WaitForChild("Comments").Text = ""
				
				telescopeGui:WaitForChild("TargetFound").Visible = false
				
				showingMessage = false
			end
		end

		
		if (not showingMessage) then
			moveInput("MoveInput", Enum.UserInputState.Change, mouse)
		end
	end
	
end)
