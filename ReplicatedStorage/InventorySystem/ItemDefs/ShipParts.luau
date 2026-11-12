local imageMap = {
	["ShipPart"]="rbxassetid://75333614406618",
};

local ItemTypes = {
	["ShipPart"]="ShipPart",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["ShipPart"]={
		["ShipSensor"]="ShipSensor",
		["ShipEngine"]="ShipEngine",
		["ShipWeapon"]="ShipWeapon",
		["ShipComm"]="ShipComm",
		["ShipShield"]="ShipShield",
	},
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

local module = {

	["ImageMap"] = imageMap;
	["Rarities"] = rarityMap;
	["ColorMap"] = colorMap;


---------------------------------------
-------------Sensors-------------------
---------------------------------------
	
	--ImageSet=False,Accessible=False
	["JNKSensorRadar"] = {
		Name = "JNKSensorRadar",
		DisplayName = "JNK Sensor Radar",
		Level = 1,
		Amount = 1,
		Desc = "Basic Radar",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 200,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common,
		SensorRange = 2000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = false,
		SensorAR = false, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = false, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships
		
	};
	
	--ImageSet=False,Accessible=False
	["SciCoSensorRadar"] = {
		Name = "SciCoSensorRadar",
		DisplayName = "Sci Co Sensor Radar",
		Level = 1,
		Amount = 1,
		Desc = "Standard Sci Co Radar with target identification",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 500,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common,
		SensorRange = 3000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = false, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = false, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SciCoSensorRadarV2"] = {
		Name = "SciCoSensorRadarV2",
		DisplayName = "Sci Co Sensor Radar V2",
		Level = 1,
		Amount = 1,
		Desc = "New Standard Sci Co Radar with extended Range",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 800,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon,
		SensorRange = 4000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = false, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = false, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SciCoSensorArray"] = {
		Name = "SciCoSensorArray",
		DisplayName = "Sci Co Sensor Array",
		Level = 1,
		Amount = 2000,
		Desc = "Standard Sci Co Sensor Array with augmented reality HUD markers",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon,
		SensorRange = 7000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["TologySensorArray"] = {
		Name = "TologySensorArray",
		DisplayName = "Tology Sensor Array",
		Level = 1,
		Amount = 1,
		Desc = "Augmented HUD identification by Tology Inc.",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 3000,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon,
		SensorRange = 7000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["FunCoSensorArray"] = {
		Name = "FunCoSensorArray",
		DisplayName = "Fun Co Sensor Array",
		Level = 1,
		Amount = 3500,
		Desc = "Advanced sensor array by Fun Co",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		SensorRange = 10000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = true,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SalvageSensorArray"] = {
		Name = "SalvageSensorArray",
		DisplayName = "Salvage Sensor Array",
		Level = 1,
		Amount = 3500,
		Desc = "Standard Salvage Recovery Sensor System",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		SensorRange = 5000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = false, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SalvageSensorArrayMK2"] = {
		Name = "SalvageSensorArrayMK2",
		DisplayName = "Salvage Sensor Array MK2",
		Level = 1,
		Amount = 3500,
		Desc = "Standard Salvage Recovery Sensor System with threat detection",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		SensorRange = 5000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = false,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["HurtCoCombatSensorArray"] = {
		Name = "HurtCoCombatSensorArray",
		DisplayName = "Hurt Co Combat Sensor Array",
		Level = 1,
		Amount = 1,
		Desc = "Standard combat sensor system by Hurt Co, the pain delivery company",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 10000,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		SensorRange = 5000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = true,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["HurtCoAdvancedCombatSensor"] = {
		Name = "HurtCoAdvancedCombatSensor",
		DisplayName = "Hurt Co Advanced Combat Sensor",
		Level = 1,
		Amount = 20000,
		Desc = "Advanced combat sensor system by Hurt Co, the pain delivery company",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		SensorRange = 7000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = true,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = true,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = true,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SearchAndRecoverySensorSystem"] = {
		Name = "SearchAndRecoverySensorSystem",
		DisplayName = "Search And Recovery Sensor System",
		Level = 1,
		Amount = 20000,
		Desc = "Sensor System used for rescue, salvage, recon, and just plain stealing",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Epic,
		SensorRange = 20000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = true,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = false,
		SensorARThreatEval = false, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SearchAndRecoverySensorSystemTD"] = {
		Name = "SearchAndRecoverySensorSystemTD",
		DisplayName = "Search And Recovery Sensor System TD",
		Level = 1,
		Amount = 20000,
		Desc = "Sensor System used for search and recovery with threat detection addon",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Epic,
		SensorRange = 20000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = true,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = false,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
		
	--ImageSet=False,Accessible=False
	["MKUltraSensorArray"] = {
		Name = "MKUltraSensorArray",
		DisplayName = "MK Ultra Sensor Array",
		Level = 1,
		Amount = 1,
		Desc = "Basic Radar",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 50000,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Epic,
		SensorRange = 15000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = true,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = true,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = false,
		SensorARProjectileTracking = true,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["PirateRadar"] = {
		Name = "PirateRadar",
		DisplayName = "PirateRadar",
		Level = 1,
		Amount = 10000,
		Desc = "Pirate illegal anti-cloaking detection",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = true,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Epic,
		SensorRange = 15000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = false, --augmented reality
		SensorARIdentityType = false,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = false,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = true, --On AR and Radar
		SensorARProjectileTracking = false,
		SensorARSalvage = false, --Can identify smaller items/loot in space or on board ships

	};
	
	--ImageSet=False,Accessible=False
	["SensitivePirate"] = {
		Name = "SensitivePirate",
		DisplayName = "SensitivePirate",
		Level = 1,
		Amount = 1,
		Desc = "Legendary custom radar systems used by space pirates",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 50000,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = true,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Legendary,
		SensorRange = 15000, --In STUDS
		SensorRadar = true,
		SensorRadarIdentityType = true,
		SensorAR = true, --augmented reality
		SensorARIdentityType = true,
		SensorARIdentityName = false,
		SensorARHullAndShieldHealth = true,
		SensorARIdentitySystems = true,
		SensorARThreatEval = true, --Displays analysis of threat level (enemy weapons, shields etc. compared to players)
		SensorCloakDetection = true,
		SensorARProjectileTracking = true,
		SensorARSalvage = true, --Can identify smaller items/loot in space or on board ships

	};
	
	---------------------------------------
	-------------Engines-------------------
	---------------------------------------
	
	--ImageSet=False,Accessible=False
	["JNKEngine"] = {
		Name = "JNKEngine",
		DisplayName = "JNK Engine",
		Level = 1,
		Amount = 1,
		Desc = "Basic Engine that can barely make escape velocity",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 200,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common,
		EngineSpeed = 100,
		EngineBoost = 0,
		EngineAcceleration = 1,
		EngineBrakeStrength = 1.0,
		EngineWarpSpeed = 0,

	};
	
	["SciCoSpeedsterEngine"] = {
		Name = "SciCoSpeedsterEngine",
		DisplayName = "Sci Co Speedster Engine",
		Level = 1,
		Amount = 1,
		Desc = "Standard Sci Co Engine rebranded with zero improvement",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 200,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common,
		EngineSpeed = 200,
		EngineBoost = 300,
		EngineAcceleration = 1,
		EngineBrakeStrength = 1.0,
		EngineWarpSpeed = 0,

	};
	
	["SciCoDeluxEngine"] = {
		Name = "SciCoDeluxEngine",
		DisplayName = "Sci Co Delux Engine",
		Level = 1,
		Amount = 1,
		Desc = "Delux Sci Co Engine",
		Type = ItemTypes.ShipPart,
		SubType = SubTypes.ShipPart.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 200,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Illicit = false,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common,
		EngineSpeed = 250,
		EngineBoost = 350,
		EngineAcceleration = 2,
		EngineBrakeStrength = 1.0,
		EngineWarpSpeed = 0,

	};
	
	---------------------------------------
	-------------Weapons-------------------
	---------------------------------------
	
	
	---------------------------------------
	-------------Shields-------------------
	---------------------------------------
	
	
	---------------------------------------
	-------------Comms-------------------
	---------------------------------------
	
}

return module
