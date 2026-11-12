-- SnapRules.lua
local SnapRules = {}

local function q(v, step) return math.floor((v/step) + 0.5) * step end

-- Ship-local grid snap on X/Z; keep Y to a fixed deck if provided
function SnapRules.snapToGrid(cf, originCF, gridSize, plane, height)
	local localCF = originCF:ToObjectSpace(cf)
	local p = localCF.Position
	--if plane == "Horizontal" then
		p = Vector3.new(q(p.X, gridSize.X), height or p.Y, q(p.Z, gridSize.Z))
	--else
	--	p = Vector3.new(q(p.X, gridSize), q(p.Y, gridSize), q(p.Z, gridSize))
	--end
	return originCF * CFrame.new(p) * CFrame.fromMatrix(Vector3.new(), localCF.XVector, localCF.YVector, localCF.ZVector)
end

function SnapRules.quantizeYaw(cf, stepDeg)
	local pos = cf.Position
	local _, y, _ = cf:ToOrientation()
	local step = math.rad(stepDeg or 90)
	local qy = q(y, step)
	return CFrame.new(pos) * CFrame.Angles(0, qy, 0)
end

-- Rotate so the part's local +Z aligns to targetNormal (world)
function SnapRules.alignOutwardToNormal(partCF, targetNormal)
	local currentOut = partCF:VectorToWorldSpace(Vector3.new(0,0,1)).Unit
	local axis = currentOut:Cross(targetNormal)
	local d = math.clamp(currentOut:Dot(targetNormal), -1, 1)
	local ang = math.acos(d)
	if axis.Magnitude < 1e-5 or ang < 1e-5 then return partCF end
	return CFrame.fromAxisAngle(axis.Unit, ang) * partCF
end

-- Check that part’s outward (+Z) is opposite of the provided look vector (≈180°)
function SnapRules.mustFaceOpposite(partCF, targetLook, tolDeg)
	local out = partCF:VectorToWorldSpace(Vector3.new(0,0,1)).Unit
	local ang = math.deg(math.acos(math.clamp(out:Dot(targetLook.Unit), -1, 1)))
	return math.abs(ang - 180) <= (tolDeg or 8)
end

return SnapRules
