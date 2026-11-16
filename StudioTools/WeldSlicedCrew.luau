-- Run this once from the Roblox Studio Command Bar in Edit mode.
-- It welds every BasePart inside each direct PartX model to that model's
-- largest non-searing part, while leaving separate PartX models independent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assets = ReplicatedStorage:FindFirstChild("SharedClientAssets")
assert(assets, "Missing ReplicatedStorage.SharedClientAssets")

local slicedCrew = assets:FindFirstChild("SlicedCrew")
assert(slicedCrew and slicedCrew:IsA("Model"), "Missing SharedClientAssets.SlicedCrew Model")

local WELD_NAME = "SlicedCrewWeld"

local function isSearPart(part)
	return part:GetAttribute("WarpedLaserSear") == true
		or string.find(string.lower(part.Name), "sear", 1, true) ~= nil
		or part.Material == Enum.Material.Neon
end

local function chooseRoot(parts)
	local best
	local bestVolume = -1
	for _, part in ipairs(parts) do
		local volume = part.Size.X * part.Size.Y * part.Size.Z
		if not isSearPart(part) and volume > bestVolume then
			best = part
			bestVolume = volume
		end
	end
	return best or parts[1]
end

local modelCount = 0
local partCount = 0
local weldCount = 0

for _, group in ipairs(slicedCrew:GetChildren()) do
	if group:IsA("Model") and group.Name:match("^Part%d+$") then
		local parts = {}
		for _, descendant in ipairs(group:GetDescendants()) do
			if descendant:IsA("WeldConstraint") and descendant.Name == WELD_NAME then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				table.insert(parts, descendant)
			end
		end

		if #parts == 0 then
			warn(("[SlicedCrewWeld] %s contains no BaseParts"):format(group:GetFullName()))
		else
			local root = chooseRoot(parts)
			group.PrimaryPart = root
			group:SetAttribute("SlicedCrewAssembly", true)

			for _, part in ipairs(parts) do
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.Massless = part ~= root

				if part ~= root then
					local weld = Instance.new("WeldConstraint")
					weld.Name = WELD_NAME
					weld.Part0 = root
					weld.Part1 = part
					weld.Parent = root
					weldCount += 1
				end
			end

			root.CanCollide = true
			root.CanQuery = true
			root.Massless = false
			modelCount += 1
			partCount += #parts
			print(("[SlicedCrewWeld] %s: root=%s, parts=%d"):format(
				group.Name,
				root.Name,
				#parts
			))
		end
	end
end

assert(modelCount > 0, "SlicedCrew has no direct child Models named Part1, Part2, etc.")

local faceTop = slicedCrew:FindFirstChild("FaceTop", true)
local faceBottom = slicedCrew:FindFirstChild("FaceBottom", true)
if not faceTop or not faceTop:IsA("BasePart") then
	warn("[SlicedCrewWeld] FaceTop BasePart was not found recursively")
end
if not faceBottom or not faceBottom:IsA("BasePart") then
	warn("[SlicedCrewWeld] FaceBottom BasePart was not found recursively")
end

local boundsCFrame, boundsSize = slicedCrew:GetBoundingBox()
print(("[SlicedCrewWeld] COMPLETE: %d PartX models, %d BaseParts, %d welds"):format(
	modelCount,
	partCount,
	weldCount
))
print(("[SlicedCrewWeld] Bounds center=%s size=%s pivot=%s"):format(
	tostring(boundsCFrame.Position),
	tostring(boundsSize),
	tostring(slicedCrew:GetPivot().Position)
))
