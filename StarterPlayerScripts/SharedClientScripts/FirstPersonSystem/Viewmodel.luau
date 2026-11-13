local UserInputService = game:GetService("UserInputService")

local Viewmodel = {}
Viewmodel.__index = Viewmodel

local function getWorldCFrame(instance): CFrame?
	if instance:IsA("Attachment") then
		return instance.WorldCFrame
	end

	if instance:IsA("Bone") then
		return instance.TransformedWorldCFrame
	end

	if instance:IsA("BasePart") then
		return instance.CFrame
	end

	if instance:IsA("Model") then
		return instance:GetPivot()
	end

	return nil
end

local function cloneInstance(source): Instance?
	local wasArchivable = source.Archivable
	source.Archivable = true

	local ok, clone = pcall(function()
		return source:Clone()
	end)

	source.Archivable = wasArchivable
	return ok and clone or nil
end

local function findEquippedSource(character, weaponName, weaponDefinition): Instance?
	local direct = character:FindFirstChild(weaponName)
	if direct then
		return direct
	end

	local modelName = weaponDefinition and weaponDefinition.Model
	if type(modelName) == "string" and modelName ~= "" then
		local namedHandle = character:FindFirstChild(modelName .. "Handle", true)
		if namedHandle then
			return namedHandle
		end
	end

	return nil
end

local function findTemplate(weaponName): Instance?
	local sharedSystem = game:GetService("ReplicatedStorage"):FindFirstChild("FirstPersonSystem")
	local templates = sharedSystem and sharedSystem:FindFirstChild("Viewmodels")
	return templates and templates:FindFirstChild(weaponName) or nil
end

local function sanitizeClone(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer")
			or descendant:IsA("Humanoid")
			or descendant:IsA("Animator")
			or descendant:IsA("Constraint")
			or descendant:IsA("JointInstance")
		then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
			descendant.Massless = true
			descendant.LocalTransparencyModifier = 0
		elseif descendant:IsA("Beam")
			or descendant:IsA("Trail")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("Smoke")
			or descendant:IsA("Fire")
			or descendant:IsA("Sparkles")
			or descendant:IsA("Highlight")
		then
			descendant.Enabled = false
		end
	end
end

local function findAnchor(container): Instance?
	return container:FindFirstChild("FirstPersonAnchor", true)
		or container:FindFirstChild("Muzzle", true)
		or container:FindFirstChild("Attachment", true)
		or container:FindFirstChildWhichIsA("BasePart", true)
end

function Viewmodel.new(camera, character, weaponName, weaponDefinition, settings)
	local source = findTemplate(weaponName)
		or findEquippedSource(character, weaponName, weaponDefinition)

	if not source then
		return nil, "no equipped weapon model or first-person template was found"
	end

	local clone = cloneInstance(source)
	if not clone then
		return nil, "the weapon model could not be cloned"
	end

	local container = Instance.new("Model")
	container.Name = "FirstPersonViewmodel"
	clone.Parent = container
	sanitizeClone(container)

	if not container:FindFirstChildWhichIsA("BasePart", true) then
		container:Destroy()
		return nil, "the cloned weapon has no renderable BasePart"
	end

	container.Parent = camera

	local anchor = findAnchor(container)
	local anchorCFrame = anchor and getWorldCFrame(anchor)
	if not anchorCFrame then
		container:Destroy()
		return nil, "the cloned weapon has no usable Muzzle or anchor"
	end

	local modelPivot = container:GetPivot()
	local renderedParts = #container:GetDescendants()
	local muzzle = container:FindFirstChild("Muzzle", true) or anchor
	local self = setmetatable({
		camera = camera,
		model = container,
		muzzle = muzzle,
		settings = settings,
		pivotToAnchor = modelPivot:ToObjectSpace(anchorCFrame),
		currentAnchor = nil,
		sway = Vector2.zero,
		bobTime = 0,
		recoil = 0,
		visible = true,
		diagnostics = {
			Source = source:GetFullName(),
			SourceClass = source.ClassName,
			Anchor = anchor:GetFullName(),
			AnchorClass = anchor.ClassName,
			DescendantCount = renderedParts,
		},
	}, Viewmodel)

	return self
end

function Viewmodel:GetDiagnostics()
	return self.diagnostics
end

function Viewmodel:GetMuzzleCFrame(): CFrame?
	if not self.muzzle or not self.muzzle.Parent then
		return nil
	end

	return getWorldCFrame(self.muzzle)
end

function Viewmodel:GetMuzzleInstance(): Instance?
	if self.muzzle and self.muzzle.Parent then
		return self.muzzle
	end
	return nil
end

function Viewmodel:SetCamera(camera)
	self.camera = camera
	if self.visible and self.model then
		self.model.Parent = camera
	end
end

function Viewmodel:SetVisible(visible)
	if self.visible == visible or not self.model then
		return
	end

	self.visible = visible
	self.model.Parent = visible and self.camera or nil
end

function Viewmodel:AddRecoil(multiplier)
	local amount = multiplier or 1
	self.recoil = math.clamp(self.recoil + amount, 0, 3)
end

function Viewmodel:Update(deltaTime, moveAmount)
	if not self.visible or not self.model or not self.model.Parent then
		return
	end

	local settings = self.settings
	local response = settings.Responsiveness or 24
	local alpha = 1 - math.exp(-response * deltaTime)
	local mouseDelta = UserInputService:GetMouseDelta()
	local swayScale = settings.SwayDegreesPerPixel or 0.035
	local maxSway = settings.MaxSwayDegrees or 3
	local targetSway = Vector2.new(
		math.clamp(-mouseDelta.X * swayScale, -maxSway, maxSway),
		math.clamp(-mouseDelta.Y * swayScale, -maxSway, maxSway)
	)
	self.sway = self.sway:Lerp(targetSway, alpha)

	local movement = math.clamp(moveAmount or 0, 0, 1)
	self.bobTime += deltaTime * (settings.BobFrequency or 9) * movement
	local horizontalBob = math.sin(self.bobTime) * (settings.BobHorizontal or 0.018) * movement
	local verticalBob = math.abs(math.cos(self.bobTime)) * (settings.BobVertical or 0.025) * movement

	self.recoil = math.max(0, self.recoil - (settings.RecoilRecovery or 8) * deltaTime)
	local recoilPitch = math.rad(settings.RecoilDegrees or 1.4) * self.recoil
	local recoilBack = (settings.RecoilBack or 0.045) * self.recoil

	local cameraCFrame = self.camera.CFrame
	local targetAnchor =
		cameraCFrame
		* settings.MuzzleOffset
		* CFrame.new(horizontalBob, verticalBob, recoilBack)
		* CFrame.Angles(
			math.rad(self.sway.Y) - recoilPitch,
			math.rad(self.sway.X),
			math.rad(-self.sway.X * 0.35)
		)

	-- Follow camera translation exactly. Smoothing this world-space CFrame makes
	-- the weapon lag behind a moving player and eventually leave the viewport.
	-- Sway is already smoothed independently in camera-local space above.
	self.currentAnchor = targetAnchor
	self.model:PivotTo(targetAnchor * self.pivotToAnchor:Inverse())
end

function Viewmodel:Destroy()
	if self.model then
		self.model:Destroy()
		self.model = nil
	end
end

return Viewmodel
