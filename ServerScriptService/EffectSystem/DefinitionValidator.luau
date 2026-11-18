local DefinitionValidator = {}

local behaviorFolder = script.Parent:WaitForChild("Behaviors")

local VALID_STACKING_MODES = {
	Ignore = true,
	Refresh = true,
	Replace = true,
	Stack = true,
}

local VALID_MOVEMENT_OPERATIONS = {
	Add = true,
	Multiply = true,
	ClampMin = true,
	ClampMax = true,
	Override = true,
	Immobilize = true,
}

-- Legacy definitions remain valid during migration, but validating their
-- Type/Action pairs catches silent misspellings before an effect reaches play.
local VALID_LEGACY_ACTIONS = {
	Armor = {Add = true},
	DestroyItem = {ExplodeWeapon = true},
	Food = {Add = true},
	Health = {Add = true, AddPercent = true, DamageEachAttack = true, DOT = true},
	Hydration = {Add = true},
	Intelligence = {Add = true, Subtract = true},
	InvisibilityLv1 = {InvisibilityLv1 = true},
	InvisibilityLv2 = {InvisibilityLv2 = true},
	Kuato = {Add = true},
	Movement = {Movement = true, Set = true},
	Mutation = {FlyHead = true},
	NightVision = {NightVision = true},
	RemoveEffects = {__NO_ACTION = true},
	Screen = {Blur = true},
	Size = {Multiply = true},
	Stability = {Subtract = true},
	Stamina = {AddOverTime = true, Subtract = true, SubtractOverTime = true},
	Strength = {Add = true, Subtract = true},
	Vitality = {Add = true},
	Composed = {None = true},
}

local function isFiniteNumber(value): boolean
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function addIssue(issues, effectName, message)
	table.insert(issues, string.format("%s: %s", effectName, message))
end

local function validateTiming(effectName, definition, issues)
	local duration = definition.Duration
	if duration == nil and definition.Effect then
		duration = definition.Effect.TimeInEffect
	end
	if not isFiniteNumber(duration) or duration < -1 then
		addIssue(issues, effectName, "Duration/Effect.TimeInEffect must be a finite number >= -1")
	end

	if definition.TickInterval ~= nil
		and (not isFiniteNumber(definition.TickInterval) or definition.TickInterval <= 0)
	then
		addIssue(issues, effectName, "TickInterval must be a finite number > 0")
	end
end

local function validateStacking(effectName, definition, issues)
	local stacking = definition.Stacking
	if stacking == nil then
		return
	end
	if typeof(stacking) ~= "table" then
		addIssue(issues, effectName, "Stacking must be a table")
		return
	end
	if not VALID_STACKING_MODES[stacking.Mode] then
		addIssue(issues, effectName, "unknown stacking mode " .. tostring(stacking.Mode))
	end
	if stacking.MaxStacks ~= nil
		and (not isFiniteNumber(stacking.MaxStacks)
			or stacking.MaxStacks < 1
			or stacking.MaxStacks % 1 ~= 0)
	then
		addIssue(issues, effectName, "Stacking.MaxStacks must be a positive integer")
	end
end

local function validateLegacyPayload(effectName, definition, issues)
	local effect = definition.Effect
	if typeof(effect) ~= "table" then
		addIssue(issues, effectName, "Effect must be a table during the compatibility migration")
		return
	end
	local validActions = VALID_LEGACY_ACTIONS[effect.Type]
	if not validActions then
		addIssue(issues, effectName, "unknown legacy Effect.Type " .. tostring(effect.Type))
		return
	end
	local actionKey = effect.Action == nil and "__NO_ACTION" or effect.Action
	if not validActions[actionKey] then
		addIssue(
			issues,
			effectName,
			string.format("invalid legacy action %s for type %s", tostring(effect.Action), tostring(effect.Type))
		)
	end
end

local function validateBehaviorConfiguration(effectName, index, behavior, issues)
	local prefix = string.format("behavior %d (%s)", index, behavior.Type)
	if behavior.Type == "DamageOverTime" then
		if not isFiniteNumber(behavior.Damage) or behavior.Damage <= 0 then
			addIssue(issues, effectName, prefix .. " requires Damage > 0")
		end
	elseif behavior.Type == "CharacterVFX" then
		if typeof(behavior.Template) ~= "string" or behavior.Template == "" then
			addIssue(issues, effectName, prefix .. " requires a non-empty Template")
		end
	elseif behavior.Type == "MeterRate" then
		if typeof(behavior.Meter) ~= "string" or behavior.Meter == "" then
			addIssue(issues, effectName, prefix .. " requires a non-empty Meter")
		end
		if not isFiniteNumber(behavior.RatePerSecond) then
			addIssue(issues, effectName, prefix .. " requires a finite RatePerSecond")
		end
	elseif behavior.Type == "Restriction" then
		local actionCount = 0
		if typeof(behavior.Action) == "string" and behavior.Action ~= "" then
			actionCount += 1
		end
		if behavior.Actions ~= nil and typeof(behavior.Actions) ~= "table" then
			addIssue(issues, effectName, prefix .. " Actions must be an array")
		else
			for _, action in ipairs(behavior.Actions or {}) do
				if typeof(action) ~= "string" or action == "" then
					addIssue(issues, effectName, prefix .. " contains an invalid action")
				else
					actionCount += 1
				end
			end
		end
		if actionCount == 0 then
			addIssue(issues, effectName, prefix .. " requires Action or Actions")
		end
	elseif behavior.Type == "MovementModifier" then
		if not VALID_MOVEMENT_OPERATIONS[behavior.Operation] then
			addIssue(issues, effectName, prefix .. " has an invalid Operation")
		elseif behavior.Operation ~= "Immobilize" and not isFiniteNumber(behavior.Value) then
			addIssue(issues, effectName, prefix .. " requires a finite Value")
		end
		if behavior.ScaleWithSourceLevel ~= nil and typeof(behavior.ScaleWithSourceLevel) ~= "boolean" then
			addIssue(issues, effectName, prefix .. " ScaleWithSourceLevel must be boolean")
		end
	end
end

local function validateBehaviors(effectName, definition, issues)
	if definition.Behaviors == nil then
		return
	end
	if typeof(definition.Behaviors) ~= "table" or #definition.Behaviors == 0 then
		addIssue(issues, effectName, "Behaviors must be a non-empty array")
		return
	end

	for index, behavior in ipairs(definition.Behaviors) do
		if typeof(behavior) ~= "table" or typeof(behavior.Type) ~= "string" or behavior.Type == "" then
			addIssue(issues, effectName, string.format("behavior %d requires a non-empty Type", index))
		else
			local handler = behaviorFolder:FindFirstChild(behavior.Type)
			if not handler or not handler:IsA("ModuleScript") then
				addIssue(
					issues,
					effectName,
					string.format("behavior %d has no registered handler for %s", index, behavior.Type)
				)
			else
				validateBehaviorConfiguration(effectName, index, behavior, issues)
			end
		end
	end
end

function DefinitionValidator.ValidateAll(definitions)
	local issues = {}
	for effectName, definition in pairs(definitions) do
		-- Effects.Image is sprite-sheet metadata rather than an effect definition.
		if effectName ~= "Image" then
			if typeof(definition) ~= "table" then
				addIssue(issues, effectName, "definition must be a table")
			else
				validateTiming(effectName, definition, issues)
				validateStacking(effectName, definition, issues)
				validateLegacyPayload(effectName, definition, issues)
				validateBehaviors(effectName, definition, issues)
			end
		end
	end

	if #issues > 0 then
		error("[EffectSystem] Invalid effect definitions:\n - " .. table.concat(issues, "\n - "), 2)
	end
	return true
end

return DefinitionValidator
