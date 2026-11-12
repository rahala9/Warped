local imageMap = {
	["Consumables"]="rbxassetid://135044387284181",  --same as weapon
};

local ItemTypes = {
	["Consumable"]="Consumable",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Consumable"]={
		["Food"]="Food",
		["Drink"]="Drink",
		["Poison"]="Poison",
		["Container"]="Container",
		["Ingredient"]="Ingredient",
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

	["Apple"] = {
		Name = "Apple",
		DisplayName = "Apple",
		Level = 0,
		Amount = 1,
		Desc = "A healthy apple",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		IngredientType = IngredientTypes.Fruit,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 8*64,
		ImageOffsetY = 2*64,
		Trade = true,
		ConsumeEffects={SmallFood=5,AddItem="AppleCore"},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	["Cheese"] = {
		Name = "Cheese",
		DisplayName = "Cheese",
		Level = 0,
		Amount = 1,
		Desc = "Just the smell of cheese and I lose control!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Cheese,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 13*64,
		ImageOffsetY = 2*64,
		Trade = true,
		ConsumeEffects={SmallFood=10},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	["Salt"] = {
		Name = "Salt",
		DisplayName = "Salt",
		Level = 0,
		Amount = 1,
		Desc = "#1 Flavor Enhancer",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Spice,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 4*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	["Pepper"] = {
		Name = "Pepper",
		DisplayName = "Pepper",
		Level = 0,
		Amount = 1,
		Desc = "Hacheww",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Spice,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 5*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	["SpecialBlend"] = {
		Name = "SpecialBlend",
		DisplayName = "Special Blend",
		Level = 0,
		Amount = 1,
		Desc = "A special blend of spices",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Spice,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 8*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={},
		Limit = 999,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common
	};
	
	["RawChicken"] = {
		Name = "RawChicken",
		DisplayName = "Raw Chicken",
		Level = 0,
		Amount = 1,
		Desc = "Chicken",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Meat,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 3*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={Poison=1},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	["BronzeMetalMushroom"] = {
		Name = "BronzeMetalMushroom",
		DisplayName = "Bronze Metal Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "A smelly mushroom with a shiny bronze color",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 1,
		ImageOffsetX = 64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={SmallFood=10},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common,
		Collection = "Mushrooms"
	};

	["GoldyMushroom"] = {
		Name = "GoldyMushroom",
		DisplayName = "Goldy Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "A golden mushroom with a wonderful aroma",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 30,
		ImageOffsetX = 5*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={LargeFood=100},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Rare,
		Collection = "Mushrooms"
	};

	["TummyMushroom"] = {
		Name = "TummyMushroom",
		DisplayName = "Tummy Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "A normal white cap yummy mushroom",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 7*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={TinyFood=1},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common,
		Collection = "Mushrooms"
	};

	["ReddyEddyMushroom"] = {
		Name = "ReddyEddyMushroom",
		DisplayName = "Reddy Eddy Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "Named after the late Eddy May who first discovered this mushroom",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true,["Poison"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 4*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={Poison=2},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "Mushrooms"
	};

	["SpottedJoeMushroom"] = {
		Name = "SpottedJoeMushroom",
		DisplayName = "Spotted Joe Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "See the spots",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true,["Poison"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 6*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={Poison=-5,Dizzy=true},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "Mushrooms"
	};

	["PoltergeistMushroom"] = {
		Name = "PoltergeistMushroom",
		DisplayName = "Poltergeist Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "See the spots",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true,["Poison"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 8*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={Poison=3},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common,
		Collection = "Mushrooms"
	};

	["CaptainMyCaptainMushroom"] = {
		Name = "CaptainMyCaptainMushroom",
		DisplayName = "Captain My Captain Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "The captain of the mushrooms",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 10,
		ImageOffsetX = 64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={LargeFood=100,Strength=1},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon,
		Collection = "Mushrooms"
	};

	["TidalWaveMushroom"] = {
		Name = "TidalWaveMushroom",
		DisplayName = "Tidal Wave Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "Ride the wave",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 10,
		ImageOffsetX = 2*64,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={SmallFood=10},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common,
		Collection = "Mushrooms"
	};

	["SwitchBladeMushroom"] = {
		Name = "SwitchBladeMushroom",
		DisplayName = "Switch Blade Mushroom",
		Level = 0,
		Amount = 1,
		Desc = "A nice mushroom grown on the side of tree bark",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Veggitable,
		Traits = {["Solid"]=true,["Consumable"]=true,["Poison"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 0,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={Poison=10},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Common,
		Collection = "Mushrooms"
	};
	
	["Winkie"] = {
		Name = "Winkie",
		DisplayName = "Winkie",
		Level = 5,
		Amount = 1,
		PurchaseAmount = 1,
		Desc = "Wink all day with a Winkie!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 3*64,
		ImageOffsetY = 0,
		Trade = true,
		ConsumeEffects={SmallFood=20,DiseaseResistance=50},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	--Set
	["OrangeBlastCan"] = {
		Name = "OrangeBlastCan",
		DisplayName = "Orange Blast Can",
		Level = 2,
		Amount = 1,
		Desc = "Chug a blast of orange!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Container,
		Traits = {["Liquid"]=true,["Container"]=true},
		AllowedToContain = "Liquid",
		ContainerSlots=1,
		Capacity=10,
		Contains={["OrangeBlast"]={Name="OrangeBlast",Slot=1,Amount=1}},
		Value = 5,
		ImageOffsetX = 9*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	--Set
	["OrangeBlast"] = {
		Name = "OrangeBlast",
		DisplayName = "Orange Blast",
		Level = 2,
		Amount = 1,
		Desc = "Chug a blast of orange!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Drink,
		Traits = {["Liquid"]=true,["Consumable"]=true},
		NeedToContain = "Liquid",
		Value = 5,
		ImageOffsetX = 5*64,
		ImageOffsetY = 2*64,
		Trade = true,
		ConsumeEffects={SmallFood=5,Speed=3},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["ZapColaCan"] = {
		Name = "ZapColaCan",
		DisplayName = "Zap Cola Can",
		Level = 2,
		Amount = 1,
		Desc = "It's Zap Cola. Pretty Nice!!!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Container,
		Traits = {["Container"]=true},
		AllowedToContain = "Liquid",
		ContainerSlots=1,
		Capacity=10,
		Contains={["ZapCola"]={Name="ZapCola",Slot=1,Amount=1}},
		Value = .5,
		ImageOffsetX = 12*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		Stacks=false,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["ZapColaBottle"] = {
		Name = "ZapColaBottle",
		DisplayName = "Zap Cola Bottle",
		Level = 2,
		Amount = 1,
		Desc = "It's Zap Cola. Pretty Nice!!!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Container,
		Traits = {["Container"]=true},
		AllowedToContain = "Liquid",
		ContainerSlots=1,
		Capacity=10,
		Contains={["ZapCola"]={Name="ZapCola",Slot=1,Amount=1}},
		Value = .5,
		ImageOffsetX = 12*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		Stacks=false,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	["ZapCola"] = {
		Name = "ZapCola",
		DisplayName = "Zap Cola",
		Level = 2,
		Amount = 1,
		Desc = "It's Zap Cola. Pretty Nice!!!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Drink,
		Traits = {["Liquid"]=true,["Consumable"]=true},
		NeedToContain = "Liquid",
		Value = 5,
		ImageOffsetX = 6*64,
		ImageOffsetY = 2*64,
		Trade = true,
		ConsumeEffects={SmallFood=10,Speed=5},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};
	
	--ImageSet=true,Accessible=False
	["PizzaSlice"] = {
		Name = "PizzaSlice",
		Model = "PizzaSlice",
		DisplayName = "PizzaSlice",
		Level = 1,
		Amount = 1,
		Desc = "Pizza Time!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 14*64,
		ImageOffsetY = 0,
		ConsumeEffects={Food=10},
		Trade = true,
		Limit = 999,
		ToolAction1 = "Consume",
		ToolAction2 = "Drop",
		CanBeHeld = true,
		NewTool = true,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	--ImageSet=true,Accessible=True
	["SciColaCan"] = {
		Name = "SciColaCan",
		Model = "SciColaCan",
		DisplayName = "Sci Cola Can",
		Level = 2,
		Amount = 1,
		Desc = "Refreshing drink of corporate compliance",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Container,
		Traits = {["Container"]=true},
		AllowedToContain = "Liquid",
		NeedToContain = "Solid",
		ContainerSlots=1,
		Capacity=10,
		Contains={["SciCola"]={Name="SciCola",Slot=1,Amount=1}},
		Value = .5,
		ImageOffsetX = 12*64,
		ImageOffsetY = 6*64,
		Trade = true,
		Limit = 999,
		Stacks=false,
		ToolAction1 = "Consume",
		ToolAction2 = "Drop",
		CanBeHeld = true,
		NewTool = true,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};

	--ImageSet=true,Accessible=False
	["SciCola"] = {
		Name = "SciCola",
		DisplayName = "Sci Cola",
		Level = 2,
		Amount = 1,
		Desc = "Refreshing drink of corporate compliance",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Drink,
		Traits = {["Liquid"]=true,["Consumable"]=true},
		NeedToContain = "Liquid",
		Value = 1,
		ImageOffsetX = 6*64,
		ImageOffsetY = 2*64,
		Trade = true,
		ConsumeEffects={Hydration=10},
		Limit = 999,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};
	
	["Canteen"] = {
		Name = "Canteen",
		DisplayName = "Canteen",
		Level = 1,
		Amount = 1,
		Desc = "An empty canteen",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Container,
		Traits={},
		ContainerSlots=1,
		Capacity=10,
		AllowedToContain="Liquid",
		NeedToContain = "Solid",
		Contains={}, --Contains={["Water"]={Name="Water",Slot=1,Amount=1}},
		ContainerFilled = "", --TODO handle multiple
		Value = 7,
		ImageOffsetX = 64,
		ImageOffsetY = 3*64,
		Trade = true,
		Limit = 999,
		Stacks = false,
		ProductId = 1197745439,
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};

	--ImageSet=true,Accessible=False
	["Water"] = {
		Name = "Water",
		DisplayName = "Water",
		Level = 1,
		Amount = 1,
		Desc = "Refreshing",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		IngredientType = IngredientTypes.Base,
		Traits = {["Liquid"]=true,["Consumable"]=true,["Color"]="Blue"},
		NeedToContain="Liquid",
		Value = .01,
		ImageOffsetX = 0,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 999,
		ProductId = 1197745439,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Common,
	};
	
	--ImageSet=true,Accessible=False
	["GrillacticBurger"] = {
		Name = "GrillacticBurger",
		DisplayName = "Grillactic Burger",
		Level = 1,
		Amount = 1,
		Desc = "A mostly edible possibly beef burger with melted cheese and toppings layed on with the precision of a lazy teenage staff",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits={["Consumable"]=true},
		NeedToContain="Solid",
		Value = 3,
		ImageOffsetX = 1*64,
		ImageOffsetY = 0*64,
		Trade = true,
		ConsumeEffects={LargeFood=50},
		Limit = 1000,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};
	
	--ImageSet=true,Accessible=False
	["GrillacticFries"] = {
		Name = "GrillacticFries",
		DisplayName = "Grillactic Fries",
		Level = 1,
		Amount = 1,
		Desc = "Basically a container for grease",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits={["Consumable"]=true},
		NeedToContain="Solid",
		Value = 3,
		ImageOffsetX = 15*64,
		ImageOffsetY = 5*64,
		Trade = true,
		ConsumeEffects={LargeFood=50},
		Limit = 1000,
		LootType = LootTypes.General,
		Rarity = Rarity.Uncommon
	};
	
	--ImageSet=True,Accessible=False
	["RedMicroPlanet"] = {
		Name = "RedMicroPlanet",
		DisplayName = "Red Micro Planet",
		Level = 1,
		Amount = 1,
		Desc = "A candy made to look like a small planet.  Or, maybe an actual tiny populated planet",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = .25,
		ImageOffsetX = 7*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ConsumeEffects={TinyFood=5},
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};	
	
	--ImageSet=true,Accessible=False
	["OrangeMicroPlanet"] = {
		Name = "OrangeMicroPlanet",
		DisplayName = "Orange Micro Planet",
		Level = 1,
		Amount = 1,
		Desc = "A candy made to look like a small planet.  Or, maybe an actual tiny populated planet",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = .25,
		ImageOffsetX = 5*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ConsumeEffects={TinyFood=5},
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};	
	
	--ImageSet=true,Accessible=False
	["BlueMicroPlanet"] = {
		Name = "BlueMicroPlanet",
		DisplayName = "Blue Micro Planet",
		Level = 1,
		Amount = 1,
		Desc = "A candy made to look like a small planet.  Or, maybe an actual tiny populated planet",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = .25,
		ImageOffsetX = 3*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ConsumeEffects={TinyFood=5},
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	--ImageSet=true,Accessible=False
	["GreenMicroPlanet"] = {
		Name = "GreenMicroPlanet",
		DisplayName = "Green Micro Planet",
		Level = 1,
		Amount = 1,
		Desc = "A candy made to look like a small planet.  Or, maybe an actual tiny populated planet",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = .25,
		ImageOffsetX = 4*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ConsumeEffects={TinyFood=5},
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	--ImageSet=true,Accessible=False
	["PurpleMicroPlanet"] = {
		Name = "PurpleMicroPlanet",
		DisplayName = "Purple Micro Planet",
		Level = 1,
		Amount = 1,
		Desc = "A candy made to look like a small planet.  Or, maybe an actual tiny populated planet",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = .25,
		ImageOffsetX = 6*64,
		ImageOffsetY = 64,
		Trade = true,
		Limit = 999,
		ConsumeEffects={TinyFood=5},
		LootType = LootTypes.General,
		Rarity = Rarity.Common
	};
	
	--ImageSet=true,Accessible=False
	["Brains"] = {
		Name = "Brains",
		DisplayName = "Brains",
		Level = 1,
		Amount = 1,
		Desc = "eeew",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Ingredient,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain="Solid",
		Value = 1,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		Trade = true,
		Limit = 999,
		ConsumeEffects={Zombie=1},
		LootType = LootTypes.Specific,
		Rarity = Rarity.Uncommon
	};

	--ImageSet=true,Accessible=False
	["RoastedChicken"] = {
		Name = "RoastedChicken",
		DisplayName = "Roasted Chicken",
		Level = 0,
		Amount = 1,
		Desc = "Em Em Roasted ChIcKeN!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 3,
		ImageOffsetX = 1*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={MediumFood=50},
		Limit = 999,
		LootType = LootTypes.Cooked,
		Rarity = Rarity.Uncommon,
	};

	--ImageSet=true,Accessible=False
	["SpicyRoastedChicken"] = {
		Name = "SpicyRoastedChicken",
		DisplayName = "Spicy Roasted Chicken",
		Level = 0,
		Amount = 1,
		Desc = "Spicy ChIcKeN Yeah!",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 3,
		ImageOffsetX = 1*64,
		ImageOffsetY = 7*64,
		Trade = true,
		ConsumeEffects={SpicyMediumFood=50},
		Limit = 999,
		LootType = LootTypes.Cooked,
		Rarity = Rarity.Uncommon,
	};

	--ImageSet=true,Accessible=False
	["SandWormOnAStick"] = {
		Name = "SandWormOnAStick",
		DisplayName = "Sand Worm On A Stick",
		Level = 0,
		Amount = 1,
		Desc = "A bit sandy still, but tasty",
		Type = ItemTypes.Consumable,
		SubType = SubTypes.Consumable.Food,
		Traits = {["Solid"]=true,["Consumable"]=true},
		NeedToContain = "Solid",
		Value = 5,
		ImageOffsetX = 0,
		ImageOffsetY = 4*64,
		Trade = true,
		ConsumeEffects={MediumFood=50},
		Limit = 999,
		LootType = LootTypes.Cooked,
		Rarity = Rarity.Uncommon,
	};

	
}

return module
