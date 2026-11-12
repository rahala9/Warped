local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerStorage = game:GetService("ServerStorage")
local Replicator =  ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local UpdateStaminaEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateStamina")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local TweenService = game:GetService("TweenService")
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local enemyModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemy")) 

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local bearTrap = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("BearTrap")
local rocket = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Rocket")
local ServerScriptService = game:GetService("ServerScriptService")
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local EnemyFunctions = require(ServerScriptService.SharedFunctions.EnemyFunctions)
local HoldToolEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("HoldTool")
local PlaceObjectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlaceObject")

local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local CollectionService = game:GetService("CollectionService")
local ts = game:GetService("TweenService") --TweenService
local Debris = game:GetService("Debris")
local DisplayPhotoEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DisplayPhoto")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")


local spraySound = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("Spray")
local graffiti1 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti1")
local graffiti2 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti2")
local graffiti3 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti3")
local graffiti4 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti4")
local graffiti5 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti5")
local graffiti6 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti6")
local graffiti7 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti7")
local graffiti8 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti8")
local graffiti9 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti9")
local graffiti10 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti10")
local graffiti11 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti11")
local graffiti12 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti12")
local graffiti13 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti13")
local graffiti14 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti14")
local graffiti15 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti15")
local graffiti16 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti16")
local graffiti17 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti17")
local graffiti18 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti18")
local graffiti19 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti19")
local graffiti20 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti20")
local graffiti21 = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Graffiti"):WaitForChild("Graffiti21")

local GraffitiTags = {["Graffiti1"]=graffiti1,["Graffiti2"]=graffiti2,["Graffiti3"]=graffiti3,["Graffiti4"]=graffiti4,["Graffiti5"]=graffiti5,["Graffiti6"]=graffiti6,["Graffiti7"]=graffiti7,["Graffiti8"]=graffiti8,["Graffiti9"]=graffiti9,["Graffiti10"]=graffiti10,["Graffiti11"]=graffiti11,["Graffiti12"]=graffiti12,["Graffiti13"]=graffiti13,["Graffiti14"]=graffiti14,["Graffiti15"]=graffiti15,["Graffiti16"]=graffiti16,["Graffiti17"]=graffiti17,["Graffiti18"]=graffiti18,["Graffiti19"]=graffiti19,["Graffiti20"]=graffiti20,["Graffiti21"]=graffiti21} 

local ToolStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ToolStateChange")

local Balloon = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("balloon")
local Photo = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("photo")

local SetTrapAnimation = ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("SetTrap")

local R = Random.new()

local CollisionGroup = "Enemy"

local playerLastAttack = {}

local function SetVisible(targetModel: Model, visible: boolean)
	for _, obj in ipairs(targetModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- render
			obj.Transparency = visible and 0 or 1
			obj.CastShadow = visible

			-- physics (optional, for performance)
			obj.CanCollide = visible
			obj.CanTouch = visible
			obj.CanQuery = visible
		end
	end
end

function FindTerrainHeight(player,pos)

	--print("TEST FIND TERRAIN HEIGHT FOR LOG PILE pos: PlayerPosition:",pos,player.Character.HumanoidRootPart.Position.Y-200)
	local _, position, normal = workspace:FindPartOnRayWithWhitelist(Ray.new(pos, Vector3.new(0, player.Character.HumanoidRootPart.Position.Y-200, 0)), {workspace.Terrain})

	return position

end

local function SetItemOnGround(player,item,forwardOffset,heightOffset)
	-- Simplify target position calculation
	local playerCFrame = player.Character.PrimaryPart.CFrame
	local targetPosition = playerCFrame.Position + Vector3.new(0, 5, 0) + (forwardOffset * playerCFrame.LookVector)

	-- Set up raycasting parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace.Lights} --{workspace.Terrain,workspace.Ground}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Perform the raycast downward
	local raycastResult = workspace:Raycast(targetPosition, Vector3.new(0, -200, 0), raycastParams)

	if raycastResult then
		local position = raycastResult.Position
		local normal = raycastResult.Normal

		-- Adjust the position slightly above the ground
		local placingPosition = position + Vector3.new(0, heightOffset, 0)

		-- Set the rocket's position and orientation
		item:SetPrimaryPartCFrame(
			CFrame.new(placingPosition, placingPosition + normal) * CFrame.Angles(-math.pi * 0.5, 0, 0)
		)
	else
		warn("Raycast did not hit the terrain.")
	end

end

local function SetBearTrap(player)
	local newBearTrap = bearTrap:Clone()
	newBearTrap.Name = player.Name.."_".."BearTrap"

	SetItemOnGround(player,newBearTrap,8,.3)
	
	newBearTrap.Parent = workspace
	
	newBearTrap:SetAttribute("Owner",player.Name)
	
	CollectionService:AddTag(newBearTrap,"Trap")

	Debris:AddItem(newBearTrap, 60)

end

local function HandleRocketLaunch(promptObject, player)
	local newRocket = promptObject.Parent
	local weapon = InventoryFunctions.GetItemDef("Rocket") 
	
	newRocket.SparkAttachment.Spark.Enabled = true
	
	newRocket.fuse:Play()
	
	delay(3,function()
		newRocket:Destroy()

		local Data = {}
		local Module = ServerScriptService:WaitForChild("SharedFX"):FindFirstChild(weapon.Name)

		if Module then
			require(Module)(player, CFrame.new(Vector3.new(newRocket.CFrame.Position.X,newRocket.CFrame.Position.Y+100,newRocket.CFrame.Position.Z)), weapon, nil,newRocket.CFrame, Data)
		else
			Replicator:FireAllClients("Rocket")
		end
	end)
	
end

local function SetRocket(player)
	local newRocket = rocket:Clone()
	newRocket.Name = player.Name.."_".."Rocket"

	SetItemOnGround(player,newRocket,5,1)
	
	newRocket.PrimaryPart.CanCollide = false
	newRocket.Parent = workspace.UserDroppedItems

	newRocket:SetAttribute("Owner",player.Name)

	Debris:AddItem(newRocket, 60)

end

local function HandleBearTrap(player, tool)
	local setTrap = player.Character.Humanoid:LoadAnimation(SetTrapAnimation)
	
	local HRP = player.Character["HumanoidRootPart"]
	
	if (not HRP) then
		return
	end
	
	HRP.Anchored = true
	
	setTrap:Play()
	setTrap:AdjustSpeed(2)
	
	--TODO wait for animation marker event
	--wait(2) --setTrap.Stopped:Wait()
	
	local setTrapEvent
	setTrapEvent = setTrap:GetMarkerReachedSignal("Set"):Connect(function(paramString)
		SetBearTrap(player)
		setTrapEvent:Disconnect()
	end)
	
	setTrap.Stopped:Wait()
	HRP.Anchored = false
	
	
end

local function HandleRocket(player, tool)
	----local setTrap = player.Character.Humanoid:LoadAnimation(SetTrapAnimation)
	
	--local HRP = player.Character["HumanoidRootPart"]

	--if (not HRP) then
	--	return
	--end
	
	--HRP.Anchored = true
	
	----setTrap:Play()
	----setTrap:AdjustSpeed(2)

	------TODO wait for animation marker event
	------wait(2) --setTrap.Stopped:Wait()

	----local setTrapEvent
	----setTrapEvent = setTrap:GetMarkerReachedSignal("Set"):Connect(function(paramString)
	----	SetRocket(player)
	----	setTrapEvent:Disconnect()
	----end)

	----setTrap.Stopped:Wait()
	--HRP.Anchored = false
end

-- Function to return a random primary or secondary color
local function GetRandomPrimaryOrSecondaryColor()
	local colors = {
		Color3.fromRGB(255, 0, 0),    -- Red
		Color3.fromRGB(0, 255, 0),    -- Green
		Color3.fromRGB(0, 0, 255),    -- Blue
		Color3.fromRGB(255, 255, 0),  -- Yellow
		Color3.fromRGB(255, 165, 0),  -- Orange
		Color3.fromRGB(255, 255, 255) -- White
	}

	-- Return a random color from the colors table
	return colors[math.random(1, #colors)]
end


local function HandleBalloon(player, tool)
	
	local info = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0) -- -1 is for repeat count which will be infinite, false is for bool reverses which means it will not go backwards

	
	local balloonModel = Balloon:Clone()
	
	balloonModel.RopeConstraint.Attachment1 = ToolFunctions.GetToolHandle(player,"Balloon").Parent	
	balloonModel.PrimaryPart.Float.Enabled = false
	balloonModel.Parent = workspace
	
	local balloon = balloonModel.PrimaryPart
	
	balloon.Color = GetRandomPrimaryOrSecondaryColor()
	
	local targetBalloonSize = Vector3.new(1.876, 2.782, 1.972)
	local inflateSoundFX = balloon.Inflate
	local inflated = false

	local goals = {Size = targetBalloonSize} --Rotating it 360 degrees will make it go back to the original starting point, and with an infinite repeat count, it will go forever.
	local tween = ts:Create(balloon, info, goals)
	tween:Play()
	inflateSoundFX:Play()
	tween.Completed:Connect(function()

		-- Create a VectorForce
		local mass = balloon:GetMass()

		local vectorForce = Instance.new("VectorForce")
		vectorForce.Force = Vector3.new(0, mass * 196.2 + 1200, 0) -- Upward force slightly stronger than gravity
		vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World -- Force is relative to the world coordinates
		vectorForce.Attachment0 = balloon:FindFirstChildOfClass("Attachment") -- Ensure the balloon has an Attachment
		vectorForce.Parent = balloon

		-- Make sure the balloon has an Attachment for VectorForce to work
		if not vectorForce.Attachment0 then
			local attachment = Instance.new("Attachment")
			attachment.Parent = balloon
			vectorForce.Attachment0 = attachment
		end

		task.wait()
		inflated = true
	end)

end

local function placeDecal(player,position, normal)
	
	local decalPart = Instance.new("Part")
	decalPart.Size = Vector3.new(4, 4, 0.1)  
	decalPart.Anchored = true
	decalPart.CanCollide = false
	decalPart.Transparency = 1
	decalPart.Parent = workspace

	decalPart.CFrame = CFrame.lookAt(position, position - normal)

	decalPart.CFrame = decalPart.CFrame * CFrame.new(1, 1, -decalPart.Size.Z/2)

	local decal = Instance.new("Decal")

	decal.Face = Enum.NormalId.Back
	local sprayPainting = StatesFunctions.GetSpraypaintingTag(player)

	decal.Texture = GraffitiTags[sprayPainting["Tag"]].Texture
	decal.Parent = decalPart
	
	Debris:AddItem(decalPart, 60)
end

local function HandleConsume(player,toolName)
	InventoryFunctions.ConsumeItem(player,toolName)
end

local function HandleDrop(player,toolName)
	InventoryFunctions.DropItem(player,toolName)
end

local function HandleCamera(player, tool,toolAction)

	local direction = player.Character.HumanoidRootPart.CFrame.LookVector -- This gets the direction the player is facing
	local rayOrigin = player.Character.HumanoidRootPart.Position -- Start the ray from the player's position

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude 
	raycastParams.IgnoreWater = true 

	local raycastResult = workspace:Raycast(rayOrigin, direction * 20, raycastParams)
	
	local photoName = nil
	
	-- Check if the ray hit something
	if raycastResult then
		local hitPart = raycastResult.Instance -- The part the ray hit
		local hitPosition = raycastResult.Position -- The position where the ray hit
		local hitNormal = raycastResult.Normal -- The normal at the hit point
		
		local model = hitPart:FindFirstAncestorOfClass("Model")
		print("TEST PHOTO model:",model.Name)
		if (model) then
			local photo = model:GetAttribute("Photo")
			print("TEST PHOTO photo:",photo)
			if (photo) then
				photoName = photo
			end
		end
	

	end

	local toolHandle = ToolFunctions.GetToolHandle(player,tool)
	
	local photoModel = Photo:Clone()
	local forward = toolHandle.CFrame.LookVector
	local toolCFrame = toolHandle.TransformedWorldCFrame * CFrame.new(0,.4,.2) -- 0,0,2 was down, 2,0,0 went right, 0,2,0 went forward

	photoModel.PrimaryPart.CFrame = toolCFrame -- * CFrame.Angles(math.rad(-90), 0, 0)
	photoModel.PrimaryPart.CFrame = photoModel.PrimaryPart.CFrame * CFrame.Angles(math.rad(-90), 0, 0)
	--photoModel.PrimaryPart.Anchored = true
	photoModel.Parent = workspace
	
	photoModel.PrimaryPart.AssemblyLinearVelocity = toolHandle.TransformedWorldCFrame.UpVector * 20
	
	Debris:AddItem(photoModel,5)
	
	--If they take a selfie for the first time give the TrueColors quest
	
	if (toolAction == "UseTool2") then
		--message,requiredItemName,keepOn,posX,posY,textColor,fadeTime,startTime,guiType,titleType
		
		InventoryFunctions.AddItem("Selfie")
		
		MessagePlayerEvent:FireClient(player,"This camera somehow captured my true self",nil,nil,nil,nil,nil,5)
		
		DisplayPhotoEvent:FireClient(player,"Selfie")
	else
		
		if (photoName) then
			print("TEST PHOTO sending to client:",photoName)
			DisplayPhotoEvent:FireClient(player,photoName)
		end
		
	end
	

end

local function HandleSpraypaint(player, tool)

	local direction = player.Character.HumanoidRootPart.CFrame.LookVector -- This gets the direction the player is facing
	local rayOrigin = player.Character.HumanoidRootPart.Position -- Start the ray from the player's position

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude 
	raycastParams.IgnoreWater = true 

	local raycastResult = workspace:Raycast(rayOrigin, direction * 20, raycastParams)

	-- Check if the ray hit something
	if raycastResult then
		local hitPart = raycastResult.Instance -- The part the ray hit
		local hitPosition = raycastResult.Position -- The position where the ray hit
		local hitNormal = raycastResult.Normal -- The normal at the hit point
		
		if (hitPart:GetAttribute("CanBeSpraypainted")) then
			placeDecal(player,hitPosition, hitNormal)
		end
		
	end
	
	local toolHandle = ToolFunctions.GetToolHandle(player,tool)
	
	local SprayPaintParticles1 = toolHandle:FindFirstChild("SpraypaintParticles1")
	local SprayPaintParticles2 = toolHandle:FindFirstChild("SpraypaintParticles2")
	local SprayPaintParticles3 = toolHandle:FindFirstChild("SpraypaintParticles3")
	
	local sprayPainting = StatesFunctions.GetSpraypaintingTag(player)

	if (SprayPaintParticles1 and sprayPainting["Color1"] ~= "") then
		SprayPaintParticles1.Color = ColorSequence.new(Color3.fromHex(sprayPainting["Color1"]))
		SprayPaintParticles1:Emit(1)
	end
	
	if (SprayPaintParticles2 and sprayPainting["Color2"] ~= "") then
		SprayPaintParticles2.Color = ColorSequence.new(Color3.fromHex(sprayPainting["Color2"]))
		SprayPaintParticles2:Emit(1)
	end
	
	if (SprayPaintParticles3 and sprayPainting["Color3"] ~= "") then
		SprayPaintParticles3.Color = ColorSequence.new(Color3.fromHex(sprayPainting["Color3"]))
		SprayPaintParticles3:Emit(1)
	end
	
	
	local spraySoundFX = spraySound
	
	spraySoundFX:Play()
	
end

ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UseTool").OnServerEvent:Connect(function(player,toolActionType)
	
	local heldToolName = StatesFunctions.GetCurrentTool(player)
		
	if (heldToolName == "") then
		return
	end
	
	local itemDef = InventoryFunctions.GetItemDef(heldToolName)
	
	local toolAction1 = itemDef.ToolAction1
	local toolAction2 = itemDef.ToolAction2
	local toolAction = nil
	
	if (toolActionType == "UseTool") then
		toolAction = toolAction1
	else
		toolAction = toolAction2
	end
	
	if (not (InventoryFunctions.HasTool(player,heldToolName))) then --or ( not itemDef.CanBeHeld)) then
		return
	end
	
	if (heldToolName == "BearTrap") then
		HandleBearTrap(player, heldToolName)
	elseif (heldToolName == "Rocket") then
		HandleRocket(player, heldToolName)
	elseif (heldToolName == "Balloon") then
		HandleBalloon(player, heldToolName)
	elseif (heldToolName == "Spraypaint") then
		HandleSpraypaint(player, heldToolName)
	elseif (heldToolName == "Camera") then
		HandleCamera(player, heldToolName,toolActionType)
	elseif (toolAction == "Consume") then
		HandleConsume(player, heldToolName)
	elseif (toolAction == "Drop") then
		HandleDrop(player, heldToolName)
	else
		--Logger.Debug("TEST UseTool: ",heldToolName)
	end
	
	--Reduce stamina every time we use a tool
	StatesFunctions.RemoveStamina(player,1)
	UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , 100)

end)

HoldToolEvent.OnServerEvent:Connect(function(player,itemName,slot,equip)
	
	--SECURITY make sure they have the item before setting it as their current tool
	if (itemName ~= "" and (InventoryFunctions.GetItemDef(itemName) == nil) and (InventoryFunctions.GetWeapon(player,itemName) ~= nil) and (InventoryFunctions.GetOffHand(player,itemName) ~= nil) and (InventoryFunctions.GetArtifact(player,itemName) ~= nil)) then
		return
	end

	if (itemName ~= nil) then
		if (InventoryFunctions.GetItemDef(itemName)) then
			
		else
			warn("HoldToolEvent: Item Not Found: ",itemName)
		end	
	end

	if (itemName == "" or itemName == nil) then
		
		--if (slot == "One") then
		--	--if we have no item in the weapon slot then set Fists as current tool.
		--	ToolFunctions.RemoveToolFromHand(player,StatesFunctions.GetCurrentTool(player))
		--	StatesFunctions.SetCurrentTool(player,"Fists")
		--	StatesFunctions.SetCurrentToolSlotNumber(player,"Fists")
		--	CurrentHeldToolChangedEvent:FireClient(player,"Fists",slot)
		--else
		
		local currentTool = StatesFunctions.GetCurrentTool(player)
	
		ToolFunctions.RemoveToolFromHand(player,currentTool)
		StatesFunctions.SetCurrentTool(player,"")
		StatesFunctions.SetCurrentToolSlotNumber(player,"")
		CurrentHeldToolChangedEvent:FireClient(player,"",slot)
		--end
		
		--If current tool is a temp tool then remove it entirely
		if InventoryFunctions.IsTempTool(player, currentTool) then
			InventoryFunctions.RemoveTempHold(player,currentTool)
		end

	elseif (itemName == StatesFunctions.GetCurrentTool(player)) then
		if InventoryFunctions.GetItemDef(itemName).Type == "Artifact" then
			ToolFunctions.RemoveArtifact(player,itemName)
		else
			ToolFunctions.RemoveToolFromHand(player,itemName)
		end
		
		StatesFunctions.SetCurrentTool(player,"")
		StatesFunctions.SetCurrentToolSlotNumber(player,"")
		CurrentHeldToolChangedEvent:FireClient(player,"",slot)
		
		--If current tool is a temp tool then remove it entirely
		if InventoryFunctions.IsTempTool(player, itemName) then
			InventoryFunctions.RemoveTempHold(player,itemName)
		end

	elseif(InventoryFunctions.GetItemDef(itemName).Type == "Artifact") then
		
		if StatesFunctions.GetCurrentTool(player) and InventoryFunctions.GetItemDef(StatesFunctions.GetCurrentTool(player)) and InventoryFunctions.GetItemDef(StatesFunctions.GetCurrentTool(player)).Type == "Artifact" then
			ToolFunctions.RemoveArtifact(player,itemName)
		else
			ToolFunctions.RemoveToolFromHand(player,StatesFunctions.GetCurrentTool(player))
		end
		
		ToolFunctions.AddArtifact(player,itemName)
		StatesFunctions.SetCurrentTool(player,itemName)
		StatesFunctions.SetCurrentToolSlotNumber(player,slot)
		CurrentHeldToolChangedEvent:FireClient(player,itemName,slot)
		
	else
		
		if (StatesFunctions.GetInWater(player) and not InventoryFunctions.GetItemDef(itemName).Traits.UnderWaterWeapon) then
			MessagePlayerEvent:FireClient(player,"You can only equip an underwater weapon in water")
			return
		elseif (not StatesFunctions.GetInWater(player) and InventoryFunctions.GetItemDef(itemName).Traits.UnderWaterWeapon) then
			MessagePlayerEvent:FireClient(player,"You cannot equip an underwater weapon out of water")
			return
		end
		
		if (equip) then
			InventoryFunctions.EquipItem(player,itemName)
		end
		
		if ((not InventoryFunctions.HasTool(player,itemName)) and (not InventoryFunctions.HasWeaponEquipped(player,itemName))) then
			return
		end
		
		if StatesFunctions.GetCurrentTool(player) and InventoryFunctions.GetItemDef(StatesFunctions.GetCurrentTool(player)) and InventoryFunctions.GetItemDef(StatesFunctions.GetCurrentTool(player)).Type == "Artifact" then
			ToolFunctions.RemoveArtifact(player,itemName)
		else
			ToolFunctions.RemoveToolFromHand(player,StatesFunctions.GetCurrentTool(player))
		end
	
		ToolFunctions.AddToolToHand(player,itemName)
		StatesFunctions.SetCurrentTool(player,itemName)
		StatesFunctions.SetCurrentToolSlotNumber(player,slot)
		CurrentHeldToolChangedEvent:FireClient(player,itemName,slot)
		
	end
	
	
	
end)


local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "LaunchRocket")  then
		
		if (not InventoryFunctions.HasRequiredItem(player, promptObject)) then
			return
		end
		
		HandleRocketLaunch(promptObject, player)
		return
	end

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

ToolStateChangeEvent.OnServerEvent:Connect(function(player,toolName,toolState1,toolState2,toolState3,toolState4)
	if (toolName == "Spraypaint") then
		StatesFunctions.SetSpraypaintingTag(player,toolState1,toolState2,toolState3,toolState4)
	end
end)

PlaceObjectEvent.OnServerEvent:Connect(function(player,objectName)
	if (objectName == "Rocket") then
		--TODO check that they have a rocket
		SetRocket(player)
	end
end)