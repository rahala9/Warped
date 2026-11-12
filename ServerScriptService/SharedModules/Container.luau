local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
--local AchievementFunctions = require(ServerScriptService.Data.DataAchievementFunctions)
local containersFolder = ServerStorage:WaitForChild("SharedServerItems"):WaitForChild("Containers")

local R = Random.new(os.time())

local container = {}

local containers = {}

container.containerTypes = {
	["Suitcase"]="Suitcase",
	["Box"]="Box",
	["Crate"]="Crate",
	["Present"]="Present",
	["Chest"]="Chest",
	["Military"]="Military",
	["Tech"]="Tech",
	["Alien"]="Alien"
}

container.Rarity = {
	["Trash"]=0,
	["Common"]=1,
	["Uncommon"]=2,
	["Rare"]=3,
	["Epic"]=4,
	["Legendary"]=5,

}

container.LockLevels = {
	["Unlocked"]=0,
	["Level1"]=1,
	["Level2"]=2,
	["Level3"]=3,
	["Level4"]=4,

}

-- A counter to keep track of the number of container objects that have been created
local containerCounter = 1 --Single Time World Containers are set up first

function container.generateContainerLoot(player,containerID)

	local lootItem1,lootItem2 = nil

	local newContainer = container.getContainerById(containerID)

	if (newContainer ~= nil) then

		if (newContainer.looters[player.Name] == nil) then
			container.AddLooter(player,containerID)
		end

		if (newContainer.looters[player.Name].itemsGenerated == false) then

			newContainer.looters[player.Name].itemsGenerated = true


			lootItem1 = "Battery"--GetRandomItem(enemiesModule[enemyName].Loot).Name
			lootItem2 = "Bat"--GetRandomItem(enemiesModule[enemyName].Loot).Name

			if (lootItem1 == "Nothing") then
				lootItem1 = nil
			end

			if (lootItem2 == "Nothing") then
				lootItem2 = nil
			end

			newContainer.looters[player.Name].item1 = lootItem1
			newContainer.looters[player.Name].item2 = lootItem2		

		else

			return newContainer.looters[player.Name].item1,newContainer.looters[player.Name].item2

		end

		if(container.singleUse) then
			--TODO ADD BACK IN WHEN DOING ACHIEVMENTS AchievementFunctions.CompleteAchievementStep(player,"Treasures Found",containerID)
		end

	end

	return lootItem1,lootItem2
end

function container.AddLooter(player,containerID)

	local containerForLooter = container.getContainerById(containerID)

	local looter = {
		name = player.Name,
		itemsGenerated = false,
		item1 = nil,
		item2 = nil
	}

	containerForLooter.looters[player.Name] = looter
end

-- Creates a new corpse object with a unique id and a list of players allowed to loot it
function container.newContainer(containerType,lockLevel,lootRarity,position,orientation,singleUse,existingContainerObject,promptDisabled)
	containerCounter = containerCounter + 1
	local self = {
		id = containerCounter,
		looters = {}, --List of users that have already looted this while server has been up
		containerType = containerType,
		lockLevel = lockLevel,
		lootRarity = lootRarity,
		singleUse = singleUse
	}

	containers[containerCounter] = self

	local containerObject = nil

	if (existingContainerObject) then
		containerObject = existingContainerObject
		containerObject:SetAttribute("ContainerID",self.id)
		containerObject:SetAttribute("ContainerType",self.containerType)
		containerObject.Transparency = 0
	else
		containerObject = containersFolder[containerType]:Clone()
		containerObject.Name = "Container"
		--containerObject.Anchored = true
		containerObject.Position = position --TODO will have to find ground
		containerObject.Orientation = orientation
		containerObject:SetAttribute("ContainerID",self.id)
		containerObject:SetAttribute("ContainerType",self.containerType)
		containerObject.Transparency = 0
		containerObject.CanCollide = false
		containerObject.CanTouch = false
		containerObject.Parent = workspace
	end



	--TODO maybe a symbol of money or treasure
	--local skullIconBillboard = Instance.new("BillboardGui")
	--skullIconBillboard.Name = enemy.name.." CorpseSkullBillboard"
	--skullIconBillboard.Size = UDim2.new(5,0,5,0)
	--skullIconBillboard.Adornee = enemyCorpse
	--skullIconBillboard.Enabled = true
	--skullIconBillboard.AlwaysOnTop = false
	--skullIconBillboard.MaxDistance = 100
	--skullIconBillboard.StudsOffset = Vector3.new(0,3,0)
	--skullIconBillboard.Parent = enemyCorpse

	--local skullImage = Instance.new("ImageLabel")
	--skullImage.Name = enemy.name.." CorpseSkullImage"
	--skullImage.Size = UDim2.new(1,0,1,0)
	--skullImage.Transparency = 1
	--skullImage.Image = "rbxassetid://12260262531"
	--skullImage.ImageRectSize = Vector2.new(128,128)
	--skullImage.ImageRectOffset = Vector2.new(384,256)
	--skullImage.Visible = true
	--skullImage.Parent = skullIconBillboard

	local proxyPromptOpen = Instance.new("ProximityPrompt")

	if (promptDisabled) then
		proxyPromptOpen.Enabled = false
	end

	proxyPromptOpen.Name = "OpenContainer"
	proxyPromptOpen.ActionText = "Open"
	proxyPromptOpen.ObjectText = "Container"
	proxyPromptOpen.HoldDuration = 1
	proxyPromptOpen.MaxActivationDistance = 7
	proxyPromptOpen.RequiresLineOfSight = false
	proxyPromptOpen.KeyboardKeyCode = Enum.KeyCode.E
	proxyPromptOpen.UIOffset = Vector2.new(0,0)
	proxyPromptOpen.Parent = containerObject
	proxyPromptOpen.Style = Enum.ProximityPromptStyle.Custom

	self.model = containerObject

	if(not singleUse) then
		Debris:AddItem(containerObject, 3600)
	end


	self.destroyEvent = containerObject.Destroying:Connect(function()
		containers[self.id] = nil
	end)

	return self
end

-- Finds and returns a corpse object by its id
function container.getContainerById(id)
	return containers[id]
end



return container