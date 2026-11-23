local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("SecurityResponseSystem"):WaitForChild("Config"))
local LaserDoorService = require(ServerScriptService.SharedServices.LaserDoorService)

local sharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local incidentChanged = sharedRemotes:FindFirstChild(Config.IncidentRemoteName)
if not incidentChanged then
	incidentChanged = Instance.new("RemoteEvent")
	incidentChanged.Name = Config.IncidentRemoteName
	incidentChanged.Parent = sharedRemotes
end

local surrenderRemote = sharedRemotes:FindFirstChild(Config.SurrenderRemoteName)
if not surrenderRemote then
	surrenderRemote = Instance.new("RemoteEvent")
	surrenderRemote.Name = Config.SurrenderRemoteName
	surrenderRemote.Parent = sharedRemotes
end

local incidentEvent = script.Parent:FindFirstChild("IncidentChanged")
if not incidentEvent then
	incidentEvent = Instance.new("BindableEvent")
	incidentEvent.Name = "IncidentChanged"
	incidentEvent.Parent = script.Parent
end

local MessagePlayer = sharedRemotes:WaitForChild("MessagePlayer")
local SecurityResponseService = {}
local incidents = {} -- [Player] = incident
local custodies = {} -- [Player] = custody
local cellOccupants = setmetatable({}, { __mode = "k" }) -- [cell Instance] = Player
local cellUnavailableUntil = setmetatable({}, { __mode = "k" }) -- released cell while its door is open
local lastNoCellMessage = setmetatable({}, { __mode = "k" }) -- [Player] = timestamp
local random = Random.new()
local initialized = false
local accumulated = 0

local RESPONSE_RANK = {
	Fine = 0,
	Arrest = 1,
	Lethal = 2,
}

local function isPlayerAlive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character ~= nil
		and character.Parent ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and character:GetAttribute("Dead") ~= true
end

local function snapshot(incident)
	if not incident then return nil end
	return {
		response = incident.response,
		jurisdiction = incident.jurisdiction,
		offenseClass = incident.offenseClass,
		inspectionId = incident.inspectionId,
		expiresAt = incident.expiresAt,
		canSurrender = incident.response == "Arrest"
			and (incident.holdingCFrame ~= nil or incident.holdingCells ~= nil),
	}
end

local function replicate(player, incident, reason, notifyGuards)
	local data = snapshot(incident)
	if data then data.reason = reason end
	incidentChanged:FireClient(player, data)
	if notifyGuards ~= false then
		incidentEvent:Fire(player, data, reason)
	end
end

local function setAttributes(player, incident)
	player:SetAttribute("SecurityResponse", incident and incident.response or nil)
	player:SetAttribute("SecurityJurisdiction", incident and incident.jurisdiction or nil)
	player:SetAttribute("SecurityOffenseClass", incident and incident.offenseClass or nil)
	player:SetAttribute("SecurityIncidentExpiresAt", incident and incident.expiresAt or nil)
end

function SecurityResponseService:GetIncident(player)
	return incidents[player]
end

function SecurityResponseService:GetCustody(player)
	return custodies[player]
end

function SecurityResponseService:ClearIncident(player, reason)
	if not incidents[player] then return false end
	incidents[player] = nil
	setAttributes(player, nil)
	replicate(player, nil, reason or "Cleared")
	return true
end

local function setCustodyAttributes(player, custody)
	player:SetAttribute("InCustody", custody ~= nil)
	player:SetAttribute("CustodyReleaseAt", custody and custody.expiresAt or nil)
end

local function holdingPointCFrame(holdingPoint)
	if holdingPoint and holdingPoint.Parent then
		if holdingPoint:IsA("Attachment") then
			return holdingPoint.WorldCFrame
		elseif holdingPoint:IsA("BasePart") then
			return holdingPoint.CFrame * CFrame.new(0, holdingPoint.Size.Y * 0.5 + 3, 0)
		end
	end
	return nil
end

local function clearCellReservation(player, custody)
	local cell = custody and custody.holdingCell
	if not cell or cellOccupants[cell] ~= player then return end
	cellOccupants[cell] = nil
	if cell.Parent then
		cell:SetAttribute("OccupantUserId", nil)
	end
end

local function reserveHoldingLocation(player, incident)
	if incident.holdingCells then
		local available = {}
		local now = workspace:GetServerTimeNow()
		for _, definition in ipairs(incident.holdingCells) do
			local cell = definition.cell
			local cframe = holdingPointCFrame(definition.holdingPoint)
			if cell and cell.Parent and cframe and cellOccupants[cell] == nil
				and (cellUnavailableUntil[cell] or 0) <= now
			then
				table.insert(available, {
					cell = cell,
					cframe = cframe,
					door = definition.holdingDoor,
				})
			end
		end

		if #available == 0 then return nil end
		local choice = available[random:NextInteger(1, #available)]
		cellOccupants[choice.cell] = player
		choice.cell:SetAttribute("OccupantUserId", player.UserId)
		return choice
	end

	if incident.holdingCFrame then
		return {
			cframe = incident.holdingCFrame,
			door = incident.holdingDoor,
		}
	end
	return nil
end

function SecurityResponseService:ReleaseCustody(player, reason, openDoor)
	local custody = custodies[player]
	if not custody then return false end
	custodies[player] = nil
	if openDoor == true and custody.holdingCell and custody.holdingCell.Parent then
		local cell = custody.holdingCell
		local unavailableUntil = workspace:GetServerTimeNow() + Config.CustodyDoorOpenDuration
		cellUnavailableUntil[cell] = unavailableUntil
		cell:SetAttribute("UnavailableUntil", unavailableUntil)
		task.delay(Config.CustodyDoorOpenDuration, function()
			if cellUnavailableUntil[cell] ~= unavailableUntil then return end
			cellUnavailableUntil[cell] = nil
			if cell.Parent then cell:SetAttribute("UnavailableUntil", nil) end
		end)
	end
	clearCellReservation(player, custody)
	setCustodyAttributes(player, nil)
	replicate(player, nil, reason or "Released", false)

	if openDoor == true then
		if custody.holdingDoor and custody.holdingDoor.Parent then
			LaserDoorService:DisableFor(custody.holdingDoor, Config.CustodyDoorOpenDuration)
			MessagePlayer:FireClient(player, "Sentence complete. The cell door is open.")
		else
			warn(("[SecurityResponse] No HoldingDoor is linked for %s's custody release")
				:format(player.Name))
			MessagePlayer:FireClient(player, "Sentence complete, but this cell has no linked release door.")
		end
	end
	return true
end

function SecurityResponseService:StartCustody(player, incident, reason)
	if not incident then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then return false end

	local holding = reserveHoldingLocation(player, incident)
	if not holding then
		local now = workspace:GetServerTimeNow()
		if now - (lastNoCellMessage[player] or 0) >= 5 then
			lastNoCellMessage[player] = now
			MessagePlayer:FireClient(player, "All holding cells are currently occupied.")
		end
		return false
	end

	character:PivotTo(holding.cframe)
	self:ClearIncident(player, reason or "TakenIntoCustody")

	local duration = math.max(tonumber(incident.custodyDuration)
		or Config.DefaultCustodyDuration, 1)
	local custody = {
		response = "Custody",
		jurisdiction = incident.jurisdiction,
		offenseClass = incident.offenseClass,
		inspectionId = incident.inspectionId,
		expiresAt = workspace:GetServerTimeNow() + duration,
		holdingDoor = holding.door,
		holdingCell = holding.cell,
	}
	custodies[player] = custody
	setCustodyAttributes(player, custody)
	replicate(player, custody, reason or "TakenIntoCustody", false)
	return true
end

function SecurityResponseService:Report(enforcement)
	local player = enforcement and enforcement.player
	local response = enforcement and enforcement.response
	if not player or not player:IsA("Player") or not player.Parent then return false end
	if response ~= "Arrest" and response ~= "Lethal" then return false end
	if custodies[player] then return false end
	-- Inspection completion can be delayed. Never recreate an incident after
	-- the inspected player has already died during that delay.
	if not isPlayerAlive(player) then return false end

	local now = workspace:GetServerTimeNow()
	local duration = response == "Lethal"
		and Config.DefaultLethalDuration
		or Config.DefaultArrestDuration
	local current = incidents[player]
	local currentRank = current and RESPONSE_RANK[current.response] or -1
	local nextRank = RESPONSE_RANK[response]

	-- A lower-severity report cannot downgrade an active incident. Reports at
	-- the same or higher level refresh the timer and latest source details.
	if current and nextRank < currentRank then return false end

	local incident = {
		response = response,
		jurisdiction = enforcement.jurisdiction or "Local Security",
		offenseClass = enforcement.offenseClass or "Restricted",
		inspectionId = enforcement.inspectionId,
		expiresAt = now + duration,
		holdingCFrame = enforcement.holdingCFrame,
		holdingDoor = enforcement.holdingDoor,
		holdingCells = enforcement.holdingCells,
		custodyDuration = enforcement.custodyDuration,
	}
	incidents[player] = incident
	setAttributes(player, incident)
	replicate(player, incident, current and "Refreshed" or "Created")
	return true
end

function SecurityResponseService:Surrender(player)
	local incident = incidents[player]
	if not incident or incident.response ~= "Arrest"
		or (not incident.holdingCFrame and not incident.holdingCells)
	then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then return false end
	if humanoid.SeatPart then
		MessagePlayer:FireClient(player, "Exit the ship before surrendering.")
		return false
	end

	if not self:StartCustody(player, incident, "Surrendered") then return false end
	MessagePlayer:FireClient(player, "You surrendered and were taken into custody.")
	return true
end

function SecurityResponseService:Arrest(player, guard)
	local incident = incidents[player]
	if not incident or incident.response ~= "Arrest"
		or (not incident.holdingCFrame and not incident.holdingCells)
	then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then return false end

	if not self:StartCustody(player, incident, "Arrested") then return false end
	local guardName = guard and guard.Name or "Security"
	MessagePlayer:FireClient(player, guardName .. " took you into custody.")
	return true
end

local function bindCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	humanoid.Died:Connect(function()
		SecurityResponseService:ClearIncident(player, "Death")
		SecurityResponseService:ReleaseCustody(player, "Death", false)
	end)
end

local function bindPlayer(player)
	if player.Character then task.spawn(bindCharacter, player, player.Character) end
	player.CharacterAdded:Connect(function(character)
		-- Character replacement is another hard boundary for an incident. This
		-- also cleans up anything that survived an unusual death sequence.
		SecurityResponseService:ClearIncident(player, "Respawn")
		SecurityResponseService:ReleaseCustody(player, "Respawn", false)
		bindCharacter(player, character)
	end)
	player.CharacterRemoving:Connect(function()
		SecurityResponseService:ClearIncident(player, "CharacterRemoving")
		SecurityResponseService:ReleaseCustody(player, "CharacterRemoving", false)
	end)
end

function SecurityResponseService:Init(enforcementRequested)
	if initialized then return end
	initialized = true

	enforcementRequested.Event:Connect(function(enforcement)
		self:Report(enforcement)
	end)
	surrenderRemote.OnServerEvent:Connect(function(player)
		self:Surrender(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(function(player)
		incidents[player] = nil
		local custody = custodies[player]
		if custody then clearCellReservation(player, custody) end
		custodies[player] = nil
		lastNoCellMessage[player] = nil
	end)

	game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		accumulated += deltaTime
		if accumulated < Config.UpdateInterval then return end
		accumulated = 0
		local now = workspace:GetServerTimeNow()
		for player, incident in pairs(incidents) do
			if not player.Parent then
				incidents[player] = nil
			elseif now >= incident.expiresAt then
				self:ClearIncident(player, "Expired")
			end
		end
		for player, custody in pairs(custodies) do
			if not player.Parent then
				clearCellReservation(player, custody)
				custodies[player] = nil
			elseif now >= custody.expiresAt then
				self:ReleaseCustody(player, "SentenceComplete", true)
			end
		end
	end)

	local SecurityGuardService = require(script.Parent:WaitForChild("SecurityGuardService"))
	SecurityGuardService:Init(self, incidentEvent)
end

return SecurityResponseService
