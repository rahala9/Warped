local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local UpdateAttributesEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateAttributes")

local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)



UpdateAttributesEvent.OnServerEvent:Connect(function(player,attributes)
	
	AttributesFunctions.UpdateAttributesFromClient(player,attributes)

end)

