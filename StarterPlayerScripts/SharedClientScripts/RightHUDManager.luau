--[[
    RightHUDManager.lua
    Place in: StarterPlayer > StarterPlayerScripts  (ModuleScript)

    Provides a shared vertical stack on the top-right of the screen.
    Each panel has three states:
      icon     → tiny square icon (default, least intrusive)
      header   → header bar only (click icon to get here)
      expanded → full content (click header to get here, − to collapse back)

    Cycling:  icon → expanded → header → icon
]]

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")
local player       = Players.LocalPlayer
local PlayerGui    = player:WaitForChild("PlayerGui")

local RightHUDManager = {}

local COLORS = {
	BG         = Color3.fromRGB(8,  14,  26),
	BG2        = Color3.fromRGB(14, 22,  40),
	BORDER     = Color3.fromRGB(0,  200, 255),
	BORDER_DIM = Color3.fromRGB(0,  80,  120),
	ACCENT     = Color3.fromRGB(0,  220, 255),
	TEXT       = Color3.fromRGB(210, 235, 255),
	TEXT_DIM   = Color3.fromRGB(110, 150, 190),
}

local FONT_HEADER     = Enum.Font.GothamBold
local PANEL_WIDTH     = 240
local HEADER_HEIGHT   = 36
local ICON_SIZE       = 36
local STACK_PADDING   = 6
local EDGE_PADDING_TOP  = 10
local EDGE_PADDING_SIDE = 16
local TWEEN_INFO      = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local STATE_ICON     = "icon"
local STATE_HEADER   = "header"
local STATE_EXPANDED = "expanded"

local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function makeCorner(parent, radius)
	make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end

local function makeStroke(parent, color, thickness)
	make("UIStroke", {
		Color = color or COLORS.BORDER_DIM,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local sg = make("ScreenGui", {
	Name           = "RightHUD",
	ResetOnSpawn   = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder   = 5,
	ScreenInsets   = Enum.ScreenInsets.None,
}, PlayerGui)

local panels     = {}
local panelOrder = {}

local function restack()
	table.sort(panelOrder, function(a, b)
		return (panels[a] and panels[a].order or 0)
			< (panels[b] and panels[b].order or 0)
	end)

	local yOffset = EDGE_PADDING_TOP
	for _, id in ipairs(panelOrder) do
		local p = panels[id]
		if not p then continue end
		if p.hidden then continue end

		local h, w, xOff
		if p.state == STATE_ICON then
			h    = ICON_SIZE
			w    = ICON_SIZE
			xOff = -(ICON_SIZE + EDGE_PADDING_SIDE)
		elseif p.state == STATE_HEADER then
			h    = HEADER_HEIGHT
			w    = PANEL_WIDTH
			xOff = -(PANEL_WIDTH + EDGE_PADDING_SIDE)
		else
			h    = HEADER_HEIGHT + p.currentHeight
			w    = PANEL_WIDTH
			xOff = -(PANEL_WIDTH + EDGE_PADDING_SIDE)
		end

		TweenService:Create(p.frame, TWEEN_INFO, {
			Position = UDim2.new(1, xOff, 0, yOffset),
			Size     = UDim2.new(0, w, 0, h),
		}):Play()

		p.iconFrame.Visible    = p.state == STATE_ICON
		p.headerBar.Visible    = p.state ~= STATE_ICON
		p.contentFrame.Visible = p.state == STATE_EXPANDED

		yOffset = yOffset + h + STACK_PADDING
	end
end

function RightHUDManager:RegisterPanel(opts)
	local id        = opts.id
	local title     = opts.title     or id
	local icon      = opts.icon      or "◈"
	local order     = opts.order     or 99
	local maxHeight = opts.maxHeight or 200

	local frame = make("Frame", {
		Name             = "HUDPanel_" .. id,
		Size             = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE),
		Position         = UDim2.new(1, -(ICON_SIZE + EDGE_PADDING_SIDE), 0, EDGE_PADDING_TOP),
		BackgroundColor3 = COLORS.BG,
		BorderSizePixel  = 0,
		ClipsDescendants = false,
		ZIndex           = 10,
	}, sg)
	makeCorner(frame, 10)
	makeStroke(frame, COLORS.BORDER, 1.5)

	-- ── Icon state ────────────────────────────────────────────────────────────
	local iconFrame = make("TextButton", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "",
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 11,
		Visible                = true,
	}, frame)
	make("TextLabel", {
		Text                   = icon,
		TextSize               = 18,
		TextColor3             = COLORS.ACCENT,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		ZIndex                 = 12,
	}, iconFrame)

	-- ── Header bar ────────────────────────────────────────────────────────────
	local headerBar = make("Frame", {
		Size             = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundColor3 = COLORS.BG2,
		BorderSizePixel  = 0,
		ZIndex           = 11,
		Visible          = false,
	}, frame)
	makeCorner(headerBar, 10)
	make("Frame", {
		Size             = UDim2.new(1, 0, 0.5, 0),
		Position         = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG2,
		BorderSizePixel  = 0,
		ZIndex           = 11,
	}, headerBar)
	make("Frame", {
		Size             = UDim2.new(1, 0, 0, 2),
		Position         = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel  = 0,
		ZIndex           = 12,
	}, headerBar)
	make("TextLabel", {
		Text                   = icon .. "  " .. title,
		TextSize               = 13,
		Font                   = FONT_HEADER,
		TextColor3             = COLORS.ACCENT,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -40, 1, 0),
		Position               = UDim2.new(0, 10, 0, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 12,
	}, headerBar)

	local collapseBtn = make("TextButton", {
		Text                   = "−",
		TextSize               = 18,
		Font                   = FONT_HEADER,
		TextColor3             = COLORS.TEXT_DIM,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 32, 1, 0),
		Position               = UDim2.new(1, -34, 0, 0),
		BorderSizePixel        = 0,
		AutoButtonColor        = false,
		ZIndex                 = 13,
	}, headerBar)
	collapseBtn.MouseEnter:Connect(function() collapseBtn.TextColor3 = COLORS.TEXT end)
	collapseBtn.MouseLeave:Connect(function() collapseBtn.TextColor3 = COLORS.TEXT_DIM end)

	-- ── Content frame ─────────────────────────────────────────────────────────
	local contentFrame = make("Frame", {
		Name                   = "Content",
		Size                   = UDim2.new(1, -8, 1, -(HEADER_HEIGHT + 8)),
		Position               = UDim2.new(0, 4, 0, HEADER_HEIGHT + 4),
		BackgroundTransparency = 1,
		ClipsDescendants       = true,
		ZIndex                 = 11,
		Visible                = false,
	}, frame)

	local panelState = {
		id            = id,
		order         = order,
		frame         = frame,
		headerBar     = headerBar,
		iconFrame     = iconFrame,
		contentFrame  = contentFrame,
		collapseBtn   = collapseBtn,
		state         = STATE_ICON,
		currentHeight = maxHeight,
		maxHeight     = maxHeight,
	}
	panels[id] = panelState
	table.insert(panelOrder, id)

	-- icon clicked → expand
	iconFrame.Activated:Connect(function()
		panelState.state = STATE_EXPANDED
		collapseBtn.Text = "−"
		if opts.onExpand then opts.onExpand(contentFrame) end
		restack()
	end)

	-- − clicked from expanded → header only
	-- ◂ clicked from header → icon
	collapseBtn.Activated:Connect(function()
		if panelState.state == STATE_EXPANDED then
			panelState.state = STATE_HEADER
			collapseBtn.Text = "◂"
		elseif panelState.state == STATE_HEADER then
			panelState.state = STATE_ICON
		end
		restack()
	end)

	if opts.onBuild then opts.onBuild(contentFrame) end
	restack()

	return {
		setState   = function(s) panelState.state = s restack() end,
		getContent = function() return contentFrame end,
	}
end

function RightHUDManager:SetPanelHeight(id, height)
	local p = panels[id]
	if not p then return end
	p.currentHeight = math.max(0, height)
	restack()
end

function RightHUDManager:SetExpanded(id, expanded)
	local p = panels[id]
	if not p then return end
	p.state = expanded and STATE_EXPANDED or STATE_ICON
	if p.collapseBtn then p.collapseBtn.Text = "−" end
	restack()
end

-- Fully hide or show a panel (hides even the icon from the stack)
function RightHUDManager:SetVisible(id, visible)
	local p = panels[id]
	if not p then return end
	p.hidden = not visible
	p.frame.Visible = visible
	if not visible then
		-- Collapse to icon so it takes no space when re-shown
		p.state = STATE_ICON
	end
	restack()
end

return RightHUDManager