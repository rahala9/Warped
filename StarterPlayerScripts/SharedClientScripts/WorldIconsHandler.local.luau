local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:wait()
local HRP = char:WaitForChild("HumanoidRootPart")
local CollectionService = game:GetService("CollectionService")

local step_counter = 0
local timeChangeInterval = 2

LocalPlayer.CharacterAdded:Connect(function(character)
	char = character
	local humanoid = character:WaitForChild("Humanoid")
	HRP = character:WaitForChild("HumanoidRootPart")
end)

RunService.Heartbeat:Connect(function(step)
	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval

		
		--Handle hiding world icons when close to them (minimum distance)
		for _,icon in pairs(CollectionService:GetTagged("WorldIcon")) do
			
			--Skip if adornee is nil
			if (icon.Parent.Adornee == nil) then continue end
			
			if ((icon.Parent.Adornee.CFrame.Position - HRP.Position).Magnitude < 40) then
				icon.Visible = false
			else
				icon.Visible = true
			end
		end



	end
end)
