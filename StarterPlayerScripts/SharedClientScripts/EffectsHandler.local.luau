local ReplicatedStorage = game:GetService("ReplicatedStorage")
local addEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AddEffect")
local removeEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveEffect")
local effectsDef = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects"))
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CurrentPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local BlurGui = CurrentPlayer.PlayerGui:WaitForChild("SharedGUI"):WaitForChild("BlurGui")
local EffectsGui = CurrentPlayer.PlayerGui:WaitForChild("SharedGUI"):WaitForChild("EffectsGui")
local effectsFrame = EffectsGui.EffectsFrame
local icons = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Icons")

local Effects = {} 

addEffectEvent.OnClientEvent:Connect(function(effect)

	local EffectIcon = Instance.new("ImageLabel")

	EffectIcon.Name = effect.Name
	EffectIcon.Size = UDim2.new(0,36,0,36)
	--EffectIcon.BackgroundTransparency = .1
	--EffectIcon.BackgroundColor3 = Color3.new(0.109804, 1, 0.0980392)
	local icon = icons:FindFirstChild("EffectIcon") --icons:FindFirstChild(effect.Name.."Icon")
	if (icon ~= nil) then
		EffectIcon.Image = "rbxassetid://117028963756784" --icon.Image
		EffectIcon.ImageRectOffset = Vector2.new(effect.ImageOffsetX,effect.ImageOffsetY)
		EffectIcon.ImageRectSize = icon.ImageRectSize
	end

	EffectIcon.Parent = effectsFrame
	
	local EffectDescription = Instance.new("TextLabel")
	
	EffectDescription.Text = effect.Name
	EffectDescription.Visible = false
	EffectDescription.Parent = EffectIcon
	
	--Effects description gui
	local effectsDescriptionFrame = Instance.new("Frame")
	effectsDescriptionFrame.Size = UDim2.new(0, 100, 0, 0)
	effectsDescriptionFrame.AutomaticSize = Enum.AutomaticSize.Y
	effectsDescriptionFrame.Position = UDim2.new(0,0 , 0.5, 0)
	effectsDescriptionFrame.BackgroundColor3 = Color3.fromRGB(0, 188, 240)
	effectsDescriptionFrame.BorderSizePixel = 0
	effectsDescriptionFrame.BackgroundTransparency = 0.1
	effectsDescriptionFrame.Visible = false
	effectsDescriptionFrame.Parent = effectsFrame
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5) -- spacing between elements
	layout.Parent = effectsDescriptionFrame
	
	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = effect.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne -- Fun font!
	nameLabel.Parent = effectsDescriptionFrame	

	-- Description label
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 1, 0)
	descLabel.Position = UDim2.new(0, 0, 0, .5)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = effectsDef[effect.Name].Description
	descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	descLabel.TextStrokeTransparency = 0
	descLabel.TextWrapped = true
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.FredokaOne -- Another fun font
	descLabel.Parent = effectsDescriptionFrame
	
	
	---End Effects Description gui
	
	local effectCorners = Instance.new("UICorner")
	effectCorners.Parent = EffectIcon

	local effectStroke = Instance.new("UIStroke")
	effectStroke.Thickness = 2
	effectStroke.Parent = EffectIcon

	local effectTime = Instance.new("TextLabel")
	effectTime.Name = "EffectTime"
	effectTime.Position = UDim2.new(.9,0,.9,0)
	effectTime.Size = UDim2.new(.1,0,.1,0)
	effectTime.TextColor3 = Color3.fromRGB(255,255,255)
	effectTime.TextSize = 14
	effectTime.Font = Enum.Font.SourceSansBold
	effectTime.Text = effect.Effect.TimeInEffect
	effectTime.Parent = EffectIcon
	
	local hoverConnection = EffectIcon.MouseEnter:Connect(function()
		effectsDescriptionFrame.Visible = true
	end)
	
	local exitHoverConnection = EffectIcon.MouseLeave:Connect(function()
		effectsDescriptionFrame.Visible = false
	end)
	

	Effects[effect.Name] = {GUI=EffectIcon,Effect=effect,HoverConnection=hoverConnection,ExitHoverConnection=exitHoverConnection}


	if (effect.Effect.Type=="Screen" and effect.Effect.Action == "Blur") then
		BlurGui.Enabled = true

		BlurGui.Frame.BackgroundColor = BrickColor.White()
		BlurGui.Frame.BackgroundTransparency = 0
		task.wait(.1)
		BlurGui.Frame.BackgroundTransparency = 1
		BlurGui.Frame.BackgroundColor =BrickColor.Black()

		for i=1,0,-0.1 do			
			BlurGui.Frame.BackgroundTransparency = i
			task.wait(.1)
		end

	end


end)

removeEffectEvent.OnClientEvent:Connect(function(effect)
	
	if (not Effects[effect.Name]) then
		warn("EffectsHandler.removeEffectEvent: no such effect found:",effect)
		return
	end

	local hoverConnection = Effects[effect.Name].HoverConnection
	local exitHoverConnection = Effects[effect.Name].ExitHoverConnection
	
	hoverConnection:Disconnect()
	exitHoverConnection:Disconnect()
	
	Effects[effect.Name] = nil

	for _, effectIcon in pairs(effectsFrame:GetChildren()) do

		if (effectIcon.Name == effect.Name) then
			effectIcon:Destroy()
		end
	end

	if (effect.Effect.Type=="Screen" and effect.Effect.Action == "Blur") then
		BlurGui.Enabled = false
		BlurGui.Frame.BackgroundTransparency = 1
	end

end)

local step_counter = 0
local timeChangeInterval = 1

RunService.Heartbeat:Connect(function(step)
	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval
		if (Effects ~= nil) then
			for _, effects in pairs(Effects) do
				if (effects ~= nil) then
					if (effects.Effect.Effect.CurrentEffectTime > 0) then
						effects.Effect.Effect.CurrentEffectTime = effects.Effect.Effect.CurrentEffectTime - 1
						effects.GUI:WaitForChild("EffectTime").Text = effects.Effect.Effect.CurrentEffectTime
					end
				end	
			end
		end



	end
end)
