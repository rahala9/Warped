-- Services
local RunService = game:GetService('RunService')

-- Modules
local FastSignal = require(script.FastSignal)
local MockPart = require(script.MockPart)

local ProjectileHandler = { }
ProjectileHandler.__index = ProjectileHandler

function ProjectileHandler.new(Caster, Properties)
	local RaycastParameters = RaycastParams.new()
	RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
	RaycastParameters.FilterDescendantsInstances = Properties.IgnoreList or {workspace.Effects, Caster}
	
	local Projectile = { }
	Projectile.Origin = Properties.Origin or error('No origin passed!')
	Projectile.Type = Properties.Type or error('No projectile type passed!')
	Projectile.Speed = Properties.Speed or 3
	Projectile.HitRange = Properties.HitRange or 2
	Projectile.IgnoreList = RaycastParameters
	Projectile.OnHit = FastSignal.new()
	
	setmetatable(Projectile, ProjectileHandler)
	return Projectile
end

function ProjectileHandler:Start()
	local Projectile = MockPart(self.Type..'Server', self.Origin)
	
	self.Connection = RunService.Stepped:Connect(function(_, Delta)
		local Increment = 0.85 * (Delta * 60) 
		Projectile.CFrame = Projectile.CFrame * CFrame.new(0, 0, -Increment)
		
		local Hit = workspace:Raycast(Projectile.Position, Projectile.CFrame.LookVector * self.HitRange, self.IgnoreList)
		if Hit then
			Projectile:Destroy()
			self.OnHit:Fire(Hit)
			ProjectileHandler:Stop()
		end
	end)
end

function ProjectileHandler:Stop()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	
	if self.OnHit then
		self.OnHit:DisconnectAll()
		self.OnHit = nil
	end
	
	if self.IgnoreList then
		self.IgnoreList = nil
	end
end

return ProjectileHandler