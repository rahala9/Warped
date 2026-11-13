local PlayerHitEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	
local ServerScriptService = game:GetService("ServerScriptService")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local clientPlayerHitEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerHit")
local UpdateHealthEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateHealth")
local showDeathUIEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ShowDeathUI")
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local EffectsDef = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects"))
local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")
local CurrentHeldToolChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CurrentHeldToolChanged")

local lastHealthRequest = {}
UpdateHealthEvent.OnServerEvent:Connect(function(player, action)
	if action ~= "Request" then
		return
	end

	local now = os.clock()
	if now - (lastHealthRequest[player] or 0) < 0.5 then
		return
	end
	lastHealthRequest[player] = now

	UpdateHealthEvent:FireClient(
		player,
		StatesFunctions.GetHealth(player),
		AttributesFunctions.GetMaxHealth(player)
	)
end)

Players.PlayerRemoving:Connect(function(player)
	lastHealthRequest[player] = nil
end)

function TeleportToSpawnLocation(player, freeze)

	local character = player.Character
	local humanoid = character.Humanoid

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
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.HipHeight
	else
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.Parent.LeftLeg.Size.Y + humanoid.HipHeight
	end

	-- Teleport player and request content around location if applicable
	local position = CFrame.new(StatesFunctions.GetState(player).SpawnLocation + Vector3.new(0, rootPartY, 0))
	--local orientation = CFrame.Angles(0, math.rad(params.faceAngle), 0)

	character:SetPrimaryPartCFrame(position) -- * orientation)

	-- Unfreeze character
	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

function TeleportToLocation(player, location,freeze)

	local character = player.Character
	local humanoid = character.Humanoid

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
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.HipHeight
	else
		rootPartY = (humanoid.RootPart.Size.Y * 0.5) + humanoid.Parent.LeftLeg.Size.Y + humanoid.HipHeight
	end

	-- Teleport player and request content around location if applicable
	local position = CFrame.new(location + Vector3.new(0, rootPartY, 0))
	--local orientation = CFrame.Angles(0, math.rad(params.faceAngle), 0)

	character:SetPrimaryPartCFrame(position) -- * orientation)

	-- Unfreeze character
	if freeze then
		humanoid.WalkSpeed = humanoid:GetAttribute("DefaultWalkSpeed")
		humanoid.JumpPower = humanoid:GetAttribute("DefaultJumpPower")
	end
end

function EnableStates(player,enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
end


function onPlayerHit(player,damage,enemyName,damageType)
	
	if (player ~=nil and StatesFunctions.GetHealth(player) > 0) then
		
		StatesFunctions.RemoveHealth(player,damage)

		print("TEST PLAYER HEALTH current health:",StatesFunctions.GetHealth(player))
		clientPlayerHitEvent:FireClient(player, StatesFunctions.GetHealth(player),AttributesFunctions.GetMaxHealth(player), damage, damageType)
	end
	
	if (player ~=nil and not StatesFunctions.GetDead(player) and (StatesFunctions.GetHealth(player) <= 0)) then
		
		--Player is now dead
		StatesFunctions.SetDead(player,true) --TODO not needed?
		
		player.Character:SetAttribute("Dead", true)
		
		EffectsFunctions.RemoveAllEffects(player)
				
		player.Character.PrimaryPart.Anchored = true
		EnableStates(player,false)
		player.Character.Humanoid.Sit = true
		player.Character.Humanoid.WalkSpeed = 0
		
		CurrentHeldToolChangedEvent:FireClient(player,"")
		local originalJumpPower = player.Character.Humanoid.JumpPower
		local originalHipHeight = player.Character.Humanoid.HipHeight
		
		player.Character.Humanoid.AutoRotate = false
		player.Character.Humanoid.JumpPower = 0
		player.Character.Humanoid.HipHeight = 0
		player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		
		PlayerStateChangeEvent:FireClient(player,"Death")
		
		wait(7) --was 3
		
		--TELEPORT TO SAFE GRAVEYARD AREA OFF MAP SO ENEMIES DON"T HIT YOU
		TeleportToLocation(player, Vector3.new(12000, 150.792, 12000),true)
		
		local deathReason = "You Died"
		if (enemyName ~= nil) then
			deathReason = enemiesModule[enemyName].Deaths[math.random(#enemiesModule[enemyName].Deaths)]
		else
			if (EffectsDef[damageType] and EffectsDef[damageType].Deaths) then
				deathReason = EffectsDef[damageType].Deaths[math.random(#EffectsDef[damageType].Deaths)]
			end
		end
		--signal to show death screen
		showDeathUIEvent:FireClient(player,true,deathReason)
		
		wait(3)	
		
		StatesFunctions.SetHealth(player,AttributesFunctions.GetMaxHealth(player)*.75)
		UpdateHealthEvent:FireClient(player, StatesFunctions.GetHealth(player), AttributesFunctions.GetMaxHealth(player))
		
		StatesFunctions.SetDead(player,false)
		player.Character:SetAttribute("Dead", false)
		
		PlayerStateChangeEvent:FireClient(player,"Standing")
		
		player.Character.PrimaryPart.Anchored = false
		EnableStates(player,true)
		player.Character.Humanoid.Sit = false
		player.Character.Humanoid.WalkSpeed = 16
		player.Character.Humanoid.AutoRotate = true
		player.Character.Humanoid.JumpPower = originalJumpPower
		player.Character.Humanoid.HipHeight = originalHipHeight
		
		--SEND PLAYER BACK TO START
		TeleportToSpawnLocation(player, true)
		
		PlayerStateChangeEvent:FireClient(player,"Respawn")

		delay(2,function() 
			showDeathUIEvent:FireClient(player,false)
		end)
	end
end

PlayerHitEvent.Event:Connect(onPlayerHit)
