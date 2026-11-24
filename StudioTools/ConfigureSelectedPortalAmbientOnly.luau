-- Warped Studio utility: use maximum, uniform ambient lighting on selected portals.
--
-- Usage:
--   1. In Explorer, select the PortalMain BasePart you will look through
--      (for example, Workspace.PortalA.PortalMain).
--   2. Paste/run this script in Studio's Command Bar.
--
-- This deliberately disables the ViewportFrame directional light so the test
-- isolates ambient lighting. SceneLightDirection is removed because it has no
-- visible effect while SceneLightColor is black.

local Selection = game:GetService("Selection")

local configured = 0

for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("BasePart") and selected.Name == "PortalMain" then
		selected:SetAttribute("SceneAmbient", Color3.fromRGB(255, 255, 255))
		selected:SetAttribute("SceneLightColor", Color3.fromRGB(0, 0, 0))
		selected:SetAttribute("SceneLightDirection", nil)
		configured += 1
		print(("Configured ambient-only portal lighting: %s"):format(selected:GetFullName()))
	else
		warn(("Skipped %s; select a PortalMain BasePart."):format(selected:GetFullName()))
	end
end

if configured == 0 then
	warn("No portals configured. Select the PortalMain BasePart you look through and run again.")
else
	print(("Configured %d portal(s) with maximum ambient-only lighting."):format(configured))
end
