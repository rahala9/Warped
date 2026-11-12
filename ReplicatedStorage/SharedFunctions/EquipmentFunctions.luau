-- EquipmentFunctions (ModuleScript in ReplicatedStorage)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local equipmentFolder = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Equipment")

local Remotes               = ReplicatedStorage:WaitForChild("SharedRemotes")
local ClothingEquippedEvent = Remotes:WaitForChild("ClothingEquipped")

local EquipmentFunctions = {}

--[[
    Slot configuration.
    boneName          : bone on the player character to attach to
    itemBoneName : bone on the accessory to use as attachment point (Sidekick parts)
    attachBoneOffset  : optional CFrame offset applied on top of the accessory bone (Sidekick parts)
    offset            : fallback CFrame offset if no accessory bone is found (non-Sidekick parts)
]]
local SLOTS = {
	Head = {
		boneName          = "Head",
		itemBoneName = "headAttach",
		attachBoneOffset  = CFrame.new(0, 0, 0),
		offset            = CFrame.new(0, 0, 0),
	},
	Face = {
		boneName          = "Head",
		itemBoneName = "faceAttach",
		attachBoneOffset  = CFrame.new(0, -.4, .55),
		offset            = CFrame.new(0, -.2, .35),
	},
	Back = {
		boneName          = "Spine_03",
		itemBoneName = "backAttach",
		attachBoneOffset  = CFrame.new(0, 0, -0.3),
		offset            = CFrame.new(0, 0, -0.7), --0.3
	},
	Chest = {
		boneName          = "Spine_03",
		itemBoneName = "chestAttach",
		attachBoneOffset  = CFrame.new(0, 0, -0.3),
		offset            = CFrame.new(0, 0, -0.3),
	},
	Legs = {
		boneName          = "Spine_03",
		itemBoneName = "legsAttach",
		attachBoneOffset  = CFrame.new(0, 0, -0.3),
		offset            = CFrame.new(0, 0, -0.3),
	},
	Shoulder = {
		boneName          = "Clavicle_L",
		itemBoneName = "shoulderAttach_L",
		attachBoneOffset  = CFrame.new(0, 0, 0),
		offset            = CFrame.new(0, 0, 0),
	},
	Forearm = {
		boneName          = "Clavicle_L",
		itemBoneName = "forearmAttach_L",
		attachBoneOffset  = CFrame.new(0, 0, 0),
		offset            = CFrame.new(0, 0, 0),
	},
}


--[[
    Searches recursively for a bone by name within a MeshPart or Model.
    Returns the Bone instance or nil.
]]
local function findBone(parent, boneName)
	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA("Bone") and child.Name == boneName then
			return child
		end
	end
	return nil
end

function EquipmentFunctions.GetItem(itemName)
	
	local itemDef = itemsmodule[itemName]

	
	local typeFolder = equipmentFolder:FindFirstChild(itemDef.SubType)
	if not typeFolder then
		warn("EquipmentFunctions: unknown item subtype '" .. itemDef.SubType .. "'")
		return nil
	end
	
	local item = typeFolder:FindFirstChild(itemDef.Model):Clone()
	if not item then
		warn("EquipmentFunctions: unknown item '" .. itemName .. "' in subtype '" .. itemDef.SubType .. "'")
		return nil
	end
	
	return item
	
	
end
--[[
    Equips an accessory to a named slot on a character.
    Supports two attachment methods:
        1. Sidekick parts   : accessory has a named attach Bone (e.g. backAttach)
                              optionally fine-tuned with attachBoneOffset
        2. Plain MeshParts  : no bone structure, uses a CFrame offset Attachment instead

    Parameters:
        character  : Model    - the character model containing the skinned MeshPart
        slotName   : string   - key from the SLOTS table (e.g. "Back", "Head")
        accessory  : Instance - the accessory MeshPart or Model to attach

    Returns:
        RigidConstraint or nil
]]
function EquipmentFunctions.Equip(player, slotName, itemName)
	local character = player.Character
	local slot = SLOTS[slotName]
	if not slot then
		warn("EquipmentFunctions: unknown slot '" .. slotName .. "'")
		return nil
	end
	
	if not itemName then
		warn("EquipmentFunctions: no item name provided for slot '" .. slotName .. "'")
		return nil
	end
	
	if (not itemsmodule[itemName]) then
		warn("EquipmentFunctions: item '" .. itemName .. "' not found in itemsmodule")
		return nil
	end
	
	local item = EquipmentFunctions.GetItem(itemName)
	
	-- Find the target bone on the character
	local characterBone = findBone(character.PrimaryPart, slot.boneName)
	if not characterBone then
		warn("EquipmentFunctions: bone '" .. slot.boneName .. "' not found on character")
		return nil
	end

	-- Auto-unequip anything already in this slot
	EquipmentFunctions.Unequip(player, slotName, itemName)

	item.Parent = character

	-- Build the RigidConstraint
	local rc = Instance.new("RigidConstraint")
	rc.Name = "AccessoryConstraint"
	rc.Attachment0 = characterBone

	-- Method 1: Sidekick accessory with a named attach bone
	local itemBone = slot.itemBoneName
		and findBone(item, slot.itemBoneName)

	if itemBone then
		-- If there's a fine-tuning offset, create an Attachment on top of the bone
		local attachBoneOffset = slot.attachBoneOffset
		if attachBoneOffset and attachBoneOffset ~= CFrame.new() then
			local att = Instance.new("Attachment")
			att.CFrame = attachBoneOffset
			att.Name = "AccessoryAttachment"
			att.Parent = itemBone -- parented to the bone so it inherits its position
			rc.Attachment1 = att
		else
			-- No offset needed, use the bone directly
			rc.Attachment1 = itemBone
		end
		rc.Parent = item
	else
		-- Method 2: Plain MeshPart with no bone structure
		local targetPart = item:IsA("MeshPart") and item
			or item:FindFirstChildWhichIsA("MeshPart")

		if not targetPart then
			warn("EquipmentFunctions: no MeshPart found on accessory for slot '" .. slotName .. "'")
			item:Destroy()
			rc:Destroy()
			return nil
		end

		local att = Instance.new("Attachment")
		att.CFrame = slot.offset
		att.Name = "AccessoryAttachment"
		att.Parent = targetPart

		rc.Attachment1 = att
		rc.Parent = targetPart
	end

	-- Tag so we can find it by slot later
	local tag = Instance.new("StringValue")
	tag.Name = "EquipmentSlot"
	tag.Value = slotName
	tag.Parent = item

	ClothingEquippedEvent:FireClient(player,itemName,true)

	return rc
end

--[[
    Unequips whatever is currently in a slot on the character.

    Parameters:
        character : Model  - the character model
        slotName  : string - the slot to clear
]]
function EquipmentFunctions.Unequip(player, slotName, itemName)
	local character = player.Character
	
	print("EquipmentFunctions: Unequipping slot '" .. slotName .. "'")
	
	ClothingEquippedEvent:FireClient(player,itemName,false)
	
	for _, child in ipairs(character:GetChildren()) do
		local tag = child:FindFirstChild("EquipmentSlot")
		if tag and tag.Value == slotName then
			child:Destroy()
			
			return
		end
	end
	
end

--[[
    Unequips all accessories from a character.

    Parameters:
        character : Model - the character model
]]
function EquipmentFunctions.UnequipAll(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:FindFirstChild("EquipmentSlot") then
			child:Destroy()
		end
	end
end

--[[
    Returns the currently equipped accessory in a slot, or nil.

    Parameters:
        character : Model  - the character model
        slotName  : string - the slot to check
]]
function EquipmentFunctions.getEquipped(character, slotName)
	for _, child in ipairs(character:GetChildren()) do
		local tag = child:FindFirstChild("EquipmentSlot")
		if tag and tag.Value == slotName then
			return child
		end
	end
	return nil
end

--[[
    Returns a table of all currently equipped slot names on a character.

    Parameters:
        character : Model - the character model
]]
function EquipmentFunctions.getEquippedSlots(character)
	local slots = {}
	for _, child in ipairs(character:GetChildren()) do
		local tag = child:FindFirstChild("EquipmentSlot")
		if tag then
			table.insert(slots, tag.Value)
		end
	end
	return slots
end

return EquipmentFunctions