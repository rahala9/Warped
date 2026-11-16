local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("DeathEffectSystem"):WaitForChild("Config"))
local effectConfig = Config.Effects.Disintegrate

local DisintegrateProvider = {}
local random = Random.new()
local sharedAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")

local function getBaseParts(root: Instance): { BasePart }
	local parts = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function getPivot(root: Instance): CFrame
	if root:IsA("Model") then
		return root:GetPivot()
	end
	return (root :: BasePart).CFrame
end

local function pivotTo(root: Instance, cframe: CFrame)
	if root:IsA("Model") then
		root:PivotTo(cframe)
	else
		(root :: BasePart).CFrame = cframe
	end
end

local function getBounds(root: Instance): (CFrame, Vector3)
	if root:IsA("Model") then
		return root:GetBoundingBox()
	end
	local part = root :: BasePart
	return part.CFrame, part.Size
end

local function getWorldBoundsFromParts(parts: { BasePart }): (CFrame, Vector3)
	local minimum = Vector3.new(math.huge, math.huge, math.huge)
	local maximum = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ipairs(parts) do
		local half = part.Size * 0.5
		local right = part.CFrame.RightVector
		local up = part.CFrame.UpVector
		local look = part.CFrame.LookVector
		local extent = Vector3.new(
			math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
			math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
			math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
		)
		local partMinimum = part.Position - extent
		local partMaximum = part.Position + extent
		minimum = Vector3.new(
			math.min(minimum.X, partMinimum.X),
			math.min(minimum.Y, partMinimum.Y),
			math.min(minimum.Z, partMinimum.Z)
		)
		maximum = Vector3.new(
			math.max(maximum.X, partMaximum.X),
			math.max(maximum.Y, partMaximum.Y),
			math.max(maximum.Z, partMaximum.Z)
		)
	end
	local size = maximum - minimum
	return CFrame.new((minimum + maximum) * 0.5), size
end

local function getVisualBounds(root: Instance): (CFrame, Vector3)
	local visibleParts = {}
	local allParts = getBaseParts(root)
	for _, part in ipairs(allParts) do
		if part.Transparency < 1 then
			table.insert(visibleParts, part)
		end
	end
	return getWorldBoundsFromParts(if #visibleParts > 0 then visibleParts else allParts)
end

local function scaleAsset(root: Instance, factor: number)
	if not (factor > 0) or factor == math.huge then
		return
	end
	if root:IsA("Model") then
		root:ScaleTo(root:GetScale() * factor)
	else
		local part = root :: BasePart
		part.Size *= factor
		local specialMesh = part:FindFirstChildWhichIsA("SpecialMesh")
		if specialMesh then
			specialMesh.Scale *= factor
			specialMesh.Offset *= factor
		end
	end
end

local function countVisibleParts(root: Instance): (number, number)
	local total = 0
	local visible = 0
	for _, part in ipairs(getBaseParts(root)) do
		total += 1
		if part.Transparency < 1 then
			visible += 1
		end
	end
	return visible, total
end

local function choosePhysicalRoot(parts: { BasePart }): BasePart
	local best = parts[1]
	local bestScore = -1
	for _, part in ipairs(parts) do
		local volume = part.Size.X * part.Size.Y * part.Size.Z
		local visibilityBonus = if part.Transparency < 1 then 1e9 else 0
		local score = visibilityBonus + volume
		if score > bestScore then
			best = part
			bestScore = score
		end
	end
	return best
end

local function createDustEmitter(parent: Model, sourcePart: BasePart)
	local anchor = Instance.new("Part")
	anchor.Name = "DustEmitter"
	-- A volume emitter distributes dust throughout the disappearing limb instead
	-- of producing one small puff from its center.
	anchor.Size = Vector3.new(
		math.max(sourcePart.Size.X, 0.15),
		math.max(sourcePart.Size.Y, 0.15),
		math.max(sourcePart.Size.Z, 0.15)
	)
	anchor.CFrame = sourcePart.CFrame
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FallingDust"
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(effectConfig.DustColor)
	emitter.LightInfluence = 0.65
	emitter.Lifetime = NumberRange.new(1.6, 2.8)
	emitter.Speed = NumberRange.new(0.15, 1.1)
	emitter.Acceleration = Vector3.new(0, -24, 0)
	emitter.Drag = 0.35
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.SpreadAngle = Vector2.new(16, 16)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.32),
		NumberSequenceKeypoint.new(0.45, 0.48),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.75, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Rate = 0
	emitter.Parent = anchor

	local burstCount = math.max(effectConfig.ParticleBurstCount, 1)
	local particlesPerBurst = math.max(math.floor(effectConfig.ParticleCountPerPart / burstCount), 1)
	for burstIndex = 1, burstCount do
		task.delay((burstIndex - 1) * effectConfig.ParticleBurstInterval, function()
			if emitter.Parent then
				emitter:Emit(particlesPerBurst)
			end
		end)
	end
end

local function getGroundPosition(character: Model): (Vector3, Vector3)
	local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	local origin = if root and root:IsA("BasePart") then root.Position else character:GetPivot().Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = false
	local result = workspace:Raycast(origin + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), params)
	if result then
		return result.Position, result.Normal
	end
	return origin - Vector3.new(0, 3, 0), Vector3.yAxis
end

local function createPilePiece(parent: Model, position: Vector3, size: Vector3, transparency: number)
	local piece = Instance.new("Part")
	piece.Name = "DustPile"
	piece.Shape = Enum.PartType.Ball
	piece.Size = Vector3.new(size.X * 0.2, size.Y * 0.2, size.Z * 0.2)
	piece.CFrame = CFrame.new(position)
	piece.Color = effectConfig.DustPileColor
	piece.Material = Enum.Material.Sand
	piece.Transparency = 1
	piece.Anchored = true
	piece.CanCollide = false
	piece.CanTouch = false
	piece.CanQuery = false
	piece.Parent = parent

	task.delay(0.65 + random:NextNumber(0, 0.3), function()
		if piece.Parent then
			TweenService:Create(
				piece,
				TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = size, Transparency = transparency }
			):Play()
		end
	end)
end

local function createDustPile(parent: Model, character: Model)
	local groundPosition, groundNormal = getGroundPosition(character)
	local pileTemplate = sharedAssets:FindFirstChild("BonePile")
	if pileTemplate and (pileTemplate:IsA("Model") or pileTemplate:IsA("BasePart")) then
		local pile = pileTemplate:Clone()
		pile.Name = "DisintegrationBonePile"
		pile.Parent = parent
		local _, importedSize = getVisualBounds(pile)
		local importedWidth = math.max(importedSize.X, importedSize.Z)
		if importedWidth > 0 then
			scaleAsset(pile, effectConfig.BonePileWidth / importedWidth)
		end

		local originalTransparency = {}
		local authoredVisibleCount = 0
		for _, part in ipairs(getBaseParts(pile)) do
			originalTransparency[part] = part.Transparency
			if part.Transparency < 1 then
				authoredVisibleCount += 1
			end
			part.LocalTransparencyModifier = 0
			part.Transparency = 1
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
		if authoredVisibleCount == 0 then
			warn("[DeathEffectSystem] SharedClientAssets.BonePile has no visible BaseParts; forcing its parts visible")
			for part in pairs(originalTransparency) do
				originalTransparency[part] = 0
				authoredVisibleCount += 1
			end
		end

		-- Preserve the authored orientation and align the asset's lowest bound to
		-- the detected floor rather than placing its pivot inside the floor.
		local rotation = getPivot(pile).Rotation
		pivotTo(pile, CFrame.new(groundPosition) * rotation)
		-- Parts are temporarily transparent for the fade, so calculate bounds from
		-- the parts that were visible in the authored asset.
		local visualParts = {}
		for part, transparency in pairs(originalTransparency) do
			if transparency < 1 then
				table.insert(visualParts, part)
			end
		end
		local boundsCFrame, boundsSize = getWorldBoundsFromParts(visualParts)
		local bottomY = boundsCFrame.Position.Y - boundsSize.Y * 0.5
		local boundsCorrection = Vector3.new(
			groundPosition.X - boundsCFrame.Position.X,
			groundPosition.Y - bottomY + 0.02,
			groundPosition.Z - boundsCFrame.Position.Z
		)
		pivotTo(pile, getPivot(pile) + boundsCorrection)

		task.delay(0.55, function()
			for part, transparency in pairs(originalTransparency) do
				if part.Parent then
					TweenService:Create(
						part,
						TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = transparency }
					):Play()
				end
			end
		end)

		local finalBounds, finalSize = getWorldBoundsFromParts(visualParts)
		local _, totalCount = countVisibleParts(pile)
		if Config.Debug then
			print(("[DeathEffectSystem][Client] BonePile parts=%d visible=%d bounds=%s size=%s"):format(
				totalCount,
				authoredVisibleCount,
				tostring(finalBounds.Position),
				tostring(finalSize)
			))
		end
		return finalBounds.Position
	end

	warn("[DeathEffectSystem] Missing SharedClientAssets.BonePile; using procedural pile fallback")
	local centerSize = Vector3.new(3.6, 0.55, 2.7)
	local center = groundPosition + groundNormal * (centerSize.Y * 0.5 + 0.02)
	createPilePiece(parent, center, centerSize, 0.04)
	for _ = 1, effectConfig.DustPilePieceCount do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(0.2, 1.45)
		local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local pieceSize = Vector3.new(
			random:NextNumber(0.7, 1.5),
			random:NextNumber(0.18, 0.42),
			random:NextNumber(0.55, 1.25)
		)
		createPilePiece(
			parent,
			groundPosition + offset + groundNormal * (pieceSize.Y * 0.5 + random:NextNumber(0.01, 0.08)),
			pieceSize,
			random:NextNumber(0.04, 0.16)
		)
	end
	return center
end

local function findHeadPart(character: Model): BasePart?
	for _, name in ipairs({ "Head", "Skull", "Face", "face" }) do
		local candidate = character:FindFirstChild(name, true)
		if candidate and candidate:IsA("BasePart") then
			return candidate
		end
	end

	local highest
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart")
			and descendant.Name ~= "HumanoidRootPart"
			and (not highest or descendant.Position.Y > highest.Position.Y)
		then
			highest = descendant
		end
	end
	return highest
end

local function weldFeature(head: BasePart, name: string, size: Vector3, offset: CFrame, shape)
	local feature = Instance.new("Part")
	feature.Name = name
	feature.Size = size
	feature.Shape = shape or Enum.PartType.Block
	feature.Color = Color3.fromRGB(24, 21, 20)
	feature.Material = Enum.Material.SmoothPlastic
	feature.CFrame = head.CFrame * offset
	feature.Anchored = false
	feature.CanCollide = false
	feature.CanTouch = false
	feature.CanQuery = false
	feature.Massless = true
	feature.Parent = head.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = feature
	weld.Parent = feature
end

local function createFallingHead(parent: Model, character: Model, pilePosition: Vector3)
	local sourceHead = findHeadPart(character)
	local skullTemplate = sharedAssets:FindFirstChild("Skull")
	local skull: Instance
	local usingAuthoredSkull = skullTemplate ~= nil
		and (skullTemplate:IsA("Model") or skullTemplate:IsA("BasePart"))

	if usingAuthoredSkull then
		skull = skullTemplate:Clone()
	elseif sourceHead then
		local wasArchivable = sourceHead.Archivable
		sourceHead.Archivable = true
		skull = sourceHead:Clone()
		sourceHead.Archivable = wasArchivable
	else
		local fallback = Instance.new("Part")
		fallback.Size = Vector3.new(1.25, 1.25, 1.25)
		fallback.Shape = Enum.PartType.Ball
		skull = fallback
	end
	skull.Name = "FallingSkull"
	skull.Parent = parent
	if usingAuthoredSkull then
		local _, importedSize = getVisualBounds(skull)
		local importedMaximumSize = math.max(importedSize.X, importedSize.Y, importedSize.Z)
		if importedMaximumSize > 0 then
			scaleAsset(skull, effectConfig.SkullMaximumSize / importedMaximumSize)
		end
	end

	local targetCFrame = if sourceHead then sourceHead.CFrame else character:GetPivot() * CFrame.new(0, 2.5, 0)
	pivotTo(skull, targetCFrame)
	local skullParts = getBaseParts(skull)
	if #skullParts == 0 then
		skull:Destroy()
		warn("[DeathEffectSystem] SharedClientAssets.Skull contains no BaseParts")
		return
	end

	-- Imported model pivots are often nowhere near their mesh. Align the actual
	-- rendered bounds to the source head before enabling physics.
	local skullBounds = getVisualBounds(skull)
	pivotTo(skull, getPivot(skull) + (targetCFrame.Position - skullBounds.Position))

	local root = if skull:IsA("Model")
		then skull.PrimaryPart or choosePhysicalRoot(skullParts)
		else skull :: BasePart
	if skull:IsA("Model") and not skull.PrimaryPart then
		skull.PrimaryPart = root
	end

	for _, part in ipairs(skullParts) do
		part.LocalTransparencyModifier = 0
		part.Anchored = true
		part.CollisionGroup = "Default"
		part.CanCollide = part == root
		part.CanTouch = false
		part.CanQuery = part == root
		part.Massless = part ~= root
		if part ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "DisintegrationSkullWeld"
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = root
		end
	end
	local visibleSkullParts = countVisibleParts(skull)
	if visibleSkullParts == 0 then
		warn("[DeathEffectSystem] SharedClientAssets.Skull has no visible BaseParts; forcing its root visible")
		root.Transparency = 0
	end

	if not usingAuthoredSkull then
		root.Transparency = 0
		root.Color = Color3.fromRGB(226, 219, 198)
		root.Material = Enum.Material.SmoothPlastic
		local frontZ = -(root.Size.Z * 0.5 + 0.035)
		weldFeature(root, "LeftEyeSocket", Vector3.new(root.Size.X * 0.22, root.Size.Y * 0.25, 0.06), CFrame.new(-root.Size.X * 0.2, root.Size.Y * 0.12, frontZ), Enum.PartType.Ball)
		weldFeature(root, "RightEyeSocket", Vector3.new(root.Size.X * 0.22, root.Size.Y * 0.25, 0.06), CFrame.new(root.Size.X * 0.2, root.Size.Y * 0.12, frontZ), Enum.PartType.Ball)
		weldFeature(root, "SkullMouth", Vector3.new(root.Size.X * 0.4, root.Size.Y * 0.08, 0.055), CFrame.new(0, -root.Size.Y * 0.22, frontZ))
	end

	for _, part in ipairs(skullParts) do
		part.Anchored = false
	end

	local horizontal = Vector3.new(
		random:NextNumber(-effectConfig.SkullHorizontalVelocity, effectConfig.SkullHorizontalVelocity),
		0,
		random:NextNumber(-effectConfig.SkullHorizontalVelocity, effectConfig.SkullHorizontalVelocity)
	)
	local towardPile = Vector3.new(pilePosition.X - root.Position.X, 0, pilePosition.Z - root.Position.Z)
	if towardPile.Magnitude > 0.1 then
		horizontal += towardPile.Unit * 1.5
	end
	root.AssemblyLinearVelocity = horizontal + Vector3.new(0, effectConfig.SkullUpwardVelocity, 0)
	root.AssemblyAngularVelocity = Vector3.new(
		random:NextNumber(-5, 5),
		random:NextNumber(-5, 5),
		random:NextNumber(-5, 5)
	)
	if Config.Debug then
		local finalSkullBounds, finalSkullSize = getVisualBounds(skull)
		local visibleCount, totalCount = countVisibleParts(skull)
		print(("[DeathEffectSystem][Client] Dropped %s from %s; parts=%d visible=%d bounds=%s size=%s"):format(
			usingAuthoredSkull and "SharedClientAssets.Skull" or "fallback skull",
			sourceHead and sourceHead:GetFullName() or "character pivot",
			totalCount,
			visibleCount,
			tostring(finalSkullBounds.Position),
			tostring(finalSkullSize)
		))
	end
end

function DisintegrateProvider.Render(character: Model, _payload)
	local effect = Instance.new("Model")
	effect.Name = character.Name .. "_Disintegration"
	effect.Parent = workspace

	local pilePosition = createDustPile(effect, character)
	local emitted = 0
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart")
			and descendant.Name ~= "HumanoidRootPart"
			and descendant.Transparency < 1
		then
			createDustEmitter(effect, descendant)
			emitted += 1
			if emitted >= effectConfig.MaximumEmitters then
				break
			end
		end
	end
	createFallingHead(effect, character, pilePosition)
	return effect
end

return DisintegrateProvider
