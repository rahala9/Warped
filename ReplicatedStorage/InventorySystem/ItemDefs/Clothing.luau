local imageMap = {
	["Clothing"]="rbxassetid://78125635248410",  --same as weapon
};

local ItemTypes = {
	["Clothing"]="Clothing",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Clothing"]={
		["Head"]="Head",
		["Back"]="Back",
		["Face"]="Face",
		["Shoulder"]="Shoulder",
		["Forearm"]="Forearm",
		["None"]="",
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

	["JetBox"] = {
		Name = "JetBox",
		Model = "JetBox",
		DisplayName = "Jet Box",
		Level = 1,
		Amount = 1,
		Desc = "Just a children's toy",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 1, --Extra storage
		Armor = 0,
		JetPower = 30,
		JetMaxVelocity = 10,
		JetFlightTime = 7,
		JetRecharge = 0.1,
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["HopperJ7"] = {
		Name = "HopperJ7",
		Model = "HopperJ7",
		DisplayName = "HopperJ7",
		Level = 1,
		Amount = 1,
		Desc = "Aerotek B-Series Jetpack",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 2, --Extra storage
		Armor = 1,
		JetPower = 50,
		JetMaxVelocity = 10,
		JetFlightTime = 10,
		JetRecharge = 0.1,
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};
	
	["SkyBound"] = {
		Name = "SkyBound",
		Model = "Vacpac_Jetpack01",
		DisplayName = "SkyBound",
		Level = 1,
		Amount = 1,
		Desc = "Aerotek A-Series Jetpack",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 3, --Extra storage
		Armor = 5,
		JetPower = 100,
		JetMaxVelocity = 20,
		JetFlightTime = 15,
		JetRecharge = 0.5,
		Action = "",
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare
	};
	
	["SkyBoundPro"] = {
		Name = "SkyBoundPro",
		Model = "Vacpac_Jetpack01",
		DisplayName = "SkyBound Pro",
		Level = 1,
		Amount = 1,
		Desc = "Aerotek V-Series Jetpack",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 4, --Extra storage
		Armor = 5,
		JetPower = 200,
		JetMaxVelocity = 40,
		JetFlightTime = 20,
		JetRecharge = 0.5,
		Action = "",
		LootType = LootTypes.Purchase, --Robux
		Rarity = Rarity.Rare
	};
	
	["FalconX"] = {
		Name = "FalconX",
		Model = "FalconX",
		DisplayName = "Falcon X",
		Level = 1,
		Amount = 1,
		Desc = "Custom acrobatic flight pac used by the SkyWinders",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 5, --Extra storage
		Armor = 5,
		JetPower = 250,
		JetMaxVelocity = 80,
		JetFlightTime = 25,
		JetRecharge = 1,
		JetAcrobatics = true,
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};
	
	["VulcanVac"] = {
		Name = "VulcanVac",
		Model = "Vacpac_Vulcan",
		DisplayName = "Vulcan Vac",
		Level = 1,
		Amount = 1,
		Desc = "Hurt Co. Vulcan Vac Pac Mark II",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Capacity = 3, --Extra storage
		Armor = 5,
		Action = "VulcanFire",
		LootType = LootTypes.Purchase, --Robux
		Rarity = Rarity.Epic
	};
	
	["CyberSkull"] = {
		Name = "CyberSkull",
		Model = "Mask_CyberSkull",
		DisplayName = "Cyber Skull",
		Level = 1,
		Amount = 1,
		Desc = "Favored by the Glitch for both anonymity and analysis",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Face,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Armor = 2,
		Resistances = {["Toxic"]=5,["Radiation"]=5},
		OxygenDelivery = true,
		Nightvision = true,
		ThermalDetection = true,
		Magnification = true,
		TargetAnalysis = {["PlayerStats"]=true,["EnemyStats"]=true,["HackingStats"]=true,["EnvironmentStats"]=false},
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["MiragiVeil"] = {
		Name = "MiragiVeil",
		Model = "Mask_HorizontalVisor_BreathSlots",
		DisplayName = "Miragi Veil",
		Level = 1,
		Amount = 1,
		Desc = "Built to protect against the radiaton fields of Yagmar IV",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Face,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Armor = 3,
		Resistances = {["Toxic"]=0,["Radiation"]=50},
		OxygenDelivery = true,
		Nightvision = true,
		ThermalDetection = false,
		Magnification = true,
		TargetAnalysis = {["PlayerStats"]=false,["EnemyStats"]=false,["HackingStats"]=false,["EnvironmentStats"]=true},
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};
	
	["AdvancedRebreather"] = {
		Name = "AdvancedRebreather",
		Model = "Mask_AdvancedRebreather",
		DisplayName = "AdvancedRebreather",
		Level = 1,
		Amount = 1,
		Desc = "Sci co Advanced Rebreather",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Face,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = nil,
		Armor = 2,
		Resistances = {["Toxic"]=10,["Radiation"]=10},
		OxygenDelivery = true,
		Nightvision = false,
		ThermalDetection = false,
		Magnification = false,
		TargetAnalysis = {["PlayerStats"]=false,["EnemyStats"]=false,["HackingStats"]=false,["EnvironmentStats"]=false},
		Action = "",
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon
	};




	

	
}

return module
