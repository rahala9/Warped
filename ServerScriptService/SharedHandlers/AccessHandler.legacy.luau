--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProximityPromptService = game:GetService("ProximityPromptService")

--Remote Events
local RunActEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RunAct")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions
local StageFunctions = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("StageFunctions"))
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local AchievementFunctions = require(ServerScriptService.Data.DataAchievementFunctions)
local GetAccessedAreasEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetAccessedAreas")

--Definition Modules

--Objects

--Modules

GetAccessedAreasEvent.OnServerInvoke = function(player)
	return AchievementFunctions.GetAchievement(player,"Areas Accessed")
end

local debounce = false

local function HandleAccess(promptObject, player)
	if (debounce) then
		debounce = false

		return
	end

	debounce = true

	--If this prompt has a required item then check that the player has it
	if (promptObject:GetAttribute("RequiredItem") and not InventoryFunctions.HasRequiredItem(player, promptObject)) then

		if (promptObject:GetAttribute("AccessFailureMessage")) then
			MessagePlayerEvent:FireClient(player, promptObject:GetAttribute("AccessFailureMessage"))
		end
		
		debounce = false
		
		return
	end
	
	if (promptObject:GetAttribute("RequiredTool") and not InventoryFunctions.HasRequiredTool(player, promptObject)) then

		if (promptObject:GetAttribute("AccessFailureMessage")) then
			MessagePlayerEvent:FireClient(player, promptObject:GetAttribute("AccessFailureMessage"))
		end

		debounce = false

		return
	end
	
	local act = promptObject:GetAttribute("Act")
	
	if (act) then
		StageFunctions.RunAct(player,act,promptObject.Parent.Parent)

		RunActEvent:FireClient(player,act,promptObject.Parent.Parent) --TODO send to all clients that are in a group
	end

	if (promptObject:GetAttribute("AreaAccessed")) then
		AchievementFunctions.CompleteAchievementStep(player,"Areas Accessed",promptObject:GetAttribute("AreaAccessed"))
	end
	
	debounce = false

end


local function onPromptTriggered(promptObject, player)
	
	if (promptObject:GetAttribute("RequestAccess")) then
		HandleAccess(promptObject, player)
	end

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)