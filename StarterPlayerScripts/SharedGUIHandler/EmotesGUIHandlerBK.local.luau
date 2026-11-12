--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local EmotesContext = InputRoot:WaitForChild("EmotesContext")

local SelectNextEmoteAction = EmotesContext:WaitForChild("SelectNextEmoteAction")
local SelectPreviousEmoteAction = EmotesContext:WaitForChild("SelectPreviousEmoteAction")
local PlayEmoteAction = EmotesContext:WaitForChild("PlayEmoteAction")

local EmotesGui = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("EmotesGui")
local PlayButton = EmotesGui:WaitForChild("PlayButton")



local keyToIndex = {
	[Enum.KeyCode.One] = 1,   [Enum.KeyCode.Two] = 2,   [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,  [Enum.KeyCode.Five] = 5,  [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9,

	-- Numpad:
	[Enum.KeyCode.KeypadOne] = 1,   [Enum.KeyCode.KeypadTwo] = 2,   [Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,  [Enum.KeyCode.KeypadFive] = 5,  [Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.KeypadSeven] = 7, [Enum.KeyCode.KeypadEight] = 8, [Enum.KeyCode.KeypadNine] = 9,
}

--// Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local ShowGUI = Remotes:WaitForChild("ShowGUI")
local PlayEmoteEvent = Remotes:WaitForChild("LocalPlayEmote")

--// Subtypes and category maps
local SubTypes = {
	Nice  = "Nice",
	Mean  = "Mean",
	Angry = "Angry",
	Happy = "Happy",
	Sad   = "Sad",
	Dance = "Dance",
	Greet = "Greet",
	Taunt = "Taunt",
	Sport = "Sport",
}

local CategoryMap = {
	[1] = SubTypes.Nice,  [2] = SubTypes.Mean,  [3] = SubTypes.Angry,
	[4] = SubTypes.Happy, [5] = SubTypes.Sad,   [6] = SubTypes.Dance,
	[7] = SubTypes.Greet, [8] = SubTypes.Taunt, [9] = SubTypes.Sport,
}

local CONTEXT = "Emotes"

local itemsBySubType = {
	Nice  = {},
	Mean  = {},
	Angry = {},
	Happy = { "DoubleFingerGuns" },
	Sad   = {},
	Dance = {},
	Greet = {},
	Taunt = {},
	Sport = { "Backflip", "Karate" },
}

--// State
local currentSubType = SubTypes.Nice
local currentList: {string} = {} -- array of emote names available in this subtype
local emoteIndex = 0

local function resolveCategoryMap()
	return CategoryMap
end

local function rebuildCurrentList()
	currentList = {}

	local sourceList = itemsBySubType[currentSubType] or {}
	for _, name in ipairs(sourceList) do
		table.insert(currentList, name)
	end

	print("TEST Emote GUI REBUILD LIST currentSubType:", currentSubType, " size:", #currentList)
	-- Important: do NOT touch emoteIndex here; caller decides what index should be.
end

local function fireChanged()
	if emoteIndex == 0 then
		print("TEST Emote GUI fireChanged aborted: emoteIndex == 0")
		return
	end

	local emoteName = currentList[emoteIndex]
	if not emoteName then
		print("TEST Emote GUI fireChanged aborted: no emote at index", emoteIndex)
		return
	end

	print("TEST Emote GUI TEST FIRE LOCAL CHANGED EVENT", "emote:", emoteName, "index:", emoteIndex)
	PlayEmoteEvent:Fire(emoteName, true)
end

local function play()
	print("TEST Emote GUI TEST PLAY BUTTON for subtype:", currentSubType)

	-- Rebuild to reflect latest data for this subtype
	rebuildCurrentList()

	if #currentList == 0 then
		print("TEST Emote GUI PLAY: no emotes for subtype:", currentSubType)
		return
	end

	-- Clamp / set emoteIndex if it's out of range
	if emoteIndex < 1 or emoteIndex > #currentList then
		emoteIndex = 1
	end

	fireChanged()
end

local function selectCategory(index: number)
	print("TEST Emote GUI TEST SELECT CATEGORY index:", index)

	local map = resolveCategoryMap()
	local sub = map[index]
	if not sub then
		print("TEST Emote GUI selectCategory: no subtype for index", index)
		return
	end

	currentSubType = sub
	rebuildCurrentList()

	if #currentList > 0 then
		emoteIndex = 1
	else
		emoteIndex = 0
	end

	print("TEST Emote GUI SELECT CATEGORY currentSubType:", sub, " emoteIndex:", emoteIndex, " listSize:", #currentList)
end

for i = 1, 9 do
	local action = EmotesContext:WaitForChild("SelectEmoteCategoryAction"..i)

	action.Pressed:Connect(function()
		selectCategory(i)
	end)
end

local function nextModel()
	print("TEST Emote GUI TEST NEXT Emote emoteIndex:", emoteIndex, " listSize:", #currentList)

	if #currentList == 0 then return end
	emoteIndex += 1
	if emoteIndex > #currentList then
		emoteIndex = 1
	end
	-- Note: no fireChanged() here; only PlayButton actually plays.
end

local function prevModel()
	print("TEST Emote GUI TEST PREV Emote emoteIndex:", emoteIndex, " listSize:", #currentList)

	if #currentList == 0 then return end
	emoteIndex -= 1
	if emoteIndex < 1 then
		emoteIndex = #currentList
	end
	-- Note: no fireChanged() here; only PlayButton actually plays.
end

SelectNextEmoteAction.Pressed:Connect(function()
	nextModel()
end)

SelectPreviousEmoteAction.Pressed:Connect(function()
	prevModel()
end)

PlayEmoteAction.Pressed:Connect(function()
	play()
end)

--// Init
currentSubType = SubTypes.Nice
rebuildCurrentList()

if #currentList > 0 then
	emoteIndex = 1
else
	emoteIndex = 0
end

-- No fireChanged() here so nothing plays until user presses PlayButton.
