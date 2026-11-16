-- Warped: add randomized Spark3 through Spark8 audio to an existing cable
-- spark effect without changing particles, lights, or hazard zones.
--
-- Usage in Studio Edit mode:
--   1. Select each Attachment containing CableElectricController.
--   2. Paste/run this entire file in View > Command Bar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local electricSounds = ReplicatedStorage
	:WaitForChild("SharedClientAssets")
	:WaitForChild("Sounds")
	:WaitForChild("Electric")
local sparkSoundSources = {}
for index = 3, 8 do
	local source = electricSounds:WaitForChild("Spark" .. tostring(index))
	assert(source:IsA("Sound"), ("SharedClientAssets.Sounds.Electric.Spark%d must be a Sound"):format(index))
	table.insert(sparkSoundSources, source)
end

local DECLARATIONS = [=[local random = Random.new()
local sparkSounds = {
	attachment:WaitForChild("CableElectricSpark3"),
	attachment:WaitForChild("CableElectricSpark4"),
	attachment:WaitForChild("CableElectricSpark5"),
	attachment:WaitForChild("CableElectricSpark6"),
	attachment:WaitForChild("CableElectricSpark7"),
	attachment:WaitForChild("CableElectricSpark8"),
}

local function playSparkSound()
	for _, sound in ipairs(sparkSounds) do
		sound:Stop()
	end
	sparkSounds[random:NextInteger(1, #sparkSounds)]:Play()
end]=]

local OLD_TWO_SOUND_DECLARATIONS = [=[local random = Random.new()
local sparkSounds = {
	attachment:WaitForChild("CableElectricSpark2"),
	attachment:WaitForChild("CableElectricSpark3"),
}

local function playSparkSound()
	for _, sound in ipairs(sparkSounds) do
		sound:Stop()
	end
	sparkSounds[random:NextInteger(1, #sparkSounds)]:Play()
end]=]

local function replaceOnce(source: string, old: string, new: string): string
	local first, last = string.find(source, old, 1, true)
	assert(first and last, "CableElectricController source did not match the expected working version")
	return string.sub(source, 1, first - 1) .. new .. string.sub(source, last + 1)
end

local selectedAttachments = {}
for _, selected in ipairs(Selection:Get()) do
	if selected:IsA("Attachment") then
		table.insert(selectedAttachments, selected)
	end
end
assert(#selectedAttachments > 0, "Select at least one cable spark Attachment")

for _, attachment in ipairs(selectedAttachments) do
	local controller = attachment:FindFirstChild("CableElectricController")
	assert(controller and controller:IsA("Script"), attachment:GetFullName() .. " has no CableElectricController Script")

	local source = controller.Source
	if string.find(source, 'local sparkSound = attachment:WaitForChild("CableElectricSparkSound")', 1, true) then
		-- Migrate the original Spark3-only patch.
		source = replaceOnce(
			source,
			'local sparkSound = attachment:WaitForChild("CableElectricSparkSound")\nlocal random = Random.new()',
			DECLARATIONS
		)
		source = replaceOnce(source, '\tsparkSound:Stop()\n\tsparkSound:Play()', '\tplaySparkSound()')
		source = replaceOnce(source, '\t\tsparkSound:Stop()\n\t\tsparkSound:Play()', '\t\tplaySparkSound()')
	elseif string.find(source, "CableElectricSpark2", 1, true) then
		-- Migrate the Spark2/Spark3 version.
		source = replaceOnce(source, OLD_TWO_SOUND_DECLARATIONS, DECLARATIONS)
	elseif not string.find(source, "CableElectricSpark8", 1, true) then
		-- Patch the original silent controller.
		source = replaceOnce(source, "local random = Random.new()", DECLARATIONS)
		source = replaceOnce(
			source,
			'\tglow:Emit(math.max(1, math.floor(burstCount * 0.35)))\n\n\tlight.Brightness',
			'\tglow:Emit(math.max(1, math.floor(burstCount * 0.35)))\n\tplaySparkSound()\n\n\tlight.Brightness'
		)
		source = replaceOnce(
			source,
			'\t\tsparks:Emit(random:NextInteger(4, 8))\n\t\tlight.Brightness',
			'\t\tsparks:Emit(random:NextInteger(4, 8))\n\t\tplaySparkSound()\n\t\tlight.Brightness'
		)
	end

	-- Only mutate the Attachment after every controller edit has succeeded.
	for index = 2, 8 do
		local oldSound = attachment:FindFirstChild("CableElectricSpark" .. tostring(index))
		if oldSound then
			oldSound:Destroy()
		end
	end
	local legacySound = attachment:FindFirstChild("CableElectricSparkSound")
	if legacySound then
		legacySound:Destroy()
	end
	for index, sourceSound in ipairs(sparkSoundSources) do
		local sound = sourceSound:Clone()
		sound.Name = "CableElectricSpark" .. tostring(index + 2)
		sound.Looped = false
		sound.Playing = false
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 7
		sound.RollOffMaxDistance = 55
		sound.Parent = attachment
	end
	controller.Source = source

	print("[CableSparks] Added randomized Spark3-Spark8 audio to", attachment:GetFullName())
end

print(("[CableSparks] Sound update complete: %d attachment(s)"):format(#selectedAttachments))
