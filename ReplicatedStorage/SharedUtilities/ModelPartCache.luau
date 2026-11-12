-- ModelPartCache.lua
-- A lightweight object pool that supports BaseParts OR Models.
-- - Clones from a template
-- - Reparents to a hidden container when returned
-- - Supports custom Reset/OnGet hooks
-- - Supports prefilling ("warmup")

local Workspace = game:GetService("Workspace")

local Cache = {}
Cache.__index = Cache

export type CacheOptions = {
	ParentInUse: Instance?,        -- where objects go when checked out (default: workspace)
	ParentInCache: Instance?,      -- where objects live when returned (default: workspace.__Caches/<Name>)
	Max: number?,                  -- optional max cached objects (default: math.huge)
	Warm: number?,                 -- number of instances to pre-clone (default: 0)

	-- Called BEFORE handing object to caller (after parenting/moving)
	OnGet: ((obj: Instance) -> ())?,

	-- Called BEFORE caching object (you should restore welds, anchor, transparency, etc.)
	OnReturn: ((obj: Instance) -> ())?,

	-- How to position objects
	UsePivotToForModels: boolean?, -- default true; uses Model:PivotTo if available
}

local function isBasePart(x: Instance): boolean
	return x and x:IsA("BasePart")
end

local function isModel(x: Instance): boolean
	return x and x:IsA("Model")
end

local function ensureCacheFolder(name: string): Instance
	local folder = Workspace:FindFirstChild("__Caches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "__Caches"
		folder.Parent = Workspace
	end

	local sub = folder:FindFirstChild(name)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = folder
	end

	return sub
end

local function clearAssemblyMotion(inst: Instance)
	-- Clears velocities on BaseParts (or all parts in a Model)
	if isBasePart(inst) then
		inst.AssemblyLinearVelocity = Vector3.zero
		inst.AssemblyAngularVelocity = Vector3.zero
	elseif isModel(inst) then
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then
				d.AssemblyLinearVelocity = Vector3.zero
				d.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end
end

local function setHidden(inst: Instance, hidden: boolean)
	if isBasePart(inst) then
		inst.Transparency = hidden and 1 or inst.Transparency
		inst.CanCollide = not hidden and inst.CanCollide or false
		inst.CanTouch = not hidden and inst.CanTouch or false
	elseif isModel(inst) then
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then
				if hidden then
					d.Transparency = 1
					d.CanCollide = false
					d.CanTouch = false
				end
			end
		end
	end
end

local function moveTo(inst: Instance, cf: CFrame, usePivotToForModels: boolean)
	if isBasePart(inst) then
		inst.CFrame = cf
	elseif isModel(inst) then
		if usePivotToForModels and inst.PivotTo then
			inst:PivotTo(cf)
		elseif inst.PrimaryPart then
			inst:SetPrimaryPartCFrame(cf)
		else
			-- No PrimaryPart: we can still PivotTo on modern Roblox,
			-- but if that's unavailable, we can't safely move the model.
			-- We'll just leave it where it is.
		end
	end
end

-- Create a new cache
function Cache.new(template: Instance, name: string, options: CacheOptions?)
	assert(template and template.Parent == nil or template.Parent ~= nil, "Template must be an Instance")
	assert(name and #name > 0, "Cache needs a non-empty name")

	local opts = options or {}

	local self = setmetatable({}, Cache)

	self.Template = template
	self.Name = name

	self.ParentInUse = opts.ParentInUse or Workspace
	self.ParentInCache = opts.ParentInCache or ensureCacheFolder(name)

	self.Max = opts.Max or math.huge
	self.UsePivotToForModels = (opts.UsePivotToForModels ~= false)

	self.OnGet = opts.OnGet
	self.OnReturn = opts.OnReturn

	self._free = {}      -- stack of free instances
	self._inUse = {}     -- [instance] = true

	-- Warmup
	local warm = opts.Warm or 0
	for _ = 1, warm do
		local obj = template:Clone()
		obj.Parent = self.ParentInCache
		table.insert(self._free, obj)
	end

	return self
end

-- Get an instance from the cache
-- parent: optional. Where to parent while in use (default ParentInUse)
-- cf: optional CFrame to place the object
function Cache:Get(parent: Instance?, cf: CFrame?): Instance
	local obj = table.remove(self._free)

	if not obj then
		obj = self.Template:Clone()
	end

	-- Mark in use
	self._inUse[obj] = true

	-- Parent it out
	obj.Parent = parent or self.ParentInUse

	-- Place it if requested
	if cf then
		moveTo(obj, cf, self.UsePivotToForModels)
	end

	-- Optional hook
	if self.OnGet then
		self.OnGet(obj)
	end

	return obj
end

-- Return an instance to the cache
function Cache:Return(obj: Instance)
	if not obj then return end

	-- Ignore destroyed objects
	if obj.Parent == nil and not self._inUse[obj] then
		-- could be a clone never owned by us; ignore
	end

	-- Only allow returning objects this cache checked out
	if not self._inUse[obj] then
		warn(("[Cache:%s] Tried to return object not in-use by this cache: %s"):format(self.Name, obj:GetFullName()))
		return
	end

	-- Clean up state
	self._inUse[obj] = nil

	-- Caller-defined reset (restore welds, anchors, transparency, etc.)
	if self.OnReturn then
		local ok, err = pcall(function()
			self.OnReturn(obj)
		end)
		if not ok then
			warn(("[Cache:%s] OnReturn error: %s"):format(self.Name, tostring(err)))
		end
	end

	-- Stop motion just in case
	clearAssemblyMotion(obj)

	-- Hide + park
	setHidden(obj, true)
	obj.Parent = self.ParentInCache

	-- Respect max
	if #self._free < self.Max then
		table.insert(self._free, obj)
	else
		obj:Destroy()
	end
end

-- Optional: number currently free/inuse
function Cache:Stats()
	local inUseCount = 0
	for _ in pairs(self._inUse) do
		inUseCount += 1
	end
	return {
		free = #self._free,
		inUse = inUseCount,
	}
end

return Cache
