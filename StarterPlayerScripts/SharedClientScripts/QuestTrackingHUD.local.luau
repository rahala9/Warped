--[[
	QuestTrackingHUD.lua
	Place in: StarterPlayer > StarterPlayerScripts  (LocalScript)

	Registers a "Tracked Quests" panel with RightHUDManager.
	Listens directly to QuestService's QuestStateChanged RemoteEvent.

	Step display modes (auto-detected):
		Sequential   → has prerequisites     → numbered  "1. Talk to Scout"
		Parallel     → no prerequisites       → bulleted  "• Collect residue"
		Branch choice→ shares a group          → diamond   "◆ Choose truth" / — OR — / "◆ Choose coverup"
		Complete     → any mode               → strikethrough + dimmed
		Progress     → goal > 1               → shows "3/10" counter

	Complete quest → green header with "✓ COMPLETE" badge, removed after 5s
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local RightHUDManager = require(script.Parent:WaitForChild("RightHUDManager"))

-- ── Remote hookup ─────────────────────────────────────────────────────────────
local QuestRemotesFolder = ReplicatedStorage:WaitForChild("QuestRemotes", 10)
local QuestStateChanged  = QuestRemotesFolder and QuestRemotesFolder:WaitForChild("QuestStateChanged", 10)
local GetQuestSnapshot   = QuestRemotesFolder and QuestRemotesFolder:WaitForChild("GetQuestSnapshot", 10)

-- Optional: BindableEvent for toggling tracking from a journal UI
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local BE_QuestTrackChanged = SharedRemotes:FindFirstChild("QuestTrackChanged")
if not BE_QuestTrackChanged then
	BE_QuestTrackChanged = Instance.new("BindableEvent")
	BE_QuestTrackChanged.Name = "QuestTrackChanged"
	BE_QuestTrackChanged.Parent = SharedRemotes
end

-- ── Constants ─────────────────────────────────────────────────────────────────
local COLORS = {
	PANEL      = Color3.fromRGB(18,  30,  55),
	BORDER_DIM = Color3.fromRGB(0,   80,  120),
	ACCENT     = Color3.fromRGB(0,   220, 255),
	TEXT       = Color3.fromRGB(210, 235, 255),
	TEXT_DIM   = Color3.fromRGB(110, 150, 190),
	SUCCESS    = Color3.fromRGB(0,   220, 130),
	WARN       = Color3.fromRGB(255, 190, 0),
	COMPLETE   = Color3.fromRGB(0,   200, 100),
	STRIKE     = Color3.fromRGB(80,  110, 160),
	BRANCH     = Color3.fromRGB(255, 180, 50),
}

local FONT_HEADER = Enum.Font.GothamBold
local FONT_BODY   = Enum.Font.Gotham
local FONT_MONO   = Enum.Font.Code

local QUEST_ROW_BASE_HEIGHT = 32
local STEP_ROW_HEIGHT       = 20
local STEP_PADDING          = 4
local OR_DIVIDER_HEIGHT     = 14
local QUEST_PADDING         = 6
local MAX_VISIBLE_HEIGHT    = 320
local COMPLETE_LINGER       = 5

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

local function addStrikethrough(parent, yOffset, width)
	make("Frame", {
		Size             = UDim2.new(0, width, 0, 1),
		Position         = UDim2.new(0, 0, 0, yOffset + 7),
		BackgroundColor3 = COLORS.STRIKE,
		BorderSizePixel  = 0,
		ZIndex           = parent.ZIndex + 1,
	}, parent)
end

-- ── State ─────────────────────────────────────────────────────────────────────
local trackedQuestIds  = {}
local questDisplayData = {}
local untrackedQuests  = {}
local lingerTimers     = {}

local scrollFrame = nil
local emptyLabel  = nil

-- ── Step display mode detection ───────────────────────────────────────────────
-- Returns "sequential", "parallel", or "branch" for each step
local function classifySteps(steps)
	local modes = {}
	for i, step in ipairs(steps) do
		if step.group then
			modes[i] = "branch"
		elseif step.prerequisites and #step.prerequisites > 0 then
			modes[i] = "sequential"
		else
			modes[i] = "parallel"
		end
	end

	-- If ALL non-branch steps have no prerequisites, they're parallel.
	-- If ANY non-branch step has prerequisites, treat the prerequisite
	-- chain as sequential. Steps without prerequisites in a mixed quest
	-- stay parallel.
	return modes
end

-- ── Extract display data from quest runtime state ─────────────────────────────
local function extractQuestDisplay(questId, questState)
	local steps = {}
	local allComplete = true
	local seqCounter = 0

	-- First pass: collect revealed steps
	for _, stepId in ipairs(questState.stepOrder or {}) do
		local stepState = questState.steps[stepId]
		if stepState and stepState.revealed then
			table.insert(steps, {
				id            = stepId,
				title         = stepState.title or stepId,
				type          = stepState.type,
				completed     = stepState.completed or false,
				progress      = stepState.progress or 0,
				goal          = stepState.goal or 1,
				group         = stepState.group,
				prerequisites = stepState.prerequisites or {},
			})

			if not stepState.completed then
				allComplete = false
			end
		end
	end

	-- Classify step display modes
	local modes = classifySteps(steps)
	for i, step in ipairs(steps) do
		print("[QuestHUD] Step:", step.id, "group:", step.group, "prereqs:", #step.prerequisites, "mode:", modes[i])
	end
	-- Second pass: assign display indices based on mode
	seqCounter = 0
	for i, step in ipairs(steps) do
		step.displayMode = modes[i]
		if modes[i] == "sequential" then
			seqCounter += 1
			step.displayIndex = seqCounter
		elseif modes[i] == "parallel" then
			-- Parallel steps can also be numbered if they're the only type
			-- but bullets look better for "do these in any order"
			step.displayIndex = i
		end
	end

	return {
		questId  = questId,
		title    = questState.title or questId,
		category = questState.category,
		complete = allComplete and #steps > 0,
		steps    = steps,
	}
end

-- ── Calculate total height for a quest block ──────────────────────────────────
local function questBlockHeight(qdata)
	local steps = qdata.steps or {}
	local h = QUEST_ROW_BASE_HEIGHT

	for i, step in ipairs(steps) do
		h += STEP_ROW_HEIGHT + STEP_PADDING

		-- Add OR divider height between branch steps in the same group
		if step.displayMode == "branch" and i > 1 then
			local prev = steps[i - 1]
			if prev and prev.group == step.group then
				h += OR_DIVIDER_HEIGHT
			end
		end
	end

	h += QUEST_PADDING
	return h
end

-- ── Build a single quest block ────────────────────────────────────────────────
local function buildQuestBlock(qdata, layoutOrder)
	local steps    = qdata.steps or {}
	local complete = qdata.complete or false
	local h        = questBlockHeight(qdata)

	local block = make("Frame", {
		Name             = "Quest_" .. qdata.questId,
		Size             = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = COLORS.PANEL,
		BorderSizePixel  = 0,
		LayoutOrder      = layoutOrder,
		ZIndex           = 12,
	}, scrollFrame)
	makeCorner(block, 7)
	makeStroke(block, complete and COLORS.COMPLETE or COLORS.BORDER_DIM, complete and 1.5 or 1)

	-- Left accent bar
	make("Frame", {
		Size             = UDim2.new(0, 3, 1, -8),
		Position         = UDim2.new(0, 0, 0, 4),
		BackgroundColor3 = complete and COLORS.COMPLETE or COLORS.ACCENT,
		BorderSizePixel  = 0,
		ZIndex           = 13,
	}, block)

	-- ── Quest header row ──────────────────────────────────────────────────────
	local headerRow = make("Frame", {
		Size                   = UDim2.new(1, -10, 0, QUEST_ROW_BASE_HEIGHT),
		Position               = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		ZIndex                 = 13,
	}, block)

	make("TextLabel", {
		Text             = qdata.title,
		TextSize         = 13,
		Font             = FONT_HEADER,
		TextColor3       = complete and COLORS.COMPLETE or COLORS.TEXT,
		BackgroundTransparency = 1,
		Size             = UDim2.new(1, -70, 1, 0),
		Position         = UDim2.new(0, 0, 0, 0),
		TextXAlignment   = Enum.TextXAlignment.Left,
		TextTruncate     = Enum.TextTruncate.AtEnd,
		ZIndex           = 14,
	}, headerRow)

	if complete then
		local badge = make("Frame", {
			Size             = UDim2.new(0, 62, 0, 16),
			Position         = UDim2.new(1, -64, 0.5, -8),
			BackgroundColor3 = COLORS.COMPLETE,
			BackgroundTransparency = 0.75,
			BorderSizePixel  = 0,
			ZIndex           = 14,
		}, headerRow)
		makeCorner(badge, 3)
		makeStroke(badge, COLORS.COMPLETE, 1)
		make("TextLabel", {
			Text             = "✓ COMPLETE",
			TextSize         = 8,
			Font             = FONT_HEADER,
			TextColor3       = COLORS.COMPLETE,
			BackgroundTransparency = 1,
			Size             = UDim2.new(1, 0, 1, 0),
			TextXAlignment   = Enum.TextXAlignment.Center,
			ZIndex           = 15,
		}, badge)
	end

	-- ── Step rows ─────────────────────────────────────────────────────────────
	local currentY = QUEST_ROW_BASE_HEIGHT

	for i, step in ipairs(steps) do
		local isComplete  = step.completed
		local hasProgress = step.goal > 1
		local mode        = step.displayMode or "parallel"

		-- Insert OR divider between branch steps in the same group
		if mode == "branch" and i > 1 then
			local prev = steps[i - 1]
			if prev and prev.group == step.group then
				make("TextLabel", {
					Text                   = "— OR —",
					TextSize               = 9,
					Font                   = FONT_MONO,
					TextColor3             = COLORS.BRANCH,
					BackgroundTransparency = 1,
					Size                   = UDim2.new(1, -28, 0, OR_DIVIDER_HEIGHT),
					Position               = UDim2.new(0, 14, 0, currentY),
					TextXAlignment         = Enum.TextXAlignment.Center,
					ZIndex                 = 14,
				}, block)
				currentY += OR_DIVIDER_HEIGHT
			end
		end

		-- Build the prefix based on display mode
		local prefix
		if mode == "branch" then
			prefix = "◆"
		elseif mode == "sequential" then
			prefix = tostring(step.displayIndex) .. "."
		else -- parallel
			prefix = "•"
		end

		local labelText = prefix .. " " .. step.title
		local labelColor
		if isComplete then
			labelColor = COLORS.STRIKE
		elseif mode == "branch" then
			labelColor = COLORS.BRANCH
		else
			labelColor = COLORS.TEXT_DIM
		end

		local stepRow = make("Frame", {
			Size                   = UDim2.new(1, -14, 0, STEP_ROW_HEIGHT),
			Position               = UDim2.new(0, 14, 0, currentY),
			BackgroundTransparency = 1,
			ZIndex                 = 13,
		}, block)

		make("TextLabel", {
			Text             = labelText,
			TextSize         = 11,
			Font             = isComplete and FONT_HEADER or FONT_BODY,
			TextColor3       = labelColor,
			BackgroundTransparency = 1,
			Size             = UDim2.new(1, hasProgress and -48 or 0, 1, 0),
			Position         = UDim2.new(0, 0, 0, 0),
			TextXAlignment   = Enum.TextXAlignment.Left,
			TextTruncate     = Enum.TextTruncate.AtEnd,
			ZIndex           = 14,
		}, stepRow)

		if isComplete then
			addStrikethrough(stepRow, 0, 180)
		end

		if hasProgress then
			local progColor = isComplete and COLORS.COMPLETE
				or (step.progress > 0 and COLORS.WARN or COLORS.TEXT_DIM)

			make("TextLabel", {
				Text             = step.progress .. "/" .. step.goal,
				TextSize         = 10,
				Font             = FONT_MONO,
				TextColor3       = progColor,
				BackgroundTransparency = 1,
				Size             = UDim2.new(0, 44, 1, 0),
				Position         = UDim2.new(1, -44, 0, 0),
				TextXAlignment   = Enum.TextXAlignment.Right,
				ZIndex           = 14,
			}, stepRow)
		end

		currentY += STEP_ROW_HEIGHT + STEP_PADDING
	end

	return block
end

-- ── Rebuild the scroll content ────────────────────────────────────────────────
local function rebuildRows()
	if not scrollFrame then return end

	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = #trackedQuestIds
	emptyLabel.Visible = count == 0

	local totalH = 0
	for i, questId in ipairs(trackedQuestIds) do
		local qdata = questDisplayData[questId]
		if qdata then
			buildQuestBlock(qdata, i)
			totalH = totalH + questBlockHeight(qdata)
		end
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalH + 8)

	local panelH = math.min(totalH + 8, MAX_VISIBLE_HEIGHT)
	if count == 0 then panelH = 52 end
	RightHUDManager:SetPanelHeight("TrackedQuests", panelH)
end

local function trackQuest(questId, displayData)
	if not questDisplayData[questId] then
		table.insert(trackedQuestIds, questId)
	end
	questDisplayData[questId] = displayData
	rebuildRows()
end

local function untrackQuest(questId)
	questDisplayData[questId] = nil
	lingerTimers[questId] = nil
	for i, id in ipairs(trackedQuestIds) do
		if id == questId then
			table.remove(trackedQuestIds, i)
			break
		end
	end
	rebuildRows()
end

-- ── Process full state update from QuestService ───────────────────────────────
local function processStateUpdate(data)
	if not data then return end

	local active = data.active or {}
	local currentActiveIds = {}

	for questId, questState in pairs(active) do
		currentActiveIds[questId] = true

		if not untrackedQuests[questId] then
			local displayData = extractQuestDisplay(questId, questState)
			trackQuest(questId, displayData)
		end
	end

	-- Handle quests removed from active (completed, failed, abandoned)
	for i = #trackedQuestIds, 1, -1 do
		local questId = trackedQuestIds[i]
		if not currentActiveIds[questId] and not lingerTimers[questId] then
			local wasCompleted = data.completed and data.completed[questId]
			local existingDisplay = questDisplayData[questId]

			if wasCompleted and existingDisplay then
				existingDisplay.complete = true
				lingerTimers[questId] = true
				rebuildRows()

				task.delay(COMPLETE_LINGER, function()
					untrackQuest(questId)
				end)
			else
				untrackQuest(questId)
			end
		end
	end
end

-- ── Register panel with RightHUDManager ──────────────────────────────────────
RightHUDManager:RegisterPanel({
	id        = "TrackedQuests",
	title     = "TRACKED QUESTS",
	icon      = "!",
	order     = 4,
	maxHeight = MAX_VISIBLE_HEIGHT,

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
			Padding   = UDim.new(0, QUEST_PADDING),
		}, scrollFrame)

		emptyLabel = make("TextLabel", {
			Text                   = "No quests tracked.",
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
		rebuildRows()
	end,
})

-- ── Event listeners ───────────────────────────────────────────────────────────
if QuestStateChanged then
	QuestStateChanged.OnClientEvent:Connect(function(data)
		processStateUpdate(data)
	end)
end

BE_QuestTrackChanged.Event:Connect(function(payload)
	if not payload or not payload.questId then return end

	if payload.tracked == false then
		untrackedQuests[payload.questId] = true
		untrackQuest(payload.questId)
	else
		untrackedQuests[payload.questId] = nil
	end
end)

-- Request initial state on load
task.spawn(function()
	if GetQuestSnapshot then
		local data = GetQuestSnapshot:InvokeServer()
		if data then
			processStateUpdate(data)
		end
	end
end)
