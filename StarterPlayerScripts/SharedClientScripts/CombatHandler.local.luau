--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedStorage_SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local ReplicatedStorage_SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local ItemDefs = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("ItemDefs")

--Remote Events
local GetInventoryEvent = ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("GetInventory")
local CurrentHeldToolChangedEvent = ReplicatedStorage_SharedRemotes:WaitForChild("CurrentHeldToolChanged")
local ChangeTargetEvent = ReplicatedStorage_SharedRemotes:WaitForChild("ChangeTarget")
local NoAmmoEvent = ReplicatedStorage_SharedRemotes:WaitForChild("NoAmmo")
local sendinv = ReplicatedStorage_SharedRemotes:WaitForChild("SendInv")
local clientPlayerHitEvent = ReplicatedStorage_SharedRemotes:WaitForChild("PlayerHit") 
local PlayerInputEvent = ReplicatedStorage_SharedRemotes:WaitForChild("PlayerInput")
local LocalPlayerInputEvent = ReplicatedStorage_SharedRemotes:WaitForChild("LocalPlayerInput")

--Functions
local PlayerState = require(script.Parent:WaitForChild("PlayerStateFunctions"))
local AimTarget = require(script.Parent:WaitForChild("AimTarget"))

--Definition Modules
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local weaponsDef = require(ItemDefs:WaitForChild("Weapons"))
local ammoDef = require(ItemDefs:WaitForChild("Ammo"))
local attacksModule = require(ReplicatedStorage_SharedModules:WaitForChild("Attacks")) 
local weaponInfo = require(ReplicatedStorage_SharedModules:WaitForChild("WeaponInfo"))

--Assets
local CurrentPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local character = CurrentPlayer.Character or CurrentPlayer.CharacterAdded:Wait()
--local StickDartEvent = ReplicatedStorage:WaitForChild("StickDart")
--local dart = ReplicatedStorage:WaitForChild("toydartAmmo")
local player = game.Players.LocalPlayer
local char = CurrentPlayer.Character or CurrentPlayer.CharacterAdded:Wait()

--Modules

--Gui
local CombatGui = CurrentPlayer.PlayerGui:WaitForChild("SharedGUI"):WaitForChild("CombatGui")
local CombatFrame = CombatGui:WaitForChild("CombatFrame")
local AttacksFrame = CombatFrame:WaitForChild("Attacks")
local playerGui = player:WaitForChild("PlayerGui")

--Context and Actions

--Initialization

local unequippedEvent = nil
local inputEvent = nil
local activeWeapon = nil
local activeAutoWeaponOn = false

local playerInventory = nil

local mouseHitPosition = nil
local Mouse = CurrentPlayer:GetMouse()
local camera = workspace.CurrentCamera

player.CharacterAdded:Connect(function(newChar)
	char = newChar
	character = newChar
end)

--ChangeTargetEvent.OnClientEvent:Connect(function(target)
--	
--end)

NoAmmoEvent.OnClientEvent:Connect(function(noAmmo)
	if (noAmmo) then
		CombatFrame.Ammo.NoAmmo.Visible = true
		task.wait(.3)
		CombatFrame.Ammo.NoAmmo.Visible = false
		task.wait(.3)
		CombatFrame.Ammo.NoAmmo.Visible = true
		task.wait(.3)
		CombatFrame.Ammo.NoAmmo.Visible = false
		task.wait(.3)
		CombatFrame.Ammo.NoAmmo.Visible = true
	else
		CombatFrame.Ammo.NoAmmo.Visible = false
	end

end)

function HasItem(itemId,amount)

	if (amount == nil) then
		amount = 1
	end

	if (playerInventory == nil) then
		return
	end

	if (playerInventory["Items"][weaponsDef[activeWeapon].WeaponAmmo] ~= nil) then
		return true,playerInventory["Items"][weaponsDef[activeWeapon].WeaponAmmo].Amount,itemId,nil
	end

	--Check containers
	for itemToCheckContainerId,itemToCheckContainer in pairs(playerInventory["Items"]) do
		if (itemsmodule[itemToCheckContainer.Name] and itemsmodule[itemToCheckContainer.Name].SubType == "Container") then
			if (itemToCheckContainer.Contains[itemId]) then
				if (itemToCheckContainer.Contains[itemId].Amount >= amount) then
					return true,itemToCheckContainer.Contains[itemId].Amount,itemId,itemToCheckContainerId
				end

			end
		end
	end
end

function UpdateAmmoUI()

	if (not weaponsDef[activeWeapon].WeaponAmmo) then
		return
	end

	assert(weaponsDef[activeWeapon])
	assert(weaponsDef[activeWeapon].WeaponAmmo)
	assert(ammoDef[weaponsDef[activeWeapon].WeaponAmmo].Type)

	CombatFrame.Ammo.Visible = true

	local weaponDefObject = weaponsDef[activeWeapon]
	local ammoDefObject = ammoDef[weaponDefObject.WeaponAmmo]

	if (ammoDef.ImageMap[ammoDefObject.Type]) then
		CombatFrame.Ammo.AmmoImage.Image = ammoDef.ImageMap[ammoDefObject.Type]
	end

	CombatFrame.Ammo.AmmoImage.ImageRectOffset = Vector2.new(ammoDefObject.ImageOffsetX,ammoDefObject.ImageOffsetY)

	local hasItem,amount = HasItem(weaponDefObject.WeaponAmmo)

	if (hasItem) then
		CombatFrame.Ammo.AmmoImage.TextLabel.Text = amount
		CombatFrame.Ammo.NoAmmo.Visible = false
	else
		CombatFrame.Ammo.AmmoImage.TextLabel.Text = 0
		CombatFrame.Ammo.NoAmmo.Visible = true
	end
end

function UpdateInventory()
	if ((activeWeapon == nil) or (activeWeapon == "")) then
		return
	end

	local weaponDefObject = weaponsDef[activeWeapon]

	if (weaponDefObject.WeaponAmmo == nil) then
		return
	end

	if (weaponDefObject.WeaponAmmo == "NoAmmo") then
		return
	end

	playerInventory = GetInventoryEvent:InvokeServer() --TODO PERFORMANCE Maybe more efficient to just get active tool inventory item

	UpdateAmmoUI()

end


local lastFireTime = 0

function UpdateUI(attackKey)
	if (playerInventory == nil) then
		return
	end

	if (activeWeapon == nil) then
		return
	end

	local elapsedTime = os.clock() - lastFireTime
	local weapon = weaponsDef[activeWeapon]
	local weaponspeed = weapon.WeaponSpeed
	local fireRateTime = 10/weaponspeed

	if (elapsedTime < fireRateTime) then
		return
	else
		lastFireTime = os.clock()
	end

	if (attackKey == Enum.KeyCode.F) then
		if (AttacksFrame["AttackF"].HideFrame.Size.Y.Scale > 0) then
			return
		end

		local coolDown = attacksModule[weapon.WeaponAttacks["F"].Name].Cooldown

		if (coolDown) then
			local attackHideFrameInfo = TweenInfo.new(coolDown, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local attackHideFrameTween = tweenService:Create(AttacksFrame["AttackF"].HideFrame, attackHideFrameInfo, {Size = UDim2.new(1,0,1,0)})

			attackHideFrameTween:Play()
		end

	elseif (attackKey == Enum.KeyCode.G) then
		if (AttacksFrame["AttackG"].HideFrame.Size.Y.Scale > 0) then
			return
		end

		local coolDown = attacksModule[weapon.WeaponAttacks["F"].Name].Cooldown

		if (coolDown) then
			local attackHideFrameInfo = TweenInfo.new(coolDown, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local attackHideFrameTween = tweenService:Create(AttacksFrame["AttackG"].HideFrame, attackHideFrameInfo, {Size = UDim2.new(1,0,1,0)})

			attackHideFrameTween:Play()
		end

	end



	if (playerInventory["Items"][weapon.WeaponAmmo] and not weapon.Traits["UnlimitedAmmo"] and playerInventory["Items"][weapon.WeaponAmmo].Amount > 0) then
		playerInventory["Items"][weapon.WeaponAmmo].Amount = playerInventory["Items"][weapon.WeaponAmmo].Amount - 1
	end

	UpdateAmmoUI()
end

sendinv.OnClientEvent:Connect(function()
	UpdateInventory()	
end)

function getMouseHitPosition()
	local targetPosition = AimTarget.GetTarget(
		camera,
		AimTarget.GetScreenPoint(Mouse),
		char
	)

	return targetPosition
end

local function HandleInput(actionName, userInputState, input) 	

	if (userInputState ~= Enum.UserInputState.Begin) then
		return Enum.ContextActionResult.Pass	
	end

	local currentToolName = PlayerState.CurrentTool

	local currentTool = weaponsDef[currentToolName]

	if (not currentTool) then
		return
	end

	if (currentTool.Auto == true) then
		if(input.KeyCode == Enum.KeyCode.R) then
			activeAutoWeaponOn = true
		elseif(input.KeyCode == Enum.KeyCode.F) then
			activeAutoWeaponOn = false
		end
	end

	local hitPosition = getMouseHitPosition()
	if (currentToolName and weaponsDef[currentToolName] and ((weaponsDef[currentToolName].Type == "Weapon") or (weaponsDef[currentToolName].Type == "Artifact"))) then
		local attack = attacksModule[currentTool.WeaponAttacks[input.KeyCode.Name].Name]

		--For when you don't want the projectile to come out until a Release point event in the animation
		if (attack.DeferAttack) then

			PlayerState.HandleAttack(currentTool,input.KeyCode,hitPosition)

			return Enum.ContextActionResult.Pass	
		end
	end

	UpdateUI(input.KeyCode)

	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,currentToolName)

	PlayerInputEvent:FireServer(input.KeyCode,hitPosition,ToolTransformedWorldCFrame)
	LocalPlayerInputEvent:Fire(input.KeyCode,hitPosition)

	return Enum.ContextActionResult.Pass
end

local function HandleMouseInput(actionName, userInputState, input) 	

	if (userInputState ~= Enum.UserInputState.Begin) then
		return
	end

	local currentToolName = PlayerState.CurrentTool

	local currentTool = weaponsDef[currentToolName]

	if (not currentTool) then
		return
	end

	if (currentTool.Auto == true) then
		activeAutoWeaponOn = true
	end

	local hitPosition = getMouseHitPosition()

	--Ignore Mouse click if guis up

	--if (Background.Visible) then
	--	return	
	--end

	if (currentToolName and weaponsDef[currentToolName] and ((weaponsDef[currentToolName].Type == "Weapon") or (weaponsDef[currentToolName].Type == "Artifact"))) then
		local attack = attacksModule[currentTool.WeaponAttacks[Enum.KeyCode.R.Name].Name]

		--For when you don't want the projectile to come out until a Release point event in the animation
		if (attack.DeferAttack) then
			PlayerState.HandleAttack(currentTool,Enum.KeyCode.R,hitPosition)
			UpdateUI(Enum.KeyCode.R)
			return	
		end
	end

	UpdateUI(Enum.KeyCode.R)

	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,currentToolName)

	PlayerInputEvent:FireServer(Enum.KeyCode.R,hitPosition,ToolTransformedWorldCFrame)
	LocalPlayerInputEvent:Fire(Enum.KeyCode.R,hitPosition)



	----JUST TESTING
	--local animation = Instance.new("Animation")

	--if (attacksModule[currentTool.WeaponAttacks[Enum.KeyCode.R.Name].Name].Animation) then

	--	local attack = attacksModule[currentTool.WeaponAttacks[Enum.KeyCode.R.Name].Name]
	--	PlayerState.States.Attacking.Animation = PlayerState.AttackAnimations[attack.Animation]
	--	PlayerState.States.Attacking.AnimationSpeed = attack.AnimationSpeed

	--	--if (attacksModule[weapon.WeaponAttacks[keycode.Name].Name].AnimationSpeed ~= nil) then
	--	--	Track:AdjustSpeed(attacksModule[weapon.WeaponAttacks[keycode.Name].Name].AnimationSpeed)
	--	--end

	--	PlayerState.ChangeState(PlayerState.States.Attacking,false) --,keyCode,hitPosition)

	--	--animation.AnimationId = "http://www.roblox.com/asset/?id="..attacksModule[currentTool.WeaponAttacks[Enum.KeyCode.R.Name].Name].Animation
	--	--local Track = player.Character.Humanoid:LoadAnimation(animation)


	--	--Track:GetMarkerReachedSignal("EarlyCast"):Connect(function()
	--	--	--local Data = {}
	--	--	--local Module = ServerScriptService:WaitForChild("SharedFX"):FindFirstChild(weapon.Name)

	--	--	--if Module then
	--	--	--	require(Module)(player, CFrame.new(target), weapon, attacksModule[itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name],ToolTransformedWorldCFrame, Data)
	--	--	--else
	--	--	--	Replicator:FireAllClients(weapon.Name)
	--	--	--end
	--	--end)

	--	--Track:Play()
	--end


end

CurrentHeldToolChangedEvent.OnClientEvent:Connect(function(toolName,slot)

	--TODO may need to add Artifact
	if (toolName ~= "" and weaponsDef[toolName] ~= nil and ((weaponsDef[toolName].Type == "Weapon") or (weaponsDef[toolName].Type == "OffHand") or (weaponsDef[toolName].Type == "Artifact") ))  then

		activeWeapon = toolName

		CombatGui.Enabled = true

		game:GetService("ContextActionService"):BindAction("HandleInputE", HandleInput, false, Enum.KeyCode.E)
		game:GetService("ContextActionService"):BindAction("HandleInputF", HandleInput, false, Enum.KeyCode.F)
		game:GetService("ContextActionService"):BindAction("HandleInputG", HandleInput, false, Enum.KeyCode.G)
		game:GetService("ContextActionService"):BindAction("HandleInputR", HandleInput, false, Enum.KeyCode.R)
		game:GetService("ContextActionService"):BindAction("HandleInputMouse", HandleMouseInput, false, Enum.UserInputType.MouseButton1)

		if (weaponsDef[toolName].WeaponAmmo ~= nil and weaponsDef[toolName].WeaponAmmo ~= "NoAmmo") then
			UpdateInventory()
		else
			CombatFrame.Ammo.Visible = false
		end

		local weapon = weaponsDef[toolName]
		local attackR = attacksModule[weapon.WeaponAttacks[Enum.KeyCode.R.Name].Name]
		local attackF = attacksModule[weapon.WeaponAttacks[Enum.KeyCode.F.Name].Name]
		local attackG = attacksModule[weapon.WeaponAttacks[Enum.KeyCode.G.Name].Name]

		AttacksFrame.AttackR.ImageRectOffset = Vector2.new(attackR.ImageOffsetX,attackR.ImageOffsetY)
		AttacksFrame.AttackF.ImageRectOffset = Vector2.new(attackF.ImageOffsetX,attackF.ImageOffsetY)
		AttacksFrame.AttackG.ImageRectOffset = Vector2.new(attackG.ImageOffsetX,attackG.ImageOffsetY)

	else
		game:GetService("ContextActionService"):UnbindAction("HandleInputE")
		game:GetService("ContextActionService"):UnbindAction("HandleInputF")
		game:GetService("ContextActionService"):UnbindAction("HandleInputG")
		game:GetService("ContextActionService"):UnbindAction("HandleInputR")
		game:GetService("ContextActionService"):UnbindAction("HandleInputMouse")

		CombatGui.Enabled = false

		if (inputEvent ~= nil) then
			inputEvent:Disconnect()
		end
	end
end)

local step_counter = 0
local timeChangeInterval = 1

RunService.Heartbeat:Connect(function(step)

	if (AttacksFrame["AttackF"].HideFrame.Size.Y.Scale == 1) then
		AttacksFrame["AttackF"].HideFrame.Size = UDim2.new(1,0,0,0)
	end

	if (AttacksFrame["AttackG"].HideFrame.Size.Y.Scale == 1) then
		AttacksFrame["AttackG"].HideFrame.Size = UDim2.new(1,0,0,0)
	end

	step_counter = step_counter + step  --step is time in seconds since the previous frame
	if step_counter >= timeChangeInterval then
		step_counter = step_counter - timeChangeInterval

		if ((activeWeapon ~= nil) and weaponsDef[activeWeapon].SubType ~= "Trap") then

			--Handle auto weapons
			if (weaponsDef[activeWeapon].Auto == true and activeAutoWeaponOn == true) then
				mouseHitPosition = getMouseHitPosition()

				PlayerInputEvent:FireServer(Enum.KeyCode.G,mouseHitPosition)
			end
		end
	end



end)

clientPlayerHitEvent.OnClientEvent:Connect(function(health,totalHealth,damage,damageType)
	if (character.skull ~= nil) then
		if (character.skull.Hit ~= nil) then
			if (damageType) then
				if (damageType == "Bleed") then
					character.skull.Bleed:Emit(1)
				elseif (damageType == "Poison") then
					character.skull.Poison:Emit(1)
				else
					character.skull.Hit:Emit(1)
				end
			else
				character.skull.Hit:Emit(1)
			end

		end
	end
end)
