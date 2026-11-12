--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--Remote Events
local Remotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local LedgeEvent = Remotes:WaitForChild("Ledge")

--Functions

--Definition Modules

--Assets

--Modules

--Gui

--Context and Actions

--Initialization

local functions = {}


functions.LedgeActions = {
	["Hang"]="Hang",
	["Climb"]="Climb",
	["Drop"]="Drop",
	["ShimmyRight"]="ShimmyRight",
	["ShimmyLeft"]="ShimmyLeft",
}

local ROOT_MOTION_ABS = {
	--frame 0
	--RM0 = {
	--	offset = Vector3.new(0,0,0), -- studs
	--	duration = .17,--0.1,                     -- seconds
	--	easingStyle = Enum.EasingStyle.Quad,
	--	easingDir = Enum.EasingDirection.Out,
	--},
	--frame 21
	RM0 = {
		offset = Vector3.new(-0.002, .5,-0.18), -- studs --y=1.069284439086914
		duration = .07, --0.53,     --.13                -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 37
	RM1 = {
		offset = Vector3.new(0, 3.026,-0.782), -- studs
		duration = .07,--0.27,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 45
	RM2 = {
		offset = Vector3.new(0.005, 3.784,-1.194), -- studs
		duration = .07,--0.27,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	----frame 53
	RM3 = {
		offset = Vector3.new(0.008, 4.216,-1.472), -- studs
		duration = .08,--0.3,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	----frame 62
	RM4 = {
		offset = Vector3.new(0.007, 4.737,-1.552), -- studs
		duration = .05,--0.27,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 70
	RM5 = {
		offset = Vector3.new(0.008, 5.5,-1.712), -- studs
		duration = .11,--0.4,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 82
	RM6 = {
		offset = Vector3.new(0.005, 6,-1.592), -- studs
		duration = .2,--0.84,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	----frame 107
	--RM7 = {
	--	offset = Vector3.new(0.014, 5.201,-1.987), -- studs
	--	duration = .14,--0.57,                     -- seconds
	--	easingStyle = Enum.EasingStyle.Quad,
	--	easingDir = Enum.EasingDirection.Out,
	--},
	RM7 = {
		offset = Vector3.new(0.014, 6,-1.592), -- studs
		duration = .14,--0.57,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 124
	RM8 = {
		offset = Vector3.new(0.014, 6,-2.5), -- studs
		duration = 0.14,                     -- seconds
		easingStyle = Enum.EasingStyle.Quad,
		easingDir = Enum.EasingDirection.Out,
	},
	--frame 136
}

local function offsetCFInWallBasis(startCF: CFrame, wallNormal: Vector3, offset: Vector3): CFrame
	local right = startCF.RightVector
	local up = Vector3.yAxis
	local towardWall = -Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit

	local worldDelta = right * offset.X + up * offset.Y + towardWall * offset.Z
	return startCF + worldDelta
end

local function playRootMotionFromMarkers(track: AnimationTrack, hrp: BasePart, ledgeData)
	local startCF = hrp.CFrame

	local initialStep = ROOT_MOTION_ABS["RM0"]
	local initialTargetCF = offsetCFInWallBasis(startCF, -ledgeData.wallNormal, initialStep.offset)

	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(
			initialStep.duration,
			initialStep.easingStyle or Enum.EasingStyle.Quad,
			initialStep.easingDir or Enum.EasingDirection.Out
		),
		{ CFrame = initialTargetCF }
	)

	tween:Play()

	for markerName, step in pairs(ROOT_MOTION_ABS) do
		track:GetMarkerReachedSignal(markerName):Connect(function()

			local targetCF = offsetCFInWallBasis(startCF, -ledgeData.wallNormal, step.offset)

			local tween = TweenService:Create(
				hrp,
				TweenInfo.new(
					step.duration,
					step.easingStyle or Enum.EasingStyle.Quad,
					step.easingDir or Enum.EasingDirection.Out
				),
				{ CFrame = targetCF }
			)

			tween:Play()
		end)
	end
end

function functions.Hang(character,ledgeData,ledgeCfg)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	--TODO SERVER SECURITY CHECKS
	
	-- Freeze (no ragdoll)
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.Jump = false

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.CanCollide = false
	hrp.Anchored = true

	-- Face away from wall
	local grabCF = ledgeData.grabCFrame
	local faceDir = Vector3.new(0, 0, -1)
	if ledgeData.wallHit and ledgeData.wallHit.Normal then
		faceDir = -ledgeData.wallHit.Normal
	end
	faceDir = Vector3.new(faceDir.X, 0, faceDir.Z).Unit

	-- 1) Base hang position (same logic you already had)
	local baseHangPos =
		grabCF.Position
		+ faceDir * ledgeCfg.HangBack
	- Vector3.new(0, ledgeCfg.HangDown, 0)

	-- 2) Get animated right-hand world position
	local handWorldPos =
		hrp.Root.Hips.Spine_01.Spine_02.Spine_03
		.Clavicle_R.Shoulder_R.Elbow_R.Hand_R
		.WorldCFrame.Position

	-- 3) Where the hand SHOULD be (slightly over the ledge lip)
	local desiredHandPos = grabCF.Position + faceDir * -0.15
	-- tweak -0.05 → -0.30 if needed

	-- 4) Offset HRP so the hand lines up
	local handDelta = Vector3.new(0,3.4,-2)
	local finalHangPos = baseHangPos - handDelta


	-- 5) Apply final placement (upright, stable)
	hrp.CFrame = CFrame.lookAt(finalHangPos, finalHangPos + faceDir, Vector3.yAxis)

end

function functions.Climb(player,character,ledgeData,ledgeCfg)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	-- Server authority
	pcall(function() hrp:SetNetworkOwner(nil) end)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	hrp.Anchored = true
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Server plays animation for marker timing
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
	local climbLedgeAnimation = Instance.new("Animation") 
	climbLedgeAnimation.AnimationId =  "rbxassetid://80318565917776"
	local track = animator:LoadAnimation(climbLedgeAnimation)

	-- Hook markers (server)
	playRootMotionFromMarkers(track, hrp, ledgeData)
	track:Play(0.0, 1.0, 1.0)
	
	-- Tell clients to play the same anim (optional but recommended)
	local serverStartTime = workspace:GetServerTimeNow()
	LedgeEvent:FireClient(player, "ClimbLedge", serverStartTime)

	

	track.Stopped:Once(function()
		hrp.Anchored = false
		hrp.CanCollide = true
		humanoid.AutoRotate = true

		--humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end)

end

function functions.Drop(character)
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	hrp.Anchored = false
	hrp.CanCollide = true

end

functions.MOVEMENT_THRESHOLD = 1.0 -- Any velocity above this counts as "moving"

function functions.IsMoving(character)
	if not character then return false, 0 end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false, 0 end

	local velocity = rootPart.AssemblyLinearVelocity.Magnitude
	local isMoving = velocity > functions.MOVEMENT_THRESHOLD

	return isMoving, velocity
end

function functions.IsPlayerMoving(player)
	if not player or not player.Character then return false, 0 end
	return functions.IsMoving(player.Character)
end

return functions
