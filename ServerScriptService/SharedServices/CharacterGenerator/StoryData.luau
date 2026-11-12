-- StoryData.lua
local StoryData = {}

StoryData.Departments = {
	-- Core operations
	{ Name = "Containment Logistics", StartingItems = { "Matter Condensing Storage Unit", "Cargo Lift Operator License" } },
	{ Name = "Anomaly Intake", StartingItems = { "Unknown Specimen in Jar", "Do Not Approach Labels" } },
	{ Name = "Field Support", StartingItems = { "Portable Beacon", "Spare Battery Pack", "Ration Brick (unflavored)", "Folded Emergency Blanket" } },
	{ Name = "Specimen Care", StartingItems = { "Feeding Schedule Card", "Treat Pouch (contents unknown)", "Calming Spray (universal, allegedly)" } },

	-- Corporate absurdity (light humor)
	{ Name = "Cafeteria Compliance", StartingItems = { "MysteryMeat", "Sanitation Checklist Card", "Food Allergen Scanner Wand", "‘Approved Tray’ Stamp" } },
	{ Name = "Hazard Labeling", StartingItems = { "Warning Label Maker", "High-Visibility Tape Roll", "Icon Stencil Sheet", "Adhesive Remover Wipes" } },
	{ Name = "Interdepartmental Coordination", StartingItems = { "Meeting Token (non-transferable)", "Escalation Flowchart Card", "Spare Lanyard Clip", "‘Per My Last Email’ Template Sheet" } },
	{ Name = "Facilities and Structural Integrity", StartingItems = { "Structural Tape Measure", "Bolt Assortment Tin", "Panel Rattle Wedge", "Maintenance Flashlight" } },
	{ Name = "Access Control Oversight", StartingItems = { "Badge Protector Sleeve", "Checkpoint Log Card", "Door Override Request Form", "Keyring of ‘Not These Keys’" } },

	-- Science & tech
	{ Name = "Applied Anomaly Research", StartingItems = { "Calibration Prism", "Sample Vial Set", "Field Notes Binder", "Nonconductive Tweezers" } },
	{ Name = "Systems Diagnostics", StartingItems = { "Diagnostic Probe (offline)", "Spare Fuse Roll", "Error Code Quick-Reference", "Contact Cleaner" } },
	{ Name = "Experimental Engineering", StartingItems = { "Prototype Tag (do not lose)", "Spare Fasteners Pack", "Mini Multi-tool", "Schematic Printout (folded wrong)" } },
	{ Name = "Reality Stabilization", StartingItems = { "Stability Meter (reads ‘maybe’)", "Grounding Strap", "Rift Chalk (do not inhale)", "Calibration Dial Key" } },

	-- Security & risk
	{ Name = "Incident Review", StartingItems = { "Redaction Marker", "Incident Tally Clicker", "Evidence Bag (empty)", "‘Observe Only’ Badge Clip" } },
	{ Name = "Threat Assessment", StartingItems = { "Pocket Threat Guide (laminated)", "Severity Color Card", "Mini Binoculars", "Caution Tape Roll" } },
	{ Name = "Internal Security Liaison", StartingItems = { "Checkpoint Notebook", "Earpiece (one-sided)", "Wrist Restraint Zip-Tie (for cables)", "Visitor Sticker Pack" } },
	{ Name = "Emergency Response Planning", StartingItems = { "Evac Map Chip", "Glow Stick Pack", "Compression Bandage", "Emergency Whistle Beacon" } },

	-- Data & paperwork hell
	{ Name = "Records and Archival Services", StartingItems = { "Archive Gloves", "Index Tab Set", "Document Scanner Token", "Stapler (industrial)" } },
	{ Name = "Regulatory Alignment", StartingItems = { "Compliance Checklist Card", "Policy Binder (thin, suspiciously)", "Signature Stamp Pad", "‘Approved Language’ Phrase Sheet" } },
	{ Name = "Audit Preparation", StartingItems = { "Audit Trail Worksheet", "Spare Forms Packet", "Numbered Sticker Roll", "Coffee Voucher (one use)" } },
	{ Name = "Documentation Recovery", StartingItems = { "Magnetic Clip Board", "Data Shard Sleeve", "Paperclip Brick", "‘Please Reprint’ Request Form" } },

	-- Field-adjacent / intern-heavy
	{ Name = "Survey and Recon", StartingItems = { "Survey Marker Spikes", "Rangefinder (sticky button)", "Map Grid Card", "Lens Cloth" } },
	{ Name = "Equipment Staging", StartingItems = { "Cable Tie Bundle", "Label Tags (blank)", "Tool Checkout Slip", "Spare Gloves (mismatched)" } },
	{ Name = "Environmental Monitoring", StartingItems = { "Pocket Air Quality Sensor", "Thermal Strip Set", "Radiation Badge (inactive)", "Sample Swab Kit" } },
	{ Name = "Post-Incident Cleanup", StartingItems = { "Disposable Coveralls", "Biohazard Bag Roll", "Decon Wipes", "Odor Neutralizer Spray" } },
}

StoryData.InternReasons = {
	{
		Through = "mandatory college credit",
		Because = "you needed the credits",
		To = "get your credits",
	},
	{
		Through = "court-ordered career counseling",
		Because = "someone in authority decided you needed structure",
		To = "prove you could stick with something",
	},
	{
		Through = "a scholarship you definitely didn’t read the fine print on",
		Because = "the paperwork got you before you got the paperwork",
		To = "keep the scholarship from disappearing",
	},
	{
		Through = "repaying a used shuttle loan",
		Because = "you needed to pay off a debt",
		To = "pay off your shuttle loan",
	},
	{
		Through = "signing up out of spite",
		Because = "you were tired of being the punchline",
		To = "prove your family wrong",
	},
	{
		Through = "an aggressive recruiter",
		Because = "because the recruiter told you all about the money and nothing about being in constant danger",
		To = "fullfill your duty",
	},
}


StoryData.Mishaps = {
	-- Paperwork vs reality
	"accidentally filed a sentient toaster as office equipment",
	"misclassified a minor anomaly as ‘decorative’",
	"triggered a compliance audit by answering a question too honestly",
	"used the wrong form and created three new forms to fix it",

	-- Tech & systems
	"tested a prototype door that opens into last Tuesday",
	"rebooted a system that very clearly asked not to be rebooted",
	"patched a security terminal and locked out everyone, including yourself",
	"connected two devices that were never meant to acknowledge each other",

	-- Anomalies & weird science
	"sealed a minor rift with duct tape and confidence",
	"mistook a containment field for a charging station",
	"released something harmless that immediately became curious",
	"stabilized an anomaly by doing exactly the opposite of the instructions",

	-- Physical danger
	"mistook a gravity well for a beanbag chair",
	"stood in the wrong place during a controlled decompression drill",
	"rode an emergency lift that skipped three safety stops",
	"misjudged the weight of a crate labeled ‘mostly empty’",

	-- Social / HR disasters
	"brought a ‘pet’ that turned out to be a corporate auditor",
	"gave a tour to someone who definitely wasn’t cleared for it",
	"won an argument with security and regretted it immediately",
	"accidentally became the point person for an incident you didn’t cause",

	-- Mining / industrial specific
	"ignored a tremor alert that everyone else knew to respect",
	"followed a maintenance tunnel that stopped existing halfway through",
	"activated heavy machinery in the wrong gravity orientation",

	-- Starhop / high-security flavor
	"walked through the wrong checkpoint and learned how fast doors can close",
	"set off a scanner that refused to explain why",
	"was escorted somewhere and told not to worry about it",
}

-- All quirks are valid after "you ..." OR start with "are "
StoryData.PersonalQuirks = {
	{
		Text = "name every tool like it’s a coworker",
		StartingItems = { "Hex Driver", "10 Bolts" },
	},
	{
		Text = "collect expired access badges like they’re trophies",
		StartingItems = { "Green Security Card",},
	},
	{
		Text = "refuse to trust anything without at least two warning labels",
		StartingItems = { "Warning Stickers", },
	},
	{
		Text = "keep a ‘totally normal’ notebook full of conspiracy diagrams",
		StartingItems = { "Totally Normal Pocket Notebook", "Pen",},
	},
	{
		Text = "carry an inspirational clipboard everywhere",
		StartingItems = { "Inspirational Clipboard", "Paperclip" },
	},
	{
		Text = "apologize to machines before restarting them",
		StartingItems = { "5 Power Cells" },
	},
	{
		Text = "label your lunch as ‘classified’ just to see who flinches",
		StartingItems = { "Lunchbox" },
	},
	{
		Text = "insist on doing a ‘vibe check’ before entering restricted halls",
		StartingItems = { "Mood Ring", }, --Armor 1
	},
	{
		Text = "are weirdly calm during alarms, which makes everyone else nervous",
		StartingItems = { "Stress Ball" }, --For hitting people with who you are stressed out by
	},

	{
		Text = "talk through procedures out loud, even when alone",
		StartingItems = { "Sci-Co Handbook" }, --Info
	},
	{
		Text = "refuse to sit with your back to a doorway",
		StartingItems = { "Perception Augmentation 1" },
	},
	{
		Text = "rate alarms by how concerned you should actually be",
		StartingItems = { "Watch" }, --Armor 1
	},
	{
		Text = "treat maintenance bots like coworkers with seniority",
		StartingItems = { "Bleeper Bot Training Level 2" }, --Start at level 2
	},
	{
		Text = "avoid stepping on floor panels that look ‘too new’",
		StartingItems = { "Caution Tape Strip"}, --Toy
	},
	{
		Text = "never throw anything away until it’s failed at least twice",
		StartingItems = { "10 Bolts","Bleeper Bot Decoupler" }, --Needed for building bot
	},
	{
		Text = "have a favorite pen and noticeably worse handwriting without it",
		StartingItems = { "Pen" }, --Toy
	},
	{
		Text = "carry more access cards than you technically need",
		StartingItems = { "Green Security Card" },
	},
	{
		Text = "prefer manual overrides even when automation works fine",
		StartingItems = { "HexDriver" },
	},
	{
		Text = "keep a map of where the nearest exit probably is",
		StartingItems = { "Map" },
	},
	{
		Text = "always stand where you can see the whole room",
		StartingItems = { "Field Analyzer", "Flashlight" },
	},
}

return StoryData
