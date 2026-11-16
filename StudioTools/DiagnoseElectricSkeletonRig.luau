-- Read-only diagnostic for the electric skeleton rig.
-- Run from Studio's Command Bar while Play is active and the effect is visible.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function relativePath(root: Instance, instance: Instance): string
	if instance == root then return root.Name end
	local names = {}
	local current = instance
	while current and current ~= root do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end
	return root.Name .. "." .. table.concat(names, ".")
end

local function isAnimatedTransform(transform: CFrame): boolean
	local _, angle = transform:ToAxisAngle()
	return transform.Position.Magnitude > 0.0001 or math.abs(angle) > 0.0001
end

local function inspect(root: Instance, label: string)
	local counts = {
		BasePart = 0,
		Bone = 0,
		Attachment = 0,
		RigidConstraint = 0,
		WeldConstraint = 0,
		AnimatedBones = 0,
	}
	local constraints = {}
	local keyAttachments = {}

	local instances = { root }
	for _, descendant in ipairs(root:GetDescendants()) do
		table.insert(instances, descendant)
	end

	for _, instance in ipairs(instances) do
		if instance:IsA("BasePart") then
			counts.BasePart += 1
		elseif instance:IsA("Bone") then
			counts.Bone += 1
			if isAnimatedTransform(instance.Transform) then
				counts.AnimatedBones += 1
			end
		elseif instance:IsA("Attachment") then
			counts.Attachment += 1
			if instance.Name == "HipOffset" or instance.Name == "mixamorig:Hips" then
				table.insert(keyAttachments, (`{relativePath(root, instance)} [{instance.ClassName}]`))
			end
		elseif instance:IsA("RigidConstraint") then
			counts.RigidConstraint += 1
			table.insert(constraints, {
				path = relativePath(root, instance),
				attachment0 = instance.Attachment0 and instance.Attachment0:GetFullName() or "nil",
				attachment1 = instance.Attachment1 and instance.Attachment1:GetFullName() or "nil",
			})
		elseif instance:IsA("WeldConstraint") then
			counts.WeldConstraint += 1
		end
	end

	print(("[ElectricSkeletonDiagnostic] %s root=%s class=%s parent=%s"):format(
		label,
		root:GetFullName(),
		root.ClassName,
		root.Parent and root.Parent:GetFullName() or "nil"
	))
	print(("[ElectricSkeletonDiagnostic] %s parts=%d bones=%d animatedBones=%d attachments=%d rigidConstraints=%d weldConstraints=%d"):format(
		label,
		counts.BasePart,
		counts.Bone,
		counts.AnimatedBones,
		counts.Attachment,
		counts.RigidConstraint,
		counts.WeldConstraint
	))
	for _, attachment in ipairs(keyAttachments) do
		print("[ElectricSkeletonDiagnostic]", label, "key attachment", attachment)
	end
	for _, constraint in ipairs(constraints) do
		print(
			"[ElectricSkeletonDiagnostic]",
			label,
			constraint.path,
			"Attachment0=",
			constraint.attachment0,
			"Attachment1=",
			constraint.attachment1
		)
	end
end

local sharedAssets = ReplicatedStorage:FindFirstChild("SharedClientAssets")
local asset = sharedAssets and sharedAssets:FindFirstChild("Skeleton")
assert(asset, "ReplicatedStorage.SharedClientAssets.Skeleton was not found")
inspect(asset, "ASSET")

local player = Players.LocalPlayer or Players:GetPlayers()[1]
local character = player and player.Character
if not character then
	warn("[ElectricSkeletonDiagnostic] No live character. Run this during Play.")
	return
end
inspect(character, "CHARACTER")

local liveSkeleton = character:FindFirstChild("Skeleton")
if liveSkeleton then
	inspect(liveSkeleton, "LIVE_SKELETON")
else
	warn("[ElectricSkeletonDiagnostic] No direct Character.Skeleton clone is active")
end
