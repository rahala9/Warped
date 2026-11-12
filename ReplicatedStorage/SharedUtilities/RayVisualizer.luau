-- RayVisualizer.lua
local RayVisualizer = {}

-- Internal references
local originPart, hitPart, beam
local enabled = false

-- Setup function (called automatically once)
local function setup()
	if originPart then return end -- Already setup

	-- Origin Part
	originPart = Instance.new("Part")
	originPart.Anchored = true
	originPart.CanCollide = false
	originPart.Transparency = 1
	originPart.Size = Vector3.new(0.2, 0.2, 0.2)
	originPart.Name = "RayOriginPart"
	originPart.Parent = workspace

	-- Hit Part
	hitPart = originPart:Clone()
	hitPart.Name = "RayHitPart"
	hitPart.Parent = workspace

	-- Attachments
	local originAttachment = Instance.new("Attachment", originPart)
	local hitAttachment = Instance.new("Attachment", hitPart)

	-- Beam
	beam = Instance.new("Beam")
	beam.Attachment0 = originAttachment
	beam.Attachment1 = hitAttachment
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
	beam.Transparency = NumberSequence.new(0.3)
	beam.FaceCamera = true
	beam.LightInfluence = 0
	beam.Parent = originPart
end

-- Public API

function RayVisualizer.Enable()
	setup()
	enabled = true
	beam.Enabled = true
end

function RayVisualizer.Disable()
	enabled = false
	if beam then
		beam.Enabled = false
	end
end

function RayVisualizer.UpdateRay(origin: Vector3, direction: Vector3)
	if not enabled then return end
	--setup()

	-- Force CFrame set for attachments to update immediately
	originPart.CFrame = CFrame.new(origin)
	hitPart.CFrame = CFrame.new(origin + direction)

	-- Update beam
	beam.Enabled = true
end

return RayVisualizer
