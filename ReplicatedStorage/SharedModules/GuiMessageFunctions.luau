local playerGui = game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
local textService = game:GetService("TextService")
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local buildItemsmodule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("BuildItems"))
local TopNotificationManager = require(
	game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("TopNotificationManager")
)
local noteGUI = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("Note")
local noteGUITitle = noteGUI:WaitForChild("ATitleFrame"):WaitForChild("BTitle")
local noteGUIMessage = noteGUI:WaitForChild("NoteText")

local functions = {}


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
		fadeTime = 6
	end
	
	requiredItemName = functions.GetItemBaseName(requiredItemName)

	local item = nil
	local itemImage = nil

	if (requiredItemName ~= nil and itemsmodule[requiredItemName] ~= nil) then
		item  = itemsmodule[requiredItemName]
		itemImage = itemsmodule.ImageMap[item.Type]
	elseif(requiredItemName ~= nil and buildItemsmodule[requiredItemName] ~= nil) then
		item = buildItemsmodule[requiredItemName]	
		itemImage = buildItemsmodule.ImageMap[item.Type]
	elseif (requiredItemName ~= nil) then
		warn("ITEM NOT FOUND: "..requiredItemName)
	end

	local hasItem = requiredItemName ~= nil and item ~= nil
	local textWidth = hasItem and 256 or 308
	local textBounds = textService:GetTextSize(
		tostring(message),
		14,
		Enum.Font.GothamMedium,
		Vector2.new(textWidth, 180)
	)
	local frameHeight = math.clamp(textBounds.Y + 28, 56, 120)
	local messageFrame = TopNotificationManager.CreatePanel(
		"MessageToast",
		360,
		frameHeight,
		TopNotificationManager.NextToastOrder()
	)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Position = UDim2.fromOffset(0, 8)
	accent.Size = UDim2.new(0, 4, 1, -16)
	accent.BackgroundColor3 = TopNotificationManager.Theme.Border
	accent.BorderSizePixel = 0
	accent.Parent = messageFrame
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accent

	local textX = hasItem and 66 or 14
	local messageTextbox = Instance.new("TextLabel")
	messageTextbox.Name = "Message"
	messageTextbox.BackgroundTransparency = 1
	messageTextbox.Position = UDim2.fromOffset(textX, 8)
	messageTextbox.Size = UDim2.new(1, -(textX + 38), 1, -20)
	messageTextbox.Font = Enum.Font.GothamMedium
	messageTextbox.Text = tostring(message)
	messageTextbox.TextColor3 = textColor or TopNotificationManager.Theme.Text
	messageTextbox.TextSize = 14
	messageTextbox.TextWrapped = true
	messageTextbox.TextXAlignment = Enum.TextXAlignment.Left
	messageTextbox.TextYAlignment = Enum.TextYAlignment.Center
	messageTextbox.Parent = messageFrame

	if hasItem then
		local iconBacking = Instance.new("Frame")
		iconBacking.Name = "ItemIconBacking"
		iconBacking.Position = UDim2.fromOffset(14, math.max(6, math.floor((frameHeight - 42) * 0.5)))
		iconBacking.Size = UDim2.fromOffset(42, 42)
		iconBacking.BackgroundColor3 = TopNotificationManager.Theme.Muted
		iconBacking.BorderSizePixel = 0
		iconBacking.Parent = messageFrame
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 4)
		iconCorner.Parent = iconBacking

		local messageRequiredItem = Instance.new("ImageLabel")
		messageRequiredItem.Name = "RequiredItem"
		messageRequiredItem.BackgroundTransparency = 1
		messageRequiredItem.Position = UDim2.fromOffset(5, 5)
		messageRequiredItem.Size = UDim2.fromOffset(32, 32)
		messageRequiredItem.Image = itemImage
		messageRequiredItem.ImageRectSize = Vector2.new(64, 64)
		messageRequiredItem.ImageRectOffset = Vector2.new(item.ImageOffsetX, item.ImageOffsetY)
		messageRequiredItem.Parent = iconBacking
	end

	messageFrame.Visible = true
	TopNotificationManager.StartLifetime(messageFrame, fadeTime)
end

return functions
