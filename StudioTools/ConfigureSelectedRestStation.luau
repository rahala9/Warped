-- Run from Studio's Command Bar or as a local plugin action.
-- Select one or more Models/BaseParts, set DEFINITION, then run.
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local DEFINITION = "Chair"
local TAG = "RestStation"

local function firstBasePart(root)
	if root:IsA("BasePart") then return root end
	if root:IsA("Model") then
		return root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function ensureAttachment(parent, name, position)
	local attachment = parent:FindFirstChild(name)
	if attachment and not attachment:IsA("Attachment") then
		attachment:Destroy()
		attachment = nil
	end
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.Position = position
		attachment.Parent = parent
	end
	return attachment
end

local function legacyWorldCFrame(root, name)
	for _, descendant in ipairs(root:GetDescendants()) do
		if string.lower(descendant.Name) == string.lower(name) then
			if descendant:IsA("Attachment") then return descendant.WorldCFrame end
			if descendant:IsA("BasePart") then return descendant.CFrame end
		end
	end
	return nil
end

local changed = 0
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Model") or selected:IsA("BasePart") then
		local host = firstBasePart(selected)
		if host then
			local legacyEnter = legacyWorldCFrame(selected, "enter")
			local legacyExit = legacyWorldCFrame(selected, "exit")
			selected:SetAttribute("RestDefinition", DEFINITION)
			selected:SetAttribute("RestEnabled", true)
			CollectionService:AddTag(selected, TAG)

			local restPoint = ensureAttachment(host, "RestPoint", Vector3.new(0, 2.5, 0))
			local exitPoint = ensureAttachment(host, "ExitPoint", Vector3.new(0, 2.5, -3))
			if legacyEnter then restPoint.CFrame = host.CFrame:ToObjectSpace(legacyEnter) end
			if legacyExit then exitPoint.CFrame = host.CFrame:ToObjectSpace(legacyExit) end

			local prompt = restPoint:FindFirstChild("RestPrompt")
			if prompt and not prompt:IsA("ProximityPrompt") then
				prompt:Destroy()
				prompt = nil
			end
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Name = "RestPrompt"
				prompt.Parent = restPoint
			end
			prompt.ActionText = "Sit"
			prompt.ObjectText = selected.Name
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 10

			-- Old Camp-format prompts would otherwise remain visible but have no
			-- listener after migration.
			for _, descendant in ipairs(selected:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") and descendant ~= prompt
					and (descendant.Name == "Sit" or descendant.Name == "Sleep") then
					descendant.Enabled = false
				end
			end
			changed += 1
		else
			warn("Rest setup skipped; no BasePart in", selected:GetFullName())
		end
	end
end

print(string.format("RestSystem configured %d station(s) as %s. Move RestPoint and ExitPoint as needed.", changed, DEFINITION))
