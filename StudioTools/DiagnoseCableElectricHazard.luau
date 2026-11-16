-- Read-only diagnostic. Enumerates every matching cable because Roblox permits
-- duplicate sibling names, making dot paths visually identical in Explorer.

local CollectionService = game:GetService("CollectionService")
local TARGET_NAME = "SM_Prop_Cable_Pile_09"

print("========== WARPED ELECTRIC CABLE DIAGNOSTIC ==========")
print("PlaceId:", game.PlaceId, "GameId:", game.GameId)

local topLevelMatches = {}
for _, child in ipairs(workspace:GetChildren()) do
	if child.Name == TARGET_NAME then
		table.insert(topLevelMatches, child)
	end
end
print("Top-level models named", TARGET_NAME, "=", #topLevelMatches)

local attachments = {}
for modelIndex, topLevel in ipairs(topLevelMatches) do
	print(("Top-level match #%d: %s (%s)"):format(modelIndex, topLevel:GetFullName(), topLevel.ClassName))
	local namedParts = {}
	for _, descendant in ipairs(topLevel:GetDescendants()) do
		if descendant.Name == TARGET_NAME then
			table.insert(namedParts, descendant)
		end
		if descendant:IsA("Attachment") and descendant.Name == "Attachment" then
			table.insert(attachments, descendant)
		end
	end
	print("  descendants with cable name:", #namedParts)
	for partIndex, instance in ipairs(namedParts) do
		print(("    #%d %s (%s)"):format(partIndex, instance:GetFullName(), instance.ClassName))
	end
end

print("Matching Attachments found:", #attachments)
for index, attachment in ipairs(attachments) do
	print(("---- Attachment #%d ----"):format(index))
	print("Path:", attachment:GetFullName())
	print("Parent:", attachment.Parent and attachment.Parent.ClassName or "nil")
	print("Local Position:", attachment.Position)
	print("World Position:", attachment.WorldPosition)

	for _, name in ipairs({
		"CableElectricSparks",
		"CableElectricGlow",
		"CableElectricLight",
		"CableElectricController",
	}) do
		local child = attachment:FindFirstChild(name)
		if not child then
			warn(("Attachment #%d MISSING %s"):format(index, name))
		elseif child:IsA("ParticleEmitter") then
			print(name, child.ClassName, "Enabled=", child.Enabled, "Rate=", child.Rate,
				"Lifetime=", child.Lifetime, "Speed=", child.Speed)
		elseif child:IsA("PointLight") then
			print(name, child.ClassName, "Enabled=", child.Enabled, "Brightness=", child.Brightness)
		elseif child:IsA("BaseScript") then
			print(name, child.ClassName, "Enabled=", child.Enabled,
				"RunContext=", child.RunContext, "SourceLength=", #child.Source)
		else
			print(name, child.ClassName)
		end
	end

	local zone = attachment:FindFirstChild("CableElectricHazardZone")
	local bounds = zone and zone:FindFirstChild("HazardBounds")
	if zone and bounds and bounds:IsA("BasePart") then
		print("Zone tagged:", CollectionService:HasTag(zone, "ZoneFolder"))
		print("Bounds Position:", bounds.Position, "Size:", bounds.Size,
			"Distance:", (bounds.Position - attachment.WorldPosition).Magnitude)
	else
		warn(("Attachment #%d has no complete CableElectricHazardZone"):format(index))
	end
end

print("All tagged ElectricHazard zones:")
for _, folder in ipairs(CollectionService:GetTagged("ZoneFolder")) do
	if folder:GetAttribute("ZoneType") == "ElectricHazard" then
		local bounds = folder:FindFirstChild("HazardBounds", true)
		print("  ", folder:GetFullName(), "Bounds=", bounds and bounds.Position or "MISSING")
	end
end

print("======================================================")
