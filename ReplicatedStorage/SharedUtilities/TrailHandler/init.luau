local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");

local Heartbeat = RunService.Heartbeat;

local FastSignal = require(script.FastSignal);
local Types = require(script.Types);

local ERRORS = {
	POINTS = "Points are missing!",
	START_POINT = "EndPoint is missing!",
	END_POINT = "EndPoint is missing!",
	TRAIL_DATA = "TrailData is missing!",
	TYPE = "TrailData Type is missing!",
	INSTANCE = "Instance is missing!",
};

local TrailHandler = {};
TrailHandler.__index = TrailHandler;


function TrailHandler._update(self)
	local Type = self.TrailData.Type;

	Types[Type].Update(self);
	
	local Alpha = (os.clock() - self.TrailData.StartTime) / self.TrailData.Duration;
	if self.OnUpdate then
		self.OnUpdate(Alpha)
	end
end

TrailHandler.OnUpdate = nil;

function TrailHandler.new(TrailData, Points)
	assert(TrailData, ERRORS.TRAIL_DATA);
	assert(TrailData.Type, ERRORS.TYPE);
	assert(TrailData.Instance, ERRORS.INSTANCE);

	local Trail = {};
	Trail.Points = Points;
	Trail.TrailData = TrailData;
	Trail.TrailData.UpdateRate = TrailData.UpdateRate or -1;
	Trail.Finished = FastSignal.new();

	setmetatable(Trail, TrailHandler);

	return Trail;
end

function TrailHandler:Stop()
	if self._Connection then
		self._Connection:Disconnect();
	end

	if self.Finished then
		self.Finished:DisconnectAll();
	end

	self = nil;
end

function TrailHandler:Start()
	local UpdateRate = self.TrailData.UpdateRate;
	local Duration = self.TrailData.Duration;

	self.TrailData.StartTime = self.TrailData.StartTime or os.clock();
	local StartTime = self.TrailData.StartTime;
	self._lastUpdate = 1 / UpdateRate;

	Types[self.TrailData.Type].Start(self);
	self.TrailData.StartInstancePoint = self.TrailData.Instance.CFrame;

	self._Connection = Heartbeat:Connect(function(deltaTime)
		if os.clock() - StartTime >= Duration then
			self:Stop();

			return;
		end

		self._lastUpdate += deltaTime;
		if UpdateRate == -1 or self._lastUpdate >= (1 / UpdateRate) then
			self._lastUpdate = 0;
			self._update(self);
		end
	end)
end

return TrailHandler;