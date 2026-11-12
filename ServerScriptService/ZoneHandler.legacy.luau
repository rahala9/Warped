--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

--Remote Events
local TeleportCameraSync = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TeleportCameraSync")
local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")
--local SpawnEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("Spawn")
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
--local WorldChangeEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("WorldChangeEvent")
--local RunActEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RunAct")

--Functions
--local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local QuestFunctions = require(ServerScriptService.Data.DataQuestFunctions)

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local ZoneDefinitions = require(ReplicatedStorage.SharedModules.ZoneDefinitions)

--Objects

--Modules
local Zones = require(ReplicatedStorage.SharedModules.ZoneLoader)
local PPC = require(ReplicatedStorage.SharedModules.PressurePlateController)


--TODO MOVE INTO TELEPORT MODULE
function Teleport(player, freeze, destination)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.RootPart then return end

	local rootPart = humanoid.RootPart

	-- Freeze character during teleport if requested
	if freeze then
		humanoid:SetAttribute("DefaultWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("DefaultJumpPower", humanoid.JumpPower)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Calculate height of root part from character base
	local rootPartY
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		rootPartY = (rootPart.Size.Y * 0.5) + humanoid.HipHeight
	else
		rootPartY = (rootPart.Size.Y * 0.5) + humanoid.Parent.LeftLeg.Size.Y + humanoid.HipHeight
	end

	-- Preserve current facing direction (Y rotation)
	local rootCF = rootPart.CFrame
	local _, currentY, _ = rootCF:ToEulerAnglesYXZ()

	local newPos = destination + Vector3.new(0, rootPartY, 0)
	local newCF  = CFrame.new(newPos) * CFrame.Angles(0, currentY, 0)

	character:SetPrimaryPartCFrame(newCF)
	
	-- Unfreeze character
	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

function Teleport2(player, freeze, destination, reverseCam)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not humanoid.RootPart then return end

	if freeze then
		humanoid:SetAttribute("DefaultWalkSpeed", humanoid.WalkSpeed)
		humanoid:SetAttribute("DefaultJumpPower", humanoid.JumpPower)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	local characterCF = destination * CFrame.Angles(0, math.rad(-90), 0)
	character:PivotTo(characterCF)

	local cameraCF = characterCF
	if reverseCam then
		cameraCF = characterCF * CFrame.Angles(0, math.rad(180), 0)
	end

	TeleportCameraSync:FireClient(player, cameraCF)

	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

local function TeleportThroughPortal(player, freeze, entryPortalCF, exitPortalCF)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local savedWalkSpeed, savedJumpPower
	if freeze then
		savedWalkSpeed = humanoid.WalkSpeed
		savedJumpPower = humanoid.JumpPower
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Save incoming motion before moving the character
	local oldLinearVelocity = rootPart.AssemblyLinearVelocity
	local oldAngularVelocity = rootPart.AssemblyAngularVelocity

	-- Portal flip: looking into one portal comes out facing away from the other
	local portalFlip = CFrame.Angles(0, math.pi, 0)

	-- Preserve the character's relative transform through the portal pair
	local relCF = entryPortalCF:ToObjectSpace(rootPart.CFrame)
	local newRootCF = exitPortalCF * portalFlip * relCF

	-- Transform linear velocity through the portal
	local localVelocity = entryPortalCF:VectorToObjectSpace(oldLinearVelocity)
	local newLinearVelocity = (exitPortalCF * portalFlip):VectorToWorldSpace(localVelocity)

	-- Transform angular velocity too, so spins/turns remain believable
	local localAngularVelocity = entryPortalCF:VectorToObjectSpace(oldAngularVelocity)
	local newAngularVelocity = (exitPortalCF * portalFlip):VectorToWorldSpace(localAngularVelocity)

	-- Move character
	character:PivotTo(newRootCF)

	-- Reapply transformed momentum
	rootPart.AssemblyLinearVelocity = newLinearVelocity
	rootPart.AssemblyAngularVelocity = newAngularVelocity

	-- Sync camera to the same final orientation
	TeleportCameraSync:FireClient(player, newRootCF)

	if freeze then
		humanoid.WalkSpeed = savedWalkSpeed
		humanoid.JumpPower = savedJumpPower
	end
end
Zones:OnLoaded("PortalA", function(zone)

	local door = zone.Folder.Parent

	zone:OnPlayerEntered(function(player)
		--Teleport2(player,true, workspace.PortalB.PortalMain.Exit.WorldCFrame,false)
		TeleportThroughPortal(
			player,
			true,
			workspace.PortalA.PortalMain.Exit.WorldCFrame,
			workspace.PortalB.PortalMain.Exit.WorldCFrame
		)
	end)
end)

Zones:OnLoaded("PortalB", function(zone)

	local door = zone.Folder.Parent

	zone:OnPlayerEntered(function(player)
		--Teleport2(player,true, workspace.PortalA.PortalMain.Exit.WorldCFrame,false)
		TeleportThroughPortal(
			player,
			true,
			workspace.PortalB.PortalMain.Exit.WorldCFrame,
			workspace.PortalA.PortalMain.Exit.WorldCFrame
		)
	end)
end)