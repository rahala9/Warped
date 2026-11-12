--[[
    JetpackManager (ModuleScript)
    Place in: StarterPlayer > StarterPlayerScripts (alongside RightHUDManager)

    Owns everything jetpack:
        - RightHUDManager panel registration and GUI updates
        - AlignOrientation constraint setup
        - Fuel drain / recharge / depletion
        - Thrust and orientation physics
        - ClothingEquipped RemoteEvent listening for show/hide

    StateHandler interface:
        JetpackManager.Init(char, humanoid, HRP, playerState)  -- call from characterAdded
        JetpackManager.Update(dt)                              -- call every Heartbeat frame
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local Players           = game:GetService("Players")

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local player = Players.LocalPlayer

local RightHUDManager = require(script.Parent:WaitForChild("RightHUDManager"))

-- -------------------------------------------------------
-- Remote Events
-- -------------------------------------------------------
local Remotes               = ReplicatedStorage:WaitForChild("SharedRemotes")
local ClothingEquippedEvent = Remotes:WaitForChild("ClothingEquipped")

local JetpackSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("Jetpack"):Clone()
JetpackSoundFX.Parent = game.Workspace
-- -------------------------------------------------------
-- Tuning constants
-- -------------------------------------------------------
local JETPACK_FORCE         = 200 --50 to 200   -- base upward/directional impulse per frame
local JETPACK_VELOCITY_CAP  = 40 --10 to 40    -- max speed in thrust direction
local JETPACK_MAX_FUEL      = 10    -- seconds of full thrust
local JETPACK_DRAIN_RATE    = 1     -- fuel per second while thrusting
local JETPACK_RECHARGE_RATE = 1 --0.5 to 2   -- fuel per second while grounded

-- -------------------------------------------------------
-- GUI colors
-- -------------------------------------------------------
local COLOR_ACTIVE   = Color3.fromRGB(0, 220, 255)
local COLOR_IDLE     = Color3.fromRGB(0, 120, 160)
local COLOR_DEPLETED = Color3.fromRGB(220, 60, 60)
local COLOR_RECHARGE = Color3.fromRGB(255, 180, 0)
local COLOR_BORDER   = Color3.fromRGB(0, 180, 220)

-- -------------------------------------------------------
-- GUI references (populated in BuildPanel)
-- -------------------------------------------------------
local hudPanel       = nil
local isRegistered   = false
local modeLabel      = nil
local statusLabel    = nil
local fuelBarFill    = nil
local fuelPctLabel   = nil

-- -------------------------------------------------------
-- Physics / state references (set in Init)
-- -------------------------------------------------------
local char                = nil
local humanoid            = nil
local HRP                 = nil
local PlayerState         = nil
local alignOrientation    = nil

-- -------------------------------------------------------
-- Runtime state
-- -------------------------------------------------------
local isJetpacking        = false
local wasJetpacking       = false
local hasLeftGround       = false
local spaceWasReleased    = false
local jetpackFuel         = JETPACK_MAX_FUEL
local jetpackFuelDepleted = false
local jetpackEquipped     = false

currentJetpackModelName = nil

local JetpackManager = {}

-- -------------------------------------------------------
-- GUI: build content inside RightHUDManager content frame
-- -------------------------------------------------------
local function BuildPanel(contentFrame)
	local ml = Instance.new("TextLabel")
	ml.Name = "ModeLabel"
	ml.Size = UDim2.new(1, -8, 0, 22)
	ml.Position = UDim2.new(0, 4, 0, 0)
	ml.BackgroundTransparency = 1
	ml.Text = "STANDBY"
	ml.TextColor3 = COLOR_IDLE
	ml.Font = Enum.Font.Code
	ml.TextSize = 16
	ml.TextXAlignment = Enum.TextXAlignment.Left
	ml.Parent = contentFrame
	modeLabel = ml

	local sl = Instance.new("TextLabel")
	sl.Name = "StatusLabel"
	sl.Size = UDim2.new(0, 100, 0, 22)
	sl.Position = UDim2.new(1, -104, 0, 0)
	sl.BackgroundTransparency = 1
	sl.Text = "READY"
	sl.TextColor3 = COLOR_IDLE
	sl.Font = Enum.Font.Code
	sl.TextSize = 13
	sl.TextXAlignment = Enum.TextXAlignment.Right
	sl.Parent = contentFrame
	statusLabel = sl

	local fuelBg = Instance.new("Frame")
	fuelBg.Name = "FuelBg"
	fuelBg.Size = UDim2.new(1, -8, 0, 12)
	fuelBg.Position = UDim2.new(0, 4, 0, 26)
	fuelBg.BackgroundColor3 = Color3.fromRGB(15, 28, 40)
	fuelBg.BorderSizePixel = 0
	fuelBg.Parent = contentFrame

	local fuelBgCorner = Instance.new("UICorner")
	fuelBgCorner.CornerRadius = UDim.new(0, 3)
	fuelBgCorner.Parent = fuelBg

	local fuelBgStroke = Instance.new("UIStroke")
	fuelBgStroke.Color = COLOR_BORDER
	fuelBgStroke.Thickness = 1
	fuelBgStroke.Transparency = 0.6
	fuelBgStroke.Parent = fuelBg

	local ff = Instance.new("Frame")
	ff.Name = "FuelFill"
	ff.Size = UDim2.new(1, 0, 1, 0)
	ff.BackgroundColor3 = COLOR_ACTIVE
	ff.BorderSizePixel = 0
	ff.Parent = fuelBg

	local fuelFillCorner = Instance.new("UICorner")
	fuelFillCorner.CornerRadius = UDim.new(0, 3)
	fuelFillCorner.Parent = ff
	fuelBarFill = ff

	local fuelLabel = Instance.new("TextLabel")
	fuelLabel.Name = "FuelLabel"
	fuelLabel.Size = UDim2.new(0, 40, 0, 14)
	fuelLabel.Position = UDim2.new(0, 4, 0, 42)
	fuelLabel.BackgroundTransparency = 1
	fuelLabel.Text = "FUEL"
	fuelLabel.TextColor3 = COLOR_BORDER
	fuelLabel.TextTransparency = 0.4
	fuelLabel.Font = Enum.Font.Code
	fuelLabel.TextSize = 10
	fuelLabel.TextXAlignment = Enum.TextXAlignment.Left
	fuelLabel.Parent = contentFrame

	local fp = Instance.new("TextLabel")
	fp.Name = "FuelPct"
	fp.Size = UDim2.new(0, 50, 0, 14)
	fp.Position = UDim2.new(1, -54, 0, 42)
	fp.BackgroundTransparency = 1
	fp.Text = "100%"
	fp.TextColor3 = COLOR_BORDER
	fp.TextTransparency = 0.4
	fp.Font = Enum.Font.Code
	fp.TextSize = 10
	fp.TextXAlignment = Enum.TextXAlignment.Right
	fp.Parent = contentFrame
	fuelPctLabel = fp

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, -8, 0, 10)
	hint.Position = UDim2.new(0, 4, 0, 58)
	hint.BackgroundTransparency = 1
	hint.Text = "SPC:LIFT  SPC+SHIFT:HOVER  WASD:STEER"
	hint.TextColor3 = COLOR_BORDER
	hint.TextTransparency = 0.6
	hint.Font = Enum.Font.Code
	hint.TextSize = 8
	hint.TextXAlignment = Enum.TextXAlignment.Center
	hint.Parent = contentFrame
end

-- -------------------------------------------------------
-- GUI: register with RightHUDManager (once, lazily)
-- -------------------------------------------------------
local function EnsureRegistered()
	if isRegistered then return end
	isRegistered = true
	hudPanel = RightHUDManager:RegisterPanel({
		id        = "jetpack",
		title     = "JETPACK",
		icon      = "🚀",
		order     = 30,
		maxHeight = 74,
		onBuild   = BuildPanel,
	})
end

-- -------------------------------------------------------
-- GUI: show / hide
-- -------------------------------------------------------
local function ShowHUD()
	EnsureRegistered()
	RightHUDManager:SetVisible("jetpack", true)
	RightHUDManager:SetExpanded("jetpack", true)
end

local function HideHUD()
	if not isRegistered then return end
	RightHUDManager:SetVisible("jetpack", false)
end

-- -------------------------------------------------------
-- GUI: update labels and fuel bar
-- -------------------------------------------------------
local function UpdateHUD(modeText, modeColor, statusText, statusColor, fuelFraction)
	if not isRegistered then return end

	if modeLabel then
		modeLabel.Text = modeText
		modeLabel.TextColor3 = modeColor
	end

	if statusLabel then
		statusLabel.Text = statusText
		statusLabel.TextColor3 = statusColor
	end

	if fuelBarFill then
		local f = math.clamp(fuelFraction, 0, 1)
		fuelBarFill.Size = UDim2.new(f, 0, 1, 0)
		if jetpackFuelDepleted then
			fuelBarFill.BackgroundColor3 = COLOR_DEPLETED
		elseif f < 0.25 then
			fuelBarFill.BackgroundColor3 = COLOR_RECHARGE
		elseif isJetpacking then
			fuelBarFill.BackgroundColor3 = COLOR_ACTIVE
		else
			fuelBarFill.BackgroundColor3 = COLOR_IDLE
		end
	end

	if fuelPctLabel then
		fuelPctLabel.Text = math.floor(fuelFraction * 100) .. "%"
	end
end

-- -------------------------------------------------------
-- Physics: setup AlignOrientation constraint on HRP
-- -------------------------------------------------------
local function SetupConstraint()
	if alignOrientation then
		alignOrientation:Destroy()
		alignOrientation = nil
	end
	local existingAtt = HRP:FindFirstChild("JetpackAttachment")
	if existingAtt then existingAtt:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "JetpackAttachment"
	attachment.Parent = HRP

	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.RigidityEnabled = false
	alignOrientation.MaxTorque = 50000
	alignOrientation.Responsiveness = 20
	alignOrientation.Enabled = false
	alignOrientation.Parent = HRP
end

-- -------------------------------------------------------
-- Reset all runtime state (call on each spawn)
-- -------------------------------------------------------
local function ResetState()
	isJetpacking        = false
	wasJetpacking       = false
	hasLeftGround       = false
	spaceWasReleased    = false
	jetpackFuel         = JETPACK_MAX_FUEL
	jetpackFuelDepleted = false
end

-- -------------------------------------------------------
-- Public: Init — call from characterAdded in StateHandler
-- -------------------------------------------------------
function JetpackManager.Init(newChar, newHumanoid, newHRP, newPlayerState)
	char        = newChar
	humanoid    = newHumanoid
	HRP         = newHRP
	PlayerState = newPlayerState

	SetupConstraint()
	ResetState()

	-- Keep HUD visible across respawns if jetpack was equipped
	if jetpackEquipped then
		ShowHUD()
	end
end

local function ToggleJetpack()
	local jetpackModel = char:FindFirstChild(currentJetpackModelName)
	local JetL = jetpackModel:FindFirstChild("JetL")
	local JetR = jetpackModel:FindFirstChild("JetR")
	JetL.Fire.Enabled = not JetL.Fire.Enabled
	JetR.Fire.Enabled = not JetR.Fire.Enabled
end

-- -------------------------------------------------------
-- Public: Update — call every Heartbeat frame from StateHandler
-- -------------------------------------------------------
function JetpackManager.Update(dt)
	if not char or not humanoid or not HRP or not alignOrientation then return end
	if not jetpackEquipped then return end

	local spaceDown = UIS:IsKeyDown(Enum.KeyCode.Space)

	-- Ground detection
	local onGround = humanoid:GetState() == Enum.HumanoidStateType.Running or
		humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics or
		humanoid:GetState() == Enum.HumanoidStateType.Landed or
		humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding or
		humanoid:GetState() == Enum.HumanoidStateType.Seated

	if onGround then
		hasLeftGround    = false
		spaceWasReleased = false
		-- Recharge fuel when grounded
		if jetpackFuel < JETPACK_MAX_FUEL then
			jetpackFuel = math.min(JETPACK_MAX_FUEL, jetpackFuel + JETPACK_RECHARGE_RATE * dt)
			if jetpackFuelDepleted and jetpackFuel >= JETPACK_MAX_FUEL then
				jetpackFuelDepleted = false
			end
		end
	else
		hasLeftGround = true
	end

	-- Must release space at least once after jumping before jetpack engages
	if hasLeftGround and not spaceDown then
		spaceWasReleased = true
	end

	-- Determine if jetpack can fire
	local canJet = hasLeftGround and spaceWasReleased and spaceDown
		and not PlayerState.InWater and not jetpackFuelDepleted

	isJetpacking = canJet

	-- State transitions — fire once on engage/disengage
	if isJetpacking and not wasJetpacking then
		alignOrientation.Enabled = true
		ToggleJetpack()
		JetpackSoundFX:Play()
		PlayerState.ChangeState(PlayerState.States.Jetpacking)
	elseif not isJetpacking and wasJetpacking then
		alignOrientation.Enabled = false
		alignOrientation.CFrame  = CFrame.new()
		ToggleJetpack()
		JetpackSoundFX:Stop()
	end
	wasJetpacking = isJetpacking

	-- Drain fuel while thrusting
	if isJetpacking then
		jetpackFuel = math.max(0, jetpackFuel - JETPACK_DRAIN_RATE * dt)
		if jetpackFuel <= 0 then
			jetpackFuelDepleted = true
			isJetpacking        = false
		end
	end

	-- Update HUD
	local fuelFraction = jetpackFuel / JETPACK_MAX_FUEL
	if isJetpacking then
		local cruiseMode = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
		if cruiseMode then
			UpdateHUD("HOVER",   COLOR_ACTIVE,   "ACTIVE",     COLOR_ACTIVE,   fuelFraction)
		else
			UpdateHUD("LIFT",    COLOR_ACTIVE,   "ACTIVE",     COLOR_ACTIVE,   fuelFraction)
		end
	elseif jetpackFuelDepleted then
		UpdateHUD("OFFLINE",     COLOR_DEPLETED, "RECHARGING", COLOR_RECHARGE, fuelFraction)
	elseif jetpackFuel < JETPACK_MAX_FUEL then
		UpdateHUD("STANDBY",     COLOR_IDLE,     "RECHARGING", COLOR_RECHARGE, fuelFraction)
	else
		UpdateHUD("STANDBY",     COLOR_IDLE,     "READY",      COLOR_IDLE,     fuelFraction)
	end

	-- Apply thrust
	if not isJetpacking then return end

	local cam        = workspace.CurrentCamera
	local camCF      = cam.CFrame
	local camForward = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
	local camRight   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)

	local moveDir = Vector3.new(0, 0, 0)
	if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camForward end
	if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camForward end
	if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camRight  end
	if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camRight  end

	local hasDirectionalInput = moveDir.Magnitude > 0.01
	local cruiseMode          = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
	local currentVelY         = HRP.AssemblyLinearVelocity.Y

	-- Vertical thrust
	if not cruiseMode then
		-- LIFT: rise
		if currentVelY < JETPACK_VELOCITY_CAP then
			HRP:ApplyImpulse(Vector3.new(0, JETPACK_FORCE, 0))
		end
	else
		-- HOVER: arrest fall then hold altitude
		if currentVelY < 0 then
			HRP:ApplyImpulse(Vector3.new(0, JETPACK_FORCE, 0))
		elseif currentVelY < 1 then
			local gravityCancel = HRP.AssemblyMass * workspace.Gravity * (1/60)
			HRP:ApplyImpulse(Vector3.new(0, gravityCancel, 0))
		end
	end

	-- Horizontal thrust + body tilt when WASD pressed
	if hasDirectionalInput then
		moveDir = moveDir.Unit
		local currentVelH  = Vector3.new(HRP.AssemblyLinearVelocity.X, 0, HRP.AssemblyLinearVelocity.Z)
		local velInMoveDir = currentVelH:Dot(moveDir)
		if velInMoveDir < JETPACK_VELOCITY_CAP then
			HRP:ApplyImpulse(moveDir * JETPACK_FORCE * 0.6)
		end
		local uprightUp = Vector3.new(0, 1, 0)
		local bodyUp    = (uprightUp + moveDir * 0.5).Unit
		local bodyRight = moveDir:Cross(bodyUp)
		if bodyRight.Magnitude > 0.001 then
			bodyRight = bodyRight.Unit
			local bodyForward = bodyUp:Cross(bodyRight).Unit
			alignOrientation.CFrame = CFrame.fromMatrix(Vector3.zero, bodyRight, bodyUp, -bodyForward)
		end
	else
		-- No WASD: return to upright facing camera direction
		local lookDir = Vector3.new(HRP.CFrame.LookVector.X, 0, HRP.CFrame.LookVector.Z)
		if lookDir.Magnitude > 0.01 then
			lookDir = lookDir.Unit
			local right = lookDir:Cross(Vector3.new(0, 1, 0)).Unit
			alignOrientation.CFrame = CFrame.fromMatrix(Vector3.zero, right, Vector3.new(0, 1, 0), -lookDir)
		end
	end
end

ClothingEquippedEvent.OnClientEvent:Connect(function(itemName, isEquipped)
	print("Clothing Equipped: itemName=" .. itemName .. ", isEquipped=" .. tostring(isEquipped))
	
	local itemDef = itemsmodule[itemName]
	if not itemDef or not itemDef.JetPower then return end
	
	
	if isEquipped then
		jetpackEquipped = true
		currentJetpackModelName = itemDef.Model
		JETPACK_FORCE         = itemDef.JetPower
		JETPACK_VELOCITY_CAP  = itemDef.JetMaxVelocity
		JETPACK_MAX_FUEL      = itemDef.JetFlightTime
		JETPACK_RECHARGE_RATE = itemDef.JetRecharge
		ResetState()
		ShowHUD()

	else
		jetpackEquipped = false
		isJetpacking    = false
		wasJetpacking   = false
		if alignOrientation then
			alignOrientation.Enabled = false
			alignOrientation.CFrame  = CFrame.new()
		end
		HideHUD()
	end
end)

return JetpackManager