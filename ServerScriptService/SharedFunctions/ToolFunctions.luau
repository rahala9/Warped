--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets
local Tools = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Tools")

--Modules
local Data = require(ServerScriptService.Data.Data)


local functions = {}



function functions.GetToolHandle(player,heldToolName)

	if (not itemsmodule[heldToolName]) then
		warn("ToolFunctions.GetToolHandle Item Not Found: playerName,itemName",player.Name,heldToolName)
		return
	end

	local modelName = itemsmodule[heldToolName].Model

	local newTool = itemsmodule[heldToolName].NewTool -- These are ones without bones

	local hand = itemsmodule[heldToolName].Hand
	if (hand == nil) then
		hand = "Right"
	end

	if (hand == "Left") then
		return player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"][modelName.."Handle"]
	elseif (hand == "Both") then
		return  player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"][modelName.."RightHandle"],player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"][modelName.."LeftHandle"]
	else
		if (newTool) then
			return  player.Character:FindFirstChild(modelName)[modelName.."Handle"]
		else
			return  player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"][modelName.."Handle"]
		end
		
	end

end

function functions.AddToolToHand(player,itemName,itemModel)

	--Handle container or non stackable unique custom ids
	local itemPieces = string.split(itemName,"_")
	itemName = itemPieces[1]
	
	if (not itemsmodule[itemName]) then
		warn("ToolFunctions.AddToolToHand Item Not Found: playerName,itemName",player.Name,itemName)
		return
	end

	if (itemName == "Fists") then
		--nothing to do
		return
	end

	local hand = itemsmodule[itemName].Hand
	if (hand == nil) then
		hand = "Right"
	end

	if (hand == "Left") then
		functions.AddToolToLeftHand(player,itemName)
	elseif (hand == "Both") then
		functions.AddToolToBothHands(player,itemName)
	else
		functions.AddToolToRightHand(player,itemName,itemModel)
	end
end

local function getRightHandPart(character: Model): BasePart?

	return character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]
end

local function ensureCarryGrip(hand: BasePart): Attachment
	local grip = hand:FindFirstChild("CarryGrip")
	if grip and grip:IsA("Attachment") then
		return grip
	end

	grip = Instance.new("Attachment")
	grip.Name = "CarryGrip"
	grip.Parent = hand

	-- Tune this offset to match your hold animation pose:
	-- forward/back (Z), up/down (Y), left/right (X)
	grip.CFrame = CFrame.new(0, -0.25, -0.8) * CFrame.Angles(0, math.rad(90), 0)

	return grip
end

local function isHumanoidOrInHumanoidModel(model: Model): boolean
	-- Direct humanoid in this model?
	if model:FindFirstChildOfClass("Humanoid") then
		return true
	end

	-- Some rigs put Humanoid in an ancestor model; check up the tree.
	local p = model.Parent
	while p do
		if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") then
			return true
		end
		p = p.Parent
	end

	return false
end

local function getModelParts(model: Model): {BasePart}
	local parts = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	return parts
end

local function waitUntilSettledThenAnchor(model: Model, opts)
	opts = opts or {}
	local CHECK_DT = opts.checkDt or 0.15
	local SPEED_EPS = opts.speedEps or 0.10         -- studs/sec
	local ANG_EPS   = opts.angularEps or 0.50       -- rad/sec-ish (AssemblyAngularVelocity magnitude)
	local REQUIRED_STABLE_TICKS = opts.stableTicks or 8
	local TIMEOUT = opts.timeout or 6.0

	-- Never anchor characters/NPCs/humanoids
	if isHumanoidOrInHumanoidModel(model) then
		return false
	end

	local parts = getModelParts(model)
	if #parts == 0 then
		return false
	end

	-- Prefer a root part to judge motion
	local root = model.PrimaryPart or parts[1]

	local stable = 0
	local start = os.clock()

	while model.Parent and (os.clock() - start) < TIMEOUT do
		-- If something anchored it already, stop
		if root.Anchored then
			return true
		end

		local v = root.AssemblyLinearVelocity.Magnitude
		local w = root.AssemblyAngularVelocity.Magnitude

		-- Optional: require it to be near ground-ish (raycast)
		-- (keeps you from anchoring mid-air if it somehow gets stuck)
		local nearGround = true
		if opts.requireGroundContact then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = {model}
			local origin = root.Position
			local result = workspace:Raycast(origin, Vector3.new(0, -6, 0), rp)
			nearGround = result ~= nil
		end

		if nearGround and v < SPEED_EPS and w < ANG_EPS then
			stable += 1
			if stable >= REQUIRED_STABLE_TICKS then
				
				--Don't anchore if already held again.
				if (model:GetAttribute("HeldBy")) then
					return true
				end
				
				-- Anchor everything
				for _, p in ipairs(parts) do
					-- Don't anchor parts that are inside a humanoid accidentally
					p.Anchored = true
					-- Optional: stop collisions too if you want it “sleepy”
					-- p.CanCollide = true -- usually keep true so it sits on ground normally
				end
				return true
			end
		else
			stable = 0
		end

		task.wait(CHECK_DT)
	end

	return false
end


local function setModelCarryPhysics(model: Model, carrying: boolean)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if carrying then
				d.Anchored = false
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				d.Massless = true
			else
				d.CanCollide = true
				d.CanTouch = true
				d.CanQuery = true
				d.Massless = false
				-- Keep unanchored at first so it can fall and settle
				-- We'll anchor later once settled (if eligible)
			end
		end
	end

	-- On drop: wait until settled then anchor (only if NOT humanoid)
	
	if not carrying and not isHumanoidOrInHumanoidModel(model) then
		task.spawn(function()
			waitUntilSettledThenAnchor(model, {
				checkDt = 0.15,
				speedEps = 0.12,
					angularEps = 0.75,
					stableTicks = 8,
				timeout = 6.0,
				requireGroundContact = false,
			})
		end)
	end
end


function functions.AddLiveObjectToRightHand(player, itemName, itemModel)
	if not player.Character then return end
	if not itemModel or not itemModel:IsA("Model") then return end

	-- Ensure PrimaryPart
	local item = itemModel.PrimaryPart or itemModel:FindFirstChild("HumanoidRootPart") or itemModel:FindFirstChildWhichIsA("BasePart")
	if not item then return end
	itemModel.PrimaryPart = item

	itemModel.Name = itemName

	---- Only do this behavior for your NPC model whose primary part is "Body"
	--if item.Name ~= "Body" then return end

	local hand = getRightHandPart(player.Character)
	if not hand then return end

	-- Stop any existing weld first (avoid duplicates)
	functions.RemoveLiveObjectFromRightHand(player, itemName, itemModel)

	itemModel:SetAttribute("HeldBy", player.Name)
	itemModel:SetAttribute("DroppedBy", nil)

	-- Make the held NPC not fight movement
	local heldHum = itemModel:FindFirstChildOfClass("Humanoid")
	if heldHum then
		heldHum.PlatformStand = true
		pcall(function()
			heldHum:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end

	setModelCarryPhysics(itemModel, true)

	-- Move it to the hand grip first (prevents snapping from HRP space)
	local grip = ensureCarryGrip(hand)
	item.CFrame = grip.WorldCFrame

	-- Weld to the HAND so it follows walk/hold animation
	local weld = Instance.new("RigidConstraint")
	weld.Name = "LiveObjectWeld"
	weld.Attachment0 = hand
	weld.Attachment1 = itemModel.PrimaryPart.HoldAttachment
	weld.Parent = hand

	-- Smooth replication: let the carrier simulate the held assembly
	pcall(function()
		item:SetNetworkOwner(player)
	end)
end

function functions.RemoveLiveObjectFromRightHand(player, itemName, itemModel)
	if not player.Character then return end
	if not itemModel or not itemModel:IsA("Model") then return end

	local item = itemModel.PrimaryPart or itemModel:FindFirstChild("HumanoidRootPart") or itemModel:FindFirstChildWhichIsA("BasePart")
	if not item then return end
	itemModel.PrimaryPart = item

	itemModel.Name = itemName

	-- Destroy weld
	local hand = getRightHandPart(player.Character)
	if hand then
		for _, child in ipairs(hand:GetChildren()) do
			if child:IsA("RigidConstraint") and child.Name == "LiveObjectWeld" then
				child:Destroy()
			end
		end
	end

	-- Restore attributes
	itemModel:SetAttribute("HeldBy", nil)
	itemModel:SetAttribute("DroppedBy", player.Name)

	-- Restore humanoid behavior
	local heldHum = itemModel:FindFirstChildOfClass("Humanoid")
	if heldHum then
		heldHum.PlatformStand = false
	end

	-- Restore physics (you can keep CanCollide=false if you want it ghostly on drop)
	setModelCarryPhysics(itemModel, false)

	-- Return ownership to server (optional)
	pcall(function()
		item:SetNetworkOwner(nil)
	end)
end


function functions.AddLiveObjectToHand(player,itemName,itemModel)
	if (not itemsmodule[itemName]) then
		warn("ToolFunctions.AddToolToHand Item Not Found: playerName,itemName",player.Name,itemName,itemsmodule)
		return
	end

	functions.AddLiveObjectToRightHand(player,itemName,itemModel)

end

function functions.RemoveLiveObjectFromHand(player,itemName,itemModel)
	if (not itemsmodule[itemName]) then
		warn("ToolFunctions.AddToolToHand Item Not Found: playerName,itemName",player.Name,itemName,itemsmodule)
		return
	end

	functions.RemoveLiveObjectFromRightHand(player,itemName,itemModel)

end

function RemoveCampBillboards(player)
	for index,item in ipairs(workspace:WaitForChild(player.Name.."_CampObjects"):GetDescendants()) do
		if ((item.Name =="ElectricNode") or (item:GetAttribute("PowerSource"))) then
			item.BoltBillboard.Enabled = false
		end
	end
end

function functions.RemoveToolFromHand(player,itemName)

	if (not itemsmodule[itemName]) then
		return
	end

	if (itemName == "Fists") then
		--nothing to do
		return
	end

	local hand = itemsmodule[itemName].Hand
	if (hand == nil) then
		hand = "Right"
	end

	if (hand == "Left") then
		functions.RemoveToolFromLeftHand(player,itemName)
	elseif (hand == "Both") then
		functions.RemoveToolFromBothHands(player,itemName)
	else
		functions.RemoveToolFromRightHand(player,itemName)
	end

end

function functions.AddToolModelToRightHand(player,itemName,rightHandItem)

	local modelName = itemsmodule[itemName].Model

	local item = rightHandItem.PrimaryPart
	rightHandItem.Name = modelName
	item.CanCollide = false

	--local position = Vector3.new(player.Character.HumanoidRootPart.CFrame.Position.X,player.Character.HumanoidRootPart.CFrame.Position.Y+1.6,player.Character.HumanoidRootPart.CFrame.Position.Z-5)
	--item.Position = position

	item.CFrame = player.Character.HumanoidRootPart.CFrame:ToWorldSpace(CFrame.new(0, 3, -2))


	local weldToRightHand = Instance.new("WeldConstraint")
	weldToRightHand.Name = "WeldToRightHand"
	weldToRightHand.Part0,weldToRightHand.Part1 = player.Character.HumanoidRootPart,item
	weldToRightHand.Parent = item	

	item.Parent = player.Character


	local openModule = item:FindFirstChild(rightHandItem.Name.."Open")

	if (openModule) then
		require(openModule).Open(player)
	end

	--Attach Bone
	item[rightHandItem.Name.."Handle"].Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

	for _,v in ipairs(rightHandItem:GetChildren()) do
		if (not v:IsA("MeshPart")) then
			continue
		end
		if (v.Name ~= modelName) then
			local weld = Instance.new("WeldConstraint")
			weld.Name = v.Name.."Weld"
			weld.Part0,weld.Part1 = player.Character.HumanoidRootPart,v
			weld.Parent = v

			v.Parent = item

			--Handles case of Marshmellow on end of marshmellow stick for example
			local bone = v:FindFirstChildOfClass("Bone")
			if (bone) then
				bone.Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"][rightHandItem.Name.."Handle"]
			end

		end
	end

	rightHandItem:Destroy()

end

function functions.AddNewToolToRightHand(player,itemName,rightHandItem)


	local rightHand = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

	rightHandItem.CanCollide = false
	rightHandItem.Parent = player.Character

	local weldToRightHand = Instance.new("RigidConstraint")
	weldToRightHand.Name = "WeldToRightHand"
	weldToRightHand.Attachment0,weldToRightHand.Attachment1 = rightHandItem[itemName.."Handle"],rightHand
	weldToRightHand.Parent = rightHandItem		

end

function functions.AddToolToRightHand(player,itemName,itemModel)

	local modelName = itemsmodule[itemName].Model

	local rightHandItem

	if (itemModel) then
		rightHandItem = itemModel
	else
		local rightHandItemSource = Tools:FindFirstChild(modelName)

		if (not rightHandItemSource) then
			warn("ToolFunctions.AddToolToRightHand rightHandItemSource not found: playerName,itemName:",player.Name,modelName)
			return
		end

		rightHandItem = rightHandItemSource:Clone()

	end

	if (rightHandItem:IsA("Model")) then
		functions.AddToolModelToRightHand(player,itemName,rightHandItem)
		return
	elseif (rightHandItem:GetAttribute("NewTool") == true) then
		functions.AddNewToolToRightHand(player,itemName,rightHandItem)
		return
	end

	rightHandItem.CanCollide = false
	rightHandItem.Parent = player.Character


	local position = Vector3.new(player.Character.HumanoidRootPart.CFrame.Position.X,player.Character.HumanoidRootPart.CFrame.Position.Y+1.6,player.Character.HumanoidRootPart.CFrame.Position.Z)

	rightHandItem.Position = position

	local weldToRightHand = Instance.new("WeldConstraint")
	weldToRightHand.Name = "WeldToRightHand"
	weldToRightHand.Part0,weldToRightHand.Part1 = player.Character.HumanoidRootPart,rightHandItem
	weldToRightHand.Parent = rightHandItem

	rightHandItem[rightHandItem.Name.."Handle"].Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

end

function functions.RemoveToolFromRightHand(player,itemName)

	if (not itemName) then
		return
	end

	local modelName = itemsmodule[itemName].Model

	if (not player.Character:FindFirstChild(modelName)) then
		return
	end

	local toolHandle = functions.GetToolHandle(player,itemName)
	if (toolHandle) then
		toolHandle:Destroy()
	end

	player.Character[modelName]:Destroy()
end

function functions.RemoveArtifact(player,itemName)
	local item = player.Character:FindFirstChild(itemName)
	if (item) then
		item:Destroy() --Maybe change from clone and destroy to transparency and cannot collide
	end
end

function functions.HandleElectricasm(item)
	spawn(function()

		local animator = item:WaitForChild("AnimationController"):WaitForChild("Animator")
		local animation = Instance.new("Animation")
		animation.AnimationId = "http://www.roblox.com/asset/?id=12249335035"
		local electricasmOpenTrack = animator:LoadAnimation(animation)

		electricasmOpenTrack:Play()
		electricasmOpenTrack.Stopped:Wait()

		task.wait(1)

		item.c1.Color = Color3.new(1, 1, 1)
		item.c1.Material = Enum.Material.Neon

		task.wait(5)

		item.c1.Color = Color3.new(0.258824, 0.258824, 0.258824)
		item.c1.Material = Enum.Material.Plastic
	end)
end

function functions.HandleJacksLantern(item)
	spawn(function()

		item.a1.Material = Enum.Material.Plastic

		task.wait(1)

		item.a1.Material = Enum.Material.Neon
	end)
end

function functions.AddArtifact(player,itemName)

	local modelName = itemsmodule[itemName].Model


	local itemSource = Tools:FindFirstChild(modelName)

	if (not itemSource) then
		warn("ToolFunctions.AddArtifact itemSource not found: playerName,itemName:",player.Name,modelName)
		return
	end

	local item = itemSource:Clone()

	item.PrimaryPart.CanCollide = false
	item.Parent = player.Character


	--local position = Vector3.new(player.Character.HumanoidRootPart.CFrame.Position.X-2,player.Character.HumanoidRootPart.CFrame.Position.Y+1.6,player.Character.HumanoidRootPart.CFrame.Position.Z)
	local rightVector = player.Character.HumanoidRootPart.CFrame.RightVector
	local newPosition = player.Character.HumanoidRootPart.Position + (rightVector * 2) -- Calculate new position
	newPosition = newPosition + Vector3.new(0, 3, 0)

	item:SetPrimaryPartCFrame(CFrame.new(newPosition))

	local weldToArtifact = Instance.new("WeldConstraint")
	weldToArtifact.Name = "WeldToArtifact"
	weldToArtifact.Part0,weldToArtifact.Part1 = player.Character.HumanoidRootPart,item.a1
	weldToArtifact.Parent = item

	if (modelName == "Electricasm") then
		functions.HandleElectricasm(item)
	elseif (modelName == "JacksLantern") then
		functions.HandleJacksLantern(item)
	end

end

function functions.AddToolToLeftHand(player,itemName)

	local modelName = itemsmodule[itemName].Model


	local leftHandItemSource = Tools:FindFirstChild(modelName)

	if (not leftHandItemSource) then
		warn("ToolFunctions.AddToolToLeftHand rightHandItemSource not found: playerName,itemName:",player.Name,modelName)
		return
	end

	local leftHandItem = leftHandItemSource:Clone()

	if (leftHandItem:IsA("Model")) then
		functions.AddToolModelToLeftHand(player,itemName,leftHandItem)
		return
	end

	leftHandItem.CanCollide = false
	leftHandItem.Parent = player.Character


	local position = Vector3.new(player.Character.HumanoidRootPart.CFrame.Position.X,player.Character.HumanoidRootPart.CFrame.Position.Y+1.6,player.Character.HumanoidRootPart.CFrame.Position.Z)

	leftHandItem.Position = position

	local weldToLeftHand = Instance.new("WeldConstraint")
	weldToLeftHand.Name = "WeldToLeftHand"
	weldToLeftHand.Part0,weldToLeftHand.Part1 = player.Character.HumanoidRootPart,leftHandItem
	weldToLeftHand.Parent = leftHandItem

	leftHandItem[leftHandItem.Name.."Handle"].Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"]

end

function functions.RemoveToolFromLeftHand(player,itemName)

	local modelName = itemsmodule[itemName].Model

	if (not player.Character:FindFirstChild(modelName)) then
		return
	end

	functions.GetToolHandle(player,itemName):Destroy()
	player.Character[modelName]:Destroy()
end

function functions.AddToolToBothHands(player,itemName)

	local modelName = itemsmodule[itemName].Model

	local handItemSource = Tools:WaitForChild(modelName)
	local rightHandItemSource = handItemSource:FindFirstChild(modelName.."Right")
	local leftHandItemSource = handItemSource:FindFirstChild(modelName.."Left")

	if (rightHandItemSource == nil) then
		warn("ToolFunctions.AddToolToolToBothHands rightHandItemSource not found: playerName,itemName:",player.Name,modelName)
		return
	end

	if (leftHandItemSource == nil) then
		warn("ToolFunctions.AddToolToolToBothHands leftHandItemSource not found: playerName,itemName:",player.Name,modelName)
		return
	end	

	local rightHandItem = rightHandItemSource:Clone()
	rightHandItem.CanCollide = false
	rightHandItem.Parent = player.Character

	local leftHandItem = leftHandItemSource:Clone()
	leftHandItem.CanCollide = false
	leftHandItem.Parent = player.Character


	local position = Vector3.new(player.Character.HumanoidRootPart.CFrame.Position.X,player.Character.HumanoidRootPart.CFrame.Position.Y,player.Character.HumanoidRootPart.CFrame.Position.Z)
	rightHandItem.Position = position
	leftHandItem.Position = position

	local weldToRightHand = Instance.new("WeldConstraint")
	weldToRightHand.Name = "WeldToRightHand"
	weldToRightHand.Part0,weldToRightHand.Part1 = player.Character.HumanoidRootPart,rightHandItem
	weldToRightHand.Parent = rightHandItem

	rightHandItem[rightHandItem.Name.."Handle"].Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

	local weldToLeftHand = Instance.new("WeldConstraint")
	weldToLeftHand.Name = "WeldToLeftHand"
	weldToLeftHand.Part0,weldToLeftHand.Part1 = player.Character.HumanoidRootPart,leftHandItem
	weldToLeftHand.Parent = leftHandItem

	leftHandItem[leftHandItem.Name.."Handle"].Parent = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"]

end

function functions.RemoveToolFromBothHands(player,itemName)

	local modelName = itemsmodule[itemName].Model

	if (not player.Character:FindFirstChild(modelName.."Right")) then
		return
	end

	if (not player.Character:FindFirstChild(modelName.."Left")) then
		return
	end

	local right,left = functions.GetToolHandle(player,itemName)
	right:Destroy()
	left:Destroy()
	player.Character[modelName.."Right"]:Destroy()
	player.Character[modelName.."Left"]:Destroy()
end


return functions
