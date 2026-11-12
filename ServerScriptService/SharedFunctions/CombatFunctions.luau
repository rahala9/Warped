--Roblox Services
local ServerScriptService = game:GetService("ServerScriptService")

--Remote Events

--Functions
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)

--Definition Modules
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))

--Assets

--Modules

local CombatFunctions = {}

-- ========================================
-- DEBUG LOGGING
-- ========================================

-- Set to true to enable detailed combat logging
CombatFunctions.DEBUG_ENABLED = true

-- Debug print function - only prints when DEBUG_ENABLED is true
local function dprint(...)
	if CombatFunctions.DEBUG_ENABLED then
		print("[COMBAT DEBUG]", ...)
	end
end

-- ========================================
-- WEAPON TYPE DATA
-- ========================================
CombatFunctions.WeaponTypes = {
	Pistol = {
		FireRate = 5, -- RPS
		DrawTimeModifier = 1.5,
		MobileAccuracyModifier = 0.9,
		Capacity = 10,
		RangeAccuracyModifier = 1.0,
		CritDamageModifier = 2.0
	},
	Rifle = {
		FireRate = 8,
		DrawTimeModifier = 0.8,
		MobileAccuracyModifier = 0.5,
		Capacity = 20,
		RangeAccuracyModifier = 1.3,
		CritDamageModifier = 2.0
	},
	Sniper = {
		FireRate = 1,
		DrawTimeModifier = 0.1,
		MobileAccuracyModifier = 0.1,
		Capacity = 20,
		RangeAccuracyModifier = 2.0,
		CritDamageModifier = 3.0
	},
	Thrown = {
		FireRate = 1,
		DrawTimeModifier = 0,
		MobileAccuracyModifier = 0,
		Capacity = 1,
		RangeAccuracyModifier = 0.8,
		CritDamageModifier = 0
	},
	ShipLaserCannon = {
		FireRate = 1,
		DrawTimeModifier = 0,
		MobileAccuracyModifier = 1,
		Capacity = 100,
		RangeAccuracyModifier = 1,
		CritDamageModifier = 2.0
	}
	
	
}

-- ========================================
-- DAMAGE TYPE DATA
-- ========================================
CombatFunctions.DamageTypes = {
	Kinetic = {
		ShieldModifier = 0.7,
		ArmorModifier = 1.0,
		ArmorPenetration = 0, -- No armor bypass
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 1.3,
		AccuracyModifier = 0.8,
		Recoil = true,
		AOE = false,
		Piercing = true,
		ChainedTargets = false,
		ShieldOverflow = 0.20, -- 20%
		Effects = {
			Bleed = true,
			Heat = false,
			Stun = false,
			Knockback = true,
			SlowMovement = false
		}
	},
	Laser = {
		ShieldModifier = 1.0,
		ArmorModifier = 1.0,
		ArmorPenetration = 0, -- No armor bypass
		CriticalChanceModifier = 1.3,
		KnockbackChanceModifier = 1.0,
		AccuracyModifier = 1.3,
		Recoil = false,
		AOE = false,
		Piercing = false,
		ChainedTargets = false,
		ShieldOverflow = 0,
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = false,
			Knockback = false,
			SlowMovement = false
		}
	},
	Plasma = {
		ShieldModifier = 0.8,
		ArmorModifier = 1.2, -- Better vs armor
		ArmorPenetration = 0.05, -- 5% bypasses armor entirely
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 1.0,
		AccuracyModifier = 0.7,
		Recoil = false,
		AOE = true,
		Piercing = false,
		ChainedTargets = true,
		ShieldOverflow = 0,
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = false,
			Knockback = false,
			SlowMovement = false
		}
	},
	Electric = {
		ShieldModifier = 0.8,
		ArmorModifier = 1.0,
		ArmorPenetration = 0, -- No armor bypass
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 1.0,
		AccuracyModifier = 0.7,
		Recoil = false,
		AOE = false,
		Piercing = false,
		ChainedTargets = true,
		ShieldOverflow = true, -- % equal to % of shield
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = true,
			Knockback = false,
			SlowMovement = false
		}
	},
	ParticleBeam = {
		ShieldModifier = 1.2,
		ArmorModifier = 0.7, -- Weak vs armor normally
		ArmorPenetration = 0.20, -- But 20% bypasses armor entirely
		CriticalChanceModifier = 1.1,
		KnockbackChanceModifier = 0.0,
		AccuracyModifier = 1.3,
		Recoil = false,
		AOE = false,
		Piercing = true,
		ChainedTargets = false,
		ShieldOverflow = 0.20,
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = false,
			Knockback = false,
			SlowMovement = false,
			Radiation = true
		}
	},
	Explosive = {
		ShieldModifier = 1.5,
		ArmorModifier = 0.8, -- Weak vs armor normally
		ArmorPenetration = 0.15, -- But 15% bypasses armor
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 2.0,
		AccuracyModifier = 1.0,
		Recoil = false,
		AOE = true,
		Piercing = false,
		ChainedTargets = false,
		ShieldOverflow = 0,
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = false,
			Knockback = true,
			SlowMovement = false
		}
	},
	Thermal = {
		ShieldModifier = 0.7,
		ArmorModifier = 1.3, -- Strong vs armor
		ArmorPenetration = 0.10, -- 10% bypasses armor
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 1.0,
		AccuracyModifier = 0.5,
		Recoil = false,
		AOE = true,
		Piercing = false,
		ChainedTargets = false,
		ShieldOverflow = 0,
		Effects = {
			Bleed = false,
			Heat = true,
			Stun = false,
			Knockback = false,
			SlowMovement = false
		}
	},
	Cryo = {
		ShieldModifier = 1.3,
		ArmorModifier = 0.8,
		ArmorPenetration = 0, -- No armor bypass
		CriticalChanceModifier = 1.0,
		KnockbackChanceModifier = 1.0,
		AccuracyModifier = 0.5,
		Recoil = false,
		AOE = true,
		Piercing = false,
		ChainedTargets = false,
		ShieldOverflow = 0,
		Effects = {
			Bleed = false,
			Heat = false,
			Stun = false,
			Knockback = false,
			SlowMovement = true,
			Frozen = 0.10,
			Shatter = true
		}
	}
}

-- ========================================
-- DAMAGE CALCULATION
-- ========================================

--[[
	Calculate damage dealt to a target
	@param player - Player object (for skills/attributes)
	@param weapon - Table with WeaponType, DamageType, BaseDamage, Tier
	@param target - Table with CurrentShield, MaxShield, CurrentArmor, MaxArmor, CurrentHealth, MaxHealth, StatusEffects
	@param distance - Distance to target (optional, for range calculations)
	@param isMoving - Whether shooter is moving (optional, for accuracy)
	@param isCritical - Whether this is a critical hit (optional, can be calculated)
	@return damageResult - Table with detailed breakdown of damage dealt
]]
function CombatFunctions.CalculateDamage(attacker, weapon, target, distance, isMoving, isCritical)
	dprint("========================================")
	dprint("DAMAGE CALCULATION START")
	dprint("========================================")
	dprint(string.format("Weapon: %s %s (Tier %d)", weapon.DamageType, weapon.WeaponType, weapon.Tier))
	dprint(string.format("Base Damage: %.2f", weapon.BaseDamage))

	local weaponData = CombatFunctions.WeaponTypes[weapon.WeaponType]
	local damageData = CombatFunctions.DamageTypes[weapon.DamageType]

	if not weaponData or not damageData then
		warn("Invalid weapon or damage type")
		return nil
	end

	local result = {
		TotalDamage = 0,
		ShieldDamage = 0,
		ArmorMitigation = 0,
		HealthDamage = 0,
		IsCritical = false,
		AppliedEffects = {},
		PiercedTargets = {},
		ChainedTargets = {},
		SkillBonuses = {} -- Track what bonuses were applied
	}

	dprint("\n--- TARGET STATUS ---")
	dprint(string.format("Shield: %.2f / %.2f", target.CurrentShield or 0, target.MaxShield or 0))
	dprint(string.format("Armor Rating: %.2f%% reduction", (target.ArmorRating or 0) * 100))
	dprint(string.format("Health: %.2f / %.2f", target.CurrentHealth or 0, target.MaxHealth or 0))

	-- Apply skill bonuses if playerStats provided
	dprint("\n--- SKILL BONUSES ---")
	local damageMultiplier = 1.0
	local critChanceBonus = 0

	if (attacker:IsA("Player")) then
		damageMultiplier = AttributesFunctions.GetDamageBonusForPlayer(attacker, weapon)
		critChanceBonus = AttributesFunctions.GetCriticalChanceBonusForPlayer(attacker, weapon)
	else
		local enemy = enemiesModule[attacker.Name]
		damageMultiplier = AttributesFunctions.GetDamageBonus(enemy.Attributes.Finesse or 0,enemy.Attributes.Combat or 0,enemy.Attributes[weapon.DamageType .. weapon.WeaponType .. "Combat"] or 0, weapon)
		critChanceBonus = AttributesFunctions.GetCriticalChanceBonus(enemy.Attributes.Finesse or 0,enemy.Attributes.Combat or 0,enemy.Attributes[weapon.DamageType .. weapon.WeaponType .. "Combat"] or 0, weapon)
	end

	dprint(string.format("Damage Multiplier: %.2fx (%.0f%% bonus)", damageMultiplier, (damageMultiplier - 1) * 100))
	dprint(string.format("Crit Chance Bonus: +%.1f%%", critChanceBonus * 100))

	result.SkillBonuses.DamageMultiplier = damageMultiplier
	result.SkillBonuses.CritChanceBonus = critChanceBonus

	-- Determine if critical hit
	dprint("\n--- CRITICAL HIT CHECK ---")
	if not isCritical then
		local baseCritChance = 0.1 -- 10% base crit chance
		local modifiedCritChance = (baseCritChance + critChanceBonus) * damageData.CriticalChanceModifier
		dprint(string.format("Base Crit Chance: %.1f%%", baseCritChance * 100))
		dprint(string.format("Modified Crit Chance: %.1f%% (with %.2fx modifier)", modifiedCritChance * 100, damageData.CriticalChanceModifier))
		local roll = math.random()
		isCritical = roll < modifiedCritChance
		dprint(string.format("Critical Hit: %s (roll: %.3f vs %.3f)", isCritical and "YES" or "NO", roll, modifiedCritChance))
	else
		dprint("Critical Hit (forced): YES")
	end
	result.IsCritical = isCritical

	-- Check for shatter bonus (Cryo frozen targets)
	local shatterBonus = 1.0
	if target.StatusEffects and target.StatusEffects.Frozen and damageData.Effects.Shatter then
		shatterBonus = 2.0 -- +100% crit damage on frozen targets
		dprint("SHATTER BONUS ACTIVE: +100% crit damage on frozen target!")
	end

	-- Calculate base damage with critical modifier and skill bonuses
	dprint("\n--- DAMAGE CALCULATION ---")
	local baseDamage = weapon.BaseDamage * damageMultiplier
	dprint(string.format("Base Damage × Skill Multiplier: %.2f × %.2f = %.2f", weapon.BaseDamage, damageMultiplier, baseDamage))

	if isCritical then
		local critMult = weaponData.CritDamageModifier * shatterBonus
		dprint(string.format("Critical Multiplier: %.2fx × %.2fx (shatter) = %.2fx", weaponData.CritDamageModifier, shatterBonus, critMult))
		baseDamage = baseDamage * critMult
		dprint(string.format("Critical Damage: %.2f", baseDamage))
	end

	-- Apply damage to shields first
	dprint("\n--- SHIELD DAMAGE PHASE ---")
	local remainingDamage = baseDamage or 0
	if target.CurrentShield and target.CurrentShield > 0 then
		local shieldDamage = remainingDamage * damageData.ShieldModifier
		dprint(string.format("Shield Modifier: %.2fx", damageData.ShieldModifier))
		dprint(string.format("Shield Damage: %.2f × %.2f = %.2f", remainingDamage, damageData.ShieldModifier, shieldDamage))

		local actualShieldDamage = math.min(shieldDamage, target.CurrentShield)
		dprint(string.format("Actual Shield Damage: %.2f (capped by current shield %.2f)", actualShieldDamage, target.CurrentShield))

		result.ShieldDamage = actualShieldDamage
		target.CurrentShield = target.CurrentShield - actualShieldDamage
		dprint(string.format("Remaining Shield: %.2f", target.CurrentShield))

		-- Calculate shield overflow
		local overflowAmount = shieldDamage - actualShieldDamage
		if overflowAmount > 0 then
			dprint(string.format("Overflow Amount: %.2f", overflowAmount))

			if damageData.ShieldOverflow == true then
				-- Electric: overflow % equals % of shield penetrated
				local shieldPenetrationPercent = actualShieldDamage / target.MaxShield
				remainingDamage = overflowAmount * shieldPenetrationPercent
				dprint(string.format("Electric Overflow: %.2f × %.2f%% penetration = %.2f", overflowAmount, shieldPenetrationPercent * 100, remainingDamage))
			elseif type(damageData.ShieldOverflow) == "number" and damageData.ShieldOverflow > 0 then
				-- Fixed percentage overflow (Kinetic, Particle Beam)
				remainingDamage = overflowAmount * damageData.ShieldOverflow
				dprint(string.format("Fixed Overflow: %.2f × %.0f%% = %.2f", overflowAmount, damageData.ShieldOverflow * 100, remainingDamage))
			else
				remainingDamage = 0
				dprint("No overflow - shields absorbed all damage")
			end
		else
			remainingDamage = 0
			dprint("Shields not broken - no overflow")
		end
	else
		dprint("No shields - damage continues to armor phase")
	end
	dprint(string.format("Damage continuing to armor phase: %.2f", remainingDamage))

	-- Apply armor mitigation (% reduction, not depletable)
	dprint("\n--- ARMOR MITIGATION PHASE ---")
	if remainingDamage > 0 then
		local armorRating = target.ArmorRating or 0 -- 0.0 to 0.75 (0% to 75% reduction)
		dprint(string.format("Base Armor Rating: %.2f%% reduction", armorRating * 100))

		-- Calculate effective armor against this damage type
		local armorEffectiveness = armorRating / damageData.ArmorModifier
		armorEffectiveness = math.clamp(armorEffectiveness, 0, 0.75) -- Cap at 75% max reduction
		dprint(string.format("Armor Modifier: %.2fx (higher = better vs armor)", damageData.ArmorModifier))
		dprint(string.format("Effective Armor: %.2f%% reduction", armorEffectiveness * 100))

		-- Apply armor penetration (some damage bypasses armor entirely)
		local penetration = damageData.ArmorPenetration or 0
		local penetratedDamage = remainingDamage * penetration
		local mitigatedDamage = remainingDamage * (1 - penetration)

		if penetration > 0 then
			dprint(string.format("Armor Penetration: %.0f%% bypasses armor", penetration * 100))
			dprint(string.format("Penetrated Damage: %.2f (bypasses armor)", penetratedDamage))
			dprint(string.format("Mitigatable Damage: %.2f (subject to armor)", mitigatedDamage))
		end

		-- Apply armor reduction to non-penetrated portion
		local damageReduced = mitigatedDamage * armorEffectiveness
		local damageAfterArmor = mitigatedDamage - damageReduced

		result.ArmorMitigation = damageReduced
		dprint(string.format("Armor Mitigated: %.2f damage", damageReduced))
		dprint(string.format("Damage After Armor: %.2f", damageAfterArmor))

		-- Total damage to health = penetrated + what got through armor
		remainingDamage = penetratedDamage + damageAfterArmor
		dprint(string.format("Total to Health: %.2f (penetrated) + %.2f (through armor) = %.2f", 
			penetratedDamage, damageAfterArmor, remainingDamage))
	else
		dprint("No damage reached armor phase")
	end

	-- Apply remaining damage to health
	dprint("\n--- HEALTH DAMAGE PHASE ---")
	if remainingDamage > 0 then
		result.HealthDamage = math.min(remainingDamage, target.CurrentHealth)
		target.CurrentHealth = target.CurrentHealth - result.HealthDamage
		dprint(string.format("Health Damage: %.2f", result.HealthDamage))
		dprint(string.format("Remaining Health: %.2f", target.CurrentHealth))

		if target.CurrentHealth <= 0 then
			dprint("*** TARGET KILLED ***")
		end
	else
		dprint("No damage reached health")
	end

	-- Apply status effects
	CombatFunctions.ApplyEffects(weapon, target, damageData, result)

	-- Calculate total damage dealt
	result.TotalDamage = result.ShieldDamage + result.HealthDamage

	dprint("\n--- DAMAGE SUMMARY ---")
	dprint(string.format("Shield Damage: %.2f", result.ShieldDamage))
	dprint(string.format("Armor Mitigated: %.2f", result.ArmorMitigation))
	dprint(string.format("Health Damage: %.2f", result.HealthDamage))
	dprint(string.format("TOTAL DAMAGE DEALT: %.2f", result.TotalDamage))
	if #result.AppliedEffects > 0 then
		dprint(string.format("Applied Effects: %s", table.concat(result.AppliedEffects, ", ")))
	end
	dprint("========================================\n")

	return result
end

---[[
--	Calculate damage dealt to a target
--	@param player - Player object (for skills/attributes)
--	@param weapon - Table with WeaponType, DamageType, BaseDamage, Tier
--	@param target - Table with CurrentShield, MaxShield, CurrentHull, MaxHull, CurrentReactor, MaxReactor, CurrentLifeSupport, MaxLifeSupport, StatusEffects
--	@param distance - Distance to target (optional, for range calculations)
--	@param isCritical - Whether this is a critical hit (optional, can be calculated)
--	@return damageResult - Table with detailed breakdown of damage dealt
--]]
function CombatFunctions.CalculateShipDamage(attacker, weapon, target, distance, isMoving, isCritical)
	dprint("========================================")
	dprint("DAMAGE CALCULATION START")
	dprint("========================================")
	dprint(string.format("Weapon: %s %s (Tier %d)", weapon.DamageType, weapon.WeaponType, weapon.Tier))
	dprint(string.format("Base Damage: %.2f", weapon.BaseDamage))

	local weaponData = CombatFunctions.WeaponTypes[weapon.WeaponType]
	local damageData = CombatFunctions.DamageTypes[weapon.DamageType]

	if not weaponData or not damageData then
		warn("Invalid weapon or damage type")
		return nil
	end

	local result = {
		TotalDamage = 0,
		ShieldDamage = 0,
		HullDamage = 0,
		ReactorDamage = 0,
		LifeSupportDamage = 0,
		ArmorMitigation = 0,
		IsCritical = false,
		AppliedEffects = {},
		PiercedTargets = {},
		ChainedTargets = {},
		SkillBonuses = {} -- Track what bonuses were applied
	}

	dprint("\n--- TARGET STATUS ---")
	dprint(string.format("Shield: %.2f / %.2f", target.CurrentShield or 0, target.MaxShield or 0))
	dprint(string.format("Hull: %.2f / %.2f", target.CurrentHull or 0, target.MaxHull or 0))
	dprint(string.format("Reactor: %.2f / %.2f", target.CurrentReactor or 0, target.MaxReactor or 0))
	dprint(string.format("LifeSupport: %.2f / %.2f", target.CurrentLifeSupport or 0, target.MaxLifeSupport or 0))
	dprint(string.format("Armor Rating: %.2f%% reduction", (target.ArmorRating or 0) * 100))

	-- Apply skill bonuses if playerStats provided
	dprint("\n--- SKILL BONUSES ---")
	local damageMultiplier = 1.0
	local critChanceBonus = 0

	if (attacker:IsA("Player")) then
		damageMultiplier = AttributesFunctions.GetDamageBonusForPlayer(attacker, weapon)
		critChanceBonus = AttributesFunctions.GetCriticalChanceBonusForPlayer(attacker, weapon)
	else
		local enemy = enemiesModule[attacker.Name]
		damageMultiplier = AttributesFunctions.GetDamageBonus(enemy.Attributes.Finesse or 0,enemy.Attributes.Combat or 0,enemy.Attributes[weapon.DamageType .. weapon.WeaponType .. "Combat"] or 0, weapon)
		critChanceBonus = AttributesFunctions.GetCriticalChanceBonus(enemy.Attributes.Finesse or 0,enemy.Attributes.Combat or 0,enemy.Attributes[weapon.DamageType .. weapon.WeaponType .. "Combat"] or 0, weapon)
	end

	dprint(string.format("Damage Multiplier: %.2fx (%.0f%% bonus)", damageMultiplier, (damageMultiplier - 1) * 100))
	dprint(string.format("Crit Chance Bonus: +%.1f%%", critChanceBonus * 100))

	result.SkillBonuses.DamageMultiplier = damageMultiplier
	result.SkillBonuses.CritChanceBonus = critChanceBonus

	-- Determine if critical hit
	dprint("\n--- CRITICAL HIT CHECK ---")
	if not isCritical then
		local baseCritChance = 0.1 -- 10% base crit chance
		local modifiedCritChance = (baseCritChance + critChanceBonus) * damageData.CriticalChanceModifier
		dprint(string.format("Base Crit Chance: %.1f%%", baseCritChance * 100))
		dprint(string.format("Modified Crit Chance: %.1f%% (with %.2fx modifier)", modifiedCritChance * 100, damageData.CriticalChanceModifier))
		local roll = math.random()
		isCritical = roll < modifiedCritChance
		dprint(string.format("Critical Hit: %s (roll: %.3f vs %.3f)", isCritical and "YES" or "NO", roll, modifiedCritChance))
	else
		dprint("Critical Hit (forced): YES")
	end
	result.IsCritical = isCritical

	-- Calculate base damage with critical modifier and skill bonuses
	dprint("\n--- DAMAGE CALCULATION ---")
	local baseDamage = weapon.BaseDamage * damageMultiplier
	dprint(string.format("Base Damage × Skill Multiplier: %.2f × %.2f = %.2f", weapon.BaseDamage, damageMultiplier, baseDamage))

	if isCritical then
		local critMult = weaponData.CritDamageModifier
		dprint(string.format("Critical Multiplier: %.2fx × %.2fx", weaponData.CritDamageModifier, critMult))
		baseDamage = baseDamage * critMult
		dprint(string.format("Critical Damage: %.2f", baseDamage))
	end

	-- Apply damage to shields first
	dprint("\n--- SHIELD DAMAGE PHASE ---")
	local remainingDamage = baseDamage or 0
	if target.CurrentShield and target.CurrentShield > 0 then
		local shieldDamage = remainingDamage * damageData.ShieldModifier
		dprint(string.format("Shield Modifier: %.2fx", damageData.ShieldModifier))
		dprint(string.format("Shield Damage: %.2f × %.2f = %.2f", remainingDamage, damageData.ShieldModifier, shieldDamage))

		local actualShieldDamage = math.min(shieldDamage, target.CurrentShield)
		dprint(string.format("Actual Shield Damage: %.2f (capped by current shield %.2f)", actualShieldDamage, target.CurrentShield))

		result.ShieldDamage = actualShieldDamage
		target.CurrentShield = target.CurrentShield - actualShieldDamage
		dprint(string.format("Remaining Shield: %.2f", target.CurrentShield))

		-- Calculate shield overflow
		local overflowAmount = shieldDamage - actualShieldDamage
		if overflowAmount > 0 then
			dprint(string.format("Overflow Amount: %.2f", overflowAmount))

			if damageData.ShieldOverflow == true then
				-- Electric: overflow % equals % of shield penetrated
				local shieldPenetrationPercent = actualShieldDamage / target.MaxShield
				remainingDamage = overflowAmount * shieldPenetrationPercent
				dprint(string.format("Electric Overflow: %.2f × %.2f%% penetration = %.2f", overflowAmount, shieldPenetrationPercent * 100, remainingDamage))
			elseif type(damageData.ShieldOverflow) == "number" and damageData.ShieldOverflow > 0 then
				-- Fixed percentage overflow (Kinetic, Particle Beam)
				remainingDamage = overflowAmount * damageData.ShieldOverflow
				dprint(string.format("Fixed Overflow: %.2f × %.0f%% = %.2f", overflowAmount, damageData.ShieldOverflow * 100, remainingDamage))
			else
				remainingDamage = 0
				dprint("No overflow - shields absorbed all damage")
			end
		else
			remainingDamage = 0
			dprint("Shields not broken - no overflow")
		end
	else
		dprint("No shields - damage continues to armor phase")
	end
	dprint(string.format("Damage continuing to armor phase: %.2f", remainingDamage))

	---- Apply armor mitigation (% reduction, not depletable)
	--dprint("\n--- ARMOR MITIGATION PHASE ---")
	--if remainingDamage > 0 then
	--	local armorRating = target.ArmorRating or 0 -- 0.0 to 0.75 (0% to 75% reduction)
	--	dprint(string.format("Base Armor Rating: %.2f%% reduction", armorRating * 100))

	--	-- Calculate effective armor against this damage type
	--	local armorEffectiveness = armorRating / damageData.ArmorModifier
	--	armorEffectiveness = math.clamp(armorEffectiveness, 0, 0.75) -- Cap at 75% max reduction
	--	dprint(string.format("Armor Modifier: %.2fx (higher = better vs armor)", damageData.ArmorModifier))
	--	dprint(string.format("Effective Armor: %.2f%% reduction", armorEffectiveness * 100))

	--	-- Apply armor penetration (some damage bypasses armor entirely)
	--	local penetration = damageData.ArmorPenetration or 0
	--	local penetratedDamage = remainingDamage * penetration
	--	local mitigatedDamage = remainingDamage * (1 - penetration)

	--	if penetration > 0 then
	--		dprint(string.format("Armor Penetration: %.0f%% bypasses armor", penetration * 100))
	--		dprint(string.format("Penetrated Damage: %.2f (bypasses armor)", penetratedDamage))
	--		dprint(string.format("Mitigatable Damage: %.2f (subject to armor)", mitigatedDamage))
	--	end

	--	-- Apply armor reduction to non-penetrated portion
	--	local damageReduced = mitigatedDamage * armorEffectiveness
	--	local damageAfterArmor = mitigatedDamage - damageReduced

	--	result.ArmorMitigation = damageReduced
	--	dprint(string.format("Armor Mitigated: %.2f damage", damageReduced))
	--	dprint(string.format("Damage After Armor: %.2f", damageAfterArmor))

	--	-- Total damage to health = penetrated + what got through armor
	--	remainingDamage = penetratedDamage + damageAfterArmor
	--	dprint(string.format("Total to Health: %.2f (penetrated) + %.2f (through armor) = %.2f", 
	--		penetratedDamage, damageAfterArmor, remainingDamage))
	--else
	--	dprint("No damage reached armor phase")
	--end

	-- Apply remaining damage to health
	dprint("\n--- HEALTH DAMAGE PHASE ---")
	if remainingDamage > 0 then
		result.HullDamage = math.min(remainingDamage, target.CurrentHull)
		target.CurrentHull = target.CurrentHull - result.HullDamage
		dprint(string.format("Hull Damage: %.2f", result.HullDamage))
		dprint(string.format("Remaining Hull: %.2f", target.CurrentHull))

		if target.CurrentHull <= 0 then
			dprint("*** TARGET DESTROYED ***")
		end
	else
		dprint("No damage reached hull")
	end

	-- Apply status effects
	CombatFunctions.ApplyEffects(weapon, target, damageData, result)

	-- Calculate total damage dealt
	result.TotalDamage = result.ShieldDamage + result.HullDamage + result.ReactorDamage + result.LifeSupportDamage

	dprint("\n--- DAMAGE SUMMARY ---")
	dprint(string.format("Shield Damage: %.2f", result.ShieldDamage))
	--dprint(string.format("Armor Mitigated: %.2f", result.ArmorMitigation))
	dprint(string.format("Hull Damage: %.2f", result.HullDamage))
	dprint(string.format("Reactor Damage: %.2f", result.ReactorDamage))
	dprint(string.format("Life Support Damage: %.2f", result.LifeSupportDamage))
	dprint(string.format("TOTAL DAMAGE DEALT: %.2f", result.TotalDamage))
	if #result.AppliedEffects > 0 then
		dprint(string.format("Applied Effects: %s", table.concat(result.AppliedEffects, ", ")))
	end
	dprint("========================================\n")

	return result
end

-- ========================================
-- STATUS EFFECTS
-- ========================================

function CombatFunctions.ApplyEffects(weapon, target, damageData, result)
	if not target.StatusEffects then
		target.StatusEffects = {}
	end

	dprint("\n--- STATUS EFFECTS CHECK ---")
	local effects = damageData.Effects

	-- Bleed (Kinetic) - only when shields and armor are penetrated
	if effects.Bleed and target.CurrentShield == 0 and target.CurrentArmor == 0 then
		table.insert(result.AppliedEffects, "Bleed")
		target.StatusEffects.Bleed = {
			Duration = 5, -- 5 seconds
			DamagePerTick = weapon.BaseDamage * 0.05, -- 5% of base damage per tick
			TickRate = 1 -- 1 second per tick
		}
		dprint(string.format("Applied BLEED: %.2f damage/sec for 5 seconds", target.StatusEffects.Bleed.DamagePerTick))
	end

	-- Heat DOT (Thermal)
	if effects.Heat then
		table.insert(result.AppliedEffects, "Heat")
		target.StatusEffects.Heat = {
			Duration = 6,
			DamagePerTick = weapon.BaseDamage * 0.08,
			TickRate = 1
		}
		dprint(string.format("Applied HEAT: %.2f damage/sec for 6 seconds", target.StatusEffects.Heat.DamagePerTick))
	end

	-- Radiation DOT (Particle Beam) - bypasses shields/armor
	if effects.Radiation then
		table.insert(result.AppliedEffects, "Radiation")
		target.StatusEffects.Radiation = {
			Duration = 8,
			DamagePerTick = weapon.BaseDamage * 0.06,
			TickRate = 1,
			BypassesDefenses = true
		}
		dprint(string.format("Applied RADIATION: %.2f damage/sec for 8 seconds (bypasses defenses)", target.StatusEffects.Radiation.DamagePerTick))
	end

	-- Stun (Electric)
	if effects.Stun then
		local duration = 1 + (weapon.Tier * 0.2)
		table.insert(result.AppliedEffects, "Stun")
		target.StatusEffects.Stun = {
			Duration = duration,
			MovementReduction = 0 -- No movement, medium downtime
		}
		dprint(string.format("Applied STUN: %.1f seconds", duration))
	end

	-- Knockback (Kinetic, Explosive)
	if effects.Knockback then
		local knockbackChance = 0.3 * damageData.KnockbackChanceModifier -- 30% base chance
		dprint(string.format("Knockback chance: %.0f%%", knockbackChance * 100))
		if math.random() < knockbackChance then
			table.insert(result.AppliedEffects, "Knockback")
			target.StatusEffects.Knockback = {
				Force = 50 * damageData.KnockbackChanceModifier,
				Duration = 0.5 + (weapon.Tier * 0.1) -- Small downtime based on tier
			}
			dprint(string.format("Applied KNOCKBACK: Force %.1f", target.StatusEffects.Knockback.Force))
		else
			dprint("Knockback roll failed")
		end
	end

	-- Slow Movement (Cryo)
	if effects.SlowMovement then
		table.insert(result.AppliedEffects, "Slow")
		target.StatusEffects.Slow = {
			Duration = 3,
			MovementReduction = 0.5 -- 50% movement speed reduction
		}
		dprint("Applied SLOW: 50% speed reduction for 3 seconds")
	end

	-- Frozen (Cryo)
	if effects.Frozen then
		dprint(string.format("Freeze chance: %.0f%%", effects.Frozen * 100))
		if math.random() < effects.Frozen then -- 10% chance
			table.insert(result.AppliedEffects, "Frozen")
			target.StatusEffects.Frozen = {
				Duration = 2,
				MovementReduction = 1.0, -- 100% immobilized
				VulnerableToCrit = true
			}
			dprint("Applied FROZEN: Immobilized for 2 seconds, vulnerable to shatter")
		else
			dprint("Freeze roll failed")
		end
	end

	if #result.AppliedEffects == 0 then
		dprint("No status effects applied")
	end
end

-- ========================================
-- ACCURACY CALCULATION
-- ========================================

--[[
	Calculate spread angles based on weapon accuracy
	Returns min and max spread angles in degrees for use with firing system
	Higher accuracy = tighter spread (smaller angles)
	
	@param player - Player object (for skills/attributes)
	@param weapon - Weapon config table
	@param distance - Distance to target in studs
	@param isMoving - Boolean OR MovementState table from MovementHelper.GetMovementState()
]]
function CombatFunctions.CalculateSpreadAngles(attacker, weapon, distance, isMoving)
	dprint("========================================")
	dprint("SPREAD ANGLE CALCULATION")
	dprint("========================================")
	dprint(string.format("Weapon: %s %s", weapon.DamageType, weapon.WeaponType))
	dprint(string.format("Distance: %.1f studs", distance))

	local weaponData = CombatFunctions.WeaponTypes[weapon.WeaponType]
	local damageData = CombatFunctions.DamageTypes[weapon.DamageType]

	-- Base spread angles (in degrees) - these are your MIN/MAX defaults
	local baseMinSpread = 0.1
	local baseMaxSpread = 2.0
	dprint(string.format("Base spread range: %.3f° - %.3f°", baseMinSpread, baseMaxSpread))

	-- Start with base accuracy
	local accuracyFactor = 1.0
	dprint("\n--- ACCURACY FACTORS ---")

	local skillBonus = 0
	local untrainedPenalty = 1.0 -- Default 100% penalty

	if (attacker:IsA("Player")) then
		skillBonus = AttributesFunctions.GetAccuracyBonusForPlayer(attacker, weapon)
		untrainedPenalty = AttributesFunctions.GetUntrainedPenaltyForPlayer(attacker, weapon)
	else
		local enemy = enemiesModule[attacker.Name]
		skillBonus = AttributesFunctions.GetAccuracyBonus(enemy.Attributes.Finesse or 0,enemy.Attributes.Combat or 0,enemy.Attributes[weapon.DamageType .. weapon.WeaponType .. "Combat"] or 0)
		untrainedPenalty = AttributesFunctions.GetUntrainedPenalty(enemy.Attributes.Combat)
	end

	dprint(string.format("Skill Bonus: %.2fx", skillBonus))
	dprint(string.format("Untrained Penalty: %.2fx", untrainedPenalty))

	accuracyFactor = accuracyFactor * skillBonus * untrainedPenalty
	dprint(string.format("After skills: %.2fx", accuracyFactor))

	-- Apply damage type accuracy modifier (inverse - lower modifier = more spread)
	accuracyFactor = accuracyFactor * damageData.AccuracyModifier
	dprint(string.format("Damage Type Modifier (%.2fx): %.2fx", damageData.AccuracyModifier, accuracyFactor))

	-- Apply mobile accuracy if moving
	-- Support both boolean and MovementState table
	local movementPenalty = 1.0
	if type(isMoving) == "table" then
		-- Advanced movement state from MovementHelper
		if isMoving.IsAirborne then
			movementPenalty = 0.3 -- Severe penalty while airborne
			dprint("Movement: Airborne (0.30x penalty)")
		elseif isMoving.IsSprinting then
			movementPenalty = 0.5 -- Heavy penalty while sprinting
			dprint("Movement: Sprinting (0.50x penalty)")
		elseif isMoving.IsStrafing then
			movementPenalty = 0.7 -- Moderate penalty while strafing
			dprint("Movement: Strafing (0.70x penalty)")
		elseif isMoving.IsMoving then
			movementPenalty = weaponData.MobileAccuracyModifier
			dprint(string.format("Movement: Walking (%.2fx penalty)", movementPenalty))
		else
			dprint("Movement: Standing still (no penalty)")
		end
	elseif isMoving == true then
		-- Simple boolean - use weapon's mobile accuracy modifier
		movementPenalty = weaponData.MobileAccuracyModifier
		dprint(string.format("Movement: Moving (%.2fx penalty)", movementPenalty))
	else
		dprint("Movement: Standing still (no penalty)")
	end

	accuracyFactor = accuracyFactor * movementPenalty
	dprint(string.format("After movement: %.2fx", accuracyFactor))

	-- Apply range accuracy modifier with distance falloff
	local optimalRange = 100 -- studs
	local rangeFactor = math.clamp(1 - (distance / optimalRange), 0.3, 1.0)
	dprint(string.format("Range Factor: %.2fx (optimal: %d studs)", rangeFactor, optimalRange))

	accuracyFactor = accuracyFactor * rangeFactor * weaponData.RangeAccuracyModifier
	dprint(string.format("Range Modifier (%.2fx): %.2fx", weaponData.RangeAccuracyModifier, accuracyFactor))
	dprint(string.format("Final Accuracy Factor: %.2fx", accuracyFactor))

	-- Convert accuracy to spread (inverse relationship)
	-- High accuracy (1.0) = tight spread (small angles)
	-- Low accuracy (0.3) = wide spread (large angles)
	local spreadMultiplier = 1 / math.max(accuracyFactor, 0.1) -- Avoid division by zero
	dprint(string.format("Spread Multiplier: %.2fx (inverse of accuracy)", spreadMultiplier))

	local minSpread = baseMinSpread * spreadMultiplier
	local maxSpread = baseMaxSpread * spreadMultiplier

	-- Weapon type specific adjustments
	if weapon.WeaponType == "Sniper" then
		-- Snipers have tighter base spread
		minSpread = minSpread * 0.3
		maxSpread = maxSpread * 0.4
		dprint("Weapon Type: Sniper (0.30x/0.40x tighter spread)")
	elseif weapon.WeaponType == "Pistol" then
		-- Pistols have moderate spread
		minSpread = minSpread * 0.7
		maxSpread = maxSpread * 0.8
		dprint("Weapon Type: Pistol (0.70x/0.80x tighter spread)")
	else
		dprint("Weapon Type: Rifle (no adjustment)")
	end

	dprint(string.format("\nFinal Spread: %.3f° - %.3f°", minSpread, maxSpread))
	dprint("========================================\n")

	return minSpread, maxSpread
end

-- Legacy accuracy function (returns 0-1 value)
function CombatFunctions.CalculateAccuracy(weapon, distance, isMoving)
	local weaponData = CombatFunctions.WeaponTypes[weapon.WeaponType]
	local damageData = CombatFunctions.DamageTypes[weapon.DamageType]

	local baseAccuracy = 1.0

	-- Apply damage type accuracy modifier
	baseAccuracy = baseAccuracy * damageData.AccuracyModifier

	-- Apply mobile accuracy if moving
	if isMoving then
		baseAccuracy = baseAccuracy * weaponData.MobileAccuracyModifier
	end

	-- Apply range accuracy modifier (simplified - you'd want to use actual distance calculations)
	-- For now, assume accuracy drops off linearly with distance
	local optimalRange = 100 -- studs
	local rangeFactor = math.clamp(1 - (distance / optimalRange), 0.3, 1.0)
	baseAccuracy = baseAccuracy * rangeFactor * weaponData.RangeAccuracyModifier

	return math.clamp(baseAccuracy, 0, 1)
end

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function CombatFunctions.GetWeaponInfo(weaponType, damageType)
	return {
		WeaponData = CombatFunctions.WeaponTypes[weaponType],
		DamageData = CombatFunctions.DamageTypes[damageType]
	}
end

function CombatFunctions.CreateWeapon(weaponType, damageType, baseDamage, tier)
	return {
		WeaponType = weaponType,
		DamageType = damageType,
		BaseDamage = baseDamage or 10,
		Tier = tier or 1
	}
end

function CombatFunctions.CreateTarget(maxShield, armorRating, maxHealth)
	return {
		CurrentShield = maxShield or 0,
		MaxShield = maxShield or 0,
		ArmorRating = armorRating or 0,
		CurrentHealth = maxHealth or 100,
		MaxHealth = maxHealth or 100,
		StatusEffects = {}
	}
end

return CombatFunctions