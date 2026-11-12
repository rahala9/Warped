--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local ShipBuildContext = InputRoot:WaitForChild("ShipBuildContext")

local SelectNextShipBuildAction = ShipBuildContext:WaitForChild("SelectNextShipBuildAction")
local SelectPreviousShipBuildAction = ShipBuildContext:WaitForChild("SelectPreviousShipBuildAction")

--// Optional data sources (used if present)
local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local shipBuild = SharedClientAssets and SharedClientAssets:WaitForChild("ShipBuild")
local shipBuildItems = shipBuild and shipBuild:WaitForChild("ShipBuildItems")

local floorsItems = shipBuildItems and shipBuildItems:WaitForChild("Floors")
local wallsItems = shipBuildItems and shipBuildItems:WaitForChild("Walls")
local wallAttachmentsItems = shipBuildItems and shipBuildItems:WaitForChild("WallAttachments")
local commandItems = shipBuildItems and shipBuildItems:WaitForChild("Command")
local exteriorPanelItems = shipBuildItems and shipBuildItems:WaitForChild("ExteriorPanels")

local itemsBySubType = {
	Floors=floorsItems,
	Walls=wallsItems,
	WallAttachments=wallAttachmentsItems,
	Command=commandItems,
	ExteriorPanels=exteriorPanelItems,
	--Misc="Misc",
	--Engines="Engines",
	--Weapons="Weapons",
	--Power="Power",
}

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
local BuildSelectionChangedEvent = Remotes:WaitForChild("BuildSelectionChanged")
local LocalBuildSelectionChangedEvent = Remotes:WaitForChild("LocalBuildSelectionChanged")


--// Subtypes and category maps
local SubTypes = {
	Floors="Floors",
	Walls="Walls",
	WallAttachments="WallAttachments",
	Command="Command",
	ExteriorPanels="ExteriorPanels",
	Misc="Misc",
	Engines="Engines",
	Weapons="Weapons",
	Power="Power",
}

local CategoryMapShip = {
	[1]=SubTypes.Floors, [2]=SubTypes.Walls, [3]=SubTypes.WallAttachments,
	[4]=SubTypes.Command,   [5]=SubTypes.ExteriorPanels, [6]=SubTypes.Misc,
	[7]=SubTypes.Engines,[8]=SubTypes.Weapons,[9]=SubTypes.Power,
}

--// State

local currentSubType = SubTypes.Floors
local currentList = {}        -- array of model names available in this subtype
local modelIndex = 0

--// Helpers
local function scanFolderNames(folder)
	local out = {}
	if not folder then return out end
	for _, inst in ipairs(folder:GetChildren()) do
		if inst:IsA("Model") then table.insert(out, inst.Name) end
	end
	table.sort(out)
	return out
end


local function resolveCategoryMap()
	return  CategoryMapShip --TODO add switch to base building
end

local function rebuildCurrentList()
	currentList = {}

	for _, n in ipairs(scanFolderNames(itemsBySubType[currentSubType])) do table.insert(currentList, n) end

	print("TEST resolveCategoryMap currentList:",currentList, " crrentSubType:",currentSubType, " itemsBySubType[currentSubType]:",itemsBySubType[currentSubType])

	if #currentList > 0 then modelIndex = math.clamp(modelIndex, 1, #currentList) else modelIndex = 0 end
end

local function fireChanged()
	if modelIndex == 0 then return end
	local payload = {
		subType  = currentSubType,
		modelName = currentList[modelIndex],
	}
	-- Local + Remote
	print("TEST FIRE LOCAL CHANGED EVENT")
	LocalBuildSelectionChangedEvent:Fire(payload)
	BuildSelectionChangedEvent:FireServer(payload)
end

local function selectCategory(index)
	
	print("TEST SELECT CATEGORY index:",index)
	
	local map = resolveCategoryMap()
	local sub = map[index]
	if not sub then return end
	currentSubType = sub
	modelIndex = 1
	
	print("TEST SELECT CATEGORY current SubType:",sub, " modelIndex:",modelIndex)
	
	rebuildCurrentList()
	fireChanged()
end

local function nextModel()
	
	print("TEST NEXT MODEL modelIndex:",modelIndex)
	
	if #currentList == 0 then return end
	modelIndex += 1
	if modelIndex > #currentList then modelIndex = 1 end
	fireChanged()
end
local function prevModel()
	
	print("TEST PREV MODEL modelIndex:",modelIndex)
	
	if #currentList == 0 then return end
	modelIndex -= 1
	if modelIndex < 1 then modelIndex = #currentList end
	fireChanged()
end

for i = 1, 9 do
	local action = ShipBuildContext:WaitForChild("SelectShipBuildCategoryAction"..i)

	action.Pressed:Connect(function()
		selectCategory(i)
	end)
end

SelectNextShipBuildAction.Pressed:Connect(function()
	nextModel()
end)

SelectPreviousShipBuildAction.Pressed:Connect(function()
	prevModel()
end)

--// Init
currentSubType = SubTypes.Floors
rebuildCurrentList()
if modelIndex == 0 and #currentList > 0 then modelIndex = 1 end
if modelIndex > 0 then fireChanged() end
