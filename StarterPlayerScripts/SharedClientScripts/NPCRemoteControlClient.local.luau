-- NPCRemoteControlClient.client.lua
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ModeManager = require(script.Parent:WaitForChild("ModeManager"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")

local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local NPCRemoteControlContext = InputRoot:WaitForChild("NPCRemoteControlContext")

local ExitNPCRemoteControlAction = NPCRemoteControlContext:WaitForChild("ExitNPCRemoteControlAction")
local NPCRemoteControlAction1 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction1")
local NPCRemoteControlAction2 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction2")
local NPCRemoteControlAction3 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction3")
local NPCRemoteControlAction4 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction4")
local NPCRemoteControlAction5 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction5")
local NPCRemoteControlAction6 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction6")
local NPCRemoteControlAction7 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction7")
local NPCRemoteControlAction8 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction8")
local NPCRemoteControlAction9 = NPCRemoteControlContext:WaitForChild("NPCRemoteControlAction9")

-- Remotes
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local NPCRemoteControl = SharedRemotes:WaitForChild("NPCRemoteControl")
local ReleaseControl = NPCRemoteControl:WaitForChild("ReleaseControl")
local SendInput      = NPCRemoteControl:WaitForChild("SendInput")
local ControlGranted = NPCRemoteControl:WaitForChild("ControlGranted")
local ControlRevoked = NPCRemoteControl:WaitForChild("ControlRevoked")
local PlaySound = SharedRemotes:WaitForChild("PlaySound")

--Assets
local Sounds = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Sounds")

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local controlledNPC  = nil
local isControlling  = false
local rightClickHeld = false
local lastMousePos   = nil

-- Camera
local camYaw          = 0
local camPitch        = 15
local CAM_DISTANCE    = 12
local CAM_MIN_PITCH   = -20
local CAM_MAX_PITCH   = 60
local CAM_SENSITIVITY = 0.3
local originalCameraType = nil

-- Input
local inputState = {
	moveDir       = Vector3.zero,
	jumpRequested = false,
	sprintHeld    = false,
}

local function changeExpression(npc,expression)
	local currentExpression = npc.Body.Head.Face:FindFirstChildOfClass("SurfaceAppearance")
	if currentExpression then
		currentExpression.Parent = npc.Expressions
	end

	local newExpression = npc.Expressions:FindFirstChild(expression)
	if newExpression then
		newExpression.Parent = npc.Body.Head.Face
	end
end

------------------------------------------------------------------
-- Animations
------------------------------------------------------------------
local Tracks = {}

local function loadAnim(npc, name: string): AnimationTrack?
	local animObj = npc.Animations:FindFirstChild(name)
	if not animObj or not animObj:IsA("Animation") then
		warn(("[NPCRemoteControl] Missing Animation %q under %s.Animations"):format(name, npc.Name))
		return nil
	end
	local animator = npc:WaitForChild("Humanoid"):WaitForChild("Animator")
	return animator:LoadAnimation(animObj)
end

local function loadAnimations(npc)
	Tracks = {
		Run        = loadAnim(npc, "Run"),
		Idle1      = loadAnim(npc, "Idle1"),
		FrontSweep = loadAnim(npc, "FrontSweep"),
		SideSweep  = loadAnim(npc, "SideSweep"),
	}
	
	for name, track in pairs(Tracks) do
		print("Loaded track:", name, track and track.Length or "NIL")
	end
end

-- Two independent layers:
--   locomotionTrack  — idle/run, always playing, freely interruptible
--   actionTrack      — sweep etc, plays on top, locked for its duration

local locomotionTrack: AnimationTrack? = nil
local actionTrack: AnimationTrack?     = nil
local actionLockUntil                  = 0

local function playLocomotion(track: AnimationTrack?, fade: number?)
	if not track then return end
	if locomotionTrack == track and track.IsPlaying then return end
	print("TEST PLAY LOCO ANIMATION:",track.Name)
	if locomotionTrack then
		pcall(function() locomotionTrack:Stop(fade or 0.1) end)
	end
	locomotionTrack = track
	pcall(function() track:Play(fade or 0.1) end)
end

local function playActionAnim(track: AnimationTrack?, fade: number?)
	if not track then return end
	-- Don't interrupt an action still within its lock window
	if os.clock() < actionLockUntil then return end
	if actionTrack then
		pcall(function() actionTrack:Stop(fade or 0.05) end)
	end
	actionTrack = track
	-- Lock for the full length of the animation
	actionLockUntil = os.clock() + track.Length
	pcall(function()
		track.TimePosition = 0
		track:Play(fade or 0.05)
	end)
end

------------------------------------------------------------------
-- Default controls
------------------------------------------------------------------
local function disableDefaultControls()
	pcall(function()
		local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
		require(playerModule):GetControls():Disable()
	end)
end

local function enableDefaultControls()
	pcall(function()
		local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
		require(playerModule):GetControls():Enable()
	end)
end

------------------------------------------------------------------
-- Camera
------------------------------------------------------------------
local function startNPCCamera(npc)
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if hrp then
		local lookVec = hrp.CFrame.LookVector
		camYaw = math.deg(math.atan2(-lookVec.X, -lookVec.Z))
	end
end

local function stopNPCCamera()
	camera.CameraType = originalCameraType or Enum.CameraType.Custom
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then camera.CameraSubject = hum end
	end
end

local function updateCamera(npc)
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local yawRad   = math.rad(camYaw)
	local pitchRad = math.rad(camPitch)

	local offset = Vector3.new(
		math.sin(yawRad) * math.cos(pitchRad),
		math.sin(pitchRad),
		math.cos(yawRad) * math.cos(pitchRad)
	) * CAM_DISTANCE

	local targetPos = hrp.Position + Vector3.new(0, 1.5, 0)
	local camPos    = targetPos + offset

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {npc}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local ray = workspace:Raycast(targetPos, offset, rayParams)
	if ray then
		camPos = ray.Position - offset.Unit * 0.3
	end

	camera.CFrame = CFrame.new(camPos, targetPos)
end

------------------------------------------------------------------
-- Movement
------------------------------------------------------------------
local function getMoveDirFromKeys()
	local x = 0
	local z = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then z = z + 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then z = z - 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then x = x + 1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then x = x - 1 end

	if x == 0 and z == 0 then return Vector3.zero end

	local camLook = camera.CFrame.LookVector
	local forward = Vector3.new(camLook.X, 0, camLook.Z).Unit
	local right   = Vector3.new(camLook.Z, 0, -camLook.X).Unit
	return (forward * z + right * x).Unit
end

------------------------------------------------------------------
-- Input events
------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = true
		lastMousePos = UserInputService:GetMouseLocation()
	end

	if gameProcessed then return end
	if not isControlling then return end

	if input.KeyCode == Enum.KeyCode.Space then
		inputState.jumpRequested = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightClickHeld = false
		lastMousePos = nil
	end
	if input.KeyCode == Enum.KeyCode.Space then
		inputState.jumpRequested = false
	end
end)

------------------------------------------------------------------
-- Control functions
------------------------------------------------------------------
local function releaseControl()
	if not isControlling then return end
	ReleaseControl:FireServer()
end

local function enterControlMode(npc)
	isControlling  = true
	controlledNPC  = npc
	rightClickHeld = false
	lastMousePos   = nil
	actionLockUntil = 0
	actionTrack     = nil
	locomotionTrack = nil

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	disableDefaultControls()
	startNPCCamera(npc)
	loadAnimations(npc)
	ModeManager:SetMode(ModeManager.Modes.NPCRemoteControl)
end

local function exitControlMode()
	isControlling   = false
	controlledNPC   = nil
	rightClickHeld  = false
	lastMousePos    = nil
	actionLockUntil = 0

	-- Stop any playing tracks cleanly
	if locomotionTrack then pcall(function() locomotionTrack:Stop(0.1) end) end
	if actionTrack then pcall(function() actionTrack:Stop(0.1) end) end
	locomotionTrack = nil
	actionTrack     = nil
	Tracks          = {}

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	enableDefaultControls()
	stopNPCCamera()
	ModeManager:SetMode(ModeManager.Modes.Gameplay)
end

------------------------------------------------------------------
-- Action button bindings
------------------------------------------------------------------
ExitNPCRemoteControlAction.Pressed:Connect(function()
	releaseControl()
end)

NPCRemoteControlAction1.Pressed:Connect(function()
	playActionAnim(Tracks.FrontSweep, 0.05)
end)

NPCRemoteControlAction2.Pressed:Connect(function()
	playActionAnim(Tracks.SideSweep, 0.05)
end)

NPCRemoteControlAction3.Pressed:Connect(function() 
	changeExpression(controlledNPC,"HAPPY")
end)
NPCRemoteControlAction4.Pressed:Connect(function() 
	changeExpression(controlledNPC,"MOPEY")
end)
NPCRemoteControlAction5.Pressed:Connect(function() 
	local soundFile = Sounds:FindFirstChild("Robot1")

	if (not soundFile) then return end

	PlaySound:FireServer(soundFile.SoundId,controlledNPC,1,50)
end)
NPCRemoteControlAction6.Pressed:Connect(function() 
	local soundFile = Sounds:FindFirstChild("Robot2")
	
	if (not soundFile) then return end
	
	PlaySound:FireServer(soundFile.SoundId,controlledNPC,1,50)
end)
NPCRemoteControlAction7.Pressed:Connect(function() 
	local soundFile = Sounds:FindFirstChild("Robot3")

	if (not soundFile) then return end

	PlaySound:FireServer(soundFile.SoundId,controlledNPC,1,50)
end)
NPCRemoteControlAction8.Pressed:Connect(function() 
	local soundFile = Sounds:FindFirstChild("Robot4")

	if (not soundFile) then return end

	PlaySound:FireServer(soundFile.SoundId,controlledNPC,1,50)
end)
NPCRemoteControlAction9.Pressed:Connect(function() 
	local soundFile = Sounds:FindFirstChild("Robot5")

	if (not soundFile) then return end

	PlaySound:FireServer(soundFile.SoundId,controlledNPC,1,50)
end)

------------------------------------------------------------------
-- Remote handlers
------------------------------------------------------------------
ControlGranted.OnClientEvent:Connect(function(npc)
	enterControlMode(npc)
end)

ControlRevoked.OnClientEvent:Connect(function()
	exitControlMode()
end)

------------------------------------------------------------------
-- Heartbeat
------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not isControlling or not controlledNPC or not controlledNPC.Parent then return end

	-- Right-click orbit
	if rightClickHeld and lastMousePos then
		local currentPos = UserInputService:GetMouseLocation()
		local delta = currentPos - lastMousePos
		if delta.Magnitude > 0 then
			camYaw   = camYaw   - delta.X * CAM_SENSITIVITY
			camPitch = math.clamp(camPitch + delta.Y * CAM_SENSITIVITY, CAM_MIN_PITCH, CAM_MAX_PITCH)
		end
		lastMousePos = currentPos
	end

	-- Movement
	inputState.moveDir    = getMoveDirFromKeys()
	inputState.sprintHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

	-- Locomotion layer — runs freely under any action
	if inputState.moveDir == Vector3.zero then
		Tracks.Idle1.Priority = Enum.AnimationPriority.Action
		playLocomotion(Tracks.Idle1, 0.1)
	else
		playLocomotion(Tracks.Run, 0.1)
	end

	SendInput:FireServer(inputState.moveDir, inputState.jumpRequested, inputState.sprintHeld)
	inputState.jumpRequested = false

	updateCamera(controlledNPC)
end)