local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local tweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local InventoryFunctions = require(ServerScriptService.InventorySystem.DataInventoryFunctions)
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")
local Debris = game:GetService("Debris")
local enemyFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("EnemyFunctions"))
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local UpdateStaminaEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("UpdateStamina")
local NoAmmoEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("NoAmmo")
local StatesFunctions = require(ServerScriptService.Data.DataStatesFunctions)
local attacksModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Attacks")) 
local FastCast = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("FastCastRedux"))
local PartCacheModule = require(ServerScriptService:WaitForChild("SharedServices"):WaitForChild("PartCache"))
local Replicator =  ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Replicator")
local ToolFunctions = require(ServerScriptService.SharedFunctions:WaitForChild("ToolFunctions"))
local EffectItems = ReplicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("FX")
local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)
local ProgressFunctions = require(ServerScriptService.Data.DataProgressFunctions)

local BoltOnWoodSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("BoltOnWood")
local BoltOnMetalSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("BoltOnMetal")
local EggSplatSoundFX = ReplicatedStorage:WaitForChild("SharedSoundFX"):WaitForChild("EggSplat")

local SharedClientAssets = ReplicatedStorage:WaitForChild("SharedClientAssets")
local GrassFX = SharedClientAssets:WaitForChild("VFX"):WaitForChild("Grass")
local DirtFX = SharedClientAssets:WaitForChild("VFX"):WaitForChild("Dirt")

local PoisonGas = SharedClientAssets:WaitForChild("VFX"):WaitForChild("PoisonGas")

local Sounds =  ReplicatedStorage:WaitForChild("SharedSoundFX")

local PlayerStateChangeEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerStateChange")

local Players = game:GetService("Players")
--local StickDartEvent = ReplicatedStorage:WaitForChild("StickDart")

--9535119139
--rbxassetid://9522950028
local defaultHitSound = BoltOnWoodSoundFX

local ammo = {["Rock"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Rock"),Stick=false,Trail=true},
["NoAmmo"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Rock"),Stick=false},
["Dart"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Dart"),Stick=true,BreakableMaterials={["None"]=true},Rotate=true},
["Laser"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Laser"),Stick=false,Destroy=true,BreakableMaterials={["None"]=true},Rotate=true,Gravity=Vector3.new(0,0,0)},
["Harpoon"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Harpoon"),Stick=true,StickOffset=1.5,RotateStickTwo=true,BreakableMaterials={["None"]=true},Rotate=false,Gravity=Vector3.new(0,0,0),Ripple=true,Splash=true,Rope=true},
["Bolt"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Bolt"),Stick=true,RotateStickTwo=true,DefaultSoundFX=BoltOnWoodSoundFX,SoundFXOnWood=BoltOnWoodSoundFX,SoundFXOnMetal=BoltOnMetalSoundFX,BreakableMaterials={["Glass"]=true}},
["Glue"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Glue"),Stick=true,RotateStickOne=true},
["Egg"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Egg"),Stick=true,RotateStickThree=true,DefaultSoundFX=EggSplatSoundFX,Trail=true},
["Shuriken"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("Shuriken"),Stick=true,RotateStickThree=true,DefaultSoundFX=BoltOnWoodSoundFX,SoundFXOnWood=BoltOnWoodSoundFX,SoundFXOnMetal=BoltOnMetalSoundFX,BreakableMaterials={["Glass"]=true},Trail=true},
["LawnDart"]={Item=SharedClientAssets:WaitForChild("Ammo"):WaitForChild("LawnDart"),Stick=true,Rotate=false,RotateStickThree=true,BreakableMaterials={["Glass"]=true}}}


local DEBUG = false								-- Whether or not to use debugging features of FastCast, such as cast visualization.
local BULLET_SPEED = 200							-- Studs/second - the speed of the bullet
local BULLET_MAXDIST = 1000							-- The furthest distance the bullet can travel 
local BULLET_GRAVITY = Vector3.new(0, -workspace.Gravity*.5, 0)		-- The amount of gravity applied to the bullet in world space (so yes, you can have sideways gravity)
local MIN_BULLET_SPREAD_ANGLE = 1					-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The least accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. Generally you want to keep this at 0 so there's at least some chance of a 100% accurate shot.
local MAX_BULLET_SPREAD_ANGLE = 4					-- THIS VALUE IS VERY SENSITIVE. Try to keep changes to it small. The most accurate the bullet can be. This angle value is in degrees. A value of 0 means straight forward. This cannot be less than the value above. A value of 90 will allow the gun to shoot sideways at most, and a value of 180 will allow the gun to shoot backwards at most. Exceeding 180 will not add any more angular varience.
local FIRE_DELAY = 0								-- The amount of time that must pass after firing the gun before we can fire again.
local BULLETS_PER_SHOT = 1							-- The amount of bullets to fire every shot. Make this greater than 1 for a shotgun effect.
local PIERCE_DEMO = true							-- True if the pierce demo should be used. See the CanRayPierce function for more info.

local CanFire = true								-- Used for a cooldown.

local RNG = Random.new()							-- Set up a randomizer.
local TAU = math.pi * 2							-- Set up mathematical constant Tau (pi * 2)
FastCast.DebugLogging = false
FastCast.VisualizeCasts = false

-- Cast Objects

-- Cosmetic bullet container

local SharedWorkspaceItems = workspace:WaitForChild("SharedWorkspaceItems")

local DartBulletsFolder = SharedWorkspaceItems:FindFirstChild("DartBulletsFolder")
local LaserBulletsFolder = SharedWorkspaceItems:FindFirstChild("LaserBulletsFolder")
local HarpoonBulletsFolder = SharedWorkspaceItems:FindFirstChild("HarpoonBulletsFolder")
local BoltBulletsFolder = SharedWorkspaceItems:FindFirstChild("BoltBulletsFolder")
local RockBulletsFolder = SharedWorkspaceItems:FindFirstChild("RockBulletsFolder")
local GlueBulletsFolder = SharedWorkspaceItems:FindFirstChild("GlueBulletsFolder")
local EggBulletsFolder = SharedWorkspaceItems:FindFirstChild("EggBulletsFolder")
local ShurikenBulletsFolder = SharedWorkspaceItems:FindFirstChild("ShurikenBulletsFolder")
local LawnDartBulletsFolder = SharedWorkspaceItems:FindFirstChild("LawnDartBulletsFolder")
local HelperPartsFolder = workspace:WaitForChild("HelperParts")
local BuildBlockersFolder = workspace:WaitForChild("BuildBlockers")

-- Now we set the caster values.
local Caster = FastCast.new() --Create a new caster object.

-- Make a base cosmetic bullet object. This will be cloned every time we fire off a ray.
--local CosmeticBullet = Instance.new("Part")
--CosmeticBullet.Material = Enum.Material.Neon
--CosmeticBullet.Color = Color3.fromRGB(0, 196, 255)
--CosmeticBullet.CanCollide = false
--CosmeticBullet.Anchored = true
--CosmeticBullet.Size = Vector3.new(0.2, 0.2, 2.4)

-- New raycast parameters.
local CastParams = RaycastParams.new()
CastParams.IgnoreWater = true
CastParams.FilterType = Enum.RaycastFilterType.Exclude
CastParams.FilterDescendantsInstances = {}

-- NEW V13.1.0 - PartCache tie-in. If you use the PartCache module to create cosmetic bullets, you can now directly tie that in.
-- Ensure you're using the latest version of PartCache.
local DartPartProvider = PartCacheModule.new(ammo["Dart"].Item, 100, DartBulletsFolder)
local LaserPartProvider = PartCacheModule.new(ammo["Laser"].Item, 100, LaserBulletsFolder)
local HarpoonPartProvider = PartCacheModule.new(ammo["Harpoon"].Item, 100, HarpoonBulletsFolder)
local BoltPartProvider = PartCacheModule.new(ammo["Bolt"].Item, 100, BoltBulletsFolder)
local RockPartProvider = PartCacheModule.new(ammo["Rock"].Item, 100, RockBulletsFolder)
local GluePartProvider = PartCacheModule.new(ammo["Glue"].Item, 100, GlueBulletsFolder)
local EggPartProvider = PartCacheModule.new(ammo["Egg"].Item, 100, EggBulletsFolder)
local ShurikenPartProvider = PartCacheModule.new(ammo["Shuriken"].Item, 100, ShurikenBulletsFolder)
local LawnDartPartProvider = PartCacheModule.new(ammo["LawnDart"].Item, 100, LawnDartBulletsFolder)

local BulletFolders = {["Dart"]=DartBulletsFolder,["Laser"]=LaserBulletsFolder,["Harpoon"]=HarpoonBulletsFolder,["Rock"]=RockBulletsFolder,["Glue"]=GlueBulletsFolder,["Bolt"]=BoltBulletsFolder,["LawnDart"]=LawnDartBulletsFolder,["Egg"]=EggBulletsFolder,["Shuriken"]=ShurikenBulletsFolder}
local PartProviders = {["Dart"]=DartPartProvider,["Laser"]=LaserPartProvider,["Harpoon"]= HarpoonPartProvider,["Rock"]=RockPartProvider,["Glue"]=GluePartProvider,["Bolt"]=BoltPartProvider,["LawnDart"]=LawnDartPartProvider,["Egg"]=EggPartProvider,["Shuriken"]=ShurikenPartProvider}

--local stuckdart =  StuckDartPartProvider:GetPart() 

-- NEW v12.0.0: Casters now use a data packet which can be made like what follows.
-- Check the API for more information: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/fcbehavior
local CastBehavior = FastCast.newBehavior()
CastBehavior.RaycastParams = CastParams
CastBehavior.MaxDistance = BULLET_MAXDIST
--CastBehavior.HighFidelityBehavior = FastCast.HighFidelityBehavior.Always
--CastBehavior.HighFidelitySegmentSize = 2

-- CastBehavior.CosmeticBulletTemplate = CosmeticBullet -- Uncomment if you just want a simple template part and aren't using PartCache
CastBehavior.CosmeticBulletProvider = PartProviders["Dart"] -- Comment out if you aren't using PartCache.
CastBehavior.CosmeticBulletContainer = BulletFolders["Dart"]
CastBehavior.Acceleration = BULLET_GRAVITY
CastBehavior.AutoIgnoreContainer = false -- We already do this! We don't need the default value of true (see the bottom of this script)
-- Cast Objects end

local FXModules = {}
for _, mod in ipairs(ServerScriptService.SharedFX:GetChildren()) do
	if mod:IsA("ModuleScript") and mod.Name ~= "FXTemplate" then
		FXModules[mod.Name] = require(mod)
	end
end

local lastDirection

local R = Random.new()

local CollisionGroup = "Enemy"

local playerLastAttack = {}

local Track

-- A function to play fire sounds.
function PlayFireSound(heldTool)
	local sfx = heldTool:FindFirstChild("Fire")
	if (sfx) then
		sfx:Play()
	end
	--TODO get sounds from weapon type
	
	--local NewSound = FireSound:Clone()
	--NewSound.Parent = Handle
	--NewSound:Play()
	--Debris:AddItem(NewSound, NewSound.TimeLength)
end

function MakeParticleFX(position, normal)
	
	--TODO do for some type of ammo
	
	---- This is a trick I do with attachments all the time.
	---- Parent attachments to the Terrain - It counts as a part, and setting position/rotation/etc. of it will be in world space.
	---- UPD 11 JUNE 2019 - Attachments now have a "WorldPosition" value, but despite this, I still see it fit to parent attachments to terrain since its position never changes.
	--local attachment = Instance.new("Attachment")
	--attachment.CFrame = CFrame.new(position, position + normal)
	--attachment.Parent = workspace.Terrain
	--local particle = ImpactParticle:Clone()
	--particle.Parent = attachment
	--Debris:AddItem(attachment, particle.Lifetime.Max) -- Automatically delete the particle effect after its maximum lifetime.

	---- A potentially better option in favor of this would be to use the Emit method (Particle:Emit(numParticles)) though I prefer this since it adds some natural spacing between the particles.
	--particle.Enabled = true
	--wait(0.05)
	--particle.Enabled = false
end

local part = Instance.new("Part")
part.Name = "START"
part.Anchored = true
part.CanCollide = false
part.BrickColor = BrickColor.Red()
part.Size = Vector3.new(1,1,1)
part.Parent = workspace

local EndPart = Instance.new("Part")
EndPart.Name = "END"
EndPart.Anchored = true
EndPart.CanCollide = false
EndPart.BrickColor = BrickColor.Blue()
EndPart.Size = Vector3.new(1,1,1)
EndPart.Parent = workspace

local function HandleAutoMelee(player,weapon,keycode, mouseHit, heldToolName)
	local character = player.Character
	local attack = attacksModule[weapon.WeaponAttacks[keycode.Name].Name]
	
	local handle = ToolFunctions.GetToolHandle(player,heldToolName)
	local HeldToolTransformedWorldCFrame = handle.TransformedWorldCFrame

	local origin = HeldToolTransformedWorldCFrame.p -- + ToolTransformedWorldCFrame.LookVector --+Vector3.new(0,.6,0)
	
	--local look = handle.TransformedWorldCFrame.lookVector
		 
	--	--Backward (negative or 'opposite' of lookVector)
	--local back = -handle.TransformedWorldCFrame.lookVector
		 
	--	--Left (gets the lookVector of a CFrame rotated 90 degrees to the left)
	--local left = (handle.TransformedWorldCFrame * CFrame.Angles(0, math.rad(90), 0)).lookVector
		 
	--	--Right (same as left, but negative. thus the opposite of left, which is right.)
	--local right = -(handle.TransformedWorldCFrame * CFrame.Angles(0, math.rad(90), 0)).lookVector
	--local up = handle.TransformedWorldCFrame.UpVector
	local down = -handle.TransformedWorldCFrame.UpVector
	
	local tipPosition = (origin - down)
	
	local direction = (tipPosition - origin).Unit * 10
	
	--part.Position = origin
	--EndPart.Position = tipPosition
		
	local list = {player.Character,DartBulletsFolder,LaserBulletsFolder,RockBulletsFolder,BoltBulletsFolder,EggBulletsFolder,HarpoonBulletsFolder,ShurikenBulletsFolder,LawnDartBulletsFolder,GlueBulletsFolder,HelperPartsFolder,BuildBlockersFolder}
	table.insert(list,workspace.Zones)
	table.insert(list,workspace.Terrain)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = list
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local Raycast = workspace:Raycast(origin, direction, params)

	if Raycast then

		local HitPart = Raycast.Instance
		
		if HitPart ~= nil and HitPart.Parent ~= nil then -- Test if we hit something

			local enemy = enemyFunctions.GetEnemy(HitPart.Parent)

			if (enemy ~= nil) then
				
				enemyFunctions.HandleBodyPartHit(player, enemy,weapon,attack)

				--MakeParticleFX(HitPart, normal) -- Particle FX
			end

			enemyFunctions.HandleEnvironmentalTarget(player,HitPart.Parent)


		end
	end
	
	if (attack.SoundFX ~= nil) then
		local weaponItem = character:FindFirstChild(weapon.Name)

		if (weaponItem) then
			local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
			if (soundFX) then
				if (not soundFX.IsPlaying) then
					soundFX:Play()
				end
			end
		end
	end
	
	InventoryFunctions.RemoveItem(player,weapon.WeaponAmmo,1,true)
end

local function HandleVFX(player, weapon, keycode)
	
	if (not itemsmodule[weapon.Name]["VFX"]) then
		return
	end
	
	--Maybe move to toolfunctions
	local modelName = weapon.Model
	
	local hand = itemsmodule[weapon.Name].Hand
	if (hand == nil) then
		hand = "Right"
	end

	local leftHand = player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_L"]["Shoulder_L"]["Elbow_L"]["Hand_L"]
	local rightHand =  player.Character.HumanoidRootPart["Root"]["Hips"]["Spine_01"]["Spine_02"]["Spine_03"]["Clavicle_R"]["Shoulder_R"]["Elbow_R"]["Hand_R"]

	if (hand == "Left") then
		if (leftHand[weapon.Model.."Handle"]) then
			if (leftHand[weapon.Model.."Handle"][weapon.Name.."Particles"]) then
				leftHand[weapon.Model.."Handle"][weapon.Name.."Particles"]:Emit(10)
			end
		end
	elseif (hand =="Right") then
		if (rightHand[weapon.Model.."Handle"]) then
			if (weapon.Name == "DeathRay" and rightHand[weapon.Model.."Handle"].Attachment) then

				--TODO Will need to be made more generic. Right now it is specific to the DeathRay
				spawn(function()
					rightHand[weapon.Model.."Handle"].Attachment[weapon.Name.."Particles1"]:Emit(300)
					rightHand[weapon.Model.."Handle"].Attachment[weapon.Name.."Particles2"]:Emit(1000)
					wait(.1)
					rightHand[weapon.Model.."Handle"].Attachment[weapon.Name.."Particles2"]:Emit(1000)
					wait(.1)
					rightHand[weapon.Model.."Handle"].Attachment[weapon.Name.."Particles2"]:Emit(1000)
					wait(.1)
					rightHand[weapon.Model.."Handle"].Attachment[weapon.Name.."Particles2"]:Emit(1000)
				end)
			elseif (rightHand[weapon.Model.."Handle"][weapon.Name.."Particles"]) then
				rightHand[weapon.Model.."Handle"][weapon.Name.."Particles"]:Emit(10)
			end
			
		end
	elseif (hand =="Both") then
		if (leftHand[weapon.Model.."LeftHandle"]) then
			if (leftHand[weapon.Model.."LeftHandle"][weapon.Name.."Particles"]) then
				leftHand[weapon.Model.."LeftHandle"][weapon.Name.."Particles"]:Emit(10)
			end
		end
		if (rightHand[weapon.Model.."RightHandle"]) then
			if (rightHand[weapon.Model.."RightHandle"][weapon.Name.."Particles"]) then
				rightHand[weapon.Model.."RightHandle"][weapon.Name.."Particles"]:Emit(10)
			end
		end
	end
	
end


local function HandleMelee(player, weapon, keycode)
	local character = player.Character
	local fieldOfView = 45
	
	
	local attack = attacksModule[weapon.WeaponAttacks[keycode.Name].Name]
	
	PlayerStateChangeEvent:FireClient(player,"Attacking",attack)
	
	if (attack.SoundFX ~= nil) then
		local weaponItem = character:FindFirstChild(weapon.Name)
		
		if (weaponItem) then
			local soundFX = weaponItem:FindFirstChild(attack.Name)
			if (soundFX) then
				soundFX:Play()
			end
		end
	end
	
	--local animation = Instance.new("Animation")
	--animation.AnimationId = "http://www.roblox.com/asset/?id="..attack.Animation
	--Track = character.Humanoid:LoadAnimation(animation) --TODO load all of these at start up.
	--wait(Track.Length/2) -- TODO move everything to spawned routine and use key events
	
	HandleVFX(player, weapon, keycode)
	
	local numberOfTargets = 0
	
	--TODO See how long this takes and perhaps check enemies in same zone
	for _,enemy in pairs(enemyFunctions.GetEnemies()) do

		local distance = (enemy.root.Position - player.Character.PrimaryPart.Position).magnitude

		--TODO this may need to be based on length of weapon
		
		if (distance < (enemy.hitRange)) then


			local npcToCharacter = (character.HumanoidRootPart.Position - enemy.root.Position).Unit
			local npcLook = character.HumanoidRootPart.CFrame.LookVector

			local dotProduct = npcToCharacter:Dot(npcLook)


			--TODO is this good or need adjusted?
			if (dotProduct < .3)  then
				
				numberOfTargets = numberOfTargets + 1
								
				--Check to see if this attack can hit more than one near target
				if (attack.MultiTarget ~= nil) then
					if (numberOfTargets >= attack.MultiTarget) then
						return
					end
					
					--Could send in number of target to reduce damage a bit if it is too overpowered
					enemyFunctions.HandleBodyPartHit(player, enemy,weapon,attack)
					
					--Apply effects if any
					if (attack.Effect and attack.Effect ~= "") then
						EffectsFunctions.AddEnemyEffect(player,enemy,attack.Effect,weapon,attack)
					end
					
				else
					enemyFunctions.HandleBodyPartHit(player, enemy,weapon,attack)
					
					--Apply effects if any
					if (attack.Effect and attack.Effect ~= "") then
						EffectsFunctions.AddEnemyEffect(player,enemy,attack.Effect,weapon,attack)
					end

					return
				end
				
				
				
			end

		end

	end
	
	--TODO get all environmentalTargets and find close ones and handle them
	--enemyFunctions.HandleEnvironmentalTarget(player,hitPart.Parent)
	for i,envTarget in pairs(CollectionService:GetTagged("EnvironmentalTarget")) do
		local distance = (envTarget.PrimaryPart.Position - player.Character.PrimaryPart.Position).magnitude
		
		if (distance < 10) then
			enemyFunctions.HandleEnvironmentalTarget(player,envTarget)
		end
	end
	
end

--function Fire(player,origin,dartDirection, heldTool, weapon, keycode)
	

--	--lastDirection = dartDirection
--	local dart = ammo[weapon.WeaponAmmo]:Clone() --rockAmmo:Clone()
--	dart:SetAttribute("PlayerName",player.Name)
--	dart:SetAttribute("WeaponName",weapon.Name)
--	dart:SetAttribute("AttackName",itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name)
--	dart.Anchored = true
--	dart.CanCollide = false
--	dart.CFrame = CFrame.new(origin,dartDirection)--Tool.Handle.CFrame
--	dart.Position = origin --dart.Position + (dartDirection*2)	
--	dart.Parent = workspace

--	Debris:AddItem(dart, 5)

--	Caster:Fire(origin , dartDirection * 1000, 100, dart, heldTool.Parent, false, Vector3.new(0, -20, 0))

--	-- Play the sound
--	--	PlayFireSound()
	
--end

local function Reflect(surfaceNormal, bulletNormal)
	return bulletNormal - (2 * bulletNormal:Dot(surfaceNormal) * surfaceNormal)
end

-- The pierce function can also be used for things like bouncing.
-- In reality, it's more of a function that the module uses to ask "Do I end the cast now, or do I keep going?"
-- Because of this, you can use it for logic such as ray reflection or other redirection methods.
-- A great example might be to pierce or bounce based on something like velocity or angle.
-- You can see this implementation further down in the OnRayPierced function.
function CanRayPierce(cast, rayResult, segmentVelocity)
	

	local hitPart = rayResult.Instance
	if (hitPart and hitPart:GetAttribute("Pierce")) then
		--HandleHit(cast,rayResult,cosmeticBulletObject,true)
		return true
	end
	
	
	-- Let's keep track of how many times we've hit something.
	--local hits = cast.UserData.Hits
	--if (hits == nil) then
	--	-- If the hit data isn't registered, set it to 1 (because this is our first hit)
	--	cast.UserData.Hits = 1
	--else
	--	-- If the hit data is registered, add 1.
	--	cast.UserData.Hits += 1
	--end

	---- And if the hit count is over 3, don't allow piercing and instead stop the ray.
	--if (cast.UserData.Hits > 3) then
	--	return false
	--end

	-- Now if we make it here, we want our ray to continue.
	-- This is extra important! If a bullet bounces off of something, maybe we want it to do damage too!
	-- So let's implement that.
	--local hitPart = rayResult.Instance
	--if hitPart ~= nil and hitPart.Parent ~= nil then
	--	--local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
	--	--if humanoid then
	--	--	humanoid:TakeDamage(10) -- Damage.
	--	--end
	--end

	-- And then lastly, return true to tell FC to continue simulating.
	--return true

	
	-- This function shows off the piercing feature literally. Pass this function as the last argument (after bulletAcceleration) and it will run this every time the ray runs into an object.
	
	-- Do note that if you want this to work properly, you will need to edit the OnRayPierced event handler below so that it doesn't bounce.
	
	
	--TODO allow certain bullets through certain materials and shatter glass for example.
	--if material == Enum.Material.Plastic or material == Enum.Material.Ice or material == Enum.Material.Glass or material == Enum.Material.SmoothPlastic then
	--	-- Hit glass, plastic, or ice...
	--	if hitPart.Transparency >= 0.5 then
	--		-- And it's >= half transparent...
	--		return true -- Yes! We can pierce.
	--	end
	--end
	return false
	
end

--TEST
--local originMarker = Instance.new("Part")
--originMarker.Size = Vector3.new(.2,.2,.2)
--originMarker.BrickColor = BrickColor.Red()
--originMarker.Anchored = true
--originMarker.CanCollide = false
--originMarker.Position = Vector3.new(0,0,0)
--originMarker.Parent = workspace


function Fire(player,origin,direction, heldTool, weapon, keycode,mouseHit,HeldToolHandle)
	
	--TEST
	--originMarker.Position = origin
	
	-- UPD. 11 JUNE 2019 - Add support for random angles.
	local directionalCF = CFrame.new(Vector3.new(), direction)
	-- Now, we can use CFrame orientation to our advantage.
		
	local direction
	
	--Handle special cases of weapons
	if (weapon.WeaponAttacks[keycode.Name] and attacksModule[weapon.WeaponAttacks[keycode.Name].Name] and attacksModule[weapon.WeaponAttacks[keycode.Name].Name].MinSpreadAngle ~= nil) then
		direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(attacksModule[weapon.WeaponAttacks[keycode.Name].Name].MinSpreadAngle, attacksModule[weapon.WeaponAttacks[keycode.Name].Name].MaxSpreadAngle)), 0, 0)).LookVector
	else
		direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(MIN_BULLET_SPREAD_ANGLE, MAX_BULLET_SPREAD_ANGLE)), 0, 0)).LookVector
	end

	-- UPDATE V6: Proper bullet velocity!
	-- IF YOU DON'T WANT YOUR BULLETS MOVING WITH YOUR CHARACTER, REMOVE THE THREE LINES OF CODE BELOW THIS COMMENT.
	-- Requested by https://www.roblox.com/users/898618/profile/
	-- We need to make sure the bullet inherits the velocity of the gun as it fires, just like in real life.
	local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart", 1)	-- Add a timeout to this.
	local myMovementSpeed = humanoidRootPart.Velocity							-- To do: It may be better to get this value on the clientside since the server will see this value differently due to ping and such.
	local modifiedBulletSpeed = (direction * weapon.WeaponAmmoSpeed)--BULLET_SPEED + myMovementSpeed	-- We multiply our direction unit by the bullet speed. This creates a Vector3 version of the bullet's velocity at the given speed. We then add MyMovementSpeed to add our body's motion to the velocity.

	--if PIERCE_DEMO then
		CastBehavior.CanPierceFunction = CanRayPierce
		--CastBehavior.MaxDistance = weapon.WeaponMaxDistance --Don't do this because it just stops mid air.
	--end
	
	CastParams.FilterDescendantsInstances = {player.Character,DartBulletsFolder,LaserBulletsFolder,RockBulletsFolder,BoltBulletsFolder,EggBulletsFolder,HelperPartsFolder,BuildBlockersFolder,workspace.Zones}

	-- NEW V13.1.0 - PartCache tie-in. If you use the PartCache module to create cosmetic bullets, you can now directly tie that in.
	-- Ensure you're using the latest version of PartCache.
	--local CosmeticPartProvider = PartCacheModule.new(ammo["Dart"], 100, CosmeticBulletsFolder)

	-- NEW v12.0.0: Casters now use a data packet which can be made like what follows.
	-- Check the API for more information: https://etithespirit.github.io/FastCastAPIDocs/fastcast-objects/fcbehavior
	--local CastBehavior = FastCast.newBehavior()
	CastBehavior.RaycastParams = CastParams
	
	if (weapon.WeaponAmmo ~= "NoAmmo") then
		CastBehavior.CosmeticBulletProvider = PartProviders[weapon.WeaponAmmo] -- Comment out if you aren't using PartCache.
		CastBehavior.CosmeticBulletContainer = BulletFolders[weapon.WeaponAmmo]
	else
		CastBehavior.CosmeticBulletProvider = nil -- Comment out if you aren't using PartCache.
		CastBehavior.CosmeticBulletContainer = nil
	end
	
	if (ammo[weapon.WeaponAmmo].Gravity) then
		CastBehavior.Acceleration = ammo[weapon.WeaponAmmo].Gravity
	end
	
	print("TEST WEAPON Caster Fire:",origin,direction)
	local simBullet = Caster:Fire(origin, direction, modifiedBulletSpeed, CastBehavior)
	print("TEST WEAPON After Caster Fire: simBullet",simBullet)
	simBullet.UserData.Player = player
	simBullet.UserData.WeaponName = weapon
	simBullet.UserData.AttackName = itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name
	
	if (weapon.WeaponAmmo ~= "NoAmmo") then
		if (ammo[weapon.WeaponAmmo].Trail) then
			--simBullet.RayInfo.CosmeticBulletObject.Trail.Attachment1.CFrame = CFrame.new(origin)
			simBullet.RayInfo.CosmeticBulletObject.Trail.Enabled = true
		end
		
		
		if (ammo[weapon.WeaponAmmo].Rope) then 
			local rope = simBullet.RayInfo.CosmeticBulletObject.RopeConstraint
			local distance = (origin - mouseHit).Magnitude
			rope.Attachment0 = rope.Parent.RopeEnd
			rope.Attachment1 = HeldToolHandle.RopeStart
			rope.Length = distance
		end
		
		if (ammo[weapon.WeaponAmmo].Ripple) then 
			simBullet.RayInfo.CosmeticBulletObject.WaterFXAttachment.RIPPLE.Enabled = StatesFunctions.GetUnderWater(player)
		end
		
		if (ammo[weapon.WeaponAmmo].Splash) then 
			simBullet.RayInfo.CosmeticBulletObject.WaterFXAttachment.SPLASH.Enabled = StatesFunctions.GetUnderWater(player)
		end
	end

	-- Play the sound
	PlayFireSound(heldTool)
end

---------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
-- Event Handlers
function spawner(func,...)
	local co = coroutine.wrap(func)
	co(...)
end

function HandlePoisonGas(player,hitPart)
	local gas = PoisonGas:Clone()
	gas.Position = hitPart.Position
	gas.CanCollide = false
	gas.Anchored = true
	gas.Parent = workspace
	gas.PoisonGasSource:Emit(25)
	spawner(function()

		local enemiesSnapshot = enemyFunctions.GetEnemies()

		for _,enemy in pairs(enemiesSnapshot) do
			local distance = (enemy.root.Position - gas.Position).magnitude

			if (distance < 20) then
				EffectsFunctions.AddEnemyEffect(player,enemy,"Poison")
			else
			end
		end
		
		for i,ply in pairs(game.Players:GetChildren()) do

			if((ply.Character.PrimaryPart.Position - gas.Position).magnitude<20) then
				EffectsFunctions.AddEffect(ply,"Poison",ProgressFunctions.GetLevel(player))
			end
		end
	end)
	Debris:AddItem(gas,5)
end

function HandleHitEffects(player,hitPart,hitPoint,hitMaterial)

	if (hitPart:GetAttribute("HitEffect_Unanchor")) then
		hitPart.Anchored = false
	end
	if (hitPart:GetAttribute("HitEffect_DebrisModel")) then
		if (hitPart.Parent and hitPart.Parent:IsA("Model")) then
			Debris:AddItem(hitPart.Parent,5)
		end
	end
	if (hitPart:GetAttribute("HitEffect_Invis")) then
		hitPart.Transparency = 1
	end
	if (hitPart:GetAttribute("HitEffect_SizeSmall")) then
		hitPart.Size = Vector3.new(1,1,1)
		hitPart.Massless = true
	end
	if (hitPart:GetAttribute("HitEffect_Destroy")) then
		hitPart:Destroy()
	end
	
	if (hitPart:GetAttribute("HitEffect_PoisonGas")) then
		HandlePoisonGas(player,hitPart)
	end
	
	if (hitPart:GetAttribute("HitEffect_SibRopeShorten")) then
		hitPart.Parent.RopeConstraint.Length = hitPart.Parent.RopeConstraint.Length/2
		hitPart.Parent.RopeConstraint.Restitution = .2
	end
	
	if (hitPart:IsA("Terrain")) then
		
		local terrainFX = nil
		
		if (hitMaterial == Enum.Material.LeafyGrass) then
			terrainFX = GrassFX:Clone()
			
		elseif (hitMaterial == Enum.Material.Ground) then
			terrainFX = DirtFX:Clone()
		end
		
		if (terrainFX) then
			terrainFX.Position = hitPoint
			terrainFX.Parent = workspace
			terrainFX.FX:Emit(100)
			Debris:AddItem(terrainFX,2)
		end
		
	end
end

function HandleHitSoundFx(hitPart,cosmeticBulletObject)

	local hitSound = hitPart:FindFirstChild("HitSound")

	if (hitSound) then
		hitSound:Play()
	else
		if(hitPart:GetAttribute("Material") == "Wood" and (ammo[cosmeticBulletObject.Name].SoundFXOnWood)) then
			if (ammo[cosmeticBulletObject.Name].SoundFXOnWood) then
				local soundFx = ammo[cosmeticBulletObject.Name].SoundFXOnWood:Clone() --TODO too slow should go on bullets?
				soundFx.Parent = cosmeticBulletObject
				soundFx:Play()
			elseif((ammo[cosmeticBulletObject.Name].DefaultSoundFX)) then

				local soundFx = ammo[cosmeticBulletObject.Name].DefaultSoundFX:Clone() --TODO too slow should go on bullets?
				soundFx.Parent = cosmeticBulletObject
				soundFx:Play()

			end
		elseif(hitPart:GetAttribute("Material") == "Metal") then
			if (ammo[cosmeticBulletObject.Name].SoundFXOnMetal) then
				local soundFx = ammo[cosmeticBulletObject.Name].SoundFXOnMetal:Clone() --TODO too slow should go on bullets?
				soundFx.Parent = cosmeticBulletObject
				soundFx:Play()
			elseif((ammo[cosmeticBulletObject.Name].DefaultSoundFX)) then

				local soundFx = ammo[cosmeticBulletObject.Name].DefaultSoundFX:Clone() --TODO too slow should go on bullets?
				soundFx.Parent = cosmeticBulletObject
				soundFx:Play()

			end	
		elseif(hitPart:GetAttribute("Material") == "Plastic") then
		elseif((ammo[cosmeticBulletObject.Name].DefaultSoundFX)) then

			local soundFx = ammo[cosmeticBulletObject.Name].DefaultSoundFX:Clone() --TODO too slow should go on bullets?
			soundFx.Parent = cosmeticBulletObject
			soundFx:Play()
				
		else
			local soundFx = defaultHitSound:Clone() --TODO too slow should go on bullets?
			soundFx.Parent = cosmeticBulletObject
			soundFx:Play()
		end
	end
end

function HandleHit(cast,raycastResult,cosmeticBulletObject,pierced)

	local hitPart = raycastResult.Instance
	local hitPoint = raycastResult.Position
	local normal = raycastResult.Normal
	
	print("TEST WEAPON hitPart:",hitPart)
	
	if (cosmeticBulletObject) then

		if (cosmeticBulletObject:FindFirstChild("Trail") ~= nil) then
			cosmeticBulletObject.Trail.Enabled = false
		end

		if ((not pierced) and ammo[cosmeticBulletObject.Name].Stick) then
			--TODO Change to attach for moving things like people, maybe check if part is anchored and if it is just anchore here then.
			
			if (cosmeticBulletObject:GetAttribute("HasSplat")) then
				cosmeticBulletObject.CFrame =  CFrame.new(hitPoint	, hitPoint+normal)
				cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal*-.9)	
				cosmeticBulletObject.Transparency = 1
				cosmeticBulletObject.Splat.Transparency = 0
				cosmeticBulletObject.Splat.CFrame = cosmeticBulletObject.CFrame * CFrame.Angles( math.rad(-90), 0, 0)
				cosmeticBulletObject.Splat.Position = cosmeticBulletObject.Splat.Position + (normal)	
			else
				cosmeticBulletObject.CFrame =  CFrame.new(hitPoint	, hitPoint+normal)
				if(ammo[cosmeticBulletObject.Name].StickOffset) then
					cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal*1.5)
				else
					cosmeticBulletObject.Position = cosmeticBulletObject.Position + (normal*.5)
				end
					
			end
			
			if (ammo[cosmeticBulletObject.Name].Ripple) then 
				cosmeticBulletObject.WaterFXAttachment.RIPPLE.Enabled = false

			end

			if (ammo[cosmeticBulletObject.Name].Splash) then 
				cosmeticBulletObject.WaterFXAttachment.SPLASH.Enabled = false
			end
			
			--end
			
		
		elseif ammo[cosmeticBulletObject.Name].Destroy then
			--cosmeticBulletObject.Transparency = 1
			CastBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
		
		else
			cosmeticBulletObject.Anchored = false
			cosmeticBulletObject.CanCollide = true
		end
		
		HandleHitEffects(cast.UserData.Player,hitPart,hitPoint,raycastResult.Material)

		HandleHitSoundFx(hitPart,cosmeticBulletObject)

		local rotatedCFrame = nil

		if (ammo[cosmeticBulletObject.Name].RotateStickOne) then
			rotatedCFrame = CFrame.Angles( math.rad(-90), math.rad(-90), 0)
		elseif (ammo[cosmeticBulletObject.Name].RotateStickTwo) then
			rotatedCFrame = CFrame.Angles( 0, math.rad(180), 0)
		elseif (ammo[cosmeticBulletObject.Name].RotateStickThree) then
			rotatedCFrame = CFrame.Angles( 0, 0, 0)
		else
			rotatedCFrame = CFrame.Angles( 0, math.rad(-90), 0)
		end

		cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
	end
	
	if hitPart ~= nil and hitPart.Parent ~= nil then -- Test if we hit something
		
		local enemy = enemyFunctions.GetEnemy(hitPart.Parent)

		if (enemy ~= nil) then
			enemyFunctions.HandleBodyPartHit(cast.UserData.Player, enemy,cast.UserData.WeaponName,attacksModule[cast.UserData.AttackName])

			MakeParticleFX(hitPoint, normal) -- Particle FX
		end

		enemyFunctions.HandleEnvironmentalTarget(cast.UserData.Player,hitPart.Parent,ammo[cosmeticBulletObject.Name].BreakableMaterials)


	end
end

function OnRayHit(cast, raycastResult, segmentVelocity, cosmeticBulletObject)
	-- This function will be connected to the Caster's "RayHit" event.
	HandleHit(cast,raycastResult,cosmeticBulletObject,false)
end

function OnRayPierced(cast, raycastResult, segmentVelocity, cosmeticBulletObject)	

	HandleHit(cast,raycastResult,cosmeticBulletObject,true)
	
	---- You can do some really unique stuff with pierce behavior - In reality, pierce is just the module's way of asking "Do I keep the bullet going, or do I stop it here?"
	---- You can make use of this unique behavior in a manner like this, for instance, which causes bullets to be bouncy.
	local position = raycastResult.Position
	--local normal = raycastResult.Normal

	--local newNormal = Reflect(normal, segmentVelocity.Unit)
	--cast:SetVelocity(newNormal * segmentVelocity.Magnitude)

	---- It's super important that we set the cast's position to the ray hit position. Remember: When a pierce is successful, it increments the ray forward by one increment.
	---- If we don't do this, it'll actually start the bounce effect one segment *after* it continues through the object, which for thin walls, can cause the bullet to almost get stuck in the wall.
	cast:SetPosition(position)

	-- Generally speaking, if you plan to do any velocity modifications to the bullet at all, you should use the line above to reset the position to where it was when the pierce was registered.
end

function OnRayUpdated(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	-- Whenever the caster steps forward by one unit, this function is called.
	-- The bullet argument is the same object passed into the fire function.
	if cosmeticBulletObject == nil then return end
	local bulletLength = cosmeticBulletObject.Size.Z / 2 -- This is used to move the bullet to the right spot based on a CFrame offset
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))
	
	if (ammo[cosmeticBulletObject.Name].Rotate) then

		local rotatedCFrame = CFrame.Angles(0, math.rad(90), 0) --CFrame.Angles(0, math.rad(270), 0)
		cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
		--local rotatedCFrame = CFrame.Angles(0, math.rad(180), 0) --CFrame.Angles(0, math.rad(270), 0)
		--cosmeticBulletObject.CFrame = cosmeticBulletObject.CFrame:ToWorldSpace(rotatedCFrame)
	end

end

function OnRayTerminated(cast)
	local player = cast.UserData.Player
	local cosmeticBullet = cast.RayInfo.CosmeticBulletObject
	
	if cosmeticBullet ~= nil then
		-- This code here is using an if statement on CastBehavior.CosmeticBulletProvider so that the example gun works out of the box.
		-- In your implementation, you should only handle what you're doing (if you use a PartCache, ALWAYS use ReturnPart. If not, ALWAYS use Destroy.
		
		task.delay(10,function()
			if (ammo[cosmeticBullet.Name].Ripple) then 
				cosmeticBullet.WaterFXAttachment.RIPPLE.Enabled = StatesFunctions.GetUnderWater(player)
			end

			if (ammo[cosmeticBullet.Name].Splash) then 
				cosmeticBullet.WaterFXAttachment.SPLASH.Enabled = StatesFunctions.GetUnderWater(player)
			end
			cosmeticBullet.CanCollide = true
			cosmeticBullet.Anchored = false
			
			wait(2)
			
			if (ammo[cosmeticBullet.Name].Ripple) then 
				cosmeticBullet.WaterFXAttachment.RIPPLE.Enabled = false

			end

			if (ammo[cosmeticBullet.Name].Splash) then 
				cosmeticBullet.WaterFXAttachment.SPLASH.Enabled = false
			end
				
			cosmeticBullet.CanCollide = false
			cosmeticBullet.Anchored = true
			
			--print("TEST BULLET RETURN BULLET TO CACHE:",#LaserBulletsFolder:GetChildren())
			CastBehavior.CosmeticBulletProvider:ReturnPart(cosmeticBullet)
			
		end)
	end
end

local function HandleFX(player, weapon, keycode, target,ToolTransformedWorldCFrame)
	--local animation = Instance.new("Animation")

	--if (attacksModule[weapon.WeaponAttacks[keycode.Name].Name].Animation) then
	--	animation.AnimationId = "http://www.roblox.com/asset/?id="..attacksModule[weapon.WeaponAttacks[keycode.Name].Name].Animation
	--	Track = player.Character.Humanoid:LoadAnimation(animation)
		
		
	--	Track:GetMarkerReachedSignal("EarlyCast"):Connect(function()
	--		local Data = {}
	--		local Module = ServerScriptService:WaitForChild("SharedFX"):FindFirstChild(weapon.Name)

	--		if Module then
	--			require(Module)(player, CFrame.new(target), weapon, attacksModule[itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name],ToolTransformedWorldCFrame, Data)
	--		else
	--			Replicator:FireAllClients(weapon.Name)
	--		end
	--	end)
		
		
	--	Track:Play()
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	--	--Logger.Debug("TEST ANIMATION SPEED HandleFX in combathandler:",attacksModule[weapon.WeaponAttacks[keycode.Name].Name].AnimationSpeed)
	--	--Track:AdjustSpeed(attacksModule[weapon.WeaponAttacks[keycode.Name].Name].AnimationSpeed)
	--	--Track.Stopped:Wait()
		
	--	--TODO make generic , use ammo name if there is ammo and check if there is an fx ammo named same
	--	--local rocket = EffectItems.Rocket.Rocket:Clone()
		
	--	--local rocketWeld = Instance.new("WeldConstraint")
	--	--rocketWeld.Part0 = rocket
	--	--rocketWeld.Part1 = Projectile
	--	--rocketWeld.Enabled = true
	--	--rocketWeld.Parent = rocket
		
	--	----Set Parent to tool cframe
	--	--rocket.CFrame = ToolTransformedWorldCFrame
	--	--rocket.Parent =  workspace

		

	--else
	--task.defer(function()
	
		local fxFunc = FXModules[weapon.Name]
		if fxFunc then
			local Data = {}
			fxFunc(player, CFrame.new(target), weapon, attacksModule[itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name], ToolTransformedWorldCFrame, Data)
		else
			Replicator:FireAllClients(weapon.Name)
		end
	
		--local Data = {}
		--local Module = ServerScriptService:WaitForChild("SharedFX"):FindFirstChild(weapon.Name)

		--if Module then
		--	require(Module)(player, CFrame.new(target), weapon, attacksModule[itemsmodule[weapon.Name].WeaponAttacks[keycode.Name].Name],ToolTransformedWorldCFrame, Data)
		--else
		--	Replicator:FireAllClients(weapon.Name)
		--end
	--end)
		
	--end
end

local function HandleArtifact(player, weapon, keycode, target)
	HandleFX(player, weapon, keycode, target)
end


local function HandleRanged(player, weapon, keycode, mouseHit, heldToolName,ToolTransformedWorldCFrame,HeldToolHandle)
	if not CanFire then
		return
	end
	CanFire = false --TODO must be made per player!!!!!
	
	if (itemsmodule[weapon.Name].FX) then
		HandleFX(player, weapon, keycode, mouseHit,ToolTransformedWorldCFrame)
		CanFire = true
		return
	end
	
	if (itemsmodule[weapon.Name].VFX) then
		HandleVFX(player, weapon, keycode)
	end
	
	local origin = ToolTransformedWorldCFrame.p -- + ToolTransformedWorldCFrame.LookVector --+Vector3.new(0,.6,0)
	
	--local debugSearchArea = Instance.new("Part")
	--debugSearchArea.Transparency = .5
	--debugSearchArea.Size = Vector3.new(.1,.1,.1)
	--debugSearchArea.BrickColor = BrickColor.Red()
	--debugSearchArea.CanCollide = false
	--debugSearchArea.Anchored = true
	--debugSearchArea.Parent = workspace
	--debugSearchArea.Position = origin
	
	local direction = (mouseHit - origin).Unit

	if (weapon.WeaponAttacks[keycode.Name].Multishot ~= nil) then
		for i = 1,weapon.WeaponAttacks[keycode.Name].Multishot do
			Fire(player, origin, direction, player.Character[heldToolName], weapon, keycode,mouseHit,HeldToolHandle)
			
			if (weapon.WeaponAmmo ~= "NoAmmo") and not itemsmodule[weapon.Name].Traits["UnlimitedAmmo"] then
				InventoryFunctions.RemoveItem(player,weapon.WeaponAmmo,1,true,true)
			end
			
		end
	else
		print("TEST WEAPON Fire:",origin,direction)
		Fire(player, origin, direction, player.Character[heldToolName], weapon, keycode,mouseHit,HeldToolHandle)

		if (weapon.WeaponAmmo ~= "NoAmmo")  and not itemsmodule[weapon.Name].Traits["UnlimitedAmmo"] then
			InventoryFunctions.RemoveItem(player,weapon.WeaponAmmo,1,true,true)
		end
	end
	
	--wait(1/weapon.WeaponSpeed)

	CanFire = true
end

local function HandleTrap(player, weapon, keycode)
	--TODO handle trap
end

--local numberOfBulletsFiredPerSecond = 0

ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("PlayerInput").OnServerEvent:Connect(function(player, keycode, mouseHit, ToolTransformedWorldCFrame)

	--if (keycode == Enum.KeyCode.Tab) then
		--StatesFunctions.ChangeNearestTarget(player)
	--end

	local heldToolName = StatesFunctions.GetCurrentTool(player)
	
	if (heldToolName == "") then
		return
	end
		
	local item = itemsmodule[heldToolName] --InventoryFunctions.GetItem(player,heldToolName)
	--local weaponItemTemplate = itemsmodule[heldToolName]
	
	if (item == nil) then
		warn("CombatHandler.PlayerInput item not found: ",heldToolName)
		return
	end

	--Check key presses
	if ((keycode == Enum.KeyCode.R) or (keycode == Enum.KeyCode.F) or (keycode == Enum.KeyCode.G)) then
		
		if (item.Type ~= "Weapon" and item.Type ~= "OffHand" and item.Type ~= "Artifact") then
			return
		end

		if (itemsmodule[item.Name].WeaponAmmo ~= nil and itemsmodule[item.Name].WeaponAmmo ~= "NoAmmo"  and not InventoryFunctions.HasItem(player,itemsmodule[item.Name].WeaponAmmo,1,true, true)) then
			NoAmmoEvent:FireClient(player,true)
			return
		end
		
		local nowTime = os.time()
		
		local elapsedTime = os.clock() - StatesFunctions.GetLastFireTime(player)
		local weaponspeed = item.WeaponSpeed
		local fireRateTime = 10/weaponspeed

		if (elapsedTime < fireRateTime) then
			return
		else
			StatesFunctions.SetLastFireTime(player,os.clock())
		end

		if (item.Type == "Weapon") then
			
			if (not InventoryFunctions.HasWeaponEquipped(player,heldToolName) or (itemsmodule[heldToolName].Type ~= "Weapon")) then
				return
			end
			
			--if (item.SubType == "Ranged") then
			--	if ((nowTime - lastFireTime) >= 1) then
			--		if (numberOfBulletsFiredPerSecond > attacksModule[item.WeaponAttacks[keycode.Name].Name].AttackSpeed) then
			--			numberOfBulletsFiredPerSecond = 0
			--			return
			--		else
			--			numberOfBulletsFiredPerSecond = numberOfBulletsFiredPerSecond + 1
			--		end

			--	end

			--	lastFireTime = nowTime
			--else
			--	--Are we trying to attack too soon
			--	if (playerLastAttack[player.Name] ~= nil) and ((nowTime - playerLastAttack[player.Name]) < (1/attacksModule[item.WeaponAttacks[keycode.Name].Name].AttackSpeed)) then
			--		return
			--	end
			--end

			local timeElapsedSinceLastAttack = (nowTime - item.WeaponAttacks[keycode.Name].LastUsed)
			local coolDown = attacksModule[item.WeaponAttacks[keycode.Name].Name].Cooldown

			--Has this attack cooled down yet?
			if (InventoryFunctions.TimeElapsedSinceLastUse(player, heldToolName, keycode) < attacksModule[item.WeaponAttacks[keycode.Name].Name].Cooldown) then
				return
			end

			InventoryFunctions.UpdateLastUsed(player, heldToolName, keycode, nowTime)

			playerLastAttack[player.Name] = nowTime
			
			local character = player.Character
			local attack = attacksModule[item.WeaponAttacks[keycode.Name].Name]


			if (item.SubType == "Melee") then
				if (not item.Auto) then
					HandleMelee(player, item, keycode)
				else
					if (keycode == Enum.KeyCode.R) then
						
						if (attack.SoundFX ~= nil) then
							local weaponItem = character:FindFirstChild(item.Name)

							if (weaponItem) then
								local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
								if (soundFX) then
									if (not soundFX.IsPlaying) then
										soundFX:Play()
									end
								end
							end
						end
					elseif (keycode == Enum.KeyCode.F) then
						
						if (attack.SoundFX ~= nil) then
							local weaponItem = character:FindFirstChild(item.Name)

							if (weaponItem) then
								local soundFX = weaponItem:FindFirstChild(attack.SoundFX)
								if (soundFX) then
									if (soundFX.IsPlaying) then
										soundFX:Stop()
									end
								end
								
								local autoAttack = attacksModule[item.WeaponAttacks["G"].Name]
								if (autoAttack) then
									if (autoAttack.IsPlaying) then
										autoAttack:Stop()
									end
								end
								
							end
						end
					elseif (keycode == Enum.KeyCode.G) then
						HandleAutoMelee(player,item,keycode, mouseHit, heldToolName)
					end
					
				end
				
			elseif (item.SubType == "Ranged") then
				
				local HeldToolHandle = ToolFunctions.GetToolHandle(player,heldToolName)
				--This will not really be correct on server so use client passed value
				--local HeldToolTransformedWorldCFrame = nil
				
				--if (HeldToolHandle:GetAttribute("HasTip")) then
				--	HeldToolTransformedWorldCFrame = HeldToolHandle.Attachment.WorldCFrame --HeldToolHandle.TransformedWorldCFrame
				--else
				--	HeldToolTransformedWorldCFrame = HeldToolHandle.TransformedWorldCFrame
				--end
				
				HandleRanged(player, item, keycode,mouseHit, heldToolName, ToolTransformedWorldCFrame,HeldToolHandle)
			elseif (item.SubType == "Trap") then
				HandleTrap(player, item, keycode)
			end
			
			
		elseif (item.Type == "OffHand") then
			
			if (not InventoryFunctions.HasOffHandEquipped(player,heldToolName) or (itemsmodule[heldToolName].Type ~= "OffHand")) then
				return
			end
			
			--if (item.SubType == "Artifact") then
			--	HandleArtifact(player, item, keycode,mouseHit)			
			--end
			
		elseif (item.Type == "Artifact") then

			HandleArtifact(player, item, keycode,mouseHit)			

		end
		
		
		--Reduce stamina every time we attack
		StatesFunctions.RemoveStamina(player,1)
		UpdateStaminaEvent:FireClient(player,StatesFunctions.GetStamina(player) , 100)

	end
end)

--TODO move all of these into some LootFunctions script
local function getRandomItem(weightedItems)
	local sum = 0
	for _,v in pairs(weightedItems) do
		sum = sum + v.Rarity
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(weightedItems) do
		rand = rand - v.Rarity
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

Caster.RayHit:Connect(OnRayHit)
Caster.RayPierced:Connect(OnRayPierced)
Caster.LengthChanged:Connect(OnRayUpdated)
Caster.CastTerminating:Connect(OnRayTerminated)



