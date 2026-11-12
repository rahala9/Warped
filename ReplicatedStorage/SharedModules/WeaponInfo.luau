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
	CurrentWeaponOrigin = nil
	
}

function functions.GetToolHandle(player,heldToolName)

	if (not itemsmodule[heldToolName]) then
		warn("WeaponInfo.GetToolHandle Item Not Found: playerName,itemName",player.Name,heldToolName)
		return
	end

	local modelName = itemsmodule[heldToolName].Model
	
	if (itemsmodule[heldToolName].NewTool) then
		return player.Character:FindFirstChild(heldToolName)[modelName.."Handle"]
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

-- Finds and returns a enemy object by its id
function functions.SetWeaponSource(currentWeaponOrigin)
	functions.CurrentWeaponOrigin = currentWeaponOrigin
end

function functions.GetWeaponSource()
	return functions.CurrentWeaponOrigin
end

return functions