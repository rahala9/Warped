local effects = {
	["Poison"] = {
		Name = "Poison",
		Description = "Low damage over long time",
		Duration = 20,
		TickInterval = 1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="DamageOverTime", Damage=1},
		},
		-- Retained temporarily because enemy effects still consume these fields.
		Effect = {Type="Health",Action="DOT",Amount=1,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {"Poisoned", "Was it something he ate?"},
		ImageOffsetX = 2*64,
		ImageOffsetY = 0,
	};

	["DestroyWeapon"] = {
		Name = "DestroyWeapon",
		Description = "Weapon Explodes",
		Effect = {Type="DestroyItem",Action="ExplodeWeapon",Amount=1,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {"Kablooy!", "Go Boom Boom"},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Slow"] = {
		Name = "Slow",
		Description = "Slow speed",
		Duration = -1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="ClampMax", Value=10, ScaleWithSourceLevel=false},
		},
		Effect = {Type="Movement",Action="Movement",Amount=10,TimeInEffect=-1,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Speed"] = {
		Name = "Speed",
		Description = "Increase speed",
		Duration = 60,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="ClampMin", Value=17, ScaleWithSourceLevel=false},
		},
		Effect = {Type="Movement",Action="Movement",Amount=17,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["SwimSpeed"] = {
		Name = "SwimSpeed",
		Description = "Increase swim speed",
		Duration = 60,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="ClampMin", Value=17, ScaleWithSourceLevel=false},
		},
		Effect = {Type="Movement",Action="Movement",Amount=17,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Kuato"] = {
		Name = "Kuato",
		Description = "Wow that is grose",
		Effect = {Type="Kuato",Action="Add",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,

	};

	["SmallBleed"] = {
		Name = "SmallBleed",
		Description = "Small damage over long time",
		Duration = 20,
		TickInterval = 1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="DamageOverTime", Damage=1},
		},
		-- Retained temporarily because enemy effects still consume these fields.
		Effect = {Type="Health",Action="DOT",Amount=1,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {"Bled out", "Guess he needed that blood"},
		ImageOffsetX = 3*64,
		ImageOffsetY = 0,
	};

	["Bleed"] = {
		Name = "Bleed",
		Description = "Medium damage over long time",
		Duration = 20,
		TickInterval = 1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="DamageOverTime", Damage=8},
		},
		-- Retained temporarily because enemy effects still consume these fields.
		Effect = {Type="Health",Action="DOT",Amount=8,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {"Bled out", "Guess he needed that blood"},
		ImageOffsetX = 3*64,
		ImageOffsetY = 0,
	};

	["Hemorrhage"] = {
		Name = "Hemorrhage",
		Description = "Large damage over short time",
		Duration = 5,
		TickInterval = 1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="DamageOverTime", Damage=15},
		},
		-- Retained temporarily because enemy effects still consume these fields.
		Effect = {Type="Health",Action="DOT",Amount=15,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {"Human Blood Shower", "Well color him red"},
		ImageOffsetX = 6*64,
		ImageOffsetY = 0,
	};
	
	["Food"] = {
		Name = "Food",
		Description = "Food",
		Effect = {Type="Food",Action="Add",Amount=1,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};
	
	["Hydration"] = {
		Name = "Hydration",
		Description = "Hydration",
		Effect = {Type="Hydration",Action="Add",Amount=1,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["TinyFood"] = {
		Name = "SmallFood",
		Description = "Small one time addition to health",
		Effect = {Type="Health",Action="Add",Amount=5,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["SmallFood"] = {
		Name = "SmallFood",
		Description = "Small one time addition to health",
		Effect = {Type="Health",Action="Add",Amount=20,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["MediumFood"] = {
		Name = "MediumFood",
		Description = "Small one time addition to health",
		Effect = {Type="Health",Action="Add",Amount=100,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["SpicyMediumFood"] = {
		Name = "MediumFood",
		Description = "Small one time addition to health",
		Effect = {Type="Health",Action="AddPercent",Amount=50,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["SpicyLargeFood"] = {
		Name = "MediumFood",
		Description = "Small one time addition to health",
		Effect = {Type="Health",Action="AddPercent",Amount=100,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["LargeFood"] = {
		Name = "LargeFood",
		Description = "Large one time addition to health",
		Effect = {Type="Health",Action="Add",Amount=1000,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Armor"] = {
		Name = "Armor",
		Description = "You feel protected",
		Effect = {Type="Armor",Action="Add",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Strength"] = {
		Name = "Strength",
		Description = "Addition to strength for a time",
		Effect = {Type="Strength",Action="Add",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Intelligence"] = {
		Name = "Intelligence",
		Description = "Addition to Intelligence for a time",
		Effect = {Type="Intelligence",Action="Add",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 7*64,
		ImageOffsetY = 0,
	};

	["Vitality"] = {
		Name = "Vitality",
		Description = "Addition to strength for a time",
		Effect = {Type="Vitality",Action="Add",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["SuperStrength"] = {
		Name = "SuperStrength",
		Description = "Large addition to strength for a time",
		Effect = {Type="Strength",Action="Add",Amount=100,TimeInEffect=30,TimeStarted=0,CurrentEffectTime=30},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Stung"] = {
		Name = "Stung",
		Description = "Small loss of strength for a time",
		Effect = {Type="Strength",Action="Subtract",Amount=1,TimeInEffect=10,TimeStarted=0,CurrentEffectTime=10},
		Source = nil,
		Deaths = {"Stung to death"},
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
	};

	["Stung2"] = {
		Name = "Stung2",
		Description = "You feel pretty weak",
		Effect = {Type="Strength",Action="Subtract",Amount=2,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {"Stung to death"},
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
	};

	["SuperSize"] = {
		Name = "SuperSize",
		Description = "You're a giant now",
		Effect = {Type="Size",Action="Multiply",Amount=2,TimeInEffect=30,TimeStarted=0,CurrentEffectTime=30},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 3*64,
		ImageOffsetY = 2*64,
	};

	["Trapped"] = {
		Name = "Trapped",
		Description = "You aint going nowhere",
		Duration = 10,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="Immobilize"},
		},
		Effect = {Type="Movement",Action="Set",Amount=0,TimeInEffect=10,TimeStarted=0,CurrentEffectTime=10},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 5*64,
		ImageOffsetY = 0,
	};

	["WebTrapped"] = {
		Name = "WebTrapped",
		Description = "Sticky Ain't It?",
		Duration = 5,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="Immobilize"},
			{Type="CharacterVFX", Template="webTrap"},
		},
		Effect = {Type="Movement",Action="Set",Amount=0,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 5*64,
		ImageOffsetY = 0,
	};

	["SlimeWebTrapped"] = {
		Name = "SlimeWebTrapped",
		Description = "Sticky Ain't It?",
		Duration = 5,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Behaviors = {
			{Type="MovementModifier", Operation="Immobilize"},
			{Type="CharacterVFX", Template="slimeTrap"},
		},
		Effect = {Type="Movement",Action="Set",Amount=0,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 5*64,
		ImageOffsetY = 0,
	};

	["Resting"] = {
		Name = "Resting",
		Description = "You feel rested",
		Effect = {Type="Stamina",Action="AddOverTime",Amount=1,TimeInEffect=120,TimeStarted=0,CurrentEffectTime=120},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 1*64,
		ImageOffsetY = 0,
	};

	["Corruption"] = {
		Name = "Corruption",
		Description = "You are being taken over by evil",
		Effect = {Type="Stamina",Action="SubtractOverTime",Amount=10,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
	};

	["Blind"] = {
		Name = "Blind",
		Description = "Can't see a darn thing",
		Effect = {Type="Screen",Action="Blur",Amount=90,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 0,
		ImageOffsetY = 1*64,
	};

	["Tired"] = {
		Name = "Tired",
		Description = "Zzzzzzzzzzz",
		Effect = {Type="Stamina",Action="Subtract",Amount=50,TimeInEffect=0,TimeStarted=0,CurrentEffectTime=50},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 7*64,
		ImageOffsetY = 1*64,
	};

	["OnFire"] = {
		Name = "OnFire",
		Description = "Do you smell something. Someone must be BBQing",
		Duration = 20,
		TickInterval = 1,
		Stacking = {Mode="Ignore", MaxStacks=1},
		Behaviors = {
			{Type="DamageOverTime", Damage=5},
			{Type="CharacterVFX", Template="Fire"},
		},
		-- Retained temporarily because enemy effects still consume these fields.
		Effect = {Type="Health",Action="DOT",Amount=5,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {"Melted","Playing with fire is dangerous","PLayed Human Marshmellow"},
		ImageOffsetX = 0,
		ImageOffsetY = 2*64,
	};

	["Confusion"] = {
		Name = "Confusion",
		Description = "Who are you? Who am I?",
		Effect = {Type="Health",Action="DamageEachAttack",Amount=3,TimeInEffect=20,TimeStarted=5,CurrentEffectTime=20},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 4*64,
		ImageOffsetY = 1*64,
	};

	["Stink"] = {
		Name = "Stink",
		Description = "Nobody will talk to you while you smell like that!",
		Duration = 60,
		TickInterval = 1,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Presentation = {
			Description = "Nobody will talk to you while you smell like that!",
			ShowTimer = true,
			Icon = {OffsetX=1*64, OffsetY=1*64},
		},
		-- Compatibility timing fields remain for older consumers, but every Stink
		-- outcome is now declared independently in Behaviors.
		Effect = {Type="Composed",Action="None",Amount=0,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Behaviors = {
			{Type="CharacterVFX", Template="Flies"},
			-- Net exposure is +0.25/sec after the meter's natural -0.10/sec recovery,
			-- resulting in 15 Biohazard over a full 60-second Stink duration.
			{Type="MeterRate", Meter="Biohazard", RatePerSecond=0.35},
			{
				Type="Restriction",
				Actions={"NPCInteraction", "Purchase"},
				Message="You smell awful. Come back after you've cleaned up.",
			},
		},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 1*64,
		ImageOffsetY = 1*64,
	};

	["Mutation"] = {
		Name = "Mutation",
		Description = "Teleportation has scrambled your genetic structure!",
		Effect = {Type="Mutation",Action="FlyHead",Amount=0,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60,ClientVisual=true},
		Source = nil,
		Deaths = {},
		-- Reuse this populated icon slot until Mutation has dedicated art.
		ImageOffsetX = 3*64,
		ImageOffsetY = 3*64,
	};

	["ElectricShock"] = {
		Name = "ElectricShock",
		Description = "High-voltage current is coursing through your suit.",
		Duration = 3,
		TickInterval = 1,
		Stacking = {Mode="Refresh", MaxStacks=1},
		Effect = {Type="Composed",Action="None",Amount=0,TimeInEffect=3,TimeStarted=0,CurrentEffectTime=3},
		Behaviors = {
			{
				Type="DamageOverTime",
				Damage=10,
				DamageType="Electric",
				DeathEffect="Electrocuted",
				DeathEffectChanceKey="ElectricStatusChance",
			},
			{Type="CharacterVFX", Template="Electricity"},
			{Type="ClientVisual"},
		},
		Source = nil,
		Deaths = {"Zapped","Regular little Nicky Tesla","Shocked"},
		ImageOffsetX = 1*64,
		ImageOffsetY = 3*64,
	};

	["InvisibilityLv1"] = {
		Name = "InvisibilityLv1",
		Description = "Well this is wierd",
		Effect = {Type="InvisibilityLv1",Action="InvisibilityLv1",Amount=1,TimeInEffect=30,TimeStarted=0,CurrentEffectTime=30},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 2*64,
		ImageOffsetY = 3*64,
	};

	["InvisibilityLv2"] = {
		Name = "InvisibilityLv2",
		Description = "My Precious",
		Effect = {Type="InvisibilityLv2",Action="InvisibilityLv2",Amount=1,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 2*64,
		ImageOffsetY = 3*64,
	};

	["Wet"] = {
		Name = "Wet",
		Description = "You are soaking",
		Effect = {Type="RemoveEffects",EffectsRemoved={"Stink","OnFire"},TimeInEffect=-1,TimeStarted=0,CurrentEffectTime=0},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,

	};

	["Dumb"] = {
		Name = "Dumb",
		Description = "You feel...uh. you forgot",
		Effect = {Type="Intelligence",Action="Subtract",Amount=3,TimeInEffect=20,TimeStarted=0,CurrentEffectTime=20},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 4*64,
		ImageOffsetY = 1*64,
	};

	["Smarts"] = {
		Name = "Smarts",
		Description = "You feel sharp as ever",
		Effect = {Type="Intelligence",Action="Add",Amount=2,TimeInEffect=60,TimeStarted=0,CurrentEffectTime=60},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 7*64,
		ImageOffsetY = 0,
	};

	--Stability if % likelihood of staying on your feet when hit. if you fail then you get knocked down for a time
	-- in which you get double damage and cannot attack. (same for player or npc/mob)
	["Dizzy"] = {
		Name = "Dizzy",
		Description = "Spinning Spinning Spinning",
		Effect = {Type="Stability",Action="Subtract",Amount=50,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 5*64,
		ImageOffsetY = 1*64,
	};

	["Knockdown"] = {
		Name = "Knockdown",
		Description = "You got knocked out",
		Effect = {Type="Stability",Action="Subtract",Amount=100,TimeInEffect=5,TimeStarted=0,CurrentEffectTime=5},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 4*64,
		ImageOffsetY = 0,
	};

	["NightVision"] = {
		Name = "NightVision",
		Description = "Night Vision",
		Effect = {Type="NightVision",Action="NightVision",Amount=1,TimeInEffect=180,TimeStarted=0,CurrentEffectTime=180},
		Source = nil,
		Deaths = {},
		ImageOffsetX = 5*64,
		ImageOffsetY = 1*64,
	};

}

effects.Image = "rbxassetid://17504087445"

return effects
