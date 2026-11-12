

local recipes = {

	--No Tool Required

	["HoneyApple"] = {
		Name = "HoneyApple",
		Ingredients = {
			{Item = "Apple", Amount = 1},
			{Item = "HoneyComb", Amount = 1},
		},
		Servings = 1,
		RequiredItem = nil
	};

	--Spit	

	["RoastedChicken"] = {
		Name = "RoastedChicken",
		Ingredients = {
			{Item = "RawChicken", Amount = 1},
		},
		Servings = 2,
		RequiredItem = "Spit"
	};

	["SpicyRoastedChicken"] = {
		Name = "SpicyRoastedChicken",
		Ingredients = {
			{Item = "RawChicken", Amount = 1},
			{Type = "Spice", Amount = 1},
		},
		Servings = 2,
		RequiredItem = "Spit"
	};

	--FryingPan

	["SunnySideUp"] = {
		Name = "SunnySideUp",
		Ingredients = {
			{Item = "Egg", Amount = 3},
		},
		Servings = 1,
		RequiredItem = "FryingPan"
	};

	["CheesyEggs"] = {
		Name = "CheesyEggs",
		Ingredients = {
			{Item = "Egg", Amount = 3},
			{Item = "Cheese", Amount = 1},
		},
		Servings = 1,
		RequiredItem = "FryingPan"
	};

	["FriedBrains"] = {
		Name = "FriedBrains",
		Ingredients = {
			{Item = "Brains", Amount = 1},
			{Type = "Spice", Amount = 1},
		},
		Servings = 1,
		RequiredItem = "FryingPan"
	};


	--Pot

	["GoldyMushroomSoup"] = {
		Name = "GoldyMushroomSoup",
		Ingredients = {
			{Item = "GoldyMushroom", Amount = 10},
			{Item = "Water", Amount = 5},
		},
		Servings = 5,
		RequiredItem = "CookingPot"
	};

	["RatMeatStew"] = {
		Name = "RatMeatStew",
		Ingredients = {
			{Item = "RatMeat", Amount = 2},
			{Item = "Water", Amount = 5},
		},
		Servings = 3,
		RequiredItem = "CookingPot"
	};

	["ToxicRatMeatStew"] = {
		Name = "ToxicRatMeatStew",
		Ingredients = {
			{Item = "ToxicRatMeat", Amount = 2},
			{Item = "Water", Amount = 5},
		},
		Servings = 3,
		RequiredItem = "CookingPot"
	};


	--Oven	

	["HoneyCake"] = {
		Name = "HoneyCake",
		Ingredients = {
			{Item = "Honey", Amount = 5},
			{Item = "Flour", Amount = 2},
			{Item = "Egg", Amount = 3},
		},
		Servings = 5,
		RequiredItem = "Oven"
	};





}

local functions = {}

function functions.GetRecipes()
	return recipes
end

return functions
