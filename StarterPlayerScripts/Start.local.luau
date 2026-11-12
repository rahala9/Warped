local starterGui = game:GetService('StarterGui')
local Player =  game:GetService("Players").LocalPlayer
local playerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("SharedClientScripts"):WaitForChild("UIManager"))

local StarterGui = game:GetService("StarterGui")

local function setCoreGui()
	local success = pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
		StarterGui:SetCore("TopbarEnabled", false)
	end)
	if not success then
		task.wait(0.1)
		setCoreGui()
	end
end

setCoreGui()