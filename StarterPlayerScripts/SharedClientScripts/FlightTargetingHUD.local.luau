-- ShipMinimap.lua
-- LocalScript — place in StarterPlayerScripts or alongside your HUD script
-- Shows nearby ships tagged "EnemyShip" or "PlayerShip" on a circular radar
-- Range scales with sensor power from PowerState
-- Map rotates with ship yaw so "up" = forward
-- Each blip has a vertical bar showing elevation relative to player
-- When a ship is targeted via CycleTarget(), shows targeting data above radar

-- ── Integration flag ──────────────────────────────────────────────────────────
-- Set USE_RIGHT_HUD_MANAGER = true to register the target panel and radar as
-- panels in RightHUDManager instead of floating standalone UI.
-- When true: panels appear in the right-side stack alongside cargo/quests.
-- When false: panels float top-right independently (original behaviour).
local USE_RIGHT_HUD_MANAGER = true

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local PlayerState = require(Player.PlayerScripts
	:WaitForChild("SharedClientScripts")
	:WaitForChild("PlayerStateFunctions"))

local SpaceFlightFunctions = require(Player.PlayerScripts
	:WaitForChild("SharedClientScripts")
	:WaitForChild("SpaceFlightFunctions"))

local RightHUDManager = USE_RIGHT_HUD_MANAGER
	and require(script.Parent:WaitForChild("RightHUDManager"))
	or nil

----------------------------------------------------------------
-- Config
----------------------------------------------------------------
local MAX_RANGE   = SpaceFlightFunctions.ActiveSensorRange
local MAP_RADIUS  = 70
local BLIP_SIZE   = 8
local UPDATE_RATE = 0.05

local PANEL_W = MAP_RADIUS * 2 + 20

local SCAN_TAGS = { "EnemyShip", "PlayerShip" }

local TAG_COLORS = {
	EnemyShip  = Color3.fromRGB(255, 60,  60),
	PlayerShip = Color3.fromRGB(60,  200, 255),
}

local function getScanRange()
	return SpaceFlightFunctions.ActiveSensorRange
end

local function sensorsOnline()
	return SpaceFlightFunctions.ActiveSensorRange > 0
end

local BAR_COLORS = {
	Shield      = Color3.fromRGB(60,  180, 255),
	Hull        = Color3.fromRGB(0,   210, 130),
	Reactor     = Color3.fromRGB(255, 190, 0),
	LifeSupport = Color3.fromRGB(200, 80,  255),
}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function make(cls, props, parent)
	local i = Instance.new(cls)
	for k, v in pairs(props or {}) do i[k] = v end
	if parent then i.Parent = parent end
	return i
end

local function corner(p, r)
	make("UICorner", {CornerRadius = UDim.new(0, r or 6)}, p)
end

local function stroke(p, col, thick)
	make("UIStroke", {
		Color           = col or Color3.fromRGB(0, 80, 130),
		Thickness       = thick or 1,
		Transparency    = 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, p)
end

----------------------------------------------------------------
-- Root ScreenGui (standalone mode only)
----------------------------------------------------------------
local MinimapGui
if not USE_RIGHT_HUD_MANAGER then
	MinimapGui = make("ScreenGui", {
		Name           = "ShipMinimapGui",
		ResetOnSpawn   = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets   = Enum.ScreenInsets.None,
		Enabled        = false,
	}, PlayerGui)
end

-- Returns the parent to attach standalone UI to
local function guiRoot()
	return MinimapGui
end

----------------------------------------------------------------
-- Health bar builder (shared between both modes)
----------------------------------------------------------------
local function makeHealthBar(parent, label, color, order)
	local row = make("Frame", {
		Size                   = UDim2.new(1, 0, 0, 13),
		BackgroundTransparency = 1,
		LayoutOrder            = order,
		ZIndex                 = 4,
	}, parent)

	make("TextLabel", {
		Text                   = label,
		TextSize               = 8,
		Font                   = Enum.Font.GothamBold,
		TextColor3             = color,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 72, 1, 0),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 5,
	}, row)

	local track = make("Frame", {
		Size             = UDim2.new(1, -80, 0, 7),
		Position         = UDim2.new(0, 74, 0.5, -3),
		BackgroundColor3 = Color3.fromRGB(10, 20, 40),
		BorderSizePixel  = 0,
		ZIndex           = 5,
	}, row)
	corner(track, 3)
	stroke(track, Color3.fromRGB(0, 40, 80), 0.5)

	local fill = make("Frame", {
		Size             = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = color,
		BorderSizePixel  = 0,
		ZIndex           = 6,
	}, track)
	corner(fill, 3)

	local valLabel = make("TextLabel", {
		Text                   = "—",
		TextSize               = 7,
		Font                   = Enum.Font.GothamBold,
		TextColor3             = color,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 52, 1, 0),
		Position               = UDim2.new(1, -52, 0, 0),
		TextXAlignment         = Enum.TextXAlignment.Right,
		ZIndex                 = 5,
	}, row)

	return { fill = fill, label = valLabel }
end

----------------------------------------------------------------
-- Radar disc builder (shared between both modes)
-- Returns RadarDisc, RangeLabel, OfflineLabel, PlayerDot
----------------------------------------------------------------
local function buildRadarDisc(parent)
	local disc = make("Frame", {
		Name             = "RadarDisc",
		Size             = UDim2.new(0, MAP_RADIUS*2, 0, MAP_RADIUS*2),
		BackgroundColor3 = Color3.fromRGB(6, 14, 26),
		BackgroundTransparency = 0.1,
		BorderSizePixel  = 0,
		ClipsDescendants = true,
	}, parent)
	corner(disc, MAP_RADIUS)
	stroke(disc, Color3.fromRGB(0, 100, 160), 1)

	for _, frac in ipairs({0.33, 0.66}) do
		local ring = make("Frame", {
			Size                   = UDim2.new(frac, 0, frac, 0),
			Position               = UDim2.new((1-frac)/2, 0, (1-frac)/2, 0),
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
		}, disc)
		corner(ring, MAP_RADIUS)
		stroke(ring, Color3.fromRGB(0, 60, 100), 1)
	end

	for _, def in ipairs({
		{UDim2.new(0.5, -1, 0, 0), UDim2.new(0, 1, 1, 0)},
		{UDim2.new(0, 0, 0.5, -1), UDim2.new(1, 0, 0, 1)},
		}) do
		make("Frame", {
			Position               = def[1],
			Size                   = def[2],
			BackgroundColor3       = Color3.fromRGB(0, 60, 100),
			BackgroundTransparency = 0.6,
			BorderSizePixel        = 0,
		}, disc)
	end

	local playerDot = make("Frame", {
		Size             = UDim2.new(0, 8, 0, 8),
		Position         = UDim2.new(0.5, -4, 0.5, -4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		ZIndex           = 5,
	}, disc)
	corner(playerDot, 4)

	local headingTick = make("Frame", {
		Size             = UDim2.new(0, 6, 0, 6),
		Position         = UDim2.new(0.5, -3, 0, -3),
		BackgroundColor3 = Color3.fromRGB(0, 200, 255),
		BorderSizePixel  = 0,
		ZIndex           = 6,
	}, disc)
	corner(headingTick, 3)

	local offlineLabel = make("TextLabel", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundColor3       = Color3.fromRGB(4, 7, 14),
		BackgroundTransparency = 0.3,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 9,
		TextColor3             = Color3.fromRGB(255, 60, 60),
		Text                   = "SENSORS\nOFFLINE",
		TextXAlignment         = Enum.TextXAlignment.Center,
		Visible                = false,
		ZIndex                 = 10,
	}, disc)

	return disc, playerDot, offlineLabel
end

----------------------------------------------------------------
-- Build targeting content (shared between both modes)
-- Returns { nameLabel, barRefs }
----------------------------------------------------------------
local function buildTargetContent(parent)
	-- Accent line
	make("Frame", {
		Size             = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.fromRGB(255, 60, 60),
		BorderSizePixel  = 0,
		ZIndex           = 3,
	}, parent)

	make("TextLabel", {
		Text                   = "TARGET",
		TextSize               = 9,
		Font                   = Enum.Font.GothamBold,
		TextColor3             = Color3.fromRGB(255, 60, 60),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 16),
		Position               = UDim2.new(0, 8, 0, 4),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 3,
	}, parent)

	local nameLabel = make("TextLabel", {
		Text                   = "—",
		TextSize               = 13,
		Font                   = Enum.Font.GothamBold,
		TextColor3             = Color3.fromRGB(210, 235, 255),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -16, 0, 18),
		Position               = UDim2.new(0, 8, 0, 20),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 3,
	}, parent)

	local barsFrame = make("Frame", {
		Size                   = UDim2.new(1, -16, 0, 64),
		Position               = UDim2.new(0, 8, 0, 42),
		BackgroundTransparency = 1,
		ZIndex                 = 3,
	}, parent)

	make("UIListLayout", {
		SortOrder     = Enum.SortOrder.LayoutOrder,
		Padding       = UDim.new(0, 4),
		FillDirection = Enum.FillDirection.Vertical,
	}, barsFrame)

	local barRefs = {
		Shield      = makeHealthBar(barsFrame, "SHIELD",    BAR_COLORS.Shield,      1),
		Hull        = makeHealthBar(barsFrame, "HULL",      BAR_COLORS.Hull,        2),
		Reactor     = makeHealthBar(barsFrame, "REACTOR",   BAR_COLORS.Reactor,     3),
		LifeSupport = makeHealthBar(barsFrame, "LIFE SUP.", BAR_COLORS.LifeSupport, 4),
	}

	return nameLabel, barRefs
end

----------------------------------------------------------------
-- Live UI references (assigned below based on mode)
----------------------------------------------------------------
local TargetPanel    = nil   -- Frame or nil (standalone only)
local RadarDisc      = nil
local PlayerDot      = nil
local OfflineLabel   = nil
local RangeLabel     = nil
local TargetNameLabel = nil
local barRefs        = nil

local TARGET_PANEL_H = 110
local RADAR_GAP      = 6

----------------------------------------------------------------
-- MODE A: Standalone (USE_RIGHT_HUD_MANAGER = false)
----------------------------------------------------------------
if not USE_RIGHT_HUD_MANAGER then

	-- Target panel
	TargetPanel = make("Frame", {
		Name                   = "TargetPanel",
		Size                   = UDim2.new(0, PANEL_W, 0, TARGET_PANEL_H),
		Position               = UDim2.new(1, -(PANEL_W + 30), 0, 10),
		BackgroundColor3       = Color3.fromRGB(4, 7, 14),
		BackgroundTransparency = 0.2,
		BorderSizePixel        = 0,
		Visible                = false,
		ZIndex                 = 2,
	}, guiRoot())
	corner(TargetPanel, 8)
	stroke(TargetPanel)

	TargetNameLabel, barRefs = buildTargetContent(TargetPanel)

	-- Radar container
	local Container = make("Frame", {
		Name                   = "MinimapContainer",
		Size                   = UDim2.new(0, PANEL_W, 0, MAP_RADIUS*2 + 36),
		Position               = UDim2.new(1, -(PANEL_W + 30), 0, 10),
		BackgroundColor3       = Color3.fromRGB(4, 7, 14),
		BackgroundTransparency = 0.2,
		BorderSizePixel        = 0,
	}, guiRoot())
	corner(Container, 8)
	stroke(Container)

	make("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 18),
		Position               = UDim2.new(0, 0, 0, 4),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 9,
		TextColor3             = Color3.fromRGB(0, 140, 190),
		Text                   = "RADAR",
		TextXAlignment         = Enum.TextXAlignment.Center,
	}, Container)

	-- Disc inside a sub-frame so we can offset it below the title
	local discHolder = make("Frame", {
		Size                   = UDim2.new(0, MAP_RADIUS*2, 0, MAP_RADIUS*2),
		Position               = UDim2.new(0, 10, 0, 22),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
	}, Container)

	RadarDisc, PlayerDot, OfflineLabel = buildRadarDisc(discHolder)
	-- RadarDisc itself fills discHolder
	RadarDisc.Size     = UDim2.new(1, 0, 1, 0)
	RadarDisc.Position = UDim2.new(0, 0, 0, 0)

	RangeLabel = make("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 14),
		Position               = UDim2.new(0, 0, 1, -16),
		BackgroundTransparency = 1,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 8,
		TextColor3             = Color3.fromRGB(0, 80, 120),
		Text                   = "RANGE: " .. MAX_RANGE,
		TextXAlignment         = Enum.TextXAlignment.Center,
	}, Container)

	-- Reposition radar below target panel when visible
	local function updateLayout()
		if TargetPanel.Visible then
			Container.Position = UDim2.new(1, -(PANEL_W + 30), 0,
				10 + TARGET_PANEL_H + RADAR_GAP)
		else
			Container.Position = UDim2.new(1, -(PANEL_W + 30), 0, 10)
		end
	end

	-- Store for use in update loop
	rawset(_G, "__minimapUpdateLayout", updateLayout)

	----------------------------------------------------------------
	-- MODE B: RightHUDManager panels (USE_RIGHT_HUD_MANAGER = true)
	----------------------------------------------------------------
else
	-- ── Targeting panel ───────────────────────────────────────────────────────
	RightHUDManager:RegisterPanel({
		id        = "ShipTarget",
		title     = "TARGET",
		icon      = "◎",
		order     = 1,
		maxHeight = TARGET_PANEL_H,

		onBuild = function(contentFrame)
			TargetNameLabel, barRefs = buildTargetContent(contentFrame)
		end,

		onExpand = function(_)
		end,
	})
	RightHUDManager:SetVisible("ShipTarget", false)

	local radarPanelH = MAP_RADIUS * 2 + 8

	RightHUDManager:RegisterPanel({
		id        = "ShipRadar",
		title     = "RADAR",
		icon      = "◉",
		order     = 2,
		maxHeight = radarPanelH,

		onBuild = function(contentFrame)
			local discHolder = make("Frame", {
				Size                   = UDim2.new(0, MAP_RADIUS*2, 0, MAP_RADIUS*2),
				Position               = UDim2.new(0.5, -MAP_RADIUS, 0, 4),
				BackgroundTransparency = 1,
				BorderSizePixel        = 0,
			}, contentFrame)

			RadarDisc, PlayerDot, OfflineLabel = buildRadarDisc(discHolder)
			RadarDisc.Size     = UDim2.new(1, 0, 1, 0)
			RadarDisc.Position = UDim2.new(0, 0, 0, 0)

			RangeLabel = make("TextLabel", {
				Size                   = UDim2.new(1, 0, 0, 14),
				Position               = UDim2.new(0, 0, 1, -2),
				BackgroundTransparency = 1,
				Font                   = Enum.Font.GothamBold,
				TextSize               = 8,
				TextColor3             = Color3.fromRGB(0, 80, 120),
				Text                   = "RANGE: " .. MAX_RANGE,
				TextXAlignment         = Enum.TextXAlignment.Center,
			}, contentFrame)
		end,

		onExpand = function(_)
		end,
	})
	RightHUDManager:SetVisible("ShipRadar", false)

	-- Auto-expand both panels when flight starts, collapse when it stops
	-- (handled in the render loop below)
end

----------------------------------------------------------------
-- Blip pool (uses RadarDisc — assigned above in either mode)
----------------------------------------------------------------
local blipPool = {}

local function getBlip()
	-- Wait until RadarDisc is ready (RightHUD mode builds it async on first expand)
	if not RadarDisc then return nil end

	for _, b in ipairs(blipPool) do
		if not b.inUse then
			b.inUse         = true
			b.dot.Visible   = true
			b.arrow.Visible = false
			return b
		end
	end

	local dot = make("Frame", {
		Size            = UDim2.new(0, BLIP_SIZE, 0, BLIP_SIZE),
		BorderSizePixel = 0,
		ZIndex          = 4,
		AnchorPoint     = Vector2.new(0.5, 0.5),
	}, RadarDisc)
	corner(dot, BLIP_SIZE / 2)

	local arrow = make("TextLabel", {
		Size                   = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 8,
		ZIndex                 = 5,
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Visible                = false,
	}, RadarDisc)

	local b = { dot = dot, arrow = arrow, inUse = true }
	table.insert(blipPool, b)
	return b
end

local function releaseAllBlips()
	for _, b in ipairs(blipPool) do
		b.inUse         = false
		b.dot.Visible   = false
		b.arrow.Visible = false
	end
end

----------------------------------------------------------------
-- Ship basis / position helpers
----------------------------------------------------------------
local function getShipBasis()
	local char = Player.Character
	if not char then return Vector3.new(0,0,-1), Vector3.new(1,0,0) end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return Vector3.new(0,0,-1), Vector3.new(1,0,0) end

	local weld = hrp:FindFirstChild("PilotShipWeld")
	local cf   = weld and weld:IsA("WeldConstraint") and weld.Part1
		and weld.Part1.CFrame or hrp.CFrame

	local fwd   = Vector3.new(cf.LookVector.X,  0, cf.LookVector.Z)
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if fwd.Magnitude   < 0.01 then fwd   = Vector3.new(0,0,-1) end
	if right.Magnitude < 0.01 then right = Vector3.new(1,0,0)  end
	return fwd.Unit, right.Unit
end

local function worldToRadar(shipPos, shipFwd, shipRight, targetPos, range)
	local rel      = targetPos - shipPos
	local fwdDot   = rel.X * shipFwd.X   + rel.Z * shipFwd.Z
	local rightDot = rel.X * shipRight.X + rel.Z * shipRight.Z
	local mapX     =  (rightDot / range) * MAP_RADIUS
	local mapY     = -(fwdDot   / range) * MAP_RADIUS

	local elevSign
	if rel.Y > 50 then elevSign = 1
	elseif rel.Y < -50 then elevSign = -1
	else elevSign = 0 end

	local dotScale = math.clamp(1 - (math.abs(rel.Y) / range) * 0.7, 0.3, 1.0)
	return mapX, mapY, elevSign, dotScale
end

local function getShipPosition()
	local char = Player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local weld = hrp:FindFirstChild("PilotShipWeld")
	if weld and weld:IsA("WeldConstraint") and weld.Part1 then
		return weld.Part1.Parent and weld.Part1.Parent.PrimaryPart
			and weld.Part1.Parent.PrimaryPart.Position
			or hrp.Position
	end
	return hrp.Position
end

----------------------------------------------------------------
-- Health data reader
-- TODO: replace fallbacks with real attribute names once implemented
----------------------------------------------------------------
local function getTargetHealth(ship)
	if not ship then
		return {
			shield      = {cur=0, max=0},
			hull        = {cur=0, max=0},
			reactor     = {cur=0, max=0},
			lifeSupport = {cur=0, max=0},
		}
	end
	local function attr(name, fallback)
		local v = ship:GetAttribute(name)
		return v ~= nil and v or fallback
	end
	return {
		shield      = {cur=attr("ShieldHealth",      350), max=attr("ShieldHealthMax",      500)},
		hull        = {cur=attr("HullHealth",        280), max=attr("HullHealthMax",        400)},
		reactor     = {cur=attr("ReactorHealth",     190), max=attr("ReactorHealthMax",     200)},
		lifeSupport = {cur=attr("LifeSupportHealth",  80), max=attr("LifeSupportHealthMax", 100)},
	}
end

local function setBar(ref, cur, max)
	if max and max > 0 then
		ref.fill.Size = UDim2.new(math.clamp(cur/max, 0, 1), 0, 1, 0)
		ref.label.Text = math.floor(cur) .. "/" .. math.floor(max)
	else
		ref.fill.Size  = UDim2.new(0, 0, 1, 0)
		ref.label.Text = "—"
	end
end

----------------------------------------------------------------
-- Target panel updater
----------------------------------------------------------------
local function updateTargetPanel()
	local target = SpaceFlightFunctions._currentTarget
	local hasTarget = target and target.Parent ~= nil

	if USE_RIGHT_HUD_MANAGER then
		if hasTarget then
			RightHUDManager:SetVisible("ShipTarget",  true)
			RightHUDManager:SetExpanded("ShipTarget", true)
		else
			RightHUDManager:SetVisible("ShipTarget", false)
		end
	else
		if TargetPanel then
			TargetPanel.Visible = hasTarget
		end
		local updateLayout = rawget(_G, "__minimapUpdateLayout")
		if updateLayout then updateLayout() end
	end

	if hasTarget and TargetNameLabel and barRefs then
		TargetNameLabel.Text = target.Name
		local h = getTargetHealth(target)
		setBar(barRefs.Shield,      h.shield.cur,      h.shield.max)
		setBar(barRefs.Hull,        h.hull.cur,        h.hull.max)
		setBar(barRefs.Reactor,     h.reactor.cur,     h.reactor.max)
		setBar(barRefs.LifeSupport, h.lifeSupport.cur, h.lifeSupport.max)
	end
end

----------------------------------------------------------------
-- Main update loop
----------------------------------------------------------------
local timeSinceUpdate    = 0
local timeSinceTarget    = 0
local TARGET_UPDATE_RATE = 0.1
local wasFlying          = false

RunService.RenderStepped:Connect(function(dt)
	local isFlying = PlayerState.IsFlying

	-- Handle flight start/stop
	if isFlying ~= wasFlying then
		wasFlying = isFlying
		if USE_RIGHT_HUD_MANAGER then
			if isFlying then
				RightHUDManager:SetVisible("ShipRadar",  true)
				RightHUDManager:SetExpanded("ShipRadar", true)
				-- Target stays hidden until a ship is locked
				RightHUDManager:SetVisible("ShipTarget", false)
			else
				RightHUDManager:SetVisible("ShipRadar",  false)
				RightHUDManager:SetVisible("ShipTarget", false)
			end
		else
			if MinimapGui then MinimapGui.Enabled = isFlying end
		end
	end

	if not isFlying then
		releaseAllBlips()
		return
	end

	-- Range label sync
	if MAX_RANGE ~= SpaceFlightFunctions.ActiveSensorRange then
		MAX_RANGE = SpaceFlightFunctions.ActiveSensorRange
		if RangeLabel then
			RangeLabel.Text = "RANGE: " .. MAX_RANGE
		end
	end

	-- Target panel update (10hz)
	timeSinceTarget = timeSinceTarget + dt
	if timeSinceTarget >= TARGET_UPDATE_RATE then
		timeSinceTarget = 0
		updateTargetPanel()
	end

	-- Sensors check
	local online = sensorsOnline()
	if OfflineLabel then OfflineLabel.Visible = not online end
	if PlayerDot    then PlayerDot.Visible    = online      end

	if not online then
		releaseAllBlips()
		return
	end

	-- Radar blips (UPDATE_RATE hz)
	timeSinceUpdate = timeSinceUpdate + dt
	if timeSinceUpdate < UPDATE_RATE then return end
	timeSinceUpdate = 0

	-- RadarDisc may not be built yet if RightHUD panel hasn't been expanded
	if not RadarDisc then return end

	local shipPos = getShipPosition()
	if not shipPos then return end

	local shipFwd, shipRight = getShipBasis()
	local range = getScanRange()

	if RangeLabel then
		RangeLabel.Text = string.format("RANGE: %d", math.floor(range))
	end

	releaseAllBlips()

	for _, tag in ipairs(SCAN_TAGS) do
		local color = TAG_COLORS[tag] or Color3.fromRGB(200, 200, 200)

		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			local char = Player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local weld = hrp:FindFirstChild("PilotShipWeld")
					if weld and weld.Part1 and weld.Part1:IsDescendantOf(inst) then
						continue
					end
				end
			end

			local model = inst:IsA("Model") and inst or inst.Parent
			local targetPos
			if model and model:IsA("Model") and model.PrimaryPart then
				targetPos = model.PrimaryPart.Position
			elseif inst:IsA("BasePart") then
				targetPos = inst.Position
			else
				continue
			end

			local dist = (targetPos - shipPos).Magnitude
			if dist > range then continue end

			local mapX, mapY, elevSign, dotScale =
				worldToRadar(shipPos, shipFwd, shipRight, targetPos, range)

			local blip = getBlip()
			if not blip then continue end

			local dotPx = math.max(4, math.floor(BLIP_SIZE * dotScale))

			local isTarget = SpaceFlightFunctions._currentTarget
				and (model == SpaceFlightFunctions._currentTarget
					or inst == SpaceFlightFunctions._currentTarget)
			local blipColor = isTarget and Color3.fromRGB(255, 255, 255) or color

			blip.dot.Size             = UDim2.new(0, dotPx, 0, dotPx)
			blip.dot.Position         = UDim2.new(0, MAP_RADIUS + mapX, 0, MAP_RADIUS + mapY)
			blip.dot.BackgroundColor3 = blipColor
			blip.dot.Visible          = true

			if elevSign ~= 0 then
				blip.arrow.Text       = elevSign > 0 and "▲" or "▼"
				blip.arrow.TextColor3 = elevSign > 0
					and Color3.fromRGB(100, 200, 255)
					or  Color3.fromRGB(255, 140, 60)
				blip.arrow.Position   = UDim2.new(
					0, MAP_RADIUS + mapX + dotPx/2 + 6,
					0, MAP_RADIUS + mapY
				)
				blip.arrow.Visible = true
			else
				blip.arrow.Visible = false
			end
		end
	end
end)