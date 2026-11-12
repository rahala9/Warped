

local imageMap = {
	["Artifact"]="rbxassetid://124954524360448", 
};

local ItemTypes = {
	["Artifact"]="Artifact",
}


local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Artifact"]={
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

	["Electricasm"] = {
		Name = "Electricasm",
		DisplayName = "Electricasm",
		Model = "Electricasm",
		Amount = 1,
		Desc = "Zap!",
		Type = ItemTypes.Artifact,
		SubType = SubTypes.Artifact.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Aim = false,
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 3*64,
		Trade = true,
		LootType = LootTypes.Quest,
		Rarity= Rarity.Rare,
		Limit = 1,
	};

	["ProbabilityManipulator"] = {
		Name = "ProbabilityManipulator",
		DisplayName = "Probability Manipulator",
		Model = "NerdCube",
		Amount = 1,
		Desc = "This strange ancient device is thought to have the power to change chance,override odds,lasso luck, and foil fate. ",
		Type = ItemTypes.Artifact,
		SubType = SubTypes.Artifact.None,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={SkillBonus={Skill="All",Value="3"}},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 15*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		Illicit = true,
		LootType = LootTypes.General,
		Rarity = Rarity.Rare,
		Hand = "Left"
	};

}

return module
