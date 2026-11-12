local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local EnemyFunctions = require(ServerScriptService.SharedFunctions.EnemyFunctions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpdateStaminaEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateStamina")
local UpdateHealthEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateHealth")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local PlayerHitEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	

local timeChangeInterval = 1
local step_counter = 0 
local FOOD_TICK_SECONDS = 60
local foodCounter = 0

local profileLoaded = false

ProfileLoadedEvent.Event:Connect(function (player)
	profileLoaded = true
end)

playersLastHit = {}

function onPlayerHit(player,damage,enemyName,damageType)
	if (not player) then
		return
	end
	playersLastHit[player] = os.time()
end

PlayerHitEvent.Event:Connect(onPlayerHit)


RunService.Heartbeat:Connect(function(step)

	if (not profileLoaded) then
		return
	end
	--debug.profilebegin("EffectsHandler")

	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval --TODO shouldn't this fully reset to zero?
		
		foodCounter += timeChangeInterval -- 1 second
		
		
		local currentTime = os.time()
		
		--Apply any time based effects to each player every second
		for i, player in pairs(Players:GetChildren()) do
			
			--Only recover if it has been more than a certain amount based on vitality since your last hit
			local recoveryWaitTime = math.max(20 - (AttributesFunctions.GetGrit(player)*5),10)
			if (playersLastHit[player] and (currentTime - playersLastHit[player]) < recoveryWaitTime) then
				continue
			end

			--normal health and stamina recovery is 2% every 1 seconds (1 vitality)
			if (StatesFunctions.GetHealth(player) < AttributesFunctions.GetMaxHealth(player)) then

				local baseRecoveryPercentage = .001
				local perVitalityRecoveryPercentage = .00005
				local Vitality = 100 --TODO get actual AttributesFunctions.GetVitality(player)
				local MaxHealth = AttributesFunctions.GetMaxHealth(player)
				local recoveryAmountPercentage = (baseRecoveryPercentage+(perVitalityRecoveryPercentage*Vitality*Vitality))
				local recoveryAmountPerSecond = math.round(recoveryAmountPercentage*MaxHealth)+1 --the +1 makes sure there is some recovery for low level players
				--Logger.Debug("TEST RECOVERY recoveryAmountPercentage:"..recoveryAmountPercentage*100)
				--Logger.Debug("TEST RECOVERY recoveryAmountPerSecond:"..recoveryAmountPerSecond)
				--Logger.Debug("TEST RECOVERY MaxHealth:"..MaxHealth)
				--Logger.Debug("TEST RECOVERY CurrentHealth:"..StatesFunctions.GetHealth(player))

				StatesFunctions.AddHealth(player,recoveryAmountPerSecond)
				UpdateHealthEvent:FireClient(player,StatesFunctions.GetHealth(player) , AttributesFunctions.GetMaxHealth(player))
			end
			if (StatesFunctions.GetStamina(player) < AttributesFunctions.GetMaxStamina(player)) then 
				StatesFunctions.AddStamina(player,.2)
				--UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , AttributesFunctions.GetMaxStamina(player))
			end
			if foodCounter >= FOOD_TICK_SECONDS then
				foodCounter -= FOOD_TICK_SECONDS
				StatesFunctions.RemoveFood(player, 1)
				StatesFunctions.RemoveHydration(player, 1)
			end

		end
		
	end

	--debug.profileend()
end)

