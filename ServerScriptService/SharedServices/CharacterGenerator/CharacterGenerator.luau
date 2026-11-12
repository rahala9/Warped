-- CharacterGenerator.lua (data-driven)
local CharacterGenerator = {}

local Planets = require(script.Parent:WaitForChild("Planets"))
local StoryData = require(script.Parent:WaitForChild("StoryData"))
local Rules = require(script.Parent:WaitForChild("NarrativeRules"))

---------------------------------------------------------------------
-- CONFIG
---------------------------------------------------------------------
local STAT_LIST = { "Strength", "Intelligence", "Wisdom", "Charisma", "Perception", "Vitality" }
local STAT_ABBR = { Strength="Str", Intelligence="Int", Wisdom="Wis", Charisma="Cha", Perception="Per", Vitality="Vit" }
local STAT_EFFECTS = { 
	Strength="Melee attack power, moving and forcing physical objects, carrying capacity", 
	Intelligence="Hacking and engineering proficiency, gadget efficiency, resistance to mind-altering effects", --Logic reasoning, confusion,overloading,illusion
	Wisdom="Accuracy of planet and enemy intel, hazard recognition, resistance to reality-altering effects",
	Charisma="Expanded dialog options, vendor pricing, social influence, ability to redirect or control enemy attention", 
	Perception="Ranged weapon accuracy, detection of enemy telegraphs, ambush awareness, environmental detail detection", 
	Vitality="Maximum hit points, health recovery rate, resistance to status effects, endurance against environmental damage" 
}

local RANDOM_POINTS = 15
local PLAYER_POINTS = 5
local BASE = 0
local MIN_STAT = 0
local MAX_STAT = 10
local MIN_AGE = 18
local MAX_AGE = 29

---------------------------------------------------------------------
-- Utility
---------------------------------------------------------------------
local function makeRng(seed) return Random.new(seed or os.time()) end
local function clamp(n, lo, hi) if n < lo then return lo elseif n > hi then return hi else return n end end
local function choose(rng, list) return list[rng:NextInteger(1, #list)] end

local function pickUnique(rng, list, used)
	if not list or #list == 0 then return nil end
	local tries = 8
	while tries > 0 do
		local item = choose(rng, list)
		if item and not used[item] then
			used[item] = true
			return item
		end
		tries -= 1
	end
	-- fallback: allow duplicate if we couldn't find unique
	local item = choose(rng, list)
	if item then used[item] = true end
	return item
end

local function quirkToTag(quirkText)
	local q = string.lower(quirkText or "")

	-- keep this intentionally simple; it’s data-driven in StartingItems.ByQuirkTag
	if q:find("tool") then return "tools" end
	if q:find("badge") then return "badges" end
	if q:find("warning") or q:find("label") then return "labels" end
	if q:find("notebook") or q:find("diagram") then return "notebook" end
	if q:find("clipboard") then return "clipboard" end
	if q:find("machine") or q:find("restart") then return "machines" end
	if q:find("classified") or q:find("lunch") then return "classified" end
	if q:find("vibe") then return "vibe" end
	if q:find("alarm") then return "alarms" end

	return nil
end

local function selectStartingItems(rng, planet, dept, quirk)
	local used = {}

	local function pickUnique(list)
		if not list or #list == 0 then return nil end
		for _ = 1, 8 do
			local item = choose(rng, list)
			if item and not used[item] then
				used[item] = true
				return item
			end
		end
		local item = choose(rng, list)
		if item then used[item] = true end
		return item
	end

	local items = {
		Planet = pickUnique(planet.StartingItems) or "Basic Survival Kit",
		Department = pickUnique(dept.StartingItems) or "Standard Issue Toolkit",
		Quirk = pickUnique(quirk and quirk.StartingItems) or "Pocket Notebook",
	}
	items.All = { items.Planet, items.Department, items.Quirk }
	return items
end

local function capFirst(s)
	if not s or s == "" then return s end
	return (s:gsub("^%l", string.upper))
end

local function ensurePeriod(s)
	if not s or s == "" then return s end
	local last = s:sub(-1)
	if last == "." or last == "!" or last == "?" then return s end
	return s .. "."
end

local function formatTemplate(text, vars)
	return (text:gsub("{(%w+)}", function(key)
		local v = vars[key]
		if v == nil then return "{" .. key .. "}" end
		return tostring(v)
	end))
end

local function debugTag(stats, statNames, debugEnabled)
	if not debugEnabled then return "" end
	if type(statNames) ~= "table" then statNames = { statNames } end
	local parts = {}
	for _, s in ipairs(statNames) do
		local ab = STAT_ABBR[s] or s
		table.insert(parts, ("%s %d"):format(ab, stats[s] or 0))
	end
	return " (" .. table.concat(parts, ", ") .. ")"
end

---------------------------------------------------------------------
-- Stats
---------------------------------------------------------------------
local function initStats()
	local stats = {}
	for _, s in ipairs(STAT_LIST) do stats[s] = BASE end
	return stats
end

local function validateAndCountPlayerAlloc(playerAlloc)
	local total = 0
	playerAlloc = playerAlloc or {}
	for _, stat in ipairs(STAT_LIST) do
		local v = playerAlloc[stat]
		if v ~= nil then
			if type(v) ~= "number" or v < 0 or v % 1 ~= 0 then
				error(("Player allocation for %s must be a non-negative integer"):format(stat))
			end
			total += v
		end
	end
	return total
end

local function distributeRandomPoints(rng, stats, points)
	for _ = 1, points do
		local candidates = {}
		for _, s in ipairs(STAT_LIST) do
			if stats[s] < MAX_STAT then table.insert(candidates, s) end
		end
		if #candidates == 0 then break end
		local pick = candidates[rng:NextInteger(1, #candidates)]
		stats[pick] = stats[pick] + 1
	end
end

local function applyPlayerPoints(stats, playerAlloc)
	if not playerAlloc then return end
	for _, s in ipairs(STAT_LIST) do
		local add = playerAlloc[s] or 0
		if add ~= 0 then
			stats[s] = clamp(stats[s] + add, MIN_STAT, MAX_STAT)
		end
	end
end

local function rankStats(stats)
	local arr = {}
	for _, s in ipairs(STAT_LIST) do table.insert(arr, { stat=s, value=stats[s] }) end
	table.sort(arr, function(a,b)
		if a.value == b.value then return a.stat < b.stat end
		return a.value > b.value
	end)
	return arr
end

local function statTag(stats, statName)
	local v = stats[statName] or 0
	if v >= 8 then return "high" end
	if v <= 2 then return "low" end
	return "mid"
end

---------------------------------------------------------------------
-- Condition evaluation (data-driven)
-- Condition form examples:
-- { all = { {tag="Charisma", is="high"}, {tag="Wisdom", is="low"} } }
-- { any = { {tag="Perception", is="high"} } }
---------------------------------------------------------------------
local function matchAtom(ctx, atom)
	-- atom: { tag="Charisma", is="high" }
	local t = atom.tag
	local want = atom.is
	local actual = ctx.tags[t]
	return actual == want
end

local function matchCondition(ctx, cond)
	if cond == nil then return true end
	if cond.all then
		for _, atom in ipairs(cond.all) do
			if not matchAtom(ctx, atom) then return false end
		end
		return true
	end
	if cond.any then
		for _, atom in ipairs(cond.any) do
			if matchAtom(ctx, atom) then return true end
		end
		return false
	end
	-- If malformed, be permissive
	return true
end

local function pickRule(rng, ctx, rules)
	-- rules: array of {text, when, weight, stats}
	local candidates = {}
	local totalWeight = 0
	for _, r in ipairs(rules) do
		if matchCondition(ctx, r.when) then
			local w = r.weight or 1
			totalWeight += w
			table.insert(candidates, { rule=r, w=w })
		end
	end
	if #candidates == 0 then return nil end

	local roll = rng:NextNumber(0, totalWeight)
	local acc = 0
	for _, c in ipairs(candidates) do
		acc += c.w
		if roll <= acc then
			return c.rule
		end
	end
	return candidates[#candidates].rule
end

---------------------------------------------------------------------
-- Corporate Liability Risk (kept logic-y, but you can also data-drive this later)
---------------------------------------------------------------------
local function computeCorporateLiabilityRisk(rng, stats)
	local score = 0
	if statTag(stats,"Wisdom") == "low" then score += 2 end
	if statTag(stats,"Perception") == "low" then score += 2 end
	if statTag(stats,"Charisma") == "high" then score += 1 end
	if statTag(stats,"Intelligence") == "high" and statTag(stats,"Wisdom") == "low" then score += 2 end
	if statTag(stats,"Vitality") == "high" then score += 1 end
	score += rng:NextInteger(0, 1)

	if score <= 1 then return "low" end
	if score <= 3 then return "moderate" end
	if score <= 5 then return "concerning" end
	return "please stop asking questions"
end

---------------------------------------------------------------------
-- Narrative assembly (data-driven)
---------------------------------------------------------------------
local function buildContext(stats)
	local tags = {}
	for _, s in ipairs(STAT_LIST) do tags[s] = statTag(stats, s) end
	return { tags = tags }
end

local function buildNarrative(rng, stats, planet, reason, mishap, quirk, debugEnabled)
	local ctx = buildContext(stats)

	local vars = {
		PlanetName = planet.Name,
		Terrain = planet.Terrain,
		Climate = planet.Climate,
		Trade = planet.Trade,
		CultureFlavor = planet.CultureFlavor,
		ReasonThrough = reason.Through,
		ReasonBecause = reason.Because,
		ReasonTo = reason.To,
		Mishap = mishap,
		Quirk = quirk.Text,
	}

	-- Sentence 1: planet base + 1 childhood clause
	local intro1 = formatTemplate(Rules.PlanetIntro.First, vars)
	local intro2 = formatTemplate(Rules.PlanetIntro.Second, vars)
	local s1 = capFirst(intro1 .. " " .. intro2)
	local childRule = pickRule(rng, ctx, Rules.ChildhoodClauses)
	
	if childRule then
		s1 = s1 .. " " .. childRule.text .. debugTag(stats, childRule.stats or {}, debugEnabled)
	end
	s1 = ensurePeriod(capFirst(s1))

	-- Sentence 2: reason sentence
	local reasonRule = pickRule(rng, ctx, Rules.ReasonSentences)
	local s2 = formatTemplate((reasonRule and reasonRule.text) or "You got here through {Reason}.", vars)
	s2 = ensurePeriod(capFirst(s2 .. debugTag(stats, (reasonRule and reasonRule.stats) or {}, debugEnabled)))

	-- Sentence 3: role based on top + secondary based on second
	local ranked = rankStats(stats)
	local top = ranked[1].stat
	local second = ranked[2].stat

	local rolePool = Rules.RoleByTopStat[top] or { { text="You’ve become strangely useful in ways nobody can define.", stats={top} } }
	local roleRule = choose(rng, rolePool)
	local secEntry = Rules.SecondaryFlavor[second]
	local secRule

	if secEntry then
		local tag = statTag(stats, second) -- "high" / "mid" / "low"
		local bucket = secEntry.Mid

		if tag == "high" then
			bucket = secEntry.High or secEntry.Mid
		elseif tag == "low" then
			bucket = secEntry.Low or secEntry.Mid
		end

		if bucket and #bucket > 0 then
			secRule = choose(rng, bucket) -- ✅ random within correct category
		end
	end

	local s3 = capFirst(roleRule.text .. debugTag(stats, roleRule.stats or { top }, debugEnabled))
	if secRule then
		s3 = s3 .. " " .. secRule.text .. debugTag(stats, secRule.stats or { second }, debugEnabled)
	end
	s3 = ensurePeriod(s3)

	-- Sentence 4: mishap
	local mishapTemplate = choose(rng, Rules.MishapTemplates)
	local s4 = formatTemplate(mishapTemplate, vars)
	s4 = ensurePeriod(capFirst(s4 .. debugTag(stats, { "Wisdom", "Perception" }, debugEnabled)))

	-- Sentence 5: quirk (handles "are ..." quirks)
	local quirkTemplate = choose(rng, Rules.QuirkTemplates)
	local s5 = formatTemplate(quirkTemplate, vars)
	s5 = ensurePeriod(capFirst(s5 .. debugTag(stats, { "Charisma", "Wisdom" }, debugEnabled)))

	return table.concat({ s1, s2, s3, s4, s5 }, " ")
end

---------------------------------------------------------------------
-- PUBLIC API
-- Generate(seed, playerName, playerAlloc, options)
-- options = { debug = true/false }
---------------------------------------------------------------------
function CharacterGenerator.Generate(seed, playerName, playerAlloc, options)
	local rng = makeRng(seed)
	options = options or {}
	local debugEnabled = options.debug == true

	playerName = playerName or "Intern"
	playerAlloc = playerAlloc or {}

	local allocTotal = validateAndCountPlayerAlloc(playerAlloc)
	if allocTotal > PLAYER_POINTS then
		error(("Player allocated %d points but only %d allowed"):format(allocTotal, PLAYER_POINTS))
	end

	local stats = initStats()
	distributeRandomPoints(rng, stats, RANDOM_POINTS)
	applyPlayerPoints(stats, playerAlloc)

	for _, s in ipairs(STAT_LIST) do
		stats[s] = clamp(stats[s], MIN_STAT, MAX_STAT)
	end

	local planet = choose(rng, Planets.List)
	local dept = choose(rng, StoryData.Departments)
	local reason = choose(rng, StoryData.InternReasons)
	local mishap = choose(rng, StoryData.Mishaps)
	local quirk = choose(rng, StoryData.PersonalQuirks)
	local startingItems = selectStartingItems(rng, planet.Name, dept, quirk)

	local age = rng:NextInteger(MIN_AGE, MAX_AGE)
	local risk = computeCorporateLiabilityRisk(rng, stats)

	local dataProfile = {
		Name = playerName,
		Age = age,
		HomePlanet = planet.Name,
		AssignedTo = ("Sci-Ops: %s"):format(dept.Name),
		CorporateLiabilityRisk = risk,
		StartingItems = startingItems.All
	}

	local narrative = buildNarrative(rng, stats, planet, reason, mishap, quirk, debugEnabled)

	return {
		Stats = stats,
		RankedStats = rankStats(stats),
		Backstory = {
			DataProfile = dataProfile,
			Narrative = narrative,
			Planet = planet, -- helpful for debugging/expansion
		},
		StartingItems = startingItems, 
	}
end

return CharacterGenerator
