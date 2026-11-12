

local imageMap = {
	["Weapon"]="rbxassetid://124954524360448", 
	["OffHand"]="rbxassetid://124954524360448",	  --same as weapon
	["Ammo"]="rbxassetid://124954524360448",  --same as weapon
};

local ItemTypes = {
	["Weapon"]="Weapon",
	["Artifact"]="Artifact",
	["OffHand"]="OffHand",
	["Ammo"]="Ammo",
}


local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local WeaponTypes = {
	["Pistol"]="Pistol", 
	["Rifle"]="Rifle",  
	["Sniper"]="Sniper", 
	["Thrown"]="Thrown", 
}

local DamageTypes = {
	["Kinetic"]="Kinetic",
	["Laser"]="Laser", 
	["Plasma"]="Plasma",
	["Electric"]="Electric", 
	["ParticleBeam"]="ParticleBeam",
	["Explosive"]="Explosive",
	["Thermal"]="Thermal",
	["Cryo"]="Cryo",
}

local SubTypes = {
	["Weapon"]={
		["Melee"]="Melee",
		["Ranged"]="Ranged",
		["OffHand"]="OffHand",
		["None"]="",
	},
	["OffHand"]={["None"]="None"},
	["Ammo"]={["None"]=""},
}

local Rarity = {
	["Trash"]=0,
	["Common"]=1,
	["Uncommon"]=2,
	["Rare"]=3,
	["Epic"]=4,
	["Legendary"]=5,

}

local rarityMap = {
	[0]="Trash",
	[1]="Common",
	[2]="Uncommon",
	[3]="Rare",
	[4]="Epic",
	[5]="Legendary",

}

local colorMap = {
	["Blue"] =  Color3.fromRGB(25,218,231),
	["Orange"] = Color3.fromRGB(231,175,27),
}

--Rarity     	RarityPercentage/weight 	type of enemy that drops the General type of this level loot
-- 0 trash   	100							any enemy
-- 1 common		80							any enemy
-- 2 uncommon	50							any enemy
-- 3 rare		1							elite (unless specific loot from enemy)
-- 4 epic		.03							miniboss (unless specific loot from enemy)
-- 5 legendary	.01							boss (unless specific loot from enemy)


local module = {

	["ImageMap"] = imageMap;
	["Rarities"] = rarityMap;
	["ColorMap"] = colorMap;

	["Egg"] = {
		Name = "Egg",
		DisplayName = "Egg",
		Model = "Egg",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 12,
		Desc = "Grade A Eggs",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		Aim = true,
		WeaponDamageMin = 10,
		WeaponDamageMax = 12,
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 200,
		WeaponMaxDistance = 200,
		WeaponAmmo = "Egg",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="Throw",LastUsed=0},["F"]={Name="Throw",LastUsed=0},["G"]={Name="Throw",LastUsed=0}},
		Value = .25,
		ImageOffsetX = 7*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon
	},

	["Fists"] = {
		Name = "Fists",
		DisplayName = "Fists",
		Model = "",
		Level = 1,
		Amount = 1,
		Desc = "Fisticuffs",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Melee,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		WeaponDamageMin = "1",
		WeaponDamageMax = "1",
		WeaponSpeed = "20",
		WeaponAttacks = {["R"]={Name="Jab",LastUsed=0},["F"]={Name="Hook",LastUsed=0},["G"]={Name="Jab",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 3*64,
		Trade = false,
		CanNotRemove = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
		Hand = "Both",
	};

	["NerdGun"] = {
		Name = "NerdGun",
		DisplayName = "Nerd Gun",
		Model = "NerdGun",
		Level = 1,
		Amount = 1,
		Desc = "Shoot!",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = true,
		WeaponDamageMin = 1,
		WeaponDamageMax = 1,
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 100,
		WeaponMaxDistance = 400,
		WeaponAmmo = "Dart",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="Shoot",LastUsed=0},["F"]={Name="Shoot",LastUsed=0},["G"]={Name="Shoot",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["SciCoP92"] = {
		Name = "SciCoP92",
		DisplayName = "SciCo P92",
		Model = "SciCoP92",
		Level = 1,
		Amount = 1,
		Desc = "Knicknamed Double Tap. Melting Law Breakers since Star Date 49385721",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = true,
		Tier = 4,
		BaseDamage = 50,
		WeaponType = WeaponTypes.Rifle, --NEW
		DamageType = DamageTypes.Laser, --NEW
		WeaponSpeed = 200,
		WeaponAmmoSpeed = 400,
		WeaponMaxDistance = 800,
		WeaponAmmo = "Laser",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="ShootPrecise",LastUsed=0},["F"]={Name="ShootPrecise",LastUsed=0},["G"]={Name="ShootPrecise",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};
	
	["SciCo00Zero"] = {
		Name = "SciCo00Zero",
		DisplayName = "SciCo 00Zero",
		Model = "SciCo00Zero", --Synty Sci-Fi Space SM_Wep_Pistol_01
		Level = 1,
		Amount = 1,
		Desc = "The Sci Co Standard Issue Double Oh Zero. The reason Sci Co Troopers have a reputation of not being to hit the planet when aiming down",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = true,
		Tier = 1,
		BaseDamage = 5,
		WeaponType = WeaponTypes.Pistol, --NEW
		DamageType = DamageTypes.Laser, --NEW
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 100,
		WeaponMaxDistance = 300,
		WeaponAmmo = "Laser",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="ShootPerfect",LastUsed=0},["F"]={Name="ShootPerfect",LastUsed=0},["G"]={Name="ShootPerfect",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};
	
	["Splatifier9000"] = {
		Name = "Splatifier9000",
		DisplayName = "Splatifier 9000",
		Model = "Splatifier9000", --Synty Assets/PolygonCyberCity/Prefabs/Weapons/SM_Wep_Laser_Gun_01.prefab
		Level = 1,
		Amount = 1,
		Desc = "Top of the line weapon from A.I.M. — Advanced Interstellar Munitions corp.",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = true,
		Tier = 3,
		BaseDamage = 30,
		WeaponType = WeaponTypes.Rifle, --NEW
		DamageType = DamageTypes.Plasma, --NEW
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 200,
		WeaponMaxDistance = 300,
		WeaponAmmo = "Laser",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="ShootPerfect",LastUsed=0},["F"]={Name="ShootPerfect",LastUsed=0},["G"]={Name="ShootPerfect",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};
	
	["Rock"] = {
		Name = "Rock",
		DisplayName = "Rock",
		Model = "Rock", --Synty Sci-Fi Space SM_Wep_Pistol_01
		Level = 1,
		Amount = 1,
		Desc = "Nice palm sized rock",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = false,
		Tier = 1,
		BaseDamage = 1,
		WeaponType = WeaponTypes.Thrown, --NEW
		DamageType = DamageTypes.Kinetic, --NEW
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 100,
		WeaponMaxDistance = 300,
		WeaponAmmo = "Rock",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="ShootPerfect",LastUsed=0},["F"]={Name="ShootPerfect",LastUsed=0},["G"]={Name="ShootPerfect",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};
	
	["BagOMonkeyWrenches"] = {
		Name = "BagOMonkeyWrenches",
		DisplayName = "BagOMonkeyWrenches",
		Model = "MonkeyWrench",
		Level = 1,
		Amount = 1,
		Desc = "Clang",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={Intelligence=1},
		NeedToContain="Solid",
		Aim = false,
		Tier = 1,
		BaseDamage = 5,
		WeaponType = WeaponTypes.Thrown, --NEW
		DamageType = DamageTypes.Kinetic, --NEW
		WeaponSpeed = 50,
		WeaponAmmoSpeed = 150,
		WeaponMaxDistance = 300,
		WeaponAmmo = "MonkeyWrench",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="ShootPerfect",LastUsed=0},["F"]={Name="ShootPerfect",LastUsed=0},["G"]={Name="ShootPerfect",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};

	["DeathRay"] = {
		Name = "DeathRay",
		DisplayName = "Death Ray",
		Model = "DeathRay",
		Level = 10,
		Amount = 1,
		Desc = "To Dust!",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		Aim = true,
		VFX = true,
		WeaponDamageMin = 150,
		WeaponDamageMax = 150,
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 400,
		WeaponMaxDistance = 500,
		WeaponAmmo = "NoAmmo",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="Shoot",LastUsed=0},["F"]={Name="Shoot",LastUsed=0},["G"]={Name="Shoot",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Legendary
	};

	["HarpoonGun"] = {
		Name = "HarpoonGun",
		DisplayName = "Harpoon Gun",
		Model = "HarpoonGun", --TODO change to real HarpoonGun model
		Level = 10,
		Amount = 1,
		Desc = "It's a whale of a weapon",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true,["UnderWaterWeapon"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		Aim = false,
		WeaponDamageMin = 56,
		WeaponDamageMax = 80,
		WeaponSpeed = 20,
		WeaponAmmoSpeed = 50,
		WeaponMaxDistance = 500,
		WeaponAmmo = "Harpoon",
		WeaponAnimation = imageMap["Weapon"],
		WeaponAttacks = {["R"]={Name="Shoot",LastUsed=0},["F"]={Name="Shoot",LastUsed=0},["G"]={Name="Shoot",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 9*64,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};

	["BottleRocket"] = {
		Name = "BottleRocket",
		DisplayName = "Bottle Rocket",
		Model = "BottleRocket",
		Level = 11,
		Amount = 1,
		Desc = "Don't play with fireworks, defend with fireworks",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Ranged,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		Aim = true,
		FX = true,
		WeaponDamageMin = 24,
		WeaponDamageMax = 28,
		WeaponSpeed = 5,
		WeaponAmmoSpeed = 400,
		WeaponMaxDistance = 1000,
		WeaponAmmo = "Rocket",
		WeaponAnimation = "9923904224",
		WeaponAttacks = {["R"]={Name="FireRocket",LastUsed=0},["F"]={Name="FireRocket",LastUsed=0},["G"]={Name="FireRocket",LastUsed=0}},
		Value = 0,
		ImageOffsetX = 1*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
		Hand = "Right"
	};

}

return module
