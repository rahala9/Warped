-- ServerScriptService/BuilderServer.lua
-- Authoritative placement & welding

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = RS:WaitForChild("SharedRemotes")
local PlacePart = Remotes:WaitForChild("PlacePart")

local PartLibrary = require(RS:WaitForChild("PartLibrary"))
local SnapMath    = require(RS:WaitForChild("SnapMath"))
local SnapRules   = require(RS:WaitForChild("SnapRules"))

local Assets = RS:WaitForChild("SharedClientAssets"):WaitForChild("ShipBuild")

-- --------- helpers ---------

local function ensurePrimary(model, coreName)
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart and model.PrimaryPart.Parent == model then
		return model.PrimaryPart
	end
	local core = (coreName and model:FindFirstChild(coreName)) or model:FindFirstChild("ShipCore")
	core = core or model:FindFirstChildWhichIsA("BasePart", true)
	if not core then return nil end
	model.PrimaryPart = core
	return core
end

-- Find the active ship for this player.
-- Prefers a model with attribute OwnerUserId == player.UserId,
-- falls back to a model named MyShip.
local function getPlayerShip(player)
	-- attribute scan
	for _,inst in ipairs(workspace:GetChildren()) do
		if inst:IsA("Model") and inst:GetAttribute("OwnerUserId") == player.UserId then
			if ensurePrimary(inst, "ShipCore") then
				return inst
			end
		end
	end
	-- fallback
	local fallback = workspace:FindFirstChild("MyShip")
	if fallback and ensurePrimary(fallback, "ShipCore") then
		return fallback
	end
	return nil
end

local function weldToShip(model, ship)
	ensurePrimary(model)
	local root = ship.PrimaryPart
	for _,p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = p
			wc.Part1 = root
			wc.Parent = p
		end
	end
end

local function findShipSocket(ship, socketType, socketId)
	for _,att in ipairs(ship:GetDescendants()) do
		if att:IsA("Attachment") and att:GetAttribute("SocketType") and att:GetAttribute("SocketId") then
			if att:GetAttribute("SocketType") == socketType and att:GetAttribute("SocketId") == socketId then
				return att
			end
		end
	end
	return nil
end

-- --------- main handler ---------

PlacePart.OnServerEvent:Connect(function(player, payload)
	-- Basic sanity
	if typeof(payload) ~= "table" or not payload.PartId then return end

	local def = PartLibrary.Parts[payload.PartId]
	if not def then
		warn("[BuilderServer] Unknown PartId:", payload.PartId)
		return
	end
	local policy = def.SnapPolicy
	if not policy then
		warn("[BuilderServer] No SnapPolicy for part:", payload.PartId)
		return
	end

	-- Ship lookup
	local ship = getPlayerShip(player)
	if not ship then
		warn("[BuilderServer] No ship found for", player.Name)
		return
	end
	local shipRoot = ensurePrimary(ship, "ShipCore")
	if not shipRoot then
		warn("[BuilderServer] Ship has no PrimaryPart:", ship:GetFullName())
		return
	end

	-- Clone asset
	local prefab = Assets:FindFirstChild(payload.PartId,true)
	if not prefab then
		warn("[BuilderServer] Missing asset model in ReplicatedStorage/Assets:", payload.PartId)
		return
	end
	local newModel = prefab:Clone()
	newModel.Parent = workspace
	-- Force PrimaryPart to match the client’s ghost
	if payload.PrimaryName then
		local same = newModel:FindFirstChild(payload.PrimaryName, true)
		if same and same:IsA("BasePart") then
			newModel.PrimaryPart = same
		end
	end
	-- Debug trace
	print(("[BuilderServer] Place %s Mode=%s for %s"):format(payload.PartId, tostring(payload.Mode), player.Name))
	
	print("[SERVER] newModel PrimaryPart (before):", newModel.PrimaryPart and newModel.PrimaryPart:GetFullName())
	print("[SERVER] payload.PrimaryName:", payload.PrimaryName)

	-- after forcing PrimaryPart from payload:
	print("[SERVER] newModel PrimaryPart (after):", newModel.PrimaryPart and newModel.PrimaryPart:GetFullName())
	
	local finalCF

	if policy.Mode == "Grid" and payload.Mode == "Grid" then

		local proposed = payload.ProposedCF
		if typeof(proposed) ~= "CFrame" then
			warn("[BuilderServer] Bad ProposedCF")
			newModel:Destroy(); return
		end
	
		finalCF = proposed
		
	elseif policy.Mode == "Socket" and payload.Mode == "Socket" then
		-- Resolve target socket on ship
		if not payload.Target or not payload.Target.Id then
			warn("[BuilderServer] Missing target info")
			newModel:Destroy(); return
		end
		local tAtt = findShipSocket(ship, policy.TargetSocketType, payload.Target.Id)
		if not tAtt then
			warn("[BuilderServer] Target socket not found", policy.TargetSocketType, payload.Target.Id)
			newModel:Destroy(); return
		end

		-- Find the part's Mount attachment by NAME (not by type)
		local mountName = payload.MountId or policy.MountAttachmentName or "Mount"
		local pAtt = newModel:FindFirstChild(mountName, true)
		if not (pAtt and pAtt:IsA("Attachment")) then
			warn("[BuilderServer] Mount attachment missing:", mountName, "in", payload.PartId)
			newModel:Destroy(); return
		end

		-- Compute raw alignment: mount → target
		local partSocketLocal = partRoot.CFrame:ToObjectSpace(pAtt.WorldCFrame)
		local prelim = SnapMath.computePartCFrame(partRoot.CFrame, partSocketLocal, tAtt.WorldCFrame)

		-- Align outward to target normal if requested
		if policy.AnchorNormalTo == "TargetNormal" then
			prelim = SnapRules.alignOutwardToNormal(prelim, tAtt.WorldCFrame.LookVector)
		end

		-- Orientation (Horizontal/Vertical)
		if policy.OrientationModes and payload.OrientationMode == "Vertical" then
			prelim = prelim * CFrame.Angles(math.rad(90), 0, 0)
		end

		finalCF = SnapRules.quantizeYaw(prelim, policy.RotationStepDeg)

		-- Facing rule (e.g., InteriorWallSide)
		if policy.FaceOppositeOfTargetLook then
			local outName = policy.UseTargetOutwardAttachment or "Outward"
			local outwardAtt = tAtt.Parent:FindFirstChild(outName)
			local targetLook = outwardAtt and outwardAtt.WorldCFrame.LookVector or tAtt.WorldCFrame.LookVector
			local ok = SnapRules.mustFaceOpposite(finalCF, targetLook, 8)
			if not ok then
				warn("[BuilderServer] Facing rule failed for", payload.PartId)
				newModel:Destroy(); return
			end
		end
	else
		warn("[BuilderServer] Mode mismatch. Policy:", policy.Mode, "Payload:", payload.Mode)
		newModel:Destroy(); return
	end

	-- Place & weld
	newModel:SetPrimaryPartCFrame(finalCF)
	weldToShip(newModel, ship)
end)
