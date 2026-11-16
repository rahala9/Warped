-- Install this file as a local Studio plugin. Select the character model and its
-- laser door together, then press "Bake Selected". This is intentionally kept
-- outside the runtime service folders so it can be removed from production.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")

local toolbar = plugin:CreateToolbar("Warped Laser Slices")
local bakeButton = toolbar:CreateButton(
	"BakeLaserSlices",
	"Bake the selected character at the selected laser door's beam heights",
	"rbxassetid://4458901886",
	"Bake Selected"
)
local bakeExistingButton = toolbar:CreateButton(
	"BakeExistingLaserSlices",
	"Upload the selected runtime laser slices as a permanent baked template",
	"rbxassetid://4458901886",
	"Bake Existing"
)

local statusWidget = plugin:CreateDockWidgetPluginGui(
	"WarpedLaserSliceBakerStatus",
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		460,
		150,
		320,
		100
	)
)
statusWidget.Title = "Warped Laser Slice Baker"

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.fromScale(1, 1)
statusLabel.BackgroundColor3 = Color3.fromRGB(28, 30, 34)
statusLabel.BorderSizePixel = 0
statusLabel.TextColor3 = Color3.fromRGB(225, 230, 235)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Text = "Ready. Select a generated slice model, then press Bake Existing."
statusLabel.Parent = statusWidget

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = statusLabel

local function setStatus(message, failed)
	statusLabel.Text = message
	statusLabel.TextColor3 = failed
		and Color3.fromRGB(255, 125, 125)
		or Color3.fromRGB(225, 230, 235)
	statusWidget.Enabled = true
	print("[LaserSliceBaker] " .. message)
end

print("[LaserSliceBaker] Plugin loaded")

local function findSelection()
	local character
	local laserSource
	for _, selected in ipairs(Selection:Get()) do
		local current = selected
		while current and current ~= game do
			if current:IsA("Model") then
				if not character and current:FindFirstChildWhichIsA("Humanoid", true) then
					character = current
				end
				if not laserSource and current:FindFirstChild("LaserBeamWall", true) then
					laserSource = current
				end
			end
			current = current.Parent
		end
	end
	return character, laserSource
end

local function getPlanes(laserSource)
	local planes = {}
	local wall = laserSource:FindFirstChild("LaserBeamWall", true)
	for _, child in ipairs(wall:GetChildren()) do
		if child:IsA("Model") and child.Name == "LaserBeam" then
			local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
			if part then
				table.insert(planes, part.Position.Y)
			end
		end
	end
	table.sort(planes)
	return planes
end

local function copyPartProperties(source, target)
	target.Name = source.Name
	target.CFrame = source.CFrame
	target.Size = source.Size
	target.Color = source.Color
	target.Material = source.Material
	target.MaterialVariant = source.MaterialVariant
	target.Reflectance = source.Reflectance
	target.Transparency = source.Transparency
	target.CastShadow = source.CastShadow
	target.DoubleSided = source.DoubleSided
	target.Anchored = true
	target.CanCollide = false
	target.CanTouch = false
	target.CanQuery = false
	local appearance = source:FindFirstChildOfClass("SurfaceAppearance")
	if appearance then
		appearance:Clone().Parent = target
	end
	pcall(function()
		target.TextureID = source.TextureID
	end)
end

local function creatorParameters(assetName)
	local creatorType = game.CreatorType == Enum.CreatorType.Group
		and Enum.AssetCreatorType.Group
		or Enum.AssetCreatorType.User
	return {
		CreatorId = game.CreatorId,
		CreatorType = creatorType,
		Name = assetName,
		Description = "Baked laser-slice mesh for Warped",
	}
end

local function uploadMesh(part, assetName)
	local meshContent = part.MeshContent
	local editable = meshContent and meshContent.Object
	local ownsEditable = false
	if not editable or not editable:IsA("EditableMesh") then
		-- Asset-backed meshes do not expose an Object. This fallback uses a
		-- fixed-size copy, which consumes substantially less memory.
		local readOk, result = pcall(
			AssetService.CreateEditableMeshAsync,
			AssetService,
			meshContent,
			{ FixedSize = true }
		)
		if not readOk then
			error(("Could not read mesh geometry from %s: %s"):format(part:GetFullName(), tostring(result)))
		end
		editable = result
		ownsEditable = true
	end
	if not editable then
		error(("%s has no live mesh geometry. Restart the playtest and bake a newly generated result."):format(
			part:GetFullName()
		))
	end
	local permanentContent
	local assetId
	local uploadOk, uploadResult, uploadedId = pcall(function()
		return AssetService:CreateAssetAsync(
			editable,
			Enum.AssetType.Mesh,
			creatorParameters(assetName)
		)
	end)
	if uploadOk and uploadResult == Enum.CreateAssetResult.Success then
		assetId = uploadedId
		permanentContent = Content.fromAssetId(assetId)
	else
		if RunService:IsRunning() then
			error(("Cloud mesh upload is unavailable in this Studio build (%s). Use Bake Selected in Edit mode so the meshes can be baked directly into the place."):format(
				tostring(uploadResult)
			))
		end

		setStatus(("Cloud upload unavailable; baking %s directly into this place..."):format(part.Name), false)
		local bakeOk, bakeResult, bakedContent = pcall(function()
			return AssetService:CreateDataModelContentAsync(Content.fromObject(editable))
		end)
		if not bakeOk then
			error(("DataModel mesh bake failed for %s: %s"):format(part.Name, tostring(bakeResult)))
		end
		if bakeResult ~= Enum.CreateContentResult.Success then
			error(("DataModel mesh bake failed for %s: %s"):format(part.Name, tostring(bakeResult)))
		end
		permanentContent = bakedContent
	end
	if ownsEditable then
		editable:Destroy()
	end

	local permanent = AssetService:CreateMeshPartAsync(permanentContent, {
		CollisionFidelity = Enum.CollisionFidelity.Hull,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})
	copyPartProperties(part, permanent)
	if assetId then
		permanent:SetAttribute("BakedMeshAssetId", assetId)
	else
		permanent:SetAttribute("BakedIntoDataModel", true)
	end
	return permanent
end

local function getDynamicProvider()
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local system = scripts:WaitForChild("SharedClientScripts"):WaitForChild("LaserSliceSystem")
	return require(system:WaitForChild("Providers"):WaitForChild("DynamicSliceProvider"))
end

local function getTemplatesFolder()
	local sharedFolder = ReplicatedStorage:WaitForChild("LaserSliceSystem")
	local templates = sharedFolder:FindFirstChild("BakedTemplates")
	if not templates then
		templates = Instance.new("Folder")
		templates.Name = "BakedTemplates"
		templates.Parent = sharedFolder
	end
	return templates
end

local function installTemplate(permanentModel, templateKey)
	local templates = getTemplatesFolder()
	local existing = templates:FindFirstChild(templateKey)
	if existing then
		existing:Destroy()
	end
	permanentModel.Parent = templates
	Selection:Set({ permanentModel })
end

local function uploadGeneratedModel(generated, templateKey)
	local permanentModel = Instance.new("Model")
	permanentModel.Name = templateKey
	local meshIndex = 0
	local meshTotal = 0
	for _, child in ipairs(generated:GetChildren()) do
		if child:IsA("MeshPart") and child.Name:find("_LaserSlice") then
			meshTotal += 1
		end
	end
	if meshTotal == 0 then
		permanentModel:Destroy()
		error("The selected model contains no temporary _LaserSlice MeshParts")
	end

	for _, child in ipairs(generated:GetChildren()) do
		if child:IsA("MeshPart") and child.Name:find("_LaserSlice") then
			meshIndex += 1
			setStatus(("Uploading mesh %d of %d: %s"):format(meshIndex, meshTotal, child.Name), false)
			local uploaded = uploadMesh(child, (`{templateKey}_{meshIndex}`))
			uploaded.Parent = permanentModel
		elseif child:IsA("BasePart") then
			local clone = child:Clone()
			clone.Anchored = true
			clone.Parent = permanentModel
		end
	end

	permanentModel.WorldPivot = generated:GetPivot()
	installTemplate(permanentModel, templateKey)
	return permanentModel, meshIndex
end

local function bake()
	setStatus("Bake Selected started. Checking character and laser-door selection...", false)
	local character, laserSource = findSelection()
	if not character or not laserSource then
		error("Select one character model and one LaserDoor model")
	end

	local planes = getPlanes(laserSource)
	if #planes == 0 then
		error("The selected laser door has no LaserBeam models")
	end

	local ok, generated = pcall(getDynamicProvider().Render, character, {
		SlicePlanes = planes,
		Source = laserSource.Name,
	})
	if not ok or not generated then
		error("Dynamic generation failed: " .. tostring(generated))
	end

	local templateKey = laserSource:GetAttribute("LaserSliceTemplate") or "Default"
	generated.WorldPivot = character:GetPivot()
	local permanentModel, meshIndex = uploadGeneratedModel(generated, templateKey)
	generated:Destroy()
	setStatus(("Success: baked %d permanent meshes into BakedTemplates/%s"):format(meshIndex, permanentModel.Name), false)
	print(("[LaserSliceBaker] Baked %d meshes into template %s"):format(meshIndex, templateKey))
end

local function bakeExisting()
	setStatus("Bake Existing started. Checking the selected model...", false)
	local selected = Selection:Get()
	if #selected ~= 1 or not selected[1]:IsA("Model") then
		error("Select exactly one generated laser-slice Model")
	end

	local generated = selected[1]
	local templateKey = generated:GetAttribute("LaserSliceTemplate") or "Default"
	local permanentModel, meshIndex = uploadGeneratedModel(generated, templateKey)
	setStatus(("Success: uploaded %d permanent meshes into BakedTemplates/%s. Before stopping Play, right-click that model and Save to File."):format(
		meshIndex,
		permanentModel.Name
	), false)
	print(("[LaserSliceBaker] Uploaded %d existing meshes into template %s"):format(
		meshIndex,
		permanentModel.Name
	))
end

bakeButton.Click:Connect(function()
	local ok, message = pcall(bake)
	if not ok then
		setStatus("Bake Selected failed: " .. tostring(message), true)
		warn("[LaserSliceBaker]", message)
	end
end)

bakeExistingButton.Click:Connect(function()
	local ok, message = pcall(bakeExisting)
	if not ok then
		setStatus("Bake Existing failed: " .. tostring(message), true)
		warn("[LaserSliceBaker]", message)
	end
end)
