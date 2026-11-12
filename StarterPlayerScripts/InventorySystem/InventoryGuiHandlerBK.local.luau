-- StarterPlayerScripts/InventoryGuiHandler.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local InventoryFunctions = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("InventoryFunctions"))

-- remotes
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local sendinv = Remotes:WaitForChild("SendInv")
local GetInventory = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
local MoveItemEvent = Remotes:WaitForChild("MoveItem")
local EquipItemEvent = Remotes:WaitForChild("EquipItem")
local AddToolEvent = Remotes:WaitForChild("AddTool")
local RemoveItemEvent = Remotes:WaitForChild("RemoveItem")
local ClothingEquippedEvent = Remotes:WaitForChild("ClothingEquipped")

-- UI root
--local inventoryRoot = script.Parent  -- put this LocalScript under the Inventory root frame
-- If your script is elsewhere, set this to the correct Frame:
local inventoryRoot = playerGui:WaitForChild("SharedGUI"):WaitForChild("VacpacGui"):WaitForChild("Background")

-- requires
local UIRefs = require(script.Parent.UIRefs)
local TabsController = require(script.Parent.TabsController)
local DragDropController = require(script.Parent.DragDropController)
local Dialogs = require(script.Parent.Dialogs)
local InventoryRenderer = require(script.Parent.InventoryRenderer)
local ContainerController = require(script.Parent.ContainersController)
local ItemDetailsController = require(script.Parent.ItemDetailsController)

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local ui = UIRefs.Build(playerGui, inventoryRoot)

-- basic defaults
ui.frames.frame_tools.Visible = true
ui.frames.frame_weapons.Visible = false
ui.frames.frame_consumables.Visible = false
ui.frames.frame_materials.Visible = false
ui.frames.frame_misc.Visible = false
ui.frames.frame_access.Visible = false
ui.frames.frame_info.Visible = false
ui.frames.frame_clothing.Visible = false

ui.buttons.equip.Visible = false
ui.buttons.unequip.Visible = false
ui.buttons.consume.Visible = false

local tabs = TabsController.new(ui)
local dialogs = Dialogs.new(ui)

local renderer = InventoryRenderer.new(ui, {
	InventoryFunctions = InventoryFunctions,
	getInventory = function()
		return GetInventory:InvokeServer()
	end,
	onInventoryLoaded = function(inv)
		-- optional
	end
})

ClothingEquippedEvent.OnClientEvent:Connect(function(itemName, isEquipped)
	local itemDef = itemsmodule[itemName]
	if not itemDef or itemDef.SubType ~= "Back" then return end

	ui.vacpacExtraGui.Visible = isEquipped
	ui.vacpacExtraGui.Interactable = isEquipped

	ui.vacpacExtraGui:SetAttribute("MaxSlots",itemDef.Capacity)

end)

-- your drop routing (this replaces the old handleFinalDrop)
local function handleFinalDrop(targetFrame: GuiObject, amount: number)
	local inv = renderer:GetInventory()
	if not inv then
		renderer:LoadInventory()
		inv = renderer:GetInventory()
	end

	local dragged = dragDropPayload
	if not dragged then
		return
	end

	local itemId = dragged.itemId
	local fromArea = dragged.fromArea
	local fromSlot = dragged.fromSlot
	local sourceContainerId = dragged.sourceContainerId
	local destinationContainerId = targetFrame:GetAttribute("ParentContainerId")

	local toArea = targetFrame:GetAttribute("DDArea")
	local toSlot = targetFrame:GetAttribute("DDSlot")

	-- route actions (keep your existing logic)
	if toArea == "Toolbelt" then
		AddToolEvent:FireServer(itemId, toSlot)
	elseif toArea == "Weapon" or toArea == "OffHand" or toArea == "Accessory" or toArea == "Back" or toArea == "Head" then
		print("TEST DRAGG Sending Server EquipItem request: itemId:",itemId)
		EquipItemEvent:FireServer(itemId)
	elseif toArea == "Crafting" then
		MoveItemEvent:FireServer("ToCrafting", itemId, amount, nil, "Crafting", nil, nil, nil, toSlot)
	elseif toArea == "Power" then
		MoveItemEvent:FireServer("ToPower", itemId, amount, nil, "Power", nil, nil, nil, toSlot)
	elseif toArea == "Trading" and ui.tradingGui.Enabled then
		MoveItemEvent:FireServer("ToTrading", itemId, amount, nil, "Trading", nil, nil, nil, toSlot)
	elseif toArea == "Selling" and ui.tradingGui.Enabled then
		MoveItemEvent:FireServer("ToSelling", itemId, amount, nil, "Selling", nil, nil, nil, toSlot)
	elseif toArea ~= nil and fromArea ~= nil then
		MoveItemEvent:FireServer("MoveItem", itemId, amount, fromArea, toArea, sourceContainerId, fromSlot, destinationContainerId, toSlot)
	else
		-- fallback: refresh
	end

	-- refresh
	--renderer:LoadInventory()
	--renderer:RenderAll()
end

-- store payload for drag
dragDropPayload = nil

local containers = nil
local itemDetails = nil
local dragDrop = nil

local function wireSlots(slotContainer: Instance, isHotbar: boolean?)
	for _, v in ipairs(slotContainer:GetChildren()) do
		if v:IsA("ImageButton") then
			v.Active = true
			v.Selectable = true

			-- Click handler
			v.MouseButton1Click:Connect(function()
				-- Ignore if currently dragging
				if dragDrop and dragDrop:IsDragging() then
					return
				end

				local itemId = v:GetAttribute("ItemId")
				if not itemId or itemId == "" then return end

				local itemPieces = string.split(itemId, "_")
				local itemName = itemPieces[1]
				local itemDef = InventoryFunctions.GetItemDef(itemName)

				if not itemDef then return end

				-- Check if it's a container - open it
				if itemDef.SubType == "Container" then
					local containerGui = containers:CreateContainer(itemId)
					if containerGui then
						containers:PopulateContainer(itemId, function(id, slot, item, parentId)
							renderer:PopulateSlot(id, slot, item, parentId)
						end)
					end
				else
					-- Show item details
					local inv = renderer:GetInventory()
					if inv then
						itemDetails:ShowItemDetails(itemId, v, inv)
					end
				end
			end)

			-- Drag/drop handlers (existing code)
			v.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not v:GetAttribute("DD") then return end

				dragDropPayload = {
					itemId = v:GetAttribute("ItemId"),
					fromArea = v:GetAttribute("DDArea"),
					fromSlot = v:GetAttribute("DDSlot"),
					sourceContainerId = v:GetAttribute("ParentContainerId"),
				}

				dragDrop:BeginDragFromSlot(v, function()
					local ghost = v:Clone()
					ghost.Size = UDim2.new(0,64,0,64)
					return ghost
				end)
			end)

			v.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				dragDrop:EndDragAtPosition(input.Position)
			end)
		end
	end
end

local function containerMovement(ContainerGui)
	local clickedOnFrame = nil
	local mouseDown = false
	local mouseDownTime = 0
	local mousePos = nil
	local framePos = nil
	local dragThreshold = 0.05

	ContainerGui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			clickedOnFrame = ContainerGui.Name
			mouseDown = true
			mouseDownTime = tick()
			mousePos = input.Position
			framePos = ContainerGui.Position
		end
	end)

	ContainerGui.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDown = false
		end
	end)

	ContainerGui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if not mouseDown then return end
			if ContainerGui.Name ~= clickedOnFrame then return end

			local currentTime = tick()
			if currentTime - mouseDownTime >= dragThreshold then
				local delta = input.Position - mousePos
				ContainerGui.Position = UDim2.new(
					framePos.X.Scale,
					framePos.X.Offset + delta.X,
					framePos.Y.Scale,
					framePos.Y.Offset + delta.Y
				)
			end
		end
	end)
end


containers = ContainerController.new(ui, {
	InventoryFunctions = InventoryFunctions,
	getInventory = function()
		return renderer:GetInventory()
	end,
	onContainerCreated = function(containerGui, containerId)
		-- Wire up drag/drop for this new container
		local slotsContainer = containerGui.ItemSlots.Slots
		wireSlots(slotsContainer)

		-- Make container draggable
		containerMovement(containerGui)
	end
})

itemDetails = ItemDetailsController.new(ui, {
	InventoryFunctions = InventoryFunctions,
	getInventory = function()
		return renderer:GetInventory()
	end,
})

dragDrop = DragDropController.new(ui, {
	onDrop = function(targetFrame, moveAmount)
		handleFinalDrop(targetFrame, moveAmount)
		dragDropPayload = nil
	end,
	onDroppedOutside = function()
		if not dragDropPayload then return end

		local itemId = dragDropPayload.itemId
		local fromArea = dragDropPayload.fromArea
		local parentContainerId = dragDropPayload.sourceContainerId

		local itemPieces = string.split(itemId, "_")
		local itemName = itemPieces[1]

		local def = InventoryFunctions.GetItemDef(itemName)
		if def and not def.CanNotRemove then
			dialogs:ShowRemoveConfirm(("Do you want to remove %s?"):format(itemId), function()
				RemoveItemEvent:FireServer(itemId, parentContainerId, fromArea, 1)
			end)
		end

		dragDropPayload = nil
		renderer:LoadInventory()
		renderer:RenderAll()
	end,
	clearSelection = function()
		itemDetails:ClearSelection()  -- ADD THIS
	end,
})

-- WIRE TAB BUTTONS -> TabsController
-- (Adjust these paths to match your actual UI tree)
local function wireTab(button: GuiButton, tabSlots: Instance, title: string)
	if not button then
		warn("Missing tab button for:", title)
		return
	end

	-- make sure it can receive clicks
	button.Active = true
	button.Selectable = true

	button.Activated:Connect(function()
		-- Ignore clicks while dragging something
		if dragDrop and dragDrop:IsDragging() then
			return
		end

		tabs:Set(tabSlots, title)

		-- If your renderer supports rendering a single tab, call that.
		-- Otherwise just refresh all.
		if renderer.RenderTab then
			renderer:RenderTab(tabSlots)
		else
			renderer:RenderAll()
		end
	end)
end

wireTab(ui.tabs.tools,       ui.slots.slots_tools,       "Tools")
wireTab(ui.tabs.food,        ui.slots.slots_consumables, "Food")
wireTab(ui.tabs.weapons,     ui.slots.slots_weapons,     "Weapons")
wireTab(ui.tabs.clothing,    ui.slots.slots_clothing,    "Clothing")
wireTab(ui.tabs.materials,   ui.slots.slots_materials,   "Materials")
wireTab(ui.tabs.misc,        ui.slots.slots_misc,        "Misc")
wireTab(ui.tabs.access,      ui.slots.slots_access,      "Access")
wireTab(ui.tabs.info,        ui.slots.slots_info,        "Info")

-- wire all your slots (same list as before, but now clean)
wireSlots(ui.slots.slots_tools)
wireSlots(ui.slots.slots_consumables)
wireSlots(ui.slots.slots_weapons)
wireSlots(ui.slots.slots_clothing)
wireSlots(ui.slots.slots_materials)
wireSlots(ui.slots.slots_misc)
wireSlots(ui.slots.slots_access)
wireSlots(ui.slots.slots_info)


wireSlots(ui.slots.slots_weapon, true)
wireSlots(ui.slots.slots_offhand, true)
wireSlots(ui.slots.slots_head, true)
wireSlots(ui.slots.slots_back, true)
wireSlots(ui.slots.slots_chest, true)
wireSlots(ui.slots.slots_face, true)
wireSlots(ui.slots.slots_accessory, true)

wireSlots(ui.slots.slots_toolbelt, true)
wireSlots(ui.slots.slots_watch, true)
wireSlots(ui.slots.slots_trade, true)
wireSlots(ui.slots.slots_overflow, true)
wireSlots(ui.slots.slots_vacpacExtra, true)

-- inventory refresh event
sendinv.OnClientEvent:Connect(function()
	local inv = renderer:LoadInventory()
	renderer:RenderAll()

	-- Refresh all open containers
	for containerId, containerGui in pairs(containers:GetOpenContainers()) do
		containers:PopulateContainer(containerId, function(id, slot, item, parentId)
			renderer:PopulateSlot(id, slot, item, parentId)
		end)
	end
	
	if (inv.Back and itemsmodule[inv.Back.Name].Capacity) then
		ui.vacpacExtraGui.Visible = true
		ui.vacpacExtraGui.Interactable = true
		ui.vacpacExtraGui:SetAttribute("MaxSlots",itemsmodule[inv.Back.Name].Capacity)

	end
end)

-- open/close inventory keybind (keep your old behavior, simplified)
local InventoryOpen = false
local function toggleInventory()
	local inv = renderer:LoadInventory()
	renderer:RenderAll()

	ui.background.Visible = true
	if InventoryOpen then
		ui.background:TweenPosition(UDim2.new(-0.6, 0, 0.3, 0))
		InventoryOpen = false
	else
		ui.background:TweenPosition(UDim2.new(0, 0, 0, 0))
		InventoryOpen = true
	end
			
end

--ContextActionService:BindAction("openBackpack", function(_, state)
--	if state == Enum.UserInputState.Begin then
--		toggleInventory()
--	end
--end, false, Enum.KeyCode.B)

--ui.buttons.close.Activated:Connect(function()
--	ui.background:TweenPosition(UDim2.new(-0.6, 0, 0.3, 0))
--	InventoryOpen = false
--end)

-- initial
renderer:LoadInventory()
renderer:RenderAll()
