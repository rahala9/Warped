-- ServerScriptService.Systems.ScannerEffects
local ScannerEffects = {}

function ScannerEffects.LockDoor(scannerModel)
	local door = scannerModel:FindFirstChild("ScannerDoor")
	if door then
		door:SetAttribute("Locked", true)
	end
end

function ScannerEffects.LockAllDoors(scannerModel)
	-- Find all doors in vicinity and lock them
	local nearbyDoors = {}
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj.Name:match("Door") and obj:IsA("Model") then
			local dist = (obj:GetPivot().Position - scannerModel:GetPivot().Position).Magnitude
			if dist < 50 then -- Within 50 studs
				obj:SetAttribute("Locked", true)
			end
		end
	end
end

function ScannerEffects.AlertGuards(scannerModel)
	print("Alerting guards near", scannerModel:GetFullName())
	-- Spawn or activate guard NPCs
end

function ScannerEffects.SpawnGuards(scannerModel)
	print("Spawning guards at", scannerModel:GetFullName())
	-- Your guard spawning logic
end

function ScannerEffects.EnableAlarm(scannerModel)
	local alarm = scannerModel:FindFirstChild("Alarm")
	if alarm then
		alarm:SetAttribute("Active", true)
	end
end

function ScannerEffects.LogIncident(scannerModel)
	print("Logging security incident at", scannerModel:GetFullName())
	-- Log to your analytics/security system
end

function ScannerEffects.AlertSecurity(scannerModel)
	print("Security alert triggered at", scannerModel:GetFullName())
	-- Your security alert system
end

return ScannerEffects