--TODO add all rest of items
--TODO SECURITY move this server side for security

local imageMap = {
	["Tents"]="rbxassetid://18959203312",
	["Other"]="rbxassetid://18959203312",
	["Gardening"]="rbxassetid://18959203312",
};

local SubTypes = {
	["BeachItem"]="BeachItem",
	["Seating"]="Seating",
	["Walls"]="Walls",
	["Electric"]="Electric",
	["Decor"]="Decor",
	["Signs"]="Signs",
	["Misc"]="Misc",
	["Trophies"]="Trophies",
	["Construct"]="Construct",
	["Soil"]="Soil",
	["Seeds"]="Seeds",
};

local buildItems = {

	["ImageMap"] = imageMap;

	["Tent1"] = {
		Name = "Tent1",
		DisplayName = "Tent1",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 17,
		AreaY = 10,
		AreaZ = 34,
		ImageOffsetX = 0,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent2"] = {
		Name = "Tent2",
		DisplayName = "Tent2",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 15,
		AreaY = 10,
		AreaZ = 15,
		ImageOffsetX = 64,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","SkullBanner","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent3"] = {
		Name = "Tent3",
		DisplayName = "Tent3",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 10,
		AreaY = 9,
		AreaZ = 14,
		ImageOffsetX = 128,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent4"] = {
		Name = "Tent4",
		DisplayName = "Tent4",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 12,
		AreaY = 7,
		AreaZ = 14,
		ImageOffsetX = 192,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent5"] = {
		Name = "Tent5",
		DisplayName = "Tent5",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 18,
		AreaY = 12,
		AreaZ = 18,
		ImageOffsetX = 256,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 50
	};

	["Tent6"] = {
		Name = "Tent6",
		DisplayName = "Tent6",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 20,
		AreaX = 20,
		AreaY = 20,
		AreaZ = 20,
		ImageOffsetX = 320,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent7"] = {
		Name = "Tent7",
		DisplayName = "Tent7",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 384,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value = 0
	};

	["Tent8"] = {
		Name = "Tent8",
		DisplayName = "Tent8",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 448,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		ProductId=87916627518163,
		Value=800
	};

	["Tent9"] = {
		Name = "Tent9",
		DisplayName = "Tent9",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 512,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		ProductId=1228880627,
		Value=200
	};

	["Tent10"] = {
		Name = "Tent10",
		DisplayName = "Tent10",
		Type = "Tents",
		SubType = SubTypes.BeachItem,
		Limit = 1,
		OffsetY = -.2,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 512,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"Boombox","flag1","flag2"},
		ProductId=1228880627,
		Value=200
	};

	["Tent11"] = {
		Name = "Tent11",
		DisplayName = "Tent11",
		Type = "Tents",
		Limit = 1,
		OffsetY = -.2,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 512,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"Boombox","flag1","flag2"},
		ProductId=1228880627,
		Value=200
	};

	["Tent12"] = {
		Name = "Tent12",
		DisplayName = "Tent12",
		Type = "Tents",
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 448,
		ImageOffsetY = 15*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","flag1","flag2","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		ProductId=116665270453832,
		Value=800
	};

	["camp_fire"] = {
		Name = "Campfire",
		DisplayName = "Campfire",
		Type = "Other",
		SubType = SubTypes.Misc,
		Limit = 1,
		OffsetY = -1,
		MaxDeleteActivation = 8,
		MaterialsRequired={{MaterialRequired = "Rock",AmountRequired = 3},{MaterialRequired = "Log",AmountRequired = 3}},
		AreaX = 10,
		AreaY = 5,
		AreaZ = 10,
		ImageOffsetX = 0,
		ImageOffsetY = 0,
		AllowedToBuildOn={}	,
		Value=0,
		Power = 0	
	};

	["stone_wall_3"] = {
		Name = "Small Stone Wall",
		DisplayName = "Small Stone Wall",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 5,
		MaterialsRequired={{MaterialRequired = "Rock",AmountRequired = 3}},
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 1*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy","BarbedWire"},
		Value=0,
		Power = 0,
		Armor = 8
	};

	["stone_wall_2"] = {
		Name = "Medium Stone Wall",
		DisplayName = "Medium Stone Wall",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 5,
		MaterialsRequired={{MaterialRequired = "Rock",AmountRequired = 6}},
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 2*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy","BarbedWire"},
		Value=0,
		Power = 0,
		Armor = 8
	};

	["stone_wall_1"] = {
		Name = "Large Stone Wall",
		DisplayName = "Large Stone Wall",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 5,
		MaterialRequired = "Rock",
		MaterialsRequired={{MaterialRequired = "Rock",AmountRequired = 10}},
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 3*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy","BarbedWire"},
		Value=0,
		Power = 0,
		Armor = 8
	};




	["DirectionSign"] = {
		Name = "Direction Sign",
		DisplayName = "Direction Sign",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 5,
		MaterialRequired = "Log",
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 4}},
		MaxDeleteActivation = 10,
		AreaX = 5,
		AreaY = 5,
		AreaZ = 5,
		ImageOffsetX = 4*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=0,
		Power = 0
	};

	["bridge"] = {
		Name = "Wood Bridge",
		DisplayName = "Wood Bridge",
		Type = "Other",
		SubType = SubTypes.Misc,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 50}},
		Limit = 1,
		MaxDeleteActivation = 10,
		AreaX = 12,
		AreaY = 10,
		AreaZ = 40,
		ImageOffsetX = 5*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=0,
		Power = 0
	};

	["tree_stump"] = {
		Name = "Tree Stump",
		DisplayName = "Tree Stump",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 6,
		OffsetY = -1,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 5}},
		MaxDeleteActivation = 6,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=0,
		Power = 0
	};


	["PlankFence"] = {
		Name = "Plank Fence",
		DisplayName = "Plank Fence",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 20,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 10}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 7*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"BarbedWire"},
		Value=0,
		Power = 0,
		Armor = 2
	};

	["PikeFence"] = {
		Name = "Pike Fence",
		DisplayName = "Pike Fence",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 20,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 10}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 8*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={"BarbedWire"},
		Value=0,
		Power = 0,
		Armor = 2
	};

	["Barricade"] = {
		Name = "Barricade",
		DisplayName = "Barricade",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 20,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 3},{MaterialRequired = "ScrapMetal",AmountRequired = 5}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 8*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=0,
		Power = 0,
		Armor = 6
	};

	["Barricade2"] = {
		Name = "Barricade2",
		DisplayName = "Barricade 2",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 20,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 3},{MaterialRequired = "ScrapMetal",AmountRequired = 3}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 8*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=0,
		Power = 0,
		Armor = 5
	};

	["BarbedWire"] = {
		Name = "Barbed Wire",
		DisplayName = "Barbed Wire",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 20,
		MaterialsRequired={{MaterialRequired = "ScrapMetal",AmountRequired = 2}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 7*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=0,
		Power = 0,
		Armor = 2
	};



	["Generator"] = {
		Name = "Generator",
		DisplayName = "Generator",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 1,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 9*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		ProductId=1228989901,
		Value=1200,
		PowerSource=true,
		Power = 3600,
		MaxPower = 3600
	};

	["SkullBanner"] = {
		Name = "SkullBanner",
		DisplayName = "Skull Banner",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 4,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 10*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=40,
		HangOn=true,
		Power = 0
	};

	["KeepOutSign"] = {
		Name = "KeepOutSign",
		DisplayName = "Keep Out Sign",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 10,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 11*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=20,
		HangOn=true,
		Power = 0
	};

	["DangerSign"] = {
		Name = "DangerSign",
		DisplayName = "Danger Sign",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 10,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 12*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=20,
		HangOn=true,
		Power = 0
	};

	["Lantern"] = {
		Name = "Lantern",
		DisplayName = "Lantern",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 10,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 13*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=50,
		HangOn=true,
		Electric=true,
		Power = 0
	};

	["BearStatue"] = {
		Name = "BearStatue",
		DisplayName = "Bear Statue",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 1,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 14*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=400,
		ProductId=1229492184,
		Power = 0
	};

	--Comes from loot of the Evil Garden Gnome
	["GardenGnome"] = {
		Name = "GardenGnome",
		DisplayName = "Garden Gnome",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 1,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 14*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=400,
		ProductId=1229492184,
		Power = 0
	};

	["LightBulb"] = {
		Name = "LightBulb",
		DisplayName = "Light Bulb",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 4,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 15*64,
		ImageOffsetY = 0,
		AllowedToBuildOn={},
		Value=10,
		HangOn=true,
		Electric=true,
		Power = 0
	};

	["QuarantineSign"] = {
		Name = "QuarantineSign",
		DisplayName = "Quarantine Sign",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 4,
		OffsetY = 0,
		MaxDeleteActivation = 10,
		AreaX = 24,
		AreaY = 10,
		AreaZ = 24,
		ImageOffsetX = 0,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=20,
		HangOn=true,
		Power = 0
	};

	["Boombox"] = {
		Name = "Boombox",
		DisplayName = "Boombox",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 1*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=200,
		Electric=true,
		Power = 0
	};

	["WireSpool"] = {
		Name = "Wire Spool",
		DisplayName = "Wire Spool",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 999,
		Unlimited = true,
		MaxDeleteActivation = 10,
		AreaX = 5,
		AreaY = 5,
		AreaZ = 5,
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=20,
		Wire=true,
		Power = 0

	};

	["CarBattery"] = {
		Name = "Car Battery",
		DisplayName = "Car Battery",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 1,
		MaxDeleteActivation = 10,
		AreaX = 5,
		AreaY = 5,
		AreaZ = 5,
		AllowedToBuildOn={},
		Value=100,
		ImageOffsetX = 3*64,
		ImageOffsetY = 1*64,
		PowerSource=true,
		Power = 1200,
		MaxPower = 1200

	};

	["cactus1"] = {
		Name = "Cactus 1",
		DisplayName = "Cactus 1",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 5,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 4*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=20,
		Power = 0
	};

	["cactus2"] = {
		Name = "Cactus 2",
		DisplayName = "Cactus 1",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 5,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 5*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=30,
		Power = 0
	};

	["flowers_mix"] = {
		Name = "Mixed Flowers",
		DisplayName = "Mixed Flowers",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 5,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["flowers_pink"] = {
		Name = "Pink Flowers",
		DisplayName = "Pink Flowers",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 5,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 7*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["flowers_red"] = {
		Name = "Red Flowers",
		DisplayName = "Red Flowers",
		Type = "Other",
		SubType = SubTypes.Decor,
		Limit = 5,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 8*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["park_bench"] = {
		Name = "Park Bench",
		DisplayName = "Park Bench",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 1,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 10}},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 9,
		ImageOffsetX = 9*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","sleeping_bag","ParticipationTrophy","cactus","Boombox","lay-Z-chair","BookPile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=100,
		Power = 0
	};

	["sleeping_bag"] = {
		Name = "Sleeping Bag",
		DisplayName = "Sleeping Bag",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 2,
		MaxDeleteActivation = 6,
		AreaX = 5,
		AreaY = 10,
		AreaZ = 13,
		ImageOffsetX = 10*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value = 50,
		Power = 0
	};

	["flag1"] = {
		Name = "Flag 1",
		DisplayName = "Flag 1",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 10,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 11*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=30,
		Power = 0
	};

	["BookPile"] = {
		Name = "BookPile",
		DisplayName = "Book Pile",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 10,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 11*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=30,
		Power = 0,
		Armor = 1
	};


	["flag2"] = {
		Name = "Flag 2",
		DisplayName = "Flag 2",
		Type = "Other",
		SubType = SubTypes.Signs,
		Limit = 10,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 12*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=30,
		Power = 0
	};

	["BalloonGroup"] = {
		Name = "Balloon Group",
		DisplayName = "Balloon Group",
		Type = "Other",
		SubType = SubTypes.Misc,
		Limit = 10,
		MaterialsRequired={},
		MaxDeleteActivation = 5,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 8,
		ImageOffsetX = 13*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		ProductId=0,
		Value=10,
		Power = 0
	};

	["BeanBagChair"] = {
		Name = "Bean Bag Chair",
		DisplayName = "Bean Bag Chair",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 4,
		MaterialsRequired={},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 8,
		ImageOffsetX = 14*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=30,
		Power = 0
	};

	["ArcheryTarget"] = {
		Name = "ArcheryTarget",
		DisplayName = "Archery Target",
		Type = "Other",
		SubType = SubTypes.Misc,
		Limit = 4,
		MaterialsRequired={},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 8,
		ImageOffsetX = 14*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["UmbrellaChair"] = {
		Name = "Umbrella Chair",
		DisplayName = "Umbrella Chair",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 4,
		MaterialsRequired={},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 8,
		ImageOffsetX = 15*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=50,
		Power = 0
	};

	["StringLights"] = {
		Name = "Strings Of Shimmering Lights",
		DisplayName = "String Lights",
		Type = "Other",
		SubType = SubTypes.Electric,
		Limit = 4,
		MaterialsRequired={},
		MaxDeleteActivation = 10,
		AreaX = 8,
		AreaY = 10,
		AreaZ = 8,
		ImageOffsetX = 0,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"SkullBanner"},
		Value=100,
		Power = 0
	};

	["lay-Z-chair"] = {
		Name = "Lay-Z-Chair",
		DisplayName = "Lay-Z-Chair",
		Type = "Other",
		SubType = SubTypes.Seating,
		Limit = 1,
		MaxDeleteActivation = 8,
		AreaX = 5,
		AreaY = 5,
		AreaZ = 5,
		ImageOffsetX = 1*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={},
		Value=1200,
		Power = 0
	};

	["Shop"] = {
		Name = "Shop",
		DisplayName = "Shop",
		Type = "Other",
		SubType = SubTypes.Misc,
		Limit = 4,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 10}},
		MaxDeleteActivation = 10,
		AreaX = 10,
		AreaY = 4,
		AreaZ = 4,
		ImageOffsetX = 14*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","sleeping_bag","ParticipationTrophy","cactus","Boombox","Bookpile","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=30,
		Power = 0
	};

	["rock"] = {
		Name = "Rock",
		DisplayName = "Rock",
		Type = "Other",
		SubType = SubTypes.Misc,
		Limit = 1,
		MaterialsRequired={{MaterialRequired = "Rock",AmountRequired = 50}},
		MaxDeleteActivation = 10,
		AreaX = 16,
		AreaY = 10,
		AreaZ = 16,
		ImageOffsetX = 2*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"flowers_red","flowers_pink","flowers_mix","ParticipationTrophy","cactus","Boombox","OuterspaceTrophy","ZombieHunterTrophy","MaxLevelTrophy"},
		Value=0,
		Power = 0
	};

	["ParticipationTrophy"] = {
		Name = "ParticipationTrophy",
		DisplayName = "Participation Trophy",
		Type = "Other",
		SubType = SubTypes.Trophies,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 3*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={},
		Value=500,
		Power = 0
	};

	["MaxLevelTrophy"] = {
		Name = "MaxLevelTrophy",
		DisplayName = "Max Level Trophy",
		Type = "Other",
		SubType = SubTypes.Trophies,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 3*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={},
		Value=500,
		Power = 0
	};

	["OuterspaceTrophy"] = {
		Name = "OuterspaceTrophy",
		DisplayName = "Outerspace Trophy",
		Type = "Other",
		SubType = SubTypes.Trophies,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["ZombieHunterTrophy"] = {
		Name = "ZombieHunterTrophy",
		DisplayName = "Zombie Hunter Trophy",
		Type = "Other",
		SubType = SubTypes.Trophies,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};

	["JourneyTrophy"] = {
		Name = "JourneyTrophy",
		DisplayName = "Journey Trophy",
		Type = "Other",
		SubType = SubTypes.Trophies,
		Limit = 1,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 1*64,
		AllowedToBuildOn={},
		Value=10,
		Power = 0
	};




	["SandCastleRound"] = {
		Name = "SandCastleRound",
		DisplayName = "Sand Castle Round",
		Type = "Other",
		SubType = SubTypes.BeachItem,
		Limit = 20,
		Amount = 99,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"SandCastleSquareSmall","SandCastleSquareLarge"},
		Value=1,
		Power = 0
	};

	["SandCastleLong"] = {
		Name = "SandCastleLong",
		DisplayName = "Sand Castle Long",
		Type = "Other",
		SubType = SubTypes.BeachItem,
		Limit = 20,
		Amount = 99,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 7*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"SandCastleSquareSmall","SandCastleSquareLarge"},
		Value=1,
		Power = 0
	};

	["SandCastleSquareLarge"] = {
		Name = "SandCastleSquareLarge",
		DisplayName = "Sand Castle Square Large",
		Type = "Other",
		SubType = SubTypes.BeachItem,
		Limit = 20,
		Amount = 99,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 5*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"SandCastleSquareSmall"},
		Value=1,
		Power = 0
	};

	["SandCastleSquareSmall"] = {
		Name = "SandCastleSquareSmall",
		DisplayName = "Sand Castle Square Small",
		Type = "Other",
		SubType = SubTypes.BeachItem,
		Limit = 20,
		Amount = 99,
		MaxDeleteActivation = 4,
		AreaX = 4,
		AreaY = 10,
		AreaZ = 4,
		ImageOffsetX = 8*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"SandCastleSquareSmall"},
		Value=1,
		Power = 0
	};	

	["SmallGate"] = {
		Name = "Small Gate",
		DisplayName = "Small Gate",
		Type = "Other",
		SubType = SubTypes.Walls,
		Limit = 5,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 5}},
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 4*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={},
		Value=0,
		Power = 0,
		Armor = 2
	};

	["Board"] = {
		Name = "Board",
		DisplayName = "Board",
		Type = "Other",
		SubType = SubTypes.Construct,
		Limit = 99,
		MaterialsRequired={{MaterialRequired = "Log",AmountRequired = 1}},
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 4*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={},
		Value=0,
		Power = 0,
		Armor = 1
	};

	["Soil"] = {
		Name = "Soil",
		DisplayName = "Soil",
		Type = "Gardening",
		SubType = SubTypes.Soil,
		Limit = 99,
		MaterialsRequired={{MaterialRequired = "Soil",AmountRequired = 1}}, --TODO change to soil type
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 4*64,
		ImageOffsetY = 2*64,
		AllowedToBuildOn={"TomatoPlant","GardenGnome"},
		Value=0,
		Power = 0,
		Armor = 1
	};

	["TomatoPlant"] = {
		Name = "TomatoPlant",
		DisplayName = "Tomato Plant",
		Type = "Gardening",
		SubType = SubTypes.Seeds,
		Limit = 99,
		MaterialsRequired={{MaterialRequired = "TomatoSeeds",AmountRequired = 1}}, --TODO change to soil type
		MaxDeleteActivation = 10,
		AreaX = 20,
		AreaY = 5,
		AreaZ = 4,
		ImageOffsetX = 6*64,
		ImageOffsetY = 9*64,
		AllowedToBuildOn={},
		CannotBuildOnTerrain=true,
		Value=0,
		Power = 0,
		Armor = 1
	};



}
return buildItems