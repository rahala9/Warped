local TweenService = game:GetService("TweenService")

local ItemDetailsController = {}
ItemDetailsController.__index = ItemDetailsController

local TWEEN_IN_POS = UDim2.new(0.95, 0, 0, 0)
local TWEEN_OUT_POS = UDim2.new(1.25, 0, 0, 0)

local PANEL_WIDTH = 420
local PANEL_HEIGHT = 620

local TYPE_COLORS = {
	Weapon = Color3.fromRGB(255, 120, 95),
	Clothing = Color3.fromRGB(115, 190, 255),
	Consumable = Color3.fromRGB(110, 230, 145),
	Tool = Color3.fromRGB(255, 205, 100),
	OffHand = Color3.fromRGB(180, 145, 255),
	Artifact = Color3.fromRGB(120, 255, 235),
	Material = Color3.fromRGB(190, 190, 190),
	Default = Color3.fromRGB(135, 170, 255),
}

-- Rarity color guide:
-- Trash = gray, Common = white, Uncommon = green, Rare = blue,
-- Epic = purple, Legendary = gold.
--
-- Supports:
-- itemDef.Rarity = 1 / "1" / "Trash"
-- itemDef.Rarity = 2 / "2" / "Common"
-- itemDef.Rarity = 3 / "3" / "Uncommon"
-- itemDef.Rarity = 4 / "4" / "Rare"
-- itemDef.Rarity = 5 / "5" / "Epic"
-- itemDef.Rarity = 6 / "6" / "Legendary"
local RARITY_MAP = {
	[0] = {
		Name = "Trash",
		Color = Color3.fromRGB(120, 115, 130),
		TextColor = Color3.fromRGB(245, 245, 245),
	},
	[1] = {
		Name = "Common",
		Color = Color3.fromRGB(235, 235, 255),
		TextColor = Color3.fromRGB(25, 25, 35),
	},
	[2] = {
		Name = "Uncommon",
		Color = Color3.fromRGB(105, 200, 45),
		TextColor = Color3.fromRGB(10, 35, 10),
	},
	[3] = {
		Name = "Rare",
		Color = Color3.fromRGB(35, 175, 230),
		TextColor = Color3.fromRGB(5, 25, 40),
	},
	[4] = {
		Name = "Epic",
		Color = Color3.fromRGB(185, 55, 235),
		TextColor = Color3.fromRGB(255, 245, 255),
	},
	[5] = {
		Name = "Legendary",
		Color = Color3.fromRGB(235, 180, 30),
		TextColor = Color3.fromRGB(45, 25, 0),
	},

	trash = {
		Name = "Trash",
		Color = Color3.fromRGB(120, 115, 130),
		TextColor = Color3.fromRGB(245, 245, 245),
	},
	common = {
		Name = "Common",
		Color = Color3.fromRGB(235, 235, 255),
		TextColor = Color3.fromRGB(25, 25, 35),
	},
	uncommon = {
		Name = "Uncommon",
		Color = Color3.fromRGB(105, 200, 45),
		TextColor = Color3.fromRGB(10, 35, 10),
	},
	rare = {
		Name = "Rare",
		Color = Color3.fromRGB(35, 175, 230),
		TextColor = Color3.fromRGB(5, 25, 40),
	},
	epic = {
		Name = "Epic",
		Color = Color3.fromRGB(185, 55, 235),
		TextColor = Color3.fromRGB(255, 245, 255),
	},
	legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(235, 180, 30),
		TextColor = Color3.fromRGB(45, 25, 0),
	},
}

local HIDDEN_KEYS = {
	ImageOffsetX = true,
	ImageOffsetY = true,
	Image = true,
	Icon = true,
	Desc = true,
	Description = true,
	DisplayName = true,
	Name = true,
	Value = true,
	Type = true,
	SubType = true,
	Rarity = true,
	ConsumeEffects = true,
	WeaponDamageMin = true,
	WeaponDamageMax = true,
	Armor = true,
}

local ORDERED_EXTRA_KEYS = {
	--"Rarity",
	--"Class",
	--"Slot",
	--"Stackable",
	--"MaxStack",
	--"Weight",
	--"AmmoType",
	--"FireRate",
	--"ReloadTime",
	--"Range",
	--"Accuracy",
	--"Knockback",
	--"Stun",
	--"DamageType",
	--"ShieldDamage",
	--"CritChance",
	--"CritDamage",
	--"Durability",
	--"Cooldown",
	--"UseTime",
	--"CraftingCategory",
}

local function make(parent, className, props)
	local obj = Instance.new(className)

	for key, value in pairs(props or {}) do
		obj[key] = value
	end

	obj.Parent = parent
	return obj
end

local function addCorner(parent, radius)
	make(parent, "UICorner", {
		CornerRadius = UDim.new(0, radius or 10),
	})
end

local function addStroke(parent, color, thickness, transparency)
	make(parent, "UIStroke", {
		Color = color or Color3.fromRGB(90, 130, 180),
		Thickness = thickness or 1,
		Transparency = transparency or 0.35,
	})
end

local function safeText(value)
	if value == nil then
		return ""
	end

	if typeof(value) == "boolean" then
		return value and "Yes" or "No"
	end

	return tostring(value)
end

local function niceKey(key)
	local text = tostring(key)

	text = text:gsub("([a-z])([A-Z])", "%1 %2")
	text = text:gsub("_", " ")
	text = text:gsub("^%l", string.upper)

	return text
end

local function getRarityInfo(rarity)
	if rarity == nil then
		return nil
	end

	if typeof(rarity) == "number" then
		return RARITY_MAP[rarity]
	end

	local rarityText = tostring(rarity)
	local rarityNumber = tonumber(rarityText)

	if rarityNumber then
		return RARITY_MAP[rarityNumber]
	end

	return RARITY_MAP[string.lower(rarityText)]
end

local function formatValue(value, depth)
	depth = depth or 0

	if typeof(value) ~= "table" then
		return safeText(value)
	end

	if depth >= 2 then
		return "{...}"
	end

	local parts = {}

	for key, subValue in pairs(value) do
		table.insert(parts, niceKey(key) .. ": " .. formatValue(subValue, depth + 1))
	end

	table.sort(parts)
	return table.concat(parts, ", ")
end

local function clearChildren(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if not child:IsA("UIListLayout")
			and not child:IsA("UIPadding")
			and not child:IsA("UICorner")
			and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

function ItemDetailsController.new(ui, options)
	local self = setmetatable({}, ItemDetailsController)

	self.ui = ui
	self.InventoryFunctions = options.InventoryFunctions
	self.getInventory = options.getInventory
	self.currentSelectedSlot = nil
	self._hideToken = 0

	self:BuildGui()

	if self.ui.itemDetails and self.gui.CloseButton then
		self.gui.CloseButton.Activated:Connect(function()
			self:Hide()
		end)
	end

	return self
end

function ItemDetailsController:BuildGui()
	local root = self.ui.itemDetails

	if not root then
		warn("ItemDetailsController: ui.itemDetails is missing")
		return
	end

	root.Visible = false
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = TWEEN_OUT_POS
	root.Size = UDim2.new(0, PANEL_WIDTH, 0, PANEL_HEIGHT)
	root.BackgroundTransparency = 1

	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "GeneratedItemDetails" then
			child:Destroy()
		end
	end

	local panel = make(root, "Frame", {
		Name = "GeneratedItemDetails",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(13, 20, 32),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})

	addCorner(panel, 18)
	addStroke(panel, Color3.fromRGB(90, 180, 255), 2, 0.25)

	make(panel, "UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	})

	local header = make(panel, "Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 118),
		BackgroundColor3 = Color3.fromRGB(20, 32, 50),
		BorderSizePixel = 0,
	})

	addCorner(header, 14)
	addStroke(header, Color3.fromRGB(80, 150, 220), 1, 0.45)

	local iconFrame = make(header, "Frame", {
		Name = "IconFrame",
		Size = UDim2.new(0, 86, 0, 86),
		Position = UDim2.new(0, 14, 0, 16),
		BackgroundColor3 = Color3.fromRGB(8, 14, 24),
		BorderSizePixel = 0,
	})

	addCorner(iconFrame, 12)
	addStroke(iconFrame, Color3.fromRGB(120, 210, 255), 1, 0.35)

	local itemPic = make(iconFrame, "ImageLabel", {
		Name = "ItemPic",
		Size = UDim2.new(0, 64, 0, 64),
		Position = UDim2.new(0.5, -32, 0.5, -32),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Stretch,
		Visible = false,
	})

	local textArea = make(header, "Frame", {
		Name = "TextArea",
		Size = UDim2.new(1, -126, 1, -20),
		Position = UDim2.new(0, 112, 0, 10),
		BackgroundTransparency = 1,
	})

	local closeButton = make(header, "TextButton", {
		Name = "CloseButton",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -38, 0, 8),
		BackgroundColor3 = Color3.fromRGB(40, 55, 75),
		Text = "X",
		TextColor3 = Color3.fromRGB(235, 245, 255),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		BorderSizePixel = 0,
	})

	addCorner(closeButton, 8)

	local itemName = make(textArea, "TextLabel", {
		Name = "ItemName",
		Size = UDim2.new(1, -40, 0, 36),
		Position = UDim2.new(0, 0, 0, 4),
		BackgroundTransparency = 1,
		Text = "Item Name",
		TextColor3 = Color3.fromRGB(245, 250, 255),
		TextSize = 22,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	})

	local typeBadge = make(textArea, "TextLabel", {
		Name = "TypeBadge",
		Size = UDim2.new(0, 112, 0, 24),
		Position = UDim2.new(0, 0, 0, 46),
		BackgroundColor3 = Color3.fromRGB(80, 150, 220),
		Text = "TYPE",
		TextColor3 = Color3.fromRGB(5, 10, 18),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
	})

	addCorner(typeBadge, 8)

	local rarityBadge = make(textArea, "TextLabel", {
		Name = "RarityBadge",
		Size = UDim2.new(0, 118, 0, 24),
		Position = UDim2.new(0, 120, 0, 46),
		BackgroundColor3 = Color3.fromRGB(120, 115, 130),
		Text = "RARITY",
		TextColor3 = Color3.fromRGB(245, 245, 245),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		Visible = false,
	})

	addCorner(rarityBadge, 8)

	local subText = make(textArea, "TextLabel", {
		Name = "SubText",
		Size = UDim2.new(1, -12, 0, 24),
		Position = UDim2.new(0, 0, 0, 76),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(170, 195, 225),
		TextSize = 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true,
	})

	local descBox = make(panel, "Frame", {
		Name = "DescriptionBox",
		Size = UDim2.new(1, 0, 0, 96),
		Position = UDim2.new(0, 0, 0, 130),
		BackgroundColor3 = Color3.fromRGB(8, 14, 24),
		BorderSizePixel = 0,
	})

	addCorner(descBox, 12)
	addStroke(descBox, Color3.fromRGB(80, 130, 190), 1, 0.55)

	make(descBox, "UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	})

	local desc = make(descBox, "TextLabel", {
		Name = "Desc",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(215, 230, 245),
		TextSize = 15,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
	})

	local scroll = make(panel, "ScrollingFrame", {
		Name = "StatsScroll",
		Size = UDim2.new(1, 0, 1, -240),
		Position = UDim2.new(0, 0, 0, 238),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = Color3.fromRGB(90, 170, 235),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})

	make(scroll, "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})

	self.gui = {
		Panel = panel,
		Header = header,
		ItemPic = itemPic,
		ItemName = itemName,
		TypeBadge = typeBadge,
		RarityBadge = rarityBadge,
		SubText = subText,
		Desc = desc,
		StatsScroll = scroll,
		CloseButton = closeButton,
	}
end

function ItemDetailsController:AddSection(title)
	local scroll = self.gui.StatsScroll

	local section = make(scroll, "Frame", {
		Name = title .. "Section",
		Size = UDim2.new(1, -6, 0, 34),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(18, 29, 45),
		BorderSizePixel = 0,
	})

	addCorner(section, 10)
	addStroke(section, Color3.fromRGB(75, 125, 185), 1, 0.6)

	make(section, "UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	})

	make(section, "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	})

	make(section, "TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Color3.fromRGB(130, 220, 255),
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 0,
	})

	return section
end

function ItemDetailsController:AddStatRow(parent, label, value, layoutOrder)
	if value == nil or value == "" then
		return
	end

	local row = make(parent, "Frame", {
		Name = tostring(label) .. "Row",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(10, 18, 30),
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
	})

	addCorner(row, 7)

	make(row, "TextLabel", {
		Name = "Key",
		Size = UDim2.new(0.42, -8, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Color3.fromRGB(165, 190, 215),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	make(row, "TextLabel", {
		Name = "Value",
		Size = UDim2.new(0.58, -8, 1, 0),
		Position = UDim2.new(0.42, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = formatValue(value),
		TextColor3 = Color3.fromRGB(235, 245, 255),
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	return row
end

function ItemDetailsController:AddLongRow(parent, label, value, layoutOrder)
	if value == nil or value == "" then
		return
	end

	local row = make(parent, "Frame", {
		Name = tostring(label) .. "LongRow",
		Size = UDim2.new(1, 0, 0, 62),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(10, 18, 30),
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
	})

	addCorner(row, 7)

	make(row, "UIPadding", {
		PaddingTop = UDim.new(0, 7),
		PaddingBottom = UDim.new(0, 7),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	make(row, "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	})

	make(row, "TextLabel", {
		Name = "Key",
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Color3.fromRGB(165, 190, 215),
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		LayoutOrder = 1,
	})

	make(row, "TextLabel", {
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 34),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = formatValue(value),
		TextColor3 = Color3.fromRGB(235, 245, 255),
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 2,
	})

	return row
end

function ItemDetailsController:GetItemFromSlot(itemId, slot, inventory)
	local itemPieces = string.split(itemId, "_")
	local fallbackItemName = itemPieces[1]

	local item = nil
	local fromArea = slot:GetAttribute("DDArea")
	local parentContainerId = slot:GetAttribute("ParentContainerId")

	if fromArea == "Container" or parentContainerId then
		local container = nil
		if parentContainerId then
			container = inventory.Items and inventory.Items[parentContainerId]
			if not container and inventory.Tools then
				container = inventory.Tools[parentContainerId]
			end
		end

		if container and container.Contains then
			for _, containedItem in pairs(container.Contains) do
				if containedItem.Slot == tonumber(string.match(slot.Name, "%d+")) then
					item = containedItem
					break
				end
			end
		end
	elseif fromArea == "Backpack" then
		item = (inventory.Items and inventory.Items[itemId]) or (inventory.Tools and inventory.Tools[itemId])
	elseif fromArea == "Weapon" then
		item = inventory.Weapon
	elseif fromArea == "OffHand" then
		item = inventory.OffHand
	elseif fromArea == "Head" then
		item = inventory.Head
	elseif fromArea == "Back" then
		item = inventory.Back
	elseif fromArea == "Accessory" then
		item = inventory.Accessory
	else
		item = (inventory.Items and inventory.Items[itemId]) or (inventory.Tools and inventory.Tools[itemId])
	end

	return item, fromArea, fallbackItemName
end

function ItemDetailsController:SetItemImage(itemDef)
	local itemPic = self.gui.ItemPic
	itemPic.Visible = false
	itemPic.Image = ""

	local imageMap = self.InventoryFunctions.GetImageMap and self.InventoryFunctions.GetImageMap()
	if not imageMap then
		return
	end

	local atlas = imageMap[itemDef.Type]

	if atlas then
		itemPic.Image = atlas
		itemPic.Visible = true
		itemPic.ImageRectOffset = Vector2.new(itemDef.ImageOffsetX or 0, itemDef.ImageOffsetY or 0)
		itemPic.ImageRectSize = Vector2.new(64, 64)
		itemPic.ScaleType = Enum.ScaleType.Stretch
	elseif itemDef.Image then
		itemPic.Image = itemDef.Image
		itemPic.Visible = true
	end
end

function ItemDetailsController:PopulateStats(itemDef, item)
	clearChildren(self.gui.StatsScroll)

	local general = self:AddSection("General")

	if itemDef.Value == -1 then
		self:AddStatRow(general, "Value", "Priceless", 5)
	elseif itemDef.Value then
		local amount = item.Amount or 1
		local total = itemDef.Value * amount

		if amount > 1 then
			self:AddStatRow(general, "Value", "$" .. total .. "  ($" .. itemDef.Value .. " each)", 5)
		else
			self:AddStatRow(general, "Value", "$" .. itemDef.Value, 5)
		end
	end

	if itemDef.Type == "Weapon" then
		local combat = self:AddSection("Weapon Stats")
		self:AddStatRow(combat, "Weapon Type", itemDef.WeaponType, 1)
		self:AddStatRow(combat, "Damage Type", itemDef.DamageType, 2)
		self:AddStatRow(combat, "Base Damage", tostring(itemDef.BaseDamage), 3)
		self:AddStatRow(combat, "Fire Rate", tostring(itemDef.WeaponSpeed), 4)
		self:AddStatRow(combat, "Firing Velocity", tostring(itemDef.WeaponAmmoSpeed), 5)
		self:AddStatRow(combat, "Max Firing Distance", tostring(itemDef.WeaponMaxDistance), 6)
	end

	if itemDef.Type == "Clothing" then
		local defense = self:AddSection("Defense")
		self:AddStatRow(defense, "Armor", itemDef.Armor or 0, 1)
	end

	if itemDef.Type == "Consumable" then
		local consume = self:AddSection("Consumable")

		if itemDef.ConsumeEffects then
			for key, value in pairs(itemDef.ConsumeEffects) do
				self:AddStatRow(consume, niceKey(key), value, 10)
			end
		else
			self:AddStatRow(consume, "Effect", "None", 1)
		end

		self:AddStatRow(consume, "Cooldown", itemDef.Cooldown, 20)
	end

	local extras = self:AddSection("Other Item Data")
	local added = {}

	for order, key in ipairs(ORDERED_EXTRA_KEYS) do
		if itemDef[key] ~= nil and not HIDDEN_KEYS[key] then
			local value = itemDef[key]

			if typeof(value) == "table" then
				self:AddLongRow(extras, niceKey(key), value, order)
			else
				self:AddStatRow(extras, niceKey(key), value, order)
			end

			added[key] = true
		end
	end
end

function ItemDetailsController:ShowItemDetails(itemId: string, slot: Instance, inventory: any)
	if not self.gui then
		self:BuildGui()
	end

	local item, fromArea, fallbackItemName = self:GetItemFromSlot(itemId, slot, inventory)

	if not item then
		-- Some equipped/browser slots only carry the item name. Build a light fallback
		-- item so the details panel can still display the itemDef.
		item = {
			Name = fallbackItemName,
			Amount = 1,
		}
	end

	local itemDef = self.InventoryFunctions.GetItemDef(item.Name or fallbackItemName)

	if not itemDef then
		warn("ItemDetailsController: No itemDef for", item.Name or fallbackItemName)
		return
	end

	if self.currentSelectedSlot and self.currentSelectedSlot:FindFirstChild("SelectedBox") then
		self.currentSelectedSlot.SelectedBox.Enabled = false
	end

	self.currentSelectedSlot = slot

	if slot:FindFirstChild("SelectedBox") then
		slot.SelectedBox.Enabled = true
	end

	if itemDef.SubType == "Container" then
		self.ui.itemDetails.Visible = false
		return
	end

	local displayName = itemDef.DisplayName or itemDef.Name or item.Name or fallbackItemName or "Unknown Item"
	local itemType = itemDef.Type or "Unknown"
	local subType = itemDef.SubType

	self.gui.ItemName.Text = displayName
	self.gui.Desc.Text = itemDef.Desc or itemDef.Description or "No description available."

	local typeColor = TYPE_COLORS[itemType] or TYPE_COLORS.Default
	self.gui.TypeBadge.BackgroundColor3 = typeColor
	self.gui.TypeBadge.Text = string.upper(itemType)

	local rarityInfo = getRarityInfo(itemDef.Rarity)

	if rarityInfo then
		self.gui.RarityBadge.Visible = true
		self.gui.RarityBadge.BackgroundColor3 = rarityInfo.Color
		self.gui.RarityBadge.TextColor3 = rarityInfo.TextColor
		self.gui.RarityBadge.Text = string.upper(rarityInfo.Name)
	else
		self.gui.RarityBadge.Visible = false
	end

	if subType then
		self.gui.SubText.Text = subType
	else
		self.gui.SubText.Text = "Standard issue questionable inventory object."
	end

	self:SetItemImage(itemDef)
	self:PopulateStats(itemDef, item)

	self.ui.itemDetails.Visible = true

	TweenService:Create(
		self.ui.itemDetails,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = TWEEN_IN_POS }
	):Play()

	self:UpdateActionButtons(itemDef, item, inventory, fromArea)
end

function ItemDetailsController:UpdateActionButtons(itemDef, item, inventory, fromArea)
	local equipBtn = self.ui.buttons and self.ui.buttons.equip
	local unequipBtn = self.ui.buttons and self.ui.buttons.unequip
	local consumeBtn = self.ui.buttons and self.ui.buttons.consume

	if equipBtn and equipBtn:IsA("GuiObject") then equipBtn.Visible = false end
	if unequipBtn and unequipBtn:IsA("GuiObject") then unequipBtn.Visible = false end
	if consumeBtn and consumeBtn:IsA("GuiObject") then consumeBtn.Visible = false end

	if fromArea == "Container" or fromArea == "Crafting" or fromArea == "Cooking" or fromArea == "Trading" then
		return
	end

	local itemType = itemDef.Type

	if itemType == "Clothing"
		or itemType == "Tool"
		or itemType == "Weapon"
		or itemType == "OffHand"
		or itemType == "Artifact" then

		local isEquipped = false

		if itemType == "Tool" then
			for _, toolName in pairs(inventory.Tools or {}) do
				if toolName == item.Name then
					isEquipped = true
					break
				end
			end
		elseif itemType == "Weapon" and inventory.Weapon and inventory.Weapon.Name == item.Name then
			isEquipped = true
		elseif itemType == "OffHand" and inventory.OffHand and inventory.OffHand.Name == item.Name then
			isEquipped = true
		elseif itemType == "Clothing" then
			if (inventory.Head and inventory.Head.Name == item.Name)
				or (inventory.Back and inventory.Back.Name == item.Name)
				or (inventory.Accessory and inventory.Accessory.Name == item.Name) then
				isEquipped = true
			end
		elseif itemType == "Artifact" then
			if inventory.Artifact and inventory.Artifact.Name == item.Name then
				isEquipped = true
			end
		end

		if isEquipped and unequipBtn then
			unequipBtn.Visible = true
		elseif equipBtn then
			equipBtn.Visible = true
		end

	elseif itemType == "Consumable" and consumeBtn then
		consumeBtn.Visible = true
	end
end

function ItemDetailsController:Hide()
	self._hideToken += 1
	local hideToken = self._hideToken

	if not self.ui.itemDetails then
		return
	end

	TweenService:Create(
		self.ui.itemDetails,
		TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = TWEEN_OUT_POS }
	):Play()

	task.delay(0.18, function()
		if self._hideToken ~= hideToken then
			return
		end

		if self.ui.itemDetails then
			self.ui.itemDetails.Visible = false
		end
	end)

	if self.currentSelectedSlot and self.currentSelectedSlot:FindFirstChild("SelectedBox") then
		self.currentSelectedSlot.SelectedBox.Enabled = false
	end

	self.currentSelectedSlot = nil
end

function ItemDetailsController:ClearSelection()
	self._hideToken += 1

	if self.currentSelectedSlot and self.currentSelectedSlot:FindFirstChild("SelectedBox") then
		self.currentSelectedSlot.SelectedBox.Enabled = false
	end

	self.currentSelectedSlot = nil

	if self.ui.itemDetails then
		self.ui.itemDetails.Visible = false
		self.ui.itemDetails.Position = TWEEN_OUT_POS
	end
end

return ItemDetailsController