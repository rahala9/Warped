local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("SecurityResponseSystem"):WaitForChild("Config"))

local SecurityGuardService = {}
local initialized = false
local responseService
local accumulated = 0

local function getLivingRoot(model)
	if not model or not model:IsA("Model") or not model.Parent then return nil end
	if model:GetAttribute("Dead") == true then return nil end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then return nil end
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function getPlayerRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then return nil end
	return character:FindFirstChild("HumanoidRootPart")
end

local function guardJurisdiction(guard)
	return guard:GetAttribute(Config.GuardJurisdictionAttribute) or Config.DefaultGuardJurisdiction
end

local function jurisdictionMatches(guard, incident)
	local jurisdiction = guardJurisdiction(guard)
	return jurisdiction == "*" or jurisdiction == incident.jurisdiction
end

local function clearAssignment(guard)
	guard:SetAttribute(Config.GuardTargetAttribute, nil)
	guard:SetAttribute(Config.GuardResponseAttribute, nil)
end

local function chooseAssignment(guard, guardRoot)
	local bestPlayer
	local bestIncident
	local bestDistance = Config.GuardDispatchRadius

	for _, player in ipairs(Players:GetPlayers()) do
		local incident = responseService:GetIncident(player)
		if incident and jurisdictionMatches(guard, incident) then
			local playerRoot = getPlayerRoot(player)
			if playerRoot then
				local distance = (playerRoot.Position - guardRoot.Position).Magnitude
				if distance <= bestDistance then
					bestDistance = distance
					bestPlayer = player
					bestIncident = incident
				end
			end
		end
	end

	return bestPlayer, bestIncident, bestDistance
end

local function updateGuard(guard)
	local guardRoot = getLivingRoot(guard)
	if not guardRoot then
		if guard and guard.Parent then clearAssignment(guard) end
		return
	end

	local player, incident, distance = chooseAssignment(guard, guardRoot)
	if not player then
		clearAssignment(guard)
		return
	end

	guard:SetAttribute(Config.GuardTargetAttribute, player.UserId)
	guard:SetAttribute(Config.GuardResponseAttribute, incident.response)

	if incident.response == "Arrest" and distance <= Config.GuardArrestDistance then
		responseService:Arrest(player, guard)
	end
end

local function updateAllGuards()
	for _, guard in ipairs(CollectionService:GetTagged(Config.GuardTag)) do
		updateGuard(guard)
	end
end

function SecurityGuardService:Init(securityResponseService, incidentChanged)
	if initialized then return end
	initialized = true
	responseService = securityResponseService

	incidentChanged.Event:Connect(function()
		task.defer(updateAllGuards)
	end)
	CollectionService:GetInstanceAddedSignal(Config.GuardTag):Connect(function(guard)
		task.defer(updateGuard, guard)
	end)
	CollectionService:GetInstanceRemovedSignal(Config.GuardTag):Connect(function(guard)
		if guard and guard.Parent then clearAssignment(guard) end
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		accumulated += deltaTime
		if accumulated < Config.GuardUpdateInterval then return end
		accumulated = 0
		updateAllGuards()
	end)

	updateAllGuards()
end

return SecurityGuardService
