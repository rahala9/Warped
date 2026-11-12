-- NarrativeRules.lua
local Rules = {}

Rules.Tags = { High="high", Mid="mid", Low="low" }

---------------------------------------------------------------------
-- Planet introduction (2 sentences, atmospheric)
---------------------------------------------------------------------
Rules.PlanetIntro = {
	First =
		"You grew up on {PlanetName}, a world of {Terrain} beneath {Climate}.",
	Second =
		"Most people there made their living in {Trade}, and it taught you that {CultureFlavor}.",
}

---------------------------------------------------------------------
-- Childhood clauses (stat-driven, reflective tone)
---------------------------------------------------------------------
Rules.ChildhoodClauses = {

	-----------------------------------------------------------------
	-- INTELLIGENCE
	-----------------------------------------------------------------
	{
		text = "Early on, you learned to take things apart, map the patterns, and put them back together without admitting you ever touched them.",
		stats = { "Intelligence" },
		when = { all = { { tag="Intelligence", is="high" } } },
	},
	{
		text = "You spent a lot of time taking things apart just to see how they worked, and putting them back together well enough that no one complained.",
		stats = { "Intelligence" },
		when = { all = { { tag="Intelligence", is="high" } } },
	},
	{
		text = "You learned by doing, sometimes twice, because the first attempt rarely told the whole story.",
		stats = { "Intelligence" },
		when = { all = { { tag="Intelligence", is="low" } } },
	},
	{
		text = "You learned early that instructions were optional, as long as the result looked intentional.",
		stats = { "Intelligence" },
		when = { all = { { tag="Intelligence", is="low" } } },
	},

	-----------------------------------------------------------------
	-- PERCEPTION
	-----------------------------------------------------------------
	{
		text = "You developed an eye for small warnings before they became real problems.",
		stats = { "Perception" },
		when = { all = { { tag="Perception", is="high" } } },
	},
	{
		text = "You learned to notice small changes—sounds, movements, patterns—that told you when to pay attention.",
		stats = { "Perception" },
		when = { all = { { tag="Perception", is="high" } } },
	},
	{
		text = "You had a habit of missing hazards until they were already part of your routine.",
		stats = { "Perception" },
		when = { all = { { tag="Perception", is="low" } } },
	},
	{
		text = "You trusted that anything important would announce itself loudly.",
		stats = { "Perception" },
		when = { all = { { tag="Perception", is="low" } } },
	},

	-----------------------------------------------------------------
	-- WISDOM
	-----------------------------------------------------------------
	{
		text = "You got used to checking things twice—doors, tools, people—before trusting them.",
		stats = { "Wisdom" },
		when = { all = { { tag="Wisdom", is="high" } } },
	},
	{
		text = "You developed a habit of watching how things failed before trusting how they worked.",
		stats = { "Wisdom" },
		when = { all = { { tag="Wisdom", is="high" } } },
	},
	{
		text = "You carried a quiet confidence in bad ideas, and somehow lived long enough to refine them.",
		stats = { "Wisdom" },
		when = { all = { { tag="Wisdom", is="low" } } },
	},
	{
		text = "You tended to learn lessons after the consequences made them memorable.",
		stats = { "Wisdom" },
		when = { all = { { tag="Wisdom", is="low" } } },
	},

	-----------------------------------------------------------------
	-- STRENGTH
	-----------------------------------------------------------------
	{
		text = "You were often handed the heavy end of a problem, and no one bothered asking if you minded.",
		stats = { "Strength" },
		when = { all = { { tag="Strength", is="high" } } },
	},
	{
		text = "You learned to solve problems without relying on brute force.",
		stats = { "Strength" },
		when = { all = { { tag="Strength", is="low" } } },
	},

	-----------------------------------------------------------------
	-- CHARISMA
	-----------------------------------------------------------------
	{
		text = "You got good at talking people into helping, or at least not stopping you.",
		stats = { "Charisma" },
		when = { all = { { tag="Charisma", is="high" } } },
	},
	{
		text = "You preferred listening to talking, which meant people often underestimated you.",
		stats = { "Charisma" },
		when = { all = { { tag="Charisma", is="low" } } },
	},

	-----------------------------------------------------------------
	-- VITALITY
	-----------------------------------------------------------------
	{
		text = "Long days didn’t scare you; you learned how to keep going without making a show of it.",
		stats = { "Vitality" },
		when = { all = { { tag="Vitality", is="high" } } },
	},
	{
		text = "You learned the importance of pacing yourself, because pushing too hard always came back to collect.",
		stats = { "Vitality" },
		when = { all = { { tag="Vitality", is="low" } } },
	},

	-----------------------------------------------------------------
	-- MIXED / GENERAL FLAVOR
	-----------------------------------------------------------------
	{
		text = "You weren’t flashy, but you were usually around when something needed doing.",
		stats = { "Wisdom", "Vitality" },
		weight = 0.5,
	},
	{
		text = "You weren’t the loudest or the boldest, but you paid attention.",
		stats = { "Wisdom", "Perception" },
		weight = 0.4,
	},
	{
		text = "You grew up adapting to whatever was broken that day.",
		stats = { "Intelligence", "Vitality" },
		weight = 0.4,
	},
	{
		text = "You learned early that competence mattered more than confidence.",
		stats = { "Wisdom", "Intelligence" },
		weight = 0.4,
	},
}


---------------------------------------------------------------------
-- Internship origin (hindsight framing)
---------------------------------------------------------------------
Rules.ReasonSentences = {
	{
		text = "You ended up at Sci-Ops through {ReasonThrough}, and you somehow made it sound like their idea.",
		stats = { "Charisma" },
		when = { all = { { tag="Charisma", is="high" } } },
	},
	{
		text = "Sci-Ops started as a way to deal with {ReasonThrough}, and then you kept getting assigned things you were good at.",
		stats = { "Intelligence" },
		when = { all = { { tag="Intelligence", is="high" } } },
	},
	{
		text = "You came to Sci-Ops through {ReasonThrough}, and the fine print has been quietly winning ever since.",
		stats = { "Wisdom" },
		when = { all = { { tag="Wisdom", is="low" } } },
	},
	{
		text = "You ended up here because {ReasonBecause}.",
		stats = { "Charisma", "Intelligence", "Wisdom" },
		weight = 0.7,
	},
}


---------------------------------------------------------------------
-- Role sentences (unchanged structure, refined tone)
---------------------------------------------------------------------
Rules.RoleByTopStat = {
	Strength = {
		{ text = "You’re the person they call when something heavy refuses to move.", stats={ "Strength" } },
		{ text = "You’ve become reliable around crates, doors, and machinery that claims it isn’t broken.", stats={ "Strength" } },
	},
	Intelligence = {
		{ text = "You tend to check one thing and end up fixing three others along the way.", stats={ "Intelligence" } },
		{ text = "Systems behave better when you’re the one talking to them.", stats={ "Intelligence" } },
	},
	Wisdom = {
		{ text = "You’re usually the one slowing things down before they turn into paperwork.", stats={ "Wisdom" } },
		{ text = "You’ve learned when not to improvise.", stats={ "Wisdom" } },
	},
	Charisma = {
		{ text = "You can calm a room with a few sentences and a confident nod.", stats={ "Charisma" } },
		{ text = "People tend to agree with you before they realize they have.", stats={ "Charisma" } },
	},
	Perception = {
		{ text = "You notice details most people walk past without thinking.", stats={ "Perception" } },
		{ text = "Anomalies tend to announce themselves to you first.", stats={ "Perception" } },
	},
	Vitality = {
		{ text = "You outlast bad shifts and worse ideas.", stats={ "Vitality" } },
		{ text = "You keep showing up, even when you probably shouldn’t.", stats={ "Vitality" } },
	},
}

Rules.SecondaryFlavor = {
	Strength = {
		High = {
			{ text = "You’re sturdier than you look.", stats = { "Strength" } },
			{ text = "You don’t complain about heavy work—you just do it.", stats = { "Strength" } },
			{ text = "When something jams, you tend to become the solution.", stats = { "Strength" } },
			{ text = "You’ve got the kind of strength that makes broken equipment nervous.", stats = { "Strength" } },
		},
		Low = {
			{ text = "You’ve learned that leverage beats brute force every time.", stats = { "Strength" } },
			{ text = "You avoid lifting anything you can convince a cart to carry.", stats = { "Strength" } },
			{ text = "You have excellent opinions about ‘team lifts.’", stats = { "Strength" } },
		},
		Mid = {
			{ text = "You can handle yourself, but you don’t try to win arguments with bulkheads.", stats = { "Strength" } },
		},
	},

	Intelligence = {
		High = {
			{ text = "You learn fast and remember inconvenient details.", stats = { "Intelligence" } },
			{ text = "Systems make more sense after you’ve looked at them.", stats = { "Intelligence" } },
			{ text = "You can usually tell what’s wrong before the alarm finishes warming up.", stats = { "Intelligence" } },
			{ text = "You’re good at turning chaos into something that almost works.", stats = { "Intelligence" } },
		},
		Low = {
			{ text = "You’ve learned to rely on instincts and checklists, in that order.", stats = { "Intelligence" } },
			{ text = "You prefer buttons with labels and problems with witnesses.", stats = { "Intelligence" } },
			{ text = "You can do a lot—as long as nobody asks you to explain it.", stats = { "Intelligence" } },
		},
		Mid = {
			{ text = "You’re capable, but you don’t fall in love with your own theories.", stats = { "Intelligence" } },
		},
	},

	Wisdom = {
		High = {
			{ text = "You’ve learned caution the hard way.", stats = { "Wisdom" } },
			{ text = "You’re good at noticing when a plan is becoming an incident report.", stats = { "Wisdom" } },
			{ text = "You tend to ask one question that saves everyone later.", stats = { "Wisdom" } },
			{ text = "You don’t trust ‘probably’ as a safety rating.", stats = { "Wisdom" } },
		},
		Low = {
			{ text = "You have a rare confidence in bad ideas.", stats = { "Wisdom" } },
			{ text = "You can talk yourself into trouble faster than you can talk yourself out of it.", stats = { "Wisdom" } },
			{ text = "You’re learning the difference between bravery and paperwork.", stats = { "Wisdom" } },
		},
		Mid = {
			{ text = "You’ll take a risk when you must, but you prefer not to donate your future to HR.", stats = { "Wisdom" } },
		},
	},

	Charisma = {
		High = {
			{ text = "You’re persuasive, even when you’re wrong.", stats = { "Charisma" } },
			{ text = "People tend to agree with you before they realize they have.", stats = { "Charisma" } },
			{ text = "You can turn a ‘no’ into a ‘fine’ with impressive speed.", stats = { "Charisma" } },
			{ text = "You’ve got a talent for making problems sound temporary.", stats = { "Charisma" } },
		},
		Low = {
			{ text = "You speak mostly when it matters, which sometimes makes people nervous.", stats = { "Charisma" } },
			{ text = "You have the energy of someone who’d rather email than talk.", stats = { "Charisma" } },
			{ text = "You’re not great at small talk, but you’re excellent at leaving.", stats = { "Charisma" } },
		},
		Mid = {
			{ text = "You can get your point across—eventually.", stats = { "Charisma" } },
		},
	},

	Perception = {
		High = {
			{ text = "You catch patterns others miss.", stats = { "Perception" } },
			{ text = "You notice details most people walk past without thinking.", stats = { "Perception" } },
			{ text = "If something changes, you’re usually the first to feel it.", stats = { "Perception" } },
			{ text = "You’ve got the kind of awareness that makes ambushes awkward.", stats = { "Perception" } },
		},
		Low = {
			{ text = "You’re optimistic about hazards, which is a polite way to describe it.", stats = { "Perception" } },
			{ text = "You sometimes miss the obvious, but you commit to the bit.", stats = { "Perception" } },
			{ text = "You’ve learned to trust other people’s warning shots.", stats = { "Perception" } },
		},
		Mid = {
			{ text = "You notice enough to stay alive, and that’s a skill.", stats = { "Perception" } },
		},
	},

	Vitality = {
		High = {
			{ text = "You bounce back faster than expected.", stats = { "Vitality" } },
			{ text = "You outlast bad shifts and worse ideas.", stats = { "Vitality" } },
			{ text = "You’ve got endurance that makes overtime look nervous.", stats = { "Vitality" } },
			{ text = "You recover quickly, even when you shouldn’t.", stats = { "Vitality" } },
		},
		Low = {
			{ text = "You’ve learned to pace yourself, because your body will file a complaint otherwise.", stats = { "Vitality" } },
			{ text = "You can push through, but you pay for it later.", stats = { "Vitality" } },
			{ text = "You’ve become an expert in ‘short breaks’ and ‘strategic sitting.’", stats = { "Vitality" } },
		},
		Mid = {
			{ text = "You can keep going, but you don’t pretend it’s free.", stats = { "Vitality" } },
		},
	},
}


---------------------------------------------------------------------
---------------------------------------------------------------------
-- Mishap sentence templates (randomly chosen)
---------------------------------------------------------------------
Rules.MishapTemplates = {
	"Your first week included an incident where you {Mishap}, and the official response was to add two new forms.",
	"During your first week, you {Mishap}. This resulted in additional paperwork.",
	"Early on, you managed to {Mishap}, which prompted an internal review and several new forms.",
	"Your onboarding period was marked by the moment you {Mishap}, after which procedures were quietly updated.",
	"Somewhere in your first week, you {Mishap}, and no one has let you forget it since.",
	"It didn’t take long before you {Mishap}, triggering a brief meeting and a permanent policy change.",
}

---------------------------------------------------------------------
-- Quirk sentence templates (randomly chosen)
---------------------------------------------------------------------
Rules.QuirkTemplates = {
	"People have already noticed that you {Quirk}, which is either endearing or a compliance issue.",
	"It has not gone unnoticed that you {Quirk}, and opinions on this are divided.",
	"Colleagues have started to comment on the fact that you {Quirk}. HR has not weighed in yet.",
	"You have developed a reputation for how you {Quirk}, and management is still deciding what to call it.",
	"More than one person has pointed out that you {Quirk}. This has been logged.",
	"It quickly became apparent that you {Quirk}, which may or may not be a problem.",
}
return Rules
