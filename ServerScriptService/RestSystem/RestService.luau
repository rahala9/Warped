local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("RestSystem")
local Config = require(sharedFolder:WaitForChild("Config"))

local function ensureRemote(name: string): RemoteEvent
	local existing = sharedFolder:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), name .. " must be a RemoteEvent")
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = sharedFolder
	return remote
end

local stateRemote = ensureRemote(Config.StateRemoteName)
local exitRemote = ensureRemote(Config.ExitRemoteName)

local RestService = {}

type Session = {
	player: Player,
	station: Instance,
	prompt: ProximityPrompt,
	definitionId: string,
	exitCFrame: CFrame,
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	previousAutoRotate: boolean,
	deathConnection: RBXScriptConnection?,
}

local initialized = false
local stationsByPrompt: {[ProximityPrompt]: Instance} = setmetatable({}, {__mode = "k"})
local promptsByStation: {[Instance]: ProximityPrompt} = setmetatable({}, {__mode = "k"})
local sessionsByPlayer: {[Player]: Session} = {}
local sessionsByStation: {[Instance]: Session} = setmetatable({}, {__mode = "k"})

local function findNamedDescendant(root: Instance, name: string, className: string): Instance?
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == name and descendant:IsA(className) then
			return descendant
		end
	end
	return nil
end

local function getStationParts(station: Instance): (Attachment?, Attachment?, ProximityPrompt?)
	local restPoint = findNamedDescendant(station, Config.RestPointName, "Attachment") :: Attachment?
	local exitPoint = findNamedDescendant(station, Config.ExitPointName, "Attachment") :: Attachment?
	local prompt = restPoint and restPoint:FindFirstChild(Config.PromptName)
	if prompt and not prompt:IsA("ProximityPrompt") then
		prompt = nil
	end
	return restPoint, exitPoint, prompt :: ProximityPrompt?
end

local function definitionFor(station: Instance): (string?, any?)
	local definitionId = station:GetAttribute(Config.DefinitionAttribute)
	if type(definitionId) ~= "string" or definitionId == "" then
		return nil, nil
	end
	return definitionId, Config.Definitions[definitionId]
end

local function setRestAttributes(player: Player, character: Model?, definitionId: string?)
	local resting = definitionId ~= nil
	player:SetAttribute(Config.RestingAttribute, resting or nil)
	player:SetAttribute(Config.DefinitionAttribute, definitionId)
	if character then
		character:SetAttribute(Config.RestingAttribute, resting or nil)
		character:SetAttribute(Config.DefinitionAttribute, definitionId)
	end
end

local function registerStation(station: Instance)
	local definitionId, definition = definitionFor(station)
	local restPoint, exitPoint, prompt = getStationParts(station)
	if not definition then
		warn("[RestSystem] Unknown or missing RestDefinition on", station:GetFullName(), definitionId)
		return
	end
	if not restPoint or not exitPoint or not prompt then
		warn("[RestSystem] Station needs RestPoint, ExitPoint, and RestPrompt:", station:GetFullName())
		return
	end

	local previousPrompt = promptsByStation[station]
	if previousPrompt and previousPrompt ~= prompt then
		stationsByPrompt[previousPrompt] = nil
	end
	promptsByStation[station] = prompt
	stationsByPrompt[prompt] = station

	prompt.ActionText = definition.EnterText
	prompt.ObjectText = definition.ObjectText or ""
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = Config.ExitKey
	prompt.GamepadKeyCode = Config.ExitGamepadKey
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = definition.PromptDistance or Config.DefaultPromptDistance
	prompt.Enabled = station:GetAttribute(Config.EnabledAttribute) ~= false
	station:SetAttribute(Config.OccupantAttribute, nil)
end

local function unregisterStation(station: Instance)
	local session = sessionsByStation[station]
	if session then
		RestService.Exit(session.player, "StationRemoved")
	end
	local prompt = promptsByStation[station]
	if prompt then
		stationsByPrompt[prompt] = nil
	end
	promptsByStation[station] = nil
end

local function characterState(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then return nil, nil, nil end
	return character, humanoid, root
end

local function canEnter(player: Player, station: Instance, prompt: ProximityPrompt, restPoint: Attachment): boolean
	if sessionsByPlayer[player] or sessionsByStation[station] then return false end
	if station:GetAttribute(Config.EnabledAttribute) == false then return false end

	local character, humanoid, root = characterState(player)
	if not character or not humanoid or not root then return false end
	if humanoid.Health <= 0 or humanoid.SeatPart ~= nil or root.Anchored then return false end
	if player:GetAttribute(Config.RestingAttribute) or character:GetAttribute(Config.RestingAttribute) then return false end
	if character:GetAttribute("HoldingLiveObject") == true then return false end

	local allowedDistance = math.max(prompt.MaxActivationDistance, Config.DefaultPromptDistance)
		+ Config.DistanceTolerance
	return (root.Position - restPoint.WorldPosition).Magnitude <= allowedDistance
end

function RestService.Enter(player: Player, station: Instance): boolean
	local definitionId, definition = definitionFor(station)
	local restPoint, exitPoint, prompt = getStationParts(station)
	if not definitionId or not definition or not restPoint or not exitPoint or not prompt then
		return false
	end
	if stationsByPrompt[prompt] ~= station or not canEnter(player, station, prompt, restPoint) then
		return false
	end

	local character, humanoid, root = characterState(player)
	if not character or not humanoid or not root then return false end

	local session: Session = {
		player = player,
		station = station,
		prompt = prompt,
		definitionId = definitionId,
		exitCFrame = exitPoint.WorldCFrame,
		character = character,
		humanoid = humanoid,
		root = root,
		previousAutoRotate = humanoid.AutoRotate,
		deathConnection = nil,
	}
	sessionsByPlayer[player] = session
	sessionsByStation[station] = session

	station:SetAttribute(Config.OccupantAttribute, player.UserId)
	prompt.ActionText = definition.ExitText or "Stand"
	humanoid:UnequipTools()
	humanoid.AutoRotate = false
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = true
	root.CFrame = restPoint.WorldCFrame
	setRestAttributes(player, character, definitionId)

	session.deathConnection = humanoid.Died:Connect(function()
		RestService.Exit(player, "Died")
	end)
	stateRemote:FireClient(player, "Entered", definitionId, station)
	return true
end

function RestService.Exit(player: Player, reason: string?): boolean
	local session = sessionsByPlayer[player]
	if not session then return false end

	sessionsByPlayer[player] = nil
	if sessionsByStation[session.station] == session then
		sessionsByStation[session.station] = nil
	end
	if session.deathConnection then
		session.deathConnection:Disconnect()
	end

	if session.station.Parent then
		session.station:SetAttribute(Config.OccupantAttribute, nil)
	end
	if session.prompt.Parent then
		local _, definition = definitionFor(session.station)
		session.prompt.ActionText = definition and definition.EnterText or "Rest"
		session.prompt.Enabled = session.station.Parent ~= nil
			and session.station:GetAttribute(Config.EnabledAttribute) ~= false
	end

	local currentCharacter = player.Character
	if currentCharacter == session.character and session.root.Parent and session.humanoid.Parent then
		setRestAttributes(player, currentCharacter, nil)
		session.humanoid.AutoRotate = session.previousAutoRotate
		if reason ~= "Died" and reason ~= "CharacterRemoving" and reason ~= "PlayerRemoving" then
			session.root.CFrame = session.exitCFrame
		end
		session.root.AssemblyLinearVelocity = Vector3.zero
		session.root.AssemblyAngularVelocity = Vector3.zero
		session.root.Anchored = false
	else
		setRestAttributes(player, currentCharacter, nil)
	end

	stateRemote:FireClient(player, "Exited", reason or "Requested")
	return true
end

function RestService.IsResting(player: Player): boolean
	return sessionsByPlayer[player] ~= nil
end

function RestService.Init()
	if initialized then return end
	initialized = true

	for _, station in ipairs(CollectionService:GetTagged(Config.TagName)) do
		registerStation(station)
	end
	CollectionService:GetInstanceAddedSignal(Config.TagName):Connect(registerStation)
	CollectionService:GetInstanceRemovedSignal(Config.TagName):Connect(unregisterStation)

	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local station = stationsByPrompt[prompt]
		if not station then return end
		local session = sessionsByPlayer[player]
		if session and session.station == station then
			RestService.Exit(player, "Requested")
		else
			RestService.Enter(player, station)
		end
	end)

	exitRemote.OnServerEvent:Connect(function(player)
		RestService.Exit(player, "Requested")
	end)

	Players.PlayerRemoving:Connect(function(player)
		RestService.Exit(player, "PlayerRemoving")
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			RestService.Exit(player, "CharacterRemoving")
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterRemoving:Connect(function()
			RestService.Exit(player, "CharacterRemoving")
		end)
	end
end

return RestService
