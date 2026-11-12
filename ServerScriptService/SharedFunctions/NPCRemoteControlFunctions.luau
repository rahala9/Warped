-- NPCRemoteControlModule.lua
-- ModuleScript in ServerScriptService
-- Handles NPC control state, network ownership, and AI pause signaling
-- Call grantControl/revokeControl from terminal handlers or any server script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NPCRemoteControl = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("NPCRemoteControl")
local ControlGranted = NPCRemoteControl:WaitForChild("ControlGranted")
local ControlRevoked = NPCRemoteControl:WaitForChild("ControlRevoked")

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local npcToController = {}  -- [npc]    = player
local playerToNpc     = {}  -- [player] = npc

------------------------------------------------------------------
-- Private helpers
------------------------------------------------------------------
local function getHRP(npc)
	return npc:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(npc)
	return npc:FindFirstChildOfClass("Humanoid")
end

------------------------------------------------------------------
-- Module
------------------------------------------------------------------
local NPCRemoteControl = {}

function NPCRemoteControl.isControllable(npc)
	local flag = npc:FindFirstChild("RemoteControllable")
	if flag and flag:IsA("BoolValue") and flag.Value then return true end
	local ok, tagged = pcall(function()
		return game:GetService("CollectionService"):HasTag(npc, "RemoteControllable")
	end)
	return ok and tagged
end

function NPCRemoteControl.getControllerOf(npc)
	return npcToController[npc]
end

function NPCRemoteControl.getNpcOf(player)
	return playerToNpc[player]
end

function NPCRemoteControl.revokeControl(npc, reason)
	local controller = npcToController[npc]
	if not controller then return end

	npcToController[npc] = nil
	playerToNpc[controller] = nil

	-- Restore server network ownership
	local hrp = getHRP(npc)
	if hrp then
		pcall(function() hrp:SetNetworkOwner(nil) end)
	end

	-- Signal AI script to resume
	npc:SetAttribute("RemoteControlled", false)
	npc:SetAttribute("RemoteController", nil)

	-- Stop lingering movement
	local hum = getHumanoid(npc)
	if hum then
		pcall(function() hum:Move(Vector3.zero) end)
	end

	-- Notify client
	if controller and controller.Parent then
		ControlRevoked:FireClient(controller, npc, reason or "released")
	end

	print(("[NPCRemoteControl] %s released control of %s (%s)"):format(
		controller and controller.Name or "?", npc.Name, reason or "released"))
end

function NPCRemoteControl.grantControl(player, npc)
	if not npc or not npc.Parent then
		warn("[NPCRemoteControl] grantControl called with invalid npc")
		return false
	end

	-- Revoke any existing control this player has
	local oldNpc = playerToNpc[player]
	if oldNpc then
		NPCRemoteControl.revokeControl(oldNpc, "switched")
	end

	-- Revoke any existing controller for this NPC
	local oldController = npcToController[npc]
	if oldController then
		NPCRemoteControl.revokeControl(npc, "taken")
	end

	npcToController[npc] = player
	playerToNpc[player]  = npc

	-- Give network ownership to player for smooth movement
	local hrp = getHRP(npc)
	if hrp then
		pcall(function() hrp:SetNetworkOwner(player) end)
	end

	-- Signal AI script to pause
	npc:SetAttribute("RemoteControlled", true)
	npc:SetAttribute("RemoteController", player.UserId)

	-- Notify client
	ControlGranted:FireClient(player, npc)

	print(("[NPCRemoteControl] %s took control of %s"):format(player.Name, npc.Name))
	return true
end

------------------------------------------------------------------
-- Cleanup when player leaves
------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	local npc = playerToNpc[player]
	if npc then
		NPCRemoteControl.revokeControl(npc, "player_left")
	end
end)

------------------------------------------------------------------
-- Cleanup when NPC is removed (polled each heartbeat)
------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	for npc, controller in pairs(npcToController) do
		if not npc.Parent then
			npcToController[npc] = nil
			playerToNpc[controller] = nil
			if controller and controller.Parent then
				ControlRevoked:FireClient(controller, nil, "npc_destroyed")
			end
		end
	end
end)

return NPCRemoteControl