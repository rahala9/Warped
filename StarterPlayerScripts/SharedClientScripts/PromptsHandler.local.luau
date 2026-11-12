local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local SkillCheckFunctions = require(ReplicatedStorage.SharedFunctions.SkillCheckFunctions)

local GetInventoryEvent = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
local GetQuests = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetQuests")
local DisplayActionMessageEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DisplayActionMessage")
local CanGetLootFromCorpseEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CanGetLootFromCorpse")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SharedGui = PlayerGui:WaitForChild("SharedGUI")
local ActionGui = SharedGui:WaitForChild("ActionGui")
local ActionMessagesFrame = ActionGui:WaitForChild("ActionMessagesFrame")
local ActionMessage = ActionMessagesFrame:WaitForChild("ActionMessage")
local ActionMessageTimer = ActionMessagesFrame:WaitForChild("ActionMessageTimer")

local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))

local activePromptCleanups = {}

local function cleanupPrompt(prompt)
	local cleanup = activePromptCleanups[prompt]
	if cleanup then
		activePromptCleanups[prompt] = nil
		cleanup()
	end
end

-- ============================================================
-- FLIGHT HUD MATCHING STYLE
-- ============================================================

local HUD_STYLE = {
	PanelBg = Color3.fromRGB(4, 7, 14),
	InnerBg = Color3.fromRGB(6, 14, 26),
	TrackBg = Color3.fromRGB(10, 20, 40),

	Cyan = Color3.fromRGB(0, 200, 255),
	CyanDim = Color3.fromRGB(0, 100, 160),
	CyanDark = Color3.fromRGB(0, 60, 100),

	Text = Color3.fromRGB(210, 235, 255),
	MutedText = Color3.fromRGB(0, 140, 190),
	White = Color3.fromRGB(255, 255, 255),
	Red = Color3.fromRGB(255, 60, 60),

	Font = Enum.Font.GothamBold,
}

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or HUD_STYLE.CyanDim
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.35
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- ============================================================
-- CONFIG
-- ============================================================

local ActionData = {
	["Hacking"] = {["SkillName"] = SkillCheckFunctions.Skills.Hacking.name},
	["BuildElectronic"] = {["SkillName"] = SkillCheckFunctions.Skills.ElectronicalEngineering.name},
	["BuildMechanical"] = {["SkillName"] = SkillCheckFunctions.Skills.MechanicalEngineering.name},
	["BuildPowerSystem"] = {["SkillName"] = SkillCheckFunctions.Skills.PowerEngineering.name},
	["BuildWeapon"] = {["SkillName"] = SkillCheckFunctions.Skills.WeaponEngineering.name},
}

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRS.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

-- ============================================================
-- GUI HELPERS
-- ============================================================

local function getScreenGui3()
	return PlayerGui:WaitForChild("SharedGUI"):FindFirstChild("ActionGui")
end

local function createProgressBarGradient(parent, leftSide)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.5, 1)
	frame.Position = UDim2.fromScale(leftSide and 0 or 0.5, 0)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.Parent = parent

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(leftSide and 0 or -1, 0)
	image.Image = "rbxassetid://12367858557"
	image.ImageRectSize = Vector2.new(128, 128)
	image.ImageRectOffset = Vector2.new(128, 384)
	image.ImageColor3 = HUD_STYLE.Cyan
	image.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new {
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(.4999, 0),
		NumberSequenceKeypoint.new(.5, 1),
		NumberSequenceKeypoint.new(1, 1)
	}
	gradient.Rotation = leftSide and 180 or 0
	gradient.Parent = image

	return gradient
end

local function createCircularProgressBar()
	local bar = Instance.new("Frame")
	bar.Name = "CircularProgressBar"
	bar.Size = UDim2.fromOffset(30, 30)
	bar.AnchorPoint = Vector2.new(0, 0)
	bar.Position = UDim2.fromScale(0, 0)
	bar.BackgroundTransparency = 1

	local gradient1 = createProgressBarGradient(bar, true)
	local gradient2 = createProgressBarGradient(bar, false)

	local progress = Instance.new("NumberValue")
	progress.Name = "Progress"
	progress.Parent = bar

	progress.Changed:Connect(function(value)
		local angle = math.clamp(value * 360, 0, 360)
		gradient1.Rotation = math.clamp(angle - 180, 0, 180) + 180
		gradient2.Rotation = math.clamp(angle, 0, 180)
		bar.BackgroundTransparency = angle == 0 and 1 or 0
	end)

	return bar
end

-- ============================================================
-- INVENTORY / REQUIREMENT HELPERS
-- ============================================================

local function GetItemTotal(inventory, itemId)
	local totalAmount = 0

	if inventory["Items"][itemId] then
		totalAmount += inventory["Items"][itemId].Amount
	end

	for key, item in pairs(inventory["Items"]) do
		if itemsmodule[item.Name] and itemsmodule[item.Name].SubType == "Container" then
			for containerItemKey, containerItem in pairs(inventory["Items"][key].Contains) do
				if containerItemKey == itemId then
					totalAmount += containerItem.Amount
				end
			end
		end
	end

	return totalAmount
end

function IsTempTool(playerInventory, itemName)
	if playerInventory["TempHold"] and playerInventory["TempHold"].Name == itemName then
		return true
	end

	return false
end

function HasTool(playerInventory, toolName, orEquivalent)
	for _, tool in pairs(playerInventory["Tools"]) do
		if tool == toolName then
			return true
		end
	end

	if itemsmodule[toolName] and itemsmodule[toolName].Type == "TempHold" then
		if playerInventory["TempHold"] and playerInventory["TempHold"].Name == toolName then
			return true
		end
	end

	if orEquivalent and itemsmodule[toolName] and itemsmodule[toolName].EqualItems ~= nil then
		for _, equalItem in pairs(itemsmodule[toolName].EqualItems) do
			if IsTempTool(playerInventory, equalItem) then
				return true
			end

			local hasItem = HasTool(playerInventory, equalItem, false)
			if hasItem then
				return true
			end
		end
	end

	return false
end

function HasItem(playerInventory, itemName, amountNeeded, includeToolbelt, orEquivalent)
	if itemsmodule[itemName] == nil then
		warn("PromptsHandler - HasItem: Item does not exist:" .. itemName)
		return false, itemName, 0, amountNeeded
	end

	if includeToolbelt then
		if HasTool(playerInventory, itemName, true) then
			return true, true, 1, 1
		elseif playerInventory["Items"][itemName] then
			if itemsmodule[itemName].Limit == 1 then
				amountNeeded = 1
			end
			return true, itemName, playerInventory["Items"][itemName].Amount, amountNeeded
		else
			local totalAmount = GetItemTotal(playerInventory, itemName)
			if totalAmount >= amountNeeded then
				return true, itemName, totalAmount, amountNeeded
			end
		end
	else
		local totalAmount = GetItemTotal(playerInventory, itemName)
		if totalAmount >= amountNeeded then
			return true, itemName, totalAmount, amountNeeded
		end
	end

	if orEquivalent and itemsmodule[itemName].EqualItems ~= nil then
		for _, equalItem in pairs(itemsmodule[itemName].EqualItems) do
			if IsTempTool(playerInventory, equalItem) then
				return true, equalItem, 1, 1
			end

			local hasItem, usedItemName, equalAmount, equalAmountNeeded = HasItem(playerInventory, equalItem, amountNeeded, true, false)

			if hasItem then
				if itemsmodule[itemName].Limit == 1 then
					equalAmountNeeded = 1
				end
				return true, usedItemName, equalAmount, equalAmountNeeded
			end
		end
	end

	return false, itemName
end

function GetSkillBonus(itemName, skillName)
	local itemDef = itemsmodule[itemName]

	if itemDef and itemDef.Attributes and itemDef.Attributes.SkillBonus then
		if itemDef.Attributes.SkillBonus.Skill == "All" then
			return itemDef.Attributes.SkillBonus.Value
		elseif itemDef.Attributes.SkillBonus.Skill == skillName then
			return itemDef.Attributes.SkillBonus.Value
		end
	end

	return 0
end

function GetEquipmentBonus(skillName, playerInventory)
	local equipmentSkillBonus = 0

	local offHandItem = playerInventory["OffHand"]
	if offHandItem then
		equipmentSkillBonus += GetSkillBonus(offHandItem.Name, skillName)
	end

	local heldToolName = PlayerState.CurrentTool
	if heldToolName then
		equipmentSkillBonus += GetSkillBonus(heldToolName, skillName)
	end

	return equipmentSkillBonus
end

-- ============================================================
-- CUSTOM PROMPT CREATION
-- ============================================================

local function createPrompt3(prompt, inputType, gui)
	local tweensForButtonHoldBegin = {}
	local tweensForButtonHoldEnd = {}
	local tweensForFadeOut = {}
	local tweensForFadeIn = {}

	local tweenInfoInFullDuration = TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenInfoOutHalfSecond = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local promptUI = Instance.new("Frame")
	promptUI.Name = "Prompt"
	promptUI.Position = UDim2.new(.6, 0, -.23, 0)
	promptUI.Size = UDim2.fromOffset(190, 38)
	promptUI.BackgroundTransparency = 1

	local proximityPromptGUIFrame = Instance.new("Frame")
	proximityPromptGUIFrame.Name = "PromptFrame"
	proximityPromptGUIFrame.Size = UDim2.fromOffset(190, 38)
	proximityPromptGUIFrame.BackgroundColor3 = HUD_STYLE.PanelBg
	proximityPromptGUIFrame.BackgroundTransparency = 0.12
	proximityPromptGUIFrame.BorderSizePixel = 0
	proximityPromptGUIFrame.ClipsDescendants = true
	addCorner(proximityPromptGUIFrame, 8)
	local frameStroke = addStroke(proximityPromptGUIFrame, HUD_STYLE.CyanDim, 1, 0.35)

	local accentLine = Instance.new("Frame")
	accentLine.Name = "AccentLine"
	accentLine.Size = UDim2.new(1, 0, 0, 2)
	accentLine.BackgroundColor3 = HUD_STYLE.Cyan
	accentLine.BorderSizePixel = 0
	accentLine.Parent = proximityPromptGUIFrame

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -8, 1, -6)
	content.Position = UDim2.fromOffset(4, 4)
	content.BackgroundTransparency = 1
	content.Parent = proximityPromptGUIFrame

	local uilist = Instance.new("UIListLayout")
	uilist.FillDirection = Enum.FillDirection.Horizontal
	uilist.SortOrder = Enum.SortOrder.LayoutOrder
	uilist.VerticalAlignment = Enum.VerticalAlignment.Center
	uilist.Padding = UDim.new(0, 6)
	uilist.Parent = content

	local itemRequired = Instance.new("ImageLabel")
	itemRequired.Name = "ItemRequired"
	itemRequired.Size = UDim2.fromOffset(30, 30)
	itemRequired.BackgroundColor3 = HUD_STYLE.InnerBg
	itemRequired.BackgroundTransparency = 0.05
	itemRequired.BorderSizePixel = 0
	itemRequired.ImageRectSize = Vector2.new(64, 64)
	itemRequired.LayoutOrder = 1
	itemRequired.Parent = content
	addCorner(itemRequired, 6)
	addStroke(itemRequired, HUD_STYLE.CyanDim, 1, 0.45)

	local keyBox = Instance.new("Frame")
	keyBox.Name = "KeyBox"
	keyBox.Size = UDim2.fromOffset(36, 30)
	keyBox.BackgroundColor3 = HUD_STYLE.TrackBg
	keyBox.BackgroundTransparency = 0
	keyBox.BorderSizePixel = 0
	keyBox.LayoutOrder = 2
	keyBox.Parent = content
	addCorner(keyBox, 6)
	addStroke(keyBox, HUD_STYLE.Cyan, 1, 0.25)

	local button = Instance.new("TextLabel")
	button.Name = "Button"
	button.BackgroundTransparency = 1
	button.Font = HUD_STYLE.Font
	button.Size = UDim2.fromScale(1, 1)
	button.RichText = true
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Center
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.TextStrokeTransparency = 1
	button.TextColor3 = HUD_STYLE.Cyan
	button.Text = ""
	button.Parent = keyBox

	local action = Instance.new("TextLabel")
	action.Name = "Action"
	action.BackgroundTransparency = 1
	action.LayoutOrder = 3
	action.Font = HUD_STYLE.Font
	action.Size = UDim2.new(1, -82, 1, 0)
	action.RichText = true
	action.TextSize = 12
	action.TextWrapped = true
	action.TextStrokeTransparency = 1
	action.TextColor3 = HUD_STYLE.Text
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.TextYAlignment = Enum.TextYAlignment.Center
	action.Text = string.upper(prompt.ActionText or "")
	action.Parent = content

	local numberRequired = Instance.new("TextLabel")
	numberRequired.Name = "NumberRequired"
	numberRequired.BackgroundTransparency = 1
	numberRequired.Font = HUD_STYLE.Font
	numberRequired.Size = UDim2.fromOffset(30, 10)
	numberRequired.Position = UDim2.fromOffset(0, 20)
	numberRequired.TextSize = 8
	numberRequired.TextXAlignment = Enum.TextXAlignment.Center
	numberRequired.TextStrokeTransparency = 1
	numberRequired.TextColor3 = HUD_STYLE.Cyan
	numberRequired.Parent = itemRequired

	local function getOrCreateKeyIcon()
		local icon = button:FindFirstChild("KeyIcon")
		if not icon then
			icon = Instance.new("ImageLabel")
			icon.Name = "KeyIcon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.fromOffset(22, 22)
			icon.Position = UDim2.new(0.5, -11, 0.5, -11)
			icon.ImageColor3 = HUD_STYLE.White
			icon.Parent = button
		end
		return icon
	end

	local function clearKeyIcon()
		local icon = button:FindFirstChild("KeyIcon")
		if icon then
			icon:Destroy()
		end
	end

	local function refreshPromptButton()
		clearKeyIcon()

		if inputType == Enum.ProximityPromptInputType.Gamepad then
			local gamepadImage = GamepadButtonImage[prompt.GamepadKeyCode]
			if gamepadImage then
				local icon = getOrCreateKeyIcon()
				icon.Image = gamepadImage
				button.Text = ""
				return
			end
			button.Text = UserInputService:GetStringForKeyCode(prompt.GamepadKeyCode)
			return
		end

		local keyboardImage = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if keyboardImage then
			local icon = getOrCreateKeyIcon()
			icon.Image = keyboardImage
			button.Text = ""
			return
		end

		local keyText = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		local mappedIcon = KeyboardButtonIconMapping[keyText]

		if mappedIcon then
			local icon = getOrCreateKeyIcon()
			icon.Image = mappedIcon
			button.Text = ""
			return
		end

		button.Text = KeyCodeToTextMapping[prompt.KeyboardKeyCode] or keyText
	end

	local requiredItem = prompt:GetAttribute("RequiredItem")
	local requiredTool = prompt:GetAttribute("RequiredTool")
	local requiredToolHidden = prompt:GetAttribute("RequiredToolHidden")
	local requiredState = prompt:GetAttribute("RequiredState")

	if requiredItem ~= nil and itemsmodule[requiredItem] then
		itemRequired.Image = itemsmodule.ImageMap[itemsmodule[requiredItem].Type]
		itemRequired.ImageRectOffset = Vector2.new(itemsmodule[requiredItem].ImageOffsetX, itemsmodule[requiredItem].ImageOffsetY)

		local playerInventory = GetInventoryEvent:InvokeServer()
		local requiredAmount = prompt:GetAttribute("RequiredItemAmount") or 1

		local hasItem, usedItemName, itemAmount, itemAmountNeeded = HasItem(playerInventory, requiredItem, requiredAmount, true, true)

		if hasItem then
			numberRequired.Text = itemAmount .. "/" .. itemAmountNeeded
			if usedItemName ~= requiredItem then
				itemRequired.Image = itemsmodule.ImageMap[itemsmodule[usedItemName].Type]
				itemRequired.ImageRectOffset = Vector2.new(itemsmodule[usedItemName].ImageOffsetX, itemsmodule[usedItemName].ImageOffsetY)
				if itemsmodule[usedItemName].Type == "Tool" then
					numberRequired.Text = ""
				end
			end
		else
			numberRequired.Text = "0/1"
			numberRequired.TextColor3 = HUD_STYLE.Red
		end

	elseif requiredState ~= nil then
		local requiredStateOn = prompt:GetAttribute(requiredState)
		itemRequired.Image = itemsmodule.ImageMap[itemsmodule[requiredState].Type]
		itemRequired.ImageRectOffset = Vector2.new(itemsmodule[requiredState].ImageOffsetX, itemsmodule[requiredState].ImageOffsetY)
		numberRequired.Text = requiredStateOn and "ON" or "OFF"

	elseif requiredTool ~= nil then
		if requiredToolHidden then
			itemRequired.Image = "rbxassetid://74058163635426"
			itemRequired.ImageRectOffset = Vector2.new(0, 3 * 64)
		else
			itemRequired.Image = itemsmodule.ImageMap[itemsmodule[requiredTool].Type]
			itemRequired.ImageRectOffset = Vector2.new(itemsmodule[requiredTool].ImageOffsetX, itemsmodule[requiredTool].ImageOffsetY)
		end

		local playerInventory = GetInventoryEvent:InvokeServer()

		if HasTool(playerInventory, requiredTool, true) then
			numberRequired.Text = ""
		else
			numberRequired.Text = "X"
			numberRequired.TextColor3 = HUD_STYLE.Red
		end
	else
		itemRequired.Visible = false
		promptUI.Size = UDim2.fromOffset(154, 38)
		proximityPromptGUIFrame.Size = UDim2.fromOffset(154, 38)
		action.Size = UDim2.new(1, -42, 1, 0)
	end

	refreshPromptButton()
	
	for _, child in ipairs(gui.ActionFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Prompt_" .. prompt.Name then
			child:Destroy()
		end
	end

	proximityPromptGUIFrame.Parent = promptUI
	proximityPromptGUIFrame.Visible = true
	promptUI.Active = true
	promptUI.Parent = gui.ActionFrame

	if prompt.HoldDuration > 0 then
		local circleBar = createCircularProgressBar()
		circleBar.Parent = itemRequired.Visible and itemRequired or keyBox

		table.insert(tweensForButtonHoldBegin, TweenService:Create(circleBar.Progress, tweenInfoInFullDuration, { Value = 1 }))
		table.insert(tweensForButtonHoldEnd, TweenService:Create(circleBar.Progress, tweenInfoOutHalfSecond, { Value = 0 }))
	end

	local holdBeganConnection
	local holdEndedConnection
	local triggeredConnection
	local triggerEndedConnection
	local changedConnection

	local cleanedUp = false

	local function cleanup()
		if cleanedUp then return end
		cleanedUp = true

		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end

		if prompt.Parent and prompt.Parent:FindFirstChild("SelectionBox") then
			prompt.Parent.SelectionBox.Visible = false
		end

		if holdBeganConnection then holdBeganConnection:Disconnect() end
		if holdEndedConnection then holdEndedConnection:Disconnect() end
		if triggeredConnection then triggeredConnection:Disconnect() end
		if triggerEndedConnection then triggerEndedConnection:Disconnect() end
		if changedConnection then changedConnection:Disconnect() end

		if promptUI then
			promptUI:Destroy()
		end
	end

	if prompt.HoldDuration > 0 then
		holdBeganConnection = prompt.PromptButtonHoldBegan:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldBegin) do
				tween:Play()
			end
		end)

		holdEndedConnection = prompt.PromptButtonHoldEnded:Connect(function()
			for _, tween in ipairs(tweensForButtonHoldEnd) do
				tween:Play()
			end
		end)
	end

	triggeredConnection = prompt.Triggered:Connect(function()
		for _, tween in ipairs(tweensForFadeOut) do
			tween:Play()
		end
	end)

	triggerEndedConnection = prompt.TriggerEnded:Connect(function()
		for _, tween in ipairs(tweensForFadeIn) do
			tween:Play()
		end
	end)

	changedConnection = prompt.Changed:Connect(function(propertyName)
		if cleanedUp then return end

		if propertyName == "ActionText" then
			action.Text = string.upper(prompt.ActionText or "")
		elseif propertyName == "KeyboardKeyCode" or propertyName == "GamepadKeyCode" then
			refreshPromptButton()
		end
	end)

	return cleanup
end

-- ============================================================
-- QUEST / LOOT FILTERS
-- ============================================================

local function ShowQuestTargetPrompt(promptObject)
	local quests = GetQuests:InvokeServer("PlayerQuests")
	local questTargetFullName = promptObject.Parent:GetFullName()

	for _, quest in pairs(quests) do
		for _, quest_step in pairs(quest.Steps) do
			if quest_step.Type == "Put" then
				if quest_step.Destination == questTargetFullName and quest_step.Complete == false then
					return true
				end
			elseif quest_step.Type == "Search" then
				if quest_step.Object == questTargetFullName and quest_step.Complete == false then
					return true
				end
			elseif quest_step.Type == "UseItem" then
				if quest_step.Object == questTargetFullName and quest_step.Complete == false then
					return true
				end
			elseif quest_step.Type == "Action" then
				if quest_step.Action == promptObject.Name and quest_step.Object == questTargetFullName and quest_step.Complete == false then
					return quest, quest_step
				end
			end
		end
	end

	return false
end

local function ShowLootCorpsePrompt(promptObject)
	if promptObject.Parent == nil then
		return false
	end

	local corpseID = promptObject.Parent:GetAttribute("CorpseID")
	if not corpseID then
		return false
	end

	return CanGetLootFromCorpseEvent:InvokeServer(corpseID)
end

-- ============================================================
-- ACTION MESSAGES
-- ============================================================

local activeSeq = 0

DisplayActionMessageEvent.OnClientEvent:Connect(function(messages, messageDelay, timer, opts)
	activeSeq += 1
	local seq = activeSeq

	local function isCancelled()
		return seq ~= activeSeq
	end

	local messageNumber = 1
	ActionMessagesFrame.Visible = true

	local function setUI(text, t)
		if isCancelled() then
			return false
		end

		ActionMessage.Text = text or ""
		ActionMessageTimer.Text = t or ""

		return true
	end

	if not timer then
		if not setUI(messages[messageNumber], "") then
			return
		end

		task.wait(messageDelay)

		if isCancelled() then
			return
		end

		setUI("", "")
		ActionMessagesFrame.Visible = false

		return
	end

	local lastMessageChangeAt = os.clock()
	local endAt = os.clock() + timer

	while true do
		if isCancelled() then
			return
		end

		local remaining = math.max(0, math.ceil(endAt - os.clock()))

		if not setUI(messages[messageNumber], tostring(remaining)) then
			return
		end

		if messageNumber < #messages and os.clock() - lastMessageChangeAt >= messageDelay then
			messageNumber += 1
			lastMessageChangeAt = os.clock()
		end

		if remaining <= 0 then
			break
		end

		task.wait(0.1)
	end

	if isCancelled() then
		return
	end

	setUI("", "")
	ActionMessagesFrame.Visible = false
end)

-- ============================================================
-- LOAD
-- ============================================================

local function onLoad()
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Default then
			return
		end

		if not prompt.Enabled then
			cleanupPrompt(prompt)
			return
		end

		-- Prevent duplicate custom UI for the same prompt.
		cleanupPrompt(prompt)

		if prompt.Name == "TakeBurger" then
			PlayerGui:WaitForChild("BurgerCookGui").Enabled = true
			return
		end

		if prompt:GetAttribute("QuestTarget") then
			if not ShowQuestTargetPrompt(prompt) then
				return
			end
		elseif prompt.Name == "LootCorpse" then
			if not ShowLootCorpsePrompt(prompt) then
				return
			end
		end

		if prompt.Parent and prompt.Parent:FindFirstChild("SelectionBox") ~= nil then
			prompt.Parent.SelectionBox.Visible = true
		end

		local gui = getScreenGui3()
		if not gui then
			warn("PromptsHandler: ActionGui was not found")
			return
		end

		local rawCleanup = createPrompt3(prompt, inputType, gui)

		local enabledConnection
		local hiddenConnection
		local ancestryConnection

		local function cleanup()
			if activePromptCleanups[prompt] ~= cleanup then
				return
			end

			activePromptCleanups[prompt] = nil

			if enabledConnection then
				enabledConnection:Disconnect()
				enabledConnection = nil
			end

			if hiddenConnection then
				hiddenConnection:Disconnect()
				hiddenConnection = nil
			end

			if ancestryConnection then
				ancestryConnection:Disconnect()
				ancestryConnection = nil
			end

			if rawCleanup then
				rawCleanup()
				rawCleanup = nil
			end
		end

		activePromptCleanups[prompt] = cleanup

		enabledConnection = prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
			print("TEST PROMPT ENABLED CHANGED:",prompt)
			if not prompt.Enabled then
				cleanup()
			end
		end)

		hiddenConnection = ProximityPromptService.PromptHidden:Connect(function(hiddenPrompt)
			if hiddenPrompt == prompt then
				cleanup()
			end
		end)

		ancestryConnection = prompt.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				cleanup()
			end
		end)

		if not prompt.Enabled then
			cleanup()
		end
	end)

	ProximityPromptService.PromptHidden:Connect(function(prompt)
		cleanupPrompt(prompt)

		if prompt.Name == "TakeBurger" then
			PlayerGui:WaitForChild("BurgerCookGui").Enabled = false
			return
		end
	end)
end

onLoad()
