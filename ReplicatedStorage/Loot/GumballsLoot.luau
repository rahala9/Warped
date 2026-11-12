-- 0 trash   	100		any enemy
-- 1 common		80		any enemy
-- 2 uncommon	50		any enemy
-- 3 rare		1		elite
-- 4 epic		.03		miniboss
-- 5 legendary	.01		boss

local module = {	
	["RedGumball"] = {
		Name = "RedGumball",
		Rarity = 80
	};	
	["YellowGumball"] = {
		Name = "YellowGumball",
		Rarity = 80
	};	
	["BlueGumball"] = {
		Name = "BlueGumball",
		Rarity = 50
	};	

	["GreenGumball"] = {
		Name = "GreenGumball",
		Rarity = 1
	};

	["OrangeGumball"] = {
		Name = "OrangeGumball",
		Rarity = 50
	};

	["PurpleGumball"] = {
		Name = "PurpleGumball",
		Rarity = .03
	};

	["PinkGumball"] = {
		Name = "PinkGumball",
		Rarity = 50
	};



}

return module
