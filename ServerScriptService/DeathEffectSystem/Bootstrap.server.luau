local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the network contract before loading any effect implementation. This
-- keeps the client from waiting forever if an unrelated server module yields
-- or an individual effect provider fails while the server is starting.
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
elseif not remote:IsA("RemoteEvent") then
	error("ReplicatedStorage.DeathEffectSystem.RenderDeathEffect must be a RemoteEvent")
end

local ok, result = pcall(require, script.Parent:WaitForChild("DeathEffectService"))
if not ok then
	warn("[DeathEffectSystem] Server initialization failed:", result)
end
