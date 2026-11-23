--[[
    CargoHUD.lua
    Place in: StarterPlayer > StarterPlayerScripts  (LocalScript)

    Registers the Active Deliveries panel with RightHUDManager.
    Polls RF_GetPlayerCargo every 5 seconds and immediately refreshes
    when CargoJobAccepted fires.
    Distance updates live each second from workspace.Zones.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local RightHUDManager = require(script.Parent:WaitForChild("RightHUDManager"))

-- ── Remotes ───────────────────────────────────────────────────────────────────
local Remotes           = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DockRemotes")
local RF_GetPlayerCargo = Remotes:WaitForChild("GetPlayerCargo")
local RF_CancelCargoJob = Remotes:WaitForChild("CancelCargoJob")
local RE_CargoRiskChanged = Remotes:WaitForChild("CargoRiskChanged")

local cargoJobAccepted  = ReplicatedStorage:WaitForChild("CargoJobAccepted", 10)

-- ── Zone lookup ───────────────────────────────────────────────────────────────
local ZonesFolder = workspace:WaitForChild("Zones", 10)

local function getZonePosition(zoneName)
	if not ZonesFolder then return nil end
	local zone = ZonesFolder:FindFirstChild(zoneName)
	if not zone then return nil end
	if zone:IsA("BasePart") then
		return zone.Position
	elseif zone:IsA("Model") then
		return zone.PrimaryPart and zone.PrimaryPart.Position
			or zone:FindFirstChildWhichIsA("BasePart", true) and zone:FindFirstChildWhichIsA("BasePart", true).Position
	end
	return nil
end

local function getPlayerPosition()
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

-- ── Constants ─────────────────────────────────────────────────────────────────
local COLORS = {
	PANEL       = Color3.fromRGB(18, 30,  55),
	BORDER_DIM  = Color3.fromRGB(0,  80,  120),
	ACCENT2     = Color3.fromRGB(255, 160, 0),
	TEXT        = Color3.fromRGB(210, 235, 255),
	TEXT_DIM    = Color3.fromRGB(110, 150, 190),
	ERROR       = Color3.fromRGB(255, 80,  80),
	SUCCESS     = Color3.fromRGB(0,  220, 130),
	WARN        = Color3.fromRGB(255, 190, 0),
	RARITY_COMMON    = Color3.fromRGB(180, 180, 180),
	RARITY_UNCOMMON  = Color3.fromRGB(80,  200, 100),
	RARITY_RARE      = Color3.fromRGB(60,  140, 255),
	RARITY_EPIC      = Color3.fromRGB(180, 80,  255),
	RARITY_LEGENDARY = Color3.fromRGB(255, 160, 0),
}

local RARITY_COLOR = {
	Common    = COLORS.RARITY_COMMON,
	Uncommon  = COLORS.RARITY_UNCOMMON,
	Rare      = COLORS.RARITY_RARE,
	Epic      = COLORS.RARITY_EPIC,
	Legendary = COLORS.RARITY_LEGENDARY,
}

local FONT_HEADER   = Enum.Font.GothamBold
local FONT_BODY     = Enum.Font.Gotham
local FONT_MONO     = Enum.Font.Code
local ROW_HEIGHT    = 118
local POLL_INTERVAL = 5

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function makeCorner(parent, radius)
	make("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function makeStroke(parent, color, thickness)
	make("UIStroke", {
		Color           = color or COLORS.BORDER_DIM,
		Thickness       = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function formatTime(seconds)
	if seconds <= 0 then return "EXPIRED" end
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return m > 0 and string.format("%dm %02ds", m, s) or string.format("%ds", s)
end

local function timeColor(seconds)
	if seconds <= 60 then return COLORS.ERROR
	elseif seconds <= 300 then return COLORS.WARN
	else return COLORS.SUCCESS end
end

local function dangerText(danger)
	local p = math.floor((danger or 0) * 100)
	if p == 0 then return "NO RISK"
	elseif p < 20 then return "LOW RISK"
	elseif p < 50 then return "MID RISK"
	elseif p < 80 then return "HIGH RISK"
	else return "EXTREME" end
end

local function dangerColor(danger)
	local p = math.floor((danger or 0) * 100)
	if p == 0 then return COLORS.SUCCESS
	elseif p < 50 then return COLORS.WARN
	else return COLORS.ERROR end
end

local function hasRisk(job, riskName)
	local risks = job.risks or {}
	if (typeof(risks[riskName]) == "number" and risks[riskName] > 0) or risks[riskName] == true then
		return true
	end
	for _, configuredRisk in ipairs(risks) do
		if configuredRisk == riskName then return true end
	end
	return false
end

local function conditionColor(condition)
	local normalized = math.clamp((condition or 0) / 100, 0, 1)
	if normalized > 0.5 then
		return COLORS.WARN:Lerp(COLORS.SUCCESS, (normalized - 0.5) * 2)
	end
	return COLORS.ERROR:Lerp(COLORS.WARN, normalized * 2)
end

local function formatDistance(studs)
	if studs >= 1000 then
		return string.format("%.1fk st", studs / 1000)
	else
		return string.format("%d st", math.floor(studs))
	end
end

-- ── State ─────────────────────────────────────────────────────────────────────
local activeJobs  = {}
local timeLabels  = {}       -- { [jobKey] = { label, timeLeft } }
local distLabels  = {}       -- { [jobKey] = { label, zoneName } }
local stabilityWidgets = {}  -- { [jobKey] = { label, fill } }
local containmentWidgets = {} -- { [jobKey] = { label, fill } }
local scrollFrame = nil
local emptyLabel  = nil
local fetchAndRefresh

-- ── Build job row ─────────────────────────────────────────────────────────────
local function buildJobRow(entry, index)
	local job      = entry.job
	local timeLeft = entry.timeLeft
	local rc       = RARITY_COLOR[job.rarity] or COLORS.TEXT_DIM
	local dc       = dangerColor(job.danger)
	local jobKey   = entry.dockId .. "_" .. entry.jobId .. "_" .. tostring(entry.expiresAt)

	local row = make("Frame", {
		Name             = "JobRow_" .. index,
		Size             = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = COLORS.PANEL,
		BorderSizePixel  = 0,
		LayoutOrder      = index,
		ZIndex           = 12,
	}, scrollFrame)
	makeCorner(row, 7)
	makeStroke(row, COLORS.BORDER_DIM, 1)

	-- Rarity accent bar
	make("Frame", {
		Size             = UDim2.new(0, 3, 1, -8),
		Position         = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = rc,
		BorderSizePixel  = 0,
		ZIndex           = 13,
	}, row)

	local content = make("Frame", {
		Size                   = UDim2.new(1, -12, 1, 0),
		Position               = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		ZIndex                 = 13,
	}, row)

	-- Cargo name
	make("TextLabel", {
		Text                   = job.cargoName,
		TextSize               = 13,
		Font                   = FONT_HEADER,
		TextColor3             = rc,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -28, 0, 18),
		Position               = UDim2.new(0, 0, 0, 6),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 14,
	}, content)

	-- Payout
	make("TextLabel", {
		Text                   = "§" .. tostring(job.payout),
		TextSize               = 14,
		Font                   = FONT_HEADER,
		TextColor3             = COLORS.ACCENT2,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 58, 0, 18),
		Position               = UDim2.new(1, -58, 0, 26),
		TextXAlignment         = Enum.TextXAlignment.Right,
		ZIndex                 = 14,
	}, content)

	-- Compact cancellation control leaves the header available for long cargo
	-- names. The server remains authoritative over whether it can be cancelled.
	local cancelButton = make("TextButton", {
		Text                   = "X",
		TextSize               = 11,
		Font                   = FONT_HEADER,
		TextColor3             = COLORS.ERROR,
		BackgroundColor3       = Color3.fromRGB(48, 20, 28),
		BackgroundTransparency = 0.1,
		BorderSizePixel        = 0,
		Size                   = UDim2.fromOffset(18, 18),
		Position               = UDim2.new(1, -18, 0, 5),
		AutoButtonColor        = false,
		ZIndex                 = 15,
	}, content)
	makeCorner(cancelButton, 4)
	makeStroke(cancelButton, COLORS.ERROR, 1)

	cancelButton.Activated:Connect(function()
		cancelButton.Active = false
		cancelButton.Text = "…"
		local invokeOk, cancelled, message = pcall(function()
			return RF_CancelCargoJob:InvokeServer(entry.dockId, entry.jobId)
		end)
		if invokeOk and cancelled then
			task.defer(function()
				if fetchAndRefresh then fetchAndRefresh() end
			end)
		else
			cancelButton.Text = "!"
			warn("[CargoDeliveryHUD] Cancel failed:", invokeOk and message or cancelled)
			task.delay(2, function()
				if cancelButton.Parent then
					cancelButton.Active = true
					cancelButton.Text = "X"
				end
			end)
		end
	end)

	-- Destination
	make("TextLabel", {
		Text                   = ">> " .. job.destination,
		TextSize               = 11,
		Font                   = FONT_BODY,
		TextColor3             = COLORS.TEXT,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, -64, 0, 14),
		Position               = UDim2.new(0, 0, 0, 26),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ZIndex                 = 14,
	}, content)

	-- Distance (live — updated by ticker)
	local distLabel = make("TextLabel", {
		Text                   = formatDistance(job.distance),
		TextSize               = 10,
		Font                   = FONT_MONO,
		TextColor3             = COLORS.TEXT_DIM,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 70, 0, 12),
		Position               = UDim2.new(0, 0, 0, 42),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 14,
	}, content)

	-- Danger
	make("TextLabel", {
		Text                   = dangerText(job.danger),
		TextSize               = 10,
		Font                   = FONT_HEADER,
		TextColor3             = dc,
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 0, 12),
		Position               = UDim2.new(0, 72, 0, 42),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 14,
	}, content)

	-- Contraband badge (below danger)
	if job.contraband then
		local contrabandSeverity = typeof(job.risks) == "table" and job.risks.Contraband or nil
		local contrabandClass = string.upper(job.contrabandClass or "Restricted")
		local hasSignature = typeof(contrabandSeverity) == "number"
		local offenseBadge = make("Frame", {
			Size                   = UDim2.new(0, hasSignature and 76 or 112, 0, 13),
			Position               = UDim2.new(0, 0, 0, 56),
			BackgroundColor3       = COLORS.ERROR,
			BackgroundTransparency = 0.75,
			BorderSizePixel        = 0,
			ZIndex                 = 14,
		}, content)
		makeCorner(offenseBadge, 3)
		makeStroke(offenseBadge, COLORS.ERROR, 1)
		make("TextLabel", {
			Text                   = "⚠ " .. contrabandClass,
			TextSize               = 8,
			Font                   = FONT_HEADER,
			TextColor3             = COLORS.ERROR,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 1, 0),
			TextXAlignment         = Enum.TextXAlignment.Center,
			ZIndex                 = 15,
		}, offenseBadge)
		if hasSignature then
			local signatureBadge = make("Frame", {
				Size                   = UDim2.new(0, 82, 0, 13),
				Position               = UDim2.new(0, 80, 0, 56),
				BackgroundColor3       = COLORS.ERROR,
				BackgroundTransparency = 0.75,
				BorderSizePixel        = 0,
				ZIndex                 = 14,
			}, content)
			makeCorner(signatureBadge, 3)
			makeStroke(signatureBadge, COLORS.ERROR, 1)
			make("TextLabel", {
				Text                   = string.format("SIGNATURE %d%%", math.round(contrabandSeverity * 100)),
				TextSize               = 8,
				Font                   = FONT_HEADER,
				TextColor3             = COLORS.ERROR,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(1, 0, 1, 0),
				TextXAlignment         = Enum.TextXAlignment.Center,
				ZIndex                 = 15,
			}, signatureBadge)
		end
	end

	-- Time remaining
	local timerLabel = make("TextLabel", {
		Text                   = formatTime(timeLeft),
		TextSize               = 11,
		Font                   = FONT_MONO,
		TextColor3             = timeColor(timeLeft),
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 80, 0, 14),
		Position               = UDim2.new(0, 0, 0, 72),
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 14,
	}, content)

	local hasStability = entry.cargoStability ~= nil
	if hasStability then
		local stability = entry.cargoStability
		local color = conditionColor(stability)
		local stabilityLabelText = entry.cargoStabilityLabel or "CARGO STABILITY"
		local conditionLabel = make("TextLabel", {
			Text                   = entry.cargoStabilityTriggered and stabilityLabelText .. "  TRIGGERED"
				or string.format("%s  %d%%", stabilityLabelText, math.round(stability)),
			TextSize               = 9,
			Font                   = FONT_HEADER,
			TextColor3             = color,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, -86, 0, 12),
			Position               = UDim2.new(0, 86, 0, 68),
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 14,
		}, content)
		local conditionTrack = make("Frame", {
			Size             = UDim2.new(1, -86, 0, 6),
			Position         = UDim2.new(0, 86, 0, 82),
			BackgroundColor3 = Color3.fromRGB(45, 55, 65),
			BorderSizePixel  = 0,
			ZIndex           = 14,
		}, content)
		makeCorner(conditionTrack, 3)
		local conditionFill = make("Frame", {
			Size             = UDim2.new(math.clamp(stability / 100, 0, 1), 0, 1, 0),
			BackgroundColor3 = color,
			BorderSizePixel  = 0,
			ZIndex           = 15,
		}, conditionTrack)
		makeCorner(conditionFill, 3)
		stabilityWidgets[jobKey] = { label = conditionLabel, fill = conditionFill }
	end

	if hasRisk(job, "Biohazardous") then
		local containment = entry.cargoContainment or 100
		local containmentState = entry.cargoContainmentState or "SEALED?"
		local color = conditionColor(containment)
		local y = hasStability and 90 or 68
		local containmentLabel = make("TextLabel", {
			Text                   = string.format("%s  %d%%", containmentState, math.round(containment)),
			TextSize               = 9,
			Font                   = FONT_HEADER,
			TextColor3             = color,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, -86, 0, 12),
			Position               = UDim2.new(0, 86, 0, y),
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 14,
		}, content)
		local containmentTrack = make("Frame", {
			Size             = UDim2.new(1, -86, 0, 6),
			Position         = UDim2.new(0, 86, 0, y + 14),
			BackgroundColor3 = Color3.fromRGB(45, 55, 65),
			BorderSizePixel  = 0,
			ZIndex           = 14,
		}, content)
		makeCorner(containmentTrack, 3)
		local containmentFill = make("Frame", {
			Size             = UDim2.new(math.clamp(containment / 100, 0, 1), 0, 1, 0),
			BackgroundColor3 = color,
			BorderSizePixel  = 0,
			ZIndex           = 15,
		}, containmentTrack)
		makeCorner(containmentFill, 3)
		containmentWidgets[jobKey] = { label = containmentLabel, fill = containmentFill }
	end

	timeLabels[jobKey] = { label = timerLabel, timeLeft = timeLeft }
	distLabels[jobKey] = { label = distLabel,  zoneName = job.zoneName }
end

-- ── Rebuild scroll content ────────────────────────────────────────────────────
local function rebuildRows()
	if not scrollFrame then return end

	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	timeLabels = {}
	distLabels = {}
	stabilityWidgets = {}
	containmentWidgets = {}

	local count = #activeJobs
	emptyLabel.Visible = (count == 0)

	for i, entry in ipairs(activeJobs) do
		buildJobRow(entry, i)
	end

	local contentH = count > 0 and (count * (ROW_HEIGHT + 6)) or 40
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentH)

	local panelH = math.min(contentH + 8, ROW_HEIGHT * 3 + 24)
	if count == 0 then panelH = 52 end
	RightHUDManager:SetPanelHeight("CargoDeliveries", panelH)
end

-- ── Server fetch ──────────────────────────────────────────────────────────────
fetchAndRefresh = function()
	local ok, result = pcall(function()
		return RF_GetPlayerCargo:InvokeServer()
	end)

	if ok and result then
		local rowsChanged = #result ~= #activeJobs
		if not rowsChanged then
			for index, entry in ipairs(result) do
				local previous = activeJobs[index]
				if not previous
					or previous.dockId ~= entry.dockId
					or previous.jobId ~= entry.jobId
					or previous.expiresAt ~= entry.expiresAt
				then
					rowsChanged = true
					break
				end
			end
		end
		activeJobs = result

		-- Sync timeLeft to prevent drift
		for _, entry in ipairs(activeJobs) do
			local jobKey = entry.dockId .. "_" .. entry.jobId .. "_" .. tostring(entry.expiresAt)
			if timeLabels[jobKey] then
				timeLabels[jobKey].timeLeft = entry.timeLeft
			end
			local widget = stabilityWidgets[jobKey]
			if widget and entry.cargoStability ~= nil then
				local stability = math.clamp(entry.cargoStability, 0, 100)
				local color = conditionColor(stability)
				local stabilityLabel = entry.cargoStabilityLabel or "CARGO STABILITY"
				widget.label.Text = entry.cargoStabilityTriggered and stabilityLabel .. "  TRIGGERED"
					or string.format("%s  %d%%", stabilityLabel, math.round(stability))
				widget.label.TextColor3 = color
				widget.fill.Size = UDim2.new(stability / 100, 0, 1, 0)
				widget.fill.BackgroundColor3 = color
			end
			local containmentWidget = containmentWidgets[jobKey]
			if containmentWidget and entry.cargoContainment then
				local containment = math.clamp(entry.cargoContainment, 0, 100)
				local color = conditionColor(containment)
				containmentWidget.label.Text = string.format(
					"%s  %d%%",
					entry.cargoContainmentState or "SEALED?",
					math.round(containment)
				)
				containmentWidget.label.TextColor3 = color
				containmentWidget.fill.Size = UDim2.new(containment / 100, 0, 1, 0)
				containmentWidget.fill.BackgroundColor3 = color
			end
		end

		-- Rebuild when job identity changes, even when one completed contract is
		-- immediately replaced by another and the total count stays the same.
		if rowsChanged then
			rebuildRows()
		end
	end
end

-- ── Register with RightHUDManager ────────────────────────────────────────────
RightHUDManager:RegisterPanel({
	id        = "CargoDeliveries",
	title     = "ACTIVE DELIVERIES",
	icon      = "📦",
	order     = 3,
	maxHeight = ROW_HEIGHT * 3 + 24,

	onBuild = function(contentFrame)
		scrollFrame = make("ScrollingFrame", {
			Size                   = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			ScrollBarThickness     = 3,
			ScrollBarImageColor3   = Color3.fromRGB(0, 220, 255),
			CanvasSize             = UDim2.new(0, 0, 0, 0),
			ZIndex                 = 11,
			ClipsDescendants       = true,
		}, contentFrame)

		make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 6),
		}, scrollFrame)

		emptyLabel = make("TextLabel", {
			Text                   = "No active deliveries.",
			TextSize               = 12,
			Font                   = FONT_BODY,
			TextColor3             = COLORS.TEXT_DIM,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 40),
			TextXAlignment         = Enum.TextXAlignment.Center,
			ZIndex                 = 12,
			Visible                = true,
		}, scrollFrame)
	end,

	onExpand = function(_)
		fetchAndRefresh()
	end,
})

-- ── Immediate refresh on job accepted ────────────────────────────────────────
if cargoJobAccepted then
	cargoJobAccepted.Event:Connect(function()
		task.delay(0.3, function()
			fetchAndRefresh()
			RightHUDManager:SetExpanded("CargoDeliveries", true)
		end)
	end)
end

RE_CargoRiskChanged.OnClientEvent:Connect(function(changedJobKey, snapshot)
	snapshot = snapshot or {}
	for _, entry in ipairs(activeJobs) do
		local key = tostring(entry.dockId) .. ":" .. tostring(entry.jobId)
		if key == changedJobKey then
			entry.cargoStability = snapshot.stability
			entry.cargoStabilityLabel = snapshot.stabilityLabel
			entry.cargoStabilityTriggered = snapshot.stabilityTriggered
			entry.cargoContainment = snapshot.containment
			entry.cargoContainmentState = snapshot.containmentState
			entry.cargoBroken = snapshot.broken
			local displayKey = entry.dockId .. "_" .. entry.jobId .. "_" .. tostring(entry.expiresAt)
			local widget = stabilityWidgets[displayKey]
			if widget and snapshot.stability ~= nil then
				local displayedCondition = math.clamp(snapshot.stability, 0, 100)
				local color = conditionColor(displayedCondition)
				local stabilityLabel = snapshot.stabilityLabel or "CARGO STABILITY"
				widget.label.Text = snapshot.broken and stabilityLabel .. "  BROKEN"
					or snapshot.stabilityTriggered and stabilityLabel .. "  TRIGGERED"
					or string.format("%s  %d%%", stabilityLabel, math.round(displayedCondition))
				widget.label.TextColor3 = color
				widget.fill.Size = UDim2.new(displayedCondition / 100, 0, 1, 0)
				widget.fill.BackgroundColor3 = color
			end
			local containmentWidget = containmentWidgets[displayKey]
			if containmentWidget and snapshot.containment ~= nil then
				local containment = math.clamp(snapshot.containment, 0, 100)
				local color = conditionColor(containment)
				containmentWidget.label.Text = string.format(
					"%s  %d%%",
					snapshot.containmentState or "SEALED?",
					math.round(containment)
				)
				containmentWidget.label.TextColor3 = color
				containmentWidget.fill.Size = UDim2.new(containment / 100, 0, 1, 0)
				containmentWidget.fill.BackgroundColor3 = color
			end
			break
		end
	end

	if snapshot.broken then
		task.delay(0.25, fetchAndRefresh)
	end
end)

-- ── Live ticker — countdown + distance ───────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(1)

		local playerPos = getPlayerPosition()

		-- Update timers
		for _, entry in pairs(timeLabels) do
			entry.timeLeft = math.max(0, entry.timeLeft - 1)
			if entry.label and entry.label.Parent then
				entry.label.Text       = formatTime(entry.timeLeft)
				entry.label.TextColor3 = timeColor(entry.timeLeft)
			end
		end

		-- Update distances
		if playerPos then
			for _, entry in pairs(distLabels) do
				if entry.label and entry.label.Parent then
					local zonePos = getZonePosition(entry.zoneName)
					if zonePos then
						local dist = (zonePos - playerPos).Magnitude
						entry.label.Text = formatDistance(dist)
					end
				end
			end
		end
	end
end)

-- ── Polling loop ──────────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		fetchAndRefresh()
		task.wait(POLL_INTERVAL)
	end
end)
