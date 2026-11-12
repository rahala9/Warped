
local Players = game:GetService("Players")
local CurrentPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local DailyRewardsGui = CurrentPlayer.PlayerGui:WaitForChild("SharedGUI"):WaitForChild("DailyRewardsGui")
local ClaimFrame = DailyRewardsGui:WaitForChild("MainFrame"):WaitForChild("ButtonsFrame"):WaitForChild("ClaimFrame")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetDailyRewardEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetDailyReward")
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local ImageFrame = DailyRewardsGui:WaitForChild("MainFrame"):WaitForChild("ImageFrame")
local ShowDailyRewardUIEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ShowDailyRewardUI")

ShowDailyRewardUIEvent.OnClientEvent:Connect(function(streak)
	ImageFrame.ImageLabel.Streak.Visible = true
	ImageFrame.ImageLabel.Streak.Text = streak.." Day Playing Streak"
	DailyRewardsGui.Enabled = true
end)

ClaimFrame.Claim.Activated:Connect(function()
	
	
	if (ClaimFrame.Claim.Text == "Close") then
		DailyRewardsGui.Enabled = false
		return
	end
	
	local dailyReward = GetDailyRewardEvent:InvokeServer() --Maybe more efficient to just get active tool inventory item
	
	if (not dailyReward) then
		return
	end
	
	--Logger.Debug("DAILY ALLOWANCE:"..dailyReward.Allowance)
	ImageFrame.RewardedMoney.Visible = true
	ImageFrame.RewardedMoney.MoneyAmount.Text = "$"..dailyReward.Allowance
	
	if (dailyReward.PlayingStreakItemName ~= nil and dailyReward.PlayingStreakItemName ~= "") then
		--Logger.Debug("PLAYING STREAK REWARD:"..dailyReward.PlayingStreakItemName)
		ImageFrame.RewardedItem.Image = itemsmodule.ImageMap[itemsmodule[dailyReward.PlayingStreakItemName].Type]
		ImageFrame.RewardedItem.ImageRectOffset = Vector2.new(itemsmodule[dailyReward.PlayingStreakItemName].ImageOffsetX,itemsmodule[dailyReward.PlayingStreakItemName].ImageOffsetY)	
		ImageFrame.RewardedItem.Visible = true
	else
		ImageFrame.RewardedItem.Visible = false
	end
	
	ImageFrame.ImageLabel.Streak.Visible = false
	ImageFrame.ImageLabel.ImageRectOffset = Vector2.new(512,0)
	
	ClaimFrame.Claim.Text = "Close"
	
	task.wait(5)
	
	DailyRewardsGui.Enabled = false
	
	
end)