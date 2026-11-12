-- InventoryBrowser.lua
-- Fully generated replacement UI. Does NOT require VacpacGui or UIRefs.
-- Creates: inventory browser, equipment slots, toolbelt slots, item-details host,
-- container host, and a normal backpack drop target using DDArea="Backpack".

local TweenService = game:GetService("TweenService")

local InventoryBrowser = {}
InventoryBrowser.__index = InventoryBrowser

local CFG = {
	SLOT_SIZE = 72,
	SLOT_GAP = 6,
	ITEM_COLUMNS = 6,
	EQUIP_COLUMNS = 2,
	TOOLBELT_START_SLOT = 3,
	TOOLBELT_END_SLOT = 9,
	PANEL_H_SCALE = 0.72,
	BASE_BACKPACK_CAPACITY = 20, -- normal backpack slots before Back clothing capacity is added
	ACCENT = Color3.fromRGB(255, 200, 40),
	BG = Color3.fromRGB(10, 12, 16),
	PANEL = Color3.fromRGB(18, 22, 28),
	PANEL_BORDER = Color3.fromRGB(38, 48, 58),
	EQUIP_BG = Color3.fromRGB(14, 18, 24),
	TEXT_PRIMARY = Color3.fromRGB(230, 235, 240),
	TEXT_DIM = Color3.fromRGB(90, 105, 120),
	FILTER_ACTIVE = Color3.fromRGB(255, 200, 40),
	FILTER_INACTIVE = Color3.fromRGB(22, 28, 38),
	RARITY_ATLAS = "rbxassetid://13802435951",
	RARITY_RECT_Y = 832,
	RARITY_RECT_SZ = 64,
	TYPE_CATEGORIES = {
		Weapon="Weapons", Artifact="Weapons", Ammo="Weapons", OffHand="Weapons",
		Tool="Tools", Consumable="Consumables", Clothing="Clothing",
		Material="Materials", Access="Access", Info="Info",
		Misc="Misc", PowerSource="Misc", Disk="Misc", Heal="Misc", Trash="Misc", Money="Misc",
	},
	FILTERS = {
		{key="All", label="ALL", icon="◈"},
		{key="Weapons", label="WEAPONS", icon="⚔"},
		{key="Tools", label="TOOLS", icon="🔧"},
		{key="Consumables", label="CONSUMABLES", icon="🍖"},
		{key="Clothing", label="CLOTHING", icon="👕"},
		{key="Materials", label="MATERIALS", icon="📦"},
		{key="Access", label="ACCESS", icon="🔑"},
		{key="Info", label="INFO", icon="📄"},
		{key="Misc", label="MISC", icon="📎"},
	},
	EQUIP_SLOTS = {
		{key="Weapon", label="WEAPON", invKey="Weapon"},
		{key="OffHand", label="OFF HAND", invKey="OffHand"},
		{key="Head", label="HEAD", invKey="Head"},
		{key="Face", label="FACE", invKey="Face"},
		{key="Chest", label="CHEST", invKey="Chest"},
		{key="Back", label="BACK", invKey="Back"},
		{key="Pants", label="PANTS", invKey="Pants"},
	},
}

local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(parent, radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return make("UIStroke", {
		Color = color or CFG.PANEL_BORDER,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, parent)
end

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tw(inst, props)
	TweenService:Create(inst, FAST, props):Play()
end

local function setDD(inst, area, slot, itemId, dragSource)
	inst:SetAttribute("DD", true)
	inst:SetAttribute("DDArea", area)
	inst:SetAttribute("DDSlot", slot)
	inst:SetAttribute("ItemId", itemId)
	inst:SetAttribute("ParentContainerId", nil)
	inst:SetAttribute("DDDragSource", dragSource ~= false)
end

local function makeSlotButton(parent, name, size, showNameStrip)
	local btn = make("ImageButton", {
		Name = name or "Slot",
		Size = size or UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE),
		BackgroundColor3 = CFG.PANEL,
		AutoButtonColor = false,
		Active = true,
		Selectable = true,
		ZIndex = 5,
	}, parent)
	corner(btn, 4)
	stroke(btn, CFG.PANEL_BORDER, 1, 0)

	make("ImageLabel", {
		Name = "ItemPic",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 6,
	}, btn)
	make("TextLabel", {
		Name = "ItemName",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 1,
		TextTransparency = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 1, 0, 1),
		ZIndex = 1,
	}, btn)
	make("TextLabel", {
		Name = "ItemAmount",
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0.25,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 16),
		Position = UDim2.new(0, 4, 0, 3),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 10,
	}, btn)
	make("ImageLabel", {
		Name = "RarityPic",
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, -3),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 8,
	}, btn)

	if showNameStrip then
		make("TextLabel", {
			Name = "NameStrip",
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = Color3.fromRGB(245, 250, 255),
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			TextStrokeTransparency = 0.25,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 0, 18),
			Position = UDim2.new(0, 2, 1, -20),
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 11,
		}, btn)
	end

	return btn
end

local function makeEquipSlot(name, labelText, parent)
	local frame = make("Frame", {
		Name = name .. "Frame",
		Size = UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE + 14),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, parent)
	make("TextLabel", {
		Name = "SlotLabel",
		Text = labelText,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(80, 95, 110),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, CFG.SLOT_SIZE, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, frame)
	local btn = makeSlotButton(frame, "Slot1", UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE), false)
	btn.Position = UDim2.new(0, 0, 0, 14)
	btn.BackgroundColor3 = CFG.EQUIP_BG
	return btn
end

local function buildUI(playerGui)
	local gridW = (CFG.ITEM_COLUMNS * CFG.SLOT_SIZE) + ((CFG.ITEM_COLUMNS - 1) * CFG.SLOT_GAP) + 14
	local equipW = (CFG.EQUIP_COLUMNS * CFG.SLOT_SIZE) + ((CFG.EQUIP_COLUMNS - 1) * CFG.SLOT_GAP) + 20
	local panelW = 8 + gridW + 8 + equipW + 8

	local sg = make("ScreenGui", {
		Name = "InventoryBrowser",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
		Enabled = false,
		DisplayOrder = 1000,
	}, playerGui)

	local containerHost = make("Frame", {
		Name = "ContainerHost",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 70,
	}, sg)

	local itemDetails = make("Frame", {
		Name = "ItemDetails",
		Visible = false,
		BackgroundTransparency = 1,
		ZIndex = 80,
	}, sg)

	local dialogHost = make("Frame", {
		Name = "DialogHost",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 90,
	}, sg)

	local panel = make("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0, 0),
		Size = UDim2.new(0, panelW, CFG.PANEL_H_SCALE, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = CFG.BG,
		ClipsDescendants = false,
		ZIndex = 2,
	}, sg)
	corner(panel, 8)
	stroke(panel, CFG.PANEL_BORDER, 1.5, 0)
	make("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 28, 38)),
			ColorSequenceKeypoint.new(0.08, CFG.BG),
			ColorSequenceKeypoint.new(1, CFG.BG),
		}),
		Rotation = 90,
	}, panel)

	local header = make("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.fromRGB(14, 18, 24),
		ZIndex = 3,
	}, panel)
	corner(header, 8)
	make("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Color3.fromRGB(14, 18, 24),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, header)
	make("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = CFG.ACCENT,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, header)
	make("TextLabel", {
		Name = "Title",
		Text = "◈  VACPAC™",
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextColor3 = CFG.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -330, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 4,
	}, header)
	local capacityBadge = make("TextLabel", {
		Name = "CapacityBadge",
		Text = "INVENTORY 0 / " .. tostring(CFG.BASE_BACKPACK_CAPACITY),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(245, 250, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 208, 0, 30),
		Position = UDim2.new(1, -254, 0, 9),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, header)
	local closeBtn = make("TextButton", {
		Name = "CloseBtn",
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(235, 245, 255),
		BackgroundColor3 = Color3.fromRGB(40, 55, 75),
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -38, 0, 9),
		AutoButtonColor = true,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, header)
	corner(closeBtn, 8)

	local filterColumns = 5
	local filterGap = 4
	local filterH = 24
	local filterW = math.floor((panelW - 16 - ((filterColumns - 1) * filterGap)) / filterColumns)
	local filterBar = make("Frame", {
		Name = "FilterBar",
		Size = UDim2.new(1, -16, 0, (filterH * 2) + filterGap),
		Position = UDim2.new(0, 8, 0, 52),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, panel)
	make("UIGridLayout", {
		CellSize = UDim2.new(0, filterW, 0, filterH),
		CellPadding = UDim2.new(0, filterGap, 0, filterGap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, filterBar)
	local filterBtns = {}
	for i, f in ipairs(CFG.FILTERS) do
		local isAll = f.key == "All"
		local fb = make("TextButton", {
			Name = "Filter_" .. f.key,
			Text = f.icon .. " " .. f.label,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = isAll and CFG.BG or CFG.TEXT_DIM,
			BackgroundColor3 = isAll and CFG.FILTER_ACTIVE or CFG.FILTER_INACTIVE,
			Size = UDim2.new(0, filterW, 0, filterH),
			AutoButtonColor = false,
			LayoutOrder = i,
			ZIndex = 4,
		}, filterBar)
		corner(fb, 4)
		filterBtns[f.key] = fb
	end

	local infoRow = make("Frame", {
		Name = "InfoRow",
		Size = UDim2.new(1, -16, 0, 16),
		Position = UDim2.new(0, 8, 0, 108),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, panel)
	local itemCountLbl = make("TextLabel", {
		Name = "ItemCount",
		Text = "0 items",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = CFG.TEXT_DIM,
		BackgroundTransparency = 1,
		Size = UDim2.new(0.5, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, infoRow)
	local pageInfoLbl = make("TextLabel", {
		Name = "PageInfo",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = CFG.TEXT_DIM,
		BackgroundTransparency = 1,
		Visible = false,
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
	}, infoRow)

	local bodyTop = 128
	local bodyBottom = 48
	local gridFrame = make("ScrollingFrame", {
		Name = "GridFrame",
		Size = UDim2.new(0, gridW, 1, -(bodyTop + bodyBottom)),
		Position = UDim2.new(0, 8, 0, bodyTop),
		BackgroundColor3 = Color3.fromRGB(14, 18, 24),
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = CFG.ACCENT,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 3,
		ClipsDescendants = true,
	}, panel)
	corner(gridFrame, 6)
	stroke(gridFrame, CFG.PANEL_BORDER, 1, 0)
	gridFrame:SetAttribute("DD", true)
	gridFrame:SetAttribute("DDArea", "Backpack")
	gridFrame:SetAttribute("BrowserInventoryDropTarget", true)

	local grid = make("Frame", {
		Name = "SlotGrid",
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 4,
	}, gridFrame)
	grid:SetAttribute("DD", true)
	grid:SetAttribute("DDArea", "Backpack")
	grid:SetAttribute("BrowserInventoryDropTarget", true)
	make("UIGridLayout", {
		CellSize = UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE),
		CellPadding = UDim2.new(0, CFG.SLOT_GAP, 0, CFG.SLOT_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, grid)
	make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }, grid)

	local equipCol = make("ScrollingFrame", {
		Name = "EquipCol",
		Size = UDim2.new(0, equipW, 1, -(bodyTop + bodyBottom)),
		Position = UDim2.new(0, 8 + gridW + 8, 0, bodyTop),
		BackgroundColor3 = Color3.fromRGB(14, 18, 24),
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = CFG.ACCENT,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 3,
		ClipsDescendants = true,
	}, panel)
	corner(equipCol, 6)
	stroke(equipCol, CFG.PANEL_BORDER, 1, 0)
	make("TextLabel", {
		Name = "EquipHeader",
		Text = "EQUIPPED",
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = CFG.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 14),
		Position = UDim2.new(0, 4, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, equipCol)
	local equipInner = make("Frame", {
		Name = "EquipInner",
		Size = UDim2.new(0, (CFG.EQUIP_COLUMNS * CFG.SLOT_SIZE) + ((CFG.EQUIP_COLUMNS - 1) * CFG.SLOT_GAP), 0, 0),
		Position = UDim2.new(0, 4, 0, 24),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 4,
	}, equipCol)
	make("UIGridLayout", {
		CellSize = UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE + 14),
		CellPadding = UDim2.new(0, CFG.SLOT_GAP, 0, CFG.SLOT_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = CFG.EQUIP_COLUMNS,
	}, equipInner)
	local equipSlotBtns = {}
	for i, es in ipairs(CFG.EQUIP_SLOTS) do
		local btn = makeEquipSlot(es.key, es.label, equipInner)
		btn.Parent.LayoutOrder = i
		equipSlotBtns[es.key] = btn
	end

	local toolbeltBar = make("Frame", {
		Name = "ToolbeltBar",
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.new(0, 8, 1, -40),
		BackgroundColor3 = Color3.fromRGB(14, 18, 24),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, panel)
	corner(toolbeltBar, 6)
	stroke(toolbeltBar, CFG.PANEL_BORDER, 1, 0)
	make("TextLabel", {
		Name = "ToolbeltLabel",
		Text = "TOOLBELT",
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = CFG.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 68, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, toolbeltBar)
	local toolbeltInner = make("Frame", {
		Name = "ToolbeltInner",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -84, 1, -8),
		Position = UDim2.new(0, 76, 0, 4),
		ZIndex = 4,
	}, toolbeltBar)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, toolbeltInner)
	local toolbeltSlots = {}
	for i = CFG.TOOLBELT_START_SLOT, CFG.TOOLBELT_END_SLOT do
		local b = makeSlotButton(toolbeltInner, "ToolbeltSlot" .. i, UDim2.new(0, 32, 0, 32), false)
		b.LayoutOrder = i
		b:SetAttribute("DD", true)
		b:SetAttribute("DDArea", "Toolbelt")
		b:SetAttribute("DDSlot", i)
		toolbeltSlots[i] = b
	end

	local pagingBar = make("Frame", {
		Name = "PagingBar",
		Visible = false,
		Size = UDim2.new(1, -16, 0, 34),
		Position = UDim2.new(0, 8, 1, -40),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, panel)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, pagingBar)
	local function pageButton(txt, order)
		local b = make("TextButton", {
			Name = txt .. "Btn",
			Text = txt,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = CFG.TEXT_DIM,
			BackgroundColor3 = CFG.FILTER_INACTIVE,
			Size = UDim2.new(0, 100, 0, 26),
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 4,
		}, pagingBar)
		corner(b, 5)
		stroke(b, CFG.PANEL_BORDER, 1, 0)
		return b
	end
	local prevBtn = pageButton("◀  PREV", 1)
	local pageNumLbl = make("TextLabel", {
		Name = "PageNum",
		Text = "1",
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = CFG.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 60, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 4,
	}, pagingBar)
	local nextBtn = pageButton("NEXT  ▶", 3)

	local slotTemplate = makeSlotButton(sg, "Slot", UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE), true)
	slotTemplate.Visible = false

	return {
		inventoryGUI = sg,
		sg = sg,
		panel = panel,
		containerHost = containerHost,
		itemDetails = itemDetails,
		dialogHost = dialogHost,
		closeBtn = closeBtn,
		capacityBadge = capacityBadge,
		filterBtns = filterBtns,
		itemCountLbl = itemCountLbl,
		pageInfoLbl = pageInfoLbl,
		gridFrame = gridFrame,
		grid = grid,
		equipSlotBtns = equipSlotBtns,
		toolbeltSlots = toolbeltSlots,
		prevBtn = prevBtn,
		nextBtn = nextBtn,
		pageNumLbl = pageNumLbl,
		slotTemplate = slotTemplate,
		buttons = {},
	}
end

local function clearSlot(btn)
	btn:SetAttribute("ItemId", nil)
	local itemPic = btn:FindFirstChild("ItemPic")
	local rarityPic = btn:FindFirstChild("RarityPic")
	local itemAmount = btn:FindFirstChild("ItemAmount")
	local itemName = btn:FindFirstChild("ItemName")
	local nameStrip = btn:FindFirstChild("NameStrip")
	if itemPic then itemPic.Image = ""; itemPic.ImageTransparency = 1; itemPic.Visible = true end
	if rarityPic then rarityPic.Image = ""; rarityPic.ImageTransparency = 1; rarityPic.Visible = false end
	if itemAmount then itemAmount.Text = ""; itemAmount.Visible = false end
	if itemName then itemName.Text = "" end
	if nameStrip then nameStrip.Text = ""; nameStrip.Visible = false end
end

function InventoryBrowser.new(playerGui, InventoryFunctions, wireSlotsFn, options)
	local self = setmetatable({}, InventoryBrowser)
	options = options or {}
	self.InventoryFunctions = InventoryFunctions
	self._wireSlots = wireSlotsFn
	self._onCloseRequested = options.onCloseRequested
	self._isOpen = false
	self._ui = buildUI(playerGui)
	self._inventory = nil
	self._allItems = {}
	self._filtered = {}
	self._activeFilter = "All"
	self._page = 1
	self._slotPool = {}
	self._wiredSlots = {}
	self:_wireEvents()

	local function wireOne(btn)
		if self._wireSlots and not self._wiredSlots[btn] then
			local oldParent = btn.Parent
			local holder = Instance.new("Frame")
			holder.Visible = false
			btn.Parent = holder
			holder.Parent = self._ui.sg
			self._wireSlots(holder)
			btn.Parent = oldParent
			holder:Destroy()
			self._wiredSlots[btn] = true
		end
	end

	for _, btn in pairs(self._ui.equipSlotBtns) do wireOne(btn) end
	for _, btn in pairs(self._ui.toolbeltSlots) do wireOne(btn) end

	return self
end

function InventoryBrowser:GetRefs()
	return self._ui
end

function InventoryBrowser:GetContainerHost()
	return self._ui.containerHost
end

function InventoryBrowser:GetPanel()
	return self._ui.panel
end

function InventoryBrowser:_BuildItemList()
	self._allItems = {}
	local inv = self._inventory
	if not inv or not inv.Items then return end

	for itemId, playerItem in pairs(inv.Items) do
		if type(playerItem) == "table" and playerItem.Name then
			local def = self.InventoryFunctions.GetItemDef(playerItem.Name)
			if def and def.Type ~= "TempHold" then
				table.insert(self._allItems, {
					itemId = itemId,
					playerItem = playerItem,
					def = def,
					category = CFG.TYPE_CATEGORIES[def.Type] or "Misc",
				})
			end
		end
	end

	table.sort(self._allItems, function(a, b)
		local ra = tonumber(a.def.Rarity) or 0
		local rb = tonumber(b.def.Rarity) or 0
		if ra ~= rb then return ra > rb end
		return tostring(a.def.DisplayName or a.def.Name or a.itemId) < tostring(b.def.DisplayName or b.def.Name or b.itemId)
	end)
end

function InventoryBrowser:_ApplyFilter()
	self._filtered = {}
	for _, e in ipairs(self._allItems) do
		if self._activeFilter == "All" or e.category == self._activeFilter then
			table.insert(self._filtered, e)
		end
	end
	self._page = 1
end

function InventoryBrowser:_TotalPages()
	return 1
end

function InventoryBrowser:_GetSlot()
	for i, e in ipairs(self._slotPool) do
		if e.slot and not e.slot.Visible then
			local slot = e.slot
			slot.Visible = true
			table.remove(self._slotPool, i)
			return slot
		end
	end
	local s = self._ui.slotTemplate:Clone()
	s.Visible = true
	s.Parent = self._ui.grid
	return s
end

function InventoryBrowser:_RecycleAllSlots()
	for _, child in ipairs(self._ui.grid:GetChildren()) do
		if child:IsA("ImageButton") then
			child.Visible = false
			clearSlot(child)
			local found = false
			for _, e in ipairs(self._slotPool) do
				if e.slot == child then found = true; break end
			end
			if not found then table.insert(self._slotPool, { slot = child }) end
		end
	end
end

function InventoryBrowser:_FillSlot(btn, itemId, playerItem, def, area, slotNum, showName)
	clearSlot(btn)
	btn.Visible = true
	btn.Active = true
	btn.Selectable = true
	btn.BackgroundColor3 = (area == "Toolbelt") and CFG.EQUIP_BG or CFG.PANEL
	setDD(btn, area, slotNum, itemId, true)

	local itemPic = btn:FindFirstChild("ItemPic")
	local imageMap = self.InventoryFunctions.GetImageMap and self.InventoryFunctions.GetImageMap()
	local atlas = imageMap and def and imageMap[def.Type]
	if itemPic and atlas then
		itemPic.Image = atlas
		itemPic.ImageRectOffset = Vector2.new(def.ImageOffsetX or 0, def.ImageOffsetY or 0)
		itemPic.ImageRectSize = Vector2.new(64, 64)
		itemPic.ImageTransparency = 0
		itemPic.Visible = true
	end

	local rarityPic = btn:FindFirstChild("RarityPic")
	if rarityPic and def then
		local rarity = tonumber(def.Rarity) or 0
		rarityPic.Image = CFG.RARITY_ATLAS
		rarityPic.ImageRectOffset = Vector2.new(rarity * CFG.RARITY_RECT_SZ, CFG.RARITY_RECT_Y)
		rarityPic.ImageRectSize = Vector2.new(CFG.RARITY_RECT_SZ, CFG.RARITY_RECT_SZ)
		rarityPic.ImageTransparency = 0
		rarityPic.Visible = true
	end

	local itemName = btn:FindFirstChild("ItemName")
	if itemName then itemName.Text = itemId or "" end

	local amount = playerItem and playerItem.Amount
	local itemAmount = btn:FindFirstChild("ItemAmount")
	if itemAmount then
		itemAmount.Text = (amount and amount > 1) and ("x" .. tostring(amount)) or ""
		itemAmount.Visible = itemAmount.Text ~= ""
	end

	local nameStrip = btn:FindFirstChild("NameStrip")
	if nameStrip then
		nameStrip.Text = showName and (def.DisplayName or def.Name or itemId or "") or ""
		nameStrip.Visible = showName and nameStrip.Text ~= ""
	end
end

function InventoryBrowser:_RenderEquipSlots()
	local inv = self._inventory
	if not inv then return end

	for _, es in ipairs(CFG.EQUIP_SLOTS) do
		local btn = self._ui.equipSlotBtns[es.key]
		local equipped = inv[es.invKey]
		clearSlot(btn)
		btn:SetAttribute("DD", true)
		btn:SetAttribute("DDArea", es.key)
		btn:SetAttribute("DDSlot", 1)
		btn:SetAttribute("DDDragSource", equipped ~= nil)
		btn:SetAttribute("ItemId", equipped and equipped.Name or nil)
		btn.BackgroundColor3 = CFG.EQUIP_BG
		if equipped and equipped.Name then
			local def = self.InventoryFunctions.GetItemDef(equipped.Name)
			if def then
				self:_FillSlot(btn, equipped.Name, equipped, def, es.key, 1, false)
				btn:SetAttribute("DDArea", es.key)
			end
		end
	end
end

function InventoryBrowser:_RenderToolbelt()
	local inv = self._inventory
	local toolItemsBySlot = {}
	if inv and inv.Tools then
		for itemId, toolItem in pairs(inv.Tools) do
			if type(toolItem) == "table" then
				local slot = tonumber(toolItem.Slot) or 0
				if slot > 0 then
					toolItemsBySlot[slot] = { itemId = itemId, item = toolItem }
				end
			end
		end
	end

	for i = CFG.TOOLBELT_START_SLOT, CFG.TOOLBELT_END_SLOT do
		local btn = self._ui.toolbeltSlots[i]
		if btn then
			clearSlot(btn)
			btn:SetAttribute("DD", true)
			btn:SetAttribute("DDArea", "Toolbelt")
			btn:SetAttribute("DDSlot", i)
			btn:SetAttribute("DDDragSource", false)
			btn.BackgroundColor3 = CFG.EQUIP_BG
			local entry = toolItemsBySlot[i]
			if entry and entry.item and entry.item.Name then
				local def = self.InventoryFunctions.GetItemDef(entry.item.Name)
				if def then
					self:_FillSlot(btn, entry.itemId, entry.item, def, "Toolbelt", i, false)
					btn:SetAttribute("DDDragSource", true)
				end
			end
		end
	end
end

function InventoryBrowser:_GetBackpackCapacity()
	local inv = self._inventory
	local baseCapacity = CFG.BASE_BACKPACK_CAPACITY

	if inv then
		baseCapacity = tonumber(inv.BackpackCapacity)
			or tonumber(inv.InventoryCapacity)
			or tonumber(inv.BaseBackpackCapacity)
			or tonumber(inv.BaseCapacity)
			or baseCapacity
	end

	local extraCapacity = 0
	local backItem = inv and inv.Back
	local backItemName = nil

	if type(backItem) == "table" then
		backItemName = backItem.Name
	elseif type(backItem) == "string" then
		backItemName = backItem
	end

	if backItemName then
		local backDef = self.InventoryFunctions.GetItemDef(backItemName)
		if backDef and backDef.Capacity then
			local subTypeText = tostring(backDef.SubType or "")
			local isBackClothing = (subTypeText == "Back") or (subTypeText:match("%.Back$") ~= nil) or (backDef.Type == "Clothing" and subTypeText == "Back")
			if isBackClothing then
				extraCapacity = tonumber(backDef.Capacity) or 0
			end
		end
	end

	return math.max(0, baseCapacity + extraCapacity), baseCapacity, extraCapacity
end

function InventoryBrowser:_GetBackpackUsedSlots()
	local inv = self._inventory
	if not inv or not inv.Items then
		return 0
	end

	local used = 0
	for _, playerItem in pairs(inv.Items) do
		if type(playerItem) == "table" and playerItem.Name then
			local def = self.InventoryFunctions.GetItemDef(playerItem.Name)
			if not def or def.Type ~= "TempHold" then
				used += 1
			end
		end
	end

	return used
end

function InventoryBrowser:_UpdateCapacityBadge()
	local badge = self._ui.capacityBadge
	if not badge then
		return
	end

	local used = self:_GetBackpackUsedSlots()
	local capacity, _, extraCapacity = self:_GetBackpackCapacity()
	badge.Text = ("INVENTORY %d / %d"):format(used, capacity)

	badge.BackgroundTransparency = 1
	badge.TextColor3 = Color3.fromRGB(245, 250, 255)

	if extraCapacity > 0 then
		badge:SetAttribute("TooltipText", ("Equipped Back clothing adds +%d inventory slots"):format(extraCapacity))
	else
		badge:SetAttribute("TooltipText", nil)
	end
end

function InventoryBrowser:_Render()
	local ui = self._ui
	self:_RecycleAllSlots()
	self:_UpdateCapacityBadge()

	self._page = 1
	ui.itemCountLbl.Text = ("%d item%s"):format(#self._filtered, #self._filtered == 1 and "" or "s")
	if ui.pageInfoLbl then
		ui.pageInfoLbl.Text = ""
		ui.pageInfoLbl.Visible = false
	end
	if ui.pageNumLbl then
		ui.pageNumLbl.Text = ""
		ui.pageNumLbl.Visible = false
	end
	if ui.prevBtn then ui.prevBtn.Visible = false end
	if ui.nextBtn then ui.nextBtn.Visible = false end

	for index, entry in ipairs(self._filtered) do
		local order = index - 1
		local slot = self:_GetSlot()
		slot.LayoutOrder = order
		self:_FillSlot(slot, entry.itemId, entry.playerItem, entry.def, "Backpack", entry.playerItem.Slot or 0, true)
		slot:SetAttribute("BrowserInventoryDropTarget", true)

		if self._wireSlots and not self._wiredSlots[slot] then
			local holder = Instance.new("Frame")
			holder.Visible = false
			local oldParent = slot.Parent
			slot.Parent = holder
			holder.Parent = ui.sg
			self._wireSlots(holder)
			slot.Parent = oldParent
			holder:Destroy()
			self._wiredSlots[slot] = true
		end
	end

	self:_RenderEquipSlots()
	self:_RenderToolbelt()
end

function InventoryBrowser:_wireEvents()
	local ui = self._ui
	for key, fb in pairs(ui.filterBtns) do
		fb.MouseButton1Click:Connect(function()
			self:SetFilter(key)
		end)
		fb.MouseEnter:Connect(function()
			if key ~= self._activeFilter then tw(fb, { BackgroundColor3 = Color3.fromRGB(32, 40, 52) }) end
		end)
		fb.MouseLeave:Connect(function()
			if key ~= self._activeFilter then tw(fb, { BackgroundColor3 = CFG.FILTER_INACTIVE }) end
		end)
	end

	ui.closeBtn.Activated:Connect(function()
		if self._onCloseRequested then
			self._onCloseRequested()
		else
			self:Close()
		end
	end)
end

function InventoryBrowser:SetFilter(key)
	for k, fb in pairs(self._ui.filterBtns) do
		if k == key then
			tw(fb, { BackgroundColor3 = CFG.FILTER_ACTIVE })
			fb.TextColor3 = CFG.BG
		else
			tw(fb, { BackgroundColor3 = CFG.FILTER_INACTIVE })
			fb.TextColor3 = CFG.TEXT_DIM
		end
	end
	self._activeFilter = key
	self._page = 1
	self:_ApplyFilter()
	self:_Render()
end

function InventoryBrowser:SetInventory(inv)
	self._inventory = inv
	self:_BuildItemList()
	self:_ApplyFilter()
	self:_Render()
end

function InventoryBrowser:Refresh()
	self:_BuildItemList()
	self:_ApplyFilter()
	self:_Render()
end

function InventoryBrowser:Open(inv)
	self._isOpen = true
	if inv then self._inventory = inv end
	self:_BuildItemList()
	self:_ApplyFilter()
	local ui = self._ui
	ui.panel.Position = UDim2.new(0, -(ui.panel.AbsoluteSize.X + 10), 0, 0)
	ui.sg.Enabled = true
	self:_Render()
	TweenService:Create(ui.panel, MED, { Position = UDim2.new(0, 0, 0, 0) }):Play()
end

function InventoryBrowser:Close()
	self._isOpen = false
	local ui = self._ui
	TweenService:Create(ui.panel, MED, { Position = UDim2.new(0, -(ui.panel.AbsoluteSize.X + 10), 0, 0) }):Play()
	task.delay(0.25, function()
		ui.sg.Enabled = false
	end)
end

function InventoryBrowser:IsOpen()
	return self._isOpen == true
end

function InventoryBrowser:Destroy()
	self._ui.sg:Destroy()
end

return InventoryBrowser
