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
local Workspace    = game:GetService("Workspace")
local player       = Players.LocalPlayer
local PlayerGui    = player:WaitForChild("PlayerGui")
-- The toolbelt is cloned after this module can be required. Never block here:
-- StateHandler must connect equipment events immediately or it can miss the
-- initial jetpack-equipped event entirely.
local ToolbeltGui

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
local DEFAULT_TOOLBELT_INSET = 104
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
local bottomReservations = {}

local function findToolbeltGui()
	if ToolbeltGui and ToolbeltGui.Parent then return ToolbeltGui end
	local sharedGui = PlayerGui:FindFirstChild("SharedGUI")
	ToolbeltGui = sharedGui and sharedGui:FindFirstChild("ToolbeltGui") or nil
	return ToolbeltGui
end

local function isEffectivelyVisible(guiObject, toolbeltGui)
	local current = guiObject
	while current and current ~= toolbeltGui do
		if current:IsA("GuiObject") and not current.Visible then return false end
		current = current.Parent
	end
	return not toolbeltGui:IsA("LayerCollector") or toolbeltGui.Enabled
end

local function hasVisibleAppearance(guiObject)
	if guiObject.BackgroundTransparency < 0.99 then return true end
	if (guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton"))
		and guiObject.Image ~= ""
		and guiObject.ImageTransparency < 0.99
	then
		return true
	end
	if (guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox"))
		and guiObject.Text ~= ""
		and guiObject.TextTransparency < 0.99
	then
		return true
	end
	return false
end

function RightHUDManager:GetBottomInset(rightSideWidth)
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local toolbeltGui = findToolbeltGui()
	if not toolbeltGui then
		return math.min(DEFAULT_TOOLBELT_INSET, math.max(48, math.min(240, viewport.Y * 0.45)))
	end
	if toolbeltGui:IsA("LayerCollector") and not toolbeltGui.Enabled then return 16 end
	if toolbeltGui:IsA("GuiObject") and not toolbeltGui.Visible then return 16 end

	local rightStart = viewport.X - math.min(rightSideWidth or 360, viewport.X)
	local minimumTop
	for _, descendant in ipairs(toolbeltGui:GetDescendants()) do
		if not descendant:IsA("GuiObject")
			or not isEffectivelyVisible(descendant, toolbeltGui)
			or not hasVisibleAppearance(descendant)
		then
			continue
		end

		local position = descendant.AbsolutePosition
		local size = descendant.AbsoluteSize
		local bottom = position.Y + size.Y
		if size.X > 2
			and size.Y > 2
			and position.X + size.X >= rightStart
			and position.Y >= viewport.Y * 0.45
			and position.Y < viewport.Y
			and bottom >= viewport.Y * 0.7
		then
			minimumTop = minimumTop and math.min(minimumTop, position.Y) or position.Y
		end
	end

	local maximumInset = math.max(48, math.min(240, viewport.Y * 0.45))
	if minimumTop then
		return math.clamp(viewport.Y - minimumTop + 12, 48, maximumInset)
	end
	return math.min(DEFAULT_TOOLBELT_INSET, maximumInset)
end

local function reservedBottomHeight()
	local total = 0
	for _, height in pairs(bottomReservations) do total += height end
	return total
end

local function restack()
	table.sort(panelOrder, function(a, b)
		return (panels[a] and panels[a].order or 0)
			< (panels[b] and panels[b].order or 0)
	end)

	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local panelWidth = math.max(160, math.min(PANEL_WIDTH, viewport.X - EDGE_PADDING_SIDE * 2))
	local bottomLimit = viewport.Y
		- RightHUDManager:GetBottomInset(panelWidth + EDGE_PADDING_SIDE * 2)
		- reservedBottomHeight()
	local availableHeight = math.max(0, bottomLimit - EDGE_PADDING_TOP)

	local fixedHeight = 0
	local desiredExpandedContent = 0
	local visibleCount = 0
	for _, id in ipairs(panelOrder) do
		local p = panels[id]
		if not p or p.hidden then continue end
		visibleCount += 1
		if p.state == STATE_ICON then
			fixedHeight += ICON_SIZE
		elseif p.state == STATE_HEADER then
			fixedHeight += HEADER_HEIGHT
		else
			fixedHeight += HEADER_HEIGHT
			desiredExpandedContent += p.currentHeight
		end
	end
	if visibleCount > 1 then fixedHeight += (visibleCount - 1) * STACK_PADDING end
	local contentScale = desiredExpandedContent > 0
		and math.clamp((availableHeight - fixedHeight) / desiredExpandedContent, 0, 1)
		or 1

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
			w    = panelWidth
			xOff = -(panelWidth + EDGE_PADDING_SIDE)
		else
			h    = HEADER_HEIGHT + math.floor(p.currentHeight * contentScale)
			w    = panelWidth
			xOff = -(panelWidth + EDGE_PADDING_SIDE)
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

function RightHUDManager:SetBottomReservation(id, height)
	height = math.max(0, tonumber(height) or 0)
	if bottomReservations[id] == height then return end
	bottomReservations[id] = height
	restack()
end

function RightHUDManager:RefreshLayout()
	restack()
end

local viewportConnection
local function bindViewport()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(restack)
	end
	restack()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)

local toolbeltConnections = {}
local function bindToolbelt(toolbeltGui)
	for _, connection in ipairs(toolbeltConnections) do connection:Disconnect() end
	table.clear(toolbeltConnections)
	ToolbeltGui = toolbeltGui
	if not toolbeltGui then return end
	if toolbeltGui:IsA("LayerCollector") then
		table.insert(toolbeltConnections, toolbeltGui:GetPropertyChangedSignal("Enabled"):Connect(restack))
	end
	if toolbeltGui:IsA("GuiObject") then
		table.insert(toolbeltConnections, toolbeltGui:GetPropertyChangedSignal("Visible"):Connect(restack))
	end
	table.insert(toolbeltConnections, toolbeltGui.DescendantAdded:Connect(function() task.defer(restack) end))
	table.insert(toolbeltConnections, toolbeltGui.DescendantRemoving:Connect(function() task.defer(restack) end))
	table.insert(toolbeltConnections, toolbeltGui.AncestryChanged:Connect(function(_, parent)
		if not parent then bindToolbelt(nil) end
	end))
	task.defer(restack)
end

local initialToolbelt = findToolbeltGui()
if initialToolbelt then bindToolbelt(initialToolbelt) end
PlayerGui.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "ToolbeltGui" and descendant.Parent and descendant.Parent.Name == "SharedGUI" then
		bindToolbelt(descendant)
	end
end)
-- Close the small race between the initial lookup and connecting DescendantAdded.
if not ToolbeltGui then
	local lateToolbelt = findToolbeltGui()
	if lateToolbelt then bindToolbelt(lateToolbelt) end
end
bindViewport()

return RightHUDManager
