local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sharedFolder = ReplicatedStorage:WaitForChild("RestSystem")
local Config = require(sharedFolder:WaitForChild("Config"))
local RestInputContextFactory = require(sharedFolder:WaitForChild("RestInputContextFactory"))
local stateRemote = sharedFolder:WaitForChild(Config.StateRemoteName)

local sharedGui = playerGui:WaitForChild("SharedGUI")
local inputRoot = sharedGui:WaitForChild("InputContexts")
local restContext = RestInputContextFactory.Ensure(inputRoot)

local obsoleteExitPrompt = sharedGui:WaitForChild("ActionGui"):FindFirstChild("RestActionPrompt")
if obsoleteExitPrompt then obsoleteExitPrompt:Destroy() end

local currentDefinitionId: string? = nil
local currentTrack: AnimationTrack? = nil
local tracksByDefinition: {[string]: AnimationTrack} = {}
local trackedCharacter: Model? = nil
local suspendedContexts: {[InputContext]: boolean} = {}

local function setRestInputEnabled(enabled: boolean)
	if enabled then
		suspendedContexts = {}
		for _, contextName in {"GameplayContext", "ContextSwitchingContext"} do
			local context = inputRoot:FindFirstChild(contextName)
			if context and context:IsA("InputContext") then
				suspendedContexts[context] = context.Enabled
				context.Enabled = false
			end
		end
		restContext.Enabled = true
	else
		restContext.Enabled = false
		for context, wasEnabled in pairs(suspendedContexts) do
			if context.Parent then context.Enabled = wasEnabled end
		end
		suspendedContexts = {}
	end
end

local function stopAnimation()
	if currentTrack then
		currentTrack:Stop(0.15)
		currentTrack = nil
	end
end

local function resetAnimationCache(character: Model?)
	stopAnimation()
	for _, track in pairs(tracksByDefinition) do
		track:Destroy()
	end
	tracksByDefinition = {}
	trackedCharacter = character
end

local function getTrack(definitionId: string): AnimationTrack?
	local character = player.Character
	if not character then return nil end
	if trackedCharacter ~= character then resetAnimationCache(character) end

	local cached = tracksByDefinition[definitionId]
	if cached then return cached end

	local definition = Config.Definitions[definitionId]
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not definition or not definition.AnimationId or not animator then return nil end

	local animation = Instance.new("Animation")
	animation.Name = "Rest_" .. definitionId
	animation.AnimationId = definition.AnimationId
	local track = animator:LoadAnimation(animation)
	animation:Destroy()
	track.Looped = true
	-- Warped's locomotion/tool tracks deliberately layer different body regions.
	-- Rest poses are full-body and must win every keyed joint while active.
	track.Priority = Enum.AnimationPriority.Action4
	tracksByDefinition[definitionId] = track
	return track
end

local function enter(definitionId: string)
	local definition = Config.Definitions[definitionId]
	if not definition then
		warn("[RestSystem] Client received unknown definition", definitionId)
		return
	end

	currentDefinitionId = definitionId
	setRestInputEnabled(true)

	stopAnimation()
	currentTrack = getTrack(definitionId)
	if currentTrack then currentTrack:Play(0.15, 1, 1) end
end

local function exit()
	currentDefinitionId = nil
	setRestInputEnabled(false)
	stopAnimation()
end

stateRemote.OnClientEvent:Connect(function(action: string, definitionId: string?)
	if action == "Entered" and definitionId then
		enter(definitionId)
	elseif action == "Exited" then
		exit()
	end
end)

player.CharacterRemoving:Connect(function(character)
	if trackedCharacter == character then resetAnimationCache(nil) end
	exit()
end)

restContext.Enabled = false
