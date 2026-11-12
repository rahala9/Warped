
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local placementSwimItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("SwimItems")
local toysFolder = placementSwimItems:WaitForChild("Toys")
local toys = toysFolder:GetChildren()
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local Character = player.Character or player.CharacterAdded:Wait()
local Lighting = game:GetService("Lighting")
local swimItems = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("SwimItems"))
local GetInventoryEvent = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
PlayerGui = player:FindFirstChild("PlayerGui")
local SwimGui = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("SwimGui")
local sendinv = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SendInv")
local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))
local SwimmingFunctions = require(script.Parent:WaitForChild("SwimmingFunctions"))
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))

local PlayerStateChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChanged")

local rotation = 0
local modelCount = 0
local model = nil
local modelType = "tent"
local homeIsPlaced = false

local inWater = false

local onBeach = false

local playerInventory = {}
local playerFilteredInventory = {}
local playerBeachInventory = {}

local onSwitchDebounce = false
local initialToyOffsetY = .7
local duckyOffset  = 1

local currentState = "None"

player.CharacterAdded:Connect(function(character)
	Character = character
end)

local function SetModelPosition()
	
	local offset = 0
	
	if (model.Name == "Ducky") then
		offset = duckyOffset
	end
	
	if (currentState == "SurfaceSwimming") then
		model.Position = Vector3.new(Character.PrimaryPart.Position.X,(Character.PrimaryPart.Position.Y + offset) - 1,Character.PrimaryPart.Position.Z)
	else
		model.Position = Vector3.new(Character.PrimaryPart.Position.X,(Character.PrimaryPart.Position.Y + offset) + initialToyOffsetY,Character.PrimaryPart.Position.Z)
	end
end

local function onSwitch(actionName, userInputState, input)

	if (onSwitchDebounce) then
		return
	end

	onSwitchDebounce = true 

	if (userInputState == Enum.UserInputState.Begin) then
		if (model) then
			model:Destroy()
		end

		--local playerInventory = GetInventoryEvent:InvokeServer()
		
		local currentSwimItems = playerInventory["SwimItems"]
		
		if (inWater) then
			if (actionName == "switch") then
				modelCount = modelCount + 1 > #currentSwimItems.Toys and 1 or modelCount + 1
			elseif (actionName == "Init") then
				modelCount = 1
			else
				modelCount = modelCount - 1 < 1 and #currentSwimItems.Toys or modelCount - 1
			end	
			
			local swimItemModel = nil
			
			if (currentSwimItems.Toys[modelCount] and currentSwimItems.Toys[modelCount].Name ~= "Blank") then
				swimItemModel = toysFolder[currentSwimItems.Toys[modelCount].Name]
			end
			
			if (swimItemModel ~= nil) then
				model = swimItemModel:Clone()
				modelType = "toy"	
				model.CanCollide = false
				model.CFrame = Character.PrimaryPart.CFrame
				
				SetModelPosition()
				
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = Character.PrimaryPart
				weld.Part1 = model
				weld.Parent = model
				
				model.Anchored = false
				model.Parent = Character.PrimaryPart
				
			end
			
			if (currentSwimItems.Toys[modelCount].Name == "Blank") then
				Character.PrimaryPart:SetAttribute("InTube",false)
			else
				Character.PrimaryPart:SetAttribute("InTube",true)
			end

			SwimGui.SwimItems.ToysFrame["1"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["2"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["3"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["4"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["5"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["6"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["7"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["8"].Image = swimItems.ImageMap.Toys
			SwimGui.SwimItems.ToysFrame["9"].Image = swimItems.ImageMap.Toys

			if (#currentSwimItems.Toys>4) then
				SwimGui.SwimItems.ToysFrame["1"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount - 4) > 0 and (modelCount - 4) or #currentSwimItems.Toys + (modelCount - 4))].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount - 4) > 0 and (modelCount - 4) or #currentSwimItems.Toys + (modelCount - 4))].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["1"].Image = ""
			end

			if (#currentSwimItems.Toys>3) then
				SwimGui.SwimItems.ToysFrame["2"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount - 3) > 0 and (modelCount - 3) or #currentSwimItems.Toys + (modelCount - 3))].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount - 3) > 0 and (modelCount - 3) or #currentSwimItems.Toys + (modelCount - 3))].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["2"].Image = ""	
			end

			if (#currentSwimItems.Toys>2) then
				SwimGui.SwimItems.ToysFrame["3"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount - 2) > 0 and (modelCount - 2) or #currentSwimItems.Toys + (modelCount - 2))].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount - 2) > 0 and (modelCount - 2) or #currentSwimItems.Toys + (modelCount - 2))].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["3"].Image = ""	
			end

			if (#currentSwimItems.Toys>1) then
				SwimGui.SwimItems.ToysFrame["4"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount - 1) > 0 and (modelCount - 1) or #currentSwimItems.Toys + (modelCount - 1))].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount - 1) > 0 and (modelCount - 1) or #currentSwimItems.Toys + (modelCount - 1))].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["4"].Image = ""	
			end

			if (#currentSwimItems.Toys>0) then
				SwimGui.SwimItems.ToysFrame["5"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[modelCount].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[modelCount].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["5"].Image = ""	
			end

			if (#currentSwimItems.Toys>1) then
				SwimGui.SwimItems.ToysFrame["6"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount + 1) > #currentSwimItems.Toys and ((modelCount + 1) - #currentSwimItems.Toys) or modelCount + 1)].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount + 1) > #currentSwimItems.Toys and ((modelCount + 1) - #currentSwimItems.Toys) or modelCount + 1)].Name]["ImageOffsetY"])
			else
				SwimGui.SwimItems.ToysFrame["6"].Image = ""	
			end

			if (#currentSwimItems.Toys>2) then
				SwimGui.SwimItems.ToysFrame["7"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount + 2) > #currentSwimItems.Toys and ((modelCount + 2) - #currentSwimItems.Toys) or modelCount + 2)].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount + 2) > #currentSwimItems.Toys and ((modelCount + 2) - #currentSwimItems.Toys) or modelCount + 2)].Name]["ImageOffsetY"])	
			else
				SwimGui.SwimItems.ToysFrame["7"].Image = ""	
			end

			if (#currentSwimItems.Toys>3) then
				SwimGui.SwimItems.ToysFrame["8"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount + 3) > #currentSwimItems.Toys and ((modelCount + 3) - #currentSwimItems.Toys) or modelCount + 3)].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount + 3) > #currentSwimItems.Toys and ((modelCount + 3) - #currentSwimItems.Toys) or modelCount + 3)].Name]["ImageOffsetY"])	
			else
				SwimGui.SwimItems.ToysFrame["8"].Image = ""	
			end

			if (#currentSwimItems.Toys>4) then
				SwimGui.SwimItems.ToysFrame["9"].ImageRectOffset = Vector2.new(swimItems[currentSwimItems.Toys[((modelCount + 4) > #currentSwimItems.Toys and ((modelCount + 4) - #currentSwimItems.Toys) or modelCount + 4)].Name]["ImageOffsetX"],swimItems[currentSwimItems.Toys[((modelCount + 4) > #currentSwimItems.Toys and ((modelCount + 4) - #currentSwimItems.Toys) or modelCount + 4)].Name]["ImageOffsetY"])	
			else
				SwimGui.SwimItems.ToysFrame["9"].Image = ""	
			end

		end

	end

	onSwitchDebounce = false
end



local function BuildSwimInventory()
	playerInventory = GetInventoryEvent:InvokeServer()
end

local function InWater(state)
	
	if (model) then
		
		SetModelPosition()
	end
	
	if (inWater) then
		return
	end
	
	inWater = true
	
	BuildSwimInventory()
	
	SwimGui.Enabled = true
	SwimGui.SwimItems.ToysFrame.Visible = true
	
	--Initially switch to tent model
	onSwitch("Init", Enum.UserInputState.Begin, nil)
	
	game:GetService("ContextActionService"):BindAction("switch", onSwitch, false, Enum.KeyCode.E)
	game:GetService("ContextActionService"):BindAction("switchback", onSwitch, false, Enum.KeyCode.Q)
	
	
end

local function OutOfWater()
	
	if (not inWater) then
		return
	end

	
	inWater = false
	
	SwimGui.Enabled = false
	SwimGui.SwimItems.ToysFrame.Visible = false
	
	if (model ~= nil) then
		model:Destroy() 
	end
	
	game:GetService("ContextActionService"):UnbindAction("switch", onSwitch, false, Enum.KeyCode.E)
	game:GetService("ContextActionService"):UnbindAction("switchback", onSwitch, false, Enum.KeyCode.Q)
end


PlayerStateChangedEvent.Event:Connect(function(state,inWater)
	
	currentState = state
	
	if (inWater) then
		InWater(state)
	else
		OutOfWater()
	end
	
end)

sendinv.OnClientEvent:Connect(function()
	BuildSwimInventory()
end)

