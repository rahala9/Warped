local imageMap = {
	["Info"]="rbxassetid://100366117316511", --same as misc
};

local ItemTypes = {
	["Info"]="Info",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Info"]={
		["StickyNote"]="StickyNote",
		["Paper"]="Paper",
		["Disk"]="Disk",
		["Cassette"]="Cassette",
		["Document"]="Document", --Folder
		["Photo"]="Photo",
		["Map"]="Map",
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

	["Disk1"] = {
		Name = "Disk1",
		DisplayName = "Disk1",
		Level = 1,
		Amount = 1,
		Desc = "Top of the line floppy disk with more than a whole megabyte of space!",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 5*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon
	};

	["Disk2"] = {
		Name = "Disk2",
		DisplayName = "Disk2",
		Level = 16,
		Amount = 1,
		Desc = "Special Recipes is written in pencil on the label",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["Disk3"] = {
		Name = "Disk3",
		DisplayName = "Disk3",
		Level = 7,
		Amount = 1,
		Desc = "Outer Space Quest 5 Disk 3 of 50",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["Disk4"] = {
		Name = "Disk4",
		DisplayName = "Disk4",
		Level = 19,
		Amount = 1,
		Desc = "The label contains a series of unknown symbols",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};

	["Disk5"] = {
		Name = "Disk5",
		DisplayName = "Disk5",
		Level = 20,
		Amount = 1,
		Desc = "TOP SECRET is written on the label in black sharpy",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Legendary
	};
	
	["StolenDisk"] = {
		Name = "StolenDisk",
		DisplayName = "StolenDisk",
		Level = 20,
		Amount = 1,
		Desc = "Stolen Data Disk",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Disk,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = false,
		Illicit = true,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Legendary
	};

	["Selfie"] = {
		Name = "Selfie",
		DisplayName = "Selfie",
		Level = 20,
		Amount = 1,
		Desc = "You just love taking pictures of yourself, don't you?",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Photo,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 15*64,
		ImageOffsetY = 6*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common
	};
	
	["ZombieNote"] = {
		Name = "ZombieNote",
		DisplayName = "Zombie Note",
		Level = 1,
		Amount = 1,
		Desc = "Mary, if you find this, I have not felt well lately.  I think when Jeff bit me, it gave me some kind of fever.  I've been craving.....BRAINS!'",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.StickyNote,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 1*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["BlankTape"] = {
		Name = "BlankTape",
		DisplayName = "Blank Tape",
		Level = 2,
		Amount = 1,
		Desc = "",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Cassette,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 5*64,
		ImageOffsetY = 4*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["SecretTape"] = {
		Name = "SecretTape",
		DisplayName = "Cassette tape marked Secret",
		Level = 2,
		Amount = 1,
		Desc = "",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Cassette,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 7*64,
		ImageOffsetY = 4*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["DeathRatsMixedTape"] = {
		Name = "DeathRatsMixedTape",
		DisplayName = "Death Rats Mixed Tape",
		Level = 1,
		Amount = 1,
		Desc = "Probe the Globe",
		Type = ItemTypes.Info,
		SubType = SubTypes.Info.Cassette,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 6*64,
		ImageOffsetY = 4*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon
	};
	
	
}

return module
