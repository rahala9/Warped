-- Warped: create only the ElectricHazard zone for selected Attachments.
-- This utility never changes particles, lights, or spark controllers.

local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local HAZARD_SIZE = Vector3.new(3, 3, 3)

local function removeOldHazards(attachment: Attachment, zoneKey: string)
	local localZone = attachment:FindFirstChild("CableElectricHazardZone")
	if localZone then localZone:Destroy() end
	for _, tagged in ipairs(CollectionService:GetTagged("ZoneFolder")) do
		if tagged:GetAttribute("ZoneKey") == zoneKey then
			tagged:Destroy()
		end
	end
end

local function createHazard(attachment: Attachment): BasePart
	local parentPart = attachment.Parent
	assert(parentPart and parentPart:IsA("BasePart"),
		("Attachment %s must be directly under a BasePart"):format(attachment:GetFullName()))
	assert(attachment:IsDescendantOf(workspace),
		("Attachment %s must be in Workspace"):format(attachment:GetFullName()))

	local worldPosition = attachment.WorldCFrame.Position
	local zoneKey = attachment:GetFullName() .. ":ElectricHazard"
	removeOldHazards(attachment, zoneKey)

	local folder = Instance.new("Folder")
	folder.Name = "CableElectricHazardZone"
	folder:SetAttribute("ZoneKey", zoneKey)
	folder:SetAttribute("ZoneType", "ElectricHazard")
	folder:SetAttribute("EffectName", "ElectricShock")
	folder:SetAttribute("SourceLevel", 1)
	folder:SetAttribute("RemoveOnExit", true)
	folder:SetAttribute("Enabled", true)
	folder.Parent = attachment

	local bounds = Instance.new("Part")
	bounds.Name = "HazardBounds"
	bounds.Size = HAZARD_SIZE
	bounds.CFrame = CFrame.new(worldPosition)
	bounds.Anchored = true
	bounds.CanCollide = false
	bounds.CanTouch = false
	bounds.CanQuery = false
	bounds.Transparency = 0.75 -- visible while placement is being verified
	bounds.Color = Color3.fromRGB(0, 225, 255)
	bounds.Material = Enum.Material.ForceField
	bounds.Parent = folder
	-- Parenting does not alter BasePart world CFrames, but assign again after
	-- parenting to make the intended order explicit and verifiable.
	bounds.CFrame = CFrame.new(worldPosition)

	CollectionService:AddTag(folder, "ZoneFolder")
	print(("[ElectricHazard] Attachment=%s Bounds=%s Distance=%.6f"):format(
		tostring(worldPosition),
		tostring(bounds.Position),
		(bounds.Position - worldPosition).Magnitude
	))
	return bounds
end

local attachments = {}
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Attachment") then table.insert(attachments, selected) end
end
assert(#attachments > 0, "Select at least one Attachment before running this script")

local bounds = {}
for _, attachment in ipairs(attachments) do
	table.insert(bounds, createHazard(attachment))
end
Selection:Set(bounds)
print(("[ElectricHazard] Complete: %d zone(s)"):format(#bounds))
