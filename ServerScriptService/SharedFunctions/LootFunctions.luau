local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local containerModule = require(game.ServerScriptService:WaitForChild("SharedModules"):WaitForChild("Container")) 
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local AchievementFunctions = require(ServerScriptService.Data.DataAchievementFunctions)

local lootFunctions = {}

local R = Random.new(os.time())

local lootByTypeByLevel = {}

function lootFunctions.BuildLootTables()
	for _,v in pairs() do

	end
end

local function GetRandomItem(weightedItems)
	local sum = 0
	for _,v in pairs(weightedItems) do
		sum = sum + v.RarityPercentage
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(weightedItems) do
		rand = rand - v.RarityPercentage
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

function lootFunctions.GetLootFromLootTable(player,lootTable)
	local loot = GetRandomItem(lootTable)

	if (loot) then
		InventoryFunctions.AddItem(player,loot.Name)
	end


end

function lootFunctions.GetFilteredEnemyLootItem(enemyName,typeWhiteList,typeBlackList,itemBlackList)
	--1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss

	--Rarity     	RarityPercentage/weight
	-- 0 trash   	100		any enemy
	-- 1 common		80		any enemy
	-- 2 uncommon	50		any enemy
	-- 3 rare		1		elite
	-- 4 epic		.03		miniboss
	-- 5 legendary	.01		boss

	--["Weapon"]="rbxassetid://15294372438",--"rbxassetid://10117941467",
	--["OffHand"]="rbxassetid://15294372438",--"rbxassetid://10117941467",
	--["Ammo"]="rbxassetid://15294372438",--"rbxassetid://10117941467",
	--["Tool"]="rbxassetid://13922101662", --rbxassetid://13921826727",      --"rbxassetid://10129630450",
	--["Clothing"]="rbxassetid://15294347699", --rbxassetid://13841773623", --rbxassetid://10272956695",
	--["Misc"]="rbxassetid://10272959685",
	--["PowerSource"]="rbxassetid://10272959685",
	--["Disk"]="rbxassetid://10272959685",
	--["Heal"]="rbxassetid://10272959685",
	--["Trash"]="rbxassetid://10272959685",
	--["Consumable"]="rbxassetid://10272960057",
	--["Material"]="rbxassetid://10272960057",

	if (enemiesModule[enemyName] == nil) then
		warn("lootFunctions.GetFilteredEnemyLootItem enemy:"..enemyName.." not found in enemies list")
		return
	end

	return lootFunctions.GetFilteredLootItem2(enemiesModule[enemyName].Level-2,enemiesModule[enemyName].Level+2,enemiesModule[enemyName].Rank,nil,typeWhiteList,enemiesModule[enemyName].Loot,typeBlackList,itemBlackList)

end

function lootFunctions.GetFilteredLootItem(minLevel,maxLevel,minRarity,maxRarity,typeWhiteList,specificLootItems,rarityPercentages,typeBlackList,itemBlackList)

	local filteredItemList = {}

	for name,v in pairs(itemsmodule) do

		--Logger.Debug("TEST LOOT a itemname: minLevel: maxLevel:minRarity:maxRarity:",v.Name, minLevel,maxLevel,minRarity,maxRarity)

		local isSpecificLoot = false
		local item = {}

		if (name == "ImageMap") then
			continue
		end

		if (itemBlackList ~= nil) then
			if table.find(itemBlackList, v.Name) then
				continue
			end
		end	

		if (v.LootType ~= "General") then
			if (v.LootType == "Specific") then
				if not table.find(specificLootItems, v.Name) then
					continue	
				else
					isSpecificLoot = true
				end
			end
		end

		if (not isSpecificLoot) then
			if (typeWhiteList ~= nil) then
				if not table.find(typeWhiteList, v.Type) then
					continue
				end
			end	

			if (typeBlackList ~= nil) then
				if table.find(typeBlackList, v.Type) then
					continue
				end
			end	
		end

		--ignore loot level if is specifically for this enemy or the loot has no level
		if (not isSpecificLoot or v.Level == 0) then
			if (v.Level < minLevel) then
				continue
			end

			if (v.Level > maxLevel) then
				continue
			end

		end
		if (not isSpecificLoot) then
			if (v.Rarity < minRarity) then
				continue
			end

			if (v.Rarity > maxRarity) then
				continue
			end

			if (v.Rarity > maxRarity) then
				continue
			end
		end

		item.name = name
		--Rarity
		-- 0 trash
		-- 1 common
		-- 2 uncommon
		-- 3 rare
		-- 4 epic
		-- 5 legendary
		if (v.Rarity == 0) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[1]
			else
				item.RarityPercentage = 100
			end

		elseif (v.Rarity == 1) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[2]
			else
				item.RarityPercentage = 80
			end
		elseif (v.Rarity == 2) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[3]
			else
				item.RarityPercentage = 50
			end
		elseif (v.Rarity == 3) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[4]
			else
				item.RarityPercentage = 1
			end
		elseif (v.Rarity == 4) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[5]
			else
				item.RarityPercentage = .03	
			end
		elseif (v.Rarity == 5) then
			if (rarityPercentages ~= nil) then
				item.RarityPercentage = rarityPercentages[6]
			else
				item.RarityPercentage = .01
			end
		end

		--make it 20% more likely to get a specific item
		if (isSpecificLoot) then
			item.RarityPercentage = item.RarityPercentage + (item.RarityPercentage*.2)
		end

		--Logger.Debug("DAILY REWARDS FOUND ITEM: name:"..item.name.." raritypercentage:"..item.RarityPercentage)
		table.insert(filteredItemList,item)
	end

	local randomItem = GetRandomItem(filteredItemList)

	if (randomItem ~= nil) then
		--Logger.Debug("DAILY REWARDS CHOSEN RANDOM ITEM: name:"..randomItem.name.." raritypercentage:"..randomItem.RarityPercentage)
		return randomItem.name
	else
		return nil
	end




end

-- Base Probabilities
local baseProbabilities = {
	[0] = 30.0,   -- Trash
	[1] = 50.0,   -- Common
	[2] = 15.0,   -- Uncommon
	[3] = 4.0,    -- Rare
	[4] = 0.9,    -- Epic
	[5] = 0.1     -- Legendary
}

local enemyRankMultipliers = {
	[1] = {       -- Grunt
		[0] = 1.0,    -- Trash (~30.0% chance)
		[1] = 1.0,    -- Common (~50.0% chance)
		[2] = 1.0,    -- Uncommon (~15.0% chance)
		[3] = 1.0,    -- Rare (~4.0% chance)
		[4] = 1.0,    -- Epic (~0.9% chance)
		[5] = 1.0     -- Legendary (~0.1% chance)
	},
	[2] = {       -- Experienced
		[0] = 0.2,    -- Trash (~7.84% chance)
		[1] = 0.8,    -- Common (~52.27% chance)
		[2] = 1.5,    -- Uncommon (~29.40% chance)
		[3] = 1.5,    -- Rare (~7.84% chance)
		[4] = 2.0,    -- Epic (~2.35% chance)
		[5] = 2.5     -- Legendary (~0.33% chance)
	},
	[3] = {       -- Elite
		[0] = 0.01,   -- Trash (~0.65% chance)
		[1] = 0.1,    -- Common (~10.78% chance)
		[2] = 2.0,    -- Uncommon (~64.66% chance)
		[3] = 2.0,    -- Rare (~17.24% chance)
		[4] = 3.0,    -- Epic (~5.82% chance)
		[5] = 4.0     -- Legendary (~0.86% chance)
	},
	[4] = {       -- Miniboss
		[0] = 0.01,   -- Trash (~0.56% chance)
		[1] = 0.05,   -- Common (~4.67% chance)
		[2] = 1.5,    -- Uncommon (~42.06% chance)
		[3] = 5.0,    -- Rare (~37.38% chance)
		[4] = 8.0,    -- Epic (~13.46% chance)
		[5] = 10.0    -- Legendary (~1.87% chance)
	},
	[5] = {       -- Boss
		[0] = 0.01,   -- Trash (~0.53% chance)
		[1] = 0.01,   -- Common (~0.88% chance)
		[2] = 0.5,    -- Uncommon (~13.20% chance)
		[3] = 8.0,    -- Rare (~56.34% chance)
		[4] = 15.0,   -- Epic (~23.77% chance)
		[5] = 30.0    -- Legendary (~5.28% chance)
	}
}

-- Function to get a random rarity based on enemy rank
function getRandomRarity(enemyRank)
	local adjustedProbabilities = {}
	local totalAdjustedProbability = 0

	-- Apply multipliers and calculate adjusted probabilities
	for rarity = 0, 5 do
		local baseProb = baseProbabilities[rarity]
		local multiplier = enemyRankMultipliers[enemyRank][rarity] or 1.0
		local adjustedProb = baseProb * multiplier
		adjustedProbabilities[rarity] = adjustedProb
		totalAdjustedProbability = totalAdjustedProbability + adjustedProb
	end

	-- Normalize probabilities
	for rarity, adjustedProb in pairs(adjustedProbabilities) do
		adjustedProbabilities[rarity] = (adjustedProb / totalAdjustedProbability) * 100
	end

	-- Generate a random number between 0 and 100
	local randomValue = math.random() * 100

	-- Determine the rarity
	local cumulativeProbability = 0
	for rarity = 0, 5 do
		local prob = adjustedProbabilities[rarity]
		cumulativeProbability = cumulativeProbability + prob
		if randomValue <= cumulativeProbability then
			return rarity
		end
	end

	-- Fallback (should not occur due to normalization)
	return 5  -- Return Legendary by default
end


function lootFunctions.TestRarityDrops(enemyLevel, numRuns)
	-- Initialize counters for each rarity
	local rarityCounts = {
		[0] = 0,  -- Trash
		[1] = 0,  -- Common
		[2] = 0,  -- Uncommon
		[3] = 0,  -- Rare
		[4] = 0,  -- Epic
		[5] = 0   -- Legendary
	}

	-- Run the simulation
	for i = 1, numRuns do
		local rarity = getRandomRarity(enemyLevel)
		rarityCounts[rarity] = rarityCounts[rarity] + 1
	end

	-- Calculate percentages
	local rarityPercentages = {}
	for rarity = 0, 5 do
		rarityPercentages[rarity] = (rarityCounts[rarity] / numRuns) * 100
	end

	-- Print the results
	local rarityNames = {
		[0] = "Trash",
		[1] = "Common",
		[2] = "Uncommon",
		[3] = "Rare",
		[4] = "Epic",
		[5] = "Legendary"
	}

	--Logger.Debug("Results after " .. numRuns .. " runs at enemy level " .. enemyLevel .. ":")
	for rarity = 0, 5 do
		local count = rarityCounts[rarity]
		local percentage = rarityPercentages[rarity]
		--Logger.Debug(string.format("%s: %d times (%.2f%%)", rarityNames[rarity], count, percentage))
	end
end

function getRandomListItem(items)
	-- Ensure the list is not empty
	if #items == 0 then
		return nil  -- or handle the empty list case as needed
	end

	-- Seed the random number generator (optional)
	math.randomseed(os.time())

	-- Generate a random index between 1 and the number of items
	local randomIndex = math.random(1, #items)

	-- Return the item at the random index
	return items[randomIndex]
end


--This will first just pick what rarity item you will get and then have a much higher percentage that you get the specificLootItems over general loot items
--then it will get an item using rest of filters if generic was chosen
function lootFunctions.GetFilteredLootItem2(minLevel,maxLevel,enemyRank,rarityOverride,typeWhiteList,specificLootItems,typeBlackList,itemBlackList,excludeItemPlayerAlreadyHas,player)

	--1 = grunt , 2 = experienced, 3 = elite, 4 = miniboss, 5 = boss

	--Rarity     	RarityPercentage/weight
	-- 0 trash   	100		any enemy
	-- 1 common		80		any enemy
	-- 2 uncommon	50		any enemy
	-- 3 rare		1		elite
	-- 4 epic		.03		miniboss
	-- 5 legendary	.01		boss

	local filteredItemList = {}

	math.randomseed(os.time())
	local chosenRarity = nil

	if (rarityOverride) then
		chosenRarity = rarityOverride
	else
		chosenRarity = getRandomRarity(enemyRank)
	end

	local useSpecificLoot = false

	if (specificLootItems) then
		useSpecificLoot = (math.random(1,100) > 20)
	end

	--TODO don't always prefer specficloot items , but make it like 75% of the time
	if (useSpecificLoot) then
		--Run throught the specific loot and pick the first one that is the rarity of the chosenRarity
		--If not found then get general loot
		for i,name in pairs(specificLootItems) do

			if (itemBlackList ~= nil) then
				if table.find(itemBlackList, name) then
					continue
				end
			end	

			local itemRarity = nil

			--Certain rare items looted are build items.
			if (name == "GardenGnome") then
				itemRarity = 3
			else
				itemRarity = itemsmodule[name].Rarity
			end

			if (itemRarity == chosenRarity) then
				return name
			end
		end

	end

	--If we got here then we did not find the right specific item so go get a general one.

	for name,v in pairs(itemsmodule) do

		local item = {}

		if (name == "ImageMap") then
			continue
		end

		if (itemBlackList ~= nil) then
			if table.find(itemBlackList, v.Name) then
				continue
			end
		end	

		if (v.LootType ~= "General") then
			continue
		end

		--Exclude liquid items
		if (v.NeedToContain and v.NeedToContain ~= "Solid") then
			continue
		end

		--excludeItemPlayerAlreadyHas
		if (player and excludeItemPlayerAlreadyHas and InventoryFunctions.HasItem(player,v.Name,1)) then
			continue
		end

		if (typeWhiteList ~= nil) then
			if ((not table.find(typeWhiteList, v.Type)) and (not table.find(typeWhiteList, v.SubType))) then
				continue
			end
		end	

		if (typeBlackList ~= nil) then
			if table.find(typeBlackList, v.Type) then
				continue
			end
		end	

		--ignore loot level if is specifically for this enemy or the loot has no level
		--if (v.Level == 0) then
		if (v.Level < minLevel) then
			continue
		end

		if (v.Level > maxLevel) then
			continue
		end

		--end

		if (v.Rarity ~= chosenRarity) then
			continue
		end

		item.name = name

		--Logger.Debug("DAILY REWARDS FOUND ITEM: name:"..item.name.." raritypercentage:"..item.RarityPercentage)
		table.insert(filteredItemList,item)
	end


	--At this point every item should be with level range and exact chosen Rarity so just be randomly between them all

	local randomItem =getRandomListItem(filteredItemList)

	if (randomItem ~= nil) then
		--Logger.Debug("DAILY REWARDS CHOSEN RANDOM ITEM: name:"..randomItem.name.." raritypercentage:"..randomItem.RarityPercentage)
		return randomItem.name
	else
		return nil
	end




end

function lootFunctions.GenerateCorpseLoot(player,enemyName,corpse)

	local lootItem1,lootItem2 = nil

	if (corpse ~= nil) then

		if (corpse.looters[player.Name].itemsGenerated == false) then

			corpse.looters[player.Name].itemsGenerated = true


			local typeWhiteList = {}

			--Humanoid
			--Animal
			--Insect
			--Machine
			--Plant


			if (enemiesModule[enemyName].Type == "Humanoid") then
				typeWhiteList = {"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal","Disk","Trash","Consumable","Material"}
			elseif (enemiesModule[enemyName].Type == "Animal") then
				typeWhiteList = {"Trash","Food","Material"}
			elseif (enemiesModule[enemyName].Type == "Insect") then
				typeWhiteList = {"Trash","Material"}
			elseif (enemiesModule[enemyName].Type == "Machine") then
				typeWhiteList = {"Disk"}
			elseif (enemiesModule[enemyName].Type == "Plant") then
				typeWhiteList = {}
			else
				typeWhiteList = {"Trash","Consumable","Material"}
			end


			lootItem1 = lootFunctions.GetFilteredEnemyLootItem(enemyName,typeWhiteList)	--GetRandomItem(enemiesModule[enemyName].Loot).Name

			lootItem2 = lootFunctions.GetFilteredEnemyLootItem(enemyName,typeWhiteList,{lootItem1},{lootItem1})

			if (lootItem1 == "Nothing") then
				lootItem1 = nil
			end

			if (lootItem2 == "Nothing") then
				lootItem2 = nil
			end

			corpse.looters[player.Name].item1 = lootItem1
			corpse.looters[player.Name].item2 = lootItem2		

		else

			return corpse.looters[player.Name].item1,corpse.looters[player.Name].item2

		end

	end

	return lootItem1,lootItem2
end

-- Returns true if the player with the given name has at least 10% of the total damage of all players in the looter table, false otherwise
function lootFunctions.CanGetLootFromCorpse(player,corpse)

	if (corpse ~= nil) then
		-- Calculate the total damage of all players in the looter table
		local totalDamage = 0
		for _, looter in pairs(corpse.looters) do
			totalDamage = totalDamage + looter.damage
		end

		-- Check if the player has at least 10% of the total damage
		if corpse.looters[player.Name] and corpse.looters[player.Name].damage / totalDamage >= 0.1 then
			return true
		else
			return false
		end
	end
end

function lootFunctions.TakeLootItemFromCorpse(player,enemyName,corpse, targetItem1,targetItem2)

	if (not lootFunctions.CanGetLootFromCorpse(player,corpse)) then
		return
	end

	if (corpse ~= nil) then
		local lootItem1 = corpse.looters[player.Name].item1
		local lootItem2 = corpse.looters[player.Name].item2

		if (targetItem1 ~= nil and lootItem1 == targetItem1) then

			if (lootItem1 ~= "Nothing") then

				if (itemsmodule[lootItem1].SubType == "Decor") then
					InventoryFunctions.AddBuildItem(player,lootItem1)
				else
					InventoryFunctions.AddItem(player,lootItem1)
				end
			end

			lootItem1 = nil
			corpse.looters[player.Name].item1 = nil

			if (not lootItem1 and not lootItem2) then
				corpse.looters[player.Name] = nil
			end

		end

		if (targetItem2 ~= nil and lootItem2 == targetItem2) then

			if (lootItem2 ~= "Nothing") then
				if (itemsmodule[lootItem2].SubType == "Decor") then
					InventoryFunctions.AddBuildItem(player,lootItem2)
				else
					InventoryFunctions.AddItem(player,lootItem2)
				end
			end

			lootItem2 = nil
			corpse.looters[player.Name].item2 = nil

			if (not lootItem1 and not lootItem2) then
				corpse.looters[player.Name] = nil
			end

		end

		return lootItem1,lootItem2
	else
		return nil,nil
	end

end

function lootFunctions.CanGetLootFromContainer(player,container)

	--TODO return false if the player has already gotten this (as shown in achievements)
	if (container.singleUse) then
		return not AchievementFunctions.IsAchievementStepComplete(player,"Treasures Found",container.id)
	end

	return true

end

function lootFunctions.TakeLootItemFromContainer(player,container, targetItem1,targetItem2)

	if (not lootFunctions.CanGetLootFromContainer(player,container)) then
		return
	end

	if (container ~= nil) then
		local lootItem1 = container.looters[player.Name].item1
		local lootItem2 = container.looters[player.Name].item2

		if (targetItem1 ~= nil and lootItem1 == targetItem1) then

			if (lootItem1 ~= "Nothing") then
				InventoryFunctions.AddItem(player,lootItem1)
			end

			lootItem1 = nil
			container.looters[player.Name].item1 = nil

			--if (not lootItem1 and not lootItem2) then
			--	corpse.looters[player.Name] = nil
			--end

		end

		if (targetItem2 ~= nil and lootItem2 == targetItem2) then

			if (lootItem2 ~= "Nothing") then
				InventoryFunctions.AddItem(player,lootItem2)
			end

			lootItem2 = nil
			container.looters[player.Name].item2 = nil

			--if (not lootItem1 and not lootItem2) then
			--	corpse.looters[player.Name] = nil
			--end

		end

		return lootItem1,lootItem2
	else
		return nil,nil
	end

end

function lootFunctions.GetLootFromContainer(player,containerRarity)
	local level = ProgressFunctions.GetLevel(player)
	return lootFunctions.GetFilteredLootItem2(level,level+5,nil,containerRarity,{"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal"})	
end



return lootFunctions
