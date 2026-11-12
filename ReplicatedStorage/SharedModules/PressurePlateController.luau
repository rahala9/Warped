-- Controller for pressure plates using your ZoneService zones.
-- Supports:
--   Mode = "Hold"      -> Active while anything is on plate (count >= RequiredCount)
--   Mode = "Momentary" -> Fires once when becoming active (rising edge), then immediately resets
-- Tracks players (HRP) via zone callbacks and optionally items/models you register.
--
-- Usage:
--   local PPC = require(ReplicatedStorage.SharedModules.PressurePlateController)
--   local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader) -- registry with :OnLoaded()
--
--   Zones:OnLoaded("PressurePlate1", function(zone)
--       local plate = PPC.new({
--           Name = "PressurePlate1",
--           Zone = zone,
--           Mode = "Hold",         -- or "Momentary"
--           RequiredCount = 1,
--           Cooldown = 0.25,       -- for Momentary (and spam protection)
--       })
--
--       plate.OnActivated:Connect(function(ctx)
--           print("Plate activated by", ctx.by, ctx.count)
--           -- open door / trigger quest / etc
--       end)
--
--       plate.OnDeactivated:Connect(function(ctx)
--           print("Plate deactivated; count", ctx.count)
--           -- close door if Hold-mode, etc
--       end)
--   end)

local RunService = game:GetService("RunService")

local PressurePlateController = {}
PressurePlateController.__index = PressurePlateController

-- Lightweight Signal
local function MakeSignal()
	local sig = { _handlers = {} }
	function sig:Connect(fn)
		table.insert(self._handlers, fn)
		return {
			Disconnect = function()
				for i = #sig._handlers, 1, -1 do
					if sig._handlers[i] == fn then
						table.remove(sig._handlers, i)
						break
					end
				end
			end,
		}
	end
	function sig:Fire(...)
		for _, fn in ipairs(self._handlers) do
			fn(...)
		end
	end
	return sig
end

export type Config = {
	Name: string?,
	Zone: any, -- your ZoneService.Zone object
	Mode: "Hold" | "Momentary",
	RequiredCount: number?,
	Cooldown: number?, -- seconds; mainly for Momentary to prevent rapid re-fire
	Debug: boolean?,

	-- Optional: treat players/items separately or compute weight; keep simple by default.
	-- If you want "requires 2 things on plate", set RequiredCount=2.
}

local function now()
	return os.clock()
end

local function isFn(x): boolean
	return typeof(x) == "function"
end

function PressurePlateController.new(cfg: Config)
	assert(RunService:IsServer(), "PressurePlateController should run on the server for authority.")
	assert(cfg and cfg.Zone, "PressurePlateController requires cfg.Zone")

	local self = setmetatable({}, PressurePlateController)
	self.Name = cfg.Name or "PressurePlate"
	self.Zone = cfg.Zone
	self.Mode = cfg.Mode or "Hold"
	self.RequiredCount = cfg.RequiredCount or 1
	self.Cooldown = cfg.Cooldown or 0.25
	self.Debug = cfg.Debug or false

	-- State
	self._active = false
	self._lastFireT = -math.huge
	self._playerInside = {} -- [Player] = true
	self._itemsInside = {}  -- [Instance] = true

	-- Public signals
	self.OnActivated = MakeSignal()
	self.OnDeactivated = MakeSignal()

	-- Hook zone callbacks

	self.Zone:OnPlayerEntered(function(player)
		self._playerInside[player] = true
		self:_recompute("player")
	end)

	self.Zone:OnPlayerExited(function(player)
		self._playerInside[player] = nil
		self:_recompute("player")
	end)
	
	-- Items: if your ZoneService is tracking items and firing callbacks, we can hook them too.
	-- If you don’t use item tracking for this plate, ignore.
	if isFn(self.Zone.OnItemEntered) then
		self.Zone:OnItemEntered(function(item)
			self._itemsInside[item] = true
			self:_recompute("item")
		end)
	end
	if isFn(self.Zone.OnItemExited) then
		self.Zone:OnItemExited(function(item)
			self._itemsInside[item] = nil
			self:_recompute("item")
		end)
	end

	-- Initialize based on any pre-existing inside state (rare but safe)
	self:_recompute("init")

	return self
end

function PressurePlateController:IsActive(): boolean
	return self._active
end

function PressurePlateController:GetCount(): number
	local n = 0
	for _ in pairs(self._playerInside) do n += 1 end
	for _ in pairs(self._itemsInside) do n += 1 end
	return n
end

function PressurePlateController:_setActive(nextActive: boolean, reason: string, by: string?)
	if self._active == nextActive then return end
	self._active = nextActive

	local ctx = {
		name = self.Name,
		reason = reason,
		by = by or "unknown",
		count = self:GetCount(),
		mode = self.Mode,
	}

	if nextActive then
		if self.Debug then
			print(("[PPC] %s ACTIVE (count=%d)"):format(self.Name, ctx.count))
		end
		self.OnActivated:Fire(ctx)
	else
		if self.Debug then
			print(("[PPC] %s INACTIVE (count=%d)"):format(self.Name, ctx.count))
		end
		self.OnDeactivated:Fire(ctx)
	end
end

function PressurePlateController:_recompute(by: string)
	local count = self:GetCount()
	local shouldBeActive = (count >= self.RequiredCount)

	if self.Mode == "Hold" then
		-- Rising edge activates, falling edge deactivates
		self:_setActive(shouldBeActive, "recompute", by)
		return
	end

	-- Momentary
	if shouldBeActive then
		-- Only fire on rising edge AND obey cooldown
		if not self._active then
			local t = now()
			if (t - self._lastFireT) >= self.Cooldown then
				self._lastFireT = t
				self:_setActive(true, "momentary_fire", by)

				-- Immediately reset (next frame) so it behaves like a "button press"
				task.defer(function()
					-- Only reset if still this instance and still marked active
					if self and self._active then
						self:_setActive(false, "momentary_reset", by)
					end
				end)
			end
		end
	else
		-- If nothing is inside, ensure inactive
		if self._active then
			self:_setActive(false, "momentary_clear", by)
		end
	end
end

-- Optional: if you want to track specific items for this plate only
function PressurePlateController:TrackItem(inst: Instance)
	if isFn(self.Zone.TrackItem) then
		self.Zone:TrackItem(inst)
	else
		warn("[PPC] Zone does not support TrackItem(). Update ZoneService if needed.")
	end
end

function PressurePlateController:UntrackItem(inst: Instance)
	if isFn(self.Zone.UntrackItem) then
		self.Zone:UntrackItem(inst)
	end
	self._itemsInside[inst] = nil
	self:_recompute("item_untrack")
end

return PressurePlateController
