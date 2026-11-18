local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterVFX = {}

local function attachModel(model: Model, rootPart: BasePart): boolean
	local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primaryPart then
		return false
	end
	model.PrimaryPart = primaryPart

	local alignmentAttachment = primaryPart:FindFirstChildOfClass("Attachment")
	local primaryToPivot = primaryPart.CFrame:ToObjectSpace(model:GetPivot())
	if alignmentAttachment then
		local targetPrimary = rootPart.CFrame * alignmentAttachment.CFrame:Inverse()
		model:PivotTo(targetPrimary * primaryToPivot)
	else
		model:PivotTo(rootPart.CFrame * primaryToPivot)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = "EffectRootWeld"
	weld.Part0 = primaryPart
	weld.Part1 = rootPart
	weld.Parent = primaryPart
	return true
end

function CharacterVFX.OnApply(context, behavior)
	local character = context.Player.Character
	local rootPart = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))
	if not rootPart or not rootPart:IsA("BasePart") then
		return nil
	end

	local vfxFolder = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("VFX")
	local template = vfxFolder:FindFirstChild(behavior.Template)
	if not template then
		warn("[EffectSystem] Missing CharacterVFX template", behavior.Template, "for", context.EffectName)
		return nil
	end

	local effect = template:Clone()
	effect.Name = behavior.InstanceName or behavior.Template
	if effect:IsA("Model") then
		effect.Parent = rootPart
		if not attachModel(effect, rootPart) then
			effect:Destroy()
			warn("[EffectSystem] CharacterVFX model has no BasePart", template:GetFullName())
			return nil
		end
	elseif effect:IsA("BasePart") then
		effect.CFrame = rootPart.CFrame
		effect.Parent = rootPart
		local weld = Instance.new("WeldConstraint")
		weld.Name = "EffectRootWeld"
		weld.Part0 = effect
		weld.Part1 = rootPart
		weld.Parent = effect
	else
		effect.Parent = rootPart
	end

	return effect
end

function CharacterVFX.OnRemove(_context, _behavior, state)
	if state and state.Parent then
		state:Destroy()
	end
end

return CharacterVFX
