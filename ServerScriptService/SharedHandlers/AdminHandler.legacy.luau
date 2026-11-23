local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local adminEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Admin")
local Config = require(ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("Config"))
local Items = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local Effects = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects"))
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local ShipFunctions = require(ServerScriptService.Data.DataShipFunctions)
local ShipsFolder = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Ships")

local function isAdmin(player)
	return RunService:IsStudio() or Config.AdminUserIds[player.UserId] == true
end

local function respond(player, ok, message)
	adminEvent:FireClient(player, "AdminResult", {
		Ok = ok,
		Message = message,
	})
end

local function resolveTarget(requestingPlayer, payload)
	if typeof(payload) ~= "table" or typeof(payload.TargetUserId) ~= "number" then
		return requestingPlayer
	end
	return Players:GetPlayerByUserId(payload.TargetUserId)
end

local function teleportPlayerToPlayer(playerA, playerB)
	local rootA = playerA and playerA.Character and playerA.Character:FindFirstChild("HumanoidRootPart")
	local rootB = playerB and playerB.Character and playerB.Character:FindFirstChild("HumanoidRootPart")
	if rootA and rootB then rootA.CFrame = rootB.CFrame + Vector3.new(0, 3, 0) end
end

local function teleportPlayerToLocation(player, location)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and typeof(location) == "Vector3" then root.CFrame = CFrame.new(location) end
end

adminEvent.OnServerEvent:Connect(function(player, action, arg, arg2)
	if not isAdmin(player) then
		warn(string.format("[AdminSystem] Rejected request from %s (%d)", player.Name, player.UserId))
		return
	end

	if action == "AddEffect" or action == "RemoveEffect" then
		local payload = typeof(arg) == "table" and arg or {Name = arg}
		local target = resolveTarget(player, payload)
		local effectName = payload.Name
		if not target then
			respond(player, false, "Target player is no longer available.")
		elseif typeof(effectName) ~= "string" or typeof(Effects[effectName]) ~= "table" then
			respond(player, false, "Unknown effect: " .. tostring(effectName))
		elseif action == "AddEffect" then
			EffectsFunctions.AddEffect(target, effectName, 1, "Admin:" .. player.UserId)
			respond(player, true, string.format("Applied %s to %s.", effectName, target.Name))
		else
			-- Admin removal intentionally clears every source claim for testing.
			EffectsFunctions.RemoveEffect(target, effectName)
			respond(player, true, string.format("Removed %s from %s.", effectName, target.Name))
		end
	elseif action == "AddItem" then
		local payload = typeof(arg) == "table" and arg or {Name = arg, Amount = arg2}
		local target = resolveTarget(player, payload)
		local itemName = payload.Name
		local amount = math.clamp(math.floor(tonumber(payload.Amount) or 1), 1, Config.MaxItemGrant)
		if not target then
			respond(player, false, "Target player is no longer available.")
		elseif typeof(itemName) ~= "string" or typeof(Items[itemName]) ~= "table" then
			respond(player, false, "Unknown item: " .. tostring(itemName))
		else
			local added = InventoryFunctions.AddItem(target, itemName, amount, true)
			respond(
				player,
				added ~= false,
				string.format("Gave %d x %s to %s.", amount, itemName, target.Name)
			)
		end
	elseif action == "GrantShip" or action == "RevokeShip" then
		local payload = typeof(arg) == "table" and arg or {Name = arg}
		local target = resolveTarget(player, payload)
		local shipName = payload.Name
		if not target then
			respond(player, false, "Target player is no longer available.")
		elseif typeof(shipName) ~= "string" or not ShipsFolder:FindFirstChild(shipName) then
			respond(player, false, "Unknown ship: " .. tostring(shipName))
		elseif action == "GrantShip" then
			local ok, message = ShipFunctions.GrantShip(target, shipName, "Admin:" .. player.UserId)
			respond(player, ok, ok and string.format("Granted %s to %s permanently.", shipName, target.Name) or message)
		else
			local ok, message = ShipFunctions.RevokeShip(target, shipName)
			respond(player, ok, ok and string.format("Revoked %s from %s.", shipName, target.Name) or message)
		end
	elseif action == "AddXP" then
		ProgressFunctions.AddXP(player, tonumber(arg) or 0)
	elseif action == "KickPlayer" then
		local targetPlayer = Players:FindFirstChild(arg)
		if targetPlayer then targetPlayer:Kick(tostring(arg2 or "Removed by an administrator.")) end
	elseif action == "TeleportToPlayer" then
		teleportPlayerToPlayer(player, Players:FindFirstChild(arg))
	elseif action == "TeleportToLocation" then
		teleportPlayerToLocation(player, arg)
	end
end)
