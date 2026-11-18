local CloseButtonStyle = {}

local NORMAL_BACKGROUND = Color3.fromRGB(18, 30, 55)
local HOVER_BACKGROUND = Color3.fromRGB(25, 45, 75)
local NORMAL_TEXT = Color3.fromRGB(0, 220, 255)
local HOVER_TEXT = Color3.fromRGB(255, 255, 255)
local BORDER = Color3.fromRGB(0, 60, 90)

function CloseButtonStyle.Apply(button: TextButton)
	button.Name = "CloseBtn"
	button.Size = UDim2.fromOffset(24, 24)
	button.Position = UDim2.new(1, -32, 0, 8)
	button.BackgroundColor3 = NORMAL_BACKGROUND
	button.BorderSizePixel = 0
	button.Text = "X"
	button.TextColor3 = NORMAL_TEXT
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.AutoButtonColor = false
	button.ZIndex = 15

	local corner = button:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = button

	local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = BORDER
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = HOVER_BACKGROUND
		button.TextColor3 = HOVER_TEXT
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = NORMAL_BACKGROUND
		button.TextColor3 = NORMAL_TEXT
	end)

	return button
end

return CloseButtonStyle
