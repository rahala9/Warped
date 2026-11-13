local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent:WaitForChild("Config"))
local Viewmodel = require(script.Parent:WaitForChild("Viewmodel"))
local PlayerState = require(script.Parent.Parent:WaitForChild("PlayerStateFunctions"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local CurrentHeldToolChangedEvent = remotes:WaitForChild("CurrentHeldToolChanged")
local items = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local weaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local activeWeaponName = nil
local activeWeaponDefinition = nil
local activeSettings = nil
local viewmodel = nil
local firstPersonActive = false
local preferredFirstPerson = Config.EnterOnEquip
local buildGeneration = 0
local hiddenParts = {}
local descendantAddedConnection = nil

local savedCameraMode = nil
local savedFieldOfView = nil
local exitFirstPerson = nil

player:SetAttribute("FirstPersonActive", false)

local function audit(message, ...)
	if Config.AuditEnabled then
		print(string.format("[FirstPersonSystem %s] %s", Config.SystemVersion, message), ...)
	end
end

local function auditWarning(message, ...)
	warn(string.format("[FirstPersonSystem %s] %s", Config.SystemVersion, message), ...)
end

audit("controller started")

local function currentCamera(): Camera
	return workspace.CurrentCamera
end

local function hidePart(part)
	if not part:IsA("BasePart") then
		return
	end

	if hiddenParts[part] == nil then
		hiddenParts[part] = part.LocalTransparencyModifier
	end
	part.LocalTransparencyModifier = 1
end

local function setCharacterHidden(hidden)
	if descendantAddedConnection then
		descendantAddedConnection:Disconnect()
		descendantAddedConnection = nil
	end

	if hidden then
		for _, descendant in ipairs(character:GetDescendants()) do
			hidePart(descendant)
		end

		descendantAddedConnection = character.DescendantAdded:Connect(hidePart)
	else
		for part, previousTransparency in pairs(hiddenParts) do
			if part.Parent then
				part.LocalTransparencyModifier = previousTransparency
			end
		end
		table.clear(hiddenParts)
	end
end

local function destroyViewmodel()
	buildGeneration += 1
	weaponInfo.SetPresentationWeaponSource(nil, nil)
	if viewmodel then
		viewmodel:Destroy()
		viewmodel = nil
	end
end

local function buildViewmodel()
	destroyViewmodel()

	if not firstPersonActive or not activeWeaponName or not activeSettings then
		return
	end

	local generation = buildGeneration
	task.spawn(function()
		task.wait(Config.EquipBuildDelay)
		if generation ~= buildGeneration
			or not firstPersonActive
			or not activeWeaponName
		then
			return
		end

		local newViewmodel = nil
		local reason = nil
		local deadline = os.clock() + Config.BuildTimeout
		local attempts = 0

		repeat
			attempts += 1
			newViewmodel, reason = Viewmodel.new(
				currentCamera(),
				character,
				activeWeaponName,
				activeWeaponDefinition,
				activeSettings
			)

			if newViewmodel
				or generation ~= buildGeneration
				or not firstPersonActive
			then
				break
			end

			if attempts == 1 then
				audit("viewmodel build waiting", activeWeaponName, reason)
			end

			task.wait(Config.BuildRetryInterval)
		until os.clock() >= deadline

		if generation ~= buildGeneration then
			if newViewmodel then
				newViewmodel:Destroy()
			end
			return
		end

		viewmodel = newViewmodel
		if not viewmodel then
			auditWarning("viewmodel build failed", activeWeaponName, reason, "attempts", attempts)
			if exitFirstPerson then
				exitFirstPerson("viewmodel build failed")
			end
		else
			local diagnostics = viewmodel:GetDiagnostics()
			audit(
				"viewmodel ready",
				activeWeaponName,
				"source", diagnostics.Source,
				"sourceClass", diagnostics.SourceClass,
				"anchor", diagnostics.Anchor,
				"anchorClass", diagnostics.AnchorClass,
				"descendants", diagnostics.DescendantCount,
				"muzzleOffset", activeSettings.MuzzleOffset.Position
			)
		end
	end)
end

local function cameraCanRenderViewmodel(camera)
	if not camera or camera.CameraType == Enum.CameraType.Scriptable then
		return false
	end

	local subject = camera.CameraSubject
	return subject == humanoid
		or (subject ~= nil and subject:IsDescendantOf(character))
end

local function cameraIsFirstPerson(camera)
	if not camera or camera.CameraType == Enum.CameraType.Scriptable then
		return false
	end

	if player.CameraMode == Enum.CameraMode.LockFirstPerson then
		return true
	end

	-- Roblox's classic camera approaches its subject as the player scrolls in.
	-- Focus distance is rig-independent, so this also works with the custom
	-- skinned character whose Head is a Bone rather than a BasePart.
	return (camera.CFrame.Position - camera.Focus.Position).Magnitude <= 1.1
end

local function onRenderStep(deltaTime)
	local camera = currentCamera()
	local canRender = cameraCanRenderViewmodel(camera)

	-- The default camera can rewrite LocalTransparencyModifier while zooming;
	-- enforce the first-person-only character visibility after it updates.
	for part in pairs(hiddenParts) do
		if part.Parent then
			part.LocalTransparencyModifier = 1
		end
	end

	if not viewmodel then
		return
	end

	viewmodel:SetCamera(camera)
	viewmodel:SetVisible(canRender)
	if canRender then
		viewmodel:Update(deltaTime, humanoid.MoveDirection.Magnitude)
		weaponInfo.SetPresentationWeaponSource(
			viewmodel:GetMuzzleCFrame(),
			activeWeaponName,
			viewmodel:GetMuzzleInstance()
		)
	else
		weaponInfo.SetPresentationWeaponSource(nil, nil)
	end
end

local function enterFirstPerson()
	if firstPersonActive
		or not Config.Enabled
		or not activeSettings
		or activeSettings.Enabled == false
	then
		return
	end

	local camera = currentCamera()
	audit(
		"entering first person",
		activeWeaponName,
		"cameraType", camera.CameraType.Name,
		"cameraSubject", camera.CameraSubject and camera.CameraSubject:GetFullName() or "nil"
	)
	firstPersonActive = true
	player:SetAttribute("FirstPersonActive", true)
	savedCameraMode = player.CameraMode
	savedFieldOfView = camera.FieldOfView
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	camera.FieldOfView = Config.FieldOfView
	setCharacterHidden(true)
	buildViewmodel()
	RunService:BindToRenderStep(Config.RenderStepName, Config.RenderPriority, onRenderStep)
end

exitFirstPerson = function(reason)
	if not firstPersonActive then
		return
	end

	audit("exiting first person", reason or "requested")
	firstPersonActive = false
	player:SetAttribute("FirstPersonActive", false)
	RunService:UnbindFromRenderStep(Config.RenderStepName)
	destroyViewmodel()
	setCharacterHidden(false)

	player.CameraMode = savedCameraMode or Enum.CameraMode.Classic
	local camera = currentCamera()
	if savedFieldOfView then
		camera.FieldOfView = savedFieldOfView
	end

	savedCameraMode = nil
	savedFieldOfView = nil
end

local function setWeapon(toolName)
	audit("held tool changed", tostring(toolName))
	activeWeaponName = nil
	activeWeaponDefinition = nil
	activeSettings = nil

	local definition = toolName ~= "" and items[toolName] or nil
	if definition and definition.Aim == true then
		activeWeaponName = toolName
		activeWeaponDefinition = definition
		activeSettings = Config.ResolveWeapon(toolName, definition)
	end

	if not definition then
		audit("tool has no item definition", tostring(toolName))
	elseif definition.Aim ~= true then
		audit("tool is not configured as an aiming weapon", tostring(toolName))
	else
		audit("aiming weapon accepted", toolName, "model", tostring(definition.Model))
	end

	if not activeWeaponName or activeSettings.Enabled == false then
		exitFirstPerson()
		return
	end

	if preferredFirstPerson then
		if firstPersonActive then
			buildViewmodel()
		else
			enterFirstPerson()
		end
	elseif cameraIsFirstPerson(currentCamera()) then
		preferredFirstPerson = true
		enterFirstPerson()
	else
		exitFirstPerson()
	end
end

local function toggleFirstPerson(_actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	audit("toggle action received", "active", firstPersonActive, "weapon", tostring(activeWeaponName))

	-- Exiting must never depend on equip state; otherwise an out-of-order tool
	-- event could leave CameraMode locked with no active weapon reference.
	if firstPersonActive then
		preferredFirstPerson = false
		exitFirstPerson("toggle input")
		return Enum.ContextActionResult.Sink
	end

	if not activeWeaponName then
		return Enum.ContextActionResult.Pass
	end

	preferredFirstPerson = true
	enterFirstPerson()

	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
	Config.ToggleActionName,
	toggleFirstPerson,
	false,
	Enum.ContextActionPriority.High.Value,
	table.unpack(Config.ToggleInputs)
)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return
	end

	if Config.ExitOnZoomOut
		and firstPersonActive
		and input.Position.Z < 0
	then
		preferredFirstPerson = false
		exitFirstPerson("mouse wheel zoom out")
	elseif not firstPersonActive
		and activeWeaponName
		and input.Position.Z > 0
	then
		-- Let Roblox update the classic camera for this wheel tick, then start
		-- presentation only if the player has actually reached first person.
		task.spawn(function()
			RunService.RenderStepped:Wait()
			if not firstPersonActive
				and activeWeaponName
				and cameraIsFirstPerson(currentCamera())
			then
				preferredFirstPerson = true
				enterFirstPerson()
			end
		end)
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if firstPersonActive and input.KeyCode == Config.EmergencyExitKey then
		preferredFirstPerson = false
		exitFirstPerson("emergency exit key")
	end
end)

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName)
	setWeapon(toolName)
end)

-- Handle a weapon that was already equipped before this LocalScript finished
-- initializing, while the remote event remains the source of later changes.
task.defer(function()
	if PlayerState.CurrentTool then
		setWeapon(PlayerState.CurrentTool)
	end
end)

task.spawn(function()
	local ProjectilePresentationEvent = remotes:WaitForChild("ProjectilePresentation", 10)
	if not ProjectilePresentationEvent then
		auditWarning("ProjectilePresentation remote was not created; confirmed recoil is unavailable")
		return
	end

	ProjectilePresentationEvent.OnClientEvent:Connect(function(shooter, weaponName)
		if shooter == player
			and weaponName == activeWeaponName
			and firstPersonActive
			and viewmodel
		then
			viewmodel:AddRecoil(1)
		end
	end)
end)

player.CharacterAdded:Connect(function(newCharacter)
	exitFirstPerson()
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	activeWeaponName = nil
	activeWeaponDefinition = nil
	activeSettings = nil
end)
