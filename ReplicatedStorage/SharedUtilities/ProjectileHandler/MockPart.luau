return function(Name, CF)
	local Part = Instance.new('Part')
	Part.Name = Name or 'MockPart'
	Part.Anchored, Part.CanCollide, Part.CanTouch, Part.CanQuery = true, false, false, false
	Part.CFrame, Part.Size = CF, Vector3.one
	Part.Transparency = 1
	Part.Parent = workspace.Effects
	return Part
end