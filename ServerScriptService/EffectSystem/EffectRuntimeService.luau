local RunService = game:GetService("RunService")

local EffectRuntimeService = {}
local tracked = setmetatable({}, { __mode = "k" })
local initialized = false

local function report(label, err)
	warn(string.format("[EffectSystem] Runtime %s failed:\n%s", label, err))
end

function EffectRuntimeService.Init()
	if initialized then
		return
	end
	initialized = true

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for runtimeEffect, record in pairs(tracked) do
			if not record.IsActive() then
				tracked[runtimeEffect] = nil
			elseif runtimeEffect.ExpiresAt and now >= runtimeEffect.ExpiresAt then
				tracked[runtimeEffect] = nil
				task.spawn(function()
					local ok, err = xpcall(record.OnExpire, debug.traceback)
					if not ok then report("expiration", err) end
				end)
			elseif now >= record.NextTickAt then
				local elapsed = math.max(0, now - record.LastTickAt)
				record.LastTickAt = now
				record.NextTickAt = now + record.TickInterval
				local ok, err = xpcall(function()
					record.OnTick(elapsed)
				end, debug.traceback)
				if not ok then report("tick", err) end
			end
		end
	end)
end

function EffectRuntimeService.Track(runtimeEffect, options)
	EffectRuntimeService.Init()
	local now = workspace:GetServerTimeNow()
	tracked[runtimeEffect] = {
		TickInterval = options.TickInterval or 1,
		LastTickAt = now,
		NextTickAt = now,
		IsActive = options.IsActive,
		OnTick = options.OnTick,
		OnExpire = options.OnExpire,
	}
end

function EffectRuntimeService.Untrack(runtimeEffect)
	tracked[runtimeEffect] = nil
end

return EffectRuntimeService
