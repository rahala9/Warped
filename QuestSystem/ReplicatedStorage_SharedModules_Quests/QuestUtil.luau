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

function QuestUtil.GetOrCreate(tbl, key, defaultValue)
	local existing = tbl[key]
	if existing == nil then
		tbl[key] = defaultValue
		return defaultValue
	end
	return existing
end

function QuestUtil.Now()
	return os.time()
end

return QuestUtil
