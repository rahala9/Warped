local AssetService = game:GetService("AssetService")

local MeshSlicer = {}

local EPSILON = 0.0001
local POSE_WORLD_CFRAME_ATTRIBUTE = "_LaserSlicePoseWorldCFrame"

local function componentScale(partSize, meshSize)
	return Vector3.new(
		meshSize.X > EPSILON and partSize.X / meshSize.X or 1,
		meshSize.Y > EPSILON and partSize.Y / meshSize.Y or 1,
		meshSize.Z > EPSILON and partSize.Z / meshSize.Z or 1
	)
end

local function createEditableMesh(source: MeshPart)
	local content
	local ok = pcall(function()
		content = source.MeshContent
	end)
	if not ok or not content then
		content = Content.fromUri(source.MeshId)
	end

	return AssetService:CreateEditableMeshAsync(content, { FixedSize = false })
end

local function scaledCFrame(cframe, scale)
	return CFrame.fromMatrix(
		cframe.Position * scale,
		cframe.XVector,
		cframe.YVector,
		cframe.ZVector
	)
end

local function bakeCurrentSkinnedPose(editable, source: MeshPart, scale)
	local boneIds = editable:GetBones()
	if #boneIds == 0 then
		return 0
	end

	local rigRoot: Instance = source
	local current = source.Parent
	while current do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			rigRoot = current
			break
		end
		current = current.Parent
	end

	local instanceBones = {}
	-- Prefer the bone hierarchy belonging to this MeshPart. Some avatar rigs have
	-- repeated bone names in layered clothing, so a rig-wide name lookup alone
	-- can select a different layer's bone and bake the wrong pose.
	for _, descendant in ipairs(source:GetDescendants()) do
		if descendant:IsA("Bone") then
			instanceBones[descendant.Name] = descendant
		end
	end
	for _, descendant in ipairs(rigRoot:GetDescendants()) do
		if descendant:IsA("Bone") and instanceBones[descendant.Name] == nil then
			instanceBones[descendant.Name] = descendant
		end
	end
	if next(instanceBones) == nil then
		return 0
	end

	local bakedVertexCount = 0
	for _, vertexId in ipairs(editable:GetVertices()) do
		local influencingBones = editable:GetVertexBones(vertexId)
		local weights = editable:GetVertexBoneWeights(vertexId)
		if #influencingBones > 0 then
			local originalStuds = editable:GetPosition(vertexId) * scale
			local posedStuds = Vector3.zero
			local appliedWeight = 0

			for index, boneId in ipairs(influencingBones) do
				local weight = weights[index] or 0
				local bone = instanceBones[editable:GetBoneName(boneId)]
				if bone and weight > 0 then
					local bindInPart = scaledCFrame(editable:GetBoneCFrame(boneId), scale)
					local posedWorld = bone:GetAttribute(POSE_WORLD_CFRAME_ATTRIBUTE)
					if typeof(posedWorld) ~= "CFrame" then
						posedWorld = bone.TransformedWorldCFrame
					end
					local posedInPart = source.CFrame:ToObjectSpace(posedWorld)
					local deformation = posedInPart * bindInPart:Inverse()
					posedStuds += deformation:PointToWorldSpace(originalStuds) * weight
					appliedWeight += weight
				end
			end

			if appliedWeight > 0 then
				if appliedWeight < 1 then
					posedStuds += originalStuds * (1 - appliedWeight)
				end
				editable:SetPosition(vertexId, posedStuds / scale)
				bakedVertexCount += 1
			end
			-- The baked vertex must no longer be influenced by the live rig.
			pcall(function()
				editable:SetVertexBones(vertexId, {})
				editable:SetVertexBoneWeights(vertexId, {})
			end)
		end
	end

	-- The generated corpse is a static snapshot. Removing bones prevents it from
	-- snapping back to the bind pose when no matching Bone instances are present.
	for index = #boneIds, 1, -1 do
		pcall(editable.RemoveBone, editable, boneIds[index])
	end
	for _, normalId in ipairs(editable:GetNormals()) do
		editable:ResetNormal(normalId)
	end
	return bakedVertexCount
end

local function interpolate(a, b, alpha)
	return {
		position = a.position:Lerp(b.position, alpha),
		uv = a.uv:Lerp(b.uv, alpha),
	}
end

local function clipPolygon(polygon, boundaryY, keepAbove, worldY, intersections)
	if #polygon == 0 then
		return polygon
	end

	local function isInside(y)
		if keepAbove then
			return y >= boundaryY - EPSILON
		end
		return y <= boundaryY + EPSILON
	end

	local output = {}
	local previous = polygon[#polygon]
	local previousY = worldY(previous.position)
	local previousInside = isInside(previousY)

	for _, current in ipairs(polygon) do
		local currentY = worldY(current.position)
		local currentInside = isInside(currentY)

		if currentInside ~= previousInside then
			local denominator = currentY - previousY
			if math.abs(denominator) > EPSILON then
				local alpha = math.clamp((boundaryY - previousY) / denominator, 0, 1)
				local intersection = interpolate(previous, current, alpha)
				table.insert(output, intersection)
				table.insert(intersections, intersection.position)
			end
		end

		if currentInside then
			table.insert(output, current)
		end

		previous = current
		previousY = currentY
		previousInside = currentInside
	end

	return output
end

local function addPolygon(editable, polygon)
	if #polygon < 3 then
		return
	end

	local vertexIds = {}
	local uvIds = {}
	for _, vertex in ipairs(polygon) do
		table.insert(vertexIds, editable:AddVertex(vertex.position))
		table.insert(uvIds, editable:AddUV(vertex.uv))
	end

	for index = 2, #vertexIds - 1 do
		local faceId = editable:AddTriangle(vertexIds[1], vertexIds[index], vertexIds[index + 1])
		editable:SetFaceUVs(faceId, { uvIds[1], uvIds[index], uvIds[index + 1] })
	end
end

local function deduplicatePoints(points, tolerance)
	local unique = {}
	for _, point in ipairs(points) do
		local duplicate = false
		for _, existing in ipairs(unique) do
			if (existing - point).Magnitude <= tolerance then
				duplicate = true
				break
			end
		end
		if not duplicate then
			table.insert(unique, point)
		end
	end
	return unique
end

local function addCapContour(editable, points, source, scale, upward)
	points = deduplicatePoints(points, 0.002)
	if #points < 3 then
		return
	end

	local center = Vector3.zero
	for _, point in ipairs(points) do
		center += point
	end
	center /= #points

	table.sort(points, function(a, b)
		local worldA = source.CFrame:PointToWorldSpace(a * scale)
		local worldB = source.CFrame:PointToWorldSpace(b * scale)
		local worldCenter = source.CFrame:PointToWorldSpace(center * scale)
		return math.atan2(worldA.Z - worldCenter.Z, worldA.X - worldCenter.X)
			< math.atan2(worldB.Z - worldCenter.Z, worldB.X - worldCenter.X)
	end)

	local centerId = editable:AddVertex(center)
	local centerUv = editable:AddUV(Vector2.new(0.5, 0.5))
	local pointIds = {}
	local uvIds = {}
	for _, point in ipairs(points) do
		table.insert(pointIds, editable:AddVertex(point))
		local delta = point - center
		table.insert(uvIds, editable:AddUV(Vector2.new(0.5 + delta.X, 0.5 + delta.Z)))
	end

	for index = 1, #pointIds do
		local nextIndex = index % #pointIds + 1
		local a = pointIds[index]
		local b = pointIds[nextIndex]
		local faceId
		local faceUvs
		if upward then
			faceId = editable:AddTriangle(centerId, a, b)
			faceUvs = { centerUv, uvIds[index], uvIds[nextIndex] }
		else
			faceId = editable:AddTriangle(centerId, b, a)
			faceUvs = { centerUv, uvIds[nextIndex], uvIds[index] }
		end
		editable:SetFaceUVs(faceId, faceUvs)
	end
end

local function appendIntersectionSegment(segments, points)
	local unique = deduplicatePoints(points, 0.002)
	if #unique >= 2 then
		table.insert(segments, { unique[1], unique[2] })
	end
end

local function addCaps(editable, segments, source, scale, upward)
	-- A horizontal plane can cross several disconnected surfaces (for example,
	-- both legs). Filling every intersection around one center bridges those
	-- surfaces with long triangles. Build connected contour groups from the
	-- per-face intersection segments and cap each group independently.
	local nodes = {}
	local parents = {}

	local function findNode(point)
		for index, existing in ipairs(nodes) do
			if (existing - point).Magnitude <= 0.002 then
				return index
			end
		end
		table.insert(nodes, point)
		table.insert(parents, #nodes)
		return #nodes
	end

	local function root(index)
		while parents[index] ~= index do
			parents[index] = parents[parents[index]]
			index = parents[index]
		end
		return index
	end

	local function union(a, b)
		a = root(a)
		b = root(b)
		if a ~= b then
			parents[b] = a
		end
	end

	for _, segment in ipairs(segments) do
		local a = findNode(segment[1])
		local b = findNode(segment[2])
		union(a, b)
	end

	local contours = {}
	for index, point in ipairs(nodes) do
		local contourRoot = root(index)
		contours[contourRoot] = contours[contourRoot] or {}
		table.insert(contours[contourRoot], point)
	end
	for _, points in pairs(contours) do
		addCapContour(editable, points, source, scale, upward)
	end
end

local function copyAppearance(source: MeshPart, generated: MeshPart, scale)
	generated.Name = source.Name .. "_LaserSlice"
	generated.CFrame = source.CFrame
	generated.Size = generated.MeshSize * scale
	generated.Color = source.Color
	generated.Material = source.Material
	generated.MaterialVariant = source.MaterialVariant
	generated.Reflectance = source.Reflectance
	generated.Transparency = source.Transparency
	generated.CastShadow = source.CastShadow
	generated.DoubleSided = true
	generated.Anchored = true
	generated.CanCollide = false
	generated.CanQuery = false
	generated.CanTouch = false
	generated.Massless = true

	pcall(function()
		generated.TextureID = source.TextureID
	end)

	local surfaceAppearance = source:FindFirstChildOfClass("SurfaceAppearance")
	if surfaceAppearance then
		surfaceAppearance:Clone().Parent = generated
	end
end

local function buildBand(source: MeshPart, lowerY, upperY, bandIndex, config)
	local editable = createEditableMesh(source)
	if not editable then
		return nil
	end

	editable:Triangulate()
	local sourceMeshSize = source.MeshSize
	local scale = componentScale(source.Size, sourceMeshSize)
	local poseBakedVertexCount = bakeCurrentSkinnedPose(editable, source, scale)
	local function worldY(position)
		return source.CFrame:PointToWorldSpace(position * scale).Y
	end

	local lowerSegments = {}
	local upperSegments = {}
	local faces = editable:GetFaces()
	for _, faceId in ipairs(faces) do
		local vertexIds = editable:GetFaceVertices(faceId)
		local uvIds = editable:GetFaceUVs(faceId)
		local polygon = {}
		for index, vertexId in ipairs(vertexIds) do
			table.insert(polygon, {
				position = editable:GetPosition(vertexId),
				uv = editable:GetUV(uvIds[index]) or Vector2.zero,
			})
		end

		local clipped = polygon
		local changed = false
		for _, vertex in ipairs(polygon) do
			local y = worldY(vertex.position)
			if (lowerY and y < lowerY - EPSILON) or (upperY and y > upperY + EPSILON) then
				changed = true
				break
			end
		end
		if lowerY then
			local intersections = {}
			clipped = clipPolygon(clipped, lowerY, true, worldY, intersections)
			appendIntersectionSegment(lowerSegments, intersections)
		end
		if upperY then
			local intersections = {}
			clipped = clipPolygon(clipped, upperY, false, worldY, intersections)
			appendIntersectionSegment(upperSegments, intersections)
		end

		if changed then
			editable:RemoveFace(faceId)
			addPolygon(editable, clipped)
		end
	end

	if lowerY then
		addCaps(editable, lowerSegments, source, scale, false)
	end
	if upperY then
		addCaps(editable, upperSegments, source, scale, true)
	end
	editable:RemoveUnused()

	local generated = AssetService:CreateMeshPartAsync(Content.fromObject(editable), {
		CollisionFidelity = config.CollisionFidelity,
		RenderFidelity = config.RenderFidelity,
	})
	copyAppearance(source, generated, scale)
	generated:SetAttribute("LaserSliceBand", bandIndex)
	generated:SetAttribute("PoseBaked", poseBakedVertexCount > 0)
	generated:SetAttribute("PoseBakedVertexCount", poseBakedVertexCount)
	-- The MeshPart remains linked to this EditableMesh. Destroying it here leaves
	-- a correctly sized MeshPart with no renderable body. The MeshPart retains the
	-- content for its lifetime and releases it when the effect is destroyed.
	return generated
end

function MeshSlicer.Slice(source: MeshPart, planes, parent: Instance, config)
	local relevant = {}
	local half = source.Size * 0.5
	local minY = math.huge
	local maxY = -math.huge
	for _, x in ipairs({ -half.X, half.X }) do
		for _, y in ipairs({ -half.Y, half.Y }) do
			for _, z in ipairs({ -half.Z, half.Z }) do
				local worldY = source.CFrame:PointToWorldSpace(Vector3.new(x, y, z)).Y
				minY = math.min(minY, worldY)
				maxY = math.max(maxY, worldY)
			end
		end
	end
	for _, planeY in ipairs(planes) do
		if planeY > minY and planeY < maxY then
			table.insert(relevant, planeY)
		end
	end
	table.sort(relevant)
	-- The same physical laser can be reported by more than one touching kill
	-- volume. Duplicate planes would otherwise create zero-width/repeated bands.
	local uniqueRelevant = {}
	for _, planeY in ipairs(relevant) do
		if #uniqueRelevant == 0 or math.abs(planeY - uniqueRelevant[#uniqueRelevant]) > EPSILON then
			table.insert(uniqueRelevant, planeY)
		end
	end
	relevant = uniqueRelevant

	if #relevant == 0 then
		return false
	end

	local bandCount = #relevant + 1
	local generatedCount = 0
	for bandIndex = 1, bandCount do
		local lowerY = bandIndex > 1 and relevant[bandIndex - 1] or nil
		local upperY = bandIndex <= #relevant and relevant[bandIndex] or nil
		local ok, generated = pcall(buildBand, source, lowerY, upperY, bandIndex, config)
		if ok and generated then
			local middle = (bandCount + 1) * 0.5
			generated.CFrame += Vector3.new(0, (bandIndex - middle) * config.CutGap, 0)
			generated.Parent = parent
			generatedCount += 1
		else
			warn("[LaserSliceSystem] Could not slice", source:GetFullName(), generated)
		end
	end
	return generatedCount > 0
end

return MeshSlicer
