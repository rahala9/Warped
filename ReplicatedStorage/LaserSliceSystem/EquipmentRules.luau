local EquipmentRules = {}

export type Behavior = "Slice" | "FollowAttachment" | "Drop" | "Detach" | "Hide"

local VALID_BEHAVIORS = {
	Slice = true,
	FollowAttachment = true,
	Drop = true,
	Detach = true,
	Hide = true,
}

local function explicitBehavior(instance: Instance): Behavior?
	local current = instance
	while current do
		local value = current:GetAttribute("LaserDeathBehavior")
		if typeof(value) == "string" and VALID_BEHAVIORS[value] then
			return value :: Behavior
		end
		current = current.Parent
	end
	return nil
end

function EquipmentRules.GetBehavior(instance: Instance): Behavior
	local explicit = explicitBehavior(instance)
	if explicit then
		return explicit
	end

	if instance:FindFirstAncestorOfClass("Tool") then
		return "Drop"
	end

	if instance:FindFirstAncestorOfClass("Accessory") then
		return "FollowAttachment"
	end

	return "Slice"
end

return EquipmentRules
