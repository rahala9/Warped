local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local MessagePlayerEvent = Remotes:WaitForChild("MessagePlayer")
local DisplayNoteEvent = Remotes:WaitForChild("DisplayNote")
local GuiMessageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GuiMessageFunctions"))

local CurrentPlayer = game.Players.LocalPlayer
local playerGui = CurrentPlayer:WaitForChild("PlayerGui")
local messageFrame = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("MessageFrame")
local message = messageFrame:WaitForChild("GraphicFrame"):WaitForChild("message")
local requiredItem = messageFrame:WaitForChild("GraphicFrame"):WaitForChild("Picture"):WaitForChild("RequiredItem")

local noteGUI = playerGui:WaitForChild("SharedGUI"):WaitForChild("ScreenGui"):WaitForChild("Note")
local noteGUITitle = noteGUI:WaitForChild("ATitleFrame"):WaitForChild("BTitle")
local noteGUIMessage = noteGUI:WaitForChild("NoteText")
local noteGUICloseButton = noteGUI:WaitForChild("CloseButton")

MessagePlayerEvent.OnClientEvent:Connect(function(message,requiredItemName,keepOn,posX,posY,textColor,fadeTime,startTime,guiType,titleType)
	GuiMessageFunctions.DisplayOnScreenMessage(message,requiredItemName,keepOn,posX,posY,textColor,fadeTime,startTime,guiType,titleType)
end)

DisplayNoteEvent.OnClientEvent:Connect(function(message,guiType,titleType)
	GuiMessageFunctions.DisplayOnScreenNote(message,guiType,titleType)
end)

noteGUICloseButton.Activated:Connect(function()
	noteGUI.Visible = false
end)

