-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Debris = game:GetService('Debris')

-- Assets
local Bezier = require(script.Bezier)
local CreateTrail = require(script.CreateTrail)

local InwardBezierModule = { }
local Active = true

-- Functions
local function RandomNumber(Number, Number1)
	local RandomNew = Random.new();
	
	return RandomNew:NextNumber(Number,  Number1);
end

local Easings = {
	easeOutQuint = function(x: number): number
		return 1 - math.pow(1 - x, 5);
	end,
	
	easeOutCubic = function(x : number) : number
		return 1 - math.pow(1 - x, 3);
	end,
	
	Linear = function(x : number) : number
		return x;
	end,
};

function InwardBezierModule.Init( Part: BasePart, Properties: table )
	Active = true
	
	-- Main Properties
	local Duration = Properties.Duration or 0.44-- How fast the charging parts go in the main part.
	local Radius = Properties.Radius or 14	    -- How wide the spawning area of the curving parts are.
	local Interval = Properties.Interval or 0.1	-- Interval per part spawn in seconds
	local Index = Properties.Index or math.huge -- How many parts will spawn?
	local Curve = Properties.CurveOffset or 14 -- The offset of the curvature.
	local Projectile = Properties.Projectile or nil
	local Easing = Properties.Easing or "Linear"
	
	-- Trail Properties
	local Size = Properties.Size or 0.175
	local Color = Properties.Color or Color3.fromRGB(164, 116, 255)
	local Transparency = Properties.Transparency or 0
	local Lifetime = Properties.Lifetime or 0.4
	
	for _ = 1, Index do
		if not Active then break end
		
		-- Default values for curve offset
		local StartTime = os.clock()
		
		local DefaultCurveOffset = Vector3.new(RandomNumber(-Curve, Curve), RandomNumber(-Curve, Curve), RandomNumber(-Curve, Curve)) or Vector3.new(RandomNumber(-15, 15), RandomNumber(-5, 10),RandomNumber(-15,15))
		local Offset = CFrame.new(RandomNumber(-Radius, Radius), RandomNumber(-Radius, Radius), RandomNumber(-Radius, Radius))
		
		local Start = Part.CFrame * Offset;
		local End = Part.CFrame
		local Midpoint = Start.Position:Lerp(End.Position, 0.45) + DefaultCurveOffset
		
		local Projectile = Projectile:Clone()
		Projectile.Position = Start.Position;
		Projectile.Trail.Enabled = true;
		Projectile.Parent = workspace.Effects
	
		local Connection; Connection = RunService.RenderStepped:Connect(function(Delta)
			local Alpha = (os.clock() - StartTime) / Duration
			Alpha = Easings[Easing](Alpha)
			
			local Curve = Bezier.QuadBezier(Alpha, Start.Position, Midpoint, End.Position)
			
			if (Alpha >= 1) then
				Projectile.Position = End.Position
				
				task.delay(Projectile.Trail.Lifetime, function()
					Projectile.Trail.Enabled = false
					Projectile:Destroy()
				end)
				
				Connection:Disconnect()
				return
			else
				Projectile.Position = Curve
			end
		end)
		task.wait(Interval)
	end
end

function InwardBezierModule.Disconnect()
	Active = false
end

return InwardBezierModule