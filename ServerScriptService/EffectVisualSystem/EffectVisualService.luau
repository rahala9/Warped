local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("EffectVisualSystem")
local remote = sharedFolder:FindFirstChild("RenderEffectVisual")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "RenderEffectVisual"
	remote.Parent = sharedFolder
end

local EffectVisualService = {}

function EffectVisualService.Start(player: Player, effectName: string, payload)
	local character = player and player.Character
	if not character or not character.Parent then return false end
	remote:FireAllClients("Start", effectName, character, payload or {})
	return true
end

function EffectVisualService.Stop(player: Player, effectName: string)
	local character = player and player.Character
	if not character then return false end
	remote:FireAllClients("Stop", effectName, character, {})
	return true
end

return EffectVisualService
