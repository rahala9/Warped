--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local addEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("AddEffect")
local removeEffectEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveEffect")
--local TalkToNPCEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("TalkToNPC")
local RemoveItemFromServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("RemoveItemFromServer")
local PlayerHitEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("PlayerHit")	
local UpdateStaminaEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateStamina")
local UpdateHealthEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateHealth")
local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")
local ProfileLoadedEvent = ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")

--Functions
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)
local AttributesFunctions = require(ServerScriptService.Data.DataAttributesFunctions)
local CharacterFunctions = require(ServerScriptService.Data.DataCharacterFunctions)
local EnemyFunctions = require(ServerScriptService.SharedFunctions.EnemyFunctions)

--Definition Modules
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local EffectsDef = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects")) --generic defs
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies"))
--local NPCDialog = require(ServerStorage.Data.Templates.NPCDialog)

--Assets
local icons = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("Icons")
local VFX = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("VFX")

--Modules
local Data = require(ServerScriptService.Data.Data)
local Logger = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Logger"))

local Effects = {}
local functions = {}

function EnableStates(player,enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.FallingDown, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Running, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Jumping, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.GettingUp, enabled)
	player.Character:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Freefall, enabled)
end

--Used to create new threads easily while avoid spawn()
function spawner(func,...)
	local co = coroutine.wrap(func)
	co(...)
end

function functions.GetEffects(player)

	if (Effects[player.Name] == nil) then return nil end

	return Effects[player.Name]
end

function functions.HasEffect(player,effectName,checkResultsOfEffect)

	if(not player) then return end

	if (Effects[player.Name] == nil) then return nil end

	--If we already have the results of the effect and caller wants to check that
	--then we can say we already have the effect
	if (checkResultsOfEffect) then
		if (EffectsDef[effectName].Effect.Type == "Stamina" and EffectsDef[effectName].Effect.Action == "Subtract" and (StatesFunctions.GetStamina(player) < 10)) then
			return true
		end
	end


	return (Effects[player.Name][effectName] ~= nil)
end

function functions.RemoveEnemyEffectUI(enemy,effectName)

	local effectsFrame = enemy.root.EnemyHealth.EffectsFrame

	for _, effectIcon in pairs(effectsFrame:GetChildren()) do
		if (effectIcon.Name == effectName) then
			effectIcon:Destroy()
		end
	end

end

function functions.AddEnemyEffectUI(enemy,effect)

	if (enemy.health.main <= 0) then
		return
	end

	local effectsFrame = enemy.root.EnemyHealth.EffectsFrame
	local EffectIcon = Instance.new("ImageLabel")

	EffectIcon.Name = effect.Name
	EffectIcon.Size = UDim2.new(0,16,0,16)
	--EffectIcon.BackgroundTransparency = .1
	--EffectIcon.BackgroundColor3 = Color3.new(0.109804, 1, 0.0980392)
	local icon = icons:FindFirstChild(effect.Name.."Icon")
	if (icon ~= nil) then
		EffectIcon.Image = icon.Image
		EffectIcon.ImageRectOffset = icon.ImageRectOffset
		EffectIcon.ImageRectSize = icon.ImageRectSize
	end

	EffectIcon.Parent = effectsFrame

	local effectCorners = Instance.new("UICorner")
	effectCorners.Parent = EffectIcon

	local effectStroke = Instance.new("UIStroke")
	effectStroke.Thickness = 2
	effectStroke.Parent = EffectIcon

	local effectTime = Instance.new("TextLabel")
	effectTime.Name = "EffectTime"
	effectTime.Position = UDim2.new(.9,0,.9,0)
	effectTime.Size = UDim2.new(.1,0,.1,0)
	effectTime.TextColor3 = Color3.fromRGB(255,255,255)
	effectTime.TextSize = 14
	effectTime.Font = Enum.Font.SourceSansBold
	effectTime.Text = effect.Effect.TimeInEffect
	effectTime.Parent = EffectIcon
end

function functions.AddEnemyEffect(player,enemy,effectName,weapon,attack)

	--if (Effects[effectName] == nil) then
	--	--TODO ADD WARNING
	--	return
	--end

	if (enemy.health.main <= 0) then
		return
	end

	--Check to see if we already have this effect
	if (enemy.Effects[effectName] == nil) then

		enemy.Effects[effectName]=EffectsDef[effectName]
		enemy.Effects[effectName].Effect.Amount = enemy.Effects[effectName].Effect.Amount -- * ProgressFunctions.GetLevel(player)
		enemy.Effects[effectName].Effect.TimeStarted = os.time()

		--TODO PERFORMANCE perhaps could be wrapped up into the enemyAI or statemachine
		spawner(function()

			while enemy.health.main > 0 do
				if (EffectsDef[effectName].Effect.Action == "DOT") then

					local totalDamage = 0

					if (weapon and attack) then
						totalDamage = math.ceil((EffectsDef[effectName].Effect.Amount * EnemyFunctions.CalculateDamage(player,weapon,attack)) / EffectsDef[effectName].Effect.TimeInEffect)
					else
						totalDamage = EffectsDef[effectName].Effect.Amount
					end

					EnemyFunctions.HandleBodyPartHit(player,enemy,nil,nil,totalDamage)
				elseif (EffectsDef[effectName].Effect.Type=="Movement") then
					if (EffectsDef[effectName].Effect.Amount == 0) then
						enemy.char.PrimaryPart.Anchored = true
						enemy.human.WalkSpeed = EffectsDef[effectName].Effect.Amount
					else
						enemy.human.WalkSpeed = EffectsDef[effectName].Effect.Amount --TODO is this default and what if we need to restore faster previous speed?
					end
				elseif(EffectsDef[effectName].Effect.Type == "DestroyItem" and EffectsDef[effectName].Effect.Action == "ExplodeWeapon") then

					local states = StatesFunctions.GetState(player)
					local currentToolName = states.CurrentTool

					if (player.Character) then
						local currentTool = player.Character:FindFirstChild(itemsmodule[currentToolName].Model)

						if (currentTool) then
							local explosionEmitter = currentTool:FindFirstChild("ExplosionEmitter")
							if (explosionEmitter) then
								Debris:AddItem(currentTool,1)

								RemoveItemFromServerEvent:Fire(player,currentToolName)

								explosionEmitter.Enabled = true
								explosionEmitter:Emit(1)
								explosionEmitter.Enabled = false

							end
						end
					end


				end

				if ((os.time() - enemy.Effects[effectName].Effect.TimeStarted) >= enemy.Effects[effectName].Effect.TimeInEffect) then
					functions.RemoveEnemyEffect(enemy,effectName)
					break
				end

				wait(1)
			end

		end)

		--Show effects on enemies
		functions.AddEnemyEffectUI(enemy,EffectsDef[effectName])
	end 

end

function functions.HandleVFX(player,effectName)
	--Handle VFX (particles)
	if (EffectsDef[effectName].Effect["VFX"] ~= nil) then
		local fx = VFX:FindFirstChild(EffectsDef[effectName].Effect.VFX):Clone()
		if (fx) then
			if (fx:IsA("Model")) then

				if (EffectsDef[effectName].Effect.Type=="Movement") then
					--We need to anchor early here to have correct position
					player.Character.PrimaryPart.Anchored = true
				end

				local attachment = fx.PrimaryPart:FindFirstChildOfClass("Attachment")

				--weld the fx model to the character using a weldconstraint but position it so the attachment is at center of character primary part
				local weld = Instance.new("WeldConstraint")
				weld.Parent = fx
				weld.Part0 = fx.PrimaryPart
				weld.Part1 = player.Character.PrimaryPart
				weld.Enabled = true
				fx:SetPrimaryPartCFrame(player.Character.PrimaryPart.CFrame * attachment.CFrame:Inverse())
				--player.Character:SetPrimaryPartCFrame(CFrame.new(Vector3.new(attachment.WorldPosition.X,player.Character.PrimaryPart.Position.Y,attachment.WorldPosition.Z)))
				-- Create a new CFrame with the new position but keep the original rotation
				local newCFrame = CFrame.new( attachment.WorldPosition.X, player.Character.PrimaryPart.Position.Y,  attachment.WorldPosition.Z) * CFrame.Angles(player.Character.PrimaryPart.CFrame:ToEulerAnglesXYZ())

				-- Set the PrimaryPart CFrame
				player.Character:SetPrimaryPartCFrame(newCFrame)
				fx.Parent = player.Character.PrimaryPart

			else
				fx.Parent = player.Character.PrimaryPart

			end
		end
	end
end

local function HandleSkeletonTransparency(player,electricOn,bodyTransparency,noskeleton)
	if (not noskeleton) then
		player.Character.Skeleton.Transparency = 1 - electricOn
	end

	player.Character.face.faceTexture.Transparency = electricOn
	player.Character.face.Transparency = bodyTransparency * electricOn
	player.Character.neck.Transparency = bodyTransparency * electricOn
	player.Character.scalp.Transparency = bodyTransparency * electricOn
	player.Character.skull.Transparency = bodyTransparency * electricOn
	for _,part in ipairs(player.Character:GetChildren()) do
		if (part:IsA("MeshPart") and part.Name ~= "Skeleton") then
			if (string.match(part.Name, "^".."kid")) then
				part.Transparency = bodyTransparency * electricOn
			elseif (string.match(part.Name, "^".."hair")) then
				if (bodyTransparency > 0) then
					part.Transparency = 1 -- Hair is always totally invisible		
				else
					part.Transparency = 0
				end

			else
				--part.Transparency = electricOn
			end
		end
	end
end

function functions.AddSkeleton(player)
	if(not player.Character:FindFirstChild("Skeleton")) then
		local skeleton = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Skeleton"):Clone()
		skeleton.RigidConstraint.Attachment0 = skeleton["mixamorig:Hips"]["HipOffset"] --skeleton["mixamorig:Hips"]
		skeleton.RigidConstraint.Attachment1 = player.Character.HumanoidRootPart["mixamorig:Hips"]
		skeleton.CFrame = player.Character.HumanoidRootPart.CFrame
		skeleton.Parent = player.Character
	end
end

function functions.RemoveSkeleton(player)
	if (player.Character:FindFirstChild("Skeleton")) then
		player.Character.Skeleton:Destroy()
	end
end

local function Electricute(player)


	local function updateShock()
		local electricOn = 1
		while functions.HasEffect(player,"ElectricShock") do

			HandleSkeletonTransparency(player,electricOn,.4)

			if (electricOn == 1) then
				player.Character.Skeleton.LightPart.PointLight.Enabled = true
				player.Character.Skeleton.LightPart.PointLight.Brightness = 1 + (math.random() * 0.6)   -- Random flicker within a range

				electricOn = 0
			else
				player.Character.Skeleton.LightPart.PointLight.Enabled = false
				electricOn = 1
			end

			wait(math.random(1,8)*.1) -- Adjust flicker frequency
		end

	end

	coroutine.wrap(updateShock)()
end

function functions.HandleElectricShock(player)
	functions.AddSkeleton(player)
	Electricute(player)
end

function functions.HandleIvisibilityLv1(player)
	functions.AddSkeleton(player)
	HandleSkeletonTransparency(player,1,.6)
end

function functions.HandleIvisibilityLv2(player)
	HandleSkeletonTransparency(player,1,1,true)
end

function functions.AddKuato(player)
	if(not player.Character:FindFirstChild("Kuato")) then
		local kuato = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Kuato"):Clone()
		kuato.RigidConstraint.Attachment0 = kuato.RootPart["mixamorig:Hips"]["HipOffset"] --["HipOffset"] --skeleton["mixamorig:Hips"]
		kuato.RigidConstraint.Attachment1 = player.Character.HumanoidRootPart["mixamorig:Hips"]
		kuato.RootPart.CFrame = player.Character.HumanoidRootPart.CFrame*CFrame.Angles(math.rad(30),0,0)
		kuato.Parent = player.Character

		local kuatoTalkTrack = kuato.AnimationController:LoadAnimation(kuato.KuatoTalk)
		kuatoTalkTrack:Play()

		delay(2,function()
			--TalkToNPCEvent:FireClient(player,"Kuato","Open",NPCDialog["Kuato-OpenYourMind"],"1")
			functions.AddEffect(player,"Smarts")
		end)

	end
end

function functions.RemoveKuato(player)
	if(player.Character:FindFirstChild("Kuato")) then
		local kuato =player.Character:FindFirstChild("Kuato")
		local kuatoTalkTrack = kuato.AnimationController:LoadAnimation(kuato.KuatoTalk)
		kuatoTalkTrack:Stop()
		kuato:Destroy()
	end
end

function functions.HandleOneTimeEffects(player,effectName,sourceLevel,source)

	if (EffectsDef[effectName].Effect.Type == "Health" and EffectsDef[effectName].Effect.Action == "Add") then
		StatesFunctions.AddHealth(player,sourceLevel)
		UpdateHealthEvent:FireClient(player,StatesFunctions.GetHealth(player), AttributesFunctions.GetMaxHealth(player))
		functions.RemoveEffect(player,effectName)
	elseif (EffectsDef[effectName].Effect.Type == "Food" and EffectsDef[effectName].Effect.Action == "Add") then
		StatesFunctions.AddFood(player,sourceLevel)
		--UpdateHealthEvent:FireClient(player,StatesFunctions.GetHealth(player) , 100)
		functions.RemoveEffect(player,effectName)
	elseif (EffectsDef[effectName].Effect.Type == "Hydration" and EffectsDef[effectName].Effect.Action == "Add") then
		StatesFunctions.AddHydration(player,sourceLevel)
		--UpdateHealthEvent:FireClient(player,StatesFunctions.GetHealth(player) , 100)
		functions.RemoveEffect(player,effectName)
	elseif(EffectsDef[effectName].Effect.Type == "DestroyItem" and EffectsDef[effectName].Effect.Action == "ExplodeWeapon") then

		local states = StatesFunctions.GetState(player)
		local currentToolName = states.CurrentTool

		if (player.Character) then
			local currentTool = player.Character:FindFirstChild(currentToolName)
			if (currentTool) then
				local explosionEmitter = currentTool:FindFirstChild("ExplosionEmitter")
				if (explosionEmitter) then
					Debris:AddItem(currentTool,1)
					RemoveItemFromServerEvent:Fire()
					explosionEmitter.Enabled = true
					explosionEmitter:Emit(1)
					explosionEmitter.Enabled = false
				end
			end
		end

	end

end

function functions.HandleUntimedEffects(player,effect,sourceLevel,source)
	if (EffectsDef[effect.Name].Effect.Type == "Movement") then
		player.Character.Humanoid.WalkSpeed = sourceLevel
		PlayerStateChangeEvent:FireClient(player,"Movement",nil,nil,nil,nil,player.Character.Humanoid.WalkSpeed)
	elseif (EffectsDef[effect.Name].Effect.Type == "InvisibilityLv2") then
		functions.HandleIvisibilityLv2(player)
	end

	addEffectEvent:FireClient(player,effect)
end

function functions.AddEffect(player,effectName,sourceLevel,source)

	if (player) and (Effects[player.Name] == nil) then return nil end

	--Logger.Debug("EffectFunctions - AddEffect player:"..player.Name.." effect Name:"..effectName)

	if (EffectsDef[effectName] == nil) then
		warn("EffectsFunctions.AddEffect - EFFECT NAME UNKNOWN:"..effectName)
		return
	end

	--Don't add effect to a dead player
	if (StatesFunctions.GetDead(player)) then
		return
	end


	if (not sourceLevel) then
		sourceLevel = 1
	end

	--Check to see if we already have this effect
	if (Effects[player.Name][effectName] == nil) then

		Effects[player.Name][effectName]=EffectsDef[effectName]
		Effects[player.Name][effectName].Effect.TimeStarted = os.time()
		Effects[player.Name][effectName].Effect.Source = source

		--Effects that are immediate have a time in effect of 0 and do not need to add icon on UI, but should message that it has happened
		--Effects with time in effect of -1 are special effects that stay on until switched out with others or death
		--TODO handle the special effects
		if (EffectsDef[effectName].Effect.TimeInEffect > 0) then

			--One Time effects effects that last for certain time will be done here,
			if (EffectsDef[effectName].Effect.Type=="Size" and EffectsDef[effectName].Effect.Action == "Multiply") then
				local Humanoid = player.Character:FindFirstChild("Humanoid")
				if Humanoid then
					local HS = Humanoid.HeadScale
					local BDS = Humanoid.BodyDepthScale
					local BWS = Humanoid.BodyWidthScale
					local BHS = Humanoid.BodyHeightScale

					HS.Value = HS.Value * EffectsDef[effectName].Effect.Amount
					BDS.Value = BDS.Value * EffectsDef[effectName].Effect.Amount
					BWS.Value = BWS.Value * EffectsDef[effectName].Effect.Amount
					BHS.Value = BHS.Value * EffectsDef[effectName].Effect.Amount


					--local CurrentColumn = (face.X/64) + 1 
					--local CurrentRow =(face.Y/64) + 1 
					local rows = 5
					local columns = 8
					local faceSize = Vector3.new(.85,.85,.85) * EffectsDef[effectName].Effect.Amount
					local faceColumn,faceRow = CharacterFunctions.GetFaceColumnRow(player)

					player.Character.face.faceTexture.StudsPerTileU = columns*faceSize.X
					player.Character.face.faceTexture.StudsPerTileV = rows*faceSize.Y
					player.Character.face.faceTexture.OffsetStudsU = (faceSize.X*(faceColumn))-(faceSize.X/2)
					player.Character.face.faceTexture.OffsetStudsV = (faceSize.Y*(faceRow))-(faceSize.Y/2) + 0.05

					Humanoid.HipHeight = EffectsDef[effectName].Effect.Amount
				end
			elseif (EffectsDef[effectName].Effect.Type == "Stability" and EffectsDef[effectName].Effect.Action == "Subtract") then

				PlayerStateChangeEvent:FireClient(player,"KnockedDown")

			elseif (EffectsDef[effectName].Effect.Type == "Strength" and EffectsDef[effectName].Effect.Action == "Add") then

				StatesFunctions.AddStrength(player,EffectsDef[effectName].Effect.Amount)

			elseif (EffectsDef[effectName].Effect.Type == "Strength" and EffectsDef[effectName].Effect.Action == "Subtract") then

				StatesFunctions.RemoveStrength(player,EffectsDef[effectName].Effect.Amount)

			elseif (EffectsDef[effectName].Effect.Type == "RemoveEffects") then

				for i, effectName in pairs(EffectsDef[effectName].Effect.EffectsRemoved) do
					functions.RemoveEffect(player,effectName)
				end
			elseif (EffectsDef[effectName].Effect.Type == "InvisibilityLv1") then
				functions.HandleIvisibilityLv1(player)
			elseif (EffectsDef[effectName].Effect.Type == "InvisibilityLv2") then
				functions.HandleIvisibilityLv2(player)
			elseif (EffectsDef[effectName].Effect.Type == "Kuato") then
				functions.AddKuato(player)
			end

			functions.SetEffect(player,Effects[player.Name][effectName],sourceLevel)

		elseif (EffectsDef[effectName].Effect.TimeInEffect == 0) then	
			functions.HandleOneTimeEffects(player,effectName,sourceLevel,source)
		elseif (EffectsDef[effectName].Effect.TimeInEffect == -1) then	
			functions.HandleUntimedEffects(player,Effects[player.Name][effectName],sourceLevel,source)
		else

			--TODO check if effect type has a corresponding stat and that stat is full/max then don't message the effect increase here

			if (Effects[player.Name][effectName].Effect.Amount) then
				if (Effects[player.Name][effectName].Effect.Amount > 0) then
					MessagePlayerEvent:FireClient(player,"+"..Effects[player.Name][effectName].Effect.Amount.." "..Effects[player.Name][effectName].Effect.Type) --TODO maybe green for effects?
				else
					MessagePlayerEvent:FireClient(player,""..Effects[player.Name][effectName].Effect.Amount.." "..Effects[player.Name][effectName].Effect.Type) --TODO maybe green for effects?
				end
			end

		end

		functions.HandleVFX(player,effectName)

	end 
end

function functions.RemoveAllEffects(player)

	if (Effects[player.Name] == nil) then return nil end

	for i, effect in pairs(Effects[player.Name]) do
		functions.RemoveEffect(player,effect.Name)
	end
end

function functions.RemoveEffect(player,effectName,source)

	if (Effects[player.Name] == nil) then return nil end

	if (EffectsDef[effectName] == nil) then
		--TODO ADD WARNING
		return
	end

	if (effectName == "ElectricShock") then
		HandleSkeletonTransparency(player,0,.4)
		functions.RemoveSkeleton(player)
	elseif (effectName == "InvisibilityLv1") then
		HandleSkeletonTransparency(player,0,.4)
		functions.RemoveSkeleton(player)
	elseif (effectName == "InvisibilityLv2") then
		HandleSkeletonTransparency(player,0,0,true)
	elseif (effectName == "Kuato") then
		functions.RemoveKuato(player)
	end

	--Check to see if we have this effect active
	if (Effects[player.Name][effectName] ~= nil and Effects[player.Name][effectName].Effect.Source == source) then

		if (Effects[player.Name][effectName].Effect.Type=="Movement") then
			if (EffectsDef[effectName].Effect.Amount == 0) then

				player.Character.PrimaryPart.Anchored = false
				EnableStates(player,true)
				player.Character.Humanoid.Sit = false
			else

				player.Character.Humanoid.WalkSpeed = 16
				PlayerStateChangeEvent:FireClient(player,"Movement",nil,nil,nil,nil,player.Character.Humanoid.WalkSpeed)
			end
		end

		if (Effects[player.Name][effectName].Effect.Type=="Stability") then
			if (EffectsDef[effectName].Effect.Amount == 100) then

				player.Character.PrimaryPart.Anchored = false
				EnableStates(player,true)
				player.Character.Humanoid.Sit = false

				PlayerStateChangeEvent:FireClient(player,"Standing")
			else
				player.Character.Humanoid.WalkSpeed = 16
				PlayerStateChangeEvent:FireClient(player,"Movement",nil,nil,nil,nil,player.Character.Humanoid.WalkSpeed)
			end
		end

		if (EffectsDef[effectName].Effect.Type=="Size" and EffectsDef[effectName].Effect.Action == "Multiply") then
			local Humanoid = player.Character:FindFirstChild("Humanoid")
			if Humanoid then
				local HS = Humanoid.HeadScale
				local BDS = Humanoid.BodyDepthScale
				local BWS = Humanoid.BodyWidthScale
				local BHS = Humanoid.BodyHeightScale

				HS.Value = HS.Value * (1/EffectsDef[effectName].Effect.Amount)
				BDS.Value = BDS.Value * (1/EffectsDef[effectName].Effect.Amount)
				BWS.Value = BWS.Value * (1/EffectsDef[effectName].Effect.Amount)
				BHS.Value = BHS.Value * (1/EffectsDef[effectName].Effect.Amount)

				CharacterFunctions.SetFace(player)

				Humanoid.HipHeight = 2.65
			end
		end

		functions.UnsetEffect(player,Effects[player.Name][effectName])

		Effects[player.Name][effectName] = nil --TODO do we need to remove from table some other way?

		--Handle VFX (particles)
		if (EffectsDef[effectName].Effect["VFX"] ~= nil) then

			local fx = player.Character.PrimaryPart:FindFirstChild(EffectsDef[effectName].Effect.VFX)
			if (fx) then

				fx:Destroy()
			end
		end

	end 

end

function functions.RemoveEnemyEffect(enemy,effectName)
	--TODO add handling to restore movement or other stats
	if (EffectsDef[effectName] == nil) then
		--TODO ADD WARNING
		return
	end

	if (enemy.Effects[effectName].Effect.Type=="Movement") then
		if (enemy.Effects[effectName].Effect.Amount == 0) then
			enemy.char.PrimaryPart.Anchored = false
			enemy.human.WalkSpeed = enemy.WalkSpeed --TODO is this default and what if we need to restore faster previous speed?
		else
			enemy.human.WalkSpeed = enemy.WalkSpeed --TODO is this default and what if we need to restore faster previous speed?
		end

	end

	--Check to see if we have this effect active
	if (enemy.Effects[effectName] ~= nil) then
		--functions.UnsetEffect(player,profile.Data.Effect[effectName])

		enemy.Effects[effectName] = nil --TODO do we need to remove from table some other way?

	end 

	functions.RemoveEnemyEffectUI(enemy,effectName)
end

function functions.SetEffect(player,effect,sourceLevel)
	Logger.Debug("EffectFunctions - SetEffect player:"..player.Name.." effect Name:"..effect.Name.." sourceLevel:"..sourceLevel)

	spawner(function()

		while not StatesFunctions.GetDead(player) do
			if (effect.Effect.Action == "DOT") then
				--TODO SECURITY need to take down player server health 
				local totalDamage = EffectsDef[effect.Name].Effect.Amount * sourceLevel --(sourceLevel*sourceLevel)

				--Custom electric shock effect
				if (effect.Name == "ElectricShock") then
					functions.HandleElectricShock(player)
				end

				Logger.Debug("EffectFunctions - SetEffect firing PlayerHitEvent")

				PlayerHitEvent:Fire(player, totalDamage,nil,effect.Name)

			elseif (effect.Effect.Type=="Movement") then
				if (effect.Effect.Amount == 0) then
					player.Character.PrimaryPart.Anchored = true
					player.Character.Humanoid.Sit = true
					EnableStates(player,false)
				else
					player.Character.Humanoid.WalkSpeed = effect.Effect.Amount*sourceLevel
					PlayerStateChangeEvent:FireClient(player,"Movement",nil,nil,nil,nil,player.Character.Humanoid.WalkSpeed)
				end
			elseif (effect.Effect.Type=="Stability") then
				if (effect.Effect.Amount == 100) then
					player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
					--player.Character.Humanoid.HipHeight = 0 --2.65
					--wait(1)
					player.Character.PrimaryPart.Anchored = true
					player.Character.Humanoid.Sit = true
					EnableStates(player,false)
				else
					player.Character.Humanoid.WalkSpeed = effect.Effect.Amount*sourceLevel
					PlayerStateChangeEvent:FireClient(player,"Movement",nil,nil,nil,nil,player.Character.Humanoid.WalkSpeed)
				end	
			elseif (effect.Effect.Type=="Stamina" and effect.Effect.Action == "AddOverTime") then
				if (StatesFunctions.GetStamina(player) < 100) then --TODO remove hardcode
					StatesFunctions.AddStamina(player,effect.Effect.Amount)
					UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , 100)
				end
			elseif (effect.Effect.Type=="Stamina" and effect.Effect.Action == "SubtractOverTime") then
				if (StatesFunctions.GetStamina(player) > 0) then --TODO remove hardcode
					StatesFunctions.RemoveStamina(player,effect.Effect.Amount)
					UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , 100)
				end
			elseif (effect.Effect.Type=="Stamina" and effect.Effect.Action == "Subtract") then
				if (StatesFunctions.GetStamina(player) > 0) then --TODO remove hardcode
					StatesFunctions.AddStamina(player,effect.Effect.Amount)
					UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , 100)
				end
			elseif (effect.Effect.Type=="Health" and effect.Effect.Action == "Add") then 
				if StatesFunctions.GetHealth(player) < AttributesFunctions.GetMaxHealth(player) then
					StatesFunctions.AddHealth(player,effect.Effect.Amount)
					UpdateHealthEvent:FireClient(player,StatesFunctions.GetHealth(player), AttributesFunctions.GetMaxHealth(player))
					functions.RemoveEffect(player,effect.Name)
				end

			end

			--Remove any effect that is complete
			if (effect~= nil and (os.time() - effect.Effect.TimeStarted) >= effect.Effect.TimeInEffect) then
				functions.RemoveEffect(player,effect.Name)
				break
			end

			task.wait(1)
		end

		Logger.Debug("EXITING EFFECT LOOP Player Dead status:",StatesFunctions.GetDead(player))

	end)

	addEffectEvent:FireClient(player,effect)
end

function functions.UnsetEffect(player,effect)
	--Logger.Debug("EffectFunctions - UnsetEffect player:"..player.Name.." effect Name:"..effect.Name)

	removeEffectEvent:FireClient(player,effect)
end


function onProfileLoaded(player)
	Effects[player.Name] = {}
end

Players.PlayerRemoving:Connect(function(player)
	Effects[player.Name] = nil
end)

ProfileLoadedEvent.Event:Connect(onProfileLoaded)


return functions
