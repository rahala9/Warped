local achievements = {

	["Screaming In Space"] = {
		Name = "Screaming In Space",
		TotalSteps = 2,
		Steps = {
			["Death1"]=false, -- By Laser
			["Death2"]=false, --By Plasma
			["Death3"]=false, --By Electric
			["Death4"]=false, --By Beam
			["Death5"]=false, --By Rocket
			["Death6"]=false, --By Falling
			["Death7"]=false, --By Squished by Automatic Door
			["Death8"]=false, --By Sliced by Laser Door
			["Death9"]=false, --By Bordem
			["Death10"]=false, --By Trash Compactor
			["Death11"]=false, --By Hunger
			["Death12"]=false, --By Thirst
			["Death13"]=false, --By Drowning
			["Death14"]=false, --By Zombification
			["Death15"]=false, --By Desintigration
			["Death16"]=false, --By Blackhole
			["Death17"]=false, --By Explosion
			["Death18"]=false, --By Shipwreck
			["Death19"]=false, --By Poison
			["Death20"]=false, --By Heat Exhaustion
			["Death21"]=false, --By Freezing
			["Death22"]=false, --By Spontaneous Combustion
			["Death23"]=false, --By Radiation
			["Death24"]=false, --By Teleporting Flyification
			
		},
		Complete = false,
		Title = "Screaming In Space",
		Perk = {
			{Type="Title",Value="The Perished"},
			{Type="Item",Value="Gravestone"} --Gravestone you can place and Edit the inscription
			},
		Image = Vector3.new(4,1,0) -- image group, x, y
	};
		
	["Treasures Found"] = {
		Name = "Treasures Found",
		TotalSteps = 100,
		Steps = {
			{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false},{Complete = false}
		},
		Complete = false,
		Title = "Treasures Found",
		Perk = {Type="Item",Value="GoldenJetPack"},
		Image = Vector3.new(4,0,0) -- image group, x, y
	};
	
	["Areas Accessed"] = {
		Name = "Areas Accessed",
		TotalSteps = 100,
		Steps = {
			["1"]={Complete = false}, --Spider Cave
			["2"]={Complete = false}, --Eye Bunker Hatch
			["3"]={Complete = false}, --Mess Hall at Night
		},
		Complete = false,
		Title = "Areas Accessed",
		Perk = "GlowingTrophy",
		Image = Vector3.new(4,0,0) -- image group, x, y
	};
	
	["Areas Discovered"] = {
		Name = "Areas Discovered",
		TotalSteps = 100,
		Steps = {
			["1"]={Complete = false}, --Camp Whispering Woods
			["2"]={Complete = false}, --Lake
			["3"]={Complete = false}, --Camp Skull
			["4"]={Complete = false}, --Deep Woods
			["5"]={Complete = false}, --Cliffs of
			["6"]={Complete = false}, --something Mountain
			["7"]={Complete = false}, --Leviathan Bunker
			["8"]={Complete = false}, --The Eye Bunker
			["9"]={Complete = false}, --The Abyss Bunker
			["10"]={Complete = false}, --Molitov Camping Supplies and Minigolf
			["11"]={Complete = false}, --Redneck Road
			["12"]={Complete = false}, --Outerspace
		},
		Complete = false,
		Title = "Areas Discovered",
		Perk = "JourneyTrophy",
		Image = Vector3.new(4,0,0) -- image group, x, y
	};
	
	["Zombie Hunter"] = {
		Name = "Zombie Hunter",
		TotalSteps = 100,
		Steps = {
			["1"]={Complete = false}, --kill 100 zombies
		},
		Complete = false,
		Title = "Zombie Hunter",
		Perk = "ZombieHunterTrophy",
		Image = Vector3.new(4,0,0) -- image group, x, y
	};	
	
}
return achievements