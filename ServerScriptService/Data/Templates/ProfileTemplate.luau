local ProfileTemplate = {
	Money = 0,
	Inventory = {
		["Items"] = {},
		["Tools"] = {},
		["BuildItems"] = {
			
		},
		["Weapon"]=nil,
		["OffHand"]=nil,
		["Head"]=nil,
		["Back"]=nil,
		["Accessory"]=nil,
		["Selling"]={},
		["Overflow"]={Contains={}},
		["Suitcase"]={Contains={}},
		["VacpacExtra"]={Contains={}},
		["Power"]=0,
	},
	NextContainerId=0,
	Quests = {},
	QuestActive = {},
	QuestCompleted = {},
	QuestFlags = {},
	Collections = {},
	Achievements = {},
	GamePasses = {},
	Subscriptions = {},
	Character = {
		Class = "", --The Jocks, The Nerds, The Popular, The Rebels, The Artsy  
		Gender = "",
		Outfit = 1,
		Face = 1,
		Hair = 1,
		HairHue = 0.07861,
		HairSaturation = 1,
		HairValue = 0.4704,
		SkinHue = 0.05,
		SkinSaturation = 0.28,
		SkinValue = 0.4704,
		AccessoryHue = 0.005,
		AccessorySaturation = 0.84,
		AccessoryValue = 0.4704
	},
	Attributes= {
		AttributePoints = 0, --Get Attribute point every other level and Skill Point every other level
		MaxHealth = 100, --MaxHealth  = math.round(math.pow(level/.4,2+(level/50)) )
		MaxStamina = 10,
		MaxSpeed = 1,
		Armor = 1, --(Armor - 1)*.5 = % reduction of normal damage. so need 101 to get 50% reduction of damage
		HeatResistance = 1, --normal mobs and alien --TODO handle all resistances
		ColdResistance = 1, --normal mobs
		PoisonResistance = 1, --normal mobs and plant mobs
		DiseaseResistance = 1, --zombie attacks
		ParanormalResistance = 1, --ghost attacks
		VoidResitance = 1, --nightshade and other "vile of the void" attacks
		MindAlteringResistance = 1, --alien
		Oomph = 0,
		Brains = 0,
		Wits = 0,
		Finesse = 0,
		Vibe = 0,
		Grit = 0,
	},
	Progress= {
		Started = false,
		XP = 0,
		Level = 1,
		PaperAirplayHighScore = 0,
		Discoveries = {
			[1]=false, --Lighthouse
			[2]=false, --Football Field
		},
		LastTimePlayed = 0,
		PlayingStreak = 1,
		LastTimeDailyRewardsClaimed = 0,
	}	
}

return ProfileTemplate