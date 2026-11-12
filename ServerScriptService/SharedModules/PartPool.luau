-- PartPool.lua
local RunService = game:GetService("RunService")

local PartPool = {}
PartPool.__index = PartPool

function PartPool.new(templateProperties, maxSize)
	local self = setmetatable({}, PartPool)
	self.template = templateProperties or {}
	self.maxSize = maxSize or 50
	self.pool = {}
	self.active = {}

	-- Pre-warm the pool
	for _ = 1, self.maxSize do
		table.insert(self.pool, self:createPart())
	end

	return self
end

function PartPool:createPart()
	local part = Instance.new("Part")
	part.Name = self.template.Name or "PooledPart"
	part.Anchored = self.template.Anchored or true
	part.CanCollide = self.template.CanCollide or false
	part.CanTouch = self.template.CanTouch or false
	part.CanQuery = self.template.CanQuery or false
	part.Transparency = self.template.Transparency or 1
	part.Size = self.template.Size or Vector3.one
	part.Material = self.template.Material or Enum.Material.SmoothPlastic
	--part.Parent = workspace.Effects
	part:SetAttribute("InUse", false)
	return part
end

function PartPool:GetPart(cframe)
	local part

	-- Reuse from pool
	if #self.pool > 0 then
		part = table.remove(self.pool)
	else
		-- Expand pool if needed
		part = self:createPart()
	end

	part.CFrame = cframe
	part.Transparency = self.template.Transparency or 1
	--part.Parent = workspace.Effects
	part:SetAttribute("InUse", true)

	-- Optional: reset automatically after 0.5s
	--task.delay(0.5, function()
	--	self:ReturnPart(part)
	--end)

	return part
end

function PartPool:ReturnPart(part)
	if not part or part:GetAttribute("InUse") == false then return end
	part.CFrame = CFrame.new()
	part.Parent = nil
	part:SetAttribute("InUse", false)
	table.insert(self.pool, part)
end

return PartPool
