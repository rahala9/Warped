local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("DeathEffectSystem")
local Config = require(sharedFolder:WaitForChild("Config"))
local remote = sharedFolder:WaitForChild("RenderDeathEffect")
local providersFolder = script.Parent:WaitForChild("Providers")
local ElectricShockRenderer = require(
	script.Parent.Parent:WaitForChild("EffectVisualSystem")
		:WaitForChild("Renderers"):WaitForChild("ElectricShockRenderer")
)

local runtimeFolder = workspace:FindFirstChild(Config.RuntimeFolderName)
if not runtimeFolder then
	runtimeFolder = Instance.new("Folder")
	runtimeFolder.Name = Config.RuntimeFolderName
	runtimeFolder.Parent = workspace
end

local activeEffects = {}

local function hideCharacter(character: Model)
	local original = {}
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			original[descendant] = {
				property = "LocalTransparencyModifier",
				value = descendant.LocalTransparencyModifier,
			}
			descendant.LocalTransparencyModifier = 1
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			original[descendant] = {
				property = "Transparency",
				value = descendant.Transparency,
			}
			descendant.Transparency = 1
		end
	end
	return original
end

local function restoreCharacter(original)
	for instance, appearance in pairs(original) do
		if instance.Parent then
			instance[appearance.property] = appearance.value
		end
	end
end

local function clearActive(character: Model, destroyEffect: boolean)
	local active = activeEffects[character]
	if not active then
		return
	end
	restoreCharacter(active.original)
	if destroyEffect and active.effect and active.effect.Parent then
		active.effect:Destroy()
	end
	if active.deadConnection then
		active.deadConnection:Disconnect()
	end
	if active.destroyingConnection then
		active.destroyingConnection:Disconnect()
	end
	activeEffects[character] = nil
end

remote.OnClientEvent:Connect(function(effectName, character, payload)
	if not Config.Enabled
		or typeof(effectName) ~= "string"
		or not character
		or not character:IsA("Model")
		or typeof(payload) ~= "table"
	then
		return
	end

	local providerModule = providersFolder:FindFirstChild(effectName .. "Provider")
	if not providerModule or not providerModule:IsA("ModuleScript") then
		warn("[DeathEffectSystem] Missing client provider", effectName .. "Provider")
		return
	end

	-- A death presentation owns character visibility from this point forward.
	-- Stop any living electric flicker first so it cannot restore the body over
	-- the death effect on its next frame.
	ElectricShockRenderer.Stop(character)
	clearActive(character, true)
	local effectSettings = Config.Effects[effectName]
	local shouldHideCharacter = not effectSettings or effectSettings.HideCharacter ~= false
	local original = if shouldHideCharacter then hideCharacter(character) else {}
	local ok, effect = pcall(function()
		local provider = require(providerModule)
		return provider.Render(character, payload)
	end)
	if not ok or not effect or not effect:IsA("Model") then
		restoreCharacter(original)
		warn("[DeathEffectSystem] Provider failed", effectName, effect)
		return
	end
	effect.Parent = runtimeFolder

	local active = {
		effect = effect,
		original = original,
	}
	activeEffects[character] = active
	active.deadConnection = character:GetAttributeChangedSignal("Dead"):Connect(function()
		if character:GetAttribute("Dead") ~= true then
			-- Respawn/revival ends the presentation immediately. Restoring only the
			-- character here used to leave the effect model until its full lifetime.
			clearActive(character, true)
		end
	end)
	active.destroyingConnection = character.Destroying:Connect(function()
		clearActive(character, true)
	end)

	local lifetime = if effectSettings and typeof(effectSettings.Lifetime) == "number"
		then effectSettings.Lifetime
		else 15
	task.delay(lifetime, function()
		local current = activeEffects[character]
		if current == active then
			clearActive(character, true)
		elseif effect.Parent then
			effect:Destroy()
		end
	end)

	if Config.Debug then
		print(("[DeathEffectSystem][Client] Rendered %s for %s"):format(effectName, character.Name))
	end
end)

if Config.Debug then
	print("[DeathEffectSystem][Client] Controller started")
end
