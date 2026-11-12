

local imageMap = {
	["Ammo"]="rbxassetid://124954524360448",  --same as weapon
};

local ItemTypes = {
	["Ammo"]="Ammo",
}


local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
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

	["Dart"] = {
		Name = "Dart",
		DisplayName = "Dart",
		Level = 1,
		Amount = 1,
		Desc = "Fun to shoot, impossible to find",
		Type = ItemTypes.Ammo,
		SubType = SubTypes.Ammo.None,
		Traits={},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 100,
		ProductId = 10117941467,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	["Laser"] = {
		Name = "Laser",
		DisplayName = "Laser",
		Level = 1,
		Amount = 1,
		Desc = "For burny action",
		Type = ItemTypes.Ammo,
		SubType = SubTypes.Ammo.None,
		Traits={},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 100,
		ProductId = 10117941467,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	["MonkeyWrench"] = {
		Name = "MonkeyWrench",
		DisplayName = "Monkey Wrench",
		Level = 1,
		Amount = 1,
		Desc = "Good for throwing",
		Type = ItemTypes.Ammo,
		SubType = SubTypes.Ammo.None,
		Traits={},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 100,
		ProductId = 10117941467,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	
}

return module
