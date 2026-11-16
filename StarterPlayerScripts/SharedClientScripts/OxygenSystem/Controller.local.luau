local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.SharedModules.OxygenSystem.Config)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local toolbeltGui = playerGui:WaitForChild("SharedGUI"):WaitForChild("ToolbeltGui")
local Attributes = Config.Attributes
local UI = Config.UI

local function createBar()
	local existing = toolbeltGui:FindFirstChild(UI.Name)
	if existing and existing:IsA("Frame") then
		return existing
	end

	local bar = Instance.new("Frame")
	bar.Name = UI.Name
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	bar.BackgroundTransparency = 0.08
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.Parent = toolbeltGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = UI.FillColor
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, UI.GradientDark),
		ColorSequenceKeypoint.new(1, UI.GradientBright),
	})
	gradient.Rotation = 90
	gradient.Parent = fill

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextColor3 = Color3.fromRGB(235, 250, 255)
	value.TextSize = 10
	value.TextStrokeColor3 = Color3.fromRGB(0, 20, 40)
	value.TextStrokeTransparency = 0.25
	value.Parent = bar

	return bar
end

local oxygenBar = createBar()
local fill = oxygenBar:WaitForChild("Fill")
local value = oxygenBar:WaitForChild("Value")
local activeTween = nil

local function applyLayout()
	oxygenBar.Visible = true
	oxygenBar.Position = UI.Position
	oxygenBar.Size = UI.Size
	oxygenBar.ZIndex = UI.ZIndex
	fill.Visible = true
	fill.ZIndex = UI.ZIndex + 1
	value.Visible = true
	value.ZIndex = UI.ZIndex + 2
end

local function updateBar()
	local maximum = tonumber(player:GetAttribute(Attributes.Maximum)) or Config.MaxOxygen
	local current = tonumber(player:GetAttribute(Attributes.Current)) or maximum
	maximum = math.max(1, maximum)
	current = math.clamp(current, 0, maximum)

	if activeTween then
		activeTween:Cancel()
	end

	activeTween = TweenService:Create(
		fill,
		TweenInfo.new(Config.UpdateInterval, Enum.EasingStyle.Linear),
		{Size = UDim2.fromScale(current / maximum, 1)}
	)
	activeTween:Play()
	value.Text = string.format("%d / %d", math.floor(current + 0.5), math.floor(maximum + 0.5))
end

applyLayout()
updateBar()

player:GetAttributeChangedSignal(Attributes.Current):Connect(updateBar)
player:GetAttributeChangedSignal(Attributes.Maximum):Connect(updateBar)
