local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local PlayerHitEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	

local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage

local function isHazardEnabled(zone, zonePart)
	-- Zone parts are sometimes nested more deeply than the original
	-- zonePart.Parent.Parent layout. Use the closest explicit Enabled state.
	local current = zonePart
	while current do
		local enabled = current:GetAttribute("Enabled")
		if enabled ~= nil then
			return enabled
		end
		current = current.Parent
	end

	current = zone and zone.Folder
	while current do
		local enabled = current:GetAttribute("Enabled")
		if enabled ~= nil then
			return enabled
		end
		current = current.Parent
	end

	-- Preserve the existing default for hazards without an Enabled attribute.
	return true
end

local function getHazardOwner(zone, zonePart)
	local current = zonePart
	while current do
		if current:GetAttribute("Enabled") ~= nil then
			return current
		end
		current = current.Parent
	end

	current = zone and zone.Folder
	while current do
		if current:GetAttribute("Enabled") ~= nil then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function getLaserDeathContext(zone, zonePart)
	local owner = getHazardOwner(zone, zonePart)
	local beamWall = owner and owner:FindFirstChild("LaserBeamWall")
	local planes = {}

	if beamWall then
		for _, child in ipairs(beamWall:GetChildren()) do
			if child:IsA("Model") and child.Name == "LaserBeam" then
				local beamPart = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
				if beamPart then
					table.insert(planes, beamPart.Position.Y)
				end
			end
		end
	end

	if #planes == 0 and zonePart and zonePart:IsA("BasePart") then
		table.insert(planes, zonePart.Position.Y)
	end

	return {
		Effect = "LaserSlice",
		Source = owner and owner.Name or "LaserHazard",
		TemplateKey = owner and owner:GetAttribute("LaserSliceTemplate") or nil,
		ContactPlaneY = zonePart and zonePart:IsA("BasePart") and zonePart.Position.Y or nil,
		SlicePlanes = planes,
	}
end


Zones:OnLoaded("KillZone", function(zone)
	local connection
	connection = zone:OnPlayerEntered(function(enteredPlayer,zonePart)
		print("Player:",enteredPlayer," entered a kill zone. zonePart:",zonePart.Name )	
		PlayerHitEvent:Fire(enteredPlayer,9999999999)
	end)

	
end)

-- Laser doors and traps are data-driven by ZoneType. ZoneKey remains a unique
-- identifier for each zone, but adding another laser hazard no longer requires
-- another name-specific registration in this script.
Zones:OnTypeLoaded("LaserHazard", function(zone, zoneFolder)
	zone:OnPlayerEntered(function(enteredPlayer, zonePart)
		if not isHazardEnabled(zone, zonePart) then return end

		print(
			"Player:",
			enteredPlayer,
			"entered laser hazard:",
			zoneFolder:GetAttribute("ZoneKey") or zoneFolder.Name,
			"zonePart:",
			zonePart.Name
		)
		PlayerHitEvent:Fire(
			enteredPlayer,
			9999999999,
			nil,
			nil,
			getLaserDeathContext(zone, zonePart)
		)
	end)
end)
