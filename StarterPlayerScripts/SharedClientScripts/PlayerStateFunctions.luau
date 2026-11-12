--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--Remote Events
local PlayerStateChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChanged")
local DeferredAttackEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DeferredAttack")
local PlayerInputEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerInput")
local LocalPlayerInputEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("LocalPlayerInput")
local PlaceObjectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlaceObject")
local ActionEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Action")
local ToolActionEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ToolAction") --Runs after tool animation is done or action event in animation is done

--Functions

--Definition Modules
local attacksModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks")) 
local weaponInfo = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("WeaponInfo"))
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets

--Modules
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))

--Gui

--Context and Actions

--Initialization

local localPlayer = game.Players.LocalPlayer

local DisplayHUDEvent = ReplicatedStorage
	:WaitForChild("SharedRemotes")
	:WaitForChild("DisplayHUD")
local HUDOpen1 = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("HUDOpen1")

local playerState = {

	States = {},
	ToolStates = {},
	CurrentState = {},
	CurrentToolState = {},
	AttackAnimations = {},
	ToolAnimationTypes = {},
	AboveWater = false,
	Diving = false,
	InWater = false,
	DistanceFromWaterBottom = 999999,
	InWaterZone = false,
	InSlideZone = false,
	UnderwaterWalking = false,
	InInnerWaterZone = false,
	InInnerWaterSurfaceZone = false,
	IsSwimming = false,
	IsSprinting = false,
	Crawling = false,
	CurrentTool = "",
	DeferredKeyCode = nil,
	DeferredHitPosition = nil,
	CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0},
	lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0},
	SPEED = 0,
	WalkSpeed = 16,
	CrawlSpeed = 5,
	RunSpeed = 30,
	SlideSpeed = 20,
	RollSpeed = 20,
	NormalHeight = 3.471999883651733,
	CrawlingHeight = 1.972, -- normal - 1.5,
	SittingHeight = 6,
	LastPushedObject = nil,
	NumberOfItemsCarried = 0,
}

local flightSpeed = .5
local keyDown = nil
local keyUp = nil
function playerState.ParachuteControl(on, mouse)

	if (not on) then
		if (keyDown) then
			keyDown:Disconnect()
		end
		if (keyUp) then
			keyUp:Disconnect()
		end
	end

	if (game.UserInputService:IsKeyDown(Enum.KeyCode.W)) then
		playerState.CONTROL.F = flightSpeed
	else
		playerState.CONTROL.F = 0
	end

	keyDown = mouse.KeyDown:Connect(function(KEY)
		if KEY:lower() == 'w' then
			playerState.CONTROL.F = flightSpeed
		elseif KEY:lower() == 's' then
			playerState.CONTROL.B = - flightSpeed
		elseif KEY:lower() == 'a' then
			playerState.CONTROL.L = - flightSpeed
		elseif KEY:lower() == 'd' then 
			playerState.CONTROL.R = flightSpeed
		end
		pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
	end)
	keyUp = mouse.KeyUp:Connect(function(KEY)
		if KEY:lower() == 'w' then
			playerState.CONTROL.F = 0
		elseif KEY:lower() == 's' then
			playerState.CONTROL.B = 0
		elseif KEY:lower() == 'a' then
			playerState.CONTROL.L = 0
		elseif KEY:lower() == 'd' then
			playerState.CONTROL.R = 0
		elseif KEY:lower() == 'e' then
			playerState.CONTROL.Q = 0
		elseif KEY:lower() == 'q' then
			playerState.CONTROL.E = 0
		end
	end)
end

--function playerState.ParachuteHandler(char,humanoid,HRP)

--	playerState.SPEED = 50 * flightSpeed

--	if (playerState.BV ~= nil) then
--		if (playerState.CONTROL.L + playerState.CONTROL.R) ~= 0 or (playerState.CONTROL.F + playerState.CONTROL.B) ~= 0 or (playerState.CONTROL.Q + playerState.CONTROL.E) ~= 0 then
--			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.CONTROL.F + playerState.CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.CONTROL.L + playerState.CONTROL.R, (playerState.CONTROL.F + playerState.CONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
--			playerState.lCONTROL = {F = playerState.CONTROL.F, B = playerState.CONTROL.B, L = playerState.CONTROL.L, R = playerState.CONTROL.R}
--		elseif (playerState.CONTROL.L + playerState.CONTROL.R) == 0 and (playerState.CONTROL.F + playerState.CONTROL.B) == 0 and (playerState.CONTROL.Q + playerState.CONTROL.E) == 0 and playerState.SPEED ~= 0 then
--			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.lCONTROL.F + playerState.lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.lCONTROL.L + playerState.lCONTROL.R, (playerState.lCONTROL.F + playerState.lCONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
--		else
--			--BV.velocity = Vector3.new(0, 0, 0)
--		end

--		local dragCoefficient = 0.05
--		local drag = -1 * (playerState.BV.velocity * dragCoefficient)
--		local newVelocity = playerState.BV.velocity + drag

--		playerState.BV.velocity = newVelocity

--	end

--	--if (functions.BG ~= nil) then
--	--	functions.BG.cframe = functions.BG.cframe:Lerp(workspace.CurrentCamera.CoordinateFrame,.1)
--	--end
--end

--TODO move to some new InventoryFunctions for client side
function GetContainer(inventory,containerId)
	local containerIsInToolbelt = false

	local item = inventory["Items"][containerId]

	--If not in items, check tools
	if (not item) then
		item = inventory["Tools"][containerId]
		containerIsInToolbelt = true
	end

	return item,containerIsInToolbelt
end

--TODO move to some new InventoryFunctions for client side
function ContainerHasItem(inventory,containerId,containerItemId)
	local container,containerIsInToolbelt = GetContainer(inventory,containerId)

	if (not container) then
		return false
	else
		return container.Contains[containerItemId] or false
	end

end

function ContainerInfo(inventory,containerId)
	local container,containerIsInToolbelt = GetContainer(inventory,containerId)

	if (not container) then
		return nil,0,""
	else

		local itemName = ""

		for key, item in pairs(container.Contains) do
			itemName = key
			break
		end

		if (itemName == "") then
			return nil,0,""
		end

		return container.Contains,container.Amount,itemName
	end

end

function playerState.ParachuteHandler(char, humanoid, HRP)

	playerState.SPEED = 50 * flightSpeed

	-- Check if BodyVelocity (BV) exists
	if playerState.BV ~= nil then
		-- Movement controls for forward, backward, left, right, and rotational controls
		if (playerState.CONTROL.L + playerState.CONTROL.R) ~= 0 or (playerState.CONTROL.F + playerState.CONTROL.B) ~= 0 or (playerState.CONTROL.Q + playerState.CONTROL.E) ~= 0 then
			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.CONTROL.F + playerState.CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.CONTROL.L + playerState.CONTROL.R, (playerState.CONTROL.F + playerState.CONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
			playerState.lCONTROL = {F = playerState.CONTROL.F, B = playerState.CONTROL.B, L = playerState.CONTROL.L, R = playerState.CONTROL.R}
		elseif (playerState.CONTROL.L + playerState.CONTROL.R) == 0 and (playerState.CONTROL.F + playerState.CONTROL.B) == 0 and (playerState.CONTROL.Q + playerState.CONTROL.E) == 0 and playerState.SPEED ~= 0 then
			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.lCONTROL.F + playerState.lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.lCONTROL.L + playerState.lCONTROL.R, (playerState.lCONTROL.F + playerState.lCONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
		end

		-- Apply drag to slow down horizontal movement
		local dragCoefficient = 0.05
		local horizontalVelocity = Vector3.new(playerState.BV.velocity.X, 0, playerState.BV.velocity.Z) -- Only X and Z for horizontal drag
		local drag = -horizontalVelocity * dragCoefficient
		local newVelocity = playerState.BV.velocity + drag

		-- Ensure that the Y-velocity does not go upwards (positive Y)
		local minFallSpeed = -10 -- Adjust this value for how fast you want to fall
		local currentYVelocity = playerState.BV.velocity.Y

		-- Ensure that the player is always falling downward at a controlled rate
		if currentYVelocity > minFallSpeed then
			-- Set the Y-velocity to the min fall speed if it's greater than the min fall speed (falling too slowly or going up)
			newVelocity = Vector3.new(newVelocity.X, minFallSpeed, newVelocity.Z)
		else
			-- Otherwise, retain the current Y-velocity, which will naturally fall
			newVelocity = Vector3.new(newVelocity.X, currentYVelocity, newVelocity.Z)
		end

		-- Update the player's velocity
		playerState.BV.velocity = newVelocity
	end
end

function playerState.FloatingHandler(char, humanoid, HRP)

	playerState.SPEED = 50 * flightSpeed

	-- Check if BodyVelocity (BV) exists
	if playerState.BV ~= nil then
		-- Movement controls for forward, backward, left, right, and rotational controls
		if (playerState.CONTROL.L + playerState.CONTROL.R) ~= 0 or (playerState.CONTROL.F + playerState.CONTROL.B) ~= 0 or (playerState.CONTROL.Q + playerState.CONTROL.E) ~= 0 then
			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.CONTROL.F + playerState.CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.CONTROL.L + playerState.CONTROL.R, (playerState.CONTROL.F + playerState.CONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
			playerState.lCONTROL = {F = playerState.CONTROL.F, B = playerState.CONTROL.B, L = playerState.CONTROL.L, R = playerState.CONTROL.R}
		elseif (playerState.CONTROL.L + playerState.CONTROL.R) == 0 and (playerState.CONTROL.F + playerState.CONTROL.B) == 0 and (playerState.CONTROL.Q + playerState.CONTROL.E) == 0 and playerState.SPEED ~= 0 then
			playerState.BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (playerState.lCONTROL.F + playerState.lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(playerState.lCONTROL.L + playerState.lCONTROL.R, (playerState.lCONTROL.F + playerState.lCONTROL.B + playerState.CONTROL.Q + playerState.CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.Position)) * playerState.SPEED
		end

		-- Apply drag to slow down horizontal movement
		local dragCoefficient = 0.05
		local horizontalVelocity = Vector3.new(playerState.BV.velocity.X, 0, playerState.BV.velocity.Z) -- Only X and Z for horizontal drag
		local drag = -horizontalVelocity * dragCoefficient
		local newVelocity = playerState.BV.velocity + drag

		-- Ensure that the Y-velocity does not go upwards (positive Y)
		local minFallSpeed = -1 -- Adjust this value for how fast you want to fall
		local currentYVelocity = playerState.BV.velocity.Y

		-- Ensure that the player is always falling downward at a controlled rate
		if currentYVelocity > minFallSpeed then
			-- Set the Y-velocity to the min fall speed if it's greater than the min fall speed (falling too slowly or going up)
			newVelocity = Vector3.new(newVelocity.X, minFallSpeed, newVelocity.Z)
		else
			-- Otherwise, retain the current Y-velocity, which will naturally fall
			newVelocity = Vector3.new(newVelocity.X, currentYVelocity, newVelocity.Z)
		end

		-- Update the player's velocity
		playerState.BV.velocity = newVelocity
	end
end

function playerState.DiveStartForce(on,HRP)

	if on then
		if (playerState.DiveBV ~= nil) then return end

		playerState.DiveBV = Instance.new('BodyVelocity')
		playerState.DiveBV.Parent = HRP
		playerState.DiveBV.velocity = HRP.CFrame.LookVector*16
		playerState.DiveBV.maxForce = Vector3.new(9e9, 9e9, 9e9)

	else
		if (playerState.DiveBV) then
			playerState.DiveBV.velocity = Vector3.new(0, 0, 0)
			HRP.Velocity = Vector3.new(0, 0, 0)
			playerState.DiveBV:Destroy()
			playerState.DiveBV = nil
		end

	end
end

function playerState.ParachuteControlForce(on,HRP)

	if on then
		if (playerState.BV ~= nil) then return end

		playerState.BV = Instance.new('BodyVelocity')
		playerState.BV.Parent = HRP
		playerState.BV.velocity = Vector3.new(0, 0, 0)
		playerState.BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

	else
		if (playerState.BV) then
			playerState.BV.velocity = Vector3.new(0, 0, 0)
			HRP.Velocity = Vector3.new(0, 0, 0)
			playerState.BV:Destroy()
			playerState.BV = nil
		end

	end
end

function playerState.FloatForce(on,HRP,direction)

	if on then
		if (playerState.BV ~= nil) then return end

		playerState.BV = Instance.new('BodyVelocity')
		playerState.BV.Parent = HRP
		playerState.BV.velocity = direction
		playerState.BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

	else
		if (playerState.BV) then
			playerState.BV.velocity = Vector3.new(0, 0, 0)
			HRP.Velocity = Vector3.new(0, 0, 0)
			playerState.BV:Destroy()
			playerState.BV = nil
		end

	end
end

function playerState.SlowFallForce(on, HRP,Mass)
	if on then
		if playerState.SlowFall ~= nil then return end

		-- Create Attachment and VectorForce
		local attachment = Instance.new('Attachment')
		attachment.Parent = HRP

		playerState.SlowFall = Instance.new('VectorForce')
		playerState.SlowFall.Attachment0 = attachment
		playerState.SlowFall.Force = Vector3.new(0, Mass * (workspace.Gravity+10), 0) --Might need to lower from 10 -- Slight upward force to counter gravity
		playerState.SlowFall.ApplyAtCenterOfMass = true
		playerState.SlowFall.RelativeTo = Enum.ActuatorRelativeTo.World
		playerState.SlowFall.Parent = HRP

	else
		if playerState.SlowFall then
			playerState.SlowFall:Destroy()
			playerState.SlowFall = nil
		end
	end
end

--function playerState.UnderwaterWalkingForce(on, HRP)
--	if on then
--		if playerState.UnderwaterWalkingForce ~= nil then return end

--		-- Create Attachment and VectorForce
--		local attachment = Instance.new('Attachment')
--		attachment.Parent = HRP

--		playerState.UnderwaterWalking = Instance.new('VectorForce')
--		playerState.UnderwaterWalking.Attachment0 = attachment
--		playerState.UnderwaterWalking.Force =  Vector3.new(0, -2 * (HRP.AssemblyMass * workspace.Gravity), 0)
--		playerState.UnderwaterWalking.ApplyAtCenterOfMass = true
--		playerState.UnderwaterWalking.RelativeTo = Enum.ActuatorRelativeTo.World
--		playerState.UnderwaterWalking.Parent = HRP

--	else
--		if playerState.UnderwaterWalking then
--			playerState.UnderwaterWalking:Destroy()
--			playerState.UnderwaterWalking = nil
--		end
--	end
--end

local parachuteTrackConnection = nil
local diveTrackConnection = nil

function playerState.Init(player)

	local humanoid = player.Character:WaitForChild("Humanoid")

	--Load Animations

	--local runningTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Running"))
	--local crawlingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Crawl")) --Maximo 
	--local walkingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Walking"))
	--local idleTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Idle"))
	local jumpingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Jumping"))
	--local climbingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Climbing"))
	local fallingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Falling"))
	--local runningStopTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("RunningStop"))
	local jumpingRollTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("JumpingRoll"))
	local runningJumpTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("RunningJump"))
	local runningStopTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("RunningStop"))




	--local parachuteTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Parachute"))

	local Mass = 0
	for _, Descendant in ipairs(player.Character:GetDescendants()) do
		if (not (Descendant:IsA("BasePart"))) and (not (Descendant:IsA("MeshPart"))) then continue end
		Mass += Descendant:GetMass()
	end

	--if (parachuteTrackConnection) then
	--	parachuteTrackConnection:Disconnect()
	--end

	--parachuteTrackConnection = parachuteTrack:GetMarkerReachedSignal("Pause"):Connect(function()
	--	parachuteTrack:AdjustSpeed(0)
	--	playerState.ParachuteControlForce(true,player.Character.HumanoidRootPart)
	--	playerState.SlowFallForce(true,player.Character.HumanoidRootPart,Mass)
	--end)

	--local toolWalkingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("ToolWalk"))

	--local electrickShockTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("ElectricShock"))
	--local drinkingTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Drinking"))


	local idleAnimation = Instance.new("Animation")
	idleAnimation.AnimationId =  "rbxassetid://94926903791469" --MIXAMO 76512480052650" --121460912324625" --SYNTY 94926903791469" --121460912324625" --123196736047687"
	local  idleTrack = humanoid:LoadAnimation(idleAnimation)

	local walkingAnimation = Instance.new("Animation") --Now only legs and hips only. spines go on upper body animations
	walkingAnimation.AnimationId =  "rbxassetid://100662821629354" --113046237320094" --138272258347352" --MIXAMO 126494634330255" --123196736047687" --SYNTY 138272258347352"--"123196736047687" 
	local  walkingTrack = humanoid:LoadAnimation(walkingAnimation)

	local walkingFullBodyAnimation = Instance.new("Animation") --Now only legs and hips only. spines go on upper body animations
	walkingFullBodyAnimation.AnimationId =  "rbxassetid://138272258347352" --113046237320094" --138272258347352" --MIXAMO 126494634330255" --123196736047687" --SYNTY 138272258347352"--"123196736047687" 
	local  walkingFullBodyTrack = humanoid:LoadAnimation(walkingFullBodyAnimation)

	local runningAnimation = Instance.new("Animation")
	runningAnimation.AnimationId =  "rbxassetid://95585834242532" --RUNNING NO HIPS> WIERD 125484748841019--SYNTY JOG 73617620275759" --MIXAMO 138729400822458" --SYNTY 73617620275759" --138729400822458"
	local  runningTrack = humanoid:LoadAnimation(runningAnimation)

	local runningFullBodyAnimation = Instance.new("Animation")
	runningFullBodyAnimation.AnimationId =  "rbxassetid://80540007410665" --SYNTY JOG 73617620275759" --MIXAMO 138729400822458" --SYNTY 73617620275759" --138729400822458"
	local  runningFullBodyTrack = humanoid:LoadAnimation(runningFullBodyAnimation)

	local slideAnimation = Instance.new("Animation") 
	slideAnimation.AnimationId =  "rbxassetid://101519688461489" --75303655631497" --PERFECT BUT WITH ORIGINAL HIP HEIGHT 104760087778967" --96834514149834" --126583016345891" --97514664134485
	local  slideTrack = humanoid:LoadAnimation(slideAnimation)

	local rollAnimation = Instance.new("Animation") 
	rollAnimation.AnimationId =  "rbxassetid://103012349109728" --95174255103369" --ROLL LONG VERSION 77315614272843" -- BOW ROLL 85216123712208" -- ORIGINAL WORKING SLIDE 104760087778967" --96834514149834" --126583016345891" --97514664134485
	local  rollTrack = humanoid:LoadAnimation(rollAnimation)

	slideTrack.Priority = Enum.AnimationPriority.Action
	rollTrack.Priority = Enum.AnimationPriority.Action

	local crouchingAnimation = Instance.new("Animation") 
	crouchingAnimation.AnimationId =  "rbxassetid://114212423545478" 
	local  crouchingTrack = humanoid:LoadAnimation(crouchingAnimation)

	local crouchingIdleAnimation = Instance.new("Animation") 
	crouchingIdleAnimation.AnimationId =  "rbxassetid://97895681275442" 
	local  crouchingIdleTrack = humanoid:LoadAnimation(crouchingIdleAnimation)

	local crawlingAnimation = Instance.new("Animation") 
	crawlingAnimation.AnimationId =  "rbxassetid://139281391897690" --101343040639073
	local  crawlingTrack = humanoid:LoadAnimation(crawlingAnimation)

	local crawlingIdleAnimation = Instance.new("Animation") 
	crawlingIdleAnimation.AnimationId =  "rbxassetid://119050417601268" 
	local  crawlingIdleTrack = humanoid:LoadAnimation(crawlingIdleAnimation)

	local ledgeGrabAnimation = Instance.new("Animation") 
	ledgeGrabAnimation.AnimationId =  "rbxassetid://130332732901133" --133022061866325" --110928708348061" --WORKING GREAT BUT NOT ANIMATED 137830921874109" --134430615384252" --75132666381959" 
	local ledgeGrabTrack = humanoid:LoadAnimation(ledgeGrabAnimation)

	local climbLedgeAnimation = Instance.new("Animation") 
	climbLedgeAnimation.AnimationId =  "rbxassetid://80318565917776" --124485297367883" --89294925036796" --132591281249691" --100846843631313" --WITH HIP UP MOVEMENT 123499558517139" --74829984209709" --120680832303645"
	local climbLedgeTrack = humanoid:LoadAnimation(climbLedgeAnimation)

	local climbingLadderAnimation = Instance.new("Animation") 
	climbingLadderAnimation.AnimationId =  "rbxassetid://138950179943988" --70786925292613" --114008412537470"
	local climbingLadderTrack = humanoid:LoadAnimation(climbingLadderAnimation)

	local climbingLadderIdleAnimation = Instance.new("Animation") 
	climbingLadderIdleAnimation.AnimationId =  "rbxassetid://90504503499387" --118644058566704" --128511752275688" --106180770368654"
	local climbingLadderIdleTrack = humanoid:LoadAnimation(climbingLadderIdleAnimation)

	climbingLadderTrack.Priority = Enum.AnimationPriority.Movement
	climbingLadderIdleTrack.Priority = Enum.AnimationPriority.Movement
	climbingLadderTrack.Looped = true
	climbingLadderIdleTrack.Looped = true


	local upperBodyWalkingAnimation = Instance.new("Animation") 
	upperBodyWalkingAnimation.AnimationId =  "rbxassetid://111990038221089"
	local upperBodyWalkingTrack = humanoid:LoadAnimation(upperBodyWalkingAnimation)




	local backflipAnimation = Instance.new("Animation")
	backflipAnimation.AnimationId =  "rbxassetid://104275219126757" --SYNTY 104275219126757
	local  backflipTrack = humanoid:LoadAnimation(backflipAnimation)

	local doubleFingerGunsAnimation = Instance.new("Animation")
	doubleFingerGunsAnimation.AnimationId =  "rbxassetid://118340859777391" --SYNTY 118340859777391
	local  doubleFingerGunsTrack = humanoid:LoadAnimation(doubleFingerGunsAnimation)

	local karateAnimation = Instance.new("Animation")
	karateAnimation.AnimationId =  "rbxassetid://72495798345036" --SYNTY 72495798345036
	local  karateTrack = humanoid:LoadAnimation(karateAnimation)

	local flexAnimation = Instance.new("Animation")
	flexAnimation.AnimationId =  "rbxassetid://73453111415792" --SYNTY 73453111415792
	local  flexTrack = humanoid:LoadAnimation(flexAnimation)

	local saluteAnimation = Instance.new("Animation")
	saluteAnimation.AnimationId =  "rbxassetid://75925034693031" --SYNTY 75925034693031
	local  saluteTrack = humanoid:LoadAnimation(saluteAnimation)

	local waveAnimation = Instance.new("Animation")
	waveAnimation.AnimationId =  "rbxassetid://77756858703326" --SYNTY 77756858703326
	local  waveTrack = humanoid:LoadAnimation(waveAnimation)

	local cryAnimation = Instance.new("Animation")
	cryAnimation.AnimationId =  "rbxassetid://77468094662217" --SYNTY 77468094662217
	local  cryTrack = humanoid:LoadAnimation(cryAnimation)

	local lightningAnimation = Instance.new("Animation")
	lightningAnimation.AnimationId =  "rbxassetid://97948084894308" --SYNTY 97948084894308
	local  lightningTrack = humanoid:LoadAnimation(lightningAnimation)

	local spinAnimation = Instance.new("Animation")
	spinAnimation.AnimationId =  "rbxassetid://73986955736410" --SYNTY 73986955736410
	local  spinTrack = humanoid:LoadAnimation(spinAnimation)

	local stretchAnimation = Instance.new("Animation")
	stretchAnimation.AnimationId =  "rbxassetid://87328507893220" --SYNTY 87328507893220
	local  stretchTrack = humanoid:LoadAnimation(stretchAnimation)

	local yawnAnimation = Instance.new("Animation")
	yawnAnimation.AnimationId =  "rbxassetid://129784207584669" --SYNTY 129784207584669
	local  yawnTrack = humanoid:LoadAnimation(yawnAnimation)


	--Tool Using Animation
	local setObjectOnGroundAnimation = Instance.new("Animation")
	setObjectOnGroundAnimation.AnimationId =  "rbxassetid://115275671217645" --127647026434382"
	local  setObjectOnGroundTrack = humanoid:LoadAnimation(setObjectOnGroundAnimation)

	local drinkAnimation = Instance.new("Animation")
	drinkAnimation.AnimationId =  "rbxassetid://77128977677386"
	local drinkTrack = humanoid:LoadAnimation(drinkAnimation)

	local eatAnimation = Instance.new("Animation")
	eatAnimation.AnimationId =  "rbxassetid://102695767494177"
	local eatTrack = humanoid:LoadAnimation(eatAnimation)


	local draggingIdleAnimation = Instance.new("Animation")
	draggingIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=15492519404" --15492419289" --15490983639" --15490934563" --15490881967"
	local draggingIdleTrack =humanoid:LoadAnimation(draggingIdleAnimation)

	local draggingWalkingAnimation = Instance.new("Animation")
	draggingWalkingAnimation.AnimationId = "http://www.roblox.com/asset/?id=15492596645"
	local draggingWalkingTrack =humanoid:LoadAnimation(draggingWalkingAnimation)

	local boomboxIdleAnimation = Instance.new("Animation")
	boomboxIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=18184424016"
	local boomboxIdleTrack =humanoid:LoadAnimation(boomboxIdleAnimation)

	local boomboxWalkingAnimation = Instance.new("Animation")
	boomboxWalkingAnimation.AnimationId = "http://www.roblox.com/asset/?id=18184249510"
	local boomboxWalkingTrack =humanoid:LoadAnimation(boomboxWalkingAnimation)

	local choppingAnimation = Instance.new("Animation")
	choppingAnimation.AnimationId = "http://www.roblox.com/asset/?id=117728090751992" --133315625932249" --90158281552153" --117728090751992" --117697888631507"
	local choppingTrack =humanoid:LoadAnimation(choppingAnimation)

	local pistolIdleAnimation = Instance.new("Animation")
	pistolIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=89234309843676" 
	local pistolIdleTrack =humanoid:LoadAnimation(pistolIdleAnimation)
	pistolIdleTrack.Priority = Enum.AnimationPriority.Action2

	local pistolRunningAnimation = Instance.new("Animation")
	pistolRunningAnimation.AnimationId = "http://www.roblox.com/asset/?id=106329376997144" --105744657821486" --76306564127426" --137078646340658" --110932770882330" --102021982773804" 
	local pistolRunningTrack =humanoid:LoadAnimation(pistolRunningAnimation)
	pistolRunningTrack.Priority = Enum.AnimationPriority.Action2

	local rifleIdleAnimation = Instance.new("Animation")
	rifleIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=137278230152235" 
	local rifleIdleTrack =humanoid:LoadAnimation(rifleIdleAnimation)
	rifleIdleTrack.Priority = Enum.AnimationPriority.Action2

	local flashlightIdleAnimation = Instance.new("Animation")
	flashlightIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=103621371386689" --77902694666419" --128612331545570" 
	local flashlightIdleTrack =humanoid:LoadAnimation(flashlightIdleAnimation)
	flashlightIdleTrack.Priority = Enum.AnimationPriority.Action2


	--local boxingIdleTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("BoxingIdle"))
	--boxingIdleTrack.Priority = Enum.AnimationPriority.Action2



	local boxingIdleAnimation = Instance.new("Animation")
	boxingIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=15330204681"
	local boxingIdleTrack =humanoid:LoadAnimation(boxingIdleAnimation)


	local boxingWalkingAnimation = Instance.new("Animation")
	boxingWalkingAnimation.AnimationId = "http://www.roblox.com/asset/?id=110653377437848" --89073943197603" --15330163358"
	local boxingWalkingTrack =humanoid:LoadAnimation(boxingWalkingAnimation)



	local torchIdleTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("TorchIdle"))
	torchIdleTrack.Priority = Enum.AnimationPriority.Action2

	local torchWalkTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("TorchWalk"))
	torchWalkTrack.Priority = Enum.AnimationPriority.Action2

	local cameraTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("Camera"))
	cameraTrack.Priority = Enum.AnimationPriority.Action2

	--local chainsawIdleTrack = humanoid:LoadAnimation(ReplicatedStorage:WaitForChild("SharedAnimations"):WaitForChild("ChainsawIdle"))
	--chainsawIdleTrack.Priority = Enum.AnimationPriority.Action2

	local swimmingAnimation = Instance.new("Animation")
	swimmingAnimation.AnimationId = "http://www.roblox.com/asset/?id=12655145004" --9053386071"
	local swimmingTrack = humanoid:LoadAnimation(swimmingAnimation)
	swimmingTrack.Looped = true

	local swimmingIdleAnimation = Instance.new("Animation")
	swimmingIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=12116009430"
	local swimmingIdleTrack = humanoid:LoadAnimation(swimmingIdleAnimation)
	swimmingIdleTrack.Looped = true

	local swimmingEdgeAnimation = Instance.new("Animation")
	swimmingEdgeAnimation.AnimationId = "http://www.roblox.com/asset/?id=12177179304" --12175812711"
	local swimmingEdgeTrack = humanoid:LoadAnimation(swimmingEdgeAnimation)
	swimmingEdgeTrack.Looped = true

	local fishingIdleAnimation = Instance.new("Animation")
	fishingIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=93157387434149"
	local fishingIdleTrack = humanoid:LoadAnimation(fishingIdleAnimation)

	local fishingCastingAnimation = Instance.new("Animation")
	fishingCastingAnimation.AnimationId = "http://www.roblox.com/asset/?id=96164340023211" --106775991377172"
	local fishingCastingTrack = humanoid:LoadAnimation(fishingCastingAnimation)

	local fishingReelingAnimation = Instance.new("Animation")
	fishingReelingAnimation.AnimationId = "http://www.roblox.com/asset/?id=93723457075766"
	local fishingReelingTrack = humanoid:LoadAnimation(fishingReelingAnimation)

	local diveAnimation = Instance.new("Animation")
	diveAnimation.AnimationId = "http://www.roblox.com/asset/?id=18320970082" --18320999692 18320676647" --18319974101" --18318734967" --12616653138" --18320137113
	local diveTrack = humanoid:LoadAnimation(diveAnimation)

	local carryDeliveryCrateIdleAnimation = Instance.new("Animation")
	carryDeliveryCrateIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=131743828707045"  --105786603450444
	local carryDeliveryCrateIdleTrack = humanoid:LoadAnimation(carryDeliveryCrateIdleAnimation)

	local carryDeliveryCrateAnimation = Instance.new("Animation")
	carryDeliveryCrateAnimation.AnimationId = "http://www.roblox.com/asset/?id=91935768790276"   --88532136578051
	local carryDeliveryCrateTrack = humanoid:LoadAnimation(carryDeliveryCrateAnimation)

	local carrySmallAnimation = Instance.new("Animation")
	carrySmallAnimation.AnimationId = "http://www.roblox.com/asset/?id=73770209584893" --103648676719465"
	local carrySmallTrack = humanoid:LoadAnimation(carrySmallAnimation)

	local carrySmallIdleAnimation = Instance.new("Animation")
	carrySmallIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=97804909394019" --73770209584893" --89608989633364"
	local carrySmallIdleTrack = humanoid:LoadAnimation(carrySmallIdleAnimation)

	local carryMediumIdleAnimation = Instance.new("Animation")
	carryMediumIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=105461602523775" --139739797558798" -- little bit smaller = 105554160615356" --73770209584893" --89608989633364"
	local carryMediumIdleTrack = humanoid:LoadAnimation(carryMediumIdleAnimation)


	if (diveTrackConnection) then
		diveTrackConnection:Disconnect()
	end

	diveTrackConnection = diveTrack:GetMarkerReachedSignal("End"):Connect(function()
		diveTrack:AdjustSpeed(0)
	end)

	--JumpIntoWater
	--18319926257

	--JumpIntoWaterToDive
	--18319974101

	--Rest Animations (Sitting, Sleeping)
	local sittingAnimation = Instance.new("Animation")
	sittingAnimation.AnimationId = "http://www.roblox.com/asset/?id=82670185019554" --137665163986879" --17415741748" --13452747415" --13452731790" --13452698147" --13452678623" --13452624173" --13452569133"  --13452547135" --13452519995" --13452491336" --13434821879" --9881078485" --8951132198"
	local sittingTrack = humanoid:LoadAnimation(sittingAnimation)

	local sittingForwardAnimation = Instance.new("Animation")
	sittingForwardAnimation.AnimationId = "http://www.roblox.com/asset/?id=137665163986879" --17415741748" --13452747415" --13452731790" --13452698147" --13452678623" --13452624173" --13452569133"  --13452547135" --13452519995" --13452491336" --13434821879" --9881078485" --8951132198"
	local sittingForwardTrack = humanoid:LoadAnimation(sittingForwardAnimation)

	local sittingAtTableAnimation = Instance.new("Animation")
	sittingAtTableAnimation.AnimationId = "http://www.roblox.com/asset/?id=12389770058" --13452731790" --13452698147" --13452678623" --13452624173" --13452569133"  --13452547135" --13452519995" --13452491336" --13434821879" --9881078485" --8951132198"
	local sittingAtTableTrack = humanoid:LoadAnimation(sittingAtTableAnimation)

	local sleepingAnimation = Instance.new("Animation")
	sleepingAnimation.AnimationId = "http://www.roblox.com/asset/?id=8949463565"
	local sleepingTrack = humanoid:LoadAnimation(sleepingAnimation)

	local sittingRelaxedAnimation = Instance.new("Animation")
	sittingRelaxedAnimation.AnimationId = "http://www.roblox.com/asset/?id=99208674530252" --12380734981" --8951132198"
	local sittingRelaxedTrack = humanoid:LoadAnimation(sittingRelaxedAnimation)


	local drivingIdleAnimation = Instance.new("Animation")
	drivingIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=18278139043" --18290135730
	local drivingIdleTrack = humanoid:LoadAnimation(drivingIdleAnimation)

	--End Rest Animations


	local knockedDownAnimation = Instance.new("Animation")
	knockedDownAnimation.AnimationId = "http://www.roblox.com/asset/?id=13521789822" --13520698099"
	local knockedDownTrack = humanoid:LoadAnimation(knockedDownAnimation)

	local deathAnimation = Instance.new("Animation")
	deathAnimation.AnimationId = "http://www.roblox.com/asset/?id=128612022634420" --122786317759583" --95991519570016" --83594331908387" --95676969595977"--78081375672490"
	local deathTrack = humanoid:LoadAnimation(deathAnimation)

	local slingshotAnimation = Instance.new("Animation")
	slingshotAnimation.AnimationId = "http://www.roblox.com/asset/?id=9923904224"
	local slingshotIdleTrack =humanoid:LoadAnimation(slingshotAnimation)

	local nunchucksIdleAnimation = Instance.new("Animation")
	nunchucksIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=15317299882"
	local nunchucksIdleTrack =humanoid:LoadAnimation(nunchucksIdleAnimation)

	local shovelIdleAnimation = Instance.new("Animation")
	shovelIdleAnimation.AnimationId = "http://www.roblox.com/asset/?id=8989713319"
	local shovelIdleTrack =humanoid:LoadAnimation(shovelIdleAnimation)

	local shovelMovingAnimation = Instance.new("Animation")
	shovelMovingAnimation.AnimationId = "http://www.roblox.com/asset/?id=126028445136686"
	local shovelMovingTrack =humanoid:LoadAnimation(shovelMovingAnimation)

	local shovelUsingAnimation = Instance.new("Animation")
	shovelUsingAnimation.AnimationId = "http://www.roblox.com/asset/?id=126028445136686" --Find shovel animation
	local shovelUsingTrack =humanoid:LoadAnimation(shovelUsingAnimation)


	local pusingAnimation = Instance.new("Animation")
	pusingAnimation.AnimationId = "http://www.roblox.com/asset/?id=77934637881290" -- WORKS BUT NOT OFFSET 136835289477979" --140377937410093" --113039488561833" --114295627353662" --83786240951179"
	local pushingTrack =humanoid:LoadAnimation(pusingAnimation)

	local WateringAnimation = Instance.new("Animation")
	WateringAnimation.AnimationId = "http://www.roblox.com/asset/?id=124996660977103" --95443715509680"
	local wateringTrack =humanoid:LoadAnimation(WateringAnimation)

	local CheckHUDAnimation = Instance.new("Animation")
	CheckHUDAnimation.AnimationId = "http://www.roblox.com/asset/?id=100385843118895" --SYNTY
	local checkHUDTrack =humanoid:LoadAnimation(CheckHUDAnimation)

	local StopCheckHUDAnimation = Instance.new("Animation")
	StopCheckHUDAnimation.AnimationId = "http://www.roblox.com/asset/?id=84203348300826" --SYNTY
	local stopCheckHUDTrack =humanoid:LoadAnimation(StopCheckHUDAnimation)



	local queuedActions = {}

	for name, obj in attacksModule do
		if (obj.Animation and obj.Animation ~= "") then
			local animation = Instance.new("Animation")
			animation.AnimationId = "http://www.roblox.com/asset/?id="..obj.Animation
			playerState.AttackAnimations[obj.Animation] = humanoid:LoadAnimation(animation)
			playerState.AttackAnimations[obj.Animation].Priority = Enum.AnimationPriority.Action3

			if (obj.DeferAttack) then
				playerState.AttackAnimations[obj.Animation]:GetMarkerReachedSignal("Release"):Connect(function()

					if (not playerState.DeferredHitPosition) then
						return
					end

					if (not playerState.DeferredKeyCode) then
						return
					end

					table.insert(queuedActions, true)

					--DeferredAttackEvent:Fire(localPlayer)

					--PlayerInputEvent:FireServer(playerState.DeferredKeyCode,playerState.DeferredHitPosition,ToolTransformedWorldCFrame)
					--LocalPlayerInputEvent:Fire(playerState.DeferredKeyCode,playerState.DeferredHitPosition)

					--task.defer(function()
					--local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,playerState.CurrentTool)

					--PlayerInputEvent:FireServer(playerState.DeferredKeyCode,playerState.DeferredHitPosition,ToolTransformedWorldCFrame)
					--LocalPlayerInputEvent:Fire(playerState.DeferredKeyCode,playerState.DeferredHitPosition)

					--end)

					--task.spawn(function()

					--	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,playerState.CurrentTool)

					--	PlayerInputEvent:FireServer(playerState.DeferredKeyCode,playerState.DeferredHitPosition,ToolTransformedWorldCFrame)
					--	LocalPlayerInputEvent:Fire(playerState.DeferredKeyCode,playerState.DeferredHitPosition)

					--	task.wait(1)
					--	-- Do other stuff
					--end)


				end)
			end



		end
	end	

	RunService.Heartbeat:Connect(function()
		if #queuedActions > 0 then
			for i = 1, #queuedActions do
				local action = queuedActions[i] -- capture reference safely
				if action then
					task.delay(0.1,function()
						local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(localPlayer,playerState.CurrentTool)

						PlayerInputEvent:FireServer(playerState.DeferredKeyCode,playerState.DeferredHitPosition,ToolTransformedWorldCFrame)
						--LocalPlayerInputEvent:Fire(playerState.DeferredKeyCode,playerState.DeferredHitPosition)
					end)
				end

			end
			table.clear(queuedActions)
		end

	end)

	--Setup States

	playerState.States = {
		["None"]={Name="None",Animation=nil,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		["Idle"]={Name="Idle",Animation=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Walking"]={Name="Walking",Animation=walkingFullBodyTrack,ToolAnimation=walkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Running"]={Name="Running",Animation=runningFullBodyTrack,ToolAnimation=runningTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Jumping"]={Name="Jumping",Animation=jumpingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Climbing"]={Name="Climbing",Animation=climbingLadderTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["ClimbingIdle"]={Name="ClimbingIdle",Animation=climbingLadderIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Falling"]={Name="Falling",Animation=fallingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["RunningJump"]={Name="RunningJump",Animation=runningJumpTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["DoubleJump"]={Name="DoubleJump",Animation=jumpingRollTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["Parachute"]={Name="Parachute",Animation=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Floating"]={Name="Floating",Animation=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Sliding"]={
			Name="Sliding",
			Animation=slideTrack,
			ToolAnimation=nil,
			Playing=false,
			AnimationSpeed=1,
			AnimationFadeTime=0,
			AnimationWeight=1,
			ForceFullBody=true,
		},

		["Rolling"]={
			Name="Rolling",
			Animation=rollTrack,
			ToolAnimation=nil,
			Playing=false,
			AnimationSpeed=1,
			AnimationFadeTime=0,
			AnimationWeight=1,
			ForceFullBody=true,
		},
		["RunningStop"]={Name="RunningStop",Animation=runningStopTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},


		["Crouching"]={Name="Crouching",Animation=crouchingTrack, Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["CrouchingIdle"]={Name="CrouchingIdle",Animation=crouchingIdleTrack, Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["Crawling"]={Name="Crawling",Animation=crawlingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["CrawlingIdle"]={Name="CrawlingIdle",Animation=crawlingIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		["HoldingEdge"]={Name="HoldingEdge",Animation=ledgeGrabTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["ClimbLedge"]={Name="ClimbLedge",Animation=climbLedgeTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},


		["Pushing"]={Name="Pushing",Animation=pushingTrack,ToolAnimation=walkingTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=0,AnimationWeight=1},
		["CheckHUD"]={Name="CheckHUD",Animation=checkHUDTrack,ToolAnimation=checkHUDTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["StopCheckHUD"]={Name="StopCheckHUD",Animation=stopCheckHUDTrack,ToolAnimation=stopCheckHUDTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		--["Placing"]={Name="Placing",Animation=setObjectOnGroundTrack,ToolAnimation=setObjectOnGroundTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=0,AnimationWeight=1},



		["Attacking"]={Name="Attacking",Animation=nil,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},


		--EMOTES
		["Backflip"]={Name="Backflip",Animation=backflipTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["DoubleFingerGuns"]={Name="DoubleFingerGuns",Animation=doubleFingerGunsTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1,SoundID="127281197428523"},
		["Karate"]={Name="Karate",Animation=karateTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1,SoundID="133815422895408"},
		["Flex"]={Name="Flex",Animation=flexTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Salute"]={Name="Salute",Animation=saluteTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Wave"]={Name="Wave",Animation=waveTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Cry"]={Name="Cry",Animation=cryTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Lightning"]={Name="Lightning",Animation=lightningTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Spin"]={Name="Spin",Animation=spinTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Stretch"]={Name="Stretch",Animation=stretchTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},
		["Yawn"]={Name="Yawn",Animation=yawnTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=1,AnimationWeight=1},


		["Jetpacking"]={Name="Jetpacking",Animation=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},


		--Flying
		["Flying"]={Name="Flying",Animation=sittingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},

		--Swimming
		--["JumpIntoWater"]={Name="JumpIntoWater",Animation=jumpIntoWaterTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=0,AnimationWeight=1},
		["DivingIntoWater"]={Name="DivingIntoWater",Animation=diveTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=0,AnimationWeight=1},
		["EnteringWater"]={Name="EnteringWater",Animation=swimmingIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["UnderwaterSwimming"]={Name="UnderwaterSwimming",Animation=swimmingTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["UnderwaterSwimmingIdle"]={Name="UnderwaterSwimmingIdle",Animation=swimmingIdleTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["UnderwaterWalking"]={Name="UnderwaterWalking",Animation=walkingTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["UnderwaterWalkingIdle"]={Name="UnderwaterWalkingIdle",Animation=idleTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["SurfaceSwimming"]={Name="SurfaceSwimming",Animation=swimmingTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["SurfaceSwimmingIdle"]={Name="SurfaceSwimmingIdle",Animation=swimmingIdleTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["Diving"]={Name="Diving",Animation=swimmingTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		["HoldingWaterEdge"]={Name="HoldingWaterEdge",Animation=swimmingEdgeTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},
		--["StopDiving"]={Name="StopDiving",Animation=jumpingRollTrack,Playing=false,AnimationSpeed=2,AnimationFadeTime=.1,AnimationWeight=1},


		--Sitting,Laying down etc
		["Sitting"]={Name="Sitting",Animation=sittingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["SittingForward"]={Name="SittingForward",Animation=sittingForwardTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["SittingAtTable"]={Name="SittingAtTable",Animation=sittingAtTableTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["Sleeping"]={Name="Sleeping",Animation=sleepingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["SittingRelaxed"]={Name="SittingRelaxed",Animation=sittingRelaxedTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["KnockedDown"]={Name="KnockedDown",Animation=knockedDownTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		["UsingTool"]={Name="UsingTool",Animation=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},

		--["ElectricShock"]={Name="ElectricShock",Animation=electrickShockTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},
		--["Drinking"]={Name="Drinking",Animation=drinkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},

		--Driving
		["DrivingIdle"]={Name="DrivingIdle",Animation=drivingIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1},

		["Death"]={Name="Death",Animation=deathTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=.1,AnimationWeight=1, Ragdoll=true},

	}

	playerState.ToolStates = {
		["NoTool"]={Name="NoTool",Animation=nil,AnimationMoving=nil,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["NerdGun"]={Name="NerdGun",Animation=rifleIdleTrack,AnimationMoving=rifleIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["SciCoP92"]={Name="SciCoP92",Animation=rifleIdleTrack,AnimationMoving=rifleIdleTrack,AnimationRunning=pistolRunningTrack,AnimationWalking=rifleIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["SciCo00Zero"]={Name="SciCo00Zero",Animation=pistolIdleTrack,AnimationMoving=pistolIdleTrack,AnimationRunning=pistolRunningTrack,AnimationWalking=pistolIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["DeathRay"]={Name="DeathRay",Animation=gunIdleTrack,AnimationMoving=gunIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["BottleRocket"]={Name="BottleRocket",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Fists"]={Name="Fists",Animation=boxingIdleTrack,AnimationMoving=boxingWalkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["BoxingGloves"]={Name="BoxingGloves",Animation=boxingIdleTrack,AnimationMoving=boxingWalkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Torch"]={Name="Torch",Animation=torchIdleTrack,AnimationMoving=torchWalkTrack,Moving=false,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Camera"]={Name="Camera",Animation=cameraTrack,AnimationMoving=cameraTrack,Moving=false,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["ChainSaw"]={Name="ChainSaw",Animation=chainsawIdleTrack,AnimationMoving=chainsawIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Slingshot"]={Name="Slingshot",Animation=slingshotIdleTrack,AnimationMoving=slingshotIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Nunchucks"]={Name="Nunchucks",Animation=nunchucksIdleTrack,AnimationMoving=nunchucksIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["GiantStinger"]={Name="GiantStinger",Animation=idleTrack,AnimationMoving=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Crossbow"]={Name="Crossbow",Animation=rifleIdleTrack,AnimationMoving=rifleIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["HarpoonGun"]={Name="HarpoonGun",Animation=rifleIdleTrack,AnimationMoving=rifleIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		----["FishingPole"]={Name="FishingPole",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Moving=false,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		--["MetalDetector"]={Name="MetalDetector",Animation=metalDetectorTrack,AnimationMoving=metalDetectorTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100,NoMix=false},
		--["GhostDetector"]={Name="GhostDetector",Animation=metalDetectorTrack,AnimationMoving=metalDetectorTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100,NoMix=false},

		--["Balloon"]={Name="Balloon",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["PoisonGasBalloon"]={Name="PoisonGasBalloon",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		

		["Plunger"]={Name="Plunger",Animation=idleTrack,AnimationMoving=walkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["WateringCan"]={Name="WateringCan",Animation=idleTrack,AnimationMoving=walkingTrack,AnimationUsing=wateringTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,ToolFX="WateringStart",ToolFXRequiredItem="Water"},
		["Flashlight"]={Name="Flashlight",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Moving=false,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Hairspray"]={Name="Hairspray",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Spraypaint"]={Name="Spraypaint",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Pyrospray"]={Name="Pyrospray",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["GlueGun"]={Name="GlueGun",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Trashbag"]={Name="Trashbag",Animation=draggingIdleTrack,AnimationMoving=draggingWalkingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100,NoMix=true},
		["Shovel"]={Name="Shovel",Animation=idleTrack,AnimationMoving=shovelMovingTrack,AnimationUsing=shovelIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100},
		--["SloppyBurgerItem"]={Name="SloppyBurgerItem",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		["Hatchet"]={Name="Hatchet",Animation=idleTrack,AnimationMoving=shovelMovingTrack,AnimationUsing=choppingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100},
		["SharpHatchet"]={Name="SharpHatchet",Animation=idleTrack,AnimationMoving=shovelMovingTrack,AnimationUsing=choppingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100},
		["Axe"]={Name="Axe",Animation=idleTrack,AnimationMoving=shovelMovingTrack,AnimationUsing=choppingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100},
		["FiremansAxe"]={Name="FiremansAxe",Animation=idleTrack,AnimationMoving=shovelMovingTrack,AnimationUsing=choppingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100},


		--TODO could add specific swimming animations for swimming + holding boombox
		["Boombox"]={Name="Boombox",Animation=boomboxIdleTrack,AnimationMoving=boomboxWalkingTrack,AnimationIdleSwimming=swimmingIdleTrack,AnimationSwimming=swimmingTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=100,NoMix=false},
		--["Electricasm"]={Name="Electricasm",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["Hammer"]={Name="Hammer",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		--["SledgeHammer"]={Name="SledgeHammer",Animation=flashlightIdleTrack,AnimationMoving=flashlightIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		--Thrown items
		["Egg"]={Name="Egg",Animation=idleTrack,AnimationMoving=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Shuriken"]={Name="Shuriken",Animation=idleTrack,AnimationMoving=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["LawnDart"]={Name="LawnDart",Animation=idleTrack,AnimationMoving=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["Baseball"]={Name="Baseball",Animation=idleTrack,AnimationMoving=idleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		--["FishDeliveryCrate"]={Name="FishDeliveryCrate",Animation=carryDeliveryCrateIdleTrack,AnimationMoving=carryDeliveryCrateTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=true},
		--["LogPile"]={Name="LogPile",Animation=carryDeliveryCrateIdleTrack,AnimationMoving=carryDeliveryCrateTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=true},
		["Chicken"]={Name="Chicken",Animation=carrySmallIdleTrack,AnimationMoving=carrySmallIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=false},
		--["GaterMadeDelivery"]={Name="GaterMadeDelivery",Animation=carryDeliveryCrateIdleTrack,AnimationMoving=carryDeliveryCrateTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=true},
		--["CoconutDelivery"]={Name="CoconutDelivery",Animation=carrySmallIdleTrack,AnimationMoving=carrySmallTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=true},
		--["BeeHive"]={Name="BeeHive",Animation=carrySmallIdleTrack,AnimationMoving=carrySmallTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=true},
		["Cargo1"]={Name="Cargo1",Animation=carryMediumIdleTrack,AnimationMoving=carryMediumIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=false},
		["Cargo2"]={Name="Cargo2",Animation=carrySmallIdleTrack,AnimationMoving=carrySmallIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=false},
		["Cargo3"]={Name="Cargo3",Animation=carryMediumIdleTrack,AnimationMoving=carryMediumIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=false},
		["Cargo4"]={Name="Cargo4",Animation=carryMediumIdleTrack,AnimationMoving=carryMediumIdleTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1,NoMix=false},


		["Rocket"]={Name="Rocket",Animation=idleTrack,AnimationMoving=walkingFullBodyTrack,AnimationRunning=upperBodyWalkingTrack,AnimationWalking=walkingFullBodyTrack,AnimationUsing=setObjectOnGroundTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

		["SciColaCan"]={Name="SciColaCan",Animation=idleTrack,AnimationMoving=walkingFullBodyTrack,AnimationRunning=upperBodyWalkingTrack,AnimationWalking=walkingFullBodyTrack,AnimationUsing=drinkTrack,AnimationUsing2=setObjectOnGroundTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},
		["PizzaSlice"]={Name="PizzaSlice",Animation=idleTrack,AnimationMoving=walkingFullBodyTrack,AnimationRunning=upperBodyWalkingTrack,AnimationWalking=walkingFullBodyTrack,AnimationUsing=eatTrack,AnimationUsing2=setObjectOnGroundTrack,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},



		--["FryingPan"]={Name="FryingPan",Animation=nil,AnimationMoving=nil,Playing=false,AnimationSpeed=1,AnimationFadeTime=0,AnimationWeight=1},

	}

	playerState.ToolAnimationTypes = {
		["Idle"]={Name="Idle"},
		["Moving"]={Name="Moving"},
		["Using"]={Name="Using"},
		["SwimmingIdle"]={Name="SwimmingIdle"},
		["Swimming"]={Name="Swimming"}

	}

	--AnimationHooks
	local setRocketAnimation = playerState.ToolStates["Rocket"].AnimationUsing
	local setRocketEvent
	setRocketEvent = setRocketAnimation:GetMarkerReachedSignal("Set"):Connect(function(paramString)

		ToolActionEvent:Fire("Rocket","Set")
		--setRocketEvent:Disconnect()
	end)

	local checkHUDEvent
	checkHUDEvent = checkHUDTrack:GetMarkerReachedSignal("End"):Connect(function(paramString)
		checkHUDTrack:AdjustSpeed(0)

		print("TEST HUD Send DisplayHUD")
		DisplayHUDEvent:FireServer("DisplayHUD")

		HUDOpen1:Play()
	end)
	
	local slideEvent
	slideEvent = slideTrack:GetMarkerReachedSignal("End"):Connect(function(paramString)
		if playerState.CurrentState ~= playerState.States.Sliding then return end

		playerState.Crouching = false
		playerState.Sliding = false
		--playerState.IsSprinting = true
		humanoid.WalkSpeed = playerState.RunSpeed
		playerState.ChangeState(playerState.States.Running)
	end)
	
	local rollEvent
	rollEvent = rollTrack:GetMarkerReachedSignal("End"):Connect(function(paramString)
		if playerState.CurrentState ~= playerState.States.Rolling then return end

		playerState.Crouching = false
		playerState.Rolling = false
		playerState.IsSprinting = true
		humanoid.WalkSpeed = playerState.RunSpeed
		playerState.ChangeState(playerState.States.Running)
	end)

	playerState.CurrentState = playerState.States.Idle
	playerState.CurrentToolState = playerState.ToolStates.NoTool

end

function playerState.StopAllToolAnimations()
	print("TEST TOOL ANIMATION Stop ALL animations:", debug.traceback())

	local ts = playerState.CurrentToolState
	if ts.Animation then ts.Animation:Stop(0.15) end
	if ts.AnimationMoving then ts.AnimationMoving:Stop(0.15) end
	if ts.AnimationRunning then ts.AnimationRunning:Stop(0.15) end
	if ts.AnimationWalking then ts.AnimationWalking:Stop(0.15) end
	if ts.AnimationUsing then ts.AnimationUsing:Stop(0.15) end
	if ts.AnimationIdleSwimming then ts.AnimationIdleSwimming:Stop(0.15) end
	if ts.AnimationSwimming then ts.AnimationSwimming:Stop(0.15) end

	ts.Playing = false
end


local debounce = false

-- helper: phase-match and weight-blend without delay
local function phaseBlend(curTrack: AnimationTrack, nextTrack: AnimationTrack, fade: number?, speed: number?)
	if not curTrack or not nextTrack then return end
	local curLen  = math.max(curTrack.Length, 1/60)
	local phase   = (curTrack.TimePosition % curLen) / curLen
	local nextLen = math.max(nextTrack.Length, 1/60)

	if not nextTrack.IsPlaying then
		-- pre-arm next at weight 0 so there's no startup lag
		nextTrack:Play(0.0, 0.0, speed or 1.0)
	else
		nextTrack:AdjustWeight(0, 0)
	end

	nextTrack.TimePosition = phase * nextLen

	fade = fade or 0.10
	curTrack:AdjustWeight(0,    fade)
	nextTrack:AdjustWeight(1.0, fade)

	-- optional: stop the old after the blend finishes
	task.delay(fade, function()
		if curTrack.IsPlaying then curTrack:Stop(0) end
	end)
end

local function isAirState(s)
	local n = s.Name
	return n == playerState.States.Jumping.Name
		or n == playerState.States.Falling.Name
		or n == playerState.States.RunningJump.Name
		or n == playerState.States.DoubleJump.Name
end

function playerState.ChangeState(state, keyCode, hitPosition)
	if (debounce) then
		debounce = false
		return
	end

	debounce = true

	if (not state) then
		warn("playerState.ChangeState state was null", debug.traceback())
		debounce = false
		return
	end

	-- The current tool does not have a Use, so do not change state
	if ((state.Name == playerState.States.UsingTool.Name) and (playerState.CurrentToolState.AnimationUsing == nil)) then
		debounce = false
		return
	end

	-- release pushing ownership, etc.
	if (playerState.LastPushedObject) then
		ActionEvent:FireServer("ReleaseOwnership", playerState.LastPushedObject)
		--playerState.LastPushedObject.Anchored = true
		--playerState.LastPushedObject.VectorForce.Force = Vector3.zero
		playerState.LastPushedObject = nil
	end

	local doNotPlayAnimation = false
	if (playerState.CurrentToolState.Playing) then
		if (playerState.CurrentToolState.NoMix) then
			doNotPlayAnimation = true
		end
	end

	Logger.DebugWithTrace( --Debug
		"ChangeState: "..playerState.CurrentState.Name.." --> "..state.Name
			.." CurrentToolState:"..playerState.CurrentToolState.Name
			.." doNotPlayAnimation:", doNotPlayAnimation
	)
	--print("TEST DEBUGGER:",debug.traceback())

	----------------------------------------------------------------
	-- Special-case: Running -> Walking with phase-matched blending
	-- IMPORTANT: If armed (tool equipped) and both states have ToolAnimation,
	-- blend bottom-half tracks; otherwise blend full-body tracks.
	----------------------------------------------------------------
	local handledRunToWalk = false

	local function isArmed()
		return playerState.CurrentToolState ~= playerState.ToolStates.NoTool
	end

	if playerState.CurrentState
		and playerState.CurrentState.Name == playerState.States.Running.Name
		and state
		and state.Name == playerState.States.Walking.Name
		and not doNotPlayAnimation
	then
		local useToolTracks =
			isArmed()
			and playerState.CurrentState.ToolAnimation
			and state.ToolAnimation

		if useToolTracks then
			phaseBlend(
				playerState.CurrentState.ToolAnimation,
				state.ToolAnimation,
				state.AnimationFadeTime or 0.10,
				state.AnimationSpeed or 1.0
			)

			-- prevent full-body locomotion tracks from lingering underneath
			if playerState.CurrentState.Animation and playerState.CurrentState.Animation.IsPlaying then
				playerState.CurrentState.Animation:Stop(0)
			end
			if state.Animation and state.Animation.IsPlaying then
				state.Animation:Stop(0)
			end
		else
			phaseBlend(
				playerState.CurrentState.Animation,
				state.Animation,
				state.AnimationFadeTime or 0.10,
				state.AnimationSpeed or 1.0
			)

			-- prevent tool locomotion tracks from lingering underneath
			if playerState.CurrentState.ToolAnimation and playerState.CurrentState.ToolAnimation.IsPlaying then
				playerState.CurrentState.ToolAnimation:Stop(0)
			end
			if state.ToolAnimation and state.ToolAnimation.IsPlaying then
				state.ToolAnimation:Stop(0)
			end
		end

		-- mark state flags; we already blended to the new loop
		playerState.CurrentState.Playing = false
		state.Playing = true
		handledRunToWalk = true
	end

	----------------------------------------------------------------
	-- Stop current state's locomotion (unless we already handled Run->Walk)
	----------------------------------------------------------------
	if (playerState.CurrentState.Playing) and not handledRunToWalk then

		local fadeOut = playerState.CurrentState.AnimationFadeTime or 0.15

		if ((playerState.CurrentToolState ~= playerState.ToolStates.NoTool)
			and playerState.CurrentState["ToolAnimation"] ~= nil) then

			-- ToolAnimation on states is bottom-half locomotion
			playerState.CurrentState.ToolAnimation:Stop(fadeOut)
			playerState.CurrentState.Animation:Stop(fadeOut)
		else
			-- safety: sometimes ToolAnimation exists even when unarmed
			if (playerState.CurrentState.ToolAnimation) then
				playerState.CurrentState.ToolAnimation:Stop(fadeOut)
			end
			playerState.CurrentState.Animation:Stop(fadeOut)
		end

		playerState.CurrentState.Playing = false
	end

	----------------------------------------------------------------
	-- Play next state's locomotion (unless we already handled Run->Walk)
	----------------------------------------------------------------
	if (not doNotPlayAnimation) and not handledRunToWalk then
		if (state.Animation ~= nil) then

			local useToolAnimation =
				playerState.CurrentToolState ~= playerState.ToolStates.NoTool
				and state.ToolAnimation
				and not state.ForceFullBody

			if state.ForceFullBody then
				playerState.StopAllToolAnimations()
			end

			if useToolAnimation then
				-- armed: play bottom-half locomotion
				state.ToolAnimation:Play(
					state.AnimationFadeTime or 0.05,
					state.AnimationWeight or 1,
					state.AnimationSpeed or 1
				)
			else
				-- unarmed OR forced full-body action like roll/slide
				playerState.DeferredKeyCode = keyCode
				playerState.DeferredHitPosition = hitPosition

				state.Animation:Play(
					state.AnimationFadeTime or 0.05,
					state.AnimationWeight or 1,
					state.AnimationSpeed or 1
				)
			end

			state.Playing = true
		end
	end

	----------------------------------------------------------------
	-- Tool overlay animation selection (idle/move/use/swim)
	----------------------------------------------------------------
	if (playerState.CurrentToolState ~= playerState.ToolStates.NoTool) then
		if state.ForceFullBody then
			playerState.StopAllToolAnimations()

		elseif isAirState(state) then
			playerState.StopAllToolAnimations()

		elseif (state.Name == playerState.States.UsingTool.Name) then
			playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.Using)

		elseif (state.Name == playerState.States.Idle.Name) then
			-- Keep base idle alive under the tool upper-body pose.
			if state.Animation and not state.Animation.IsPlaying then
				state.Animation:Play(
					state.AnimationFadeTime or 0.15,
					state.AnimationWeight or 1,
					state.AnimationSpeed or 1
				)
			end

			state.Playing = true
			playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.Idle)
		elseif (state == playerState.States.SurfaceSwimming) or (state == playerState.States.UnderwaterSwimming) then
			playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.Swimming)

		elseif (state == playerState.States.SurfaceSwimmingIdle) or (state == playerState.States.UnderwaterSwimmingIdle) then
			playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.SwimmingIdle)

		else
			playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.Moving)
		end
	end

	playerState.CurrentState = state
	PlayerStateChangedEvent:Fire(playerState.CurrentState.Name, playerState.InWater)

	debounce = false
end

function playerState.HandleAttack(weapon,keyCode,hitPosition)
	local attack = attacksModule[weapon.WeaponAttacks[keyCode.Name].Name]

	--Maybe move this into PlayerStateFunctions
	if (playerState.AttackAnimations[attack.Animation] == nil) then
		warn("PlayerStateFunctions.HandleAttack no animation found")
		return
	end

	playerState.States.Attacking.Animation = playerState.AttackAnimations[attack.Animation]
	playerState.States.Attacking.AnimationSpeed = attack.AnimationSpeed


	playerState.ChangeState(playerState.States.Attacking,keyCode,hitPosition)
end

function playerState.ChangeIsSwimmingState(isSwimming)
	playerState.IsSwimming = isSwimming
	PlayerStateChangedEvent:Fire(playerState.CurrentState.Name,playerState.IsSwimming)

	if(isSwimming) then
		playerState.ChangeToolAnimation(playerState.ToolAnimationTypes.Swimming)
	end

end

function playerState.ChangeToolState(state,toolName)

	playerState.CurrentTool = toolName

	if (state.Name == playerState.CurrentToolState.Name) then
		return
	end

	--Logger.Debug("ChangeToolState: "..playerState.CurrentToolState.Name.." --> "..state.Name)


	if (playerState.CurrentToolState.Playing) then

		playerState.StopAllToolAnimations()

		playerState.CurrentState.Animation:Play()
	end


	playerState.CurrentToolState = state

	Logger.Debug("PlayerStateFunctions.ChangeToolState InWater:",playerState.InWater)
	if (playerState.InWater) then
		--playerState.ChangeState(playerState.States.SurfaceSwimmingIdle)
	else
		playerState.ChangeState(playerState.States.Idle)
	end


end

local currentToolAnimationPlaying = ""


local activeEmoteConnection = nil
local activeEmoteThread = nil

function playerState.PlayEmote(state, playSound)
	local animation = state.Animation

	-- Cancel any previous emote
	if activeEmoteConnection then
		activeEmoteConnection:Disconnect()
		activeEmoteConnection = nil
	end
	if activeEmoteThread then
		task.cancel(activeEmoteThread)
		activeEmoteThread = nil
	end

	playerState.CurrentState.Animation:Stop(0.1)
	print("ChangeState to Emote:", state.Name)
	playerState.CurrentState = state
	animation:Play()

	local finished = false

	activeEmoteConnection = animation.Stopped:Connect(function()
		if finished then return end
		finished = true
		activeEmoteConnection:Disconnect()
		activeEmoteConnection = nil
		playerState.ChangeState(playerState.States.Idle)
	end)

	activeEmoteThread = task.delay(animation.Length + 0.2, function()
		if finished then return end
		finished = true
		if activeEmoteConnection then
			activeEmoteConnection:Disconnect()
			activeEmoteConnection = nil
		end
		playerState.ChangeState(playerState.States.Idle)
	end)

	if playSound and state.SoundID then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. state.SoundID
		sound.Parent = script.Parent
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
end
--Plays tool animation and sends event when stopped.  Could be updated to send bindable event also when hitting an animation event
local function PlayToolAnimation(toolName,animation, waitUntilFinished, timeoutSeconds,fadeTime,weight,speed,toolFX,ToolFXRequiredItem)

	waitUntilFinished = waitUntilFinished or false
	timeoutSeconds = timeoutSeconds or 5

	if (currentToolAnimationPlaying == animation.Name) then
		return
	end

	local toolFXEmitter = nil
	if (toolFX) then
		local toolHandle = weaponInfo.GetToolHandle(localPlayer,toolName)

		toolFXEmitter = toolHandle.Attachment.FX
	end

	currentToolAnimationPlaying = animation.Name
	animation:Play()

	if waitUntilFinished then
		local finished = false

		local toolFXConnection = nil

		if (toolFX) then
			-- Yield until the "Fire" event is hit:
			toolFXConnection = animation:GetMarkerReachedSignal(toolFX):Connect(function(paramString)
				--enable FX
				if (toolFXEmitter) then

					--TODO check that you have the required item to show the tool fx
					local playerInventory = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory"):InvokeServer()

					local contains,amount,itemName = ContainerInfo(playerInventory,toolName)
					print("TEST TOOL CONTAINER contains:",contains," amount:",amount)
					if (amount > 0) then

						if (itemsmodule[toolName].AllowedToContain == "Liquid") then
							print("TEST TOOL CONTAINER itemName:",itemName)
							local colorType = itemsmodule[itemName].Traits["Color"]
							toolFXEmitter.Color = ColorSequence.new(itemsmodule.ColorMap[colorType]) or ColorSequence.new(Color3.fromRGB(25,218,231))
						end

						toolFXEmitter.Enabled = true

					end

				end

				toolFXConnection:Disconnect()
			end) 
		end

		-- Create a connection to listen for stop
		local connection
		connection = animation.Stopped:Connect(function()
			finished = true
			currentToolAnimationPlaying = ""

			if (toolFX) then
				--disable FX
				if (toolFXEmitter) then
					toolFXEmitter.Enabled = false
				end
			end

			ToolActionEvent:Fire(toolName,"Stopped")
			if connection then connection:Disconnect() end
		end)

		-- Timeout loop
		local elapsed = 0
		while not finished and elapsed < timeoutSeconds do
			task.wait(0.1)
			elapsed += 0.1
		end

		if not finished and toolFXConnection then
			--disable FX
			if (toolFXEmitter) then
				toolFXEmitter.Enabled = false
			end
			toolFXConnection:Disconnect()
		end

		if not finished and connection then
			connection:Disconnect()
		end

	else
		currentToolAnimationPlaying = ""
	end
end

function playerState.ChangeToolAnimation(toolAnimationType)

	--Logger.Debug("ChangeToolAnimation type:",toolAnimationType)
	--Stop all current tool animations

	-- If we're currently in a Using swing, ignore other tool anim requests
	--local usingTrack = playerState.CurrentToolState
	--	and playerState.CurrentToolState.AnimationUsing

	--if usingTrack and usingTrack.IsPlaying
	--	and toolAnimationType ~= playerState.ToolAnimationTypes.Using then
	--	print("TEST TOOL PLAYING USING ANIMATION")
	--	return
	--end

	--print("TEST TOOL ANIMATION ChangeToolAnimation: ",playerState.CurrentToolState)

	--if toolAnimationType == playerState.ToolAnimationTypes.Using then
	--	local tr = playerState.CurrentToolState and playerState.CurrentToolState.AnimationUsing
	--	if tr and tr.IsPlaying then
	--		print("TEST TOOL ALREADY PLAYING USING ANIMATION")
	--		return -- already playing; don't stop/restart
	--	end
	--end

	if (playerState.CurrentToolState.Playing) then

		playerState.StopAllToolAnimations()
	end

	if (toolAnimationType == playerState.ToolAnimationTypes.Idle) then
		if (playerState.CurrentToolState.Animation ~= nil) then
			playerState.CurrentToolState.Animation:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			playerState.CurrentToolState.Playing = true
			playerState.CurrentToolState.Moving = false
		end
	elseif (toolAnimationType == playerState.ToolAnimationTypes.Moving) then
		if (playerState.CurrentToolState.AnimationMoving ~= nil) then
			if (playerState.CurrentToolState.AnimationRunning and playerState.IsSprinting) then
				print("TEST ANIMATION 1")
				playerState.CurrentToolState.AnimationRunning:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			elseif (playerState.CurrentToolState.AnimationWalking) then
				print("TEST ANIMATION 2")
				playerState.CurrentToolState.AnimationWalking:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			else
				print("TEST ANIMATION 3")
				playerState.CurrentToolState.AnimationMoving:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			end

			playerState.CurrentToolState.Playing = true
			playerState.CurrentToolState.Moving = true
		end
	elseif (toolAnimationType == playerState.ToolAnimationTypes.Using) then
		if (playerState.CurrentToolState.AnimationUsing ~= nil) then
			--playerState.CurrentToolState.AnimationUsing:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	

			local animationToPlay = playerState.CurrentToolState.AnimationUsing
			if (playerState.States.UsingToolAction == "UseTool2") then
				animationToPlay = playerState.CurrentToolState.AnimationUsing2
			end

			PlayToolAnimation(playerState.CurrentTool,animationToPlay,true,5,playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed,playerState.CurrentToolState.ToolFX,playerState.CurrentToolState.ToolFXRequiredItem)
			playerState.CurrentToolState.Playing = true
			playerState.CurrentToolState.Moving = false
		end
	elseif (toolAnimationType == playerState.ToolAnimationTypes.SwimmingIdle) then
		if (playerState.CurrentToolState.AnimationIdleSwimming ~= nil) then
			playerState.CurrentToolState.AnimationIdleSwimming:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			playerState.CurrentToolState.Playing = true
			playerState.CurrentToolState.Moving = false
		end
	elseif (toolAnimationType == playerState.ToolAnimationTypes.Swimming) then
		if (playerState.CurrentToolState.AnimationSwimming ~= nil) then
			playerState.CurrentToolState.AnimationSwimming:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
			playerState.CurrentToolState.Playing = true
			playerState.CurrentToolState.Moving = false
		end
	end
end

--function playerState.ChangeToolAnimation(moving,useTool)

--	--If we have not changed our moving state just leave
--	if ((useTool==nil) and (moving == playerState.CurrentToolState.Moving)) then
--		return
--	end

--	if (useTool) then
--		moving = false --stop movement when using tool --maybe not do this later if we need
--	end


--	if (playerState.CurrentToolState.Playing) then
--		playerState.CurrentToolState.Animation:Stop()
--		if (playerState.CurrentToolState.AnimationMoving ~= nil) then
--			playerState.CurrentToolState.AnimationMoving:Stop()
--		end

--		if (playerState.CurrentToolState.AnimationUsing ~= nil) then
--			playerState.CurrentToolState.AnimationUsing:Stop()
--		end

--		playerState.CurrentToolState.Playing = false
--	end


--	if (useTool and playerState.CurrentToolState.AnimationUsing) then
--		if (playerState.CurrentToolState.AnimationUsing ~= nil) then
--			playerState.CurrentToolState.AnimationUsing:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
--			playerState.CurrentToolState.Playing = true
--		end

--		return --if using tool we don't want to move into idle or moving animations
--	end

--	if (not moving) then
--		if (playerState.CurrentToolState.Animation ~= nil) then
--			playerState.CurrentToolState.Animation:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
--			playerState.CurrentToolState.Playing = true
--			playerState.CurrentToolState.Moving = false
--		end
--	else
--		if (playerState.CurrentToolState.AnimationMoving ~= nil) then
--			playerState.CurrentToolState.AnimationMoving:Play(playerState.CurrentToolState.AnimationFadeTime,playerState.CurrentToolState.AnimationWeight,playerState.CurrentToolState.AnimationSpeed)	
--			playerState.CurrentToolState.Playing = true
--			playerState.CurrentToolState.Moving = true
--		end
--	end
--end


DeferredAttackEvent.Event:Connect(function(player)

	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,playerState.CurrentTool)

	PlayerInputEvent:FireServer(playerState.DeferredKeyCode,playerState.DeferredHitPosition,ToolTransformedWorldCFrame)
	LocalPlayerInputEvent:Fire(playerState.DeferredKeyCode,playerState.DeferredHitPosition)

end)


return playerState

