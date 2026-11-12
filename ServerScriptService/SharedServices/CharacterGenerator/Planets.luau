-- Planets.lua
local Planets = {}

Planets.List = {
	{
		Name = "Vega Minor",
		Terrain = "wind-scoured mesas and salt flats",
		Climate = "a sky that was always too bright and too open",
		Trade = "survey work and mineral prospecting",
		CultureFlavor = "nobody wasted words, and everyone carried goggles whether they needed them or not",
		StartingItems = { "Desert Wrap Cloth", "Cracked Compass" }, --Armor 1 or junk value 1
	},
	{
		Name = "Kestrel-9",
		Terrain = "sky-reefs and hanging cliff towns",
		Climate = "storms that rolled in without warning",
		Trade = "aerial shipping and emergency response",
		CultureFlavor = "people learned to decide fast and apologize later",
		StartingItems = { "Poncho", "Grappling Hook", "Wind-Shear Goggles", "Reviving Gel" }, --Armor 1, tool, can revive fallen teammate
	},
	{
		Name = "Glimmerhold Station",
		Terrain = "stacked corridors, maintenance shafts, and forgotten decks",
		Climate = "recycled air and flickering artificial daylight",
		Trade = "repairs, salvage brokerage, and unofficial favors",
		CultureFlavor = "everyone knew a shortcut, and nobody asked why you needed it",
		StartingItems = { "10 Bolts","Salvage Kit" },
	},
	{
		Name = "Starhop Station",
		Terrain = "a massive torus of security corridors, transit rings, and layered maintenance decks",
		Climate = "sterile air recycled a thousand times over, punctuated by controlled gravity shifts",
		Trade = "interstellar commerce, customs brokerage, and the movement of everything that matters",
		CultureFlavor = "nothing happened without clearance, and everyone learned which cameras to ignore and which ones never blinked",
		StartingItems = { "10 Credits" },
	},
	{
		Name = "Ironfall Deep",
		Terrain = "hollowed asteroid caverns, reinforced shafts, and kilometer-deep extraction tunnels",
		Climate = "thin dusty air, constant vibration, and a background hum that never truly stops",
		Trade = "deep-core mining, raw ore processing, and contract extraction work",
		CultureFlavor = "people trusted the walls more than the stars, and everyone learned which tremors were normal and which meant run",
		StartingItems = { "Emergency Patch Kit", "Pet Rock" },
	},
	{
		Name = "Orchid Prime",
		Terrain = "lush biomes and greenhouse megacities",
		Climate = "warm air thick with moisture and pollen",
		Trade = "biotech cultivation and nutrient processing",
		CultureFlavor = "politeness was expected, but intensity lived just under the surface",
		StartingItems = { "Pollen Filter Wipe", "Sterile Nutrient Gel Pack", "Plant-ID Strip (works… mostly)", "Small Vial of ‘Premium Oxygen’" },
	},
	{
		Name = "Rustmoon",
		Terrain = "industrial ruins and red dust basins",
		Climate = "cold nights broken by the heat of active machinery",
		Trade = "scrap refining and heavy fabrication",
		CultureFlavor = "honesty mattered more than comfort, and tools were treated better than excuses",
		StartingItems = { "Work Gloves (still stiff)", "Mini Rivet Kit", "Impact Wrench Attachment", "Scrap Token (redeemable somewhere, allegedly)" },
	},
	{
		Name = "Ionos",
		Terrain = "magnetized badlands and glowing aurora fields",
		Climate = "skies that crackled with constant electrical tension",
		Trade = "energy capture and field stabilizer maintenance",
		CultureFlavor = "engineers trusted superstition almost as much as their math",
		StartingItems = { "Static Discharge Strap", "Insulated Cable Tie Bundle", "Field-Stabilizer Charm (not endorsed)", "Mini Compass (spins sometimes)" },
	},
	{
		Name = "Galactic Archives on Planet Zetron 4",
		Terrain = "ice tunnels and archival vaults",
		Climate = "permanent cold and administrative silence",
		Trade = "compliance work, record keeping, and long-term storage",
		CultureFlavor = "nothing moved quickly, and every signature had consequences",
		StartingItems = { "Thermal Hand Warmer Pack", "Archive Keycard Sleeve", "Stamped Duplicate Form (blank)", "Microfilm Reader Token (non-refundable)" },
	},
}

return Planets
