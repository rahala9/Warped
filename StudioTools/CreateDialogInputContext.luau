-- Run in Studio's Command Bar after the synced modules are present.
-- This persists an inspectable DialogContext beside the game's other contexts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local factory = require(
	ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UI"):WaitForChild("DialogInputContextFactory")
)
local inputRoot = StarterGui:WaitForChild("SharedGUI"):WaitForChild("InputContexts")
local context = factory.Ensure(inputRoot)

print(string.format(
	"Created/updated %s (Priority=%d, Sink=%s) with number-row and keypad bindings.",
	context:GetFullName(),
	context.Priority,
	tostring(context.Sink)
))
