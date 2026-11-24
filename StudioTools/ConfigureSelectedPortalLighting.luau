-- Warped Studio utility: apply the Fizzle exterior lighting preset to portals.
--
-- Usage:
--   1. In Explorer, select one or both PortalMain BaseParts (for example,
--      Workspace.PortalA.PortalMain and Workspace.PortalB.PortalMain).
--   2. Paste/run this script in Studio's Command Bar.
--
-- The attributes affect only the scene rendered by the selected portal.
-- SceneLightDirection is intentionally removed so the portal continues to
-- follow the current world's sun direction.

local Selection = game:GetService("Selection")

local FIZZLE_EXTERIOR_AMBIENT = Color3.fromRGB(219, 219, 235)
local FIZZLE_EXTERIOR_LIGHT_COLOR = Color3.fromRGB(255, 244, 225)

local configured = 0

for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("BasePart") and selected.Name == "PortalMain" then
		selected:SetAttribute("SceneAmbient", FIZZLE_EXTERIOR_AMBIENT)
		selected:SetAttribute("SceneLightColor", FIZZLE_EXTERIOR_LIGHT_COLOR)
		selected:SetAttribute("SceneLightDirection", nil)
		configured += 1
		print(("Configured portal lighting: %s"):format(selected:GetFullName()))
	else
		warn(("Skipped %s; select a PortalMain BasePart."):format(selected:GetFullName()))
	end
end

if configured == 0 then
	warn("No portals configured. Select at least one PortalMain BasePart and run again.")
else
	print(("Configured %d portal(s) with the Fizzle exterior lighting preset."):format(configured))
end
