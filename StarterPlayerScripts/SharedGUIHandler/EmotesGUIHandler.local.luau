--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local EmotesContext = InputRoot:WaitForChild("EmotesContext")

local ChangeEmoteCategoryAction = EmotesContext:WaitForChild("ChangeEmoteCategoryAction")

local EmotesGui = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("EmotesGui")


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
	Idle  = "Idle",
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
	[1] = SubTypes.Idle,  [2] = SubTypes.Mean,  [3] = SubTypes.Angry,
	[4] = SubTypes.Happy, [5] = SubTypes.Sad,   [6] = SubTypes.Dance,
	[7] = SubTypes.Greet, [8] = SubTypes.Taunt, [9] = SubTypes.Sport,
}

local CONTEXT = "Emotes"

local emotesPicId1 = "rbxassetid://107276575724095"


local itemsBySubType = {
	Idle  = {
		{Name="Stretch",PicId=emotesPicId1,X="0",Y="0"},	
		{Name="Yawn",PicId=emotesPicId1,X="64",Y="0"},	
	},
	Mean  = {},
	Angry = {},
	Happy = { 
		{Name="DoubleFingerGuns",PicId=emotesPicId1,X="0",Y="192"} 
	},
	Sad   = {
		{Name="Cry",PicId=emotesPicId1,X="0",Y="256"},	
	},
	Dance = {
		{Name="Lightning",PicId=emotesPicId1,X="0",Y="320"},
		{Name="Spin",PicId=emotesPicId1,X="64",Y="320"}, 	
	},
	Greet = {
		{Name="Salute",PicId=emotesPicId1,X="0",Y="384"}, 	
		{Name="Wave",PicId=emotesPicId1,X="64",Y="384"}, 	
	},
	Taunt = {},
	Sport = { 
		{Name="Backflip",PicId=emotesPicId1,X="0",Y="512"}, 
		{Name="Karate",PicId=emotesPicId1,X="64",Y="512"},
		{Name="Flex",PicId=emotesPicId1,X="128",Y="512"} 
	},
}

--// State
local currentSubType = SubTypes.Nice
local currentList: {string} = {} -- array of emote names available in this subtype
local categoryIndex = 0

local function resolveCategoryMap()
	return CategoryMap
end

local function cleanEmotes()
	for i = 1, 9 do
		EmotesGui.EmoteItems[i].Image = ""
	end
end

local function rebuildCurrentList()
	currentList = {}

	cleanEmotes()

	local sourceList = itemsBySubType[currentSubType] or {}
	for i, item in ipairs(sourceList) do
		table.insert(currentList, item)
		EmotesGui.EmoteItems[i].Image = item.PicId
		EmotesGui.EmoteItems[i].ImageRectOffset = Vector2.new(item.X, item.Y)
	end

end

local selectEmoteDebounce = false

local function selectEmote(emoteIndex)
	if emoteIndex == 0 then
		return
	end

	if (selectEmoteDebounce) then
		return
	end

	selectEmoteDebounce = true

	local emoteName = currentList[emoteIndex].Name
	if not emoteName then
		return
	end

	PlayEmoteEvent:Fire(emoteName, true)
	
	selectEmoteDebounce = false
end

local function selectCategory(index: number)
	
	local map = resolveCategoryMap()
	local sub = map[index]
	if not sub then
		return
	end
	print("TEST EMOTES selected category:",index," sub:",sub)
	currentSubType = sub
	rebuildCurrentList()

end

for i = 1, 9 do
	local action = EmotesContext:WaitForChild("SelectEmoteAction"..i)

	action.Pressed:Connect(function()
		selectEmote(i)
	end)
end

ChangeEmoteCategoryAction.Pressed:Connect(function()
	
	EmotesGui.EmoteCategories[categoryIndex].SelectedBox.Enabled = false
	
	if (categoryIndex + 1) < 10 then
		
		categoryIndex = categoryIndex + 1
		
	else
		categoryIndex = 0
	end
	
	selectCategory(categoryIndex)
	
	EmotesGui.EmoteCategories[categoryIndex].SelectedBox.Enabled = true
	
end)

--// Init
currentSubType = SubTypes.Nice
rebuildCurrentList()

if #currentList > 0 then
	emoteIndex = 1
else
	emoteIndex = 0
end