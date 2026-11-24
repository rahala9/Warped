--[[
	Skill Check System Module
	
	A comprehensive skill check system for action RPGs with:
	- Percentile-based probability (0-100%)
	- Attribute modifiers (like Intelligence, Dexterity, etc.)
	- Skill levels (0-5+)
	- Difficulty modifiers
	- Degrees of success/failure
	- Critical successes and failures
	- Contested rolls
	- Hidden modifiers for surprise
	
	Usage Example:
		local SkillCheck = require(script.SkillCheckSystem)
		
		local result = SkillCheck.MakeCheck({
			skillLevel = 2,
			attributeModifier = 1,
			difficulty = SkillCheck.Difficulty.Hard,
			showExactChance = false
		})
		
		if result.success then
			print("Success! Degree:", result.degree)
		end
]]

local SkillCheckSystem = {}

-- ==================== CONSTANTS ====================

-- Difficulty presets
SkillCheckSystem.Difficulty = {
	Trivial = 20,
	Easy = 10,
	Average = 0,
	Hard = -20,
	VeryHard = -40,
	NearImpossible = -60
}

-- Skill progression is intentionally nonlinear. Becoming trained is a large
-- improvement over being untrained, levels 1-4 grow steadily, and level 5 is
-- an exceptional jump beyond ordinary expertise.
SkillCheckSystem.MaxSkillLevel = 5
SkillCheckSystem.MaxAttributeLevel = 5
SkillCheckSystem.SkillTiers = {
	[0] = {SuccessBonus = 0, CriticalFailureRisk = 30, Name = "Untrained"},
	[1] = {SuccessBonus = 22, CriticalFailureRisk = 20, Name = "Novice"},
	[2] = {SuccessBonus = 32, CriticalFailureRisk = 17, Name = "Trained"},
	[3] = {SuccessBonus = 42, CriticalFailureRisk = 14, Name = "Skilled"},
	[4] = {SuccessBonus = 52, CriticalFailureRisk = 11, Name = "Expert"},
	[5] = {SuccessBonus = 78, CriticalFailureRisk = 3, Name = "Legendary"},
}

-- Descriptor mappings for vague chance display
SkillCheckSystem.ChanceDescriptor = {
	{max = 10, text = "Nearly Impossible", color = Color3.fromRGB(139, 0, 0)},
	{max = 25, text = "Very Unlikely", color = Color3.fromRGB(178, 34, 34)},
	{max = 40, text = "Unlikely", color = Color3.fromRGB(205, 92, 92)},
	{max = 60, text = "Possible", color = Color3.fromRGB(255, 215, 0)},
	{max = 75, text = "Likely", color = Color3.fromRGB(154, 205, 50)},
	{max = 90, text = "Very Likely", color = Color3.fromRGB(34, 139, 34)},
	{max = 100, text = "Almost Certain", color = Color3.fromRGB(0, 100, 0)}
}

-- ==================== CONFIGURATION ====================

local ATTRIBUTE_MULTIPLIER = 6
local MINIMUM_SUCCESS_CHANCE = 1
local MAXIMUM_SUCCESS_CHANCE = 95
local MINIMUM_CRITICAL_FAILURE_CHANCE = 2
local MAXIMUM_CRITICAL_FAILURE_CHANCE = 30

-- ==================== UTILITY FUNCTIONS ====================

-- Generate a random number between min and max (inclusive)
local function RandomRange(min, max)
	return math.random(min, max)
end

-- Clamp a value between min and max
local function Clamp(value, min, max)
	return math.max(min, math.min(max, value))
end

local function GetTier(options)
	local level = Clamp(math.floor(tonumber(options.skillLevel) or 0), 0, SkillCheckSystem.MaxSkillLevel)
	return SkillCheckSystem.SkillTiers[level], level
end

local function GetAttributeLevel(options)
	return Clamp(tonumber(options.attributeModifier) or 0, 0, SkillCheckSystem.MaxAttributeLevel)
end

local function GetDifficultyDanger(difficulty)
	-- Existing difficulty modifiers are in ten-point steps. Harder checks add
	-- danger while easier checks shave a small amount off the catastrophic risk.
	return Clamp(math.round(-(tonumber(difficulty) or 0) / 10), -2, 6)
end

-- Get a descriptor for a chance percentage
local function GetChanceDescriptor(chance)
	for _, descriptor in ipairs(SkillCheckSystem.ChanceDescriptor) do
		if chance <= descriptor.max then
			return descriptor.text, descriptor.color
		end
	end
	return "Unknown", Color3.fromRGB(128, 128, 128)
end

-- ==================== CORE FUNCTIONS ====================

--[[
	Calculate the success chance for a skill check
	
	Parameters:
		options (table):
			- skillLevel (number): Character's skill level (0-5)
			- attributeModifier (number): Relevant permanent attribute level (0-5)
			- difficulty (number): Difficulty modifier (use Difficulty constants)
			- hiddenModifier (number, optional): Hidden modifier not shown to player
			- equipmentBonus (number, optional): Bonus from tools/equipment
	
	Returns:
		number: The calculated success chance (0-100, clamped)
]]
function SkillCheckSystem.CalculateChance(options)
	local tier = GetTier(options)
	local attributeModifier = GetAttributeLevel(options)
	local difficulty = options.difficulty or 0
	local hiddenModifier = options.hiddenModifier or 0
	local equipmentBonus = options.equipmentBonus or 0

	local chance = tier.SuccessBonus

	-- Add attribute modifier
	chance = chance + (attributeModifier * ATTRIBUTE_MULTIPLIER)

	-- Add difficulty
	chance = chance + difficulty

	-- Add equipment bonus
	chance = chance + equipmentBonus

	-- Add hidden modifier (not shown to player)
	chance = chance + hiddenModifier

	return math.floor(Clamp(chance, MINIMUM_SUCCESS_CHANCE, MAXIMUM_SUCCESS_CHANCE))
end

function SkillCheckSystem.CalculateCriticalFailureChance(options)
	local tier = GetTier(options)
	local attributeLevel = GetAttributeLevel(options)
	local risk = tier.CriticalFailureRisk
		- attributeLevel
		+ GetDifficultyDanger(options.difficulty)
	return math.floor(Clamp(
		risk,
		MINIMUM_CRITICAL_FAILURE_CHANCE,
		MAXIMUM_CRITICAL_FAILURE_CHANCE
	))
end

--[[
	Make a skill check
	
	Parameters:
		options (table):
			- skillLevel (number): Character's skill level
			- attributeModifier (number): Attribute modifier
			- difficulty (number): Difficulty modifier
			- hiddenModifier (number, optional): Hidden modifier
			- equipmentBonus (number, optional): Equipment bonus
			- showExactChance (boolean, optional): If true, returns exact %. If false, returns descriptor
			- critEnabled (boolean, optional): Enable critical success/failure (default: true)
	
	Returns:
		table: {
			success (boolean): Whether the check succeeded
			roll (number): The actual roll (1-100)
			chance (number): The calculated success chance
			margin (number): How much the roll beat/missed the chance by
			degree (string): Degree of success/failure
			critical (boolean): Whether this was a critical success/failure
			descriptor (string): Vague descriptor of chance
			descriptorColor (Color3): Color for the descriptor
		}
]]
function SkillCheckSystem.MakeCheck(options)
	local chance = SkillCheckSystem.CalculateChance(options)

	local critEnabled = options.critEnabled
	if critEnabled == nil then
		critEnabled = true
	end

	local criticalFailureChance = critEnabled
		and SkillCheckSystem.CalculateCriticalFailureChance(options)
		or 0
	-- Reserve at least one roll for an ordinary failure after the two explicit
	-- outcome bands.
	chance = math.min(chance, 99 - criticalFailureChance)
	local descriptor, descriptorColor = GetChanceDescriptor(chance)

	local roll = RandomRange(1, 100)
	local successBandEnd = criticalFailureChance + chance
	local isCritical = false
	local success = false
	local degree

	if critEnabled and roll <= criticalFailureChance then
		degree = "Catastrophic"
		isCritical = true
	elseif roll <= successBandEnd then
		success = true
		local criticalSuccessWidth = critEnabled and math.min(5, chance) or 0
		isCritical = criticalSuccessWidth > 0
			and roll <= criticalFailureChance + criticalSuccessWidth

		local positionInSuccessBand = (roll - criticalFailureChance) / chance
		if isCritical or positionInSuccessBand <= 0.1 then
			degree = "Exceptional"
		elseif positionInSuccessBand <= 0.4 then
			degree = "Good"
		elseif positionInSuccessBand <= 0.75 then
			degree = "Average"
		else
			degree = "Marginal"
		end
	else
		-- Ordinary failures can never become catastrophic. Severity is based on
		-- how deep the roll landed in the remaining failure band.
		local failureBandSize = 100 - successBandEnd
		local positionInFailureBand = (roll - successBandEnd) / failureBandSize
		if positionInFailureBand <= 0.34 then
			degree = "Marginal"
		elseif positionInFailureBand <= 0.67 then
			degree = "Average"
		else
			degree = "Severe"
		end
	end

	local margin = successBandEnd - roll

	-- Return comprehensive result
	return {
		success = success,
		roll = roll,
		chance = chance,
		margin = margin,
		degree = degree,
		critical = isCritical,
		criticalFailureChance = criticalFailureChance,
		descriptor = descriptor,
		descriptorColor = descriptorColor
	}
end

--[[
	Make a contested check (two opponents rolling against each other)
	
	Parameters:
		attacker (table): Options for the attacker (same as MakeCheck)
		defender (table): Options for the defender (same as MakeCheck)
	
	Returns:
		table: {
			attackerWins (boolean): Whether the attacker won
			attackerResult (table): Full result for attacker
			defenderResult (table): Full result for defender
			margin (number): Difference between the two rolls
		}
]]
function SkillCheckSystem.ContestedCheck(attacker, defender)
	-- Both sides make their own check (without crit enabled for contested)
	attacker.critEnabled = false
	defender.critEnabled = false

	local attackerResult = SkillCheckSystem.MakeCheck(attacker)
	local defenderResult = SkillCheckSystem.MakeCheck(defender)

	-- Calculate total scores
	local attackerScore = attackerResult.roll + attackerResult.chance
	local defenderScore = defenderResult.roll + defenderResult.chance

	local attackerWins = attackerScore > defenderScore
	local margin = math.abs(attackerScore - defenderScore)

	return {
		attackerWins = attackerWins,
		attackerResult = attackerResult,
		defenderResult = defenderResult,
		margin = margin
	}
end

--[[
	Make a chain of skill checks (multiple checks in sequence)
	Each check can affect the next one
	
	Parameters:
		checks (array of tables): Array of check options
		stopOnFailure (boolean, optional): If true, stops chain on first failure
	
	Returns:
		table: {
			allSucceeded (boolean): Whether all checks succeeded
			results (array): Array of individual check results
			failedAt (number or nil): Index where chain failed (if any)
		}
]]
function SkillCheckSystem.ChainedChecks(checks, stopOnFailure)
	if stopOnFailure == nil then
		stopOnFailure = true
	end

	local results = {}
	local allSucceeded = true
	local failedAt = nil

	for i, checkOptions in ipairs(checks) do
		local result = SkillCheckSystem.MakeCheck(checkOptions)
		table.insert(results, result)

		if not result.success then
			allSucceeded = false
			failedAt = i

			if stopOnFailure then
				break
			end
		end
	end

	return {
		allSucceeded = allSucceeded,
		results = results,
		failedAt = failedAt
	}
end

--[[
	Get a formatted string describing the check result
	
	Parameters:
		result (table): Result from MakeCheck
		verboseMode (boolean, optional): If true, includes detailed info
	
	Returns:
		string: Formatted description of the result
]]
function SkillCheckSystem.FormatResult(result, verboseMode)
	local output = ""

	if result.success then
		output = output .. "✓ SUCCESS"
		if result.critical then
			output = output .. " (CRITICAL!)"
		end
		output = output .. " - " .. result.degree
	else
		output = output .. "✗ FAILURE"
		if result.critical then
			output = output .. " (CRITICAL!)"
		end
		output = output .. " - " .. result.degree
	end

	if verboseMode then
		output = output .. string.format("\nRoll: %d | Chance: %d%% | Margin: %+d", 
			result.roll, result.chance, result.margin)
	end

	return output
end

--[[
	Helper function to create common difficulty scenarios
]]
function SkillCheckSystem.QuickCheck(skillName, skillLevel, attributeMod, difficulty)
	local result = SkillCheckSystem.MakeCheck({
		skillLevel = skillLevel,
		attributeModifier = attributeMod,
		difficulty = difficulty or SkillCheckSystem.Difficulty.Average
	})

	print(string.format("[%s Check] %s", skillName, SkillCheckSystem.FormatResult(result, true)))

	return result
end

-- ==================== EXAMPLE SKILL CONFIGURATIONS ====================

--[[
	Predefined skill check configurations for common scenarios
	These can be customized for your specific game needs
]]

SkillCheckSystem.Skills = {
	-- Technology skills
	Hacking = {
		name = "Hacking",
		baseSkillName = "Hacking",
		primaryAttribute = "Brains",
		description = "Bypass security systems and access computer networks"
	},
	Engineering = {
		name = "Engineering",
		baseSkillName = "Engineering",
		primaryAttribute = "Brains",
		description = "Build and modify various systems"
	},
	--Engineering Specialization
	ElectronicalEngineering = {
		name = "ElectronicalEngineering",
		baseSkillName = "Engineering",
		primaryAttribute = "Brains",
		description = "Build and modify Electronic systems"
	},
	
	MechanicalEngineering = {
		name = "MechanicalEngineering",
		baseSkillName = "Engineering",
		primaryAttribute = "Brains",
		description = "Build and modify Mechanical systems"
	},
	
	PowerEngineering = {
		name = "PowerEngineering",
		baseSkillName = "Engineering",
		primaryAttribute = "Brains",
		description = "Build and modify Power systems"
	},
	
	WeaponEngineering = {
		name = "WeaponEngineering",
		baseSkillName = "Engineering",
		primaryAttribute = "Brains",
		description = "Build and modify Weapon systems"
	},

	-- Social skills
	Persuasion = {
		name = "Persuasion",
		baseSkillName = "Persuasion",
		primaryAttribute = "Vibe",
		description = "Convince others through reasoning and charm"
	},
	Intimidation = {
		name = "Intimidation",
		baseSkillName = "Intimidation",
		primaryAttribute = "Oomph",
		description = "Coerce others through threats and fear"
	},
	Deception = {
		name = "Deception",
		baseSkillName = "Deception",
		primaryAttribute = "Vibe",
		description = "Lie convincingly and mislead others"
	},

	-- Physical skills
	Athletics = {
		name = "Athletics",
		baseSkillName = "Athletics",
		primaryAttribute = "Oomph",
		description = "Perform feats of physical prowess. Passive Increase in speed and dodge ability"
	},
	Stealth = {
		name = "Stealth",
		baseSkillName = "Stealth",
		primaryAttribute = "Finesse",
		description = "Move silently and remain undetected"
	},
	--Stealth Specialization
	EscapeArtist = {
		name = "EscapeArtist",
		baseSkillName = "Stealth",
		primaryAttribute = "Finesse",
		description = "Can escape from any restraints, cuffs, traps etc."
	},
	-- Knowledge skills
	Investigation = {
		name = "Investigation",
		baseSkillName = "Investigation",
		primaryAttribute = "Brains",
		description = "Analyze clues and solve mysteries"
	},
	Medic = {
		name = "Medic",
		baseSkillName = "Medic",
		primaryAttribute = "Wits",
		description = "Bandage to stop bleeding"
	},
	--Medic Specialization
	Doctor = {
		name = "Doctor",
		baseSkillName = "Medic",
		primaryAttribute = "Brains",
		description = "Treat minor injury"
	},
	Surgeon = {
		name = "Surgeon",
		baseSkillName = "Medic",
		primaryAttribute = "Brains",
		description = "Treat major injury and disease"
	},
	
	Mechanic = {
		name = "Mechanic",
		baseSkillName = "Mechanic",
		primaryAttribute = "Finesse",
		description = "Repair planet side and space side vehicles"
	},

	Survival = {
		name = "Survival",
		baseSkillName = "Survival",
		primaryAttribute = "Grit",
		description = "Build shelter, identify plants, forage for food"
	},
	
	Trade = {
		name = "Trade",
		baseSkillName = "Trade",
		primaryAttribute = "Vibe",
		description = "Trade"
	},
	--Trade Specialization
	MarketTrade = {
		name = "MarketTrade",
		baseSkillName = "Trade",
		primaryAttribute = "Vibe",
		description = "Trade in legal goods"
	},
	BlackMarketTrade = {
		name = "BlackMarketTrade",
		baseSkillName = "Trade",
		primaryAttribute = "Vibe",
		description = "Trade in illegal goods"
	},
	Navigation = {
		name = "Navigation",
		baseSkillName = "Trade",
		primaryAttribute = "Vibe",
		description = "Plotting Course, Landing on Planets,Reading Maps" -- How close you land to city on planet, faster course and closer to object, less chance of surprise encounter while on plot., unlock more way points
	},
	ShipSystems = {
		name = "ShipSystems",
		baseSkillName = "ShipSystems",
		primaryAttribute = "Brains",
		description = "Working with various systems of a spaceship"
	},
	--ShipSystems Specialization
	Scanners = {
		name = "Scanners",
		baseSkillName = "ShipSystems",
		primaryAttribute = "Brains",
		description = "Working with a ships scanner system"
	},
	Communications = {
		name = "Communications",
		baseSkillName = "ShipSystems",
		primaryAttribute = "Brains",
		description = "Working with a ships comm system"
	},
	Combat = {
		name = "Combat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Land Close and Ranged Combat"
	},
	
	--Combat Specialization
	MeleeCombat = {
		name = "MeleeCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Oomph",
		description = "Close combat with hands and feet"
	},
	KineticPistolCombat = {
		name = "KineticPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat with bullet based pistols"
	},
	KineticRifleCombat = {
		name = "KineticPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with bullet based rifles"
	},
	LaserPistolCombat = {
		name = "LaserPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Laser pistols"
	},
	LaserRifleCombat = {
		name = "LaserRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Laser rifles"
	},
	ElectricPistolCombat = {
		name = "ElectricPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Electric pistols"
	},
	ElectricRifleCombat = {
		name = "ElectricRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Electric rifles"
	},
	PlasmaPistolCombat = {
		name = "PlasmaPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Plasma pistols"
	},
	PlasmaRifleCombat = {
		name = "PlasmaRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Plasma rifles"
	},
	SonicPistolCombat = {
		name = "SonicPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Sonic pistols"
	},
	SonicRifleCombat = {
		name = "SonicRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Sonic rifles"
	},
	CryoPistolCombat = {
		name = "CryoPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Cryo pistols"
	},
	CryoRifleCombat = {
		name = "CryoRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Cryo rifles"
	},
	IncendiaryPistolCombat = {
		name = "IncendiaryPistolCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Mid Rang combat Incendiary pistols"
	},
	IncendiaryRifleCombat = {
		name = "IncendiaryRifleCombat",
		baseSkillName = "Combat",
		primaryAttribute = "Finesse",
		description = "Long Range combat with Incendiary rifles"
	},
	SpaceCombat = {
		name = "SpaceCombat",
		baseSkillName = "SpaceCombat",
		primaryAttribute = "Finesse",
		description = "Combat with spaceships"
	},
	--SpaceCombat Specialization
	ElectronicWarfare = {
		name = "ElectronicWarfare",
		baseSkillName = "SpaceCombat",
		primaryAttribute = "Brains",
		description = "Jamming Scanners, Spoofing spacecraft signature, Spoofing scanners (hiding cargo)"
	},
	ShipWeaponSystems = {
		name = "ShipWeaponSystems",
		baseSkillName = "SpaceCombat",
		primaryAttribute = "Finesse",
		description = "Ship weapon systems accuracy and targeted damage"
	},
	Explosives = {
		name = "Explosives",
		baseSkillName = "Explosives",
		primaryAttribute = "Wits",
		description = "Grenades, Traps, Charges"
	},
	Pilot = {
		name = "Pilot",
		baseSkillName = "Pilot",
		primaryAttribute = "Finesse",
		description = "Flying, Maneuvering, Landing"
	},
	HeavyWeapons = {
		name = "HeavyWeapons",
		baseSkillName = "HeavyWeapons",
		primaryAttribute = "Oomph",
		description = "Rocket Launchers, Plasma Cannons"
	},
	Tracking = {
		name = "Tracking",
		baseSkillName = "Tracking",
		primaryAttribute = "Wits",
		description = "Tracking People"
	},
	Language = {
		name = "Language",
		baseSkillName = "Language",
		primaryAttribute = "Brains",
		description = "Learning and Using Languages"
	},
	Science = {
		name = "Science",
		baseSkillName = "Science",
		primaryAttribute = "Brains",
		description = "Knowledge and application of the sciences"
	},
	--Science Specialization
	Chemistry = {
		name = "Chemistry",
		baseSkillName = "Science",
		primaryAttribute = "Brains",
		description = "Knowledge and application of Chemistry"
	},
	Geology = {
		name = "Geology",
		baseSkillName = "Science",
		primaryAttribute = "Brains",
		description = "Knowledge and application of Geology"
	},
	Biology = {
		name = "Biology",
		baseSkillName = "Science",
		primaryAttribute = "Brains",
		description = "Knowledge and application of Biology"
	},
	Genetics = {
		name = "Genetics",
		baseSkillName = "Science",
		primaryAttribute = "Brains",
		description = "Knowledge and application of Genetics"
	},
	Protocol = {
		name = "Protocol",
		baseSkillName = "Protocol",
		primaryAttribute = "Vibe",
		description = "Fitting into other class gatherings, military or corporate."
	},
	Psionics = {
		name = "Psionics",
		baseSkillName = "Psionics",
		primaryAttribute = "Wits",
		description = "Outward projection of your mind"
	},
	--Psionics Specialization
	Telepathy = {
		name = "Telepathy",
		baseSkillName = "Psionics",
		primaryAttribute = "Wits",
		description = "Mind reading"
	},
	Telekinesis = {
		name = "Telekinesis",
		baseSkillName = "Psionics",
		primaryAttribute = "Wits",
		description = "Controlling objects with your mind"
	},
	RemoteViewing = {
		name = "RemoteViewing",
		baseSkillName = "Psionics",
		primaryAttribute = "Wits",
		description = "Viewing anything remotely"
	},


}

return SkillCheckSystem
