--[[
	AIStateMachine.lua
	
	Base class for enemy AI state machines. Provides common functionality
	and structure that specific AI implementations can extend.
	
	This eliminates duplication between PassiveWandering, PassiveGuard, Patrol, etc.
]]

local AIStateMachine = {}
AIStateMachine.__index = AIStateMachine

--[[
	Create a new state object
	@return Empty state table
]]
function AIStateMachine.NewState()
	local state = {}
	state.Name = ""
	state.Conditions = {}
	state.isRunning = false

	-- Override these in specific states
	state.Action = function()
		-- What the state does each frame
	end

	state.Init = function()
		-- Called once when state machine is initialized
	end

	state.Start = function()
		-- Called when transitioning into this state
		state.isRunning = true
	end

	state.Stop = function()
		-- Called when transitioning out of this state
		state.isRunning = false
	end

	return state
end

--[[
	Create a new condition object
	@return Empty condition table
]]
function AIStateMachine.NewCondition()
	local condition = {}
	condition.Name = ""

	-- Override this in specific conditions
	condition.Evaluate = function()
		return false
	end

	condition.TransitionState = nil

	return condition
end

--[[
	Create a new AI state machine instance
	@param enemy - The enemy this AI controls
	@return AI instance
]]
function AIStateMachine.new(enemy)
	local self = setmetatable({}, AIStateMachine)

	-- Core properties
	self.enemy = enemy
	self.isRunning = false
	self.WaitTime = 0.05 -- Update frequency

	-- State tracking
	self.States = {}
	self.Conditions = {}
	self.CurrentState = nil

	-- Animation tracking
	self.currentAnimation = nil
	self.currentSound = nil

	-- Common AI properties (can be overridden)
	self.AlarmStateDistance = Vector2.new(5, 10)
	self.PlayerNearbyDistance = 5
	self.AlarmStateFrequency = 1
	self.PatrolWaypoints = {}
	self.PatrolCycleNode = 1

	-- Debug settings
	self.DEBUG = false  -- Set to true to enable state debugging
	self.DEBUG_SHOW_OVERHEAD = false  -- Show state name overhead
	self._debugOverhead = nil
	self._lastStateChange = 0

	return self
end

--[[
	Play an animation on the enemy
	@param animationName - Name of the animation to play
]]
function AIStateMachine:PlayAnimation(animationName)
	if not self.isRunning or not animationName then
		return
	end

	local enemy = self.enemy

	-- Stop current animation if different
	if self.currentAnimation and self.currentAnimation ~= enemy.animations[animationName] then
		self.currentAnimation:Stop()
	end

	-- Play new animation
	if enemy.animations[animationName] and self.currentAnimation ~= enemy.animations[animationName] then
		self.currentAnimation = enemy.animations[animationName]
		enemy.animations[animationName]:Play()
	end
end

--[[
	Debug print function (only prints when DEBUG = true)
	@param ... - Arguments to print
]]
function AIStateMachine:DebugPrint(...)
	if self.DEBUG then
		local enemyName = self.enemy.name or "Unknown"
		print(string.format("[AI Debug - %s]", enemyName), ...)
	end
end

--[[
	Create or update debug overhead display showing current state
]]
function AIStateMachine:_updateDebugOverhead()
	if not self.DEBUG_SHOW_OVERHEAD then
		if self._debugOverhead then
			self._debugOverhead:Destroy()
			self._debugOverhead = nil
		end
		return
	end

	if not self.enemy.root then
		return
	end

	-- Create overhead display if it doesn't exist
	if not self._debugOverhead or not self._debugOverhead.Parent then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "AIDebugOverhead"
		billboard.Adornee = self.enemy.root
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = true

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.BackgroundTransparency = 0.5
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.Parent = billboard

		billboard.Parent = self.enemy.root
		self._debugOverhead = billboard
	end

	-- Update text
	local textLabel = self._debugOverhead:FindFirstChildOfClass("TextLabel")
	if textLabel and self.CurrentState then
		textLabel.Text = string.format("State: %s", self.CurrentState.Name)

		-- Color code by state
		if self.CurrentState.Name == "Idle" then
			textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		elseif self.CurrentState.Name == "Search" or self.CurrentState.Name == "Wander" then
			textLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		elseif self.CurrentState.Name == "Pursue" then
			textLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		elseif self.CurrentState.Name == "Attack" then
			textLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		elseif self.CurrentState.Name == "Alarmed" then
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		elseif self.CurrentState.Name == "Patrol" then
			textLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		else
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

--[[
	Play a sound on the enemy
	@param soundName - Name of the sound to play
]]
function AIStateMachine:PlaySound(soundName)
	if not self.isRunning or not soundName then
		return
	end

	local enemy = self.enemy

	if self.currentSound == nil and enemy.sounds and enemy.sounds[soundName] then
		self.currentSound = enemy.sounds[soundName]
		enemy.sounds[soundName]:Play()
	end
end

--[[
	Switch to a new state
	@param newState - The state to switch to (or nil to stop current state)
]]
function AIStateMachine:SwitchState(newState)
	local oldStateName = self.CurrentState and self.CurrentState.Name or "None"
	local newStateName = newState and newState.Name or "None"

	-- Debug logging
	if self.DEBUG and oldStateName ~= newStateName then
		local timeSinceLastChange = os.clock() - self._lastStateChange
		self:DebugPrint(string.format(
			"State Change: %s → %s (was in %s for %.1fs)",
			oldStateName,
			newStateName,
			oldStateName,
			timeSinceLastChange
			))
		self._lastStateChange = os.clock()
	end

	if self.CurrentState then
		self.CurrentState.Stop()
	end

	self.CurrentState = newState

	if newState then
		newState.Start()
	end

	-- Update overhead display
	self:_updateDebugOverhead()
end

--[[
	Set up state conditions from a configuration map
	@param conditionMap - Map of {StateName = {Condition1, Condition2, ...}}
]]
function AIStateMachine:SetConditions(conditionMap)
	if not conditionMap then
		return
	end

	-- Clear existing conditions
	for _, state in pairs(self.States) do
		if state.Conditions then
			state.Conditions = {}
		end
	end

	-- Apply new conditions
	for stateName, conditions in pairs(conditionMap) do
		local state = self.States[stateName]

		if state and state.Conditions then
			for _, conditionName in ipairs(conditions) do
				local condition = self.Conditions[conditionName]

				if condition then
					table.insert(state.Conditions, condition)
				else
					warn("Unknown condition:", conditionName, "for state:", stateName)
				end
			end
		else
			warn("Unknown state or missing Conditions table:", stateName)
		end
	end
end

--[[
	Set a specific condition's transition state
	@param stateName - The state containing the condition
	@param conditionName - The condition to modify
	@param transitionState - The state to transition to (as string)
]]
function AIStateMachine:SetConditionTransition(stateName, conditionName, transitionStateName)
	local state = self.States[stateName]

	if not state or not state.Conditions then
		warn("Unknown state:", stateName)
		return
	end

	local transitionState = self.States[transitionStateName]

	if not transitionState then
		warn("Unknown transition state:", transitionStateName)
		return
	end

	for _, condition in pairs(state.Conditions) do
		if condition.Name == conditionName then
			condition.TransitionState = transitionState
			return
		end
	end

	warn("Condition not found:", conditionName, "in state:", stateName)
end

--[[
	Register a state in the state machine
	@param name - State name (key for States table)
	@param state - State object
]]
function AIStateMachine:RegisterState(name, state)
	self.States[name] = state
end

--[[
	Register a condition in the state machine
	@param name - Condition name (key for Conditions table)
	@param condition - Condition object
]]
function AIStateMachine:RegisterCondition(name, condition)
	self.Conditions[name] = condition
end

--[[
	Start the AI state machine
]]
function AIStateMachine:Start()
	if self.isRunning then
		warn("AI already running for", self.enemy.name)
		return
	end

	self.isRunning = true
	self._lastStateChange = os.clock()

	-- Initialize current state if set
	if self.CurrentState and self.CurrentState.Init then
		self.CurrentState.Init()
	end

	-- Debug logging
	if self.DEBUG then
		self:DebugPrint("AI Started | Initial State:", self.CurrentState and self.CurrentState.Name or "None")
	end

	-- Create overhead display if enabled
	self:_updateDebugOverhead()

	-- Start the main update loop
	coroutine.wrap(function()
		while self.isRunning do
			if self.CurrentState then
				-- Check state transition conditions
				for _, condition in ipairs(self.CurrentState.Conditions) do
					if condition.Evaluate() then
						if self.DEBUG then
							self:DebugPrint("Condition triggered:", condition.Name)
						end
						self:SwitchState(condition.TransitionState)
						break
					end
				end

				-- Perform current state action
				if self.CurrentState and self.CurrentState.Action then
					self.CurrentState.Action()
				end
			end

			-- Update overhead display periodically
			if self.DEBUG_SHOW_OVERHEAD then
				self:_updateDebugOverhead()
			end

			task.wait(self.WaitTime)
		end
	end)()
end

--[[
	Stop the AI state machine
]]
function AIStateMachine:Stop()
	self.isRunning = false

	if self.CurrentState then
		self.CurrentState.Stop()
	end

	-- Clean up debug overhead
	if self._debugOverhead then
		self._debugOverhead:Destroy()
		self._debugOverhead = nil
	end

	if self.DEBUG then
		self:DebugPrint("AI Stopped")
	end
end

--[[
	Get the current state name
	@return Current state name or nil
]]
function AIStateMachine:GetCurrentStateName()
	return self.CurrentState and self.CurrentState.Name or nil
end

--[[
	Check if currently in a specific state
	@param stateName - Name of state to check
	@return true if in that state
]]
function AIStateMachine:IsInState(stateName)
	return self.CurrentState and self.CurrentState.Name == stateName
end

return AIStateMachine