-- Replicator.client.lua (LocalScript in StarterPlayerScripts or similar)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Remote   = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local player   = Players.LocalPlayer
local SharedFX = ReplicatedStorage:WaitForChild("SharedFX")

Remote.OnClientEvent:Connect(function(Input, ...)
	-- Input is either "EffectName" or { "EffectName", "MethodName" }
	local Evaluation = (type(Input) == "string") and Input or Input[1]

	for _, ModuleObj in ipairs(SharedFX:GetDescendants()) do
		if ModuleObj:IsA("ModuleScript") and ModuleObj.Name == Evaluation then
			local EffectModule = require(ModuleObj)

			if typeof(EffectModule) == "table" then
				-- pattern: { "BottleRocket", "Projectile" }, then call EffectModule.Projectile(player, ...)
				local methodName = Input[2]
				local func = EffectModule[methodName]
				if type(func) == "function" then
					func(player, ...)
				else
					warn("Replicator: No function", methodName, "on module", Evaluation)
				end

			elseif typeof(EffectModule) == "function" then
				-- pattern: "SomeEffect", then call the module as a function
				EffectModule(player, ...)
			else
				warn("Replicator: Module", Evaluation, "returned", typeof(EffectModule))
			end
		end
	end
end)
