-- SpaceFlightFunctions.client.lua
-- Player-driven flight with smooth aim (mouse accumulates yaw/pitch)
-- Physics on Heartbeat, Camera on RenderStepped

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local EVAFunctions = require(script.Parent:WaitForChild("EVAFunctions"))
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))

local shipPartsDef = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("ItemDefs"):WaitForChild("ShipParts"))

local playerInfo = require(script.Parent.PlayerInfo)

local Remotes           = ReplicatedStorage:WaitForChild("SharedRemotes")
local ShipPowerPanelChanged = Remotes:FindFirstChild("ShipPowerPanelChanged")

local functions = {}

--------------------------------------------------------------------
-- CONFIG / TUNING
--------------------------------------------------------------------
functions.FlightForceMode = "LinearVelocity" -- "BodyVelocity"

functions.TranslationMode = "Planar" -- "Planar" | "FullCamera"
functions.VerticalMode = "WorldUp"   -- "WorldUp" | "CameraUp"

functions.MaxBaseSpeed = 0		--based on engine installed on ship
functions.ActiveBaseSpeed = 0     --based on engine installed on ship and amount of power allocated to it
functions.MaxBoostSpeed = 0		--based on engine installed on ship
functions.ActiveBoostSpeed = 0	--based on engine installed on ship and amount of power allocated to it
functions.MaxSensorRange = 2000  --Set to lowest Sensor Radar item
functions.ActiveSensorRange = 2000
functions.BaseSpeed = functions.MaxBaseSpeed
functions.BoostSpeed = functions.MaxBoostSpeed
functions.VerticalSpeedMult = 0.7

-- from PowerPanel in UI
functions.EngineSystemPower = 0
functions.WeaponSystemPower = 0
functions.ShieldSystemPower = 0
functions.SensorSystemPower = 0
functions.CommSystemPower = 0
functions.LifeSupportSystemPower = 0

functions.AccelResponse = 1

functions.GlideEnabled = true
functions.LinearDamp = 0.45
functions.MinStopSpeed = 0.05

functions.BrakeDampMult = 1.0

functions.LVMaxForce = 50000
functions.LVMaxForceBoost = 100000
functions.BVMaxForce = Vector3.new(9e9, 9e9, 9e9)

functions.ThrottleMode = true
functions.ThrottleAccel = 1
functions.ThrottleDecay = 0

-- Rotation
functions.RotationEnabled = true
functions.RotationResponsiveness = 50
functions.RotationMaxTorque = math.huge

-- Smooth steering (NMS-ish)
functions.MouseSensitivity = 0.0022
functions.AimSmoothing = 14
functions.MaxPitchDegrees = 60
functions.InvertYaw = true
functions.InvertPitch = false

functions.ModelForwardYawOffsetDegrees = 0

-- Banking
functions.BankingEnabled = true
functions.MaxBankDegrees = 14
functions.BankResponse = 10
functions.BankFrom = "Blend"
functions.BankInvert = false
functions.BankInvertStrafe = true
functions.BankStrength = 20
functions.BankStrafeWeight = 0.65
functions.BankYawWeight = 1.0

-- Camera
functions.UseScriptableChaseCamera = true
functions.LockMouseToCenterWhileFlying = true
functions.CameraDistance = 28
functions.CameraHeight = 10
functions.CameraLookAhead = 14
functions.CameraSmooth = 12
functions.CameraFov = nil

-- Orbit camera while RMB held
functions.OrbitDistance = 34
functions.OrbitHeight = 8
functions.OrbitSensitivity = 0.0022
functions.OrbitMaxPitchDegrees = 75

-- Zoom
functions.MinZoomDistance = 0  -- 0 = first person cockpit view
functions.MaxZoomDistance = 50
functions.ZoomSpeed = 5  -- studs per scroll tick
functions.ZoomSmooth = 8  -- smoothing factor

-- Input smoothing
functions.InputSmoothing = 18

--------------------------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------------------------
functions.BV = nil
functions.LV = nil
functions.LVAtt = nil

functions.AO = nil
functions.AOAtt = nil

functions._targetVel = Vector3.zero

-- Aim state
functions._aimYaw = 0
functions._aimPitch = 0
functions._aimYawSm = 0
functions._aimPitchSm = 0

functions._lastYawDelta = 0
functions._bank = 0

-- ship attachment
functions._ship = nil :: Model?
functions._shipWeld = nil :: WeldConstraint?

-- camera
functions._camEnabled = false
functions._prevCamType = nil
functions._prevCamSubject = nil
functions._prevMouseBehavior = nil
functions._prevMouseIcon = nil
functions._camCF = nil :: CFrame?

-- smoothed movement inputs
functions._inF = 0
functions._inS = 0
functions._inU = 0

functions._throttle = 0
functions._braking = false

-- RMB orbit state
functions._orbiting = false
functions._orbitYaw = 0
functions._orbitPitch = 0

-- Zoom state
functions._zoomDistance = 28
functions._zoomDistanceTarget = 28

-- Input connections
functions._inputConnections = {}
functions._exitDebounce = false

-- Targeting
functions._currentTarget = nil   -- currently targeted ship Model
functions._selectionBox = nil    -- 3D SelectionBox on targeted ship

-- Standard threshold: the power % at which full/standard performance is reached
-- Below this scales linearly from 0, above this gives bonuses
local POWER_ENG_STANDARD_THRESHOLD = {
	[0] = 25,
	[1] = 20,
	[2] = 15,
	[3] = 10,
	[4] = 5,
}

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function expSmoothing(alphaPerSecond: number, dt: number): number
	return 1 - math.exp(-alphaPerSecond * dt)
end

local function axis(negKey: Enum.KeyCode, posKey: Enum.KeyCode): number
	return (UserInputService:IsKeyDown(posKey) and 1 or 0) + (UserInputService:IsKeyDown(negKey) and -1 or 0)
end

local function ensureAttachment(parent: Instance, name: string): Attachment
	local a = parent:FindFirstChild(name)
	if a and a:IsA("Attachment") then return a end
	a = Instance.new("Attachment")
	a.Name = name
	a.Parent = parent
	return a
end

local function unanchorModel(m: Model)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and d.Anchored then
			d.Anchored = false
		end
	end
end

local function clampPitchRad(p: number, maxDegrees: number)
	local maxP = math.rad(maxDegrees)
	return math.clamp(p, -maxP, maxP)
end

local function getYawFromLook(look: Vector3): number
	return math.atan2(-look.X, -look.Z)
end

local function getPitchFromLook(look: Vector3): number
	local flatMag = math.max(1e-6, Vector3.new(look.X, 0, look.Z).Magnitude)
	return math.atan2(look.Y, flatMag)
end

--------------------------------------------------------------------
-- HUMANOID STATES
--------------------------------------------------------------------
function functions.EnableStates(enabled, humanoid)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
end

--------------------------------------------------------------------
-- FORCE CREATION
--------------------------------------------------------------------
function functions.FlightControlForce(on: boolean, HRP: BasePart)
	if on then
		if functions.FlightForceMode == "BodyVelocity" then
			if functions.BV then return end
			if functions.LV then functions.LV:Destroy(); functions.LV=nil end
			if functions.LVAtt then functions.LVAtt:Destroy(); functions.LVAtt=nil end

			local bv = Instance.new("BodyVelocity")
			bv.Name = "FlightBV"
			bv.velocity = Vector3.zero
			bv.maxForce = functions.BVMaxForce
			bv.Parent = HRP
			functions.BV = bv
		else
			if functions.LV then return end
			if functions.BV then functions.BV:Destroy(); functions.BV=nil end

			local att = ensureAttachment(HRP, "FlightAttachment")
			functions.LVAtt = att

			local lv = Instance.new("LinearVelocity")
			lv.Name = "FlightLV"
			lv.Attachment0 = att
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.VectorVelocity = Vector3.zero
			lv.MaxForce = functions.LVMaxForce
			lv.Parent = HRP
			functions.LV = lv
		end
	else
		if functions.BV then functions.BV:Destroy(); functions.BV=nil end
		if functions.LV then functions.LV:Destroy(); functions.LV=nil end
		if functions.LVAtt then functions.LVAtt:Destroy(); functions.LVAtt=nil end
	end
end

function functions.FlightStabilityForce(on: boolean, HRP: BasePart)
	if not functions.RotationEnabled then return end

	if on then
		if functions.AO then return end
		local att = HRP:FindFirstChild("FlightAttachment") or ensureAttachment(HRP, "FlightAttachment")
		functions.AOAtt = att

		local ao = Instance.new("AlignOrientation")
		ao.Name = "FlightAlignOrientation"
		ao.Attachment0 = att
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Responsiveness = functions.RotationResponsiveness
		ao.MaxTorque = functions.RotationMaxTorque
		ao.RigidityEnabled = false
		ao.Parent = HRP
		functions.AO = ao
	else
		if functions.AO then functions.AO:Destroy(); functions.AO=nil end
		if functions.AOAtt then functions.AOAtt:Destroy(); functions.AOAtt=nil end
	end
end

--------------------------------------------------------------------
-- SHIP ATTACH
--------------------------------------------------------------------
local function attachShipToPilot(ship: Model, HRP: BasePart)
	if not ship or not ship.PrimaryPart then return end
	unanchorModel(ship)

	local shipAtt = ship.PrimaryPart:FindFirstChild("ShipPilotAttach")
	if not (shipAtt and shipAtt:IsA("Attachment")) then
		shipAtt = Instance.new("Attachment")
		shipAtt.Name = "ShipPilotAttach"
		shipAtt.Parent = ship.PrimaryPart
	end

	HRP.CFrame = shipAtt.WorldCFrame

	local wc = Instance.new("WeldConstraint")
	wc.Name = "PilotShipWeld"
	wc.Part0 = HRP
	wc.Part1 = ship.PrimaryPart
	wc.Parent = HRP

	functions._ship = ship
	functions._shipWeld = wc
end

local function detachShip()
	if functions._shipWeld then
		functions._shipWeld:Destroy()
		functions._shipWeld = nil
	end
	functions._ship = nil
end

--------------------------------------------------------------------
-- CAMERA (RenderStepped)
--------------------------------------------------------------------
local function enableChaseCamera()
	local cam = workspace.CurrentCamera
	if not cam or functions._camEnabled then return end

	functions._camEnabled = true
	functions._prevCamType = cam.CameraType
	functions._prevCamSubject = cam.CameraSubject

	if functions.LockMouseToCenterWhileFlying then
		functions._prevMouseBehavior = UserInputService.MouseBehavior
		functions._prevMouseIcon = UserInputService.MouseIconEnabled
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end

	cam.CameraType = Enum.CameraType.Scriptable
	functions._camCF = cam.CFrame
end

local function disableChaseCamera()
	local cam = workspace.CurrentCamera
	if not cam or not functions._camEnabled then return end

	functions._camEnabled = false
	cam.CameraType = functions._prevCamType or Enum.CameraType.Custom
	cam.CameraSubject = functions._prevCamSubject

	if functions.LockMouseToCenterWhileFlying and functions._prevMouseBehavior then
		UserInputService.MouseBehavior = functions._prevMouseBehavior
		UserInputService.MouseIconEnabled = (functions._prevMouseIcon ~= nil) and functions._prevMouseIcon or true
	end

	functions._prevCamType = nil
	functions._prevCamSubject = nil
	functions._prevMouseBehavior = nil
	functions._prevMouseIcon = nil
	functions._camCF = nil
end

local function getCameraBasis(HRP: BasePart)
	local basisPos = HRP.Position
	local basisCF = HRP.CFrame
	if functions._ship and functions._ship.PrimaryPart then
		basisPos = functions._ship.PrimaryPart.Position
		basisCF = functions._ship.PrimaryPart.CFrame
	end
	return basisPos, basisCF
end

--------------------------------------------------------------------
-- MOUSE SCROLL ZOOM
--------------------------------------------------------------------
local function handleZoom(input: InputObject)
	if not PlayerState.IsFlying then return end

	local delta = -input.Position.Z
	functions._zoomDistanceTarget = math.clamp(
		functions._zoomDistanceTarget + (delta * functions.ZoomSpeed),
		functions.MinZoomDistance,
		functions.MaxZoomDistance
	)
end

local function setCharacterVisibility(character: Model, visible: boolean)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = visible and 0 or 1
		end
	end
end

function functions.CameraRenderStep(dt: number, HRP: BasePart)
	if not functions.UseScriptableChaseCamera then return end
	if not functions._camEnabled then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	if functions.CameraFov then cam.FieldOfView = functions.CameraFov end

	local basisPos, basisCF = getCameraBasis(HRP)

	local zoomAlpha = expSmoothing(functions.ZoomSmooth or 8, dt)
	functions._zoomDistance += (functions._zoomDistanceTarget - functions._zoomDistance) * zoomAlpha

	local player = game:GetService("Players").LocalPlayer

	-- RMB ORBIT CAMERA
	if functions._orbiting then
		if player and player.Character then
			setCharacterVisibility(player.Character, true)
		end

		local yaw = functions._orbitYaw
		local pitch = functions._orbitPitch

		local orbitCF = CFrame.fromOrientation(pitch, yaw, 0)
		local forward = orbitCF.LookVector

		local distance = math.max(functions._zoomDistance, 5)
		local desiredPos =
			basisPos
			+ (-forward) * distance
			+ (Vector3.yAxis) * (functions.OrbitHeight or 8)

		cam.CFrame = CFrame.lookAt(desiredPos, basisPos, Vector3.yAxis)
		functions._camCF = cam.CFrame
		return
	end

	-- FIRST PERSON / COCKPIT VIEW (zoom = 0)
	if functions._zoomDistance < 1 then
		if player and player.Character then
			setCharacterVisibility(player.Character, false)
		end

		local cockpitOffset = CFrame.new(0, 2, 0)

		if functions._ship and functions._ship.PrimaryPart then
			local cockpitAtt = functions._ship.PrimaryPart:FindFirstChild("CockpitView")
			if cockpitAtt and cockpitAtt:IsA("Attachment") then
				cam.CFrame = cockpitAtt.WorldCFrame
			else
				cam.CFrame = basisCF * cockpitOffset
			end
		else
			cam.CFrame = basisCF * cockpitOffset
		end

		functions._camCF = cam.CFrame
		return
	end

	if player and player.Character then
		setCharacterVisibility(player.Character, true)
	end

	-- NORMAL FLIGHT CHASE VIEW
	local aim = CFrame.fromOrientation(functions._aimPitchSm, functions._aimYawSm, 0)
	local forward = aim.LookVector
	local up = Vector3.yAxis

	local desiredPos =
		basisPos
		+ (-forward) * functions._zoomDistance
		+ (up) * functions.CameraHeight

	local lookAt =
		basisPos
		+ (forward) * functions.CameraLookAhead

	local desiredCF = CFrame.lookAt(desiredPos, lookAt, up)
	cam.CFrame = desiredCF
	functions._camCF = desiredCF
end

--------------------------------------------------------------------
-- RMB ORBIT HANDLING
--------------------------------------------------------------------
local function beginOrbit(HRP: BasePart)
	functions._orbiting = true

	local cam = workspace.CurrentCamera
	if cam and HRP then
		local basisPos, _ = getCameraBasis(HRP)
		local look = (basisPos - cam.CFrame.Position).Unit
		functions._orbitYaw = getYawFromLook(look)
		functions._orbitPitch = clampPitchRad(getPitchFromLook(look), functions.OrbitMaxPitchDegrees or 75)
	end
end

local function endOrbit()
	functions._orbiting = false
end

--------------------------------------------------------------------
-- AIM / ORBIT UPDATE (Heartbeat)
--------------------------------------------------------------------
local function updateAimOrOrbit(dt: number, HRP: BasePart)
	local md = UserInputService:GetMouseDelta()

	if functions._orbiting then
		local yawDelta = md.X * (functions.OrbitSensitivity or functions.MouseSensitivity or 0.0022)
		local pitchDelta = md.Y * (functions.OrbitSensitivity or functions.MouseSensitivity or 0.0022)

		if functions.InvertYaw then yawDelta = -yawDelta end
		if not functions.InvertPitch then pitchDelta = -pitchDelta end

		functions._orbitYaw += yawDelta
		functions._orbitPitch = clampPitchRad(functions._orbitPitch + pitchDelta, functions.OrbitMaxPitchDegrees or 75)
		return
	end

	local yawDelta = md.X * (functions.MouseSensitivity or 0.0022)
	local pitchDelta = md.Y * (functions.MouseSensitivity or 0.0022)

	if functions.InvertYaw then yawDelta = -yawDelta end
	if not functions.InvertPitch then pitchDelta = -pitchDelta end

	functions._lastYawDelta = yawDelta

	functions._aimYaw += yawDelta
	functions._aimPitch += pitchDelta
	functions._aimPitch = clampPitchRad(functions._aimPitch, functions.MaxPitchDegrees or 60)

	local a = expSmoothing(functions.AimSmoothing or 14, dt)
	functions._aimYawSm += (functions._aimYaw - functions._aimYawSm) * a
	functions._aimPitchSm += (functions._aimPitch - functions._aimPitchSm) * a

	if functions.TranslationMode == "Planar" then
		functions._aimPitchSm = 0
	end
end

--------------------------------------------------------------------
-- ROTATION TARGET (Heartbeat)
--------------------------------------------------------------------
local function updateRotationTarget(HRP: BasePart, dt: number)
	if not functions.AO then return end

	if functions._orbiting then
		return
	end

	local aimCF = CFrame.fromOrientation(functions._aimPitchSm, functions._aimYawSm, 0)
	local base = CFrame.lookAt(HRP.Position, HRP.Position + aimCF.LookVector, Vector3.yAxis)

	local bankInput = 0
	if functions.BankingEnabled then
		local strafe = math.clamp(functions._inS or 0, -1, 1)

		local yawDelta = functions._lastYawDelta or 0
		local strength = functions.BankStrength or 8
		local yawBank = math.clamp(
			yawDelta / ((functions.MouseSensitivity or 0.0022) * strength),
			-1, 1
		)

		local invertedYawBank = (functions.BankInvert and -yawBank or yawBank)
		local invertedStrafe = (functions.BankInvertStrafe and -strafe or strafe)

		local mode = functions.BankFrom or "Yaw"
		if mode == "Strafe" then
			bankInput = invertedStrafe
		elseif mode == "Blend" then
			local wS = functions.BankStrafeWeight or 0.65
			local wY = functions.BankYawWeight or 1.0
			bankInput = math.clamp(invertedYawBank * wY + invertedStrafe * wS, -1, 1)
		else
			bankInput = invertedYawBank
		end
	end

	local aBank = expSmoothing(functions.BankResponse or 10, dt)
	functions._bank += (bankInput - functions._bank) * aBank

	local rollRadians = math.rad(functions.MaxBankDegrees or 14) * functions._bank
	local yawOffset = math.rad(functions.ModelForwardYawOffsetDegrees or 0)

	functions.AO.CFrame = base * CFrame.Angles(0, 0, rollRadians) * CFrame.Angles(0, yawOffset, 0)
end

--------------------------------------------------------------------
-- DESIRED VELOCITY (Heartbeat)
--------------------------------------------------------------------
local function computeDesiredVelocity(speed: number): Vector3
	local aimCF = CFrame.fromOrientation(0, functions._aimYawSm, 0)

	local forward: Vector3
	if functions.TranslationMode == "FullCamera" then
		aimCF = CFrame.fromOrientation(functions._aimPitchSm, functions._aimYawSm, 0)
		forward = aimCF.LookVector
	else
		forward = aimCF.LookVector
	end

	local up: Vector3
	if functions.VerticalMode == "CameraUp" and functions.TranslationMode == "FullCamera" then
		up = aimCF.UpVector
	else
		up = Vector3.yAxis
	end

	if forward.Magnitude < 1e-4 then
		return Vector3.zero
	end
	forward = forward.Unit
	up = up.Unit

	local right: Vector3

	local dot = math.abs(forward:Dot(up))
	if dot > 0.99 then
		right = aimCF.RightVector
		up = right:Cross(forward).Unit
	else
		right = forward:Cross(up)

		if right.Magnitude < 0.1 then
			warn("[FLIGHT] Cross product failed, using camera right vector")
			right = aimCF.RightVector
			up = right:Cross(forward).Unit
		else
			right = right.Unit
		end
	end

	local f = functions._inF or 0
	local s = functions._inS or 0
	local u = functions._inU or 0

	local worldUp = Vector3.yAxis

	local dir =
		(forward * f) +
		(right   * s) +
		(worldUp * (u * functions.VerticalSpeedMult))

	local mag = dir.Magnitude
	if mag < 1e-4 then
		return Vector3.zero
	end

	if mag > 1 then
		dir = dir / mag
	end

	if dir ~= dir or math.abs(dir.X) == math.huge or math.abs(dir.Y) == math.huge or math.abs(dir.Z) == math.huge then
		warn("[FLIGHT] Invalid direction vector detected, returning zero")
		return Vector3.zero
	end

	return dir * speed
end

--------------------------------------------------------------------
-- TOGGLES
--------------------------------------------------------------------
function functions.ToggleFlightForceMode(HRP: BasePart?)
	functions.FlightForceMode = (functions.FlightForceMode == "BodyVelocity") and "LinearVelocity" or "BodyVelocity"
	print("[Flight] Force Mode:", functions.FlightForceMode)
	if HRP then
		functions.FlightControlForce(false, HRP)
		functions.FlightControlForce(true, HRP)
	end
end

function functions.ToggleTranslationMode()
	functions.TranslationMode = (functions.TranslationMode == "Planar") and "FullCamera" or "Planar"
	print("[Flight] Translation Mode:", functions.TranslationMode)
end

function functions.ToggleVerticalMode()
	functions.VerticalMode = (functions.VerticalMode == "WorldUp") and "CameraUp" or "WorldUp"
	print("[Flight] Vertical Mode:", functions.VerticalMode)
end

function functions.ToggleBrake()
	functions._braking = not functions._braking
end

function functions.ExitShip()
	if functions._exitDebounce then
		print("[ExitShip] Debounced - ignoring rapid call")
		return
	end
	functions._exitDebounce = true
	task.delay(0.5, function()
		functions._exitDebounce = false
	end)

	if not PlayerState.IsFlying then
		print("[ExitShip] Not flying - ignoring exit request")
		functions._exitDebounce = false
		return
	end

	local player = game:GetService("Players").LocalPlayer
	local char = player.Character
	if not char then
		functions._exitDebounce = false
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local HRP = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not HRP then
		functions._exitDebounce = false
		return
	end

	local canEVA = EVAFunctions.CanEVA(player)

	local nearGround = false
	if not canEVA then
		local rayOrigin = HRP.Position
		local rayDirection = Vector3.new(0, -100, 0)

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {char, functions._ship}

		local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		nearGround = rayResult and (rayResult.Distance < 10)
		print("TEST Distance from ground:", rayResult.Distance)
		if not nearGround then
			warn("[ExitShip] Cannot exit - not in space and not near ground!")
			print("[ExitShip] You must land the ship first!")
			functions._exitDebounce = false
			return
		end
	end

	PlayerState.ChangeState(PlayerState.States.Falling)

	print("[ExitShip] Exiting ship", canEVA and "(entering EVA)" or "(landing on ground)")

	local exitOffset = Vector3.new(5, 2, 0)
	if functions._ship and functions._ship.PrimaryPart then
		local shipCF = functions._ship.PrimaryPart.CFrame
		local exitPos = (shipCF * CFrame.new(exitOffset)).Position
		local _, yaw, _ = shipCF:ToEulerAnglesYXZ()
		HRP.CFrame = CFrame.new(exitPos) * CFrame.Angles(0, yaw, 0)
		HRP.AssemblyLinearVelocity = Vector3.zero
		HRP.AssemblyAngularVelocity = Vector3.zero
	end

	local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
	local ExitShip = Remotes:FindFirstChild("ExitShip")
	if ExitShip then
		ExitShip:FireServer(functions._ship)
	end

	functions.StopFlying(humanoid, HRP)

	task.wait(0.1)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

	if canEVA then
		print("[EVA] Entering EVA mode - in space")
		EVAFunctions.StartEVA(humanoid, HRP)
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		print("[ExitShip] Exited on ground - mouse unlocked")
	end
end

--------------------------------------------------------------------
-- POWER ENGINEERING
--------------------------------------------------------------------
function functions.GetEffectivePower(rawPower, systemId)
	local skillLevel = playerInfo.Attributes["PowerEngineering"] or 0
	local standardThreshold = POWER_ENG_STANDARD_THRESHOLD[skillLevel] or 25

	return math.min(rawPower, 100), standardThreshold
end

--------------------------------------------------------------------
-- SENSOR POWER
--------------------------------------------------------------------
function functions.HandleSensorPower()
	----Sensors---
	--0% — blind: no minimap, no AR
	--1–stdThreshold% — passive only: Radar only, Range % of standard
	--stdThreshold–74% — standard: full range, enemy stats visible, loot markers active
	--75–99% — enhanced: Range 125%
	--100% — omniscient: Range 150%
	local effectivePower, stdThreshold = functions.GetEffectivePower(functions.SensorSystemPower, 4)

	if effectivePower == 0 then
		functions.ActiveSensorRange = 0
	elseif effectivePower < stdThreshold then
		local t = math.clamp(effectivePower / stdThreshold, 0, 1)
		functions.ActiveSensorRange = functions.MaxSensorRange * t
	elseif effectivePower <= 74 then
		functions.ActiveSensorRange = functions.MaxSensorRange
	elseif effectivePower <= 99 then
		functions.ActiveSensorRange = functions.MaxSensorRange * 1.25
	else
		functions.ActiveSensorRange = functions.MaxSensorRange * 1.5
	end
end

function functions.UpdateSensorRange(ship)
	print("TEST UPDATE SENSOR RANGE")
	local sensorName = ship:GetAttribute("SensorName")
	if not sensorName then return end
	local sensorDef = shipPartsDef[sensorName]
	if not sensorDef then return end

	local sensorRange = sensorDef.SensorRange
	local sensorAR = sensorDef.SensorAR
	local sensorARIdentityType = sensorDef.SensorARIdentityType
	local sensorARThreatEval = sensorDef.SensorARThreatEval
	local sensorARHullAndShieldHealth = sensorDef.SensorARHullAndShieldHealth

	functions.MaxSensorRange = sensorRange
	functions.HandleSensorPower()

	local effectivePower, stdThreshold = functions.GetEffectivePower(functions.SensorSystemPower, 4)

	print("TEST UPDATE SENSOR RANGE. UPDATED: SensorSystemPower: ", functions.SensorSystemPower, ", MaxSensorRange:", functions.MaxSensorRange, ", ActiveSensorRange:", functions.ActiveSensorRange)

	for _, sensorTarget in ipairs(CollectionService:GetTagged("SensorTarget")) do
		local gui = sensorTarget:FindFirstChildWhichIsA("BillboardGui", true)
		if gui then
			gui.MaxDistance = functions.ActiveSensorRange

			if sensorAR and effectivePower >= stdThreshold then
				gui.HealthBarFrame.Visible = sensorARHullAndShieldHealth
				gui.TypeFrame.TypeLabel.Visible = sensorARIdentityType and true or false
				gui.TypeFrame.XFrame.Level.Text = sensorARThreatEval and 2 or ""
			else
				gui.TypeFrame.TypeLabel.Visible = false
				gui.TypeFrame.XFrame.Level.Text = ""
				gui.HealthBarFrame.Visible = false
			end
		end
	end
end

--------------------------------------------------------------------
-- ENGINE POWER
--------------------------------------------------------------------
function functions.UpdateEngine(ship)
	print("TEST UPDATE ENGINE")
	local engineName = ship:GetAttribute("EngineName")

	if not engineName then return end

	local engineDef = shipPartsDef[engineName]
	if not engineDef then return end

	local speed = engineDef.EngineSpeed
	local boost = engineDef.EngineBoost
	local acceleration = engineDef.EngineAcceleration
	local brakeStrength = engineDef.EngineBrakeStrength

	functions.MaxBaseSpeed = speed
	functions.MaxBoostSpeed = boost
	functions.AccelResponse = acceleration
	functions.BrakeDampMult = brakeStrength

	----Engine---
	--0% — truly offline, no movement
	--1–stdThreshold% — reduced: scales linearly
	--stdThreshold–74% — standard: full speed, normal boost
	--75–99% — boosted: +20% top speed & boost
	--100% — afterburn: +50% speed
	local effectivePower, stdThreshold = functions.GetEffectivePower(functions.EngineSystemPower, 3)

	if effectivePower == 0 then
		functions.ActiveBaseSpeed = 0
		functions.ActiveBoostSpeed = 0
	elseif effectivePower < stdThreshold then
		local t = math.clamp(effectivePower / stdThreshold, 0, 1)
		functions.ActiveBaseSpeed = functions.MaxBaseSpeed * t
		functions.ActiveBoostSpeed = functions.MaxBoostSpeed * t
	elseif effectivePower <= 74 then
		functions.ActiveBaseSpeed = functions.MaxBaseSpeed
		functions.ActiveBoostSpeed = functions.MaxBoostSpeed
	elseif effectivePower <= 99 then
		functions.ActiveBaseSpeed = functions.MaxBaseSpeed * 1.2
		functions.ActiveBoostSpeed = functions.MaxBoostSpeed * 1.2
	else
		functions.ActiveBaseSpeed = functions.MaxBaseSpeed * 1.5
		functions.ActiveBoostSpeed = functions.MaxBoostSpeed * 1.5
	end

	print("TEST UPDATE ENGINE. UPDATED: EngineSystemPower: ", functions.EngineSystemPower, ", MaxBaseSpeed:", functions.MaxBaseSpeed, ", ActiveBaseSpeed:", functions.ActiveBaseSpeed, ", ActiveBoostSpeed:", functions.ActiveBoostSpeed)
end

--------------------------------------------------------------------
-- TARGETING
--------------------------------------------------------------------
function functions.ClearTarget()
	-- hide TargetBracket on old target's BillboardGui
	if functions._currentTarget then
		local primary = functions._currentTarget.PrimaryPart
		if primary then
			local gui = primary:FindFirstChildWhichIsA("BillboardGui", true)
			if gui then
				local bracket = gui:FindFirstChild("TargetBracket")
				if bracket then bracket.Visible = false end
			end
		end
		functions._currentTarget = nil
	end

	-- remove 3D selection box
	if functions._selectionBox then
		functions._selectionBox:Destroy()
		functions._selectionBox = nil
	end
end

function functions.SetTarget(ship)
	functions.ClearTarget()
	functions._currentTarget = ship

	-- 3D selection box around the target ship
	local box = Instance.new("SelectionBox")
	box.Adornee = ship
	box.Color3 = Color3.fromRGB(255, 50, 68)
	box.LineThickness = 0.04
	box.SurfaceTransparency = 0.9
	box.SurfaceColor3 = Color3.fromRGB(255, 50, 68)
	box.Parent = workspace
	functions._selectionBox = box

	-- show TargetBracket on the new target's BillboardGui if it exists
	local primary = ship.PrimaryPart
	if primary then
		local gui = primary:FindFirstChildWhichIsA("BillboardGui", true)
		if gui then
			local bracket = gui:FindFirstChild("TargetBracket")
			if bracket then bracket.Visible = true end
		end
	end

	print("[Target] Locked:", ship.Name)
end

function functions.CycleTarget()
	local shipPos = functions._ship and functions._ship.PrimaryPart
		and functions._ship.PrimaryPart.Position
	if not shipPos then return end

	-- gather all valid targets within sensor range, sorted by distance
	local candidates = {}
	for _, target in ipairs(CollectionService:GetTagged("EnemyShip")) do
		local primary = target:IsA("Model") and target.PrimaryPart
		if primary then
			local dist = (primary.Position - shipPos).Magnitude
			if dist <= functions.ActiveSensorRange then
				table.insert(candidates, {ship = target, dist = dist})
			end
		end
	end
	table.sort(candidates, function(a, b) return a.dist < b.dist end)

	if #candidates == 0 then
		functions.ClearTarget()
		print("[Target] No targets in sensor range")
		return
	end

	-- find current target index and advance to next, wrapping around
	local currentIndex = 0
	for i, c in ipairs(candidates) do
		if c.ship == functions._currentTarget then
			currentIndex = i
			break
		end
	end
	currentIndex = (currentIndex % #candidates) + 1
	functions.SetTarget(candidates[currentIndex].ship)
end

-- Returns the lead position to aim at for the current target given a bullet speed.
-- Returns nil if there is no target or ship.
-- Use workspace.CurrentCamera:WorldToScreenPoint(pos) to place a screen reticle.
function functions.GetLeadPosition(bulletSpeed: number)
	if not functions._currentTarget or not functions._ship then return nil end
	local targetPart = functions._currentTarget.PrimaryPart
	local shipPart = functions._ship.PrimaryPart
	if not targetPart or not shipPart then return nil end

	local relPos = targetPart.Position - shipPart.Position
	local relVel = targetPart.AssemblyLinearVelocity - shipPart.AssemblyLinearVelocity
	local dist = relPos.Magnitude
	local leadTime = dist / math.max(bulletSpeed, 1)
	return targetPart.Position + relVel * leadTime
end

--------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------
function functions.StartFlying(humanoid: Humanoid, HRP: BasePart, pilotedShip: Model)
	Logger.Debug("SpaceFlightFunctions.StartFlying called")

	EVAFunctions.ForceCleanup(HRP)

	PlayerState.IsFlying = true
	functions.EnableStates(false, humanoid)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	local char = humanoid.Parent
	if char then
		local runningSound = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("Running", true)
		if runningSound and runningSound:IsA("Sound") then
			functions._prevRunningSoundVolume = runningSound.Volume
			runningSound.Volume = 0
		end
	end

	local cam = workspace.CurrentCamera
	if cam then
		local look = cam.CFrame.LookVector
		functions._aimYaw = getYawFromLook(look)
		functions._aimPitch = clampPitchRad(getPitchFromLook(look), functions.MaxPitchDegrees or 60)
		functions._aimYawSm = functions._aimYaw
		functions._aimPitchSm = (functions.TranslationMode == "Planar") and 0 or functions._aimPitch
	end

	functions._targetVel = Vector3.zero
	functions._bank = 0
	functions._inF, functions._inS, functions._inU = 0, 0, 0
	functions._orbiting = false

	functions._zoomDistance = functions.CameraDistance
	functions._zoomDistanceTarget = functions.CameraDistance

	if pilotedShip then
		attachShipToPilot(pilotedShip, HRP)
	end

	functions.FlightControlForce(true, HRP)
	functions.FlightStabilityForce(true, HRP)

	if functions.UseScriptableChaseCamera then
		enableChaseCamera()
	end

	for _, conn in ipairs(functions._inputConnections) do
		conn:Disconnect()
	end
	functions._inputConnections = {}
	print("[StartFlying] Cleared old input connections")

	table.insert(functions._inputConnections, UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if not PlayerState.IsFlying then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			beginOrbit(HRP)
		end
	end))

	table.insert(functions._inputConnections, UserInputService.InputEnded:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			endOrbit()
		end
	end))

	table.insert(functions._inputConnections, UserInputService.InputChanged:Connect(function(input, gp)
		if gp then return end
		if not PlayerState.IsFlying then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			handleZoom(input)
		end
	end))

	functions.UpdateSensorRange(pilotedShip)
	functions.UpdateEngine(pilotedShip)

	PlayerState.ChangeState(PlayerState.States.Flying)
end

function functions.StopFlying(humanoid: Humanoid, HRP: BasePart)
	Logger.Debug("SpaceFlightFunctions.StopFlying called")

	-- clear targeting on exit
	functions.ClearTarget()

	disableChaseCamera()
	detachShip()

	functions.FlightStabilityForce(false, HRP)
	functions.FlightControlForce(false, HRP)

	functions._targetVel = Vector3.zero
	functions._bank = 0
	functions._inF, functions._inS, functions._inU = 0, 0, 0

	functions._orbiting = false

	humanoid.PlatformStand = false
	humanoid.AutoRotate = true

	functions.EnableStates(true, humanoid)

	local char = humanoid.Parent
	if char then
		local runningSound = char:FindFirstChild("HumanoidRootPart"):FindFirstChild("Running", true)
		if runningSound and runningSound:IsA("Sound") and functions._prevRunningSoundVolume then
			runningSound.Volume = functions._prevRunningSoundVolume
			functions._prevRunningSoundVolume = nil
		end
	end

	for _, conn in ipairs(functions._inputConnections) do
		conn:Disconnect()
	end
	functions._inputConnections = {}

	PlayerState.IsFlying = false

	functions._throttle = 0

	functions._zoomDistance = functions.CameraDistance
	functions._zoomDistanceTarget = functions.CameraDistance
end

-- CALL THIS FROM Heartbeat(dt)
function functions.FlightHeartbeat(dt: number, humanoid: Humanoid, HRP: BasePart)
	if not humanoid or not HRP then return end
	dt = math.min(dt, 0.033)

	if functions._ship then
		local shipStillValid = functions._ship.Parent ~= nil and functions._ship.PrimaryPart ~= nil
		local weldStillValid = functions._shipWeld and functions._shipWeld.Parent ~= nil

		if not shipStillValid then
			warn("[Flight] Ship was destroyed! Stopping flight mode...")
			functions.StopFlying(humanoid, HRP)
			return
		end

		if not weldStillValid then
			warn("[Flight] Ship weld broke!")
			if shipStillValid then
				warn("[Flight] Ship exists but weld broke - stopping flight")
				functions.StopFlying(humanoid, HRP)
			end
			return
		end
	end

	-- auto-clear target if it goes out of sensor range or is destroyed
	if functions._currentTarget then
		local primary = functions._currentTarget.PrimaryPart
		if not primary or not functions._currentTarget.Parent then
			functions.ClearTarget()
		elseif functions._ship and functions._ship.PrimaryPart then
			local dist = (primary.Position - functions._ship.PrimaryPart.Position).Magnitude
			if dist > functions.ActiveSensorRange then
				functions.ClearTarget()
				print("[Target] Target out of sensor range, cleared")
			end
		end
	end

	updateAimOrOrbit(dt, HRP)

	local rawF = axis(Enum.KeyCode.S, Enum.KeyCode.W)
	local rawS = axis(Enum.KeyCode.A, Enum.KeyCode.D)
	local rawU = axis(Enum.KeyCode.LeftControl, Enum.KeyCode.Space)

	if functions.ThrottleMode then
		if rawF > 0 then
			functions._throttle = math.clamp(functions._throttle + (functions.ThrottleAccel or 2) * dt, 0, 1)
		elseif rawF < 0 then
			functions._throttle = math.clamp(functions._throttle - (functions.ThrottleAccel or 2) * dt, 0, 1)
		else
			if (functions.ThrottleDecay or 0) > 0 then
				functions._throttle = math.max(0, functions._throttle - (functions.ThrottleDecay or 1) * dt)
			end
		end

		functions._inF = functions._throttle
		functions._inS = rawS
		functions._inU = rawU
	else
		functions._inF = rawF
		functions._inS = rawS
		functions._inU = rawU
	end

	local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)

	-- Disable boost if engines are too low powered OR boost speed is unavailable
	if functions.EngineSystemPower <= 10 or functions.ActiveBoostSpeed == 0 then
		boosting = false
	end

	-- Use ActiveBaseSpeed/ActiveBoostSpeed directly — calculated by UpdateEngine()
	-- with skill thresholds applied. ActiveBaseSpeed is 0 when engines are offline.
	local speed = boosting and functions.ActiveBoostSpeed or functions.ActiveBaseSpeed

	local desiredVel = computeDesiredVelocity(speed)
	local hasInput = desiredVel.Magnitude > 1e-3

	if functions._braking then
		boosting = false
		if functions.ThrottleMode then
			functions._throttle = 0
			functions._inF = 0
		end
		desiredVel = Vector3.zero
		hasInput = false
	end

	local a = expSmoothing(functions.AccelResponse or 6, dt)
	functions._targetVel = functions._targetVel:Lerp(desiredVel, a)

	if functions.GlideEnabled then
		local dampMult = 1
		if functions._braking then
			dampMult = dampMult * (functions.BrakeDampMult or 4.0)
		end
		if (not hasInput) or functions._braking then
			local dampK = (functions.LinearDamp or 0.45) * dampMult
			local mul = math.exp(-dampK * dt)
			functions._targetVel *= mul
			if functions._targetVel.Magnitude < (functions.MinStopSpeed or 0.05) then
				functions._targetVel = Vector3.zero
			end
		end
	end

	if functions.FlightForceMode == "BodyVelocity" then
		if functions.BV then
			functions.BV.velocity = functions._targetVel
		end
	else
		if functions.LV then
			functions.LV.VectorVelocity = functions._targetVel
			functions.LV.MaxForce = boosting and functions.LVMaxForceBoost or functions.LVMaxForce
		end
	end

	updateRotationTarget(HRP, dt)
end

functions.EnableChaseCamera = enableChaseCamera
functions.DisableChaseCamera = disableChaseCamera

function functions.UpdatePowerState(powerState)
	functions.WeaponSystemPower = powerState.weapons
	functions.ShieldSystemPower = powerState.shields
	functions.EngineSystemPower = powerState.engines
	functions.SensorSystemPower = powerState.sensors
	functions.LifeSupportSystemPower = powerState.lifesup
	functions.CommSystemPower = powerState.comms

	if functions._ship then
		functions.UpdateSensorRange(functions._ship)
		functions.UpdateEngine(functions._ship)
	end
end

-- NOTE: ShipPowerPanelChanged event listener removed.
-- UpdatePowerState is called directly from computePower() in the HUD script,
-- which is the single source of truth.

return functions