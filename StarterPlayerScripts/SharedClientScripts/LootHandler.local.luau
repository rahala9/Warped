
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedRemotes = ReplicatedStorage:WaitForChild("SharedRemotes")
local LootRemotes = SharedRemotes:WaitForChild("Loot")
local GetLootFunction = LootRemotes:WaitForChild("GetLoot")
local GetLootFromContainerFunction = LootRemotes:WaitForChild("GetLootFromContainer")
local TakeLootFunction = LootRemotes:WaitForChild("TakeLoot")
local TakeLootFromContainerFunction = LootRemotes:WaitForChild("TakeLootFromContainer")
local Players = game:GetService("Players")
local CurrentPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()
local LootGui = CurrentPlayer.PlayerGui:WaitForChild("SharedGUI"):WaitForChild("LootGui")
local itemsmodule = require(game.ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))

local currentLootPrompt = nil

local containerImages = "rbxassetid://12290455266"
local corpseImage = "rbxassetid://12290455266" --"rbxassetid://11284961924"
containerTypes = {
	["Suitcase"]={
		Type="Suitcase",
		OpenImageRecOffset = Vector2.new(0,0),
		ClosedImageRecOffset = Vector2.new(0,303),
		OpenSize = Vector2.new(266,300),
		ClosedSize = Vector2.new(266,208)
	},
	["Box"]={
		Type="Box",
		OpenImageRecOffset = Vector2.new(266,0),
		ClosedImageRecOffset = Vector2.new(266,303),
		OpenSize = Vector2.new(266,303),
		ClosedSize = Vector2.new(266,208)
	},
	["Crate"]={
		Type="Crate",
		OpenImageRecOffset = Vector2.new(530,0),
		ClosedImageRecOffset = Vector2.new(530,303),
		OpenSize = Vector2.new(266,300),
		ClosedSize = Vector2.new(266,208)
	}
}

function OpenContainer()
	local containerID = currentLootPrompt.Parent:GetAttribute("ContainerID")
	local containerType = currentLootPrompt.Parent:GetAttribute("ContainerType")

	local con = containerTypes[containerType]
	
	--Closed
	LootGui.Background.Size = UDim2.new(0,con.ClosedSize.X,0,con.ClosedSize.Y)
	LootGui.Background.Image = containerImages
	LootGui.Background.ImageRectSize = Vector2.new(con.ClosedSize.X,con.ClosedSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.ClosedImageRecOffset.X,con.ClosedImageRecOffset.Y)
	LootGui.Background.Item1.Visible = false
	LootGui.Background.Item2.Visible = false
	LootGui.Enabled = true
	task.wait(1)
	
	--Open
	LootGui.Background.Size = UDim2.new(0,con.OpenSize.X,0,con.OpenSize.Y)
	LootGui.Background.Image = containerImages
	LootGui.Background.ImageRectSize = Vector2.new(con.OpenSize.X,con.OpenSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.OpenImageRecOffset.X,con.OpenImageRecOffset.Y)
	LootGui.Background.Item1.Visible = true
	LootGui.Background.Item2.Visible = true


	

end

function CloseContainer()

	local containerType = currentLootPrompt.Parent:GetAttribute("ContainerType")
	
	local con = containerTypes[containerType]
	
	LootGui.Background.Size = UDim2.new(0,con.ClosedSize.X,0,con.ClosedSize.Y)
	LootGui.Background.Image = containerImages
	LootGui.Background.ImageRectSize = Vector2.new(con.ClosedSize.X,con.ClosedSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.ClosedImageRecOffset.X,con.ClosedImageRecOffset.Y)
	LootGui.Background.Item1.Visible = false
	LootGui.Background.Item2.Visible = false
	
	task.wait(1)
	
	LootGui.Enabled = false
	if (currentLootPrompt and currentLootPrompt.Parent) then
		currentLootPrompt.Parent:Destroy()
	end
	
	currentLootPrompt = nil
	
end

function OpenCorpse()

	local con = containerTypes.Suitcase

	--Closed
	LootGui.Background.Size = UDim2.new(0,con.ClosedSize.X,0,con.ClosedSize.Y)
	LootGui.Background.Image = corpseImage
	LootGui.Background.ImageRectSize = Vector2.new(con.ClosedSize.X,con.ClosedSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.ClosedImageRecOffset.X,con.ClosedImageRecOffset.Y)
	LootGui.Background.Item1.Visible = false
	LootGui.Background.Item2.Visible = false
	LootGui.Enabled = true
	task.wait(1)

	--Open
	LootGui.Background.Size = UDim2.new(0,con.OpenSize.X,0,con.OpenSize.Y)
	LootGui.Background.Image = corpseImage
	LootGui.Background.ImageRectSize = Vector2.new(con.OpenSize.X,con.OpenSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.OpenImageRecOffset.X,con.OpenImageRecOffset.Y)
	LootGui.Background.Item1.Visible = true
	LootGui.Background.Item2.Visible = true

end

function CloseCorpse()
	local containerID = currentLootPrompt.Parent:GetAttribute("ContainerID")
	local containerType = currentLootPrompt.Parent:GetAttribute("ContainerType")
	
	local con = containerTypes.Suitcase
	
	LootGui.Background.Size = UDim2.new(0,con.ClosedSize.X,0,con.ClosedSize.Y)
	LootGui.Background.Image = corpseImage
	LootGui.Background.ImageRectSize = Vector2.new(con.ClosedSize.X,con.ClosedSize.Y)
	LootGui.Background.ImageRectOffset = Vector2.new(con.ClosedImageRecOffset.X,con.ClosedImageRecOffset.Y)
	LootGui.Background.Item1.Visible = false
	LootGui.Background.Item2.Visible = false

	task.wait(1)

	LootGui.Enabled = false
	if (currentLootPrompt and currentLootPrompt.Parent) then
		currentLootPrompt.Parent:Destroy()
	end
	
	currentLootPrompt = nil
end

function CloseLoot()
	if (currentLootPrompt == nil) then
		return
	end

	if (currentLootPrompt.Name == "OpenContainer") then
		CloseContainer()
	else
		CloseCorpse()
	end
end

function UpdateItems(lootItem1,lootItem2)
	
	--if (currentLootPrompt ~= nil and currentLootPrompt.Name == "OpenContainer") then
		
	--	OpenContainer()
	--else
	--	LootGui.Background.Size = UDim2.new(0,266,0,303)
	--	LootGui.Background.Image = corpseImage
	--	LootGui.Background.ImageRectSize = Vector2.new(266,303)
	--	LootGui.Background.ImageRectOffset = Vector2.new(containerTypes.Box.OpenImageX,containerTypes.Box.OpenImageY)

	--end
	
	if (lootItem1 == nil) then
		LootGui.Background.Item1.ItemPic.ImageTransparency = 1
		LootGui.Background.Item1.ItemName.Text = ""
	else
		LootGui.Background.Item1.ItemName.Text = lootItem1
		--Frame.ItemAmount.Text = "x"..playeritem.Amount	
		LootGui.Background.Item1.ItemPic.ImageTransparency = 0
		LootGui.Background.Item1.ItemPic.BackgroundTransparency = 1
		LootGui.Background.Item1.ItemPic.Image = itemsmodule["ImageMap"][itemsmodule[lootItem1].Type] --TODO doesn't this need to pick the right image map?
		LootGui.Background.Item1.ItemPic.ImageRectOffset = Vector2.new(itemsmodule[lootItem1]["ImageOffsetX"],itemsmodule[lootItem1]["ImageOffsetY"])
		LootGui.Background.Item1.ItemPic.ImageRectSize = Vector2.new(64,64)
		LootGui.Background.Item1.ItemPic.ScaleType = Enum.ScaleType.Stretch

	end
	
	if (lootItem2 == nil) then
		LootGui.Background.Item2.ItemPic.ImageTransparency = 1
		LootGui.Background.Item2.ItemName.Text = ""
	else
		LootGui.Background.Item2.ItemName.Text = lootItem2
		--Frame.ItemAmount.Text = "x"..playeritem.Amount	
		LootGui.Background.Item2.ItemPic.ImageTransparency = 0
		LootGui.Background.Item2.ItemPic.BackgroundTransparency = 1
		LootGui.Background.Item2.ItemPic.Image = itemsmodule["ImageMap"][itemsmodule[lootItem2].Type] --TODO doesn't this need to pick the right image map?
		LootGui.Background.Item2.ItemPic.ImageRectOffset = Vector2.new(itemsmodule[lootItem2]["ImageOffsetX"],itemsmodule[lootItem2]["ImageOffsetY"])
		LootGui.Background.Item2.ItemPic.ImageRectSize = Vector2.new(64,64)
		LootGui.Background.Item2.ItemPic.ScaleType = Enum.ScaleType.Stretch
	end
	
	
end

function HandleCorpseItemClicked(lootItemNumber)
	if (currentLootPrompt == nil) then
		return
	end

	if (currentLootPrompt.Parent == nil) then
		return
	end

	local enemyName = currentLootPrompt.Parent:GetAttribute("EnemyName")
	local corpseID = currentLootPrompt.Parent:GetAttribute("CorpseID")
	local lootItem1,lootItem2 = GetLootFunction:InvokeServer(enemyName,corpseID)
	
	if (lootItemNumber == 1) then
		if(lootItem1 == nil) then
			return
		end
		lootItem2 = nil
	else
		if(lootItem2 == nil) then
			return
		end
		lootItem1 = nil
	end
	
	local takenLootItem1,takenLootItem2 = TakeLootFunction:InvokeServer(enemyName,corpseID,lootItem1,lootItem2)

	UpdateItems(takenLootItem1,takenLootItem2)

	--If both items are gone from loot Destroy the corpse for this client
	if (takenLootItem1 == nil and takenLootItem2 == nil) then
		CloseLoot()
	end
end

function HandleContainerItemClicked(lootItemNumber)
	if (currentLootPrompt == nil) then
		return
	end

	if (currentLootPrompt.Parent == nil) then
		return
	end

	local containerID = currentLootPrompt.Parent:GetAttribute("ContainerID")
	local lootItem1,lootItem2 = GetLootFromContainerFunction:InvokeServer(containerID)

	if (lootItemNumber == 1) then
		if(lootItem1 == nil) then
			return
		end
		lootItem2 = nil
	else
		if(lootItem2 == nil) then
			return
		end
		lootItem1 = nil
	end

	local takenLootItem1,takenLootItem2 = TakeLootFromContainerFunction:InvokeServer(containerID,lootItem1,lootItem2)

	UpdateItems(takenLootItem1,takenLootItem2)

	--If both items are gone from loot Destroy the corpse for this client
	if (takenLootItem1 == nil and takenLootItem2 == nil) then
		CloseLoot()
	end
end

function HandleItemClicked(lootItemNumber)
	if (currentLootPrompt == nil) then
		return
	end

	if (currentLootPrompt.Name == "OpenContainer") then
		HandleContainerItemClicked(lootItemNumber)
	else
		HandleCorpseItemClicked(lootItemNumber)
	end
end


LootGui.Background.Item1.Activated:Connect(function()
	
	HandleItemClicked(1)
	
end)

LootGui.Background.Item2.Activated:Connect(function()
	
	HandleItemClicked(2)
	
end)

LootGui.Background.CloseButton.Activated:Connect(function()
	
	CloseLoot()
end)

local function onPromptTriggered(promptObject, player)

	if (promptObject.Name == "OpenCorpse") then
		
		currentLootPrompt = promptObject
		
		local enemyName = promptObject.Parent:GetAttribute("EnemyName")
		local corpseID = promptObject.Parent:GetAttribute("CorpseID")
		
		local lootItem1,lootItem2 = GetLootFunction:InvokeServer(enemyName,corpseID)
		
		UpdateItems(lootItem1,lootItem2)
		
		OpenCorpse()
		
	elseif (promptObject.Name == "LootAllCorpse") then
		
		currentLootPrompt = promptObject
		
		local enemyName = promptObject.Parent:GetAttribute("EnemyName")
		local corpseID = promptObject.Parent:GetAttribute("CorpseID")
		
		local lootItem1,lootItem2 = GetLootFunction:InvokeServer(enemyName,corpseID)
		
		local takenLootItem1,takenLootItem2 = TakeLootFunction:InvokeServer(enemyName,corpseID,lootItem1,lootItem2)

		--If both items are gone from loot Destroy the corpse for this client
		if (takenLootItem1 == nil and takenLootItem2 == nil) then
			CloseLoot()
		end
		
	elseif (promptObject.Name == "OpenContainer") then
		
		currentLootPrompt = promptObject
		
		local containerID = promptObject.Parent:GetAttribute("ContainerID")
		
		local lootItem1,lootItem2 = GetLootFromContainerFunction:InvokeServer(containerID)

		UpdateItems(lootItem1,lootItem2)

		OpenContainer()
		
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
