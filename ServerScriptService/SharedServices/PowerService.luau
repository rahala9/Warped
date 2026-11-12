-- ServerScriptService.SharedServices.PowerService

local CollectionService = game:GetService("CollectionService")

local PowerService = {}

local cores = {}
local receivers = {}
local wires = {}

local CORE_TAG = "PowerCore"
local RECEIVER_TAG = "PowerReceiver"
local WIRE_TAG = "PowerWire"

local function getId(obj, attrName)
	local id = obj:GetAttribute(attrName)
	if typeof(id) ~= "string" or id == "" then
		return nil
	end
	return id
end

local function registerCore(obj)
	local coreId = getId(obj, "PowerCoreId")
	if not coreId then
		warn("PowerCore missing PowerCoreId:", obj:GetFullName())
		return
	end

	cores[coreId] = obj

	if obj:GetAttribute("PowerEnabled") == nil then
		obj:SetAttribute("PowerEnabled", false)
	end
end

local function registerReceiver(obj)
	local inputId = getId(obj, "PowerInputId")
	if not inputId then
		warn("PowerReceiver missing PowerInputId:", obj:GetFullName())
		return
	end

	receivers[inputId] = obj

	if obj:GetAttribute("Powered") == nil then
		obj:SetAttribute("Powered", false)
	end
end

local function registerWire(obj)
	local fromId = getId(obj, "FromPowerId")
	local toId = getId(obj, "ToPowerInputId")

	if not fromId or not toId then
		warn("PowerWire missing FromPowerId or ToPowerInputId:", obj:GetFullName())
		return
	end

	table.insert(wires, obj)

	if obj:GetAttribute("Powered") == nil then
		obj:SetAttribute("Powered", false)
	end

	if obj:GetAttribute("Broken") == nil then
		obj:SetAttribute("Broken", false)
	end
end

local function unregisterCore(obj)
	for id, core in pairs(cores) do
		if core == obj then
			cores[id] = nil
			break
		end
	end
end

local function unregisterReceiver(obj)
	for id, receiver in pairs(receivers) do
		if receiver == obj then
			receivers[id] = nil
			break
		end
	end
end

local function unregisterWire(obj)
	for i = #wires, 1, -1 do
		if wires[i] == obj then
			table.remove(wires, i)
		end
	end
end

function PowerService.GetCore(coreId)
	return cores[coreId]
end

function PowerService.GetReceiver(inputId)
	return receivers[inputId]
end

function PowerService.IsCoreEnabled(coreId)
	local core = cores[coreId]
	return core and core:GetAttribute("PowerEnabled") == true
end

function PowerService.IsReceiverPowered(inputId)
	local receiver = receivers[inputId]
	return receiver and receiver:GetAttribute("Powered") == true
end

function PowerService.SetCoreEnabled(coreId, enabled)
	local core = cores[coreId]
	if not core then
		warn("PowerService.SetCoreEnabled: unknown core:", coreId)
		return
	end

	core:SetAttribute("PowerEnabled", enabled == true)
	PowerService.Recalculate()
end

function PowerService.ToggleCore(coreId)
	local core = cores[coreId]
	if not core then
		warn("PowerService.ToggleCore: unknown core:", coreId)
		return
	end

	PowerService.SetCoreEnabled(coreId, not core:GetAttribute("PowerEnabled"))
end

function PowerService.SetWireBroken(wire, broken)
	if not wire then return end
	wire:SetAttribute("Broken", broken == true)
	PowerService.Recalculate()
end

function PowerService.Recalculate()
	local poweredInputs = {}

	for _, wire in ipairs(wires) do
		local fromId = wire:GetAttribute("FromPowerId")
		local toId = wire:GetAttribute("ToPowerInputId")
		local broken = wire:GetAttribute("Broken") == true

		local core = cores[fromId]
		local isPowered = false

		if core and core:GetAttribute("PowerEnabled") == true and not broken then
			isPowered = true
			poweredInputs[toId] = true
		end

		wire:SetAttribute("Powered", isPowered)
	end

	for inputId, receiver in pairs(receivers) do
		receiver:SetAttribute("Powered", poweredInputs[inputId] == true)
	end
end

function PowerService.Init()
	for _, obj in ipairs(CollectionService:GetTagged(CORE_TAG)) do
		registerCore(obj)
	end

	for _, obj in ipairs(CollectionService:GetTagged(RECEIVER_TAG)) do
		registerReceiver(obj)
	end

	for _, obj in ipairs(CollectionService:GetTagged(WIRE_TAG)) do
		registerWire(obj)
	end

	CollectionService:GetInstanceAddedSignal(CORE_TAG):Connect(function(obj)
		registerCore(obj)
		PowerService.Recalculate()
	end)

	CollectionService:GetInstanceRemovedSignal(CORE_TAG):Connect(function(obj)
		unregisterCore(obj)
		PowerService.Recalculate()
	end)

	CollectionService:GetInstanceAddedSignal(RECEIVER_TAG):Connect(function(obj)
		registerReceiver(obj)
		PowerService.Recalculate()
	end)

	CollectionService:GetInstanceRemovedSignal(RECEIVER_TAG):Connect(function(obj)
		unregisterReceiver(obj)
		PowerService.Recalculate()
	end)

	CollectionService:GetInstanceAddedSignal(WIRE_TAG):Connect(function(obj)
		registerWire(obj)

		obj:GetAttributeChangedSignal("Broken"):Connect(function()
			PowerService.Recalculate()
		end)

		PowerService.Recalculate()
	end)

	CollectionService:GetInstanceRemovedSignal(WIRE_TAG):Connect(function(obj)
		unregisterWire(obj)
		PowerService.Recalculate()
	end)

	for _, core in pairs(cores) do
		core:GetAttributeChangedSignal("PowerEnabled"):Connect(function()
			PowerService.Recalculate()
		end)
	end

	for _, wire in ipairs(wires) do
		wire:GetAttributeChangedSignal("Broken"):Connect(function()
			PowerService.Recalculate()
		end)
	end

	PowerService.Recalculate()
end

return PowerService