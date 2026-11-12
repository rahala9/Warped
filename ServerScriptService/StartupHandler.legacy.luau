local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local CharacterFunctions = require(ServerScriptService.Data.DataCharacterFunctions)
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local enemiesModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
--local buildItemsModule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("BuildItems")) 
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
--local GamepassFunctions = require(ServerScriptService.Data.DataGamePassFunctions)
--local SubscriptionFunctions = require(ServerScriptService.Data.DataSubscriptionFunctions)
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)
local Quests = require(ServerScriptService.Data.Templates.Quests)
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local enemiesmodule = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local CollectionFunctions = require(ServerScriptService.Data.DataCollectionFunctions)
--local LootFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").LootFunctions)
local containerFunctions = require(ServerScriptService:WaitForChild("SharedModules"):WaitForChild("Container"))
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local CharacterGenerator = require(ServerScriptService.SharedServices.CharacterGenerator.CharacterGenerator)
local SkillCheckFunctions = require(ReplicatedStorage.SharedFunctions.SkillCheckFunctions)
local EquipmentFunctions = require(ReplicatedStorage.SharedFunctions.EquipmentFunctions)

local PowerService = require(ServerScriptService.SharedServices.PowerService)



local EnemySpawnerManager = require(ServerScriptService.SharedServices.EnemySpawningManager)
local manager = EnemySpawnerManager.GetInstance()

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		CharacterFunctions.SetCharacter(player)	
		

		--EquipmentFunctions.equip(player, character, "Back", "SkyBoundPro")

		
	end)
end)

local function placeCharacter(character: Model, targetCFrame: CFrame)
	
	character:PivotTo(targetCFrame)
	-- stop leftover physics from flinging you
	for _, p in ipairs(character:GetDescendants()) do
		if p:IsA("BasePart") then
			p.AssemblyLinearVelocity = Vector3.zero
			p.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

function Teleport(player,freeze, destination)


	local character = player.Character
	local humanoid = character.Humanoid

	-- Freeze character during teleport if requested
	if freeze then
		humanoid:SetAttribute("DefaultWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("DefaultJumpPower", humanoid.JumpPower)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Calculate height of root part from character base
	local rootPartY
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.HipHeight
	else
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.Parent.LeftLeg.Size.Y + humanoid.HipHeight
	end

	-- Teleport player and request content around location if applicable
	local position = CFrame.new(destination + Vector3.new(0, rootPartY, 0))
	--local orientation = CFrame.Angles(0, math.rad(params.faceAngle), 0)

	character:SetPrimaryPartCFrame(position) -- * orientation)

	-- Unfreeze character
	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

local function GenerateCharacter(player)
	local playerAlloc = {
		Strength = 2,
		Intelligence = 2,
		Charisma = 1, -- total 5
	}

	local seed = Random.new():NextInteger(1, 2^31-1)
	local profile = CharacterGenerator.Generate(seed, player.Name, playerAlloc, { debug = true })

	print("=== Sci-Co Data Profile ===")
	print("Name:", profile.Backstory.DataProfile.Name)
	print("Age:", profile.Backstory.DataProfile.Age)
	print("Home Planet:", profile.Backstory.DataProfile.HomePlanet)
	print("Assigned To:", profile.Backstory.DataProfile.AssignedTo)
	print("Corporate Liability Risk:", profile.Backstory.DataProfile.CorporateLiabilityRisk)
	print("")

	print("=== Narrative ===")
	print(profile.Backstory.Narrative)
	print("")

	--print("=== GENERATED CHARACTER ===")
	--print(profile.Backstory.Title)

	--for _, line in ipairs(profile.Backstory.Lines) do
	--	print(line)
	--end

	--print("--- Stats ---")
	--for _, s in ipairs({ "Strength", "Intelligence", "Wisdom", "Charisma", "Perception", "Vitality" }) do
	--	print(s, profile.Stats[s])
	--end

	print("--- Ranked ---")
	for i, entry in ipairs(profile.RankedStats) do
		print(i, entry.stat, entry.value)
	end
	
	print("=== Starting Items ===")
	print("From Home Planet:", profile.StartingItems.Planet)
	print("From Assignment:", profile.StartingItems.Department)
	print("From Quirk:", profile.StartingItems.Quirk)

	--print("--- Corporate Liability Risk ---", profile.Backstory.CorporateLiabilityRisk)
	--print("--- Stats Summary ---", profile.Backstory.StatsSummary)
end

local function Load(player)
	
	--player:LoadCharacter()

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	-- Place character exactly where you want
	local spawnPart = workspace:WaitForChild("StarhopStationSpawn") --workspace:WaitForChild("TutorialSpawn") --
	task.wait(4)
	--placeCharacter(character, spawnPart.CFrame * CFrame.new(0, 20, 0))
	Teleport(player,true, Vector3.new(spawnPart.Position.X, spawnPart.Position.Y + 5, spawnPart.Position.Z))
	
	--Are we coming from the character designer?
	local joinData = player:GetJoinData()
	if ((joinData.TeleportData ~= nil) and (joinData.TeleportData["gender"] ~= nil)) then

		CharacterFunctions.SetupNewCharacter(player)

		CharacterFunctions.SetCharacter(player)	

		AttributesFunctions.SetAttributes(player)

	else

		CharacterFunctions.SetCharacter(player)	

		AttributesFunctions.SetAttributes(player)
	end

	local offhand = InventoryFunctions.GetOffHandItem(player)

	if (offhand) then
		ToolFunctions.AddToolToLeftHand(player,offhand.Name)
	end
	
	GenerateCharacter(player)

end

local R = Random.new()

local function getRandomItem(weightedItems)

	local sum = 0
	for _,v in pairs(weightedItems) do
		if (v.Rarity == nil) then
			continue
		end

		sum = sum + v.Rarity
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(weightedItems) do
		if (v.Rarity == nil) then
			continue
		end

		rand = rand - v.Rarity
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

--function AddAllBuildItems(player)
--	for buildItemName,buildItem in pairs(buildItemsModule) do
--		Logger.Debug("TEST CAMP buildItem.Name:"..buildItemName)

--		if (buildItemName ~= "ImageMap") then
--			InventoryFunctions.AddBuildItem(player,buildItemName)
--		end

--	end

--end

function AddAllItemsOfType(player,itemType)
	for itemName,item in pairs(itemsmodule) do


		if (item.Type ~= nil and item.Type == itemType) then
			InventoryFunctions.AddItem(player,itemName)
		end

	end

end

function CalculateDamageFromEnemy(enemy,attack)
	--emeny damage is just melee or instant right now
	local DamageMin = 0
	local DamageMax = 0
	local Rank = enemy.Rank
	local Strength = enemy.Level + (enemy.Rank-1) --MAY BE TOO STRONG
	local Level = enemy.Level


	--TODO PERFORMANCE: Change all of these to a table lookup for PERFORMANCE

	local healthVSWeaponDamageModifier = .01
	local rarityLevelDamageModifier = .048
	local mobHealth = math.round(math.pow(Level/.4,2+(Level/50)) )
	local weaponRarityDamagePercentModifier = rarityLevelDamageModifier*(Rank*Rank*Rank*Rank)
	local weaponDamageBase = math.ceil(mobHealth*healthVSWeaponDamageModifier)
	local weaponDamageMax = math.round((weaponDamageBase+ (weaponDamageBase*weaponRarityDamagePercentModifier))) -- removing the max possible strength or perception bonus
	local weaponDamageMin = math.round((weaponDamageBase+ (weaponDamageBase*weaponRarityDamagePercentModifier))*.8) -- removing the max possible strength or perception bonus

	local mobDamageReductionModifier = .70

	if (attack and attack.AttackDamageMin.Type == "*") then
		DamageMin = math.round(weaponDamageMin*attack.AttackDamageMin.Amount)
	elseif(attack and attack.AttackDamageMin.Type == "+WeaponLevel*") then
		DamageMin = math.round(weaponDamageMin + Level * attack.AttackDamageMin.Amount)
	else
		DamageMin = weaponDamageMin
	end

	if (attack and attack.AttackDamageMax.Type == "*") then
		DamageMax = math.round(weaponDamageMax*attack.AttackDamageMax.Amount)
	elseif(attack and attack.AttackDamageMax.Type == "+WeaponLevel*") then
		DamageMax = math.round(weaponDamageMax + Level * attack.AttackDamageMax.Amount)
	else
		DamageMax = weaponDamageMax
	end	

	--Handle strength
	DamageMin = math.round(DamageMin +  ((Strength*Level)*mobDamageReductionModifier))
	DamageMax = math.round(DamageMax +  ((Strength*Level)*mobDamageReductionModifier))



	local finalDamage = math.random(DamageMin, DamageMax)

	--Logger.Debug("ENEMY FINAL DAMAGE:"..finalDamage.." Min:"..DamageMin.." Max:"..DamageMax)

	return finalDamage

end

local function AddTestItems(player)
	--GamepassFunctions.AddGamePass(player,116665270453832)
	--AddAllBuildItems(player)
	--QuestFunctions.AddQuest(player,Quests["FetchMeABone"])
	--QuestFunctions.AddQuest(player,Quests["CoolerHeads"])
	--QuestFunctions.AddQuest(player,Quests["RatsRock"])
	--QuestFunctions.AddQuest(player,Quests["ToxicAvenging"])
	--QuestFunctions.AddQuest(player,Quests["MixedFeelings"])
	--QuestFunctions.AddQuest(player,Quests["GophersOrGolfers"])
	--QuestFunctions.AddQuest(player,Quests["Lookout"])


	--InventoryFunctions.AddItem(player,"Spraypaint")
	InventoryFunctions.AddItem(player,"Camera",1)
	InventoryFunctions.AddItem(player,"Rocket",1)
	InventoryFunctions.AddItem(player,"StolenDisk",1)
	InventoryFunctions.AddItem(player,"EmpireLunchbox",1)
	InventoryFunctions.AddItem(player,"ProbabilityManipulator",1)
	InventoryFunctions.AddItem(player,"Flashlight",1)
	InventoryFunctions.AddItem(player,"Flashlight80s",1)
	InventoryFunctions.AddItem(player,"PocketUniverse",1)
	InventoryFunctions.AddItem(player,"InventoryImplant",1)
	InventoryFunctions.AddItem(player,"JetBox",1)
	InventoryFunctions.AddItem(player,"HopperJ7",1)
	InventoryFunctions.AddItem(player,"SkyBoundPro",1)
	InventoryFunctions.AddItem(player,"FalconX",1)
	InventoryFunctions.AddItem(player,"VulcanVac",1)
	InventoryFunctions.AddItem(player,"CyberSkull",1)
	InventoryFunctions.AddItem(player,"Cheese",1)
	InventoryFunctions.AddItem(player,"Winkie",1)
	InventoryFunctions.AddItem(player,"ZapColaCan",1)
	InventoryFunctions.AddItem(player,"SciColaCan",1)
	InventoryFunctions.AddItem(player,"PlumberId",1)
	InventoryFunctions.AddItem(player,"AccessCard",1)
	InventoryFunctions.AddItem(player,"MedKit",1)
	InventoryFunctions.AddItem(player,"DuctTape",1)
	
	

	
	InventoryFunctions.AddMoney(player,1000)


	--InventoryFunctions.AddItem(player,"AlienMask")
	--InventoryFunctions.AddItem(player,"GhostDetector")
	--tools

	InventoryFunctions.AddItem(player,"NerdGun")
	InventoryFunctions.AddItem(player,"SciCoP92")
	InventoryFunctions.AddItem(player,"SciCo00Zero")

end

ProfileLoadedEvent.Event:Connect(function(player)
	Load(player)

	if (not ProgressFunctions.GetStarted(player)) then 

		Logger.Debug("SETTING UP NEW PLAYER ITEMS")

		InventoryFunctions.AddItem(player,"Fists")



		--REMOVE> NOT PART OF DEFAULT STARTUP
		if game:GetService("RunService"):IsStudio() then
			AddTestItems(player)
		end

		---------------REMOVE------------------


		--local level = 1

		--ProgressFunctions.SetLevel(player,level)
		--AttributeFunctions.SetStrength(player,2)
		--AttributeFunctions.SetPerception(player,3)
		--AttributeFunctions.SetIntelligence(player,2)
		--AttributeFunctions.SetWisdom(player,1)
		--AttributeFunctions.SetCharisma(player,1)
		--AttributeFunctions.SetCrafting(player,1)


		--InventoryFunctions.AddItemToSuitcase(player,"Canteen",1)
		--InventoryFunctions.AddItemToSuitcase(player,"MomNote",2)
		--InventoryFunctions.AddItemToSuitcase(player,"Matches",3)
		--InventoryFunctions.AddItemToSuitcase(player,"5Dollar",4)

		--QuestFunctions.AddQuest(player,Quests["BePrepared"])
		ProgressFunctions.SetStarted(player)

	end









	--TODO remove
	InventoryFunctions.AddItem(player,"PowerCell",5)
	InventoryFunctions.AddItem(player,"Dart",20)
	InventoryFunctions.AddItem(player,"Laser",100)
	--InventoryFunctions.AddItem(player,"Firework",1)
	InventoryFunctions.AddItem(player,"PizzaSlice",1)
	
	--QuestFunctions.RestartQuest(player,Quests.SteakOut)
	
	AttributesFunctions.SetBrains(player,5)
	
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.Hacking.name,3)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.Engineering.name,1)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.PowerEngineering.name,1)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.MechanicalEngineering.name,2)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.WeaponEngineering.name,4)
	
	AttributesFunctions.SetGrit(player,10)
	AttributesFunctions.SetFinesse(player,8)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.Combat.name,1)
	AttributesFunctions.SetSkill(player,SkillCheckFunctions.Skills.LaserPistolCombat.name,1)

	
	ProgressFunctions.SendProgress(player)
	
	manager:RegisterAllSpawners()

	--LootFunctions.TestRarityDrops(5, 100000)

	-------BELOW IS ALL TEST ABOVE IS ALL NEEDED

	--StatsFrame:WaitForChild("StrengthValue").Text = "2"
	--StatsFrame:WaitForChild("PerceptionValue").Text = "3"
	--StatsFrame:WaitForChild("IntelligenceValue").Text = "2"
	--StatsFrame:WaitForChild("WisdomValue").Text = "1"
	--StatsFrame:WaitForChild("CharismaValue").Text = "1"
	--StatsFrame:WaitForChild("CraftingValue").Text = "1"






	--TODO REMOVE

	----loop for 50 rounds
	--for currentLevel = 1,50 do
	--	--local vitality = 1
	--	--local health = math.round(math.pow(currentLevel/.4,2+(currentLevel/50)+(vitality/25)))
	--	--local xpToLevel = math.round(math.pow(currentLevel/.4,2+(currentLevel/50)) + 50 )
	--	--Logger.Debug("TEST STATS: level:"..currentLevel.." MAXHEALTH:"..health.. " XP TO LEVEL:"..xpToLevel)
	--	local damage = CalculateDamageFromEnemy(enemiesmodule["ToxicRat"],nil)
	--	Logger.Debug("TEST ENEMY DAMAGE :",damage)
	--end
	--for currentLevel = 1,50 do
	--	local xpToLevel = math.round(math.pow(currentLevel/.4,2+(currentLevel/50)) + 50 )
	--	--local xpForAtLevelGrunt = math.round(xpToLevel/50)
	--	--local xpForAtLevelExperienced = xpForAtLevelGrunt*2
	--	--local xpForAtLevelElite = xpForAtLevelExperienced*2 
	--	--local xpForAtLevelMiniBoss = xpForAtLevelElite*2 
	--	--local xpForAtLevelBoss = xpForAtLevelMiniBoss*2 
	--	--Logger.Debug("TEST STATS XP FOR RANK: level:"..currentLevel.." 1:"..xpForAtLevelGrunt.." 2:"..xpForAtLevelExperienced.." 3:"..xpForAtLevelElite.." 4:"..xpForAtLevelMiniBoss.." 5:"..xpForAtLevelBoss)

	--	local baseXP = math.round(xpToLevel/50)
	--	local xpForAtLevelGrunt = baseXP *math.pow(2,1-1)
	--	local xpForAtLevelExperienced = baseXP *math.pow(2,2-1)
	--	local xpForAtLevelElite = baseXP *math.pow(2,3-1)
	--	local xpForAtLevelMiniBoss = baseXP *math.pow(2,4-1)
	--	local xpForAtLevelBoss = baseXP *math.pow(2,5-1)
	--	Logger.Debug("TEST STATS XP FOR RANK: level:"..currentLevel.." 1:"..xpForAtLevelGrunt.." 2:"..xpForAtLevelExperienced.." 3:"..xpForAtLevelElite.." 4:"..xpForAtLevelMiniBoss.." 5:"..xpForAtLevelBoss)


	--end



	--InventoryFunctions.UpdateItem(player,"Hairspray")

	--Items here will happen only once in the very start of this character




	--max base damage of common equal to mob level weapon
	--(average mob health at that level * .10)*(.048*(rarityLevel*rarityLevel*rarityLevel))  - (level*level)
	--level 10 mob health 1190 * .10 = 119*(.048*(rarityLevel*rarityLevel*rarityLevel)) - 100 = 19 (at best killing unarmored mob after 10 hits with level 10 common weapon)
	-- common 1, uncommon 2, rare, 3, epic 4, legendary 5 
	--so 19 max damage with level 10 common 1%  rarity level 0   (10 hits)
	-- 20 max damage with level 10 uncommon 4% rarity level 1   (10 hits)
	-- 26 max damage with level 10 rare 20% 38% rarity level 2    (5 hits)
	-- 43 max damage with level 10 epic 30% 130%   rarity level 3 (3 hits)
	-- 57 max damage with level 10 legendary 300% rarity level 4  (2 hits)

	--local mobHealth = 1190
	--local level = 10

	local healthVSWeaponDamageModifier = .05
	local rarityLevelDamageModifier = .048

	local playerVitalityAttribute = 5

	--for level = 1, 50 do
	--	--	gruntHealth = math.round(math.pow(i/.4,2+(i/50)) )
	--	--	print(i.." "..gruntHealth)
	--	--	--print(i.." "..math.round(math.pow(i/.3,1.8) ))

	--	local mobHealth = math.round(math.pow(level/.4,2+(level/50)) )
	--	local playerHealth = math.round(math.pow(level/.4,2+(level/50) ) ) + 100

	--	local playerVitalityAttribute1 = math.round(playerHealth + ( (.1 * playerHealth)*1 ) )
	--	playerHealth = math.round(playerHealth + ( (.1 * playerHealth)*playerVitalityAttribute ) )

	--	for rarityLevel = 0, 4 do
	--		local weaponRarityDamagePercentModifier = rarityLevelDamageModifier*(rarityLevel*rarityLevel*rarityLevel*rarityLevel)
	--		local weaponDamageBase = math.ceil(mobHealth*healthVSWeaponDamageModifier)
	--		local weaponDamageMax = math.round((weaponDamageBase+ (weaponDamageBase*weaponRarityDamagePercentModifier))) -- removing the max possible strength or perception bonus

	--		local fullMaxDamageWithMaxAtributePerLevelBonus = weaponDamageMax + (level*level)
	--		local numHits = math.ceil(mobHealth/fullMaxDamageWithMaxAtributePerLevelBonus)

	--		Logger.Debug("Level:"..level.." Player Health:"..playerHealth.. " playerHealthWithAttribute1:"..playerVitalityAttribute1)

	--		--Logger.Debug("Level:"..level.." MobHealth:"..mobHealth.." RarityLevel:"..rarityLevel.." WeaponRarityDamagePercentModifier:"..weaponRarityDamagePercentModifier.." WeaponDamageMax:"..weaponDamageMax.." FullMaxDamageWithMaxAtributePerLevelBonus:"..fullMaxDamageWithMaxAtributePerLevelBonus.." NumHits:"..numHits)
	--	end
	--end


	--local loot = ""
	--local numNumchucks = 0

	--for lootNumber = 1, 1000 do
	--	loot = getRandomItem(enemiesModule["Bully"].Loot)
	--	if (loot ~= nil) then
	--		Logger.Debug("Loot #"..lootNumber.." = "..loot.Name)

	--		if (loot.Name == "Numchucks") then
	--			numNumchucks = numNumchucks + 1
	--		end
	--	else
	--		Logger.Debug("Loot #"..lootNumber.." = NOTHING")
	--	end

	--end


	--StatesFunctions.SetCurrentTool(player,"Trashbag")
	--ToolFunctions.AddToolToRightHand(player,"Trashbag")
	--CurrentHeldToolChangedEvent:FireClient(player,"Trashbag")

end) 

PowerService.Init()

--Server Setup Stuff
--containerFunctions.newContainer(containerFunctions.containerTypes.Suitcase,containerFunctions.LockLevels.Unlocked,containerFunctions.Rarity.Common,Vector3.new(341.842, 2.444, -3620.642),Vector3.new(0, 180, 0),true)

--containerFunctions.newContainer(containerFunctions.containerTypes.Box,containerFunctions.LockLevels.Unlocked,containerFunctions.Rarity.Common,Vector3.new(348, 4, -3620.642),Vector3.new(0, 180, 0),false)




--local Players = game:GetService("Players")

-- Function to handle the touch event
--local function onTouched(hit, player)
--	Logger.Debug("TEST PLAYER COLLISION:"..player.Name .. "'s HumanoidRootPart touched: " .. hit.Name)
--	-- You can add more logic here to handle the collision
--end

--local function onStateChanged(humanoid, oldState, newState)
--	print(humanoid.Parent.Name .. "'s Humanoid state changed from " .. tostring(oldState) .. " to " .. tostring(newState))
--	-- You can add more logic here to handle specific state changes
--end

-- Function to set up the character
--local function setupCharacter(character, humanoid, player)
--	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
--	humanoidRootPart.Touched:Connect(function(hit)
--		onTouched(hit, player)
--	end)

--	humanoid.StateChanged:Connect(function(oldState, newState)
--		onStateChanged(humanoid, oldState, newState)
--	end)
--end

---- Connect setupCharacter function to CharacterAdded event for each player
--Players.PlayerAdded:Connect(function(player)
--	player.CharacterAdded:Connect(function(character)
--		local humanoid = character:WaitForChild("Humanoid")
--		setupCharacter(character, humanoid, player)
--	end)
--end)