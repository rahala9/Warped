--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local tweenService = game:GetService("TweenService")
Players = game:GetService("Players")

--Remote Events
local PlayerHitEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	

--Functions
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local CombatFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("CombatFunctions"))
local PlayerMovementFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("PlayerMovementFunctions"))

--Definition Modules
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
local enemyModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemy")) 
local corpseModule = require(game.ServerScriptService:WaitForChild("SharedModules"):WaitForChild("Corpse")) 
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets
local brokenCrate = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("BrokenCrate")
local brokenCrackedFloor = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("BrokenCrackedFloor")

--Modules
local Data = require(ServerScriptService.Data.Data)
local Cache = require(ReplicatedStorage.SharedUtilities.ModelPartCache)

--Initialization

local enemyFunctions = {}

local enemyID = 0

--enemyFunctions.enemies = {}

enemyFunctions.CollisionGroup = "Enemy"

local R = Random.new()

local tweeningInformation = TweenInfo.new(

	1, -- Length
	Enum.EasingStyle.Quad, -- Easing style of the TweenInfo
	Enum.EasingDirection.InOut, -- Easing direction of the TweenInfo
	0, -- Number of times the tween will repeat   
	false, -- Should the tween repeat?
	0 -- Delay between each tween  
)

local BrokenCratePool = Cache.new(brokenCrate, "BrokenCratePool", {
	Warm = 10,

	OnGet = function(model)
		-- show parts and prepare for use
		--for _, d in ipairs(model:GetDescendants()) do
		--	if d:IsA("BasePart") then
		--		d.Transparency = 0
		--		d.CanCollide = true
		--		d.CanTouch = true
		--		d.Anchored = false
		--	elseif d:IsA("WeldConstraint") then
		--		d.Enabled = true
		--	end
		--end
	end,

	OnReturn = function(model)
		-- reset to pristine state (welds on, anchored, no collision)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("WeldConstraint") then
				d.Enabled = true
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.Transparency = 1
			end
		end
	end,
})

local BrokenCrackedFloorPool = Cache.new(brokenCrackedFloor, "BrokenCrackedFloorPool", {
	Warm = 10,

	OnGet = function(model)
		-- show parts and prepare for use
		--for _, d in ipairs(model:GetDescendants()) do
		--	if d:IsA("BasePart") then
		--		d.Transparency = 0
		--		d.CanCollide = true
		--		d.CanTouch = true
		--		d.Anchored = false
		--	elseif d:IsA("WeldConstraint") then
		--		d.Enabled = true
		--	end
		--end
	end,

	OnReturn = function(model)
		-- reset to pristine state (welds on, anchored, no collision)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("WeldConstraint") then
				d.Enabled = true
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.Transparency = 1
			end
		end
	end,
})


function enemyFunctions.AddEnemy(enemy)

	enemyID = enemyID + 1

	enemy.id = enemyID

	enemy.char.Name = enemy.char.Name --..enemyID

	enemy.char:SetAttribute("EnemyID", enemy.id)

	--enemyFunctions.AddHealthbarAndTitle(enemy.name, enemy.root)

	local billboard = enemy["root"]:FindFirstChild("EnemyHealth")
	if (billboard) then
		billboard.EnemyHealthBarFrame.HealthText.Text = enemy.health.main.." / "..enemiesModule[enemy.name].Health.main
	end

	--enemyFunctions.enemies[enemyID] = enemy

	table.insert(enemyModule.enemies,enemy)
end

function enemyFunctions.GetTargetSlotPosition(player,enemy)
	return StatesFunctions.GetEnemyTargetSlotPosition(player,enemy.targetSlot)
end

function enemyFunctions.GetEnemy(enemyInstance)
	local enemyID = enemyInstance:GetAttribute("EnemyID")

	if (enemyID ~= nil) then
		return enemyFunctions.GetEnemyByID(enemyID)
	end

	return nil
end

function enemyFunctions.GetEnemyByID(enemyID)
	for _,enemy in pairs(enemyModule.enemies) do
		if (enemy.id == enemyID) then
			return enemy
		end
	end

	return nil
end

local function shallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

--TODO add filters
function enemyFunctions.GetEnemies()
	return shallowCopy(enemyModule.enemies)
end

function enemyFunctions.PickRandomAttack(attacks)

	if (attacks == nil) then
		return nil
	end

	local sum = 0
	for _,v in pairs(attacks) do
		sum = sum + v.RarityPercentage
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(attacks) do
		rand = rand - v.RarityPercentage
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

function enemyFunctions.GetEmptyPlayerEnemyTargetSlot(player,enemy,keepCurrentSlot)
	local enemyTargetSlots = StatesFunctions.GetEnemyTargetSlots(player)

	if (enemyTargetSlots == nil) then
		return Vector3.new(1,0,0)
	end	


	if (keepCurrentSlot) then
		--Pick your same slot if available TODO remove this possibly and just always pick closest slot..looks more natural
		if (enemyTargetSlots[enemy.targetSlot] ~= nil and enemyTargetSlots[enemy.targetSlot].EnemyID == enemy.id) then
			return enemyTargetSlots[enemy.targetSlot].Position
		else
			enemy.targetSlot = ""
		end
	end


	local nearestSlot = -1
	local nearestSlotPosition = Vector3.new(0,0,0)
	local nearestSlotDistance = 99999

	for i,v in pairs(enemyTargetSlots) do
		--if we find an empty slot or our current slot check distance for closest.
		if ((v.EnemyID == -1) or v.EnemyID == enemy.id) then
			local finalTargetSlotPosition = player.HumanoidRootPart.Position +v.Position
			local distance = (enemy.char.HumanoidRootPart.Position - finalTargetSlotPosition).magnitude --local distance = (enemy.char.HumanoidRootPart.Position - closeToTarget).magnitude
			if (distance < nearestSlotDistance) then
				nearestSlotDistance = distance
				nearestSlot = i
				nearestSlotPosition = v.Position
			end
		end
	end

	if (nearestSlot ~= -1) then
		StatesFunctions.SetEnemyTargetSlots(player,enemy.targetSlot,-1) --remove previous target slot
		StatesFunctions.SetEnemyTargetSlots(player,nearestSlot,enemy.id) --set as my new target slot
		enemy.targetSlot = nearestSlot
	end

	return nearestSlotPosition

end


function enemyFunctions.SetPartsCollisionGroup(Part, CollisionGroupName)
	-- Sets the collision group of the Part to the second parameter, then calls the function on its children
	local PhysicsService = game:GetService("PhysicsService")

	if Part:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(Part, CollisionGroupName)
	end

	for _, Child in next, Part:GetChildren() do
		enemyFunctions.SetPartsCollisionGroup(Child, CollisionGroupName)
	end
end

function enemyFunctions.AddHealthbarAndTitle(title, parent)


	local enemyHealthBar = Instance.new("BillboardGui")	
	enemyHealthBar.AlwaysOnTop = true
	enemyHealthBar.Name = "EnemyBillboard"
	enemyHealthBar.ExtentsOffset = Vector3.new(0,.5,0)

	local enemyTitleFrame = Instance.new("Frame")
	enemyTitleFrame.Size = UDim2.new(1.5,0,0,0)
	enemyTitleFrame.Position = UDim2.new(0,0,0,0)
	enemyTitleFrame.BackgroundTransparency = 1
	enemyTitleFrame.Parent = enemyHealthBar

	local enemyTitle = Instance.new("TextLabel")
	enemyTitle.Text = title
	enemyTitle.Font = Enum.Font.SourceSansBold
	enemyTitle.Position = UDim2.new(.05,0,0,0)
	enemyTitle.Size = UDim2.new(1,0,1.5,0)
	enemyTitle.BackgroundTransparency = 1
	enemyTitle.TextSize = 60
	enemyTitle.TextScaled = true
	enemyTitle.TextColor3 = Color3.new(255,255,255)
	enemyTitle.Parent = enemyTitleFrame

	local enemyHealthBarFrame = Instance.new("Frame")
	enemyHealthBarFrame.Size = UDim2.new(1.5,0,.5,0)
	enemyHealthBarFrame.Position = UDim2.new(0,0,.9,0)
	enemyHealthBarFrame.BorderSizePixel = 2
	enemyHealthBarFrame.Name = "EnemyHealthBarFrame"
	enemyHealthBarFrame.Parent = enemyHealthBar

	local healthBarFrameCorners = Instance.new("UICorner")
	healthBarFrameCorners.Parent = enemyHealthBarFrame

	local enemyHealthBarHealth = Instance.new("Frame")
	enemyHealthBarHealth.Size = UDim2.new(1,0,1,0)
	enemyHealthBarHealth.BackgroundColor3 = Color3.new(255,0,0)
	enemyHealthBarHealth.Name = "EnemyHealthBarHealth"
	enemyHealthBarHealth.Parent = enemyHealthBarFrame

	local healthCorners = Instance.new("UICorner")
	healthCorners.Parent = enemyHealthBarHealth

	local healthStroke = Instance.new("UIStroke")
	healthStroke.Thickness = 2
	healthStroke.Parent = enemyHealthBarHealth

	--enemyHealthBar.Adornee = enemy
	enemyHealthBar.SizeOffset = Vector2.new(0,4.5)
	enemyHealthBar.Size =  UDim2.new(4,0,1,0)

	enemyHealthBar.Parent = parent


	--Add Debug textbox
	--local debugText = Instance.new("TextLabel")
	--debugText.Name = "DebugText"
	--debugText.Text = "Debug"
	--debugText.Font = Enum.Font.SourceSansBold
	--debugText.Position = UDim2.new(.01,0,.2,0)
	--debugText.Size = UDim2.new(0,75,0,50)
	--debugText.BackgroundTransparency = 1
	--debugText.TextSize = 40
	--debugText.TextScaled = true
	--debugText.TextColor3 = Color3.new(1,0,0)
	--debugText.Parent = enemyHealthBar

end

function enemyFunctions.StopCurrentAnimations(enemy)
	if (enemy.human) then
		for i,v in pairs(enemy.human:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	else
		for i,v in pairs(enemy.char.AnimationController:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	end
end

function enemyFunctions.GetEffectsHandler(enemy,effectsHandler)
	if (not effectsHandler) then
		return nil
	end

	--TODO perhaps turn this into own table in module
	if (effectsHandler == "RockSmash") then
		return function()
			--rbxassetid://71472197762839
			local sound = enemy.char:FindFirstChild("Sounds", true):FindFirstChild("RockSmash", true)
			if sound then
				sound.PlaybackSpeed = 0.95 + math.random() * 0.1
				if sound.IsPlaying then sound:Stop() end
				sound:Play()
			end
		end
	end
end

function enemyFunctions.EnemyMeleeAttack(enemy,attack,EnemyTarget)
	if (attack.Emit ~= nil) then

		if (attack.Emit.Emitter1 ~= nil) then
			enemy.char[attack.Emit.Emitter1][attack.Name]:Emit(attack.Emit.Amount)
		end

		if (attack.Emit.Emitter2 ~= nil) then
			enemy.char[attack.Emit.Emitter2][attack.Name.."2"]:Emit(attack.Emit.Amount)
		end
	end

	local damageData =  {HealthDamage = 10} --TODO CombatFunctions.CalculateMeleeDamage(enemy, weapon, EnemyTarget, false)-- enemyFunctions.CalculateDamage(player,weapon,attack,directDamage)

	--TODO send all damage data to handle armor and shields
	PlayerHitEvent:Fire(game:GetService("Players"):GetPlayerFromCharacter(EnemyTarget),damageData.HealthDamage,enemy.name)
end

function enemyFunctions.EnemyRangedAttack(enemy,attack,EnemyTarget)
	if (attack.Emit ~= nil) then

		if (attack.Emit.Emitter1 ~= nil) then
			enemy.char[attack.Emit.Emitter1][attack.Name]:Emit(attack.Emit.Amount)
		end

		if (attack.Emit.Emitter2 ~= nil) then
			enemy.char[attack.Emit.Emitter2][attack.Name.."2"]:Emit(attack.Emit.Amount)
		end
	end
	
	local distance = (EnemyTarget.PrimaryPart.Position - enemy.PrimaryPart.Position).magnitude	
	local isMoving = false --PlayerMovementFunctions.IsPlayerMoving(player)
	
	local target = {}
	target.CurrentShield = StatesFunctions.GetShield(EnemyTarget) or 0
	target.MaxShield = AttributesFunctions.GetMaxShield(EnemyTarget) or 0
	target.ArmorRating = AttributesFunctions.GetMaxArmor(EnemyTarget) or 0
	target.CurrentHealth = StatesFunctions.GetHealth(EnemyTarget) or 100
	target.MaxHealth = AttributesFunctions.GetMaxHealth(EnemyTarget) or 100
	
	local damageData =  CombatFunctions.CalculateDamage(enemy, itemsmodule[enemiesModule[enemy.Name].Weapon], target, distance, isMoving, false)-- enemyFunctions.CalculateDamage(player,weapon,attack,directDamage)

	--TODO send all damage data to handle armor and shields
	PlayerHitEvent:Fire(game:GetService("Players"):GetPlayerFromCharacter(EnemyTarget),damageData.HealthDamage,enemy.name)
end

function enemyFunctions.CalculateMeleeDamage(player, weapon, attack)

	local Strength = StatesFunctions.GetCurrentStrength(player)
	local CriticalHitChance = StatesFunctions.GetCurrentCriticalHitChance(player) or 0
	local CriticalHitDamage = StatesFunctions.GetCurrentCriticalHitDamage(player) or 0

	local DamageMin = 0
	local DamageMax = 0

	-- Calculate DamageMin
	if attack.AttackDamageMin and attack.AttackDamageMin.Type == "*" then
		DamageMin = math.floor(weapon.WeaponDamageMin * attack.AttackDamageMin.Amount + 0.5)
	else
		DamageMin = weapon.WeaponDamageMin or 0
	end

	-- Calculate DamageMax
	if attack.AttackDamageMax and attack.AttackDamageMax.Type == "*" then
		DamageMax = math.floor(weapon.WeaponDamageMax * attack.AttackDamageMax.Amount + 0.5)
	else
		DamageMax = weapon.WeaponDamageMax or 0
	end

	-- Prevent math.random crash from min > max
	if DamageMax < DamageMin then
		DamageMax = DamageMin
	end

	local BaseDamage = math.random(DamageMin, DamageMax)

	-- Strength scaling and cap settings
	local StrengthScaling = 1.0 -- TODO: scale this by weapon weight class (e.g., light = 0.3, heavy = 1.2)
	local StrengthBonusScale = 1.2 -- each point of strength gives a 12% bonus to damage
	local StrengthBonusCapPercent = 1.0 -- cap strength bonus at 100% of base damage

	-- Calculate capped strength bonus
	local EffectiveStrength = Strength * StrengthScaling
	local rawBonus = EffectiveStrength * StrengthBonusScale
	local maxBonus = BaseDamage * StrengthBonusCapPercent
	local StrengthBonus = math.min(rawBonus, maxBonus)

	local CriticalHit = math.random(1,100) <= CriticalHitChance
	local CriticalHitDamageBonus = 0

	local TotalDamage = BaseDamage + StrengthBonus

	if (CriticalHit) then
		CriticalHitDamageBonus = TotalDamage*CriticalHitDamage	--Set as percentage multipled
	end

	local FinalDamage = TotalDamage + CriticalHitDamageBonus

	print("TEST DAMAGE:","BaseDamage:",BaseDamage," StrengthBonus:",StrengthBonus," rawBonus:",rawBonus," maxBonus:",maxBonus)

	print("TEST DAMAGE:"," Critical hit damage bonus:",CriticalHitDamageBonus," CriticalHitChance:",CriticalHitChance," CriticalHitDamage:",CriticalHitDamage)


	return math.floor(FinalDamage + 0.5)
end

function enemyFunctions.CalculateRangedDamage(player, weapon, attack, perception)

	local Finesse = StatesFunctions.GetCurrentFinesse(player) 

	local DamageMin = 0
	local DamageMax = 0

	-- Calculate DamageMin
	if attack.AttackDamageMin and attack.AttackDamageMin.Type == "*" then
		DamageMin = math.floor(weapon.WeaponDamageMin * attack.AttackDamageMin.Amount + 0.5)
	else
		DamageMin = weapon.WeaponDamageMin or 0
	end

	-- Calculate DamageMax
	if attack.AttackDamageMax and attack.AttackDamageMax.Type == "*" then
		DamageMax = math.floor(weapon.WeaponDamageMax * attack.AttackDamageMax.Amount + 0.5)
	else
		DamageMax = weapon.WeaponDamageMax or 0
	end

	-- Prevent math.random crash from min > max
	if DamageMax < DamageMin then
		DamageMax = DamageMin
	end

	local BaseDamage = math.random(DamageMin, DamageMax)

	-- Strength scaling and cap settings
	local PerceptionScaling = 1.0 -- TODO: scale this by weapon weight class (e.g., light = 0.3, heavy = 1.2)
	local PerceptionBonusScale = 1.2 -- each point of Perception gives a 12% bonus to damage
	local PerceptionBonusCapPercent = 1.0 -- cap Perception bonus at 100% of base damage

	-- Calculate capped Perception bonus
	local EffectivePerception = perception * PerceptionScaling
	local rawBonus = EffectivePerception * PerceptionBonusScale
	local maxBonus = BaseDamage * PerceptionBonusCapPercent
	local PerceptionBonus = math.min(rawBonus, maxBonus)

	local FinalDamage = BaseDamage + PerceptionBonus

	--print("TEST DAMAGE:","BaseDamage:",BaseDamage," PerceptionBonus:",PerceptionBonus," rawBonus:",rawBonus," maxBonus:",maxBonus)

	return math.floor(FinalDamage + 0.5)
end





function enemyFunctions.DealBodyPartDamage(enemy, bodyPart, damage)

	local bodyPartHealth

	if (bodyPart.Name == "Head") then
		enemy.health.head = enemy.health.head - damage
		bodyPartHealth = enemy.health.head
	elseif (bodyPart.Name == "RightArm") then
		enemy.health.rightArm = enemy.health.rightArm - damage
		bodyPartHealth = enemy.health.rightArm
	elseif (bodyPart.Name == "LeftArm")  then
		enemy.health.leftArm = enemy.health.leftArm - damage
		bodyPartHealth = enemy.health.leftArm
	elseif (bodyPart.Name == "RightLeg") then
		enemy.health.rightLeg = enemy.health.rightLeg - damage
		bodyPartHealth = enemy.health.rightLeg
	elseif (bodyPart.Name == "LeftLeg") then
		enemy.health.leftLeg = enemy.health.leftLeg - damage
		bodyPartHealth = enemy.health.leftLeg
	else
		--Main Damage only for body
		enemy.health.main = enemy.health.main - damage

		--Update health bar
		local billboard = enemy["root"]:FindFirstChild("EnemyHealth")
		if (billboard) then

			if (enemy.health.main > 0) then
				billboard.EnemyHealthBarFrame.HealthText.Text = enemy.health.main.." / "..enemiesModule[enemy.name].Health.main

				local TweenHealth = tweenService:Create(billboard.EnemyHealthBarFrame.Health,tweeningInformation,{Size = UDim2.new(enemy.health.main/enemiesModule[enemy.name].Health.main,0,1,0)}) --TODO remove hardcoded 30
				TweenHealth:Play()
				--TweenHealth.Completed:wait() --TODO should we wait here or just move on?
			else
				billboard.Enabled = false
			end

		end
	end

	if (bodyPartHealth ~=nil and bodyPartHealth <= 0) then

		return true
	end

	return false
end


--local damageForColours = 
--	{
--		[25] = Color3.fromRGB(255, 196, 101),
--		[50] = Color3.fromRGB(255, 234, 0),
--		[75] = Color3.fromRGB(255, 140, 0),
--		[100] = Color3.fromRGB(255, 0, 0),
--	}

local damageIndicatorTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)



function enemyFunctions.HandleDamageIndicator(enemy, damage,hitBodyPart)

	local enemyStartLife = 30 --TODO get this from table of enemies

	local damageIndicatorGui = Instance.new("BillboardGui")
	damageIndicatorGui.AlwaysOnTop = true
	damageIndicatorGui.Size = UDim2.new(1.5, 0, 1.5, 0)

	local offsetX = math.random(-3, 3)
	local offsetY = math.random(0, 5)
	local offsetZ = math.random(-3, 3)
	damageIndicatorGui.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

	local damageIndicatorLabel = Instance.new("TextLabel")

	damageIndicatorLabel.Active = true
	damageIndicatorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	damageIndicatorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	damageIndicatorLabel.TextScaled = false
	damageIndicatorLabel.BackgroundTransparency = 1
	damageIndicatorLabel.TextStrokeTransparency = 0
	damageIndicatorLabel.Font = Enum.Font.GothamBlack
	damageIndicatorLabel.TextSize = 24 + math.clamp(damage,1,20)

	if (hitBodyPart.Name == "Body") then
		damageIndicatorLabel.Text = damage
	else
		damageIndicatorLabel.Text = damage.."("..hitBodyPart.Name..")" 
	end

	damageIndicatorLabel.Size = UDim2.new(1, 0, 1, 0)

	damageIndicatorLabel.TextColor3 = Color3.fromRGB(255, 196, 101)

	--for colorDamage, colour in pairs(damageForColours) do

	--	if damage <= colorDamage then 

	--		damageIndicatorLabel.TextColor3 = colour
	--		colorDamage = 100
	--	end
	--end

	damageIndicatorLabel.Parent = damageIndicatorGui
	damageIndicatorGui.Parent = enemy.root


	local guiUpTween = tweenService:Create(damageIndicatorGui, damageIndicatorTweenInfo, {StudsOffset = damageIndicatorGui.StudsOffset + Vector3.new(0, 10, 0)})

	local textFadeTween = tweenService:Create(damageIndicatorLabel, damageIndicatorTweenInfo, {TextTransparency = 1,TextStrokeTransparency = 1})

	guiUpTween:Play()
	textFadeTween:Play()

	Debris:AddItem(damageIndicatorGui, 5)

end

function enemyFunctions.HandleShipDamageIndicator(enemy, damageData)

	local enemyStartLife = 30 --TODO get this from table of enemies

	local damageIndicatorGui = Instance.new("BillboardGui")
	damageIndicatorGui.AlwaysOnTop = true
	damageIndicatorGui.Size = UDim2.new(1.5, 0, 1.5, 0)

	local offsetX = math.random(-3, 3)
	local offsetY = math.random(0, 5)
	local offsetZ = math.random(-3, 3)
	damageIndicatorGui.StudsOffset = Vector3.new(offsetX, offsetY, offsetZ)

	local damageIndicatorLabel = Instance.new("TextLabel")

	damageIndicatorLabel.Active = true
	damageIndicatorLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	damageIndicatorLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	damageIndicatorLabel.TextScaled = false
	damageIndicatorLabel.BackgroundTransparency = 1
	damageIndicatorLabel.TextStrokeTransparency = 0
	damageIndicatorLabel.Font = Enum.Font.GothamBlack
	damageIndicatorLabel.TextSize = 24 + math.clamp(damageData.HullDamage,1,10)
	damageIndicatorLabel.Text = math.floor(damageData.HullDamage)
	damageIndicatorLabel.Size = UDim2.new(1, 0, 1, 0)
	damageIndicatorLabel.TextColor3 = Color3.fromRGB(255, 196, 101)

	damageIndicatorLabel.Parent = damageIndicatorGui
	damageIndicatorGui.Parent = enemy.root


	local guiUpTween = tweenService:Create(damageIndicatorGui, damageIndicatorTweenInfo, {StudsOffset = damageIndicatorGui.StudsOffset + Vector3.new(0, 40, 0)})

	local textFadeTween = tweenService:Create(damageIndicatorLabel, damageIndicatorTweenInfo, {TextTransparency = 1,TextStrokeTransparency = 1})

	guiUpTween:Play()
	textFadeTween:Play()

	Debris:AddItem(damageIndicatorGui, 5)

end

function enemyFunctions.HandleEnemyDeath(enemy,noCorpse)

	if (enemy.deathHipHeight) then
		enemy.human.HipHeight = enemy.deathHipHeight
	end

	enemy.char:SetAttribute("Dead",true) --enemy.AI.Stop() --Stops enemy logic and switches to death state, playing death animation

	local index = table.find(enemyModule.enemies,enemy)
	table.remove(enemyModule.enemies,index)

	--If this enemy has a self destruct attack do it
	if (enemiesModule[enemy.name].SelfDestruct ~= nil) then
		for i, player in pairs(Players:GetPlayers()) do
			local Character = player.Character or player.CharacterAdded:Wait()
			local torso = Character:FindFirstChild("HumanoidRootPart")
			if torso then
				local distance = (enemy.char.HumanoidRootPart.Position - torso.Position).magnitude
				if distance <= enemiesModule[enemy.name].SelfDestruct.Range then
					PlayerHitEvent:Fire(player,enemiesModule[enemy.name].SelfDestruct.Damage,enemy.name)
				end

			end	
		end
	end

	--Reward XP to those that had a large enough percentage of damage to enemy
	for _,enemyLooter in pairs(enemy.Looters) do
		local percentageOfEnemyDamage = enemyLooter.damage/enemiesModule[enemy.name].Health.main


		if (percentageOfEnemyDamage >= .2) then --20%

			--get player
			if game:GetService("Players"):FindFirstChild(enemyLooter.name) then
				local player = game:GetService("Players"):FindFirstChild(enemyLooter.name)

				if (player ~= nil) then
					ProgressFunctions.AddXPFromKill(player,enemiesModule[enemy.name],percentageOfEnemyDamage)
				end
			end
		end
	end


	--TODO check if this was part of quest

	--Only generate a corpse to loot 20% of the time (but maybe always for bosses and maybe for mini boss too)

	--TODO perhaps handle differently for ships. Add ship wreckage
	if (not noCorpse) and (math.random(1,100) <= 100) then
		local corpse = corpseModule.newCorpse(enemy)
	end


	CollectionService:RemoveTag(enemy.char,enemy.spawnTag)

	-- MUST BE DONE INSIDE DIE HANDLER IN AI enemy.char:Destroy()

	enemy = nil

end

--Used to create new threads easily while avoid spawn()
function spawner(func,...)
	local co = coroutine.wrap(func)
	co(...)
end

--local testdone = false

function enemyFunctions.AddLooter(player, enemy, damage)

	--if(not testdone) then
	--	testdone = true
	--	enemyFunctions.HandleBodyPartHit({Name="TESTPLAYER"}, enemy, nil, nil,50)
	--end	



	-- Check if a looter object with the given playerName already exists
	if enemy.Looters[player.Name] then
		-- If the looter object exists, add the damage to the previous damage value
		enemy.Looters[player.Name].damage = enemy.Looters[player.Name].damage + math.clamp(damage,0,enemy.health.main)

	else
		-- If the looter object does not exist, create a new one
		enemy.Looters[player.Name] = {
			name = player.Name,
			damage = math.clamp(damage,0,enemy.health.main)
		}
	end
end

function enemyFunctions.HandleBodyPartHit(player, enemy, weapon, attack, directDamage, hitPart, critical, criticalName)
	local detatch = false

	--prevent dot damage etc from coming in after death
	if (enemy.health.main <= 0) then
		return
	end	

	--protected is when they are hidden or running home etc.
	if (enemy.protected) then
		return
	end

	local distance = (player.Character.HumanoidRootPart.Position - enemy.char.HumanoidRootPart.Position).magnitude	
	local isMoving = PlayerMovementFunctions.IsPlayerMoving(player)
	local damageData =  CombatFunctions.CalculateDamage(player, weapon, enemy, distance, isMoving, false)-- enemyFunctions.CalculateDamage(player,weapon,attack,directDamage)

	local damage = damageData.HealthDamage
	

	print("TEST DAMAGE distance:",distance," isMoving:",isMoving," Health Damage:",damage, damageData, hitPart, critical, criticalName)

	--TODO handle shield and Armor damage
	
	enemyFunctions.AddLooter(player,enemy,damageData.TotalDamage)	

	local selectedBodyPartIndex = math.random(1,#enemy.bodyParts)
	local selectedBodyPart = enemy.bodyParts[selectedBodyPartIndex]

	if (selectedBodyPart == nil) then
		return
	end

	enemyFunctions.HandleDamageIndicator(enemy, math.floor(damage),selectedBodyPart)

	--Play hit animation if there is one for this enemy
	--Signal hit to AI
	enemy.char:SetAttribute("Hit",true)
	enemy.char:SetAttribute("HitByUserId",player.UserId)
	enemy.char:SetAttribute("HitDamage",damageData.TotalDamage)
	
	--if not enemy.crawling and (enemy.animations["TakeHit"] ~= nil) then
	--	enemyFunctions.StopCurrentAnimations(enemy)

	--	enemy.animations["TakeHit"]:Play()
	--	enemy.animations["TakeHit"].Stopped:Connect(function()
	--		--enemy.animations["BaseAttack"]:Play() --TODO get specific enemy main attack.
	--	end)


	--end

	--Cause Hit Particles
	local damagePercentage = damage / enemiesModule[enemy.name].Health.main
	local numParticles =  math.clamp(math.floor(damagePercentage * 10), 1, 10)

	local body = enemy.char:FindFirstChild("Body")
	if body then
		local hitAttachment = body:FindFirstChild("HitAttachment")
		if (hitAttachment) then
			hitAttachment.Hit:Emit(numParticles)
		else
			body.Hit:Emit(numParticles)
		end

	else
		warn("Missing Body or Hit emitter on enemy:", enemy.id)
	end

	detatch = enemyFunctions.DealBodyPartDamage(enemy, selectedBodyPart, damage)

	--If this is the first hit on an enemy

	if (enemy["BeingAttackedBy"] == nil) then
		enemy["BeingAttackedBy"] = player
	end

	if (enemy.health.main <= 0) then
		task.spawn(function()
			enemyFunctions.HandleEnemyDeath(enemy)
		end)
	end	

	if (not detatch) then
		return
	end

	table.remove(enemy.bodyParts,selectedBodyPartIndex)

	local severedBodyPart

	if (selectedBodyPart.Name == "Head") then
		severedBodyPart = enemy.root.Parent:WaitForChild("Head")
	elseif (selectedBodyPart.Name == "LeftArm") then
		enemy.HasLeftArm = false
		severedBodyPart = enemy.root.Parent:WaitForChild("LeftArm")
	elseif (selectedBodyPart.Name == "RightArm") then
		enemy.HasRightArm = false
		severedBodyPart = enemy.root.Parent:WaitForChild("RightArm")
	elseif (selectedBodyPart.Name == "LeftLeg") then
		enemy.HasLeftLeg = false
		severedBodyPart = enemy.root.Parent:WaitForChild("LeftLeg")
	elseif (selectedBodyPart.Name == "RightLeg") then
		enemy.HasRightLeg = false
		severedBodyPart = enemy.root.Parent:WaitForChild("RightLeg")
	else		
		return
	end


	local bodyPartClone
	local bodyPartClone2
	local bodyPartClone3

	if (severedBodyPart ~=nil) then
		bodyPartClone = severedBodyPart:Clone()
		bodyPartClone.Anchored = false
		bodyPartClone.CanCollide = true
		bodyPartClone.Name = severedBodyPart.Name.."_Detatched"
		severedBodyPart.CanCollide = false
		severedBodyPart.Transparency = 1

		if (bodyPartClone:FindFirstChild("Motor") ~= nil) then
			bodyPartClone.Motor:Destroy()
		end

		if (severedBodyPart.Name == "Head") then
			bodyPartClone.Position = Vector3.new(bodyPartClone.Position.X + 2,bodyPartClone.Position.Y,bodyPartClone.Position.Z)
		end


	else
		return
	end

	bodyPartClone.Parent = workspace

	local startTime = tick()

	local newThread = coroutine.wrap(function()

		while (tick() - startTime) < 5 do
			wait()
		end

		CollectionService:AddTag(bodyPartClone,"DetatchedLimb")
	end)

	newThread()

	--TODO destroy any accessories as well

	Debris:AddItem(bodyPartClone, 30)	

	if (not enemy.HasLeftLeg or not enemy.HasRightLeg) then

		enemy.crawling = true
		enemy.human.HipHeight = 2.2
		enemy.animations["Crawl"].Priority = Enum.AnimationPriority.Action
		enemy.animations["Crawl"]:Play()

	end

	--If the enemy is crawling and just lost his last arm then he is dead
	if (enemy.crawling and not enemy.HasLeftArm and not enemy.HasRightArm) then
		task.spawn(function()
			enemyFunctions.HandleEnemyDeath(enemy)
		end)
	end
end

function enemyFunctions.HandleShipHit(player, enemy, weapon)
	local detatch = false

	--prevent dot damage etc from coming in after ship destroyed
	if (enemy.CurrentHull <= 0) then
		return
	end	

	local distance = (player.Character.HumanoidRootPart.Position - enemy.char.PrimaryPart.Position).magnitude	

	local damageData =  CombatFunctions.CalculateShipDamage(player, weapon, enemy, distance, false)

	if (not damageData) then
		return
	end

	local shieldDamage = damageData.ShieldDamage
	local hullDamage = damageData.HullDamage
	local reactorDamage = damageData.ReactorDamage
	local lifeSupportDamage = damageData.LifeSupportDamage

	print("TEST DAMAGE distance:",distance," Shield Shield Damage:",shieldDamage," Hull Damage:",hullDamage," Hull Damage:",reactorDamage," Life Support Damage:",lifeSupportDamage, damageData)

	--TODO handle shield and Armor damage

	enemyFunctions.AddLooter(player,enemy,damageData.TotalDamage)	

	enemyFunctions.HandleShipDamageIndicator(enemy, damageData)

	--Play hit animation if there is one for this enemy
	--Signal hit to AI
	enemy.char:SetAttribute("Hit",true)
	enemy.char:SetAttribute("HitByUserId",player.UserId)
	enemy.char:SetAttribute("HitDamage",damageData.TotalDamage)

	--Cause Hit Particles
	--local damagePercentage = damage / enemiesModule[enemy.name].Health.main
	--local numParticles =  math.clamp(math.floor(damagePercentage * 10), 1, 10)

	--local body = enemy.char:FindFirstChild("Body")
	--if body then
	--	local hitAttachment = body:FindFirstChild("HitAttachment")
	--	if (hitAttachment) then
	--		hitAttachment.Hit:Emit(numParticles)
	--	else
	--		body.Hit:Emit(numParticles)
	--	end

	--else
	--	warn("Missing Body or Hit emitter on enemy:", enemy.id)
	--end


	--If this is the first hit on an enemy
	if (enemy["BeingAttackedBy"] == nil) then
		enemy["BeingAttackedBy"] = player
	end

	if (enemy.CurrentHull <= 0) then
		task.spawn(function()
			enemyFunctions.HandleEnemyDeath(enemy)
		end)
	end	

end

local function BlastModel(model: Model, hitDir: Vector3, hitPos: Vector3?, strength: number)
	hitDir = hitDir.Unit
	strength = strength or 1

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("WeldConstraint") then
			d.Enabled = false
		elseif d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = true

			-- Base impulse forward + slight upward lift
			local forward = hitDir * (60 * d.AssemblyMass * strength)
			local up = Vector3.new(0, 30 * d.AssemblyMass * strength, 0)

			-- Optional: scale by distance to hit point (closer = stronger)
			local scale = 1
			if hitPos then
				local dist = (d.Position - hitPos).Magnitude
				scale = math.clamp(1.5 - dist / 8, 0.25, 1.5)
			end

			d:ApplyImpulse((forward + up) * scale)

			-- Optional: add spin
			local randomSpin = Vector3.new(
				math.random(-1,1),
				math.random(-1,1),
				math.random(-1,1)
			).Unit
			d:ApplyAngularImpulse(randomSpin * (20 * d.AssemblyMass * strength))
		end
	end
end

function enemyFunctions.HandleEnvironmentalTarget(player,instance,breakableMaterials,hitNormal,hitPos,hitDir)
	if (instance == nil) then
		return
	end

	if (instance:GetAttribute("EnvironmentalTarget")) then

		instance:SetAttribute("EnvironmentalTarget",false)

		if (breakableMaterials) then

			if (not breakableMaterials[instance:GetAttribute("Material")]) then
				return
			end
		end


		if (instance:GetAttribute("Explosive")) then

			local body = instance.Body
			local source = instance.Source
			
			local brokenBody = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Broken"..instance.Name):Clone()

			spawner(function()

				local enemiesSnapshot = enemyFunctions.GetEnemies()

				for _,enm in pairs(enemiesSnapshot) do
					local distance = (enm.root.Position - source.Position).magnitude

					if (distance < 20) then
						enemyFunctions.HandleBodyPartHit(player, enm, nil, nil,instance:GetAttribute("Damage"))
					else
					end
				end
			end)

			source.ExplosionEmitter.Enabled = true
			source.ExplosionEmitter:Emit(1)
			source.ExplosionEmitter.Enabled = false

			body.CanCollide = false
			body.Anchored = true
			body.Transparency = 1

			brokenBody.CFrame = body.CFrame
			brokenBody.CanCollide = true
			brokenBody.Transparency = 0
			brokenBody.Anchored = false
			brokenBody.Parent = instance

			brokenBody.VectorForce.Enabled = true
			wait(.01)
			brokenBody.VectorForce.Enabled = false

			local explosionSound = workspace:WaitForChild("Audio"):WaitForChild(instance.Name.."Explosion")
			explosionSound:Play()

			Debris:AddItem(instance, 10)
		elseif (instance:GetAttribute("Breakable")) then

			local body = instance.Body
			--local source = instance.Source or nil

			local brokenPool = nil
			
			if (instance.Name == "Crate") then
				brokenPool = BrokenCratePool
			elseif (instance.Name == "CrackedFloor") then
				brokenPool = BrokenCrackedFloorPool
			else
				warn("No broken pool for "..instance.Name)
				return
			end

			local brokenBody = brokenPool:Get(instance, body.CFrame)

			task.delay(20, function()
				brokenPool:Return(brokenBody)
			end)

			--if (source) then
			--	source.Emitter.Enabled = true
			--	source.Emitter:Emit(1)
			--	source.Emitter.Enabled = false
			--end

			body.CanCollide = false
			body.Anchored = true
			
			for _,otherPart in pairs(instance:GetChildren()) do
				if (otherPart:IsA("BasePart")) then
					otherPart.Anchored = true
					otherPart.CanCollide = false
				end
			end
			
			if (brokenBody:GetAttribute("SetBrokenCFrame")) then
				brokenBody:SetPrimaryPartCFrame(body.CFrame)
			end
			
			brokenBody.PrimaryPart.Transparency = 0
			body.Transparency = 1

			if (not brokenBody:GetAttribute("BrokenCanCollide")) then
				brokenBody.PrimaryPart.CanCollide = false
			end

			body.Transparency = 1
			body.CanCollide = false
			body.CanQuery = false
			
			if (instance:GetAttribute("HasDecal")) then
				if (body.Texture) then
					body.Texture.Transparency = 1
				end

				if (body.Decal) then
					body.Decal.Decal.Transparency = 1
				end
			end
			
	
			
			--Done in BlastModel.  For melee smash may want this back in or just use blast downward.
			--spawner(function()

			--	for _, d in ipairs(brokenBarrelBody:GetDescendants()) do
			--		if d:IsA("WeldConstraint") then
			--			d.Enabled = false
			--		elseif d:IsA("BasePart") then
			--			d.Anchored = false
			--			d.CanCollide = true
			--		end
			--	end
			--end)
			
			BlastModel(brokenBody, hitDir, hitPos, 1)

			local crateSmashSound = workspace:WaitForChild("Audio"):WaitForChild(instance.Name.."Smash")
			crateSmashSound:Play()

			if (instance:GetAttribute("LootCrate")) then
				--body.SearchCrate.Enabled = true
				local crateProximityPrompt = body:FindFirstChildOfClass("ProximityPrompt")

				if (crateProximityPrompt) then
					crateProximityPrompt.Enabled = true
				end
			end

			Debris:AddItem(instance, 20)

		end
	end
end

return enemyFunctions

