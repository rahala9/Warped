local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("LaserSliceSystem")
local Config = require(sharedFolder:WaitForChild("Config"))

local SlicedCrewSliceProvider = {}

local random = Random.new()
local RUNTIME_WELD_NAME = "LaserSliceRuntimeWeld"
local FACE_GUI_NAME = "LaserSliceFaceImage"

local function isSearPart(part: BasePart): boolean
	return part:GetAttribute("WarpedLaserSear") == true
		or string.find(string.lower(part.Name), "sear", 1, true) ~= nil
		or part.Material == Enum.Material.Neon
end

local function findFaceImage(character: Model)
	local fallback
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") then
			local data = {
				texture = descendant.Texture,
				color = descendant.Color3,
				transparency = descendant.Transparency,
			}
			if string.lower(descendant.Name) == "face" then
				return data
			end
			if not fallback and descendant.Face == Enum.NormalId.Front then
				fallback = data
			end
		end
	end
	return fallback
end

local function findPartRecursive(root: Instance, name: string): BasePart?
	local candidate = root:FindFirstChild(name, true)
	if candidate and candidate:IsA("BasePart") then
		return candidate
	end
	return nil
end

local function clearGeneratedFace(part: BasePart)
	local existing = part:FindFirstChild(FACE_GUI_NAME)
	if existing then
		existing:Destroy()
	end
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("Decal") and string.lower(child.Name) == "face" then
			child:Destroy()
		end
	end
end

local function addFaceSection(
	part: BasePart,
	faceImage,
	imageHeightScale: number,
	imagePositionY: number
)
	clearGeneratedFace(part)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = FACE_GUI_NAME
	surfaceGui.Adornee = part
	surfaceGui.Face = Config.SlicedCrew.FaceSurface
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = Config.SlicedCrew.FacePixelsPerStud
	surfaceGui.LightInfluence = 0
	surfaceGui.AlwaysOnTop = false
	surfaceGui.Parent = part

	local clipFrame = Instance.new("Frame")
	clipFrame.Name = "Clip"
	clipFrame.Size = UDim2.fromScale(1, 1)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants = true
	clipFrame.Parent = surfaceGui

	local image = Instance.new("ImageLabel")
	image.Name = "Face"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.Size = UDim2.fromScale(1, imageHeightScale)
	image.Position = UDim2.fromScale(0, imagePositionY)
	image.Image = faceImage.texture
	image.ImageColor3 = faceImage.color
	image.ImageTransparency = faceImage.transparency
	image.ScaleType = Enum.ScaleType.Stretch
	image.Parent = clipFrame
end

local function applyFace(effectModel: Model, character: Model)
	local faceImage = findFaceImage(character)
	if not faceImage or faceImage.texture == "" then
		return
	end

	local top = findPartRecursive(effectModel, "FaceTop")
	local bottom = findPartRecursive(effectModel, "FaceBottom")
	if not top or not bottom then
		warn("[LaserSliceSystem] SlicedCrew is missing FaceTop or FaceBottom")
		return
	end

	local topHeight = math.max(top.Size.Y, 0.001)
	local bottomHeight = math.max(bottom.Size.Y, 0.001)
	local totalHeight = topHeight + bottomHeight

	-- Each SurfaceGui sees only its own half. Scale and offset one full face image
	-- so the upper and lower parts display their corresponding vertical regions.
	addFaceSection(top, faceImage, totalHeight / topHeight, 0)
	addFaceSection(
		bottom,
		faceImage,
		totalHeight / bottomHeight,
		-topHeight / bottomHeight
	)
end

local function topLevelChild(instance: Instance, effectModel: Model): Instance
	local current = instance
	while current.Parent and current.Parent ~= effectModel do
		current = current.Parent
	end
	return current
end

local function hasWeldBetween(effectModel: Model, first: BasePart, second: BasePart): boolean
	for _, descendant in ipairs(effectModel:GetDescendants()) do
		if descendant:IsA("WeldConstraint") then
			if (descendant.Part0 == first and descendant.Part1 == second)
				or (descendant.Part0 == second and descendant.Part1 == first) then
				return true
			end
		end
	end
	return false
end

type SliceAssembly = {
	root: BasePart,
	parts: { BasePart },
	group: Instance,
}

local function prepareAssemblies(effectModel: Model): { SliceAssembly }
	local groups = {}
	for _, descendant in ipairs(effectModel:GetDescendants()) do
		if descendant:IsA("WeldConstraint") and descendant.Name == RUNTIME_WELD_NAME then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.LocalTransparencyModifier = 0
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero

			local topLevel = topLevelChild(descendant, effectModel)
			local groupKey = if topLevel.Name:match("^Part%d+$") then topLevel else descendant
			groups[groupKey] = groups[groupKey] or {}
			table.insert(groups[groupKey], descendant)
		end
	end

	-- Imported rigs can retain an old joint between two exported islands. Such a
	-- joint makes multiple PartX groups one physical assembly and can suspend the
	-- corpse in midair. Only connections inside the same slice are valid here.
	for _, descendant in ipairs(effectModel:GetDescendants()) do
		local firstPart
		local secondPart
		if descendant:IsA("WeldConstraint") then
			firstPart = descendant.Part0
			secondPart = descendant.Part1
		elseif descendant:IsA("JointInstance") then
			firstPart = descendant.Part0
			secondPart = descendant.Part1
		elseif descendant:IsA("Constraint") then
			firstPart = descendant.Attachment0 and descendant.Attachment0.Parent
			secondPart = descendant.Attachment1 and descendant.Attachment1.Parent
		end
		if firstPart and secondPart and firstPart:IsA("BasePart") and secondPart:IsA("BasePart") then
			local firstGroup = topLevelChild(firstPart, effectModel)
			local secondGroup = topLevelChild(secondPart, effectModel)
			if firstGroup ~= secondGroup then
				warn(("[LaserSliceSystem] Removed cross-slice connection %s between %s and %s"):format(
					descendant:GetFullName(),
					firstGroup.Name,
					secondGroup.Name
				))
				descendant:Destroy()
			end
		end
	end

	local assemblies = {}
	for group, parts in pairs(groups) do
		local root
		local rootVolume = -1
		for _, part in ipairs(parts) do
			local volume = part.Size.X * part.Size.Y * part.Size.Z
			if not isSearPart(part) and volume > rootVolume then
				root = part
				rootVolume = volume
			end
		end
		root = root or parts[1]
		root.CanCollide = true
		root.CanQuery = true
		root.Massless = false

		for _, part in ipairs(parts) do
			if part ~= root then
				part.Massless = true
				if not hasWeldBetween(effectModel, root, part) then
					local weld = Instance.new("WeldConstraint")
					weld.Name = RUNTIME_WELD_NAME
					weld.Part0 = root
					weld.Part1 = part
					weld.Parent = root
				end
			end
		end
		table.insert(assemblies, {
			root = root,
			parts = parts,
			group = group,
		})
	end
	return assemblies
end

local function isAssemblyGrounded(effectModel: Model, assembly: SliceAssembly): boolean
	local boundsCFrame
	local boundsSize
	if assembly.group:IsA("Model") then
		boundsCFrame, boundsSize = assembly.group:GetBoundingBox()
	else
		boundsCFrame = assembly.root.CFrame
		boundsSize = assembly.root.Size
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { effectModel }
	raycastParams.IgnoreWater = false

	local distance = boundsSize.Y * 0.5 + Config.SlicedCrew.SettleGroundProbeDistance
	local result = workspace:Raycast(boundsCFrame.Position, Vector3.new(0, -distance, 0), raycastParams)
	return result ~= nil
end

local function anchorAssembly(assembly: SliceAssembly)
	for _, part in ipairs(assembly.parts) do
		if part.Parent then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			part.Anchored = true
		end
	end
end

local function monitorSettling(effectModel: Model, assemblies: { SliceAssembly })
	if not Config.SlicedCrew.SettleEnabled then
		return
	end

	local unsettled = {}
	for _, assembly in ipairs(assemblies) do
		unsettled[assembly] = 0
	end
	local startedAt = os.clock()

	task.spawn(function()
		while effectModel.Parent and next(unsettled) ~= nil do
			if os.clock() - startedAt >= Config.SlicedCrew.SettleMonitorDuration then
				-- Do not force-anchor remaining pieces. If one is still airborne or
				-- moving after the monitor expires, normal physics is safer.
				break
			end

			local elapsed = task.wait(Config.SlicedCrew.SettlePollInterval)
			for assembly, stillTime in pairs(unsettled) do
				local root = assembly.root
				if not root.Parent then
					unsettled[assembly] = nil
				else
					local isStill = root.AssemblyLinearVelocity.Magnitude <= Config.SlicedCrew.SettleLinearSpeed
						and root.AssemblyAngularVelocity.Magnitude <= Config.SlicedCrew.SettleAngularSpeed
					local isGrounded = isAssemblyGrounded(effectModel, assembly)
					if isStill and isGrounded then
						stillTime += elapsed
						if stillTime >= Config.SlicedCrew.SettleStillTime then
							anchorAssembly(assembly)
							unsettled[assembly] = nil
						else
							unsettled[assembly] = stillTime
						end
					else
						unsettled[assembly] = 0
					end
				end
			end
		end
	end)
end

local function enablePhysics(effectModel: Model, assemblies: { SliceAssembly })
	if not effectModel.Parent then
		return
	end

	for _, descendant in ipairs(effectModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end

	local boundsCFrame = effectModel:GetBoundingBox()
	local center = boundsCFrame.Position
	for _, assembly in ipairs(assemblies) do
		local root = assembly.root
		if root.Parent then
			local offset = root.Position - center
			local outward = Vector3.new(offset.X, 0, offset.Z)
			if outward.Magnitude < 0.05 then
				local angle = random:NextNumber(0, math.pi * 2)
				outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
			else
				outward = outward.Unit
			end
			local scatterSpeed = random:NextNumber(
				Config.SlicedCrew.MinimumScatterSpeed,
				Config.SlicedCrew.MaximumScatterSpeed
			)
			local jitterAngle = random:NextNumber(-0.3, 0.3)
			outward = CFrame.Angles(0, jitterAngle, 0):VectorToWorldSpace(outward)

			root.AssemblyLinearVelocity = Vector3.new(
				outward.X * scatterSpeed,
				random:NextNumber(
					Config.SlicedCrew.MinimumUpwardVelocity,
					Config.SlicedCrew.MaximumUpwardVelocity
				),
				outward.Z * scatterSpeed
			)
			root.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-Config.SlicedCrew.MaximumAngularVelocity, Config.SlicedCrew.MaximumAngularVelocity),
				random:NextNumber(-Config.SlicedCrew.MaximumAngularVelocity, Config.SlicedCrew.MaximumAngularVelocity),
				random:NextNumber(-Config.SlicedCrew.MaximumAngularVelocity, Config.SlicedCrew.MaximumAngularVelocity)
			)
		end
	end
	monitorSettling(effectModel, assemblies)
end

function SlicedCrewSliceProvider.Render(character: Model, _payload)
	local assets = ReplicatedStorage:FindFirstChild(Config.SlicedCrew.AssetFolderName)
	local template = assets and assets:FindFirstChild(Config.SlicedCrew.TemplateName)
	if not template or not template:IsA("Model") then
		warn(("[LaserSliceSystem] Missing ReplicatedStorage.%s.%s model"):format(
			Config.SlicedCrew.AssetFolderName,
			Config.SlicedCrew.TemplateName
		))
		return nil
	end

	local clone = template:Clone()
	clone.Name = character.Name .. "_SlicedCrew"
	clone:PivotTo(character:GetPivot() * Config.SlicedCrew.PivotOffset)
	if Config.SlicedCrew.AlignBoundingBoxCenter then
		local characterBounds = character:GetBoundingBox()
		local cloneBounds = clone:GetBoundingBox()
		clone:PivotTo(clone:GetPivot() + (characterBounds.Position - cloneBounds.Position))
	end
	applyFace(clone, character)
	local assemblies = prepareAssemblies(clone)
	if #assemblies == 0 then
		clone:Destroy()
		warn("[LaserSliceSystem] SlicedCrew contains no BaseParts")
		return nil
	end
	clone.Parent = workspace

	task.delay(Config.SlicedCrew.PhysicsDelay, function()
		enablePhysics(clone, assemblies)
	end)

	if Config.Debug then
		local boundsCFrame, boundsSize = clone:GetBoundingBox()
		local visiblePartCount = 0
		for _, descendant in ipairs(clone:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Transparency < 1 then
				visiblePartCount += 1
			end
		end
		print(("[LaserSliceSystem][Client] Spawned SlicedCrew with %d falling assembly(ies), %d visible part(s), bounds %s size %s"):format(
			#assemblies,
			visiblePartCount,
			tostring(boundsCFrame.Position),
			tostring(boundsSize)
		))
		if visiblePartCount == 0 then
			warn("[LaserSliceSystem] Every BasePart in SlicedCrew has Transparency = 1")
		end
	end
	return clone
end

return SlicedCrewSliceProvider
