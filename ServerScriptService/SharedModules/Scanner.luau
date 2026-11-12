-- BodyScanner.lua (ModuleScript)

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)

local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))


-- Import enums from config
local ScannerConfigurations = require(ServerScriptService.SharedModules.Scanners)

local BodyScanner = {}
BodyScanner.__index = BodyScanner

-- Re-export enums for convenience (so existing code still works)
BodyScanner.ScanType = ScannerConfigurations.ScanType
BodyScanner.Species = ScannerConfigurations.Species

--========================
-- Helpers
--========================

local function getPrimary(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function setBeamsVisible(beams: { Model }, visible: boolean)
	local transparency = visible and 0 or 1

	for _, beamModel in ipairs(beams) do
		local pp = getPrimary(beamModel)
		if pp then
			local part = pp:FindFirstChild("Part") or pp
			if part:IsA("BasePart") then
				part.Transparency = transparency
			end

			local beam = pp:FindFirstChildWhichIsA("Beam", true)
			if beam then
				beam.Enabled = visible
			end
		end
	end
end

local function tweenModelTo(model: Model, targetCFrame: CFrame, tweenInfo: TweenInfo)
	local proxy = Instance.new("CFrameValue")
	proxy.Value = model:GetPivot()

	local conn = proxy:GetPropertyChangedSignal("Value"):Connect(function()
		model:PivotTo(proxy.Value)
	end)

	local tween = TweenService:Create(proxy, tweenInfo, { Value = targetCFrame })
	tween:Play()
	tween.Completed:Wait()

	conn:Disconnect()
	proxy:Destroy()
end

--========================
-- Context + Checks
--========================

local function BuildPlayerScanContext(player)
	local ctx = {}

	-- INVENTORY / TOOLS (wire up later)
	ctx.HasWeapon = InventoryFunctions.HasItemType(player,itemsmodule.ItemTypes.Weapon,true)

	-- ILLICIT ITEMS (wire up later)
	ctx.HasIllicit = InventoryFunctions.HasIllicitItem(player,true)

	-- SPECIES (enum value)
	ctx.Species = ScannerConfigurations.Species.Human

	return ctx
end

local function containsNumber(list: { number }, value: number): boolean
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

--========================
-- BodyScanner Class
--========================

export type Config = {
	tweenTime: number?,
	travel: number?,
	scanTypes: { number }?,
	allowedSpecies: { number }?,
	onResult: ((Player, boolean, any, { number }, { [number]: boolean }, any) -> ())?,
}

function BodyScanner.new(bodyScannerModel: Model, zone, config: Config?)
	local self = setmetatable({}, BodyScanner)

	self.Model = bodyScannerModel
	self.Zone = zone
	self.Config = config or {}

	if self.Config.scanType ~= nil and self.Config.scanTypes == nil then
		warn("BodyScanner config uses 'scanType' but expects 'scanTypes' (list). Did you mean scanTypes?")
	end

	self.TweenTime = self.Config.tweenTime or 5
	self.Travel = self.Config.travel or 10

	self.ScanTypes = self.Config.scanTypes or { ScannerConfigurations.ScanType.Weapon }
	self.AllowedSpecies = self.Config.allowedSpecies or { 
		ScannerConfigurations.Species.Human, 
		ScannerConfigurations.Species.Bleeper 
	}

	-- Validate scanTypes are enum numbers
	for i, t in ipairs(self.ScanTypes) do
		assert(type(t) == "number", ("scanTypes[%d] must be a ScanType enum value (number)"):format(i))
	end

	-- If species scanning is enabled, ensure whitelist is non-empty and numeric
	if containsNumber(self.ScanTypes, ScannerConfigurations.ScanType.SpeciesAllowed) then
		assert(type(self.AllowedSpecies) == "table" and #self.AllowedSpecies > 0, "SpeciesAllowed scan enabled but allowedSpecies is empty")
		for i, s in ipairs(self.AllowedSpecies) do
			assert(type(s) == "number", ("allowedSpecies[%d] must be a Species enum value (number)"):format(i))
		end
	end

	self.OnResult = self.Config.onResult

	-- Build per-instance check table
	self.Checks = {
		[ScannerConfigurations.ScanType.Weapon] = function(ctx)
			return ctx.HasWeapon ~= true
		end,

		[ScannerConfigurations.ScanType.IllicitItem] = function(ctx)
			return ctx.HasIllicit ~= true
		end,

		[ScannerConfigurations.ScanType.SpeciesAllowed] = function(ctx)
			return containsNumber(self.AllowedSpecies, ctx.Species)
		end,
	}

	-- Model wiring
	local entrance = bodyScannerModel:FindFirstChild("Entrance")
	assert(entrance, "BodyScanner missing Entrance: " .. bodyScannerModel:GetFullName())

	local beamsFolder = entrance:FindFirstChild("LaserBeams")
	assert(beamsFolder, "BodyScanner missing Entrance/LaserBeams: " .. bodyScannerModel:GetFullName())

	self.Beams = {}
	for _, child in ipairs(beamsFolder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(self.Beams, child)
		end
	end
	table.sort(self.Beams, function(a, b) return a.Name < b.Name end)
	assert(#self.Beams > 0, "BodyScanner has no beam models in LaserBeams folder")

	self.RootBeam = self.Beams[1]

	-- Cache pivots + relative offsets
	self.UpCFrame = self.RootBeam:GetPivot()
	self.DownCFrame = self.UpCFrame * CFrame.new(0, -self.Travel, 0)

	self.Rel = {}
	local rootPivot = self.UpCFrame
	for i, beamModel in ipairs(self.Beams) do
		self.Rel[i] = rootPivot:ToObjectSpace(beamModel:GetPivot())
	end

	self._moveToken = 0
	self.Activated = false

	-- Hook zone
	zone:OnPlayerEntered(function(player: Player)
		self.Activated = true
		self:Activate(player)
	end)

	zone:OnPlayerExited(function(player: Player)
		self.Activated = false
		self:Deactivate(player)
	end)

	return self
end

function BodyScanner:_runScan(scanType: number, ctx): boolean
	local checkFn = self.Checks[scanType]
	if not checkFn then
		warn("Unknown scan type:", scanType)
		return false
	end
	return checkFn(ctx)
end

function BodyScanner:_runAllScans(ctx): (boolean, { [number]: boolean })
	local passed = true
	local results: { [number]: boolean } = {}

	for _, scanType in ipairs(self.ScanTypes) do
		local ok = self:_runScan(scanType, ctx)
		results[scanType] = ok
		if ok ~= true then
			passed = false
		end
	end

	return passed, results
end

function BodyScanner:_tweenAllTo(targetRoot: CFrame)
	local token = self._moveToken
	local info = TweenInfo.new(self.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local completions = 0
	local total = #self.Beams
	local done = Instance.new("BindableEvent")

	for i, beamModel in ipairs(self.Beams) do
		task.spawn(function()
			if token ~= self._moveToken then
				return
			end

			local target = targetRoot * self.Rel[i]
			tweenModelTo(beamModel, target, info)

			completions += 1
			if completions == total then
				done:Fire()
			end
		end)
	end

	done.Event:Wait()
	done:Destroy()
end

function BodyScanner:Activate(player: Player)
	setBeamsVisible(self.Beams, true)

	self._moveToken += 1
	local scanToken = self._moveToken

	task.spawn(function()
		local ok, err = pcall(function()
			self:_tweenAllTo(self.DownCFrame)
			self:_tweenAllTo(self.UpCFrame)
		end)
		if not ok then
			warn("BodyScanner tween error:", err)
		end

		if scanToken ~= self._moveToken then
			return
		end

		if self.Activated then
			local ctx = BuildPlayerScanContext(player)
			local passed, perCheckResults = self:_runAllScans(ctx)

			if self.OnResult then
				local okCb, cbErr = pcall(function()
					self.OnResult(player, passed, ctx, self.ScanTypes, perCheckResults, self)
				end)
				if not okCb then
					warn("BodyScanner OnResult callback error:", cbErr)
				end
			end
		end

		setBeamsVisible(self.Beams, false)
	end)
end

function BodyScanner:Deactivate(_player: Player)
	self._moveToken += 1
	setBeamsVisible(self.Beams, false)
end

return BodyScanner