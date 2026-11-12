local machine = {}

machine.new = function()
	local StateMachine = {}	

	StateMachine.WaitTime = .2
	StateMachine.CurrentState = nil
	StateMachine.SwitchState = function(newState)
		if StateMachine.CurrentState then
			StateMachine.CurrentState.Stop()
		end
		StateMachine.CurrentState = newState
		if newState then
			newState.Start()
		end
	end

	StateMachine.NewState = function()
		local state = {}
		state.Name = ""
		state.Conditions = {}
		state.isRunning = false
		state.Action = function() end
		state.Run = function()
			state.isRunning = true
			while state.isRunning do
				--check conditions
				--Logger.Debug("checking conditions")
				for _, condition in pairs(state.Conditions) do
					--Logger.Debug("ENEMY AI: Checking " .. condition.Name)
					if condition.Evaluate() then
						--Logger.Debug("ENEMY AI:"..condition.Name .. " is true. Switching states:"..condition.TransitionState.Name)
						StateMachine.SwitchState(condition.TransitionState)
						return
					end
				end

				--if no conditions satisfied, perform action
				--Logger.Debug("ENEMY AI: Do ACTION:"..state.Name)
				state.Action()
				wait(StateMachine.WaitTime)
			end
		end
		state.Init = function()

		end
		state.Start = function()

			state.Init()
			local thread = coroutine.create(state.Run)
			coroutine.resume(thread)
		end
		state.Stop = function()

			state.isRunning = false
		end
		return state
	end

	StateMachine.NewCondition = function()
		local condition = {}
		condition.Name = ""
		condition.Evaluate = function() print("replace me") return false end
		condition.TransitionState = {}
		return condition
	end	

	return StateMachine
end

return machine