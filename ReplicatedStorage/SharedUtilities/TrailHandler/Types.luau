local function GetXYRadial(Angle, Radius)
	local x = math.cos(Angle) * Radius;
	local y = math.sin(Angle) * Radius;
	return x, y;
end

local function Lerp(Start : number, Finish : number, Alpha : number) : number
	return Start + Alpha * (Finish - Start);
end

return {
	Beam = {
		Start = function(self)
			local Points = self.Points;
			local TrailData = self.TrailData;

			local StartPoint = Points.Start;
			local EndPoint = Points.End;
			local StartOffset = self.TrailData.StartOffset;
			
			local Instance = TrailData.Instance;
			
			Instance.CFrame = StartPoint * CFrame.Angles(0, -math.rad(90), 0) * CFrame.new(0, 0, StartOffset);
		end,
		
		Update = function(self, deltaTime)
			local Points = self.Points;
			local TrailData = self.TrailData;

			local Instance = TrailData.Instance;

			local Radius = TrailData.Radius;
			local StartAngle = TrailData.StartAngle or 0;
			local Angle = TrailData.Angle;
			local FinalOffset = TrailData.FinalOffset;
			local StartTime = TrailData.StartTime;
			local Duration = TrailData.Duration;
			local StartInstancePoint = TrailData.StartInstancePoint;
			
			local Alpha = (os.clock() - StartTime) / Duration;
			local CurrentAngle = Lerp(StartAngle, StartAngle + Angle, Alpha);
			
			local X, Y = GetXYRadial(CurrentAngle, Radius);
			local Z = Lerp(0, FinalOffset, Alpha);
	
			Instance.CFrame = StartInstancePoint * CFrame.new(X, Y, Z);
		end,
	},
};