-- ZoneService.lua
-- Adds DetectionMode support:
--   "Center" (default): uses HumanoidRootPart.Position
--   "Ground": raycast down once per player at a throttled rate, then tests hit position
--
-- Updated:
--   - OnPlayerEntered(callback) now passes (player, zonePart)
--   - OnPlayerExited(callback) now passes (player, zonePart)
--   - Tracks the current matching sub-part for each player

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ZoneService = {}

ZoneService.Zone = {}
ZoneService.Zone.__index = ZoneService.Zone

---------------------------------------------------------------------
-- Tuning
---------------------------------------------------------------------
ZoneService.PLATE_CHECK_DT = 0.10 -- 10 Hz for DetectionMode="Ground" zones

---------------------------------------------------------------------
-- Public: Create zone from folder containing multiple BaseParts
---------------------------------------------------------------------
function ZoneService:CreateZoneFromFolder(folder)
	local parts = {}

	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end

	assert(#parts > 0, "No parts found inside folder: " .. folder:GetFullName())

	local zone = setmetatable({
		Folder = folder,
		Parts = parts,

		DetectionMode = "Center",

		TrackedPlayers = {},         -- [player] = true
		PlayerCurrentPart = {},      -- [player] = BasePart

		OnPlayerEnteredCallbacks = {},
		OnPlayerExitedCallbacks = {},

		TrackedItems = {},
		OnItemEnteredCallbacks = {},
		OnItemExitedCallbacks = {},
	}, ZoneService.Zone)

	if ZoneService.DebugVisualizer then
		for _, part in ipairs(parts) do
			local box = Instance.new("Part")
			box.Name = "ZoneDebugBounds"
			box.Anchored = true
			box.CanCollide = false
			box.Size = part.Size
			box.CFrame = part.CFrame
			box.Transparency = 0.7
			box.Color = Color3.new(1, 0, 0)
			box.Parent = workspace:FindFirstChild("Zones") or workspace
		end
	end

	table.insert(ZoneService.ActiveZones, zone)

	return zone
end

---------------------------------------------------------------------
-- Public: Set detection mode
---------------------------------------------------------------------
function ZoneService.Zone:SetDetectionMode(mode: string)
	if mode ~= "Center" and mode ~= "Ground" then
		error(("Invalid DetectionMode '%s' (expected 'Center' or 'Ground')"):format(tostring(mode)))
	end
	self.DetectionMode = mode
end

---------------------------------------------------------------------
-- Public: Bind callbacks
---------------------------------------------------------------------
function ZoneService.Zone:OnPlayerEntered(callback)
	table.insert(self.OnPlayerEnteredCallbacks, callback)
end

function ZoneService.Zone:OnPlayerExited(callback)
	table.insert(self.OnPlayerExitedCallbacks, callback)
end

function ZoneService.Zone:OnItemEntered(callback)
	table.insert(self.OnItemEnteredCallbacks, callback)
end

function ZoneService.Zone:OnItemExited(callback)
	table.insert(self.OnItemExitedCallbacks, callback)
end

---------------------------------------------------------------------
-- Public: Register items to track
---------------------------------------------------------------------
function ZoneService.Zone:TrackItem(item)
	self.TrackedItems[item] = false
end

function ZoneService.Zone:UntrackItem(item)
	self.TrackedItems[item] = nil
end

---------------------------------------------------------------------
-- Internal: Check if position is inside any part of this zone
-- Returns:
--   inside: boolean
--   matchedPart: BasePart?
---------------------------------------------------------------------
function ZoneService.Zone:IsInside(position)
	for i = #self.Parts, 1, -1 do
		local part = self.Parts[i]
		if not part or not part.Parent then
			table.remove(self.Parts, i)
		else
			local cf = part.CFrame
			local size = part.Size * 0.5
			local localPos = cf:PointToObjectSpace(position)

			if math.abs(localPos.X) <= size.X
				and math.abs(localPos.Y) <= size.Y
				and math.abs(localPos.Z) <= size.Z then
				return true, part
			end
		end
	end

	return false, nil
end

function ZoneService.Zone:IsPlayerInZone(player)
	return self.TrackedPlayers[player] == true
end

function ZoneService.Zone:GetPlayerCurrentPart(player)
	return self.PlayerCurrentPart[player]
end

function ZoneService.Zone:Destroy()
	for i = #ZoneService.ActiveZones, 1, -1 do
		if ZoneService.ActiveZones[i] == self then
			table.remove(ZoneService.ActiveZones, i)
			break
		end
	end

	self.TrackedPlayers = {}
	self.PlayerCurrentPart = {}
	self.TrackedItems = {}
	self.OnPlayerEnteredCallbacks = {}
	self.OnPlayerExitedCallbacks = {}
	self.OnItemEnteredCallbacks = {}
	self.OnItemExitedCallbacks = {}
	self.Parts = {}
end

---------------------------------------------------------------------
-- Raycast helpers (Ground mode)
---------------------------------------------------------------------
local function groundPointForCharacter(character, hrp)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	local footY = hrp.Position.Y - (hrp.Size.Y * 0.5 + humanoid.HipHeight)
	local origin = Vector3.new(hrp.Position.X, footY + 0.5, hrp.Position.Z)
	local direction = Vector3.new(0, -1.5, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local hit = workspace:Raycast(origin, direction, params)
	return hit and hit.Position or nil
end

function ZoneService.Zone:IsPartOverlapping(part: BasePart): boolean
	for i = #self.Parts, 1, -1 do
		local zonePart = self.Parts[i]
		if zonePart and zonePart.Parent then
			local cf = zonePart.CFrame
			local half = zonePart.Size * 0.5
			local localPos = cf:PointToObjectSpace(part.Position)
			local ext = part.Size * 0.5

			if math.abs(localPos.X) <= (half.X + ext.X)
				and math.abs(localPos.Y) <= (half.Y + ext.Y)
				and math.abs(localPos.Z) <= (half.Z + ext.Z) then
				return true
			end
		else
			table.remove(self.Parts, i)
		end
	end
	return false
end

---------------------------------------------------------------------
-- Internal: Heartbeat loop for all zones
---------------------------------------------------------------------
ZoneService._lastPlateTick = 0
ZoneService._cachedGroundPos = {}

function ZoneService:_Heartbeat()
	local playerList = Players:GetPlayers()

	local hasGroundZones = false
	for _, zone in ipairs(ZoneService.ActiveZones) do
		if zone.DetectionMode == "Ground" then
			hasGroundZones = true
			break
		end
	end

	local t = os.clock()
	local doPlateTick = false
	if hasGroundZones and (t - ZoneService._lastPlateTick) >= ZoneService.PLATE_CHECK_DT then
		doPlateTick = true
		ZoneService._lastPlateTick = t

		for _, player in ipairs(playerList) do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if hrp then
				ZoneService._cachedGroundPos[player] = groundPointForCharacter(character, hrp)
			else
				ZoneService._cachedGroundPos[player] = nil
			end
		end
	end

	for _, zone in ipairs(ZoneService.ActiveZones) do
		local shouldUpdatePlayers = true
		if zone.DetectionMode == "Ground" then
			shouldUpdatePlayers = doPlateTick
		end

		if shouldUpdatePlayers then
			local insideNow = {}

			for _, player in ipairs(playerList) do
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")

				if hrp then
					local pos
					if zone.DetectionMode == "Ground" then
						pos = ZoneService._cachedGroundPos[player]
					else
						pos = hrp.Position
					end

					if pos then
						local isInside, matchedPart = zone:IsInside(pos)

						if isInside then
							insideNow[player] = true
							zone.PlayerCurrentPart[player] = matchedPart

							if not zone.TrackedPlayers[player] then
								zone.TrackedPlayers[player] = true
								for _, cb in ipairs(zone.OnPlayerEnteredCallbacks) do
									cb(player, matchedPart)
								end
							end
						end
					end
				end
			end

			for trackedPlayer, _ in pairs(zone.TrackedPlayers) do
				if not insideNow[trackedPlayer] then
					local lastPart = zone.PlayerCurrentPart[trackedPlayer]
					zone.TrackedPlayers[trackedPlayer] = nil
					zone.PlayerCurrentPart[trackedPlayer] = nil

					for _, cb in ipairs(zone.OnPlayerExitedCallbacks) do
						cb(trackedPlayer, lastPart)
					end
				end
			end
		end

		for item, wasInside in pairs(zone.TrackedItems) do
			if item and item:IsDescendantOf(workspace) then
				local pos = nil

				if item:IsA("BasePart") then
					pos = item.Position
				elseif item:IsA("Model") then
					if item.PrimaryPart then
						pos = item.PrimaryPart.Position
					else
						zone.TrackedItems[item] = nil
					end
				else
					zone.TrackedItems[item] = nil
				end

				if pos then
					local inside
					if item:IsA("BasePart") then
						inside = zone:IsPartOverlapping(item)
					elseif item:IsA("Model") and item.PrimaryPart then
						inside = zone:IsPartOverlapping(item.PrimaryPart)
					end

					if inside and not wasInside then
						zone.TrackedItems[item] = true
						for _, cb in ipairs(zone.OnItemEnteredCallbacks) do
							cb(item)
						end
					elseif not inside and wasInside then
						zone.TrackedItems[item] = false
						for _, cb in ipairs(zone.OnItemExitedCallbacks) do
							cb(item)
						end
					end
				end
			else
				zone.TrackedItems[item] = nil
			end
		end
	end
end

---------------------------------------------------------------------
-- Bootstrap system
---------------------------------------------------------------------
ZoneService.ActiveZones = {}
ZoneService.DebugVisualizer = false

RunService.Heartbeat:Connect(function()
	ZoneService:_Heartbeat()
end)

return ZoneService