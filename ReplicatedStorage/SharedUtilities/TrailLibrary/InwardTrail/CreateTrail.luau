return function(Part: BasePart, Data): Trail
	
	local Lifetime = Data.Lifetime
	local Size = Data.Size
	local Color = Data.Color
	local Transparency = Data.Transparency
	
	local Attachment0 = Instance.new('Attachment')
	Attachment0.Position = Vector3.new(0, Size, 0)
	Attachment0.Parent = Part
	
	local Attachment1 = Instance.new('Attachment')
	Attachment1.Position = Vector3.new(0, -Size, 0)
	Attachment1.Parent = Part
	
	local Trail = Instance.new('Trail')
	Trail.Attachment0, Trail.Attachment1 = Attachment0, Attachment1
	Trail.LightInfluence, Trail.MinLength = 0, 0
	Trail.FaceCamera = true
	Trail.Brightness = 3.5
	Trail.Lifetime = Lifetime
	Trail.Color = ColorSequence.new(Color)
	Trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0)})
	Trail.Transparency = NumberSequence.new(Transparency)
	Trail.Parent = Attachment0
	return Trail
end