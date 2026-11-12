--[[
	QuestUtil
	Shared pure-function utilities used by all quest modules.
	Lives in ReplicatedStorage.SharedModules.Quests.QuestUtil
]]

local QuestUtil = {}

function QuestUtil.DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local result = {}
	for k, v in pairs(value) do
		result[QuestUtil.DeepCopy(k)] = QuestUtil.DeepCopy(v)
	end
	return result
end

function QuestUtil.Matches(payload, criteria)
	if not criteria then
		return true
	end

	if type(criteria) ~= "table" then
		return payload == criteria
	end

	if type(payload) ~= "table" then
		return false
	end

	for key, expected in pairs(criteria) do
		local actual = payload[key]

		if type(expected) == "table" then
			if not QuestUtil.Matches(actual, expected) then
				return false
			end
		else
			if actual ~= expected then
				return false
			end
		end
	end

	return true
end

function QuestUtil.ArrayContains(array, value)
	for _, v in ipairs(array or {}) do
		if v == value then
			return true
		end
	end
	return false
end

function QuestUtil.Now()
	return os.time()
end

function QuestUtil.SafePairs(tbl)
	if type(tbl) ~= "table" then
		return next, {}, nil
	end
	return pairs(tbl)
end

--- Snapshot the keys of a table into an array so you can iterate
--- safely even if the table is mutated during the loop.
function QuestUtil.SnapshotKeys(tbl)
	local keys = {}
	for k in QuestUtil.SafePairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end

return QuestUtil
