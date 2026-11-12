-- StarterPlayerScripts > LocalScript
-- Blink any BasePart tagged "TowerBeacon" like a radio tower light.
-- One lightweight loop for all beacons; only writes on state changes.

local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")

local TAG = "TowerBeacon"

-- Defaults (override per-part via Attributes)
local DEFAULTS = {
	Period     = 1.2,                       -- seconds for full cycle
	OnTime     = 0.25,                      -- seconds "on" each cycle
	Phase      = 0.0,                       -- per-part offset (seconds)
	Color      = Color3.fromRGB(255, 70, 70),
	UseLight   = true,
	Brightness = 6,
	Range      = 16,
}

-- part -> state
local beacons = {}

local function readAttr(part, name, fallback)
	local v = part:GetAttribute(name)
	if v == nil then return fallback end
	return v
end

local function readCfg(part)
	local period = tonumber(readAttr(part, "Period", DEFAULTS.Period)) or DEFAULTS.Period
	local ontime = tonumber(readAttr(part, "OnTime", DEFAULTS.OnTime)) or DEFAULTS.OnTime
	local phase  = tonumber(readAttr(part, "Phase", DEFAULTS.Phase)) or DEFAULTS.Phase
	local color  = readAttr(part, "Color", DEFAULTS.Color)
	if typeof(color) ~= "Color3" then color = DEFAULTS.Color end

	local useLight = readAttr(part, "UseLight", DEFAULTS.UseLight) and true or false
	local bright   = tonumber(readAttr(part, "Brightness", DEFAULTS.Brightness)) or DEFAULTS.Brightness
	local range    = tonumber(readAttr(part, "Range", DEFAULTS.Range)) or DEFAULTS.Range

	period = math.max(0.05, period)
	ontime = math.clamp(ontime, 0.01, 10)
	bright = math.max(0, bright)
	range  = math.max(0, range)

	return {
		Period = period,
		OnTime = ontime,
		Phase = phase,
		Color = color,
		UseLight = useLight,
		Brightness = bright,
		Range = range,
	}
end

local function ensureLight(part, cfg)
	if not cfg.UseLight then return nil end
	local light = part:FindFirstChildOfClass("PointLight")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "BeaconLight"
		light.Parent = part
	end
	light.Shadows = false
	light.Brightness = cfg.Brightness
	light.Range = cfg.Range
	light.Enabled = false
	return light
end

local function attach(part)
	if beacons[part] then return end
	if not part:IsA("BasePart") then return end

	local cfg = readCfg(part)
	local light = ensureLight(part, cfg)

	beacons[part] = {
		part = part,
		origMat = part.Material,
		origColor = part.Color,
		pointLight = light,
		cfg = cfg,
		lastOn = nil,
	}

	-- React to attribute changes
	part.AttributeChanged:Connect(function()
		local st = beacons[part]
		if not st then return end
		st.cfg = readCfg(part)
		if st.pointLight or st.cfg.UseLight then
			st.pointLight = ensureLight(part, st.cfg)
		end
	end)

	-- Cleanup if removed
	part.AncestryChanged:Connect(function(_, parent)
		if not parent then
			beacons[part] = nil
		end
	end)
end

local function detach(part)
	local st = beacons[part]
	if not st then return end
	if st.part and st.part.Parent then
		st.part.Material = st.origMat
		st.part.Color = st.origColor
		if st.pointLight then st.pointLight.Enabled = false end
	end
	beacons[part] = nil
end

-- Attach existing
for _, inst in ipairs(CollectionService:GetTagged(TAG)) do
	attach(inst)
end

-- React to future tag changes
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	attach(inst)
end)

CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
	if inst:IsA("BasePart") then
		detach(inst)
	end
end)

-- Throttled global update
local accum = 0
RunService.Heartbeat:Connect(function(dt)
	accum += dt
	if accum < 0.1 then return end
	accum = 0

	local t = os.clock()
	for part, st in pairs(beacons) do
		if not part or not part.Parent then
			beacons[part] = nil
		else
			local cfg = st.cfg
			local now = (t + cfg.Phase) % cfg.Period
			local isOn = now < cfg.OnTime

			if isOn ~= st.lastOn then
				st.lastOn = isOn
				if isOn then
					part.Material = Enum.Material.Neon
					part.Color = cfg.Color
					if st.pointLight then st.pointLight.Enabled = true end
				else
					part.Material = st.origMat
					part.Color = st.origColor
					if st.pointLight then st.pointLight.Enabled = false end
				end
			end
		end
	end
end)
