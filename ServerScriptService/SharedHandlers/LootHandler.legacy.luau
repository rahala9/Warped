
local ProximityPromptService = game:GetService("ProximityPromptService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LootFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").LootFunctions)
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local LootRemotes = SharedRemotes:WaitForChild("Loot")
local CanGetLootFromCorpseEvent = SharedRemotes:WaitForChild("CanGetLootFromCorpse")
local GetLootFunction = LootRemotes:WaitForChild("GetLoot")
local GetLootFromContainerFunction = LootRemotes:WaitForChild("GetLootFromContainer")
local TakeLootFunction = LootRemotes:WaitForChild("TakeLoot")
local TakeLootFromContainerFunction = LootRemotes:WaitForChild("TakeLootFromContainer")
local corpseModule = require(game.ServerScriptService:WaitForChild("SharedModules"):WaitForChild("Corpse")) 
local containerModule = require(game.ServerScriptService:WaitForChild("SharedModules"):WaitForChild("Container")) 
local dumpsterLootModule = require(game.ReplicatedStorage.Loot.DumpsterLoot)
local toiletLootModule = require(game.ReplicatedStorage.Loot.ToiletLoot) --TODO add ToiletLoot
local crateLootModule = require(game.ReplicatedStorage.Loot.CrateLoot)
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)

CanGetLootFromCorpseEvent.OnServerInvoke = function(player,CorpseID)
	local corpse = corpseModule.getCorpseById(CorpseID)
	return LootFunctions.CanGetLootFromCorpse(player,corpse)
end

function GetLootFunction.OnServerInvoke(player,enemyName,corpseID)
	
	local corpse = corpseModule.getCorpseById(corpseID)
	if (not LootFunctions.CanGetLootFromCorpse(player,corpse)) then
		return
	end
	
	local lootItem1,lootItem2 = LootFunctions.GenerateCorpseLoot(player,enemyName,corpse)
	
	return lootItem1,lootItem2
end

function TakeLootFunction.OnServerInvoke(player,enemyName,corpseID,targetItem1,targetItem2)
	
	local corpse = corpseModule.getCorpseById(corpseID)
	if (not LootFunctions.CanGetLootFromCorpse(player,corpse)) then
		return
	end
	
	local corpse = corpseModule.getCorpseById(corpseID)
	local lootItem1,lootItem2 = LootFunctions.TakeLootItemFromCorpse(player,enemyName,corpse,targetItem1,targetItem2)

	return lootItem1,lootItem2
	--end

end

function GetLootFromContainerFunction.OnServerInvoke(player,containerID)
	
	local container = containerModule.getContainerById(containerID)
	
	--Logger.Debug("LootHandler.GetLootFromContainerFunction containerID,container:",containerID,container)
	
	if (not LootFunctions.CanGetLootFromContainer(player,container)) then
		return
	end

	local lootItem1,lootItem2 = containerModule.generateContainerLoot(player,containerID)
	
	return lootItem1,lootItem2
end

function TakeLootFromContainerFunction.OnServerInvoke(player,containerID,targetItem1,targetItem2)

	local container = containerModule.getContainerById(containerID)
	if (not LootFunctions.CanGetLootFromContainer(player,container)) then
		return
	end

	local lootItem1,lootItem2 = LootFunctions.TakeLootItemFromContainer(player,container,targetItem1,targetItem2)
	
	return lootItem1,lootItem2
	--end

end
local debounce = false

local function HandleSearchDumpster(player)
	LootFunctions.GetLootFromLootTable(player,dumpsterLootModule)
end

local function HandlePlungeToilet(player,promptObject)
	--Required tool must be held in hand
	
	if (not InventoryFunctions.HasRequiredTool(player, promptObject)) then
		return
	end	
	
	LootFunctions.GetLootFromLootTable(player,toiletLootModule)
end

local function HandleSearchCrate(player)
	LootFunctions.GetLootFromLootTable(player,crateLootModule)
end

local function onPromptTriggered(promptObject, player)

	
	if debounce == false then
		debounce = true
		
		promptObject.Enabled = false
		
		if (promptObject.Name == "SearchDumpster") then
			HandleSearchDumpster(player)
		elseif (promptObject.Name == "PlungeToilet") then
			HandlePlungeToilet(player,promptObject)
		elseif (promptObject.Name == "SearchCrate") then
			HandleSearchCrate(player)
		end
		
		promptObject.Enabled = true
		debounce = false
	end
end


ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)