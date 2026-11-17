-- Warped: configure selected Folder(s) as data-driven status-effect zones.
--
-- Before running, set the values below. Each selected Folder must contain at
-- least one BasePart that defines its bounds. This utility does not move,
-- resize, create, or search for parts.

local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local EFFECT_NAME = "Stink"
local SOURCE_LEVEL = 1
local REMOVE_ON_EXIT = false
local DETECTION_MODE = "Center" -- "Center" or "Ground"

local folders = {}
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Folder") then
		table.insert(folders, selected)
	end
end
assert(#folders > 0, "Select at least one Folder containing zone bounds parts")

for _, folder in ipairs(folders) do
	local hasBounds = false
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			hasBounds = true
			break
		end
	end
	assert(hasBounds, ("%s must contain at least one BasePart"):format(folder:GetFullName()))

	local existingKey = folder:GetAttribute("ZoneKey")
	if typeof(existingKey) ~= "string" or existingKey == "" then
		folder:SetAttribute("ZoneKey", ("StatusEffect:%s:%s"):format(EFFECT_NAME, folder.Name))
	end
	folder:SetAttribute("ZoneType", "StatusEffect")
	folder:SetAttribute("EffectName", EFFECT_NAME)
	folder:SetAttribute("SourceLevel", SOURCE_LEVEL)
	folder:SetAttribute("RemoveOnExit", REMOVE_ON_EXIT)
	folder:SetAttribute("DetectionMode", DETECTION_MODE)
	folder:SetAttribute("Enabled", true)
	CollectionService:AddTag(folder, "ZoneFolder")

	print("[StatusEffectZoneSystem] Configured", folder:GetFullName(), folder:GetAttribute("ZoneKey"))
end
