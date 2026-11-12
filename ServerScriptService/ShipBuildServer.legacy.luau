-- ServerScriptService/ServerPlacePart.trust.lua
-- Minimal server: place exactly at client preview (ProposedCF).
-- No strict validation; no re-alignment. Just weld to ShipCore.

local RS            = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes     = RS:WaitForChild("SharedRemotes")
local PlacePart   = Remotes:WaitForChild("PlacePart")

local Assets      = RS:WaitForChild("SharedClientAssets"):WaitForChild("ShipBuild")
local PartLibrary = require(RS:WaitForChild("PartLibrary"))
local Registry    = require(ServerStorage:WaitForChild("BuildRegistry")) -- exposes GetPlayerShip(player)

-- -----------------------
-- helpers
-- -----------------------
local function ensurePrimary(model: Instance, coreName: string?): BasePart?
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart and model.PrimaryPart.Parent == model then
		return model.PrimaryPart
	end
	local core = coreName and model:FindFirstChild(coreName) or model:FindFirstChild("ShipCore")
	core = core or model:FindFirstChildWhichIsA("BasePart", true)
	if not core then return nil end
	model.PrimaryPart = core
	return core
end

local function weldModelTo(anchor: BasePart, model: Model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = anchor
			wc.Part1 = d
			wc.Parent = d
		end
	end
end

-- Soft “consume”: bump attributes if we can find the attachment, but never block
local function softBump(att: Attachment?)
	if not att then return end
	local used = tonumber(att:GetAttribute("Connections")) or 0
	local max  = tonumber(att:GetAttribute("MaxConnections")) or 1
	used += 1
	att:SetAttribute("Connections", used)
	if used >= max then
		print("TEST SET OCCUPIED:",att)
		att:SetAttribute("Occupied", true)
		-- (optional) att:Destroy()
	end
end

local function tryFindSocketByPos(ship: Model, partType: string?, pos: Vector3?, tol: number?): Attachment?
	if not ship or not partType or not pos then return nil end
	local eps = tol or 0.05 -- tweak to your grid precision
	local best, bestD
	for _, a in ipairs(ship:GetDescendants()) do
		if a:IsA("Attachment") and a:GetAttribute("PartType") == partType then
			local d = (a.WorldCFrame.Position - pos).Magnitude
			if d <= eps and (not best or d < bestD) then
				best, bestD = a, d
			end
		end
	end
	return best
end

local function tryFindMountById(model: Model, mountId: string?): Attachment?
	if not model or not mountId or mountId == "" then return nil end
	local a = model:FindFirstChild(mountId, true)
	if a and a:IsA("Attachment") then return a end
	return nil
end

-- -----------------------
-- main
-- -----------------------
PlacePart.OnServerEvent:Connect(function(plr, payload)

	--print("TEST BuildServer PlacePart called")
	-- Only handle socket mode; ignore others
	if type(payload) ~= "table" or payload.Mode ~= "Socket" then return end

	-- Ship
	local ship = Registry.GetPlayerShip(plr)
	if not ship then
		warn("[ServerPlacePart] No ship for player", plr.Name)
		return
	end
	local shipRoot = ensurePrimary(ship, "ShipCore")
	if not shipRoot then
		warn("[ServerPlacePart] Ship missing ShipCore for", plr.Name)
		return
	end

	-- Def + prefab
	local partId = payload.PartId
	local def = PartLibrary.Parts[partId]
	if not def then
		warn("[ServerPlacePart] Unknown part:", partId)
		return
	end
	local prefab = Assets:FindFirstChild(partId, true)
	if not prefab then
		warn("[ServerPlacePart] Missing prefab:", partId)
		return
	end

	-- We trust the client's ProposedCF entirely
	local proposed = payload.ProposedCF
	if typeof(proposed) ~= "CFrame" then
		warn("[ServerPlacePart] Missing ProposedCF from client for", partId)
		return
	end

	-- Clone under ship (so attachments/world frames make sense if we reference them)
	local model = prefab:Clone()
	model.Name = partId
	model.Parent = ship
	ensurePrimary(model)

	-- Place exactly where client preview was
	model:PivotTo(proposed)
	weldModelTo(shipRoot, model)

	-- Best-effort: bump mount/socket connection counts if those references exist
	-- (won’t block if not found)
	do
		-- Mount used by the client (if they sent one)
		local mountAtt = tryFindMountById(model, payload.MountId)
		softBump(mountAtt)

		-- Socket used on the ship (if they sent one)
		if payload.Target and payload.Target.Type and payload.Target.Pos then
			local socketAtt = tryFindSocketByPos(ship, payload.Target.Type, payload.Target.Pos, payload.TargetTol or 0.05)
			softBump(socketAtt)
		end
	end

	-- Done
	-- print(("[ServerPlacePart] placed %s at (%.2f, %.2f, %.2f)"):format(
	-- 	partId, proposed.Position.X, proposed.Position.Y, proposed.Position.Z))
end)
