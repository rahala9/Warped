-- Handle mining and destruction of Asteroids

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local PartCache = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("PartCache"):WaitForChild("PartCache"))

local AsteroidMining = {}

-- Configuration
local LARGE_CHUNK_LIFETIME = 35 -- seconds
local SMALL_FRAGMENT_LIFETIME = 5 -- seconds
local LARGE_CHUNK_VELOCITY = 200
local SMALL_FRAGMENT_VELOCITY = 55
local LARGE_CHUNK_ANGULAR_VEL = 2
local SMALL_FRAGMENT_ANGULAR_VEL = 4
local VELOCITY_SETTLE_THRESHOLD = 0.2 -- When velocity drops below this, anchor the chunk
local LINEAR_DAMPING = 0.98 -- Multiplier per frame to slow down linear velocity
local ANGULAR_DAMPING = 0.98 -- Multiplier per frame to slow down rotation
local DAMPING_DELAY = 5 -- Seconds before damping starts

-- Initialize caches immediately on module load
local SmallFragmentCache
local fragmentTemplate = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("AsteroidDebris"):WaitForChild("SmallFragmentTemplate")
SmallFragmentCache = PartCache.new(fragmentTemplate, 50)
SmallFragmentCache:SetCacheParent(workspace.Debris)

-- Helper to add anti-gravity to a part
local function AddAntiGravity(part)
	local attachment = Instance.new("Attachment")
	attachment.Name = "AntiGravityAttachment"
	attachment.Parent = part

	local vectorForce = Instance.new("VectorForce")
	vectorForce.Name = "AntiGravityForce"
	vectorForce.Force = Vector3.new(0, part:GetMass() * workspace.Gravity, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Attachment0 = attachment
	vectorForce.Parent = part

	return vectorForce, attachment
end

-- Helper to monitor velocity and anchor when settled with damping
local function MonitorAndAnchor(part, lifetime)
	local startTime = tick()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not part or not part.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime

		-- Check if lifetime expired
		if elapsed >= lifetime then
			part.Anchored = true
			-- Clean up anti-gravity
			local force = part:FindFirstChild("AntiGravityForce")
			local attachment = part:FindFirstChild("AntiGravityAttachment")
			if force then force:Destroy() end
			if attachment then attachment:Destroy() end
			connection:Disconnect()
			return
		end

		-- Apply damping ONLY after grace period
		if not part.Anchored and elapsed > DAMPING_DELAY then
			part.AssemblyLinearVelocity = part.AssemblyLinearVelocity * LINEAR_DAMPING
			part.AssemblyAngularVelocity = part.AssemblyAngularVelocity * ANGULAR_DAMPING
		end

		-- Check if velocity has settled (only check after damping has started)
		if elapsed > DAMPING_DELAY and part.AssemblyLinearVelocity.Magnitude < VELOCITY_SETTLE_THRESHOLD then
			part.Anchored = true
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
			-- Clean up anti-gravity
			local force = part:FindFirstChild("AntiGravityForce")
			local attachment = part:FindFirstChild("AntiGravityAttachment")
			if force then force:Destroy() end
			if attachment then attachment:Destroy() end
			connection:Disconnect()
		end
	end)
end

-- Stage 1: Destroy intact asteroid, activate large chunks
function AsteroidMining.DestroyAsteroid(asteroid)
	if not asteroid or not asteroid:IsA("Model") then
		warn("Invalid asteroid model")
		return
	end
	local core = asteroid:FindFirstChild("Core")
	local largeChunksFolder = asteroid:FindFirstChild("LargeChunks")
	if not core or not largeChunksFolder then
		warn("Asteroid missing Core or LargeChunks folder")
		return
	end

	-- Hide and disable core
	core.CanCollide = false
	core.Transparency = 1

	-- Activate all large chunks
	local chunks = largeChunksFolder:GetChildren()

	for _, chunk in chunks do
		-- Handle BaseParts directly (not Models)
		if chunk:IsA("BasePart") then
			chunk.Transparency = 0
			chunk.CanCollide = true

			-- Clear any existing constraints/welds that might resist movement
			for _, constraint in chunk:GetChildren() do
				if constraint:IsA("Constraint") or constraint:IsA("WeldConstraint") then
					constraint:Destroy()
				end
			end

			chunk.Anchored = false

			-- Add anti-gravity
			AddAntiGravity(chunk)

			-- Calculate explosion direction from core center
			local direction = (chunk.Position - core.Position).Unit
			local explosionStrength = LARGE_CHUNK_VELOCITY

			-- Calculate linear velocity with radial direction + randomness
			local linearVelocity = direction * explosionStrength + Vector3.new(
				math.random(-5, 5),
				math.random(-5, 5),
				math.random(-5, 5)
			)

			-- Use ApplyImpulse for instant velocity (more responsive than AssemblyLinearVelocity)
			local impulse = linearVelocity * chunk.AssemblyMass
			chunk:ApplyImpulse(impulse)

			-- Simple random angular velocity
			chunk.AssemblyAngularVelocity = Vector3.new(
				math.random(-LARGE_CHUNK_ANGULAR_VEL, LARGE_CHUNK_ANGULAR_VEL),
				math.random(-LARGE_CHUNK_ANGULAR_VEL, LARGE_CHUNK_ANGULAR_VEL),
				math.random(-LARGE_CHUNK_ANGULAR_VEL, LARGE_CHUNK_ANGULAR_VEL)
			)

			-- Mark as active and hittable
			chunk:SetAttribute("IsLargeChunk", true)
			chunk:SetAttribute("SpawnTime", tick())

			-- Monitor velocity and anchor when settled
			MonitorAndAnchor(chunk, LARGE_CHUNK_LIFETIME)
		end
	end

	-- Schedule cleanup of entire asteroid after lifetime expires
	task.delay(LARGE_CHUNK_LIFETIME, function()
		if asteroid and asteroid.Parent then
			asteroid:Destroy()
		end
	end)
end

-- Stage 2: Break large chunk into small fragments
function AsteroidMining.BreakLargeChunk(chunk)
	if not chunk or not chunk:IsA("BasePart") then
		return
	end

	if not chunk:GetAttribute("IsLargeChunk") then
		return -- Not a large chunk
	end

	-- Get position and velocity from chunk
	local position = chunk.Position
	local velocity = chunk.AssemblyLinearVelocity

	-- Hide and disable chunk
	chunk.CanCollide = false
	chunk.Transparency = 1
	chunk.Anchored = true -- Stop physics
	chunk:SetAttribute("IsLargeChunk", false) -- Prevent re-breaking

	-- Clean up anti-gravity on the chunk
	local force = chunk:FindFirstChild("AntiGravityForce")
	local attachment = chunk:FindFirstChild("AntiGravityAttachment")
	if force then force:Destroy() end
	if attachment then attachment:Destroy() end

	-- Calculate direction from chunk center for radial explosion
	local chunkCenter = chunk.Position

	-- Spawn 3 small fragments from cache
	for i = 1, 3 do
		local fragment = SmallFragmentCache:GetPart()

		-- Random offset position
		local offset = Vector3.new(
			math.random(-2, 2),
			math.random(-2, 2),
			math.random(-2, 2)
		)
		local fragmentPos = position + offset

		fragment.CFrame = CFrame.new(fragmentPos)
		fragment.Anchored = false
		fragment.CanCollide = false -- Visual only
		fragment.Transparency = 0

		-- Add anti-gravity to fragment
		AddAntiGravity(fragment)

		-- Calculate radial direction from chunk center
		local direction = (fragmentPos - chunkCenter).Unit

		-- Calculate linear velocity: inherit some + add radial scatter
		local linearVelocity = velocity * 0.5 + direction * SMALL_FRAGMENT_VELOCITY + Vector3.new(
			math.random(-5, 5),
			math.random(-5, 5),
			math.random(-5, 5)
		)

		-- Use ApplyImpulse for instant velocity
		local impulse = linearVelocity * fragment.AssemblyMass
		fragment:ApplyImpulse(impulse)

		-- Simple random angular velocity
		fragment.AssemblyAngularVelocity = Vector3.new(
			math.random(-SMALL_FRAGMENT_ANGULAR_VEL, SMALL_FRAGMENT_ANGULAR_VEL),
			math.random(-SMALL_FRAGMENT_ANGULAR_VEL, SMALL_FRAGMENT_ANGULAR_VEL),
			math.random(-SMALL_FRAGMENT_ANGULAR_VEL, SMALL_FRAGMENT_ANGULAR_VEL)
		)

		-- Monitor velocity and anchor when settled, then return to cache
		task.spawn(function()
			local startTime = tick()
			local FRAGMENT_DAMPING_DELAY = 0.5 -- Shorter delay for small fragments

			while fragment and fragment.Parent and tick() - startTime < SMALL_FRAGMENT_LIFETIME do
				local elapsed = tick() - startTime

				-- Apply damping ONLY after grace period
				if not fragment.Anchored and elapsed > FRAGMENT_DAMPING_DELAY then
					fragment.AssemblyLinearVelocity = fragment.AssemblyLinearVelocity * LINEAR_DAMPING
					fragment.AssemblyAngularVelocity = fragment.AssemblyAngularVelocity * ANGULAR_DAMPING
				end

				-- Check if settled (only after damping delay)
				if elapsed > FRAGMENT_DAMPING_DELAY and fragment.AssemblyLinearVelocity.Magnitude < VELOCITY_SETTLE_THRESHOLD then
					fragment.Anchored = true
					fragment.AssemblyLinearVelocity = Vector3.zero
					fragment.AssemblyAngularVelocity = Vector3.zero
					break
				end

				task.wait(0.1)
			end

			-- Clean up anti-gravity
			local fragForce = fragment:FindFirstChild("AntiGravityForce")
			local fragAttachment = fragment:FindFirstChild("AntiGravityAttachment")
			if fragForce then fragForce:Destroy() end
			if fragAttachment then fragAttachment:Destroy() end

			-- Return to cache
			SmallFragmentCache:ReturnPart(fragment)
		end)
	end
end

-- Helper function to check if a part is a large chunk
function AsteroidMining.IsLargeChunk(part)
	if part:IsA("BasePart") and part:GetAttribute("IsLargeChunk") then
		return part
	end
	return nil
end

-- Cleanup function (call this when unloading area or resetting)
function AsteroidMining.Cleanup()
	if SmallFragmentCache then
		SmallFragmentCache:Dispose()
	end
end

return AsteroidMining