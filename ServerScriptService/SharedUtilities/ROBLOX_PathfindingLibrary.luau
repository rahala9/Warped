local PathfindingUtility = {}
local TargetOffsetMax = 10
local JumpThreshold = 1.5 --2.5
local NextPointThreshold = 4
local PathfindingService = game:GetService("PathfindingService")
PathfindingService.EmptyCutoff = .3

function PathfindingUtility.new()
	local this = {}

	local currentTargetPos = nil	
	local lastTargetPos = Vector3.new(math.huge, math.huge, math.huge)	
	local path = nil
	local currentPointIndex = 1	
	
	function this:smoothPath(waypoints,character)
		local smoothedWaypoints = {}
		local currentWaypoint = waypoints[1]
		table.insert(smoothedWaypoints, currentWaypoint)

		for i = 2, #waypoints do
			local nextWaypoint = waypoints[i]
			-- Check if a direct path exists between currentWaypoint and nextWaypoint
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {character}

			local rayResult = workspace:Raycast(currentWaypoint.Position, nextWaypoint.Position - currentWaypoint.Position, rayParams)
			if not rayResult then
				-- No obstacle, can skip to nextWaypoint
				currentWaypoint = nextWaypoint
			else
				-- Obstacle detected, add the previous waypoint
				table.insert(smoothedWaypoints, waypoints[i - 1])
				currentWaypoint = waypoints[i - 1]
			end
		end

		-- Ensure the last waypoint is included
		table.insert(smoothedWaypoints, waypoints[#waypoints])

		return smoothedWaypoints
	end
	
	local function canTargetSeeEnemy(character, enemy)
		local npcToCharacter = (character.HumanoidRootPart.Position - enemy.root.Position).Unit
		local npcLook = character.HumanoidRootPart.CFrame.LookVector

		local dotProduct = npcToCharacter:Dot(npcLook)
		--Logger.Debug("TEST GNOME dotProduct:",dotProduct)
		if (dotProduct < 0)  then
			--Logger.Debug("TEST GNOME CAN SEE dotProduct:",dotProduct)
			return true
		else
			--Logger.Debug("TEST GNOME CANT SEE dotProduct:",dotProduct)
			return false
		end
	end

	function this:MoveToTarget(character, target,playerCharacter,enemy,debugPath,overrideParams)
		local targetOffset = (lastTargetPos - target).magnitude
		--print("TEST PATH:",enemy.name," targetOffset:",targetOffset," > TargetOffsetMax:",TargetOffsetMax," lastTargetPos:",lastTargetPos," target:",target)
		--print("TEST PATH TYPE OF VARS:",typeof(targetOffset), typeof(TargetOffsetMax))
		--TODO What was this for??
		if targetOffset > TargetOffsetMax then
		
			local startPoint = character.HumanoidRootPart.Position
			local humanoidState = character.Humanoid:GetState()
			if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
			
				local ray = Ray.new(character.HumanoidRootPart.Position, Vector3.new(0, -100, 0))
				local hitPart, hitPoint = game.Workspace:FindPartOnRay(ray, character)
				if hitPart then
					startPoint = hitPoint
				end
			end

			local newTarget = target
			--local ray = Ray.new(target + Vector3.new(0,-3,0), Vector3.new(0, -100, 0))			
			--local hitPart, hitPoint = game.Workspace:FindPartOnRay(ray, character)
			--if hitPoint then
			--	if (hitPoint - target).magnitude > 4 then
					
			--		--TODO SHOULD WE EVEN USE THIS OR REMOVE IT?
			--		character.Humanoid:MoveTo(target)
			--		return
			--		--newTarget = newTarget * Vector3.new(1,0,1) + Vector3.new(0,3,0)
			--	end
			--end	

			local agentParameters = {
				AgentCanJump = false,
				AgentRadius = 2,  -- Adjust to match your character's size
				AgentHeight = 5,  -- Adjust based on your humanoid height,
				--AgentMaxSlope = 45,
				Costs = {
					NoNav = math.huge
				}
			}
			
			if (overrideParams) then
				agentParameters = overrideParams
			end
			
			--print("TEST AGENT PARAMETERS:",agentParameters,enemy,overrideParams)
			path = PathfindingService:CreatePath(agentParameters)
			path:ComputeAsync(startPoint, newTarget)
			print("TEST Got path",path)
			if path.Status ~= Enum.PathStatus.Success then
				--print(tostring(path.Status))
				print("TEST PATH FAILED")
				character.Humanoid:MoveTo(target)
				--character.Humanoid.Jump = true
			end
			
			if (debugPath) then
				game.Workspace.Points:ClearAllChildren()
				
				local points = this:smoothPath(path:GetWaypoints())

				for _, point in pairs(points) do
					local part = Instance.new("Part", game.Workspace.Points)
					part.CanCollide = false
					part.Anchored = true
					part.Color = Color3.fromRGB(255,255,0)
					part.FormFactor = Enum.FormFactor.Custom
					part.Size = Vector3.new(1,1,1)
					part.Position = point.Position
				end			
			end
			

			currentPointIndex = 1
			lastTargetPos = target
		
		else
			--print("SKIPPING PATH:targetOffset > TargetOffsetMax:",enemy.name,targetOffset,TargetOffsetMax)
		end

		if path then
			--local points = path:GetWaypoints()
			--New smooth path, but has some cost.  above is original
			local points = this:smoothPath(path:GetWaypoints(),character)
			
			if currentPointIndex < #points then
				local currentPoint = points[currentPointIndex]
				local distance = (character.HumanoidRootPart.Position - currentPoint.Position).magnitude
				if distance < NextPointThreshold then
					currentPointIndex = currentPointIndex + 1
				end
				
				if (playerCharacter and canTargetSeeEnemy(playerCharacter,enemy)) then
					return
				end
				
				currentPoint = points[currentPointIndex]
				character.Humanoid:MoveTo(currentPoint.Position)
				if currentPoint.Position.Y - character.HumanoidRootPart.Position.Y > JumpThreshold then
					character.Humanoid.Jump = true
				end
				
				--THIS MADE MOVEMENT LOOK JERKY
				--if currentPoint.Action == Enum.PathWaypointAction.Walk then
					
				--	local at = character.HumanoidRootPart.Position
				--	local lookAt = currentPoint.Position
				--	lookAt = Vector3.new(lookAt.X, at.Y, lookAt.Z)
				--	character.PrimaryPart.CFrame = CFrame.lookAt(at, lookAt)
				--end
				
			else
				character.Humanoid:MoveTo(target)
				return true
			end
		else
			print("TEST NO PATH FOUND:",enemy.name)
		end
	end
	
	function this:MoveToTarget2(character, target)
		
	end

	return this
end
return PathfindingUtility 