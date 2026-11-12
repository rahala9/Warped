local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PortalClass = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Portal"))
local TeleportCameraSync = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TeleportCameraSync")

local portalAPart = workspace:WaitForChild("PortalA"):WaitForChild("PortalMain")
local portalBPart = workspace:WaitForChild("PortalB"):WaitForChild("PortalMain")

local ROTATE = CFrame.Angles(0, math.pi, 0)

local TAG_A = "PortalSceneA"
local TAG_B = "PortalSceneB"

for _, name in ipairs({ "PortalGuiA", "PortalGuiB" }) do
	local oldGui = playerGui:FindFirstChild(name)
	if oldGui then
		oldGui:Destroy()
	end
end

local function makeSurfaceGui(name, adornee)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = name
	surfaceGui.Adornee = adornee
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = false
	surfaceGui.ClipsDescendants = true
	surfaceGui.LightInfluence = 0
	surfaceGui.ZOffset = 0
	surfaceGui.Parent = playerGui
	return surfaceGui
end

local surfaceGuiA = makeSurfaceGui("PortalGuiA", portalAPart)
local surfaceGuiB = makeSurfaceGui("PortalGuiB", portalBPart)

local portalA = PortalClass.new(surfaceGuiA)
local portalB = PortalClass.new(surfaceGuiB)

local function stripScripts(instance)
	for _, d in ipairs(instance:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
end

local function prepClonePart(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
end

local function clearViewportScene(portalObj)
	for _, child in ipairs(portalObj.ViewportFrame:GetChildren()) do
		child:Destroy()
	end
end

local function gatherTaggedBaseParts(tagName)
	local tagged = CollectionService:GetTagged(tagName)
	local parts = {}
	local seen = {}

	for _, obj in ipairs(tagged) do
		if obj:IsA("BasePart") then
			if not seen[obj] then
				seen[obj] = true
				table.insert(parts, obj)
			end
		else
			for _, desc in ipairs(obj:GetDescendants()) do
				if desc:IsA("BasePart") and not seen[desc] then
					seen[desc] = true
					table.insert(parts, desc)
				end
			end
		end
	end

	return parts
end

local function computeBoundsFromParts(parts)
	local minVec = Vector3.new(math.huge, math.huge, math.huge)
	local maxVec = Vector3.new(-math.huge, -math.huge, -math.huge)

	for _, part in ipairs(parts) do
		local cf = part.CFrame
		local size = part.Size
		local sx, sy, sz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5

		local corners = {
			cf * Vector3.new(sx, sy, sz),
			cf * Vector3.new(sx, sy, -sz),
			cf * Vector3.new(sx, -sy, sz),
			cf * Vector3.new(sx, -sy, -sz),
			cf * Vector3.new(-sx, sy, sz),
			cf * Vector3.new(-sx, sy, -sz),
			cf * Vector3.new(-sx, -sy, sz),
			cf * Vector3.new(-sx, -sy, -sz),
		}

		for _, p in ipairs(corners) do
			minVec = Vector3.new(
				math.min(minVec.X, p.X),
				math.min(minVec.Y, p.Y),
				math.min(minVec.Z, p.Z)
			)
			maxVec = Vector3.new(
				math.max(maxVec.X, p.X),
				math.max(maxVec.Y, p.Y),
				math.max(maxVec.Z, p.Z)
			)
		end
	end

	if #parts == 0 then
		return Vector3.zero, Vector3.new(100, 100, 100)
	end

	local center = (minVec + maxVec) * 0.5
	local size = maxVec - minVec
	return center, size
end

local function createViewportSkybox(parent, sceneParts)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		warn("No Sky found in Lighting")
		return
	end

	local center, boundsSize = computeBoundsFromParts(sceneParts)

	local pad = Vector3.new(80, 80, 80)
	local total = boundsSize + pad

	local sx = math.max(total.X, 50)
	local sy = math.max(total.Y, 50)
	local sz = math.max(total.Z, 50)

	local thickness = 4
	local hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5

	local folder = Instance.new("Folder")
	folder.Name = "ViewportSkybox"
	folder.Parent = parent

	local function makeWall(name, position, lookAtPos, upVector, wallSize, textureId, studsU, studsV)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Transparency = 1
		part.Size = wallSize
		part.CFrame = CFrame.lookAt(position, lookAtPos, upVector)
		part.Parent = folder

		local tex = Instance.new("Texture")
		tex.Face = Enum.NormalId.Front
		tex.Texture = textureId
		tex.StudsPerTileU = studsU
		tex.StudsPerTileV = studsV
		tex.Parent = part

		return part
	end

	makeWall(
		"Front",
		center + Vector3.new(0, 0, -(hz + thickness * 0.5)),
		center,
		Vector3.yAxis,
		Vector3.new(sx, sy, thickness),
		sky.SkyboxFt,
		sx, sy
	)

	makeWall(
		"Back",
		center + Vector3.new(0, 0, (hz + thickness * 0.5)),
		center,
		Vector3.yAxis,
		Vector3.new(sx, sy, thickness),
		sky.SkyboxBk,
		sx, sy
	)

	makeWall(
		"Left",
		center + Vector3.new(-(hx + thickness * 0.5), 0, 0),
		center,
		Vector3.yAxis,
		Vector3.new(sz, sy, thickness),
		sky.SkyboxLf,
		sz, sy
	)

	makeWall(
		"Right",
		center + Vector3.new((hx + thickness * 0.5), 0, 0),
		center,
		Vector3.yAxis,
		Vector3.new(sz, sy, thickness),
		sky.SkyboxRt,
		sz, sy
	)

	makeWall(
		"Up",
		center + Vector3.new(0, (hy + thickness * 0.5), 0),
		center,
		Vector3.zAxis,
		Vector3.new(sx, sz, thickness),
		sky.SkyboxUp,
		sx, sz
	)

	makeWall(
		"Down",
		center + Vector3.new(0, -(hy + thickness * 0.5), 0),
		center,
		-Vector3.zAxis,
		Vector3.new(sx, sz, thickness),
		sky.SkyboxDn,
		sx, sz
	)

	return folder
end

local function cloneSceneIntoPortal(viewPortalObj, sourceTag, sourcePortalObj, targetPortalObj)
	clearViewportScene(viewPortalObj)

	local sourceSurfaceCF = select(1, sourcePortalObj:GetSurfaceInfo())
	local targetSurfaceCF = select(1, targetPortalObj:GetSurfaceInfo())

	local sourceParts = gatherTaggedBaseParts(sourceTag)
	print("Tag", sourceTag, "resolved parts:", #sourceParts)

	local clonedParts = {}

	for _, obj in ipairs(sourceParts) do
		if obj ~= portalAPart and obj ~= portalBPart then
			local clone = obj:Clone()
			stripScripts(clone)
			prepClonePart(clone)

			local offset = sourceSurfaceCF:Inverse() * obj.CFrame
			clone.CFrame = targetSurfaceCF * ROTATE * offset

			clone.Parent = viewPortalObj.ViewportFrame
			table.insert(clonedParts, clone)
		end
	end

	createViewportSkybox(viewPortalObj.ViewportFrame, clonedParts)
end

local function rebuildPortalScenes()
	-- Assumes:
	-- PortalSceneA = things PortalA should show
	-- PortalSceneB = things PortalB should show
	cloneSceneIntoPortal(portalA, TAG_A, portalB, portalA)
	cloneSceneIntoPortal(portalB, TAG_B, portalA, portalB)
end

rebuildPortalScenes()

RunService:BindToRenderStep("PortalRender", Enum.RenderPriority.Camera.Value + 1, function()
	portalA:RenderFrame()
	portalB:RenderFrame()
end)

TeleportCameraSync.OnClientEvent:Connect(function(finalCF)
	local camera = workspace.CurrentCamera
	local character = player.Character
	if not camera or not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable

	local backDistance = 12
	local height = 4
	local lookAhead = 6

	local camPos = finalCF.Position - finalCF.LookVector * backDistance + finalCF.UpVector * height
	local lookPos = finalCF.Position + finalCF.LookVector * lookAhead

	camera.CFrame = CFrame.lookAt(camPos, lookPos, finalCF.UpVector)

	humanoid:Move(Vector3.zero, true)

	task.wait(0.1)
	camera.CameraType = Enum.CameraType.Custom
end)

print("Two-way tagged portals ready.")
print("PortalA shows PortalSceneA")
print("PortalB shows PortalSceneB")