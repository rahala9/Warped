local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(
	ReplicatedStorage:WaitForChild("CargoRiskSystem"):WaitForChild("Config")
)
local PlayerMeterService = require(
	ServerScriptService:WaitForChild("PlayerMeterSystem"):WaitForChild("PlayerMeterService")
)
PlayerMeterService.Init()

local sharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local MessagePlayerEvent = sharedRemotes:WaitForChild("MessagePlayer")
local dockRemotes = sharedRemotes:FindFirstChild("DockRemotes")
if not dockRemotes then
	dockRemotes = Instance.new("Folder")
	dockRemotes.Name = "DockRemotes"
	dockRemotes.Parent = sharedRemotes
end
local riskChangedEvent = dockRemotes:FindFirstChild("CargoRiskChanged")
if not riskChangedEvent then
	riskChangedEvent = Instance.new("RemoteEvent")
	riskChangedEvent.Name = "CargoRiskChanged"
	riskChangedEvent.Parent = dockRemotes
end

local CargoRiskService = {}

local tracked = setmetatable({}, { __mode = "k" })
local UPDATE_INTERVAL = 0.25
local accumulatedTime = 0

local function getRiskSeverity(job, riskName)
	local risks = job.risks or {}
	local configuredSeverity = risks[riskName]
	if typeof(configuredSeverity) == "number" then
		local normalized = math.clamp(configuredSeverity, 0, 1)
		return normalized > 0 and normalized or nil
	elseif configuredSeverity == true then
		return 0.5
	end
	-- Temporary compatibility for any cached jobs created before the severity
	-- map migration.
	for _, configuredRisk in ipairs(risks) do
		if configuredRisk == riskName then return 0.5 end
	end
	return nil
end

local function getRiskNames(job)
	local names = {}
	for riskName, severity in pairs(job.risks or {}) do
		if typeof(riskName) == "string"
			and ((typeof(severity) == "number" and severity > 0) or severity == true)
		then
			table.insert(names, riskName)
		elseif typeof(riskName) == "number" and typeof(severity) == "string" then
			table.insert(names, severity)
		end
	end
	table.sort(names)
	return names
end

local function severityMultiplier(severity)
	return 0.75 + math.clamp(severity or 0, 0, 1) * 0.75
end

local function getStabilityRisks(job)
	local result = {}
	for riskName, behavior in pairs(Config.Stability.RiskTypes) do
		local severity = getRiskSeverity(job, riskName)
		if severity then
			table.insert(result, {
				name = riskName,
				severity = severity,
				behavior = behavior,
			})
		end
	end
	table.sort(result, function(a, b) return a.severity > b.severity end)
	return result
end

local function disconnectConnections(connections)
	for _, connection in ipairs(connections or {}) do
		connection:Disconnect()
	end
end

local function clearShipCollisionTracking(state)
	disconnectConnections(state.shipCollisionConnections)
	state.shipCollisionConnections = {}
	state.mountedShip = nil
end

local function clearCargoCollisionTracking(state)
	disconnectConnections(state.cargoCollisionConnections)
	state.cargoCollisionConnections = {}
end

local function getBiohazardStage(containment)
	for _, stage in ipairs(Config.Biohazardous.Stages) do
		if containment >= stage.MinimumContainment then return stage end
	end
	return Config.Biohazardous.Stages[#Config.Biohazardous.Stages]
end

local function publishState(state)
	if not state.player.Parent then return end
	riskChangedEvent:FireClient(state.player, state.jobKey, {
		broken = state.broken == true,
		stability = state.stability,
		stabilityLabel = state.stabilityLabel,
		stabilityTriggered = state.stabilityTriggered == true,
		containment = state.containment,
		containmentState = state.containment and getBiohazardStage(state.containment).Label or nil,
	})
end

local function failCargo(state, reason)
	if state.broken then return end
	state.broken = true
	state.cargo:SetAttribute("CargoBroken", true)
	publishState(state)
	state.onBroken(reason)
end

local function fireImportantMessage(player, message)
	MessagePlayerEvent:FireClient(player, message, nil, nil, nil, nil, nil, 10)
end

local function triggerStability(state)
	if state.stabilityTriggered then return end
	state.stabilityTriggered = true
	state.cargo:SetAttribute("CargoStabilityTriggered", true)

	local failureReason = nil
	for _, risk in ipairs(state.stabilityRisks) do
		local behavior = risk.behavior
		if behavior.ZeroAction == "FailContract" then
			failureReason = failureReason or behavior.ZeroMessage or "Cargo stability failed."
		elseif behavior.ZeroAction == "Message" then
			fireImportantMessage(
				state.player,
				string.format(
					"%s: %s",
					state.cargoName,
					behavior.ZeroMessage or "Cargo stability failed."
				)
			)
		end
	end

	if failureReason then
		failCargo(state, failureReason)
	else
		publishState(state)
	end
end

local function setStability(state, nextStability)
	if state.broken or state.stability == nil or state.stabilityTriggered then return end
	local clamped = math.clamp(nextStability, 0, Config.Stability.Maximum)
	if math.abs(clamped - state.stability) < 0.001 then return end
	state.stability = clamped
	state.cargo:SetAttribute("CargoStability", clamped)
	if clamped <= 0 then
		triggerStability(state)
	else
		publishState(state)
	end
end

local function setContainment(state, nextContainment)
	if state.broken or state.containment == nil then return end
	local maximum = Config.Biohazardous.MaximumContainment
	local clamped = math.clamp(nextContainment, 0, maximum)
	if math.abs(clamped - state.containment) < 0.001 then return end
	state.containment = clamped
	local stage = getBiohazardStage(clamped)
	state.cargo:SetAttribute("CargoContainment", clamped)
	state.cargo:SetAttribute("CargoContainmentState", stage.Label)
	publishState(state)
	if clamped <= 0 then failCargo(state, "Biohazard containment ruptured.") end
end

local function damageStability(state, amount)
	if amount <= 0 or state.stability == nil or state.stabilityTriggered then return end
	state.lastStabilityDamageAt = workspace:GetServerTimeNow()
	setStability(state, state.stability - amount)
end

local function recoverStability(state, amount)
	if amount <= 0 or state.stability == nil or state.stabilityTriggered then return end
	if workspace:GetServerTimeNow() - state.lastStabilityDamageAt < Config.Stability.RecoveryDelay then return end
	setStability(state, state.stability + amount)
end

local function damageContainment(state, amount)
	if amount > 0 then setContainment(state, (state.containment or 0) - amount) end
end

local function removeExposureSources(state)
	for exposedPlayer in pairs(state.exposedPlayers) do
		PlayerMeterService.RemoveRateSource(exposedPlayer, "Biohazard", state.exposureSourceKey)
	end
	state.exposedPlayers = {}
end

local function updateExposure(state)
	if state.containment == nil or state.broken then
		removeExposureSources(state)
		return
	end

	local cargoPart = state.cargo.PrimaryPart
	if not cargoPart then
		removeExposureSources(state)
		return
	end

	local stage = getBiohazardStage(state.containment)
	local rate = stage.ExposureRate * state.biohazardMultiplier
	if state.mountedShip then rate *= Config.Biohazardous.MountedExposureMultiplier end
	local currentlyExposed = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0
			and (root.Position - cargoPart.Position).Magnitude <= Config.Biohazardous.ExposureRadius
		then
			currentlyExposed[player] = true
			PlayerMeterService.SetRateSource(player, "Biohazard", state.exposureSourceKey, rate)
		end
	end

	for exposedPlayer in pairs(state.exposedPlayers) do
		if not currentlyExposed[exposedPlayer] then
			PlayerMeterService.RemoveRateSource(exposedPlayer, "Biohazard", state.exposureSourceKey)
		end
	end
	state.exposedPlayers = currentlyExposed
end

local function isExternalShipContact(state, otherPart)
	if not otherPart or not otherPart:IsA("BasePart") then return false end
	local ship = state.mountedShip
	if not ship or otherPart:IsDescendantOf(ship) or otherPart:IsDescendantOf(state.cargo) then
		return false
	end
	local character = state.player.Character
	if character and otherPart:IsDescendantOf(character) then return false end
	return true
end

local function handleShipCollision(state, otherPart)
	if state.broken or not isExternalShipContact(state, otherPart) then return end
	local primaryPart = state.mountedShip and state.mountedShip.PrimaryPart
	if not primaryPart
		or primaryPart.AssemblyLinearVelocity.Magnitude < Config.Stability.ShipCollisionMinimumSpeed
	then
		return
	end

	local now = workspace:GetServerTimeNow()
	if now - state.lastShipImpactAt < Config.Stability.ImpactCooldown then return end
	state.lastShipImpactAt = now

	-- Containment damage is applied first so combined stability + biohazardous
	-- cargo publishes its final containment state before a stability reaction.
	damageContainment(
		state,
		Config.Biohazardous.ShipCollisionContainmentDamage * state.biohazardMultiplier
	)
	if not state.broken and state.stability ~= nil and Config.Stability.ShipCollisionBreaks then
		setStability(state, 0)
	end
end

local function isExternalCargoContact(state, otherPart)
	if not otherPart or not otherPart:IsA("BasePart") then return false end
	if otherPart:IsDescendantOf(state.cargo) then return false end
	local character = state.player.Character
	if character and otherPart:IsDescendantOf(character) then return false end
	return true
end

local function handleFreeCargoCollision(state, otherPart)
	if state.broken or state.transportMode ~= "Free" then return end
	if not isExternalCargoContact(state, otherPart) then return end
	local now = workspace:GetServerTimeNow()
	if now - state.freeStartedAt < Config.Stability.FreeReleaseGrace
		or now - state.lastFreeImpactAt < Config.Stability.FreeImpactCooldown
	then
		return
	end

	local primaryPart = state.cargo.PrimaryPart
	if not primaryPart then return end
	local previousSpeed = state.lastFreeVelocity and state.lastFreeVelocity.Magnitude or 0
	local impactSpeed = math.max(previousSpeed, primaryPart.AssemblyLinearVelocity.Magnitude)
	if impactSpeed <= Config.Stability.FreeImpactThreshold then return end
	state.lastFreeImpactAt = now

	damageStability(
		state,
		(impactSpeed - Config.Stability.FreeImpactThreshold)
			* Config.Stability.FreeImpactDamageScale
			* state.stabilityMultiplier
	)
	damageContainment(
		state,
		(impactSpeed - Config.Biohazardous.ImpactThreshold)
			* Config.Biohazardous.ImpactContainmentScale
			* state.biohazardMultiplier
	)
end

local function trackCargoCollisions(state)
	clearCargoCollisionTracking(state)
	for _, descendant in ipairs(state.cargo:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(state.cargoCollisionConnections, descendant.Touched:Connect(function(otherPart)
				handleFreeCargoCollision(state, otherPart)
			end))
		end
	end
end

local function trackMountedShip(state, ship)
	if state.mountedShip == ship then return end
	clearShipCollisionTracking(state)
	if not ship or not ship:IsA("Model") then return end

	state.mountedShip = ship
	for _, descendant in ipairs(ship:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(state.shipCollisionConnections, descendant.Touched:Connect(function(otherPart)
				handleShipCollision(state, otherPart)
			end))
		end
	end
	state.lastCarrierVelocity = nil
end

local function getMountedShip(cargo)
	local reference = cargo:FindFirstChild("MountedShip")
	if reference and reference:IsA("ObjectValue") then return reference.Value end
	return nil
end

local function carrierHitObstacle(state, root, previousVelocity, deltaTime)
	if previousVelocity.Magnitude <= 0 then return false end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { state.player.Character, state.cargo }
	local castDistance = math.max(4, previousVelocity.Magnitude * deltaTime + 3)
	return workspace:Raycast(
		root.Position,
		previousVelocity.Unit * castDistance,
		raycastParams
	) ~= nil
end

local function getVariableRunStabilityDamage(state, deltaTime)
	local variation = Config.Stability.RunVariation
	local now = workspace:GetServerTimeNow()
	if now >= state.nextRunRateChangeAt then
		state.runRateMultiplier = state.random:NextNumber(
			variation.RateMultiplierMin,
			variation.RateMultiplierMax
		)
		state.nextRunRateChangeAt = now + state.random:NextNumber(
			variation.RateChangeIntervalMin,
			variation.RateChangeIntervalMax
		)
	end

	local damage = Config.Stability.RunDamagePerSecond
		* state.stabilityMultiplier
		* state.runRateMultiplier
		* deltaTime
	local instability = 1 - math.clamp(state.stability / Config.Stability.Maximum, 0, 1)
	local chanceMultiplier = 1
		+ (variation.LowStabilityBurstChanceMultiplier - 1) * instability
	local burstChance = 1 - math.exp(
		-variation.BurstChancePerSecond * chanceMultiplier * deltaTime
	)
	if now - state.lastRandomBurstAt >= variation.BurstCooldown
		and state.random:NextNumber() < burstChance
	then
		state.lastRandomBurstAt = now
		local damageMultiplier = 1
			+ (variation.LowStabilityBurstDamageMultiplier - 1) * instability
		damage += state.random:NextNumber(
			variation.BurstDamageMin,
			variation.BurstDamageMax
		) * damageMultiplier * state.stabilityMultiplier
	end

	return damage
end

local function updateCarriedRisk(state, deltaTime)
	if state.cargo:GetAttribute("HeldBy") ~= state.player.Name then
		state.lastCarrierVelocity = nil
		return
	end

	local character = state.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		state.lastCarrierVelocity = nil
		return
	end

	local planarSpeed = Vector3.new(
		root.AssemblyLinearVelocity.X,
		0,
		root.AssemblyLinearVelocity.Z
	).Magnitude
	if humanoid.MoveDirection.Magnitude > 0.05 then
		if planarSpeed >= Config.Stability.RunSpeedThreshold then
			if state.stability ~= nil then
				damageStability(state, getVariableRunStabilityDamage(state, deltaTime))
			end
			damageContainment(state, Config.Biohazardous.RunContainmentLossPerSecond * state.biohazardMultiplier * deltaTime)
		elseif planarSpeed >= Config.Stability.WalkSpeedThreshold then
			recoverStability(state, Config.Stability.WalkRecoveryPerSecond * deltaTime)
			damageContainment(state, Config.Biohazardous.WalkContainmentLossPerSecond * state.biohazardMultiplier * deltaTime)
		end
	else
		recoverStability(state, Config.Stability.IdleRecoveryPerSecond * deltaTime)
	end

	local velocity = root.AssemblyLinearVelocity
	if state.lastCarrierVelocity then
		local velocityChange = state.lastCarrierVelocity.Magnitude - velocity.Magnitude
		local now = workspace:GetServerTimeNow()
		if velocityChange > Config.Stability.ImpactThreshold
			and now - state.lastImpactAt >= Config.Stability.ImpactCooldown
			and carrierHitObstacle(state, root, state.lastCarrierVelocity, deltaTime)
		then
			state.lastImpactAt = now
			damageStability(
				state,
				(velocityChange - Config.Stability.ImpactThreshold)
					* Config.Stability.ImpactDamageScale
					* state.stabilityMultiplier
			)
			damageContainment(
				state,
				(velocityChange - Config.Biohazardous.ImpactThreshold)
					* Config.Biohazardous.ImpactContainmentScale
					* state.biohazardMultiplier
			)
		end
	end
	state.lastCarrierVelocity = velocity
end

local function updateFreeRisk(state, deltaTime)
	local primaryPart = state.cargo.PrimaryPart
	if not primaryPart then return end
	if state.transportMode ~= "Free" then
		state.transportMode = "Free"
		state.freeStartedAt = workspace:GetServerTimeNow()
		state.lastFreeVelocity = nil
	end
	state.lastFreeVelocity = primaryPart.AssemblyLinearVelocity
	if primaryPart.AssemblyLinearVelocity.Magnitude < Config.Stability.WalkSpeedThreshold then
		recoverStability(state, Config.Stability.FreeRecoveryPerSecond * deltaTime)
	end
end

local function updateCargo(state, deltaTime)
	if state.broken or not state.cargo.Parent then return end
	trackMountedShip(state, getMountedShip(state.cargo))
	if state.mountedShip then
		state.transportMode = "Mounted"
		state.lastFreeVelocity = nil
		recoverStability(state, Config.Stability.MountedRecoveryPerSecond * deltaTime)
	elseif state.cargo:GetAttribute("HeldBy") == state.player.Name then
		state.transportMode = "Carried"
		state.lastFreeVelocity = nil
		updateCarriedRisk(state, deltaTime)
	else
		updateFreeRisk(state, deltaTime)
	end
	updateExposure(state)
end

function CargoRiskService:Register(player, cargo, job, onBroken)
	self:Unregister(cargo)
	local stabilityRisks = getStabilityRisks(job)
	local biohazardSeverity = getRiskSeverity(job, "Biohazardous")
	local usesStability = #stabilityRisks > 0
	local biohazardous = biohazardSeverity ~= nil
	if not usesStability and not biohazardous then return false end

	local maximumStabilitySeverity = 0
	for _, risk in ipairs(stabilityRisks) do
		maximumStabilitySeverity = math.max(maximumStabilitySeverity, risk.severity)
	end
	local stabilityLabel = usesStability and stabilityRisks[1].behavior.Label or nil
	if #stabilityRisks > 1 then stabilityLabel = "CARGO STABILITY" end

	local state = {
		player = player,
		cargo = cargo,
		cargoName = job.cargoName or cargo.Name,
		jobKey = cargo:GetAttribute("CargoJobKey"),
		stability = usesStability and Config.Stability.Maximum or nil,
		stabilityLabel = stabilityLabel,
		stabilityRisks = stabilityRisks,
		stabilityTriggered = false,
		containment = biohazardous and Config.Biohazardous.MaximumContainment or nil,
		biohazardSeverity = biohazardSeverity,
		stabilityMultiplier = severityMultiplier(maximumStabilitySeverity),
		biohazardMultiplier = severityMultiplier(biohazardSeverity),
		broken = false,
		onBroken = onBroken,
		lastCarrierVelocity = nil,
		lastStabilityDamageAt = -math.huge,
		random = Random.new(),
		runRateMultiplier = 1,
		nextRunRateChangeAt = -math.huge,
		lastRandomBurstAt = -math.huge,
		lastImpactAt = -math.huge,
		lastShipImpactAt = -math.huge,
		lastFreeImpactAt = -math.huge,
		mountedShip = nil,
		shipCollisionConnections = {},
		cargoCollisionConnections = {},
		transportMode = "Free",
		freeStartedAt = workspace:GetServerTimeNow(),
		lastFreeVelocity = nil,
		exposedPlayers = {},
		exposureSourceKey = "Cargo:" .. tostring(cargo:GetAttribute("CargoJobKey")) .. ":Biohazard",
	}
	tracked[cargo] = state
	cargo:SetAttribute("CargoBroken", false)
	cargo:SetAttribute("CargoRisks", table.concat(getRiskNames(job), ","))
	if usesStability then
		cargo:SetAttribute("CargoStability", state.stability)
		cargo:SetAttribute("CargoStabilityLabel", state.stabilityLabel)
		cargo:SetAttribute("CargoStabilityTriggered", false)
	end
	if biohazardous then
		cargo:SetAttribute("CargoContainment", state.containment)
		cargo:SetAttribute("CargoContainmentState", getBiohazardStage(state.containment).Label)
	end
	trackCargoCollisions(state)
	publishState(state)
	return true
end

function CargoRiskService:Unregister(cargo)
	local state = tracked[cargo]
	if not state then return end
	clearShipCollisionTracking(state)
	clearCargoCollisionTracking(state)
	removeExposureSources(state)
	tracked[cargo] = nil
end

RunService.Heartbeat:Connect(function(deltaTime)
	accumulatedTime += deltaTime
	if accumulatedTime < UPDATE_INTERVAL then return end
	local elapsed = accumulatedTime
	accumulatedTime = 0

	for cargo, state in pairs(tracked) do
		if not cargo.Parent or not state.player.Parent then
			CargoRiskService:Unregister(cargo)
		else
			updateCargo(state, elapsed)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for cargo, state in pairs(tracked) do
		if state.player == player then CargoRiskService:Unregister(cargo) end
	end
end)

return CargoRiskService
