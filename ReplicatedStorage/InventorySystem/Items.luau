--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events

--Functions
local InventorySystem = ReplicatedStorage:WaitForChild("InventorySystem")
local ItemDefs = InventorySystem:WaitForChild("ItemDefs")
--Types and subtypes


--TEMPLATE
--["Bat"] = {
--	Name = "Bat",
--	Level = 1,
--	Amount = 1,
--	Desc = "America's favorite pasttime, bashing stuff",
--	Type = "Weapon",
--	SubType = SubTypes.Weapon.Melee,
--	WeaponDamageMin = 1,
--	WeaponDamageMax = 1,
--	WeaponSpeed = 10,
--	WeaponAttacks = {["R"]={Name="Swing",LastUsed=0},["F"]={Name="OverheadSmash",LastUsed=0},["G"]={Name="PowerSwing",LastUsed=0}},
--	Value = 0,
--	ImageOffsetX = 14*128,
--	ImageOffsetY = 1*128,
--	Trade = false,
--	Limit = 1,
--	LootType = LootTypes.Specific,
--	Rarity = "Common"
--};


--Main Terrain Textures
--Rocks - rbxassetid://15803581119
--Main Building Textures

--Town1A - rbxgameasset://Images/PolygonTown_Texture_01_A rbxassetid://5220193520 count:196  
--Town1A DUPE - 5001147434	(brick Top Right)	count: 34
--Town1A DUPE -5219385463 (Siding Top Right) count:1
--Town1A DUPE:4970717525 count:39
--Town1A DUPE:5220193520 count:70
--Town1A DUPE 4970718409 count:11
--Town3A - rbxgameasset://Images/PolygonTown_Texture_03_A count:52
--Shops - 8199477136    count:143
--Shops Cobbles - 8199508114 count:34
--Shops Brick - 8199489556  count:183
--Farm rbxgameasset://Images/PolygonFarm_Texture_01_A count:51
--Shops Wood rbxassetid://8199492529 count:133
--Apoco1A 5075303276 count:67
--Apoco1A DUPE - rbxgameasset://Images/PolygonApocalypse_Texture_01_A count:26
--Apoco2C 5076852049 count:17
--Apoco4C 5076687674 count:11
--ApocoVehicle1A - 5169249924  - Images/PolygonApocalypse_Veh_Texture_01 count:20
--ApocoVehicle1 DUPE? rbxgameasset://Images/PolygonApocalypse_Veh_Texture_01 count:19 
--Apoco 5728194883 count:17
--Kid1A 5886620187 count:190
--Kid1A DUPE 5900950075 count:101
--Office1A - rbxgameasset://Images/PolygonOffice_Texture_01_A count:19
--Office1A DUPE - Images/PolygonOffice_Texture_01_A - 5736700771 count:82
--NonPolyTown - rbxgameasset://Images/T_colorPalette2048_CGT count:116
--NonPolyTown DUPE? rbxgameasset://Images/T_colorPalette2048 - 5610566946 count:187
--PolyZombie1A - Images/PolygonZombie_Texture_01_A - 5281519268 count:26
--Roads - 5610570121 count:75
--Some kind of brick? 5676335764 count:14
--Nature1 - PolygonNature_01 - 5251479922 count:10
--Nature4 PolyNature_04 5251482147 count:2

--House1 Couch rbxgameasset://Images/couch count:1

--GasStation Exterior/interior rbxassetid://5675854935

--House2 Bathroom Floor rbxassetid://5004337556

--Apoco something 5052503262 count:17

--MusicSpeakers (Radio Station Basement) rbxassetid://9304716260

--BankFloors rbxassetid://5613748800

--Mower - rbxassetid://4911083087

--GasStation Tile Floor - 5680737795 count:1

--TODO replace flower pots in build with Synty ones

--CITY NEWSPAPER - what texture? rbxassetid://9938275800 TODO replace

--8212789682 count:13 (store shelves only) -- needs removed

--Shovel rbxassetid://8989346207 count:4 TODO REPLACE
--Boombox rbxassetid://5227974548 - TODO maybe replace with synty
--Cactus1 - rbxassetid://5229631590 --needs retextured
--SINGLE OR LOW COUNT DUPES
--5219385463 - Change to Town1A rbxgameasset://Images/PolygonTown_Texture_01_A

--Roads rbxassetid://4627913212


local imageMap = {
	["Weapon"]="rbxassetid://124954524360448", 
	["Artifact"]="rbxassetid://124954524360448", 
	["OffHand"]="rbxassetid://124954524360448",	  --same as weapon
	["Ammo"]="rbxassetid://124954524360448",  --same as weapon
	["Tool"]="rbxassetid://100837309869874",
	["Clothing"]="rbxassetid://78125635248410",
	["Misc"]="rbxassetid://100366117316511",
	["PowerSource"]="rbxassetid://100366117316511", --same as misc
	["Disk"]="rbxassetid://100366117316511", --same as misc
	["Heal"]="rbxassetid://100366117316511", --same as misc
	["Trash"]="rbxassetid://100366117316511", --same as misc
	["Consumable"]="rbxassetid://135044387284181",
	["Material"]="rbxassetid://100366117316511", --same as misc
	["Access"]="rbxassetid://75333614406618",
	["Info"]="rbxassetid://100366117316511", --same as misc
	["TempHold"]="rbxassetid://100366117316511", --same as misc
	["Money"]="rbxassetid://100366117316511", --same as misc
	["QuestItem"]="rbxassetid://122175562772961",

};

local ItemTypes = {
	["Weapon"]="Weapon",
	["Artifact"]="Artifact",
	["OffHand"]="OffHand",
	["Ammo"]="Ammo",
	["Tool"]="Tool",
	["Clothing"]="Clothing",
	["Misc"]="Misc",
	["PowerSource"]="PowerSource",
	["Heal"]="Heal",
	["Trash"]="Trash",
	["Consumable"]="Consumable",
	["Material"]="Material",
	["Access"]="Access",
	["Info"]="Info",
	["TempHold"]="TempHold",
	["Money"]="Money",
	["QuestItem"]="QuestItem"

}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Weapon"]={
		["Melee"]="Melee",
		["Ranged"]="Ranged",
		["OffHand"]="OffHand",
		["None"]="",
	},
	["OffHand"]={["None"]="None"},
	["Artifact"]={["None"]=""},
	["Ammo"]={["None"]=""},
	["Tool"]={
		["None"]="",
		["Trap"]="Trap",
		["Container"]="Container", --Like WateringCan
	},
	["Clothing"]={
		["Head"]="Head",
		["Back"]="Back",
		["Accessory"]="Accessory",
		["None"]="",
	},
	["Misc"]={
		["Other"]="Other",
		["QuestItem"]="QuestItem",
		["Container"]="Container",
		["Collectible"]="Collectible",
		["Decor"]="Decor",
		["None"]="",
	},
	["Access"]={
		["Keycard"]="Keycard",
		["Retina"]="Lockpick",
		["DNA"]="DNA",
		["Ticket"]="Ticket",
		["None"]="",
	},
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
	["PowerSource"]={["None"]=""},
	["Heal"]={["None"]=""},
	["Trash"]={["None"]=""},
	["Consumable"]={
		["Food"]="Food",
		["Drink"]="Drink",
		["Poison"]="Poison",
		["Container"]="Container",
		["Ingredient"]="Ingredient",
		["None"]="",
	},
	["Material"]={
		["FlammableLiquid"]="FlammableLiquid",
		["Plastic"]="Plastic",
		["Metal"]="Metal",
		["Cloth"]="Cloth",
		["None"]="",
	},
	["TempHold"]={["None"]=""},
	["Money"]={["None"]=""},
	["QuestItem"]={["None"]=""},
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
	["ItemTypes"] = ItemTypes;
	
	--ImageSet=true,Accessible=True
	["PowerCell"] = {
		Name = "PowerCell",
		DisplayName = "PowerCell",
		PurchaseAmount = 1,
		Level = 1,
		Amount = 1,
		Desc = "Keeps going and going and going",
		Type = ItemTypes.PowerSource,
		SubType = SubTypes.PowerSource.None,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 2*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 999,
		ProductId = 1197745439,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	--ImageSet=True,Accessible=True
	["Bandaid"] = {
		Name = "Bandaid",
		DisplayName = "Bandaid",
		PurchaseAmount = 6,
		Level = 1,
		Amount = 1,
		Desc = "No need for a doctor",
		Type = ItemTypes.Heal,
		SubType = SubTypes.Heal.None,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 1*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Effects={Health=500,RemoveEffect="Bleed"},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	--ImageSet=True,Accessible=False
	["InterdimensionalContainmentBottle"] = {
		Name = "InterdimensionalContainmentBottle",
		DisplayName = "Interdimensional Containment Bottle",
		Level = 10,
		Amount = 1,
		Desc = "Bottle for containing interdimensional substances",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits={"Concealment"},
		ContainerSlots=1,
		Capacity=10,
		AllowedToContain="InterdimensionalLiquid",
		NeedToContain="Solid",
		Contains={},
		Value = 3,
		ImageOffsetX = 7*64,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 999,
		Stacks = false,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};
	
	--ImageSet=False,Accessible=False
	["PocketUniverse"] = {
		Name = "PocketUniverse",
		DisplayName = "Pocket Universe",
		Level = 10,
		Amount = 1,
		Desc = "Small opening to a tiny universe for the secret horder in you",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits={"Concealment"},
		ContainerSlots=4,
		Capacity=10,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 1000000,
		ImageOffsetX = 7*64,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 999,
		Stacks = false,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Legendary
	};
	
	--ImageSet=True,Accessible=False
	["InventoryImplant"] = {
		Name = "InventoryImplant",
		DisplayName = "Inventory Implant",
		Level = 10,
		Amount = 1,
		Desc = "Bigger on the Inside",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits={"Concealment"},
		ContainerSlots=1,
		Capacity=10,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 100000,
		ImageOffsetX = 4*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 999,
		Stacks = false,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};
	
	

	["MedKit"] = {
		Name = "MedKit",
		DisplayName = "MedKit",
		Level = 5,
		Amount = 1,
		Desc = "Combat healing in a box",
		Type = ItemTypes.Heal,
		SubType = SubTypes.Heal.None,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = 20,
		ImageOffsetX = 8*64,
		ImageOffsetY = 1*64,
		Trade = true,
		HealEffects={Health=1000,RemoveEffect="Bleed",RemoveEffect2="Hemorage"},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};
	
	["DuctTape"] = {
		Name = "DuctTape",
		DisplayName = "Duct Tape",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 10,
		Desc = "Fixes anything",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 6*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare
	};
	

	["PowerPlantBlueprint"] = {
		Name = "PowerPlantBlueprint",
		DisplayName = "Power Plant Blueprint",
		Level = 20,
		Amount = 1,
		Desc = "This should be helpful to find the location of the bathrooms",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.QuestItem,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = 20,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 999,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon
	};


	["ScrapMetal"] = {
		Name = "ScrapMetal",
		DisplayName = "Scrap Metal",
		Level = 0,
		Amount = 1,
		Desc = "Sharp rusted scrap pieces of metal",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.Metal,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = .05,
		ImageOffsetX = 10*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 999,
		ProductId = 1924530131,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["ScrapCloth"] = {
		Name = "ScrapCloth",
		DisplayName = "Scrap Cloth",
		Level = 0,
		Amount = 1,
		Desc = "A torn piece of cloth",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.Cloth,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = .05,
		ImageOffsetX = 10*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 999,
		ProductId = 1924530131,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["ScrapPlastic"] = {
		Name = "ScrapPlastic",
		DisplayName = "Scrap Plastic",
		Level = 0,
		Amount = 1,
		Desc = "Pieces of broken toys and packaging",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.Plastic,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = .05,
		ImageOffsetX = 10*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 999,
		ProductId = 1924530131,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};


	["Rocket"] = {
		Name = "Rocket",
		Model = "Rocket",
		DisplayName = "Rocket",
		Level = 3,
		Amount = 1,
		PurchaseAmount = 1,
		Desc = "For entertainment purposes only",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.Trap,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 13*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
		ToolAction1 = "Set",
		DeferAction = true,
	};

	["FuelCell"] = {
		Name = "FuelCell",
		DisplayName = "FuelCell",
		PurchaseAmount = 4,
		Level = 1,
		Amount = 1,
		Desc = "Keeps going and going and going",
		Type = ItemTypes.PowerSource,
		SubType = SubTypes.PowerSource.None,
		Traits = {["Solid"]=true},
		NeedToContain = "Solid",
		Value = .1,
		ImageOffsetX = 2*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 999,
		ProductId = 1197745439,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	--Used just to have required item for world object
	["Electricity"] = {
		Name = "Electricity",
		DisplayName = "Electricity",
		Level = 3,
		Amount = 1,
		Desc = "ZAP",
		Type = ItemTypes.Material,
		SubType= SubTypes.Material.None,
		Traits = {["Power"]=true},
		Value = 3,
		ImageOffsetX = 3*64,
		ImageOffsetY = 7*64,
		Trade = true,
		Limit = 999,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
	};

	["Chicken"] = {
		Name = "Chicken",
		DisplayName = "Chicken",
		Model = "Chicken",
		Level = 1,
		Amount = 1,
		Desc = "Leave the chicken alone",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits={},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 8*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["Cargo1"] = {
		Name = "Cargo1",
		DisplayName = "Cargo1",
		Model = "Cargo1",
		Level = 1,
		Amount = 1,
		Desc = "Unknown Cargo",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits={},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 8*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["Cargo2"] = {
		Name = "Cargo2",
		DisplayName = "Cargo2",
		Model = "Cargo2",
		Level = 1,
		Amount = 1,
		Desc = "Unknown Cargo",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits={},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 8*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["Cargo3"] = {
		Name = "Cargo3",
		DisplayName = "Cargo3",
		Model = "Cargo3",
		Level = 1,
		Amount = 1,
		Desc = "Unknown Cargo",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits={},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 8*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};
	
	["Cargo4"] = {
		Name = "Cargo4",
		DisplayName = "Cargo4",
		Model = "Cargo4",
		Level = 1,
		Amount = 1,
		Desc = "Unknown Cargo",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits={},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 8*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["Trashbag"] = {
		Name = "Trashbag",
		DisplayName = "Trashbag",
		Model = "Trashbag",
		Level = 1,
		Amount = 1,
		Desc = "Just disgusting",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits = {["Smelly"]=true},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 1,
		LootType = "None",
		Rarity = Rarity.Common
	};

	["Boombox"] = {
		Name = "Boombox",
		DisplayName = "Boombox",
		Model = "Boombox",
		Level = 1,
		Amount = 1,
		Desc = "Boom Boom Boom",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits = {["Electric"]=true,["Loud"]=true},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 1,
		LootType = "None",
		Rarity = Rarity.Common
	};

	["DeliveryCrate"] = {
		Name = "DeliveryCrate",
		DisplayName = "Delivery Crate",
		Model = "DeliveryCrate",
		Level = 1,
		Amount = 1,
		Desc = "Big Box",
		Type = ItemTypes.TempHold,
		SubType = SubTypes.TempHold.None,
		Traits = {},
		NeedToContain="Solid",
		NotInventory = true,
		Value = 0,
		ImageOffsetX = 13*64,
		ImageOffsetY = 5*64,
		Trade = false,
		Limit = 1,
		LootType = "None",
		Rarity = Rarity.Common
	};

	["Hairspray"] = {
		Name = "Hairspray",
		DisplayName = "Hairspray",
		Model = "Hairspray",
		Level = 1,
		Amount = 1,
		Desc = "Make your perm hold forever but don't get any in your eyes",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Melee,
		Traits={},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		Value = 0,
		VFX = true,
		WeaponDamageMin = 1,
		WeaponDamageMax = 2,
		WeaponSpeed = 10,
		WeaponAmmo = nil,
		WeaponAttacks = {["R"]={Name="Spray",LastUsed=0},["F"]={Name="Spray",LastUsed=0},["G"]={Name="Spray",LastUsed=0}},
		ImageOffsetX = 15*64,
		ImageOffsetY = 0,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["Pyrospray"] = {
		Name = "Pyrospray",
		DisplayName = "Pyrospray",
		Model = "Hairspray",
		Level = 5,
		Amount = 1,
		Desc = "Very flammable!",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Melee,
		Traits={},
		Effects={},
		Attributes={},
		VFX = true,
		NeedToContain="Solid",
		Value = 0,
		WeaponDamageMin = 11,
		WeaponDamageMax = 15,
		WeaponSpeed = 10,
		WeaponAmmo = "Matches",
		WeaponAttacks = {["R"]={Name="Flame",LastUsed=0},["F"]={Name="SelfDestruct",LastUsed=0},["G"]={Name="SelfDestruct",LastUsed=0}},
		ImageOffsetX = 14*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Crafted,
		Rarity = Rarity.Rare
	};

	["Camera"] = {
		Name = "Camera",
		DisplayName = "Camera",
		Model = "Camera",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 2,
		ToolAction1 = "Take Photo",
		ToolAction2 = "Selfie",
		Desc = "Lets tag some walls",
		Aim = true,
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 20,
		ImageOffsetX = 7*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Common,
	};
	
	["Flashlight"] = {
		Name = "Flashlight",
		DisplayName = "Flashlight",
		Model = "Flashlight",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 2,
		ToolAction1 = "Turn On / Off",
		Desc = "A handheld darkness-negotiation device. Emits a focused beam of reassurance, mild judgment, and exactly enough light to reveal whatever you wish you hadn’t seen",
		Aim = true,
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 20,
		ImageOffsetX = 8*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon,
		NewTool = true
	};


	["Spring"] = {
		Name = "Spring",
		DisplayName = "Spring",
		Level = 9,
		Amount = 1,
		Desc = "BOING",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 1*64,
		ImageOffsetY = 4*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Rare
	};

	["FryingPan"] = {
		Name = "FryingPan",
		DisplayName = "Frying Pan",
		Model = "FryingPan",
		Level = 2,
		Amount = 1,
		Desc = "If you can't take the heat, get out of the kitchen",
		Type = ItemTypes.Weapon,
		SubType = SubTypes.Weapon.Melee,
		Traits = {["Solid"]=true},
		Effects={},
		Attributes={},
		NeedToContain="Solid",
		WeaponDamageMin = 3, 
		WeaponDamageMax = 4,
		WeaponSpeed = 8,
		WeaponAttacks = {["R"]={Name="Swing",LastUsed=0},["F"]={Name="Scramble",LastUsed=0},["G"]={Name="Swing",LastUsed=0}},
		Value = 5,
		ImageOffsetX = 12*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Common
	};

	["MarshmellowStick"] = {
		Name = "MarshmellowStick",
		DisplayName = "Marshmellow Stick",
		Model = "MarshmellowStick",
		Level = 1,
		Amount = 1,
		Desc = "Let's set some ewy goey marshmellows on fire.",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Crafted,
		Rarity = Rarity.Uncommon
	};

	["Torch"] = {
		Name = "Torch",
		DisplayName = "Torch",
		Model = "Torch",
		Level = 1,
		Amount = 1,
		Desc = "Light it up!",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 7*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Crafted,
		Rarity = Rarity.Uncommon
	};

	["Wrench"] = {
		Name = "Wrench",
		DisplayName = "Wrench",
		Model = "Wrench",
		Level = 1,
		Amount = 1,
		Desc = "Great for tinkering with things",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 5*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon,
		ToolAction1 = "Fix",
	};

	["Screwdriver"] = {
		Name = "Screwdriver",
		DisplayName = "Screwdriver",
		Model = "Screwdriver",
		Level = 1,
		Amount = 1,
		Desc = "Loosen up",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon,
		ToolAction1 = "Screw",
	};

	["Plunger"] = {
		Name = "Plunger",
		DisplayName = "Plunger",
		Model = "Plunger",
		Level = 5,
		Amount = 1,
		Desc = "Plunge your way through any pipe",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 15*64,
		ImageOffsetY = 64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
	};

	["Crowbar"] = {
		Name = "Crowbar",
		DisplayName = "Crowbar",
		Model = "Crowbar",
		Level = 10,
		Amount = 1,
		Desc = "Pryer to this you could not open it",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 3*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon,
		ToolAction1 = "Pry",
	};

	["Wirecutters"] = {
		Name = "Wirecutters",
		DisplayName = "Wirecutters",
		Model = "Wirecutters",
		Level = 1,
		Amount = 1,
		Desc = "Snip Snip",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 7*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon,
	};

	["WalkieTalkie"] = {
		Name = "WalkieTalkie",
		DisplayName = "Walkie Talkie",
		Level = 1,
		Amount = 1,
		Desc = "The only way to communicate",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 11*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		EqualItems = {},
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon,
		ToolAction1 = "Talk",
	};

	["Cards"] = {
		Name = "Cards",
		DisplayName = "Cards",
		Level = 1,
		Amount = 1,
		Desc = "Guess my card",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 3,
		ImageOffsetX = 7*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	["Lighter"] = {
		Name = "Lighter",
		DisplayName = "Lighter",
		Model = "Lighter",
		Level = 10,
		Amount = 1,
		Desc = "",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Uncommon
	};

	["FakeLicense"] = {
		Name = "FakeLicense",
		DisplayName = "Fake License",
		Level = 1,
		Amount = 1,
		Desc = "A handwritten drivers license with your photo taped on",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 8*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Crafted,
		Rarity = Rarity.Rare,
	};

	["SchoolBackpack"] = {
		Name = "SchoolBackpack",
		DisplayName = "School Backpack",
		Level = 1,
		Amount = 1,
		Desc = "A bottomless bag of back breaking books",
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
		Capacity = 4,
		Armor = 3,
		ArmorLoad = 4,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Common
	};

	["LightBackpack"] = {
		Name = "LightBackpack",
		DisplayName = "Light Backpack",
		Level = 5,
		Amount = 1,
		Desc = "A light backpack that gets the job done",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 30,
		ImageOffsetX = 5*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "",
		Capacity = 8,
		Armor = 3,
		ArmorLoad = 1,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare
	};

	["CampingBackpack"] = {
		Name = "CampingBackpack",
		DisplayName = "Camping Backpack",
		Level = 7,
		Amount = 1,
		Desc = "A useful backpack with all sorts of camping gear",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 9*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "CampsiteSize_2x",
		Capacity = 12,
		Armor = 6,
		ArmorLoad = 3,
		LootType = LootTypes.Gamepass,
		Rarity = Rarity.Rare
	};

	["HikingBackpack"] = {
		Name = "HikingBackpack",
		DisplayName = "HikingBackpack",
		Level = 10,
		Amount = 1,
		Desc = "A backpack fit for hiking",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 9*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "",
		Capacity = 8,
		Armor = 5,
		ArmorLoad = 3,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Uncommon
	};

	["ScoutBackpack"] = {
		Name = "ScoutBackpack",
		DisplayName = "Scout Backpack",
		Level = 10,
		Amount = 1,
		Desc = "An official grizzly scout explorers backpack with built in compass",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "DiscoverXP_2x,FindTreasure_5%",
		Capacity = 8,
		Armor = 6,
		ArmorLoad = 3,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["RangerRickBackpack"] = {
		Name = "RangerRickBackpack",
		DisplayName = "Ranger Rick Backpack",
		Level = 15,
		Amount = 1,
		Desc = "The one and only backpack of the Woodland Ranger",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 10*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "DiscoverXP_2x,FindTreasure_5%,AnimalXP_2x",
		Capacity = 12,
		Armor = 6,
		ArmorLoad = 3,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["GoBag"] = {
		Name = "GoBag",
		DisplayName = "Go Bag",
		Level = 18,
		Amount = 1,
		Desc = "A backpack for the tiny prepper in you",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 100,
		ImageOffsetX = 8*64,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 1,
		Effect = "FindTreasure_20%",
		Capacity = 16,
		Armor = 8,
		ArmorLoad = 3,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};

	["SurvivalBackpack"] = {
		Name = "SurvivalBackpack",
		DisplayName = "Survival Backpack",
		Level = 20,
		Amount = 1,
		Desc = "A backpack prepared for a Zombie Apocalypse",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Back,
		Traits = {["Solid"]=true,["Backpack"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 7*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		Effect = "MeleeWeapons_5%,HealingRate_10%,FindTreasure_20%",
		Capacity = 16,
		Armor = 10,
		ArmorLoad = 5,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	--aligned
	["TrafficConeHelmet"] = {
		Name = "TrafficConeHelmet",
		DisplayName = "Traffic Cone Helmet",
		Level = 2,
		Amount = 1,
		Desc = "Nobody would dare violate your personal space",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effect = "",
		Armor = 1,
		ArmorLoad = 1,
		LootType = LootTypes.General,
		Rarity =   1, --"Common"
		YOffset =-.2,
		ZOffset =.2,
		KeepHair = true,
		TopOfHair = true
	};

	--aligned
	["Fez"] = {
		Name = "Fez",
		DisplayName = "Fez",
		Level = 5,
		Amount = 1,
		Desc = "The hat for those looking stylish while getting themselves killed",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 50,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effect = "Intelligence_+1,FindTreasure_5%",
		Armor = 2, --Armor rating is % reduction of damage from all types.
		ArmorLoad = 1, --Armor load allowed is determined by 3 + strength. So to wear this you would need 11 strength. So most classes would not be able to wear this.
		LootType = LootTypes.General,
		Rarity = Rarity.Epic,
		YOffset = -.2,
		ZOffset = -0.15,
		KeepHair = true,
		TopOfHair = true
	};

	--aligned
	["Headphones"] = {
		Name = "Headphones",
		DisplayName = "Headphones",
		Level = 5,
		Amount = 1,
		Desc = "Jamming to the beat while drowning out the rest",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 20,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effects={},
		Attributes={SoundResistance=20,CriticalHitChance=1},
		Armor = 1, --Armor rating is % reduction of damage from all types.
		ArmorLoad = 0, --Armor load allowed is determined by 3 + strength. So to wear this you would need 11 strength. So most classes would not be able to wear this.
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		YOffset = 1.1,
		ZOffset = -0.2,
		KeepHair = true
	};

	--aligned
	["GasMask"] = {
		Name = "GasMask",
		DisplayName = "GasMask",
		Level = 20,
		Amount = 1,
		Desc = "A gas proof mask",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 300,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effect = "GasResistance_100%",
		Armor = 3, --Armor rating is % reduction of damage from all types.
		ArmorLoad = 1, --Armor load allowed is determined by 3 + strength. So to wear this you would need 11 strength. So most classes would not be able to wear this.
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		KeepHair = true,
		YOffset = .9, --.9 --1.9
		ZOffset = -.2 -- -.2 
	};


	--aligned
	["HazmatMask"] = {
		Name = "HazmatMask",
		DisplayName = "Hazmat Mask",
		Level = 20,
		Amount = 1,
		Desc = "A gas, virus, and nanite proof mask",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 300,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effect = "GasResistance_100%,VirusResistance_100%,NaniteResistance_100%",
		Armor = 5, --Armor rating is % reduction of damage from all types.
		ArmorLoad = 2, --Armor load allowed is determined by 3 + strength. So to wear this you would need 11 strength. So most classes would not be able to wear this.
		LootType = LootTypes.General,
		Rarity = Rarity.Rare,
		YOffset = 0.95,
		ZOffset = -0.2
	};

	--aligned
	["WeldersMask"] = {
		Name = "WeldersMask",
		DisplayName = "Welders Mask",
		Level = 7,
		Amount = 1,
		Desc = "A fireproof welder's mask",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 300,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 1,
		Effect = "FireResistance_20%",
		Armor = 8, --Armor rating is % reduction of damage from all types.
		ArmorLoad = 6, --Armor load allowed is determined by 3 + strength. So to wear this you would need 11 strength. So most classes would not be able to wear this.
		LootType = LootTypes.General,
		Rarity = Rarity.Rare,
		KeepHair = true,
		YOffset = 0.9,
		Offset = -0.2
	};

	--aligned
	["3DGlasses"] = {
		Name = "3DGlasses",
		DisplayName = "3D Glasses",
		Level = 10,
		Amount = 1,
		Desc = "A pair of 3D glasses. See a 2D world inside a 3D world in 3D!",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 30,
		ImageOffsetX = 1*64,
		ImageOffsetY = 0,
		Trade = false,
		Limit = 1,
		Effect = "Perception_2,GhostView",
		Armor = 1,
		ArmorLoad = 1,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Epic,
		YOffset = 1,
		ZOffset = -.2
	};

	["AlienMask"] = {
		Name = "AlienMask",
		DisplayName = "Alien Mask",
		Level = 5,
		Amount = 1,
		Desc = "A scary green alien mask",
		Type = ItemTypes.Clothing,
		SubType = SubTypes.Clothing.Head,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 30,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = false,
		Limit = 1,
		Effect = "AlienHidden,AlienSpeech_10%",
		Armor = 4,
		ArmorLoad = 1,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Rare,
		YOffset = 0.5,
		ZOffset = -0.05
	};

	["RustyZapColaCan"] = {
		Name = "RustyZapColaCan",
		DisplayName = "Rusty Zap Cola Can",
		Level = 1,
		Amount = 1,
		Desc = "A rusty vintage Zap Cola can",
		Type = ItemTypes.Trash,
		SubType = SubTypes.Trash.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 4*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Trash
	};

	["ToiletPaper"] = {
		Name = "ToiletPaper",
		DisplayName = "Toilet Paper",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 1,
		Desc = "Currency of the Apocalypse",
		Type = ItemTypes.Trash,
		SubType = SubTypes.Trash.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 9*64,
		ImageOffsetY = 4*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Trash
	};

	["Lockbox"] = {
		Name = "Lockbox",
		DisplayName = "Lockbox",
		Level = 1,
		Amount = 1,
		Desc = "What could be inside?",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=3,
		Capacity=99,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 50,
		ImageOffsetX = 10*64,
		ImageOffsetY = 4*64,
		Trade = true,
		Limit = 1,
		Stacks=false,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["EmpireLunchbox"] = {
		Name = "EmpireLunchbox",
		DisplayName = "Empire Lunchbox",
		Level = 1,
		Amount = 1,
		Desc = "Lunchbox from the movie the Empire Strikes Out",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=2,
		Capacity=99,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 1,
		Stacks=false,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};

	["ETLunchbox"] = {
		Name = "ETLunchbox",
		DisplayName = "ET Lunchbox",
		Level = 1,
		Amount = 1,
		Desc = "Lunchbox from the movie the Extra Trouble",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=2,
		Capacity=99,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 2*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 1,
		Stacks=false,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Rare
	};

	["Gift1"] = {
		Name = "Gift1",
		DisplayName = "Gift1",
		Level = 1,
		Amount = 1,
		Desc = "A blue gift with a purple bow",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=1,
		Capacity=1,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 5*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["Gift2"] = {
		Name = "Gift2",
		DisplayName = "Gift2",
		Level = 1,
		Amount = 1,
		Desc = "A green gift with a yellow bow",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=1,
		Capacity=1,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 6*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["Gift3"] = {
		Name = "Gift3",
		DisplayName = "Gift3",
		Level = 1,
		Amount = 1,
		Desc = "A aqua colored gift with a purple bow",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=1,
		Capacity=1,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 7*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["Gift4"] = {
		Name = "Gift4",
		DisplayName = "Gift4",
		Level = 1,
		Amount = 1,
		Desc = "A red gift with a green ribbon and yellow bow",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=1,
		Capacity=1,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 20,
		ImageOffsetX = 8*64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	["TimeCapsule"] = {
		Name = "TimeCapsule",
		DisplayName = "Time Capsule",
		Level = 1,
		Amount = 1,
		Desc = "A capsule that traps time itself!",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Container,
		Traits = {},
		ContainerSlots=3,
		Capacity=3,
		AllowedToContain="Solid",
		NeedToContain="Solid",
		Contains={},
		Value = 10,
		ImageOffsetX = 1*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	--Set
	

	["MonkeyKeychain"] = {
		Name = "MonkeyKeychain",
		DisplayName = "Monkey Keychain",
		Level = 1,
		Amount = 1,
		Desc = "A silly monkey on a keychain",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "KeyChains"
	};

	["TradingCard1"] = {
		Name = "TradingCard1",
		DisplayName = "Trading Card 1",
		Level = 1,
		Amount = 1,
		Desc = "A kraken card from the Beast Battles Trading Card Collection",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "TradingCards"
	};

	["TradingCard2"] = {
		Name = "TradingCard2",
		DisplayName = "Trading Card 2",
		Level = 1,
		Amount = 1,
		Desc = "A Stone Golem card from the Beast Battles Trading Card Collection",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible, 
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "TradingCards"
	};

	["TradingCard3"] = {
		Name = "TradingCard3",
		DisplayName = "Trading Card 3",
		Level = 1,
		Amount = 1,
		Desc = "A Vampire card from the Beast Battles Trading Card Collection",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "TradingCards"
	};

	["CatKeychain"] = {
		Name = "CatKeychain",
		DisplayName = "Cat Keychain",
		Level = 1,
		Amount = 1,
		Desc = "A black cat on a keychain",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "KeyChains"
	};

	["PandaKeychain"] = {
		Name = "PandaKeychain",
		DisplayName = "Panda Keychain",
		Level = 1,
		Amount = 1,
		Desc = "A panda on a keychain",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "KeyChains"
	};

	["DogKeychain"] = {
		Name = "DogKeychain",
		DisplayName = "Dog Keychain",
		Level = 1,
		Amount = 1,
		Desc = "A brown dog on a keychain",
		Type = ItemTypes.Misc,
		SubType = SubTypes.Misc.Collectible,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "KeyChains"
	};

	["Balloon"] = {
		Name = "Balloon",
		DisplayName = "Balloon",
		Model = "Balloon",
		Level = 1,
		Amount = 1,
		PurchaseAmount = 1,
		Desc = "Want a balloon?",
		Type = ItemTypes.Tool,
		SubType = SubTypes.Tool.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 20,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon,
		ToolAction1 = "Deploy",
	};

	["SpiderEye"] = {
		Name = "SpiderEye",
		DisplayName = "Spider Eye",
		Level = 3,
		Amount = 1,
		Desc = "Umm. Grose",
		Type = ItemTypes.Material,
		SubType = SubTypes.Material.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Trash
	};	

	["Credit"] = {
		Name = "Credit",
		DisplayName = "Credit",
		Level = 1,
		Amount = 1,
		Desc = "Money Money Money",
		Type = ItemTypes.Money,
		SubType = SubTypes.Money.None,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = .05,
		ImageOffsetX = 15*64,
		ImageOffsetY = 0*64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};		


}

local sources = {
	require(ItemDefs:WaitForChild("Weapons")),
	require(ItemDefs:WaitForChild("Artifacts")),
	require(ItemDefs:WaitForChild("Ammo")),
	require(ItemDefs:WaitForChild("Info")),
	require(ItemDefs:WaitForChild("Access")),
	require(ItemDefs:WaitForChild("Consumables")),
	require(ItemDefs:WaitForChild("Materials")),
	require(ItemDefs:WaitForChild("Clothing")),
}

local function merge(sourceTable)
	for id, def in pairs(sourceTable) do
		if module[id] then
			warn(("[Items.Registry] Duplicate item id '%s' found. Keeping first."):format(id))
		else
			module[id] = def
		end
	end
end

for _, src in ipairs(sources) do
	merge(src)
end

return module
