--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local QuestsUpdatedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("QuestsUpdated")
local QuestCompleteEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("QuestComplete")
local QuestAddedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("QuestAdded")
local UpdateClientObjectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateClientObject")	

--Functions
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

--Definition Modules
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local QuestsDef = require(game.ServerScriptService.Data.Templates.Quests)

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)
local Utility = require(ServerScriptService:WaitForChild("SharedUtilities").Utility)

local functions = {}

function functions.GetQuest(player,questName)
	local profile = Data[player]
	if (profile == nil) then return nil end	

	return profile.Data.Quests[questName]
end

function functions.GetQuests(player)
	local profile = Data[player]
	if (profile == nil) then return nil end	

	--Hide steps that are sequential and after the last non complete step

	local quests = {}
	local steps = {}

	for i, quest in pairs(profile.Data.Quests) do
		for stepNumber, step in pairs(quest.Steps ) do

			if (stepNumber > 1) then
				if (step.Sequential) then
					--If this step is supposed to be sequential and we have not completed previous step then skip
					if (quest.Steps[stepNumber-1].Complete)  then
						steps[stepNumber] = step
					end
				else
					steps[stepNumber] = step
				end
			else
				steps[stepNumber] = step
			end
		end

		quests[quest.Name] = Utility.DeepCopy(quest)
		quests[quest.Name].Steps = steps
		quests[quest.Name].Desc = QuestsDef[quest.Name].Desc
		quests[quest.Name].Reward = QuestsDef[quest.Name].Reward
		quests[quest.Name].Drawing = QuestsDef[quest.Name].Drawing
		quests[quest.Name].Guided = QuestsDef[quest.Name].Guided
		steps = {}
	end


	return quests
end

function functions.ToggleTracked(player,questName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Quests[questName]  ~= nil) then
		profile.Data.Quests[questName].Tracked = not profile.Data.Quests[questName].Tracked

		QuestsUpdatedEvent:FireClient(player,profile.Data.Quests[questName],QuestsDef[questName].QuestGiver)
	end

end

function functions.CanPlayerGetQuest(player,questName)

	if (not QuestsDef[questName]) then
		return
	end

	local quest = QuestsDef[questName]

	if (ProgressFunctions.GetLevel(player) < quest.AvailableLevel) then
		return false
	else 
		return true
	end
end


--Used to put check mark
function functions.GetPlayerAvailableQuests(player)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local availableQuests = {}

	if (profile == nil) then
		return availableQuests
	end

	for i, quest in pairs(QuestsDef) do

		if ((quest.DependentQuest == "") or ( (profile.Data.Quests[quest.DependentQuest] ~= nil) and (profile.Data.Quests[quest.DependentQuest].Completed) )) then
			availableQuests[quest.Name] = {}
			availableQuests[quest.Name].Available = (ProgressFunctions.GetLevel(player) >= quest.AvailableLevel)
			availableQuests[quest.Name].Started = (profile.Data.Quests[quest.Name] ~= nil)
			availableQuests[quest.Name].QuestGiver = quest.QuestGiver
			availableQuests[quest.Name].Steps = quest.Steps
			availableQuests[quest.Name].Complete = quest.Complete
		end
	end

	return availableQuests
end



function functions.HandleQuestTrigger(player,promptObject)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local questName = promptObject.Parent:GetAttribute("QuestTrigger")

	if (QuestsDef[questName] == nil) then
		warn("DataQuestFunctions reported quest does not exist:"..questName)
		MessagePlayerEvent:FireClient(player,"ERROR: Quest not found. Please report to game admins")
		return
	end

	if (QuestsDef[questName].QuestTrigger.RequiredItem ~= "") then
		if (not InventoryFunctions.CheckItem(player,QuestsDef[questName].QuestTrigger.RequiredItem,1)) then
			MessagePlayerEvent:FireClient(player,"You don't seem to have the necessary item")
			return
		end
	end

	if (QuestsDef[questName].QuestTrigger.RequiredHeldItem ~= "") then

		local heldToolName = StatesFunctions.GetCurrentTool(player)

		if (QuestsDef[questName].QuestTrigger.RequiredHeldItem ~= heldToolName) then
			MessagePlayerEvent:FireClient(player,"You don't seem to be holding the necessary item")
			return
		end
	end

	MessagePlayerEvent:FireClient(player,QuestsDef[questName].QuestTrigger.StartText)

	--We made it with all the requirements to start this quest, so add the quest
	functions.AddQuest(player,QuestsDef[questName])
end

function functions.CompleteStep(player,questName,stepIndex)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (functions.HasQuest(player,questName)) then
		profile.Data.Quests[questName].Steps[stepIndex].Complete=true --TODO should probably go through AdvanceQuestStep function instead
	end
end


--function functions.HandleQuestStepActions(quest,quest_step,promptObject)
--	for i, action in pairs(quest_step.Actions) do
--		if (action.Type == "PropertyChange") then

--			if (action.TargetType == "Parent") then
--				promptObject.Parent[action.Key] = action.Value
--			elseif (action.TargetType == "Sibling") then
--				promptObject.Parent:FindFirstChild(action.TargetName)[action.Key] = action.Value
--			end

--		end
--	end
--end

function functions.HandleQuestActions(player,questActions)
	for i, action in pairs(questActions) do
		if (action.Type == "ChangeClientObjectProperties") then

			UpdateClientObjectEvent:FireClient(player,action.Target,action.Props)	

		end
	end
end

function functions.HandleQuestStepPostActions(player,quest_step)

	if (quest_step.PostActions) then
		functions.HandleQuestActions(player,quest_step.PostActions)
	end

end

function functions.HandleQuest(player,promptObject)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--Find the quest associated with this object.  For Performance we could put this in attribute, but then needs maintained everyywhere
	local quest,quest_step = functions.GetObjectQuestStep(player,promptObject)
	if (quest_step ~= nil) then
		functions.AdvanceQuestStep(player,quest.Name, quest_step.Index)

	end
end

function functions.CompleteQuestStep(player,questName, stepIndex)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local quest = profile.Data.Quests[questName]

	--Logger.Debug("**************************QUEST "..questName.." Step complete")
	quest.Steps[stepIndex].Complete = true
	functions.HandleQuestStepPostActions(player,quest.Steps[stepIndex])

	if (functions.AreQuestStepsComplete(player,questName)) then
		--Logger.Debug("**************************QUEST "..questName.." Quest complete")

		--If the quest has a quest giver then you are reward after dialog with them if not then you are rewarded here
		if (not QuestsDef[questName].QuestGiver) then
			functions.CompleteQuest(player,quest.Name)
		else
			--Rewarded with QuestGiver
		end

		--quest.Complete = true --DO NOT DO THIS.  THIS HAPPENS ONLY WHEN QUEST IS REWARDED
		--QuestsUpdatedEvent:FireClient(player,quest,Quests[quest.Name].QuestGiver)
		QuestCompleteEvent:FireClient(player,"QUEST "..QuestsDef[questName].DisplayName.." COMPLETE")
		return true
	end

	return false
end

function functions.AdvanceQuestStep(player,questName, stepIndex, amount)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local quest = profile.Data.Quests[questName]
	local AllComplete = false


	if (functions.AreQuestStepsComplete(player,questName)) then
		return true
	end

	local quest_step = quest.Steps[stepIndex]

	if(quest_step.Type == "ActionAmount") then

		if (amount) then
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + amount
		else
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + 1
		end

		--Logger.Debug("**************************QUEST "..questName.." AdvanceQuestStep incremented")

		MessagePlayerEvent:FireClient(player,"Quest "..questName..quest_step.Name.." "..quest_step.CurrentAmount.."/"..quest_step.AmountNeeded,nil,nil,nil,nil,nil,3)

		if (quest_step.CurrentAmount  >= quest_step.AmountNeeded) then
			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		end
	elseif(quest_step.Type == "Drop") then
		if (amount) then
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + amount
		else
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + 1
		end

		MessagePlayerEvent:FireClient(player,"Quest "..questName..quest_step.Name.." \n"..quest_step.CurrentAmount.."/"..quest_step.AmountNeeded,nil,nil,nil,nil,nil,3)

		if (quest_step.CurrentAmount  >= quest_step.AmountNeeded) then
			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		end
	elseif(quest_step.Type == "Kill") then
		if (amount) then
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + amount
		else
			quest_step.CurrentAmount = quest.Steps[stepIndex].CurrentAmount + 1
		end

		MessagePlayerEvent:FireClient(player,"Quest "..questName..quest_step.Name.." "..quest_step.CurrentAmount.."/"..quest_step.AmountNeeded,nil,nil,nil,nil,nil,3)

		if (quest_step.CurrentAmount  >= quest_step.AmountNeeded) then
			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		end
	elseif(quest_step.Type == "GoToArea") then

		AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
	elseif(quest_step.Type == "TalkTo") then

		AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
	elseif(quest_step.Type == "Task") then 

		AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
	elseif (quest_step.Type == "UseItem") then
		if (InventoryFunctions.CheckItem(player,quest_step.RequiredItem,1)) then

			----Does this quest change this object in anyway?
			--if (quest_step.PropertyChange ~= nil) then
			--	promptObject.Parent[quest_step.PropertyChange] = quest_step.PropertyChangeValue

			--	--If we are changing a spotlight with rays then we need to set the property change on the rays object as well
			--	if (promptObject.Parent.Name == "SpotLightWithRays") then
			--		promptObject.Parent.rays[quest_step.PropertyChange] = quest_step.PropertyChangeValue
			--	end

			--else
			--	if (quest_step.Actions ~= nil) then
			--		functions.HandleQuestStepActions(quest,quest_step,promptObject)
			--	end
			--end

			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		else
			MessagePlayerEvent:FireClient(player,"Must have "..quest_step.RequiredItem,quest_step.RequiredItem)
		end
	elseif (quest_step.Type == "Search") then

		if (quest.RequiredItem ~= nil and not InventoryFunctions.CheckItem(player,quest.RequiredItem,1)) then

			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		else

			MessagePlayerEvent:FireClient(player,"Quest "..quest.DisplayName.." requires a "..quest.RequiredItem,quest.RequiredItem,nil,nil,nil,Color3.new(0,255,0),6)
		end

	elseif (quest_step.Type == "Put") then
		if (InventoryFunctions.CheckItem(player,quest_step.Object,quest_step.Amount)) then

			InventoryFunctions.RemoveItem(player,quest_step.Object,quest_step.Amount)

			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)

		else
			MessagePlayerEvent:FireClient(player,"Must have "..quest_step.Amount.." "..quest_step.Object.."s")
		end
	elseif (quest_step.Type == "Get") then

		--Item has already been added and CurrentAmount updated by the QuestHandler from the InventoryItem Update event
		--Logger.Debug("**************************QUEST "..questName.." AdvanceQuestStep incremented")

		MessagePlayerEvent:FireClient(player,"Quest "..questName..quest_step.Name.." "..quest_step.CurrentAmount.."/"..quest_step.AmountNeeded)

		if (quest_step.CurrentAmount  >= quest_step.AmountNeeded) then
			AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)
		end

	elseif (quest_step.Type == "Build") then

		--If we got here for build type then the correct item is built
		--Logger.Debug("**************************QUEST "..questName.." AdvanceQuestStep incremented")

		AllComplete = functions.CompleteQuestStep(player,questName, stepIndex)

	end

	profile.Data.Quests[quest.Name]=quest

	QuestsUpdatedEvent:FireClient(player,quest,QuestsDef[quest.Name].QuestGiver)

	return AllComplete

end

function functions.ShowHiddenQuestStep(player,questName, stepIndex)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local quest = profile.Data.Quests[questName]

	if (functions.AreQuestStepsComplete(player,questName)) then
		return true
	end

	if (quest.Steps[stepIndex] ~= nil) then
		quest.Steps[stepIndex].Hidden = false
	end

	profile.Data.Quests[quest.Name] = quest

	QuestsUpdatedEvent:FireClient(player,quest,QuestsDef[quest.Name].QuestGiver)

end

--gets the first quest step associated with this model/object if any if it is 
--not already a completed step.  Does not handle multiple quests yet
function functions.GetObjectQuestStep(player,promptObject)

	local profile = Data[player]
	if (profile == nil) then return nil end

	local questTargetFullName = promptObject.Parent:GetFullName()

	for i, quest in pairs(profile.Data.Quests) do
		for i, quest_step in pairs(quest.Steps) do

			if(quest_step.Type == "Put") then
				if(quest_step.Destination == questTargetFullName) and (quest_step.Complete == false) then
					return quest,quest_step
				end
			elseif(quest_step.Type == "Drop") then
				--Is player in zone that object should be dropped

				local isInZone = StatesFunctions.IsInZone(player,quest_step.Zone)

				if(isInZone and quest_step.Object == promptObject.Parent.Parent.Name) and (quest_step.Complete == false) then
					return quest,quest_step
				end
			elseif(quest_step.Type == "Search") then
				if(quest_step.Object == questTargetFullName) and (quest_step.Complete == false) then
					return quest,quest_step
				end
			elseif(quest_step.Type == "UseItem") then
				if(quest_step.Object == questTargetFullName) and (quest_step.Complete == false) then
					return quest,quest_step
				end
			elseif(quest_step.Type == "Action") then
				if(quest_step.Action == promptObject.Name) and (quest_step.Object == questTargetFullName) and (quest_step.Complete == false) then
					return quest,quest_step
				end
			end
		end
	end

	--Did not find a quest associated with this model/object
	return nil,nil
end

function functions.UpdateQuestStepAmount(player,requiredObject,amount)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for i, quest in pairs(profile.Data.Quests) do

		if (quest.Complete) then
			continue
		end

		for i, quest_step in pairs(quest.Steps) do

			if (quest_step.Complete) then
				continue
			end

			if (quest_step.Type ~= "Get") then
				continue
			end

			if(quest_step.Object == requiredObject) then
				quest_step.CurrentAmount = quest_step.CurrentAmount + amount
				functions.AdvanceQuestStep(player,quest.Name, quest_step.Index)
			end
		end
	end

	--Did not find a quest associated with this model/object
	return nil,nil
end

function functions.CompleteGoToAreaQuestSteps(player,zoneName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for questIndex, quest in pairs(profile.Data.Quests) do

		if (quest.Complete) then
			continue
		end

		for questStepIndex, questStep in pairs(quest.Steps) do

			if (questStep.Complete) then
				continue
			end

			if(questStep.Type == "GoToArea") then
				if(questStep.Destination == zoneName) and (questStep.Complete == false) then
					functions.AdvanceQuestStep(player,quest.Name, questStepIndex)
				end
			end
		end
	end
end

function functions.CompleteTalkToQuestSteps(player,NPCName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for questIndex, quest in pairs(profile.Data.Quests) do

		if (quest.Complete) then
			continue
		end

		for questStepIndex, questStep in pairs(quest.Steps) do

			if (questStep.Complete) then
				continue
			end

			if(questStep.Type == "TalkTo") then
				if(questStep.Object == NPCName) and (questStep.Complete == false) then
					functions.AdvanceQuestStep(player,quest.Name, questStepIndex)
				end
			end
		end
	end
end

function functions.CompleteDropQuestSteps(player,ZoneName,amount)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for questIndex, quest in pairs(profile.Data.Quests) do

		if (quest.Complete) then
			continue
		end

		for questStepIndex, questStep in pairs(quest.Steps) do

			if (questStep.Complete) then
				continue
			end

			if(questStep.Type == "Drop") then
				if(questStep.Zone == ZoneName) and (questStep.Complete == false) then
					functions.AdvanceQuestStep(player,quest.Name, questStepIndex,amount)
				end
			end
		end
	end
end

function functions.CompleteTaskQuestSteps(player,action)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for questIndex, quest in pairs(profile.Data.Quests) do

		if (quest.Complete) then
			continue
		end

		for questStepIndex, questStep in pairs(quest.Steps) do

			if (questStep.Complete) then
				continue
			end

			if(questStep.Type == "Task") then
				if(questStep.Action == action) and (questStep.Complete == false) then
					functions.AdvanceQuestStep(player,quest.Name, questStepIndex)
				end
			end
		end
	end
end


--all quest steps are complete but quest has not been rewarded yet
function functions.AreQuestStepsComplete(player,questName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Quests == nil) then
		return false
	end

	if (profile.Data.Quests[questName] == nil) then
		return false
	end

	for i, quest_step in pairs(profile.Data.Quests[questName].Steps) do
		if (not quest_step.Complete) then
			return false
		end
	end

	return true
end

--is the quest completely done (steps done and final reward given)
function functions.IsQuestComplete(player,questName)

	local profile = Data[player]
	if (profile == nil) then return false end

	if (profile.Data.Quests == nil) then
		return false
	end

	if (profile.Data.Quests[questName] == nil) then
		return false
	end

	return profile.Data.Quests[questName].Complete

end

function functions.IsQuestStepComplete(player,questName,StepIndex)

	local profile = Data[player]
	if (profile == nil) then return false end

	if (profile.Data.Quests == nil) then
		return false
	end

	if (profile.Data.Quests[questName] == nil) then
		return false
	end

	if (profile.Data.Quests[questName].Steps[StepIndex] == nil) then
		return false
	end

	return profile.Data.Quests[questName].Steps[StepIndex].Complete

end

function functions.HasQuest(player,questName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	if (profile.Data.Quests == nil) then
		return false
	end

	if (profile.Data.Quests[questName] == nil) then
		return false
	end

	return true
end

function functions.CompleteQuest(player,questName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	for i, v in pairs(QuestsDef[questName].Reward) do
		if (i == "Money") then
			InventoryFunctions.AddMoney(player,v)
		elseif (i == "Experience") then
			ProgressFunctions.AddXP(player,v)
		elseif (i == "Item") then
			InventoryFunctions.AddItem(player,v.Name,v.Amount)
		elseif (i == "Item2") then
			InventoryFunctions.AddItem(player,v.Name,v.Amount)
		elseif (i == "Quest") then
			functions.AddQuest(player,QuestsDef[v])
		end

	end

	--Update the player quest to complete.  This will stop the quest from being offered again. TODO only for one time only quests
	profile.Data.Quests[questName].Complete = true

	--Leave quest as nil so all quests will be considered in marking
	QuestsUpdatedEvent:FireClient(player,nil,QuestsDef[questName].QuestGiver)

	if (QuestsDef[questName].PostActions) then
		functions.HandleQuestActions(player,QuestsDef[questName].PostActions)
	end
end

function functions.AddQuestByName(player,questName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	if (not QuestsDef[questName]) then
		warn("DataQuestFunctions reported quest does not exist:"..questName)
		return
	end

	functions.AddQuest(player,QuestsDef[questName])
end

function functions.RestartQuest(player,quest)
	functions.RemoveQuest(player,quest.Name)
	functions.AddQuest(player,quest)
end

function functions.AddQuest(player,quest)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--If we already have this quest leave
	if (functions.HasQuest(player,quest.Name)) then
		return
	end

	--Only set the fields that we need to store
	profile.Data.Quests[quest.Name] = {}
	profile.Data.Quests[quest.Name].Name = quest.Name
	profile.Data.Quests[quest.Name].DisplayName = quest.DisplayName
	profile.Data.Quests[quest.Name].Steps = quest.Steps
	profile.Data.Quests[quest.Name].Complete = quest.Complete
	profile.Data.Quests[quest.Name].Tracked = quest.Tracked

	QuestsUpdatedEvent:FireClient(player,quest,QuestsDef[quest.Name].QuestGiver)

	MessagePlayerEvent:FireClient(player,"Quest Added: "..quest.DisplayName)

	QuestAddedEvent:FireClient(player,quest)

	if (quest.TempItem ~= nil) then
		InventoryFunctions.AddTempHold(player,quest.TempItem,nil,quest.Name)
	end

	if (quest.PreActions) then
		functions.HandleQuestActions(player,quest.PreActions)
	end

end

function functions.RemoveQuest(player,questName)

	local profile = Data[player]
	if (profile == nil) then return nil end

	--If we don't have this quest then nothing to remove
	if (not functions.HasQuest(player,questName)) then
		return
	end

	local quest = profile.Data.Quests[questName]

	--Only set the fields that we need to store
	profile.Data.Quests[questName] = nil

	QuestsUpdatedEvent:FireClient(player,quest,QuestsDef[questName].QuestGiver)

	MessagePlayerEvent:FireClient(player,"Quest Removed: "..QuestsDef[questName].DisplayName)

end

return functions