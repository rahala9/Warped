-- ShipWeaponInput.client.lua
-- Sends client ship CFrame + client muzzle local CFrames (sorted) to server
-- UPDATED: also sends fireTime (server-synced clock) + client ship linear velocity for lag compensation

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ShipHUDGui = PlayerGui:WaitForChild("FlightHUDGui")
local PowerPanel = ShipHUDGui:WaitForChild("PowerPanel")

local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local ShipFireWeapon = Remotes:FindFirstChild("ShipFireWeapon")
if not ShipFireWeapon then
	warn("[ShipWeaponInput] ShipFireWeapon remote not found")
	return
end

local PRIMARY_FIRE_KEY = Enum.KeyCode.F
local SECONDARY_FIRE_MOUSE = Enum.UserInputType.MouseButton1
local fireDebounce = 0.15

local DEFAULT_PRIMARY_WEAPON_NAME = "Small Laser Cannon"

local currentShip = nil
local canFire = true

local function GetWeaponNameForSlot(ship, slot)
	local wc = ship:FindFirstChild("WeaponConfiguration")
	if wc then
		local sv = wc:FindFirstChild(slot)
		if sv and sv:IsA("StringValue") and sv.Value ~= "" then
			return sv.Value
		end
	end
	return DEFAULT_PRIMARY_WEAPON_NAME
end

local function GetWeaponFirePointsClient(ship, weaponName)
	local firePoints = {}
	local weaponPattern = (weaponName or ""):gsub(" ", "")

	for _, d in ipairs(ship:GetDescendants()) do
		if d:IsA("Attachment") and d.Name:find(weaponPattern) then
			table.insert(firePoints, d)
		end
	end

	table.sort(firePoints, function(a, b)
		return a.Name < b.Name
	end)

	return firePoints
end

local function FireWeapon(weaponSlot)
	if not PlayerState.IsFlying then return end
	if not currentShip then return end
	if not canFire then return end

	local primary = currentShip.PrimaryPart
	if not primary then return end

	canFire = false
	task.delay(fireDebounce, function()
		canFire = true
	end)

	local camera = workspace.CurrentCamera
	if not camera then return end

	local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * 10000)

	-- Snapshot at fire time (client POV)
	local shipCFrame = primary.CFrame
	local shipLinVel = primary.AssemblyLinearVelocity
	local shipAngVel = primary.AssemblyAngularVelocity -- optional (not required for position compensation)
	local fireTime = workspace:GetServerTimeNow() -- server-synced clock on client

	local weaponName = GetWeaponNameForSlot(currentShip, weaponSlot == "Secondary" and "Secondary" or "Primary")
	local firePoints = GetWeaponFirePointsClient(currentShip, weaponName)

	local muzzlesLocalCF = nil
	if #firePoints > 0 then
		muzzlesLocalCF = table.create(#firePoints)
		for i, att in ipairs(firePoints) do
			muzzlesLocalCF[i] = shipCFrame:ToObjectSpace(att.WorldCFrame)
		end
	end

	-- UPDATED ARG LIST:
	-- (ship, slot, targetPos, clientShipCFrame, clientMuzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
	ShipFireWeapon:FireServer(currentShip, weaponSlot, targetPos, shipCFrame, muzzlesLocalCF, fireTime, shipLinVel, shipAngVel)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not PlayerState.IsFlying then return end
	if PowerPanel.Visible then return end

	if input.KeyCode == PRIMARY_FIRE_KEY then
		FireWeapon("Primary")
	elseif input.UserInputType == SECONDARY_FIRE_MOUSE then
		FireWeapon("Secondary")
	end
end)

local SetPilotedShip = Remotes:FindFirstChild("SetPilotedShip")
if SetPilotedShip then
	SetPilotedShip.OnClientEvent:Connect(function(ship)
		currentShip = ship
	end)
end
