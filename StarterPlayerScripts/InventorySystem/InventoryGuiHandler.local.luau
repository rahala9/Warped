-- StarterPlayerScripts/InventoryGuiHandler.client.lua
-- No-VacpacGui transition version.
-- Requires ONLY these InventoryUI modules: InventoryBrowser, DragDropController,
-- ContainersController, ItemDetailsController.
-- Server remotes are unchanged.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local InventoryFunctions = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("InventoryFunctions"))
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local sendinv = Remotes:WaitForChild("SendInv")
local GetInventory = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
local MoveItemEvent = Remotes:WaitForChild("MoveItem")
local EquipItemEvent = Remotes:WaitForChild("EquipItem")
local AddToolEvent = Remotes:WaitForChild("AddTool")
local RemoveItemEvent = Remotes:WaitForChild("RemoveItem")
local ClothingEquippedEvent = Remotes:WaitForChild("ClothingEquipped")

-- UIManager fires these when the ShowVacpacAction opens/closes the inventory.
local GuiShownClientEvent = Remotes:WaitForChild("GuiShownClient")
local GuiHiddenClientEvent = Remotes:WaitForChild("GuiHiddenClient")

local DragDropController = require(script.Parent.DragDropController)
local ContainerController = require(script.Parent.ContainersController)
local ItemDetailsController = require(script.Parent.ItemDetailsController)
local InventoryBrowser = require(script.Parent.InventoryBrowser)

local currentInventory = nil
local populateSlot
local browser = nil
local ui = nil
local containers = nil
local itemDetails = nil
local dragDrop = nil
local browserOpen = false
local openInventory = nil
local closeInventory = nil
local toggleInventory = nil

local dragDropPayload = nil
local activeDragBegin = nil
local activeDragStartPos = nil
local controllerHandledDrop = false
local suppressOutsideDropPrompt = false

local RARITY_ATLAS = "rbxassetid://13802435951"
local RARITY_RECT_Y = 832
local RARITY_RECT_SZ = 64

local function getInventory()
	local ok, inv = pcall(function()
		return GetInventory:InvokeServer()
	end)
	if ok then
		currentInventory = inv
		return inv
	end
	warn("[InventoryGuiHandler] GetInventory failed:", inv)
	return currentInventory
end

local function getItemNameFromId(itemId)
	if not itemId then return nil end
	return (string.split(tostring(itemId), "_")[1]) or itemId
end

local function findFirstFreeBackpackSlot(inv)
	local used = {}
	if inv and inv.Items then
		for _, item in pairs(inv.Items) do
			if type(item) == "table" and item.Slot then
				used[tonumber(item.Slot)] = true
			end
		end
	end
	for i = 1, 999 do
		if not used[i] then
			return i
		end
	end
	return nil
end

local function refreshInventoryViews()
	local inv = getInventory()
	if browser then
		browser:SetInventory(inv)
	end
	if containers then
		for containerId in pairs(containers:GetOpenContainers()) do
			containers:PopulateContainer(containerId, function(id, slot, item, parentId)
				-- Container item IDs in your old renderer were usually item.Name.
				-- Keep that behavior unless your server sends unique contained IDs later.
				local def = InventoryFunctions.GetItemDef(item.Name)
				if def then
					populateSlot(id, slot, item, parentId)
				end
			end)
		end
	end
end

local function restoreSourceSlotVisuals(slot)
	if not slot or not slot.Parent then return end
	local pic = slot:FindFirstChild("ItemPic")
	local rarity = slot:FindFirstChild("RarityPic")
	local amount = slot:FindFirstChild("ItemAmount")
	if pic and pic:IsA("GuiObject") then pic.Visible = true end
	if rarity and rarity:IsA("GuiObject") then rarity.Visible = true end
	if amount and amount:IsA("TextLabel") and amount.Text ~= "" then amount.Visible = true end
	-- Do not force ItemName visible. Toolbelt names should stay hidden.
end

function populateSlot(itemId, slot, playerItem, parentContainerId)
	if not slot or not slot:IsA("ImageButton") or not playerItem then return end
	local def = InventoryFunctions.GetItemDef(playerItem.Name)
	if not def then return end

	slot:SetAttribute("ItemId", itemId)
	slot:SetAttribute("ParentContainerId", parentContainerId)
	slot:SetAttribute("DD", true)
	if parentContainerId then
		slot:SetAttribute("DDArea", "Container")
	end

	local itemName = slot:FindFirstChild("ItemName")
	local itemAmount = slot:FindFirstChild("ItemAmount")
	local itemPic = slot:FindFirstChild("ItemPic")
	local rarityPic = slot:FindFirstChild("RarityPic")

	if itemName then itemName.Text = tostring(itemId) end
	if itemAmount then
		local amount = playerItem.Amount or 1
		itemAmount.Text = amount > 1 and ("x" .. tostring(amount)) or ""
		itemAmount.Visible = itemAmount.Text ~= ""
		itemAmount.Position = UDim2.new(0, 4, 0, 3)
		itemAmount.TextXAlignment = Enum.TextXAlignment.Left
	end

	local imageMap = InventoryFunctions.GetImageMap and InventoryFunctions.GetImageMap()
	local atlas = imageMap and imageMap[def.Type]
	if itemPic and atlas then
		itemPic.Image = atlas
		itemPic.ImageRectOffset = Vector2.new(def.ImageOffsetX or 0, def.ImageOffsetY or 0)
		itemPic.ImageRectSize = Vector2.new(64, 64)
		itemPic.ImageTransparency = 0
		itemPic.Visible = true
	end
	if rarityPic then
		local rarity = tonumber(def.Rarity) or 0
		rarityPic.Image = RARITY_ATLAS
		rarityPic.ImageRectOffset = Vector2.new(rarity * RARITY_RECT_SZ, RARITY_RECT_Y)
		rarityPic.ImageRectSize = Vector2.new(RARITY_RECT_SZ, RARITY_RECT_SZ)
		rarityPic.ImageTransparency = 0
		rarityPic.Visible = true
	end
end

local function showRemoveConfirm(message, onYes)
	local host = ui and ui.dialogHost
	if not host then
		onYes()
		return
	end

	host:ClearAllChildren()
	host.Visible = true

	local shade = Instance.new("Frame")
	shade.Name = "ConfirmShade"
	shade.Size = UDim2.new(1, 0, 1, 0)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.4
	shade.ZIndex = 100
	shade.Parent = host

	local box = Instance.new("Frame")
	box.Name = "ConfirmBox"
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.Size = UDim2.new(0, 360, 0, 150)
	box.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	box.BorderSizePixel = 0
	box.ZIndex = 101
	box.Parent = shade
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 200, 40)
	st.Thickness = 1.5
	st.Parent = box

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Text = message
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(235, 240, 245)
	label.TextWrapped = true
	label.Size = UDim2.new(1, -28, 0, 72)
	label.Position = UDim2.new(0, 14, 0, 14)
	label.ZIndex = 102
	label.Parent = box

	local yes = Instance.new("TextButton")
	yes.Text = "REMOVE"
	yes.Font = Enum.Font.GothamBold
	yes.TextSize = 13
	yes.TextColor3 = Color3.fromRGB(30, 16, 16)
	yes.BackgroundColor3 = Color3.fromRGB(255, 120, 90)
	yes.Size = UDim2.new(0, 120, 0, 34)
	yes.Position = UDim2.new(0.5, -128, 1, -48)
	yes.ZIndex = 102
	yes.Parent = box
	Instance.new("UICorner", yes).CornerRadius = UDim.new(0, 7)

	local no = Instance.new("TextButton")
	no.Text = "CANCEL"
	no.Font = Enum.Font.GothamBold
	no.TextSize = 13
	no.TextColor3 = Color3.fromRGB(235, 240, 245)
	no.BackgroundColor3 = Color3.fromRGB(38, 48, 58)
	no.Size = UDim2.new(0, 120, 0, 34)
	no.Position = UDim2.new(0.5, 8, 1, -48)
	no.ZIndex = 102
	no.Parent = box
	Instance.new("UICorner", no).CornerRadius = UDim.new(0, 7)

	local function close()
		host:ClearAllChildren()
	end
	yes.Activated:Connect(function()
		close()
		onYes()
	end)
	no.Activated:Connect(close)
end

local function isDropCandidate(obj)
	if not obj then return false end
	if obj:IsDescendantOf(playerGui:FindFirstChild("DragGui") or Instance.new("Folder")) then return false end
	if obj:GetAttribute("DD") == true then return true end
	if obj:GetAttribute("BrowserInventoryDropTarget") == true then return true end
	return false
end

local function findDropTargetAtPosition(pos)
	local objects = playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
	for _, obj in ipairs(objects) do
		local current = obj
		while current and current ~= playerGui do
			if current:IsA("GuiObject") and isDropCandidate(current) then
				return current
			end
			current = current.Parent
		end
	end
	return nil
end

local function handleFinalDrop(targetFrame, amount)
	local dragged = dragDropPayload
	if not dragged or not targetFrame then return end

	local itemId = dragged.itemId
	local fromArea = dragged.fromArea
	local fromSlot = dragged.fromSlot
	local sourceContainerId = dragged.sourceContainerId
	local destinationContainerId = targetFrame:GetAttribute("ParentContainerId")
	local toArea = targetFrame:GetAttribute("DDArea")
	local toSlot = targetFrame:GetAttribute("DDSlot")

	if not itemId or itemId == "" then return end

	-- Dropping anywhere in the item browser/grid means normal inventory.
	if targetFrame:GetAttribute("BrowserInventoryDropTarget") == true then
		toArea = "Backpack"
		if not toSlot or toSlot == 0 then
			toSlot = findFirstFreeBackpackSlot(currentInventory or getInventory())
		end
		destinationContainerId = nil
	end

	if toArea == "Toolbelt" then
		AddToolEvent:FireServer(itemId, toSlot)
	elseif toArea == "Weapon" or toArea == "OffHand" or toArea == "Accessory" or toArea == "Back" or toArea == "Head" then
		EquipItemEvent:FireServer(itemId)
	elseif toArea == "Crafting" then
		MoveItemEvent:FireServer("ToCrafting", itemId, amount, nil, "Crafting", nil, nil, nil, toSlot)
	elseif toArea == "Power" then
		MoveItemEvent:FireServer("ToPower", itemId, amount, nil, "Power", nil, nil, nil, toSlot)
	elseif toArea == "Trading" and ui.tradingGui and ui.tradingGui.Enabled then
		MoveItemEvent:FireServer("ToTrading", itemId, amount, nil, "Trading", nil, nil, nil, toSlot)
	elseif toArea == "Selling" and ui.tradingGui and ui.tradingGui.Enabled then
		MoveItemEvent:FireServer("ToSelling", itemId, amount, nil, "Selling", nil, nil, nil, toSlot)
	elseif toArea ~= nil and fromArea ~= nil then
		-- Server now expects normal inventory as Backpack.
		MoveItemEvent:FireServer("MoveItem", itemId, amount or 1, fromArea, toArea, sourceContainerId, fromSlot, destinationContainerId, toSlot)
	end
end

local function completeDragAtPosition(releasePos)
	if not dragDropPayload then return false end
	local target = findDropTargetAtPosition(releasePos)
	if target then
		handleFinalDrop(target, 1)
		local oldPayload = dragDropPayload
		dragDropPayload = nil
		restoreSourceSlotVisuals(oldPayload and oldPayload.sourceSlot)
		refreshInventoryViews()
		return true
	end
	return false
end

local function makeIconGhostFromSlot(slot)
	local ghost = Instance.new("Frame")
	ghost.Name = "IconGhost"
	ghost.Size = UDim2.new(0, 64, 0, 64)
	ghost.BackgroundTransparency = 1

	local srcPic = slot:FindFirstChild("ItemPic")
	if srcPic and srcPic:IsA("ImageLabel") then
		local pic = srcPic:Clone()
		pic.Name = "ItemPic"
		pic.Visible = true
		pic.Size = UDim2.new(1, 0, 1, 0)
		pic.Position = UDim2.new(0, 0, 0, 0)
		pic.BackgroundTransparency = 1
		pic.Parent = ghost
	end
	return ghost
end

local function wireSlots(slotContainer)
	for _, v in ipairs(slotContainer:GetChildren()) do
		if v:IsA("ImageButton") then
			if v:GetAttribute("_InventoryWired") then continue end
			v:SetAttribute("_InventoryWired", true)
			v.Active = true
			v.Selectable = true

			v.Activated:Connect(function()
				if dragDrop and dragDrop:IsDragging() then return end
				local itemId = v:GetAttribute("ItemId")
				if not itemId or itemId == "" then return end

				-- Toolbelt clicks should not open details.
				if v:GetAttribute("DDArea") == "Toolbelt" then return end

				local itemName = getItemNameFromId(itemId)
				local itemDef = InventoryFunctions.GetItemDef(itemName)
				if not itemDef then return end

				if itemDef.SubType == "Container" then
					local containerGui = containers and containers:CreateContainer(itemId)
					if containerGui and containers then
						containers:PopulateContainer(itemId, populateSlot)
					end
				else
					local inv = currentInventory or getInventory()
					if inv and itemDetails then
						itemDetails:ShowItemDetails(itemId, v, inv)
					end
				end
			end)

			v.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not v:GetAttribute("DD") then return end
				if v:GetAttribute("DDDragSource") == false then return end
				local itemId = v:GetAttribute("ItemId")
				if not itemId or itemId == "" then return end

				activeDragStartPos = Vector2.new(input.Position.X, input.Position.Y)
				activeDragBegin = function()
					if dragDrop and dragDrop:IsDragging() then return end
					dragDropPayload = {
						itemId = itemId,
						fromArea = v:GetAttribute("DDArea"),
						fromSlot = v:GetAttribute("DDSlot"),
						sourceContainerId = v:GetAttribute("ParentContainerId"),
						sourceSlot = v,
					}
					dragDrop:BeginDragFromSlot(v, function()
						return makeIconGhostFromSlot(v)
					end)
					-- Force the old DragDropController to start immediately after our own
					-- movement threshold has passed. Otherwise it may wait for another
					-- MouseMovement event and miss quick releases.
					if dragDrop._StartDragging then
						dragDrop:_StartDragging()
					end
				end
			end)
		end
	end
end

-- Browser must be created after wireSlots exists. The closures above safely use
-- containers/itemDetails/dragDrop after they are assigned below.
browser = InventoryBrowser.new(playerGui, InventoryFunctions, wireSlots, {
	onCloseRequested = function()
		-- Let UIManager own the open/closed state when it is present.
		-- The deferred fallback makes the X close button still work even if UIManager.Init()
		-- was not called yet or the close-request bindable was not connected.
		local closeRequest = playerGui:FindFirstChild("InventoryCloseRequested")
		if closeRequest and closeRequest:IsA("BindableEvent") then
			closeRequest:Fire()
		else
			closeInventory()
			return
		end

		task.defer(function()
			if browserOpen then
				closeInventory()
			end
		end)
	end,
})
ui = browser:GetRefs()

itemDetails = ItemDetailsController.new(ui, {
	InventoryFunctions = InventoryFunctions,
	getInventory = function()
		return currentInventory or getInventory()
	end,
})

local function positionContainerToRight(containerGui, containerId, openContainers)
	local panel = browser:GetPanel()
	local host = browser:GetContainerHost()
	local gap = 12

	-- Default fallback if AbsoluteSize has not updated yet.
	local panelX = 0
	local panelY = 0
	local panelW = 620
	if panel then
		panelX = panel.AbsolutePosition.X
		panelY = panel.AbsolutePosition.Y
		panelW = panel.AbsoluteSize.X
	end

	local hostH = host and host.AbsoluteSize.Y or 720
	local containerW = math.max(containerGui.AbsoluteSize.X, containerGui.Size.X.Offset)
	local containerH = math.max(containerGui.AbsoluteSize.Y, containerGui.Size.Y.Offset)

	local startX = panelX + panelW + gap
	local startY = panelY
	local usableH = math.max(containerH, hostH - startY - gap)
	local rowsPerColumn = math.max(1, math.floor((usableH + gap) / (containerH + gap)))

	local count = 0
	for _, existing in pairs(openContainers or {}) do
		if existing and existing.Parent then
			count += 1
		end
	end

	local col = math.floor(count / rowsPerColumn)
	local row = count % rowsPerColumn

	containerGui.AnchorPoint = Vector2.new(0, 0)
	containerGui.Position = UDim2.new(
		0,
		startX + (col * (containerW + gap)),
		0,
		startY + (row * (containerH + gap))
	)
end

containers = ContainerController.new(ui, {
	InventoryFunctions = InventoryFunctions,
	getInventory = function()
		return currentInventory or getInventory()
	end,
	containerParent = browser:GetContainerHost(),
	positionContainer = positionContainerToRight,
	onContainerCreated = function(containerGui)
		local slotsContainer = containerGui.ItemSlots.Slots
		wireSlots(slotsContainer)
	end,
})

dragDrop = DragDropController.new(ui, {
	onDrop = function(targetFrame, moveAmount)
		controllerHandledDrop = true
		handleFinalDrop(targetFrame, moveAmount)
		local oldPayload = dragDropPayload
		dragDropPayload = nil
		restoreSourceSlotVisuals(oldPayload and oldPayload.sourceSlot)
		refreshInventoryViews()
	end,
	onDroppedOutside = function()
		if suppressOutsideDropPrompt then return end
		if not dragDropPayload then return end

		local itemId = dragDropPayload.itemId
		local fromArea = dragDropPayload.fromArea
		local parentContainerId = dragDropPayload.sourceContainerId
		local itemName = getItemNameFromId(itemId)
		local def = InventoryFunctions.GetItemDef(itemName)

		if def and not def.CanNotRemove then
			showRemoveConfirm(("Do you want to remove %s?"):format(itemId), function()
				RemoveItemEvent:FireServer(itemId, parentContainerId, fromArea, 1)
			end)
		end

		local oldPayload = dragDropPayload
		dragDropPayload = nil
		restoreSourceSlotVisuals(oldPayload and oldPayload.sourceSlot)
		refreshInventoryViews()
	end,
	clearSelection = function()
		if itemDetails then itemDetails:ClearSelection() end
	end,
})

-- Put drag ghost into a top DisplayOrder gui.
do
	local dragFrame = ui.inventoryGUI:FindFirstChild("DragFrame")
	if dragFrame then
		local dragGui = Instance.new("ScreenGui")
		dragGui.Name = "DragGui"
		dragGui.DisplayOrder = 9999
		dragGui.IgnoreGuiInset = true
		dragGui.ResetOnSpawn = false
		dragGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		dragGui.Parent = playerGui
		dragFrame.Parent = dragGui
	end
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
	if not activeDragBegin or not activeDragStartPos then return end
	if dragDrop and dragDrop:IsDragging() then return end

	local currentPos = Vector2.new(input.Position.X, input.Position.Y)
	if (currentPos - activeDragStartPos).Magnitude >= 8 then
		activeDragBegin()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	activeDragBegin = nil
	activeDragStartPos = nil

	local releasePos = Vector2.new(input.Position.X, input.Position.Y)
	local wasDragging = dragDrop and dragDrop:IsDragging()
	local payloadBeforeDrop = dragDropPayload
	local targetBeforeDrop = payloadBeforeDrop and findDropTargetAtPosition(releasePos) or nil

	controllerHandledDrop = false
	suppressOutsideDropPrompt = targetBeforeDrop ~= nil

	if wasDragging then
		dragDrop:EndDragAtPosition(input.Position)
	end

	suppressOutsideDropPrompt = false

	if dragDropPayload then
		completeDragAtPosition(releasePos)
	elseif wasDragging and payloadBeforeDrop and targetBeforeDrop and not controllerHandledDrop then
		dragDropPayload = payloadBeforeDrop
		handleFinalDrop(targetBeforeDrop, 1)
		dragDropPayload = nil
		restoreSourceSlotVisuals(payloadBeforeDrop.sourceSlot)
		refreshInventoryViews()
	end
end)

openInventory = function()
	local inv = getInventory()
	browserOpen = true
	browser:Open(inv)
end

closeInventory = function()
	browserOpen = false
	browser:Close()
end

toggleInventory = function()
	if browserOpen then closeInventory() else openInventory() end
end

local function matchesInventoryGuiName(name)
	-- Keep "VacpacGui" as the UIManager window/action name for compatibility,
	-- even though the generated ScreenGui is now named "InventoryBrowser".
	return name == "VacpacGui" or name == "InventoryBrowser"
end

local function connectBindableOrRemote(signalObject, bindableCallback, remoteCallback)
	if signalObject:IsA("BindableEvent") then
		return signalObject.Event:Connect(bindableCallback)
	elseif signalObject:IsA("RemoteEvent") then
		return signalObject.OnClientEvent:Connect(remoteCallback or bindableCallback)
	else
		warn("[InventoryGuiHandler] Unsupported GUI event object:", signalObject:GetFullName(), signalObject.ClassName)
	end
end

connectBindableOrRemote(GuiShownClientEvent, function(name)
	if matchesInventoryGuiName(name) then
		openInventory()
	end
end)

connectBindableOrRemote(GuiHiddenClientEvent, function(name)
	if matchesInventoryGuiName(name) then
		closeInventory()
	end
end)

sendinv.OnClientEvent:Connect(function()
	refreshInventoryViews()
end)

ClothingEquippedEvent.OnClientEvent:Connect(function()
	-- No VacpacExtraGui now. Just refresh the generated browser/equipment.
	refreshInventoryViews()
end)

-- Initial load/render. Browser remains closed until UIManager shows VacpacGui/InventoryBrowser.
currentInventory = getInventory()
browser:SetInventory(currentInventory)
