--[[
	DialogService
	Server-side dialog orchestrator.

	Manages active player conversations, evaluates conditions to determine
	which root node and options to show, validates player selections,
	and runs actions on node entry and option selection.

	Usage:
		local DialogService = require(path.to.DialogService)
		DialogService:Init(QuestService)

	Players initiate dialog by firing RequestDialog with an npcId.
	The NPC interaction system (e.g. ProximityPrompt) should fire:
		DialogRemotes.GetRemoteEvent("RequestDialog"):FireServer(npcId)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DialogRemotes = require(ReplicatedStorage.SharedModules.Dialog:WaitForChild("DialogRemotes"))
local Definitions = require(script.Parent.DialogDefinitions)
local Conditions = require(script.Parent.DialogConditions)
local Actions = require(script.Parent.DialogActions)

local DialogService = {}

local ActiveDialogs = {} -- [Player] = { npcId, currentNodeId, dialogDef }
local QuestService = nil

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function getDialogDef(npcId)
	return Definitions.Dialogs[npcId]
end

local function buildContext(player, npcId)
	return {
		player = player,
		questService = QuestService,
		npcId = npcId,
	}
end

--- Find the first matching root node for this player
local function resolveRoot(player, dialogDef)
	local context = buildContext(player, dialogDef.npcId)

	for _, root in ipairs(dialogDef.roots) do
		if Conditions.EvaluateAll(context, root.conditions) then
			return root.nodeId
		end
	end

	return nil
end

--- Filter options by conditions, returning only the ones the player can see
local function filterOptions(player, npcId, options)
	if not options then
		return {}
	end

	local context = buildContext(player, npcId)
	local visible = {}

	for _, option in ipairs(options) do
		if Conditions.EvaluateAll(context, option.conditions) then
			table.insert(visible, {
				text = option.text,
				index = #visible + 1,
			})
		end
	end

	return visible
end

--- Build the payload to send to the client for a given node
local function buildNodePayload(player, npcId, dialogDef, nodeId)
	local node = dialogDef.nodes[nodeId]
	if not node then
		return nil
	end

	local visibleOptions = filterOptions(player, npcId, node.options)

	return {
		npcId = npcId,
		npcDisplayName = dialogDef.displayName or npcId,
		nodeId = nodeId,
		npcText = node.npcText,
		options = visibleOptions,
	}
end

--- Get the raw option definition by matching the visible index back to the
--- original options array (accounting for condition-filtered options)
local function getRawOptionByVisibleIndex(player, npcId, options, visibleIndex)
	if not options then
		return nil
	end

	local context = buildContext(player, npcId)
	local count = 0

	for _, option in ipairs(options) do
		if Conditions.EvaluateAll(context, option.conditions) then
			count += 1
			if count == visibleIndex then
				return option
			end
		end
	end

	return nil
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

function DialogService:OpenDialog(player, npcId)
	-- Close any existing dialog first
	self:CloseDialog(player)

	local dialogDef = getDialogDef(npcId)
	if not dialogDef then
		warn("[DialogService] No dialog definition for NPC:", npcId)
		return false
	end

	local rootNodeId = resolveRoot(player, dialogDef)
	if not rootNodeId then
		warn("[DialogService] No matching root for", npcId, "player:", player.Name)
		return false
	end

	local node = dialogDef.nodes[rootNodeId]
	if not node then
		warn("[DialogService] Root points to missing node:", rootNodeId)
		return false
	end

	-- Set active dialog
	ActiveDialogs[player] = {
		npcId = npcId,
		currentNodeId = rootNodeId,
		dialogDef = dialogDef,
	}

	-- Run node entry actions
	local context = buildContext(player, npcId)
	Actions.Run(context, node.actions)

	-- Send node to client
	local payload = buildNodePayload(player, npcId, dialogDef, rootNodeId)
	if payload then
		DialogRemotes.GetRemoteEvent("DialogOpened"):FireClient(player, payload)
	end

	return true
end

function DialogService:SelectOption(player, optionIndex)
	local active = ActiveDialogs[player]
	if not active then
		return
	end

	local dialogDef = active.dialogDef
	local currentNode = dialogDef.nodes[active.currentNodeId]
	if not currentNode then
		self:CloseDialog(player)
		return
	end

	-- Resolve which raw option this visible index maps to
	local rawOption = getRawOptionByVisibleIndex(
		player, active.npcId, currentNode.options, optionIndex
	)

	if not rawOption then
		warn("[DialogService] Invalid option index:", optionIndex, "for node:", active.currentNodeId)
		return
	end

	-- Run option actions
	local context = buildContext(player, active.npcId)
	Actions.Run(context, rawOption.actions)

	-- Navigate to next node or close
	local nextNodeId = rawOption.nextNode
	if not nextNodeId then
		-- End of dialog
		self:CloseDialog(player)
		return
	end

	local nextNode = dialogDef.nodes[nextNodeId]
	if not nextNode then
		warn("[DialogService] Option points to missing node:", nextNodeId)
		self:CloseDialog(player)
		return
	end

	-- Update state
	active.currentNodeId = nextNodeId

	-- Run next node's entry actions
	Actions.Run(context, nextNode.actions)

	-- Send new node to client
	local payload = buildNodePayload(player, active.npcId, dialogDef, nextNodeId)
	if payload then
		DialogRemotes.GetRemoteEvent("DialogOpened"):FireClient(player, payload)
	end
end

function DialogService:CloseDialog(player)
	if ActiveDialogs[player] then
		ActiveDialogs[player] = nil
		DialogRemotes.GetRemoteEvent("DialogClosed"):FireClient(player)
	end
end

function DialogService:IsInDialog(player)
	return ActiveDialogs[player] ~= nil
end

function DialogService:RequestDialog(player, npcId)
	if type(npcId) ~= "string" then return end
	if self:IsInDialog(player) then return end -- already talking
	self:OpenDialog(player, npcId)
end
------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function DialogService:Init(questService)
	assert(questService, "[DialogService] QuestService is required")
	QuestService = questService

	DialogRemotes.Init()

	local RequestDialog = DialogRemotes.GetRemoteEvent("RequestDialog")
	local SelectOption = DialogRemotes.GetRemoteEvent("SelectOption")
	local CloseDialog = DialogRemotes.GetRemoteEvent("CloseDialog")

	RequestDialog.OnServerEvent:Connect(function(player, npcId)
		DialogService:RequestDialog(player, npcId)
	end)

	SelectOption.OnServerEvent:Connect(function(player, optionIndex)
		if type(optionIndex) ~= "number" then return end
		self:SelectOption(player, optionIndex)
	end)

	CloseDialog.OnServerEvent:Connect(function(player)
		self:CloseDialog(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		ActiveDialogs[player] = nil
	end)
end

return DialogService
