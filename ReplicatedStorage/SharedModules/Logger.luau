local Logger = {}

Logger.Level = {
	NONE = 0,
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
}

Logger.CurrentLevel = Logger.Level.DEBUG

-- Helper: get script and line info
local function getTraceInfo()
	local level = 4
	local source = debug.info(level, "s") or "?"
	source = source:gsub("^.+/", "")
	local line = debug.info(level, "l") or 0
	local name = debug.info(level, "n") or "?"
	return string.format("[%s:%d @ %s()]", source, line, name)
end


-- Core print without trace
local function formatLog(levelTag, ...)
	print(levelTag, ...)
end

-- Core print with trace
local function formatLogWithTrace(levelTag, ...)
	local output = {}                              -- make sure this is a table
	output[1] = getTraceInfo()                     -- insert trace at index 1
	for i = 1, select("#", ...) do
		output[i + 1] = select(i, ...)            -- fill in the rest
	end
	print(levelTag, unpack(output))
end

-- Logger functions:

function Logger.Debug(...)
	if Logger.CurrentLevel <= Logger.Level.DEBUG then
		formatLog("[DEBUG]", ...)
	end
end

function Logger.DebugWithTrace(...)
	if Logger.CurrentLevel <= Logger.Level.DEBUG then
		formatLogWithTrace("[DEBUG]", ...)
	end
end

function Logger.Info(...)
	if Logger.CurrentLevel <= Logger.Level.INFO then
		formatLog("[INFO]", ...)
	end
end

function Logger.InfoWithTrace(...)
	if Logger.CurrentLevel <= Logger.Level.INFO then
		formatLogWithTrace("[INFO]", ...)
	end
end

function Logger.Warn(...)
	if Logger.CurrentLevel <= Logger.Level.WARN then
		formatLog("[WARN]", ...)
	end
end

function Logger.WarnWithTrace(...)
	if Logger.CurrentLevel <= Logger.Level.WARN then
		formatLogWithTrace("[WARN]", ...)
	end
end

function Logger.Error(...)
	if Logger.CurrentLevel <= Logger.Level.ERROR then
		formatLog("[ERROR]", ...)
	end
end

function Logger.ErrorWithTrace(...)
	if Logger.CurrentLevel <= Logger.Level.ERROR then
		formatLogWithTrace("[ERROR]", ...)
	end
end

return Logger
