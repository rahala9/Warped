local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateClientObjectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateClientObject")	

function GetObject(fullName)
	local segments = fullName:split(".")
	local current = game

	for _,location in pairs(segments) do
		current = current[location]
	end

	return current
end

UpdateClientObjectEvent.OnClientEvent:Connect(function(clientObjectFullPath,props)
	
	
	local instance = GetObject(clientObjectFullPath)
		
	if instance then
		
		if (instance:IsA("Folder")) then
			for _, childInstance in pairs(instance:GetChildren()) do
				if (childInstance:IsA("BasePart") or childInstance:IsA("MeshPart")) then
					for propName, propValue in pairs(props) do
						
						if (childInstance[propName] ~= nil) then
							childInstance[propName] = propValue
						end
						
					end
				end
			end
		else
			--Set properties
			for propName, propValue in pairs(props) do
				local prop = instance:FindFirstChild(propName)

				if (instance[propName] ~= nil) then
					instance[propName] = propValue
				end
				
			end
		end
		
	else
		warn("Could not find instance with full name " .. clientObjectFullPath)
	end
	
	
end)








