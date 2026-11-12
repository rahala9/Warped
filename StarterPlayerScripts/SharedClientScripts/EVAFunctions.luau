-- EVAFunctions.client.lua
-- Extra-Vehicular Activity (spacewalk) system
-- Separate from ship flight - handles floating in space

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local EVA = {}

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
EVA.Speed = 20
EVA.BoostSpeed = 30
EVA.AccelResponse = 3
EVA.LinearDamp = 0.45
EVA.MinStopSpeed = 0.05

EVA.LVMaxForce = 50000
EVA.LVMaxForceBoost = 100000

--------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------
EVA.IsActive = false
EVA._LV = nil
EVA._LVAtt = nil
EVA._AO = nil  -- AlignOrientation for stability
EVA._AOAtt = nil
EVA._targetVel = Vector3.zero
EVA._inF = 0
EVA._inS = 0
EVA._inU = 0

EVA.InSpace = {}

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

Zones:OnLoaded("StarhopStationZone", function(zone)
	zone:OnPlayerEntered(function(player)
		print("[EVA] CanEVA:", player.Name, "in StarhopStationZone")
		EVA.InSpace[player] = false
	end)
	zone:OnPlayerExited(function(player)
		print("[EVA] CanEVA:", player.Name, "left StarhopStationZone")
		EVA.InSpace[player] = true
	end)
end)


--------------------------------------------------------------------
-- FORCE CREATION
--------------------------------------------------------------------
local function createEVAForce(HRP: BasePart)
	if EVA._LV then return end

	local att = ensureAttachment(HRP, "EVAAttachment")
	EVA._LVAtt = att

	local lv = Instance.new("LinearVelocity")
	lv.Name = "EVALV"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = Vector3.zero
	lv.MaxForce = EVA.LVMaxForce
	lv.Parent = HRP
	EVA._LV = lv

	print("[EVA] Created LinearVelocity force")
end

local function createEVAStability(HRP: BasePart)
	if EVA._AO then return end

	local att = HRP:FindFirstChild("EVAAttachment") or ensureAttachment(HRP, "EVAAttachment")
	EVA._AOAtt = att

	local ao = Instance.new("AlignOrientation")
	ao.Name = "EVAAO"
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Responsiveness = 20  -- Moderate responsiveness
	ao.MaxTorque = 10000
	ao.RigidityEnabled = false
	ao.Parent = HRP
	EVA._AO = ao

	print("[EVA] Created AlignOrientation for stability")
end

local function destroyEVAForce()
	if EVA._LV then 
		EVA._LV:Destroy()
		EVA._LV = nil
	end
	if EVA._LVAtt then
		EVA._LVAtt:Destroy()
		EVA._LVAtt = nil
	end
	if EVA._AO then
		EVA._AO:Destroy()
		EVA._AO = nil
	end
	if EVA._AOAtt then
		EVA._AOAtt:Destroy()
		EVA._AOAtt = nil
	end
	print("[EVA] Destroyed all forces")
end

--------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------
function EVA.CanEVA(player)
	print("[EVA] CanEVA called")
	return EVA.InSpace[player]
end

function EVA.StartEVA(humanoid: Humanoid, HRP: BasePart)
	if EVA.IsActive then
		warn("[EVA] Already in EVA mode")
		return
	end

	print("[EVA] Starting EVA mode")

	EVA.IsActive = true
	PlayerState.IsFlying = true

	-- Set humanoid to physics mode
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.PlatformStand = true
	humanoid.AutoRotate = true  -- Face movement direction

	-- Disable walking states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)

	-- Create movement force
	createEVAForce(HRP)
	createEVAStability(HRP)

	-- Initialize state
	EVA._targetVel = Vector3.zero
	EVA._inF, EVA._inS, EVA._inU = 0, 0, 0

	print("[EVA] EVA mode active - use WASD to move, Space/Ctrl for up/down, Shift to boost")
end

function EVA.StopEVA(humanoid: Humanoid, HRP: BasePart)
	if not EVA.IsActive then
		warn("[EVA] Not in EVA mode")
		return
	end

	print("[EVA] Stopping EVA mode")

	EVA.IsActive = false
	PlayerState.IsFlying = false

	-- Destroy forces
	destroyEVAForce()

	-- Reset state
	EVA._targetVel = Vector3.zero
	EVA._inF, EVA._inS, EVA._inU = 0, 0, 0

	-- Restore humanoid
	humanoid.PlatformStand = false
	humanoid.AutoRotate = true
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)

	-- Zero out velocity
	HRP.AssemblyLinearVelocity = Vector3.zero
	HRP.AssemblyAngularVelocity = Vector3.zero
end

-- Helper: Force cleanup EVA forces even if not active (for when re-entering ship)
function EVA.ForceCleanup(HRP: BasePart)
	print("[EVA] Force cleanup of any EVA components")

	-- Destroy any EVA instances
	local evalv = HRP:FindFirstChild("EVALV")
	if evalv then evalv:Destroy() end

	local evaao = HRP:FindFirstChild("EVAAO")
	if evaao then evaao:Destroy() end

	local evaatt = HRP:FindFirstChild("EVAAttachment")
	if evaatt then evaatt:Destroy() end

	-- Reset state
	EVA.IsActive = false
	EVA._LV = nil
	EVA._LVAtt = nil
	EVA._AO = nil
	EVA._AOAtt = nil
	EVA._targetVel = Vector3.zero
end

function EVA.EVAHeartbeat(dt: number, humanoid: Humanoid, HRP: BasePart)
	if not EVA.IsActive then return end
	if not humanoid or not HRP then return end

	dt = math.min(dt, 0.033)

	-- Get camera
	local cam = workspace.CurrentCamera
	if not cam then return end

	-- Get input using axis helper
	local rawF = axis(Enum.KeyCode.S, Enum.KeyCode.W)
	local rawS = axis(Enum.KeyCode.A, Enum.KeyCode.D)
	local rawU = axis(Enum.KeyCode.LeftControl, Enum.KeyCode.Space)

	-- Check if we have any input
	local hasInput = (math.abs(rawF) + math.abs(rawS) + math.abs(rawU)) > 0.1

	-- Calculate desired velocity (camera-relative movement)
	local camCF = cam.CFrame
	local forward = camCF.LookVector
	local right = camCF.RightVector
	local up = Vector3.yAxis  -- Always use world up for vertical

	local boosting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	local speed = boosting and EVA.BoostSpeed or EVA.Speed

	local desiredVel = Vector3.zero
	if hasInput then
		local dir = 
			(forward * rawF) +
			(right * rawS) +
			(up * rawU * 0.7)  -- Slower vertical movement

		local mag = dir.Magnitude
		if mag > 0.01 then
			dir = dir / mag
			desiredVel = dir * speed
		end
	end

	-- Smooth velocity change
	local a = expSmoothing(EVA.AccelResponse or 3, dt)
	EVA._targetVel = EVA._targetVel:Lerp(desiredVel, a)

	-- Apply damping when no input
	if not hasInput then
		local dampK = EVA.LinearDamp or 0.45
		local mul = math.exp(-dampK * dt)
		EVA._targetVel *= mul
		if EVA._targetVel.Magnitude < (EVA.MinStopSpeed or 0.05) then
			EVA._targetVel = Vector3.zero
		end
	end

	-- Apply force
	if EVA._LV then
		EVA._LV.VectorVelocity = EVA._targetVel
		EVA._LV.MaxForce = boosting and EVA.LVMaxForceBoost or EVA.LVMaxForce
	else
		warn("[EVA] LinearVelocity is missing!")
	end

	-- JETPACK-STYLE ORIENTATION: Stay mostly upright with subtle tilts
	if EVA._AO then
		-- Get horizontal movement (ignore vertical)
		local horizontalVel = Vector3.new(EVA._targetVel.X, 0, EVA._targetVel.Z)

		if horizontalVel.Magnitude > 1 then
			-- Moving horizontally - face that direction with a subtle forward tilt
			local moveDir = horizontalVel.Unit

			-- Calculate yaw from movement direction
			local yaw = math.atan2(-moveDir.X, -moveDir.Z)

			-- Subtle forward tilt (15 degrees max) - ALWAYS leans forward in local space
			local tiltAmount = math.min(horizontalVel.Magnitude / 50, 1) -- 0-1 based on speed
			local pitch = math.rad(-15) * tiltAmount  -- Negative = lean forward

			-- Create orientation: first set yaw (facing), then apply pitch (lean forward)
			-- This makes the pitch relative to the character's facing direction
			local targetCF = CFrame.new(HRP.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
			EVA._AO.CFrame = targetCF
		else
			-- Not moving horizontally - stay perfectly upright
			-- Just maintain current yaw, no pitch or roll
			local currentCF = HRP.CFrame
			local _, currentYaw, _ = currentCF:ToEulerAnglesYXZ()
			local targetCF = CFrame.new(HRP.Position) * CFrame.Angles(0, currentYaw, 0)
			EVA._AO.CFrame = targetCF
		end
	end
end

return EVA