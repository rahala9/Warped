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

local DEFAULT_PORTAL_COOLDOWN = 1
local portalTransitUntil = {}

local function getPortalCooldown(zoneFolder)
	local configuredCooldown = zoneFolder:GetAttribute("PortalCooldown")
	if typeof(configuredCooldown) ~= "number" then
		return DEFAULT_PORTAL_COOLDOWN
	end

	return math.max(0, configuredCooldown)
end

local function canUsePortal(player, zoneFolder)
	local requiredItem = zoneFolder:GetAttribute("RequiredItem")
	if typeof(requiredItem) ~= "string" or requiredItem == "" then
		return true
	end

	local requiredAmount = zoneFolder:GetAttribute("RequiredItemAmount")
	if typeof(requiredAmount) ~= "number" then
		requiredAmount = 1
	end
	requiredAmount = math.max(1, math.floor(requiredAmount))

	local hasItem, usedItemName, containerId = InventoryFunctions.HasItem(
		player,
		requiredItem,
		requiredAmount,
		true,
		true
	)

	if not hasItem then
		local itemDefinition = InventoryFunctions.GetItemDef(requiredItem)
		local displayName = itemDefinition and itemDefinition.DisplayName or requiredItem
		MessagePlayerEvent:FireClient(
			player,
			string.format("Requires %d %s", requiredAmount, displayName),
			requiredItem
		)
		return false
	end

	local usedItemDefinition = InventoryFunctions.GetItemDef(usedItemName)
	local isTicket = usedItemDefinition and usedItemDefinition.SubType == "Ticket"
	local shouldConsume = isTicket or zoneFolder:GetAttribute("ConsumeRequiredItem") == true

	if shouldConsume then
		if containerId then
			InventoryFunctions.RemoveItemFromContainer(
				player,
				containerId,
				usedItemName,
				requiredAmount,
				true
			)
		else
			InventoryFunctions.RemoveItem(player, usedItemName, requiredAmount)
		end
	end

	return true
end


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

local function handlePortalEntered(zone, player, entryPortalCF, exitPortalCF)
	local now = os.clock()
	if now < (portalTransitUntil[player] or 0) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart then
		return
	end

	-- Set this before moving the character so entering the destination zone cannot
	-- immediately send the player back or charge a second ticket.
	portalTransitUntil[player] = now + getPortalCooldown(zone.Folder)

	if not canUsePortal(player, zone.Folder) then
		return
	end

	TeleportThroughPortal(player, true, entryPortalCF, exitPortalCF)
end

Zones:OnLoaded("PortalA", function(zone)
	zone:OnPlayerEntered(function(player)
		handlePortalEntered(
			zone,
			player,
			workspace.PortalA.PortalMain.Exit.WorldCFrame,
			workspace.PortalB.PortalMain.Exit.WorldCFrame
		)
	end)
end)

Zones:OnLoaded("PortalB", function(zone)
	zone:OnPlayerEntered(function(player)
		handlePortalEntered(
			zone,
			player,
			workspace.PortalB.PortalMain.Exit.WorldCFrame,
			workspace.PortalA.PortalMain.Exit.WorldCFrame
		)
	end)
end)
