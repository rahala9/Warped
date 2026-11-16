local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("DeathEffectSystem"):WaitForChild("Config"))
local settings = Config.Effects.Electrocuted
local ElectricShockRenderer = require(
	script.Parent.Parent.Parent:WaitForChild("EffectVisualSystem")
		:WaitForChild("Renderers"):WaitForChild("ElectricShockRenderer")
)

local ElectrocutedProvider = {}

local function addDeathSparks(root: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "ElectrocutedDeathFX"
	attachment.Parent = root

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.fromRGB(100, 235, 255), Color3.fromRGB(240, 255, 255))
	sparks.LightEmission = 1
	sparks.Lifetime = NumberRange.new(0.15, 0.5)
	sparks.Speed = NumberRange.new(4, 12)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 0
	sparks.Parent = attachment
	sparks:Emit(55)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(120, 235, 255)
	light.Brightness = settings.LightBrightness
	light.Range = settings.LightRange
	light.Shadows = true
	light.Parent = root
	task.delay(settings.FlashDuration, function()
		if light.Parent then light.Enabled = false end
	end)
end

function ElectrocutedProvider.Render(character: Model, _payload)
	local model = Instance.new("Model")
	model.Name = character.Name .. "_ElectrocutedDeath"
	local skeleton, root, characterRoot, bonePairs = ElectricShockRenderer.CreateSkeleton(character, model)
	if not skeleton or not root or not characterRoot then
		model:Destroy()
		return nil
	end

	-- Death keeps the x-ray skeleton inside the character instead of launching
	-- it as a second ragdoll. Pose tracking includes the death/fall animation.
	local followWeld = Instance.new("WeldConstraint")
	followWeld.Name = "ElectrocutedDeathFollow"
	followWeld.Part0 = root
	followWeld.Part1 = characterRoot
	followWeld.Parent = root
	ElectricShockRenderer.TrackPose(skeleton, bonePairs)
	ElectricShockRenderer.SuppressCharacterShadows(character, model)

	for _, part in ipairs(skeleton:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		end
	end
	addDeathSparks(root)
	ElectricShockRenderer.PlayElectrocutedSound(characterRoot)
	return model
end

return ElectrocutedProvider
