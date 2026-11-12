--[[
	EconomyConfig.lua
	Shared configuration for the dynamic trade economy system.
	Place in ReplicatedStorage so both server and client can access.
	
	SYSTEM OVERVIEW:
	- Each station/planet has a production/consumption profile
	- Prices shift dynamically based on local supply vs demand
	- Sci Co sets floor/ceiling prices (the "corporate rate")
	- Players profit by transporting goods from surplus to deficit locations
	- Events (plagues, wars, blockades) temporarily alter demand
]]

local EconomyConfig = {}

------------------------------------------------------------------------
-- COMMODITY DEFINITIONS
-- basePrice  = galactic average (used as reference for Sci Co rates)
-- weight     = cargo units per 1 quantity (affects ship capacity)
-- category   = grouping for UI and trade permits
-- illegal    = true if contraband (no Sci Co trading, black market only)
-- perishable = decay rate per minute (0 = doesn't decay)
------------------------------------------------------------------------

EconomyConfig.Commodities = {
	-- RAW MATERIALS
	IronOre = {
		displayName = "Iron Ore",
		basePrice = 10,
		weight = 2,
		category = "RawMaterials",
		illegal = false,
		perishable = 0,
		description = "Common metallic ore. Foundation of most manufacturing.",
	},
	TitaniumOre = {
		displayName = "Titanium Ore",
		basePrice = 25,
		weight = 2,
		category = "RawMaterials",
		illegal = false,
		perishable = 0,
		description = "Durable ore used in advanced hull plating and weapons.",
	},
	CrystalShard = {
		displayName = "Crystal Shard",
		basePrice = 60,
		weight = 1,
		category = "RawMaterials",
		illegal = false,
		perishable = 0,
		description = "Rare crystalline formations. Essential for energy systems.",
	},
	Ooze = {
		displayName = "Interdimensional Ooze",
		basePrice = 200,
		weight = 3,
		category = "RawMaterials",
		illegal = true,
		perishable = 0.01, -- slowly destabilizes
		description = "Dangerous extradimensional substance. Highly regulated.",
	},

	-- REFINED MATERIALS
	SteelPlate = {
		displayName = "Steel Plate",
		basePrice = 30,
		weight = 3,
		category = "RefinedMaterials",
		illegal = false,
		perishable = 0,
		description = "Processed iron. Standard construction material.",
	},
	TitaniumAlloy = {
		displayName = "Titanium Alloy",
		basePrice = 65,
		weight = 3,
		category = "RefinedMaterials",
		illegal = false,
		perishable = 0,
		description = "Military-grade alloy for armor and ship components.",
	},
	PowerCell = {
		displayName = "Power Cell",
		basePrice = 80,
		weight = 1,
		category = "RefinedMaterials",
		illegal = false,
		perishable = 0,
		description = "Refined crystal energy cells. Powers most technology.",
	},

	-- CONSUMER GOODS
	FoodRation = {
		displayName = "Food Ration",
		basePrice = 15,
		weight = 1,
		category = "ConsumerGoods",
		illegal = false,
		perishable = 0.005, -- spoils slowly
		description = "Standard nutritional packs. Every station needs them.",
	},
	MedSupply = {
		displayName = "Medical Supplies",
		basePrice = 40,
		weight = 1,
		category = "ConsumerGoods",
		illegal = false,
		perishable = 0,
		description = "Medicines, surgical tools, and biotech supplies.",
	},
	LuxuryGoods = {
		displayName = "Luxury Goods",
		basePrice = 100,
		weight = 1,
		category = "ConsumerGoods",
		illegal = false,
		perishable = 0,
		description = "High-end consumer products. Popular on wealthy stations.",
	},

	-- MANUFACTURED / MILITARY
	WeaponParts = {
		displayName = "Weapon Components",
		basePrice = 70,
		weight = 2,
		category = "Military",
		illegal = false,
		perishable = 0,
		description = "Precision-machined parts for weapon manufacturing.",
	},
	ShipParts = {
		displayName = "Ship Components",
		basePrice = 90,
		weight = 4,
		category = "Military",
		illegal = false,
		perishable = 0,
		description = "Engines, hull plates, avionics modules.",
	},
	Contraband = {
		displayName = "Contraband",
		basePrice = 150,
		weight = 1,
		category = "BlackMarket",
		illegal = true,
		perishable = 0,
		description = "Assorted illegal goods. Don't ask what's inside.",
	},
}

------------------------------------------------------------------------
-- SCI CO CORPORATE PRICING
-- The corporation sets price floors and ceilings as a percentage of
-- the current local price. Players always have the option to sell to
-- Sci Co at the floor or buy from Sci Co at the ceiling.
-- This prevents total market collapse and ensures newbies can trade.
------------------------------------------------------------------------

EconomyConfig.SciCo = {
	-- Sci Co buys from players at this % of local market price (floor)
	buyRatePercent = 0.70,  -- 70% of market price (they lowball you)
	-- Sci Co sells to players at this % above local market price (ceiling)
	sellMarkupPercent = 1.40, -- 140% of market price (they gouge you)
	-- Transaction tax on all Sci Co trades
	taxPercent = 0.05, -- 5% corporate tax
	-- Sci Co won't trade illegal goods at all
	tradesIllegal = false,
}

------------------------------------------------------------------------
-- PRICE DYNAMICS
------------------------------------------------------------------------

EconomyConfig.PriceDynamics = {
	-- How much a single delivery shifts the price (per unit delivered)
	deliveryImpact = 0.002,     -- 0.2% price drop per unit delivered
	-- How much natural consumption raises prices over time
	consumptionDrift = 0.001,   -- 0.1% price rise per tick when deficit
	-- Price can't go below this % of base price
	minPricePercent = 0.25,     -- 25% floor
	-- Price can't go above this % of base price
	maxPricePercent = 4.0,      -- 400% ceiling
	-- How fast prices drift back toward equilibrium (per tick)
	equilibriumPull = 0.0005,   -- slow drift back to normal
	-- Tick interval in seconds
	tickInterval = 60,          -- economy updates every 60 seconds
}

------------------------------------------------------------------------
-- STATION / PLANET DEFINITIONS
-- Each station has:
--   produces = commodities it generates (surplus → cheap here)
--   consumes = commodities it needs (deficit → expensive here)
--   priceModifiers = starting price multiplier per commodity
--   supply = current stock levels (initialized at runtime)
------------------------------------------------------------------------

EconomyConfig.Stations = {
	-- MINING COLONY In Space
	KraggPrime = {
		displayName = "Kragg Prime Mining Colony",
		type = "Mining",
		description = "Deep-core mining operation built inside a giant asteroid",
		produces = {
			Ultrium = { rate = 5, capacity = 500 },    -- Laser resistant hulls
			Abyssium = { rate = 2, capacity = 200 },    -- Super-dense armor
			KraggCrystalShard = { rate = 3, capacity = 300 }, -- Superconductor cores for reactive armor
		},
		consumes = {
			FoodRation = { rate = 3, capacity = 300 },
			Water = { rate = 3, capacity = 300 },
			MiningDrillBit = { rate = 1, capacity = 50 }, --Mining Drills
			LargeMedKit = { rate = 2, capacity = 100 },
			IllegalNaniteMuscles = { rate = 1, capacity = 50 },
		},
		priceModifiers = {
			LargeMedKit = 1.1,
			MiningDrillBit = 1.4,
			IllegalNaniteMuscles = 1.5,
		},
	},

	-- REFINERY STATION In Space
	RyanicStation = {
		displayName = "Ryanic Refinery Station",
		type = "Refinery",
		description = "Orbital refinery complex. Turns raw ore into alloys and components.",
		produces = {
			AbyssiumAlloy = { rate = 3, capacity = 300 }, -- Super-dense Armor crafting component
			UltriumPlating = { rate = 1.5, capacity = 150 },
			PowerCell = { rate = 1, capacity = 100 },
		},
		consumes = {
			Abyssium = { rate = 4, capacity = 400 },
			Ultrium = { rate = 2, capacity = 200 },
			Meganite = { rate = 1, capacity = 100 },
			Oomphium = { rate = 1, capacity = 50 },
			FoodRation = { rate = 2, capacity = 200 },
			Water = { rate = 2, capacity = 200 },
		},
		priceModifiers = {
			Abyssium = 1.6,
			Ultrium = 1.4,
			Meganite = 1.3,
			Oomphium = 1.4,   
		},
	},

	-- MANUFACTURING HUB on Planet Forge
	Forge = {
		displayName = "Forge Manufacturing Hub",
		type = "Manufacturing",
		description = "An industrial hellscape dedicated entirely to manufacturing. The atmosphere is thick with particulates from endless factories. Sci Co's major shipyards and equipment production facilities operate in three shifts that never stop. Worker mortality rates are classified.",
		produces = {
			PlasmaCoil = { rate = 2, capacity = 200 }, --Crafting
			LaserDiode = { rate = 1.5, capacity = 150 }, --Crafting
			TeslaCoil = { rate = 1, capacity = 100 }, --Crafting
			Bullets = { rate = 3, capacity = 300 }, --Kinetic Ammo
			MiniRockets = { rate = 2, capacity = 200 }, --Rocket Guantlet Ammo
			
		},
		consumes = {
			Meganite = { rate = 3, capacity = 300 },
			Oomphium  = { rate = 2, capacity = 200 },
			PowerCell = { rate = 1.5, capacity = 150 },
			FoodRation = { rate = 2, capacity = 200 },
			Water = { rate = 2, capacity = 200 },
			IllegalNueroBoost = { rate = 1, capacity = 100 },
		},
		priceModifiers = {
			Meganite = 1.2,
			Oomphium = 1.2,
			PowerCell = 1.1,
			FoodRation = 1.1,
			Water = 1.1,
			IllegalNueroBoost = 1.3,
			PlasmaCoil = .7,
			LaserDiode = .8,
			TeslaCoil = .8,
			Bullets = .4,
			MiniRockets =.6,
		},
	},

	---- AGRICULTURAL WORLD
	--VerdenFields = {
	--	displayName = "Verden Fields Agricultural Colony",
	--	type = "Agricultural",
	--	description = "Lush garden world. Breadbasket of the sector.",
	--	produces = {
	--		FoodRation = { rate = 8, capacity = 800 },
	--		MedSupply = { rate = 2, capacity = 200 },
	--	},
	--	consumes = {
	--		SteelPlate = { rate = 1, capacity = 100 },
	--		WeaponParts = { rate = 0.5, capacity = 50 },
	--		ShipParts = { rate = 0.5, capacity = 50 },
	--		LuxuryGoods = { rate = 1, capacity = 100 },
	--	},
	--	priceModifiers = {
	--		FoodRation = 0.4,    -- dirt cheap here
	--		MedSupply = 0.7,
	--		SteelPlate = 1.3,
	--		WeaponParts = 1.4,
	--		ShipParts = 1.5,
	--		LuxuryGoods = 1.6,
	--	},
	--},

	---- MILITARY OUTPOST
	--FortVanguard = {
	--	displayName = "Fort Vanguard Military Outpost",
	--	type = "Military",
	--	description = "Frontier defense station. Always hungry for supplies.",
	--	produces = {
	--		-- Military produces salvage-type goods (handled separately)
	--	},
	--	consumes = {
	--		WeaponParts = { rate = 3, capacity = 300 },
	--		ShipParts = { rate = 2, capacity = 200 },
	--		FoodRation = { rate = 4, capacity = 400 },
	--		MedSupply = { rate = 2, capacity = 200 },
	--		TitaniumAlloy = { rate = 1, capacity = 100 },
	--	},
	--	priceModifiers = {
	--		WeaponParts = 1.8,   -- military pays premium
	--		ShipParts = 1.7,
	--		FoodRation = 1.6,
	--		MedSupply = 1.8,
	--		TitaniumAlloy = 1.5,
	--	},
	--},

	-- LUXURY / TRADE HUB In Space
	StarhopStation = {
		displayName = "Starhop Trade Station",
		type = "TradeHub",
		description = "Bustling trade hub. Everything is for sale. Everything.",
		produces = {
			SandwormSilkLining = { rate = 2, capacity = 200 }, --for use in Armor crafting
			IllegalMemoryImplant = { rate = 1, capacity = 50 }, --for use in Crafting
			IllegalNueroBoost = { rate = 0.5, capacity = 50 }, --Brains + 1 consumable
			IllegalNaniteMuscles = { rate = 0.5, capacity = 50 }, --Strength + 1 consumable
			IllegalDataCartridge = { rate = 0.1, capacity = 50 }, --Pure resale
			FakeID = { rate = 0.1, capacity = 50 }, --Fake ID
			GreenAccessCard = { rate = 0.1, capacity = 50 }, --Green Access Card
		},
		consumes = {
			-- Trade hubs consume a little of everything
			FoodRation = { rate = 3, capacity = 300 },
			SmallMedKit = { rate = 1, capacity = 100 },
			PowerCell = { rate = 1, capacity = 100 },
			SandwormSilk = { rate = 2, capacity = 100 },
		},
		priceModifiers = {
			PowerCell = 1.1,    -- cheapest place to buy illegal goods
			SmallMedKit = 1.2,
			FoodRation = 1.1,
		},
	},

	-- Desert World on Planet
	Whispral = {
		displayName = "Whispral",
		type = "Exotic",
		description = "Desert planet with infinite dunes guarded by giant sandworms",
		produces = {
			Meganite = { rate = 3, capacity = 300 }, -- For Ship Hulls
			Oomphium = { rate = 2, capacity = 200 }, -- For Armor
			SandwormSilk = { rate = 1, capacity = 100 }, -- For Armor Lining
		},
		consumes = {
			FoodRation = { rate = 2, capacity = 200 },
			Water = { rate = 3, capacity = 200 },
			SmallMedKit = { rate = 1, capacity = 100 },
			MediumMedKit = { rate = 1, capacity = 100 },
		},
		priceModifiers = {
			Meganite = 0.3,
			Oomphium = 0.5,
			SandwormSilk = .7,
			FoodRation = 1.2,
			Water = 1.4,
			MedSupply = 1.3,
			SmallMedKit = 1.1,
			MediumMedKit = 1.2,
		},
	},
}

------------------------------------------------------------------------
-- ECONOMY EVENTS
-- Random or triggered events that modify station demand/prices.
-- duration = seconds the event lasts
------------------------------------------------------------------------

EconomyConfig.Events = {
	Plague = {
		displayName = "Plague Outbreak",
		description = "A deadly virus has broken out! Medical supplies desperately needed.",
		priceEffects = {
			MedSupply = 3.0,     -- 3x price multiplier
			FoodRation = 1.5,
		},
		duration = 600,          -- 10 minutes
		applicableTo = { "Mining", "Agricultural", "Exotic" },
	},
	WarEscalation = {
		displayName = "War Escalation",
		description = "Conflict intensifies! Military stations need weapons and materials.",
		priceEffects = {
			WeaponParts = 2.5,
			TitaniumAlloy = 2.0,
			ShipParts = 2.0,
			MedSupply = 1.5,
		},
		duration = 480,
		applicableTo = { "Military" },
	},
	Famine = {
		displayName = "Crop Failure",
		description = "Harvest devastated. Food prices skyrocket across the sector.",
		priceEffects = {
			FoodRation = 3.5,
		},
		duration = 720,
		applicableTo = { "Agricultural" }, -- ironic: hits the food producer
	},
	PirateBlockade = {
		displayName = "Pirate Blockade",
		description = "Pirates blockading trade routes! All goods in short supply.",
		priceEffects = {
			FoodRation = 2.0,
			MedSupply = 2.0,
			SteelPlate = 1.5,
			WeaponParts = 1.5,
		},
		duration = 300,
		applicableTo = { "TradeHub", "Refinery", "Manufacturing" },
	},
	CrystalBoom = {
		displayName = "Crystal Resonance Surge",
		description = "Unusual psionic activity has amplified crystal growth.",
		priceEffects = {
			CrystalShard = 0.4,  -- price drops (glut)
			PowerCell = 0.6,
		},
		duration = 360,
		applicableTo = { "Exotic" },
	},
	OozeIncursion = {
		displayName = "Interdimensional Rift",
		description = "A rift has opened! Ooze seeping into local space. Danger... and profit.",
		priceEffects = {
			Ooze = 0.5,         -- ooze becomes more available
			MedSupply = 2.0,    -- casualties mount
		},
		duration = 240,
		applicableTo = { "Mining", "Military", "Exotic" },
	},
}

------------------------------------------------------------------------
-- TRADE SKILL BONUSES
-- Players with higher trade/logistics skills get better rates.
-- These stack with the base prices.
------------------------------------------------------------------------

EconomyConfig.SkillBonuses = {
	-- Skill level thresholds and their bonus
	-- e.g., a player with Trading skill 50 gets 5% better prices
	Trading = {
		{ threshold = 20, bonus = 0.02 },   -- 2% better prices
		{ threshold = 40, bonus = 0.05 },   -- 5%
		{ threshold = 60, bonus = 0.08 },   -- 8%
		{ threshold = 80, bonus = 0.12 },   -- 12%
		{ threshold = 95, bonus = 0.15 },   -- 15% (master trader)
	},
	-- Hauling skill affects how much cargo you can carry (separate system)
	-- Negotiation skill for black market deals (separate system)
}

------------------------------------------------------------------------
-- TRADE ROUTE DANGER RATINGS
-- Used to calculate risk/reward for route suggestions in UI
------------------------------------------------------------------------

EconomyConfig.DangerRatings = {
	Safe = { multiplier = 1.0, description = "Patrolled lanes. Low risk." },
	Moderate = { multiplier = 1.2, description = "Occasional pirate activity." },
	Dangerous = { multiplier = 1.5, description = "Frequent hostiles. Travel armed." },
	Lawless = { multiplier = 2.0, description = "No patrols. Expect trouble." },
}

-- Route danger between stations (bidirectional)
EconomyConfig.RouteDanger = {
	["KraggPrime-SolaceStation"] = "Safe",
	["KraggPrime-VerdenFields"] = "Moderate",
	["KraggPrime-FortVanguard"] = "Dangerous",
	["SolaceStation-NovaTech"] = "Safe",
	["SolaceStation-NeonBazaar"] = "Moderate",
	["NovaTech-FortVanguard"] = "Safe",
	["NovaTech-NeonBazaar"] = "Moderate",
	["VerdenFields-NeonBazaar"] = "Moderate",
	["VerdenFields-MiragiNexus"] = "Dangerous",
	["FortVanguard-MiragiNexus"] = "Lawless",
	["NeonBazaar-MiragiNexus"] = "Dangerous",
}

-- Helper to get danger for any route (checks both directions)
function EconomyConfig.GetRouteDanger(stationA, stationB)
	local key1 = stationA .. "-" .. stationB
	local key2 = stationB .. "-" .. stationA
	local danger = EconomyConfig.RouteDanger[key1] or EconomyConfig.RouteDanger[key2]
	return danger or "Moderate" -- default if route not defined
end

return EconomyConfig