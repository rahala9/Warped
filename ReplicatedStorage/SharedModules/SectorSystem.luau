-- SpatialPartitionSystem.lua
-- Pure math-based spatial partitioning - no physical parts needed!
-- Can be used as ModuleScript or standalone

local SpatialPartitionSystem = {}

--////////////////////////////////////////////////////////////////
-- CONFIGURATION
--////////////////////////////////////////////////////////////////
SpatialPartitionSystem.Config = {
	-- Sector size (can be any size - no 2048 limit!)
	SectorSize = Vector3.new(5000, 5000, 5000),  -- Much larger than physical parts allow

	-- Grid dimensions
	GridSize = Vector3.new(20, 20, 20),  -- 20x20x20 = 8000 sectors

	-- Grid center point
	GridCenter = Vector3.new(0, 0, 0),
}

--////////////////////////////////////////////////////////////////
-- CORE FUNCTIONS
--////////////////////////////////////////////////////////////////

-- Convert world position to sector coordinates
function SpatialPartitionSystem.WorldToSector(position)
	local config = SpatialPartitionSystem.Config

	-- Calculate total grid size
	local totalSize = Vector3.new(
		config.SectorSize.X * config.GridSize.X,
		config.SectorSize.Y * config.GridSize.Y,
		config.SectorSize.Z * config.GridSize.Z
	)

	-- Calculate grid start position (bottom-left-back corner)
	local gridStart = config.GridCenter - (totalSize / 2)

	-- Calculate relative position from grid start
	local relativePos = position - gridStart

	-- Calculate sector coordinates
	local sectorX = math.floor(relativePos.X / config.SectorSize.X)
	local sectorY = math.floor(relativePos.Y / config.SectorSize.Y)
	local sectorZ = math.floor(relativePos.Z / config.SectorSize.Z)

	-- Check if in bounds
	if sectorX < 0 or sectorX >= config.GridSize.X or
		sectorY < 0 or sectorY >= config.GridSize.Y or
		sectorZ < 0 or sectorZ >= config.GridSize.Z then
		return nil  -- Outside grid
	end

	return Vector3.new(sectorX, sectorY, sectorZ)
end

-- Convert sector coordinates to world position (center of sector)
function SpatialPartitionSystem.SectorToWorld(sectorCoords)
	local config = SpatialPartitionSystem.Config

	-- Calculate total grid size
	local totalSize = Vector3.new(
		config.SectorSize.X * config.GridSize.X,
		config.SectorSize.Y * config.GridSize.Y,
		config.SectorSize.Z * config.GridSize.Z
	)

	-- Calculate grid start position
	local gridStart = config.GridCenter - (totalSize / 2)

	-- Calculate world position (center of sector)
	local worldPos = gridStart + Vector3.new(
		(sectorCoords.X + 0.5) * config.SectorSize.X,
		(sectorCoords.Y + 0.5) * config.SectorSize.Y,
		(sectorCoords.Z + 0.5) * config.SectorSize.Z
	)

	return worldPos
end

-- Get all neighboring sectors (26 neighbors in 3D)
function SpatialPartitionSystem.GetNeighboringSectors(sectorCoords, includeCenter)
	local neighbors = {}
	local config = SpatialPartitionSystem.Config

	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				-- Skip center unless requested
				if not includeCenter and dx == 0 and dy == 0 and dz == 0 then
					continue
				end

				local neighborX = sectorCoords.X + dx
				local neighborY = sectorCoords.Y + dy
				local neighborZ = sectorCoords.Z + dz

				-- Check bounds
				if neighborX >= 0 and neighborX < config.GridSize.X and
					neighborY >= 0 and neighborY < config.GridSize.Y and
					neighborZ >= 0 and neighborZ < config.GridSize.Z then
					table.insert(neighbors, Vector3.new(neighborX, neighborY, neighborZ))
				end
			end
		end
	end

	return neighbors
end

-- Format sector coordinates as string
function SpatialPartitionSystem.FormatSector(sectorCoords)
	if not sectorCoords then
		return "Outside Grid"
	end
	return string.format("Sector [%d, %d, %d]", sectorCoords.X, sectorCoords.Y, sectorCoords.Z)
end

-- Get sector bounds (min and max world positions)
function SpatialPartitionSystem.GetSectorBounds(sectorCoords)
	local config = SpatialPartitionSystem.Config

	local totalSize = Vector3.new(
		config.SectorSize.X * config.GridSize.X,
		config.SectorSize.Y * config.GridSize.Y,
		config.SectorSize.Z * config.GridSize.Z
	)

	local gridStart = config.GridCenter - (totalSize / 2)

	local minPos = gridStart + Vector3.new(
		sectorCoords.X * config.SectorSize.X,
		sectorCoords.Y * config.SectorSize.Y,
		sectorCoords.Z * config.SectorSize.Z
	)

	local maxPos = minPos + config.SectorSize

	return minPos, maxPos
end

--////////////////////////////////////////////////////////////////
-- OBJECT TRACKING (for spatial queries)
--////////////////////////////////////////////////////////////////

-- Store objects by sector
local SectorObjects = {}  -- [sectorKey] = {object1, object2, ...}

-- Convert sector coords to string key
local function SectorKey(sectorCoords)
	return string.format("%d_%d_%d", sectorCoords.X, sectorCoords.Y, sectorCoords.Z)
end

-- Register object in sector
function SpatialPartitionSystem.RegisterObject(object, position)
	local sectorCoords = SpatialPartitionSystem.WorldToSector(position)
	if not sectorCoords then return false end

	local key = SectorKey(sectorCoords)

	if not SectorObjects[key] then
		SectorObjects[key] = {}
	end

	-- Store object with its sector
	table.insert(SectorObjects[key], object)

	-- Store sector on object for later removal
	object._SectorKey = key
	object._SectorCoords = sectorCoords

	return true
end

-- Remove object from its sector
function SpatialPartitionSystem.UnregisterObject(object)
	if not object._SectorKey then return false end

	local key = object._SectorKey
	local objects = SectorObjects[key]

	if objects then
		for i, obj in ipairs(objects) do
			if obj == object then
				table.remove(objects, i)
				break
			end
		end
	end

	object._SectorKey = nil
	object._SectorCoords = nil

	return true
end

-- Update object position (move between sectors if needed)
function SpatialPartitionSystem.UpdateObject(object, newPosition)
	local newSectorCoords = SpatialPartitionSystem.WorldToSector(newPosition)

	-- If moved to different sector, update registration
	if object._SectorCoords ~= newSectorCoords then
		SpatialPartitionSystem.UnregisterObject(object)
		if newSectorCoords then
			SpatialPartitionSystem.RegisterObject(object, newPosition)
		end
	end
end

-- Get all objects in a sector
function SpatialPartitionSystem.GetObjectsInSector(sectorCoords)
	local key = SectorKey(sectorCoords)
	return SectorObjects[key] or {}
end

-- Get all objects in sector + neighbors (for queries)
function SpatialPartitionSystem.GetNearbyObjects(position, checkNeighbors)
	local sectorCoords = SpatialPartitionSystem.WorldToSector(position)
	if not sectorCoords then return {} end

	local nearbyObjects = {}

	-- Add objects from current sector
	local currentObjects = SpatialPartitionSystem.GetObjectsInSector(sectorCoords)
	for _, obj in ipairs(currentObjects) do
		table.insert(nearbyObjects, obj)
	end

	-- Optionally check neighboring sectors
	if checkNeighbors then
		local neighbors = SpatialPartitionSystem.GetNeighboringSectors(sectorCoords, false)
		for _, neighborCoords in ipairs(neighbors) do
			local neighborObjects = SpatialPartitionSystem.GetObjectsInSector(neighborCoords)
			for _, obj in ipairs(neighborObjects) do
				table.insert(nearbyObjects, obj)
			end
		end
	end

	return nearbyObjects
end

--////////////////////////////////////////////////////////////////
-- DEBUG VISUALIZATION (optional)
--////////////////////////////////////////////////////////////////

function SpatialPartitionSystem.VisualizeGrid()
	local config = SpatialPartitionSystem.Config

	print("[SpatialPartition] Grid Configuration:")
	print(string.format("  Sector Size: %.0f x %.0f x %.0f studs", 
		config.SectorSize.X, config.SectorSize.Y, config.SectorSize.Z))
	print(string.format("  Grid Dimensions: %d x %d x %d sectors", 
		config.GridSize.X, config.GridSize.Y, config.GridSize.Z))
	print(string.format("  Total Coverage: %.0f x %.0f x %.0f studs",
		config.SectorSize.X * config.GridSize.X,
		config.SectorSize.Y * config.GridSize.Y,
		config.SectorSize.Z * config.GridSize.Z))
	print(string.format("  Total Sectors: %d", 
		config.GridSize.X * config.GridSize.Y * config.GridSize.Z))
end

return SpatialPartitionSystem