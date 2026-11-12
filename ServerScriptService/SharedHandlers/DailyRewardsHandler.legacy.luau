local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GetDailyRewardEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetDailyReward")
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local CharacterFunctions = require(ServerScriptService.Data.DataCharacterFunctions)
local LootFunctions = require(ServerScriptService.SharedFunctions.LootFunctions)
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local ShowDailyRewardUIEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ShowDailyRewardUI")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)

function CalculateAllowance(player)
	local allowance = 0
	
	if (CharacterFunctions.GetClass(player) == "Popular") then
		allowance = 7 * ProgressFunctions.GetLevel(player)
	else
		allowance = 5 * ProgressFunctions.GetLevel(player)
	end
	
	return allowance
end

ProfileLoadedEvent.Event:Connect(function(player)
	local lastTimeDailedRewardClaimed = ProgressFunctions.GetLastTimeDailyRewardsClaimed(player)

	--If less than 24 hours don't show Daily Reward GUI
	if (os.difftime(os.time(),lastTimeDailedRewardClaimed) < (24*60*60)) then
		return
	else
		local streak = ProgressFunctions.GetPlayingStreak(player)
		ShowDailyRewardUIEvent:FireClient(player, streak)
	end
end)

GetDailyRewardEvent.OnServerInvoke = function(player)
	--local lastTimePlayed = 1669824055 --ProgressFunctions.GetLastTimePlayed(player)
	local lastTimeDailedRewardClaimed = ProgressFunctions.GetLastTimeDailyRewardsClaimed(player)
	local level = ProgressFunctions.GetLevel(player)
	local item = nil
	
	--If less than 24 hours don't allow just return
	if (os.difftime(os.time(),lastTimeDailedRewardClaimed) < (24*60*60)) then
		return
	else
		ProgressFunctions.SetLastTimeDailyRewardsClaimed(player,os.time())
	end
	
	if (os.difftime(os.time(),lastTimeDailedRewardClaimed) < (36*60*60)) then
		ProgressFunctions.AddPlayingStreak(player)
	end
	
	local playingStreak = ProgressFunctions.GetPlayingStreak(player)
	
	--TODO just for testing
	--playingStreak = 5
	
	--If streak is > 5 then reset
	if (playingStreak > 5) then
		ProgressFunctions.SetPlayingStreak(player,1)
		playingStreak = 1
	end

	--Give correct reward depending on what day of streak
	if (playingStreak == 5) then
		--Reward a rare item at player level
		--										 minLevel,maxLevel,minRarity,maxRarity,typeWhiteList,rarityPercentages
												--minLevel,maxLevel,minRarity,maxRarity,typeWhiteList,specificLootItems,rarityPercentages,typeBlackList,itemBlackList,exclude items already in inventory
		item = LootFunctions.GetFilteredLootItem2(level,level+2,1,3,{"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal"},nil,{100,80,70,10,.03,.01},nil,nil,true,player)	
		ProgressFunctions.SetPlayingStreak(player,0)
	elseif(playingStreak == 3) then
		item = LootFunctions.GetFilteredLootItem2(level,level+2,1,2,{"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal"},nil,{100,80,70,1,.03,.01},nil,nil,true,player)	
	elseif(playingStreak == 1) then
		item = LootFunctions.GetFilteredLootItem2(level,level+2,1,1,{"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal","Material"},nil,{100,80,50,1,.03,.01},nil,nil,true,player)		
	end
	
	--Add item to inventory
	
	if (item ~= nil) then
		InventoryFunctions.AddItem(player,item)
	end
	
	local allowance = CalculateAllowance(player)
	
	if (allowance ~= nil) then
		InventoryFunctions.AddMoney(player,allowance)
	end
	
	return {Allowance=allowance,PlayingStreakItemName = item}
end