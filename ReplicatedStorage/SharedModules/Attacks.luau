--Types of attack bonus
-- {Type="",Amount=0}  is no bonus
--*   min or max damage is multiplied by amount
--+WeaponLevel* -- min or max damage is added with the weapon level multiplied by amount

local module = {

	["PowerPush"] = {
		Name = "PowerPush",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Knockdown",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Cooldown = 30,
		Emit=nil
	};

	["Flame"] = {
		Name = "Flame",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "OnFire",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Cooldown = 0,
		Emit=nil
	};

	["FireRocket"] = {
		Name = "FireRocket",
		BaseDamageModifier = {Type="",Amount=0},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Effect = nil,
		Cooldown = 0,
		Emit=nil
	};

	["SelfDestruct"] = {
		Name = "SelfDestruct",
		BaseDamageModifier = {Type="*",Amount=2},
		Effect = "DestroyWeapon",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Cooldown = 0,
		Emit=nil
	};

	["Zap"] = {
		Name = "Zap",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Flash"] = {
		Name = "Flash",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Blind",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Scare"] = {
		Name = "Scare",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "RunAway",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Haunt"] = {
		Name = "Haunt",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "RunAway",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["SpontaneousCombustion"] = {
		Name = "SpontaneousCombustion",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "OnFire",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Fatigue"] = {
		Name = "Fatigue",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Tired",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["EnemyWithin"] = {
		Name = "EnemyWithin",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Confusion",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Burn"] = {
		Name = "Burn",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "OnFire",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["LittleBite"] = {
		Name = "LittleBite",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Peck"] = {
		Name = "Peck",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["HeadButt"] = {
		Name = "HeadButt",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Bite"] = {
		Name = "Bite",
		BaseDamageModifier = {Type="*",Amount=1.5},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["TailWhip"] = {
		Name = "TailWhip",
		BaseDamageModifier = {Type="*",Amount=1.5},
		MultiTarget = 3,
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["LeapingBite"] = {
		Name = "LeapingBite",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Hemorrhage",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Claw"] = {
		Name = "Claw",
		BaseDamageModifier = {Type="",Amount=0},
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["ZombieBite"] = {
		Name = "ZombieBite",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Zombie",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Hit"] = {
		Name = "Hit",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Chomp"] = {
		Name = "Chomp",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Thorns"] = {
		Name = "Thorns",
		BaseDamageModifier = {Type="",Amount=0},
		MultiShot = 10,
		Effect = nil,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["ToxicSpores"] = {
		Name = "ToxicSpores",
		BaseDamageModifier = {Type="",Amount=0},
		MultiShot = 10,
		Effect = "Poison",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit={Emitter1="HumanoidRootPart",Amount=100}
	};

	["ToxicSporeShot"] = {
		Name = "ToxicSporeShot",
		BaseDamageModifier = {Type="",Amount=0},
		MultiShot = 1,
		Effect = "Poison",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Trip"] = {
		Name = "Trip",
		BaseDamageModifier = {Type="",Amount=0},
		Effect = "Knockdown",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["CheckPlease"] = {
		Name = "CheckPlease",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 5,
		Effect = "Knockdown",
		Animation = "82431374802269",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		AnimationSpeed = 1,
		Emit=nil
	};

	["Swing"] ={
		Name = "Swing",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "8981580187",
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
		AnimationSpeed = 2,
		Emit=nil
	};

	["Crush"] ={
		Name = "Crush",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "Knockdown",
		Animation = "8981580187",
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
		AnimationSpeed = 2,
		Emit=nil
	};

	["UnderhandThrow"] ={
		Name = "UnderhandThrow",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "100759128080543",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		DeferAttack = true,
		AnimationSpeed = 2,
		Emit=nil
	};

	["Throw"] ={
		Name = "Throw",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "109109001621034",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		DeferAttack = true,
		AnimationSpeed = 2,
		Emit=nil
	};

	["ChickenEggCannon"] ={
		Name = "ChickenEggCannon",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "109109001621034",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		DeferAttack = true,
		AnimationSpeed = 2,
		Emit=nil
	};


	["Slash"] ={
		Name = "Slash",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		AnimationSpeed = 2,
		Emit=nil,
		SoundFX = "9119749145"
	};

	["OverheadSmash"] ={
		Name = "OverheadSmash",
		BaseDamageModifier = {Type="*",Amount=2},
		Cooldown = 10,
		Effect = nil,
		Animation = "81768074451112",
		ImageOffsetX = 4*64,
		ImageOffsetY = 1*64,
		Emit=nil
	};

	["OverheadSlash"] ={
		Name = "OverheadSlash",
		BaseDamageModifier = {Type="*",Amount=2},
		MaxSpreadAngle = 4,
		Cooldown = 10,
		Effect = "Hemorrhage",
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["PrecisionCut"] ={
		Name = "PrecisionCut",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 3,
		Effect = "Hemorrhage",
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};


	["Punch"] ={
		Name = "Punch",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Jab"] ={
		Name = "Jab",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown =0,
		Effect = nil,
		Animation = "15330250000", -- "12328729982",
		AnimationSpeed = 2,
		ImageOffsetX = 0,
		ImageOffsetY = 1*64,
		Emit=nil,
		MultiTarget = 3,
	};

	["Hook"] ={
		Name = "Hook",
		BaseDamageModifier = {Type="*",Amount=2},
		Cooldown = 3,
		Effect = "Dizzy",
		Animation = "12329881060",
		ImageOffsetX = 1*64,
		ImageOffsetY = 1*64,
		AnimationSpeed = 2,
		Emit=nil
	};

	["Uppercut"] ={
		Name = "Uppercut",
		BaseDamageModifier = {Type="*",Amount=3},
		Cooldown = 10,
		Effect = "Knockdown",
		Animation = "12330350151",
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,
		AnimationSpeed = 1.5,
		Emit=nil
	};

	["Venom"] ={
		Name = "Venom",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "Poison",
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Web"] ={
		Name = "Web",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "WebTrapped",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Animation = "",
		Emit=nil,
	};

	["SlimeWeb"] ={
		Name = "SlimeWeb",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "SlimeWebTrapped",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Animation = "",
		Emit=nil,
	};

	["RockSmash"] ={
		Name = "RockSmash",
		BaseDamageModifier = {Type="*",Amount=1.5},
		Cooldown = 0,
		Effect = nil,
		AOECount = 3,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		AnimationSpeed = 2,
		Emit=nil,
		EffectsHandler = "RockSmash"
	};


	["ShootWild"] ={
		Name = "Shoot",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};
	
	["Shoot"] ={
		Name = "Shoot",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};
	
	["ShootPrecise"] ={
		Name = "ShootPrecise",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};
	
	["ShootPerfect"] ={
		Name = "ShootPerfect",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};
	

	["Cast"] ={
		Name = "Cast",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "136140148002774", --72591447531022", --12252711061", -- "12252674412" --12251862248",
		DeferAttack = true,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["CastUp"] ={
		Name = "CastUp",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "79279199393492",
		DeferAttack = true,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};


	["Spray"] ={
		Name = "Spray",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	
	["Strum"] ={
		Name = "Strum",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 20,
		Effect = nil,
		Animation = "122913802971049",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Pluck"] ={
		Name = "Pluck",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 10,
		Effect = "Bleed",
		Animation = "132945257724313",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Drum"] ={
		Name = "Drum",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Shred"] ={
		Name = "Shred",
		BaseDamageModifier = {Type="",Amount=0},
		MultiTarget = 3,
		Cooldown = 30,
		Effect = nil,
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["PlaceBearTrap"] ={
		Name = "PlaceBearTrap",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "Trapped",
		Animation = "",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};

	["Dumb"] ={
		Name = "Dumb",
		BaseDamageModifier = {Type="",Amount=0},
		Cooldown = 0,
		Effect = "Dumb",
		Animation = "8981580187",
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Emit=nil
	};
}

return module
