local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Data.Data)

local ShipFunctions = {}

local function getOwnedShipsTable(player)
	local profile = Data[player]
	if not profile then return nil end
	profile.Data.OwnedShips = profile.Data.OwnedShips or {}
	return profile.Data.OwnedShips
end

function ShipFunctions.OwnsShip(player, shipName)
	if typeof(shipName) ~= "string" or shipName == "" then return false end
	local ownedShips = getOwnedShipsTable(player)
	return ownedShips ~= nil and ownedShips[shipName] ~= nil
end

function ShipFunctions.GetOwnedShips(player)
	local ownedShips = getOwnedShipsTable(player)
	if not ownedShips then return {} end

	local result = {}
	for shipName in pairs(ownedShips) do
		table.insert(result, shipName)
	end
	table.sort(result, function(a, b)
		return a:lower() < b:lower()
	end)
	return result
end

function ShipFunctions.GrantShip(player, shipName, source)
	if typeof(shipName) ~= "string" or shipName == "" then
		return false, "Invalid ship name."
	end
	local ownedShips = getOwnedShipsTable(player)
	if not ownedShips then return false, "Player profile is not loaded." end
	if ownedShips[shipName] then return false, "Player already owns this ship." end

	ownedShips[shipName] = {
		AcquiredAt = os.time(),
		Source = source or "Unknown",
	}
	return true, "Ship granted."
end

function ShipFunctions.RevokeShip(player, shipName)
	local ownedShips = getOwnedShipsTable(player)
	if not ownedShips then return false, "Player profile is not loaded." end
	if not ownedShips[shipName] then return false, "Player does not own this ship." end
	ownedShips[shipName] = nil
	return true, "Ship revoked."
end

return ShipFunctions
