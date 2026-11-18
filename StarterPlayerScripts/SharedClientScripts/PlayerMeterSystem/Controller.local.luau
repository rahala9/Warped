local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("PlayerMeterSystem"):WaitForChild("Config"))
local player = Players.LocalPlayer
local toolbeltGui = player:WaitForChild("PlayerGui"):WaitForChild("SharedGUI"):WaitForChild("ToolbeltGui")

local function createBar(definition)
	local ui = definition.UI
	local existing = toolbeltGui:FindFirstChild(ui.Name)
	if existing and existing:IsA("Frame") then
		return existing
	end

	local bar = Instance.new("Frame")
	bar.Name = ui.Name
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	bar.BackgroundTransparency = 0.08
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.Parent = toolbeltGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = ui.FillColor
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, ui.GradientDark),
		ColorSequenceKeypoint.new(1, ui.GradientBright),
	})
	gradient.Rotation = 90
	gradient.Parent = fill

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.fromScale(1, 1)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamBold
	value.TextColor3 = ui.TextColor
	value.TextSize = 10
	value.TextStrokeColor3 = ui.TextStrokeColor
	value.TextStrokeTransparency = 0.25
	value.Parent = bar

	return bar
end

local function bindMeter(definition)
	local ui = definition.UI
	local bar = createBar(definition)
	local fill = bar:WaitForChild("Fill")
	local value = bar:WaitForChild("Value")
	local activeTween = nil

	bar.Visible = true
	bar.Position = ui.Position
	bar.Size = ui.Size
	bar.ZIndex = ui.ZIndex
	fill.ZIndex = ui.ZIndex + 1
	value.ZIndex = ui.ZIndex + 2

	local function update()
		local maximum = tonumber(player:GetAttribute(definition.MaximumAttribute)) or definition.Maximum
		local current = tonumber(player:GetAttribute(definition.CurrentAttribute)) or definition.Default
		maximum = math.max(1, maximum)
		current = math.clamp(current, 0, maximum)

		if activeTween then
			activeTween:Cancel()
		end
		activeTween = TweenService:Create(
			fill,
			TweenInfo.new(Config.UpdateInterval, Enum.EasingStyle.Linear),
			{ Size = UDim2.fromScale(current / maximum, 1) }
		)
		activeTween:Play()
		value.Text = string.format("%d / %d", math.floor(current + 0.5), math.floor(maximum + 0.5))
	end

	update()
	player:GetAttributeChangedSignal(definition.CurrentAttribute):Connect(update)
	player:GetAttributeChangedSignal(definition.MaximumAttribute):Connect(update)
end

for _, definition in pairs(Config.Meters) do
	bindMeter(definition)
end
