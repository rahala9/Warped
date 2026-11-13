local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local MuzzleEffects = {}

local function configurePart(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Massless = true
end

local function effectParent(): Instance
	return workspace:FindFirstChild("SharedWorkspaceItems") or workspace
end

local function createAttachedFlash(muzzleAttachment, settings)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "EnergyMuzzleFlash"
	emitter.Enabled = false
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(settings.Color)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Lifetime = NumberRange.new(settings.FlashDuration)
	emitter.Rate = 0
	emitter.Speed = NumberRange.new(0)
	emitter.LockedToPart = true
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, settings.FlashSize),
		NumberSequenceKeypoint.new(0.35, settings.FlashSize * settings.FlashExpansion),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.65, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = muzzleAttachment

	local light = Instance.new("PointLight")
	light.Name = "EnergyMuzzleLight"
	light.Color = settings.Color
	light.Brightness = settings.LightBrightness
	light.Range = settings.LightRange
	light.Shadows = false
	light.Parent = muzzleAttachment

	emitter:Emit(2)
	TweenService:Create(
		light,
		TweenInfo.new(settings.FlashDuration, Enum.EasingStyle.Linear),
		{Brightness = 0, Range = 0}
	):Play()
	Debris:AddItem(emitter, settings.FlashDuration + 0.1)
	Debris:AddItem(light, settings.FlashDuration + 0.02)
end

local function createWorldFlash(origin, settings)
	local flash = Instance.new("Part")
	flash.Name = "LocalMuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Color = settings.Color
	flash.Size = Vector3.one * settings.FlashSize
	flash.Transparency = 0.08
	flash.CFrame = CFrame.new(origin)
	configurePart(flash)
	flash.Parent = effectParent()

	local light = Instance.new("PointLight")
	light.Name = "EnergyMuzzleLight"
	light.Color = settings.Color
	light.Brightness = settings.LightBrightness
	light.Range = settings.LightRange
	light.Shadows = false
	light.Parent = flash

	local duration = settings.FlashDuration
	TweenService:Create(
		flash,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = flash.Size * settings.FlashExpansion,
			Transparency = 1,
		}
	):Play()
	TweenService:Create(
		light,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{Brightness = 0, Range = 0}
	):Play()

	Debris:AddItem(flash, duration + 0.02)
end

local function createOriginStreak(origin, target, settings)
	if not settings.StreakLength or settings.StreakLength <= 0 then
		return
	end

	local offset = target - origin
	local targetDistance = offset.Magnitude
	if targetDistance < 0.01 then
		return
	end

	local length = math.min(settings.StreakLength, targetDistance)
	local direction = offset.Unit
	local streakEnd = origin + direction * length
	local midpoint = origin:Lerp(streakEnd, 0.5)

	local streak = Instance.new("Part")
	streak.Name = "LocalMuzzleStreak"
	streak.Color = settings.Color
	streak.Size = Vector3.new(settings.StreakWidth, settings.StreakWidth, length)
	streak.Transparency = 0.12
	streak.CFrame = CFrame.lookAt(midpoint, streakEnd)
	configurePart(streak)
	streak.Parent = effectParent()

	local duration = settings.StreakDuration
	TweenService:Create(
		streak,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{Transparency = 1}
	):Play()
	Debris:AddItem(streak, duration + 0.02)
end

function MuzzleEffects.Emit(muzzleCFrame, targetPosition, settings, muzzleInstance)
	if not muzzleCFrame or typeof(targetPosition) ~= "Vector3" then
		return
	end

	-- Snapshot both endpoints. These effects intentionally remain in world
	-- space and never follow the player, camera, or weapon after the shot.
	local effectCFrame = muzzleCFrame * (settings.MuzzleEffectOffset or CFrame.identity)
	local origin = effectCFrame.Position
	if muzzleInstance
		and muzzleInstance:IsA("Attachment")
		and muzzleInstance.Parent
		and (settings.MuzzleEffectOffset or CFrame.identity) == CFrame.identity
	then
		createAttachedFlash(muzzleInstance, settings)
	else
		createWorldFlash(origin, settings)
	end
	createOriginStreak(origin, targetPosition, settings)
end

return MuzzleEffects
