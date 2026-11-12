--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

--Remote Events
local MessagePlayerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MessagePlayer")

--Functions

--Definition Modules
local enemiesModule = require(game.ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Enemies")) 
local itemsmodule = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

--Assets

--Modules
local Data = require(ServerScriptService.Data.Data)


local R = Random.new(os.time())

local corpse = {}

local corpses = {}

-- A counter to keep track of the number of corpse objects that have been created
local corpseCounter = 0

local function GetRandomItem(weightedItems)
	local sum = 0
	for _,v in pairs(weightedItems) do
		sum = sum + v.RarityPercentage
	end

	local rand = R:NextNumber(0, sum)
	local found
	for i, v in pairs(weightedItems) do
		rand = rand - v.RarityPercentage
		if rand < 0 then
			found = v
			break
		end
	end
	return found
end

-- Creates a new corpse object with a unique id and a list of players allowed to loot it
function corpse.newCorpse(enemy)
	corpseCounter = corpseCounter + 1
	local self = {
		id = corpseCounter,
		looters = {}
	}

	--TODO restrict the looters who had less than 20% of damage to the enemy
	for _,enemyLooter in pairs(enemy.Looters) do

		local looter = {
			name = enemyLooter.name,
			damage = enemyLooter.damage,
			itemsGenerated = false,
			item1 = nil,
			item2 = nil
		}

		self.looters[enemyLooter.name] = looter

	end

	corpses[corpseCounter] = self

	local enemyCorpse = Instance.new("Part")
	enemyCorpse.Name = enemy.name.." Corpse"
	enemyCorpse.Anchored = true
	enemyCorpse.Position = Vector3.new(enemy.char.PrimaryPart.Position.X,enemy.char.PrimaryPart.Position.Y + 1,enemy.char.PrimaryPart.Position.Z)
	enemyCorpse:SetAttribute("EnemyName",enemy.name)
	enemyCorpse:SetAttribute("CorpseID",self.id)
	enemyCorpse.Size = Vector3.new(1,1,1)
	enemyCorpse.Transparency = 1
	enemyCorpse.CanCollide = false
	enemyCorpse.CanTouch = false
	enemyCorpse.Parent = workspace

	local skullIconBillboard = Instance.new("BillboardGui")
	skullIconBillboard.Name = enemy.name.." CorpseSkullBillboard"
	skullIconBillboard.Size = UDim2.new(3,0,3,0)
	skullIconBillboard.Adornee = enemyCorpse
	skullIconBillboard.Enabled = true
	skullIconBillboard.AlwaysOnTop = false
	skullIconBillboard.MaxDistance = 100
	skullIconBillboard.StudsOffset = Vector3.new(0,2,0)
	skullIconBillboard.Parent = enemyCorpse

	local skullImage = Instance.new("ImageLabel")
	skullImage.Name = enemy.name.." CorpseSkullImage"
	skullImage.Size = UDim2.new(1,0,1,0)
	skullImage.Transparency = 1
	skullImage.Image = "rbxassetid://12260262531"
	skullImage.ImageRectSize = Vector2.new(128,128)
	skullImage.ImageRectOffset = Vector2.new(384,256)
	skullImage.Visible = true
	skullImage.Parent = skullIconBillboard

	local proxyPromptLootAll = Instance.new("ProximityPrompt")
	proxyPromptLootAll.Name = "LootAllCorpse"
	proxyPromptLootAll.ActionText = "Loot All"
	proxyPromptLootAll.ObjectText = enemyCorpse.Name
	proxyPromptLootAll.HoldDuration = 1
	proxyPromptLootAll.MaxActivationDistance = 7
	proxyPromptLootAll.RequiresLineOfSight = false
	proxyPromptLootAll.Style = Enum.ProximityPromptStyle.Custom
	proxyPromptLootAll.KeyboardKeyCode = Enum.KeyCode.E
	proxyPromptLootAll.UIOffset = Vector2.new(4,4)
	proxyPromptLootAll.Parent = enemyCorpse

	local proxyPromptOpen = Instance.new("ProximityPrompt")
	proxyPromptOpen.Name = "OpenCorpse"
	proxyPromptOpen.ActionText = "Open"
	proxyPromptOpen.ObjectText = enemyCorpse.Name
	proxyPromptOpen.HoldDuration = 1
	proxyPromptOpen.MaxActivationDistance = 7
	proxyPromptOpen.RequiresLineOfSight = false
	proxyPromptOpen.Style = Enum.ProximityPromptStyle.Custom
	proxyPromptOpen.KeyboardKeyCode = Enum.KeyCode.Q
	proxyPromptOpen.UIOffset = Vector2.new(0,4)
	proxyPromptOpen.Parent = enemyCorpse

	self.model = enemyCorpse

	Debris:AddItem(enemyCorpse, 60)

	self.destroyEvent = enemyCorpse.Destroying:Connect(function()
		corpses[self.id] = nil
	end)

	return self
end

-- Finds and returns a corpse object by its id
function corpse.getCorpseById(id)
	return corpses[id]
end

return corpse