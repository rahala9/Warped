local handlersFolder = script.Parent:WaitForChild("Behaviors")

local EffectBehaviorService = {}

local handlers = {}
local runtimeStates = setmetatable({}, { __mode = "k" })

local function getHandler(behaviorType: string)
	if handlers[behaviorType] then
		return handlers[behaviorType]
	end

	local module = handlersFolder:FindFirstChild(behaviorType)
	if not module or not module:IsA("ModuleScript") then
		warn("[EffectSystem] No behavior handler registered for", behaviorType)
		return nil
	end

	local handler = require(module)
	handlers[behaviorType] = handler
	return handler
end

local function callHandler(handler, methodName: string, context, behavior, state)
	local method = handler and handler[methodName]
	if not method then
		return nil
	end

	local ok, result = xpcall(method, debug.traceback, context, behavior, state)
	if not ok then
		warn(string.format("[EffectSystem] %s failed for %s (%s):\n%s", methodName, context.EffectName, behavior.Type, result))
		return nil
	end
	return result
end

local function makeContext(player, effectName, runtimeEffect, sourceLevel, definition, behaviorIndex)
	return {
		Player = player,
		EffectName = effectName,
		RuntimeEffect = runtimeEffect,
		SourceLevel = sourceLevel or 1,
		Definition = definition,
		BehaviorIndex = behaviorIndex,
	}
end

function EffectBehaviorService.Apply(player, effectName, runtimeEffect, sourceLevel, definition)
	local behaviors = definition.Behaviors
	if not behaviors then
		return
	end

	local states = {}
	runtimeStates[runtimeEffect] = states
	for index, behavior in ipairs(behaviors) do
		local handler = getHandler(behavior.Type)
		local context = makeContext(player, effectName, runtimeEffect, sourceLevel, definition, index)
		states[index] = callHandler(handler, "OnApply", context, behavior, nil)
	end
end

function EffectBehaviorService.Tick(player, effectName, runtimeEffect, sourceLevel, definition, dt)
	local behaviors = definition.Behaviors
	if not behaviors then
		return
	end

	local states = runtimeStates[runtimeEffect] or {}
	for index, behavior in ipairs(behaviors) do
		local handler = getHandler(behavior.Type)
		local context = makeContext(player, effectName, runtimeEffect, sourceLevel, definition, index)
		context.DeltaTime = dt
		callHandler(handler, "OnTick", context, behavior, states[index])
	end
end

function EffectBehaviorService.Remove(player, effectName, runtimeEffect, sourceLevel, definition)
	local behaviors = definition.Behaviors
	if not behaviors then
		return
	end

	local states = runtimeStates[runtimeEffect] or {}
	for index = #behaviors, 1, -1 do
		local behavior = behaviors[index]
		local handler = getHandler(behavior.Type)
		local context = makeContext(player, effectName, runtimeEffect, sourceLevel, definition, index)
		callHandler(handler, "OnRemove", context, behavior, states[index])
	end
	runtimeStates[runtimeEffect] = nil
end

return EffectBehaviorService
