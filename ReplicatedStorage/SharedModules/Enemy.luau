local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local CharacterUtility = require(ServerScriptService:WaitForChild("SharedUtilities"):WaitForChild("CharacterUtility")) 
local CollectionService = game:GetService("CollectionService")

local EnemyBillboard = ReplicatedStorage:WaitForChild("Enemies"):WaitForChild("Templates"):WaitForChild("EnemyHealth")

local enemy = {}

enemy.enemies = {}

-- A counter to keep track of the number of enemy objects that have been created
local enemyCounter = 0

local function shallowCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

-- Creates a new enemy object with a unique id and a list of players allowed to loot it
function enemy.newEnemy(enemyName,position,spawnerName,size,additionalTags)
	enemyCounter = enemyCounter + 1

	local enemyModel = ReplicatedStorage:WaitForChild("Enemies"):WaitForChild(enemyName):Clone()
	enemyModel:SetPrimaryPartCFrame(CFrame.new(Vector3.new(position.X,position.Y,position.Z)))
	enemyModel.Name = enemyName
	
	if(enemyModel:FindFirstChild("HumanoidRootPart")) then
		enemyModel.HumanoidRootPart.Anchored = false
		enemyModel.HumanoidRootPart.CanCollide = true --enemyModel.HumanoidRootPart.CanCollide = true
	end
	
	enemyModel:SetAttribute("ConfigId",spawnerName)

	--local collider = Instance.new("Part")
	--collider.Name = "Collider"
	--collider.Size = size or Vector3.new(2, 2, 2) -- size to roughly match the chicken body
	--collider.Transparency = 1
	--collider.Anchored = false
	--collider.CanCollide = true
	--collider.Massless = true
	--collider.Parent = enemyModel
	--collider.CFrame = enemyModel.HumanoidRootPart.CFrame

	---- Attach it to the HumanoidRootPart
	--local weld = Instance.new("WeldConstraint")
	--weld.Part0 = enemyModel.HumanoidRootPart
	--weld.Part1 = collider
	--weld.Parent = collider

	-- Assign the collision group to all parts in the model
	for _, part in pairs(enemyModel:GetChildren()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "enemies" --was Enemy

			if (part.Name ~= "HumanoidRootPart") then
				part.CanCollide = false
				part.Massless = true
			end
		end
	end

	for i,v in pairs(enemyModel:GetDescendants()) do
		if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
			v:SetNetworkOwner(nil)
		end
	end

	enemyModel.Parent = workspace

	local humanoid = nil
	local root = nil

	if (enemyModel:FindFirstChild("Humanoid")) then
		humanoid = enemyModel.Humanoid
		root = enemyModel.Humanoid.RootPart
	else
		root = enemyModel.PrimaryPart
	end

	local self = {
		id = enemyCounter,
		name = enemyName,
		level = enemiesModule[enemyName].Level,
		type = enemiesModule[enemyName].Type,
		rank = enemiesModule[enemyName].Rank,
		char = enemyModel,
		root = root,
		human = humanoid,
		flip = false,
		deathHipHeight = enemiesModule[enemyName].DeathHipHeight,
		target = nil,
		target_priority = 1,
		targetSlot = "",
		clone = root,
		hasRangedWeapon = false,
		hasMeleeWeapon = true,
		rangedWeapon = nil,
		affraidOfFire = true,
		agentParameters = nil,
		home = position,
		spawn = position,
		altLocation1 = position,
		altLocation2 = position,
		altLocation3 = position,
		spawnTag = spawnerName,
		attackRange = enemiesModule[enemyName].AttackRange,
		rangedAttackRange = enemiesModule[enemyName].RangedAttackRange or 30,
		hitRange = enemiesModule[enemyName].HitRange,
		chanceOfBoredom = .5,               
		aggroRange = enemiesModule[enemyName].AggroRange,
		guardRange = enemiesModule[enemyName].GuardRange,
		rangedAmmo = enemiesModule[enemyName].RangedAmmo,
		slowAppear = enemiesModule[enemyName].SlowAppear or false,
		protected = false,
		boredomDuration = enemiesModule[enemyName].BoredomDuration or 30,
		searchingForWeapon = false,
		search = enemiesModule[enemyName].Search,
		walkSpeed = enemiesModule[enemyName].WalkSpeed,
		crawlSpeed = enemiesModule[enemyName].CrawlSpeed,
		runSpeed = enemiesModule[enemyName].RunSpeed,
		animations = enemiesModule[enemyName].Animations,
		idle3 = function (enemyObject)


		end,		
		health = shallowCopy(enemiesModule[enemyName].Health),
		HasLeftArm = true,
		HasRightArm = true,
		HasLeftLeg = true,
		HasRightLeg = true,
		bodyParts = shallowCopy(enemiesModule[enemyName].BodyParts or {{Name="Body"}}),
		CurrentShield = enemiesModule[enemyName].MaxShield or 0,
		MaxShield = enemiesModule[enemyName].MaxShield or 0,
		CurrentArmor = enemiesModule[enemyName].MaxArmor or 0,
		MaxArmor = enemiesModule[enemyName].MaxArmor or 0,
		CurrentHealth = enemiesModule[enemyName].MaxHealth or 0 or 100,
		MaxHealth = enemiesModule[enemyName].MaxHealth or 100,
		MaxHull = enemiesModule[enemyName].MaxHull or 0,
		CurrentHull = enemiesModule[enemyName].MaxHull or 0,
		MaxReactor = enemiesModule[enemyName].MaxReactor or 0,
		CurrentReactor = enemiesModule[enemyName].MaxReactor or 0,
		MaxLifeSupport = enemiesModule[enemyName].MaxLifeSupport or 0,
		CurrentLifeSupport = enemiesModule[enemyName].MaxLifeSupport or 0,
		Effects = {},
		Looters = {}
	}
	
	if (self.human) then
		self.human.JumpPower = 0
		self.human.UseJumpPower = true
	end

	local MIN_RADIUS = 1     -- Avoids squeezing through impossible spaces
	local MIN_HEIGHT = 2.5   -- Ensures proper vertical clearance

	self.agentParameters = {
		AgentRadius = math.max(self.root.Size.X / 2, self.root.Size.Z / 2, MIN_RADIUS),
		AgentHeight = math.max(self.root.Size.Y + (humanoid and humanoid.HipHeight or 0), MIN_HEIGHT),
		AgentCanJump = false,
	}

	local loadedAnimations = {}

	if (self.animations) then
		for index,anim in pairs(self.animations) do
			if (humanoid) then
				loadedAnimations[index] = humanoid:LoadAnimation(enemyModel.Animations:WaitForChild(anim))
				loadedAnimations[index].Priority = Enum.AnimationPriority.Action
			else
				loadedAnimations[index] = self.char.AnimationController:LoadAnimation(enemyModel.Animations:WaitForChild(anim))
				loadedAnimations[index].Priority = Enum.AnimationPriority.Action
			end

		end

		self.animations = loadedAnimations

	end
	
	self.char:SetAttribute("EnemyID", self.id)

	if (enemiesModule[enemyName].Face) then
		if (enemiesModule[enemyName].Face > 0) then
			CharacterUtility.ChangeFace(self.char,enemiesModule[enemyName].Face)
		end
	end

	if (humanoid) then
		self.human.HipHeight = enemiesModule[enemyName].HipHeight
	end

	local billboard = EnemyBillboard:Clone() --self["root"]:FindFirstChild("EnemyHealth")
	if (billboard) then
		billboard.EnemyHealthBarFrame.HealthText.Text = self.health.main.." / "..enemiesModule[enemyName].Health.main
		billboard.Frame.XFrame.Level.Text = enemiesModule[enemyName].Level --TODO should show based on how difficult the enemy is compared to you

		if (billboard.Frame["XFrame"]) then
			if (enemiesModule[enemyName].Rank == 1) then
				billboard.Frame.XFrame.Rank.ImageRectOffset = Vector2.new(64,832)
			elseif (enemiesModule[enemyName].Rank == 2) then
				billboard.Frame.XFrame.Rank.ImageRectOffset = Vector2.new(128,832)
			elseif (enemiesModule[enemyName].Rank == 3) then
				billboard.Frame.XFrame.Rank.ImageRectOffset = Vector2.new(192,832)
			elseif (enemiesModule[enemyName].Rank == 4) then
				billboard.Frame.XFrame.Rank.ImageRectOffset = Vector2.new(256,832)
			elseif (enemiesModule[enemyName].Rank == 5) then
				billboard.Frame.XFrame.Rank.ImageRectOffset = Vector2.new(320,832)
			end
		end

		billboard.Adornee = self.root
		billboard.Frame.EnemyNameLabel.Text = self.name
		billboard.Parent = self.root

	end

	CollectionService:AddTag(enemyModel,spawnerName)
	
	--Loops through AdditonalTags
	if (additionalTags) then
		for _,tag in pairs(additionalTags) do
			CollectionService:AddTag(enemyModel,tag)
		end
	end
	
	table.insert(enemy.enemies,self) --TODO should we set by id instead?

	return self
end

-- Finds and returns a enemy object by its id
function enemy.getEnemyById(id)
	return enemy.enemies[id]
end

return enemy