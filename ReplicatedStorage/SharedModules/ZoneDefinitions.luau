local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspaceZones = workspace:WaitForChild("Zones")
local animations = ReplicatedStorage:WaitForChild("SharedAnimations")

return {
	-- Each entry: { Name, FolderReference }
	
	["InfiniteStairs1"]={ 
		Name = "InfiniteStairs1", 
		DisplayName="",
	},
	["Door1"]={ 
		Name = "Door1", 
		DisplayName="",  
		--ActivatedObject="Door1"
	},
	["PressurePlate1"]={ 
		Name = "PressurePlate1", 
		DisplayName="", 
		--TriggerObject = "InnerPlate1", 
		--ActivatedObject = "Door1" 
	},

	
	--["FarmClothesLine"]={ Name = "FarmClothesLine", DisplayName="", Folder = workspaceZones:WaitForChild("FarmClothesLine") },
	--["FarmChimney"]={ Name = "FarmChimney", DisplayName="", Folder = workspaceZones:WaitForChild("FarmChimney") },
	--["FarmCropCircle"]={ Name = "FarmCropCircle", DisplayName="", Folder = workspaceZones:WaitForChild("FarmCropCircle"),Effects = {["TimeDistortion"]={Condition=nil,Value=nil}} },
	--["Outhouse"]={ Name = "Outhouse", DisplayName="", Folder = workspaceZones:WaitForChild("Outhouse"), Effects = {["Stink"]={Condition=nil,Value=nil}}},
	--["Swimming"]={ Name = "Swimming",  DisplayName="", Folder = workspaceZones:WaitForChild("Swimming"), Effects = {["Wet"]={Condition=nil,Value=nil},["ElectricShock"]={Condition="HoldingItemWithTrait",Value="Electric"},["SpawnOldToothy"]={Condition="HasEffect",Value="Bleed"},["SpawnOldToothy2"]={Condition="HasEffect",Value="Hemorrhage"}} },
	
	--["GasStation"]={ Name = "GasStation", DisplayName="Gas Station", Folder = workspaceZones:WaitForChild("Gas Station"), Store = true, Sound = workspace.Zones["Gas Station"]:FindFirstChild("Sound"),
	--	Animation = workspace.QuestGivers.GasStationClerk.AnimationController:LoadAnimation(animations.HipHop1),
	--	AnimationSpeed = .5,
	--	NPC =  workspace.QuestGivers:WaitForChild("GasStationClerk"),
	--	NPCRightArmOriginalCFrame = workspace.QuestGivers:WaitForChild("GasStationClerk").PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:RightShoulder"]["mixamorig:RightArm"].CFrame,
	--	NPCLeftArmOriginalCFrame = workspace.QuestGivers:WaitForChild("GasStationClerk").PrimaryPart["mixamorig:Hips"]["mixamorig:Spine"]["mixamorig:Spine1"]["mixamorig:Spine2"]["mixamorig:LeftShoulder"]["mixamorig:LeftArm"].CFrame,
	--},
	
	--["CampWhisperingWoods"]={ Name = "CampWhisperingWoods", DisplayName="Camp Whispering Woods", MinLevel=1,MaxLevel=3, Folder = workspaceZones:WaitForChild("Camp Whispering Woods") },
	
	--["ChickenCoop"]={ Name = "ChickenCoop",  DisplayName="", Folder = workspaceZones:WaitForChild("Chicken Coop") },
	--["BeeHives"]={ Name = "BeeHives",  DisplayName="", Folder = workspaceZones:WaitForChild("BeeHives") },
	--["CowPasture"]={ Name = "CowPasture",  DisplayName="", Folder = workspaceZones:WaitForChild("Cow Pasture") },
	--["Toxic"]={ Name = "Toxic", DisplayName="", Folder = workspaceZones:WaitForChild("Toxic"),Effects = {["Biohazard"]={Condition=nil,Value=nil},["Kuato"]={Condition=nil,Value=nil}} },
	--["GasStationDelivery"]={ Name = "GasStationDelivery", DisplayName="", Folder = workspaceZones:WaitForChild("Gas Station Delivery"), Effects = {["Deliver"]={Condition="HoldingItemForDelivery",Value="FishDeliveryCrate"}} },
	--["MesshallDelivery"]={ Name = "MesshallDelivery", DisplayName="", Folder = workspaceZones:WaitForChild("Messhall Delivery"), Effects = {["Deliver"]={Condition="HoldingItemForDelivery",Value="GaterMadeDelivery"}} },
	--["CoconutDelivery"]={ Name = "CoconutDelivery", DisplayName="", Folder = workspaceZones:WaitForChild("CoconutDelivery"), Effects = {["Deliver"]={Condition="HoldingItemForDelivery",Value="CoconutDelivery"}} },
	--["Buoy"]={ Name = "Buoy", DisplayName="", Folder = workspaceZones:WaitForChild("Buoy") },
	--["GrumpyRoosterFarms"]={ Name = "GrumpyRoosterFarms", DisplayName="Grumpy Rooster Farms", MinLevel=3,MaxLevel=6, Folder = workspaceZones:WaitForChild("Grumpy Rooster Farms") },
	--["Slide"]={ Name = "Slide", DisplayName="", Folder = workspaceZones:WaitForChild("Slide") },
	--["LakeInWater"]={ Name = "LakeInWater", DisplayName="", Folder = workspaceZones:WaitForChild("LakeInWater") },
	--["LeviathanBunker"]={ Name = "LeviathanBunker", DisplayName="Leviathan Bunker", Folder = workspaceZones:WaitForChild("LeviathanBunker") },
	--["MessHallOffice"]={ Name = "MessHallOffice", DisplayName="", Folder = workspaceZones:WaitForChild("MessHallOffice") },
	--["PhoneBooth"]={ Name = "PhoneBooth", DisplayName="", Folder = workspaceZones:WaitForChild("PhoneBooth") },
	--["RedSpiderCave"]={ Name = "RedSpiderCave", DisplayName="", Folder = workspaceZones:WaitForChild("RedSpiderCave") },
	--["CampingStore"]={ Name = "CampingStore", DisplayName="Camping Store", Folder = workspaceZones:WaitForChild("CampingStore") },
	--["Campfire"]={ Name = "Campfire", DisplayName="", Folder = workspaceZones:WaitForChild("Campfire") },

	
	
	
	-- ✅ Add more zones here
}
