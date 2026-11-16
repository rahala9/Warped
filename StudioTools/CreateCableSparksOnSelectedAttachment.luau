-- Warped: create an intermittent electrical cable-spark effect.
--
-- Usage:
--   1. In Roblox Studio Edit mode, select one or more Attachments.
--   2. Open View > Command Bar.
--   3. Paste and run this script.
--
-- The generated Script controls intermittent bursts at runtime. Hazard-zone
-- authoring intentionally lives in a separate utility so it cannot alter this
-- working visual effect.

local Selection = game:GetService("Selection")

local EFFECT_NAMES = {
	CableElectricSparks = true,
	CableElectricGlow = true,
	CableElectricLight = true,
	CableElectricSparkSound = true,
	CableElectricSpark2 = true,
	CableElectricSpark3 = true,
	CableElectricSpark4 = true,
	CableElectricSpark5 = true,
	CableElectricSpark6 = true,
	CableElectricSpark7 = true,
	CableElectricSpark8 = true,
	CableElectricController = true,
}

local CONTROLLER_SOURCE = [==[
local attachment = script.Parent
local sparks = attachment:WaitForChild("CableElectricSparks")
local glow = attachment:WaitForChild("CableElectricGlow")
local light = attachment:WaitForChild("CableElectricLight")
local random = Random.new()
local sparkSounds = {
	attachment:WaitForChild("CableElectricSpark3"),
	attachment:WaitForChild("CableElectricSpark4"),
	attachment:WaitForChild("CableElectricSpark5"),
	attachment:WaitForChild("CableElectricSpark6"),
	attachment:WaitForChild("CableElectricSpark7"),
	attachment:WaitForChild("CableElectricSpark8"),
}

local function playSparkSound()
	for _, sound in ipairs(sparkSounds) do
		sound:Stop()
	end
	sparkSounds[random:NextInteger(1, #sparkSounds)]:Play()
end

local MINIMUM_PAUSE = 0.12
local MAXIMUM_PAUSE = 1.15
local MINIMUM_SPARKS = 6
local MAXIMUM_SPARKS = 16

light.Enabled = false

while attachment:IsDescendantOf(workspace) do
	task.wait(random:NextNumber(MINIMUM_PAUSE, MAXIMUM_PAUSE))
	if not attachment:IsDescendantOf(workspace) then
		break
	end

	local burstCount = random:NextInteger(MINIMUM_SPARKS, MAXIMUM_SPARKS)
	sparks:Emit(burstCount)
	glow:Emit(math.max(1, math.floor(burstCount * 0.35)))
	playSparkSound()

	light.Brightness = random:NextNumber(3, 5)
	light.Enabled = true
	task.wait(random:NextNumber(0.025, 0.075))
	light.Enabled = false

	-- Occasional quick second snap makes the fault feel irregular.
	if random:NextNumber() < 0.28 then
		task.wait(random:NextNumber(0.035, 0.12))
		sparks:Emit(random:NextInteger(4, 8))
		playSparkSound()
		light.Brightness = random:NextNumber(2, 4)
		light.Enabled = true
		task.wait(random:NextNumber(0.02, 0.05))
		light.Enabled = false
	end
end
]==]

local function removePreviousEffect(attachment)
	for _, child in ipairs(attachment:GetChildren()) do
		if EFFECT_NAMES[child.Name] then
			child:Destroy()
		end
	end
end

local function createSparks(attachment)
	local electricSounds = game:GetService("ReplicatedStorage")
		:WaitForChild("SharedClientAssets")
		:WaitForChild("Sounds")
		:WaitForChild("Electric")
	local sparkSoundSources = {}
	for index = 3, 8 do
		local source = electricSounds:WaitForChild("Spark" .. tostring(index))
		assert(source:IsA("Sound"), ("SharedClientAssets.Sounds.Electric.Spark%d must be a Sound"):format(index))
		table.insert(sparkSoundSources, source)
	end

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "CableElectricSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 252, 255)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(66, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(32, 100, 255)),
	})
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Lifetime = NumberRange.new(0.1, 0.34)
	sparks.Speed = NumberRange.new(7, 16)
	sparks.Acceleration = Vector3.new(0, -18, 0)
	sparks.Drag = 1.5
	sparks.SpreadAngle = Vector2.new(65, 65)
	sparks.EmissionDirection = Enum.NormalId.Front
	sparks.Rotation = NumberRange.new(0, 360)
	sparks.RotSpeed = NumberRange.new(-220, 220)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.35, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Rate = 0
	sparks.Enabled = true
	sparks.LockedToPart = false
	sparks.ZOffset = 0.2
	sparks.Parent = attachment

	local glow = Instance.new("ParticleEmitter")
	glow.Name = "CableElectricGlow"
	glow.Texture = "rbxasset://textures/particles/smoke_main.dds"
	glow.Color = ColorSequence.new(Color3.fromRGB(72, 214, 255))
	glow.LightEmission = 1
	glow.LightInfluence = 0
	glow.Lifetime = NumberRange.new(0.06, 0.14)
	glow.Speed = NumberRange.new(0, 0.4)
	glow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.35, 1),
		NumberSequenceKeypoint.new(1, 0.25),
	})
	glow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	glow.Rate = 0
	glow.Enabled = true
	glow.LockedToPart = true
	glow.Parent = attachment

	local light = Instance.new("PointLight")
	light.Name = "CableElectricLight"
	light.Color = Color3.fromRGB(75, 215, 255)
	light.Brightness = 4
	light.Range = 12
	light.Shadows = true
	light.Enabled = false
	light.Parent = attachment

	for index, source in ipairs(sparkSoundSources) do
		local sparkSound = source:Clone()
		sparkSound.Name = "CableElectricSpark" .. tostring(index + 2)
		sparkSound.Looped = false
		sparkSound.Playing = false
		sparkSound.RollOffMode = Enum.RollOffMode.InverseTapered
		sparkSound.RollOffMinDistance = 7
		sparkSound.RollOffMaxDistance = 55
		sparkSound.Parent = attachment
	end

	local controller = Instance.new("Script")
	controller.Name = "CableElectricController"
	controller.Source = CONTROLLER_SOURCE
	controller.Parent = attachment
end

local selectedAttachments = {}
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Attachment") then
		table.insert(selectedAttachments, selected)
	end
end

assert(#selectedAttachments > 0, "Select at least one Attachment before running this script")

for _, attachment in ipairs(selectedAttachments) do
	removePreviousEffect(attachment)
	createSparks(attachment)
	print(("[CableSparks] Created effect under %s"):format(attachment:GetFullName()))
end

print(("[CableSparks] Complete: %d attachment(s)"):format(#selectedAttachments))
