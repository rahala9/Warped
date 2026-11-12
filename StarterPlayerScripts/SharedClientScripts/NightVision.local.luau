-- StarterPlayerScripts > LocalScript (client-side)
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local addEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AddEffect")
local removeEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveEffect")


local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Create post effects under the camera (local-only)
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "NV_Color"
cc.Enabled = false
cc.Parent = camera

local bloom = Instance.new("BloomEffect")
bloom.Name = "NV_Bloom"
bloom.Enabled = false
bloom.Intensity = 0.3     -- subtle halo on bright pixels
bloom.Size = 24
bloom.Threshold = 1.0
bloom.Parent = camera

-- (Optional) film grain overlay
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NV_Overlay"
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local noise = Instance.new("ImageLabel")
noise.Name = "Noise"
noise.Size = UDim2.fromScale(1, 1)
noise.Position = UDim2.fromOffset(0, 0)
noise.BackgroundTransparency = 1
noise.Image = "rbxassetid://10962260384" -- any seamless monochrome noise tile works
noise.ImageTransparency = 0.8            -- super subtle
noise.ScaleType = Enum.ScaleType.Tile
noise.SliceScale = 0
noise.TileSize = UDim2.new(0, 256, 0, 256) -- tile size; adjust to taste
noise.Parent = screenGui

-- Simple shimmer on the noise so it feels alive
task.spawn(function()
	while task.wait(0.1) do
		if screenGui.Enabled then
			noise.Position = UDim2.fromOffset(math.random(-4,4), math.random(-4,4))
		end
	end
end)

-- Smooth enable/disable
local function tweenProps(inst, time, props)
	return TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local nvOn = false
local function enableNV()
	nvOn = true
	cc.Enabled = true
	bloom.Enabled = true
	screenGui.Enabled = true

	-- Typical NVG look: green tint, lifted mids, slightly desaturated
	cc.TintColor = Color3.fromRGB(170, 255, 170)
	cc.Brightness = 0
	cc.Contrast = 0
	cc.Saturation = 0

	tweenProps(cc, 0.25, {
		Brightness = 0.35,   -- lift darkness
		Contrast   = 0.15,   -- add definition
		Saturation = -0.25,  -- slight desaturation
	}):Play()
end

local function disableNV()
	nvOn = false
	-- tween back then disable
	local t = tweenProps(cc, 0.2, {Brightness = 0, Contrast = 0, Saturation = 0})
	t.Completed:Connect(function()
		if not nvOn then
			cc.Enabled = false
			bloom.Enabled = false
			screenGui.Enabled = false
		end
	end)
	t:Play()
end

local function toggleNV()
	if nvOn then disableNV() else enableNV() end
end

-- Bind to "N"
ContextActionService:BindAction("ToggleNightVision", function(_, state)
	if state == Enum.UserInputState.Begin then
		toggleNV()
	end
end, false, Enum.KeyCode.K)

addEffectEvent.OnClientEvent:Connect(function(effect)
	if (effect.Name == "NightVision") then
		enableNV()
	end
end)

removeEffectEvent.OnClientEvent:Connect(function(effect)
	if (effect.Name == "NightVision") then
		disableNV()
	end
end)
