-- BottleRocket.client.lua (ModuleScript under ReplicatedStorage.SharedFX.BottleRocket)

local Camera          = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local Debris          = game:GetService("Debris")

local weaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

local Folder      = workspace:WaitForChild("Effects")
local EffectItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("FX")

local Utilities   = require(ReplicatedStorage:WaitForChild("SharedUtilities").Utilities)
local CameraShaker = require(ReplicatedStorage:WaitForChild("SharedUtilities").CameraShake)

local CamShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(CF)
	Camera.CFrame = Camera.CFrame * CF
end)
CamShake:Start()

local Info  = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local Info1 = TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- Helper functions (unchanged)
----------------------------------------------------------------------

local colors = { "red", "orange", "yellow", "green", "blue", "purple" }

local function flare(pos, vel, floaty, timer, color)
	floaty = floaty or 0
	timer  = timer or 2

	local p = Instance.new("Part")
	p.Name = "EffectFlare"
	p.Transparency = 1
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.CanCollide = false
	p.CFrame = CFrame.new(pos) * CFrame.Angles(math.pi, 0, 0)
	p.Velocity = vel

	local particles = {}

	local s = Instance.new("Sparkles")
	s.SparkleColor = Color3.new(1, 1, 0)
	s.Parent = p
	table.insert(particles, s)

	local s2 = Instance.new("Sparkles")
	s2.Parent = p
	table.insert(particles, s2)

	local s3 = Instance.new("Sparkles")
	s3.SparkleColor = Color3.new(1, 1, 0)
	s3.Parent = p
	table.insert(particles, s3)

	local s4 = Instance.new("Sparkles")
	s4.Parent = p
	table.insert(particles, s4)

	local f = Instance.new("Fire")
	f.Color = Color3.new(1, 1, 0.5)
	f.SecondaryColor = Color3.new(1, 1, 1)
	f.Heat = 25
	f.Parent = p
	table.insert(particles, f)

	if color == "red" then
		s.SparkleColor  = Color3.new(1, 0, 0)
		s3.SparkleColor = Color3.new(1, 0, 0)
		f.Color         = Color3.new(1, 0, 0)
	elseif color == "blue" then
		s.SparkleColor  = Color3.new(0, 0, 1)
		s3.SparkleColor = Color3.new(0, 0, 1)
		f.Color         = Color3.new(0, 0, 1)
	elseif color == "green" then
		s.SparkleColor  = Color3.new(0, 1, 0)
		s3.SparkleColor = Color3.new(0, 1, 0)
		f.Color         = Color3.new(0, 1, 0)
	elseif color == "yellow" then
		s.SparkleColor  = Color3.new(1, 1, 0)
		s3.SparkleColor = Color3.new(1, 1, 0)
		f.Color         = Color3.new(1, 1, 0)
	elseif color == "purple" then
		s.SparkleColor  = Color3.new(1, 0, 1)
		s3.SparkleColor = Color3.new(1, 0, 1)
		f.Color         = Color3.new(1, 0, 1)
	elseif color == "orange" then
		s.SparkleColor  = Color3.new(1, 0.5, 0)
		s3.SparkleColor = Color3.new(1, 0.5, 0)
		f.Color         = Color3.new(1, 0.5, 0)
	end

	if floaty > 0 then
		local bf = Instance.new("BodyForce")
		bf.Force = Vector3.new(0, p:GetMass() * 196.2 * floaty, 0)
		bf.Parent = p
	end

	Debris:AddItem(p, timer + 2)
	p.Parent = workspace

	task.delay(timer, function()
		for _, v in pairs(particles) do
			if v and v.Parent and v.Enabled ~= nil then
				v.Enabled = false
			end
		end
	end)

	return p
end

local function StartFireworks(fireworks, position)
	fireworks.Parent = workspace
	fireworks.Position = position
	fireworks.Anchored = false

	Debris:AddItem(fireworks, 20)

	fireworks.CanCollide = false
	fireworks.Anchored   = true
	fireworks.Transparency = 1

	fireworks.Bang4:Play()
	fireworks.Pop2:Play()

	local clr = colors[math.random(1, #colors)]
	local ocf = fireworks.CFrame * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2)

	for i = 1, 7 do
		flare(fireworks.Position, (ocf * CFrame.Angles(i / 7 * math.pi * 2, 0.75, 0)).LookVector * 20, 0.8, 2, clr)
	end

	clr = colors[math.random(1, #colors)]
	for i = 1, 7 do
		flare(fireworks.Position, (ocf * CFrame.Angles(i / 7 * math.pi * 2, -0.75, 0)).LookVector * 20, 0.8, 2, clr)
	end

	fireworks.Fountain:Stop()
	task.wait(10)
	fireworks:Destroy()
end

-- Bezier helper (client-side)
local function cubicBezier(t, p0, p1, p2, p3)
	local u   = 1 - t
	local uu  = u * u
	local uuu = uu * u
	local tt  = t * t
	local ttt = tt * t

	return uuu * p0
		+ 3 * uu * t * p1
		+ 3 * u * tt * p2
		+ ttt * p3
end

----------------------------------------------------------------------
-- Exported FX API
----------------------------------------------------------------------

return {
	------------------------------------------------------------------
	-- PROJECTILE (visual rocket path, streaming-safe)
	------------------------------------------------------------------
	Projectile = function(Player: Player, ...)
		local Data = { ... }
		local startPos = Data[1]
		local endPos   = Data[2]
		local mid1     = Data[3]
		local mid2     = Data[4]

		if typeof(startPos) ~= "Vector3" or typeof(endPos) ~= "Vector3" then
			warn("BottleRocket Projectile: invalid path data from server", startPos, endPos)
			return
		end

		local Projectile = EffectItems.Rocket.Rocket:Clone()
		local weaponSource = weaponInfo.GetWeaponSource()

		if weaponSource == nil then
			Projectile.CFrame = CFrame.new(startPos, endPos)
		else
			Projectile.CFrame = weaponSource
		end

		Projectile.Parent = Folder

		local straight_length   = 10
		local totalVec          = endPos - startPos
		local dir               = totalVec.Magnitude > 0 and totalVec.Unit or Vector3.new(0, 1, 0)
		local straight_end      = startPos + dir * straight_length
		local distance_straight = (straight_end - startPos).Magnitude
		local distance_curve    = (endPos - straight_end).Magnitude
		local total_distance    = distance_straight + distance_curve
		local speed             = 50

		local Elapsed   = 0
		local Connection

		Connection = RunService.RenderStepped:Connect(function(dt)
			Elapsed += dt * 1.5

			local pos = nil

			if Elapsed <= distance_straight / speed then
				-- straight segment
				pos = startPos + dir * speed * Elapsed
			elseif Elapsed <= (distance_straight + distance_curve) / speed then
				-- curved (Bezier) segment
				local t = (Elapsed - distance_straight / speed) / (distance_curve / speed)
				pos = cubicBezier(t, straight_end, mid1, mid2, endPos)
			else
				-- end of path, fade out FX
				if Projectile:FindFirstChild("Attachment") then
					local att = Projectile.Attachment
					if att:FindFirstChild("Smoke") then     att.Smoke.Enabled      = false end
					if att:FindFirstChild("Smoke1") then    att.Smoke1.Enabled     = false end
					if att:FindFirstChild("Specs") then     att.Specs.Enabled      = false end
					if att:FindFirstChild("SpecsDark") then att.SpecsDark.Enabled  = false end
					if att:FindFirstChild("PointLight") then
						TweenService:Create(att.PointLight, Info1, {Brightness = 0}):Play()
					end
				end

				Debris:AddItem(Projectile, 1.25)
				Connection:Disconnect()
				return
			end

			if pos then
				local moveDir = (pos - Projectile.Position)
				if moveDir.Magnitude > 0 then
					moveDir = moveDir.Unit
				else
					moveDir = dir
				end

				Projectile.CFrame = CFrame.new(pos, pos + moveDir) * CFrame.fromOrientation(-math.pi / 2, 0, 0)
			end
		end)
	end,

	------------------------------------------------------------------
	-- IMPACT (unchanged, uses Vector3 from server)
	------------------------------------------------------------------
	Impact = function(player, ...)
		local Data = { ... }
		if not Data[1] then
			return
		end

		local impactPos = Data[1]

		local Impact = EffectItems.Rocket.Impact:Clone()
		Impact.CFrame = CFrame.new(impactPos)

		StartFireworks(Impact.Attachment.Firework:Clone(), Impact.CFrame.Position)

		Debris:AddItem(Impact, 1)
	end,
}
