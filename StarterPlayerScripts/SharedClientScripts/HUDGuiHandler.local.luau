-- StarterPlayerScripts/SharedClientScripts/HUDGuiHandler (LocalScript)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Modules
local SharedClientScripts = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("SharedClientScripts")
local ImageLabelAnimator = require(SharedClientScripts:WaitForChild("ImageLabelAnimator"))

local PlayerStateFunctions = require(LocalPlayer:WaitForChild("PlayerScripts")
	:WaitForChild("SharedClientScripts")
	:WaitForChild("PlayerStateFunctions"))

local font = require(workspace.Rbx_CustomFont)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local DisplayHUDEvent = Remotes:WaitForChild("DisplayHUD")
local AttributesChangedEvent = Remotes:WaitForChild("AttributesChanged")
local GuiShownClientEvent = Remotes:WaitForChild("GuiShownClient")
local GuiHiddenClientEvent = Remotes:WaitForChild("GuiHiddenClient")

-- GUI
local SharedGUI = PlayerGui:WaitForChild("SharedGUI")
local HUDGui = SharedGUI:WaitForChild("HUDGui")

local HUDAnimatedImageLabel = HUDGui:WaitForChild("HUDAnimatedImageLabel")
local HUDLargeImageLabel = HUDGui:WaitForChild("HUDLargeImageLabel")

local HUDGuiBackground = HUDLargeImageLabel
local HUDGuiMainFrame = HUDGuiBackground:WaitForChild("MainFrame")

local HUDGuiAttributesFrame = HUDGuiMainFrame:WaitForChild("Attributes")
local HUDGuiStrengthFrame = HUDGuiAttributesFrame:WaitForChild("StrengthFrame")
local HUDGuiIntelligenceFrame = HUDGuiAttributesFrame:WaitForChild("IntelligenceFrame")
local HUDGuiWisdomFrame = HUDGuiAttributesFrame:WaitForChild("WisdomFrame")
local HUDGuiPerceptionFrame = HUDGuiAttributesFrame:WaitForChild("PerceptionFrame")
local HUDGuiCharismaFrame = HUDGuiAttributesFrame:WaitForChild("CharismaFrame")
local HUDGuiVitalityFrame = HUDGuiAttributesFrame:WaitForChild("VitalityFrame")
local HUDGuiCombatFrame = HUDGuiMainFrame:WaitForChild("Combat")
local HUDGuiArmorFrame = HUDGuiCombatFrame:WaitForChild("ArmorFrame")
local HUDGuiAttackFrame = HUDGuiCombatFrame:WaitForChild("AttackFrame")
local HUDGuiCriticalHitChanceFrame = HUDGuiCombatFrame:WaitForChild("CriticalHitChanceFrame")
local HUDGuiCriticalHitDamageFrame = HUDGuiCombatFrame:WaitForChild("CriticalHitDamageFrame")

local StrengthTitle = font.Label("WarText")
local StrengthData = font.Label("WarText")
local IntelligenceTitle = font.Label("WarText")
local IntelligenceData = font.Label("WarText")
local WisdomTitle = font.Label("WarText")
local WisdomData = font.Label("WarText")
local PerceptionTitle = font.Label("WarText")
local PerceptionData = font.Label("WarText")
local CharismaTitle = font.Label("WarText")
local CharismaData = font.Label("WarText")
local VitalityTitle = font.Label("WarText")
local VitalityData = font.Label("WarText")
local ArmorTitle = font.Label("WarText")
local ArmorData = font.Label("WarText")
local AttackTitle = font.Label("WarText")
local AttackData = font.Label("WarText")
local CriticalHitChanceTitle = font.Label("WarText")
local CriticalHitChanceData = font.Label("WarText")
local CriticalHitDamageTitle = font.Label("WarText")
local CriticalHitDamageData = font.Label("WarText")

local function initLabel(name,label,position,parentFrame)
	label.Parent = parentFrame
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextSize = 18
	label.SizeConstraint = Enum.SizeConstraint.RelativeXY
	label.AnchorPoint = Vector2.new(0, 0)
	label.Position = position
	label.TextColor3 = Color3.fromRGB(352, 397, 408)
	label.Name = name
	label.Text = ""
	label.BorderSizePixel = 0
	label.RichText = true
end

local function typeText(txt: string,label)
	if (not txt) then
		return
	end
	
	label.Text = ""
	for c in string.gmatch(txt,".") do
		label.Text ..= c
		task.wait(c == "." and 1 or .1)
	end
end

initLabel("StrengthTitle",StrengthTitle,UDim2.new(.25,0,.1,0),HUDGuiStrengthFrame)
initLabel("StrengthData",StrengthData,UDim2.new(.75,0,.1,0),HUDGuiStrengthFrame)
initLabel("IntelligenceTitle",IntelligenceTitle,UDim2.new(.25,0,.1,0),HUDGuiIntelligenceFrame)
initLabel("IntelligenceData",IntelligenceData,UDim2.new(.75,0,.1,0),HUDGuiIntelligenceFrame)
initLabel("WisdomTitle",WisdomTitle,UDim2.new(.25,0,.1,0),HUDGuiWisdomFrame)
initLabel("WisdomData",WisdomData,UDim2.new(.75,0,.1,0),HUDGuiWisdomFrame)
initLabel("PerceptionTitle",PerceptionTitle,UDim2.new(.25,0,.1,0),HUDGuiPerceptionFrame)
initLabel("PerceptionData",PerceptionData,UDim2.new(.75,0,.1,0),HUDGuiPerceptionFrame)
initLabel("CharismaTitle",CharismaTitle,UDim2.new(.25,0,.1,0),HUDGuiCharismaFrame)
initLabel("CharismaData",CharismaData,UDim2.new(.75,0,.1,0),HUDGuiCharismaFrame)
initLabel("VitalityTitle",VitalityTitle,UDim2.new(.25,0,.1,0),HUDGuiVitalityFrame)
initLabel("VitalityData",VitalityData,UDim2.new(.75,0,.1,0),HUDGuiVitalityFrame)

initLabel("AttackTitle",AttackTitle,UDim2.new(0,0,.1,0),HUDGuiAttackFrame)
initLabel("AttackData",AttackData,UDim2.new(.55,0,.1,0),HUDGuiAttackFrame)

initLabel("ArmorTitle",ArmorTitle,UDim2.new(0,0,.1,0),HUDGuiArmorFrame)
initLabel("ArmorData",ArmorData,UDim2.new(.55,0,.1,0),HUDGuiArmorFrame)

initLabel("CriticalHitChanceTitle",CriticalHitChanceTitle,UDim2.new(0,0,.1,0),HUDGuiCriticalHitChanceFrame)
initLabel("CriticalHitChanceData",CriticalHitChanceData,UDim2.new(.55,0,.1,0),HUDGuiCriticalHitChanceFrame)

initLabel("CriticalHitDamageTitle",CriticalHitDamageTitle,UDim2.new(0,0,.1,0),HUDGuiCriticalHitDamageFrame)
initLabel("CriticalHitDamageData",CriticalHitDamageData,UDim2.new(.55,0,.1,0),HUDGuiCriticalHitDamageFrame)



-- If you want UIManager to own enabling/disabling, set true.
-- If you want this handler to control HUDGui.Enabled directly, set false.
local DEFER_ENABLED = true

-- Flipbook settings
local FlipbookCfg = {
	Image = "rbxassetid://99697161837404",
	FrameSize = Vector2.new(256, 154),
	Columns = 4,
	Rows = 6,
	FPS = 24,
	StartFrame = 0,
}

-- Final big HUD image (static)
local FinalLargeGuiHUD = "rbxassetid://76519281227756"
local LARGE_W, LARGE_H = 768, 462

local currentAttributes = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function setHudEnabled(on: boolean)
	if DEFER_ENABLED then return end
	HUDGui.Enabled = on
end

local function setLayerEnabled(layer: Instance?, enabled: boolean)
	if layer and layer:IsA("LayerCollector") then
		layer.Enabled = enabled
	end
end

----------------------------------------------------------------
-- Big HUD animator (two labels, no blink)
----------------------------------------------------------------
HUDLargeImageLabel.Image = FinalLargeGuiHUD
HUDLargeImageLabel.ImageRectSize = Vector2.new(LARGE_W, LARGE_H)
HUDLargeImageLabel.ImageRectOffset = Vector2.new(0, 0)

HUDAnimatedImageLabel.Visible = false
HUDLargeImageLabel.Visible = false

local BigFlip = ImageLabelAnimator.new(HUDAnimatedImageLabel, FlipbookCfg)
local bigToken = 0
local bigOnFinal = false

task.spawn(function()
	ContentProvider:PreloadAsync({ HUDAnimatedImageLabel, HUDLargeImageLabel })
end)

local function bigCancelImmediate()
	bigToken += 1
	bigOnFinal = false

	BigFlip:Cancel()
	BigFlip:SetFrame(0)

	HUDAnimatedImageLabel.Visible = false
	HUDLargeImageLabel.Visible = false
	setHudEnabled(false)
end

local function bigOpen(loopMode: boolean)
	bigToken += 1
	local t = bigToken

	setHudEnabled(true)
	bigOnFinal = false

	HUDLargeImageLabel.Visible = false
	HUDAnimatedImageLabel.Visible = true
	BigFlip:SetFrame(0)

	BigFlip:PlayForward({
		loop = loopMode,
		onFinished = function()
			if bigToken ~= t then return end
			if loopMode then return end

			-- swap visibility only
			HUDAnimatedImageLabel.Visible = false
			HUDLargeImageLabel.Visible = true
			bigOnFinal = true
			
			task.wait(.5)
			task.spawn(typeText, "Oomph", StrengthTitle)
			task.spawn(typeText, "Big Brain", IntelligenceTitle)
			task.spawn(typeText, "Common Sense", WisdomTitle)
			task.spawn(typeText, "Peep", PerceptionTitle)
			task.spawn(typeText, "Brick", VitalityTitle)
			task.spawn(typeText, "Vibe", CharismaTitle)
			
			task.wait(1)
			task.spawn(typeText, currentAttributes.Strength, StrengthData)
			task.spawn(typeText, currentAttributes.Intelligence, IntelligenceData)
			task.spawn(typeText, currentAttributes.Wisdom, WisdomData)
			task.spawn(typeText, currentAttributes.Perception, PerceptionData)
			task.spawn(typeText, currentAttributes.Vitality, VitalityData)
			task.spawn(typeText, currentAttributes.Charisma, CharismaData)
			
			task.spawn(typeText, "Attack", AttackTitle)
			task.spawn(typeText, currentAttributes.Attack, AttackData)
			task.spawn(typeText, "Armor", ArmorTitle)
			task.spawn(typeText, currentAttributes.Armor, ArmorData)
			
			task.spawn(typeText, "Crit Chance", CriticalHitChanceTitle)
			task.spawn(typeText, currentAttributes.CriticalHitChance, CriticalHitChanceData)
			task.spawn(typeText, "Crit Damage", CriticalHitDamageTitle)
			task.spawn(typeText, currentAttributes.CriticalHitDamage, CriticalHitDamageData)
			
		end
	})
end

local function bigClose()
	bigToken += 1
	local t = bigToken

	setHudEnabled(true)

	-- hide final instantly, show sheet label instantly
	HUDLargeImageLabel.Visible = false
	HUDAnimatedImageLabel.Visible = true

	local startFrame
	if bigOnFinal then
		startFrame = BigFlip:GetTotalFrames() - 1
	else
		startFrame = BigFlip:GetFrame()
		if startFrame == 0 then
			startFrame = BigFlip:GetTotalFrames() - 1
		end
	end
	bigOnFinal = false

	BigFlip:Cancel()
	BigFlip:PlayReverse({
		fromFrame = startFrame,
		onFinished = function()
			if bigToken ~= t then return end
			HUDAnimatedImageLabel.Visible = false
			setHudEnabled(false)
		end
	})
end

----------------------------------------------------------------
-- Arm HUD (per player) using same animator module
----------------------------------------------------------------
local ArmByPlayer = {} -- [Player] = record

local function getArmHudParts(targetPlayer: Player)
	local character = targetPlayer.Character
	if not character then return end

	local armHUD = character:FindFirstChild("armHUD")
	if not armHUD then return end

	local frontScreen = armHUD:FindFirstChild("FrontScreen")
	local backScreen  = armHUD:FindFirstChild("BackScreen")
	if not frontScreen or not backScreen then return end

	local frontImage = frontScreen:FindFirstChild("FrontImageLabel")
	local backImage  = backScreen:FindFirstChild("BackImageLabel")
	if not frontImage or not backImage then return end

	return frontScreen, backScreen, frontImage, backImage
end

local function getArmRecord(plr: Player)
	local frontScreen, backScreen, frontImage, backImage = getArmHudParts(plr)
	if not frontScreen then return end

	local rec = ArmByPlayer[plr]
	if rec and rec.boundFront == frontImage then
		return rec
	end

	rec = {
		boundFront = frontImage,
		frontScreen = frontScreen,
		backScreen = backScreen,
		frontAnim = ImageLabelAnimator.new(frontImage, FlipbookCfg),
		backAnim  = ImageLabelAnimator.new(backImage,  FlipbookCfg),
		token = 0,
	}
	ArmByPlayer[plr] = rec
	return rec
end

local function armCancel(rec)
	rec.token += 1
	rec.frontAnim:Cancel()
	rec.backAnim:Cancel()
	rec.frontAnim:SetFrame(0)
	rec.backAnim:SetFrame(0)
	setLayerEnabled(rec.frontScreen, false)
	setLayerEnabled(rec.backScreen, false)
end

local function armOpen(rec, loopMode: boolean)
	rec.token += 1
	setLayerEnabled(rec.frontScreen, true)
	setLayerEnabled(rec.backScreen, true)
	rec.frontAnim:SetFrame(0)
	rec.backAnim:SetFrame(0)
	rec.frontAnim:PlayForward({ loop = loopMode })
	rec.backAnim:PlayForward({ loop = loopMode })
end

local function armClose(rec)
	rec.token += 1
	local t = rec.token

	setLayerEnabled(rec.frontScreen, true)
	setLayerEnabled(rec.backScreen, true)

	local startFrame = rec.frontAnim:GetFrame()
	if startFrame == 0 then
		startFrame = rec.frontAnim:GetTotalFrames() - 1
	end

	rec.frontAnim:Cancel()
	rec.backAnim:Cancel()

	rec.frontAnim:PlayReverse({
		fromFrame = startFrame,
		onFinished = function()
			if rec.token ~= t then return end
			setLayerEnabled(rec.frontScreen, false)
		end
	})

	rec.backAnim:PlayReverse({
		fromFrame = startFrame,
		onFinished = function()
			if rec.token ~= t then return end
			setLayerEnabled(rec.backScreen, false)
		end
	})
end

----------------------------------------------------------------
-- HUD UI wiring (titles + attributes)
----------------------------------------------------------------

AttributesChangedEvent.OnClientEvent:Connect(function(attributes)
	
	currentAttributes.Strength = attributes.Strength
	currentAttributes.Intelligence = attributes.Intelligence
	currentAttributes.Wisdom = attributes.Wisdom
	currentAttributes.Perception = attributes.Perception
	currentAttributes.Charisma = attributes.Charisma
	currentAttributes.Vitality = attributes.Vitality

	currentAttributes.Attack = attributes.Attack
	currentAttributes.Armor = attributes.Armor
	
	currentAttributes.CriticalHitChance = attributes.CriticalHitChance
	currentAttributes.CriticalHitDamage = attributes.CriticalHitDamage
end)

GuiShownClientEvent.Event:Connect(function(name)
	if name ~= "HUDGui" then return end

	PlayerStateFunctions.ChangeState(PlayerStateFunctions.States.CheckHUD)
end)

GuiHiddenClientEvent.Event:Connect(function(name)
	if name ~= "HUDGui" then return end

	StrengthTitle.Text = ""
	IntelligenceTitle.Text = ""
	WisdomTitle.Text = ""
	PerceptionTitle.Text = ""
	VitalityTitle.Text = ""
	CharismaTitle.Text = ""
	AttackTitle.Text = ""
	ArmorTitle.Text = ""
	CriticalHitChanceTitle.Text = ""
	CriticalHitDamageTitle.Text = ""

	StrengthData.Text = ""
	IntelligenceData.Text = ""
	WisdomData.Text = ""
	PerceptionData.Text = ""
	VitalityData.Text = ""
	CharismaData.Text = ""
	AttackData.Text = ""
	ArmorData.Text = ""
	CriticalHitChanceData.Text = ""
	CriticalHitDamageData.Text = ""
	
	PlayerStateFunctions.ChangeState(PlayerStateFunctions.States.StopCheckHUD)
end)

-- Close button
local CloseButton = HUDLargeImageLabel:WaitForChild("CloseButton")
CloseButton.Activated:Connect(function()
	-- If UIManager is the owner, you probably want to trigger whatever hides HUDGui.
	-- We'll at least play the close animation:
	bigClose()

	-- If you ALSO want to notify your UI show/hide system:
	GuiHiddenClientEvent:Fire("HUDGui", HUDGui)
end)

----------------------------------------------------------------
-- DisplayHUD remote: arm HUD for target player + big HUD only for local player
----------------------------------------------------------------
DisplayHUDEvent.OnClientEvent:Connect(function(targetPlayer: Player, mode: string)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return
	end
	if mode ~= "Stop" and mode ~= "PlayLoop" and mode ~= "PlayOnce" then
		return
	end

	local character = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	character:WaitForChild("armHUD", 5)

	local rec = getArmRecord(targetPlayer)
	if not rec then return end

	if mode == "Stop" then
		armClose(rec)
		if targetPlayer == LocalPlayer then
			bigClose()
		end
		return
	end

	local loopMode = (mode == "PlayLoop")

	armCancel(rec)
	armOpen(rec, loopMode)

	if targetPlayer == LocalPlayer then
		bigCancelImmediate()
		bigOpen(loopMode)
	end
end)

warn("HUDGuiHandler LocalScript running.")
