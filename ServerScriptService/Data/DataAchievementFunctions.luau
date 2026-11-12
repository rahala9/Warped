local ServerScriptService = game:GetService("ServerScriptService")
local Data = require(ServerScriptService.Data.Data)
local replicatedStorage = game:GetService("ReplicatedStorage")
local MessagePlayerEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local AchievementEarnedEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AchievementEarned")
local Achievements = require(ServerScriptService.Data.Templates.Achievements)

local functions = {}

--Achievements
--	Flipped out the Burger Boss
--		Title - Worst Employee
--		Perk - Free Fries From Friends (get fries once a day from back door of Sloppy Burger)
--		Steps	
--			Break a plate
--			Let meat rot
--			Let meat catch on fire
--			Get order wrong
--			Yell at customer
--			Don't take customer order
--			Eat the food


function functions.HasAccess(player,accessStep)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Achievements == nil) then
		return false
	end

	if (profile.Data.Achievements["Areas Accessed"] == nil) then
		return false
	end

	if (profile.Data.Achievements["Areas Accessed"].Steps == nil) then
		return false
	end

	if (profile.Data.Achievements["Areas Accessed"].Steps[accessStep] == nil) then
		return false
	end

	return profile.Data.Achievements["Areas Accessed"].Steps[accessStep].Complete

end


--all quest steps are complete but quest has not been rewarded yet
function functions.AreAchievementStepsComplete(player,achievementName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Achievements == nil) then
		return false
	end

	if (profile.Data.Achievements[achievementName] == nil) then
		return false
	end

	for i, achievement_step in pairs(profile.Data.Achievements[achievementName].Steps) do

		if (achievement_step.Complete ~= true) then
			return false
		end
	end

	return true
end

function functions.IsAchievementStepComplete(player,achievementName,achievementStepName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Achievements == nil) then
		return false
	end

	if (profile.Data.Achievements[achievementName] == nil) then
		return false
	end

	if (not profile.Data.Achievements[achievementName].Steps[achievementStepName]) then
		return false
	end

	if (profile.Data.Achievements[achievementName].Steps[achievementStepName].Complete) then
		return true
	end

	return false
end

function functions.GetAchievements(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Achievements
end

function functions.GetAchievement(player,achievementName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Achievements[achievementName]
end

function functions.CompleteAchievementStep(player, achievementName, achievementStepName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Logger.Debug("..............CompleteAchievementStep........player:"..player.Name.." achievement:"..achievementName.." achievementStepName:"..achievementStepName)

	--If we are completing an Achievement Step and do not yet have the Achievement then add it.
	if(profile.Data.Achievements[achievementName] == nil) then
		functions.AddAchievement(player,Achievements[achievementName])
	end

	--if we already have this achievement then do nothing.
	if (profile.Data.Achievements[achievementName].Complete) then
		return
	end

	profile.Data.Achievements[achievementName].Steps[achievementStepName] = {Complete = true}

	--If all steps are complete then complete achievement and award to player

	if(functions.AreAchievementStepsComplete(player,achievementName)) then
		--Logger.Debug("~~~~~~~~~~~~~~~~~ALL STEPS COMPLETE.  YOU GET AN ACHIEVEMENT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
		profile.Data.Achievements[achievementName].Complete = true

		functions.DisplayAchievement(player, achievementName)
	end


end

function functions.DisplayAchievement(player, achievementName)

	AchievementEarnedEvent:FireClient(player,achievementName,Achievements[achievementName].Image)
end

function functions.AddAchievement(player,achievement)

	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Achievements[achievement.Name]={}
	profile.Data.Achievements[achievement.Name].Complete = false
	profile.Data.Achievements[achievement.Name].Steps=Achievements[achievement.Name].Steps

end

return functions