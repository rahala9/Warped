local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("EffectVisualSystem")
local Config = require(sharedFolder:WaitForChild("Config"))
local remote = sharedFolder:WaitForChild("RenderEffectVisual")
local renderersFolder = script.Parent:WaitForChild("Renderers")

local runtimeFolder = workspace:FindFirstChild(Config.RuntimeFolderName)
if not runtimeFolder then
	runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = Config.RuntimeFolderName
	runtimeFolder.Parent = workspace
end

remote.OnClientEvent:Connect(function(action, effectName, character, payload)
	if typeof(action) ~= "string" or typeof(effectName) ~= "string"
		or not character or not character:IsA("Model") then
		return
	end
	local module = renderersFolder:FindFirstChild(effectName .. "Renderer")
	if not module or not module:IsA("ModuleScript") then
		warn("[EffectVisualSystem] Missing renderer", effectName)
		return
	end
	local renderer = require(module)
	if action == "Start" then
		renderer.Start(character, runtimeFolder, payload or {})
	elseif action == "Stop" then
		renderer.Stop(character)
	end
end)

if Config.Debug then
	print("[EffectVisualSystem][Client] Controller started")
end
