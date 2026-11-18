local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")

local MovementModifierService = {}
local records = setmetatable({}, { __mode = "k" })

local CONTROLLED_STATES = {
	Enum.HumanoidStateType.RunningNoPhysics,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Running,
	Enum.HumanoidStateType.Jumping,
	Enum.HumanoidStateType.GettingUp,
	Enum.HumanoidStateType.Freefall,
}

local function getCharacterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
	return character, humanoid, root
end

local function captureRecord(player)
	local character, humanoid, root = getCharacterParts(player)
	if not character or not humanoid then return nil end
	local record = {
		Character = character,
		Humanoid = humanoid,
		Root = root,
		BaseWalkSpeed = humanoid.WalkSpeed,
		Modifiers = {},
		Immobilized = false,
	}
	records[player] = record
	return record
end

local function recordStillApplies(player, record)
	return record and record.Character == player.Character and record.Humanoid.Parent ~= nil
end

local function setImmobilized(record, enabled)
	if record.Immobilized == enabled then return end
	record.Immobilized = enabled
	if enabled then
		record.PreviousRootAnchored = record.Root and record.Root.Anchored or false
		record.PreviousSit = record.Humanoid.Sit
		record.PreviousStateEnabled = {}
		for _, state in ipairs(CONTROLLED_STATES) do
			record.PreviousStateEnabled[state] = record.Humanoid:GetStateEnabled(state)
			record.Humanoid:SetStateEnabled(state, false)
		end
		if record.Root then record.Root.Anchored = true end
		record.Humanoid.Sit = true
	else
		if record.Root then record.Root.Anchored = record.PreviousRootAnchored == true end
		for _, state in ipairs(CONTROLLED_STATES) do
			local previous = record.PreviousStateEnabled and record.PreviousStateEnabled[state]
			if previous ~= nil then record.Humanoid:SetStateEnabled(state, previous) end
		end
		record.Humanoid.Sit = record.PreviousSit == true
		record.PreviousStateEnabled = nil
	end
end

local function recompute(player, record)
	local speed = record.BaseWalkSpeed
	local multiplier = 1
	local clampMin
	local clampMax
	local override
	local immobilized = false
	for _, modifier in pairs(record.Modifiers) do
		local value = modifier.Value or 0
		if modifier.Operation == "Add" then
			speed += value
		elseif modifier.Operation == "Multiply" then
			multiplier *= value
		elseif modifier.Operation == "ClampMin" then
			clampMin = clampMin and math.max(clampMin, value) or value
		elseif modifier.Operation == "ClampMax" then
			clampMax = clampMax and math.min(clampMax, value) or value
		elseif modifier.Operation == "Override" then
			override = override and math.min(override, value) or value
		elseif modifier.Operation == "Immobilize" then
			immobilized = true
		end
	end
	speed *= multiplier
	if clampMin then speed = math.max(speed, clampMin) end
	if clampMax then speed = math.min(speed, clampMax) end
	if override then speed = override end
	if immobilized then speed = 0 end
	setImmobilized(record, immobilized)
	record.Humanoid.WalkSpeed = math.max(0, speed)
	PlayerStateChangeEvent:FireClient(player, "Movement", nil, nil, nil, nil, record.Humanoid.WalkSpeed)
end

function MovementModifierService.Add(player, sourceKey, modifier)
	local record = records[player]
	if not recordStillApplies(player, record) then record = captureRecord(player) end
	if not record then return false end
	record.Modifiers[sourceKey] = modifier
	recompute(player, record)
	return true
end

function MovementModifierService.Remove(player, sourceKey)
	local record = records[player]
	if not recordStillApplies(player, record) then
		records[player] = nil
		return
	end
	record.Modifiers[sourceKey] = nil
	if next(record.Modifiers) == nil then
		setImmobilized(record, false)
		record.Humanoid.WalkSpeed = record.BaseWalkSpeed
		PlayerStateChangeEvent:FireClient(player, "Movement", nil, nil, nil, nil, record.BaseWalkSpeed)
		records[player] = nil
	else
		recompute(player, record)
	end
end

return MovementModifierService
