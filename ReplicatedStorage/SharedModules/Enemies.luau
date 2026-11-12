--gruntHealth = math.round(math.pow(level/.4,2+(level/50)) ) unique less than 2 multiple (1.1 for example)
--rank makes health number of levels above level .  

--1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss

--level 1 rank 1 = level 1 health +0
--level 1 rank 2 = level 2 health + 1
--level 1 rank 3 = level 4 health + 3
--level 1 rank 4 = level 7 health + 6
--level 1 rank 5 = level 11 health + 10


--types (mostly effects loot whitelist)
--Humanoid
--Animal
--Insect
--Machine
--Plant


--grunt base health at each level.
-- 08:15:16.448  1 6  -  Client - Startup:50
--08:15:16.449  2 27  -  Client - Startup:50
--08:15:16.449  3 63  -  Client - Startup:50
--08:15:16.449  4 120  -  Client - Startup:50
--08:15:16.449  5 201  -  Client - Startup:50
--08:15:16.449  6 311  -  Client - Startup:50
--08:15:16.449  7 457  -  Client - Startup:50
--08:15:16.449  8 646  -  Client - Startup:50
--08:15:16.450  9 887  -  Client - Startup:50
--08:15:16.450  10 1190  -  Client - Startup:50
--08:15:16.450  11 1568  -  Client - Startup:50
--08:15:16.450  12 2036  -  Client - Startup:50
--08:15:16.450  13 2611  -  Client - Startup:50
--08:15:16.451  14 3315  -  Client - Startup:50
--08:15:16.451  15 4171  -  Client - Startup:50
--08:15:16.451  16 5209  -  Client - Startup:50
--08:15:16.451  17 6463  -  Client - Startup:50
--08:15:16.451  18 7972  -  Client - Startup:50
--08:15:16.451  19 9784  -  Client - Startup:50
--08:15:16.452  20 11954  -  Client - Startup:50
--08:15:16.452  21 14547  -  Client - Startup:50
--08:15:16.452  22 17639  -  Client - Startup:50
--08:15:16.452  23 21320  -  Client - Startup:50
--08:15:16.452  24 25693  -  Client - Startup:50
--08:15:16.452  25 30882  -  Client - Startup:50
--08:15:16.452  26 37029  -  Client - Startup:50
--08:15:16.453  27 44303  -  Client - Startup:50
--08:15:16.453  28 52899  -  Client - Startup:50
--08:15:16.453  29 63048  -  Client - Startup:50
--08:15:16.453  30 75017  -  Client - Startup:50
--08:15:16.453  31 89119  -  Client - Startup:50
--08:15:16.453  32 105720  -  Client - Startup:50
--08:15:16.453  33 125247  -  Client - Startup:50
--08:15:16.453  34 148198  -  Client - Startup:50
--08:15:16.454  35 175155  -  Client - Startup:50
--08:15:16.454  36 206795  -  Client - Startup:50
--08:15:16.454  37 243909  -  Client - Startup:50
--08:15:16.454  38 287420  -  Client - Startup:50
--08:15:16.454  39 338402  -  Client - Startup:50
--08:15:16.454  40 398107  -  Client - Startup:50
--08:15:16.454  41 467995  -  Client - Startup:50
--08:15:16.455  42 549766  -  Client - Startup:50
--08:15:16.455  43 645399  -  Client - Startup:50
--08:15:16.455  44 757201  -  Client - Startup:50
--08:15:16.455  45 887856  -  Client - Startup:50
--08:15:16.455  46 1040489  -  Client - Startup:50
--08:15:16.455  47 1218741  -  Client - Startup:50
--08:15:16.455  48 1426844  -  Client - Startup:50
--08:15:16.456  49 1669727  -  Client - Startup:50
--08:15:16.456  50 1953125  -  Client - Startup:50

--max base damage of common equal to mob level weapon
--(average mob health at that level * .10) - (level*level)
--level 10 mob health 1190 * .10 = 119*(.048*(Rarity*Rarity*Rarity)) - 100 = 19 (at best killing unarmored mob after 10 hits with level 10 common weapon)
-- common 1, uncommon 2, rare, 3, epic 4, legendary 5 
--so 19 max damage with level 10 common 1%  Rarity level 0   (10 hits)
-- 20 max damage with level 10 uncommon 4% Rarity level 1   (10 hits)
-- 26 max damage with level 10 rare 20% 38% Rarity level 2    (5 hits)
-- 43 max damage with level 10 epic 30% 130%   Rarity level 3 (3 hits)
-- 57 max damage with level 10 legendary 300% Rarity level 4  (2 hits)

local module = {

	enemies = {};

	--Level 1 Grunt
	--Health Adjusted
	["Mouse"] = {
		Name = "Mouse",
		Type= "Animal",
		Level = 1,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 8
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"Killed by Mickey","Killed by a squeek toy"},
		Loot = {"Twine","Cheese"},
		NothingMessage="Nope nothing there",
		Attacks = {
			{Name="LittleBite",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Run",
			["Run"]="Run",
			["TakeHit"]="Idle",
			["Die"]="Idle",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 5,
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=16,
		RunSpeed=30,
		HipHeight = .2,
		Search = false,
		Face = 0, --no face
	};

	--Health Adjusted
	["Rat"] = {
		Name = "Rat",
		Type= "Animal",
		Level = 1,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 10
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"Rats","How embarrassing"},
		Loot = {"RatMeat","Cheese"},
		NothingMessage="You found nothing any sane person would want to salvage from the corpse of a rat",
		Attacks = {
			{Name="Bite",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Bite"]="Attack",
			["Walk"]="Run",
			["Run"]="Run",
			["TakeHit"]="Idle",
			["Die"]="Idle",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=16,
		RunSpeed=20,
		HipHeight = 1, --was 1.3
		Search = false,
		Face = 0, --no face
	};

	--Level 1 Experienced

	--Level 1 Elite
	--ACTIVE--
	--Health Adjusted
	["ToxicRat"] = {
		Name = "Toxic Rat",
		Type= "Animal",
		Level = 1,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 556 --56
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		AttackDamageMin = 4,
		AttackDamageMax = 5,
		Deaths = {"Bio Hazard","Had one bad idea"},
		Loot = {"ToxicRatMeat","ToxicRatTooth"},
		NothingMessage="So even when the rat is glowing you still will search it's corpse. Nice.",
		Attacks = {
			{Name="Bite",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Run",
			["Run"]="Run",
			["TakeHit"]="Idle",
			["Die"]="Idle",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 4,
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=16,
		RunSpeed=16,
		HipHeight = 0,
		Search = false,
		Face = 0, --no face
	};

	--Level 2 Grunt


	["Chicken"] = {
		Name = "Chicken",
		Type= "Animal",
		Level = 2,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		MaxHealth = 28,
		MaxShield = 0,
		MaxArmor = 0,
		Health = {
			main = 28
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 6,
		RangeAttack = "ChickenEggCannon",
		Deaths = {"Don't Be A Chicken","Chicken Feed"},
		Loot = {"Egg","RawChicken"},
		NothingMessage="Just picking through its corpse like it's an Egg hunt eh?",
		Attacks = {
			{Name="Peck",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle2",
			["Idle3"]="Idle3",
			["Idle4"]="Idle4",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Peck"]="Peck",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="Idle",
			["Die"]="Idle",
			["WingsIdle"]="WingsIdle",
			["WingsFlap"]="WingsFlap",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		IsRanged = true,
		CombatRole = "melee", -- "melee", "ranged", or "hybrid"
		MeleeRange = 5,
		RangedMinRange = 10,
		RangedMaxRange = 50,
		--AttackRange = 5,
		RangedAmmo = "Egg",
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=3,
		BoredomDuration=10,
		RunSpeed=9,
		NavHitboxSize = Vector3.new(2,1,2),
		HipHeight = 1,
		Search = false,
		Face = 0, --no face
		Attributes = {
			["Oomph"]=1,
			["Brains"]=1,
			["Wits"]=1,
			["Finesse"]=1,
			["Vibe"]=1,
			["Grit"]=1,
			["Combat"]=0,
		},
	};
	
	["SpaceMonkey"] = {
		Name = "SpaceMonkey",
		Type= "Animal",
		Level = 2,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		MaxHealth = 28,
		MaxShield = 0,
		MaxArmor = 0,
		Health = {
			main = 28
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 6,
		RangeAttack = "Throw",
		Deaths = {"Don't Monkey Around","Monkeyed around and found out"},
		Loot = {"Egg","RawChicken"},
		NothingMessage="Just picking through its corpse like it's an Egg hunt eh?",
		Attacks = {
			{Name="Claw",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle1",
			["Idle2"]="Idle2",
			["Idle3"]="Idle1",
			["Idle4"]="Idle2",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Claw"]="Attack",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="Idle1",
			["Die"]="Idle1",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		IsRanged = true,
		CombatRole = "hybrid", -- "melee", "ranged", or "hybrid"
		MeleeRange = 5,
		RangedMinRange = 10,
		RangedMaxRange = 50,
		--AttackRange = 5,
		Weapon = "BagOMonkeyWrenches",
		RangedAmmo = "MonkeyWrench",
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=3,
		BoredomDuration=10,
		RunSpeed=14,
		NavHitboxSize = Vector3.new(3,5,5),
		HipHeight = 2, --was 1.8,
		Search = false,
		Face = 0, --no face
		Attributes = {
			["Oomph"]=2,
			["Brains"]=2,
			["Wits"]=1,
			["Finesse"]=2,
			["Vibe"]=3,
			["Grit"]=1,
			["Combat"]=1,
		},
	};
	
	["ZAP-09-F"] = {
		Name = "ZAP-09-F",
		Type= "Robot",
		Level = 50,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		MaxHealth = 1200,
		MaxShield = 1000,
		MaxArmor = 50,
		Health = {
			main = 1200
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 6,
		RangeAttack = "Shoot",
		Deaths = {"YOU'VE BEEN ZAPPED","Botz"},
		Loot = {},
		NothingMessage="Just a Bucket of Bolts",
		Attacks = {
			{Name="Shoot",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle1",
			["Idle2"]="Idle1",
			["Idle3"]="Idle1",
			["Idle4"]="Idle1",
			["Hit"]="Hit",
			["BaseAttack"]="Attack",
			["Shoot"]="Attack",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="Hit",
			["Die"]="Die",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		IsRanged = true,
		CombatRole = "ranged", -- "melee", "ranged", or "hybrid"
		MeleeRange = 5,
		RangedMinRange = 10,
		RangedMaxRange = 90,
		RangedVerticalRange = 180,
		RangedAbsoluteMaxRange = 200,
		--AttackRange = 5,
		Weapon = "SciCoP92",
		RangedAmmo = "Laser",
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=3,
		BoredomDuration=10,
		RunSpeed=14,
		NavHitboxSize = Vector3.new(2,5,2),
		HipHeight = 3, --was 1.8,
		Search = false,
		Face = 0, --no face
		Attributes = {
			["Oomph"]=7,
			["Brains"]=1, --was 8
			["Wits"]=1,
			["Finesse"]=1, --was 8
			["Vibe"]=1,
			["Grit"]=1,
			["Combat"]=1, --was 8
		},
	};
	
	["MOP-E7"] = {
		Name = "MOP-E7",
		Description = "Maintenance Operating Patrol",
		Type= "Robot",
		Level = 2,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		MaxHealth = 28,
		MaxShield = 0,
		MaxArmor = 0,
		Health = {
			main = 28
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 6,
		RangeAttack = "",
		Deaths = {"Exterminated!","Metal beats flesh","Swept off their feet"},
		Loot = {"ScrapMetal","Wires","Spring","GreenCircuitBoard","Screw"},
		NothingMessage="Just a bucket of bolts",
		Attacks = {
			{Name="Clean",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle1",
			["Idle2"]="Idle2",
			["Idle3"]="Idle1",
			["Idle4"]="Idle2",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["Clean"]="Attack",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="Idle1",
			["Die"]="Idle1",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		IsRanged = true,
		CombatRole = "melee", -- "melee", "ranged", or "hybrid"
		MeleeRange = 5,
		RangedMinRange = 10,
		RangedMaxRange = 50,
		--AttackRange = 5,
		Weapon = "",
		RangedAmmo = "",
		HitRange = 10,
		GuardRange = 100,
		WalkSpeed=3,
		BoredomDuration=10,
		RunSpeed=14,
		NavHitboxSize = Vector3.new(2.63, 1.5, 2.292),
		HipHeight = 2.8, --was 1.8,
		Search = false,
		Face = 0, --no face
		Attributes = {
			["Oomph"]=2,
			["Brains"]=3,
			["Wits"]=1,
			["Finesse"]=1,
			["Vibe"]=1,
			["Grit"]=1,
			["Combat"]=1,
		},
	};

	["ScavReconShip"] = {
		Name = "ScavReconShip",
		Type= "Ship",
		Level = 1,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		MaxHealth = 100,
		MaxShield = 0,
		MaxArmor = 100,
		Health = {
			main = 100
		},
		MaxHull = 1000,
		MaxReactor = 1000,
		MaxLifeSupport = 1000,
		Deaths = {"To Davey Jone's Locker"},
		Loot = {"Egg"},
		Attributes = {
			["Oomph"]=2,
			["Brains"]=2,
			["Wits"]=1,
			["Finesse"]=2,
			["Vibe"]=3,
			["Grit"]=1,
			["Combat"]=1,
		},
	};










	--Health Adjusted
	["The Recently Deceased"] = {
		Name = "The Recently Deceased",
		Type= "Humanoid",
		Level = 2,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 28
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Met their Match","Died"},
		Loot = {"Ectoplasm"},
		NothingMessage="Surprise, you found nothing among the ghostly spirit",
		Attacks = {
			{Name="Scare",RarityPercentage = 20},
			{Name="Claw",RarityPercentage = 80},
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 2,
		HitRange = 10,
		WalkSpeed=16,
		RunSpeed=30,
		HipHeight = 3,
		Search = false,
		Face = 0, --no face
	};

	--Level 2 Experienced

	--Level 2 Elite


	--Level 3 Grunt
	--ACTIVE--
	--Health Adjusted
	["BeeSwarm"] = {
		Name = "BeeSwarm",
		Type= "Insect",
		Level = 3,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"Taken down by the smallest of creatures","Wish they had a fly swatter"},
		Loot = {"HoneyComb","Beeswax"},
		NothingMessage="You found nothing on the tiny little bees",
		Attacks = {
			{Name="LittleSting",RarityPercentage = 100},
		},
		Animations =  {
		},
		Flight = true, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 5,
		HitRange = 10,

		WalkSpeed=16,
		RunSpeed=30,
		HipHeight = 3,
		Search = false,
		Face = 0, --no face
	};

	--Health Adjusted
	["BlackAnts"] = {
		Name = "BlackAnts",
		Type= "Insect",
		Level = 3,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"Stepped on one too many ants","Fried too many ants","Ants revenge"},
		Loot = {},
		NothingMessage="Nothing of any use",
		Attacks = {
			{Name="LittleBite",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["LittleBite"]="Bite",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 3,
		HitRange = 10,
		GuardRange = 150,
		WalkSpeed=30,
		RunSpeed=30,
		HipHeight = 0.3,
		Search = false,
		Face = 0, --no face
	};

	--Health Adjusted
	["FireAnts"] = {
		Name = "FireAnts",
		Type= "Insect",
		Level = 3,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"That bites","Life's no picnic"},
		Loot = {},
		NothingMessage="Nothing of any use",
		Attacks = {
			{Name="Bite",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Bite",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
		},
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		AggroRange = 30,
		AttackRange = 3,
		HitRange = 10,
		WalkSpeed=30,
		GuardRange = 150,
		RunSpeed=30,
		HipHeight = 0.3,
		Search = false,
		Face = 0, --no face
	};

	--Health Adjusted
	["RedSpider"] = {
		Name = "RedSpider",
		Type= "Insect",
		Level = 3,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 4,
		AttackDamageMax = 8,
		Deaths = {"The itsy bitsy spider...","Tangled Up","Was hoping to turn into Spiderman"},
		Loot = {"SpiderEye"},
		NothingMessage="Nothing but smashed spider guts",
		Attacks = {
			{Name="Bite",RarityPercentage = 80},{Name="Web",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["Web"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 150,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = .5,
		Face = 0,
	};

	--Level 3 Experienced	
	--Health Adjusted
	["GreenSpider"] = {
		Name = "GreenSpider",
		Type= "Insect",
		Level = 3,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 10,
		Deaths = {"The itsy bitsy spider...","Tangled Up","Was hoping to turn into Spiderman"},
		Loot = {"RoughSpiderSilk","SpiderEye"},
		NothingMessage="You don't know what to do with a Giant Bee corpse",
		Attacks = {
			{Name="Bite",RarityPercentage = 80},{Name="Venom",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["Venom"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 100,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = .5,
		Face = 0,
	};

	--Health Adjusted
	["Cobra"] = {
		Name = "Cobra",
		Type= "Animal",
		Level = 2,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 7,
		AttackDamageMax = 10,
		RangeAttack = "ToxicSporeShot",
		Deaths = {"Got the Fangs","Turns out, cobras don’t make good pets."},
		Loot = {},
		NothingMessage="Mess of snake guts",
		Attacks = {
			{Name="Bite",RarityPercentage = 80},{Name="Venom",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["Venom"]="Attack2",
			["RangeAttack"]="RangeAttack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 94
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 100,
		RangedAmmo = "Spore",
		AttackRange = 8,
		HitRange = 10,
		GuardRange = 100,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 2.4,
		Face = 0,
	};



	--Level 3 Elite
	--ACTIVE--
	--Health Adjusted
	["OrangeSpider"] = {
		Name = "OrangeSpider",
		Type= "Insect",
		Level = 3,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 10,
		Deaths = {"The itsy bitsy spider...","Tangled Up","Was hoping to turn into Spiderman"},
		Loot = {"FineSpiderSilk","SpiderEye"},
		NothingMessage="You don't know what to do with a Giant Bee corpse",
		Attacks = {
			{Name="Bite",RarityPercentage = 60},{Name="Venom",RarityPercentage = 20},{Name="Web",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["Venom"]="Attack",
			["Web"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 94
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 70,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 150,
		Search = true,
		Flight = true, --flight causes a lot of missing with melee and none with ranged
		HipHeight = .5,
		Face = 0,
	};

	--Health Adjusted
	["OldToothy"] = {
		Name = "OldToothy",
		Type= "Animal",
		Level = 10,
		Rank = 4, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 50,
		AttackDamageMax = 70,
		Deaths = {"Chomp","See ya later gater, after a while crocodile","Playing it safe as usual"},
		Loot = {"CrocodileTooth","ToothysKey","TheOneRing","CrocodileHide",},
		NothingMessage="Nothing but bones and cans of orange soda",
		Attacks = {
			{Name="LittleBite",RarityPercentage = 20},{Name="Bite",RarityPercentage = 60},{Name="TailWhip",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["LittleBite"]="Attack",
			["TailWhip"]="TailWhip",
			["Web"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Swim",
			["Run"]="Swim",
			["SurfaceIdle"]="SurfaceIdle",
			["Swim"]="Swim",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Swim"
		},		
		Health = {
			main = 568
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 150,
		AttackRange = 30,
		HitRange = 50,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 1,
		Face = 0,
	};

	--Health Adjusted
	["Wolf"] = {
		Name = "Wolf",
		Type= "Animal",
		Level = 3,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 4,
		AttackDamageMin = 17,
		AttackDamageMax = 24,
		Deaths = {"Unhappy Camper","Bit the dust"},
		Loot = {},
		NothingMessage="You found nothing, but a bit of camper's blood",
		Attacks = {
			{Name="Bite",RarityPercentage = 50},
			{Name="Claw",RarityPercentage = 50},
		},
		Animations =  {
			["Idle1"]="Sit",
			["Idle2"]="Sit",
			["Idle3"]="Poop",
			["Hit"]="Claw",
			["BaseAttack"]="Claw",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="TakeHit",
			["Die"]="TakeHit", --TODO get die animation
			["Crawl"]="Walk",
			["Bite"]="Bite",
			["Claw"]="Claw",
		},
		Health = {
			main = 94
		},
		BodyParts = {{Name="Body"}},	
		WalkSpeed=16,
		CrawlSpeed=16,
		RunSpeed=30,
		AggroRange = 100,
		AttackRange = 6,
		HitRange = 10,
		Search = true,
		HipHeight = 2,
		Face = 0, --no face
	};

	--Level 4 Grunt
	--ACTIVE--
	--Health Adjusted
	["GiantBee"] = {
		Name = "GiantBee",
		Type= "Insect",
		Level = 5,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 10,
		AttackDamageMax = 15,
		Deaths = {"Now that stings","Bee more careful"},
		Loot = {"HoneyComb","Beeswax","GiantStinger"},
		NothingMessage="You don't know what to do with a Giant Bee corpse",
		Attacks = {
			{Name="Sting",RarityPercentage = 70},{Name="Claw",RarityPercentage = 30}
		},
		Animations =  {
			["Idle1"]="GiantBeeIdle",
			["Idle2"]="GiantBeeIdle",
			["Idle3"]="GiantBeeIdle",
			["Sting"]="Sting",
			["Claw"]="Claw",
			["BaseAttack"]="Claw",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 193
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 70,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 100,
		Search = true,
		Flight = true, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 3.2,
		Face = 0,
	};


	--Level 4 Experienced

	--Level 4 Elite

	--Level 4 Miniboss
	--Health Adjusted
	["Monty"] = {
		Name = "Monty",
		Type= "Animal",
		Level = 4,
		Rank = 4, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 40,
		AttackDamageMax = 80,
		Deaths = {"It waaas the Bunny!","Look at the bones!","Run away!"},
		Loot = {"SharpTeeth"},
		NothingMessage="Nothing but smashed spider guts",
		Attacks = {
			{Name="LeapingBite",RarityPercentage = 100}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["LeapingBite"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 253
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 70,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 150,
		Search = true,
		Flight = true, --flight causes a lot of missing with melee and none with ranged
		HipHeight = .5,
		Face = 0,
	};

	--Level 5 Grunt
	--ACTIVE--
	--Health Adjusted
	["VileVine"] = {
		Name = "VileVine",
		Type= "Plant",
		Level = 5,
		Rank = 4, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = .5,
		AttackDamageMin = 35,
		AttackDamageMax = 50,
		Deaths = {"Consumed by the Forest"},
		Loot = {"VileVineSample","ThornHat","Thorn","Twine"},
		NothingMessage="You only find the remains of a shrivled plant",
		Attacks = {
			{Name="OverheadSmash",RarityPercentage = 50},
			{Name="Trip",RarityPercentage = 0},
			{Name="ThornWhip",RarityPercentage = 20},
			{Name="ToxicSpores",RarityPercentage = 20},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="ThornWhip",
			["BaseAttack"]="ThornWhip",
			["Walk"]="Idle",
			["Run"]="Idle",
			["TakeHit"]="Idle",
			["Die"]="Idle",
			["Grow"]="ThornWhip", --"Grow",
			["OverheadSmash"]="ThornWhip",
			["Trip"]="ThornTrip",
			["ThornWhip"]="ThornWhip",
			["ToxicSpores"]="ThornWhip", --"ToxicSpores",
		},
		Health = {
			main = 321
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=0,
		CrawlSpeed=0,
		RunSpeed=0,
		AggroRange = 0,
		AttackRange = 30,
		HitRange = 30,
		Search = false,
		HipHeight = 4,
		Face = 0,
	};

	--Health Adjusted
	["VileVineJr"] = {
		Name = "VileVineJr",
		Type= "Plant",
		Level = 5,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 11,
		AttackDamageMax = 15,
		Deaths = {"Consumed by the Forest"},
		Loot = {"VileVineSample","Twine"},
		NothingMessage="You only find the remains of a shrivled plant",
		Attacks = {
			{Name="Trip",RarityPercentage = 20},
			{Name="ThornWhip",RarityPercentage = 50},
		},
		Animations =  {
			["Idle1"]="ThornWhip",
			["Idle2"]="ThornWhip",
			["Idle3"]="ThornWhip",
			["Hit"]="ThornWhip",
			["BaseAttack"]="ThornWhip",
			["Walk"]="ThornWhip",
			["Run"]="ThornWhip",
			["TakeHit"]="ThornWhip",
			["Die"]="ThornWhip",
			["Grow"]="ThornWhip", --"Grow",
			["Trip"]="ThornWhip",
			["ThornWhip"]="ThornWhip",
		},
		Health = {
			main = 139
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=0,
		CrawlSpeed=0,
		RunSpeed=0,
		AggroRange = 100,
		AttackRange = 20,
		HitRange = 20,
		Search = false,
		HipHeight = 4,
		Face = 0,
	};

	["Murf"] = {
		Name = "Murf",
		Type= "Humanoid",
		Level = 5,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 11,
		AttackDamageMax = 15,
		Deaths = {"Whooped by an imaginary blue little man"},
		Loot = {},
		NothingMessage="You find nothing from the imaginary blue little man",
		Attacks = {},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Idle",
			["BaseAttack"]="Idle",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="Idle",
			["Die"]="Idle",
		},
		Health = {
			main = 99999999999
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=35,
		CrawlSpeed=35,
		RunSpeed=35,
		AggroRange = 150,
		AttackRange = 10,
		HitRange = 10,
		Search = false,
		HipHeight = 1.1,
		Face = 0,
	};

	["MushroomMan"] = {
		Name = "MushroomMan",
		Type= "Animal",
		Level = 5,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 5,
		AttackDamageMax = 10,
		RangeAttack = "ToxicSporeShot",
		Deaths = {"Spore Guy Died","Fun Guy"},
		Loot = {},
		NothingMessage="You found nothing on the corpse",
		Attacks = {
			{Name="HeadButt",RarityPercentage = 100}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle2",
			["Idle3"]="Idle",
			["HeadButt"]="Attack",
			["RangeAttack"]="RangeAttack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 57
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 50,
		AttackRange = 6,
		RangedAmmo = "Spore",
		HitRange = 10,
		GuardRange = 200,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 2,
		Face = 0,
	};

	--Level 5 Experienced
	--ACTIVE--
	--Health Adjusted
	["JunkyardWorker"] = {
		Name = "JunkyardWorker",
		Type= "Humanoid",
		Level = 5,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2 (lose if no armor, win if armor). single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 2,
		AttackDamageMin = 18,
		AttackDamageMax = 25,
		Deaths = {
			"Thrown out as trash",
			"Living a pipe dream"
		},
		Loot = {"Pipe","BigRigKeys","RustyZapColaCan","LavaPocket"},
		NothingMessage="Did not even find a penny",
		Attacks = {
			{Name="Hit",RarityPercentage = 100}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Hit",
			["BaseAttack"]="Hit",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
		},
		Health = {
			main = 139
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 100,
		AttackRange = 6,
		HitRange = 10,
		Search = true,
		HipHeight = 2.5,
		Face = 26,
	};

	--ACTIVE--
	--Health Adjusted
	["JunkyardDog"] = {
		Name = "JunkyardDog",
		Type= "Animal",
		Level = 5,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2 (lose if no armor, win if armor). single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 2,
		AttackDamageMin = 12,
		AttackDamageMax = 12,
		Deaths = {
			"Dog Chow",
			"Dog Food",
			"Dead Meat",
			"Lost at fetch",
			"Licked to death"
		},
		Loot = {"DogCollar","Bone","Fleas"},
		NothingMessage="Nothing but dog hair",
		Attacks = {
			{Name="Bite",RarityPercentage = 30},
			{Name="Claw",RarityPercentage = 70}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Bite",
			["Claw"]="Claw",
			["BaseAttack"]="Claw",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
		},
		Health = {
			main = 139
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=40,
		AggroRange = 100,
		AttackRange = 3,
		HitRange = 10,
		Search = true,
		HipHeight = 0,
		Face = 0,
	};

	--ACTIVE--
	--Health Adjusted
	["JunkyardWelder"] = {
		Name = "JunkyardWelder",
		Type= "Humanoid",
		Level = 5,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2 (lose if no armor, win if armor). single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 2,
		AttackDamageMin = 15,
		AttackDamageMax = 22,
		Deaths = {
			"That Burned",
			"Now Toast"
		},
		Loot = {"WeldingTorch","Trash"},
		NothingMessage="You found nothing",
		Attacks = {
			{Name="Burn",RarityPercentage = 100}
		},
		Animations = {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Burn"]="Hit",
			["BaseAttack"]="Hit",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
		},
		Health = {
			main = 193
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 100,
		AttackRange = 6,
		HitRange = 10,
		Search = false,
		HipHeight = 2.5,
		Face = 0,
	};

	--ACTIVE--
	--Health Adjusted
	["ArmyManMike"] = {
		Name = "ArmyManMike",
		Type= "Humanoid",
		Level = 5,
		Rank = 4, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2 (lose if no armor, win if armor). single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 321
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 2,
		AttackDamageMin = 9,
		AttackDamageMax = 12,
		Deaths = {
			"Discharged",
			"Extinguished"
		},
		Loot = {"Molotov","JunkyardGateKey"},
		NothingMessage="",
		Attacks = {
			{Name="MolotovFlurry",RarityPercentage = 50},
			{Name="ExplodingBarrel",RarityPercentage = 50}
		},
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 100,
		Search = true,
	};

	["EvilGardenGnome"] = {
		Name = "EvilGardenGnome",
		Type= "Humanoid",
		Level = 3,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 253
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 1,
		Deaths = {"Defeated by Lawn Ornament","This guy is Gnome more"},
		Loot = {"GardenGnome","Hairspray","5Dollar","Superglue","DuctTape"},
		NothingMessage="The gnome has no pockets",
		Attacks = {
			{Name="Stab",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Stab"]="Stab",
			["BaseAttack"]="Stab",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Hit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		WalkSpeed=10,
		CrawlSpeed=3,
		RunSpeed=10,
		AggroRange = 10,
		AttackRange = 5,
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = .1,
		Face = 0,
	};

	--Health Adjusted
	["Bully"] = {
		Name = "Bully",
		Type= "Humanoid",
		Level = 7,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 253
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Stomped on","Pick on someone your own size next time"},
		Loot = {"Milkbox","Jacks","5Dollar","Matches","ScrapCloth","ScrapPlastic"},
		NothingMessage="The bully's pockets were empty",
		RangeAttack = "Rock",
		Attacks = {
			{Name="Hit",RarityPercentage = 80},
			{Name="Uppercut",RarityPercentage = 20},
		},
		WalkSpeed=16,
		RunSpeed=30,
		Search = true,
		RangedAmmo = "Rock",
	};

	--Health Adjusted
	["BullyCamper"] = {
		Name = "BullyCamper",
		Type= "Humanoid",
		Level = 7,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 253
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Stomped on","Pick on someone your own size next time"},
		Loot = {"Milkbox","Jacks","5Dollar","Matches","ScrapCloth","ScrapPlastic"},
		NothingMessage="The bully's pockets were empty",
		RangeAttack = "Fling",
		Attacks = {
			{Name="Jab",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Jab"]="Jab",
			["Uppercut"]="Uppercut",
			["BaseAttack"]="Jab",
			["RangeAttack"]="RangeAttack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 150,
		AttackRange = 5,
		RangedAmmo = "Rock",
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 2.8,
		Face = 0,
	};

	--Health Adjusted
	["Brock"] = {
		Name = "Brock",
		Type= "Humanoid",
		Level = 7,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 321
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Stomped on","Pick on someone your own size next time"},
		Loot = {"PocketKnife","LavaPocket","M80","5Dollar","BadWriterLunchbox","EmpireLunchbox","ScrapCloth","ScrapPlastic"},
		NothingMessage="The bully's pockets were empty",
		RangeAttack = "Rock",
		Attacks = {
			{Name="Jab",RarityPercentage = 80},
			{Name="Uppercut",RarityPercentage = 20},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Jab"]="Jab",
			["Uppercut"]="Uppercut",
			["BaseAttack"]="Jab",
			["RangeAttack"]="RangeAttack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		WalkSpeed=10,
		CrawlSpeed=3,
		RunSpeed=10,
		AggroRange = 150,
		AttackRange = 5,
		RangedAmmo = "Rock",
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 3.5,
		Face = 0,
	};

	["DodgeballDeb"] = {
		Name = "DodgeballDeb",
		Type= "Humanoid",
		Level = 7,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 321
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Thump","Lost at Dodgeball","Forgot to Dodge"},
		Loot = {"Headphones","5Dollar","ETLunchbox","ScrapCloth","ScrapPlastic"},
		NothingMessage="The bully's pockets were empty",
		RangeAttack = "Dodgeball",
		Attacks = {
			{Name="Jab",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Jab"]="Jab",
			["BaseAttack"]="Jab",
			["RangeAttack"]="RangeAttack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		WalkSpeed=10,
		CrawlSpeed=3,
		RunSpeed=10,
		AggroRange = 150,
		AttackRange = 5,
		RangedAmmo = "Dodgeball",
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 3.5,
		Face = 0,
	};

	["JackOLantern"] = {
		Name = "JackOLantern",
		Type= "Plant",
		Level = 5,
		Rank = 3, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 250
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Got Jacked","Gourd-geous","Squashed"},
		Loot = {"PumpkinSeed,JacksLantern,RottenCandy,FarmMap"},
		NothingMessage="Just slimey pumpkin guts",
		RangeAttack = "Hit",
		Attacks = {
			{Name="Hit",RarityPercentage = 100},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["RangeAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Idle",
			["Crawl"]="Walk",
			["Hidden"]="Hidden",
			["Appear"]="Appear"
		},		
		WalkSpeed=10,
		CrawlSpeed=3,
		RunSpeed=10,
		AggroRange = 20,
		AttackRange = 5,
		RangedAttackRange = 40,
		RangedAmmo = "Rock",
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 3,
		Face = 0,
	};

	["Golem"] = {
		Name = "Golem",
		Type= "Plant",
		Level = 1,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 2250
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Fought Own Tombstone","Rocked","Smashed"},
		Loot = {},
		NothingMessage="Just Rubble",
		RangeAttack = "Hit",
		Attacks = {
			{Name="Hit",RarityPercentage = 50},
			{Name="RockSmash",RarityPercentage = 50},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Attack",
			["BaseAttack"]="Attack",
			["RangeAttack"]="RangedAttack",
			["RockSmash"]="AttackAOE",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Hit",
			["Die"]="Idle",
			["Crawl"]="Walk",
			["Hidden"]="Hidden",
			["Appear"]="Appear"
		},		
		WalkSpeed=16,
		CrawlSpeed=16,
		RunSpeed=16,
		AggroRange = 150,
		AttackRange = 50,
		RangedAttackRange = 100,
		RangedAmmo = "Rock",
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		SlowAppear = true,
		HipHeight = 2,
		Face = 0,
	};


	--Health Adjusted
	["Haunter"] = {
		Name = "Haunter",
		Type= "Humanoid",
		Level = 5,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 139
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Forever Haunted"},
		Loot = {"Ectoplasm","Ghost Chain"},
		NothingMessage="Surprise, you found nothing among the ghostly spirit",
		Attacks = {
			{Name="Claw",RarityPercentage = 70},
			{Name="Haunt",RarityPercentage = 20},
			{Name="Ectoblast",RarityPercentage = 10},
		},
		WalkSpeed=16,
		RunSpeed=30,
		Search = true,
	};

	--Level 5 Elite



	--Level 6 Grunt

	--Level 6 Experienced

	--Level 6 Elite


	--Level 7 Grunt

	--Level 7 Experienced

	--Level 7 Elite


	--Level 8 Grunt

	--Level 8 Experienced

	--Level 8 Elite


	--Level 9 Grunt

	--Level 9 Experienced

	--Level 9 Elite


	--Level 10 Grunt

	--ACTIVE--
	--Health Adjusted
	["Zombie"] = {
		Name = "Zombie",
		Type= "Humanoid",
		Level = 10,
		Rank = 1, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 2,
		AttackDamageMin = 5,
		AttackDamageMax = 7,
		Deaths = {
			"Joined the ranks of the non-living",
			"BRAINS....BRAINS...BRAINS..",
			"Donated brain for science",
			"Ouch"
		},
		Loot = {"Bone","GoldWatch","Brains","ZombieNote","ZombieArm","ScrapCloth"},
		NothingMessage="What did you think you were going to find in the corpse of a zombie?",
		Attacks = {
			{Name="Hit",RarityPercentage = 95},
			{Name="ZombieBite",RarityPercentage = 5},
		},	
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Hit",
			["BaseAttack"]="Hit",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Crawl"
		},
		Health = {
			main = 479,
			head = 200,
			leftArm = 200,
			rightArm = 200,
			leftLeg = 200,
			rightLeg = 200
		},
		BodyParts = {{Name="Body"},{Name="Head"},{Name="LeftArm"},{Name="RightArm"},{Name="LeftLeg"},{Name="RightLeg"}},
		WalkSpeed=4,
		CrawlSpeed=3,
		RunSpeed=4,
		AggroRange = 100,
		AttackRange = 6,
		HitRange = 10,
		Search = true,
		HipHeight = 1.9,
		Face = 0, --no face
	};

	--Level 10 Experienced

	["PlagueWeaver"] = {
		Name = "PlagueWeaver",
		Type= "Insect",
		Level = 10,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 21,
		AttackDamageMax = 30,
		Deaths = {"That was just nasty","Plagued"},
		Loot = {"SpiderEye"},
		NothingMessage="Nothing but smashed spider guts",
		Attacks = {
			{Name="Bite",RarityPercentage = 80},{Name="SlimeWeb",RarityPercentage = 20}
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Bite"]="Attack",
			["SlimeWeb"]="Attack",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="Idle",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 479
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=20,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 150,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 1.5,
		DeathHipHeight =.5,
		Face = 0,
	};

	--Level 10 Elite

	--Level 10 Miniboss

	["RockGuardian"] = {
		Name = "RockGuardian",
		Type= "Humanoid",
		Level = 10,
		Rank = 4, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 3210
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Smashed","Broken"},
		Loot = {"OrangeShard","Rock"},
		NothingMessage="Just Rocks",
		Attacks = {
			{Name="Jab",RarityPercentage = 70},
			{Name="Uppercut",RarityPercentage = 20},
			{Name="Smash",RarityPercentage = 10},
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["BaseAttack"]="Attack",
			["Walk"]="Walk",
			["Run"]="Walk",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		WalkSpeed=10,
		CrawlSpeed=3,
		RunSpeed=5,
		AggroRange = 100,
		AttackRange = 5,
		HitRange = 10,
		GuardRange = 150,
		Search = false,
		Flight = false, --flight causes a lot of missing with melee and none with ranged
		HipHeight = 3.5,
		Face = 0,
	};


	--Level 11 Grunt

	--Level 11 Experienced

	--Level 11 Elite


	--Level 12 Grunt

	--Level 12 Experienced

	["Banshee"] = {
		Name = "Banshee",
		Type= "Humanoid",
		Level = 12,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		Health = {
			main = 2040
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 4,
		Deaths = {"Can still hear their screams"},
		Loot = {"Ectoplasm","Ghost Chain"},
		NothingMessage="Surprise, you found nothing among the ghostly spirit",
		Attacks = {
			{Name="Claw",RarityPercentage = 60},
			{Name="Haunt",RarityPercentage = 20},
			{Name="Ectoblast",RarityPercentage = 20},
		},
		Flight = true,
		WalkSpeed=16,
		RunSpeed=30,
		Search = true,
	};

	--Level 12 Elite


	--Level 13 Grunt

	--Level 13 Experienced

	--Level 13 Elite


	--Level 14 Grunt

	--Level 14 Experienced

	--Level 14 Elite


	--Level 15 Grunt

	--Level 15 Experienced

	--ACTIVE--
	["Chompers"] = {
		Name = "Chompers",
		Type= "Plant",
		Level = 15,
		Rank = 2, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = 1,
		AttackDamageMin = 20,
		AttackDamageMax = 30,
		Deaths = {"Always told to eat more greens. In the end the greens ate them.","Face Planted"},
		Loot = {"Twine"},
		NothingMessage="Digging around in the soil found nothing",
		Attacks = {
			{Name="Chomp",RarityPercentage = 50},
			{Name="Thorns",RarityPercentage = 50},
		},
		Animations =  {
			["Idle1"]="ChompersIdle",
			["Idle2"]="ChompersIdle",
			["Idle3"]="ChompersIdle",
			["Chomp"]="Chomp",
			["Thorns"]="Thorns",
			["BaseAttack"]="Chomp",
			["Walk"]="Walk",
			["Run"]="Run",
			["TakeHit"]="TakeHit",
			["Die"]="Die",
			["Crawl"]="Walk"
		},		
		Health = {
			main = 500
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=16,
		CrawlSpeed=3,
		RunSpeed=20,
		AggroRange = 50,
		AttackRange = 6,
		HitRange = 10,
		GuardRange = 50,
		Search = true,
		HipHeight = 1,
		Face = 0,
	};


	--Level 15 Elite



	--Level 16 Grunt

	--Level 16 Experienced

	--Level 16 Elite


	--Level 17 Grunt

	--Level 17 Experienced

	--Level 17 Elite


	--Level 18 Grunt

	--Level 18 Experienced

	--Level 18 Elite


	--Level 19 Grunt

	--Level 19 Experienced

	--Level 19 Elite	


	--Level 20 Grunt

	--Level 20 Experienced

	--Level 20 Elite

	--ACTIVE--
	["Nanites"] = {
		Name = "Nanites",
		Type= "Machine",
		Level = 20,
		Rank = 3,
		Health = {
			main = 21320
		},
		BodyParts = {{Name="Body"}},	
		AttackSpeed = 100,
		AttackDamageMin = 3,
		AttackDamageMax = 3,
		Deaths = {"Did not see that one coming"},
		Loot = {"Nanite"},
		NothingMessage="You couldn't even find the corpse. It's way too small!",
		Attacks = {
			{Name="Zap",RarityPercentage = 60},
			{Name="Flash",RarityPercentage = 5},
			{Name="SpontaneousCombustion",RarityPercentage = 10},
			{Name="Fatigue",RarityPercentage = 15},
			{Name="EnemyWithin",RarityPercentage = 10}
		},
		Flight = true,
		WalkSpeed=16,
		RunSpeed=40,
		Search = true,
	};

	--ACTIVE--
	["Nuke"] = {
		Name = "Nuke",
		Type= "Machine",
		Level = 20,
		Rank = 5, --1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss . single player can handle 1 and 2. single player for 3 would be difficult and probably requires some items for healing or traps. single for miniboss is likely near impossible and impossible for boss.
		AttackSpeed = .5,
		AttackDamageMin = 10000,
		AttackDamageMax = 10000,
		Deaths = {"Boom","You dead","Bye Bye","Nuked","Here lies a pile of dust","Vaporized"},
		Loot = {"Plutonium"},
		NothingMessage="Why would you expect anything to be left?",
		Attacks = nil,
		SelfDestruct = {
			Name="Nuke",
			Range=10000,
			Damage=1000000,
		},
		Animations =  {
			["Idle1"]="Idle",
			["Idle2"]="Idle",
			["Idle3"]="Idle",
			["Hit"]="Idle",
			["BaseAttack"]="Idle",
			["Walk"]="Idle",
			["Run"]="Idle",
			["TakeHit"]="Idle",
		},
		Health = {
			main = 1000
		},
		BodyParts = {{Name="Body"}},
		WalkSpeed=0,
		CrawlSpeed=0,
		RunSpeed=0,
		AggroRange = 0,
		AttackRange = 30,
		HitRange = 40,
		Search = false,
		HipHeight = 0,
		Face = 0,
	};



	--Alpha Level CAP 5
	--Beta Level CAP 20
	--Release Level CAP 50

}

return module
