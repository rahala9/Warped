local playerGui = game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local buildItemsmodule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("BuildItems"))
local messageGuiFrame = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("MessageFrame")
local messageGuiTextbox = messageGuiFrame:WaitForChild("GraphicFrame"):WaitForChild("message")
local messageGuiPicture = messageGuiFrame:WaitForChild("GraphicFrame"):WaitForChild("Picture")
local messageGuiRequiredItem = messageGuiPicture:WaitForChild("RequiredItem")

local noteGUI = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("Note")
local noteGUITitle = noteGUI:WaitForChild("ATitleFrame"):WaitForChild("BTitle")
local noteGUIMessage = noteGUI:WaitForChild("NoteText")

local functions = {}


local numMessages = 0

function functions.GetItemBaseName(itemId)
		
	if (not itemId) then
		return nil
	end
		
	local itemPieces = string.split(itemId,"_")
	local itemName = itemPieces[1]
	return itemName
end

function functions.DisplayOnScreenNote(message,guiType,titleType)

	noteGUI.Visible = true

	if (guiType == "BlankPaper") then
		--Do nothing it is default
	end

	if (titleType == "TopSecret") then
		noteGUITitle.Text = "TOP SECRET"
	end

	noteGUIMessage.Text = message

end


function functions.DisplayOnScreenMessage(message,requiredItemName,keepOn,posX,posY,textColor,fadeTime,startTime,guiType,titleType)

	if (not fadeTime) then
		fadeTime = 2
	end
	
	requiredItemName = functions.GetItemBaseName(requiredItemName)

	local messageFrame = messageGuiFrame:Clone()
	local messageTextbox = messageFrame:WaitForChild("GraphicFrame"):WaitForChild("message")
	local messagePicture = messageFrame:WaitForChild("GraphicFrame"):WaitForChild("Picture")
	local messageRequiredItem = messagePicture:WaitForChild("RequiredItem")

	local yOffset = 128 * numMessages
	numMessages = numMessages + 1
	messageFrame.Position = UDim2.new(.4,0,0,messageFrame.Position.Y.Offset + yOffset) 

	messageTextbox.Text = message
	messageTextbox.Position = UDim2.new(.1,0,.09,0) 
	messageTextbox.Size = UDim2.new(.8,0,.65,0) 

	local item = nil
	local itemImage = nil

	if (requiredItemName ~= nil and itemsmodule[requiredItemName] ~= nil) then
		item  = itemsmodule[requiredItemName]
		itemImage = itemsmodule.ImageMap[item.Type]
		messageRequiredItem.ImageRectSize =  Vector2.new(64,64)
	elseif(requiredItemName ~= nil and buildItemsmodule[requiredItemName] ~= nil) then
		item = buildItemsmodule[requiredItemName]	
		itemImage = buildItemsmodule.ImageMap[item.Type]
		messageRequiredItem.ImageRectSize =  Vector2.new(64,64)
	elseif (requiredItemName ~= nil) then
		warn("ITEM NOT FOUND: "..requiredItemName)
	end


	if (requiredItemName ~= nil and item ~= nil) then
		messagePicture.Visible = true
		messageRequiredItem.Image = itemImage
		messageRequiredItem.ImageRectOffset = Vector2.new(item.ImageOffsetX,item.ImageOffsetY)	
		messageTextbox.Position = UDim2.new(.4,0,.09,0) 
		messageTextbox.Size = UDim2.new(.53,0,.65,0) 
	end

	messageFrame.Visible = true
	messageFrame.Parent = messageGuiFrame.Parent

	task.delay(fadeTime,function()

		messageFrame:Destroy()
		numMessages = numMessages - 1
	end)
end

return functions