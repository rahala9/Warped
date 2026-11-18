--[[
	DialogUI.lua
	Place in: StarterPlayer > StarterPlayerScripts (LocalScript)

	Renders NPC dialog with the Sci Co corporate-dystopia aesthetic.
	NPC text appears at the top of the dialog panel.
	Player options appear at the bottom as selectable buttons.

	Listens to:
		DialogOpened (RemoteEvent) – server sends node data to display
		DialogClosed (RemoteEvent) – server tells client to close
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CloseButtonStyle = require(
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UI"):WaitForChild("CloseButtonStyle")
)
local DialogInputContextFactory = require(
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UI"):WaitForChild("DialogInputContextFactory")
)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local inputRoot = playerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local dialogContext = DialogInputContextFactory.Ensure(inputRoot)

-- ── Remotes ───────────────────────────────────────────────────────────────────
local DialogRemotesFolder = ReplicatedStorage:WaitForChild("DialogRemotes", 10)
local DialogOpened = DialogRemotesFolder and DialogRemotesFolder:WaitForChild("DialogOpened", 10)
local DialogClosed = DialogRemotesFolder and DialogRemotesFolder:WaitForChild("DialogClosed", 10)
local SelectOptionRE = DialogRemotesFolder and DialogRemotesFolder:WaitForChild("SelectOption", 10)
local CloseDialogRE = DialogRemotesFolder and DialogRemotesFolder:WaitForChild("CloseDialog", 10)

-- ── Colors ────────────────────────────────────────────────────────────────────
local COLORS = {
	BG            = Color3.fromRGB(12, 20, 38),
	BG_HEADER     = Color3.fromRGB(8, 14, 28),
	BORDER        = Color3.fromRGB(0, 80, 120),
	ACCENT        = Color3.fromRGB(0, 220, 255),
	TEXT_NPC      = Color3.fromRGB(220, 240, 255),
	TEXT_NPC_NAME = Color3.fromRGB(0, 220, 255),
	TEXT_OPTION   = Color3.fromRGB(190, 215, 240),
	TEXT_HOVER    = Color3.fromRGB(255, 255, 255),
	OPTION_BG     = Color3.fromRGB(18, 30, 55),
	OPTION_HOVER  = Color3.fromRGB(25, 45, 75),
	OPTION_BORDER = Color3.fromRGB(0, 60, 90),
	DIVIDER       = Color3.fromRGB(0, 60, 90),
}

local FONT_NPC_NAME = Enum.Font.GothamBold
local FONT_NPC_TEXT = Enum.Font.Gotham
local FONT_OPTION   = Enum.Font.Gotham
local FONT_HINT     = Enum.Font.Code

local TYPEWRITER_SPEED = 0.03 -- seconds per character
local PANEL_WIDTH = 320
local PANEL_TWEEN_TIME = 0.25

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function makeCorner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function makeStroke(parent, color, thickness)
	make("UIStroke", {
		Color = color or COLORS.BORDER,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

-- ── State ─────────────────────────────────────────────────────────────────────
local isOpen = false
local typewriterThread = nil

-- ── Build the GUI ─────────────────────────────────────────────────────────────
local screenGui = make("ScreenGui", {
	Name = "DialogUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	Enabled = false,
}, playerGui)

-- Dim overlay
--local overlay = make("Frame", {
--	Name = "Overlay",
--	Size = UDim2.new(1, 0, 1, 0),
--	BackgroundColor3 = Color3.new(0, 0, 0),
--	BackgroundTransparency = 0.5,
--	BorderSizePixel = 0,
--	ZIndex = 1,
--}, screenGui)

-- Main panel — top left
local panel = make("Frame", {
	Name = "DialogPanel",
	Size = UDim2.new(0, PANEL_WIDTH, 0, 0), -- height set dynamically
	Position = UDim2.new(0, 20, 0, 56),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = COLORS.BG,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 10,
}, screenGui)
makeCorner(panel, 8)
makeStroke(panel, COLORS.BORDER, 1.5)

-- Left accent bar
local accentBar = make("Frame", {
	Size = UDim2.new(0, 3, 1, -12),
	Position = UDim2.new(0, 0, 0, 6),
	BackgroundColor3 = COLORS.ACCENT,
	BorderSizePixel = 0,
	ZIndex = 11,
}, panel)

-- X close button
local closeBtn = make("TextButton", {
}, panel)
CloseButtonStyle.Apply(closeBtn)

-- NPC name label
local npcNameLabel = make("TextLabel", {
	Name = "NpcName",
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.new(0, 14, 0, 10),
	BackgroundTransparency = 1,
	TextColor3 = COLORS.TEXT_NPC_NAME,
	Font = FONT_NPC_NAME,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
	ZIndex = 12,
}, panel)

-- NPC text label
local npcTextLabel = make("TextLabel", {
	Name = "NpcText",
	Size = UDim2.new(1, -28, 0, 0), -- height auto
	Position = UDim2.new(0, 14, 0, 38),
	BackgroundTransparency = 1,
	TextColor3 = COLORS.TEXT_NPC,
	Font = FONT_NPC_TEXT,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	AutomaticSize = Enum.AutomaticSize.Y,
	Text = "",
	RichText = true,
	ZIndex = 12,
}, panel)

-- Divider line between NPC text and options
local divider = make("Frame", {
	Name = "Divider",
	Size = UDim2.new(1, -28, 0, 1),
	Position = UDim2.new(0, 14, 0, 0), -- positioned dynamically
	BackgroundColor3 = COLORS.DIVIDER,
	BorderSizePixel = 0,
	ZIndex = 11,
}, panel)

-- Options container
local optionsFrame = make("Frame", {
	Name = "Options",
	Size = UDim2.new(1, -28, 0, 0), -- height auto
	Position = UDim2.new(0, 14, 0, 0), -- positioned dynamically
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 11,
}, panel)

make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
}, optionsFrame)

-- ── Typewriter effect ─────────────────────────────────────────────────────────
local function typewriteText(label, fullText, callback)
	-- Cancel any existing typewriter
	if typewriterThread then
		task.cancel(typewriterThread)
		typewriterThread = nil
	end

	label.Text = fullText
	label.MaxVisibleGraphemes = 0

	typewriterThread = task.spawn(function()
		local characterCount = utf8.len(fullText) or #fullText
		for i = 1, characterCount do
			label.MaxVisibleGraphemes = i
			task.wait(TYPEWRITER_SPEED)
		end
		label.MaxVisibleGraphemes = -1
		typewriterThread = nil
		if callback then callback() end
	end)
end

local function skipTypewriter(label, fullText)
	if typewriterThread then
		task.cancel(typewriterThread)
		typewriterThread = nil
	end
	label.Text = fullText
	label.MaxVisibleGraphemes = -1
end

-- ── Layout calculation ────────────────────────────────────────────────────────
local function layoutPanel()
	-- Wait a frame for AutomaticSize to compute
	task.wait()

	local npcTextHeight = npcTextLabel.AbsoluteSize.Y
	local dividerY = 38 + npcTextHeight + 12
	divider.Position = UDim2.new(0, 14, 0, dividerY)

	local optionsY = dividerY + 12
	optionsFrame.Position = UDim2.new(0, 14, 0, optionsY)

	-- Wait for options layout
	task.wait()

	local optionsHeight = optionsFrame.AbsoluteSize.Y
	local totalHeight = optionsY + optionsHeight + 30 -- padding at bottom

	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, totalHeight)
end

-- ── Build option buttons ──────────────────────────────────────────────────────
local function buildOptions(options)
	-- Clear existing options
	for _, child in ipairs(optionsFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for i, option in ipairs(options or {}) do
		local btn = make("TextButton", {
			Name = "Option_" .. i,
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundColor3 = COLORS.OPTION_BG,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 12,
		}, optionsFrame)
		makeCorner(btn, 5)
		makeStroke(btn, COLORS.OPTION_BORDER, 1)

		-- Raised keyboard keycap. This is drawn from UI primitives so it remains
		-- crisp and automatically supports every numbered dialog option.
		local keyShadow = make("Frame", {
			Name = "KeyShadow",
			Size = UDim2.fromOffset(27, 25),
			Position = UDim2.new(0, 8, 0.5, -10),
			BackgroundColor3 = Color3.fromRGB(2, 9, 18),
			BorderSizePixel = 0,
			ZIndex = 13,
		}, btn)
		makeCorner(keyShadow, 4)

		local keycap = make("Frame", {
			Name = "Keycap",
			Size = UDim2.fromOffset(27, 25),
			Position = UDim2.new(0, 8, 0.5, -13),
			BackgroundColor3 = Color3.fromRGB(10, 24, 42),
			BorderSizePixel = 0,
			ZIndex = 14,
		}, btn)
		makeCorner(keycap, 4)
		makeStroke(keycap, COLORS.ACCENT, 1.5)

		make("Frame", {
			Name = "TopHighlight",
			Size = UDim2.new(1, -8, 0, 1),
			Position = UDim2.new(0, 4, 0, 4),
			BackgroundColor3 = Color3.fromRGB(150, 240, 255),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			ZIndex = 15,
		}, keycap)

		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = COLORS.TEXT_HOVER,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			Text = tostring(i),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 16,
		}, keycap)

		-- Option text
		local optionLabel = make("TextLabel", {
			Size = UDim2.new(1, -52, 1, 0),
			Position = UDim2.new(0, 45, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = COLORS.TEXT_OPTION,
			Font = FONT_OPTION,
			TextSize = 18,
			Text = option.text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 13,
		}, btn)

		-- Hover effects
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = COLORS.OPTION_HOVER
			optionLabel.TextColor3 = COLORS.TEXT_HOVER
		end)

		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = COLORS.OPTION_BG
			optionLabel.TextColor3 = COLORS.TEXT_OPTION
		end)

		-- Click handler
		btn.MouseButton1Click:Connect(function()
			if SelectOptionRE then
				SelectOptionRE:FireServer(option.index)
			end
		end)
	end
end

-- ── Open / Close ──────────────────────────────────────────────────────────────
local currentFullText = ""

local function closeDialog()
	if typewriterThread then
		task.cancel(typewriterThread)
		typewriterThread = nil
	end

	isOpen = false
	dialogContext.Enabled = false
	screenGui.Enabled = false
	npcTextLabel.Text = ""
	npcTextLabel.MaxVisibleGraphemes = -1
	npcNameLabel.Text = ""
	currentFullText = ""

	for _, child in ipairs(optionsFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
end

local function openDialog(payload)
	if not payload then return end

	isOpen = true
	dialogContext.Enabled = true
	screenGui.Enabled = true

	npcNameLabel.Text = payload.npcDisplayName or payload.npcId or "???"
	currentFullText = payload.npcText or ""

	buildOptions(payload.options)
	-- Lay out the complete text while it is hidden, then reveal graphemes. This
	-- prevents typed lines from outrunning the panel's clipped height.
	npcTextLabel.Text = currentFullText
	npcTextLabel.MaxVisibleGraphemes = 0
	layoutPanel()
	typewriteText(npcTextLabel, currentFullText, function()
		layoutPanel()
	end)
end

for optionIndex = 1, 9 do
	local action = dialogContext:WaitForChild("SelectDialogOptionAction" .. optionIndex)
	action.Pressed:Connect(function()
		if not isOpen or not SelectOptionRE then
			return
		end
		if optionsFrame:FindFirstChild("Option_" .. optionIndex) then
			SelectOptionRE:FireServer(optionIndex)
		end
	end)
end

closeBtn.MouseButton1Click:Connect(function()
	if CloseDialogRE then
		CloseDialogRE:FireServer()
	end
	closeDialog()
end)

-- ── Input handling ────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not isOpen then return end

	-- Click anywhere to skip typewriter
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if typewriterThread then
			skipTypewriter(npcTextLabel, currentFullText)
			layoutPanel()
		end
	end

end)

-- ── Event listeners ───────────────────────────────────────────────────────────
if DialogOpened then
	DialogOpened.OnClientEvent:Connect(function(payload)
		openDialog(payload)
	end)
end

if DialogClosed then
	DialogClosed.OnClientEvent:Connect(function()
		closeDialog()
	end)
end
