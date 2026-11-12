--Roblox Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events
local ProgressUpdateEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ProgressUpdate")
--local LevelUpEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("LevelUp")	
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions
local AttributeFunctions = require(ServerScriptService.Data.DataAttributesFunctions)

--Definition Modules

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)

local functions = {}

--XP = 0,
--Level = 1,
--PaperAirplayHighScore = 0,
--Discoveries = {[1]=false,[2]=false}

--LightHouse = 1
--Football Field 2

function functions.GetLastTimeDailyRewardsClaimed(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--TODO turn on to test Daily Rewards
	--return 1700784000

	return profile.Data.Progress.LastTimeDailyRewardsClaimed
end

function functions.SetLastTimeDailyRewardsClaimed(player, lastTimeDailyRewardsClaimed)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.LastTimeDailyRewardsClaimed = lastTimeDailyRewardsClaimed
end

function functions.GetStarted(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.Started
end

function functions.SetStarted(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.Started = true
end

function functions.GetLastTimePlayed(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.LastTimePlayed
end

function functions.GetPlayingStreak(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.PlayingStreak
end

function functions.AddPlayingStreak(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.PlayingStreak = profile.Data.Progress.PlayingStreak + 1
end

function functions.SetPlayingStreak(player, streak)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.PlayingStreak = streak
end

function functions.GetDiscoveries(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.Discoveries
end

function functions.HaveDiscovered(player, discoveryIndex)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.Discoveries[discoveryIndex]
end

function functions.SetDiscovery(player,discoveryIndex, isDiscovered)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.Discoveries[discoveryIndex] = isDiscovered
end

function functions.GetXP(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.XP
end

function functions.GetLevel(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.Level
end

function functions.GetPaperAirplayHighScore(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.PaperAirplayHighScore
end

function functions.GetBestDiveScore(player,score)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.BestDiveScore
end

function functions.GetDeepestDive(player,score)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Progress.DeepestDive
end

function functions.SetXP(player, xp)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.XP = xp

	ProgressUpdateEvent:FireClient(player,profile.Data.Progress)
end

function functions.AddXPFromKill(player,enemyDef,percentageOfEnemyDamage)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local xpToLevel = math.round(math.pow(enemyDef.Level/.4,2+(enemyDef.Level/50)) + 50 )
	local baseXP = math.round(xpToLevel/50)
	local xpForAtLevelEnemy = baseXP * math.pow(2,enemyDef.Rank-1)
	local finalXP = xpForAtLevelEnemy * percentageOfEnemyDamage

	functions.AddXP(player,finalXP)
end

local function getTotalXPForLevel(level)
	return math.round(math.pow(level / 0.1, 2)) --math.round(math.pow(level / 0.4, 2 + (level / 50)) + 50)
end

function functions.AddXP(player,amount)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.XP = profile.Data.Progress.XP + amount

	local xpToCurrentLevel
	if profile.Data.Progress.Level == 1 then
		xpToCurrentLevel = 0  -- Start level at 0 XP for the first level
	else
		xpToCurrentLevel = getTotalXPForLevel(profile.Data.Progress.Level - 1) 
	end

	local xpToNextLevel = getTotalXPForLevel(profile.Data.Progress.Level)      
	local xpInCurrentLevel = profile.Data.Progress.XP - xpToCurrentLevel
	local xpNeededForThisLevel = xpToNextLevel - xpToCurrentLevel

	local levelUp = (profile.Data.Progress.XP >= xpToNextLevel)
	local levelProgressPercentage = (xpInCurrentLevel / xpNeededForThisLevel)


	--Logger.Debug("TEST LEVEL UP:level:",profile.Data.Progress.Level)
	--Logger.Debug("TEST LEVEL UP:xp:",profile.Data.Progress.XP)
	--Logger.Debug("TEST LEVEL UP:xpToCurrentLevel:",xpToCurrentLevel)
	--Logger.Debug("TEST LEVEL UP:xpToNextLevel:",xpToNextLevel)
	--Logger.Debug("TEST LEVEL UP:xpInCurrentLevel:",xpInCurrentLevel)
	--Logger.Debug("TEST LEVEL UP:xpNeededForThisLevel:",xpNeededForThisLevel)
	--Logger.Debug("TEST LEVEL UP:levelProgressPercentage:",levelProgressPercentage)

	if (levelUp) then
		local newLevel = profile.Data.Progress.Level + 1
		functions.SetLevel(player,newLevel)

		if (newLevel % 2 == 0) then
			AttributeFunctions.SetAttributePoints(player,AttributeFunctions.GetAttributePoints(player)+1)
		end

		MessagePlayerEvent:FireClient(player,"Leveled up to level "..newLevel)
	end

	ProgressUpdateEvent:FireClient(player,profile.Data.Progress,levelUp,levelProgressPercentage,amount)
end

--TODO clean up as no levels in new game
function functions.SetLevel(player,level)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.Level = level

	AttributeFunctions.RecalculateMaxHealth(player,functions.GetLevel(player))

	ProgressUpdateEvent:FireClient(player,profile.Data.Progress)
	--LevelUpEvent:Fire(player,level)

end

function functions.SendProgress(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--ProgressUpdateEvent:FireClient(player,profile.Data.Progress)
	functions.AddXP(player,0) --this will send a proper progress update with percentage to xp level
end

function functions.SetPaperAirplayHighScore(player,score)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.PaperAirplayHighScore = score
end

function functions.SetBestDiveScore(player,score)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.BestDiveScore = score
end

function functions.SetDeepestDive(player,score)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Progress.DeepestDive = score
end

return functions