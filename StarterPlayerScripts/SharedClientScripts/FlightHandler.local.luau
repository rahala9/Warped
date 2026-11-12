local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local InputRoot = PlayerGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local FlightContext = InputRoot:WaitForChild("FlightContext")
local SwitchFlightModeAction = FlightContext:WaitForChild("SwitchFlightModeAction")
local ToggleFlightAssistAction = FlightContext:WaitForChild("ToggleFlightAssistAction")
local ToggleVerticalThrustersAction = FlightContext:WaitForChild("ToggleVerticalThrustersAction")
local BrakeAction = FlightContext:WaitForChild("BrakeAction")
local ExitShipAction = FlightContext:WaitForChild("ExitShipAction")
local TargetAction = FlightContext:WaitForChild("TargetAction")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")

-- functions
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local SpaceFlightFunctions = require(script.Parent:WaitForChild("SpaceFlightFunctions"))
local EVAFunctions = require(script.Parent:WaitForChild("EVAFunctions"))

-- Assets
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

SwitchFlightModeAction.Pressed:Connect(function()
	SpaceFlightFunctions.ToggleTranslationMode(HRP)
end)

ToggleFlightAssistAction.Pressed:Connect(function()
	SpaceFlightFunctions.ToggleFlightForceMode(HRP)
end)

ToggleVerticalThrustersAction.Pressed:Connect(function()
	SpaceFlightFunctions.ToggleVerticalMode(HRP)
end)

BrakeAction.Pressed:Connect(function()
	SpaceFlightFunctions.ToggleBrake()
end)

BrakeAction.Released:Connect(function()
	SpaceFlightFunctions.ToggleBrake()
end)

ExitShipAction.Pressed:Connect(function()
	SpaceFlightFunctions.ExitShip()
end)

TargetAction.Pressed:Connect(function()
	if PlayerState.IsFlying then
		SpaceFlightFunctions.CycleTarget()
	end
end)

SetPilotedShip.OnClientEvent:Connect(function(pilotedShip)
	if pilotedShip then
		PlayerState.IsFlying = true
		SpaceFlightFunctions.StartFlying(humanoid, HRP, pilotedShip)
	else
		PlayerState.IsFlying = false
		SpaceFlightFunctions.StopFlying(humanoid, HRP, pilotedShip)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if PlayerState.IsFlying then
		SpaceFlightFunctions.FlightHeartbeat(dt, humanoid, HRP)
	end

	if EVAFunctions.IsActive then
		EVAFunctions.EVAHeartbeat(dt, humanoid, HRP)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if PlayerState.IsFlying then
		SpaceFlightFunctions.CameraRenderStep(dt, HRP)
	end
end)