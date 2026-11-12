local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CurrentPlayer = game.Players.LocalPlayer

local ModeManager = require(script.Parent:WaitForChild("ModeManager"))

local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local ContextSwitchingContext = InputRoot:WaitForChild("ContextSwitchingContext")

local SwitchContextToEmotesAction = ContextSwitchingContext:WaitForChild("SwitchContextToEmotesAction")
local ShowAdminAction = ContextSwitchingContext:WaitForChild("ShowAdminAction")


local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")

local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")

local MouseLoc = Remotes:WaitForChild("MouseLoc")
local MouseTarget = Remotes:WaitForChild("MouseTarget")
local MouseOrigin = Remotes:WaitForChild("MouseOrigin")
local Mouse = CurrentPlayer:GetMouse()

local camera = workspace.CurrentCamera

SwitchContextToEmotesAction.Pressed:Connect(function()
	ModeManager:SetMode(ModeManager.Modes.Emotes)
end)

ShowAdminAction.Pressed:Connect(function()
	ModeManager:SetMode(ModeManager.Modes.Admin)
end)

SetPilotedShip.OnClientEvent:Connect(function(pilotedShip)
	if (pilotedShip) then
		ModeManager:SetMode(ModeManager.Modes.Flight)

	else
		--TODO check if in space then go EVA mode
		ModeManager:SetMode(ModeManager.Modes.Gameplay)
	end
end)


function MouseLoc.OnClientInvoke()
	return game:GetService("Players").LocalPlayer:GetMouse().Hit.Position
end

function MouseOrigin.OnClientInvoke()
	return game:GetService("Players").LocalPlayer:GetMouse().Origin.Position
end

function MouseTarget.OnClientInvoke()
	return game:GetService("Players").LocalPlayer:GetMouse().Target
end

function getMouseTargetWithFilter(cursorPosition, filter)
	local ray = camera:ScreenPointToRay(cursorPosition.x, cursorPosition.y, 900)
	return workspace:FindPartOnRayWithIgnoreList(ray, filter)
end

local debounceMouse = false

