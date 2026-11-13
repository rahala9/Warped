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
local WeaponEnergyEvent = ReplicatedStorage_SharedRemotes:WaitForChild("WeaponEnergy")
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
local AmmoFrame = CombatFrame:WaitForChild("Ammo")
local playerGui = player:WaitForChild("PlayerGui")

local EnergyFrame = CombatFrame:FindFirstChild("Energy")
if not EnergyFrame then
	EnergyFrame = Instance.new("Frame")
	EnergyFrame.Name = "Energy"
	EnergyFrame.AnchorPoint = AmmoFrame.AnchorPoint
	EnergyFrame.Position = AmmoFrame.Position
	EnergyFrame.Size = UDim2.fromOffset(190, 48)
	EnergyFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 31)
	EnergyFrame.BackgroundTransparency = 0.12
	EnergyFrame.BorderSizePixel = 0
	EnergyFrame.ZIndex = 10
	EnergyFrame.Parent = CombatFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = EnergyFrame

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.fromRGB(80, 150, 175)
	stroke.Transparency = 0.2
	stroke.Thickness = 1
	stroke.Parent = EnergyFrame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(8, 2)
	title.Size = UDim2.new(1, -16, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.Text = "WEAPON ENERGY"
	title.TextColor3 = Color3.fromRGB(220, 235, 245)
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 11
	title.Parent = EnergyFrame

	local valueLabel = title:Clone()
	valueLabel.Name = "Value"
	valueLabel.Text = "100 / 100"
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = EnergyFrame

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(8, 25)
	bar.Size = UDim2.new(1, -16, 0, 14)
	bar.BackgroundColor3 = Color3.fromRGB(38, 48, 61)
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.ZIndex = 11
	bar.Parent = EnergyFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(55, 225, 255)
	fill.BorderSizePixel = 0
	fill.ZIndex = 12
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
end
EnergyFrame.Visible = false

--Context and Actions

--Initialization

local unequippedEvent = nil
local inputEvent = nil
local activeWeapon = nil
local activeAutoWeaponOn = false
local energyDisplayState = nil

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

local function GetDisplayedEnergy()
	if not energyDisplayState then
		return 0
	end

	local elapsed = os.clock() - energyDisplayState.ReceivedAt
	local recoveryTime = math.max(0, elapsed - energyDisplayState.RecoveryDelayRemaining)
	return math.min(
		energyDisplayState.Capacity,
		energyDisplayState.Energy + (recoveryTime * energyDisplayState.RecoveryRate)
	)
end

local function UpdateEnergyUI()
	if not energyDisplayState or energyDisplayState.WeaponName ~= activeWeapon then
		EnergyFrame.Visible = false
		return
	end

	local energy = GetDisplayedEnergy()
	local capacity = math.max(1, energyDisplayState.Capacity)
	local fraction = math.clamp(energy / capacity, 0, 1)
	EnergyFrame.Bar.Fill.Size = UDim2.fromScale(fraction, 1)
	EnergyFrame.Bar.Fill.BackgroundColor3 = energyDisplayState.Color
	EnergyFrame.Value.Text = string.format("%d / %d", math.floor(energy + 0.5), math.floor(capacity + 0.5))
	EnergyFrame.Visible = true
end

WeaponEnergyEvent.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" or state.WeaponName ~= activeWeapon then
		return
	end

	energyDisplayState = {
		WeaponName = state.WeaponName,
		Energy = state.Energy or 0,
		Capacity = state.Capacity or 100,
		RecoveryRate = state.RecoveryRate or 0,
		RecoveryDelayRemaining = state.RecoveryDelayRemaining or state.RecoveryDelay or 0,
		Color = state.Color or Color3.fromRGB(55, 225, 255),
		ReceivedAt = os.clock(),
	}
	UpdateEnergyUI()

	if state.Depleted then
		local originalColor = EnergyFrame.BackgroundColor3
		EnergyFrame.BackgroundColor3 = Color3.fromRGB(125, 25, 25)
		local warningTween = tweenService:Create(
			EnergyFrame,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = originalColor}
		)
		warningTween:Play()
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
	if (activeWeapon == nil) then
		return
	end

	local elapsedTime = os.clock() - lastFireTime
	local weapon = weaponsDef[activeWeapon]
	if weaponInfo.UsesAmmo(weapon) and playerInventory == nil then
		return
	end

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



	if weaponInfo.UsesAmmo(weapon)
		and playerInventory["Items"][weapon.WeaponAmmo]
		and playerInventory["Items"][weapon.WeaponAmmo].Amount > 0
	then
		playerInventory["Items"][weapon.WeaponAmmo].Amount = playerInventory["Items"][weapon.WeaponAmmo].Amount - 1
	end

	if weaponInfo.UsesAmmo(weapon) then
		UpdateAmmoUI()
	end
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
		local attackConfig = currentTool.WeaponAttacks
			and currentTool.WeaponAttacks[input.KeyCode.Name]
		if not attackConfig then
			return Enum.ContextActionResult.Pass
		end
		local attack = attacksModule[attackConfig.Name]

		--For when you don't want the projectile to come out until a Release point event in the animation
		if (attack and attack.DeferAttack) then

			PlayerState.HandleAttack(currentTool,input.KeyCode,hitPosition)

			return Enum.ContextActionResult.Pass	
		end
	end

	UpdateUI(input.KeyCode)

	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,currentToolName)
	if not ToolTransformedWorldCFrame then
		warn("CombatHandler: no firing position for", currentToolName)
		return
	end

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
		local attackConfig = currentTool.WeaponAttacks
			and currentTool.WeaponAttacks[Enum.KeyCode.R.Name]
		if not attackConfig then
			return
		end
		local attack = attacksModule[attackConfig.Name]

		--For when you don't want the projectile to come out until a Release point event in the animation
		if (attack and attack.DeferAttack) then
			PlayerState.HandleAttack(currentTool,Enum.KeyCode.R,hitPosition)
			UpdateUI(Enum.KeyCode.R)
			return	
		end
	end

	UpdateUI(Enum.KeyCode.R)

	local ToolTransformedWorldCFrame = weaponInfo.GetFiringPosition(player,currentToolName)
	if not ToolTransformedWorldCFrame then
		warn("CombatHandler: no firing position for", currentToolName)
		return
	end

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

		if weaponInfo.IsEnergyWeapon(weaponsDef[toolName]) then
			AmmoFrame.Visible = false
			EnergyFrame.Visible = true
			energyDisplayState = nil
			WeaponEnergyEvent:FireServer("Request", toolName)
		elseif weaponInfo.UsesAmmo(weaponsDef[toolName]) then
			EnergyFrame.Visible = false
			UpdateInventory()
		else
			AmmoFrame.Visible = false
			EnergyFrame.Visible = false
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
		EnergyFrame.Visible = false
		energyDisplayState = nil

		if (inputEvent ~= nil) then
			inputEvent:Disconnect()
		end
	end
end)

local step_counter = 0
local timeChangeInterval = 1

RunService.Heartbeat:Connect(function(step)
	UpdateEnergyUI()

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
