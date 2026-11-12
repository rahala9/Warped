-- Localization
local Random = Random.new()

-- Functions
local function GetXAndZPositions(Angle: number, Radius: number)
	local X = math.cos(Angle) * Radius
	local Z = math.sin(Angle) * Radius
	return X, Z
end

local Module = { }

function Module:Emit(Attachment: Attachment)
	for _, Particle in ipairs(Attachment:GetChildren()) do
		if Particle:IsA('ParticleEmitter') then
			Particle:Emit(Particle:GetAttribute('EmitCount') or 1)
		end
	end
end

function Module:CreateCircle(Part: Instance, PartCount: number, Radius: number)
	local FullCircle = math.pi * 2
	for Index = 1, PartCount do
		local Angle = Index * (FullCircle / PartCount)
		local X, Z = GetXAndZPositions(Angle, Radius)
		local Position = (Part.CFrame * CFrame.new(X, 0, Z)).Position

		local Part = Instance.new('Part')
		Part.Anchored, Part.CanCollide = true, false
		Part.CanTouch, Part.CanQuery = false, false
		Part.Size = Vector3.one
		Part.CFrame = CFrame.lookAt(Position, Part.Position)
		Part.Parent = workspace
	end
end

function Module:LocateSurface(Part: BasePart, Range: number, IgnoreList: table): Vector3
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterDescendantsInstances = IgnoreList or { Part, workspace.Effects, Part.Parent }
	RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
	local Hit = workspace:Raycast(Part.Position, Part.CFrame.UpVector * (Range or -10), RaycastParameters)
	return Hit and Hit.Position or warn('Unable to locate ground position')
end

function Module.Random(X, Y)
	return Random:NextNumber(X, Y)
end

return Module