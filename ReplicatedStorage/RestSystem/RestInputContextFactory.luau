local RestInputContextFactory = {}

function RestInputContextFactory.Ensure(inputRoot: Instance): InputContext
	local context = inputRoot:FindFirstChild("RestContext")
	if context and not context:IsA("InputContext") then
		error("RestContext exists but is not an InputContext: " .. context:GetFullName())
	end
	if not context then
		context = Instance.new("InputContext")
		context.Name = "RestContext"
		context.Parent = inputRoot
	end

	local highestOtherPriority = 0
	for _, child in ipairs(inputRoot:GetChildren()) do
		if child:IsA("InputContext") and child ~= context then
			highestOtherPriority = math.max(highestOtherPriority, child.Priority)
		end
	end
	context.Priority = highestOtherPriority + 110
	-- Gameplay contexts are disabled while resting. Do not sink here: the
	-- station ProximityPrompt must continue receiving its E input to exit.
	context.Sink = false
	context.Enabled = false

	local obsoleteAction = context:FindFirstChild("ExitRestAction")
	if obsoleteAction then obsoleteAction:Destroy() end

	return context
end

return RestInputContextFactory
