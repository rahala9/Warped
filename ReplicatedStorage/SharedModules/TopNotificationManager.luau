local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TopNotificationManager = {}

TopNotificationManager.Theme = {
	Background = Color3.fromRGB(7, 19, 29),
	Border = Color3.fromRGB(0, 196, 255),
	Title = Color3.fromRGB(125, 225, 255),
	Text = Color3.fromRGB(205, 225, 235),
	Muted = Color3.fromRGB(30, 52, 65),
}

local container
local nextToastOrder = 100

local function getContainer()
	if container and container.Parent then return container end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("TopNotificationGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "TopNotificationGui"
		gui.DisplayOrder = 110
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end

	container = gui:FindFirstChild("NotificationStack")
	if not container then
		container = Instance.new("Frame")
		container.Name = "NotificationStack"
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.new(0.5, 0, 0, 28)
		container.Size = UDim2.new(0, 380, 1, -40)
		container.BackgroundTransparency = 1
		container.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.Name = "NotificationLayout"
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Parent = container
	end
	return container
end

function TopNotificationManager.CreatePanel(name, width, height, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.fromOffset(width, height)
	frame.BackgroundColor3 = TopNotificationManager.Theme.Background
	frame.BorderSizePixel = 0
	frame.LayoutOrder = layoutOrder or 0
	frame.Parent = getContainer()

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Border"
	stroke.Color = TopNotificationManager.Theme.Border
	stroke.Thickness = 2
	stroke.Parent = frame

	return frame, stroke
end

function TopNotificationManager.NextToastOrder()
	nextToastOrder += 1
	return nextToastOrder
end

function TopNotificationManager.StartLifetime(frame, duration, options)
	options = options or {}
	duration = math.max(tonumber(duration) or 0, 0.1)

	local ownsTrack = options.Track == nil
	local track = options.Track
	if not track then
		track = Instance.new("Frame")
		track.Name = "LifetimeTrack"
		track.Position = UDim2.new(0, 8, 1, -6)
		track.Size = UDim2.new(1, -16, 0, 3)
		track.BackgroundColor3 = TopNotificationManager.Theme.Muted
		track.BorderSizePixel = 0
		track.Parent = frame
	end

	local fill = options.Fill
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "LifetimeFill"
		fill.BackgroundColor3 = options.Color or TopNotificationManager.Theme.Border
		fill.BorderSizePixel = 0
		fill.Parent = track
	end
	fill.BackgroundColor3 = options.Color or fill.BackgroundColor3

	local close = Instance.new("TextButton")
	close.Name = "Dismiss"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -6, 0, 5)
	close.Size = UDim2.fromOffset(24, 24)
	close.BackgroundTransparency = 1
	close.Font = Enum.Font.GothamBold
	close.Text = "X"
	close.TextColor3 = TopNotificationManager.Theme.Text
	close.TextSize = 14
	close.AutoButtonColor = true
	close.ZIndex = 20
	close.Parent = frame

	local growing = options.Direction == "Grow"
	fill.Size = growing and UDim2.fromScale(0, 1) or UDim2.fromScale(1, 1)
	local tween = TweenService:Create(
		fill,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ Size = growing and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 1) }
	)
	local finished = false
	local closeConnection
	local tweenConnection

	local function cleanup()
		if closeConnection then closeConnection:Disconnect() end
		if tweenConnection then tweenConnection:Disconnect() end
		if close.Parent then close:Destroy() end
		if ownsTrack and track.Parent then track:Destroy() end
	end

	local function dismiss()
		if finished then return end
		finished = true
		tween:Cancel()
		cleanup()
		if options.OnDismiss then
			options.OnDismiss()
		elseif frame.Parent then
			frame:Destroy()
		end
	end

	closeConnection = close.Activated:Connect(dismiss)
	tweenConnection = tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then dismiss() end
	end)
	tween:Play()

	return function()
		if finished then return end
		finished = true
		tween:Cancel()
		cleanup()
	end
end

return TopNotificationManager
