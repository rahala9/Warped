
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetTimeOfDayServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDayServer")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "TakeTool") then
		if (promptObject:GetAttribute("RequiredQuestComplete")) then

			if (not QuestFunctions.IsQuestComplete(player,promptObject:GetAttribute("RequiredQuestComplete"))) then

				MessagePlayerEvent:FireClient(player, promptObject:GetAttribute("RequiredQuestNotCompleteText"))  
				return
			end

			InventoryFunctions.AddItem(player,promptObject.ObjectText)
		else
			InventoryFunctions.AddItem(player,promptObject.ObjectText)
		end
		
		promptObject.Parent.Transparency =1
		
		task.delay(5,function()
			promptObject.Parent.Transparency = 0
		end)
		
	elseif (promptObject.Name == "TakeTempHold") then
		InventoryFunctions.AddTempHold(player,promptObject.ObjectText) --TempHold slot is a special slot for temp tools, carried until not needed like quest items or just for fun, but go away after use
		if (promptObject:GetAttribute("TempRemoveTime")) then
			promptObject.Parent.Transparency = 1
			promptObject.Enabled = false
			for _, childItem in ipairs(promptObject.Parent:GetDescendants()) do

				if childItem:IsA('BasePart') or childItem:IsA('MeshPart') or childItem:IsA('Texture')  then
					childItem.Transparency = 1					
				end
			end
			
			task.delay(promptObject:GetAttribute("TempRemoveTime"),function()
				promptObject.Parent.Transparency = 0
				promptObject.Enabled = true
				for _, childItem in ipairs(promptObject.Parent:GetDescendants()) do

					if childItem:IsA('BasePart') or childItem:IsA('MeshPart') or childItem:IsA('Texture')  then
						childItem.Transparency = 0					
					end
				end
			end)
		end	
	elseif (promptObject.Name == "TakeTempHoldLive") then
		
		if ((promptObject.Parent:GetAttribute("OwnerId") == "") or (promptObject.Parent:GetAttribute("OwnerId") == player.UserId)) then
			--This is for picking something up that is already in game world
			promptObject.Name = "DropTempHoldLive"
			promptObject.ActionText = "Drop" 
			
			InventoryFunctions.AddTempHoldLive(player,promptObject.Parent.Parent.Name,promptObject.Parent.Parent) --Should go to Model
			
			--Cleanup Dock Slot
			if (promptObject.Parent:GetAttribute("CargoSlot")) then
				
				local dock = workspace.Areas.StarhopStation.Docks[promptObject.Parent:GetAttribute("CargoDockId")]
				
				dock.SpawnAnchor[promptObject.Parent:GetAttribute("CargoSlot")]:SetAttribute("Occupied",false)
				
				promptObject.Parent:SetAttribute("CargoSlot",nil)
				promptObject.Parent:SetAttribute("CargoDockId",nil)
			end
			
		else
			MessagePlayerEvent:FireClient(player, "This is not yours to take")  
		end
		
	elseif (promptObject.Name == "DropTempHoldLive") then	
		promptObject.Name = "TakeTempHoldLive"
		promptObject.ActionText = "Pick Up" 
		InventoryFunctions.RemoveTempHoldLive(player,promptObject.Parent.Parent.Name,promptObject.Parent.Parent) 
		
		--Handled by zone handler now
		--QuestFunctions.HandleQuest(player,promptObject)
		
	elseif (promptObject.Name == "PutTempHold") then
		
		--Let the quest step remove the item if this is a quest target TODO this should have to be the right quest target
		if (promptObject.Parent:GetAttribute("QuestTarget")) then
			return
		end
		InventoryFunctions.RemoveTempHold(player,promptObject.ObjectText)	
		
	elseif (promptObject.Name == "PlaceTempHold") then
		
		InventoryFunctions.PlaceTempHold(player,promptObject.ObjectText,promptObject.Parent.PlaceAttachment)	
		
		--Let the quest step remove the item if this is a quest target TODO this should have to be the right quest target
		if (promptObject.Parent:GetAttribute("QuestTarget")) then
			return
		end
		
	end
	

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
