--For metal detecting, ghost detecting, and clue detecting

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DetectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Detect")
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:wait()

local detectorSound = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("DetectorSound")
local detectorEmitter = nil

local detector = nil
local heartBeat = nil
local metalDetect = nil
local ghostDetect = nil
local step_counter = 0
local timeChangeInterval = 1

LocalPlayer.CharacterAdded:Connect(function(character)
	char = character
end)

local function MetalDetectEventHandler(signalStrength,eventDetector)
	
	if (detector ~= eventDetector) then
		return
	end
	
	local detectorGui = char.MetalDetector.SurfaceGui

	if (not detectorGui) then
		return
	end
	
	if (signalStrength == "1") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = false
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "2") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "3") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "4") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = true
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "5") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = true
		detectorGui.signal5.Visible = true
	else
		detectorGui.signal1.Visible = false
		detectorGui.signal2.Visible = false
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	end
end

local function GhostDetectEventHandler(signalStrength,eventDetector)
	
	if (detector ~= eventDetector) then
		return
	end
	
	local detectorGui = char.GhostDetector.SurfaceGui

	if (not detectorGui) then
		return
	end

	if (signalStrength == "1") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = false
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "2") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "3") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "4") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = true
		detectorGui.signal5.Visible = false
	elseif (signalStrength == "5") then
		detectorGui.signal1.Visible = true
		detectorGui.signal2.Visible = true
		detectorGui.signal3.Visible = true
		detectorGui.signal4.Visible = true
		detectorGui.signal5.Visible = true
	else
		detectorGui.signal1.Visible = false
		detectorGui.signal2.Visible = false
		detectorGui.signal3.Visible = false
		detectorGui.signal4.Visible = false
		detectorGui.signal5.Visible = false
	end
end

local function HeartBeatHandler(step)
	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval

		if (detectorEmitter) then
			detectorEmitter:Emit(1)		
		end

		--if (detectorSound) then
		--	game:GetService("SoundService"):PlayLocalSound(detectorSound)
		--end

		DetectEvent:FireServer(false,detector)


	end
end

local function MetalDetectorEquipped()
	detector="MetalDetector"
	detectorEmitter = char.MetalDetector.Bottom.MetalDetectorPulse
	detectorEmitter.Enabled = true 

	metalDetect = DetectEvent.OnClientEvent:Connect(MetalDetectEventHandler)
	heartBeat = RunService.Heartbeat:Connect(HeartBeatHandler)
end

local function MetalDetectorUnequipped()
	detector=""
	
	if (detectorEmitter) then
		detectorEmitter.Enabled = false
	end
	
	detectorEmitter = nil

	if (heartBeat) then
		heartBeat:Disconnect()
	end
	if (metalDetect) then
		metalDetect:Disconnect()
	end
end

local function GhostDetectorEquipped()
	detector="GhostDetector"
	--detectorEmitter = char.GhostDetector:FindFirstChild("GhostDetectorPulse",true)
	--detectorEmitter.Enabled = true 

	ghostDetect = DetectEvent.OnClientEvent:Connect(GhostDetectEventHandler)
	heartBeat = RunService.Heartbeat:Connect(HeartBeatHandler)
end

local function GhostDetectorUnequipped()
	detector=""

	if (detectorEmitter) then
		detectorEmitter.Enabled = false
	end

	detectorEmitter = nil

	if (heartBeat) then
		heartBeat:Disconnect()
	end
	if (ghostDetect) then
		ghostDetect:Disconnect()
	end
end

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName,slot)
	if (toolName == "MetalDetector") then
		GhostDetectorUnequipped()
		MetalDetectorEquipped()
	elseif (toolName == "GhostDetector") then
		MetalDetectorUnequipped()
		GhostDetectorEquipped()
	else
		MetalDetectorUnequipped()
		GhostDetectorUnequipped()
	end
end)
