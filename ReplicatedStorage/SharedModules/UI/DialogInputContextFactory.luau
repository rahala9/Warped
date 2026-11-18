local DialogInputContextFactory = {}

local NUMBER_KEYS = {
	{Enum.KeyCode.One, Enum.KeyCode.KeypadOne},
	{Enum.KeyCode.Two, Enum.KeyCode.KeypadTwo},
	{Enum.KeyCode.Three, Enum.KeyCode.KeypadThree},
	{Enum.KeyCode.Four, Enum.KeyCode.KeypadFour},
	{Enum.KeyCode.Five, Enum.KeyCode.KeypadFive},
	{Enum.KeyCode.Six, Enum.KeyCode.KeypadSix},
	{Enum.KeyCode.Seven, Enum.KeyCode.KeypadSeven},
	{Enum.KeyCode.Eight, Enum.KeyCode.KeypadEight},
	{Enum.KeyCode.Nine, Enum.KeyCode.KeypadNine},
}

local function ensureBinding(action: InputAction, name: string, keyCode: Enum.KeyCode)
	local binding = action:FindFirstChild(name)
	if binding and not binding:IsA("InputBinding") then
		warn("[DialogInput] Expected InputBinding at", binding:GetFullName())
		return
	end
	if not binding then
		binding = Instance.new("InputBinding")
		binding.Name = name
		binding.Parent = action
	end
	binding.KeyCode = keyCode
end

local function ensureAction(context: InputContext, index: number)
	local name = "SelectDialogOptionAction" .. index
	local action = context:FindFirstChild(name)
	if action and not action:IsA("InputAction") then
		warn("[DialogInput] Expected InputAction at", action:GetFullName())
		return nil
	end
	if not action then
		action = Instance.new("InputAction")
		action.Name = name
		action.Parent = context
	end
	action.Type = Enum.InputActionType.Bool
	action.Enabled = true
	action.DisplayName = "Select dialog option " .. index
	ensureBinding(action, "Keyboard" .. index, NUMBER_KEYS[index][1])
	ensureBinding(action, "Keypad" .. index, NUMBER_KEYS[index][2])
	return action
end

function DialogInputContextFactory.Ensure(inputRoot: Instance): InputContext
	local context = inputRoot:FindFirstChild("DialogContext")
	if context and not context:IsA("InputContext") then
		error("DialogContext exists but is not an InputContext: " .. context:GetFullName())
	end
	if not context then
		context = Instance.new("InputContext")
		context.Name = "DialogContext"
		context.Parent = inputRoot
	end

	local highestOtherPriority = 0
	for _, child in ipairs(inputRoot:GetChildren()) do
		if child:IsA("InputContext") and child ~= context then
			highestOtherPriority = math.max(highestOtherPriority, child.Priority)
		end
	end
	context.Priority = highestOtherPriority + 100
	context.Sink = true
	context.Enabled = false

	for index = 1, 9 do
		ensureAction(context, index)
	end
	return context
end

return DialogInputContextFactory
