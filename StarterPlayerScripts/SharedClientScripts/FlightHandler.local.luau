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

-- Keep the action names accurate for any UI that reads them directly.
SwitchFlightModeAction.DisplayName = "Toggle Planar / 3D Flight"
ToggleVerticalThrustersAction.DisplayName = "Toggle World / Ship Vertical Thrusters"
TargetAction.DisplayName = "Target Enemy Ship"

-- The ship's H panel is an authored multiline TextLabel rather than Roblox's
-- automatic InputAction help. Its instance lives in PlayerGui and is not part
-- of the synced source tree, so replace its stale contents when it appears.
local SHIP_HELP_TEXT = table.concat({
	"W/S - Throttle Up/Down",
	"A/D - Strafe Left/Right",
	"Mouse - Aim/Steer",
	"Space/Ctrl - Up/Down",
	"Shift - Boost",
	"X - Brake",
	"F - Flight Mode: Planar/3D",
	"T - Target Enemy Ship",
	"L - Land (when prompted)",
	"P - Power Conduit",
	"U - Vertical: World/Ship",
}, "\n")

local function updateShipHelp(instance: Instance)
	if not (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then
		return
	end

	local text = instance.Text
	local isShipHelp = string.find(text, "W/S - Throttle Up/Down", 1, true)
		and (string.find(text, "Toggle Force Mode", 1, true)
			or string.find(text, "Toggle Translation", 1, true)
			or string.find(text, "Toggle Vertical Mode", 1, true))

	if isShipHelp then
		instance.Text = SHIP_HELP_TEXT
	end
end

for _, descendant in PlayerGui:GetDescendants() do
	updateShipHelp(descendant)
end

PlayerGui.DescendantAdded:Connect(function(descendant)
	-- Cloned UI generally has its text before parenting, but defer once so a
	-- creator that assigns Text immediately afterward is handled as well.
	task.defer(updateShipHelp, descendant)
end)

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")

-- functions
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local SpaceFlightFunctions = require(script.Parent:WaitForChild("SpaceFlightFunctions"))
local EVAFunctions = require(script.Parent:WaitForChild("EVAFunctions"))

local launchGui = Instance.new("ScreenGui")
launchGui.Name = "FlightLaunchGui"
launchGui.DisplayOrder = 1000
launchGui.IgnoreGuiInset = true
launchGui.ResetOnSpawn = false
launchGui.Enabled = false
launchGui.Parent = PlayerGui

local launchFrame = Instance.new("Frame")
launchFrame.Name = "Prompt"
launchFrame.AnchorPoint = Vector2.new(0.5, 0.5)
launchFrame.Position = UDim2.fromScale(0.5, 0.82)
launchFrame.Size = UDim2.fromOffset(390, 68)
launchFrame.BackgroundColor3 = Color3.fromRGB(8, 16, 24)
launchFrame.BackgroundTransparency = 0.12
launchFrame.BorderSizePixel = 0
launchFrame.Parent = launchGui

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 8)
launchCorner.Parent = launchFrame

local launchStroke = Instance.new("UIStroke")
launchStroke.Color = Color3.fromRGB(70, 205, 255)
launchStroke.Thickness = 2
launchStroke.Transparency = 0.15
launchStroke.Parent = launchFrame

local launchLabel = Instance.new("TextLabel")
launchLabel.Name = "Message"
launchLabel.Size = UDim2.fromScale(1, 1)
launchLabel.BackgroundTransparency = 1
launchLabel.Font = Enum.Font.GothamBold
launchLabel.TextColor3 = Color3.fromRGB(235, 250, 255)
launchLabel.TextSize = 18
launchLabel.TextWrapped = true
launchLabel.Parent = launchFrame

local function updateLaunchPrompt()
	local launchState = SpaceFlightFunctions.LaunchState
	local landingMessageActive = SpaceFlightFunctions.LandingMessage ~= nil
		and os.clock() < SpaceFlightFunctions.LandingMessageUntil
	launchGui.Enabled = PlayerState.IsFlying
		and (launchState ~= "Flying"
			or SpaceFlightFunctions.LandingAvailable
			or SpaceFlightFunctions.LandingBlockedReason ~= nil
			or landingMessageActive)

	if landingMessageActive then
		launchLabel.Text = "LANDING ABORTED\n" .. SpaceFlightFunctions.LandingMessage
	elseif launchState == "AwaitingLaunch" then
		launchLabel.Text = "SHIP PARKED\n[SPACE]  LAUNCH"
	elseif launchState == "Launching" then
		launchLabel.Text = "LAUNCHING\nVertical thrusters engaged"
	elseif launchState == "Flying" and SpaceFlightFunctions.LandingAvailable then
		launchLabel.Text = "LANDING ZONE\n[L]  LAND"
	elseif launchState == "Flying" and SpaceFlightFunctions.LandingBlockedReason then
		launchLabel.Text = "LANDING UNAVAILABLE\n" .. SpaceFlightFunctions.LandingBlockedReason
	elseif launchState == "Landing" then
		launchLabel.Text = "LANDING\nAutopilot engaged"
	elseif launchState == "Landed" then
		launchLabel.Text = "LANDED\n[E] EXIT   •   [SPACE] LAUNCH"
	end
end

-- Assets
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

SwitchFlightModeAction.Pressed:Connect(function()
	if not SpaceFlightFunctions.AreFlightControlsEnabled() then return end
	SpaceFlightFunctions.ToggleTranslationMode(HRP)
end)

ToggleFlightAssistAction.Pressed:Connect(function()
	if not SpaceFlightFunctions.AreFlightControlsEnabled() then return end
	SpaceFlightFunctions.ToggleFlightForceMode(HRP)
end)

ToggleVerticalThrustersAction.Pressed:Connect(function()
	if not SpaceFlightFunctions.AreFlightControlsEnabled() then return end
	SpaceFlightFunctions.ToggleVerticalMode(HRP)
end)

BrakeAction.Pressed:Connect(function()
	if not SpaceFlightFunctions.AreFlightControlsEnabled() then return end
	SpaceFlightFunctions.ToggleBrake()
end)

BrakeAction.Released:Connect(function()
	if not SpaceFlightFunctions.AreFlightControlsEnabled() then return end
	SpaceFlightFunctions.ToggleBrake()
end)

ExitShipAction.Pressed:Connect(function()
	if not SpaceFlightFunctions.CanExitShip() then return end
	SpaceFlightFunctions.ExitShip()
end)

TargetAction.Pressed:Connect(function()
	if SpaceFlightFunctions.AreFlightControlsEnabled() then
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
	updateLaunchPrompt()
	if PlayerState.IsFlying then
		SpaceFlightFunctions.CameraRenderStep(dt, HRP)
	end
end)
