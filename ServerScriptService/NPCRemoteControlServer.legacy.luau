-- NPCRemoteControlServer.server.lua
-- Place in ServerScriptService
-- Thin script: just wires up RemoteEvents and delegates to NPCRemoteControlModule

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NPCRemoteControlFunctions = require(ServerScriptService.SharedFunctions.NPCRemoteControlFunctions)

local NPCRemoteControl = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("NPCRemoteControl")
local ReleaseControl = NPCRemoteControl:WaitForChild("ReleaseControl")
local SendInput      = NPCRemoteControl:WaitForChild("SendInput")

local CONFIG = {
	MAX_CONTROL_DISTANCE = 20,
}

------------------------------------------------------------------
-- ReleaseControl
------------------------------------------------------------------
ReleaseControl.OnServerEvent:Connect(function(player)
	local npc = NPCRemoteControlFunctions.getNpcOf(player)
	if npc then
		NPCRemoteControlFunctions.revokeControl(npc, "released")
	end
end)

------------------------------------------------------------------
-- SendInput
------------------------------------------------------------------
SendInput.OnServerEvent:Connect(function(player, moveDir, jumpRequested, sprintHeld)
	local npc = NPCRemoteControlFunctions.getNpcOf(player)
	if not npc or not npc.Parent then return end

	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		NPCRemoteControlFunctions.revokeControl(npc, "npc_died")
		return
	end

	-- Sanitize moveDir
	if typeof(moveDir) ~= "Vector3" then moveDir = Vector3.zero end
	moveDir = Vector3.new(
		math.clamp(moveDir.X, -1, 1),
		0,
		math.clamp(moveDir.Z, -1, 1)
	)

	-- Apply speed from enemy definition if available
	local enemyDef = {}
	pcall(function()
		local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
		enemyDef = enemiesModule[npc.Name] or {}
	end)
	local walkSpeed = enemyDef.RunSpeed or 10
	local runSpeed  = enemyDef.RunSpeed  or 16
	hum.WalkSpeed   = sprintHeld and runSpeed or walkSpeed

	-- Move (world space — client already rotated by camYaw)
	if moveDir.Magnitude > 0 then
		hum:Move(moveDir, false)
	else
		hum:Move(Vector3.zero)
	end

	-- Jump
	--if jumpRequested
	--	and hum:GetState() ~= Enum.HumanoidStateType.Jumping
	--	and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
	--	hum.Jump = true
	--end
end)