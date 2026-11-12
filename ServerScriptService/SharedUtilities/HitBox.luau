local Hitbox = {}

function Hitbox:Start(Origin: Vector3, Direction: Vector3, Exclude: table, Visualizer: boolean)
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = Exclude

	if Visualizer then
		local Part = Instance.new('Part')
		Part.Position = Origin + Direction
		Part.Anchored, Part.CanCollide = true, false
		Part.Transparency = 0.5
		Part.Size = Vector3.one
		Part.Parent = workspace.Effects
		game:GetService('Debris'):AddItem(Part, 0.35)
	end

	return workspace:Raycast(Origin, Direction, RayParams)
end

return Hitbox
