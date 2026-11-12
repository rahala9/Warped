-- Localization
local Random = Random.new()

local Parent = workspace.Effects

-- Services
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

-- Player
local Player = Players.LocalPlayer

-- Properties
local Range = Vector3.new(0, -20, 0)

return function( Origin, Data )
	
	local Parts = { }
	
	-- Properties
	local Radius = Data.Radius or 20
	local Size = Data.Size or Vector3.new(2, 2, 2)
	local PartCount = Data.PartCount or 15
	local Duration = Data.Duration or 3
	local Filter = Data.Filter or { Parent, Player.Character }	
	
	-- Angles
	local Angle = 30
	local OtherAngle = 360 / PartCount
	
	-- Raycast Data
	local RaycastData = RaycastParams.new()
	RaycastData.FilterType = Enum.RaycastFilterType.Blacklist
	RaycastData.FilterDescendantsInstances = Filter
	
	-- Main function for rocks
	for _ = 1, PartCount do
		local Time = Random:NextNumber(1.35, 1.75)
		local Info = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		local CF = Origin
		local NewCFOuter = CF * CFrame.fromEulerAnglesXYZ(0, math.rad(Angle), 0) * CFrame.new(Radius / 2 + Radius / 4, 10, 0)
		local NewCFInner = CF * CFrame.fromEulerAnglesXYZ(0, math.rad(Angle), 0) * CFrame.new(Radius / 2 + Radius / 10, 10, 0)

		local OuterRaycast = workspace:Raycast(NewCFOuter.Position, Range, RaycastData)
		local InnerRaycast = workspace:Raycast(NewCFInner.Position, Range, RaycastData)
		
		if OuterRaycast then
			-- Outer Rocks
			local Part = Instance.new('Part')
			Part.Anchored, Part.CanCollide, Part.CanTouch, Part.CanQuery = true, false, false, false
			Part.Material = Enum.Material.Slate
			Part.Color = OuterRaycast.Instance.Color
			Part.CFrame = CFrame.lookAt(OuterRaycast.Position - Vector3.new(0, 0.5, 0), Origin.Position) * CFrame.fromEulerAnglesXYZ(Random:NextNumber(-0.25, 0.5), Random:NextNumber(-0.25, 0.25), Random:NextNumber(-0.25, 0.25))
			Part.Size = Vector3.new(Size.X * 1.3, Size.Y / 1.4, Size.Z * 1.3) * Random:NextNumber(1, 1.5)
			Part.Parent = Parent
			
			local Hoof = Part:Clone()
			Hoof.Size = Vector3.new(Part.Size.X * 1.01, Part.Size.Y * 0.15, Part.Size.Z * 1.01)
			Hoof.CFrame = Part.CFrame * CFrame.new(0, Part.Size.Y / 2.5 - Hoof.Size.Y / 2.5, 0)
			Hoof.Color = Color3.fromRGB(Hoof.Color.R * 0.5, Hoof.Color.G * 0.5, Hoof.Color.B * 0.5)
			Hoof.Parent = Parent
			
			-- Inner Rocks
			local InnerPart = Part:Clone()
			InnerPart.CFrame = CFrame.lookAt(InnerRaycast.Position - Vector3.new(0, Size.Y * 0.4, 0), Origin.Position) * CFrame.fromEulerAnglesXYZ(Random:NextNumber(-1 ,-0.3), Random:NextNumber(-0.15, 0.15), Random:NextNumber(-0.15, 0.15))
			InnerPart.Parent = Parent
			
			local InnerHoof = Hoof:Clone()
			InnerHoof.CFrame = InnerPart.CFrame * CFrame.new(0, InnerPart.Size.Y / 2.5 - InnerHoof.Size.Y / 2.5, 0)
			InnerHoof.Color = Color3.fromRGB(InnerHoof.Color.R * 0.5, InnerHoof.Color.G * 0.5, InnerHoof.Color.B * 0.5)
			InnerHoof.Parent = Parent
			
			table.insert(Parts, Part)
			table.insert(Parts, Hoof)
			table.insert(Parts, InnerPart)
			table.insert(Parts, InnerHoof)
			
			task.delay(Duration, function()
				for _, p in ipairs(Parts) do
					TweenService:Create(p, Info, {Position = p.CFrame.Position - Vector3.new(0, ( p.Size.Y + 2 ), 0)}):Play()
				end
				
				task.wait(Time)
				for _, p in ipairs(Parts) do p:Destroy() end
				task.wait(1)
				
				Parts = nil
			end)
		end
		Angle += OtherAngle
	end
end