local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("LaserSliceSystem")
local Config = require(sharedFolder:WaitForChild("Config"))
local EquipmentRules = require(sharedFolder:WaitForChild("EquipmentRules"))
local MeshSlicer = require(script.Parent.Parent:WaitForChild("MeshSlicer"))

local DynamicSliceProvider = {}

local random = Random.new()

local function sanitizeClone(part: BasePart)
	local clone = part:Clone()
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("JointInstance")
			or descendant:IsA("Constraint")
			or descendant:IsA("Script")
			or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanTouch = false
	clone.CanQuery = false
	return clone
end

local function enablePhysics(effectModel)
	if not effectModel.Parent then
		return
	end

	for _, descendant in ipairs(effectModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanQuery = true
			descendant.CanTouch = false
			descendant.AssemblyLinearVelocity = Vector3.new(
				random:NextNumber(-2, 2),
				random:NextNumber(Config.Dynamic.MinimumFallVelocity, Config.Dynamic.MaximumFallVelocity),
				random:NextNumber(-2, 2)
			)
			descendant.AssemblyAngularVelocity = Vector3.new(
				random:NextNumber(-Config.Dynamic.MaximumAngularVelocity, Config.Dynamic.MaximumAngularVelocity),
				random:NextNumber(-Config.Dynamic.MaximumAngularVelocity, Config.Dynamic.MaximumAngularVelocity),
				random:NextNumber(-Config.Dynamic.MaximumAngularVelocity, Config.Dynamic.MaximumAngularVelocity)
			)
		end
	end
end

function DynamicSliceProvider.Render(character: Model, payload)
	local effectModel = Instance.new("Model")
	effectModel.Name = character.Name .. "_DynamicLaserSlices"

	local renderedCount = 0
	local slicedMeshCount = 0
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			local behavior = EquipmentRules.GetBehavior(descendant)
			if behavior ~= "Hide" then
				local sliced = false
				local maySliceEquipment = Config.Dynamic.SliceEquipment or behavior == "Slice"
				if descendant:IsA("MeshPart") and maySliceEquipment and behavior ~= "Drop" and behavior ~= "Detach" then
					sliced = MeshSlicer.Slice(descendant, payload.SlicePlanes, effectModel, {
						CollisionFidelity = Config.Dynamic.CollisionFidelity,
						RenderFidelity = Config.Dynamic.RenderFidelity,
						CutGap = Config.CutGap,
					})
				end

				if not sliced then
					local clone = sanitizeClone(descendant)
					clone.Parent = effectModel
				end
				if sliced then
					slicedMeshCount += 1
				end
				renderedCount += 1
			end
		end
	end

	if renderedCount == 0 then
		effectModel:Destroy()
		return nil
	end

	-- Preserve the victim's root pivot so an inspected runtime result can be
	-- uploaded by the Studio baker and later aligned to another character.
	effectModel.WorldPivot = character:GetPivot()
	effectModel:SetAttribute("LaserSliceTemplate", payload.TemplateKey or Config.Baked.DefaultTemplate)
	effectModel.Parent = workspace
	if Config.Dynamic.EnablePhysics then
		task.delay(Config.Dynamic.PhysicsDelay, function()
			enablePhysics(effectModel)
		end)
	end
	effectModel:SetAttribute("SlicedMeshCount", slicedMeshCount)
	effectModel:SetAttribute("SourcePartCount", renderedCount)
	if Config.Debug then
		local poseBakedPartCount = 0
		local poseBakedVertexCount = 0
		for _, descendant in ipairs(effectModel:GetDescendants()) do
			if descendant:IsA("MeshPart") and descendant:GetAttribute("PoseBaked") == true then
				poseBakedPartCount += 1
				poseBakedVertexCount += descendant:GetAttribute("PoseBakedVertexCount") or 0
			end
		end
		local sourceCFrame, sourceSize = character:GetBoundingBox()
		local resultCFrame, resultSize = effectModel:GetBoundingBox()
		print(("[LaserSliceSystem][Client] Dynamic result: %d sliced mesh(es), %d source part(s)"):format(
			slicedMeshCount,
			renderedCount
		))
		print(("[LaserSliceSystem][Client] Bounds source=%s size=%s result=%s size=%s offset=%.2f"):format(
			tostring(sourceCFrame.Position),
			tostring(sourceSize),
			tostring(resultCFrame.Position),
			tostring(resultSize),
			(resultCFrame.Position - sourceCFrame.Position).Magnitude
		))
		print(("[LaserSliceSystem][Client] Pose baked %d generated part(s), %d vertices"):format(
			poseBakedPartCount,
			poseBakedVertexCount
		))

		local highlight = Instance.new("Highlight")
		highlight.Name = "LaserSliceDebugHighlight"
		highlight.FillTransparency = 0.9
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = effectModel
	end
	return effectModel
end

return DynamicSliceProvider
