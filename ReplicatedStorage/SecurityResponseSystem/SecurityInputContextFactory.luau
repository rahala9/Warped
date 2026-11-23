local Config = require(script.Parent:WaitForChild("Config"))

local SecurityInputContextFactory = {}

function SecurityInputContextFactory.Ensure(inputRoot)
	local context = inputRoot:FindFirstChild("SecurityResponseContext")
	if context and not context:IsA("InputContext") then
		error("SecurityResponseContext exists but is not an InputContext")
	end
	if not context then
		context = Instance.new("InputContext")
		context.Name = "SecurityResponseContext"
		context.Parent = inputRoot
	end

	local highestPriority = 0
	for _, child in ipairs(inputRoot:GetChildren()) do
		if child:IsA("InputContext") and child ~= context then
			highestPriority = math.max(highestPriority, child.Priority)
		end
	end
	context.Priority = highestPriority + 90
	context.Sink = false
	context.Enabled = false

	local action = context:FindFirstChild("SurrenderAction")
	if action and not action:IsA("InputAction") then
		action:Destroy()
		action = nil
	end
	if not action then
		action = Instance.new("InputAction")
		action.Name = "SurrenderAction"
		action.Parent = context
	end
	action.Type = Enum.InputActionType.Bool
	action.DisplayName = "Surrender to security"
	action.Enabled = true

	local binding = action:FindFirstChild("Keyboard")
	if binding and not binding:IsA("InputBinding") then
		binding:Destroy()
		binding = nil
	end
	if not binding then
		binding = Instance.new("InputBinding")
		binding.Name = "Keyboard"
		binding.Parent = action
	end
	binding.KeyCode = Config.SurrenderKey

	return context, action
end

return SecurityInputContextFactory
