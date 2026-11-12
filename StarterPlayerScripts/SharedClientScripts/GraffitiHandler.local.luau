
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local Character = player.Character or player.CharacterAdded:Wait()

local graffitiFolder = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti")
local ToolStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ToolStateChange")
local GetInventoryEvent = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
PlayerGui = player:FindFirstChild("PlayerGui")
local GraffitiGui = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("GraffitiGui")
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))
local GraffitiCategories = GraffitiGui:WaitForChild("GraffitiCategories")

local mouse = game.Players.LocalPlayer:GetMouse()

local hitPosition = Vector3.new(0,0,0)

local rotation = 0
local modelCount = 0
local model = nil
local modelType = "tent"
local homeIsPlaced = false

local equipped = false

local onBeach = false

local playerInventory = {}
local playerFilteredInventory = {}
local playerBeachInventory = {}
local placementLocked = false


player.CharacterAdded:Connect(function(newChar)
	Character = newChar
end)

local SubTypes = {
	["Text"]="Text",
	["Images"]="Images",
};

local onSwitchDebounce = false
local currentSubType = SubTypes.Text


local function onSwitch(actionName, userInputState, input)

	if (onSwitchDebounce) then
		return Enum.ContextActionResult.Pass	
	end

	onSwitchDebounce = true 

	if (userInputState == Enum.UserInputState.Begin) then
		
		local GraffitiItems = {
			Text={
				[1]={Name="Graffiti1",Color1="#ffbf00",Color2="#a20003",Color3="#28a4cc"},
				[2]={Name="Graffiti2",Color1="#8bcde0",Color2="#333133",Color3=""},
				[3]={Name="Graffiti4",Color1="#fef51a",Color2="#000001",Color3=""},
				[4]={Name="Graffiti6",Color1="#00ccff",Color2="#ee38a3",Color3="#000000"},
				[5]={Name="Graffiti7",Color1="#000000",Color2="",Color3=""},
				[6]={Name="Graffiti8",Color1="#000000",Color2="",Color3=""},
				[7]={Name="Graffiti9",Color1="#000000",Color2="",Color3=""},
				[8]={Name="Graffiti11",Color1="#f48024",Color2="#fdca05",Color3="#211e26"},
				[9]={Name="Graffiti12",Color1="#19eaf7",Color2="#f8ee10",Color3="#332c44"},
				[10]={Name="Graffiti13",Color1="#f6f8fe",Color2="#e9dc1e",Color3="#f73c39"},
				[11]={Name="Graffiti15",Color1="#f3db97",Color2="#d31a21",Color3="#060201"},
				[12]={Name="Graffiti16",Color1="#fa4547",Color2="#010000",Color3="#f5fbfb"},
				[13]={Name="Graffiti17",Color1="#b35cd6",Color2="#f5cd52",Color3="#000000"},
			},
			Images={
				[1]={Name="Graffiti3",Color1="#ffcf23",Color2="#010011",Color3=""},
				[2]={Name="Graffiti5",Color1="#010001",Color2="",Color3=""},
				[3]={Name="Graffiti10",Color1="#fe5f97",Color2="#030102",Color3="#fefefe"},
				[4]={Name="Graffiti14",Color1="#018ce7",Color2="#030304",Color3="#ccf5fa"},
				[5]={Name="Graffiti18",Color1="#6eb9e0",Color2="#f0ad21",Color3="#790802"},
				[6]={Name="Graffiti19",Color1="#d63030",Color2="#e96e6e",Color3="#00ffff"},
				[7]={Name="Graffiti20",Color1="#000000",Color2="",Color3=""},
				[8]={Name="Graffiti21",Color1="#d63030",Color2="#000000",Color3=""},
				[9]={Name="Graffiti3",Color1="#ffbf00",Color2="#a20003",Color3="#28a4cc"},
				[10]={Name="Graffiti3",Color1="",Color2="",Color3=""},
				[11]={Name="Graffiti3",Color1="",Color2="",Color3=""},
				[12]={Name="Graffiti3",Color1="",Color2="",Color3=""},
				[13]={Name="Graffiti3",Color1="",Color2="",Color3=""},
			}
			
		}


		--local playerInventory = GetInventoryEvent:InvokeServer()
		
		local currentGraffitiItems = GraffitiItems
			
			if (actionName == "switch") then
			modelCount = modelCount + 1 > #GraffitiItems[currentSubType] and 1 or modelCount + 1
			else
			modelCount = modelCount - 1 < 1 and #GraffitiItems[currentSubType] or modelCount - 1
			end

		GraffitiGui.GraffitiItems["1"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount - 4) > 0 and (modelCount - 4) or #GraffitiItems[currentSubType] + (modelCount - 4))].Name].Texture
		GraffitiGui.GraffitiItems["2"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount - 3) > 0 and (modelCount - 3) or #GraffitiItems[currentSubType] + (modelCount - 3))].Name].Texture
		GraffitiGui.GraffitiItems["3"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount - 2) > 0 and (modelCount - 2) or #GraffitiItems[currentSubType] + (modelCount - 2))].Name].Texture
		GraffitiGui.GraffitiItems["4"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount - 1) > 0 and (modelCount - 1) or #GraffitiItems[currentSubType] + (modelCount - 1))].Name].Texture
		GraffitiGui.GraffitiItems["5"].Image = graffitiFolder[GraffitiItems[currentSubType][modelCount].Name].Texture
		GraffitiGui.GraffitiItems["6"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount + 1) > #GraffitiItems[currentSubType] and ((modelCount + 1) - #GraffitiItems[currentSubType]) or modelCount + 1)].Name].Texture
		GraffitiGui.GraffitiItems["7"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount + 2) > #GraffitiItems[currentSubType] and ((modelCount + 2) - #GraffitiItems[currentSubType]) or modelCount + 2)].Name].Texture
		GraffitiGui.GraffitiItems["8"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount + 3) > #GraffitiItems[currentSubType] and ((modelCount + 3) - #GraffitiItems[currentSubType]) or modelCount + 3)].Name].Texture
		GraffitiGui.GraffitiItems["9"].Image = graffitiFolder[GraffitiItems[currentSubType][((modelCount + 4) > #GraffitiItems[currentSubType] and ((modelCount + 4) - #GraffitiItems[currentSubType]) or modelCount + 4)].Name].Texture
		
		ToolStateChangeEvent:FireServer("Spraypaint",GraffitiItems[currentSubType][modelCount].Name,GraffitiItems[currentSubType][modelCount].Color1,GraffitiItems[currentSubType][modelCount].Color2,GraffitiItems[currentSubType][modelCount].Color3)		
		
			--GraffitiGui.GraffitiItems["1"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount - 4) > 0 and (modelCount - 4) or numberOfGraffitiTags + (modelCount - 4))]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount - 4) > 0 and (modelCount - 4) or numberOfGraffitiTags + (modelCount - 4))]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["2"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount - 3) > 0 and (modelCount - 3) or numberOfGraffitiTags + (modelCount - 3))]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount - 3) > 0 and (modelCount - 3) or numberOfGraffitiTags + (modelCount - 3))]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["3"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount - 2) > 0 and (modelCount - 2) or numberOfGraffitiTags + (modelCount - 2))]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount - 2) > 0 and (modelCount - 2) or numberOfGraffitiTags + (modelCount - 2))]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["4"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount - 1) > 0 and (modelCount - 1) or numberOfGraffitiTags + (modelCount - 1))]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount - 1) > 0 and (modelCount - 1) or numberOfGraffitiTags + (modelCount - 1))]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["5"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[modelCount]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Tents[modelCount]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["6"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount + 1) > numberOfGraffitiTags and ((modelCount + 1) - numberOfGraffitiTags) or modelCount + 1)]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount + 1) > numberOfGraffitiTags and ((modelCount + 1) - numberOfGraffitiTags) or modelCount + 1)]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["7"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount + 2) > numberOfGraffitiTags and ((modelCount + 2) - numberOfGraffitiTags) or modelCount + 2)]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount + 2) > numberOfGraffitiTags and ((modelCount + 2) - numberOfGraffitiTags) or modelCount + 2)]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["8"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount + 3) > numberOfGraffitiTags and ((modelCount + 3) - numberOfGraffitiTags) or modelCount + 3)]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount + 3) > numberOfGraffitiTags and ((modelCount + 3) - numberOfGraffitiTags) or modelCount + 3)]]["ImageOffsetY"])
			--GraffitiGui.GraffitiItems["9"].ImageRectOffset = Vector2.new(GraffitiItems[currentGraffitiItems.Items[((modelCount + 4) > numberOfGraffitiTags and ((modelCount + 4) - numberOfGraffitiTags) or modelCount + 4)]]["ImageOffsetX"],GraffitiItems[currentGraffitiItems.Items[((modelCount + 4) > numberOfGraffitiTags and ((modelCount + 4) - numberOfGraffitiTags) or modelCount + 4)]]["ImageOffsetY"])		
		
	end

	onSwitchDebounce = false
	
	return Enum.ContextActionResult.Pass
end


local onRotateDebounce = false


local function EnableSelectedBox(clicked)
	for index,category in ipairs(GraffitiCategories:GetChildren()) do

		if category:IsA("ImageLabel") then
			category.SelectedBox.Enabled = false
		end
	end

	GraffitiCategories[clicked].SelectedBox.Enabled = true
end


GraffitiCategories["1"].InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		
		EnableSelectedBox(1)
		
		currentSubType = SubTypes.Text
		
		onSwitch(nil, Enum.UserInputState.Begin, nil)
		
	end
end)
GraffitiCategories["2"].InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		EnableSelectedBox(2)
		
		currentSubType = SubTypes.Images
		
		onSwitch(nil, Enum.UserInputState.Begin, nil)

	end
end)


GraffitiCategories.MouseEnter:Connect(function()
	placementLocked = true
end)

GraffitiCategories.MouseLeave:Connect(function()
	placementLocked = false
end)

local function SpraypaintEquipped()
	
	if (equipped) then
		return
	end
	
	
	equipped = true
	placementLocked = false

	GraffitiGui.Enabled = true

	--Initially switch to tent model
	onSwitch(nil, Enum.UserInputState.Begin, nil)
	game:GetService("ContextActionService"):BindAction("switch", onSwitch, false, Enum.KeyCode.E)
	game:GetService("ContextActionService"):BindAction("switchback", onSwitch, false, Enum.KeyCode.Q)

end

local function SpraypaintUnequipped()
	
	if (not equipped) then
		return
	end
	
	equipped = false

	GraffitiGui.Enabled = false

	game:GetService("ContextActionService"):UnbindAction("switch")
	game:GetService("ContextActionService"):UnbindAction("switchback")

end

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName,slot)

	if (toolName == "Spraypaint") then

		SpraypaintEquipped()

	else
		SpraypaintUnequipped()
	end

end)





