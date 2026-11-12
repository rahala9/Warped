-- ServerScriptService/SharedServices/ImpactDecalsService
-- Pooled impact decals aligned to surface normal.
-- Supports "hit" vs "ricochet" decals (separate pools + templates).

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ImpactDecalsService = {}

--////////////////////////////////////////////////////////////
-- CONFIG
--////////////////////////////////////////////////////////////

-- Default parent container (recommended: a workspace folder)
local DEFAULT_FOLDER_NAME = "ImpactDecals"

-- Default pooling sizes
local DEFAULT_POOL_SIZE_HIT = 80
local DEFAULT_POOL_SIZE_RICO = 60

-- Default lifetimes (seconds)
local DEFAULT_LIFETIME_HIT = 10
local DEFAULT_LIFETIME_RICO = 4

-- "Push off the surface" so it doesn't Z-fight
local DEFAULT_SURFACE_EPSILON = 0.02

-- Scale tuning
local DEFAULT_SIZE = Vector2.new(1.2, 1.2)     -- studs (X,Y) on surface
local DEFAULT_THICKNESS = 0.02                 -- studs (Z) thin plate
local DEFAULT_TRANSPARENCY = 1                -- decal-holder part transparency
local DEFAULT_FADE_OUT = 0.25                  -- fade duration

--////////////////////////////////////////////////////////////
-- TEMPLATE MAPS (edit these)
--////////////////////////////////////////////////////////////
-- You can point these to textures / Decals / SurfaceGuis etc.
-- This module uses a Part + Decal on the front face.

-- If you prefer, make these IDs per-ammo.
local HIT_TEXTURES = {
	-- ammoName -> textureId
	-- Example placeholders:
	["Laser"] = "138867480599234",
	["Bullet"] = "115682629651382",
	["Plasma"] = "rbxassetid://83679630728643",
	-- ["Bolt"]  = "rbxassetid://456",
	DEFAULT = "", -- set this!
}

local RICO_TEXTURES = {
	-- ammoName -> textureId
	["Laser"] = "135884325856972",
	["Bullet"] = "102267764343993",
	["Plasma"] = "83679630728643", --Note Plasma does not ricochet
	DEFAULT = "", -- set this!
}

--////////////////////////////////////////////////////////////
-- INTERNAL STATE
--////////////////////////////////////////////////////////////

local _folder : Folder? = nil

-- Each pool entry is a Part that has a Decal child named "Decal"
local Pools = {
	Hit = { items = {}, free = {}, inUse = {} },   -- free stack
	Rico = { items = {}, free = {}, inUse = {} },
}

--////////////////////////////////////////////////////////////
-- HELPERS
--////////////////////////////////////////////////////////////

local function GetOrCreateFolder(parent: Instance?, folderName: string?)
	parent = parent or workspace:WaitForChild("SharedWorkspaceItems")
	folderName = folderName or DEFAULT_FOLDER_NAME

	local f = parent:FindFirstChild(folderName)
	if not f then
		f = Instance.new("Folder")
		f.Name = folderName
		f.Parent = parent
	end
	return f
end

local function MakeDecalPart(): Part
	local p = Instance.new("Part")
	p.Name = "ImpactDecal"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = DEFAULT_TRANSPARENCY
	p.Material = Enum.Material.SmoothPlastic
	p.CastShadow = false
	p.Size = Vector3.new(DEFAULT_SIZE.X, DEFAULT_SIZE.Y, DEFAULT_THICKNESS)

	-- Put the decal on the "back" face (positive Z in part space)
	local d = Instance.new("Decal")
	d.Name = "Decal"
	d.Face = Enum.NormalId.Back
	d.Transparency = 0
	d.Parent = p

	return p
end

local function PoolInit(pool, count: number)
	for i = 1, count do
		local p = MakeDecalPart()
		p.Parent = _folder
		p.Transparency = 1
		
		table.insert(pool.items, p)
		table.insert(pool.free, p)
	end
end

local function PoolAcquire(pool): Part
	local p = table.remove(pool.free)
	if p then
		pool.inUse[p] = true
		return p
	end

	-- No free items: reuse oldest (simple fallback)
	-- This keeps you from silently failing to spawn decals.
	local reuse = pool.items[1]
	if reuse then
		pool.inUse[reuse] = true
		return reuse
	end

	-- Extreme case: pool empty (shouldn't happen)
	local created = MakeDecalPart()
	created.Parent = _folder
	table.insert(pool.items, created)
	pool.inUse[created] = true
	return created
end

local function PoolRelease(pool, p: Part)
	if not p then return end
	if not pool.inUse[p] then
		-- already released
		return
	end

	pool.inUse[p] = nil

	-- Reset visuals
	local d = p:FindFirstChild("Decal")
	if d and d:IsA("Decal") then
		d.Transparency = 0
		d.Texture = ""
	end

	p.Transparency = DEFAULT_TRANSPARENCY
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = Vector3.new(DEFAULT_SIZE.X, DEFAULT_SIZE.Y, DEFAULT_THICKNESS)

	-- Back to folder parent (if it was parented to hitPart)
	p.Parent = _folder

	table.insert(pool.free, p)
end

local function PickTexture(map, ammoName: string?): string
	if ammoName and map[ammoName] and map[ammoName] ~= "" then
		return map[ammoName]
	end
	return map.DEFAULT or ""
end

-- Creates an orientation that sticks a flat decal to the surface.
-- We align the part's *Front* (+Z) to point outward along the surface normal.
local function CFrameFromNormal(pos: Vector3, normal: Vector3)
	-- Choose an "up" that isn't parallel to normal
	local up = Vector3.yAxis
	if math.abs(normal:Dot(up)) > 0.98 then
		up = Vector3.xAxis
	end

	-- Make a basis:
	-- right = up x normal
	local right = up:Cross(normal).Unit
	-- trueUp = normal x right
	local trueUp = normal:Cross(right).Unit

	-- Build CFrame so:
	-- X axis = right, Y axis = trueUp, Z axis = normal
	return CFrame.fromMatrix(pos, right, trueUp, normal)
end

local function FadeAndRelease(pool, part: Part, lifetime: number, fadeTime: number)
	-- Let it live
	task.delay(math.max(0, lifetime - fadeTime), function()
		if not part or not part.Parent then
			return
		end

		local decal = part:FindFirstChild("Decal")
		if decal and decal:IsA("Decal") then
			local tween = TweenService:Create(
				decal,
				TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
				{ Transparency = 1 }
			)
			tween:Play()
			tween.Completed:Once(function()
				PoolRelease(pool, part)
			end)
		else
			PoolRelease(pool, part)
		end
	end)
end

--////////////////////////////////////////////////////////////
-- PUBLIC API
--////////////////////////////////////////////////////////////

-- Call once on server boot (or lazy-init will do it on first spawn)
function ImpactDecalsService.Init(opts)
	opts = opts or {}

	_folder = GetOrCreateFolder(opts.parent, opts.folderName)

	-- init pools once
	if #Pools.Hit.items == 0 then
		PoolInit(Pools.Hit, opts.hitPoolSize or DEFAULT_POOL_SIZE_HIT)
	end
	if #Pools.Rico.items == 0 then
		PoolInit(Pools.Rico, opts.ricoPoolSize or DEFAULT_POOL_SIZE_RICO)
	end
end

-- Set/override textures at runtime if you want
function ImpactDecalsService.SetHitTexture(ammoName: string, textureId: string)
	HIT_TEXTURES[ammoName] = textureId
end

function ImpactDecalsService.SetRicochetTexture(ammoName: string, textureId: string)
	RICO_TEXTURES[ammoName] = textureId
end

-- opts:
--  parentMode = "folder" | "hitPart"
--  folderName, parent (only for init)
--  size = Vector2, thickness = number
--  lifetime = number, fadeTime = number
--  epsilon = number
function ImpactDecalsService.SpawnHit(raycastResult, ammoName: string?, opts)
	opts = opts or {}
	if not _folder then
		ImpactDecalsService.Init(opts) -- lazy init
	end

	local hitPart = raycastResult.Instance
	local hitPos = raycastResult.Position
	local normal = raycastResult.Normal

	local pool = Pools.Hit
	local part = PoolAcquire(pool)

	-- parent choice
	local parentMode = opts.parentMode or "folder"
	if parentMode == "hitPart" and hitPart and hitPart.Parent then
		part.Parent = hitPart
	else
		part.Parent = _folder
	end

	-- sizing
	local size = opts.size or DEFAULT_SIZE
	local thickness = opts.thickness or DEFAULT_THICKNESS
	part.Size = Vector3.new(size.X, size.Y, thickness)

	-- orient + push off surface
	local eps = opts.epsilon or DEFAULT_SURFACE_EPSILON
	local cf = CFrameFromNormal(hitPos + normal * eps, normal)
	part.CFrame = cf

	-- texture
	local decal = part:FindFirstChild("Decal")
	if decal and decal:IsA("Decal") then
		print("Setting ColorMapContent of Decal")
		decal.ColorMapContent = Content.fromAssetId(PickTexture(HIT_TEXTURES, ammoName))
		print("TEST HIT_TEXTURES APPLIED TO DECAL:",ammoName,PickTexture(HIT_TEXTURES, ammoName))
		decal.Transparency = 0
	end

	local lifetime = opts.lifetime or DEFAULT_LIFETIME_HIT
	local fadeTime = opts.fadeTime or DEFAULT_FADE_OUT
	FadeAndRelease(pool, part, lifetime, fadeTime)

	return part
end

function ImpactDecalsService.SpawnRicochet(raycastResult, ammoName: string?, opts)
	opts = opts or {}
	if not _folder then
		ImpactDecalsService.Init(opts) -- lazy init
	end

	local hitPart = raycastResult.Instance
	local hitPos = raycastResult.Position
	local normal = raycastResult.Normal

	local pool = Pools.Rico
	local part = PoolAcquire(pool)

	-- parent choice
	local parentMode = opts.parentMode or "folder"
	if parentMode == "hitPart" and hitPart and hitPart.Parent then
		part.Parent = hitPart
	else
		part.Parent = _folder
	end

	-- sizing (ricochet decals often smaller)
	local size = opts.size or (DEFAULT_SIZE * 0.75)
	local thickness = opts.thickness or DEFAULT_THICKNESS
	part.Size = Vector3.new(size.X, size.Y, thickness)

	-- orient + push off surface
	local eps = opts.epsilon or DEFAULT_SURFACE_EPSILON
	local cf = CFrameFromNormal(hitPos + normal * eps, normal)
	part.CFrame = cf

	-- texture
	local decal = part:FindFirstChild("Decal")
	if decal and decal:IsA("Decal") then
		decal.ColorMapContent = Content.fromAssetId(PickTexture(RICO_TEXTURES, ammoName))
		print("TEST RICO TEXTURE APPLIED TO DECAL:",ammoName,PickTexture(RICO_TEXTURES, ammoName))
		decal.Transparency = 0
	end

	local lifetime = opts.lifetime or DEFAULT_LIFETIME_RICO
	local fadeTime = opts.fadeTime or DEFAULT_FADE_OUT
	FadeAndRelease(pool, part, lifetime, fadeTime)

	return part
end

return ImpactDecalsService
