--!strict
-- SharedClientScripts/InventoryUI/InventoryRenderer.lua

local InventoryRenderer = {}
InventoryRenderer.__index = InventoryRenderer

type UI = {
	background: Frame,
	inventoryGUI: Instance,
	itemDetails: GuiObject?,
	tradingGui: ScreenGui,
	craftingGui: GuiObject,
	overflowContainerGui: GuiObject,
	containerGuiTemplate: GuiObject,
	vacpacExtraGui: GuiObject,

	frames: { [string]: Instance },
	slots: { [string]: Instance },
	buttons: { [string]: GuiObject },
	slotSelection: GuiObject,
}

type Deps = {
	InventoryFunctions: any,
	Recipes: any?,

	-- Use ONE of these:
	GetInventoryRemote: RemoteFunction?, -- SharedRemotes.GetInventory
	getInventory: (() -> any)?,

	-- Optional: called whenever we render
	onRendered: ((inv: any) -> ())?,
}

local RARITY_COLORS = {
	[0] = Color3.fromRGB(60, 60, 60),      -- Trash (dark grey)
	[1] = Color3.fromRGB(255, 255, 255),   -- Common (white)
	[2] = Color3.fromRGB(50, 160, 50),     -- Uncommon (green)
	[3] = Color3.fromRGB(50, 160, 210),    -- Rare (cyan/blue)
	[4] = Color3.fromRGB(140, 40, 200),    -- Epic (purple)
	[5] = Color3.fromRGB(210, 160, 20),    -- Legendary (gold)
}

local function isImageButton(x: Instance): boolean
	return x:IsA("ImageButton")
end

local function isLayerCollector(x: Instance): boolean
	return x:IsA("LayerCollector")
end

local function safeSetText(lbl: Instance?, txt: string)
	if lbl and lbl:IsA("TextLabel") then
		lbl.Text = txt
		lbl.Visible = (txt ~= "")
	end
end

local function safeSetVisible(inst: Instance?, v: boolean)
	if inst and inst:IsA("GuiObject") then
		inst.Visible = v
	end
end

local function safeClearPic(pic: Instance?)
	if pic and pic:IsA("ImageLabel") then
		pic.Image = ""
		pic.ImageTransparency = 1
		pic.BackgroundTransparency = 1
		pic.BackgroundColor3 = RARITY_COLORS[0]  -- reset to common
		pic.Visible = false
	end
end

local function safeSetPicFromAtlas(pic: Instance?, atlasId: string, offset: Vector2, size: Vector2, rarity: number?, imageTrans,BackgroundTrans)
	if not (pic and pic:IsA("ImageLabel")) then
		return
	end
	pic.Visible = true
	pic.ImageTransparency = imageTrans
	pic.BackgroundTransparency = BackgroundTrans
	pic.Image = atlasId
	pic.ImageRectOffset = offset
	pic.ImageRectSize = size
	pic.ScaleType = Enum.ScaleType.Stretch

	if rarity ~= nil then
		pic.BackgroundColor3 = RARITY_COLORS[rarity] or RARITY_COLORS[0]
	end
end

function InventoryRenderer.new(ui: UI, deps: Deps)
	assert(ui, "[InventoryRenderer] ui required")
	assert(deps and deps.InventoryFunctions, "[InventoryRenderer] deps.InventoryFunctions required")

	local self = setmetatable({}, InventoryRenderer)
	self.ui = ui
	self.deps = deps
	self.playerInventory = nil

	-- rarity atlas config (your existing one)
	self._rarityAtlas = "rbxassetid://13802435951"
	self._rarityRectSize = Vector2.new(64, 64)
	self._rarityRowY = 832

	return self
end

function InventoryRenderer:GetInventory()
	return self.playerInventory
end

function InventoryRenderer:LoadInventory()
	local deps = self.deps
	local inv

	if deps.getInventory then
		inv = deps.getInventory()
	elseif deps.GetInventoryRemote then
		inv = deps.GetInventoryRemote:InvokeServer()
	else
		error("[InventoryRenderer] Provide deps.getInventory() or deps.GetInventoryRemote")
	end

	self.playerInventory = inv

	return inv
end

-- ============================================================
-- Rarity
-- ============================================================
function InventoryRenderer:_SetRarityPic(slot: Instance, itemName: string)
	local rarityPic = slot:FindFirstChild("RarityPic")
	if not (rarityPic and rarityPic:IsA("ImageLabel")) then
		return
	end

	local def = self.deps.InventoryFunctions.GetItemDef(itemName)
	if not def then
		rarityPic.Visible = false
		return
	end

	local rarity = def.Rarity
	local x = (tonumber(rarity) or 0) * 64
	safeSetPicFromAtlas(rarityPic, self._rarityAtlas, Vector2.new(x, self._rarityRowY), self._rarityRectSize, rarity,1,0)
end

function InventoryRenderer:_ClearRarityPic(slot: Instance)
	local rarityPic = slot:FindFirstChild("RarityPic")
	if rarityPic and rarityPic:IsA("ImageLabel") then
		rarityPic.Visible = false
		rarityPic.ImageTransparency = 1
	end
end

-- ============================================================
-- Slot helpers
-- ============================================================
function InventoryRenderer:_ClearSlot(slot: Instance)
	if not isImageButton(slot) then return end

	slot:SetAttribute("ItemId", nil)

	local itemName = slot:FindFirstChild("ItemName")
	local itemAmt  = slot:FindFirstChild("ItemAmount")
	local itemPic  = slot:FindFirstChild("ItemPic")

	safeSetText(itemName, "")
	safeSetText(itemAmt, "")
	safeClearPic(itemPic)

	self:_ClearRarityPic(slot)

	-- some of your slots depend on these being visible
	if itemPic and itemPic:IsA("ImageLabel") then
		itemPic.Visible = true
		itemPic.ImageTransparency = 0
	end

	local noTool = slot:FindFirstChild("NoTool")
	if noTool and noTool:IsA("GuiObject") then
		noTool.Visible = false
	end

	slot.Active = true
	slot.Visible = true
end

function InventoryRenderer:PopulateSlot(itemId: string, slot: Instance, playerItem: any?, parentContainerId: string?)
	if not playerItem then
		self:_ClearSlot(slot)
		return
	end

	local itemName = playerItem.Name or itemId
	local def = self.deps.InventoryFunctions.GetItemDef(itemName)
	if not def then
		warn("[InventoryRenderer] PopulateSlot: no itemDef for", itemName)
		return
	end

	self:_PopulateSlot(itemId, slot, playerItem, def, parentContainerId, nil)
end

function InventoryRenderer:_PopulateSlot(
	itemId: string,
	slot: Instance,
	playerItem: any?,
	itemDef: any,
	parentContainerId: string?,
	amountNeeded: number?
)
	if not isImageButton(slot) then return end

	-- attributes used by drag/drop + your logic
	slot:SetAttribute("ItemId", itemId)
	if parentContainerId then
		slot:SetAttribute("ParentContainerId", parentContainerId)
	end

	-- special case: crafting tool slot often shows NoTool
	if slot.Name == "Tool" then
		local noTool = slot:FindFirstChild("NoTool")
		if noTool and noTool:IsA("GuiObject") then
			noTool.Visible = false
		end
	end

	-- if no playerItem (ex: crafting tool placeholder)
	if not playerItem then
		if slot.Name == "Tool" then
			-- allow it to render the "NoTool" overlay
			local noTool = slot:FindFirstChild("NoTool")
			if noTool and noTool:IsA("GuiObject") then
				noTool.Visible = true
			end
		end
		return
	end

	if not itemDef then
		warn("[InventoryRenderer] _PopulateSlot itemDef nil for", itemId)
		return
	end

	-- text fields
	local itemNameLbl = slot:FindFirstChild("ItemName")
	local itemAmtLbl  = slot:FindFirstChild("ItemAmount")

	-- Name text: you were using itemId (not DisplayName) inside grid
	safeSetText(itemNameLbl, itemId)

	-- Amount
	if itemAmtLbl and itemAmtLbl:IsA("TextLabel") then
		itemAmtLbl.Position = UDim2.new(0, 4, 0, 3)
		itemAmtLbl.Size = UDim2.new(1, -6, 0, 16)
		itemAmtLbl.TextXAlignment = Enum.TextXAlignment.Left
		itemAmtLbl.ZIndex = 10
	end

	local amount = playerItem.Amount
	if amount == nil then
		amount = 1
	end

	if itemDef.SubType == "Container" and itemDef.Capacity ~= nil and playerItem.Contains then
		-- show used/capacity
		local used = 0
		for _, contained in pairs(playerItem.Contains) do
			used += (contained.Amount or 1)
		end
		safeSetText(itemAmtLbl, ("%d/%d"):format(used, itemDef.Capacity))
	else
		if amountNeeded then
			-- crafting display like "x3/5" etc (your older code mixed formats)
			if amount <= 1 then
				safeSetText(itemAmtLbl, ("1/%d"):format(amountNeeded))
			else
				safeSetText(itemAmtLbl, ("x%d/%d"):format(amount, amountNeeded))
			end
		else
			if amount > 1 then
				safeSetText(itemAmtLbl, ("x%d"):format(amount))
			else
				safeSetText(itemAmtLbl, "")
			end
		end
	end

	-- picture
	local itemPic = slot:FindFirstChild("ItemPic")
	if itemPic and itemPic:IsA("ImageLabel") then
		local imageMap = self.deps.InventoryFunctions.GetImageMap()
		local atlas = imageMap[itemDef.Type]

		if atlas then
			local ox = itemDef.ImageOffsetX or 0
			local oy = itemDef.ImageOffsetY or 0
			safeSetPicFromAtlas(itemPic, atlas, Vector2.new(ox, oy), Vector2.new(64, 64),itemDef.Rarity, 0 , 1)

			-- rarity
			self:_SetRarityPic(slot, itemDef.Name)
		else
			warn("[InventoryRenderer] No ImageMap for type:", itemDef.Type, " item:", itemDef.Name)
			safeClearPic(itemPic)
		end
	end
end

-- ============================================================
-- Containers
-- ============================================================
function InventoryRenderer:_PopulateContainer(containerId: string)
	if not self.playerInventory then return end
	if containerId == "" then return end

	local inv = self.playerInventory
	local container = inv.Items and inv.Items[containerId]
	if not container then
		container = inv.Tools and inv.Tools[containerId]
	end
	if not container then
		warn("[InventoryRenderer] PopulateContainer container not found:", containerId)
		return
	end

	local containerGui = self.ui.inventoryGUI:FindFirstChild(containerId .. "Container")
	if not containerGui then
		-- the GUI may be created by your click handler / ContainerController
		return
	end

	local slotsContainer = containerGui:FindFirstChild("ItemSlots")
	if not slotsContainer then return end
	slotsContainer = slotsContainer:FindFirstChild("Slots")
	if not slotsContainer then return end

	-- clean container slots
	for _, v in ipairs(slotsContainer:GetChildren()) do
		if isImageButton(v) then
			self:_ClearSlot(v)
			v:SetAttribute("ParentContainerId", containerId)

			local def = self.deps.InventoryFunctions.GetItemDef(container.Name)
			if def and def.ContainerSlots and v:GetAttribute("DDSlot") then
				local ddSlot = tonumber(v:GetAttribute("DDSlot"))
				if ddSlot and ddSlot > def.ContainerSlots then
					v.Active = false
					v.Visible = false
				end
			end
		end
	end

	-- populate
	if container.Contains then
		for _, containedItem in pairs(container.Contains) do
			local slotNum = containedItem.Slot
			local target = slotsContainer:FindFirstChild("Slot" .. tostring(slotNum))
			if not target then
				warn("[InventoryRenderer] Container slot missing:", containerId, "Slot" .. tostring(slotNum))
				continue
			end
			local def = self.deps.InventoryFunctions.GetItemDef(containedItem.Name)
			if def then
				self:_PopulateSlot(containedItem.Name, target, containedItem, def, containerId, nil)
			end
		end
	end
end

function InventoryRenderer:_PopulateAllOpenContainers()
	for _, child in ipairs(self.ui.inventoryGUI:GetChildren()) do
		if child:GetAttribute("DDArea") == "Container" then
			local containerId = child:GetAttribute("ContainerId")
			if containerId then
				self:_PopulateContainer(containerId)
			end
		end
	end
end

-- ============================================================
-- Overflow
-- ============================================================
function InventoryRenderer:_PopulateOverflow()
	if not self.playerInventory then return end
	local inv = self.playerInventory
	local gui = self.ui.overflowContainerGui

	gui.Interactable = false
	gui.Visible = false

	-- clean
	local slots = gui:FindFirstChild("ItemSlots")
	if not slots then return end
	slots = slots:FindFirstChild("Slots")
	if not slots then return end

	for _, v in ipairs(slots:GetChildren()) do
		if isImageButton(v) then
			self:_ClearSlot(v)
		end
	end

	local overflow = inv.Overflow
	if overflow and overflow.Contains then
		for containerItemId, containerItem in pairs(overflow.Contains) do
			gui.Interactable = true
			gui.Visible = true

			local target = slots:FindFirstChild("Slot" .. tostring(containerItem.Slot))
			if target then
				local def = self.deps.InventoryFunctions.GetItemDef(containerItem.Name)
				if def then
					self:_PopulateSlot(containerItemId, target, containerItem, def, nil, nil)
				end
			end
		end
	end
end

-- ============================================================
-- Vacpac Extra
-- ============================================================
function InventoryRenderer:_PopulateVacpacExtra()
	if not self.playerInventory then return end
	local inv = self.playerInventory
	local gui = self.ui.vacpacExtraGui

	--gui.Interactable = true
	--gui.Visible = true

	-- clean
	local slots = gui:FindFirstChild("ItemSlots")
	if not slots then return end
	slots = slots:FindFirstChild("Slots")
	if not slots then return end

	for _, v in ipairs(slots:GetChildren()) do
		if isImageButton(v) then
			self:_ClearSlot(v)

			if gui:GetAttribute("MaxSlots") then
				if (v:GetAttribute("DDSlot") <= gui:GetAttribute("MaxSlots")) then
					v.Visible = true
				else
					v.Visible = false
				end
			end

		end
	end

	local vacpacExtra = inv.VacpacExtra
	if vacpacExtra and vacpacExtra.Contains then
		for containerItemId, containerItem in pairs(vacpacExtra.Contains) do

			local target = slots:FindFirstChild("Slot" .. tostring(containerItem.Slot))
			if target then
				local def = self.deps.InventoryFunctions.GetItemDef(containerItem.Name)
				if def then
					self:_PopulateSlot(containerItemId, target, containerItem, def, nil, nil)
				end
			end
		end
	end
end


-- ============================================================
-- Crafting
-- ============================================================
function InventoryRenderer:RenderCrafting(craftingContents: any, fulfilledRecipe: string?, toolNeeded: string?, haveTool: boolean?)
	local Recipes = self.deps.Recipes
	if not Recipes then
		return
	end

	local slots = self.ui.slots.slots_crafting
	if not slots then return end

	-- clean crafting slots
	for _, v in ipairs(slots:GetChildren()) do
		if isImageButton(v) then
			self:_ClearSlot(v)
		end
	end

	local recipes = Recipes.GetRecipes()

	-- fill ingredient slots
	for craftingItemId, craftingItem in pairs(craftingContents or {}) do
		local target = slots:FindFirstChild("Slot" .. tostring(craftingItem.Slot))
		if not target then
			warn("[InventoryRenderer] Crafting slot missing:", "Slot" .. tostring(craftingItem.Slot))
			continue
		end

		local amountNeeded: number? = nil
		if fulfilledRecipe and recipes[fulfilledRecipe] then
			for _, recipeItem in pairs(recipes[fulfilledRecipe]) do
				if type(recipeItem) == "table" and recipeItem.Name == craftingItemId then
					amountNeeded = recipeItem.AmountNeeded
					break
				end
			end
		end

		local def = self.deps.InventoryFunctions.GetItemDef(craftingItemId)
		if def then
			self:_PopulateSlot(craftingItemId, target, craftingItem, def, "Crafting", amountNeeded)
		end
	end

	-- tool slot + craft button area (matches your old logic)
	local craftGui = self.ui.craftingGui
	local toolSlot = slots:FindFirstChild("Tool")
	if toolSlot and toolNeeded and toolNeeded ~= "" then
		local inv = self.playerInventory
		local toolItem = inv and inv.Items and inv.Items[toolNeeded] or nil
		local def = self.deps.InventoryFunctions.GetItemDef(toolNeeded)
		if def then
			self:_PopulateSlot(toolNeeded, toolSlot, toolItem, def, "Crafting", nil)
		end
	end

	-- fulfilled recipe preview
	local craftButton = craftGui:FindFirstChild("CraftButton")
	local fullBg = craftGui:FindFirstChild("FullfilledItemBackground")
	local fullTitle = craftGui:FindFirstChild("FullfilledItemTitle")
	local fullItem = craftGui:FindFirstChild("FullfilledItem")

	if fulfilledRecipe and recipes[fulfilledRecipe] then
		if craftButton and craftButton:IsA("GuiObject") then craftButton.Visible = true end
		if fullBg and fullBg:IsA("GuiObject") then fullBg.Visible = true end
		if fullTitle and fullTitle:IsA("TextLabel") then
			fullTitle.Visible = true
			fullTitle.Text = fulfilledRecipe
		end

		if fullItem and fullItem:IsA("ImageLabel") then
			local def = self.deps.InventoryFunctions.GetItemDef(fulfilledRecipe)
			if def then
				local atlas = self.deps.InventoryFunctions.GetImageMap()[def.Type]
				if atlas then
					fullItem.Visible = true
					fullItem.ImageTransparency = 0
					fullItem.BackgroundTransparency = 1
					fullItem.Image = atlas
					fullItem.ImageRectOffset = Vector2.new(def.ImageOffsetX or 0, def.ImageOffsetY or 0)
					fullItem.ImageRectSize = Vector2.new(64, 64)
					fullItem.ScaleType = Enum.ScaleType.Stretch
				end
			end
		end
	else
		if craftButton and craftButton:IsA("GuiObject") then craftButton.Visible = false end
		if fullBg and fullBg:IsA("GuiObject") then fullBg.Visible = false end
		if fullTitle and fullTitle:IsA("TextLabel") then fullTitle.Visible = false end
		if fullItem and fullItem:IsA("ImageLabel") then fullItem.Visible = false end

		if toolSlot and isImageButton(toolSlot) then
			local pic = toolSlot:FindFirstChild("ItemPic")
			if pic and pic:IsA("ImageLabel") then pic.Visible = false end
			self:_ClearRarityPic(toolSlot)
			local amt = toolSlot:FindFirstChild("ItemAmount")
			local nm  = toolSlot:FindFirstChild("ItemName")
			if amt and amt:IsA("TextLabel") then amt.Visible = false end
			if nm and nm:IsA("TextLabel") then nm.Visible = false end
		end
	end
end

-- ============================================================
-- Main inventory render
-- ============================================================
function InventoryRenderer:_ClearMainGrids()
	-- clear 16 slots per category (matches your UI layout)
	local function clearSlotsContainer(container: Instance?)
		if not container then return end
		for _, v in ipairs(container:GetChildren()) do
			if isImageButton(v) then
				self:_ClearSlot(v)
			end
		end
	end

	clearSlotsContainer(self.ui.slots.slots_tools)
	clearSlotsContainer(self.ui.slots.slots_consumables)
	clearSlotsContainer(self.ui.slots.slots_weapons)
	clearSlotsContainer(self.ui.slots.slots_clothing)
	clearSlotsContainer(self.ui.slots.slots_materials)
	clearSlotsContainer(self.ui.slots.slots_misc)
	clearSlotsContainer(self.ui.slots.slots_access)
	clearSlotsContainer(self.ui.slots.slots_info)
end

function InventoryRenderer:_ClearEquipSlots()
	local function clearEquip(slotsContainer: Instance?)
		if not slotsContainer then return end
		local slot1 = slotsContainer:FindFirstChild("Slot1")
		if slot1 and isImageButton(slot1) then
			self:_ClearSlot(slot1)
			-- keep images visible for these
			local pic = slot1:FindFirstChild("ItemPic")
			if pic and pic:IsA("ImageLabel") then
				pic.Visible = true
				pic.ImageTransparency = 0
			end
		end
	end

	clearEquip(self.ui.slots.slots_weapon)
	clearEquip(self.ui.slots.slots_offhand)
	clearEquip(self.ui.slots.slots_head)
	clearEquip(self.ui.slots.slots_back)
	clearEquip(self.ui.slots.slots_accessory)
	clearEquip(self.ui.slots.slots_watch)
end

function InventoryRenderer:_RenderEquipSlot(slotContainer: Instance?, equippedItem: any?, typeKey: string, amountOnly: boolean)
	if not slotContainer then return end
	local slot1 = slotContainer:FindFirstChild("Slot1")
	if not (slot1 and isImageButton(slot1)) then return end


	if equippedItem and equippedItem.Name then
		local def = self.deps.InventoryFunctions.GetItemDef(equippedItem.Name)
		if def then
			-- for equip slots you were setting ItemId to item name
			slot1:SetAttribute("ItemId", equippedItem.Name)

			local pic = slot1:FindFirstChild("ItemPic")
			local atlas = self.deps.InventoryFunctions.GetImageMap()[typeKey] or self.deps.InventoryFunctions.GetImageMap()[def.Type]
			if pic and pic:IsA("ImageLabel") and atlas then
				pic.ImageTransparency = 0
				pic.BackgroundTransparency = 1
				pic.Image = atlas
				pic.ImageRectOffset = Vector2.new(def.ImageOffsetX or 0, def.ImageOffsetY or 0)
				pic.ImageRectSize = Vector2.new(64, 64)
				pic.ScaleType = Enum.ScaleType.Stretch
				pic.Visible = true
			end

			if (amountOnly) then
				local amount = slot1:FindFirstChild("ItemAmount")
				if amount and amount:IsA("TextLabel") then
					amount.Text = "x"..equippedItem.Amount
					amount.Visible = true
				end
			else
				local nm = slot1:FindFirstChild("ItemName")
				if nm and nm:IsA("TextLabel") then
					nm.Text = equippedItem.Name
					nm.Visible = true
				end
			end


			self:_SetRarityPic(slot1, def.Name)
		end
	else
		slot1:SetAttribute("ItemId", nil)
		local nm = slot1:FindFirstChild("ItemName")
		safeSetText(nm, "")
		local pic = slot1:FindFirstChild("ItemPic")
		safeClearPic(pic)
	end
end

function InventoryRenderer:RenderAll()
	if not self.playerInventory then
		self:LoadInventory()
	end

	local inv = self.playerInventory
	if not inv then
		warn("[InventoryRenderer] RenderAll: no inventory")
		return
	end

	-- Hide side panels (your old clearUI did this)
	if self.ui.itemDetails and self.ui.itemDetails:IsA("GuiObject") then
		self.ui.itemDetails.Visible = false
	end
	if self.ui.slotSelection and self.ui.slotSelection:IsA("GuiObject") then
		self.ui.slotSelection.Visible = false
	end

	-- clear grids + equip slots
	self:_ClearMainGrids()
	self:_ClearEquipSlots()

	-- render backpack Items
	local Items = inv.Items or {}
	for itemId, playerItem in pairs(Items) do
		local def = self.deps.InventoryFunctions.GetItemDef(playerItem.Name)
		if def then
			-- skip TempHold from backpack
			if def.Type ~= "TempHold" then
				-- choose correct tab container by type
				local slotContainer: Instance? = nil
				local map = self.deps.InventoryFunctions -- only to keep naming similar
				-- replicate your mapping
				local TypeToSlots = {
					Weapon      = self.ui.slots.slots_weapons,
					Artifact    = self.ui.slots.slots_weapons,
					Ammo        = self.ui.slots.slots_weapons,
					OffHand     = self.ui.slots.slots_weapons,

					Tool        = self.ui.slots.slots_tools,
					Consumable  = self.ui.slots.slots_consumables,
					Clothing    = self.ui.slots.slots_clothing,
					Material    = self.ui.slots.slots_materials,
					Access      = self.ui.slots.slots_access,
					Info        = self.ui.slots.slots_info,
					Misc        = self.ui.slots.slots_misc,

					PowerSource = self.ui.slots.slots_misc,
					Disk        = self.ui.slots.slots_misc,
					Heal        = self.ui.slots.slots_misc,
					Trash       = self.ui.slots.slots_misc,
					Money       = self.ui.slots.slots_misc,

					TempHold    = nil,
				}

				slotContainer = TypeToSlots[def.Type]
				if slotContainer then
					local slot = slotContainer:FindFirstChild("Slot" .. tostring(playerItem.Slot))
					if slot then
						self:_PopulateSlot(itemId, slot, playerItem, def, nil, nil)
					end
				end
			end
		end
	end

	print("TEST DRAGG: inventory before RenderEquipSlot:",inv,inv.Weapon)

	-- render equipped slots
	self:_RenderEquipSlot(self.ui.slots.slots_weapon, inv.Weapon, "Weapon")
	self:_RenderEquipSlot(self.ui.slots.slots_offhand, inv.OffHand, "Weapon")
	self:_RenderEquipSlot(self.ui.slots.slots_head, inv.Head, "Clothing")
	self:_RenderEquipSlot(self.ui.slots.slots_back, inv.Back, "Clothing")
	self:_RenderEquipSlot(self.ui.slots.slots_accessory, inv.Accessory, "Clothing")

	-- containers (only those already opened / existing in UI)
	self:_PopulateAllOpenContainers()

	-- overflow
	self:_PopulateOverflow()

	self:_PopulateVacpacExtra()

	if self.deps.onRendered then
		self.deps.onRendered(inv)
	end
end

return InventoryRenderer
