--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local SkillCheckFunctions = require(ReplicatedStorage.SharedFunctions.SkillCheckFunctions)
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets


--Modules

local functions = {}

functions.ActionTypes = {
	["Hacking"] = "Hacking",
	["BuildElectronic"] = "BuildElectronic",
	["BuildMechanical"] = "BuildMechanical",
	["BuildPower"] = "BuildPower",
	["BuildWeapon"] = "BuildWeapon",
}

functions.ActionData = {
	["Hacking"] = {["SkillName"]=SkillCheckFunctions.Skills.Hacking.name},
	["BuildElectronic"] = {["SkillName"]=SkillCheckFunctions.Skills.ElectronicalEngineering.name},
	["BuildMechanical"] = {["SkillName"]=SkillCheckFunctions.Skills.MechanicalEngineering.name},
	["BuildPowerSystem"] = {["SkillName"]=SkillCheckFunctions.Skills.PowerEngineering.name},
	["BuildWeapon"] = {["SkillName"]=SkillCheckFunctions.Skills.WeaponEngineering.name},
}

functions.Difficulty = {
	["Trivial"] = "Trivial",
	["Easy"] = "Easy",
	["Average"] = "Average",
	["Hard"] = "Hard",
	["VeryHard"] = "VeryHard",
	["NearImpossible"] = "NearImpossible"
}

functions.DifficultyTime = {
	Trivial = -8,
	Easy = -5,
	Average = 0,
	Hard = 5,
	VeryHard = 8,
	NearImpossible = 10
}

local BASE_TIME_FOR_ACTION = 10

function functions.GetActionTypeSkillBonus(player,itemName,actionType)
	local itemDef = itemsmodule[itemName]

	if (itemDef) then
		if (itemDef.Attributes.SkillBonus) then
			if (itemDef.Attributes.SkillBonus.Skill == "All") then --As in Probability Manipulator then
				return itemDef.Attributes.SkillBonus.Value
			elseif (itemDef.Attributes.SkillBonus.Skill == functions.ActionData[actionType].SkillName) then
				return itemDef.Attributes.SkillBonus.Value
			end
		end
	end
	
	return 0
end
function functions.GetEquipmentBonus(player,actionType)
	
	local equipmentSkillBonus = 0
	
	--Check offhand objects like Probability Manipulator
	local offHandItem = InventoryFunctions.GetOffHandItem(player)
	
	if (offHandItem) then
		equipmentSkillBonus = equipmentSkillBonus + functions.GetActionTypeSkillBonus(player,offHandItem.Name,actionType)	
	end
	
	--Check held tools that might give bonus like nanite probes
	local heldToolName = StatesFunctions.GetCurrentTool(player)
	if (heldToolName) then
		equipmentSkillBonus = equipmentSkillBonus + functions.GetActionTypeSkillBonus(player,heldToolName,actionType)	
	end
	
	return equipmentSkillBonus
	
end

function functions.AttemptAction(player,actionType,difficulty)
	
	local allSkills =  AttributesFunctions.GetAllSkills(player)
	local skillName = functions.ActionData[actionType].SkillName
	local baseSkillName = SkillCheckFunctions.Skills[skillName].baseSkillName
	local primaryAttribute = SkillCheckFunctions.Skills[skillName].primaryAttribute
	local SkillLevel = allSkills[skillName] or allSkills[baseSkillName]
	local AttributeLevel = AttributesFunctions.GetAllAttributes(player)[primaryAttribute]
	
	print("TEST AttemptAction skillName:",skillName," baseSkillName:",baseSkillName," SkillLevel:",SkillLevel," AttributeLevel:",AttributeLevel)
	
	return SkillCheckFunctions.MakeCheck({
		skillLevel = SkillLevel,           -- Hacking skill level 0 untrained
		attributeModifier = AttributeLevel,    -- Intelligence modifier +5
		difficulty = SkillCheckFunctions.Difficulty[difficulty],
		equipmentBonus = functions.GetEquipmentBonus(player,actionType)
	})
end

function functions.GetTimeForAction(player,actionType,difficulty)

	local allSkills =  AttributesFunctions.GetAllSkills(player)
	local SkillLevel = allSkills[functions.ActionData[actionType].SkillName] or allSkills[functions.ActionData[actionType].BaseSkill]

	local totalTime = BASE_TIME_FOR_ACTION + functions.DifficultyTime[difficulty] - (SkillLevel*3)
	
	return math.clamp(totalTime,0,20)
end


return functions
