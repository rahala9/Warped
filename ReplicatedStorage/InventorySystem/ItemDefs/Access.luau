local imageMap = {
	["Access"]="rbxassetid://75333614406618",
};

local ItemTypes = {
	["Access"]="Access",
}

local LootTypes = {
	["General"]="General", -- received through random loot tables or purchased
	["Quest"]="Quest",  -- received only through quest
	["Specific"]="Specific", -- received through specific loot tables of mobs
	["Purchase"]="Purchase", -- only retrieved from purchasing item
	["Crafted"]="Crafted" -- only retrieved from crafting item
}

local SubTypes = {
	["Access"]={
		["ID"]="ID",
		["Keycard"]="Keycard",
		["Retina"]="Retina",
		["DNA"]="DNA",
		["Ticket"]="Ticket",
		["Pass"]="Pass",
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

	["PlumberId"] = {
		Name = "PlumberId",
		DisplayName = "Plumber Id",
		Level = 1,
		Amount = 1,
		Desc = "An Id card from Dark Matter Plumbing Co",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 2*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Rare
	};

	["AccessCard"] = {
		Name = "AccessCard",
		DisplayName = "Access Card",
		Level = 1,
		Amount = 1,
		Desc = "A card to an unknown room",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 11*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["WhiteKeycard"] = {
		Name = "WhiteKeycard",
		DisplayName = "White Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level White",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["YellowKeycard"] = {
		Name = "YellowKeycard",
		DisplayName = "Yellow Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Yellow",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 1*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["GreenKeycard"] = {
		Name = "GreenKeycard",
		DisplayName = "Green Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Green",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["BlueKeycard"] = {
		Name = "BlueKeycard",
		DisplayName = "Blue Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Blue",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 3*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["OrangeKeycard"] = {
		Name = "OrangeKeycard",
		DisplayName = "Orange Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Orange",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 4*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["RedKeycard"] = {
		Name = "RedKeycard",
		DisplayName = "Red Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Red",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 5*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["BlackKeycard"] = {
		Name = "BlackKeycard",
		DisplayName = "Black Keycard",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to security level Black",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Keycard,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 6*64,
		ImageOffsetY = 0*64,
		Trade = false,
		Limit = 1,
		LootType = LootTypes.Quest,
		Rarity = Rarity.Epic
	};
	
	["HumanEyeball"] = {
		Name = "HumanEyeball",
		DisplayName = "Human Eyeball",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to an unknown eye scanner",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Retina,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 0*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Epic
	};
	
	["DNSCapsule"] = {
		Name = "DNSCapsule",
		DisplayName = "DNS Capsule",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to an unknown DNA scanner",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.DNA,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 1*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Epic
	};
	
	["CyberneticEyeball"] = {
		Name = "CyberneticEyeball",
		DisplayName = "Cybernetic Eyeball",
		Level = 1,
		Amount = 1,
		Desc = "Gives access to an unknown eye scanner",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.Retina,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 0,
		ImageOffsetX = 2*64,
		ImageOffsetY = 1*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Specific,
		Rarity = Rarity.Epic
	};

	--ImageSet=True,Accessible=True
	["FakeStarhopClearanceBadge"] = {
		Name = "FakeStarhopClearanceBadge",
		DisplayName = "Fake Starhop Clearance Badge",
		Level = 1,
		Amount = 1,
		Desc = "Will fool most Humanoid officers. Watch out for bots",
		Type = ItemTypes.Access,
		SubType = SubTypes.Access.ID,
		Traits = {["Solid"]=true},
		NeedToContain="Solid",
		Value = 50,
		ImageOffsetX = 1*64,
		ImageOffsetY = 2*64,
		Trade = true,
		Limit = 1,
		LootType = LootTypes.Purchase,
		Rarity = Rarity.Legendary
	};
	
	
}

return module
