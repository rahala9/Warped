-- JetLiftFoodTruck.server.lua (Script under the truck Model)
-- Back-and-forth: Start -> End -> Start -> End ...
-- Heartbeat only while moving
-- Wobble only for a short adjustable time at takeoff

local RunService = game:GetService("RunService")

local truckModel = script.Parent
assert(truckModel:IsA("Model"), "Must be a Model")
assert(truckModel.PrimaryPart, "PrimaryPart must be set")

local root = truckModel.PrimaryPart
root.Anchored = false
root:SetNetworkOwner(nil)

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local STAY_TIME   = 10

local START_SPEED = 1.5   -- studs/sec at beginning of a move
local CRUISE_SPEED = 10   -- studs/sec after ramp
local ACCEL_TIME  = 2.5   -- seconds to ramp from START_SPEED to CRUISE_SPEED

local WOBBLE_TIME = 1.5   -- seconds wobble is active at the start of a move

local ARRIVAL_DISTANCE = 1.0 -- studs
local MOVE_TIMEOUT = 120

-- Align tuning
local ALIGN_MAX_FORCE = 2e6
local ALIGN_RESP = 10
local ORI_RESP   = 10

-- Wobble tuning
local wobbleRadiusStuds = 1.8
local wobbleHeightStuds = 0.25
local wobbleRotDegrees  = 2.5
local wobbleSpeed       = 1.4

------------------------------------------------------------
-- TARGETS (Attachments named Start and End)
------------------------------------------------------------
local startAtt = script.Parent:WaitForChild("Base"):WaitForChild("Start") :: Attachment
local endAtt   = script.Parent:WaitForChild("Base"):WaitForChild("End")   :: Attachment

------------------------------------------------------------
-- GOAL PART + ATTACHMENT (AlignPosition chases this)
------------------------------------------------------------
local goalPart = truckModel:FindFirstChild("JetLiftGoal") :: BasePart
if not goalPart then
	goalPart = Instance.new("Part")
	goalPart.Name = "JetLiftGoal"
	goalPart.Size = Vector3.one
	goalPart.Transparency = 1
	goalPart.CanCollide = false
	goalPart.CanTouch = false
	goalPart.CanQuery = false
	goalPart.Anchored = true
	goalPart.Parent = workspace
end

local goalAtt = goalPart:FindFirstChild("JetLiftGoalAttachment") :: Attachment
if not goalAtt then
	goalAtt = Instance.new("Attachment")
	goalAtt.Name = "JetLiftGoalAttachment"
	goalAtt.Parent = goalPart
end

------------------------------------------------------------
-- ALIGNMENTS
------------------------------------------------------------
local alignPos = root:FindFirstChild("JetLiftAlignPosition") :: AlignPosition
if not alignPos then
	alignPos = Instance.new("AlignPosition")
	alignPos.Name = "JetLiftAlignPosition"
	alignPos.Parent = root
end

alignPos.Attachment0 = startAtt
alignPos.Attachment1 = goalAtt
alignPos.ApplyAtCenterOfMass = true
alignPos.ReactionForceEnabled = false
alignPos.RigidityEnabled = false
alignPos.MaxForce = ALIGN_MAX_FORCE
alignPos.Responsiveness = ALIGN_RESP
alignPos.Enabled = true

local alignOri = root:FindFirstChild("JetLiftAlignOrientation") :: AlignOrientation
if not alignOri then
	alignOri = Instance.new("AlignOrientation")
	alignOri.Name = "JetLiftAlignOrientation"
	alignOri.Parent = root
end

alignOri.Attachment0 = startAtt
alignOri.ReactionTorqueEnabled = false
alignOri.RigidityEnabled = false
alignOri.MaxTorque = ALIGN_MAX_FORCE
alignOri.MaxAngularVelocity = 8
alignOri.Responsiveness = ORI_RESP
alignOri.Enabled = true

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function clamp01(x) return math.max(0, math.min(1, x)) end
local function lerp(a,b,t) return a + (b-a)*t end

local function wobbleCF(elapsed: number, strength: number): CFrame
	-- separate function: returns wobble offset+tilt for current elapsed time
	local t = elapsed * wobbleSpeed

	local sx1 = math.sin(t * 1.7)
	local sx2 = math.sin(t * 2.9)
	local sz1 = math.sin(t * 1.3)
	local sz2 = math.sin(t * 2.3)
	local sy  = math.sin(t * 2.1)

	local wobbleX = (sx1 * 0.7 + sx2 * 0.3) * wobbleRadiusStuds * strength
	local wobbleZ = (sz1 * 0.7 + sz2 * 0.3) * wobbleRadiusStuds * strength
	local wobbleY = sy * wobbleHeightStuds * strength

	local pitch = math.rad((sz1 * 0.6 + sz2 * 0.4) * wobbleRotDegrees * strength)
	local roll  = math.rad((sx1 * 0.6 + sx2 * 0.4) * wobbleRotDegrees * strength)

	return CFrame.new(wobbleX, wobbleY, wobbleZ) * CFrame.Angles(pitch, 0, roll)
end

local function holdAt(att: Attachment)
	goalPart.CFrame = att.WorldCFrame
	alignOri.CFrame = goalPart.CFrame
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

------------------------------------------------------------
-- MOVE (single-writer heartbeat)
------------------------------------------------------------
local hb: RBXScriptConnection? = nil

local function stopHB()
	if hb then hb:Disconnect(); hb = nil end
end

local function moveTo(att: Attachment)
	stopHB()

	local targetCF = att.WorldCFrame
	local targetPos = targetCF.Position
	local baseRot = targetCF.Rotation

	local basePos = goalPart.Position
	local t0 = os.clock()

	local done = false

	hb = RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local elapsed = now - t0

		-- timeout safety
		if elapsed > MOVE_TIMEOUT then
			warn("[JetLift] timeout, forcing hold")
			done = true
			return
		end

		-- speed ramp: slow -> cruise
		local accelT = clamp01(elapsed / ACCEL_TIME)
		local speed = lerp(START_SPEED, CRUISE_SPEED, accelT)

		-- prevent AlignPosition from going faster than our intended motion
		alignPos.MaxVelocity = speed * 1.25

		-- step toward target
		local delta = targetPos - basePos
		local dist = delta.Magnitude

		if dist <= ARRIVAL_DISTANCE then
			done = true
			return
		end

		local step = math.min(speed * dt, dist)
		basePos = basePos + delta.Unit * step

		-- wobble only early in the move
		local strength = (elapsed <= WOBBLE_TIME) and 1 or 0

		goalPart.CFrame =
			CFrame.new(basePos)
			* baseRot
			* wobbleCF(elapsed, strength)

		alignOri.CFrame = goalPart.CFrame
	end)

	-- wait for completion without relying on hb being nil
	local startWait = os.clock()
	while true do
		if done then break end
		if os.clock() - startWait > MOVE_TIMEOUT + 1 then break end
		task.wait(0.1)
	end

	stopHB()
	holdAt(att)
end

------------------------------------------------------------
-- MAIN LOOP (explicit direction flip)
------------------------------------------------------------
task.spawn(function()
	local toEnd = true

	holdAt(startAtt)

	while true do
		task.wait(STAY_TIME)

		if toEnd then
			moveTo(endAtt)
		else
			moveTo(startAtt)
		end

		toEnd = not toEnd
	end
end)
