local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local PlayerHitEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	

local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage


Zones:OnLoaded("KillZone", function(zone)
	local connection
	connection = zone:OnPlayerEntered(function(enteredPlayer,zonePart)
		print("Player:",enteredPlayer," entered a kill zone. zonePart:",zonePart.Name )	
		PlayerHitEvent:Fire(enteredPlayer,9999999999)
	end)

	
end)

Zones:OnLoaded("KillZoneLaserTrap1", function(zone)
	local connection
	connection = zone:OnPlayerEntered(function(enteredPlayer,zonePart)
		if (zonePart.Parent.Parent:GetAttribute("Enabled")) then
			print("Player:",enteredPlayer," entered a kill zone. zonePart:",zonePart.Name )	
			PlayerHitEvent:Fire(enteredPlayer,9999999999)
		end
	end)


end)

Zones:OnLoaded("KillZoneLaserDoor1", function(zone)
	local connection
	connection = zone:OnPlayerEntered(function(enteredPlayer,zonePart)
		if (zonePart.Parent.Parent:GetAttribute("Enabled")) then
			print("Player:",enteredPlayer," entered a kill zone. zonePart:",zonePart.Name )	
			PlayerHitEvent:Fire(enteredPlayer,9999999999)
		end
	end)


end)