local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetTimeOfDayServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetTimeOfDayServer")
local ProximityPromptService = game:GetService("ProximityPromptService")
local lights = workspace.Lights

local RunService = game:GetService('RunService')

local amountOfTimePassed = 0
local processing = false
local currentTimeOfDay = 0

local function SwitchLight(light,turnOn)
	
	print("TEST LIGHT 3 light:",light," turnOn:",turnOn)
	
	light:SetAttribute("isOn",turnOn)
	
	if (light.lights.A ~= nil) then
		light.lights.A.Enabled = turnOn
	end
	
	if (light:GetAttribute("VisibleSource")) then
		if (turnOn) then
			light.lights.Material = Enum.Material.Neon
		else
			light.lights.Material = Enum.Material.Plastic
		end
		
	end
	
	if (light:FindFirstChild("sign") ~= nil) then
		if (turnOn) then
			light.sign.Material = Enum.Material.Neon
		else
			light.sign.Material = Enum.Material.Plastic
		end
	end
	
end

local function Flicker(light)
	light.lights.Transparency = 1
	light.lights.A.Enabled = false
	wait(0.1)
	light.lights.Transparency = 0
	light.lights.A.Enabled = true
	wait(0.4)
	light.lights.Transparency = 1
	light.lights.A.Enabled = false
	wait(0.789)
	light.lights.Transparency = 0
	light.lights.A.Enabled = true
	wait(0.29)
	light.lights.Transparency = 1
	light.lights.A.Enabled = false
	wait(0.025)
	light.lights.Transparency = 0
	light.lights.A.Enabled = true
	
	wait(5)
	light:SetAttribute("flicker",true)
end

RunService.Heartbeat:Connect(function(step)
	
	if (processing) then
		return
	end
	
	amountOfTimePassed+= step

	if (amountOfTimePassed > 5) then --TODO change to 60 seconds
		processing = true
		amountOfTimePassed = 0
		currentTimeOfDay = GetTimeOfDayServerEvent:Invoke()
		
		for _, light in ipairs(workspace.Lights:GetChildren()) do
			
			print("TEST LIGHT 1:",light)
			
			if (light:GetAttribute("TimeOn") == nil) then
				continue
			end
			
			local lightTimeOn = light:GetAttribute("TimeOn")
			local lightTimeOff = light:GetAttribute("TimeOff")
			local lightIsOn =  light:GetAttribute("isOn")
			
			print("TEST LIGHT 2:",light," lightTimeOn:",lightTimeOn," lightTimeOff:",lightTimeOff," currentTimeOfDay:",currentTimeOfDay)
			
			if (lightTimeOn < lightTimeOff) then
				if (currentTimeOfDay >= lightTimeOn) and (currentTimeOfDay < lightTimeOff) then
					--turn on if not already on
					if (not lightIsOn) then
						SwitchLight(light,true)
					end
				else
					if (lightIsOn) then
						SwitchLight(light,false)
					end
				end
			else
				if ((currentTimeOfDay >= lightTimeOn) and (currentTimeOfDay <= 24)) or ((currentTimeOfDay > 0) and (currentTimeOfDay < lightTimeOff)) then
					--turn on if not already on
					if (not lightIsOn) then
						SwitchLight(light,true)
					end
				else
					if (lightIsOn) then
						SwitchLight(light,false)
					end
				end
			end
			
			if (lightIsOn and light:GetAttribute("flicker")) then
				light:SetAttribute("flicker",false)
				spawn(function()
					Flicker(light)
					local lightIsOn =  light:GetAttribute("isOn")
					SwitchLight(light,lightIsOn)
				end)
			end
			
			
		end
		
		processing = false
	end

end)

local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "Lightswitch") then
		
		local light = lights:WaitForChild(promptObject:GetAttribute("Light"))
		
		if (not light:GetAttribute("isOn")) then
			SwitchLight(light,true)
			promptObject.ActionText = "Turn Off"
		else
			SwitchLight(light,false)
			promptObject.ActionText = "Turn On"
		end
	end

end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)