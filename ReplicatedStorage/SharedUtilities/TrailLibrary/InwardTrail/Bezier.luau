-- Functions
local function Lerp(a, b, c)
	return a + (b - a) * c
end

return {
	QuadBezier = function(t, p0, p1, p2)
		local l1    = Lerp(p0, p1, t)
		local l2    = Lerp(p1, p2, t)
		return Lerp(l1, l2, t)
	end,
}