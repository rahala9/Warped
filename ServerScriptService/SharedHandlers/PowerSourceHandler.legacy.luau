local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local CollectionService = game:GetService("CollectionService")
local PowerSourcesChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PowerSourcesChanged")
local PowerSourceFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").PowerSourceFunctions)
local ProximityPromptService = game:GetService("ProximityPromptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)

local timeChangeInterval = 10
local step_counter = 0 

local profileLoaded = false

ProfileLoadedEvent.Event:Connect(function (player)
	profileLoaded = true
end)

ProximityPromptService.PromptTriggered:Connect(function(promptObject, player)
	if (promptObject.Name == "RefillGenerator") then
		local model = promptObject.Parent.Parent
		if (model.Name == "Generator") then
			
			if (InventoryFunctions.HasRequiredItem(player, promptObject)) then
				local powerSource = model.PrimaryPart:FindFirstChild("ElectricNode")

				if (powerSource) then
					PowerSourceFunctions.SetPower(powerSource,powerSource:GetAttribute("MaxPower"))
					
					--May need to check if drawing power . ie connected to anything
					PowerSourceFunctions.TurnPowerOn(powerSource)
				end
				
				local requiredItem = promptObject:GetAttribute("RequiredItem")
				local requiredItemAmount = promptObject:GetAttribute("RequiredItemAmount")
				InventoryFunctions.RemoveItem(player,requiredItem,requiredItemAmount)
			end
			
			
		end
	elseif (promptObject.Name == "RechargeBattery") then
		local model = promptObject.Parent.Parent
		if (model.Name == "CarBattery") then
			
			if (InventoryFunctions.HasRequiredItem(player, promptObject)) then
				local powerSource = model.PrimaryPart:FindFirstChild("ElectricNode")

				if (powerSource) then
					PowerSourceFunctions.SetPower(powerSource,powerSource:GetAttribute("MaxPower"))
					
					--May need to check if drawing power . ie connected to anything
					PowerSourceFunctions.TurnPowerOn(powerSource)
				end
				
				
			end
			
		end
	elseif (promptObject.Name == "TurnPowerOn") then
		
		local model = promptObject.Parent.Parent
		local powerSource = model.PrimaryPart:FindFirstChild("ElectricNode")

		if (powerSource and powerSource:GetAttribute("PowerSource")) then

			if (PowerSourceFunctions.HasPower(player,powerSource)) then
				
					--May need to check if drawing power . ie connected to anything
				PowerSourceFunctions.TurnPowerOn(powerSource)
				
				promptObject.Name = "TurnPowerOff"
				promptObject.ActionText = "Turn Power Off"
				
			end

		end
	elseif (promptObject.Name == "TurnPowerOff") then

		local model = promptObject.Parent.Parent
		local powerSource = model.PrimaryPart:FindFirstChild("ElectricNode")

		if (powerSource and powerSource:GetAttribute("PowerSource")) then

	
			--May need to check if drawing power . ie connected to anything
			PowerSourceFunctions.TurnPowerOff(powerSource)

			promptObject.Name = "TurnPowerOn"
			promptObject.ActionText = "Turn Power On"

		end
	else
		return
	end
end)

RunService.Heartbeat:Connect(function(step)
	--debug.profilebegin("PowerSourceHandler Heartbeat")
	if (not profileLoaded) then
		return
	end
		
	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval --TODO shouldn't this fully reset to zero?
				
		for i,powerSource in pairs(CollectionService:GetTagged("PowerSource")) do
			
			local powerOn = powerSource:GetAttribute("PowerOn")
			if (not powerOn) then
				continue
			end
			
			
			
			local power = tonumber(powerSource:GetAttribute("Power"))
			local startPower = tonumber(powerSource:GetAttribute("StartPower"))
			
			if (power > 0) then
				local startTime = tonumber(powerSource:GetAttribute("StartTime"))
				local timeElapsed = os.time() - startTime
				local newPower = startPower - timeElapsed
				
				--Logger.Debug("TEST POWERSOURCE newpower:",newPower)
				
				if (newPower <= 0) then
					PowerSourceFunctions.SetPower(powerSource,0)
					
					PowerSourceFunctions.TurnPowerOff(powerSource)
					
				else
					PowerSourceFunctions.SetPower(powerSource,newPower)
				end
				
				
			end
			
			
		end
		
		PowerSourcesChangedEvent:FireAllClients("ALL")
		
		
	end
	
	--debug.profileend()
end)

