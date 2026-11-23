local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("SecurityResponseSystem"):WaitForChild("Config"))
local InputFactory = require(
	ReplicatedStorage.SecurityResponseSystem:WaitForChild("SecurityInputContextFactory")
)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedGui = playerGui:WaitForChild("SharedGUI")
local toolbeltGui = sharedGui:WaitForChild("ToolbeltGui")
local inputRoot = sharedGui:WaitForChild("InputContexts")
local RightHUDManager = require(script.Parent.Parent:WaitForChild("RightHUDManager"))
local securityContext, surrenderAction = InputFactory.Ensure(inputRoot)
local remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local incidentChanged = remotes:WaitForChild(Config.IncidentRemoteName)
local surrenderRemote = remotes:WaitForChild(Config.SurrenderRemoteName)

local gui = Instance.new("ScreenGui")
gui.Name = "SecurityResponseGui"
gui.DisplayOrder = 109
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "IncidentPanel"
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -16, 1, -104)
panel.Size = UDim2.fromOffset(340, 112)
panel.BackgroundColor3 = Color3.fromRGB(25, 9, 12)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 72, 72)
stroke.Parent = panel

local header = Instance.new("TextLabel")
header.BackgroundTransparency = 1
header.Position = UDim2.fromOffset(12, 8)
header.Size = UDim2.new(1, -24, 0, 24)
header.Font = Enum.Font.GothamBold
header.TextColor3 = Color3.fromRGB(255, 90, 90)
header.TextSize = 17
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = panel

local jurisdictionLabel = Instance.new("TextLabel")
jurisdictionLabel.BackgroundTransparency = 1
jurisdictionLabel.Position = UDim2.fromOffset(12, 34)
jurisdictionLabel.Size = UDim2.new(1, -24, 0, 18)
jurisdictionLabel.Font = Enum.Font.Gotham
jurisdictionLabel.TextColor3 = Color3.fromRGB(235, 205, 205)
jurisdictionLabel.TextSize = 12
jurisdictionLabel.TextXAlignment = Enum.TextXAlignment.Left
jurisdictionLabel.Parent = panel

local timerLabel = Instance.new("TextLabel")
timerLabel.BackgroundTransparency = 1
timerLabel.Position = UDim2.fromOffset(12, 55)
timerLabel.Size = UDim2.new(1, -24, 0, 18)
timerLabel.Font = Enum.Font.Code
timerLabel.TextColor3 = Color3.fromRGB(255, 175, 95)
timerLabel.TextSize = 13
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = panel

local surrenderButton = Instance.new("TextButton")
surrenderButton.AnchorPoint = Vector2.new(1, 1)
surrenderButton.Position = UDim2.new(1, -10, 1, -9)
surrenderButton.Size = UDim2.fromOffset(156, 27)
surrenderButton.BackgroundColor3 = Color3.fromRGB(86, 29, 29)
surrenderButton.BorderSizePixel = 0
surrenderButton.Font = Enum.Font.GothamBold
surrenderButton.Text = "[" .. Config.SurrenderKey.Name .. "] SURRENDER"
surrenderButton.TextColor3 = Color3.fromRGB(255, 225, 225)
surrenderButton.TextSize = 12
surrenderButton.Visible = false
surrenderButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 4)
buttonCorner.Parent = surrenderButton

local activeIncident
local surrenderLocked = false
local SECURITY_RESERVATION_ID = "SecurityResponse"
local SECURITY_PANEL_HEIGHT = 112
local SECURITY_STACK_GAP = 10

local function updatePanelLayout()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local width = math.max(220, math.min(340, viewport.X - 32))
	local bottomInset = RightHUDManager:GetBottomInset(width + 32)
	panel.Size = UDim2.fromOffset(width, SECURITY_PANEL_HEIGHT)
	panel.Position = UDim2.new(1, -16, 1, -bottomInset)
	RightHUDManager:SetBottomReservation(
		SECURITY_RESERVATION_ID,
		activeIncident and (SECURITY_PANEL_HEIGHT + SECURITY_STACK_GAP) or 0
	)
end

local function updateSurrenderAvailability()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local available = activeIncident ~= nil
		and activeIncident.response == "Arrest"
		and activeIncident.canSurrender == true
		and humanoid ~= nil
		and humanoid.SeatPart == nil
	securityContext.Enabled = available
	surrenderButton.Visible = available
end

local function clearLocalIncident()
	activeIncident = nil
	surrenderLocked = false
	panel.Visible = false
	surrenderButton.Text = "[" .. Config.SurrenderKey.Name .. "] SURRENDER"
	updatePanelLayout()
	updateSurrenderAvailability()
end

local function requestSurrender()
	if surrenderLocked or not activeIncident or not activeIncident.canSurrender then return end
	surrenderLocked = true
	surrenderButton.Text = "SURRENDERING..."
	surrenderRemote:FireServer()
	task.delay(1, function()
		surrenderLocked = false
		if activeIncident then surrenderButton.Text = "[" .. Config.SurrenderKey.Name .. "] SURRENDER" end
	end)
end

surrenderAction.Pressed:Connect(requestSurrender)
surrenderButton.Activated:Connect(requestSurrender)

incidentChanged.OnClientEvent:Connect(function(incident)
	if typeof(incident) ~= "table" then
		clearLocalIncident()
		return
	end

	activeIncident = incident
	surrenderLocked = false
	panel.Visible = true
	updatePanelLayout()
	updateSurrenderAvailability()
	surrenderButton.Text = "[" .. Config.SurrenderKey.Name .. "] SURRENDER"

	local lethal = activeIncident.response == "Lethal"
	local inCustody = activeIncident.response == "Custody"
	header.Text = inCustody and "IN CUSTODY"
		or (lethal and "LETHAL AUTHORIZATION" or "WANTED FOR ARREST")
	header.TextColor3 = inCustody and Color3.fromRGB(110, 205, 255)
		or (lethal and Color3.fromRGB(255, 55, 55) or Color3.fromRGB(255, 150, 70))
	stroke.Color = header.TextColor3
	jurisdictionLabel.Text = string.format(
		"%s  •  %s OFFENSE",
		tostring(activeIncident.jurisdiction or "Local Security"),
		string.upper(tostring(activeIncident.offenseClass or "Unknown"))
	)
end)

local viewportConnection
local function bindViewport()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = Workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePanelLayout)
	end
	updatePanelLayout()
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport)
if toolbeltGui:IsA("LayerCollector") then
	toolbeltGui:GetPropertyChangedSignal("Enabled"):Connect(updatePanelLayout)
end
toolbeltGui.DescendantAdded:Connect(function() task.defer(updatePanelLayout) end)
toolbeltGui.DescendantRemoving:Connect(function() task.defer(updatePanelLayout) end)
bindViewport()

local deathConnection
local function bindCharacter(character)
	if deathConnection then
		deathConnection:Disconnect()
		deathConnection = nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 10)
	if humanoid and player.Character == character then
		deathConnection = humanoid.Died:Connect(clearLocalIncident)
	end
end

if player.Character then task.spawn(bindCharacter, player.Character) end
player.CharacterAdded:Connect(function(character)
	clearLocalIncident()
	task.spawn(bindCharacter, character)
end)
player.CharacterRemoving:Connect(clearLocalIncident)

task.spawn(function()
	while gui.Parent do
		if activeIncident then
			local remaining = math.max(0, math.ceil((activeIncident.expiresAt or 0) - workspace:GetServerTimeNow()))
			local timerPrefix = activeIncident.response == "Custody" and "RELEASE IN" or "SECURITY ALERT"
			timerLabel.Text = string.format("%s  %02d:%02d", timerPrefix, math.floor(remaining / 60), remaining % 60)
		end
		updateSurrenderAvailability()
		task.wait(0.25)
	end
end)
