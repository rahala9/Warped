local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)

local GetState = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("GetState")
local ActionEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Action")
local DisplayHUDEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("DisplayHUD")

local PUSH_DISTANCE_TAKE = 6
local PUSH_DISTANCE_ACTIVE = 15
local PUSH_ACCEL_PER_STRENGTH = 0.5
local PUSH_STRENGTH = 100
local PUSH_MAX_ACCEL = 50

local function getPushRoot(instance)
	if not instance then return nil end

	-- If you later move to models, this can be expanded.
	if instance:IsA("BasePart") then
		return instance
	end

	if instance:IsA("Model") then
		return instance.PrimaryPart
	end

	local ancestorPart = instance:FindFirstAncestorWhichIsA("BasePart")
	if ancestorPart then
		return ancestorPart
	end

	local ancestorModel = instance:FindFirstAncestorWhichIsA("Model")
	if ancestorModel and ancestorModel.PrimaryPart then
		return ancestorModel.PrimaryPart
	end

	return nil
end

local function ensurePushForce(box)
	local attachment = box:FindFirstChild("PushAttachment")
	if not attachment or not attachment:IsA("Attachment") then
		attachment = Instance.new("Attachment")
		attachment.Name = "PushAttachment"
		attachment.Parent = box
	end

	local vf = box:FindFirstChild("PushVectorForce")
	if not vf or not vf:IsA("VectorForce") then
		vf = Instance.new("VectorForce")
		vf.Name = "PushVectorForce"
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		vf.ApplyAtCenterOfMass = true
		vf.Attachment0 = attachment
		vf.Enabled = false
		vf.Parent = box
	else
		if vf.Attachment0 ~= attachment then
			vf.Attachment0 = attachment
		end
		vf.RelativeTo = Enum.ActuatorRelativeTo.World
		vf.ApplyAtCenterOfMass = true
	end

	return vf
end

local function stopPush(box, anchorOnStop)
	if not box or not box:IsA("BasePart") then
		return
	end

	local vf = box:FindFirstChild("PushVectorForce")
	if vf and vf:IsA("VectorForce") then
		vf.Force = Vector3.zero
		vf.Enabled = false
		Debris:AddItem(vf, 0.1) -- Cleanup after 0.1s
	end

	box.AssemblyLinearVelocity = Vector3.zero
	box.AssemblyAngularVelocity = Vector3.zero

	-- Only call SetNetworkOwner while unanchored
	if not box.Anchored then
		box:SetNetworkOwner(nil)
	end

	if anchorOnStop then
		box.Anchored = true
	end
end

ActionEvent.OnServerEvent:Connect(function(player, action, arg, arg2)
	if action == "GatherWater" then
		local newContainerItem = {}
		newContainerItem.Name = "Water"
		newContainerItem.Amount = 1
		InventoryFunctions.AddItemToOverflowContainer(player, "Water", "Water", 1, newContainerItem)

	elseif action == "UnderWater" then
		StatesFunctions.SetUnderWater(player, arg)

	elseif action == "InWater" then
		StatesFunctions.SetInWater(player, arg)

	elseif action == "TakeOwnership" then
		local box = getPushRoot(arg)
		if not box or not box:GetAttribute("Pushable") then
			return
		end

		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - box.Position).Magnitude
		if dist > PUSH_DISTANCE_TAKE then
			return
		end

		box.Anchored = false
		box:SetNetworkOwner(player)

		ensurePushForce(box)

	elseif action == "ReleaseOwnership" then
		local box = getPushRoot(arg)
		if not box then
			return
		end

		stopPush(box, true)

	elseif action == "PushObject" then
		local box = getPushRoot(arg)
		if not box or not box:GetAttribute("Pushable") then
			return
		end

		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - box.Position).Magnitude
		if dist > PUSH_DISTANCE_ACTIVE then
			stopPush(box, false)
			return
		end

		if typeof(arg2) ~= "Vector3" then
			stopPush(box, false)
			return
		end
		
		if box.Anchored then
			box.Anchored = false
		end
		
		box:SetNetworkOwner(player)

		local vf = ensurePushForce(box)

		local dir = Vector3.new(arg2.X, 0, arg2.Z)
		if dir.Magnitude < 1e-3 then
			stopPush(box, false)
			return
		end

		dir = dir.Unit

		local desiredAccel = math.clamp(PUSH_STRENGTH * PUSH_ACCEL_PER_STRENGTH, 0, PUSH_MAX_ACCEL)
		vf.Force = dir * (box.AssemblyMass * desiredAccel)
		vf.Enabled = true

	elseif action == "StopPushObject" then
		local box = getPushRoot(arg)
		if not box then
			return
		end

		stopPush(box, true)
	end
end)

GetState.OnServerInvoke = function(player)
	return StatesFunctions.GetState(player)
end

DisplayHUDEvent.OnServerEvent:Connect(function(player, command)
	if command == "DisplayHUD" then
		DisplayHUDEvent:FireClient(player, player, "PlayOnce")
	elseif command == "StopDisplayHUD" then
		DisplayHUDEvent:FireClient(player, player, "Stop")
	end
end)