local imageMap = {
	["Ammo"]="rbxassetid://124954524360448",  --same as weapon
};

local ItemTypes = {
	["Material"]="Material",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Material"]={
		["FlammableLiquid"]="FlammableLiquid",
		["Plastic"]="Plastic",
		["Metal"]="Metal",
		["Cloth"]="Cloth",
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

local IngredientTypes = {
	["Sweetner"]="Sweetner",
	["Meat"]="Meat",  
	["vegetable "]="vegetable ", 
	["Fruit"]="Fruit", 
	["Spice"]="Spice", 
	["Cheese"]="Cheese",
	["Base"]="Base", 
}

local colorMap = {
	["Blue"] =  Color3.fromRGB(25,218,231),
	["Orange"] = Color3.fromRGB(231,175,27),
}

local module = {

	["ImageMap"] = imageMap;
	["Rarities"] = rarityMap;
	["ColorMap"] = colorMap;

	--ImageSet=True,Accessible=True
	["GreenCircuitBoard"] = {
		Name = "GreenCircuitBoard",
		DisplayName = "Green Circuit Board",
		Level = 10,
		Amount = 1,
		Desc = "Usefull in all sorts of electronic devices",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 200,
		ImageOffsetX = 13*64,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	--ImageSet=True,Accessible=True
	["BlueCircuitBoard"] = {
		Name = "BlueCircuitBoard",
		DisplayName = "Blue Circuit Board",
		Level = 10,
		Amount = 1,
		Desc = "Usefull in all sorts of robotics and AI",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 500,
		ImageOffsetX = 12*64,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Rare
	};
	
	--ImageSet=True,Accessible=True
	["Wires"] = {
		Name = "Wires",
		DisplayName = "Wires",
		Level = 10,
		Amount = 1,
		Desc = "Wire it up",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 5,
		ImageOffsetX = 3*64,
		ImageOffsetY = 5*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};


	
}

return module
