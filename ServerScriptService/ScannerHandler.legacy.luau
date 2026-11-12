local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)
local Scanner = require(ServerScriptService.SharedModules.Scanner)
local ScannerConfigurations = require(ServerScriptService.SharedModules.Scanners)
local ScannerActions = require(ServerScriptService.SharedFunctions.Scanners.ScannerActionsFunctions)
local ScannerEffects = require(ServerScriptService.SharedFunctions.Scanners.ScannerEffectsFunctions)

local DisplayActionMessageEvent = ReplicatedStorage.SharedRemotes.DisplayActionMessage

local scanners = {}
local boundZones = {}
local exitConnected = {}

local function splitCsv(s)
	local t = {}
	for token in string.gmatch(s or "", "([^,%s]+)") do
		table.insert(t, token)
	end
	return t
end

local function mapEnums(tokens, enumTable)
	local out = {}
	for _, name in ipairs(tokens) do
		local v = enumTable[name]
		if v ~= nil then table.insert(out, v) end
	end
	return out
end

local function initScannerWithZone(model: Model, zone)
	if scanners[model] then return end
	if not model.Parent then return end

	-- Get config ID from attribute or model name
	local configId = model:GetAttribute("ScannerID") or model.Name
	local config = ScannerConfigurations.Scanners[configId]

	if not config then
		warn("[BodyScanner] No configuration found for:", configId)
		return
	end

	-- Allow attribute overrides if config doesn't exist
	local scanTypes = config.scanTypes or mapEnums(
		splitCsv(model:GetAttribute("ScanTypes") or "Weapon,IllicitItem"), 
		ScannerConfigurations.ScanType
	)

	local allowedSpecies = config.allowedSpecies or mapEnums(
		splitCsv(model:GetAttribute("AllowedSpecies") or "Human"), 
		ScannerConfigurations.Species
	)

	local travel = config.travel or model:GetAttribute("Travel") or 10
	local tweenTime = config.tweenTime or model:GetAttribute("TweenTime") or 1

	-- Validation
	if #scanTypes == 0 then
		scanTypes = {ScannerConfigurations.ScanType.Weapon, ScannerConfigurations.ScanType.IllicitItem}
	end
	if #allowedSpecies == 0 then
		allowedSpecies = {ScannerConfigurations.Species.Human}
	end

	local function HandleScanResult(player, passed, ctx, scanTypesUsed, perCheckResults, scanner)
		local resultConfig = passed and config.onPass or config.onFail
		if not resultConfig then
			warn("[BodyScanner] No onPass/onFail config for:", configId)
			return
		end

		-- Build message list: check perCheckResults for specific fail messages
		local messages = resultConfig.messages  -- default fallback

		if not passed and resultConfig.failMessages and perCheckResults then
			-- Find the first failed check and use its specific message
			local ScanType = ScannerConfigurations.ScanType

			-- Build reverse lookup: number -> name
			local scanTypeNames = {}
			for name, value in pairs(ScanType) do
				scanTypeNames[value] = name
			end

			for scanType, result in pairs(perCheckResults) do
				if result == false then
					local typeName = scanTypeNames[scanType]
					if typeName and resultConfig.failMessages[typeName] then
						messages = resultConfig.failMessages[typeName]
						break
					end
				end
			end
		end

		-- Display messages
		if messages then
			task.spawn(function()
				local textLabel = scanner.Model.Display.SurfaceGui.TextLabel
				for _, message in ipairs(messages) do
					textLabel.Text = message
					task.wait(2)
				end
				textLabel.Text = ""
			end)
		end

		-- Execute main action
		if resultConfig.action then
			local actionHandler = ScannerActions[resultConfig.action]
			if actionHandler then
				local ok, err = pcall(function()
					actionHandler(resultConfig, player, model)
				end)
				if not ok then
					warn("[BodyScanner] Action error:", err)
				end
			else
				warn("[BodyScanner] Unknown action:", resultConfig.action)
			end
		end

		-- Execute failure effects
		if not passed and resultConfig.effects then
			for _, effectName in ipairs(resultConfig.effects) do
				local effectHandler = ScannerEffects[effectName]
				if effectHandler then
					local ok, err = pcall(function()
						effectHandler(model)
					end)
					if not ok then
						warn("[BodyScanner] Effect error:", err)
					end
				else
					warn("[BodyScanner] Unknown effect:", effectName)
				end
			end
		end
	end

	local ok, scannerOrErr = pcall(function()
		return Scanner.new(model, zone, {
			scanTypes = scanTypes,
			allowedSpecies = allowedSpecies,
			travel = travel,
			tweenTime = tweenTime,
			onResult = HandleScanResult,
		})
	end)

	if not ok then
		warn("[BodyScanner] init error:\n", scannerOrErr)
		return
	end

	scanners[model] = scannerOrErr
end

local function teardownScanner(model: Model)
	local inst = scanners[model]
	if inst then
		if inst.Destroy then pcall(function() inst:Destroy() end) end
		scanners[model] = nil
	end
end

local function bindScannerModel(model: Model)
	if boundZones[model] then return end
	boundZones[model] = true

	local baseKey = model:GetAttribute("ZoneKey") or model.Name
	local exitKey = model:GetAttribute("ExitZoneKey") or (baseKey .. "Exit")

	local token = os.clock()
	model:SetAttribute("_BodyScannerBindToken", token)

	-- Entry zone
	Zones:OnLoaded(baseKey, function(zone)
		if not model.Parent then return end
		if model:GetAttribute("_BodyScannerBindToken") ~= token then return end
		if not CollectionService:HasTag(model, "BodyScanner") then return end

		local zoneModel = zone.Folder and zone.Folder.Parent
		if zoneModel and zoneModel ~= model then return end

		initScannerWithZone(model, zone)
	end)

	-- Exit zone (auto-open)
	Zones:OnLoaded(exitKey, function(zone)
		if not model.Parent then return end
		if model:GetAttribute("_BodyScannerBindToken") ~= token then return end
		if not CollectionService:HasTag(model, "BodyScanner") then return end

		local zoneModel = zone.Folder and zone.Folder.Parent
		if zoneModel and zoneModel ~= model then return end

		if exitConnected[zone] then return end
		exitConnected[zone] = true

		-- Get config to determine exit behavior
		local configId = model:GetAttribute("ScannerID") or model.Name
		local config = ScannerConfigurations.Scanners[configId]

		zone:OnPlayerEntered(function(player)
			if config and config.exitAction then
				local actionHandler = ScannerActions[config.exitAction.action]
				if actionHandler then
					actionHandler(config.exitAction, player, model)
				end
			else
				-- Default: slide door
				local door = model:FindFirstChild(model:GetAttribute("DoorName") or "ScannerDoor")
				if door then
					ScannerActions.SlideDoor({targetPath = "ScannerDoor"}, player, model)
				end
			end
		end)
	end)
end

local function unbindScannerModel(model: Model)
	model:SetAttribute("_BodyScannerBindToken", nil)
	boundZones[model] = nil
	teardownScanner(model)
end

-- Initial + future
for _, inst in ipairs(CollectionService:GetTagged("BodyScanner")) do
	if inst:IsA("Model") then bindScannerModel(inst) end
end

CollectionService:GetInstanceAddedSignal("BodyScanner"):Connect(function(inst)
	if inst:IsA("Model") then bindScannerModel(inst) end
end)

CollectionService:GetInstanceRemovedSignal("BodyScanner"):Connect(function(inst)
	if inst:IsA("Model") then unbindScannerModel(inst) end
end)