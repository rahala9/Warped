

local recipes = {

	--All material and tools accessible
	["FakeLicense"] = {
		Item1={Name="Selfie",AmountNeeded=1},
		Item2={Name="ScrapPlastic",AmountNeeded=1},
		Item3={Name="DuctTape",AmountNeeded=1},
		Amount=1,
		Tool="Marker",
	};

	["ToothyBackpack"] = {
		Item1={Name="CrocodileHide",AmountNeeded=1},
		Item2={Name="HikingBackpack",AmountNeeded=1},
		Item3={Name="DuctTape",AmountNeeded=1},
		Amount=1,
		Tool="",
	};



	["Molotov"] = {
		Item1={Name="Gasoline",AmountNeeded=1},
		Item2={Name="ZapColaBottle",AmountNeeded=1},
		Item3={Name="Cloth",AmountNeeded=1},
		Amount=1,
		Tool="Lighter",
	};

	--All material and tools accessible
	["MarshmellowStick"] = {
		Item1={Name="Log",AmountNeeded=1},
		Item2=nil,
		Item3=nil,
		Amount=1,
		Tool="PocketKnife",
	};

	--All material and tools accessible
	["SharpRock"] = {
		Item1={Name="Rock",AmountNeeded=2},
		Item2=nil,
		Item3=nil,
		Amount=2,
		Tool=nil,
	};

	--All material and tools accessible
	["PokeyStick"] = {
		Item1={Name="SharpRock",AmountNeeded=1},
		Item2={Name="Stick",AmountNeeded=1},
		Item3=nil,
		Amount=1,
		Tool=nil,
	};

	--All material and tools accessible
	["Spear"] = {
		Item1={Name="SharpRock",AmountNeeded=1},
		Item2={Name="Stick",AmountNeeded=1},
		Item3={Name="Twine",AmountNeeded=1},
		Amount=1,
		Tool=nil,
	};

	["Torch"] = {
		Item1={Name="Stick",AmountNeeded=1},
		Item2={Name="ScrapCloth",AmountNeeded=1},
		Item3={Name="Resin",AmountNeeded=1},
		Amount=1,
		Tool=nil,
	};


	["WaxTwine"] = {
		Item1={Name="Twine",AmountNeeded=1},
		Item2={Name="Beeswax",AmountNeeded=1},
		Item3=nil,
		Amount=2,
		Tool="Lighter",
	};

	["Slingshot"] = {
		Item1={Name="Stick",AmountNeeded=1},
		Item2={Name="ScrapRubber",AmountNeeded=2},
		Item3=nil,
		Amount=1,
		Tool=nil,
	};

	["Spike"] = {
		Item1={Name="Bat",AmountNeeded=1},
		Item2={Name="Nail",AmountNeeded=6},
		Item3=nil,
		Amount=1,
		Tool=nil,
	};

	["Arrow"] = {
		Item1={Name="PokeyStick",AmountNeeded=1},
		Item2={Name="WaxTwine",AmountNeeded=1},
		Item3={Name="Feather",AmountNeeded=1},
		Amount=10,
		Tool=nil,
	};

	["MetalRod"] = {
		Item1={Name="ScrapMetal",AmountNeeded=5},
		Item2=nil,
		Item3=nil,
		Amount=2,
		Tool=nil,
	};

	["Bolt"] = {
		Item1={Name="ScrapMetal",AmountNeeded=1},
		Item2={Name="MetalRod",AmountNeeded=1},
		Item3={Name="Feather",AmountNeeded=1},
		Amount=10,
		Tool="SolderingIron",
	};

	["PoisonGas"] = {
		Item1={Name="FrogPosion",AmountNeeded=3},
		Item2=nil,
		Item3=nil,
		Amount=5,
		Tool="ChemestrySet",
	};

	["PoisonGasBalloon"] = {
		Item1={Name="Balloon",AmountNeeded=1},
		Item2={Name="PoisonGas",AmountNeeded=1},
		Item3=nil,
		Amount=5,
		Tool=nil,
	};

	["FlamingArrow"] = {
		Item1={Name="Arrow",AmountNeeded=1},
		Item2={Name="Gasoline",AmountNeeded=1},
		Item3=nil,
		Amount=6,
		Tool="Lighter",
	};

	["BottleRocket"] = {
		Item1={Name="ZapColaBottle",AmountNeeded=1},
		Item2={Name="Rocket",AmountNeeded=1},
		Item3=nil,
		Amount=6,
		Tool="Lighter",
	};

	["MurfJuice"] = {
		Item1={Name="Murf",AmountNeeded=1},
		Item2=nil,
		Item3=nil,
		Amount=3,
		Tool="Blender",
	};





}

local functions = {}

function functions.GetRecipes()
	return recipes
end

return functions
