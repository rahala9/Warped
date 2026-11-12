local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local OpenTeleporterGuiEvent = Remotes:WaitForChild("OpenTeleporterGui")
local TeleporterRequestEvent = Remotes:WaitForChild("TeleporterRequest")

local teleporterGui
local mainFrame
local listFrame

local function closeGui()
	if not teleporterGui or not mainFrame then return end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.18), {
		Position = UDim2.new(0.5, -300, 0.6, -220),
		BackgroundTransparency = 1,
	})

	tween:Play()

	tween.Completed:Once(function()
		if teleporterGui then
			teleporterGui.Enabled = false
		end
	end)
end

local function buildGui()
	local existing = playerGui:FindFirstChild("TeleporterGui")
	if existing then existing:Destroy() end

	teleporterGui = Instance.new("ScreenGui")
	teleporterGui.Name = "TeleporterGui"
	teleporterGui.ResetOnSpawn = false
	teleporterGui.Enabled = false
	teleporterGui.Parent = playerGui

	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 640, 0, 480) -- slightly bigger to fit larger text
	mainFrame.Position = UDim2.new(0.5, -320, 0, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(8,12,22)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = teleporterGui

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1,0,0,3)
	topBar.BackgroundColor3 = Color3.fromRGB(0,200,255)
	topBar.Parent = mainFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-56,0,50)
	title.Position = UDim2.new(0,16,0,6)
	title.BackgroundTransparency = 1
	title.Text = "SCI CO · TELEPORT TERMINAL"
	title.TextColor3 = Color3.fromRGB(0,200,255)
	title.Font = Enum.Font.Code
	title.TextSize = 22 -- 🔥 bigger title
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainFrame

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0,40,0,40)
	close.Position = UDim2.new(1,-48,0,6)
	close.Text = "✕"
	close.TextSize = 18 -- bigger X
	close.Font = Enum.Font.Code
	close.Parent = mainFrame
	close.MouseButton1Click:Connect(closeGui)

	listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1,-32,1,-110)
	listFrame.Position = UDim2.new(0,16,0,70)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,14) -- more spacing for bigger text
	layout.Parent = listFrame
end

local function clear()
	for _,c in ipairs(listFrame:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end

local function addButton(teleporterPath,loc)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,0,100) -- bigger container
	btn.BackgroundColor3 = Color3.fromRGB(14,20,36)
	btn.Text = ""
	btn.Parent = listFrame

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1,-20,0,50)
	name.Position = UDim2.new(0,10,0,6)
	name.BackgroundTransparency = 1
	name.Text = loc.name
	name.Font = Enum.Font.Code
	name.TextScaled = true -- 🔥 THIS is key
	name.TextColor3 = Color3.fromRGB(210,220,255)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = btn

	-- constrain so it doesn’t get TOO big
	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 26
	nameConstraint.MinTextSize = 16
	nameConstraint.Parent = name

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1,-20,0,40)
	desc.Position = UDim2.new(0,10,0,56)
	desc.BackgroundTransparency = 1
	desc.Text = loc.description or ""
	desc.Font = Enum.Font.Code
	desc.TextScaled = true -- 🔥 also important
	desc.TextColor3 = Color3.fromRGB(0,200,255)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = btn

	local descConstraint = Instance.new("UITextSizeConstraint")
	descConstraint.MaxTextSize = 18
	descConstraint.MinTextSize = 12
	descConstraint.Parent = desc

	btn.MouseButton1Click:Connect(function()
		TeleporterRequestEvent:FireServer(teleporterPath,loc.id)
		closeGui()
	end)
end

local function open(teleporterPath,locations)
	if not teleporterGui then buildGui() end

	clear()

	for _,loc in ipairs(locations) do
		addButton(teleporterPath,loc)
	end

	teleporterGui.Enabled = true

	mainFrame.Position = UDim2.new(0.5,-300,0.6,-220)

	TweenService:Create(mainFrame, TweenInfo.new(0.25), {
		Position = UDim2.new(0.5,-300,0,0)
	}):Play()
end

OpenTeleporterGuiEvent.OnClientEvent:Connect(function(teleporterPath,locations)
	open(teleporterPath,locations)
end)