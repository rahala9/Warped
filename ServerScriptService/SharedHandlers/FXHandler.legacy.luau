-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")

-- Assets
local FXEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FX")

local Replicator =  ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")

FXEvent.OnServerEvent:Connect(function( Player, Input: string, ... )
	local Data = { ... }
	local Module = ServerScriptService:WaitForChild("SharedFX"):FindFirstChild(Input)

	if Module then
		require(Module)(Player, Data)
	else
		Replicator:FireAllClients(Input, ...)
	end
end)