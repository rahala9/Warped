local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("CargoInspectionSystem"):WaitForChild("Config"))
local TopNotificationManager = require(
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("TopNotificationManager")
)
local event = ReplicatedStorage:WaitForChild("SharedRemotes")
	:WaitForChild("DockRemotes")
	:WaitForChild(Config.RemoteName)

local frame, stroke = TopNotificationManager.CreatePanel("InspectionBanner", 360, 70, 0)
frame.Visible = false

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -50, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "CUSTOMS SCAN"
title.TextColor3 = Color3.fromRGB(125, 225, 255)
title.TextSize = 18
title.Parent = frame

local detail = Instance.new("TextLabel")
detail.BackgroundTransparency = 1
detail.Position = UDim2.fromOffset(12, 32)
detail.Size = UDim2.new(1, -50, 0, 18)
detail.Font = Enum.Font.Gotham
detail.TextColor3 = Color3.fromRGB(205, 225, 235)
detail.TextSize = 12
detail.Text = "Analyzing cargo manifest..."
detail.Parent = frame

local track = Instance.new("Frame")
track.Position = UDim2.fromOffset(12, 56)
track.Size = UDim2.new(1, -24, 0, 5)
track.BackgroundColor3 = Color3.fromRGB(30, 52, 65)
track.BorderSizePixel = 0
track.Parent = frame

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(0, 196, 255)
fill.BorderSizePixel = 0
fill.Parent = track

local cancelLifetime

local function beginLifetime(duration, direction)
	if cancelLifetime then cancelLifetime() end
	cancelLifetime = TopNotificationManager.StartLifetime(frame, duration, {
		Track = track,
		Fill = fill,
		Direction = direction,
		Color = stroke.Color,
		OnDismiss = function()
			frame.Visible = false
		end,
	})
end

local function showResult(status, cargoName, fine, response, jurisdiction)
	frame.Visible = true

	if status == "Passed" then
		stroke.Color = Color3.fromRGB(75, 255, 145)
		fill.BackgroundColor3 = stroke.Color
		title.TextColor3 = stroke.Color
		title.Text = "SCAN CLEAR"
		detail.Text = cargoName .. " passed inspection"
	else
		stroke.Color = Color3.fromRGB(255, 70, 70)
		fill.BackgroundColor3 = stroke.Color
		title.TextColor3 = stroke.Color
		title.Text = response == "Arrest" and "ARREST RESPONSE REQUESTED"
			or response == "Lethal" and "LETHAL RESPONSE REQUESTED"
			or "CONTRABAND DETECTED"
		local fineText = (fine or 0) > 0 and string.format("  •  fine §%d", fine) or ""
		local authorityText = response ~= "Fine" and "  •  " .. tostring(jurisdiction or "Security") or ""
		detail.Text = cargoName .. " confiscated" .. fineText .. authorityText
	end
	beginLifetime(
		status == "Passed" and Config.PassedDisplayDuration or Config.DetectedDisplayDuration,
		"Shrink"
	)
end

event.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.status == "Scanning" then
		frame.Visible = true
		stroke.Color = Color3.fromRGB(0, 196, 255)
		fill.BackgroundColor3 = stroke.Color
		title.TextColor3 = Color3.fromRGB(125, 225, 255)
		title.Text = "CUSTOMS SCAN"
		detail.Text = "Analyzing " .. tostring(payload.cargoName or "cargo") .. "..."
		beginLifetime(payload.duration or Config.DefaultScanDelay, "Grow")
	elseif payload.status == "Passed" or payload.status == "Detected" then
		showResult(
			payload.status,
			tostring(payload.cargoName or "Cargo"),
			payload.fine,
			payload.response,
			payload.jurisdiction
		)
	end
end)
