-- ShipWeaponRemoteHandler.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local ShipCombat = require(script.Parent.Parent:WaitForChild("SharedFunctions"):WaitForChild("ShipCombatFunctions"))

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")

local ShipFireWeapon = Remotes:FindFirstChild("ShipFireWeapon")
if not ShipFireWeapon then
	ShipFireWeapon = Instance.new("RemoteEvent")
	ShipFireWeapon.Name = "ShipFireWeapon"
	ShipFireWeapon.Parent = Remotes
end

local function IsPlayerPilotingShip(player, ship)
	if not ship or not ship:IsA("Model") then return false end
	if not player or not player.Character then return false end
	return (StatesFunctions.GetCurrentShip(player) == ship)
end

-- UPDATED SIGNATURE: includes fireTime, shipLinVel, shipAngVel
ShipFireWeapon.OnServerEvent:Connect(function(player, ship, weaponSlot, targetPosition, clientShipCFrame, clientMuzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
	if not player or not player.Character then return end
	if not ship or not ship:IsA("Model") then return end
	if typeof(targetPosition) ~= "Vector3" then return end

	if clientShipCFrame ~= nil and typeof(clientShipCFrame) ~= "CFrame" then
		clientShipCFrame = nil
	end
	if clientMuzzlesLocalCF ~= nil and typeof(clientMuzzlesLocalCF) ~= "table" then
		clientMuzzlesLocalCF = nil
	end

	-- fireTime + velocities optional but must be correct types if present
	if fireTime ~= nil and typeof(fireTime) ~= "number" then
		fireTime = nil
	end
	if shipLinVel ~= nil and typeof(shipLinVel) ~= "Vector3" then
		shipLinVel = nil
	end
	if shipAngVel ~= nil and typeof(shipAngVel) ~= "Vector3" then
		shipAngVel = nil
	end

	if not IsPlayerPilotingShip(player, ship) then return end

	ShipCombat.Fire(
		ship,
		player,
		weaponSlot or "Primary",
		targetPosition,
		clientShipCFrame,
		clientMuzzlesLocalCF,
		fireTime,
		shipLinVel,
		shipAngVel
	)
end)
