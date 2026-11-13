--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Remote Events

--Functions

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets

--Modules

--Gui

--Context and Actions

--Initialization




local functions = {
	CurrentWeaponOrigin = nil,
	CurrentWeaponName = nil,
	CurrentAimUpdatedAt = nil,
	CurrentWeaponSourceInstance = nil,
	CurrentPresentationOrigin = nil,
	CurrentPresentationWeaponName = nil,
	CurrentPresentationUpdatedAt = nil,
	CurrentPresentationSourceInstance = nil,
	
}

functions.PowerSources = {
	Ammo = "Ammo",
	Energy = "Energy",
}

local ENERGY_DAMAGE_TYPES = {
	Laser = true,
	Plasma = true,
	Electric = true,
	ParticleBeam = true,
	Cryo = true,
}

local ENERGY_DEFAULTS = {
	Laser = {Capacity = 100, Cost = 8, RecoveryRate = 24, RecoveryDelay = 0.8, Color = Color3.fromRGB(55, 225, 255)},
	Electric = {Capacity = 100, Cost = 14, RecoveryRate = 20, RecoveryDelay = 1, Color = Color3.fromRGB(255, 230, 60)},
	Plasma = {Capacity = 100, Cost = 25, RecoveryRate = 12, RecoveryDelay = 1.75, Color = Color3.fromRGB(210, 75, 255)},
	ParticleBeam = {Capacity = 100, Cost = 18, RecoveryRate = 16, RecoveryDelay = 1.25, Color = Color3.fromRGB(100, 255, 190)},
	Cryo = {Capacity = 100, Cost = 16, RecoveryRate = 14, RecoveryDelay = 1.5, Color = Color3.fromRGB(120, 190, 255)},
}

local FALLBACK_ENERGY = {
	Capacity = 100,
	Cost = 10,
	RecoveryRate = 20,
	RecoveryDelay = 1,
	Color = Color3.fromRGB(55, 225, 255),
}

function functions.IsEnergyWeapon(weapon)
	if not weapon then
		return false
	end

	if weapon.PowerSource ~= nil then
		return weapon.PowerSource == functions.PowerSources.Energy
	end

	return ENERGY_DAMAGE_TYPES[weapon.DamageType] == true
end

function functions.UsesAmmo(weapon)
	if not weapon or functions.IsEnergyWeapon(weapon) then
		return false
	end

	return weapon.WeaponAmmo ~= nil
		and weapon.WeaponAmmo ~= "NoAmmo"
		and not (weapon.Traits and weapon.Traits.UnlimitedAmmo)
end

function functions.GetEnergyConfig(weapon)
	if not functions.IsEnergyWeapon(weapon) then
		return nil
	end

	local defaults = ENERGY_DEFAULTS[weapon.DamageType] or FALLBACK_ENERGY
	return {
		Capacity = weapon.EnergyCapacity or defaults.Capacity,
		Cost = weapon.EnergyCost or defaults.Cost,
		RecoveryRate = weapon.EnergyRecoveryRate or defaults.RecoveryRate,
		RecoveryDelay = weapon.EnergyRecoveryDelay or defaults.RecoveryDelay,
		Color = weapon.EnergyColor or defaults.Color,
	}
end

function functions.GetToolHandle(player,heldToolName)

	if (not itemsmodule[heldToolName]) then
		warn("WeaponInfo.GetToolHandle Item Not Found: playerName,itemName",player.Name,heldToolName)
		return
	end

	local modelName = itemsmodule[heldToolName].Model
	
	if (itemsmodule[heldToolName].NewTool) then
		local character = player.Character
		local toolModel = character and character:FindFirstChild(heldToolName)
		local handleName = modelName.."Handle"

		-- Two-handed IK temporarily moves the live handle beneath the root.
		return (toolModel and toolModel:FindFirstChild(handleName))
			or (character and character:FindFirstChild(handleName, true))
	end
	
	local leftHand = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"]
	local rightHand =  player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]


	if (modelName == "") or (itemsmodule[heldToolName].Type == "Artifact") then
		return rightHand
	end

	local hand = itemsmodule[heldToolName].Hand
	if (hand == nil) then
		hand = "Right"
	end

	if (hand == "Left") then
		return leftHand[modelName.."Handle"]
	elseif (hand == "Both") then
		return  rightHand[modelName.."RightHandle"],leftHand[modelName.."LeftHandle"]
	else
		return  rightHand[modelName.."Handle"]
	end

end

function functions.GetFiringPosition(player,heldToolName)
	-- AimRangeWeapon owns the rendered weapon while its two grip IK controls are
	-- active. Use that exact muzzle transform instead of looking under the tool
	-- model, because the live handle is temporarily parented to HumanoidRootPart.
	if functions.CurrentWeaponOrigin
		and functions.CurrentWeaponName == heldToolName
		and functions.CurrentAimUpdatedAt
		and os.clock() - functions.CurrentAimUpdatedAt < 0.5
	then
		return functions.CurrentWeaponOrigin
	end

	local HeldToolHandle = functions.GetToolHandle(player,heldToolName)
	
	if (not HeldToolHandle) then
		return nil
	end
	
	if (itemsmodule[heldToolName].NewTool) then
		if (HeldToolHandle:GetAttribute("HasTip")) then
			return HeldToolHandle.WorldCFrame * HeldToolHandle.Attachment.CFrame
		else
			return HeldToolHandle.Muzzle.WorldCFrame
		end
	else
		if (HeldToolHandle:GetAttribute("HasTip")) then
			return HeldToolHandle.TransformedWorldCFrame * HeldToolHandle.Attachment.CFrame
		else
			return HeldToolHandle.TransformedWorldCFrame
		end
	end
	
end

function functions.SetWeaponSource(currentWeaponOrigin, weaponName, sourceInstance)
	functions.CurrentWeaponOrigin = currentWeaponOrigin
	functions.CurrentWeaponName = weaponName
	functions.CurrentAimUpdatedAt = currentWeaponOrigin and os.clock() or nil
	functions.CurrentWeaponSourceInstance = sourceInstance
end

function functions.GetWeaponSource()
	return functions.CurrentWeaponOrigin
end

function functions.GetWeaponSourceInstance()
	return functions.CurrentWeaponSourceInstance
end

-- Client-only presentation source used by first-person muzzle flashes and
-- tracers. Gameplay firing must continue to use GetFiringPosition so the
-- camera-mounted viewmodel never becomes an authoritative shot origin.
function functions.SetPresentationWeaponSource(currentWeaponOrigin, weaponName, sourceInstance)
	functions.CurrentPresentationOrigin = currentWeaponOrigin
	functions.CurrentPresentationWeaponName = weaponName
	functions.CurrentPresentationUpdatedAt = currentWeaponOrigin and os.clock() or nil
	functions.CurrentPresentationSourceInstance = sourceInstance
end

function functions.GetPresentationWeaponSource(weaponName)
	if functions.CurrentPresentationOrigin
		and (weaponName == nil or functions.CurrentPresentationWeaponName == weaponName)
		and functions.CurrentPresentationUpdatedAt
		and os.clock() - functions.CurrentPresentationUpdatedAt < 0.5
	then
		return functions.CurrentPresentationOrigin
	end

	return functions.CurrentWeaponOrigin
end

function functions.GetPresentationWeaponSourceInstance(weaponName)
	if weaponName == nil or functions.CurrentPresentationWeaponName == weaponName then
		return functions.CurrentPresentationSourceInstance
	end
	return nil
end

return functions
