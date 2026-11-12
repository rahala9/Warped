local datastore = game:GetService("DataStoreService"):GetDataStore("PlacementSystem")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local sharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local placementItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("PlacementItems")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local UpdateCampEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateCamp")
local GetCampLocationEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetCampLocation")
local CampPlacement = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CampPlacement")
local CampCommands = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CampCommands")
local buildItems = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("BuildItems"))
local tentsFolder = placementItems:WaitForChild("Tents")
local otherFolder = placementItems:WaitForChild("Other")
local gardeningFolder = placementItems:WaitForChild("Gardening")
local items = otherFolder:GetChildren()
local gardeningItems = gardeningFolder:GetChildren()
local tents = tentsFolder:GetChildren()
local ServerStorage = game:GetService("ServerStorage")
local Pallet = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Pallet")
local BuildBlockers = workspace:WaitForChild("BuildBlockers")
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local CollectionService = game:GetService("CollectionService")
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)
local GetTimeOfDayServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDayServer")
local GardeningFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").GardeningFunctions)


local PowerSourceFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").PowerSourceFunctions)

game.Players.PlayerAdded:Connect(function(player)
	local CampObjects = Instance.new("Folder")
	CampObjects.Name = player.Name.."_CampObjects"
	CampObjects.Parent = workspace

end)

game.Players.PlayerRemoving:Connect((function(player)
	workspace:WaitForChild(player.Name.."_CampObjects"):Destroy()
end))

--TODO cleanup campobjects when player is removed

local function removeGrass(part)

	local pos1 = Vector3.new(part.Position.X-(buildItems[part.Parent.Name].AreaX),part.Position.Y-(buildItems[part.Parent.Name].AreaY),part.Position.Z-(buildItems[part.Parent.Name].AreaZ))
	local pos2 = Vector3.new(part.Position.X+(buildItems[part.Parent.Name].AreaX),part.Position.Y+(buildItems[part.Parent.Name].AreaY),part.Position.Z+(buildItems[part.Parent.Name].AreaZ))

	local Region = Region3.new(pos1, pos2)

	Region = Region:ExpandToGrid(4)

	--local regionVisualizer = Instance.new("Part")   
	--regionVisualizer.Name = "myregion" 
	--regionVisualizer.Anchored = true
	--regionVisualizer.Size = Region.Size
	--regionVisualizer.CFrame = Region.CFrame
	--regionVisualizer.Parent = workspace

	workspace.Terrain:ReplaceMaterial(Region, 4, Enum.Material.Grass, Enum.Material.LeafyGrass)
end

--TODO store in the players particular camp
local terrainRegion
local ceil          = math.ceil
local resolution    = 4

local function positionWorldToVoxel(pos)
	return Vector3int16.new(ceil(pos.x / resolution), ceil(pos.y / resolution), ceil(pos.z / resolution))
end

local function removeTerrain(part)
	--TODO Terrain removal needs to be lower on Y
	local pos1 = Vector3int16.new(part.Position.X-(part.Size.X/2),part.Position.Y-(part.Size.Y/1.5),part.Position.Z-(part.Size.Z/2))
	local pos2 = Vector3int16.new(part.Position.X+(part.Size.X/2),part.Position.Y+(part.Size.Y/1.5),part.Position.Z+(part.Size.Z/2))
	local RegionToCopy = Region3int16.new(positionWorldToVoxel(pos1), positionWorldToVoxel(pos2))
	
	local pos3 = Vector3.new(part.Position.X-(part.Size.X/2),part.Position.Y-(part.Size.Y/2),part.Position.Z-(part.Size.Z/2))
	local pos4 = Vector3.new(part.Position.X+(part.Size.X/2),part.Position.Y+(part.Size.Y/2),part.Position.Z+(part.Size.Z/2))

	local Region = Region3.new(pos3, pos4)
	
	terrainRegion = workspace.Terrain:CopyRegion(RegionToCopy)
	workspace.Terrain:ReplaceMaterial(Region, 4, Enum.Material.LeafyGrass, Enum.Material.Air)
end

--TODO Will not work..  needs to know exactly previous terrain that was removed
local function addTerrain(part)	
	
	if (terrainRegion == nil) then
		return
	end
	
	local pastePos = positionWorldToVoxel(Vector3int16.new(part.Position.X-(part.Size.X/2),part.Position.Y-(part.Size.Y/1.5),part.Position.Z-(part.Size.Z/2)))
	workspace.Terrain:PasteRegion(terrainRegion, pastePos , false)
end


local function addGrass(part)
	
	local pos1 = Vector3.new(part.Position.X-(buildItems[part.Parent.Name].AreaX),part.Position.Y-(buildItems[part.Parent.Name].AreaY),part.Position.Z-(buildItems[part.Parent.Name].AreaZ))
	local pos2 = Vector3.new(part.Position.X+(buildItems[part.Parent.Name].AreaX),part.Position.Y+(buildItems[part.Parent.Name].AreaY),part.Position.Z+(buildItems[part.Parent.Name].AreaZ))

	local Region = Region3.new(pos1, pos2)

	Region = Region:ExpandToGrid(4)

	--local regionVisualizer = Instance.new("Part")   
	--regionVisualizer.Name = "myregion" 
	--regionVisualizer.Anchored = true
	--regionVisualizer.Size = Region.Size
	--regionVisualizer.CFrame = Region.CFrame
	--regionVisualizer.Parent = workspace

	workspace.Terrain:ReplaceMaterial(Region, 4, Enum.Material.LeafyGrass, Enum.Material.Grass)
end

function ItemReachedLimit(player,itemName)
	local count = 0
	for _,item in pairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetChildren()) do
		if (item.Name == itemName) then
			count = count + 1
		end
	end
	
	if (buildItems[itemName] and (count == buildItems[itemName].Limit)) then
		return true
	else
		return false
	end
end

function FindTerrainHeight(player,pos)

	local _, position, normal = workspace:FindPartOnRayWithWhitelist(Ray.new(pos, Vector3.new(0, player.Character.HumanoidRootPart.Position.Y-200, 0)), {workspace.Terrain})

	return position

end

function GetCampLocations(player,getAll)
	if (getAll == true) then
		local campLocations = {}


		for i, ply in pairs(Players:GetPlayers()) do

			if (ply.Name == player.Name) then
				continue
			end

			if (StatesFunctions.GetCampLocation(player) ~= nil) then
				campLocations[ply.Name] = StatesFunctions.GetCampLocation(player)
			end
		end

		return campLocations
	else
		return StatesFunctions.GetCampLocation(player)
	end
end


function CanBuildForQuest(player, placingTent, modelName)
	
	if (not QuestFunctions.HasQuest(player,"BuildCamp")) then
		return true
	end
	
	if (QuestFunctions.IsQuestComplete(player,"BuildCamp")) then
		return true
	end
	
	
	if (placingTent) then
		--Advance starter quest
		
		if (QuestFunctions.IsQuestStepComplete(player,"BuildCamp",1)) then
			return true
		end
		

		local timeOfDay,isDay = GetTimeOfDayServerEvent:Invoke()

		if (not isDay) then
			QuestFunctions.AdvanceQuestStep(player,"BuildCamp",1)
		else
			MessagePlayerEvent:FireClient(player, "I want to build the camp at night. Let's wait.")  
			return false
		end

	else
		--Not placing home tent		

		if (modelName == "camp_fire") then

			--Advance starter quest --TODO make this more generic to award any build quest, but may have performance issues
			if (QuestFunctions.IsQuestStepComplete(player,"BuildCamp",2)) then
				return true
			end
		
			local timeOfDay,isDay = GetTimeOfDayServerEvent:Invoke()

			if (not isDay) then
				QuestFunctions.AdvanceQuestStep(player,"BuildCamp",2)
			else
				return false
			end

			
		end
	end	
	
	return true

end

function CheckRequirements(player,model)
	if (ItemReachedLimit(player,model.Name)) then
		MessagePlayerEvent:FireClient(player,"Can only have "..buildItems[model.Name].Limit.." "..buildItems[model.Name].Name)
		return false
	end

	--Do we require anything to build this model? 
	if (buildItems[model.Name] and buildItems[model.Name].MaterialsRequired ~= nil) then

		local haveNeededMaterials = true
		local notEnoughMaterialsText = "Must have"

		for _, requiredMaterial in pairs(buildItems[model.Name].MaterialsRequired) do
			if (not InventoryFunctions.HasItem(player, requiredMaterial.MaterialRequired,requiredMaterial.AmountRequired)) then
				haveNeededMaterials = false
				MessagePlayerEvent:FireClient(player,"Must have "..requiredMaterial.AmountRequired.." "..requiredMaterial.MaterialRequired,requiredMaterial.MaterialRequired)

				if (itemsmodule[requiredMaterial.MaterialRequired] ~= nil)  then
					if (itemsmodule[requiredMaterial.MaterialRequired].ProductId ~= nil) then
						game:GetService("MarketplaceService"):PromptProductPurchase(player, itemsmodule[requiredMaterial.MaterialRequired].ProductId) --rbxassetid://"ID HERE
					end
				end

			end
		end

		if (not haveNeededMaterials) then
			return false
		else

			--Remove all the required material used
			for _, requiredMaterial in pairs(buildItems[model.Name].MaterialsRequired) do
				InventoryFunctions.RemoveItem(player,requiredMaterial.MaterialRequired, requiredMaterial.AmountRequired)
			end
			
			return true
		end
	end
	
	return true
end


function Place(player, model, cf, isColliding,placingTent, currentAttachment)
	if (not isColliding) then
		
		if (not CanBuildForQuest(player,placingTent,model.Name)) then
			return false
		end
		
		if not CheckRequirements(player,model) then
			return false
		end
				
		local clone = model:Clone()
		clone:SetAttribute("Owner",player.Name)
				
		--Set an offset if specified in builditems
		if (buildItems[model.Name] and buildItems[model.Name].OffsetY ~= nil) then
			cf = cf * CFrame.new(Vector3.new(0,buildItems[model.Name].OffsetY,0))
		end
				
		clone:SetPrimaryPartCFrame(cf)
			
		removeGrass(clone.PrimaryPart)
		
		--TODO must determine direction based on which of the 4 corner ray casts shows ground as much lower than center ground
		--OR just put for corners of pallets just in case.... won't be visible when tent is not overhanging
		
		local terrainHeightAtCenter = FindTerrainHeight(player,Vector3.new(clone.PrimaryPart.Position.X,clone.PrimaryPart.Position.Y+100,clone.PrimaryPart.Position.Z))
		local terrainHeightAtLeft = FindTerrainHeight(player,Vector3.new((clone.PrimaryPart.Position.X - clone.PrimaryPart.Size.X/4),clone.PrimaryPart.Position.Y+100,clone.PrimaryPart.Position.Z))
		local terrainHeightAtRight = FindTerrainHeight(player,Vector3.new((clone.PrimaryPart.Position.X + clone.PrimaryPart.Size.X/4),clone.PrimaryPart.Position.Y+100,clone.PrimaryPart.Position.Z))
		local terrainHeightAtBack = FindTerrainHeight(player,Vector3.new(clone.PrimaryPart.Position.X, clone.PrimaryPart.Position.Y+100,(clone.PrimaryPart.Position.Z + clone.PrimaryPart.Size.Z/4)))
		local terrainHeightAtFront = FindTerrainHeight(player,Vector3.new(clone.PrimaryPart.Position.X, clone.PrimaryPart.Position.Y+100,(clone.PrimaryPart.Position.Z - clone.PrimaryPart.Size.Z/4)))


		
		if ((terrainHeightAtCenter.Y - terrainHeightAtLeft.Y) > 2) then
			--Set Pallet for overhanging tents
			local pallet = Pallet:Clone()
			local palletOffset = .5
			pallet:SetPrimaryPartCFrame(CFrame.new(clone.PrimaryPart.Position.X - clone.PrimaryPart.Size.X/4, clone.PrimaryPart.Position.Y-((clone.PrimaryPart.Size.Y/2)+palletOffset),clone.PrimaryPart.Position.Z)*CFrame.Angles(0,math.rad(180),0))
			pallet.Parent = clone
			removeTerrain(clone.PrimaryPart)
		end
		
		if ((terrainHeightAtCenter.Y - terrainHeightAtRight.Y) > 2) then
			--Set Pallet for overhanging tents
			local pallet = Pallet:Clone()
			local palletOffset = .5
			pallet:SetPrimaryPartCFrame(CFrame.new(clone.PrimaryPart.Position.X + clone.PrimaryPart.Size.X/4, clone.PrimaryPart.Position.Y-((clone.PrimaryPart.Size.Y/2)+palletOffset),clone.PrimaryPart.Position.Z)*CFrame.Angles(0,math.rad(-180),0))
			pallet.Parent = clone
			removeTerrain(clone.PrimaryPart)
		end
			
		if ((terrainHeightAtCenter.Y - terrainHeightAtBack.Y) > 2) then
			--Set Pallet for overhanging tents
			local pallet = Pallet:Clone()
			local palletOffset = .5
			pallet:SetPrimaryPartCFrame(CFrame.new(clone.PrimaryPart.Position.X, clone.PrimaryPart.Position.Y-((clone.PrimaryPart.Size.Y/2)+palletOffset),clone.PrimaryPart.Position.Z + clone.PrimaryPart.Size.Z/4)*CFrame.Angles(0,math.rad(-90),0))
			pallet.Parent = clone

			removeTerrain(clone.PrimaryPart)
		end
		
		if ((terrainHeightAtCenter.Y - terrainHeightAtFront.Y) > 2) then
			--Set Pallet for overhanging tents
			local pallet = Pallet:Clone()
			local palletOffset = .5
			pallet:SetPrimaryPartCFrame(CFrame.new(clone.PrimaryPart.Position.X, clone.PrimaryPart.Position.Y-((clone.PrimaryPart.Size.Y/2)+palletOffset),clone.PrimaryPart.Position.Z - clone.PrimaryPart.Size.Z/4)*CFrame.Angles(0,math.rad(90),0))
			pallet.Parent = clone

			removeTerrain(clone.PrimaryPart)
		end
		
		if (placingTent) then
			--Add delete proximity
			local proxyPrompt = Instance.new("ProximityPrompt")
			proxyPrompt.Name = "DeleteBuildCamp"
			proxyPrompt.ActionText = "Delete"
			proxyPrompt.ObjectText = "Camp"
			proxyPrompt.HoldDuration = 3
			proxyPrompt.MaxActivationDistance = math.max(clone.PrimaryPart.Size.X,clone.PrimaryPart.Size.Z)
			proxyPrompt.RequiresLineOfSight = false
			proxyPrompt.Enabled = false
			proxyPrompt.Style = Enum.ProximityPromptStyle.Custom
			proxyPrompt.KeyboardKeyCode = Enum.KeyCode.Q
			proxyPrompt.Parent = clone.PrimaryPart
			
			
			StatesFunctions.SetCampLocation(player,clone.PrimaryPart.Position) 
			
			UpdateCampEvent:FireClient(player,clone.PrimaryPart.Position)
			
			--Advance starter quest
			if (QuestFunctions.HasQuest(player,"BuildCamp")) then
				if (not QuestFunctions.IsQuestComplete(player,"BuildCamp")) then
					if (not QuestFunctions.IsQuestStepComplete(player,"BuildCamp",1)) then
						local timeOfDay = GetTimeOfDayServerEvent:Invoke()
						
						if (timeOfDay > 18) then
							QuestFunctions.AdvanceQuestStep(player,"BuildCamp",1)
						else
							MessagePlayerEvent:FireClient(player, "I want to build the camp at night. Let's wait.")  
						end
						
						
					end
				end
			end
			
			
		else
			--Not placing home tent		
			
			--Add delete proximity
			local proxyPrompt = Instance.new("ProximityPrompt")
			proxyPrompt.Name = "DeleteBuildObject"
			proxyPrompt.ActionText = "Delete"
			proxyPrompt.ObjectText = model.Name
			proxyPrompt.HoldDuration = 2
			proxyPrompt.MaxActivationDistance = buildItems[model.Name].MaxDeleteActivation
			proxyPrompt.RequiresLineOfSight = false
			proxyPrompt.Enabled = false
			proxyPrompt.Style = Enum.ProximityPromptStyle.Custom
			proxyPrompt.KeyboardKeyCode = Enum.KeyCode.Q
			proxyPrompt.Parent = clone.PrimaryPart
						
			--Add light to campfire
			if (model.Name == "camp_fire") then
				local lightPart = Instance.new("Part")
				lightPart.Name = "LightPart"
				lightPart.Position = Vector3.new(clone.PrimaryPart.Position.X,clone.PrimaryPart.Position.Y + 5,clone.PrimaryPart.Position.Z)
				lightPart.Anchored = true
				lightPart.CanCollide = false
				lightPart.CanTouch = false
				lightPart.Transparency = 1
				lightPart.Parent = clone.PrimaryPart
				
				local light = Instance.new("PointLight")
				light.Enabled = false
				light.Brightness = .5
				light.Range = 15
				light.Parent = lightPart
				
				--Advance starter quest --TODO make this more generic to award any build quest, but may have performance issues
				if (QuestFunctions.HasQuest(player,"BuildCamp")) then
					if (not QuestFunctions.IsQuestComplete(player,"BuildCamp")) then
						if (not QuestFunctions.IsQuestStepComplete(player,"BuildCamp",2)) then
							local timeOfDay = GetTimeOfDayServerEvent:Invoke()

							if (timeOfDay > 18) then
								QuestFunctions.AdvanceQuestStep(player,"BuildCamp",2)
							end
							
						end
					end
				end
			end
		end	
								
		--If we are placing wire, place the wire instead of wire spool.
		if (buildItems[clone.Name].Wire) then
			
			--TODO have a timebomb created when connecting a powersource to another powersource (both eventually blow up)
			
			--This is our first wire spot
			if (PowerSourceFunctions.IsWireStart(player)) then
								
				if (currentAttachment.Parent:FindFirstChild("ElectricNode") ~= nil) then
					
					PowerSourceFunctions.AddTempWire(player,currentAttachment.Parent.ElectricNode,clone)
					clone.Parent = workspace:WaitForChild(player.Name.."_CampObjects")	
				else
					MessagePlayerEvent:FireClient(player,"No electric node found")
					return false
				end
			else
				--This is our second wire spot
				
				
				
				if (currentAttachment.Parent:FindFirstChild("ElectricNode") ~= nil) then
					
					PowerSourceFunctions.AddWire(player,currentAttachment.Parent.ElectricNode)
					
				end
								
				--TurnOnPower(player)
				
			end
		elseif (buildItems[clone.Name].Electric) then
			
			if (currentAttachment ~= nil) then
				--Electric item hanging on some other attachment like a lightbulb
				
				clone.Parent = workspace:WaitForChild(player.Name.."_CampObjects")	
				PowerSourceFunctions.AddElectricItem(player,clone,currentAttachment)

			else
				--Electric item not hanging like boombox
				clone.Parent = workspace:WaitForChild(player.Name.."_CampObjects")	
			end
			
			--TurnOnPower(player)
		else	
			clone.Parent = workspace:WaitForChild(player.Name.."_CampObjects")
			
			if (buildItems[clone.Name].PowerSource) then
				local powerSourceElectriNode = clone.PrimaryPart:FindFirstChild("ElectricNode")
				if (powerSourceElectriNode ~= nil) then
					PowerSourceFunctions.NewPlayerPowerSource(player,powerSourceElectriNode)
				end
				
			end
		end
		
		--Now that we are fully placed enable proximity prompts
		for index,decendant in ipairs(clone:GetDescendants()) do
			if (decendant:IsA("ProximityPrompt")) then
				if (decendant.ActionText ~= "Delete") then
					decendant.Enabled = true
				end
			elseif(decendant:IsA("MeshPart")) then
				if (not clone:GetAttribute("NoCollide")) then
					decendant.CanCollide = true
					
				end
			end
		end	
		
	end
	
	return true

end

function TurnOnPower(player,powerSource)
	
	--TODO we may want this to spawn on it's own thread
		
	--Clear all nodes
	for index,electricNode in ipairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetDescendants()) do
		if (electricNode.Name =="ElectricNode") then

			electricNode:SetAttribute("ElectricNodeOn",false)
			ElectricNodeChangeEvent:Fire(player,electricNode) --TODO fix this
		end
	end

	--For each power source follow the connections through all wires and electric devices
	--for index,item in ipairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetDescendants()) do
		--if ((item.Name =="ElectricNode") and (item:GetAttribute("PowerSource"))) then
			
	--TracePower(player,powerSource,CampElectricGrid[player.Name][powerSource],true)
			
		--end
	--end
	
	
end

--function TurnOffPower(player,powerSource)

--	--Do we have a camp for this owner and does this owner own this powerSource?
--	if (CampElectricGrid[player.Name] and CampElectricGrid[player.Name][powerSource]) then
--		TracePower(player,powerSource,CampElectricGrid[player.Name][powerSource],false)
--	end
	

	
--end

--TODO move to utils
local function GetPlayerFromName(name)

	for _, player in pairs(game:GetService("Players"):GetPlayers()) do

		if player.Name:lower() == name:lower() then
			return player
		end
	end

end

		
ProximityPromptService.PromptTriggered:Connect(function(promptObject, player)
	--TODO SECURITY check that player placed this object
	--if (player.Backpack:FindFirstChild("SledgeHammer") and player.Backpack:FindFirstChild("SledgeHammer"):IsA("Tool") and not player.Character:FindFirstChild("SledgeHammer")) then
	--	return
	--end
	
	if (promptObject.Name == "DeleteBuildObject") then
		addGrass(promptObject.Parent)
		
		local hasElectricNode = false
		--If this object has an electric node then reevaluate the grid
		if (promptObject.Parent:FindFirstChild("ElectricNode") ~= nil) then
			hasElectricNode = true
			
			--TODO handle this
			if (CampElectricGrid[player.Name][promptObject.Parent:FindFirstChild("ElectricNode")] ~= nil) then
				for index,connection in ipairs(CampElectricGrid[player.Name][promptObject.Parent:FindFirstChild("ElectricNode")]) do
					--Erase the connection nodes connections
					local connectionIndex = table.find(CampElectricGrid[player.Name],connection)
					table.remove(CampElectricGrid[player.Name],connectionIndex)
					--CampElectricGrid[player.Name][connection] = nil

					--Destroy the connected node
					if (connection.Parent ~= nil) then
						connection.Parent.Parent:Destroy()
					end

				end
			end			
		end
		
		promptObject.Parent.Parent:Destroy() --object.model
		
		if (hasElectricNode) then
			--TurnOnPower(player)
		end
		
		--TODO delete any connects hanging piece or electrical wire
		
		
	elseif (promptObject.Name == "DeleteBuildCamp") then
		
		StatesFunctions.SetCampLocation(player,nil)
		addTerrain(promptObject.Parent)
		addGrass(promptObject.Parent)
		sharedRemotes.CampCommands:FireClient(player,"Clear")
		--Destroy all camp objects for this player object.model.campfolder
		for _,buildObject in pairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetChildren()) do

			addGrass(buildObject.PrimaryPart)
			buildObject:Destroy()
		end
	end

end)

function FindHeight(player,model,pos)
	
	local CampObjects = workspace:WaitForChild(player.Name.."_CampObjects")

	local includedObjects={}
	local campObjects = CampObjects:GetChildren()

	table.insert(includedObjects,workspace.Terrain)

	for index,blocker in ipairs(BuildBlockers:GetChildren()) do
		table.insert(includedObjects,blocker)	
	end
	
	--TODO check HangingOnly status and set includedObjects to only those that have HangOn Attachment
	
	if (buildItems[model.Name].HangOn) then
		--INCLUDE ONLY HANGING ATTACHMENT PLACES
		for index,item in ipairs(campObjects) do
			if (item.Name ~= "CampArea" and item.Name ~= model.Name) then
				
				if (item.PrimaryPart:FindFirstChild("HangOn") ~= nil) then
					table.insert(includedObjects,item)
				end
			end
		end
	else
		--INCLUDE REGULAR ATTACHMENT PLACES THAT ARE ALLOWED FOR THIS ITEM
		for index,item in ipairs(campObjects) do
			if (item.Name ~= "CampArea" and item.Name ~= model.Name) then
				if (table.find(buildItems[item.Name].AllowedToBuildOn, model.Name) ~= nil) then
					table.insert(includedObjects,item)	
				end
			end
		end
	end
	
	local hit, position, normal = workspace:FindPartOnRayWithWhitelist(Ray.new(pos, Vector3.new(0, -400, 0)), includedObjects)	--used to be -198	

	if (hit ~= nil) then
		if (hit.Name == "BuildBlocker") then
			return Vector3.new(-1,-1,-1)
		end
	end


	if (hit ~= nil and hit.Name == "GridPart" and hit.Parent.PrimaryPart ~= nil and hit.Parent.PrimaryPart:FindFirstChild("Attachment") ~= nil) then
		if (table.find(buildItems[hit.Parent.Name].AllowedToBuildOn, model.Name) ~= nil) then

			position = hit.Parent.GridPart.Attachment.WorldPosition
		end
	end

	return position

end

function CalcPlacementCFrameWire(player, model, position, rotation, clampToCanvas, mouseHit)
	local campAreaPosition = Vector3.new(mouseHit.X,0,mouseHit.Z)
	local campAreaSize = Vector3.new(75, 100, 75)

	local x = position.X
	local z = position.Z

	local modelSize = CFrame.fromEulerAnglesYXZ(0, rotation, 0) * model.PrimaryPart.Size
	modelSize = Vector3.new(math.abs(modelSize.x), math.abs(modelSize.y), math.abs(modelSize.z))
	local size2 = (Vector2.new(campAreaSize.X,campAreaSize.Z)  - Vector2.new(modelSize.x, modelSize.z))/2

	if (clampToCanvas) then

		x = math.clamp(x, campAreaPosition.X - size2.x, campAreaPosition.X + size2.x);
		z = math.clamp(z, campAreaPosition.Z - size2.y, campAreaPosition.Z + size2.y);

	end

	--Get hit ray to ground
	local terrainPosition = FindHeight(player, model, Vector3.new(x, player.Character.HumanoidRootPart.Position.Y+200, z))

	--Find closest HangOnAttachment to mouse
	local closestDistance = 9999999
	local wireAttachment = nil
	for index,item in ipairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetDescendants()) do
		if (item.Name =="ElectricNode") then
			if ((item.WorldPosition - position).magnitude < closestDistance) then
				closestDistance = (item.WorldPosition - position).magnitude
				wireAttachment = item
			end
		end
	end

	if (wireAttachment ~= nil) then
		return (wireAttachment.Parent.CFrame * CFrame.Angles(math.rad(90), 0, 0)) - Vector3.new(0, model.PrimaryPart.Size.Y/2, 0),wireAttachment
	else
		return CFrame.new(terrainPosition.X, terrainPosition.Y + (model.PrimaryPart.Size.Y/2), terrainPosition.Z),nil
	end


end

local campAreaSize = Vector3.new(75, 100, 75)
local function withinCampsite(player,position)
	
	local campLocation = StatesFunctions.GetCampLocation(player)
	-- Calculate the min and max bounds of the box
	local halfSize = campAreaSize / 2
	local minBound = campLocation - halfSize
	local maxBound = campLocation + halfSize

	-- Check if the position is within these bounds
	return (position.X >= minBound.X and position.X <= maxBound.X) and
		(position.Y >= minBound.Y and position.Y <= maxBound.Y) and
		(position.Z >= minBound.Z and position.Z <= maxBound.Z)
end


--show initial tent whereever you want by not clamping x and y.
function CalcPlacementCFrame(player, model, position, rotation, clampToCanvas, mouseHit)
	local CampObjects = workspace:WaitForChild(player.Name.."_CampObjects")
	local campAreaPosition = Vector3.new(mouseHit.X,0,mouseHit.Z)
	local campAreaSize = Vector3.new(75, 100, 75)
	
	local x = position.X
	local z = position.Z

	local modelSize = CFrame.fromEulerAnglesYXZ(0, rotation, 0) * model.PrimaryPart.Size
	modelSize = Vector3.new(math.abs(modelSize.x), math.abs(modelSize.y), math.abs(modelSize.z))
	local size2 = (Vector2.new(campAreaSize.X,campAreaSize.Z)  - Vector2.new(modelSize.x, modelSize.z))/2
		
	if (clampToCanvas) then

		x = math.clamp(x, campAreaPosition.X - size2.x, campAreaPosition.X + size2.x);
		z = math.clamp(z, campAreaPosition.Z - size2.y, campAreaPosition.Z + size2.y);
		
	end

	--Get hit ray to ground
	local terrainPosition = FindHeight(player, model, Vector3.new(x, player.Character.HumanoidRootPart.Position.Y+200, z))

	--Logger.Debug("Model Name:"..model.Name.." X:"..x.." Z:"..z.." HIT X"..terrainPosition.X.." HIT.Y:"..terrainPosition.Y.." HIT Z:"..terrainPosition.Z)
	if (terrainPosition.X == -1) then
		return nil
	end

	return CFrame.new(terrainPosition.X, terrainPosition.Y + (model.PrimaryPart.Size.Y/2), terrainPosition.Z) * CFrame.Angles(0, rotation, 0)
end

function CalcPlacementCFrameHanging(player, model, position, rotation, clampToCanvas, mouseHit)
	local campAreaPosition = Vector3.new(mouseHit.X,0,mouseHit.Z)
	local campAreaSize = Vector3.new(75, 100, 75)
	
	local x = position.X
	local z = position.Z

	local modelSize = CFrame.fromEulerAnglesYXZ(0, rotation, 0) * model.PrimaryPart.Size
	modelSize = Vector3.new(math.abs(modelSize.x), math.abs(modelSize.y), math.abs(modelSize.z))
	local size2 = (Vector2.new(campAreaSize.X,campAreaSize.Z)  - Vector2.new(modelSize.x, modelSize.z))/2

	if (clampToCanvas) then

		x = math.clamp(x, campAreaPosition.X - size2.x, campAreaPosition.X + size2.x);
		z = math.clamp(z, campAreaPosition.Z - size2.y, campAreaPosition.Z + size2.y);

	end

	--Get hit ray to ground
	local terrainPosition = FindHeight(player, model, Vector3.new(x, player.Character.HumanoidRootPart.Position.Y+200, z))

	--Find closest HangOnAttachment to mouse
	local closestDistance = 9999999
	local hangOnAttachment = nil
	for index,item in ipairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetDescendants()) do
		if (item.Name =="HangOn") then
			if ((item.WorldPosition - position).magnitude < closestDistance) then
				closestDistance = (item.WorldPosition - position).magnitude
				hangOnAttachment = item
			end
		end
	end

	if (hangOnAttachment ~= nil) then
		return CFrame.new(hangOnAttachment.WorldPosition - Vector3.new(0, model.PrimaryPart.Size.Y/2, 0)) * CFrame.Angles(0, rotation, 0), hangOnAttachment --(hangOnAttachment.Parent.CFrame)-- * CFrame.Angles(math.rad(90), rotation, 0)) - Vector3.new(0, model.PrimaryPart.Size.Y/2, 0)
	else
		return CFrame.new(terrainPosition.X, terrainPosition.Y + (model.PrimaryPart.Size.Y/2), terrainPosition.Z), nil
	end


end

local function PlaceBoards(player,model,flipFacing,lastPreviewDir,lastPreviewCenter,lastPreviewLength,lastPreviewUp)
	if not lastPreviewDir or not lastPreviewCenter or not lastPreviewLength or not model then
		warn("Missing preview data. Cannot place boards.")
		return
	end

	local CampObjects = workspace:WaitForChild(player.Name .. "_CampObjects")
	local boardLength = 15 -- Length of a single board
	
	local dir = lastPreviewDir -- Direction the board should extend
	local up = lastPreviewUp   -- Up vector based on placement mode
	local totalLength = lastPreviewLength -- Total distance the player dragged
	local startPos = lastPreviewCenter - dir * (totalLength / 2) -- Starting point of the first board

	-- Determine if we need to split the board
	local totalBoards = 1
	local lengths = { totalLength }

	if totalLength > boardLength then
		totalBoards = 2
		local half = totalLength / 2
		lengths = { half, half }
	end

	local placedBoards = {}
	local nailSpacing = 1

	for i = 1, totalBoards do
		local length = lengths[i]
		local baseOffset = ((i - 1) * length) + (length / 2) -- Position center of board
		local lateralOffset = 0 -- No lateral staggering

		local centerPos = startPos + dir * baseOffset -- Move along placement direction
		local lateralAxis = dir:Cross(up).Unit -- Axis perpendicular to both direction and up
		centerPos += lateralAxis * lateralOffset

		local placingmodel = model:Clone()

		local board = placingmodel.PrimaryPart
		if not board then warn("Model missing PrimaryPart") return end

		-- Rotate and resize the board depending on facing
		if flipFacing then
			local look = up
			local right = dir.Unit
			local newUp = look:Cross(right).Unit
			placingmodel:PivotTo(CFrame.fromMatrix(centerPos, right, newUp))
			board.Size = Vector3.new(length, board.Size.Y, board.Size.Z)
		else
			placingmodel:PivotTo(CFrame.fromMatrix(centerPos, dir, up))
			board.Size = Vector3.new(length, board.Size.Y, board.Size.Z)
		end

		placingmodel.Parent = CampObjects
		table.insert(placedBoards, placingmodel)

		board.CanTouch = true
		board.CanCollide = true
	end

	if totalBoards == 2 then
		-- Add a third board over the seam between the two boards
		local connectingLength = totalLength/4
		local midPos = startPos + dir * (totalLength / 2)
		local offsetDir = flipFacing and up or dir
		local connectingOffset = flipFacing and 0.1 or 0

		local connectModel = model:Clone()
		connectModel.Name = "ConnectionBoard"
		local connectBoard = connectModel.PrimaryPart
		if not connectBoard then warn("Model missing PrimaryPart") return end

		if flipFacing then
			-- Face-on board, so Z is aligned with wall normal (up), face normal = up
			local look = up
			local right = dir.Unit
			local newUp = look:Cross(right).Unit

			local rotation = CFrame.fromMatrix(midPos, right, newUp)

			-- Use rotation.LookVector to offset forward (Z axis of the board)
			local faceOffset = rotation.LookVector * .25

			connectModel:PivotTo(rotation + faceOffset)
			connectBoard.Size = Vector3.new(connectingLength, connectBoard.Size.Y, connectBoard.Size.Z)

		else
			-- Edge-on board, face normal is dir, so Z is perpendicular to dir
			local rotation = CFrame.fromMatrix(midPos, dir, up)

			-- Again, offset using board's local Z (face normal)
			local faceOffset = rotation.LookVector * .25

			connectModel:PivotTo(rotation + faceOffset)
			connectBoard.Size = Vector3.new(connectingLength, connectBoard.Size.Y, connectBoard.Size.Z)
		end

		connectModel.Parent = CampObjects
		table.insert(placedBoards, connectModel)
		connectBoard.CanTouch = true
		connectBoard.CanCollide = true
	end

	--AddNails(placedBoards)


	local dir = lastPreviewDir -- Direction the board should extend
	local up = lastPreviewUp   -- Up vector based on placement mode
	local totalLength = lastPreviewLength -- Total distance the player dragged
	local startPos = lastPreviewCenter
	return
end

ReplicatedStorage:WaitForChild("SharedRemotes").CampPlacement.OnServerInvoke = function(player,actionType,modelName, cf, isColliding, mouseHit, rotation)
	
	--TODO SECURITY check if the player has already placed his home or not and allow or not allow.

	local model
	
	if (actionType=="PlaceTent") then
		
		if (not InventoryFunctions.HasBuildItem(player, modelName, "Tents")) then
			return
		end
		
		if (buildItems[modelName] ~= nil)  then
			if (InventoryFunctions.PlayerHasReachedBuildLimit(player, modelName)) then
				MessagePlayerEvent:FireClient(player,"You cannot place any more "..modelName,modelName)
			end
		end
		
		--Make sure player is allowed to place that tent in that spot
		
		--Don't allow placement of tent/camp in or too near other camps
		local campLocations = GetCampLocations(player,true)
		if (campLocations ~= nil) then
			--loop through all camp locations and see if we are too close to one
			for i, campLocation in pairs(campLocations) do

				if (campLocation - cf.Position).Magnitude < 75 then
					MessagePlayerEvent:FireClient(player,"CAN'T PLACE CAMP. TOO CLOSE TO OTHER CAMPS")
					return false
				end
			end
		end
		
		--find model if it exists
		for i=1,#tents do
			if tents[i].Name == modelName then
				model = tents[i]
				break
			end
		end
		
		if (model ~= nil) then
			
			--local serverCf = CalcPlacementCFrame(player,model, mouseHit, rotation, true, mouseHit)

			--if ((cf.p - serverCf.p).Magnitude > 3) then
			--	warn("Server tent placement does not match client attempted tent placement:",cf.p,serverCf.p)
			--	MessagePlayerEvent:FireClient(player,"ILLEGAL PLACEMENT")
			--	return false
			--end
			
			
			
			
			return Place(player,model, cf, isColliding,true)
		end
		
	elseif (actionType=="PlaceItem") then
		
		if (not InventoryFunctions.HasBuildItem(player, modelName, buildItems[modelName].Type)) then
			return false
		end
		
		if (not buildItems[modelName].Unlimited and InventoryFunctions.PlayerHasReachedBuildLimit(player, modelName)) then
			MessagePlayerEvent:FireClient(player,"You cannot place any more "..modelName,modelName)
			return false
		end
		
		if (not buildItems[modelName].Unlimited and (not InventoryFunctions.PlayerOwnsEnoughItem(player,modelName,buildItems[modelName].Type))) then

			if (buildItems[modelName].ProductId ~= nil) then
				game:GetService("MarketplaceService"):PromptProductPurchase(player, buildItems[modelName].ProductId)
			end
			
			MessagePlayerEvent:FireClient(player,"You do not have enough "..modelName,modelName)
			
			return false
		end
		
		--find model if it exists
		
		if (buildItems[modelName].Type == "Gardening") then
			for i=1,#gardeningItems do
				if gardeningItems[i].Name == modelName then
					model = gardeningItems[i]
					break
				end
			end
		else
			for i=1,#items do
				if items[i].Name == modelName then
					model = items[i]
					break
				end
			end
		end

		if (model ~= nil) then
			
			if (buildItems[model.Name].SubType == "Construction") then
				PlaceBoards(player,model,cf.FlipFacing,cf.LastPreviewDir,cf.LastPreviewCenter,cf.LastPreviewLength,cf.LastPreviewUp)
				return
			end
			
			
			local serverCf = CalcPlacementCFrame(player,model, mouseHit, rotation, true, mouseHit)
			local attachment = nil

			if (buildItems[model.Name].HangOn) then
				serverCf,attachment = CalcPlacementCFrameHanging(player,model, mouseHit, rotation, true, mouseHit)
			elseif (buildItems[model.Name].Wire) then
				serverCf,attachment = CalcPlacementCFrameWire(player,model, mouseHit, rotation, true, mouseHit)
			else
				serverCf = CalcPlacementCFrame(player,model, mouseHit, rotation, true, mouseHit)
			end
			
			--if (cf.p - serverCf.p).Magnitude > 1 then --if (cf.p ~= serverCf.p) then
			--	warn("Server build item placement does not match client attempted build item placement:",cf.p,serverCf.p)
			--	MessagePlayerEvent:FireClient(player,"ILLEGAL PLACEMENT")
			--	return false
			--end
			
			if (not withinCampsite(player,cf.p)) then
				warn("Placement is not within campsite bounds player:",player.Name)
				MessagePlayerEvent:FireClient(player,"ILLEGAL PLACEMENT")
				return false
			end
			
			if (buildItems[model.Name].SubType == "Soil") then
				local campFolder = workspace:FindFirstChild(player.Name.."_CampObjects")
				
				if (not campFolder) then
					return
				end
				
				if not CheckRequirements(player,model) then
					return false
				end
				
				local canPlace,failureReason = GardeningFunctions.CanPlaceSoil(campFolder, StatesFunctions.GetCampLocation(player), cf.Position)
				
				if (not canPlace) then
					
					MessagePlayerEvent:FireClient(player,failureReason)
					
					return false
				end
				
				local soilFertility = model:GetAttribute("SoilFertility") or "Poor"
				
				return GardeningFunctions.PlaceSoil(player, soilFertility, campFolder, StatesFunctions.GetCampLocation(player), cf.Position)
			elseif (buildItems[model.Name].SubType == "Seeds") then
				local campFolder = workspace:FindFirstChild(player.Name.."_CampObjects")

				if (not campFolder) then
					return
				end

				if not CheckRequirements(player,model) then
					return false
				end

				local canPlace,failureReason = GardeningFunctions.CanPlaceSeed(campFolder, StatesFunctions.GetCampLocation(player), cf.Position)

				if (not canPlace) then

					MessagePlayerEvent:FireClient(player,failureReason)

					return false
				end

				return GardeningFunctions.PlaceSeed(player, model, campFolder, StatesFunctions.GetCampLocation(player), cf.Position)
			else
				return Place(player,model, cf, isColliding,false,attachment)
			end
			
			
		end
		
	end
	
	return true
	
	
end

GetCampLocationEvent.OnServerInvoke = function(player,getAll)
	
	----TODO REMOVE THIS
	--for i,v in pairs (workspace:GetDescendants()) do
	--	if v:IsA("BasePart") then
	--		if v.Anchored == false then
	--			Logger.Debug("UNANCHORED PART:"..v.Name)
	--		end
	--	end
	--end
	
	return GetCampLocations(player,getAll)
end