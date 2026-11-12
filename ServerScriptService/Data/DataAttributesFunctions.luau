--Include Attributes like Brains and Oomph and Skills like Combat or Hacking (could be split up but require big effort)

--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--Remote Events
local AttributesChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AttributesChanged")
local UpdateHealthEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateHealth")
local SkillCheckFunctions = require(ReplicatedStorage.SharedFunctions.SkillCheckFunctions)
--Functions

--Definition Modules

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))

local functions = {}

BASE_HEALTH = 50
HEALTH_PER_GRIT = 50
MAX_HEALTH_CAP = 550

--MaxHealth = 100, --MaxHealth  = math.round(math.pow(level/.4,2+(level/50)) )
--MaxStamina = 10,
--MaxSpeed = 1
--Oomph = 1,
--Brains = 1,
--Wits = 1,
--Finesse = 1,
--Vibe = 1,
--Grit = 1,

function functions.Update(player)
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	AttributesChangedEvent:FireClient(player,profile.Data.Attributes)
	player:SetAttribute("Oomph", profile.Data.Attributes.Oomph)
	player:SetAttribute("Brains", profile.Data.Attributes.Brains)
	player:SetAttribute("Wits", profile.Data.Attributes.Wits)
	player:SetAttribute("Finesse", profile.Data.Attributes.Finesse)
	player:SetAttribute("Vibe", profile.Data.Attributes.Vibe)
	player:SetAttribute("Grit", profile.Data.Attributes.Grit)
	

	for _, skillData in pairs(SkillCheckFunctions.Skills) do
		player:SetAttribute(skillData.name, profile.Data.Attributes[skillData.name])
	end
end

function functions.UpdateAttributesFromClient(player,attributes)
	local profile = Data[player]
	if (profile == nil) then return nil end

	--TODO make sure character is not already set

	--TODO make sure that the delta of each attribute does not use more attribute points than are available
	local OomphDelta = attributes.Oomph - profile.Data.Attributes.Oomph

	if (OomphDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:OomphDelta less than zero")
		return
	end

	local BrainsDelta = attributes.Brains - profile.Data.Attributes.Brains

	if (BrainsDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:BrainsDelta less than zero")
		return
	end

	local WitsDelta = attributes.Wits - profile.Data.Attributes.Wits

	if (WitsDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:WitsDelta less than zero")
		return
	end

	local FinesseDelta = attributes.Finesse - profile.Data.Attributes.Finesse

	if (FinesseDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:FinesseDelta less than zero")
		return
	end

	local VibeDelta = attributes.Vibe - profile.Data.Attributes.Vibe

	if (VibeDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:VibeDelta less than zero")
		return
	end

	local GritDelta = attributes.Grit - profile.Data.Attributes.Grit

	if (GritDelta < 0) then
		warn("DataAttributesFunctions.UpdateAttributesFromClient:GritDelta less than zero")
		return
	end

	local totalDelta = (OomphDelta + BrainsDelta + WitsDelta + FinesseDelta + VibeDelta + GritDelta)

	if totalDelta > profile.Data.Attributes.AttributePoints then
		--Do not allow the update of higher numbers than the points remaining
		warn("DataAttributesFunctions.UpdateAttributesFromClient:totalDelta greater than AttributePoints")
		return
	end

	local leftOverAP = (profile.Data.Attributes.AttributePoints - totalDelta)

	if (attributes.AttributePoints ~=  leftOverAP) then
		--attributepoints remaining should be same as what is subtracted from current attribute points
		warn("DataAttributesFunctions.UpdateAttributesFromClient:Client AttributePoints not same as AttributePoints - totalDelta",attributes.AttributePoints,leftOverAP,attributes)
		return
	end

	--If we made it this far then we should be ok to set the various attributes
	profile.Data.Attributes.AttributePoints = attributes.AttributePoints
	profile.Data.Attributes.Strength = attributes.Oomph
	profile.Data.Attributes.Intelligence = attributes.Brains
	profile.Data.Attributes.Wisdom = attributes.Wits
	profile.Data.Attributes.Perception = attributes.Finesse
	profile.Data.Attributes.Charisma = attributes.Vibe
	profile.Data.Attributes.Vitality = attributes.Grit

	functions.Update(player)
end

function functions.SetAttributes(player)
	functions.Update(player)
end

function functions.RecalculateMaxHealth(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local grit = functions.GetGrit(player) or 0
	
	if (grit == 0) then
		return BASE_HEALTH
	end

	local health = BASE_HEALTH + (grit * HEALTH_PER_GRIT)
	health = math.clamp(health, BASE_HEALTH, MAX_HEALTH_CAP)

	Logger.Debug("NEW MAX HEALTH SET TO:"..health)
	functions.SetMaxHealth(player,health)
	
	functions.Update(player)
end

function functions.GetMaxShield(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Attributes.MaxShield
end

function functions.SetMaxShield(player, shield)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.MaxShield = shield

	functions.Update(player)
end

function functions.GetMaxArmor(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Attributes.MaxArmor
end

function functions.SetMaxArmor(player, armor)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.MaxArmor = armor

	functions.Update(player)
end

function functions.GetMaxHealth(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.MaxHealth
end
function functions.SetMaxHealth(player,health)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.MaxHealth = health

	functions.Update(player)
	UpdateHealthEvent:FireClient(player, health , health)
end

function functions.GetMaxStamina(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.MaxStamina
end
function functions.SetMaxStamina(player,stamina)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.MaxStamina = stamina

	functions.Update(player)
end

function functions.GetMaxSpeed(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.MaxSpeed
end
function functions.SetMaxSpeed(player,speed)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.MaxSpeed = speed

	functions.Update(player)
end

function functions.GetOomph(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.Oomph
end
function functions.SetOomph(player,oomph)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Oomph = oomph

	functions.Update(player)
end

function functions.GetBrains(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.Brains
end
function functions.SetBrains(player,brains)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Brains = brains

	functions.Update(player)
end

function functions.GetWits(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.Wits
end
function functions.SetWits(player,wits)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Wits = wits

	functions.Update(player)
end

function functions.GetFinesse(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.Finesse
end
function functions.SetFinesse(player,finesse)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Finesse = finesse

	functions.Update(player)
end

function functions.GetVibe(player)
	local profile = Data[player]
	if (profile == nil) then return 1 end

	return profile.Data.Attributes.Vibe
end
function functions.SetVibe(player,vibe)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Vibe = vibe

	functions.Update(player)
end

function functions.GetGrit(player)
	local profile = Data[player]
	if (profile == nil) then return 1 end

	return profile.Data.Attributes.Grit
end
function functions.SetGrit(player, grit)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.Grit = grit

	functions.RecalculateMaxHealth(player)

	functions.Update(player)
end

function functions.GetAllAttributes(player)
	local profile = Data[player]
	if profile == nil then 
		-- Return empty table or defaults if no profile
		return {}
	end

	return {
		Oomph = profile.Data.Attributes.Oomph or 0,
		Brains = profile.Data.Attributes.Brains or 0,
		Wits = profile.Data.Attributes.Wits or 0,
		Finesse = profile.Data.Attributes.Finesse or 0,
		Grit = profile.Data.Attributes.Grit or 0,
		Vibe = profile.Data.Attributes.Vibe or 0,
	}
end

function functions.GetAttributePoints(player)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	return profile.Data.Attributes.AttributePoints
end
function functions.SetAttributePoints(player,attributePoints)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes.AttributePoints = attributePoints

	functions.Update(player)
end

AttributesChangedEvent.OnServerEvent:Connect(function(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	functions.Update(player)
end)



--------------------SKILLS-----------------------------------
-------------------------------------------------------------
function functions.SetSkill(player,skillName,skillValue)
	local profile = Data[player]
	if (profile == nil) then return nil end

	profile.Data.Attributes[skillName] = skillValue

	functions.Update(player)
end

function functions.GetSkill(player,skillName)
	local profile = Data[player]
	if (profile == nil) then return nil end

	return profile.Data.Attributes[skillName]
end

function functions.GetAllSkills(player)
	local profile = Data[player]
	if profile == nil then 
		-- Return empty table or defaults if no profile
		return {}
	end

	local skills = {}
	for _, skillData in pairs(SkillCheckFunctions.Skills) do
		skills[skillData.name] = profile.Data.Attributes[skillData.name] or 0
	end

	return skills
end

function functions.GetAccuracyBonus(finesse, combatSkill, specializationSkill)
	-- Calculate total skill contribution (using 5:1 ratio)
	-- Base: Finesse attribute provides small bonus
	-- Combat skill provides general weapon proficiency
	-- Specialization provides the biggest bonus
	local attributeContribution = finesse * 0.02  -- 2% per point of Finesse
	local combatContribution = combatSkill * 0.10  -- 10% per Combat skill level
	local specializationContribution = specializationSkill * 0.15  -- 15% per specialization level

	-- Total bonus (additive)
	local totalBonus = 1.0 + attributeContribution + combatContribution + specializationContribution

	return totalBonus
end

function functions.GetAccuracyBonusForPlayer(player, weapon)
	
	local profile = Data[player]
	if (profile == nil) then return nil end

	-- Get relevant attribute (Finesse for ranged combat)
	local finesse = profile.Data.Attributes and profile.Data.Attributes.Finesse or 0

	-- Get general Combat skill (0-4)
	local combatSkill = profile.Data.Attributes and profile.Data.Attributes.Combat or 0

	-- Get weapon specialization (0-4)
	local specializationName = weapon.DamageType .. weapon.WeaponType .. "Combat"
	local specializationSkill = profile.Data.Attributes and profile.Data.Attributes[specializationName] or 0

	return functions.GetAccuracyBonus(finesse, combatSkill, specializationSkill)
end

function functions.GetDamageBonus(finesse, combatSkill, specializationSkill, weapon)
	
	-- Damage bonus is smaller than accuracy bonus
	-- Represents better shot placement, critical hit frequency, etc.
	local attributeContribution = finesse * 0.01  -- 1% per attribute point
	local combatContribution = combatSkill * 0.05  -- 5% per Combat skill level
	local specializationContribution = specializationSkill * 0.08  -- 8% per specialization level
	
	if (combatSkill == 0) then
		combatContribution = combatContribution * .3 --30% penalty for untrained combat
	end
	
	local totalBonus = 1.0 + attributeContribution + combatContribution + specializationContribution

	return totalBonus
end

function functions.GetDamageBonusForPlayer(player, weapon)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local finesse = profile.Data.Attributes and profile.Data.Attributes.Finesse or 0
	
	-- Get skills
	local combatSkill = profile.Data.Attributes and profile.Data.Attributes.Combat or 0
	local specializationName = weapon.DamageType .. weapon.WeaponType .. "Combat"
	local specializationSkill = profile.Data.Attributes and profile.Data.Attributes[specializationName] or 0

	return functions.GetDamageBonus(finesse, combatSkill, specializationSkill, weapon)
end

function functions.GetUntrainedPenalty(combatSkill)

	-- If completely untrained (Combat 0 and Specialization 0)
	if combatSkill == 0 then
		return 0.3  -- 30% accuracy penalty
	end

	-- Has some combat skill, no penalty
	return 1.0
end


function functions.GetUntrainedPenaltyForPlayer(player, weapon)
	local profile = Data[player]
	if (profile == nil) then return .5 end
	
	local combatSkill = profile.Data.Attributes.Combat or 0

	return functions.GetUntrainedPenalty(combatSkill)
end

function functions.GetCriticalChanceBonus(finesse, combatSkill, specializationSkill, weapon)

	-- Crit chance increases with skill mastery
	local finesseBonus = finesse * 0.005  -- 0.5% per Finesse point
	local combatBonus = combatSkill * 0.02  -- 2% per Combat level
	local specializationBonus = specializationSkill * 0.03  -- 3% per specialization level

	return finesseBonus + combatBonus + specializationBonus
end

function functions.GetCriticalChanceBonusForPlayer(player, weapon)
	local profile = Data[player]
	if (profile == nil) then return 0 end

	local finesse = profile.Data.Attributes and profile.Data.Attributes.Finesse or 0
	local combatSkill = profile.Data.Attributes and profile.Data.Attributes.Combat or 0
	local specializationName = weapon.DamageType .. weapon.WeaponType .. "Combat"
	local specializationSkill = profile.Data.Attributes and profile.Data.Attributes[specializationName] or 0

	return functions.GetCriticalChanceBonus(finesse, combatSkill, specializationSkill, weapon)
end

function functions.GetReloadSpeedModifier(player, weapon)
	local profile = Data[player]
	if (profile == nil) then return 1 end

	local finesse = profile.Data.Attributes and profile.Data.Attributes.Finesse or 0
	local combatSkill = profile.Data.Attributes and profile.Data.Attributes.Combat or 0
	local specializationName = weapon.DamageType .. weapon.WeaponType .. "Combat"
	local specializationSkill = profile.Data.Attributes[specializationName] or 0

	-- Faster reloads with higher skill
	local speedBonus = finesse * 0.01 + combatSkill * 0.05 + specializationSkill * 0.08

	-- Convert bonus to speed multiplier (more skill = lower reload time)
	return 1.0 / (1.0 + speedBonus)
end

function functions.GetDrawSpeedModifier(player, weapon)
	local profile = Data[player]
	if (profile == nil) then return 1.0 end

	local finesse = profile.Data.Attributes and profile.Data.Attributes.Finesse or 0
	local combatSkill = profile.Data.Attributes and profile.Data.Attributes.Combat or 0

	-- Draw speed mostly from general combat proficiency
	local speedBonus = finesse * 0.015 + combatSkill * 0.08

	return 1.0 / (1.0 + speedBonus)
end

return functions