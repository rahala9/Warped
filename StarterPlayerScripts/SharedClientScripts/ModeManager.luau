--Roblox Services
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

--Remote Events

--GUI
local SharedGUI = PlayerGui:WaitForChild("SharedGUI")
local GameplayGui = SharedGUI:WaitForChild("ToolbeltGui")
local WatchGui = SharedGUI:WaitForChild("WatchGui")
local ShipBuildGui = SharedGUI:WaitForChild("ShipBuildGui")
local EmotesGui = SharedGUI:WaitForChild("EmotesGui")
local HackingGui = SharedGUI:WaitForChild("HackingGui")
local FlightHUDGui = SharedGUI:WaitForChild("FlightHUDGui")
local NPCRemoteControlGui = SharedGUI:WaitForChild("NPCRemoteControlGui")

--Input Context
local InputRoot = SharedGUI:WaitForChild("InputContexts")

local ContextSwitchingContext = InputRoot:WaitForChild("ContextSwitchingContext")
local GameplayContext = InputRoot:WaitForChild("GameplayContext")
local ShipBuildContext = InputRoot:WaitForChild("ShipBuildContext")
local EmotesContext = InputRoot:WaitForChild("EmotesContext")
local HackingContext = InputRoot:WaitForChild("HackingContext")
local FlightContext = InputRoot:WaitForChild("FlightContext")
local AdminContext = InputRoot:WaitForChild("AdminContext")
local NPCRemoteControlContext = InputRoot:WaitForChild("NPCRemoteControlContext")

--Functions

--Definition Modules

--Assets

--Modules

local ModeManager = {}

local Modes = {
	ContextSwitching = "ContextSwitching", --Turned off during flight
	Gameplay = "Gameplay",
	ShipBuild = "ShipBuild",
	Emotes = "Emotes",
	Hacking = "Hacking",
	Flight = "Flight",
	Admin = "Admin",
	NPCRemoteControl = "NPCRemoteControl",
}

ModeManager.Modes = Modes
ModeManager.CurrentMode = Modes.Gameplay
local registeredModeGuis = {}

-- Simple event so other scripts can react
local modeChangedEvent = Instance.new("BindableEvent")
ModeManager.ModeChanged = modeChangedEvent.Event

local function applyMode(mode)
	
	-- Always on except during flight
	ContextSwitchingContext.Enabled = true
	
	-- InputContexts off
	GameplayContext.Enabled = false
	ShipBuildContext.Enabled = false
	EmotesContext.Enabled = false
	HackingContext.Enabled = false
	FlightContext.Enabled = false
	AdminContext.Enabled = false
	NPCRemoteControlContext.Enabled = false
	
	-- GUIs off
	GameplayGui.Enabled = false
	WatchGui.Enabled = false
	ShipBuildGui.Enabled = false
	EmotesGui.Enabled = false
	HackingGui.Enabled = false
	FlightHUDGui.Enabled = false
	NPCRemoteControlGui.Enabled = false
	for _, registeredGui in pairs(registeredModeGuis) do
		if registeredGui.Parent then registeredGui.Enabled = false end
	end

	if mode == Modes.Gameplay then
		GameplayContext.Enabled = true
		GameplayGui.Enabled = true
		WatchGui.Enabled = true

	elseif mode == Modes.ShipBuild then
		ShipBuildContext.Enabled = true
		ShipBuildGui.Enabled = true

	elseif mode == Modes.Emotes then
		EmotesContext.Enabled = true
		EmotesGui.Enabled = true
	elseif mode == Modes.Hacking then
		HackingContext.Enabled = true
		HackingGui.Enabled = true
	elseif mode == Modes.Flight then
		ContextSwitchingContext.Enabled = false
		FlightContext.Enabled = true
		FlightHUDGui.Enabled = true
	elseif mode == Modes.Admin then
		AdminContext.Enabled = true
		local adminGui = registeredModeGuis[Modes.Admin]
		if adminGui and adminGui.Parent then adminGui.Enabled = true end
	elseif mode == Modes.NPCRemoteControl then
		NPCRemoteControlContext.Enabled = true
		NPCRemoteControlGui.Enabled = true
	--elseif mode == Modes.UI then
	--	UIContext.Enabled = true
	end
end

function ModeManager:SetMode(newMode)
	local resolvedMode = newMode == self.CurrentMode and Modes.Gameplay or newMode
	self.CurrentMode = resolvedMode
	applyMode(resolvedMode)

	-- Fire event so other systems can react
	modeChangedEvent:Fire(resolvedMode)
end

function ModeManager:GetMode()
	return self.CurrentMode
end

function ModeManager:RegisterGui(mode, screenGui)
	assert(Modes[mode] == mode, "Unknown mode: " .. tostring(mode))
	assert(screenGui and screenGui:IsA("ScreenGui"), "RegisterGui requires a ScreenGui")
	registeredModeGuis[mode] = screenGui
	screenGui.Enabled = self.CurrentMode == mode
end

-- Initialize
applyMode(ModeManager.CurrentMode)

return ModeManager
