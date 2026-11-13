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
local LeftHand = nil

local NeckOriginC0 = nil
local WaistOriginC0 = nil
local TorsoOriginC0 = nil
local RightOriginC0 = nil
local LeftOriginC0 = nil

local weaponHandle = nil
local rightGrip = nil
local leftGrip = nil

local leftGripIK = nil :: IKControl?
local leftPalmEffector = nil :: Attachment?
local ikSetupAt = 0
local warnedMissingLeftGrip = false
local teardownIK = nil
local shoulderAimCorrection = CFrame.new()

local cframe = CFrame.new
local angles = CFrame.Angles
local clamp = math.clamp

local rangedWeaponEquipped = false
local currentHeldWeapon = nil
local autoRotateBeforeAim = nil :: boolean?
local directionalWalkActive = false
local stopDirectionalWalk = nil

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
	weaponInfo.SetWeaponSource(nil, nil)
	if Humanoid and autoRotateBeforeAim ~= nil then
		Humanoid.AutoRotate = autoRotateBeforeAim
	end
	if stopDirectionalWalk then
		stopDirectionalWalk(0)
	end
	autoRotateBeforeAim = nil
	muzzle = nil
	muzzleCF = nil
	rangedWeaponEquipped = false
	currentHeldWeapon = nil
	weaponHandle = nil
	rightGrip = nil
	leftGrip = nil
	warnedMissingLeftGrip = false
	shoulderAimCorrection = CFrame.new()

	if teardownIK then
		teardownIK()
	end

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

	LeftHand = nil

	if LeftShoulder then
		local elbow = LeftShoulder:FindFirstChild("Elbow_L")
		if elbow then
			LeftHand = elbow:FindFirstChild("Hand_L")
		end
	end

	if not LeftHand then
		LeftHand = Character:FindFirstChild("Hand_L", true)
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

	if teardownIK then
		teardownIK()
	end
end

local function captureAimPose()
	if Waist then
		WaistOriginC0 = Waist.CFrame
	end

	if Torso then
		TorsoOriginC0 = Torso.CFrame
	end

end

local function findWeaponMuzzle(toolName)
	if not Character or toolName == nil then
		return nil
	end

	local handle = nil
	local toolModel = Character:FindFirstChild(toolName)

	if RightHand then
		handle = RightHand:FindFirstChild(toolName .. "Handle")
	end

	if not handle then
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

	weaponHandle = handle
	rightGrip = handle:FindFirstChild("RightGrip", true)
		or handle:FindFirstChild("RightGripAttachment", true)
		or (toolModel and toolModel:FindFirstChild("RightGrip", true))
		or (toolModel and toolModel:FindFirstChild("RightGripAttachment", true))
	leftGrip = handle:FindFirstChild("LeftGrip", true)
		or handle:FindFirstChild("LeftGripAttachment", true)
		or (toolModel and toolModel:FindFirstChild("LeftGrip", true))
		or (toolModel and toolModel:FindFirstChild("LeftGripAttachment", true))

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
	if instance:IsA("Bone") then
		return instance.TransformedWorldCFrame
	end

	if instance:IsA("Attachment") then
		local parent = instance.Parent

		if parent and parent:IsA("Bone") then
			return parent.TransformedWorldCFrame * instance.CFrame
		end

		if parent and parent:IsA("Attachment") then
			local parentCf = getWorldCFrame(parent)
			return parentCf and (parentCf * instance.CFrame) or nil
		end

		return instance.WorldCFrame
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	return nil
end

teardownIK = function()
	if leftGripIK then
		leftGripIK:Destroy()
		leftGripIK = nil
	end

	if leftPalmEffector then
		leftPalmEffector:Destroy()
		leftPalmEffector = nil
	end
end

local function setupSupportHandIK(): boolean
	if leftGripIK then
		return true
	end

	if os.clock() < ikSetupAt
		or not Humanoid
		or not LeftShoulder
		or not LeftHand
	then
		return false
	end

	if leftGrip and leftGrip:IsA("Attachment") then
		local leftHandCf = getWorldCFrame(LeftHand)
		local leftGripCf = getWorldCFrame(leftGrip)
		local elbowCf = LeftHand.Parent and getWorldCFrame(LeftHand.Parent)

		if leftHandCf and leftGripCf and elbowCf then
			local forearmDirection = leftHandCf.Position - elbowCf.Position
			if forearmDirection.Magnitude < 0.001 then
				return false
			end

			local handReach = leftGrip:GetAttribute("HandReach")
			if type(handReach) ~= "number" then
				handReach = 0.35
			end

			local palmWorldPosition =
				leftHandCf.Position
				+ forearmDirection.Unit * handReach
			local palmLocalPosition = leftHandCf:PointToObjectSpace(palmWorldPosition)

			leftPalmEffector = Instance.new("Attachment")
			leftPalmEffector.Name = "ThirdPersonLeftPalmEffector"
			leftPalmEffector.CFrame = CFrame.new(palmLocalPosition)
			leftPalmEffector.Parent = LeftHand

			leftGripIK = Instance.new("IKControl")
			leftGripIK.Name = "ThirdPersonLeftHandGrip"
			leftGripIK.Type = Enum.IKControlType.Transform
			leftGripIK.ChainRoot = LeftShoulder
			leftGripIK.EndEffector = leftPalmEffector
			leftGripIK.Target = leftGrip
			-- The palm attachment keeps the wrist behind the grip. Transform IK also
			-- owns wrist rotation so locomotion animations cannot turn the fingers
			-- forward across the muzzle. PalmTwist turns the palm upward; PalmTurn
			-- then turns the fingers across the weapon within that palm plane.
			local palmTwist = leftGrip:GetAttribute("PalmTwist")
			if type(palmTwist) ~= "number" then
				palmTwist = 90
			end
			local palmTurn = leftGrip:GetAttribute("PalmTurn")
			if type(palmTurn) ~= "number" then
				palmTurn = 90
			end
			leftGripIK.Offset =
				angles(0, math.rad(palmTwist), 0)
				* angles(math.rad(palmTurn), 0, 0)
			leftGripIK.Weight = 1
			leftGripIK.SmoothTime = 0.05
			leftGripIK.Priority = 2
			leftGripIK.Parent = Humanoid
		end
	elseif not warnedMissingLeftGrip then
		warnedMissingLeftGrip = true
		warn("AimRangeWeapon: add a LeftGrip Attachment anywhere inside the equipped weapon model")
	end

	return true
end

local function getParentWorldCFrame(instance): CFrame?
	local parent = instance and instance.Parent
	if not parent then
		return nil
	end

	return getWorldCFrame(parent)
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
	local angle = math.acos(clamp(currentDirection:Dot(desiredDirection), -1, 1))

	if angle >= math.rad(0.1) then
		local axis = currentDirection:Cross(desiredDirection)
		if axis.Magnitude > 0.0001 then
			local localAxis = parentWorldCf:VectorToObjectSpace(axis.Unit)
			local correctionStep = math.min(angle * 0.25, math.rad(3))
			local nextCorrection =
				CFrame.fromAxisAngle(localAxis, correctionStep)
				* shoulderAimCorrection
			local correctionAxis, correctionAngle = nextCorrection:ToAxisAngle()

			if correctionAngle > math.rad(25) then
				nextCorrection = CFrame.fromAxisAngle(correctionAxis, math.rad(25))
			end

			shoulderAimCorrection = nextCorrection
		end
	end

	RightShoulder.CFrame =
		CFrame.new(RightOriginC0.Position)
		* shoulderAimCorrection
		* RightOriginC0.Rotation
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

local WALK_DIRECTIONS = {"F", "FR", "R", "BR", "B", "BL", "L", "FL"}
local AIM_WALK_ANIMATION_SPEED = 1.25

stopDirectionalWalk = function(fadeTime)
	if not directionalWalkActive then
		return
	end

	for _, track in pairs(PlayerState.AimWalkTracks or {}) do
		if track.IsPlaying then
			track:Stop(fadeTime or 0.12)
		end
	end

	directionalWalkActive = false
end

local function updateDirectionalWalk()
	local currentState = PlayerState.CurrentState
	local isWalking =
		currentState
		and PlayerState.States.Walking
		and currentState.Name == PlayerState.States.Walking.Name
		and not PlayerState.IsSprinting
	local moveDirection = Humanoid.MoveDirection

	if not isWalking or moveDirection.Magnitude < 0.05 then
		stopDirectionalWalk(0.12)
		return
	end

	local tracks = PlayerState.AimWalkTracks
	if not tracks or not tracks.F then
		return
	end

	if not directionalWalkActive then
		local walkingState = PlayerState.States.Walking
		if walkingState.ToolAnimation and walkingState.ToolAnimation.IsPlaying then
			walkingState.ToolAnimation:Stop(0.12)
		end
		if walkingState.Animation and walkingState.Animation.IsPlaying then
			walkingState.Animation:Stop(0.12)
		end

		for _, track in pairs(tracks) do
			track:Play(0.12, 0.001, AIM_WALK_ANIMATION_SPEED)
		end
		directionalWalkActive = true
	end

	local localMove = root.CFrame:VectorToObjectSpace(moveDirection.Unit)
	local sectorPosition = math.atan2(localMove.X, -localMove.Z) / (math.pi / 4)
	if sectorPosition < 0 then
		sectorPosition += 8
	end

	local lowerSector = math.floor(sectorPosition) % 8
	local upperSector = (lowerSector + 1) % 8
	local blend = sectorPosition - math.floor(sectorPosition)
	local lowerDirection = WALK_DIRECTIONS[lowerSector + 1]
	local upperDirection = WALK_DIRECTIONS[upperSector + 1]

	for direction, track in pairs(tracks) do
		local weight = 0.001
		if direction == lowerDirection then
			weight = math.max(0.001, 1 - blend)
		elseif direction == upperDirection then
			weight = math.max(0.001, blend)
		end
		track:AdjustWeight(weight, 0.1)
	end
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
		stopDirectionalWalk(0.12)
		muzzleCF = nil

		if debugBeamPart then
			debugBeamPart.Transparency = 1
		end

		return
	end

	if not canAim() then
		stopDirectionalWalk(0.12)
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

	updateDirectionalWalk()

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
	-- 1) The authored animation keeps ownership of the weapon and right hand.
	--    Correct the right shoulder until the actual muzzle reaches the target,
	--    while left-hand IK only keeps the support hand on LeftGrip.
	------------------------------------------------------------------

	if muzzle and muzzle.Parent then
		applyShoulderCorrection(Point)
		setupSupportHandIK()
	else
		muzzle = findWeaponMuzzle(currentHeldWeapon)
	end

	------------------------------------------------------------------
	-- 2) Update weapon source + muzzle CFrame for actual firing
	------------------------------------------------------------------

	muzzleCF = nil

	if muzzle and muzzle.Parent then
		local src

		src = getWorldCFrame(muzzle)

		if src then
			muzzleCF = src
			-- Firing uses this exact rendered muzzle as its projectile origin.
			weaponInfo.SetWeaponSource(src, currentHeldWeapon)
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
		restoreAimPose()
		weaponHandle = nil
		rightGrip = nil
		leftGrip = nil
		warnedMissingLeftGrip = false

		rangedWeaponEquipped = true
		currentHeldWeapon = toolName
		if autoRotateBeforeAim == nil then
			autoRotateBeforeAim = Humanoid.AutoRotate
		end
		Humanoid.AutoRotate = false

		muzzle = findWeaponMuzzle(currentHeldWeapon)
		ikSetupAt = os.clock() + 0.2

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
	weaponInfo.SetWeaponSource(nil, nil)
	stopDirectionalWalk(0.12)
	if autoRotateBeforeAim ~= nil then
		Humanoid.AutoRotate = autoRotateBeforeAim
		autoRotateBeforeAim = nil
	end

	rangedWeaponEquipped = false
	currentHeldWeapon = nil
	muzzleCF = nil
	muzzle = nil
	weaponHandle = nil
	rightGrip = nil
	leftGrip = nil

	if debugBeamPart then
		debugBeamPart.Transparency = 1
	end
end)
