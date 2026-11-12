
--Roblox Services
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local LedgeEvent = Remotes:WaitForChild("Ledge")

--Functions

--Definition Modules

--Assets

--Modules

--Gui

--Context and Actions

--Initialization

local LedgeGrab = {}
LedgeGrab.__index = LedgeGrab


-- Authoring rules:
-- 1) The instance tagged "Ledge" should be the *wall part* you want raycastable (BasePart) OR a Model that contains it.
-- 2) That tagged instance (or its descendants) must contain an Attachment named Config.GrabAttachmentName.
--    The attachment's WorldCFrame defines where/how to hang (HRP will align to it with optional offsets).

LedgeGrab.Config = {
	TagName = "Ledge",
	GrabAttachmentName = "LedgeGrab",

	ForwardDist = 2.0,
	ChestUp = 1.5,
	Cooldown = 0.25,

	RequireFalling = false,
	FallVelThreshold = -1.0,

	-- If you authored the attachment exactly where HRP should be while hanging, set these to 0.
	HangBack = 0.0,   -- along attachment LookVector (backwards)
	HangDown = 0.0,   -- world Y down

	-- Optional clearance check (uses Exclude ray so it can ignore the character)
	EnableHeadClearance = true,
	HeadClearUp = 1.5,
	HeadClearBack = 0.6,

	Debug = false,
}

local function buildRootMotionDeltas(absTable)
	local keys = {} -- keep stable order if you want
	for k in pairs(absTable) do table.insert(keys, k) end
	table.sort(keys) -- RM0, RM1, RM2... (works if named like that)

	local base = absTable[keys[1]].offset
	local deltas = {}

	for _, name in ipairs(keys) do
		local step = absTable[name]
		deltas[name] = {
			offset = step.offset - base,
			duration = step.duration,
			easingStyle = step.easingStyle,
			easingDir = step.easingDir,
		}
	end

	return deltas
end

local function isAirborne(humanoid)
	local st = humanoid:GetState()
	return st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
end

local function findGrabAttachment(hitInstance, attachmentName, hrpPosition)
	local bestAttachment = nil
	local bestDistance = math.huge

	local function checkAttachment(a)
		if a and a:IsA("Attachment") and a.Name == attachmentName then
			local dist = (a.WorldPosition - hrpPosition).Magnitude
			if dist < bestDistance then
				bestDistance = dist
				bestAttachment = a
			end
		end
	end

	for _, a in ipairs(hitInstance:GetDescendants()) do
		checkAttachment(a)
	end
	checkAttachment(hitInstance)

	local model = hitInstance:FindFirstAncestorOfClass("Model")
	if model then
		for _, a in ipairs(model:GetDescendants()) do
			checkAttachment(a)
		end
	end

	return bestAttachment
end

local function removeFromArray(arr, inst)
	for i = #arr, 1, -1 do
		if arr[i] == inst then
			table.remove(arr, i)
			return true
		end
	end
	return false
end

function LedgeGrab.new()
	local self = setmetatable({}, LedgeGrab)

	self._lastGrabT = 0
	self._active = false
	self._ledgeData = nil

	self._char = nil

	-- Raycast params for "ledge wall" ray: INCLUDE ONLY tagged instances
	self._includeList = {}
	self._ledgeParams = RaycastParams.new()
	self._ledgeParams.FilterType = Enum.RaycastFilterType.Include
	self._ledgeParams.FilterDescendantsInstances = self._includeList
	self._ledgeParams.IgnoreWater = true

	-- Raycast params for clearance checks: EXCLUDE character (so we can ray near the player)
	self._clearParams = RaycastParams.new()
	self._clearParams.FilterType = Enum.RaycastFilterType.Exclude
	self._clearParams.IgnoreWater = true
	self._clearParams.FilterDescendantsInstances = {}

	self._tagConns = {}
	self:_initTaggedIncludeList()

	return self
end

-- Build and maintain include list of tagged ledge instances
function LedgeGrab:_initTaggedIncludeList()
	local cfg = LedgeGrab.Config

	-- initial fill
	table.clear(self._includeList)
	for _, inst in ipairs(CollectionService:GetTagged(cfg.TagName)) do
		table.insert(self._includeList, inst)
	end
	
	self._ledgeParams.FilterDescendantsInstances = self._includeList

	-- keep synced
	-- (disconnect if you ever add a :Destroy method; omitted for simplicity)
	table.insert(self._tagConns, CollectionService:GetInstanceAddedSignal(cfg.TagName):Connect(function(inst)
		table.insert(self._includeList, inst)
		self._ledgeParams.FilterDescendantsInstances = self._includeList
	end))

	table.insert(self._tagConns, CollectionService:GetInstanceRemovedSignal(cfg.TagName):Connect(function(inst)
		removeFromArray(self._includeList, inst)
		self._ledgeParams.FilterDescendantsInstances = self._includeList
	end))
end

function LedgeGrab:SetCharacter(char)
	self._char = char
	-- only used for clearance rays
	self._clearParams.FilterDescendantsInstances = { char }
end

function LedgeGrab:IsHanging()
	return self._active
end

function LedgeGrab:GetLedgeData()
	return self._ledgeData
end

-- Returns ledgeData or nil (attachment-driven)
function LedgeGrab:FindLedge(humanoid, hrp, playerState)
	local cfg = LedgeGrab.Config

	if not humanoid or not hrp then return nil end
	if not isAirborne(humanoid) then return nil end
	if playerState.InWater or playerState.IsSwimming then return nil end
	if playerState.CurrentState == playerState.States.HoldingEdge then return nil end
	if tick() - self._lastGrabT < cfg.Cooldown then return nil end

	if cfg.RequireFalling then
		local vy = hrp.AssemblyLinearVelocity.Y
		if vy > cfg.FallVelThreshold then
			return nil
		end
	end

	-- Optional: don't allow if crawling/crouching/rolling/sliding etc.
	if playerState.Crawling or playerState.Crouching or playerState.Rolling or playerState.Sliding then
		return nil
	end

	-- If there are no tagged ledges, bail early
	if #self._includeList == 0 then
		return nil
	end

	local forward = hrp.CFrame.LookVector
	local chestOrigin = hrp.Position + Vector3.new(0, cfg.ChestUp, 0)

	if cfg.Debug then
		print("[LedgeGrab] check wallHit _ledgeParams:", self._ledgeParams," _includeList:",self._includeList)
	end
	
	-- INCLUDE raycast: can only ever hit tagged ledges
	local wallHit = Workspace:Raycast(chestOrigin, forward * cfg.ForwardDist, self._ledgeParams)
	if not wallHit then return nil end
	
	if cfg.Debug then
		print("[LedgeGrab] wallHit:", wallHit)
	end

	local hitInst = wallHit.Instance
	if not hitInst then return nil end

	-- Find attachment that defines grab anchor
	local grabAtt = findGrabAttachment(hitInst, cfg.GrabAttachmentName, hrp.Position)
	if not grabAtt then
		if cfg.Debug then
			print("[LedgeGrab] Tagged ledge hit but missing attachment:", cfg.GrabAttachmentName, "on", hitInst:GetFullName())
		end
		return nil
	end

	local grabCF = grabAtt.WorldCFrame

	-- Optional head clearance check
	if cfg.EnableHeadClearance and self._char then
		local back = -grabCF.LookVector
		local headOrigin = grabCF.Position + back * cfg.HeadClearBack
		local headClear = Workspace:Raycast(headOrigin, Vector3.new(0, cfg.HeadClearUp, 0), self._clearParams)
		if headClear then
			if cfg.Debug then
				print("[LedgeGrab] blocked head clearance by:", headClear.Instance:GetFullName())
			end
			return nil
		end
	end

	if cfg.Debug then
		print("[LedgeGrab] HIT:", hitInst:GetFullName(), "ATT:", grabAtt:GetFullName())
	end

	return {
		wallHit = wallHit,
		wallNormal = wallHit.Normal,
		hitInstance = hitInst,
		grabAttachment = grabAtt,
		grabCFrame = grabCF,
	}
end


function LedgeGrab:Hang(ledgeData, humanoid, hrp, playerState)

	local cfg = LedgeGrab.Config

	self._lastGrabT = tick()
	self._active = true
	self._ledgeData = ledgeData

	playerState.ChangeState(playerState.States.HoldingEdge)
	
	LedgeEvent:FireServer("Hang",ledgeData,cfg)
	
end

function LedgeGrab:Climb(humanoid, hrp, playerState)

	local cfg = LedgeGrab.Config
	local ledgeData = self._ledgeData
	if not ledgeData then
		return self:Drop(humanoid, hrp, playerState)
	end

	--hrp.Anchored = true

	local climbTrack = playerState.States.ClimbLedge.Animation

	climbTrack.Stopped:Once(function()

		self._active = false
		self._ledgeData = nil

		humanoid.AutoRotate = true

		playerState.ChangeState(playerState.States.Idle)
		self._active = false
	end)

	LedgeEvent:FireServer("Climb",ledgeData,cfg)
	
end

function LedgeGrab:Drop(humanoid, hrp, playerState)

	self._active = false
	self._ledgeData = nil

	humanoid.AutoRotate = true

	LedgeEvent:FireServer("Drop")

	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	playerState.ChangeState(playerState.States.Falling)

end

-- Call from RenderStepped while airborne
function LedgeGrab:Check(humanoid, hrp, playerState)
	if self._active then return end
	local ledge = self:FindLedge(humanoid, hrp, playerState)
	if ledge then
		self:Hang(ledge, humanoid, hrp, playerState)
	end
end

function LedgeGrab:HandleInput(action, humanoid, hrp, playerState)
	if not self._active then return false end
	if playerState.CurrentState ~= playerState.States.HoldingEdge then return false end

	if action == "Climb" then
		self:Climb(humanoid, hrp, playerState) --ExitClimb(humanoid, hrp, playerState)
		return true
	elseif action == "Drop" then
		self:Drop(humanoid, hrp, playerState)
		return true
	end

	return false
end

return LedgeGrab
