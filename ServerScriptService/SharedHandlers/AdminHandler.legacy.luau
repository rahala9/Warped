local replicatedStorage = game:GetService("ReplicatedStorage")
local adminEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Admin")
local ServerScriptService = game:GetService("ServerScriptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
--local LootFunctions = require(ServerScriptService:WaitForChild("SharedFunctions").LootFunctions)
local Players = game:GetService("Players")
--local WorldEventFunctions = require(ServerScriptService.SharedFunctions.WorldEventFunctions)
--local WaterChangeEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("WaterChange")

local function teleportPlayerToPlayer(playerA, playerB)
	if playerA and playerB and playerA.Character and playerB.Character then
		local rootA = playerA.Character:FindFirstChild("HumanoidRootPart")
		local rootB = playerB.Character:FindFirstChild("HumanoidRootPart")

		if rootA and rootB then
			rootA.CFrame = rootB.CFrame + Vector3.new(0, 3, 0) -- teleport slightly above to avoid overlap
		end
	end
end

local function teleportPlayerToLocation(playerA, location)
	if playerA and playerA.Character then
		local rootA = playerA.Character:FindFirstChild("HumanoidRootPart")

		if rootA then
			rootA.CFrame = CFrame.new(location)
		end
	end
end

adminEvent.OnServerEvent:Connect(function(player,action,arg,arg2)
	
	--TODO SECURITY Remove Player1 and check UserId instead
	print("TEST ADMIN player.UserId:",player.UserId," action:",action)
	if (player.UserId == 1490918058 or player.Name == "LittleSharkyZ" or player.Name == "Player1") then
		if (action == "AddEffect") then
			EffectsFunctions.AddEffect(player,arg,1)
		elseif (action == "AddXP") then
			ProgressFunctions.AddXP(player,tonumber(arg))
		elseif (action == "AddItem") then
			InventoryFunctions.AddItem(player,arg,arg2)
		elseif (action == "KickPlayer") then
			local targetPlayer = Players:FindFirstChild(arg)
			
			if targetPlayer then
				targetPlayer:Kick(arg2)
			end
			
		elseif (action == "TeleportToPlayer") then
			
			local targetPlayer = Players:FindFirstChild(arg)
			if targetPlayer then
				teleportPlayerToPlayer(player, targetPlayer)
			end
		elseif (action == "TeleportToLocation") then
			--WaterChangeEvent:FireClient(player,"WaterRemoved")
			teleportPlayerToLocation(player, arg)
		
		elseif (action == "TestLoot") then	
			--local item = LootFunctions.GetLootFromContainer(player,1)
			--Logger.Debug("TEST NEW CONTAINER LOOT Container Rarity 1: ",item)
			--item = LootFunctions.GetLootFromContainer(player,2)
			--Logger.Debug("TEST NEW CONTAINER LOOT Container Rarity 2: ",item)
			--item = LootFunctions.GetLootFromContainer(player,3)
			--Logger.Debug("TEST NEW CONTAINER LOOT Container Rarity 3: ",item)
			--item = LootFunctions.GetLootFromContainer(player,4)
			--Logger.Debug("TEST NEW CONTAINER LOOT Container Rarity 4: ",item)
			--item = LootFunctions.GetLootFromContainer(player,5)
			--Logger.Debug("TEST NEW CONTAINER LOOT Container Rarity 5: ",item)
			
			
			--local typeWhiteList = {"Weapon","Clothing","OffHand","PowerSource","Tool","Misc","Heal","Disk","Trash","Consumable","Material"}
			
			--local lootItem1 = LootFunctions.GetFilteredEnemyLootItem("EvilGardenGnome",typeWhiteList)	--GetRandomItem(enemiesModule[enemyName].Loot).Name

			--local lootItem2 = LootFunctions.GetFilteredEnemyLootItem("EvilGardenGnome",typeWhiteList,{lootItem1},{lootItem1})

			--Logger.Debug("TEST GET CORPSE LOOT:",lootItem1,lootItem2)
			
		elseif (action == "DropCrate") then
			
			--WorldEventFunctions.SpawnCrate(true)

		end
	end
	
	
end)