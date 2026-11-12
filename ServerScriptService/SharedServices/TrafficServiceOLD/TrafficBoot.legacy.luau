-- ServerScriptService script to register a traffic route with vehicle pool
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local SharedServices = ServerScriptService:WaitForChild("SharedServices")
local TrafficService = require(SharedServices:WaitForChild("TrafficService"))

-- Nodes can be Attachments, Parts, or CFrames
local nodesFolder = workspace:WaitForChild("TrafficNodes"):WaitForChild("TrafficCenter")
local n1 = nodesFolder:WaitForChild("NanoBytesHome") -- Attachment
local n2 = nodesFolder:WaitForChild("PrimeStationDockingEntry1") -- Attachment
local n3 = nodesFolder:WaitForChild("PrimeStationDockingBay1")   -- Attachment

-- Vehicle pool folder (in ServerStorage)
local foodTrucks = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("FoodTrucks")
local freighters = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Freighters")

-- Register the route with a vehicle pool (no specific model needed)
local id = TrafficService.Register(nil, {  -- nil = use vehicle pool
	nodes = { n1, n2, n3 },
	-- pause 10s at start, 1s at middle, 10s at end
	pauseTimes = { 10, 1, 10 },
	mode = "pingpong", -- back and forth forever

	-- NEW: Vehicle pool configuration
	-- Each time it returns to node 1, a new random vehicle spawns
	vehiclePool = {
		storage = foodTrucks,  -- folder with vehicle models
		spawnParent = workspace:WaitForChild("ActiveTraffic"),  -- where to spawn them
	},

	-- motion profile
	startSpeed = 1.5,
	cruiseSpeed = 80,
	accelTime = 2.5,
	arrivalDistance = 0.35,
	arrivalSpeed = 0.5,
	snapEpsilon = 0.1,
	settleTime = 0.2,
	
	-- effects
	leaveEffectTime = 1.2, -- wobble only for 1.2s after leaving each node

	-- NEW: Face movement direction settings
	faceMovementDirection = true,  -- Vehicle will face the direction it's traveling
	-- Options: "-Z" (default), "+Z", "-X", "+X", "-Y", "+Y"

	-- (optional) callbacks
	onEnter = function(model, nodeIndex)
		print(model.Name, "entered node", nodeIndex)
	end,
	onLeave = function(model, nodeIndex)
		print(model.Name, "left node", nodeIndex)
	end,

	-- stability
	anchorWhilePaused = false,
})

print("Registered traffic route id:", id)
print("Vehicles will spawn from:", foodTrucks:GetFullName())