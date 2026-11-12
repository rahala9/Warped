local Players = game:GetService("Players")

----------------------------------------------------------------------
-- Create a HeadSocket that follows the Neck bone via RigidConstraint
----------------------------------------------------------------------
local ALLOWED_ACCESSORY_TYPES = {
	[Enum.AccessoryType.Hat]  = true, -- “head”
	[Enum.AccessoryType.Hair] = true, -- “head”
	[Enum.AccessoryType.Face] = true, -- “head”
	[Enum.AccessoryType.Neck] = true, -- neck
	[Enum.AccessoryType.Back] = true, -- back
}

local function createHeadSocket(character: Model): BasePart
	local hrp = character:WaitForChild("HumanoidRootPart")

	-- Bone chain: Root -> Hips -> Spine_01 -> Spine_02 -> Spine_03 -> Neck
	local rootBone   = hrp:WaitForChild("Root") :: Bone
	local hipsBone   = rootBone:WaitForChild("Hips") :: Bone
	local spine1Bone = hipsBone:WaitForChild("Spine_01") :: Bone
	local spine2Bone = spine1Bone:WaitForChild("Spine_02") :: Bone
	local spine3Bone = spine2Bone:WaitForChild("Spine_03") :: Bone
	local neckBone   = spine3Bone:WaitForChild("Neck") :: Bone

	-- Synty head part (used to get correct offset from neck)
	local headPart = character:WaitForChild("head") :: BasePart

	-- Invisible helper part that will follow the neck / head
	local headSocket = Instance.new("Part")
	headSocket.Name = "HeadSocket"
	headSocket.Size = Vector3.new(0.2, 0.2, 0.2)
	headSocket.Transparency = 1
	headSocket.CanCollide = false
	headSocket.Anchored = false
	headSocket.Massless = true
	headSocket.Parent = character

	-- Start the socket where the Synty head is
	headSocket.CFrame = headPart.CFrame

	-- Attachment on the bone
	local boneAttachment = Instance.new("Attachment")
	boneAttachment.Name = "HeadSocketBoneAttachment"
	boneAttachment.Parent = neckBone

	-- Attachment on the socket part
	local socketAttachment = Instance.new("Attachment")
	socketAttachment.Name = "HeadSocketAttachment"
	socketAttachment.Parent = headSocket

	-- Offset so the socket sits where the Synty head is, relative to the neck
	boneAttachment.CFrame = neckBone.WorldCFrame:ToObjectSpace(headPart.CFrame)
	socketAttachment.CFrame = CFrame.new()

	-- RigidConstraint tying socket to neck bone
	local rigid = Instance.new("RigidConstraint")
	rigid.Name = "HeadSocketConstraint"
	rigid.Attachment0 = boneAttachment
	rigid.Attachment1 = socketAttachment
	rigid.Parent = headSocket

	return headSocket
end

----------------------------------------------------------------------
-- Move accessories from temp R15 rig to Synty rig, preserving offsets
-- relative to the original avatar head.
----------------------------------------------------------------------

local function moveAccessoriesToHead(
	tempRig: Model,
	syntyChar: Model,
	headSocket: BasePart,
	tempHeadCFrame: CFrame,
	newAvatarHead: BasePart
)
	local accessoryClones = {}
	
	for _, child in ipairs(tempRig:GetChildren()) do
		if child:IsA("Accessory") then
			if ALLOWED_ACCESSORY_TYPES[child.AccessoryType] then
				table.insert(accessoryClones, child:Clone())
			else
				-- optional debug:
				-- print("Skipping accessory of type", child.AccessoryType, child.Name)
			end
		end
	end

	for _, acc in ipairs(accessoryClones) do
		local handle = acc:FindFirstChild("Handle")
		if not (handle and handle:IsA("BasePart")) then
			warn("Accessory missing Handle:", acc.Name)
			acc:Destroy()
			continue
		end

		----------------------------------------------------------------
		-- Key change:
		-- 1. Take handle offset relative to the OLD avatar head
		-- 2. Rebuild that offset from the NEW AvatarHead on the Synty rig
		----------------------------------------------------------------
		local relToHead = tempHeadCFrame:ToObjectSpace(handle.CFrame)

		handle.Parent = syntyChar
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true
		handle.Name = acc.Name .. "_Mesh"

		-- World-space position based on new head
		handle.CFrame = newAvatarHead.CFrame * relToHead

		-- Weld to the socket that follows the neck bone
		local weld = Instance.new("WeldConstraint")
		weld.Name = "Weld_" .. handle.Name
		weld.Part0 = headSocket
		weld.Part1 = handle
		weld.Parent = headSocket

		acc:Destroy()
	end
end

----------------------------------------------------------------------
-- Attach player AvatarHead (and accessories) to the Synty rig
----------------------------------------------------------------------

local function attachPlayerHead(syntyChar: Model, player: Player)
	-- Small delay to ensure bones/parts are fully replicated
	task.wait(1)

	local humanoid = syntyChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("No Humanoid on Synty character")
		return
	end

	local headPart = syntyChar:FindFirstChild("head")
	local facePart = syntyChar:FindFirstChild("face")
	if not headPart or not facePart or not headPart:IsA("BasePart") or not facePart:IsA("BasePart") then
		warn("Synty head/face parts missing on character:", syntyChar.Name)
		return
	end

	-- Create the socket that follows the Neck bone
	local headSocket = createHeadSocket(syntyChar)

	-- Remove any baked face texture
	local faceTexture = facePart:FindFirstChild("faceTexture")
	if faceTexture then
		faceTexture:Destroy()
	end

	-- Hide Synty head mesh; we use AvatarHead instead
	headPart.Transparency = 1
	facePart.Transparency = 1

	-- Build a temp R15 from the player's description
	local desc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
	local tempRig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	tempRig.Parent = workspace
	tempRig.Name = player.Name .. "_TempAvatar"

	local tempHead = tempRig:FindFirstChild("Head")
	if not tempHead or not tempHead:IsA("BasePart") then
		warn("Temp avatar has no Head")
		tempRig:Destroy()
		return
	end

	-- Capture original head CFrame for accessory offsets
	local tempHeadCFrame = tempHead.CFrame

	-- Strip face controls / old joints from the avatar head
	for _, child in ipairs(tempHead:GetChildren()) do
		if child:IsA("FaceControls") then
			child:Destroy()
		elseif child:IsA("JointInstance") or child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end

	-- Move AvatarHead into the Synty rig
	tempHead.Anchored = false
	tempHead.CanCollide = false
	tempHead.Massless = true
	tempHead.Parent = syntyChar
	tempHead.Name = "AvatarHead"

	-- Put avatar head where the original Synty head was
	tempHead.CFrame = headPart.CFrame

	-- Weld AvatarHead to the headSocket (which follows the Neck bone)
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Name = "Weld_AvatarHead"
	headWeld.Part0 = headSocket
	headWeld.Part1 = tempHead
	headWeld.Parent = headSocket

	-- Move accessories over and weld them to the same socket,
	-- preserving their offsets relative to the original head.
	moveAccessoriesToHead(tempRig, syntyChar, headSocket, tempHeadCFrame, tempHead)

	-- Cleanup temp rig
	tempRig:Destroy()
end

----------------------------------------------------------------------
-- Hook into player / character spawning
----------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		attachPlayerHead(character, player)
	end)
end)
