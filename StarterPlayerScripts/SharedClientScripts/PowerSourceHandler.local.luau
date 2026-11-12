local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PowerSourcesChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PowerSourcesChanged")

function round10(num)
	return math.floor(num / 10 + 0.5) * 10
end

function AdjustPowerBar(powerSource)
	
	local power = tonumber(powerSource:GetAttribute("Power"))
	local maxPower = tonumber(powerSource:GetAttribute("MaxPower"))
	local powerSourceBillboard = powerSource.PowerSourceBillboard
	local powerBar = powerSourceBillboard.PowerSource.PowerSource.Power
	
	local powerPercent = math.round((power/maxPower)*100)
	
	--Logger.Debug("TEST POWERSOURCE powerPercent:",powerPercent)
	
	--TODO more efficient way?
	for i=100,10,-10 do	
		if (powerBar[i]) then
			powerBar[i].Visible = true
		end
	end
	
	--remove from view all power bar segments that are greater than current power		
	for i=100,10,-10 do
		if (i>round10(powerPercent)) then
			if (i == 10 and powerPercent > 0) then
				continue
			end
			if (powerBar[i]) then
				powerBar[i].Visible = false
			end
		end
	end
end

PowerSourcesChangedEvent.OnClientEvent:Connect(function(targetPowerSource)
	
	if (targetPowerSource == "ALL") then
		for i,powerSource in pairs(CollectionService:GetTagged("PowerSource")) do

			AdjustPowerBar(powerSource)

		end
	else
		for i,powerSource in pairs(CollectionService:GetTagged("PowerSource")) do
			
			if (powerSource:GetAttribute("PowerSourceID") ~= targetPowerSource) then
				continue
			end
			
			AdjustPowerBar(powerSource)
			
		end
		
	end
	
end)
