local UP = Vector3.new(0, 1, 0)
local FOV120 = math.rad(120)
local PI2 = math.pi/2

local VPF = Instance.new("ViewportFrame")
VPF.Size = UDim2.new(1, 0, 1, 0)
VPF.Position = UDim2.new(0.5, 0, 0.5, 0)
VPF.AnchorPoint = Vector2.new(0.5, 0.5)
VPF.BackgroundTransparency = 1

--

local Portal = {}
Portal.__index = Portal

--

function Portal.new(surfaceGUI)
	local self = setmetatable({}, Portal)

	self.SurfaceGUI = surfaceGUI
	self.Camera = Instance.new("Camera", surfaceGUI)
	self.ViewportFrame = VPF:Clone()
	self.ViewportFrame.CurrentCamera = self.Camera
	self.ViewportFrame.Parent = surfaceGUI

	return self
end

--

function Portal:GetSurfaceInfo()
	local part = self.SurfaceGUI.Adornee
	local partCF, partSize = part.CFrame, part.Size

	local back = -Vector3.FromNormalId(self.SurfaceGUI.Face)
	local axis = (math.abs(back.y) == 1) and Vector3.new(back.y, 0, 0) or UP
	local right = CFrame.fromAxisAngle(axis, PI2) * back
	local top = back:Cross(right).Unit

	local cf = partCF * CFrame.fromMatrix(-back*partSize/2, right, top, back)
	local size = Vector2.new((partSize * right).Magnitude, (partSize * top).Magnitude)

	return cf, size
end

function Portal:RenderFrame()
	local vpf = self.ViewportFrame
	local surfaceGUI = self.SurfaceGUI
	local camera = game.Workspace.CurrentCamera
	local nCamera = self.Camera

	local camCF = camera.CFrame
	local surfaceCF, surfaceSize = self:GetSurfaceInfo()
	local viewportSizeY = camera.ViewportSize.y

	local rPoint = surfaceCF:PointToObjectSpace(camCF.p)
	local sX, sY = rPoint.x / surfaceSize.x, rPoint.y / surfaceSize.y 

	local scaleX = 1 + math.abs(sX)*2
	local scaleY = 1 + math.abs(sY)*2
	local scale = math.sqrt(scaleX*scaleX + scaleY*scaleY)

	local rDist = (camCF.p - surfaceCF.p):Dot(surfaceCF.LookVector)
	local newFov = 2*math.atan2(surfaceSize.y/2, rDist)
	local clampedFov = math.clamp(math.deg(newFov), 1, 120)
	local pDist = surfaceSize.y/2 / math.tan(math.rad(clampedFov)/2)
	local adjust = rDist / pDist

	local factor = (newFov > FOV120 and adjust or 1) / scale
	local scaleCF = CFrame.new(0, 0, 0, factor, 0, 0, 0, factor, 0, 0, 0, 1)

	vpf.Position = UDim2.new(vpf.AnchorPoint.x - sX, 0, vpf.AnchorPoint.y - sY, 0)
	vpf.Size = UDim2.new(scale, 0, scale, 0)
	vpf.BackgroundColor3 = surfaceGUI.Adornee.Color

	surfaceGUI.CanvasSize = Vector2.new(viewportSizeY*(surfaceSize.x/surfaceSize.y), viewportSizeY)

	nCamera.FieldOfView = clampedFov
	nCamera.CFrame = CFrame.new(camCF.p) * (surfaceCF - surfaceCF.p) * CFrame.Angles(0, math.pi, 0) * scaleCF
end

--

return Portal