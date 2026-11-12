local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerMouse = Player:GetMouse()

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local CurrentHeldToolChangedEvent = Remotes:WaitForChild("CurrentHeldToolChanged")
local GetWeaponSourceEvent = Remotes:WaitForChild("GetWeaponSource")

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local AimTarget = require(script.Parent:WaitForChild("AimTarget"))
local weaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

local Camera = workspace.CurrentCamera

local BodyPartsLocations = {
	GunHandle = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Clavicle_R",
		"Shoulder_R",
		"Elbow_R",
		"Hand_R",
		"NerdGunHandle"
	};

	Head = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Neck",
		"Head"
	};

	HeadMotor6D = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Neck",
		"Head"
	};

	Neck = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Neck"
	};

	Torso = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_02"
	};

	Waist = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01"
	};

	RightShoulder = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Clavicle_R",
		"Shoulder_R"
	};

	LeftShoulder = {
		"HumanoidRootPart",
		"Root",
		"Hips",
		"Spine_01",
		"Spine_02",
		"Spine_03",
		"Clavicle_L",
		"Shoulder_L"
	};
}

local Character = nil
local Humanoid = nil
local root = nil

local Head = nil
local Hips = nil
local Neck = nil
local Torso = nil
local Waist = nil
local RightShoulder = nil
local LeftShoulder = nil
local RightHand = nil

local NeckOriginC0 = nil
local WaistOriginC0 = nil
local TorsoOriginC0 = nil
local RightOriginC0 = nil
local LeftOriginC0 = nil
local shoulderAimCorrection = CFrame.new()

local cframe = CFrame.new
local angles = CFrame.Angles
local clamp = math.clamp

local rangedWeaponEquipped = false
local currentHeldWeapon = nil

local debugBeamPart = nil :: Part?
local debugBeamEnabled = false
local muzzleCF = nil :: CFrame?
local muzzle = nil

---------------------------------------------------------------------- 
-- Character / rig reference helpers
----------------------------------------------------------------------

local function getByPath(parent, path)
	local current = parent

	for _, partName in ipairs(path) do
		if not current then
			return nil
		end

		current = current:FindFirstChild(partName)

		if not current then
			return nil
		end
	end

	return current
end

local function resetAimState()
	muzzle = nil
	muzzleCF = nil
	rangedWeaponEquipped = false
	currentHeldWeapon = nil
	shoulderAimCorrection = CFrame.new()

	if debugBeamPart then
		debugBeamPart.Transparency = 1
	end
end

local function rebuildCharacterRefs(character)
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
	root = Character:WaitForChild("HumanoidRootPart")

	Head = getByPath(Character, BodyPartsLocations.HeadMotor6D)
		or getByPath(Character, BodyPartsLocations.Head)
		or Character:FindFirstChild("Head", true)

	Hips = getByPath(Character, {
		"HumanoidRootPart",
		"Root",
		"Hips"
	})

	Neck = getByPath(Character, BodyPartsLocations.Neck)
		or Character:FindFirstChild("Neck", true)

	Torso = getByPath(Character, BodyPartsLocations.Torso)
		or Character:FindFirstChild("Spine_02", true)

	Waist = getByPath(Character, BodyPartsLocations.Waist)
		or Character:FindFirstChild("Spine_01", true)

	RightShoulder = getByPath(Character, BodyPartsLocations.RightShoulder)
		or Character:FindFirstChild("Shoulder_R", true)

	LeftShoulder = getByPath(Character, BodyPartsLocations.LeftShoulder)
		or Character:FindFirstChild("Shoulder_L", true)

	RightHand = nil

	if RightShoulder then
		local elbow = RightShoulder:FindFirstChild("Elbow_R")
		if elbow then
			RightHand = elbow:FindFirstChild("Hand_R")
		end
	end

	if not RightHand then
		RightHand = Character:FindFirstChild("Hand_R", true)
	end

	if Neck then
		NeckOriginC0 = Neck.CFrame
	else
		NeckOriginC0 = nil
	end

	if Waist then
		WaistOriginC0 = Waist.CFrame
	else
		WaistOriginC0 = nil
	end

	if Torso then
		TorsoOriginC0 = Torso.CFrame
	else
		TorsoOriginC0 = nil
	end

	if RightShoulder then
		RightOriginC0 = RightShoulder.CFrame
	else
		RightOriginC0 = nil
	end

	if LeftShoulder then
		LeftOriginC0 = LeftShoulder.CFrame
	else
		LeftOriginC0 = nil
	end

	resetAimState()
end

local function restoreAimPose()
	if Neck and NeckOriginC0 then
		Neck.CFrame = NeckOriginC0
	end

	if Waist and WaistOriginC0 then
		Waist.CFrame = WaistOriginC0
	end

	if Torso and TorsoOriginC0 then
		Torso.CFrame = TorsoOriginC0
	end

	if RightShoulder and RightOriginC0 then
		RightShoulder.CFrame = RightOriginC0
	end
	shoulderAimCorrection = CFrame.new()

	if LeftShoulder and LeftOriginC0 then
		LeftShoulder.CFrame = LeftOriginC0
	end
end

local function captureAimPose()
	if Waist then
		WaistOriginC0 = Waist.CFrame
	end

	if Torso then
		TorsoOriginC0 = Torso.CFrame
	end

	shoulderAimCorrection = CFrame.new()
end

local function findWeaponMuzzle(toolName)
	if not Character or toolName == nil then
		return nil
	end

	local handle = nil

	if RightHand then
		handle = RightHand:FindFirstChild(toolName .. "Handle")
	end

	if not handle then
		local toolModel = Character:FindFirstChild(toolName)
		if toolModel then
			handle = toolModel:FindFirstChild(toolName .. "Handle")
		end
	end

	if not handle then
		handle = Character:FindFirstChild(toolName .. "Handle", true)
	end

	if not handle then
		return nil
	end

	local firePart = handle:FindFirstChild("Muzzle")

	if firePart then
		return firePart
	end

	return handle
end

---------------------------------------------------------------------- 
-- Initial character setup
----------------------------------------------------------------------

rebuildCharacterRefs(Player.Character or Player.CharacterAdded:Wait())

Player.CharacterAdded:Connect(function(character)
	rebuildCharacterRefs(character)
end)

local function getWorldCFrame(instance): CFrame?
	if instance:IsA("Attachment") then
		return instance.WorldCFrame
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	return nil
end

local function getParentWorldCFrame(instance): CFrame?
	local parent = instance.Parent

	if not parent then
		return nil
	end

	if parent:IsA("Bone") then
		return parent.TransformedWorldCFrame
	end

	if parent:IsA("Attachment") then
		return parent.WorldCFrame
	end

	if parent:IsA("BasePart") then
		return parent.CFrame
	end

	return nil
end

local function applyShoulderCorrection(targetPos: Vector3)
	if not RightShoulder or not RightOriginC0 or not muzzle or not muzzle.Parent then
		return
	end

	local muzzleCf = getWorldCFrame(muzzle)
	local parentWorldCf = getParentWorldCFrame(RightShoulder)

	if not muzzleCf or not parentWorldCf then
		return
	end

	local toTarget = targetPos - muzzleCf.Position

	if toTarget.Magnitude < 0.001 then
		return
	end

	local currentDirection = muzzleCf.LookVector.Unit
	local desiredDirection = toTarget.Unit
	local dot = clamp(currentDirection:Dot(desiredDirection), -1, 1)
	local angle = math.acos(dot)

	if angle < math.rad(0.1) then
		RightShoulder.CFrame =
			CFrame.new(RightOriginC0.Position)
			* shoulderAimCorrection
			* RightOriginC0.Rotation
		return
	end

	local axis = currentDirection:Cross(desiredDirection)

	if axis.Magnitude < 0.0001 then
		return
	end

	-- The muzzle transform is finalized after this render step, so solving the
	-- entire error at once creates a one-frame feedback loop. Accumulate only a
	-- small part of the residual error and keep it between frames instead.
	local maxShoulderCorrection = math.rad(25)
	local maxCorrectionStep = math.rad(3)
	local correctionGain = 0.25
	local localAxis = parentWorldCf:VectorToObjectSpace(axis.Unit)
	local correctionStep = math.min(angle * correctionGain, maxCorrectionStep)
	local nextCorrection = CFrame.fromAxisAngle(localAxis, correctionStep) * shoulderAimCorrection
	local correctionAxis, correctionAngle = nextCorrection:ToAxisAngle()

	if correctionAngle > maxShoulderCorrection then
		nextCorrection = CFrame.fromAxisAngle(correctionAxis, maxShoulderCorrection)
	end

	shoulderAimCorrection = nextCorrection

	RightShoulder.CFrame =
		CFrame.new(RightOriginC0.Position)
		* shoulderAimCorrection
		* RightOriginC0.Rotation
end

local function applySupportShoulderCorrection()
	if not LeftShoulder or not LeftOriginC0 or not RightShoulder then
		return
	end

	local rightParentWorldCf = getParentWorldCFrame(RightShoulder)
	local leftParentWorldCf = getParentWorldCFrame(LeftShoulder)

	if not rightParentWorldCf or not leftParentWorldCf then
		return
	end

	-- Convert the weapon shoulder's accumulated correction into world space,
	-- then into the support shoulder's parent space. This keeps the authored
	-- two-hand pose moving as one unit without independently solving either hand.
	local worldCorrection =
		rightParentWorldCf.Rotation
		* shoulderAimCorrection
		* rightParentWorldCf.Rotation:Inverse()
	local leftLocalCorrection =
		leftParentWorldCf.Rotation:Inverse()
		* worldCorrection
		* leftParentWorldCf.Rotation

	LeftShoulder.CFrame =
		CFrame.new(LeftOriginC0.Position)
		* leftLocalCorrection
		* LeftOriginC0.Rotation
end

---------------------------------------------------------------------- 
-- Debug beam support
----------------------------------------------------------------------

local function ensureDebugBeamPart(): Part
	if debugBeamPart and debugBeamPart.Parent then
		return debugBeamPart
	end

	local p = Instance.new("Part")
	p.Name = "AimDebugBeam"
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.05, 0.05, 1)
	p.Color = Color3.new(1, 0, 0)
	p.Material = Enum.Material.Neon
	p.CastShadow = false
	p.Transparency = 0.2
	p.Parent = workspace

	debugBeamPart = p
	return p
end

local function SetDebugBeamEnabled(enabled: boolean)
	debugBeamEnabled = enabled

	if not enabled and debugBeamPart then
		debugBeamPart:Destroy()
		debugBeamPart = nil
	end
end

_G.SetAimDebugBeamEnabled = SetDebugBeamEnabled

---------------------------------------------------------------------- 
-- State helpers
----------------------------------------------------------------------

local function IsMoving(): boolean
	return Humanoid ~= nil and Humanoid.MoveDirection.Magnitude > 0.05
end

local function IsInAir(s)
	if not s then
		return false
	end

	local n = s.Name

	return n == PlayerState.States.Jumping.Name
		or n == PlayerState.States.Falling.Name
		or n == PlayerState.States.RunningJump.Name
		or n == PlayerState.States.DoubleJump.Name
end

local function canAim()
	if not rangedWeaponEquipped then
		return false
	end

	if not Character or not Character.Parent then
		return false
	end

	if not Humanoid or not root then
		return false
	end

	if not Neck or not Waist or not Head or not Torso then
		return false
	end
	
	if Character:GetAttribute("Dead") then
		if Humanoid then
			Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
		end

		restoreAimPose()
		return false
	end

	if PlayerState.Crawling then
		return false
	end

	if IsMoving() then
		return false
	end

	if IsInAir(PlayerState.CurrentState) then
		return false
	end

	return true
end

---------------------------------------------------------------------- 
-- Main aim loop
----------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	if not rangedWeaponEquipped then
		muzzleCF = nil

		if debugBeamPart then
			debugBeamPart.Transparency = 1
		end

		return
	end

	if not canAim() then
		return
	end

	if not Camera.CameraSubject then
		return
	end

	local subjectIsCharacter =
		Camera.CameraSubject:IsDescendantOf(Character)
		or Camera.CameraSubject:IsDescendantOf(Player)

	if not subjectIsCharacter then
		return
	end

	local Point = AimTarget.GetTarget(
		Camera,
		AimTarget.GetScreenPoint(PlayerMouse),
		Character
	)

	------------------------------------------------------------------
	-- 0) Turn the root only as far as necessary, leaving bounded yaw
	--    for the upper body so third-person aiming remains visible.
	------------------------------------------------------------------

	local localTarget = root.CFrame:PointToObjectSpace(Point)
	local horizontalDistance = Vector2.new(localTarget.X, localTarget.Z).Magnitude
	local bodyYaw = math.atan2(-localTarget.X, -localTarget.Z)
	local bodyPitch = math.atan2(localTarget.Y, math.max(horizontalDistance, 0.001))

	local maxBodyYaw = math.rad(45)
	local maxBodyPitch = math.rad(55)
	local torsoYaw = clamp(bodyYaw, -maxBodyYaw, maxBodyYaw)
	local rootYaw = bodyYaw - torsoYaw

	if math.abs(rootYaw) > math.rad(0.1) then
		root.CFrame = root.CFrame * angles(0, rootYaw, 0)
	end

	bodyPitch = clamp(bodyPitch, -maxBodyPitch, maxBodyPitch)

	if Waist and WaistOriginC0 then
		Waist.CFrame = WaistOriginC0 * angles(bodyPitch * 0.65, torsoYaw * 0.65, 0)
	end

	if Torso and TorsoOriginC0 then
		Torso.CFrame = TorsoOriginC0 * angles(bodyPitch * 0.35, torsoYaw * 0.35, 0)
	end

	------------------------------------------------------------------
	-- 1) Use the shoulder for the remaining muzzle error. The holding
	--    animation still drives Bone.Transform; this adjusts the bone's
	--    base CFrame underneath that animated pose.
	------------------------------------------------------------------

	if muzzle and muzzle.Parent then
		applyShoulderCorrection(Point)
		applySupportShoulderCorrection()
	else
		muzzle = findWeaponMuzzle(currentHeldWeapon)
	end

	------------------------------------------------------------------
	-- 2) Update weapon source + muzzle CFrame for actual firing
	------------------------------------------------------------------

	muzzleCF = nil

	if muzzle and muzzle.Parent then
		local src

		if muzzle:IsA("Attachment") then
			src = muzzle.WorldCFrame
		elseif muzzle:IsA("BasePart") then
			src = muzzle.CFrame
		end

		if src then
			muzzleCF = src
			weaponInfo.SetWeaponSource(src)
		end
	end

	------------------------------------------------------------------
	-- Debug beam from muzzle → forward
	------------------------------------------------------------------

	if debugBeamEnabled and muzzleCF then
		local beamPart = ensureDebugBeamPart()

		local startPos = muzzleCF.Position
		local dir = muzzleCF.LookVector

		local debugDistance = 2000
		local endPos = startPos + dir * debugDistance

		local dist = (endPos - startPos).Magnitude

		if dist < 0.1 then
			beamPart.Transparency = 1
		else
			local mid = startPos + dir * (dist * 0.5)

			beamPart.Size = Vector3.new(0.05, 0.05, dist)
			beamPart.CFrame = CFrame.new(mid, endPos)
			beamPart.Transparency = 0.2
		end
	elseif debugBeamPart then
		debugBeamPart.Transparency = 1
	end
end)

---------------------------------------------------------------------- 
-- Remotes
----------------------------------------------------------------------

function GetWeaponSourceEvent.OnClientInvoke()
	return weaponInfo.GetWeaponSource()
end

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName, slot)
	if not Character or not Character.Parent then
		return
	end

	local isAimWeapon =
		toolName ~= ""
		and itemsmodule[toolName] ~= nil
		and itemsmodule[toolName].Aim == true

	if isAimWeapon then
		rangedWeaponEquipped = true
		currentHeldWeapon = toolName

		muzzle = findWeaponMuzzle(currentHeldWeapon)

		captureAimPose()

		return
	end

	------------------------------------------------------------------
	-- Unequip / reset
	------------------------------------------------------------------

	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
	end

	restoreAimPose()

	rangedWeaponEquipped = false
	currentHeldWeapon = nil
	muzzleCF = nil
	muzzle = nil

	if debugBeamPart then
		debugBeamPart.Transparency = 1
	end
end)
