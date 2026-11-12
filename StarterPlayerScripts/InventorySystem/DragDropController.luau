-- SharedClientScripts/InventoryUI/DragDropController.lua

local DragDropController = {}
DragDropController.__index = DragDropController

function DragDropController.new(ui, options)
	local self = setmetatable({}, DragDropController)

	self.ui = ui
	self.onDrop = options.onDrop
	self.onDroppedOutside = options.onDroppedOutside
	self.clearSelection = options.clearSelection or function() end

	self.dragging = false
	self.dragFrame = nil
	self.sourceSlot = nil
	self.mouseDownTime = 0
	self.dragThreshold = 0.02  -- 20ms
	self.mouseDown = false
	self.dragStartPos = nil
	self.dragDistanceThreshold = 5  -- pixels
	self.createGhost = nil

	-- Create drag frame
	self.dragFrame = Instance.new("Frame")
	self.dragFrame.Name = "DragFrame"
	self.dragFrame.Size = UDim2.new(0, 64, 0, 64)
	self.dragFrame.ZIndex = 9999
	self.dragFrame.BackgroundTransparency = 1
	self.dragFrame.Visible = false
	self.dragFrame.Parent = ui.inventoryGUI

	-- Mouse tracking
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if self.mouseDown and not self.dragging then
				if self.dragStartPos then
					-- Convert Vector3 to Vector2 for distance calculation
					local currentPos = Vector2.new(input.Position.X, input.Position.Y)
					local delta = (currentPos - self.dragStartPos).Magnitude

					-- Start drag if moved enough distance
					if delta > self.dragDistanceThreshold then
						self:_StartDragging()
					end
				end
			end

			if self.dragging then
				self:_UpdateDragPosition(input.Position)
			end
		end
	end)

	return self
end

function DragDropController:BeginDragFromSlot(slot, createGhostFunc)
	self.sourceSlot = slot
	self.mouseDown = true
	self.mouseDownTime = tick()

	-- Store as Vector2
	local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
	self.dragStartPos = mouseLocation  -- Already a Vector2

	self.createGhost = createGhostFunc
end

function DragDropController:_StartDragging()
	if self.dragging then return end
	if not self.sourceSlot then return end

	self.dragging = true

	-- Create ghost
	if self.createGhost then
		local ghost = self.createGhost()
		if ghost then
			ghost.Name = "DDItemFrame"
			ghost.Position = UDim2.new(0, 0, 0, 0)
			ghost.BackgroundTransparency = 1
			ghost.Parent = self.dragFrame
		end
	end

	-- Hide source visuals
	if self.sourceSlot then
		local pic = self.sourceSlot:FindFirstChild("ItemPic")
		local rarity = self.sourceSlot:FindFirstChild("RarityPic")
		local amt = self.sourceSlot:FindFirstChild("ItemAmount")
		local name = self.sourceSlot:FindFirstChild("ItemName")

		if pic and pic:IsA("ImageLabel") then pic.Visible = false end
		if rarity and rarity:IsA("ImageLabel") then rarity.Visible = false end
		if amt and amt:IsA("TextLabel") then amt.Visible = false end
		if name and name:IsA("TextLabel") then name.Visible = false end
	end

	self.dragFrame.Visible = true
	self.clearSelection()
end

function DragDropController:_UpdateDragPosition(mousePos)
	if not self.dragging then return end

	-- mousePos is a Vector3, extract X and Y
	self.dragFrame.Position = UDim2.new(
		0, mousePos.X - 32,  -- Center horizontally
		0, mousePos.Y + 32   -- Slight offset below cursor
	)
end

function DragDropController:EndDragAtPosition(mousePos)
	self.mouseDown = false

	if not self.dragging then
		-- This was just a click, not a drag
		return
	end

	-- Check if dropped on valid target
	local targetFrame = self:_FindTargetFrameAtPosition(mousePos)

	if targetFrame then
		-- Determine move amount based on modifier keys
		local UserInputService = game:GetService("UserInputService")
		local moveAmount = 1

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
			moveAmount = -1  -- All
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			moveAmount = -2  -- Calculator/custom amount
		end

		self.onDrop(targetFrame, moveAmount)
	else
		-- Dropped outside
		self.onDroppedOutside()
	end

	self:_Cleanup()
end

function DragDropController:_FindTargetFrameAtPosition(mousePos)
	-- Gather all potential drop targets
	local targets = {}
	for _, desc in pairs(self.ui.inventoryGUI.Parent:GetDescendants()) do
		if desc:IsA("ImageButton") and desc:GetAttribute("DD") then
			
			-- Exclude anything inside the drag frame
			if desc:IsDescendantOf(self.dragFrame) then continue end
			
			-- Check if visible and enabled
			if desc.Visible and desc.Active then
				-- Check parent visibility
				local parent = desc.Parent
				local visible = true
				while parent and parent ~= game do
					if parent:IsA("GuiObject") and not parent.Visible then
						visible = false
						break
					end
					if parent:IsA("LayerCollector") and not parent.Enabled then
						visible = false
						break
					end
					parent = parent.Parent
				end

				if visible then
					table.insert(targets, desc)
				end
			end
		end
	end

	-- Find which one mouse is over (mousePos is Vector3)
	for _, target in ipairs(targets) do
		local absPos = target.AbsolutePosition
		local absSize = target.AbsoluteSize

		if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
			mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
			print("TEST DRAG DROP target slot:",target,target.Name,target.Parent.Name,target.Parent.Parent.Name)
			return target
		end
	end

	return nil
end

function DragDropController:_Cleanup()
	self.dragging = false
	self.mouseDown = false
	self.mouseDownTime = 0
	self.dragStartPos = nil

	-- Clear drag frame
	if self.dragFrame then
		for _, child in ipairs(self.dragFrame:GetChildren()) do
			child:Destroy()
		end
		self.dragFrame.Visible = false
	end

	-- DON'T restore source slot visuals here - let the renderer handle it
	-- This prevents the flicker when the item moves to a new position

	-- Just clear references
	self.sourceSlot = nil
	self.createGhost = nil
end

function DragDropController:IsDragging()
	return self.dragging
end

return DragDropController