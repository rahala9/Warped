-- StarterPlayerScripts/BuilderClient.lua
-- Socket-based builder (position-only preview; no auto-rotation)
-- Mount attachments (on the ghost): SocketType = what I want to attach to (e.g. "Floor")
-- Socket attachments (on the ship/placed): PartType = what I am (e.g. "Floor")

--// Services & Modules
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CurrentPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local ModeManager = require(script.Parent:WaitForChild("ModeManager"))

local Remotes  = RS:WaitForChild("SharedRemotes")
local ShipBuildMode = Remotes:WaitForChild("ShipBuildMode")

local PlacePart      = Remotes:WaitForChild("PlacePart")
local LocalBuildSelectionChangedEvent = Remotes:WaitForChild("LocalBuildSelectionChanged")

local PartLibrary = require(RS:WaitForChild("PartLibrary"))

local player = Players.LocalPlayer
local assets = RS:WaitForChild("SharedClientAssets"):WaitForChild("ShipBuild")
local hologram = assets:WaitForChild("Hologram")

--// Build state
_G.BuildMode = _G.BuildMode or { Enabled = false, Ship = nil }

--// Locals
local shipModel : Model? = nil
local buildConn : RBXScriptConnection? = nil
local inputConns: {RBXScriptConnection} = {}
local ghost : Model? = nil

local currentPartId = "FloorPanel1"
local lastSocketTarget = nil

-- rotation indices (manual, discrete twists)
local rotIdx = _G.rotIdx or { X = 0, Y = 0, Z = 0 }
_G.rotIdx = rotIdx

-- Fixed base pose for ghost + cached local transforms from ghost pivot to each mount
local ghostBaseCF: CFrame? = nil
local mountLocalCF: {[Attachment]: CFrame} = {}

-- Snap latch to prevent flicker
local SnapState = {
	locked = false,
	targetAtt = nil :: Attachment?,
	mountAtt  = nil :: Attachment?,
}
local ACQUIRE_RADIUS = 1 
local RELEASE_RADIUS = 1

-- =====================================================================
-- Utilities / Helpers
-- =====================================================================

local function horizontalDist(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx*dx + dz*dz)
end


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

local function getShip(): Model?
	return shipModel
end

local function destroyGhost()
	if ghost then ghost:Destroy() end
	ghost = nil
	ghostBaseCF = nil
	mountLocalCF = {}
	SnapState.locked = false
	SnapState.targetAtt = nil
	SnapState.mountAtt = nil
end

local function socketAvailable(att: Attachment): boolean
	if att:GetAttribute("Occupied") == true then return false end
	local max  = tonumber(att:GetAttribute("MaxConnections")) or 1
	local used = tonumber(att:GetAttribute("Connections")) or 0
	return used < max
end

local function makeGhost(partId: string)
	destroyGhost()
	local prefab = assets:FindFirstChild(partId, true)
	if not prefab then warn("[BuilderClient] Missing asset:", partId) return end
	ghost = prefab:Clone()
	ghost.Name = "Ghost_" .. partId
	ghost.Parent = workspace

	for _, d in ipairs(ghost:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.Transparency = 0
		end
	end

	local holo = hologram:Clone()
	holo.CFrame = ghost:GetPivot()
	holo.Parent = ghost

	ensurePrimary(ghost)

	-- Cache base pose and each mount's local transform (from ghost pivot)
	ghostBaseCF = ghost:GetPivot()
	mountLocalCF = {}
	for _, a in ipairs(ghost:GetDescendants()) do
		if a:IsA("Attachment") and a:GetAttribute("SocketType") then
			mountLocalCF[a] = ghostBaseCF:ToObjectSpace(a.WorldCFrame)
		end
	end

	-- reset snap latch
	SnapState.locked = false
	SnapState.targetAtt = nil
	SnapState.mountAtt = nil
end

local function setActivePart(partId: string)
	currentPartId = partId
	rotIdx.X, rotIdx.Y, rotIdx.Z = 0, 0, 0
	makeGhost(currentPartId)
end

-- Cursor → deck-plane projection (only to choose nearby socket)
local function getCursorOnDeck(ship: Model, deckYWorld: number)
	local cam = workspace.CurrentCamera
	local mouse = player:GetMouse()
	local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
	local dir = ray.Direction
	if math.abs(dir.Y) < 1e-5 then
		local p = ray.Origin + dir * 100
		return Vector3.new(p.X, deckYWorld, p.Z)
	end
	local t = (deckYWorld - ray.Origin.Y) / dir.Y
	if t < 0 then t = 0 end
	local hitPos = ray.Origin + dir * t
	return Vector3.new(hitPos.X, deckYWorld, hitPos.Z)
end

-- Sockets (placed/ship): PartType = what I am
local function gatherSockets(model: Model)
	local list = {}
	for _, a in ipairs(model:GetDescendants()) do
		if a:IsA("Attachment") then
			local partType = a:GetAttribute("PartType")
			if partType then
				table.insert(list, {
					PartType = partType,
					Id       = a:GetAttribute("SocketUID"), --a:GetAttribute("SocketId"),
					Att      = a,
					Group    = a:GetAttribute("SnapGroup"),
					Priority = a:GetAttribute("SnapPriority"),
				})
			end
		end
	end
	return list
end

local function indexSocketsByPartType(model: Model)
	local idx = {}
	for _, s in ipairs(gatherSockets(model)) do
		idx[s.PartType] = idx[s.PartType] or {}
		table.insert(idx[s.PartType], s)
	end
	return idx
end

-- Mounts (ghost): SocketType = what I want to attach to
local function gatherMounts(ghostModel: Model)
	local list = {}
	for _, a in ipairs(ghostModel:GetDescendants()) do
		if a:IsA("Attachment") then
			local wants = a:GetAttribute("SocketType")
			if wants then
				table.insert(list, {
					WantsPartType = wants,
					MountId       = a:GetAttribute("MountId") or a.Name,
					Att           = a,
					Group         = a:GetAttribute("SnapGroup"),
				})
			end
		end
	end
	return list
end

-- Stronger match:
--  • Right vectors ~opposed (≈180° within faceTol)
--  • The vector from mount → socket aligns with mount.Right (and with -socket.Right)
--  • Distance within [minGap, maxGap]
local function opposedFacingOK(mAtt: Attachment, sAtt: Attachment, opts: table?): boolean
	if mAtt == sAtt then return false end

	local tol = math.cos(math.rad(10)) -- default 10°
	-- Orange arrow = Axis, in world space:
	local v1 = mAtt.WorldSecondaryAxis.Unit
	local v2 = sAtt.WorldSecondaryAxis.Unit
	local dot = v1:Dot(v2)
	return dot <= -tol, dot
end

----------------------------------------------------------------
-- Simple attachment marker (shows the socket position itself)
----------------------------------------------------------------
local __SocketMarker : BasePart? = nil

----------------------------------------------------------------
-- MULTI-SOCKET DEBUG MARKERS
----------------------------------------------------------------
local __SocketMarkers : {[Attachment]: BasePart} = {}

local function clearUnusedSocketMarkers(keep: {[Attachment]: boolean})
	for att, part in pairs(__SocketMarkers) do
		if not keep[att] then
			part:Destroy()
			__SocketMarkers[att] = nil
		end
	end
end

local function showSocketMarkers(atts: {Attachment}?,hasEnough)
	-- No matches: clear everything
	if not atts or #atts == 0 then
		clearUnusedSocketMarkers({})
		return
	end

	local keep: {[Attachment]: boolean} = {}

	for _, att in ipairs(atts) do
		if att and att.Parent then
			keep[att] = true
			local marker = __SocketMarkers[att]
			if not marker then
				marker = Instance.new("Part")
				marker.Name = "SOCKET_DEBUG_MARKER"
				marker.Anchored = true
				marker.CanCollide = false
				marker.Size = Vector3.new(2, 2, 2)
				marker.Material = Enum.Material.Neon
				
				if (hasEnough) then
					marker.Color = Color3.fromRGB(50, 255, 50)
				else
					marker.Color = Color3.fromRGB(255, 50, 50)
				end
				
				
				marker.Parent = workspace
				__SocketMarkers[att] = marker
			end

			local pos = att.WorldCFrame.Position
			marker.CFrame = CFrame.new(pos)
			marker.Transparency = 0
		end
	end

	-- Remove markers for attachments no longer matched
	clearUnusedSocketMarkers(keep)
end

-- Find all ship attachments whose position matches any ghost mount position
-- within 'tolerance', AND whose PartType matches the ghost mount's SocketType.
local function findMatchingSocketsByPositionAndType(ship: Model, ghostModel: Model, tolerance: number?)
	tolerance = tolerance or 0.05
	local tolSq = tolerance * tolerance

	local matches = {}

	-- 1) For each ghost mount (SocketType = what I want to attach to)
	for _, g in ipairs(ghostModel:GetDescendants()) do
		if g:IsA("Attachment") then
			local wantsType = g:GetAttribute("SocketType")
			if wantsType then
				local gPos = g.WorldCFrame.Position

				-- 2) Compare against all ship sockets (PartType = what I am)
				for _, s in ipairs(ship:GetDescendants()) do
					if s:IsA("Attachment") then
						local partType = s:GetAttribute("PartType")

						-- TYPE MATCH: ghost wantsType must equal ship socket's PartType
						if partType == wantsType then
							local sPos = s.WorldCFrame.Position
							local dx = sPos.X - gPos.X
							local dy = sPos.Y - gPos.Y
							local dz = sPos.Z - gPos.Z
							local distSq = dx*dx + dy*dy + dz*dz

							if distSq <= tolSq then
								table.insert(matches, s)
							end
						end
					end
				end
			end
		end
	end

	return matches
end

-- quantize helper
local function q(v, g) return math.floor((v / g) + 0.5) * g end

-- Manual-rotation-only orientation builder (no auto align to socket)
local function buildOrientedBaseCF(shipRootCF: CFrame, policy: table, rot: table): CFrame
	local function axisCfg(p, axis)
		local ar = p and p.AllowedRotation
		local cfg = (ar and ar[axis]) or {}
		if axis == "Y" and cfg.step == nil and typeof(p.RotationStepDeg) == "number" then
			cfg.step = p.RotationStepDeg
		end
		local allow = (cfg.allow ~= false)
		local stepRad = (typeof(cfg.step)=="number" and cfg.step>0) and math.rad(cfg.step) or 0
		local defaultRad = math.rad(cfg.default or 0)
		return allow, stepRad, defaultRad
	end

	local allowX, stepX, defX = axisCfg(policy, "X")
	local allowY, stepY, defY = axisCfg(policy, "Y")
	local allowZ, stepZ, defZ = axisCfg(policy, "Z")

	local rx = defX; if allowX and stepX > 0 then rx += (rot.X or 0) * stepX end
	local ry = defY; if allowY and stepY > 0 then ry += (rot.Y or 0) * stepY end
	local rz = defZ; if allowZ and stepZ > 0 then rz += (rot.Z or 0) * stepZ end

	return shipRootCF * CFrame.Angles(rx, 0, 0) * CFrame.Angles(0, ry, 0) * CFrame.Angles(0, 0, rz)
end

-- Position-only snap: keep orientation from baseCF; move so mount lands on socket position
local function translateMountToSocket(baseCF: CFrame, mountLocal: CFrame, socketWorldPos: Vector3): CFrame
	local mountWorld = baseCF * mountLocal
	local offset = socketWorldPos - mountWorld.Position
	return CFrame.fromMatrix(
		(baseCF.Position + offset),
		baseCF.RightVector,
		baseCF.UpVector
	)
end

-- --- Socket highlight (SelectionBox around the socket's parent part) ---
--local __Hi = { box = nil }
--local function hiShow(att: Attachment?)
--	if not att then
--		if __Hi.box then __Hi.box.Visible = false; __Hi.box.Adornee = nil end
--		return
--	end
--	if not __Hi.box then
--		local sb = Instance.new("SelectionBox")
--		sb.LineThickness = 0.05
--		sb.Transparency  = 0.6
--		sb.Color3        = Color3.fromRGB(0, 255, 120)
--		sb.Parent        = workspace
--		__Hi.box = sb
--	end
--	local host = att.Parent
--	if host and host:IsA("BasePart") then
--		__Hi.box.Adornee = host
--		__Hi.box.Visible = true
--	else
--		__Hi.box.Visible = false
--		__Hi.box.Adornee = nil
--	end
--end

local defaultGridStep = 1

-- Render: grid-first movement; highlight sockets near cursor; snap visually ONLY when Alt is held.
local function renderStep()
	if not _G.BuildMode.Enabled then return end
	local ship = getShip(); if not ship then return end
	local shipRoot = ensurePrimary(ship, "ShipCore"); if not shipRoot then return end
	if not ghost then makeGhost(currentPartId) end

	-- Safe deck height so hover still works if policy is missing
	local shipRootCF   = shipRoot.CFrame
	local safeDeckAtt  = ship:FindFirstChild("Deck0", true)
	local safeDeckY    = safeDeckAtt and safeDeckAtt.WorldCFrame.Position.Y or shipRoot.Position.Y

	-- Part / policy (hover fallback on problems)
	local def = PartLibrary.Parts[currentPartId]
	if not def then
		local worldHint = getCursorOnDeck(ship, safeDeckY)
		local hoverCF = CFrame.new(worldHint)
		ghost:PivotTo(hoverCF); lastSocketTarget = nil; --hiShow(nil)
		local holo = ghost:FindFirstChild("Hologram"); if holo and holo:IsA("BasePart") then holo.CFrame = hoverCF end
		return
	end
	local policy = def.SnapPolicy
	if not policy or policy.Mode ~= "Socket" then
		-- Grid-only hover if policy missing/wrong
		local worldHint = getCursorOnDeck(ship, safeDeckY)
		local hoverCF = CFrame.new(worldHint)
		ghost:PivotTo(hoverCF); lastSocketTarget = nil; --hiShow(nil)
		local holo = ghost:FindFirstChild("Hologram"); if holo and holo:IsA("BasePart") then holo.CFrame = hoverCF end
		return
	end

	-- --- GRID-FIRST movement (always smooth) ---
	local deckAtt     = ship:FindFirstChild(policy.DeckRef or "Deck0", true)
	local deckY       = deckAtt and deckAtt.WorldCFrame.Position.Y or shipRoot.Position.Y
	local mouseOnDeck = getCursorOnDeck(ship, deckY)

	-- Phase-aware quantize (keeps floors/walls aligned to the same lattice)
	local function qPhase(u, step, phase)
		return math.floor(((u - phase) / step) + 0.5) * step + phase
	end

	-- Flexible per-part steps/phases (defaults keep your current behavior)
	local stepX = (policy.GridStepX) or (policy.GridSize and policy.GridSize.X) or (tonumber(policy.GridSize) or defaultGridStep)
	local stepZ = (policy.GridStepZ) or (policy.GridSize and policy.GridSize.Z) or stepX
	local phaseX = policy.GridPhaseX or 0
	local phaseZ = policy.GridPhaseZ or 0

	-- Snap in ship-local, then convert back to world
	local mouseLocal = shipRootCF:PointToObjectSpace(mouseOnDeck)
	local snappedLocal = Vector3.new(
		qPhase(mouseLocal.X, stepX, phaseX),
		0,
		qPhase(mouseLocal.Z, stepZ, phaseZ)
	)
	local snappedWorld = shipRootCF:PointToWorldSpace(snappedLocal)

	-- Build a CF at that snapped position using your existing grid-basis convention
	local virtualCF = CFrame.fromMatrix(
		Vector3.new(snappedWorld.X, deckY, snappedWorld.Z),
		shipRootCF:VectorToWorldSpace(Vector3.new(0, 1, 0)),  -- Right/orange = +Y(local)
		shipRootCF:VectorToWorldSpace(Vector3.new(0, 0, 1))   -- Up/yellow   = +Z(local)
	)

	-- Keep user's manual orientation
	local orientedBase = buildOrientedBaseCF(shipRootCF, policy, rotIdx)

	-- Place ghost at grid position, then apply HeightFromDeck as a vertical center offset
	local baseCF = CFrame.fromMatrix(virtualCF.Position, orientedBase.RightVector, orientedBase.UpVector)

	-- >>> HeightFromDeck support (e.g., walls): treat as center-of-pivot lift above deck
	local hfd = tonumber(policy.HeightFromDeck) or 0
	if hfd ~= 0 then
		local p = baseCF.Position + Vector3.new(0, hfd, 0)
		baseCF = CFrame.fromMatrix(p, orientedBase.RightVector, orientedBase.UpVector)
	end

	ghost:PivotTo(baseCF)
	local holo = ghost:FindFirstChild("Hologram"); if holo and holo:IsA("BasePart") then holo.CFrame = baseCF end

	local matches = findMatchingSocketsByPositionAndType(ship, ghost, 0.05)

	-- How many sockets this part "needs" (1 = normal tile, 2 = wall spanning two tiles, etc.)
	local numMatchesNeeded = 1
	if def.SnapPolicy and def.SnapPolicy.NumberConnectionsNeeded then
		numMatchesNeeded = def.SnapPolicy.NumberConnectionsNeeded
	end
	
	if #matches > 0 then
		for i, att in ipairs(matches) do
			print(
				("  [%d] %s  pos=(%.2f, %.2f, %.2f) partType=%s"):format(
					i,
					att:GetFullName(),
					att.WorldCFrame.Position.X,
					att.WorldCFrame.Position.Y,
					att.WorldCFrame.Position.Z,
					tostring(att:GetAttribute("PartType"))
				)
			)
		end

		local hasEnough = (#matches >= numMatchesNeeded)

		-- Green if enough, red if not (assuming showSocketMarkers(matches, isGood))
		showSocketMarkers(matches, hasEnough)

		if hasEnough then
			
			-- Use the first matched socket as the primary target for payload.
			-- Server can also infer other sockets by position if needed.
			local primary = matches[1]
			
			lastSocketTarget = {
				Type     = primary:GetAttribute("PartType"),
				Id       = primary.Name,                         -- optional; may be ignored server-side
				MountId  = nil,                                  -- you can wire this later if you want
				AttPos   = primary.WorldCFrame.Position,         -- for positional lookup on server
				Proposed = baseCF,                               -- current ghost pose
				Virtual  = false,
			}
		else
			-- Not enough sockets to be valid placement
			lastSocketTarget = nil
		end
	else
		showSocketMarkers(nil)
		lastSocketTarget = nil
	end

	-- --- VISUAL SNAP ONLY WHEN ALT IS HELD ---
	--local altHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
	--if altHeld and pair and pair.Target and pair.Target.Att and pair.Mount and pair.Mount.Att then
	--	-- position-only snap: keep orientation, translate mount to socket center
	--	local mLocal = mountLocalCF[pair.Mount.Att]
	--	if not mLocal then
	--		mLocal = (ghostBaseCF or ghost:GetPivot()):ToObjectSpace(pair.Mount.Att.WorldCFrame)
	--		mountLocalCF[pair.Mount.Att] = mLocal
	--	end
	--	local snappedCF = translateMountToSocket(orientedBase, mLocal, pair.Target.Att.WorldCFrame.Position)

	--	-- Preserve HeightFromDeck after translation (in case mount pivot isn't centered)
	--	if hfd ~= 0 then
	--		snappedCF = CFrame.fromMatrix(
	--			snappedCF.Position + Vector3.new(0, hfd, 0),
	--			snappedCF.RightVector,
	--			snappedCF.UpVector
	--		)
	--	end

	--	ghost:PivotTo(snappedCF)
	--	if holo and holo:IsA("BasePart") then holo.CFrame = snappedCF end

	--	-- keep lastSocketTarget up to date with the snapped preview transform (nice for server logging, too)
	--	lastSocketTarget.Proposed = snappedCF
	--end
	-- If Alt not held: we stay on grid (baseCF) and only highlight.
end




-- =====================================================================
-- Inputs
-- =====================================================================

local function bindInputs()
	table.insert(inputConns, UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or not _G.BuildMode.Enabled then return end

		-- Manual rotations only
		if input.KeyCode == Enum.KeyCode.R then
			local def = PartLibrary.Parts[currentPartId]
			local pol = def and def.SnapPolicy
			if pol and pol.Mode == "Socket" then
				local stepDeg = (pol.AllowedRotation and pol.AllowedRotation.Y and pol.AllowedRotation.Y.step) or pol.RotationStepDeg or 90
				local steps = math.max(1, math.floor(360 / stepDeg + 0.5))
				rotIdx.Y = ((rotIdx.Y or 0) + 1) % steps
			end

		elseif input.KeyCode == Enum.KeyCode.T then
			local def = PartLibrary.Parts[currentPartId]
			local pol = def and def.SnapPolicy
			if pol and pol.Mode == "Socket" then
				local ar = pol.AllowedRotation and pol.AllowedRotation.X
				local stepDeg = ar and ar.step
				if ar and ar.allow ~= false and typeof(stepDeg)=="number" and stepDeg>0 then
					local steps = math.max(1, math.floor(360 / stepDeg + 0.5))
					rotIdx.X = ((rotIdx.X or 0) + 1) % steps
				end
			end

		elseif input.KeyCode == Enum.KeyCode.G then
			local def = PartLibrary.Parts[currentPartId]
			local pol = def and def.SnapPolicy
			if pol and pol.Mode == "Socket" then
				local ar = pol.AllowedRotation and pol.AllowedRotation.Z
				local stepDeg = ar and ar.step
				if ar and ar.allow ~= false and typeof(stepDeg)=="number" and stepDeg>0 then
					local steps = math.max(1, math.floor(360 / stepDeg + 0.5))
					rotIdx.Z = ((rotIdx.Z or 0) + 1) % steps
				end
			end

		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Place
			local ship = getShip()
			if not ship or not ghost then return end

			local def = PartLibrary.Parts[currentPartId]; if not def then return end
			local pol = def.SnapPolicy; if not pol or pol.Mode ~= "Socket" then return end
			if not lastSocketTarget then return end

			if lastSocketTarget.Virtual then
				PlacePart:FireServer({
					Mode       = "Socket",
					PartId     = currentPartId,
					Virtual    = true,
					TargetType = lastSocketTarget.Type,
					GridSize   = lastSocketTarget.GridSize,
					DeckRef    = pol.DeckRef or "Deck0",
					ProposedCF = ghost:GetPivot(), -- server will re-translate/consume
					RotIdx     = rotIdx,
				})
			else
				PlacePart:FireServer({
					Mode      = "Socket",
					PartId    = currentPartId,
					Target    = { Type = lastSocketTarget.Type, Pos = lastSocketTarget.AttPos },
					MountId   = lastSocketTarget.MountId,
					ProposedCF= ghost:GetPivot(), -- server aligns/consumes
					RotIdx    = rotIdx,
				})
			end
		end
	end))
end

local function unbindInputs()
	for _,c in ipairs(inputConns) do pcall(function() c:Disconnect() end) end
	inputConns = {}
end

-- =====================================================================
-- Build mode wiring
-- =====================================================================

local function startBuildMode(ship: Model)
	shipModel = ship
	_G.BuildMode.Enabled = true
	_G.BuildMode.Ship = shipModel
	ensurePrimary(shipModel, "ShipCore")
	if not ghost then makeGhost(currentPartId) end
	if buildConn then buildConn:Disconnect() end
	buildConn = RunService.RenderStepped:Connect(renderStep)
	bindInputs()
end

local function stopBuildMode()
	_G.BuildMode.Enabled = false
	_G.BuildMode.Ship = nil
	shipModel = nil
	if buildConn then buildConn:Disconnect() end
	buildConn = nil
	unbindInputs()
	destroyGhost()
end

ShipBuildMode.OnClientEvent:Connect(function(shipInstance: Model)
	if shipInstance then
		startBuildMode(shipInstance)	
	else
		stopBuildMode()
	end
	
	ModeManager:SetMode(ModeManager.Modes.ShipBuild)
end)

ModeManager.ModeChanged:Connect(function()
	if ModeManager.CurrentMode ~= ModeManager.Modes.ShipBuild then
		stopBuildMode()
		ShipBuildMode:FireServer()
	end
end)


LocalBuildSelectionChangedEvent.Event:Connect(function(payload)
	if payload and payload.modelName then
		setActivePart(payload.modelName)
	end
end)

-- Optional local test
-- task.delay(1, function()
-- 	if _G.BuildMode.Enabled then return end
-- 	local fallback = workspace:FindFirstChild("MyShip")
-- 	if fallback and fallback:IsA("Model") then
-- 		startBuildMode(fallback)
-- 	end
-- end)
