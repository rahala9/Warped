-- ContainersController.lua
-- No-VacpacGui version. Builds container windows in code and parents them into
-- ui.containerHost from InventoryBrowser.

local ContainerController = {}
ContainerController.__index = ContainerController

local CFG = {
	SLOT_SIZE = 56,
	SLOT_GAP = 6,
	COLUMNS = 5,
	ACCENT = Color3.fromRGB(255, 200, 40),
	BG = Color3.fromRGB(12, 16, 22),
	PANEL = Color3.fromRGB(18, 22, 28),
	BORDER = Color3.fromRGB(38, 48, 58),
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
		Color = color or CFG.BORDER,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	}, parent)
end


local function formatAllowedToContain(value)
	if value == nil then
		return "Any item type"
	end

	if typeof(value) ~= "table" then
		return tostring(value)
	end

	local parts = {}
	for key, subValue in pairs(value) do
		if typeof(key) == "number" then
			table.insert(parts, tostring(subValue))
		elseif subValue == true then
			table.insert(parts, tostring(key))
		elseif subValue ~= false and subValue ~= nil then
			table.insert(parts, tostring(key) .. ": " .. tostring(subValue))
		end
	end

	table.sort(parts)
	if #parts == 0 then
		return "Any item type"
	end

	return table.concat(parts, ", ")
end

local function makeSlot(parent, index)
	local slot = make("ImageButton", {
		Name = "Slot" .. tostring(index),
		Size = UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE),
		BackgroundColor3 = CFG.PANEL,
		AutoButtonColor = false,
		Active = true,
		Selectable = true,
		LayoutOrder = index,
		ZIndex = 74,
	}, parent)
	corner(slot, 4)
	stroke(slot, CFG.BORDER, 1, 0)
	slot:SetAttribute("DD", true)
	slot:SetAttribute("DDArea", "Container")
	slot:SetAttribute("DDSlot", index)
	make("ImageLabel", {
		Name = "ItemPic",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 75,
	}, slot)
	make("TextLabel", {
		Name = "ItemName",
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 1,
		TextTransparency = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 1, 0, 1),
		ZIndex = 1,
	}, slot)
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
		ZIndex = 77,
	}, slot)
	make("ImageLabel", {
		Name = "RarityPic",
		Size = UDim2.new(1, 0, 0, 3),
		Position = UDim2.new(0, 0, 1, -3),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 78,
	}, slot)
	return slot
end

function ContainerController.new(ui, options)
	local self = setmetatable({}, ContainerController)
	self.ui = ui
	self.inventoryGUI = ui.inventoryGUI
	self.containerParent = options.containerParent or ui.containerHost or ui.inventoryGUI
	self.InventoryFunctions = options.InventoryFunctions
	self.getInventory = options.getInventory
	self.onContainerCreated = options.onContainerCreated or function() end
	self.positionContainer = options.positionContainer
	self.openContainers = {}
	return self
end

function ContainerController:_BuildContainerGui(containerId, container)
	local itemDef = self.InventoryFunctions.GetItemDef(container.Name)
	local maxSlots = itemDef and (itemDef.ContainerSlots or itemDef.Capacity) or 12
	maxSlots = math.max(1, tonumber(maxSlots) or 12)
	local rows = math.ceil(maxSlots / CFG.COLUMNS)
	local w = 24 + (CFG.COLUMNS * CFG.SLOT_SIZE) + ((CFG.COLUMNS - 1) * CFG.SLOT_GAP)
	local metaH = 72
	local h = 54 + metaH + (rows * CFG.SLOT_SIZE) + ((rows - 1) * CFG.SLOT_GAP) + 16

	local frame = make("Frame", {
		Name = containerId .. "Container",
		Size = UDim2.new(0, w, 0, h),
		BackgroundColor3 = CFG.BG,
		BorderSizePixel = 0,
		Visible = true,
		ZIndex = 72,
	}, self.containerParent)
	corner(frame, 10)
	stroke(frame, CFG.BORDER, 1.5, 0)
	frame:SetAttribute("ContainerId", containerId)
	frame:SetAttribute("DDArea", "Container")

	local displayName = (itemDef and (itemDef.DisplayName or itemDef.Name)) or tostring(containerId)
	local description = (itemDef and (itemDef.Desc or itemDef.Description)) or "Container storage."
	local allowedText = itemDef and formatAllowedToContain(itemDef.AllowedToContain) or "Any item type"

	make("TextLabel", {
		Name = "Title",
		Text = tostring(displayName),
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = CFG.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -54, 0, 30),
		Position = UDim2.new(0, 12, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 73,
	}, frame)

	local close = make("TextButton", {
		Name = "CloseButton",
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(235, 245, 255),
		BackgroundColor3 = Color3.fromRGB(40, 55, 75),
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -38, 0, 8),
		AutoButtonColor = true,
		BorderSizePixel = 0,
		ZIndex = 80,
	}, frame)
	corner(close, 8)

	local metaBox = make("Frame", {
		Name = "ContainerInfo",
		BackgroundColor3 = Color3.fromRGB(10, 14, 20),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -24, 0, metaH),
		Position = UDim2.new(0, 12, 0, 40),
		ZIndex = 73,
	}, frame)
	corner(metaBox, 8)
	stroke(metaBox, CFG.BORDER, 1, 0.2)

	make("TextLabel", {
		Name = "Description",
		Text = tostring(description),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(210, 220, 230),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 36),
		Position = UDim2.new(0, 6, 0, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 74,
	}, metaBox)

	make("TextLabel", {
		Name = "AllowedToContain",
		Text = "CAN HOLD: " .. tostring(allowedText),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 200, 40),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.new(0, 6, 1, -24),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 74,
	}, metaBox)

	local itemSlots = make("Frame", {
		Name = "ItemSlots",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, -(52 + metaH)),
		Position = UDim2.new(0, 12, 0, 42 + metaH),
		ZIndex = 73,
	}, frame)
	local slots = make("Frame", {
		Name = "Slots",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 73,
	}, itemSlots)
	make("UIGridLayout", {
		CellSize = UDim2.new(0, CFG.SLOT_SIZE, 0, CFG.SLOT_SIZE),
		CellPadding = UDim2.new(0, CFG.SLOT_GAP, 0, CFG.SLOT_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, slots)

	for i = 1, maxSlots do
		local slot = makeSlot(slots, i)
		slot:SetAttribute("ParentContainerId", containerId)
	end

	return frame
end

function ContainerController:CreateContainer(containerId)
	if not containerId or containerId == "" then return end
	local existing = self.openContainers[containerId]
	if existing and existing.Parent then return existing end

	local inventory = self.getInventory()
	if not inventory then return end
	local container = inventory.Items and inventory.Items[containerId]
	if not container and inventory.Tools then
		container = inventory.Tools[containerId]
	end
	if not container then
		warn("CreateContainer container not found for containerId:" .. tostring(containerId))
		return
	end

	local gui = self:_BuildContainerGui(containerId, container)
	if self.positionContainer then
		self.positionContainer(gui, containerId, self.openContainers)
	else
		local count = 0
		for _ in pairs(self.openContainers) do count += 1 end
		gui.Position = UDim2.new(0, 24 + count * 28, 0, 80 + count * 28)
	end

	gui.CloseButton.Activated:Connect(function()
		self:CloseContainer(containerId, gui)
	end)

	self.openContainers[containerId] = gui
	self.onContainerCreated(gui, containerId)
	return gui
end

function ContainerController:CloseContainer(containerId, containerGui)
	if containerGui and containerGui.Parent then
		containerGui:Destroy()
	end
	self.openContainers[containerId] = nil
end

function ContainerController:PopulateContainer(containerId, renderFunc)
	local containerGui = self.openContainers[containerId]
	if not containerGui or not containerGui.Parent then return end

	local inventory = self.getInventory()
	if not inventory then return end
	local container = (inventory.Items and inventory.Items[containerId]) or (inventory.Tools and inventory.Tools[containerId])
	if not container then
		warn("PopulateContainer: container not found for " .. tostring(containerId))
		return
	end

	local slotsContainer = containerGui:FindFirstChild("ItemSlots") and containerGui.ItemSlots:FindFirstChild("Slots")
	if not slotsContainer then return end

	for _, slot in ipairs(slotsContainer:GetChildren()) do
		if slot:IsA("ImageButton") then
			slot:SetAttribute("ItemId", nil)
			slot:SetAttribute("ParentContainerId", containerId)
			local itemName = slot:FindFirstChild("ItemName")
			local itemAmount = slot:FindFirstChild("ItemAmount")
			local itemPic = slot:FindFirstChild("ItemPic")
			local rarityPic = slot:FindFirstChild("RarityPic")
			if itemName then itemName.Text = "" end
			if itemAmount then itemAmount.Text = ""; itemAmount.Visible = false end
			if itemPic then itemPic.Image = ""; itemPic.ImageTransparency = 1; itemPic.Visible = true end
			if rarityPic then rarityPic.Image = ""; rarityPic.ImageTransparency = 1; rarityPic.Visible = false end
			local ddSlot = tonumber(slot:GetAttribute("DDSlot")) or 0
			slot.Visible = ddSlot > 0
			slot.Active = true
		end
	end

	if container.Contains then
		for _, item in pairs(container.Contains) do
			local slot = slotsContainer:FindFirstChild("Slot" .. tostring(item.Slot))
			if slot and renderFunc then
				renderFunc(item.Name, slot, item, containerId)
			end
		end
	end
end

function ContainerController:GetOpenContainers()
	return self.openContainers
end

return ContainerController
