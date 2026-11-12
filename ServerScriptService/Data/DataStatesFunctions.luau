--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--Remote Events
local TradingChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TradingChanged")
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local sendinv = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SendInv")
local TradeCompleteEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TradeComplete")

--Functions
local AttributeFunctions = require(ServerScriptService.Data.DataAttributesFunctions)

--Definition Modules

--Assets

--Modules


local States = {}
local functions = {}

--Health = 100
--Stamina = 10
--Dead = false,
--CampLocation = nil,
--OnBike = false,
--CurrentTool = ""
--CurrentTarget = ""

--TODO test these out
--StrengthModifier (effects can change this)

local currentTool = ""
local currentTarget = "" --TODO needs to move into states object to be pepr player
local slotDistance = 1

--TODO update tool with EquipTool event

local spawnLocation = workspace:WaitForChild("StarhopStationCloningSpawn")

ProfileLoadedEvent.Event:Connect(function(player)
	States[player.Name] = {
		Health = AttributeFunctions.GetMaxHealth(player),
		Stamina = AttributeFunctions.GetMaxStamina(player),
		Food = 100,
		Hydration = 100,
		Dead = false,
		CampLocation = nil,
		SpawnLocation = Vector3.new(spawnLocation.Position.X, spawnLocation.Position.Y + 5, spawnLocation.Position.Z) ,
		OnBike = false,
		CurrentTool = "",
		CurrentToolSlotNumber = "",
		SpeedModifier = 0,
		StrengthModifier = 0,
		FinesseModifier = 0,
		CriticalHitChanceModifier = 0,
		CriticalHitDamageModifier = 0,
		LastFireTime = 0,
		UnderWater = false,
		InWater = false,
		NumberOfItemsCarried = 0,
		Crafting = {},
		Spraypainting = {["Tag"]="Graffiti1"},
		Cooking = {},
		CurrentShip = nil,
		CurrentZones = {},
		Trading = {["State"]=nil,["OtherPlayer"]=nil,["Items"]={},["Money"]=""},
		EnemyTargetSlots = {

			["Slot1"]={
				EnemyID = -1,
				Position = Vector3.new(slotDistance,0,0)
			},
			["Slot2"]={
				EnemyID = -1,
				Position = Vector3.new(0,0,slotDistance)
			},
			["Slot3"]={
				EnemyID = -1,
				Position = Vector3.new(-slotDistance,0,0)
			},
			["Slot4"]={
				EnemyID = -1,
				Position = Vector3.new(0,0,-slotDistance)
			},
			["Slot5"]={
				EnemyID = -1,
				Position = Vector3.new(slotDistance,0,slotDistance)
			},
			["Slot6"]={
				EnemyID = -1,
				Position = Vector3.new(-slotDistance,0,-slotDistance)
			}
		}

	}
end)

Players.PlayerRemoving:Connect(function(player)
	States[player.Name] = nil
end)

function functions.GetState(player)
	if (States[player.Name] == nil) then
		return nil
	end

	--Can add other states but this way it is filtered and not everything in state global
	return {CurrentTool = States[player.Name].CurrentTool, CurrentToolSlotNumber = States[player.Name].CurrentToolSlotNumber,SpawnLocation = States[player.Name].SpawnLocation}
end

function functions.GetCurrentShip(player,slot)

	if (States[player.Name] == nil) then
		return nil
	end

	return States[player.Name].CurrentShip
end

function functions.GetEnemyTargetSlotPosition(player,slot)

	if (States[player.Name] == nil) then
		return nil
	end

	if (States[player.Name].EnemyTargetSlots[slot] == nil) then
		return nil
	end

	return States[player.Name].EnemyTargetSlots[slot].Position
end

function functions.GetEnemyTargetSlots(player)

	if (States[player.Name] == nil) then
		return nil
	end

	return States[player.Name].EnemyTargetSlots
end

function functions.SetEnemyTargetSlots(player,enemyTargetSlot,enemyID)

	if (enemyTargetSlot ~= -1 and States[player.Name].EnemyTargetSlots[enemyTargetSlot] ~= nil) then
		States[player.Name].EnemyTargetSlots[enemyTargetSlot].EnemyID = enemyID
	end
end

function functions.GetLastFireTime(player)

	if (States[player.Name] == nil) then
		return nil
	end

	return States[player.Name].LastFireTime
end

function functions.SetLastFireTime(player,LastFireTime)

	States[player.Name].LastFireTime = LastFireTime
end

function functions.GetHealth(player)

	if (States[player.Name] == nil) then
		return AttributeFunctions.GetMaxHealth(player)
	end

	if (States[player.Name].Health == nil) then
		return 0
	else
		return States[player.Name].Health
	end

end


function functions.AddFood(player, amount)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Food = math.min(States[player.Name].Food + amount,100)
	
	print("TEST FOOD CONSUMPTION food:",States[player.Name].Food)

end

function functions.RemoveFood(player, amount)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Food = math.max(States[player.Name].Food - amount,0)

	print("TEST FOOD CONSUMPTION food:",States[player.Name].Food)

end

function functions.GetFood(player)

	if (States[player.Name] == nil) then
		return 100
	end

	if (States[player.Name].Food == nil) then
		return 0
	else
		return States[player.Name].Food
	end

end

function functions.AddHydration(player, amount)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Hydration = math.min(States[player.Name].Hydration + amount,100)

	print("TEST Hydration CONSUMPTION Hydration:",States[player.Name].Hydration)

end

function functions.RemoveHydration(player, amount)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Hydration = math.max(States[player.Name].Hydration - amount,0)

	print("TEST Hydration CONSUMPTION Hydration:",States[player.Name].Hydration)

end

function functions.GetHydration(player)

	if (States[player.Name] == nil) then
		return 100
	end

	if (States[player.Name].Hydration == nil) then
		return 0
	else
		return States[player.Name].Hydration
	end

end

function functions.GetShield(player)

	if (States[player.Name] == nil) then
		return AttributeFunctions.GetMaxShield(player)
	end

	if (States[player.Name].Shield == nil) then
		return 0
	else
		return States[player.Name].Shield
	end

end

function functions.GetStamina(player)

	if (States[player.Name] == nil) then
		return AttributeFunctions.GetMaxStamina(player)
	end

	if (States[player.Name].Stamina == nil) then
		return 0
	else
		return States[player.Name].Stamina
	end

end

function functions.GetDead(player)

	if (States[player.Name] == nil) then
		return false
	end

	return States[player.Name].Dead
end

function functions.GetCampLocation(player)

	if (States[player.Name] == nil) then
		return nil
	end

	return States[player.Name].CampLocation
end

function functions.GetOnBike(player)

	if (States[player.Name] == nil) then
		return false
	end

	return States[player.Name].OnBike
end

function functions.GetCurrentTool(player)

	if (States[player.Name] == nil) then
		return ""
	end

	return States[player.Name].CurrentTool
end

function functions.CurrentToolSlotNumber(player)

	if (States[player.Name] == nil) then
		return ""
	end

	return States[player.Name].CurrentToolSlotNumber
end

function functions.GetCurrentTarget(player)

	if (States[player.Name] == nil) then
		return ""
	end

	return States[player.Name].CurrentTarget
end

function functions.SetHealth(player,health)

	if (States[player.Name] == nil) then
		return
	end

	if (health <= 0) then
		States[player.Name].Health = 0
	elseif (health >= AttributeFunctions.GetMaxHealth(player)) then
		States[player.Name].Health = AttributeFunctions.GetMaxHealth(player)
	else
		States[player.Name].Health = health
	end
end

function functions.SetStrength(player,strength)

	if (States[player.Name] == nil) then
		return
	end

	if (strength <= 0) then
		States[player.Name].StrengthModifier = 0
	else
		States[player.Name].StrengthModifier = strength
	end
end

function functions.SetFinesse(player,finesse)

	if (States[player.Name] == nil) then
		return
	end

	if (finesse <= 0) then
		States[player.Name].FinesseModifier = 0
	else
		States[player.Name].FinesseModifier = finesse
	end
end

function functions.SetCriticalHitChance(player,criticalHitChance)

	if (States[player.Name] == nil) then
		return
	end

	if (criticalHitChance <= 0) then
		States[player.Name].CriticalHitChanceModifier = 0
	else
		States[player.Name].CriticalHitChanceModifier = criticalHitChance
	end
end

function functions.SetCriticalHitDamage(player,criticalHitDamage)

	if (States[player.Name] == nil) then
		return
	end

	if (criticalHitDamage <= 0) then
		States[player.Name].CriticalHitDamageModifier = 0
	else
		States[player.Name].CriticalHitDamageModifier = criticalHitDamage
	end
end

function functions.SetStamina(player,stamina)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Stamina = stamina
end

function functions.AddHealth(player,health)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetHealth(player,States[player.Name].Health + health)
end

function functions.AddStrength(player,strength)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetStrength(player,States[player.Name].StrengthModifier + strength)
end

function functions.RemoveStrength(player,strength)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetStrength(player,States[player.Name].StrengthModifier - strength)
end

function functions.AddFinesse(player,finesse)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetFinesse(player,States[player.Name].FinesseModifier + finesse)
end

function functions.RemoveFinesse(player,Finesse)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetFinesse(player,States[player.Name].FinesseModifier - Finesse)
end

function functions.AddCriticalHitChance(player,critcalHitChance)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetCriticalHitChance(player,States[player.Name].CriticalHitChanceModifier + critcalHitChance)
end

function functions.RemoveCriticalHitChance(player,critcalHitChance)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetCriticalHitChance(player,States[player.Name].CriticalHitChanceModifier - critcalHitChance)
end

function functions.AddCriticalHitDamage(player,critcalHitDamage)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetCriticalHitDamage(player,States[player.Name].CriticalHitDamageModifier + critcalHitDamage)
end

function functions.RemoveCriticalHitDamage(player,critcalHitDamage)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetCriticalHitDamage(player,States[player.Name].CriticalHitDamageModifier - critcalHitDamage)
end

function functions.AddStamina(player,stamina)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Stamina = States[player.Name].Stamina + stamina
end

function functions.RemoveHealth(player,damage)

	if (States[player.Name] == nil) then
		return
	end

	functions.SetHealth(player,States[player.Name].Health - damage)
end

function functions.RemoveStamina(player,stamina)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Stamina = States[player.Name].Stamina - stamina
end


function functions.SetCurrentShip(player,currentship)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CurrentShip = currentship
end

function functions.SetDead(player,dead)

	if (States[player.Name] == nil) then
		return
	end	

	States[player.Name].Dead = dead
end

function functions.SetCampLocation(player,camplocation)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CampLocation = camplocation
end

function functions.SetCurrentTool(player,currenttool)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CurrentTool = currenttool
end

function functions.SetCurrentToolSlotNumber(player,currenttoolSlotNumber)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CurrentToolSlotNumber = currenttoolSlotNumber
end

function functions.SetCurrentTarget(player,currenttarget)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CurrentTarget = currenttarget
end

--Get the players current strength including any modifiers
function functions.GetCurrentStrength(player)

	if (States[player.Name] == nil) then
		return
	end

	return AttributeFunctions.GetStrength(player) + States[player.Name].StrengthModifier
end

--Get the players current Finesse including any modifiers
function functions.GetCurrentFinesse(player)

	if (States[player.Name] == nil) then
		return
	end

	return AttributeFunctions.GetFinesse(player) + States[player.Name].FinesseModifier
end

--Get the players current CriticalHitChance including any modifiers
function functions.GetCurrentCriticalHitChance(player)

	if (States[player.Name] == nil) then
		return
	end

	return AttributeFunctions.GetCriticalHitChance(player) -- + States[player.Name].CriticalHitChanceModifier
end

--Get the players current CriticalHitChance including any modifiers
function functions.GetCurrentCriticalHitDamage(player)

	if (States[player.Name] == nil) then
		return
	end

	return AttributeFunctions.GetCriticalHitDamage(player) -- + States[player.Name].CriticalHitDamageModifier
end


---Crafting
function functions.ClearCrafting(player)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Crafting = {}
end

function functions.GetCrafting(player)

	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].Crafting
end

function functions.SetCraftingItem(player,itemId,item)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Crafting[itemId] = item
end

---Cooking
function functions.ClearCooking(player)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Cooking = {}
end

function functions.GetCooking(player)

	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].Cooking
end

function functions.SetCookingItem(player,itemId,item)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Cooking[itemId] = item
end

function functions.GetSpawnLocation(player)

	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].SpawnLocation
end

function functions.SetSpawnLocation(player,location)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].SpawnLocation = location
end

function functions.GetSpraypaintingTag(player)

	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].Spraypainting
end

function functions.SetSpraypaintingTag(player,tag,color1,color2,color3)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Spraypainting["Tag"] = tag
	States[player.Name].Spraypainting["Color1"] = color1
	States[player.Name].Spraypainting["Color2"] = color2
	States[player.Name].Spraypainting["Color3"] = color3
end

function functions.GetUnderWater(player)
	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].UnderWater
end

function functions.SetUnderWater(player,value)
	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].UnderWater = value
end

function functions.GetNumberOfItemsCarried(player)
	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].NumberOfItemsCarried
end

function functions.SetNumberOfItemsCarried(player,value)
	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].NumberOfItemsCarried = value
end

function functions.GetInWater(player)
	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].InWater
end

function functions.SetInWater(player,value)
	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].InWater = value
end

function functions.IsInZone(player,value)
	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].CurrentZones[value] == true
end

function functions.GetCurrentZones(player)
	if (States[player.Name] == nil) then
		return
	end

	return States[player.Name].CurrentZones
end

function functions.InZone(player,value)
	if (States[player.Name] == nil) then
		return
	end

	if (States[player.Name].CurrentZones == nil) then
		States[player.Name].CurrentZones = {}
	end

	States[player.Name].CurrentZones[value] = true
end

function functions.OutZone(player,value)
	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].CurrentZones[value] = nil
end

--Trading

function functions.GetTrading(player)
	if (States[player.Name] == nil) then
		return
	end

	if (States[player.Name].Trading) then
		return States[player.Name].Trading
	end

end

function functions.ClearTrading(player)

	if (States[player.Name] == nil) then
		return
	end

	--Clear other player trading

	local OtherPlayer = States[player.Name].Trading.OtherPlayer

	if (OtherPlayer ~= nil) then
		if (States[OtherPlayer] and States[OtherPlayer].Trading.OtherPlayer == player.Name) then
			States[OtherPlayer].Trading = {["State"]=nil,["OtherPlayer"]=nil,["Items"]={},["Money"]=""}
		end
	end

	States[player.Name].Trading = {["State"]=nil,["OtherPlayer"]=nil,["Items"]={},["Money"]=""}
end

function functions.SetTradingItem(player,itemId,item)

	if (States[player.Name] == nil) then
		return
	end

	States[player.Name].Trading.Items[itemId] = item

	local otherPlayerName = nil
	local otherPlayer = nil

	if (States[player.Name].Trading.OtherPlayer) then
		otherPlayerName = States[player.Name].Trading.OtherPlayer

		if (States[otherPlayerName] == nil) then
			MessagePlayerEvent:FireClient(player,otherPlayerName.." canceled the trade")
			functions.ClearTrading(player)
			return
		end

		if (Players[otherPlayerName]) then
			otherPlayer = Players[otherPlayerName]
		end

	end	

	sendinv:FireClient(player) --To update any drag and drop 
	TradingChangedEvent:FireClient(player,"Updated",otherPlayerName,States[player.Name].Trading,States[otherPlayerName].Trading)

	if (States[otherPlayerName].Trading.OtherPlayer == player.Name) then
		TradingChangedEvent:FireClient(otherPlayer,"Updated",player.Name,States[otherPlayerName].Trading,States[player.Name].Trading)
	end
end

function functions.UpdateTrading(player)
	if (States[player.Name] == nil) then
		return
	end

	TradingChangedEvent:FireClient(player,"Updated",nil,States[player.Name].Trading,nil)
end

function functions.MoneyUpdate(player,money)
	if (States[player.Name] == nil) then
		return
	end

	if (States[player.Name].Trading) then
		States[player.Name].Trading.Money = money
	end

	local otherPlayerName = nil
	local otherPlayer = nil

	if (States[player.Name].Trading.OtherPlayer) then
		otherPlayerName = States[player.Name].Trading.OtherPlayer

		if (States[otherPlayerName] == nil) then
			MessagePlayerEvent:FireClient(player,otherPlayerName.." canceled the trade")
			functions.ClearTrading(player)
			return
		end

		if (Players[otherPlayerName]) then
			otherPlayer = Players[otherPlayerName]
		end

	end	

	if (States[otherPlayerName].Trading.OtherPlayer == player.Name) then
		TradingChangedEvent:FireClient(otherPlayer,"Updated",player.Name,States[otherPlayerName].Trading,States[player.Name].Trading)
	end
end

function functions.CompleteTrade(player)
	if (States[player.Name] == nil) then
		return
	end

	local otherPlayerName = nil
	local otherPlayer = nil

	if (States[player.Name].Trading.OtherPlayer) then
		otherPlayerName = States[player.Name].Trading.OtherPlayer

		if (States[otherPlayerName] == nil) then
			MessagePlayerEvent:FireClient(player,otherPlayerName.." canceled the trade")
			functions.ClearTrading(player)
			return
		end

		if (Players[otherPlayerName]) then
			otherPlayer = Players[otherPlayerName]
		end

	end	

	--Check that after any timer we are still both accepting the trade
	if (States[player.Name].Trading.Accepted and States[otherPlayerName].Trading.Accepted) then

		local tempA = States[player.Name].Trading.Items
		local tempB = States[otherPlayer.Name].Trading.Items

		States[player.Name].Trading.Items = tempB
		States[otherPlayer.Name].Trading.Items = tempA

		TradeCompleteEvent:Fire(player,otherPlayer,States[player.Name].Trading.Money,States[otherPlayer.Name].Trading.Money,tempA,tempB)
		--InventoryFunctions.AddMoney(player,States[otherPlayer.Name].Trading.Money) --cannot do because circular deps
		--InventoryFunctions.AddMoney(otherPlayer,States[player.Name].Trading.Money)

		States[player.Name].Trading.State = "TradeComplete"
		States[otherPlayer.Name].Trading.State = "TradeComplete"
		States[player.Name].Trading.OtherPlayer = nil
		States[otherPlayer.Name].Trading.OtherPlayer = nil


		TradingChangedEvent:FireClient(player,"TradeComplete",otherPlayer,States[player.Name].Trading,States[otherPlayer.Name].Trading)
		TradingChangedEvent:FireClient(otherPlayer,"TradeComplete",player,States[otherPlayer.Name].Trading,States[player.Name].Trading)
	end
end

function functions.AcceptTrade(player, accept)
	if (States[player.Name] == nil) then
		return
	end

	if (States[player.Name].Trading) then
		States[player.Name].Trading.Accepted = accept
	end

	local otherPlayerName = nil
	local otherPlayer = nil

	if (States[player.Name].Trading.OtherPlayer) then
		otherPlayerName = States[player.Name].Trading.OtherPlayer

		if (States[otherPlayerName] == nil) then
			MessagePlayerEvent:FireClient(player,otherPlayerName.." canceled the trade")
			functions.ClearTrading(player)
			return
		end

		if (Players[otherPlayerName]) then
			otherPlayer = Players[otherPlayerName]
			States[otherPlayerName].Trading.OtherPlayerAccepted = accept
		end

	end	

	if (States[otherPlayerName].Trading.OtherPlayer == player.Name) then
		if (accept) then
			TradingChangedEvent:FireClient(otherPlayer,"OtherPlayerAccepted")
		else
			TradingChangedEvent:FireClient(otherPlayer,"OtherPlayerUnAccepted")
		end

		--Check if both have excepted and start timer
		if (States[player.Name].Trading.Accepted and States[otherPlayerName].Trading.Accepted) then
			TradingChangedEvent:FireClient(player,"TradePending")
			TradingChangedEvent:FireClient(otherPlayer,"TradePending")

			delay(5, function()
				functions.CompleteTrade(player)
			end)
		end
	end

end

function functions.CancelTrading(player)
	if (States[player.Name] == nil) then
		return
	end

	local otherPlayer = nil
	local otherPlayerName = States[player.Name].Trading.OtherPlayer

	if (otherPlayerName and Players[otherPlayerName]) then
		otherPlayer = Players[otherPlayerName]
	end

	functions.ClearTrading(player)

	if (otherPlayer) then
		functions.ClearTrading(otherPlayer)
	end

	TradingChangedEvent:FireClient(otherPlayer,"CancelTrade",player)	
	MessagePlayerEvent:FireClient(otherPlayer,player.Name.." canceled the trade")

end

function functions.SetRequestTrading(requestingPlayer,acceptingPlayer)
	if (States[requestingPlayer.Name] == nil) then
		return
	end

	States[requestingPlayer.Name].Trading.State = "Requested"
	States[requestingPlayer.Name].Trading.OtherPlayer = acceptingPlayer.Name

	--Send back message to other player to pop gui showing request and somehow timeout after an amount of time
	TradingChangedEvent:FireClient(acceptingPlayer,"Requested",requestingPlayer)	
end


function functions.AcceptTrading(acceptingPlayer,requestingPlayer)
	if (States[acceptingPlayer.Name] == nil) then
		return
	end

	if ((States[requestingPlayer.Name].Trading.State == "Requested") and (States[requestingPlayer.Name].Trading.OtherPlayer == acceptingPlayer.Name) ) then
		States[acceptingPlayer.Name].Trading.State = "Accepted"
		States[acceptingPlayer.Name].Trading.OtherPlayer = requestingPlayer.Name

		States[requestingPlayer.Name].Trading.State = "Accepted"
		States[requestingPlayer.Name].Trading.OtherPlayer = acceptingPlayer.Name

	else
		MessagePlayerEvent:FireClient(acceptingPlayer,requestingPlayer.Name.." is no longer requesting to trade")
		return
	end

	TradingChangedEvent:FireClient(requestingPlayer,"Accepted",acceptingPlayer,States[acceptingPlayer.Name].Trading,States[requestingPlayer.Name].Trading)
	TradingChangedEvent:FireClient(acceptingPlayer,"Accepted",requestingPlayer,States[requestingPlayer.Name].Trading,States[acceptingPlayer.Name].Trading)
end

function functions.DeclineTrading(acceptingPlayer,requestingPlayer)
	if (States[acceptingPlayer.Name] == nil) then
		return
	end

	if ((States[requestingPlayer.Name].Trading.State == "Requested") and (States[requestingPlayer.Name].Trading.OtherPlayer == acceptingPlayer.Name) ) then
		functions.ClearTrading(acceptingPlayer)
		functions.ClearTrading(requestingPlayer)

	else
		MessagePlayerEvent:FireClient(acceptingPlayer,requestingPlayer.Name.." is no longer requesting to trade")
		return
	end

	MessagePlayerEvent:FireClient(requestingPlayer,acceptingPlayer.Name.." declined to trade with you")
	--TradingChangedEvent:FireClient(requestingPlayer,"Declined",acceptingPlayer.Name,States[acceptingPlayer.Name].Trading,States[requestingPlayer.Name].Trading)
end

return functions