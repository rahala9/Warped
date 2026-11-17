-- Warped: create a self-contained swirling black-hole effect on selected
-- Attachments (or at the center of selected BaseParts).
--
-- Run in Studio Edit mode from View > Command Bar. Rerunning replaces only a
-- previous BlackHoleEffect beneath the same origin Attachment.

local Selection = game:GetService("Selection")

local SCRIPT_VERSION = "gas-vortex-4"
local EFFECT_SCALE = 0.8
local ROTATION_SPEED = 1
local INTENSITY = 1

local RING_SEGMENTS = 14
local INWARD_EMITTERS = 8
local GAS_EMITTERS_PER_LAYER = 7

local CONTROLLER_SOURCE = [==[
local RunService = game:GetService("RunService")

local effect = script.Parent
local core = effect:WaitForChild("EventHorizon")
local rotationSpeed = effect:GetAttribute("RotationSpeed") or 1

local ringAttachments = {}
local streamAttachments = {}
for _, child in ipairs(core:GetChildren()) do
	if child:IsA("Attachment") then
		local orbitKind = child:GetAttribute("OrbitKind")
		if orbitKind == "Ring" then
			table.insert(ringAttachments, child)
		elseif orbitKind == "Stream" then
			table.insert(streamAttachments, child)
		end
	end
end

local function orbitPosition(attachment: Attachment, time: number): Vector3
	local radius = attachment:GetAttribute("Radius") or 1
	local phase = attachment:GetAttribute("Phase") or 0
	local speed = attachment:GetAttribute("Speed") or 1
	local height = attachment:GetAttribute("Height") or 0
	local tiltX = attachment:GetAttribute("TiltX") or 0
	local tiltZ = attachment:GetAttribute("TiltZ") or 0
	local angle = phase + time * speed * rotationSpeed
	local flat = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
	return CFrame.Angles(tiltX, 0, tiltZ):VectorToWorldSpace(flat)
end

local elapsed = 0
local accumulator = 0
RunService.Heartbeat:Connect(function(deltaTime)
	if not effect.Parent then
		return
	end
	elapsed += deltaTime
	accumulator += deltaTime
	if accumulator < (1 / 30) then
		return
	end
	accumulator = 0

	for _, attachment in ipairs(ringAttachments) do
		attachment.Position = orbitPosition(attachment, elapsed)
	end
	for _, attachment in ipairs(streamAttachments) do
		local position = orbitPosition(attachment, elapsed)
		-- Attachment Front points toward the event horizon so emitted particles
		-- travel inward while their emission points revolve around the disk.
		attachment.CFrame = CFrame.lookAt(position, Vector3.zero)
	end
end)
]==]

local function sequenceColor(first: Color3, middle: Color3, last: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, first),
		ColorSequenceKeypoint.new(0.55, middle),
		ColorSequenceKeypoint.new(1, last),
	})
end

local function configureOrbit(attachment: Attachment, radius: number, phase: number,
	speed: number, height: number, tiltX: number, tiltZ: number)
	attachment:SetAttribute("Radius", radius)
	attachment:SetAttribute("Phase", phase)
	attachment:SetAttribute("Speed", speed)
	attachment:SetAttribute("Height", height)
	attachment:SetAttribute("TiltX", tiltX)
	attachment:SetAttribute("TiltZ", tiltZ)

	-- Give the orbit a real starting shape in Studio Edit mode. Runtime Scripts
	-- do not execute until Play starts, so leaving these at (0, 0, 0) collapses
	-- every Beam and makes the generated vortex appear to be missing.
	local flat = Vector3.new(math.cos(phase) * radius, height, math.sin(phase) * radius)
	attachment.Position = CFrame.Angles(tiltX, 0, tiltZ):VectorToWorldSpace(flat)
end

local function makePart(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = size
	part.CFrame = cframe
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function createEffect(origin: Attachment)
	local hostPart = origin.Parent
	assert(hostPart and hostPart:IsA("BasePart"),
		("Attachment %s must be directly under a BasePart"):format(origin:GetFullName()))

	local old = origin:FindFirstChild("BlackHoleEffect")
	if old then
		old:Destroy()
	end

	local scale = EFFECT_SCALE
	local effect = Instance.new("Folder")
	effect.Name = "BlackHoleEffect"
	effect:SetAttribute("GeneratorVersion", SCRIPT_VERSION)
	effect:SetAttribute("EffectScale", scale)
	effect:SetAttribute("RotationSpeed", ROTATION_SPEED)
	effect:SetAttribute("Intensity", INTENSITY)
	effect.Parent = origin

	local core = makePart("EventHorizon", Vector3.new(4.2, 4.2, 4.2) * scale, origin.WorldCFrame, effect)
	core.Color = Color3.fromRGB(0, 0, 0)
	core.Material = Enum.Material.SmoothPlastic
	core.Transparency = 0

	local weld = Instance.new("WeldConstraint")
	weld.Name = "BlackHoleWeld"
	weld.Part0 = core
	weld.Part1 = hostPart
	weld.Parent = core

	local halo = makePart("GravityHalo", Vector3.new(5.1, 5.1, 5.1) * scale, origin.WorldCFrame, effect)
	halo.Color = Color3.fromRGB(82, 16, 130)
	halo.Material = Enum.Material.Neon
	halo.Transparency = 0.82
	local haloWeld = Instance.new("WeldConstraint")
	haloWeld.Part0 = halo
	haloWeld.Part1 = core
	haloWeld.Parent = halo

	local light = Instance.new("PointLight")
	light.Name = "BlackHoleGlow"
	light.Color = Color3.fromRGB(137, 38, 255)
	light.Brightness = 2.2 * INTENSITY
	light.Range = 14 * scale
	light.Shadows = true
	light.Parent = core

	local diskAttachment = Instance.new("Attachment")
	diskAttachment.Name = "DiskMistOrigin"
	diskAttachment.Parent = core

	local diskMist = Instance.new("ParticleEmitter")
	diskMist.Name = "AccretionMist"
	diskMist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	diskMist.Color = sequenceColor(
		Color3.fromRGB(255, 175, 46),
		Color3.fromRGB(200, 45, 255),
		Color3.fromRGB(50, 18, 105)
	)
	diskMist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.65, 0.62),
		NumberSequenceKeypoint.new(1, 1),
	})
	diskMist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	diskMist.Lifetime = NumberRange.new(0.7, 1.3)
	diskMist.Rate = 34 * INTENSITY
	diskMist.Speed = NumberRange.new(1.2 * scale, 2.2 * scale)
	diskMist.Rotation = NumberRange.new(0, 360)
	diskMist.RotSpeed = NumberRange.new(-180, 180)
	diskMist.SpreadAngle = Vector2.new(8, 360)
	diskMist.LightEmission = 0.8
	diskMist.LightInfluence = 0
	diskMist.Drag = 1.5
	diskMist.LockedToPart = false
	diskMist.Parent = diskAttachment

	-- Orbiting gas banks make this read as an unstable dimensional anomaly
	-- rather than a scientifically accurate black hole. Each cloud is emitted
	-- from a moving attachment, so the whole mass visibly curls around the core.
	local gasVortex = Instance.new("Folder")
	gasVortex.Name = "SpinningGasVortex"
	gasVortex.Parent = effect
	local gasLayers = {
		{
			radius = 3.3, height = 0.10, tiltX = math.rad(18), tiltZ = math.rad(-10), speed = 1.55,
			colorA = Color3.fromRGB(26, 238, 255), colorB = Color3.fromRGB(109, 34, 255),
			size = 2.1, rate = 7,
		},
		{
			radius = 4.6, height = -0.15, tiltX = math.rad(-13), tiltZ = math.rad(20), speed = -1.05,
			colorA = Color3.fromRGB(255, 38, 224), colorB = Color3.fromRGB(74, 35, 255),
			size = 2.7, rate = 6,
		},
		{
			radius = 5.8, height = 0.20, tiltX = math.rad(8), tiltZ = math.rad(28), speed = 0.72,
			colorA = Color3.fromRGB(84, 72, 255), colorB = Color3.fromRGB(20, 205, 255),
			size = 3.2, rate = 5,
		},
	}

	for layerIndex, definition in ipairs(gasLayers) do
		local layer = Instance.new("Folder")
		layer.Name = "GasLayer" .. layerIndex
		layer.Parent = gasVortex
		local gasAttachments = {}
		for index = 1, GAS_EMITTERS_PER_LAYER do
			local phase = ((index - 1) / GAS_EMITTERS_PER_LAYER) * math.pi * 2
			local attachment = Instance.new("Attachment")
			attachment.Name = ("Gas%02d_%02d"):format(layerIndex, index)
			attachment:SetAttribute("OrbitKind", "Ring")
			configureOrbit(attachment, definition.radius * scale, phase, definition.speed,
				definition.height * scale, definition.tiltX, definition.tiltZ)
			attachment.Parent = core
			table.insert(gasAttachments, attachment)

			local gas = Instance.new("ParticleEmitter")
			gas.Name = "WarpGas"
			gas.Texture = "rbxasset://textures/particles/smoke_main.dds"
			gas.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, definition.colorA),
				ColorSequenceKeypoint.new(1, definition.colorB),
			})
			gas.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.45),
				NumberSequenceKeypoint.new(0.68, 0.68),
				NumberSequenceKeypoint.new(1, 1),
			})
			gas.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, definition.size * 0.35 * scale),
				NumberSequenceKeypoint.new(0.45, definition.size * scale),
				NumberSequenceKeypoint.new(1, definition.size * 0.18 * scale),
			})
			gas.Lifetime = NumberRange.new(1.0, 1.7)
			gas.Rate = definition.rate * 2.5 * INTENSITY
			gas.Speed = NumberRange.new(0.15 * scale, 0.55 * scale)
			gas.Rotation = NumberRange.new(0, 360)
			gas.RotSpeed = NumberRange.new(-95, 95)
			gas.SpreadAngle = Vector2.new(180, 180)
			gas.Drag = 2
			gas.LightEmission = 0.72
			gas.LightInfluence = 0
			gas.LockedToPart = true
			gas.ZOffset = -0.25
			gas.Parent = attachment
		end

		-- Broad textured beams form continuous gaseous ribbons. Their attachment
		-- points physically orbit, while TextureSpeed makes gas flow through them.
		for index, attachment0 in ipairs(gasAttachments) do
			local attachment1 = gasAttachments[(index % #gasAttachments) + 1]
			local gasRibbon = Instance.new("Beam")
			gasRibbon.Name = ("GasRibbon%02d"):format(index)
			gasRibbon.Attachment0 = attachment0
			gasRibbon.Attachment1 = attachment1
			gasRibbon.Width0 = definition.size * 0.72 * scale
			gasRibbon.Width1 = definition.size * 0.48 * scale
			gasRibbon.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, definition.colorA),
				ColorSequenceKeypoint.new(1, definition.colorB),
			})
			gasRibbon.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.5, 0.22),
				NumberSequenceKeypoint.new(1, 0.68),
			})
			gasRibbon.Texture = "rbxasset://textures/particles/smoke_main.dds"
			gasRibbon.TextureMode = Enum.TextureMode.Wrap
			gasRibbon.TextureLength = 2.4 * scale
			gasRibbon.TextureSpeed = definition.speed * 1.3
			gasRibbon.LightEmission = 0.85
			gasRibbon.LightInfluence = 0
			gasRibbon.FaceCamera = true
			gasRibbon.Segments = 8
			gasRibbon.CurveSize0 = definition.radius * 0.22 * scale
			gasRibbon.CurveSize1 = -definition.radius * 0.22 * scale
			gasRibbon.Parent = layer
		end
	end

	local portalLightAttachment = Instance.new("Attachment")
	portalLightAttachment.Name = "PortalLightOrigin"
	portalLightAttachment.Parent = core
	local portalMotes = Instance.new("ParticleEmitter")
	portalMotes.Name = "DimensionalMotes"
	portalMotes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	portalMotes.Color = sequenceColor(
		Color3.fromRGB(80, 246, 255),
		Color3.fromRGB(255, 72, 241),
		Color3.fromRGB(120, 46, 255)
	)
	portalMotes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.75, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	portalMotes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22 * scale),
		NumberSequenceKeypoint.new(0.7, 0.08 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	portalMotes.Lifetime = NumberRange.new(0.55, 1.15)
	portalMotes.Rate = 28 * INTENSITY
	portalMotes.Speed = NumberRange.new(2.0 * scale, 4.5 * scale)
	portalMotes.SpreadAngle = Vector2.new(180, 180)
	portalMotes.Rotation = NumberRange.new(0, 360)
	portalMotes.RotSpeed = NumberRange.new(-220, 220)
	portalMotes.Drag = 3.5
	portalMotes.LightEmission = 1
	portalMotes.LightInfluence = 0
	portalMotes.Parent = portalLightAttachment

	local rings = Instance.new("Folder")
	rings.Name = "AccretionRings"
	rings.Parent = effect
	local ringDefinitions = {
		{ radius = 4.2, height = 0, tiltX = math.rad(5), tiltZ = math.rad(-8), speed = 1.35,
			width = 0.30, color = Color3.fromRGB(255, 143, 31), transparency = 0.08 },
		{ radius = 5.2, height = 0.15, tiltX = math.rad(-9), tiltZ = math.rad(13), speed = -0.92,
			width = 0.22, color = Color3.fromRGB(217, 58, 255), transparency = 0.20 },
		{ radius = 6.3, height = -0.2, tiltX = math.rad(13), tiltZ = math.rad(5), speed = 0.66,
			width = 0.14, color = Color3.fromRGB(91, 91, 255), transparency = 0.35 },
	}

	for ringIndex, definition in ipairs(ringDefinitions) do
		local ringFolder = Instance.new("Folder")
		ringFolder.Name = "Ring" .. ringIndex
		ringFolder.Parent = rings
		local attachments = {}
		for index = 1, RING_SEGMENTS do
			local phase = ((index - 1) / RING_SEGMENTS) * math.pi * 2
			local attachment = Instance.new("Attachment")
			attachment.Name = ("Point%02d"):format(index)
			attachment:SetAttribute("OrbitKind", "Ring")
			configureOrbit(attachment, definition.radius * scale, phase, definition.speed,
				definition.height * scale, definition.tiltX, definition.tiltZ)
			attachment.Parent = core
			table.insert(attachments, attachment)
		end
		for index, attachment0 in ipairs(attachments) do
			local attachment1 = attachments[(index % #attachments) + 1]
			local beam = Instance.new("Beam")
			beam.Name = ("Arc%02d"):format(index)
			beam.Attachment0 = attachment0
			beam.Attachment1 = attachment1
			beam.Width0 = definition.width * scale
			beam.Width1 = definition.width * 0.72 * scale
			beam.Color = ColorSequence.new(definition.color)
			beam.Transparency = NumberSequence.new(definition.transparency)
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Segments = 4
			beam.CurveSize0 = definition.radius * 0.12 * scale
			beam.CurveSize1 = -definition.radius * 0.12 * scale
			beam.Parent = ringFolder
		end
	end

	local streams = Instance.new("Folder")
	streams.Name = "InwardStreams"
	streams.Parent = effect
	for index = 1, INWARD_EMITTERS do
		local phase = ((index - 1) / INWARD_EMITTERS) * math.pi * 2
		local attachment = Instance.new("Attachment")
		attachment.Name = ("Stream%02d"):format(index)
		attachment:SetAttribute("OrbitKind", "Stream")
		configureOrbit(attachment, 6.8 * scale, phase, 0.78, 0,
			math.rad(-5), math.rad(8))
		attachment.CFrame = CFrame.lookAt(attachment.Position, Vector3.zero)
		attachment.Parent = core

		local particles = Instance.new("ParticleEmitter")
		particles.Name = "InfallParticles"
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = sequenceColor(
			Color3.fromRGB(255, 206, 82),
			Color3.fromRGB(226, 72, 255),
			Color3.fromRGB(79, 24, 162)
		)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.75, 0.28),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.34 * scale),
			NumberSequenceKeypoint.new(0.75, 0.16 * scale),
			NumberSequenceKeypoint.new(1, 0),
		})
		particles.Lifetime = NumberRange.new(1.15, 1.55)
		particles.Rate = 5 * INTENSITY
		particles.Speed = NumberRange.new(4.2 * scale, 5.4 * scale)
		particles.EmissionDirection = Enum.NormalId.Front
		particles.SpreadAngle = Vector2.new(4, 4)
		particles.Drag = 0.4
		particles.LightEmission = 1
		particles.LightInfluence = 0
		particles.LockedToPart = false
		particles.Parent = attachment
	end

	local controller = Instance.new("Script")
	controller.Name = "BlackHoleController"
	controller.Source = CONTROLLER_SOURCE
	controller.Parent = effect

	return effect
end

local origins = {}
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Attachment") then
		table.insert(origins, selected)
	elseif selected:IsA("BasePart") then
		local origin = selected:FindFirstChild("BlackHoleOrigin")
		if not origin or not origin:IsA("Attachment") then
			origin = Instance.new("Attachment")
			origin.Name = "BlackHoleOrigin"
			origin.Parent = selected
		end
		table.insert(origins, origin)
	end
end

assert(#origins > 0, "Select at least one Attachment or BasePart")
local created = {}
for _, origin in ipairs(origins) do
	table.insert(created, createEffect(origin))
end
Selection:Set(created)
print(("[BlackHoleEffect %s] Created %d effect(s)"):format(SCRIPT_VERSION, #created))
