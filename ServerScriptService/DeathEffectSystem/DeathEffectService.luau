local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:FindFirstChild("DeathEffectSystem")
if not sharedFolder then
	sharedFolder = Instance.new("Folder")
	sharedFolder.Name = "DeathEffectSystem"
	sharedFolder.Parent = ReplicatedStorage
end

local remote = sharedFolder:FindFirstChild("RenderDeathEffect")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RenderDeathEffect"
	remote.Parent = sharedFolder
end
assert(remote:IsA("RemoteEvent"), "RenderDeathEffect must be a RemoteEvent")

local Config = require(sharedFolder:WaitForChild("Config"))

local effectsFolder = script.Parent:WaitForChild("Effects")
local registry = {}
for _, module in ipairs(effectsFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		registry[module.Name] = require(module)
	end
end

local DeathEffectService = {}

function DeathEffectService.RenderDeath(player: Player, context): boolean
	if not Config.Enabled or typeof(context) ~= "table" then
		return false
	end

	local effectName = context.Effect
	local effect = typeof(effectName) == "string" and registry[effectName] or nil
	if not effect then
		return false
	end

	local chance = if typeof(context.Chance) == "number" then math.clamp(context.Chance, 0, 1) else 1
	if chance < 1 and math.random() > chance then
		return false
	end

	local character = player.Character
	if not character or not character.Parent then
		return false
	end

	local payload = effect.BuildPayload(player, character, context)
	if not payload then
		if Config.Debug then
			warn(("[DeathEffectSystem] %s declined the death context for %s"):format(effectName, player.Name))
		end
		return false
	end

	if Config.Debug then
		print(("[DeathEffectSystem][Server] Rendering %s for %s from %s"):format(
			effectName,
			player.Name,
			tostring(context.Source)
		))
	end
	remote:FireAllClients(effectName, character, payload)
	return true
end

return DeathEffectService
