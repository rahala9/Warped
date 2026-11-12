local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = game.Players.LocalPlayer
local PlayerMouse = Player:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local GetWeaponSourceEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetWeaponSource")
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local weaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

local Camera = workspace.CurrentCamera

local Character = Player.Character or Player.CharacterAdded:Wait()

local BodyParts = {}
BodyParts.Locations = {}
local BodyPartsLocations = {
	GunHandle = {"HumanoidRootPart", "Root", "Hips", "Spine_01", "Spine_02", "Spine_03", "Clavicle_R", "Shoulder_R", "Elbow_R", "Hand_R", "NerdGunHandle"};
	Head = {"HumanoidRootPart","Root", "Hips","Spine_01","Spine_02","Spine_03","Neck","Head"};
	HeadMotor6D = {"HumanoidRootPart","Root", "Hips","Spine_01","Spine_02","Spine_03","Neck","Head"};
	Neck = {"HumanoidRootPart","Root", "Hips","Spine_01","Spine_02","Spine_03","Neck"};
	Torso = {"HumanoidRootPart","Root", "Hips","Spine_02"};
	Waist = {"HumanoidRootPart","Root", "Hips","Spine_01"};
	RightShoulder = {"HumanoidRootPart", "Root", "Hips", "Spine_01", "Spine_02", "Spine_03", "Clavicle_R","Shoulder_R"};
	LeftShoulder =  {"HumanoidRootPart", "Root", "Hips", "Spine_01", "Spine_02", "Spine_03", "Clavicle_L","Shoulder_L"};
} 

for bodyPartName, bodyPartLocation in pairs(BodyPartsLocations) do
	local part = Character
	for _, partName in ipairs(bodyPartLocation) do
		if part:FindFirstChild(partName) then
			part = part[partName]
		else 
			break
		end
		BodyParts[bodyPartName] = part.Name == BodyPartsLocations[bodyPartName][#BodyPartsLocations[bodyPartName]] and part or nil
	end
	BodyParts.Locations[bodyPartName] = BodyPartsLocations[bodyPartName][#BodyPartsLocations[bodyPartName]]
end

local Head = BodyParts.HeadMotor6D or Character:FindFirstChild(BodyParts.Locations.HeadMotor6D, true)
local Hips = Character:WaitForChild("HumanoidRootPart")["Root"]["Hips"]
local Neck = BodyParts.Neck or Character:FindFirstChild(BodyParts.Locations.Neck, true)
local Torso = BodyParts.Torso or Character:FindFirstChild(BodyParts.Locations.Torso, true)
local Waist = BodyParts.Waist or Character:FindFirstChild(BodyParts.Locations.Waist, true)
local RightShoulder = BodyParts.RightShoulder or Character:FindFirstChild(BodyParts.Locations.RightShoulder, true)
local LeftShoulder = BodyParts.LeftShoulder or Character:FindFirstChild(BodyParts.Locations.LeftShoulder, true)
local RightHand = RightShoulder["Elbow_R"]["Hand_R"]

local Humanoid = Character:WaitForChild("Humanoid")
local root = Character:WaitForChild("HumanoidRootPart")

local NeckOriginC0 = Neck.CFrame
local WaistOriginC0 = Waist.CFrame
local RightOriginC0 = RightShoulder.CFrame
local LeftOriginC0 = LeftShoulder.CFrame

local cframe = CFrame.new
local angles = CFrame.Angles
local clamp = math.clamp

local rangedWeaponEquipped = false
local currentHeldWeapon = nil

Player.CharacterAdded:Connect(function(character)
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
	root = Character:WaitForChild("HumanoidRootPart")
	-- NOTE: if you respawn a lot, you might want to recompute BodyParts here too.
end)

----------------------------------------------------------------------
-- GetAngles: yaw & pitch from *fromCf* → target, not from camera
----------------------------------------------------------------------

local function GetAngles(rootCf: CFrame, targetPos: Vector3)
	-- YAW: same as before
	local rootPos = rootCf.Position
	local toTargetRoot = targetPos - rootPos
	local yaw = math.atan2(toTargetRoot.X, toTargetRoot.Z)

	-- PITCH: waist → target
	local waistPos = Waist.WorldPosition
	local toTarget = targetPos - waistPos

	-- horizontal distance
	local flatDist = math.sqrt(toTarget.X*toTarget.X + toTarget.Z*toTarget.Z)
	local pitch = math.atan2(toTarget.Y, flatDist)

	return pitch, yaw
end


----------------------------------------------------------------------
-- Debug beam support
----------------------------------------------------------------------

local debugBeamPart = nil :: Part?
local debugBeamEnabled = true
local muzzleCF = nil :: CFrame?
local muzzle = nil

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

-- optional: so you can toggle from the console
_G.SetAimDebugBeamEnabled = SetDebugBeamEnabled

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

	if not (Neck and Waist and root and Head and Torso) then
		return
	end

	if Camera.CameraSubject:IsDescendantOf(Character) or Camera.CameraSubject:IsDescendantOf(Player) then
		local Point = PlayerMouse.Hit.p

		------------------------------------------------------------------
		-- 0) Rotate the character toward the mouse horizontally
		------------------------------------------------------------------
		do
			local rootPos = root.Position
			local flatTarget = Vector3.new(Point.X, rootPos.Y, Point.Z)

			if (flatTarget - rootPos).Magnitude > 0.01 then
				root.CFrame = CFrame.lookAt(rootPos, flatTarget)
			end
		end

		------------------------------------------------------------------
		-- 1) Get pitch/yaw from the *hand* toward the mouse
		------------------------------------------------------------------
		local pitch, yaw = GetAngles(RightHand.CFrame, Point)
		-- Debug if you want:
		-- print("pitch (deg):", math.deg(pitch), "yaw (deg):", math.deg(yaw))

		-- Optional clamps
		local maxPitch = math.rad(90)
		local maxYaw   = math.rad(90)
		pitch = clamp(pitch, -maxPitch, maxPitch)
		yaw   = clamp(yaw,   -maxYaw,   maxYaw)

		-- You can add a multiplier if you want stronger bend:
		local pitchScale = 1.0
		local yawScale   = 0.0 -- currently not twisting left/right with bones
		pitch = pitch * pitchScale
		yaw   = yaw   * yawScale

		------------------------------------------------------------------
		-- 2) Apply pitch to Spine_01 (Waist) and Spine_02 (Torso)
		--    Distribute pitch: e.g. 70% in waist, 30% in torso
		------------------------------------------------------------------
		local waistPitch  = pitch * 1 --0.7
		local torsoPitch  = pitch * .5 --0.3

		Waist.CFrame =
			CFrame.new(Waist.CFrame.Position)
			* angles(waistPitch, 0, 0)

		Torso.CFrame =
			CFrame.new(Torso.CFrame.Position)
			* angles(torsoPitch, 0, 0)

		------------------------------------------------------------------
		-- 3) Update weapon source + muzzle CFrame (from the actual muzzle part)
		------------------------------------------------------------------
		muzzleCF = nil

		if muzzle then
			local src = muzzle.WorldCFrame
			muzzleCF = src
			weaponInfo.SetWeaponSource(src)
		end
	end

	------------------------------------------------------------------
	-- Debug beam from muzzle → forward (to visualize actual aim)
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
		-- Hide the beam if enabled but we don't have a muzzle this frame
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
	if toolName ~= "" and itemsmodule[toolName] ~= nil and itemsmodule[toolName].Aim == true then
		rangedWeaponEquipped = true
		currentHeldWeapon = toolName

		if currentHeldWeapon ~= nil and RightHand:FindFirstChild(currentHeldWeapon.."Handle") ~= nil then
			local handle = RightHand[currentHeldWeapon .. "Handle"]
			local firePart = handle:FindFirstChild("Muzzle")
			if firePart then
				muzzle = firePart
			end
		elseif currentHeldWeapon ~= nil 
			and Character:FindFirstChild(currentHeldWeapon) ~= nil 
			and Character[currentHeldWeapon]:FindFirstChild(currentHeldWeapon.."Handle") ~= nil then

			local handle = Character[currentHeldWeapon][currentHeldWeapon.."Handle"]
			local firePart = handle:FindFirstChild("Muzzle")
			if firePart then
				muzzle = firePart
			end
		end

		return
	end

	Character.Humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)

	Neck.CFrame = NeckOriginC0
	Waist.CFrame = WaistOriginC0
	RightShoulder.CFrame = RightOriginC0
	LeftShoulder.CFrame = LeftOriginC0

	rangedWeaponEquipped = false
	muzzleCF = nil

	if debugBeamPart then
		debugBeamPart.Transparency = 1
	end
end)
