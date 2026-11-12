--[[
	DialogActions
	Registry of side-effect actions triggered during dialog.
	Runs on the server when a player selects an option or enters a node.

	Each action receives (context, actionDef) where:
		context.player       = Player instance
		context.questService = QuestService instance
		context.npcId        = the NPC being talked to

	To add a new action:
		DialogActions.Register("MyAction", function(context, action)
			-- do stuff
		end)

	Then use in a dialog node or option:
		actions = { { type = "MyAction", someParam = "value" } }
]]

local DialogActions = {}
DialogActions._registry = {}

function DialogActions.Register(actionType, fn)
	DialogActions._registry[actionType] = fn
end

function DialogActions.Run(context, actionList)
	if not actionList then
		return
	end

	for _, action in ipairs(actionList) do
		local fn = DialogActions._registry[action.type]
		if not fn then
			warn("[DialogActions] Unknown action type:", action.type)
		else
			local ok, err = pcall(fn, context, action)
			if not ok then
				warn("[DialogActions] Error in action", action.type, ":", err)
			end
		end
	end
end

------------------------------------------------------------------------
-- Built-in actions
------------------------------------------------------------------------

DialogActions.Register("StartQuest", function(context, action)
	context.questService:StartQuest(context.player, action.questId)
end)

DialogActions.Register("CompleteQuest", function(context, action)
	context.questService:ForceCompleteQuest(context.player, action.questId)
end)

DialogActions.Register("SetQuestFlag", function(context, action)
	context.questService:SetFlag(context.player, action.flag, action.value ~= false)
end)

DialogActions.Register("GiveReward", function(context, action)
	-- HOOK: Replace with your actual reward system
	print(("[DialogReward] %s -> %s x%s"):format(
		context.player.Name,
		tostring(action.rewardId),
		tostring(action.amount or 1)
		))
end)

DialogActions.Register("EmitQuestEvent", function(context, action)
	context.questService:EmitEvent(
		context.player,
		action.event,
		action.payload or {}
	)
end)

DialogActions.Register("Toast", function(context, action)
	context.questService:SendToast(context.player, {
		text = action.text or "",
		kind = action.kind or "Info",
	})
end)

return DialogActions
