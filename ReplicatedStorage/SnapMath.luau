-- SnapMath.lua
local SnapMath = {}

local function clampDot(x) return math.clamp(x, -1, 1) end

function SnapMath.angleBetween(a, b)
	return math.deg(math.acos(clampDot(a:Dot(b))))
end

-- Given: current part primary CF, its local socket CF, and target socket world CF
-- Returns: the part primary CF that aligns the two sockets exactly
function SnapMath.computePartCFrame(partPrimaryCF, partSocketLocalCF, targetSocketWorldCF)
	return targetSocketWorldCF * partSocketLocalCF:Inverse()
end

return SnapMath
