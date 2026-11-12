
--Types of quest steps
--Get - Get items to give to the quest giver
--Put - Put some item into some object in world (removes item)
--Give - Give some item to an NPC (removes item)
--Kill - kill X amount of enemies
--ActionAmount - do some action a certain amount of times (like 5 perfect drum hits)
--UseItem - use an item on object in world (must have item but does not remove it)
--Search - search object by using proximityprompt action
--Action - do action (proximity prompt) on object
--Binoculars - use Binoculars to see close up of target object
--Telescope - use Telescope to see close up of target object
--GoToArea - Destination - Go to an area/zone
--TalkTo - talk to NPC - complete trigger is a dialog step
--Collect -- collect certain items that go to collections not inventory


--Main Quest Lines
-- Tutorial Quest Line -  level 1
--	TakeOutTheTrash, PrepareForCamp, BuildCamp, TheTruthIsOutThere,
--Junkyard Bunker Quest Line -  level 5
--	TinkerThinker,(NEED WireCutters), 
--Rocker Rob Quest Line - level 1
--	RatsRock,ToxicAvenging,MixedFeelings
--Catacombs Bunker Quest Line -  level 10
--	MissingTeens,StakeOut,SomethingStrangeInTheNeighborhood,PutARingOnIt,GraveDigger, BadNeighbor

--Side Quests
-- CoolerHeads
-- AShellOfATime
-- FetchMeABone


--Tools
-- WireCutters - Quest- CutToTheChase
-- Wrench - Quest TinkerThinker
-- Flashlight



local QuestStepTypes = {
	["Get"]="Get",
	["Put"]="Put",
	["Drop"]="Drop", --Drop item in zone (temp items)
	["Give"]="Give",
	["Kill"]="Kill",
	["Task"]="Task", --These have separate outside evaluators to determine when complete.
	["Action"]="Action", --Use ProximityPrompt
	["ActionAmount"]="ActionAmount",
	["UseItem"]="UseItem",
	["MoveItem"]="MoveItem", --Move an item you pick up as Temp item to some place / zone
	["Search"]="Search",
	["Binoculars"]="Binoculars",
	["Telescope"]="Telescope",
	["GoToArea"]="GoToArea",
	["TalkTo"]="TalkTo",
	["Collect"]="Collect",
	["TimedAction"]="TimedAction",
	["Build"]="Build",
	["HackAction"]="HackAction"
}

local quests = {
	
	--------------Tutorial Quests------------------------
	--TODO quest - get your items out of your suitcase (canteen, note, )
	
	["BePrepared"] = {
		Name = "BePrepared",
		DisplayName = "Be Prepared",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Pac",
		Steps = {
			[1]={Index=1; Name="GetCanteen"; DisplayName="Get Canteen"; Type=QuestStepTypes.Get; Object="Canteen1"; CurrentAmount=0; AmountNeeded=1; Complete=false, Guide="SuitcaseGuide"},
			[2]={Index=2; Name="GetNote"; DisplayName="Get Note"; Type=QuestStepTypes.Get; Object="MomNote"; CurrentAmount=0; AmountNeeded=1; Complete=false, Guide="SuitcaseGuide"},
			[3]={Index=3; Name="GetMatches"; DisplayName="Get Matches"; Type=QuestStepTypes.Get; Object="Matches"; CurrentAmount=0; AmountNeeded=1; Complete=false, Guide="SuitcaseGuide"},
			[4]={Index=4; Name="GetMoney"; DisplayName="Get Money"; Type=QuestStepTypes.Get; Object="5Dollar"; CurrentAmount=0; AmountNeeded=1; Complete=false, Guide="SuitcaseGuide"},
			[5]={Index=5; Name="FillCanteen"; DisplayName="Fill Canteen"; Type=QuestStepTypes.Get; Object="Water"; CurrentAmount=0; AmountNeeded=5; Complete=false, Guide="WaterGuide"},
			[6]={Index=6; Name="TalkToCounselorTony"; DisplayName="Talk to Counselor Tony"; Type=QuestStepTypes.TalkTo; Object="CounselorTony"; CurrentAmount=0; AmountNeeded=10; Complete=false, Guide="CounselorTonyGuide"},
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "You came to camp prepared, get your items from your suitcase",
		Reward = {["Experience"]=5;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		Guided = true
	};
	
	["OldToothy"] = {
		Name = "OldToothy",
		DisplayName = "Old Toothy",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="KillOldToothy"; DisplayName="Kill Old Toothy"; Type=QuestStepTypes.Kill; Object="OldToothy"; CurrentAmount=0; AmountNeeded=1; Complete=false}},
		Complete = false,
		Desc = "Kill Old Toothy",
		Reward = {["Item"]="TheJawbreaker";["Experience"]=1000;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
	};
	
	
	--FARMER JACK QUESTS
	
	--FARMER JACK QUESTS LEVEL 2
	["GiveMeAHand"] = {
		Name = "GiveMeAHand",
		DisplayName = "Give Me A Hand",
		QuestGiver = "FarmerJack",
		DependentQuest="",
		AvailableLevel = 2,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="FindFarmHand"; DisplayName="Find the Farmer's missing farm hand"; Type=QuestStepTypes.TalkTo; Destination="Farm"; Object="FarmHand"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find the Farmer's missing farm hand",
		Reward = {["Experience"]=20;["Access"]="Hay"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Howdy partner",
			Option1Text = "Got any work?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "Sure, find the body of my missing farm hand. He disappeared one day, but if you listen carefully you can hear his ghost haunting the place. Saying: Help me, I am stuck down here",
			Option1Text = "Ok I'll look for him",
			Option1Link = "3",
			Option2Text = "What?  So I can be the second missing kid on your property. No Thanks!",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Great, find him and I'll let you move hay for me",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_GiveMeAHand",
			Option2Text = "Wow, find him for free so I can then get work from you, no thanks.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "He's too old now to work much, so I can use your help moving hay.",
			Option1Text = "Alrighty",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks for finding him. ",
			Option1Text = "Thanks",
			Option1Link = "GetReward_GiveMeAHand",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you find him yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["AChickenCrossedTheRoad"] = {
		Name = "AChickenCrossedTheRoad",
		DisplayName = "A Chicken Crossed The Road",
		QuestGiver = "FarmerJack",
		DependentQuest="",
		AvailableLevel = 2,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="RoundEmUp"; DisplayName="Round up the chickens"; Type=QuestStepTypes.Drop; Object="Chicken"; Zone="Chicken Coop"; CurrentAmount=0; AmountNeeded=4; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Get all the missing chickens into the coop",
		Reward = {["Experience"]=20;["Item"]={Name="Egg",Amount=12}},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Ever since some teenagers, I'm guessin', mowed those crop circles in my grass, my chickens been actin' so strange, escaping their coop. Mind roundin' 'em up for me?",
			Option1Text = "Sure will do",
			Option1Link = "GiveQuest_AChickenCrossedTheRoad",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here's a dozen eggs for your hard work.",
			Option1Text = "Alrighty",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks for rounding up all those chickens, now we can make tasty chicken nuggets ",
			Option1Text = "Woh.  You didn't say you were going to kill them!",
			Option1Link = "GetReward_AChickenCrossedTheRoad",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did get all the chickens?",
			Option1Text = "No, those buggers are hard to catch",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--FARMER QUESTS LEVEL 3
	["NeverBeenSoIrrigated"] = {
		Name = "NeverBeenSoIrrigated",
		DisplayName = "Never Been So Irrigated",
		QuestGiver = "FarmerJack",
		DependentQuest="",
		AvailableLevel = 3,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="TurnOffPumps"; DisplayName="Turn off all irrigation pumps"; Type=QuestStepTypes.Task; Action="FixSprinklers"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find the Farmer's missing farm hand",
		Reward = {["Experience"]=20;["Item"]={Name="PitchFork",Amount=1}},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "My irrigation pumps are actin' crazy. Turn one on and the pressure is too low for another. Think you can fix 'em?",
			Option1Text = "Sure will do",
			Option1Link = "GiveQuest_NeverBeenSoIrrigated",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here you can take my Pitch Fork",
			Option1Text = "Alrighty",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks for fixing it! ",
			Option1Text = "Thanks",
			Option1Link = "GetReward_NeverBeenSoIrrigated",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you fix the irrigation yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--FARMER JILL QUESTS LEVEL 3
	["NoneOfYourBeesWax"] = {
		Name = "NoneOfYourBeesWax",
		DisplayName = "None Of Your BeesWax",
		QuestGiver = "FarmerJill",
		DependentQuest="",
		AvailableLevel = 2,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="BringBees"; DisplayName="Bring Bees Farmer Jill"; Type=QuestStepTypes.Drop; Object="BeeHive"; Zone="BeeHives"; CurrentAmount=0; AmountNeeded=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Bring bees to Farmer Jill's Bee Hives",
		Reward = {["Experience"]=20;["Item"]={Name="BeeBackpack",Amount=1}},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hiya kid. I have a small bee problem. Care to help out?",
			Option1Text = "Sure I can help",
			Option1Link = "GiveQuest_NoneOfYourBeesWax",
			Option2Text = "I am allergic to bee stings",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here you go for your hard work.",
			Option1Text = "Thanks",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Wow I have never seen so many stings.",
			Option1Text = "You could have warned me",
			Option1Link = "GetReward_NoneOfYourBeesWax",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you get those bees for me?",
			Option1Text = "Not yet",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--TODO add miniboss scarecrow
	["Scared"] = {
		Name = "Scared",
		DisplayName = "Scared",
		QuestGiver = "FarmerJill",
		DependentQuest="",
		AvailableLevel = 3,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="KillScarecrows"; DisplayName="Kill the Scarecrows"; Type=QuestStepTypes.Kill; Object="Scarecrow"; CurrentAmount=0; AmountNeeded=10; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Kill the walking scarecrows",
		Reward = {["Experience"]=40;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Lightning struck my scarecrow and now it walks. ",
			Option1Text = "Sure will do",
			Option1Link = "GiveQuest_Scared",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "He's too old now to work much, so I can use your help moving hay.",
			Option1Text = "Alrighty",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks getting rid of that nightmare",
			Option1Text = "Thanks",
			Option1Link = "GetReward_Scared",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you take care of the 'business'",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--FARMER JACK QUESTS LEVEL 5
	["SteakOut"] = {
		Name = "SteakOut",
		DisplayName = "Steak Out",
		QuestGiver = "Farmer",
		DependentQuest="",
		AvailableLevel = 5,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="GoToCowPasture"; DisplayName="Go to cow pasture at night"; Type=QuestStepTypes.Task; Action="GoToCowPasture"; Complete=false},
			[2]={Index=2; Name="FindCowEvidence"; DisplayName="Find evidence"; Type=QuestStepTypes.Task; Action="FindCowEvidence"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find out what happened to the Farmer's cows",
		Reward = {["Experience"]=40;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Howdy partner",
			Option1Text = "What's with the shotgun?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "Nearly every night one of my cows goes missing.  I see a bright flash of light, come out, and gone without a trace.",
			Option1Text = "Really? What do you think happened",
			Option1Link = "3",
			Option2Text = "Yeah I just remembered I had somewhere I need to go",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "I bet it's that Farmer Jeffrey flashing the headlights of his fancy new truck as he steals another cow of mine",
			Option1Text = "I can look into it",
			Option1Link = "GiveQuest_SteakOut",
			Option2Text = "Well good luck figuring that one out",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Thanks for at least going out there",
			Option1Text = "Alrighty",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Pulled up to the cloud? Boy that is the craziest lie I've ever heard",
			Option1Text = "Well actually...",
			Option1Link = "GetReward_SteakOut",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you find him yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--CHEF BARTH QUESTS
	
	--CHEF BARTH QUESTS LEVEL 1
	["MysteryMeat"] = {
		Name = "MysteryMeat",
		DisplayName = "Mystery Meat",
		QuestGiver = "ChefBarth",
		DependentQuest=nil,
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="GetRatMeat"; DisplayName="Get RatMeat"; Type=QuestStepTypes.Get; Object="RatMeat"; CurrentAmount=0; AmountNeeded=10; Complete=false}},
		Complete = false,
		Desc = "Get 10 Rat Meat for Chef Barth",
		Reward = {["Item"]={Name="MysteryMeat",Amount=1},["Item2"]={Name="FryingPan",Amount=1},["Experience"]=10;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey kid do me a favor",
			Option1Text = "What is it?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "There are a ton of rats coming out of the mess hall. Normally I would 'Takes care of them', but I could use your help. ",
			Option1Text = "Ok I I'll give it a try",
			Option1Link = "3",
			Option2Text = "That sounds like something I should avoid.  All my life.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Kill 10 rats and bring their meat to me and you can have this old frying pan",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_MysteryMeat",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here ya go. Don't ask me what it is.",
			Option1Text = "Thanks. Looks yummy.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "That's great. Maybe we can have some peace now.",
			Option1Text = "Thanks",
			Option1Link = "GetReward_MysteryMeat",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you take care of those rats yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["ToxicTrouble"] = {
		Name = "ToxicTrouble",
		DisplayName = "Toxic Trouble",
		QuestGiver = "ChefBarth",
		DependentQuest=nil,
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="KillToxicRat"; DisplayName="Kill Toxic Rat"; Type=QuestStepTypes.Kill; Object="ToxicRat"; CurrentAmount=0; AmountNeeded=1; Complete=false}},
		Complete = false,
		Desc = "There is this huge rat out there eating all my supplies. Go snuff him out",
		Reward = {["Item"]={Name="MouseTrap",Amount=1},["Experience"]=30;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey I could use your help",
			Option1Text = "What is it?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "There is this giant rat behind the ballpark.  It's killing all my cooking supplies. Go snuff it out",
			Option1Text = "Sure thing",
			Option1Link = "3",
			Option2Text = "That sounds like something I will NEVER do",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Kill that toxic menace",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_ToxicTrouble",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Great work kid",
			Option1Text = "Thanks.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "That's great. Now I can better supply the Messhall",
			Option1Text = "Thanks",
			Option1Link = "GetReward_ToxicTrouble",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you take care of that thing yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["SoupOfTheDay"] = {
		Name = "SoupOfTheDay",
		DisplayName = "Soup of the day",
		QuestGiver = "ChefBarth",
		DependentQuest="MysteryMeat",
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="GetMushrooms"; DisplayName="Get Mushrooms"; Type=QuestStepTypes.Get; Object="SpottedJoeMushroom"; CurrentAmount=0; AmountNeeded=5; Complete=false}},
		Complete = false,
		Desc = "Get 10 Rat Meat for Chef Barth",
		Reward = {["Item"]={Name="SpottedJoeMushroomSoup",Amount=1},["Item2"]={Name="PotHelmet",Amount=1},["Experience"]=20;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Got mushrooms?",
			Option1Text = "No, why would I?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "Grab some Spotted Joe Mushrooms for me. I'm gonna make some soup",
			Option1Text = "Ok I I'll give it a try",
			Option1Link = "3",
			Option2Text = "I don't know where they are",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Get 5 Spotted Joe Mushrooms for me and you can have a bowl of the soup",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_SoupOfTheDay",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here ya go. Best soup this side of the lake",
			Option1Text = "Thanks. Looks yummy.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "That's great. Now I can make a delicious soup",
			Option1Text = "Thanks",
			Option1Link = "GetReward_SoupOfTheDay",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you get my mushrooms yet",
			Option1Text = "No, still searching",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--COUNSELOR TONY QUESTS
	
	--COUNSELOR TONY QUESTS LEVEL 1	
	["PrepareForCamp"] = {
		Name = "PrepareForCamp",
		DisplayName = "Prepare For Camp",
		QuestGiver = "CounselorTony",
		DependentQuest="GophersOrGolfers",
		AvailableLevel = 1,
		Drawing="Alien",
		Steps = {
			[1]={Index=1; Name="GetHammer"; DisplayName="Get Mike's' hammer"; Type=QuestStepTypes.Get; Object="Hammer"; CurrentAmount=0; AmountNeeded=1; Complete=false},
			[2]={Index=2; Name="GetSledgeHammer"; DisplayName="Get Mike's Sledge Hammer"; Type=QuestStepTypes.Get; Object="SledgeHammer"; CurrentAmount=0; AmountNeeded=1; Complete=false},
			[3]={Index=3; Name="GatherLogs"; DisplayName="Gather Logs"; Type=QuestStepTypes.Get; Object="Log"; CurrentAmount=0; AmountNeeded=5; Complete=false},
			[4]={Index=4; Name="GatherRocks"; DisplayName="Gather Rocks"; Type=QuestStepTypes.Get; Object="Rock"; CurrentAmount=0; AmountNeeded=5; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Prepare your camp by gathering the tools, logs, and rocks",
		Reward = {["Experience"]=60;["Quest"]="BuildCamp"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey kid, you should try to earn your camping merit badge",
			Option1Text = "Sure how?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "You'll need to get a hammer and sledge hammer from Molotov Mike and some wood and rocks ",
			Option1Text = "Ok I'll give it a try",
			Option1Link = "3",
			Option2Text = "That sounds too hard",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Prepare for camp and I will",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_PrepareForCamp",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Great job. Go build the camp now",
			Option1Text = "Ok",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "That's great. Always be prepared.",
			Option1Text = "Thanks",
			Option1Link = "GetReward_PrepareForCamp",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you prepare for camp yet",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--MOLOTOV MIKE QUESTS
	
	--MOLOTOV MIKE QUUESTS LEVEL 1
	["GophersOrGolfers"] = {
		Name = "GophersOrGolfers",
		DisplayName = "Gophers Or Golfers",
		QuestGiver = "MolotovMike",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Nuclear",
		Steps = {[1]={Index=1; Name="SetBearTrapHole1"; DisplayName="Set a Bear Trap at Gopher hole 1"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot1.BearTrapSpot1"; Object="BearTrap"; Amount=1; Complete=false},
			[2]={Index=2; Name="SetBearTrapHole2"; DisplayName="Set a Bear Trap at Gopher hole 2"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot2.BearTrapSpot2"; Object="BearTrap"; Amount=1; Complete=false},
			[3]={Index=3; Name="SetBearTrapHole3"; DisplayName="Set a Bear Trap at Gopher hole 3"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot3.BearTrapSpot3"; Object="BearTrap"; Amount=1; Complete=false},
			[4]={Index=4; Name="SetBearTrapHole4"; DisplayName="Set a Bear Trap at Gopher hole 4"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot4.BearTrapSpot4"; Object="BearTrap"; Amount=1; Complete=false},
			[5]={Index=5; Name="SetBearTrapHole5"; DisplayName="Set a Bear Trap at Gopher hole 5"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot5.BearTrapSpot5"; Object="BearTrap"; Amount=1; Complete=false},
			[6]={Index=6; Name="SetBearTrapHole6"; DisplayName="Set a Bear Trap at Gopher hole 6"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot6.BearTrapSpot6"; Object="BearTrap"; Amount=1; Complete=false},
			[7]={Index=7; Name="SetBearTrapHole7"; DisplayName="Set a Bear Trap at Gopher hole 7"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot7.BearTrapSpot7"; Object="BearTrap"; Amount=1; Complete=false},
			[8]={Index=8; Name="SetBearTrapHole8"; DisplayName="Set a Bear Trap at Gopher hole 8"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.BearTrapSpot8.BearTrapSpot8"; Object="BearTrap"; Amount=1; Complete=false}
		},
		PreActions={
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.Areas.CampingStore.BearTrapPile.BearTrap2.TakeTempHold",
				Props={Enabled=true}
			},

		};		--TODO change this back after last quest in chain
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Attempt to Trap the gophers",
		Reward = {["Experience"]=20;["ItemUnlocked"]="Hammer|SledgeHammer";["Quest"]="PrepareForCamp"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "If you set a bear trap for each gopher hole you can have my tools",
			Option1Text = "Deal!",
			Option1Link = "GiveQuest_GophersOrGolfers",
			Option2Text = "I don't want to harm the cute gophers",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Well you tried your best. Those gophers are clever little devils",
			Option1Text = "Thanks. These tools will come in handy when me and my friends go camping",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Did you set the traps?",
			Option1Text = "Yep all done",
			Option1Link = "GetReward_GophersOrGolfers",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you set the traps?",
			Option1Text = "Nope I might later",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
	--NO QUEST GIVER QUESTS
	
	--NO QUEST GIVER QUESTS LEVEL 1
	["BuildCamp"] = {
		Name = "BuildCamp",
		DisplayName = "Build Camp",
		QuestGiver = "",
		DependentQuest="PrepareForCamp",
		AvailableLevel = 1,
		Drawing="Alien",
		Steps = {
			[1]={Index=1; Sequential=true; Name="BuildTent"; DisplayName="Build Your Tent at Night"; Type=QuestStepTypes.Build; Object="Tent"; Complete=false},
			[2]={Index=2; Sequential=true; Name="BuildCampfire"; DisplayName="Build a Campfire"; Type=QuestStepTypes.Build; Object="Campfire"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Build a camp anywhere outside of the neighborhood at night",
		Reward = {["Experience"]=60;["Quest"]="AccessGranted"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	--NO QUEST GIVER QUESTS LEVEL 10
	["AccessGranted"] = {
		Name = "AccessGranted",
		DisplayName = "Access Granted",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 10,
		Drawing="Pac",
		Steps = {
			[1]={Index=1; Name="GetAccessToMessHall"; DisplayName="Enter MessHall at night"; Type=QuestStepTypes.GoToArea; Destination="MessHall"; Condition="Night"; Amount=1; Complete=false},
			[2]={Index=2; Name="UnlockShed"; DisplayName="Use Computer to unlock Shed"; Type=QuestStepTypes.HackAction; Computer="MessHall"; Action="UnlockShed"; Amount=1; Complete=false},
			[3]={Index=3; Name="DisableCameras"; DisplayName="Use Computer to disable cameras"; Type=QuestStepTypes.HackAction; Computer="MessHall"; Action="DisableCameras"; Amount=1; Complete=false},
			[4]={Index=4; Name="GetHedgetrimmers"; DisplayName="Get Hedge Trimmers"; Type=QuestStepTypes.Get; Object="HedgeTrimmers"; Amount=1; Complete=false}	
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find a way into the Mess Hall at night to gain access to the computer. Disable the Shed lock and cameras so you can access camp storage to get hedge trimmers",
		Reward = {["Experience"]=20;["Quest"]="TheTruthIsOutThere"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
	};
	
	["TheTruthIsOutThere"] = {
		Name = "TheTruthIsOutThere",
		DisplayName = "The Truth Is Out There",
		QuestGiver = "",
		DependentQuest="BuildCamp",
		AvailableLevel = 10,
		Drawing="Alien",
		Steps = {
			[1]={Index=1; Name="CutBrambles"; DisplayName="Cut Brambles on east entrance to deep woods"; Type=QuestStepTypes.UseItem; Object="Brambles"; CurrentAmount=0; AmountNeeded=1; Complete=false},
			[2]={Index=2; Sequential=true; Name="GetIntoWoods"; DisplayName="Get Into Woods"; Type=QuestStepTypes.GoToArea; Object="Woods"; Complete=false},
			[3]={Index=3; Sequential=true; Name="LookForEvidence"; DisplayName="Look For Evidence"; Type=QuestStepTypes.Get; Object="AlienWreckage"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Build a camp anywhere outside of the neighborhood",
		Reward = {["Experience"]=60;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	--------------END Tutorial Quests------------------------


	["Bunk2Bunker"] = {
		Name = "Bunk2Bunker",
		DisplayName = "Bunk 2 Bunker",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Pac",
		Steps = {
			[1]={Index=1; Name="LightsOut"; DisplayName="Lay In Bunk at Nightime"; Type=QuestStepTypes.Search; Destination="EyeBunker"; Object="EyeBunkerHatch"; Amount=1; Complete=false},
			[2]={Index=1; Name="SneakOut"; DisplayName="Sneak Out of Cabin"; Type=QuestStepTypes.GoToArea; Destination="CabinSquare"; Complete=false},
			[3]={Index=1; Name="FindBunker"; DisplayName="Find Bunker in the woods"; Type=QuestStepTypes.Search; Destination="EyeBunker"; Object="EyeBunkerHatch"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "There is a camp legend about a hidden underground bunker in the woods behind the cabins. Check it out at night, but don't get caught by the counselor.",
		Reward = {["Experience"]=20;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
	};
	





	
	

	--RIDDLE ROCK MAIN ISLE
	
	["FetchMeABone"] = {
		Name = "FetchMeABone",
		DisplayName = "Fetch Me A Bone",
		QuestGiver = "Joey",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="GiveBone"; DisplayName="Give Bone to Bosco"; Type=QuestStepTypes.Put; Destination="Bosco"; Object="Bone"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Fetch Bosco a bone so you can play Zogborg",
		Reward = {["Experience"]=20;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "My dog won't shut up. Can you go find him a bone and give it to him. Then you can play Zogborg",
			Option1Text = "Ok. Not sure where to find a bone, but I am sure it won't be too hard",
			Option1Link = "GiveQuest_FetchMeABone",
			Option2Text = "Nevermind",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Sure it's all yours. First level is a tough one!",
			Option1Text = "Thanks",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Awesome, thanks a lot, now I can finally concentrate on my video game",
			Option1Text = "Yeah now move over my turn",
			Option1Link = "GetReward_FetchMeABone",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "I still hear him barking. Can you get him the bone?",
			Option1Text = "Yeah I have not found one yet, sorry dude",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["CoolerHeads"] = {
		Name = "CoolerHeads",
		DisplayName = "Cooler Heads",
		QuestGiver = "HotelClerk",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Cube",
		Steps = {[1]={Index=1; Name="GetIce"; DisplayName="Put ice in hotel fridge"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.Hotel_Ice"; Object="IceCube"; Amount=5; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Go buy some ice and put it in the cooler outside of the Star Point Motel then report to the motel clerk for your reward.",
		Reward = {["Money"]=5;["Experience"]=10;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog3 = {
			NPCText = "Well we do need some more ice. Stuff keeps disappearing. Strangest thing since we hardly get any guests. Go get some ice and put it in the cooler outside and I'll pay you $5",
			Option1Text = "Sure sounds great",
			Option1Link = "GiveQuest_CoolerHeads",
			Option2Text = "Nevermind",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
				NPCText = "Great, thanks a lot. Here is your reward",
				Option1Text = "Bye",
				Option1Link = "Close",
				Option2Text = "",
				Option2Link = "",
				Option3Text = "",
		};
		QuestCompleteDialog = {
				NPCText = "Hey there, nice to see you again. Did you get the ice?",
				Option1Text = "Yes I did",
				Option1Link = "GetReward_CoolerHeads",
				Option2Text = "",
				Option2Link = "",
				Option3Text = "",
				Option3Link = "",
		};
		QuestNotCompleteDialog = {
				NPCText = "Hey there, nice to see you again. Did you get the ice?",
				Option1Text = "Sorry I don't have the ice yet",
				Option1Link = "Close",
				Option2Text = "",
				Option2Link = "",
				Option3Text = "",
				Option3Link = "",
		};
	};
	
	--Quest Chain With Rocker Rob
	["RatsRock"] = {
		Name = "RatsRock",
		DisplayName = "Rats Rock",
		QuestGiver = "RockerRob",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing = "Music",
		Steps = {[1]={Index=1; Name="HitDrumsPerfect"; DisplayName="Hit drums perfectly"; Type=QuestStepTypes.ActionAmount; CurrentAmount=0; AmountNeeded=5; Complete=false}},
		Complete = false,
		Desc = "Go sit at the drums and hit each drum or cymbal the number of times shown. Get 5 perfect hits",
		Reward = {["Item"]="DeathRatsTShirt";["Experience"]=30;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey there. Wanna join the band?",
			Option1Text = "Really?",
			Option1Link = "2",
			Option2Text = "No I don't think so",
			Option2Link = "Close",
			Option3Text = "I don't know how to play an instrument and I can't sing",
			Option3Link = "Close",
		};
		QuestDialog2 = {
			NPCText = "Ha. No not really, but our drummer went on vacation and we need ya to fill in on this song",
			Option1Text = "Ok I I'll give it a try",
			Option1Link = "3",
			Option2Text = "Nevermind. I'm busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Go sit at the drums and hit each drum or cymbal the number of times shown. Get 5 perfect hits and I will give you a Death Rat t-shirt. It will come in handy some time once we are famous dude.",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_RatsRock",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here ya go. Your very own Death Rat t-shirt",
			Option1Text = "All I get is a crummy t-shirt?",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Stellar! You rocked.",
			Option1Text = "Thanks",
			Option1Link = "GetReward_RatsRock",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Well what are you waiting for? Let's rock!",
			Option1Text = "Alright",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["ToxicAvenging"] = {
		Name = "ToxicAvenging",
		DisplayName = "Toxic Avenging",
		QuestGiver = "RockerRob",
		DependentQuest="RatsRock",
		AvailableLevel = 1,
		Drawing="Skull",
		Steps = {[1]={Index=1; Name="KillRats"; DisplayName="Kill Rats"; Type=QuestStepTypes.Kill; CurrentAmount=0; AmountNeeded=10; Complete=false}},
		Complete = false,
		Desc = "Kill 10 humongous rats for Rocker Rob",
		Reward = {["Item"]="HalfEatenBurger";["Experience"]=50;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey I got another heinous mission for you little drummer dude!",
			Option1Text = "What is it?",
			Option1Link = "2",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog2 = {
			NPCText = "When I'm not rocking this garage I'm flipping burgers at Sloppy Burger.  Last night I went around back to throw out the garbage and I saw a humongous rat with red eyes. It bit at me and ended up biting half of my burger I was holding. Now I was going to end it's song by drumming its head, but I had to get a new burger, so I ran.",
			Option1Text = "Ok I I'll give it a try",
			Option1Link = "3",
			Option2Text = "Why on earth would I want to be eaten by a gigantic rat?",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Kill 10 humongous rats and you can have my left over lunch.",
			Option1Text = "Ok",
			Option1Link = "GiveQuest_ToxicAvenging",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here ya go. I don't want the rest of this burger anyways",
			Option1Text = "Thanks. Looks yummy.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "No way dude! That's awesome.",
			Option1Text = "Thanks",
			Option1Link = "GetReward_ToxicAvenging",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you take care of those rats yet?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["MixedFeelings"] = {
		Name = "MixedFeelings",
		DisplayName = "Mixed Feelings",
		QuestGiver = "RockerRob",
		DependentQuest="ToxicAvenging",
		AvailableLevel = 1,
		Drawing="Music",
		Steps = {[1]={Index=1; Name="DistractSecretary"; Hidden=true; DisplayName="Distract the Q82 Secretary"; Type=QuestStepTypes.TimedAction; TriggeredTime=0; StartTrigger="StartTalkingOnPhone"; EndTrigger="StopTalkingOnPhone"; CompleteTrigger="Zone_RadioTVStationBasementExit"; Triggered=false; Complete=false},
		[2]={Index=2; Name="TurnInTape"; DisplayName="Give mixed tape to Radio Rod"; Type=QuestStepTypes.Give; Item="MixedTape", NPC="RadioRod", Complete=false}},
		Complete = false,
		Desc = "Give Rocker Rob's mixed tape to Radio Rod",
		Reward = {["Item"]="BackstagePass";["Experience"]=50;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey need your help again. Could you give Radio Rod down at the Q82 Radio Station our mixed tape?",
			Option1Text = "Sure thing",
			Option1Link = "GiveQuest_MixedFeelings",
			Option2Text = "I'm too busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here ya go. A backstage pass to any concert we have in the future when we are famous.",
			Option1Text = "Thanks",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "So did he love it?",
			Option1Text = "Something like that",
			Option1Link = "GetReward_MixedFeelings",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you give the mixed tape to Radio Rod?",
			Option1Text = "No, but I'll get around to it",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["FindDad"] = {
		Name = "FindDad",
		DisplayName = "Find Dad",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Pac",
		Steps = {[1]={Index=1; Name="FindDad"; DisplayName="Talk to Dad. He is likely in from of the TV"; Type=QuestStepTypes.TalkTo; Destination="Home"; Object="Dad"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find Dad",
		Reward = {["Experience"]=20;["Quest"]="TakeOutTheTrash"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
	};
	
	["TakeOutTheTrash"] = {
		Name = "TakeOutTheTrash",
		DisplayName = "Take Out The Trash",
		QuestGiver = "Dad",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Nuclear",
		Steps = {[1]={Index=1; Name="GetKitchenTrash"; DisplayName="Take the kitchen trash out and put it in the garbage can"; Type=QuestStepTypes.Put; Destination="Workspace.QuestTargets.Garbage_Can_Main.Garbage_Can_Main"; Object="Trashbag"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Take the kitchen trash out to the garbage can",
		Reward = {["Experience"]=20;["ItemUnlocked"]="Hammer|SledgeHammer";["Quest"]="PrepareForCamp"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "If you take out the trash I'll let you borrow my tools",
			Option1Text = "OK I guess",
			Option1Link = "GiveQuest_TakeOutTheTrash",
			Option2Text = "No that sounds disgusting.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Ok. For being such a good kid. You can use my tools. There should be a hammer and a sledge hammer in the garage.",
			Option1Text = "Thanks. Those might come in handy when me and my friends go camping",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Ok so you took care of the trash?",
			Option1Text = "Yep all done",
			Option1Link = "GetReward_TakeOutTheTrash",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "So you took the trash out?",
			Option1Text = "Nope I might later",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
	["HeardANoise"] = {
		Name = "HeardANoise",
		DisplayName = "Heard A Noise",
		QuestGiver = "Dad",
		DependentQuest="",
		AvailableLevel = 10,
		Drawing="Ghost",
		Steps = {[1]={Index=1; Name="SearchBathroomMirror"; DisplayName="Search the bathroom mirror"; Type=QuestStepTypes.Search; Destination="Bathroom"; Object="Mirror"; Amount=1; Complete=false},
		[2]={Index=2; Name="SearchBathroomToilet"; DisplayName="Search the bathroom toilet"; Type=QuestStepTypes.Search; Destination="Bathroom"; Object="Toilet"; Amount=1; Complete=false},
		[3]={Index=3; Name="SearchBathroomShower"; DisplayName="Search the bathroom shower"; Type=QuestStepTypes.Search; Destination="Bathroom"; Object="Shower"; Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Dad heard a strange noise in the bathroom. He thinks there may be a mouse. Go check it out.",
		Reward = {["Experience"]=20;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "I heard a strange noise from our bathroom.  Can you go check it out, I think it might be a mouse",
			Option1Text = "Ok sounds a little creepy",
			Option1Link = "GiveQuest_HeardANoise",
			Option2Text = "No I think I will just stay safe thank you.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Ok. For being such a good kid. You can use my tools. There should be a hammer and a sledge hammer in the garage.",
			Option1Text = "Thanks. Those might come in handy when me and my friends go camping",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Ok so nothing to be concerned about?  Kiddo you look like you've seen a ghost.",
			Option1Text = "No...no... I didn't find anything",
			Option1Link = "GetReward_HeardANoise",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you check out the bathroom?  Anything scary besides the hair in the tub?",
			Option1Text = "Nope I might check it out later",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--Main Quest - Zombies level 9
	--MissingTeens chain
	["MissingTeens"] = {
		Name = "MissingTeens",
		DisplayName = "Missing Teens",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 9,
		Drawing="Web",
		Steps = {
			[1]={Index=1; Name="GoToLastKnownLocation"; DisplayName="Go to the last know location"; Type=QuestStepTypes.GoToArea; Destination="Football Field"; Complete=false},
			[2]={Index=2; Sequential=true; Name="FindClue"; DisplayName="Search for a clue"; Type=QuestStepTypes.Binoculars; Object="TireTracksTarget"; Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find out any clues to the whereabouts of the missing teens",
		Reward = {["Experience"]=20;["Quest"]="StakeOut"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		PreActions={
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.QuestStepTempObjects.MissingTeens",
				Props={Transparency=0,CanCollide=true}
			},
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.QuestStepTempObjects.MissingTeens.SingleObjects.Tiretracks1.Texture",
				Props={Transparency=.3}
			},
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.QuestStepTempObjects.MissingTeens.SingleObjects.Tiretracks2.Texture",
				Props={Transparency=.3}
			},
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.QuestStepTempObjects.MissingTeens.SingleObjects.Tiretracks3.Texture",
				Props={Transparency=.3}
			},
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.QuestStepTempObjects.MissingTeens.SingleObjects.Tiretracks4.Texture",
				Props={Transparency=.3}
			},
			{
				Type="ChangeClientObjectProperties",
				Target = "Workspace.RestrictedZones.FootballFieldArea",
				Props={CanCollide=true}
			}

		};		--TODO change this back after last quest in chain
	};
	
	["GraveDigger"] = {
		Name = "GraveDigger",
		DisplayName = "Grave Digger",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 9,
		Drawing="Skull",
		Steps = {
			[1]={Index=4; Sequential=true; Name="FindMuddyTires"; DisplayName="Find car with muddy tires"; Type=QuestStepTypes.Search; Object="NeighborTruck"; Complete=false}	
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Someone drove on the football field. Find the car around town with muddy tires",
		Reward = {["Experience"]=20;["Quest"]=""},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	
	
	
	
	
	--Main Quest - Zombies level 9
	["StakeOut"] = {
		Name = "StakeOut",
		DisplayName = "Stakeout",
		QuestGiver = "",
		DependentQuest="GraveDigger",
		AvailableLevel = 9,
		Drawing="Letter",
		Steps = {
			[1]={Index=1; Name="GetMunchies"; DisplayName="Get some munchies (chips) for the stakeout"; Type=QuestStepTypes.Get; Object="Chips"; CurrentAmount=0; AmountNeeded=5; Complete=false},
			[2]={Index=2; Sequential=true; Name="GetDrinks"; DisplayName="Get some Nice Cola"; Type=QuestStepTypes.Get; Object="NiceCola"; CurrentAmount=0; AmountNeeded=5; Complete=false},
			[3]={Index=3; Sequential=true; Name="StakeoutTheNeighbor"; DisplayName="Spy on the neighbor at night"; Type=QuestStepTypes.Binoculars; Object="BackyardGrave"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "The neighbor must know something about what happened to the two teens. Let's see if we can find out more",
		Reward = {["Experience"]=60;["Quest"]="SomethingStrangeInTheNeighborhood"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};

	--Main Quest - Zombies level 9
	["SomethingStrangeInTheNeighborhood"] = {
		Name = "SomethingStrangeInTheNeighborhood",
		DisplayName = "Something Strange In The Neighborhood",
		QuestGiver = "",
		DependentQuest="StakeOut",
		AvailableLevel = 9,
		Drawing="Letter",
		Steps = {[1]={Index=1; Name="SearchGrave"; DisplayName="Search the neighbors yard"; Type=QuestStepTypes.Search; Destination="NeighborBackyard"; Object="NeighborGrave"; RequiredItem="Shovel", Amount=1; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Go see what your neighbor burried",
		Reward = {["Experience"]=20;["Item"]="HighschoolRing";["Quest"]="PutARingOnIt"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	--Main Quest - Zombies level 9
	["PutARingOnIt"] = {
		Name = "PutARingOnIt",
		DisplayName = "Put A Ring On It",
		QuestGiver = "",
		DependentQuest="SomethingStrangeInTheNeighborhood",
		AvailableLevel = 9,
		Drawing="Web",
		Steps = {
			[1]={Index=1; Name="AskAround"; DisplayName="Ask school kids"; Type=QuestStepTypes.TalkTo; Destination="School"; Object="Julia"; Amount=1; Complete=false},
			[2]={Index=2; Name="AskAround"; DisplayName="Ask school kids"; Type=QuestStepTypes.TalkTo; Destination="School"; Object="Ralph"; Amount=1; Complete=false},
			[3]={Index=3; Name="AskAround"; DisplayName="Ask school kids"; Type=QuestStepTypes.TalkTo; Destination="School"; Object="Sam"; Amount=1; Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Ask around the school to see if anyone knows who owned this ring",
		Reward = {["Experience"]=40;["Quest"]="StakeOut"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	--Main Quest - Zombies level 9
	["BadNeighbor"] = {
		Name = "BadNeighbor",
		DisplayName = "Bad Neighbor",
		QuestGiver = "",
		DependentQuest="PutARingOnIt",
		AvailableLevel = 9,
		Drawing="Skull",
		Steps = {
			[1]={Index=1; Sequential=true; Name="FindClues"; DisplayName="Search for clues at the neighbors house"; Type=QuestStepTypes.Search; Object="Desk"; Complete=false}	
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "It was Johnny's ring. We have to find more at the neighbors house",
		Reward = {["Experience"]=40;["Item"]="SkullKey";["Quest"]=""},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	
	
	--["GhostBusting"] = {
	--	Name = "GhostBusting",
	--  DisplayName = "GhostBusting",
	--	QuestGiver = "", --Empty quest giver should just award quest when done
	--	TotalSteps = 1,
	--	Steps = {[1]={Index=1; Name="KillGhosts"; Type="Kill"; CurrentAmount=0; AmountNeeded=10; Complete=false}},
	--	Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
	--	Desc = "Find that ghost that jumped out of the mirror and kill him and any others you find",
	--	Reward = {["Experience"]=50;},
	--	Picture = 137510460,
	--	Frequency = "Once", --Once,Daily,Anytime
	--};
	
	["BetterLightThanNever"] = {
		Name = "BetterLightThanNever",
		DisplayName = "Better Light Than Never",
		QuestGiver = "",
		QuestTrigger = {Object="Beacon", RequiredItem="", RequiredHeldItem="Flashlight", StartText="hmm…it seemed to cause some kind of shake. seems it needs a much more powerful source of light"},
		DependentQuest="",
		Drawing="Cube",
		AvailableLevel = 1,
		Steps = {
			[1]={
				Index=1; 
				Name="FindStrongerLightsource"; 
				DisplayName="Find stronger light source"; 
				Type="DiscoverDestination"; 
				Destination="Lighthouse"; 
				DiscoverText="Now this is a strong light. Maybe I could point it to the stone beacon"; 
				Complete=false},
			[2]={
				Index=2;
				Sequential=true;
				Name="ReplaceLightbulb"; 
				DisplayName="Replace Lighthouse Lightbulb"; 
				Type="UseItem"; 
				Object="lighthouseLight"; 
				RequiredItem="LighthouseBulb"; 
				PropertyChange="Enabled";
				PropertyChangeValue=true;
				Complete=false},
			[3]={
				Index=3; 
				Sequential=true;
				Name="CleanLightHouseWindows"; 
				DisplayName="Clean Lighthouse Windows"; 
				Type="UseItem"; 
				Object="lighthouseGlass"; 
				RequiredItem="CleaningSupplies"; 
				PropertyChange="Transparency";
				PropertyChangeValue=1;
				Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Figure out how to activate the stone beacon",
		Reward = {["Experience"]=100;["Item"]="SphereCrystal";["Quest"]="ExploreTheSphereBunker"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true
	};
	
	["CutToTheChase"] = {
		Name = "CutToTheChase", 
		DisplayName = "Cut To The Chase",
		QuestGiver = "Scott",
		DependentQuest="",
		AvailableLevel = 4,
		Drawing="Unicorn",
		Steps = {[1]={Index=1; Name="StopBullies"; DisplayName="Stop the neighborhood bullies"; Type=QuestStepTypes.Kill; Object="Bully"; CurrentAmount=0; AmountNeeded=10; Complete=false},
		[2]={Index=2; Name="GotMilk"; DisplayName="Get Milk"; Type=QuestStepTypes.Get; Object="Milk"; Amount=10; Complete=false},},
		Complete = false,
		Desc = "Help Scott get back at his bullies",
		Reward = {["Item"]="Wirecutters";["Experience"]=50;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey there. I'm working on my next gadget. I'll let you know when it is done.",
			Option1Text = "Can I borrow your Wire Cutters?",
			Option1Link = "2",
			Option2Text = "Sounds cool. Can't wait.",
			Option2Link = "Close",
			Option3Text = "Nevermind",
			Option3Link = "Close",
		};
		QuestDialog2 = {
			NPCText = "I kind of need them, but you can have my spare set if you help me with a problem I have.",
			Option1Text = "Sure what is it?",
			Option1Link = "3",
			Option2Text = "Oh I forgot something. I gotta go.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "The bullies around school have been giving me more trouble than usual lately. Could you stop them for me? Also get me a ton of milk, I'm really thirsty!",
			Option1Text = "Yeah I think I know what might stop them",
			Option1Link = "GiveQuest_CutToTheChase",
			Option2Text = "Well...I don't know.  I like my face the way it is.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Here is my extra set of wire cutters like I promised.",
			Option1Text = "thanks a lot",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks for getting back at the bullies",
			Option1Text = "No problem",
			Option1Link = "GetReward_CutToTheChase",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Is it safe around school now?",
			Option1Text = "Sorry I didn't do anything yet.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["TinkerThinker"] = {
		Name = "TinkerThinker",
		DisplayName = "Tinker Thinker",
		QuestGiver = "MechanicRick",
		DependentQuest="",
		AvailableLevel = 4,
		Drawing = "Unicorn",
		Steps = {
			[1]={
				Index=1; 
				Name="BreakIntoJunkyard"; 
				DisplayName="Find way into Junkyard"; 
				Type=QuestStepTypes.UseItem; 
				Object="Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLink"; 
				RequiredItem="Wirecutters"; 
				PostActions={
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLink",
						Props={Transparency=1}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLinkB",
						Props={Transparency=.1}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLinkC",
						Props={CanCollide=false}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.RestrictedZones.JunkyardRestrictedArea",
						Props={CanCollide=false}
					}
				};
				Complete=false;
			},
			[2]={Index=2; Name="GetCamshaft"; DisplayName="Get a Camshaft"; Type=QuestStepTypes.Get; Object="Camshaft"; CurrentAmount=0; AmountNeeded=1; Complete=false},
			[3]={Index=3; Name="GetDistributor"; DisplayName="Get a Distributor"; Type=QuestStepTypes.Get; Object="Distributor"; CurrentAmount=0; AmountNeeded=1; Complete=false},
			[4]={Index=4; Name="GetCarburetor"; DisplayName="Get a Carburetor"; Type=QuestStepTypes.Get; Object="Carburetor"; CurrentAmount=0; AmountNeeded=1; Complete=false},
		},
		Complete = false,
		Desc = "Find Mechanic Rick the parts he needs from the Junkyard",
		Reward = {["Item"]="Wrench";["Experience"]=50;["Quest"]="ExploreTheSphereBunker"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog = {
			NPCText = "Hey what do you want? Can't you tell I am busy?",
			Option1Text = "Can I borrow your wrench",
			Option1Link = "2",
			Option2Text = "Sorry didn't mean to bother you",
			Option2Link = "Close",
			Option3Text = "Nevermind",
			Option3Link = "Close",
		};
		QuestDialog2 = {
			NPCText = "What on Earth would you need that for. You don't look strong enough to even lift it.",
			Option1Text = "I just need one ok?",
			Option1Link = "3",
			Option2Text = "Thanks a lot bye.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog3 = {
			NPCText = "Alright I'll tell you what. If you can get me a camshaft, distributor and a carburetor, then you got yourself a wrench.",
			Option1Text = "Ok. No problem I'll start right away.",
			Option1Link = "GiveQuest_TinkerThinker",
			Option2Text = "Actually that sounds too hard.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Wow. I don't know how you did it, but here's your wrench.",
			Option1Text = "Awesome thanks",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Thanks for the parts",
			Option1Text = "Thanks for the wrench",
			Option1Link = "GetReward_TinkerThinker",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you get those parts yet?",
			Option1Text = "Nope",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	["RadioShow"] = {
		Name = "RadioShow",
		DisplayName = "Radio Show",
		QuestGiver = "",
		DependentQuest="",
		AvailableLevel = 7,
		Drawing = "Unicorn",
		Steps = {
			[1]={
				Index=1; 
				Name="BreakIntoRadioTower"; 
				DisplayName="Find way into the Radio Tower"; 
				Type=QuestStepTypes.UseItem; 
				Object="Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLink"; 
				RequiredItem="Wirecutters"; 
				PostActions={
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLink",
						Props={Transparency=1}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLinkB",
						Props={Transparency=.1}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.QuestTargets.JunkyardFence.JunkyardFenceChainLinkC",
						Props={CanCollide=false}
					},
					{
						Type="ChangeClientObjectProperties",
						Target = "Workspace.RestrictedZones.JunkyardRestrictedArea",
						Props={CanCollide=false}
					}
				};
				Complete=false;
			},
			[2]={Index=2; Name="PlaceSatelliteDish"; DisplayName="Place the Satellite Dish on top of the Radio Tower"; Type=QuestStepTypes.Put; Object="RadioTowerTop"; Complete=false},
		},
		Complete = false,
		Desc = "Place the satellite dish on top of the Radio Tower to get the best signal",
		Reward = {["Item"]="RadioSignalPrintout";["Experience"]=150;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
	};
	
	["AShellOfATime"] = {
		Name = "AShellOfATime",
		DisplayName = "A Shell Of A Time",
		QuestGiver = "BeachBodhi",
		DependentQuest="",
		AvailableLevel = 1,
		Drawing="Letter",
		Steps = {[1]={Index=1; Name="CollectShells"; DisplayName="Collect all types of shells and starfish etc"; Type=QuestStepTypes.Collect; Collection="Shells"; Complete=false}},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Collect all types of shells and starfish found on the beach. Some are rare.",
		Reward = {["Money"]=10;["Experience"]=20;},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog3 = {
			NPCText = "Cowabunga, dudes! We're shredding the shells on this beach with a gnarly contest to see who can score the most radical loot – 20 different kinds of shells and starfish, radder than a double overhead wave! You stoked to hang ten and join the shred?",
			Option1Text = "Sure sounds great",
			Option1Link = "GiveQuest_AShellOfATime",
			Option2Text = "Nevermind",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Stoked! You shredded those shores and snagged all twenty, man! Respect from the reef!",
			Option1Text = "Bye",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Yo, brah, how many shells did you score?",
			Option1Text = "Yes I did",
			Option1Link = "GetReward_AShellOfATime",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Yo, brah, how many shells did you score?",
			Option1Text = "I didn't find them all yet",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
	};
	
	--"LostDog","ADirtyDeed","Lookout
		
	["ADirtyDeed"] = {
		Name = "ADirtyDeed",
		DisplayName = "A Dirty Deed",
		QuestGiver = "ParkRangerSpruce",
		DependentQuest="",
		AvailableLevel = 5,
		Drawing="Skull",
		Steps = {
			[1]={Index=1; Name="GetPoo"; DisplayName="Collect samples from the wolf for further study"; Type=QuestStepTypes.Get; Object="poop"; CurrentAmount=0; AmountNeeded=10; Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Gather wolf poo samples for further study by Ranger Spruce",
		Reward = {["Experience"]=200;["Money"]=20},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "There are rumors of the wolf walking upright on its legs at night and attacking campers.  I want to collect some scat samples from the wolf for further study.",
			Option1Text = "Well that sounds dangerous and disgusting. Count me in.",
			Option1Link = "GiveQuest_ADirtyDeed",
			Option2Text = "You will never get me to collect poo while being eaten by a wolf.  Thanks but no thanks.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Wow I didn't think you would actually do it (no pun intended). Thought I was going to be stuck with it. Here's your money.",
			Option1Text = "Thanks.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Did you do your duty?",
			Option1Text = "Yes, it was the most distgusting thing I've ever done",
			Option1Link = "GetReward_ADirtyDeed",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you do your duty?",
			Option1Text = "Nope not yet",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
	["TheSporeYouKnow"] = {
		Name = "TheSporeYouKnow",
		DisplayName = "The Spore You Know",
		QuestGiver = "ParkRangerSpruce",
		DependentQuest="ADirtyDeed",
		AvailableLevel = 5,
		Drawing="Skull",
		Steps = {
			[1]={Index=1; Name="TasteBronzeMetalMushroom"; DisplayName="Taste the Bronze Metal Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Bronze Metal Mushroom"; Complete=false},
			[2]={Index=2; Name="TasteGoldyMushroom"; DisplayName="Taste the Goldy Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Goldy Mushroom"; Complete=false},
			[3]={Index=3; Name="TasteTummyMushroom"; DisplayName="Taste the Tummy Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Tummy Mushroom"; Complete=false},
			[4]={Index=4; Name="TasteReddyEddyMushroom"; DisplayName="Taste the Reddy Eddy Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Reddy Eddy Mushroom"; Complete=false},
			[5]={Index=5; Name="TasteSpottedJoeMushroom"; DisplayName="Taste the Spotted Joe Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Spotted Joe Mushroom"; Complete=false},
			[6]={Index=6; Name="TastePoltergeistMushroom"; DisplayName="Taste the Poltergeist Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Poltergeist Mushroom"; Complete=false},
			[7]={Index=7; Name="TasteCaptainMyCaptainMushroom"; DisplayName="Taste the Captain My Captain Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Captain My Captain Mushroom"; Complete=false},
			[8]={Index=8; Name="TasteTidalWaveMushroom"; DisplayName="Taste the Tidal Wave Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Tidal Wave Mushroom"; Complete=false},
			[9]={Index=9; Name="TasteSwitchBladeMushroom"; DisplayName="Taste the Switch Blade Mushroom"; Type=QuestStepTypes.Action; Action="EatMushroom"; Object="Switch Blade Mushroom"; Complete=false},
			
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Figure out which mushrooms are edible by tasting each one",
		Reward = {["Experience"]=200;["Money"]=20;["Item"]="GoldyMushroomSoup"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "I am going to study the forest mushrooms.  I need you to first figure out which are edible by tasting each one directly BEFORE picking.",
			Option1Text = "Are any poisonous?",
			Option1Link = "QuestDialog5",
			Option2Text = "I'm busy",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		QuestDialog5 = {
			NPCText = "You tell me",
			Option1Text = "Ok I'll give it a try",
			Option1Link = "GiveQuest_TheSporeYouKnow",
			Option2Text = "I rather not die thank you.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Very interesting.  I've been making Switch Blade soup all this time, but I thought it was just spicy.  Here is your reward.",
			Option1Text = "Thanks.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Did you taste all the mushrooms yet",
			Option1Text = "Yes and I feel sick to my stomach",
			Option1Link = "GetReward_TheSporeYouKnow",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you taste all the mushrooms yet",
			Option1Text = "Nope not yet",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
	["LostDog"] = {
		Name = "LostDog",
		DisplayName = "Lost Dog",
		QuestGiver = "ParkRangerSpruce",
		DependentQuest="",
		AvailableLevel = 5,
		Drawing="Skull",
		Steps = {
			[1]={Index=1; Name="GetEvidence"; DisplayName="Get evidence of Ranger Spruce's missing dog"; Type=QuestStepTypes.Get; Object="TennisBall"; CurrentAmount=0; AmountNeeded=1; Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find evidence of what may have happened to Ranger Spruce's missing dog",
		Reward = {["Experience"]=200;["Item"]="DogCollar"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "My dog Cooper was playing fetch. I threw it far off the cliff. He went after it and never came back. I am worried that Wolf Walker might have gotten him. Can you find him for me?",
			Option1Text = "Sure I'll find your dog",
			Option1Link = "GiveQuest_LostDog",
			Option2Text = "I don't have time to look for a lost pet.",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "It seems he wagged his last tail. So sad.  thanks for looking into it. Here take this. I have no use for it now.",
			Option1Text = "Thanks.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Did you find Cooper?",
			Option1Text = "Well I found his tennis ball at the bottom of The Pit",
			Option1Link = "GetReward_LostDog",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you find Cooper?",
			Option1Text = "Nope not yet",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
	["Lookout"] = {
		Name = "Lookout",
		DisplayName = "Lookout",
		QuestGiver = "ParkRangerSpruce",
		DependentQuest="LostDog",
		AvailableLevel = 5,
		Drawing="Skull",
		TempItem="BorrowedBinoculars",
		Steps = {
			[1]={Index=1; Sequential=false; Name="SpotWerewolf"; DisplayName="SpotWerewolf"; Type=QuestStepTypes.Binoculars; Object="Werewolf"; Complete=false}
		},
		Complete = false, --All Steps are complete AND quest has been rewarded / npc is done with dialog for this quest
		Desc = "Find evidence of a werewolf at night",
		Reward = {["Experience"]=200;["Item"]="Binoculars"},
		Picture = 137510460,
		Frequency = "Once", --Once,Daily,Anytime
		Tracked = true,
		QuestDialog4 = {
			NPCText = "Nurse Hadley reported some campers injured from an attack last night in what they called a werewolf. Use my binoculars up in the tower to find evidence of this werewolf at night.",
			Option1Text = "I'll look for it",
			Option1Link = "GiveQuest_Lookout",
			Option2Text = "Sounds too scary for me",
			Option2Link = "Close",
			Option3Text = "",
			Option3Link = "",
		};
		RewardDialog = {
			NPCText = "Wow I didn't believe it, but I trust you kid. Here as a reward you can have my binoculars",
			Option1Text = "Thanks.",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
		};
		QuestCompleteDialog = {
			NPCText = "Did you spot the Werewolf?",
			Option1Text = "Yes I saw some hairy wolf like creature roaming the woods below.",
			Option1Link = "GetReward_Lookout",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		};
		QuestNotCompleteDialog = {
			NPCText = "Did you spot the Werewolf?",
			Option1Text = "Nope just a bunch of trees",
			Option1Link = "Close",
			Option2Text = "",
			Option2Link = "",
			Option3Text = "",
			Option3Link = "",
		}
	};
	
}
return quests
