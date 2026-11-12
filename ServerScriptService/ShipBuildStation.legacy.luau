-- ServerScriptService/BuildStation.server.lua

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Registry = require(ServerStorage:WaitForChild("BuildRegistry"))

local Remotes = RS:WaitForChild("SharedRemotes")
local ShipBuildMode = Remotes:WaitForChild("ShipBuildMode")

local ShipsFolder  = RS:WaitForChild("SharedClientAssets"):WaitForChild("ShipBuild")
local ShipTemplate = ShipsFolder:WaitForChild("ShipTemplate")

local ShipBuildStation = workspace:WaitForChild("ShipBuildStation")
local Prompt = ShipBuildStation:FindFirstChildWhichIsA("ProximityPrompt", true)

local ScifiClickSound = RS:WaitForChild("SharedClientAssets"):WaitForChild("Sounds"):WaitForChild("ScifiClick")

local function ensurePrimary(model: Instance, coreName: string?): BasePart?
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart and model.PrimaryPart.Parent == model then
		return model.PrimaryPart
	end
	local core = nil
	if coreName then core = model:FindFirstChild(coreName) end
	core = core or model:FindFirstChild("ShipCore")
	core = core or model:FindFirstChildWhichIsA("BasePart", true)
	if not core then return nil end
	model.PrimaryPart = core
	return core
end

-- Optional: keep track of currently spawned ship to clean up on re-use
local activeShips: {[Player]: Model?} = {}

Players.PlayerRemoving:Connect(function(plr)
	local ship = activeShips[plr]
	if ship and ship.Parent then ship:Destroy() end
	activeShips[plr] = nil
	Registry.Clear(plr)
end)

local cooldown: {[Player]: number} = {}
local COOLDOWN_SEC = 2
local function canUse(plr: Player): boolean
	local now = os.clock()
	local last = cooldown[plr] or 0
	if now - last < COOLDOWN_SEC then return false end
	cooldown[plr] = now
	return true
end

local function spawnShipForPlayer(plr: Player): Model?
	-- destroy prior if any
	local prev = activeShips[plr]
	if prev and prev.Parent then prev:Destroy() end

	local ship = ShipTemplate:Clone()
	ship.Name = ("Ship_%d"):format(plr.UserId)
	ship.Parent = workspace

	local core = ensurePrimary(ship, "ShipCore")
	if not core then
		warn("[BuildStation] No core for ship (", plr.Name, ")")
		ship:Destroy()
		return nil
	end

	-- where to place it; keep deck at Y=0 as a simple default
	ship:SetPrimaryPartCFrame(CFrame.new(0, 1.5, 0))
	core.Anchored = true

	activeShips[plr] = ship
	Registry.SetPlayerShip(plr, ship)
	return ship
end

ShipBuildMode.OnServerEvent:Connect(function(plr)
	local prev = activeShips[plr]
	if (prev and prev.Parent) then prev:Destroy() end
	activeShips[plr] = nil
	Registry.Clear(plr)
end)

if Prompt then
	Prompt.Triggered:Connect(function(plr)
		if not canUse(plr) then return end


		--TODO handle saving ship
		local prev = activeShips[plr]
		if (not prev) then

			local ship = spawnShipForPlayer(plr)
			if not ship then return end

			ShipBuildMode:FireClient(plr, ship)
		else
			if (prev.Parent) then prev:Destroy() end
			activeShips[plr] = nil
			Registry.Clear(plr)
			ShipBuildMode:FireClient(plr)
		end


		if ScifiClickSound then ScifiClickSound:Play() end
	
	end)
else
	warn("[BuildStation] No ProximityPrompt found under BuildStation.")
end
