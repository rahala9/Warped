--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Remote Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local LedgeEvent = Remotes:WaitForChild("Ledge")

--Functions
local PlayerMovementFunctions = require(ServerScriptService.SharedFunctions.PlayerMovementFunctions)

--Definition Modules

--Assets

--Modules

--Gui

--Context and Actions

--Initialization

LedgeEvent.OnServerEvent:Connect(function(player,action,ledgeData,ledgeCfg)
	
	if (not PlayerMovementFunctions.LedgeActions[action]) then
		return
	end
	
	local char = player.Character
	if not char then return end

	if (action == PlayerMovementFunctions.LedgeActions["Hang"]) then
		PlayerMovementFunctions.Hang(char,ledgeData,ledgeCfg)
	elseif (action == PlayerMovementFunctions.LedgeActions["Climb"]) then
		PlayerMovementFunctions.Climb(player,char,ledgeData,ledgeCfg)
	elseif (action == PlayerMovementFunctions.LedgeActions["Drop"]) then
		PlayerMovementFunctions.Drop(char)

	end
	
end)

