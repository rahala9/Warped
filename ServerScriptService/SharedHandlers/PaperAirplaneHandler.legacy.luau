local replicatedStorage = game:GetService("ReplicatedStorage")
local flyPaperAirplaneEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("FlyPaperAirplane")
local updatePaperAirplaneAirtimeEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdatePaperAirplaneAirtime")
local paper_airplane = replicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("paper_airplane")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local rand = Random.new (1989289384958+tick())

local timeChangeInterval = 1
local step_counter = 0 
local worldTime = 0
local heartbeat
local touched


local playerPlanes = {}


local PaperAirplaneStates = {
	IDLE = "IDLE",
	FLYING = "FLYING",
	CRASHING = "CRASHING",     
}

local function AddPlayerAirplane(player)
	playerPlanes[player.Name]={
		player = player,
		paper_airplane_tool = nil,
		paper_airplane_model = nil,
		bg = nil,
		bg2 = nil,
		direction = "",
		total_flight_time = 0,
		paperAirplaneState = PaperAirplaneStates.IDLE,
	}
		
end

local function RemovePlayerAirplane(player)
	playerPlanes[player.Name]=nil
end

local step_counter = 0
local timeChangeInterval = 1

--TODO PERFORMANCE maybe not check so often for performance, especially since it sends events to client
local function onHeartbeat(step)
	debug.profilebegin("PaperAirplaneHandler Heartbeat")
	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval
		
		for _,playerPlane in pairs(playerPlanes) do

			if (playerPlane.paperAirplaneState == PaperAirplaneStates.FLYING) then
				playerPlane.total_flight_time = playerPlane.total_flight_time + step 
				updatePaperAirplaneAirtimeEvent:FireClient(playerPlane.player,playerPlane.total_flight_time)
			end


			if (playerPlane.bg ~= nil) and (playerPlane.paper_airplane_model ~= nil) then
				playerPlane.bg.CFrame = CFrame.new(playerPlane.paper_airplane_model.Position, playerPlane.paper_airplane_model.Position + playerPlane.paper_airplane_model.Velocity)
			end

			if (playerPlane.paperAirplaneState ~= PaperAirplaneStates.FLYING) then
				return
			end


			if step_counter >= timeChangeInterval then
				step_counter = step_counter - timeChangeInterval

				local anti_gravity = playerPlane.paper_airplane_model:GetMass() * workspace.Gravity
				local wind = .001*rand:NextInteger(-5,7)

				--			Logger.Debug("total_flight_time")
				--			Logger.Debug(total_flight_time)
				--		if (total_flight_time>7) then
				--			Logger.Debug("KILL WIND")
				--			wind = -.005
				--		end


				--Higher you go less upward motion
				wind = wind - (playerPlane.paper_airplane_model.Position.Y*.0003)

				playerPlane.bf.Force = Vector3.new(0,  anti_gravity + wind, 0)
				direction = direction + Vector3.new(rand:NextInteger(-100,100),0,rand:NextInteger(-100,100))

				--Turn(direction.Unit * (.001*rand:NextInteger(1,2)))

				--paper_airplane_model.Velocity = paper_airplane_model.Velocity * CFrame.Angles(0, math.rad(10), 0)


				--			local dis = (paper_airplane_model.Position - direction.Unit).Magnitude
				--			local info = TweenInfo.new(dis/speed, easingStyle, easingDirection, repeats, reverse, delayTime)
				--			local turnTween2 = tweenService:Create(bg, info, {CFrame = CFrame.new(paper_airplane_model.Position, direction.Unit)})
				--			turnTween2:Play()



			end

		end
	end
				
end

flyPaperAirplaneEvent.OnServerEvent:Connect(function(player, mouseHit)
	if (playerPlanes[player.Name] ~= nil) then
		return
	end
	
	--Add new paper airplane for this player
	AddPlayerAirplane(player)
	
	local playerPlane = playerPlanes[player.Name]

	if (player.Character:FindFirstChild("PaperAirplane")) then --TODO check if tool
		--has paper airplane tool equiped
		playerPlane.paper_airplane_tool = player.Character:FindFirstChild("PaperAirplane")
	else
		return
	end

	playerPlane.paper_airplane_model = paper_airplane:Clone()
	
	playerPlane.paper_airplane_model.Touched:Connect(function (otherPart)

		--Don't handle collision with humanoid
		local humanoid = otherPart.Parent:FindFirstChildWhichIsA("Humanoid")
		if humanoid or otherPart.Name == "Handle" then
			return
		end

		playerPlane.paperAirplaneState = PaperAirplaneStates.CRASHING

		if (playerPlane.bf ~= nil) then
			local anti_gravity = playerPlane.paper_airplane_model:GetMass() * workspace.Gravity
			playerPlane.bf.Force = Vector3.new(0,  anti_gravity - .07, 0)
		end

		--The plane has touched ground kill it after 3 seconds
		if (CollectionService:HasTag(otherPart, "Ground")) then
			playerPlane.paperAirplaneState = PaperAirplaneStates.IDLE

			RemovePlayerAirplane(player)

			if (playerPlane.bg ~= nil) then
				playerPlane.bg:Destroy()
				playerPlane.bg = nil
				playerPlane.bf:Destroy()
				playerPlane.bf = nil
			end

			delay(3, function()

				if (playerPlane.paper_airplane_model ~= nil) then
					playerPlane.paper_airplane_model:Destroy()
					playerPlane.paper_airplane_model = nil
					playerPlane.paper_airplane_tool.Handle.Transparency = 0
				end


			end)
		end

	end)

	local placeStart = playerPlane.paper_airplane_tool.Handle.Position + playerPlane.paper_airplane_tool.Handle.CFrame.LookVector+Vector3.new(0,.6,0)
	local placeDirection = (mouseHit.p - placeStart).Unit
	direction = placeDirection
	playerPlane.paper_airplane_model.CFrame = CFrame.new(placeStart,placeStart+placeDirection)
	playerPlane.paper_airplane_model.Position = placeStart
	playerPlane.paper_airplane_model.Velocity = placeDirection * 15


	playerPlane.bg = Instance.new("BodyGyro")
	playerPlane.bg.D = 500
	playerPlane.bg.MaxTorque = Vector3.new(math.huge,math.huge,math.huge)
	playerPlane.bg.P = 5000
	playerPlane.bg.CFrame = CFrame.new(placeStart,  placeStart + placeDirection)
	playerPlane.bg.Parent = playerPlane.paper_airplane_model

	playerPlane.bf = Instance.new("BodyForce")
	playerPlane.bf.Force =  Vector3.new(0, playerPlane.paper_airplane_model:GetMass() * workspace.Gravity + .001, 0)
	playerPlane.bf.Parent = playerPlane.paper_airplane_model

	playerPlane.total_flight_time = 0
	playerPlane.paper_airplane_tool.Handle.Transparency = 1	

	playerPlane.paper_airplane_model.Parent = workspace
	playerPlane.paperAirplaneState = PaperAirplaneStates.FLYING

end)

heartbeat =RunService.Heartbeat:Connect(onHeartbeat)
