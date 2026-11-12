--[[
    DockManagerUI.lua
    Place in: StarterPlayerScripts  (as a ModuleScript, sibling of DockManager_Client)

    Builds and manages all DockManager UI screens using only Roblox UI instances.
    Dark sci-fi aesthetic: deep navy/black backgrounds, cyan accents, mono fonts.
]]

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local DockManagerUI = {}

-- ── Constants ─────────────────────────────────────────────────────────────────
local COLORS = {
	BG          = Color3.fromRGB(8,  14,  26),
	BG2         = Color3.fromRGB(14, 22,  40),
	PANEL       = Color3.fromRGB(18, 30,  55),
	BORDER      = Color3.fromRGB(0,  200, 255),
	BORDER_DIM  = Color3.fromRGB(0,  80,  120),
	ACCENT      = Color3.fromRGB(0,  220, 255),
	ACCENT2     = Color3.fromRGB(255, 160, 0),
	TEXT        = Color3.fromRGB(210, 235, 255),
	TEXT_DIM    = Color3.fromRGB(110, 150, 190),
	SUCCESS     = Color3.fromRGB(0,  220, 130),
	ERROR       = Color3.fromRGB(255, 80,  80),
	BTN_SPAWN   = Color3.fromRGB(0,  160, 220),
	-- Rarity colors
	RARITY_COMMON    = Color3.fromRGB(180, 180, 180),
	RARITY_UNCOMMON  = Color3.fromRGB(80,  200, 100),
	RARITY_RARE      = Color3.fromRGB(60,  140, 255),
	RARITY_EPIC      = Color3.fromRGB(180, 80,  255),
	RARITY_LEGENDARY = Color3.fromRGB(255, 160, 0),
	BTN_DESPAWN = Color3.fromRGB(200, 60,  60),
	BTN_ACCEPT  = Color3.fromRGB(0,  180, 100),
	BTN_CLOSE   = Color3.fromRGB(40,  55,  80),
	DIST_LOCAL  = Color3.fromRGB(0,  200, 130),
	DIST_NEAR   = Color3.fromRGB(255, 190, 0),
	DIST_FAR    = Color3.fromRGB(255, 80,  80),
	JOB_HOVER   = Color3.fromRGB(22,  40,  70),
	JOB_SEL     = Color3.fromRGB(0,   50,  90),
}

local FONT_HEADER = Enum.Font.GothamBold
local FONT_BODY   = Enum.Font.Gotham
local FONT_MONO   = Enum.Font.Code

local DIST_COLOR = {
	Local   = COLORS.DIST_LOCAL,
	Nearby  = COLORS.DIST_NEAR,
	Distant = COLORS.DIST_FAR,
}

local RARITY_COLOR = {
	Common    = COLORS.RARITY_COMMON,
	Uncommon  = COLORS.RARITY_UNCOMMON,
	Rare      = COLORS.RARITY_RARE,
	Epic      = COLORS.RARITY_EPIC,
	Legendary = COLORS.RARITY_LEGENDARY,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function makePadding(parent, top, bottom, left, right)
	local p = make("UIPadding", {}, parent)
	p.PaddingTop    = UDim.new(0, top    or 0)
	p.PaddingBottom = UDim.new(0, bottom or 0)
	p.PaddingLeft   = UDim.new(0, left   or 0)
	p.PaddingRight  = UDim.new(0, right  or 0)
	return p
end

local function makeCorner(parent, radius)
	return make("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function makeStroke(parent, color, thickness)
	return make("UIStroke", {
		Color = color or COLORS.BORDER_DIM,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function makeLabel(text, fontSize, font, color, parent)
	return make("TextLabel", {
		Text = text,
		TextSize = fontSize or 14,
		Font = font or FONT_BODY,
		TextColor3 = color or COLORS.TEXT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, fontSize and fontSize + 6 or 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}, parent)
end

local function makeButton(text, bgColor, textColor, parent)
	local btn = make("TextButton", {
		Text = text,
		TextSize = 14,
		Font = FONT_HEADER,
		TextColor3 = textColor or Color3.new(1,1,1),
		BackgroundColor3 = bgColor or COLORS.BTN_SPAWN,
		Size = UDim2.new(1, 0, 0, 38),
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, parent)
	makeCorner(btn, 6)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.15)
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = bgColor
		}):Play()
	end)

	return btn
end

local function tweenIn(frame)
	frame.Position = UDim2.new(0.5, -frame.AbsoluteSize.X/2, 0.4, 0)
	frame.GroupTransparency = 1
	TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -frame.AbsoluteSize.X/2, 0.5, -frame.AbsoluteSize.Y/2),
		GroupTransparency = 0,
	}):Play()
end

-- ── Root ScreenGui ────────────────────────────────────────────────────────────
local function ensureGui()
	local sg = PlayerGui:FindFirstChild("DockManagerGui")
	if not sg then
		sg = make("ScreenGui", {
			Name = "DockManagerGui",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, PlayerGui)
	end
	return sg
end

local function clearGui()
	local sg = PlayerGui:FindFirstChild("DockManagerGui")
	if sg then sg:ClearAllChildren() end
end

-- ── Notification Toast ────────────────────────────────────────────────────────
function DockManagerUI:ShowNotification(message, success)
	local sg = ensureGui()

	local accentColor = success and COLORS.SUCCESS or COLORS.ERROR

	local toast = make("Frame", {
		Name = "Toast",
		Size = UDim2.new(0, 340, 0, 52),
		Position = UDim2.new(0.5, -170, 0, -60),
		BackgroundColor3 = COLORS.BG2,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, sg)
	makeCorner(toast, 8)
	makeStroke(toast, accentColor, 1.5)

	-- Accent bar on left edge
	make("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		ZIndex = 21,
	}, toast)
	makeCorner(toast, 8)

	make("TextLabel", {
		Text = message,
		TextSize = 14,
		Font = FONT_HEADER,
		TextColor3 = COLORS.TEXT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 22,
	}, toast)

	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -170, 0, 20),
	}):Play()

	task.delay(2.8, function()
		if toast and toast.Parent then
			TweenService:Create(toast, TweenInfo.new(0.3), {
				Position = UDim2.new(0.5, -170, 0, -60),
			}):Play()
			task.delay(0.35, function()
				if toast and toast.Parent then toast:Destroy() end
			end)
		end
	end)
end

function DockManagerUI:ShowError(msg)
	DockManagerUI:ShowNotification(msg, false)
end

function DockManagerUI:Close()
	clearGui()
end

-- ── Backdrop ──────────────────────────────────────────────────────────────────
local function makeBackdrop(sg, onClose)
	local bd = make("TextButton", {
		Name = "Backdrop",
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Text = "",
		ZIndex = 1,
	}, sg)
	bd.Activated:Connect(onClose)
	return bd
end

-- ── Panel Frame ───────────────────────────────────────────────────────────────
local function makePanel(sg, width, height, title, subtitle)
	local panel = make("Frame", {
		Name = "Panel",
		Size = UDim2.new(0, width, 0, height),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, sg)
	makeCorner(panel, 10)
	makeStroke(panel, COLORS.BORDER, 1.5)

	local titleBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = COLORS.BG2,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, panel)
	make("UICorner", {CornerRadius = UDim.new(0, 10)}, titleBar)
	make("Frame", {
		Size = UDim2.new(1, 0, 0.5, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG2,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, titleBar)

	make("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, titleBar)

	make("TextLabel", {
		Text = title or "DOCK MANAGER",
		TextSize = 17,
		Font = FONT_HEADER,
		TextColor3 = COLORS.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 28),
		Position = UDim2.new(0, 14, 0, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, titleBar)

	if subtitle then
		make("TextLabel", {
			Text = subtitle,
			TextSize = 11,
			Font = FONT_BODY,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 16),
			Position = UDim2.new(0, 14, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}, titleBar)
	end

	local content = make("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -24, 1, -66),
		Position = UDim2.new(0, 12, 0, 58),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}, panel)

	return panel, content, titleBar
end

-- ── Ship Selection UI ─────────────────────────────────────────────────────────
function DockManagerUI:ShowShipSelectUI(opts)
	clearGui()
	local sg = ensureGui()

	makeBackdrop(sg, opts.onClose)

	local panelH = math.min(80 + #opts.ships * 56 + 60, 540)
	local panel, content = makePanel(sg, 420, panelH,
		"⚓  DOCK CONTROL", "Select a ship to deploy to this dock")

	local scroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.ACCENT,
		CanvasSize = UDim2.new(0, 0, 0, #opts.ships * 56),
		ZIndex = 4,
	}, content)

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, scroll)

	for i, shipName in ipairs(opts.ships) do
		local row = make("Frame", {
			Name = "ShipRow_" .. i,
			Size = UDim2.new(1, -4, 0, 48),
			BackgroundColor3 = COLORS.PANEL,
			BorderSizePixel = 0,
			LayoutOrder = i,
			ZIndex = 5,
		}, scroll)
		makeCorner(row, 7)
		makeStroke(row, COLORS.BORDER_DIM, 1)

		make("TextLabel", {
			Text = "🚀",
			TextSize = 22,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 40, 1, 0),
			Position = UDim2.new(0, 6, 0, 0),
			ZIndex = 6,
		}, row)

		make("TextLabel", {
			Text = shipName,
			TextSize = 15,
			Font = FONT_HEADER,
			TextColor3 = COLORS.TEXT,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -130, 1, 0),
			Position = UDim2.new(0, 52, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, row)

		local spawnBtn = make("TextButton", {
			Text = "DEPLOY",
			TextSize = 12,
			Font = FONT_HEADER,
			TextColor3 = Color3.new(1,1,1),
			BackgroundColor3 = COLORS.BTN_SPAWN,
			Size = UDim2.new(0, 80, 0, 30),
			Position = UDim2.new(1, -90, 0.5, -15),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, row)
		makeCorner(spawnBtn, 5)

		spawnBtn.MouseEnter:Connect(function()
			TweenService:Create(spawnBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_SPAWN:Lerp(Color3.new(1,1,1),0.2)}):Play()
		end)
		spawnBtn.MouseLeave:Connect(function()
			TweenService:Create(spawnBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_SPAWN}):Play()
		end)

		local sn = shipName
		spawnBtn.Activated:Connect(function()
			opts.onSpawn(sn)
		end)
	end

	if #opts.ships == 0 then
		make("TextLabel", {
			Text = "No ships in your fleet.\nVisit the Ship Dealer to purchase one.",
			TextSize = 14,
			Font = FONT_BODY,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 60),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, scroll)
	end

	local closeBtn = makeButton("✕  CLOSE", COLORS.BTN_CLOSE, COLORS.TEXT, content)
	closeBtn.Size     = UDim2.new(1, 0, 0, 36)
	closeBtn.Position = UDim2.new(0, 0, 1, -40)
	closeBtn.ZIndex   = 4
	closeBtn.Activated:Connect(opts.onClose)
end

-- ── Occupied (Player Ship) UI ─────────────────────────────────────────────────
function DockManagerUI:ShowOccupiedUI(opts)
	clearGui()
	local sg = ensureGui()

	makeBackdrop(sg, opts.onClose)

	local panel, content = makePanel(sg, 380, 200,
		"⚓  DOCK STATUS",
		"Dock: " .. opts.dockId)

	make("TextLabel", {
		Text = "🚀  " .. (opts.shipName or "Unknown Ship"),
		TextSize = 16,
		Font = FONT_HEADER,
		TextColor3 = COLORS.ACCENT,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, content)

	make("TextLabel", {
		Text = opts.ownedByMe
			and "Your ship is docked here. Undock it to free up this bay."
			or  "Another player's ship is occupying this dock.",
		TextSize = 13,
		Font = FONT_BODY,
		TextColor3 = COLORS.TEXT_DIM,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 32),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
	}, content)

	local btnBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		Position = UDim2.new(0, 0, 1, -42),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, content)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, btnBar)

	if opts.onDespawn then
		local undockBtn = make("TextButton", {
			Text = "↑  UNDOCK SHIP",
			TextSize = 13,
			Font = FONT_HEADER,
			TextColor3 = Color3.new(1,1,1),
			BackgroundColor3 = COLORS.BTN_DESPAWN,
			Size = UDim2.new(0, 150, 1, 0),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			ZIndex = 5,
		}, btnBar)
		makeCorner(undockBtn, 6)
		undockBtn.MouseEnter:Connect(function()
			TweenService:Create(undockBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_DESPAWN:Lerp(Color3.new(1,1,1),0.2)}):Play()
		end)
		undockBtn.MouseLeave:Connect(function()
			TweenService:Create(undockBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_DESPAWN}):Play()
		end)
		undockBtn.Activated:Connect(opts.onDespawn)
	end

	local closeBtn = make("TextButton", {
		Text = "✕  CLOSE",
		TextSize = 12,
		Font = FONT_HEADER,
		TextColor3 = COLORS.TEXT,
		BackgroundColor3 = COLORS.BTN_CLOSE,
		Size = UDim2.new(0, 100, 1, 0),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = 5,
	}, btnBar)
	makeCorner(closeBtn, 6)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_CLOSE:Lerp(Color3.new(1,1,1),0.15)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_CLOSE}):Play()
	end)
	closeBtn.Activated:Connect(opts.onClose)
end

-- ── Cargo Jobs UI ─────────────────────────────────────────────────────────────
function DockManagerUI:ShowCargoUI(opts)
	clearGui()
	local sg = ensureGui()

	makeBackdrop(sg, opts.onClose)

	local panel, content, titleBar = makePanel(sg, 560, 560,
		"📦  CARGO CONTRACTS",
		"Dock: " .. opts.dockId .. "  ·  Ship: " .. (opts.shipName or "—"))

	-- ── Departure countdown timer ─────────────────────────────────────────────
	if opts.timeRemaining and opts.timeRemaining > 0 then
		local timerLabel = make("TextLabel", {
			Text = "DEPARTING IN " .. opts.timeRemaining .. "s",
			TextSize = 11,
			Font = FONT_HEADER,
			TextColor3 = COLORS.DIST_NEAR,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 180, 0, 16),
			Position = UDim2.new(1, -194, 0, 18),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 6,
		}, titleBar)

		local remaining = opts.timeRemaining
		task.spawn(function()
			while remaining > 0 do
				task.wait(1)
				remaining -= 1
				if not timerLabel or not timerLabel.Parent then break end
				if remaining <= 10 then
					timerLabel.TextColor3 = COLORS.DIST_FAR  -- goes red in last 10s
				end
				timerLabel.Text = "DEPARTING IN " .. remaining .. "s"
			end
			if timerLabel and timerLabel.Parent then
				DockManagerUI:ShowNotification("✗ The ship has departed.", false)
				DockManagerUI:Close()
			end
		end)
	end

	local selectedJobId = nil
	local jobFrames = {}

	local scroll = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -90),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.ACCENT,
		CanvasSize = UDim2.new(0, 0, 0, #opts.jobs * 116 + 10),
		ZIndex = 4,
		ClipsDescendants = true,
	}, content)

	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, scroll)

	local function updateSelection()
		for id, frame in pairs(jobFrames) do
			if id == selectedJobId then
				TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.JOB_SEL}):Play()
				local s = frame:FindFirstChildWhichIsA("UIStroke")
				if s then s.Color = COLORS.ACCENT s.Thickness = 1.5 end
			else
				TweenService:Create(frame, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.PANEL}):Play()
				local s = frame:FindFirstChildWhichIsA("UIStroke")
				if s then s.Color = COLORS.BORDER_DIM s.Thickness = 1 end
			end
		end
	end

	for _, job in ipairs(opts.jobs) do
		local distLabel = job.distanceLabel or "Local"
		local distColor = DIST_COLOR[distLabel] or COLORS.TEXT

		local row = make("Frame", {
			Name = "Job_" .. job.id,
			Size = UDim2.new(1, -4, 0, 106),
			BackgroundColor3 = COLORS.PANEL,
			BorderSizePixel = 0,
			LayoutOrder = job.id,
			ZIndex = 5,
		}, scroll)
		makeCorner(row, 8)
		makeStroke(row, COLORS.BORDER_DIM, 1)
		makePadding(row, 8, 8, 12, 12)

		jobFrames[job.id] = row

		local clickArea = make("TextButton", {
			Text = "",
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			ZIndex = 9,
		}, row)

		local jid = job.id
		clickArea.Activated:Connect(function()
			selectedJobId = jid
			updateSelection()
		end)

		-- ── Left block ────────────────────────────────────────────────────────
		local leftBlock = make("Frame", {
			Size = UDim2.new(0.62, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, row)

		local rarityColor = RARITY_COLOR[job.rarity] or COLORS.TEXT_DIM

		-- Cargo name (colored by rarity)
		make("TextLabel", {
			Text = job.cargoName,
			TextSize = 15,
			Font = FONT_HEADER,
			TextColor3 = rarityColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, leftBlock)

		-- Rarity badge
		local rarityBadge = make("Frame", {
			Size = UDim2.new(0, 72, 0, 14),
			Position = UDim2.new(0, 0, 0, 22),
			BackgroundColor3 = rarityColor,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, leftBlock)
		makeCorner(rarityBadge, 3)
		make("UIStroke", {
			Color = rarityColor,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, rarityBadge)
		make("TextLabel", {
			Text = (job.rarity or "Common"):upper(),
			TextSize = 9,
			Font = FONT_HEADER,
			TextColor3 = rarityColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 7,
		}, rarityBadge)

		-- Qty + value
		make("TextLabel", {
			Text = string.format("Qty: %d units  ·  Value: §%s",
				job.quantity, tostring(job.cargoValue)),
			TextSize = 12,
			Font = FONT_MONO,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0, 38),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, leftBlock)

		-- Destination
		make("TextLabel", {
			Text = ">> " .. job.destination,
			TextSize = 13,
			Font = FONT_BODY,
			TextColor3 = COLORS.TEXT,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 0, 56),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, leftBlock)

		-- Distance badge
		local badge = make("Frame", {
			Size = UDim2.new(0, 58, 0, 18),
			Position = UDim2.new(0, 0, 0, 78),
			BackgroundColor3 = distColor,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, leftBlock)
		makeCorner(badge, 9)
		make("TextLabel", {
			Text = distLabel:upper(),
			TextSize = 10,
			Font = FONT_HEADER,
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 7,
		}, badge)

		make("TextLabel", {
			Text = string.format("%s u", tostring(job.distance)),
			TextSize = 11,
			Font = FONT_MONO,
			TextColor3 = distColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 68, 0, 18),
			Position = UDim2.new(0, 64, 0, 78),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, leftBlock)

		make("TextLabel", {
			Text = string.format("⏱ %d min", job.timeLimit),
			TextSize = 11,
			Font = FONT_MONO,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 70, 0, 18),
			Position = UDim2.new(0, 138, 0, 78),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		}, leftBlock)

		-- ── Right block ───────────────────────────────────────────────────────
		local rightBlock = make("Frame", {
			Size = UDim2.new(0.35, 0, 1, 0),
			Position = UDim2.new(0.65, 0, 0, 0),
			BackgroundTransparency = 1,
			ZIndex = 6,
		}, row)

		make("TextLabel", {
			Text = "PAYOUT",
			TextSize = 10,
			Font = FONT_HEADER,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 6,
		}, rightBlock)

		make("TextLabel", {
			Text = "§" .. tostring(job.payout),
			TextSize = 22,
			Font = FONT_HEADER,
			TextColor3 = COLORS.ACCENT2,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.new(0, 0, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 6,
		}, rightBlock)

		-- Danger rating
		local dangerPct = math.floor((job.danger or 0) * 100)
		local dangerText = dangerPct == 0 and "NO RISK"
			or dangerPct < 20  and "LOW RISK"
			or dangerPct < 50  and "MID RISK"
			or dangerPct < 80  and "HIGH RISK"
			or "EXTREME"
		local dangerColor = dangerPct == 0 and COLORS.DIST_LOCAL
			or dangerPct < 50  and COLORS.DIST_NEAR
			or COLORS.DIST_FAR

		make("TextLabel", {
			Text = dangerText,
			TextSize = 10,
			Font = FONT_HEADER,
			TextColor3 = dangerColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0, 0, 0, 60),
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 6,
		}, rightBlock)

		-- Contraband warning
		if job.contraband then
			local cbBadge = make("Frame", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.new(0, 0, 0, 78),
				BackgroundColor3 = COLORS.ERROR,
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				ZIndex = 6,
			}, rightBlock)
			makeCorner(cbBadge, 3)
			make("UIStroke", {
				Color = COLORS.ERROR,
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, cbBadge)
			make("TextLabel", {
				Text = "⚠ CONTRABAND",
				TextSize = 9,
				Font = FONT_HEADER,
				TextColor3 = COLORS.ERROR,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 7,
			}, cbBadge)
		end
	end

	if #opts.jobs == 0 then
		make("TextLabel", {
			Text = "No cargo contracts available at this time.\nCheck back later.",
			TextSize = 14,
			Font = FONT_BODY,
			TextColor3 = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 60),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, scroll)
	end

	-- ── Bottom button bar ─────────────────────────────────────────────────────
	local btnBar = make("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -48),
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, content)

	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, btnBar)

	local acceptBtn = make("TextButton", {
		Text = "✓  ACCEPT JOB",
		TextSize = 13,
		Font = FONT_HEADER,
		TextColor3 = Color3.new(1,1,1),
		BackgroundColor3 = COLORS.BTN_ACCEPT,
		Size = UDim2.new(0, 160, 1, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		ZIndex = 5,
	}, btnBar)
	makeCorner(acceptBtn, 6)
	acceptBtn.MouseEnter:Connect(function()
		TweenService:Create(acceptBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_ACCEPT:Lerp(Color3.new(1,1,1),0.2)}):Play()
	end)
	acceptBtn.MouseLeave:Connect(function()
		TweenService:Create(acceptBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_ACCEPT}):Play()
	end)
	acceptBtn.Activated:Connect(function()
		if not selectedJobId then
			DockManagerUI:ShowNotification("✗ Select a contract first.", false)
			return
		end
		opts.onAccept(selectedJobId)
	end)

	local closeBtn = make("TextButton", {
		Text = "✕  CLOSE",
		TextSize = 12,
		Font = FONT_HEADER,
		TextColor3 = COLORS.TEXT,
		BackgroundColor3 = COLORS.BTN_CLOSE,
		Size = UDim2.new(0, 100, 1, 0),
		BorderSizePixel = 0,
		LayoutOrder = 3,
		ZIndex = 5,
	}, btnBar)
	makeCorner(closeBtn, 6)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_CLOSE:Lerp(Color3.new(1,1,1),0.15)}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = COLORS.BTN_CLOSE}):Play()
	end)
	closeBtn.Activated:Connect(opts.onClose)
end

return DockManagerUI