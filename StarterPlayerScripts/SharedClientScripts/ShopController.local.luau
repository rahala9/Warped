local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIGURATION
-- ============================================================

local SHOP_ITEMS = {
	["Starbits"] = {
		{ id = 1, name = "PowerCell" },
		{ id = 2, name = "Bandaid" },
	},

	["Bleepers"] = {
		{ id = 1, name = "GreenCircuitBoard" },
		{ id = 2, name = "BlueCircuitBoard" },
		{ id = 3, name = "Wires" },
	},

	["UndergroundGoods"] = {
		{ id = 1, name = "InventoryImplant" },
		{ id = 2, name = "FakeStarhopClearanceBadge" },
	},
}

local PURCHASE_REMOTE_NAME = "ShopPurchase"

-- ============================================================
-- STATE
-- ============================================================

local currentShopName = nil
local quantities = {}
local totalCost = 0

-- ============================================================
-- GUI REFERENCES
-- ============================================================

local shopGui = nil
local mainFrame = nil
local gridFrame = nil
local totalLabel = nil
local purchaseButton = nil
local closeButton = nil
local cellRefs = {}

-- Forward declarations
local openShop
local closeShop
local onPurchase

-- ============================================================
-- UTILITY
-- ============================================================

local function recalcTotal(shopName)
	totalCost = 0

	local shopItems = SHOP_ITEMS[shopName]
	if not shopItems then
		warn("ShopController: No shop items found for:", shopName)
		return
	end

	for _, item in ipairs(shopItems) do
		local itemData = itemsmodule[item.name]
		if itemData then
			totalCost += ((quantities[item.name] or 0) * itemData.Value)
		end
	end

	if totalLabel then
		totalLabel.Text = "TOTAL: " .. totalCost .. " ¢"
	end
end

local function setQuantity(itemName, newQty, shopName)
	newQty = math.max(0, math.min(99, newQty))
	quantities[itemName] = newQty

	if cellRefs[itemName] then
		cellRefs[itemName].qtyLabel.Text = tostring(newQty)
	end

	recalcTotal(shopName)
end

local function resetShopQuantities(shopName)
	quantities = {}

	local shopItems = SHOP_ITEMS[shopName]
	if not shopItems then return end

	for _, item in ipairs(shopItems) do
		quantities[item.name] = 0

		if cellRefs[item.name] then
			cellRefs[item.name].qtyLabel.Text = "0"
		end
	end

	recalcTotal(shopName)
end

-- ============================================================
-- BUILD GUI
-- ============================================================

local function buildGui(shopName)
	local existing = playerGui:FindFirstChild("ShopGui")
	if existing then
		existing:Destroy()
	end

	cellRefs = {}

	shopGui = Instance.new("ScreenGui")
	shopGui.Name = "ShopGui"
	shopGui.ResetOnSpawn = false
	shopGui.Enabled = false
	shopGui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 540)
	mainFrame.Position = UDim2.new(0.5, -350, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = shopGui

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 3)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	topBar.BorderSizePixel = 0
	topBar.Parent = mainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 40)
	titleLabel.Position = UDim2.new(0, 16, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "SCI CO  ·  SUPPLY TERMINAL"
	titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.Code
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = mainFrame

	closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 36, 0, 36)
	closeButton.Position = UDim2.new(1, -44, 0, 6)
	closeButton.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(180, 180, 200)
	closeButton.TextSize = 16
	closeButton.Font = Enum.Font.Code
	closeButton.Parent = mainFrame

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -32, 0, 1)
	divider.Position = UDim2.new(0, 16, 0, 50)
	divider.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	divider.BackgroundTransparency = 0.7
	divider.BorderSizePixel = 0
	divider.Parent = mainFrame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "GridScroll"
	scrollFrame.Size = UDim2.new(1, -32, 0, 368)
	scrollFrame.Position = UDim2.new(0, 16, 0, 58)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ClipsDescendants = true
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = mainFrame

	gridFrame = Instance.new("Frame")
	gridFrame.Name = "Grid"
	gridFrame.Size = UDim2.new(1, 0, 0, 0)
	gridFrame.AutomaticSize = Enum.AutomaticSize.Y
	gridFrame.BackgroundTransparency = 1
	gridFrame.Parent = scrollFrame

	local uiGrid = Instance.new("UIGridLayout")
	uiGrid.CellSize = UDim2.new(0, 152, 0, 152)
	uiGrid.CellPadding = UDim2.new(0, 6, 0, 6)
	uiGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiGrid.SortOrder = Enum.SortOrder.LayoutOrder
	uiGrid.Parent = gridFrame

	local gridPad = Instance.new("UIPadding")
	gridPad.PaddingTop = UDim.new(0, 4)
	gridPad.PaddingLeft = UDim.new(0, 2)
	gridPad.Parent = gridFrame

	local shopItems = SHOP_ITEMS[shopName]
	if not shopItems then
		warn("ShopController: Invalid shop:", shopName)
		return
	end

	for _, item in ipairs(shopItems) do
		local itemData = itemsmodule[item.name]
		if not itemData then
			warn("ShopController: Item missing from Items module:", item.name)
			continue
		end

		quantities[item.name] = quantities[item.name] or 0

		local cell = Instance.new("Frame")
		cell.Name = "Item_" .. item.name
		cell.BackgroundColor3 = Color3.fromRGB(14, 20, 36)
		cell.BorderSizePixel = 0
		cell.LayoutOrder = item.id
		cell.Parent = gridFrame

		local cellCorner = Instance.new("UICorner")
		cellCorner.CornerRadius = UDim.new(0, 4)
		cellCorner.Parent = cell

		local cellStroke = Instance.new("UIStroke")
		cellStroke.Color = Color3.fromRGB(0, 200, 255)
		cellStroke.Transparency = 0.75
		cellStroke.Thickness = 1
		cellStroke.Parent = cell

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 64, 0, 64)
		icon.Position = UDim2.new(0.5, -32, 0.2, 0)
		icon.BackgroundTransparency = 1
		icon.Image = itemsmodule.ImageMap[itemData.Type]
		icon.ImageRectOffset = Vector2.new(itemData.ImageOffsetX, itemData.ImageOffsetY)
		icon.ImageRectSize = Vector2.new(64, 64)
		icon.ScaleType = Enum.ScaleType.Stretch
		icon.Parent = cell

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -8, 0, 28)
		nameLabel.Position = UDim2.new(0, 4, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = itemData.DisplayName or item.name
		nameLabel.TextColor3 = Color3.fromRGB(210, 220, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.Code
		nameLabel.TextScaled = true
		nameLabel.TextWrapped = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.Parent = cell

		local priceLabel = Instance.new("TextLabel")
		priceLabel.Size = UDim2.new(1, -8, 0, 16)
		priceLabel.Position = UDim2.new(0, 4, 0.65, 0)
		priceLabel.BackgroundTransparency = 1
		priceLabel.Text = itemData.Value .. " ¢"
		priceLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
		priceLabel.TextSize = 20
		priceLabel.Font = Enum.Font.Code
		priceLabel.TextXAlignment = Enum.TextXAlignment.Center
		priceLabel.Parent = cell

		local qtyRow = Instance.new("Frame")
		qtyRow.Size = UDim2.new(1, -12, 0, 28)
		qtyRow.Position = UDim2.new(0, 6, 0, 112)
		qtyRow.BackgroundTransparency = 1
		qtyRow.Parent = cell

		local minusBtn = Instance.new("TextButton")
		minusBtn.Size = UDim2.new(0, 26, 1, 0)
		minusBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
		minusBtn.BorderSizePixel = 0
		minusBtn.Text = "−"
		minusBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
		minusBtn.TextSize = 16
		minusBtn.Font = Enum.Font.Code
		minusBtn.Parent = qtyRow

		local minusCorner = Instance.new("UICorner")
		minusCorner.CornerRadius = UDim.new(0, 3)
		minusCorner.Parent = minusBtn

		local qtyLabel = Instance.new("TextLabel")
		qtyLabel.Size = UDim2.new(1, -56, 1, 0)
		qtyLabel.Position = UDim2.new(0, 30, 0, 0)
		qtyLabel.BackgroundTransparency = 1
		qtyLabel.Text = "0"
		qtyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		qtyLabel.TextSize = 14
		qtyLabel.Font = Enum.Font.Code
		qtyLabel.TextXAlignment = Enum.TextXAlignment.Center
		qtyLabel.Parent = qtyRow

		local plusBtn = Instance.new("TextButton")
		plusBtn.Size = UDim2.new(0, 26, 1, 0)
		plusBtn.Position = UDim2.new(1, -26, 0, 0)
		plusBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 60)
		plusBtn.BorderSizePixel = 0
		plusBtn.Text = "+"
		plusBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
		plusBtn.TextSize = 16
		plusBtn.Font = Enum.Font.Code
		plusBtn.Parent = qtyRow

		local plusCorner = Instance.new("UICorner")
		plusCorner.CornerRadius = UDim.new(0, 3)
		plusCorner.Parent = plusBtn

		local itemName = item.name

		minusBtn.MouseButton1Click:Connect(function()
			setQuantity(itemName, (quantities[itemName] or 0) - 1, shopName)
		end)

		plusBtn.MouseButton1Click:Connect(function()
			setQuantity(itemName, (quantities[itemName] or 0) + 1, shopName)
		end)

		cellRefs[itemName] = {
			qtyLabel = qtyLabel,
		}
	end

	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(1, 0, 0, 52)
	bottomBar.Position = UDim2.new(0, 0, 1, -52)
	bottomBar.BackgroundColor3 = Color3.fromRGB(5, 8, 16)
	bottomBar.BorderSizePixel = 0
	bottomBar.ZIndex = 5
	bottomBar.Parent = mainFrame

	local bottomDivider = Instance.new("Frame")
	bottomDivider.Size = UDim2.new(1, 0, 0, 1)
	bottomDivider.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	bottomDivider.BackgroundTransparency = 0.6
	bottomDivider.BorderSizePixel = 0
	bottomDivider.ZIndex = 5
	bottomDivider.Parent = bottomBar

	totalLabel = Instance.new("TextLabel")
	totalLabel.Size = UDim2.new(0.5, -16, 1, 0)
	totalLabel.Position = UDim2.new(0, 16, 0, 0)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "TOTAL: 0 ¢"
	totalLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	totalLabel.TextSize = 16
	totalLabel.Font = Enum.Font.Code
	totalLabel.TextXAlignment = Enum.TextXAlignment.Left
	totalLabel.ZIndex = 5
	totalLabel.Parent = bottomBar

	purchaseButton = Instance.new("TextButton")
	purchaseButton.Size = UDim2.new(0, 180, 0, 36)
	purchaseButton.Position = UDim2.new(1, -196, 0.5, -18)
	purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 180, 230)
	purchaseButton.BorderSizePixel = 0
	purchaseButton.Text = "PURCHASE"
	purchaseButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	purchaseButton.TextSize = 14
	purchaseButton.Font = Enum.Font.Code
	purchaseButton.ZIndex = 5
	purchaseButton.Parent = bottomBar

	local purchaseCorner = Instance.new("UICorner")
	purchaseCorner.CornerRadius = UDim.new(0, 4)
	purchaseCorner.Parent = purchaseButton

	closeButton.MouseButton1Click:Connect(function()
		closeShop()
	end)

	purchaseButton.MouseButton1Click:Connect(function()
		onPurchase(shopName)
	end)
end

-- ============================================================
-- OPEN / CLOSE
-- ============================================================

function openShop(shopName)
	if not shopName or not SHOP_ITEMS[shopName] then
		warn("ShopController: Invalid or missing ShopName attribute:", shopName)
		return
	end

	if shopGui and currentShopName ~= shopName then
		shopGui:Destroy()
		shopGui = nil
		mainFrame = nil
		gridFrame = nil
		totalLabel = nil
		purchaseButton = nil
		closeButton = nil
		cellRefs = {}
		quantities = {}
	end

	currentShopName = shopName

	if not shopGui then
		buildGui(shopName)
	end

	resetShopQuantities(shopName)

	shopGui.Enabled = true

	mainFrame.Position = UDim2.new(0.5, -350, 0.6, -270)
	mainFrame.BackgroundTransparency = 1

	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Position = UDim2.new(0.5, -350, 0, 0),
		BackgroundTransparency = 0,
	})

	tween:Play()
end

function closeShop()
	if not shopGui or not mainFrame then return end

	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(mainFrame, tweenInfo, {
		Position = UDim2.new(0.5, -350, 0.6, -270),
		BackgroundTransparency = 1,
	})

	tween:Play()

	tween.Completed:Once(function()
		if shopGui then
			shopGui.Enabled = false
		end
	end)
end

-- ============================================================
-- PURCHASE
-- ============================================================

function onPurchase(shopName)
	if totalCost == 0 then return end

	local shopItems = SHOP_ITEMS[shopName]
	if not shopItems then return end

	local order = {}

	for _, item in ipairs(shopItems) do
		local qty = quantities[item.name] or 0

		if qty > 0 then
			table.insert(order, {
				id = item.name,
				qty = qty,
			})
		end
	end

	local remote = ReplicatedStorage:FindFirstChild(PURCHASE_REMOTE_NAME)

	if remote then
		remote:FireServer(order)
	else
		warn("ShopController: RemoteEvent '" .. PURCHASE_REMOTE_NAME .. "' not found in ReplicatedStorage")
	end

	closeShop()
end

-- ============================================================
-- PROXIMITY PROMPT
-- ============================================================

local debounce = false

local function onPromptTriggered(promptObject)
	if debounce then return end
	debounce = true

	if promptObject.Name == "Shop" then
		local shopName = promptObject:GetAttribute("ShopName")
		openShop(shopName)
	end

	debounce = false
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

print("ShopController loaded. Waiting for 'Shop' ProximityPrompts in Workspace.")