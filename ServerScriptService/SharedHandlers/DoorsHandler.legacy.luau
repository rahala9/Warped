
local ProximityPromptService = game:GetService("ProximityPromptService")
local tweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetTimeOfDayServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDayServer")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local DoorFunctions = require(ServerScriptService.SharedFunctions.DoorFunctions)
local CollectionService = game:GetService("CollectionService")
local WorldChangeEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("WorldChangeEvent")

local TweenService = game:GetService("TweenService")

--Assets

--Modules
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local function OpenCloseDoor(promptObject,door,close)
	door:SetAttribute("opening",true)

	local hinge = door.Hinge
	local open = door:GetAttribute("open") and 1 or -1
	local side = door:GetAttribute("side")
	local opendirection = door:GetAttribute("opendirection")
	
	if (close and (open == 1)) then
		--Already closed
		door:SetAttribute("opening",false)
		return
	end
	
	local direction = side * open * opendirection

	local tweeningInformation = TweenInfo.new(

		2, -- Length
		Enum.EasingStyle.Quad, -- Easing style of the TweenInfo
		Enum.EasingDirection.InOut, -- Easing direction of the TweenInfo
		0, -- Number of times the tween will repeat   
		false, -- Should the tween repeat?
		0 -- Delay between each tween  
	)

	local rotatedCFrame = CFrame.Angles(0,math.rad(90*direction),0)

	local partProperties = {CFrame = hinge.CFrame * rotatedCFrame}			
	local Tween = tweenService:Create(hinge,tweeningInformation,partProperties)
	Tween:Play()
	Tween.Completed:wait()

	if (open == 1) then
		door:SetAttribute("open",false)
		promptObject.ActionText = "Open"
	else
		door:SetAttribute("open",true)
		promptObject.ActionText = "Close"
	end

	door:SetAttribute("opening",false)

end

local function HandleOpenDoorPrompt(player,promptObject,door)
	if (door:GetAttribute("opening")) then
		return
	end	
	
	local opentime = door:GetAttribute("opentime")
	local closedtime = door:GetAttribute("closedtime")
	local timeOfDay = nil

	if (opentime ~= nil) then
		timeOfDay = GetTimeOfDayServerEvent:Invoke()
	end
	
	if (door:GetAttribute("locked")) then
		MessagePlayerEvent:FireClient(player,"Door is locked")
		return
	end
	
	if (opentime ~= nil and not ((timeOfDay >= opentime) and (timeOfDay <= closedtime))) then
		MessagePlayerEvent:FireClient(player,"Closed. Opens at "..door:GetAttribute("opentime")..":00 am")
		return
	end	
	
	
	OpenCloseDoor(promptObject,door)
	
	
end

local function HandleSlideDoorPrompt(player,promptObject,door)
	
	if (door:GetAttribute("RequiresPower")) then
		if (not door:GetAttribute("Powered")) then
			return
		end
	end
	
	if (door:GetAttribute("opening")) then
		return
	end	

	local opentime = door:GetAttribute("opentime")
	local closedtime = door:GetAttribute("closedtime")
	local timeOfDay = nil

	if (opentime ~= nil) then
		timeOfDay = GetTimeOfDayServerEvent:Invoke()
	end

	if (door:GetAttribute("locked")) then
		MessagePlayerEvent:FireClient(player,"Door is locked")
		return
	end

	if (opentime ~= nil and not ((timeOfDay >= opentime) and (timeOfDay <= closedtime))) then
		MessagePlayerEvent:FireClient(player,"Closed. Opens at "..door:GetAttribute("opentime")..":00 am")
		return
	end	

	DoorFunctions.SlideDoor(door)
	
	if promptObject then
		if (door:GetAttribute("open") and not door:GetAttribute("AutoClose")) then
			promptObject.ActionText = "Close"
		else
			promptObject.ActionText = "Open"
		end	
	end

end


local function HandleUnlockDoorPrompt(player,promptObject,door)
	
	local locked = door:GetAttribute("locked")
	if (not locked) then
		MessagePlayerEvent:FireClient(player,"Door is not locked")
		return
	end
	
	if ((locked) and (door:GetAttribute("RequiredKey") ~= nil)) then
		if (not InventoryFunctions.HasItem(player,door:GetAttribute("RequiredKey"))) then
			MessagePlayerEvent:FireClient(player,"Requires "..door:GetAttribute("RequiredKey"),door:GetAttribute("RequiredKey"))
			return	
		else
			promptObject.ActionText = "Lock"
			promptObject.Name = "LockDoor"
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	else
		MessagePlayerEvent:FireClient(player,"Door has no known key")
	end	
	
end

local function HandleLockDoorPrompt(player,promptObject,door)

	local locked = door:GetAttribute("locked")
	if (locked) then
		MessagePlayerEvent:FireClient(player,"Door is locked")
		return
	end

	if ((not locked) and (door:GetAttribute("RequiredKey") ~= nil)) then
		if (not InventoryFunctions.HasItem(player,door:GetAttribute("RequiredKey"))) then
			MessagePlayerEvent:FireClient(player,"Requires "..door:GetAttribute("RequiredKey"),door:GetAttribute("RequiredKey"))
			return	
		else
			promptObject.ActionText = "Unlock"
			promptObject.Name = "UnlockDoor"
			door:SetAttribute("locked",true)
			MessagePlayerEvent:FireClient(player,"Door locked")
		end
	else
		MessagePlayerEvent:FireClient(player,"Door has no known key")
	end	

end

local function HandlePickDoorLockPrompt(player,promptObject,door)
	local locked = door:GetAttribute("locked")
	if (not locked) then
		MessagePlayerEvent:FireClient(player,"Door is not locked")
		return
	end

	local lockLevel = door:GetAttribute("lockLevel")

	if (lockLevel == 1) then
		if (not InventoryFunctions.HasItem(player,"LockpickL1")) then
			MessagePlayerEvent:FireClient(player,"Requires LockpickL1 or equivalent","LockpickL1")
			return	
		else
			InventoryFunctions.RemoveItem(player,"LockpickL1",1)
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	elseif (lockLevel == 2) then
		if (not InventoryFunctions.HasItem(player,"LockpickL2")) then
			MessagePlayerEvent:FireClient(player,"Requires LockpickL2 or equivalent","LockpickL2")
			return	
		else
			InventoryFunctions.RemoveItem(player,"LockpickL2",1)
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	elseif (lockLevel == 3) then
		if (not InventoryFunctions.HasItem(player,"LockpickL3")) then
			MessagePlayerEvent:FireClient(player,"Requires LockpickL3 or equivalent","LockpickL3")
			return	
		else
			InventoryFunctions.RemoveItem(player,"LockpickL1",3)
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	elseif (lockLevel == 4) then
		if (not InventoryFunctions.HasItem(player,"LockpickL4")) then
			MessagePlayerEvent:FireClient(player,"Requires LockpickL4 or equivalent","LockpickL4")
			return	
		else
			InventoryFunctions.RemoveItem(player,"LockpickL4",1)
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	elseif (lockLevel == 5) then
		if (not InventoryFunctions.HasItem(player,"LockpickL5")) then
			MessagePlayerEvent:FireClient(player,"Requires LockpickL5 or equivalent","LockpickL5")
			return	
		else
			InventoryFunctions.RemoveItem(player,"LockpickL5",1)
			door:SetAttribute("locked",false)
			MessagePlayerEvent:FireClient(player,"Door unlocked")
		end
	else
		MessagePlayerEvent:FireClient(player,"Door lock cannot be picked")
	end



end

function Teleport(player,freeze, destination)


	local character = player.Character
	local humanoid = character.Humanoid

	-- Freeze character during teleport if requested
	if freeze then
		humanoid:SetAttribute("DefaultWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("DefaultJumpPower", humanoid.JumpPower)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Calculate height of root part from character base
	local rootPartY
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.HipHeight
	else
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.Parent.LeftLeg.Size.Y + humanoid.HipHeight
	end

	-- Teleport player and request content around location if applicable
	local position = CFrame.new(destination + Vector3.new(0, rootPartY, 0))
	--local orientation = CFrame.Angles(0, math.rad(params.faceAngle), 0)

	character:SetPrimaryPartCFrame(position) -- * orientation)

	-- Unfreeze character
	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

local function HandleOpenSplashSpirePrompt(player,promptObject)
	
	local requiredKey = promptObject:GetAttribute("RequiredItem")
	
	if (requiredKey ~= nil) then
		if (not InventoryFunctions.HasItem(player,requiredKey)) then
			MessagePlayerEvent:FireClient(player,"Requires "..requiredKey,requiredKey)
			return	
		else
			Teleport(player,true, Vector3.new(-504.168, 200, -3095.065))
		end
	end	

end

local function HandleBASHPrompt(player,promptObject,door)
	local locked = door:GetAttribute("locked")
	if (not locked) then
		MessagePlayerEvent:FireClient(player,"Door is not locked")
		return
	end
	
	local lockLevel = door:GetAttribute("lockLevel")
	
	if (lockLevel == 1) then

		door:SetAttribute("locked",false)
		MessagePlayerEvent:FireClient(player,"Door unlocked")
		
	elseif (lockLevel == 2) then
	
		door:SetAttribute("locked",false)
		MessagePlayerEvent:FireClient(player,"Door unlocked")

	else
		MessagePlayerEvent:FireClient(player,"Door lock cannot be broken")
	end
	
	
	
end

local debounce = false

local function onPromptTriggered(promptObject, player)
	
	if (debounce) then
		return
	else
		debounce = true
	end
	
	if (promptObject.Name == "OpenDoor") then
		HandleOpenDoorPrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "UnlockDoor") then
		HandleUnlockDoorPrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "LockDoor") then
		HandleLockDoorPrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "PickDoorLock") then
		HandlePickDoorLockPrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "BASH") then
		HandleBASHPrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "OpenSplashSpire") then
		HandleOpenSplashSpirePrompt(player,promptObject,promptObject.Parent)
	elseif (promptObject.Name == "SlideOpenDoor") then
		HandleSlideDoorPrompt(player,promptObject,promptObject.Parent.Parent)
	end
	
	debounce = false
	
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)


WorldChangeEvent.Event:Connect(function(season,day,partOfDay)

	for i,managedDoor in pairs(CollectionService:GetTagged("ManagedDoor")) do
		local opentime = managedDoor:GetAttribute("opentime")
		local closedtime = managedDoor:GetAttribute("closedtime")

		if (opentime ~= nil and not ((partOfDay >= opentime) and (partOfDay <= closedtime))) then

			OpenCloseDoor(managedDoor.OpenDoor,managedDoor,true) --force close if open
			managedDoor:SetAttribute("locked",true)
			return
		else
			managedDoor:SetAttribute("locked",false)
		end	

		

	end

end)

Zones:OnLoaded("Door1", function(zone)
	
	local door = zone.Folder.Parent
	
	zone:OnPlayerEntered(function(player)
		HandleSlideDoorPrompt(player,nil,door)
	end)
end)

Zones:OnLoaded("Door2", function(zone)

	local door = zone.Folder.Parent

	zone:OnPlayerEntered(function(player)
		HandleSlideDoorPrompt(player,nil,door)
	end)
end)

Zones:OnLoaded("Door3", function(zone)

	local door = zone.Folder.Parent

	zone:OnPlayerEntered(function(player)
		HandleSlideDoorPrompt(player,nil,door)
	end)
end)

Zones:OnLoaded("Door4", function(zone)

	local door = zone.Folder.Parent

	zone:OnPlayerEntered(function(player)
		HandleSlideDoorPrompt(player,nil,door)
	end)
end)

