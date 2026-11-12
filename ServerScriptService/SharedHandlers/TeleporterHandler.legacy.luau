local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local TeleporterRequestEvent = Remotes:WaitForChild("TeleporterRequest")

local LOCATIONS = {
	Commissary = { cframe = CFrame.new(0,5,0) },
	Hangar = { cframe = CFrame.new(100,5,0) },
	HighSecurityLevelB = { cframe = CFrame.new(-136, 5, 1288) },
}

local FX_DURATION = 3
local FADE_TIME = 1.2

--==================================================
-- PATH HELPER
--==================================================
local function getObjectFromPath(path)
	local parts = string.split(path, ".")
	local current

	local firstPart = parts[1]
	if firstPart == "game" then
		current = game
		table.remove(parts, 1)
	elseif firstPart == "workspace" then
		current = workspace
		table.remove(parts, 1)
	elseif firstPart == "ReplicatedStorage" then
		current = game:GetService("ReplicatedStorage")
		table.remove(parts, 1)
	elseif firstPart == "ServerScriptService" then
		current = game:GetService("ServerScriptService")
		table.remove(parts, 1)
	else
		current = workspace
	end

	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then 
			warn("Could not find '" .. part .. "' in path:", path)
			return nil 
		end
	end

	return current
end

--==================================================
-- TELEPORT
--==================================================
local function teleport(player, id)
	local loc = LOCATIONS[id]
	if not loc then return end

	local char = player.Character
	if not char then return end

	char:PivotTo(loc.cframe)
end

--==================================================
-- PARTICLE HELPERS
--==================================================
local function setEmittersEnabled(root: Instance, enabled: boolean)
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("ParticleEmitter") then
			desc.Enabled = enabled
		end
	end
end

local function cloneFXAtCFrame(fxTemplate: Instance, cf: CFrame, duration: number)
	local fxClone = fxTemplate:Clone()

	if fxClone:IsA("BasePart") then
		fxClone.Anchored = true
		fxClone.CanCollide = false
		fxClone.CFrame = cf
	elseif fxClone:IsA("Model") then
		fxClone:PivotTo(cf)
		for _, d in ipairs(fxClone:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
	end

	fxClone.Parent = workspace
	setEmittersEnabled(fxClone, true)

	task.delay(duration, function()
		if fxClone then
			setEmittersEnabled(fxClone, false)
		end
	end)

	Debris:AddItem(fxClone, duration + 2)
end

--==================================================
-- CHARACTER FADE
--==================================================
local function getFadeObjects(char)
	local objs = {}

	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("MeshPart") then
			table.insert(objs, d)
		elseif d:IsA("Decal") then
			table.insert(objs, d)
		end
	end

	return objs
end

local function fadeCharacter(char, targetTransparency, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	for _, obj in ipairs(getFadeObjects(char)) do
		if obj and obj.Parent then
			TweenService:Create(obj, tweenInfo, {
				Transparency = targetTransparency
			}):Play()
		end
	end

	task.wait(duration)
end

--==================================================
-- MAIN TELEPORT FX
--==================================================
local function teleporterFX(player, teleporterPath, id)
	local teleporter = getObjectFromPath(teleporterPath)
	if not teleporter then return end

	local loc = LOCATIONS[id]
	if not loc then return end

	local FXPart = teleporter:FindFirstChild("FX")
	if not FXPart then return end

	local char = player.Character
	if not char then return end

	local sourceCF
	if FXPart:IsA("BasePart") then
		sourceCF = FXPart.CFrame
	elseif FXPart:IsA("Model") then
		sourceCF = FXPart:GetPivot()
	else
		sourceCF = teleporter:GetPivot()
	end

	-- SOURCE FX
	cloneFXAtCFrame(FXPart, sourceCF, FX_DURATION)

	-- FADE OUT
	fadeCharacter(char, 1, FADE_TIME)

	-- TELEPORT
	teleport(player, id)

	-- DESTINATION FX, same rotation as original FXPart
	local originalRotation = sourceCF - sourceCF.Position
	local destinationFXCFrame = CFrame.new(loc.cframe.Position) * originalRotation

	cloneFXAtCFrame(FXPart, destinationFXCFrame, FADE_TIME)

	task.wait(0.25)

	-- FADE IN
	fadeCharacter(char, 0, FADE_TIME)
end

--==================================================
-- EVENT
--==================================================
TeleporterRequestEvent.OnServerEvent:Connect(function(player, teleporterPath, id)
	if typeof(id) ~= "string" then return end

	teleporterFX(player, teleporterPath, id)
end)