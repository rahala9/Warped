-- StarterPlayerScripts/ShipPilot.client.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")

local InputRemote = Remotes:WaitForChild("ShipPilotInput")

-- Server -> client: tells us which ship we are piloting (Model or nil)
local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")
if not SetPilotedShip then
	-- will exist on server; this is just a safe wait
	SetPilotedShip = Remotes:WaitForChild("SetPilotedShip")
end

------------------------------------------------------------
-- Tuning
------------------------------------------------------------
local SEND_HZ = 20
local MOUSE_SENS = 0.0025
local MOUSE_DECAY = 0.85
local ROLL_RATE = 1.0

------------------------------------------------------------
-- Current piloted ship (set by server)
------------------------------------------------------------
local currentShip: Model? = nil
SetPilotedShip.OnClientEvent:Connect(function(ship: Model?)
	currentShip = ship
end)

------------------------------------------------------------
-- Input state
------------------------------------------------------------
local input = {
	throttle = 0, strafe = 0, lift = 0,
	pitch = 0, yaw = 0, roll = 0,
	boost = false,
}

local keysDown: {[Enum.KeyCode]: boolean} = {}
local function isDown(key: Enum.KeyCode) return keysDown[key] == true end

------------------------------------------------------------
-- Jump suppression (Space = UP thrust, do not jump out)
------------------------------------------------------------
local BLOCK_JUMP_ACTION = "ShipPilotBlockJump"
local ACTION_PRIORITY = 3000

local function setJumpBlocked(block: boolean)
	if block then
		ContextActionService:BindActionAtPriority(
			BLOCK_JUMP_ACTION,
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			ACTION_PRIORITY,
			Enum.KeyCode.Space
		)
	else
		ContextActionService:UnbindAction(BLOCK_JUMP_ACTION)
	end
end

------------------------------------------------------------
-- Input events
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(io, gp)
	if gp then return end
	if io.KeyCode ~= Enum.KeyCode.Unknown then
		keysDown[io.KeyCode] = true
	end
	if io.KeyCode == Enum.KeyCode.LeftShift then
		input.boost = true
	end
end)

UserInputService.InputEnded:Connect(function(io, gp)
	if gp then return end
	if io.KeyCode ~= Enum.KeyCode.Unknown then
		keysDown[io.KeyCode] = nil
	end
	if io.KeyCode == Enum.KeyCode.LeftShift then
		input.boost = false
	end
end)

UserInputService.InputChanged:Connect(function(io, gp)
	if gp then return end
	if not currentShip then return end

	if io.UserInputType == Enum.UserInputType.MouseMovement then
		input.yaw = math.clamp(io.Delta.X * MOUSE_SENS, -1, 1)
		input.pitch = math.clamp(-io.Delta.Y * MOUSE_SENS, -1, 1)
	end
end)

local function updateKeyAxes()
	local fwd = (isDown(Enum.KeyCode.W) and 1 or 0) + (isDown(Enum.KeyCode.S) and -1 or 0)
	local str = (isDown(Enum.KeyCode.D) and 1 or 0) + (isDown(Enum.KeyCode.A) and -1 or 0)
	local lift = (isDown(Enum.KeyCode.Space) and 1 or 0) + (isDown(Enum.KeyCode.LeftControl) and -1 or 0)

	input.throttle = math.clamp(fwd, -1, 1)
	input.strafe = math.clamp(str, -1, 1)
	input.lift = math.clamp(lift, -1, 1)

	local roll = (isDown(Enum.KeyCode.E) and 1 or 0) + (isDown(Enum.KeyCode.Q) and -1 or 0)
	input.roll = math.clamp(roll * ROLL_RATE, -1, 1)
end

local function decayMouseAxes()
	input.yaw *= MOUSE_DECAY
	input.pitch *= MOUSE_DECAY
	if math.abs(input.yaw) < 0.001 then input.yaw = 0 end
	if math.abs(input.pitch) < 0.001 then input.pitch = 0 end
end

------------------------------------------------------------
-- Main loop
------------------------------------------------------------
local nextSend = 0

RunService.RenderStepped:Connect(function(dt)
	setJumpBlocked(currentShip ~= nil)
	if not currentShip then return end

	updateKeyAxes()
	decayMouseAxes()

	nextSend -= dt
	if nextSend <= 0 then
		nextSend = 1 / SEND_HZ
		local cam = workspace.CurrentCamera
		if cam then
			-- Send camera CFrame so server can face camera + do camera-relative thrust
			InputRemote:FireServer(currentShip, input, cam.CFrame)
		else
			InputRemote:FireServer(currentShip, input, nil)
		end
	end
end)
