local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("Config"))
local Effects = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Effects"))
local Items = require(ReplicatedStorage:WaitForChild("InventorySystem"):WaitForChild("Items"))
local AdminRemote = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("Admin")

if not RunService:IsStudio() and Config.AdminUserIds[player.UserId] ~= true then return end

local COLORS = {
	Panel = Color3.fromRGB(18, 23, 31),
	Surface = Color3.fromRGB(29, 37, 49),
	Surface2 = Color3.fromRGB(38, 49, 64),
	Accent = Color3.fromRGB(0, 190, 235),
	Good = Color3.fromRGB(55, 195, 105),
	Bad = Color3.fromRGB(225, 75, 75),
	Text = Color3.fromRGB(235, 242, 248),
	Muted = Color3.fromRGB(150, 165, 180),
}

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 5)
	value.Parent = parent
end

local function label(parent, text, size, position)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.Gotham
	value.Text = text
	value.TextColor3 = COLORS.Text
	value.TextSize = 14
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.Size = size
	value.Position = position or UDim2.new()
	value.Parent = parent
	return value
end

local function button(parent, text, size, position, color)
	local value = Instance.new("TextButton")
	value.AutoButtonColor = true
	value.BackgroundColor3 = color or COLORS.Surface2
	value.BorderSizePixel = 0
	value.Font = Enum.Font.GothamSemibold
	value.Text = text
	value.TextColor3 = COLORS.Text
	value.TextSize = 13
	value.Size = size
	value.Position = position or UDim2.new()
	value.Parent = parent
	corner(value, 5)
	return value
end

local gui = Instance.new("ScreenGui")
gui.Name = "AdminTestGui"
gui.DisplayOrder = 1000
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(760, 540)
main.BackgroundColor3 = COLORS.Panel
main.BorderSizePixel = 0
main.Parent = gui
corner(main, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.Accent
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = main

local title = label(main, "ADMIN TEST PANEL", UDim2.new(1, -140, 0, 42), UDim2.fromOffset(16, 0))
title.Font = Enum.Font.GothamBold
title.TextColor3 = COLORS.Accent
title.TextSize = 17
label(main, "F8", UDim2.fromOffset(42, 42), UDim2.new(1, -92, 0, 0)).TextColor3 = COLORS.Muted
local closeButton = button(main, "X", UDim2.fromOffset(38, 30), UDim2.new(1, -48, 0, 6), COLORS.Bad)

local targetButton = button(main, "Target: " .. player.Name, UDim2.fromOffset(245, 34), UDim2.fromOffset(16, 48))
local effectsTab = button(main, "Effects", UDim2.fromOffset(100, 34), UDim2.fromOffset(272, 48), COLORS.Accent)
local itemsTab = button(main, "Items", UDim2.fromOffset(100, 34), UDim2.fromOffset(378, 48))

local searchBox = Instance.new("TextBox")
searchBox.Name = "Search"
searchBox.BackgroundColor3 = COLORS.Surface
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search effects..."
searchBox.PlaceholderColor3 = COLORS.Muted
searchBox.Text = ""
searchBox.TextColor3 = COLORS.Text
searchBox.TextSize = 14
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Position = UDim2.fromOffset(16, 92)
searchBox.Size = UDim2.new(1, -186, 0, 34)
searchBox.Parent = main
corner(searchBox, 5)
local searchPadding = Instance.new("UIPadding")
searchPadding.PaddingLeft = UDim.new(0, 10)
searchPadding.Parent = searchBox

local amountBox = Instance.new("TextBox")
amountBox.Name = "Amount"
amountBox.BackgroundColor3 = COLORS.Surface
amountBox.BorderSizePixel = 0
amountBox.ClearTextOnFocus = false
amountBox.Font = Enum.Font.GothamSemibold
amountBox.PlaceholderText = "Amount"
amountBox.Text = "1"
amountBox.TextColor3 = COLORS.Text
amountBox.TextSize = 14
amountBox.Position = UDim2.new(1, -160, 0, 92)
amountBox.Size = UDim2.fromOffset(144, 34)
amountBox.Visible = false
amountBox.Parent = main
corner(amountBox, 5)

local list = Instance.new("ScrollingFrame")
list.Name = "Catalog"
list.Active = true
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.BackgroundColor3 = COLORS.Surface
list.BorderSizePixel = 0
list.CanvasSize = UDim2.new()
list.ScrollBarImageColor3 = COLORS.Accent
list.ScrollBarThickness = 6
list.Position = UDim2.fromOffset(16, 138)
list.Size = UDim2.new(1, -32, 1, -188)
list.Parent = main
corner(list, 5)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)
padding.Parent = list

local status = label(main, "Ready.", UDim2.new(1, -32, 0, 32), UDim2.new(0, 16, 1, -40))
status.TextColor3 = COLORS.Muted

local activeTab = "Effects"
local selectedTarget = player

local function getPlayers()
	local values = Players:GetPlayers()
	table.sort(values, function(a, b) return a.Name:lower() < b.Name:lower() end)
	return values
end

local function validateTarget()
	if not selectedTarget or not selectedTarget.Parent then selectedTarget = player end
	targetButton.Text = "Target: " .. selectedTarget.Name
	return selectedTarget
end

local function send(action, name, amount)
	local target = validateTarget()
	AdminRemote:FireServer(action, {
		TargetUserId = target.UserId,
		Name = name,
		Amount = amount,
	})
	status.Text = string.format("Sending %s for %s...", action, target.Name)
	status.TextColor3 = COLORS.Muted
end

local function clearRows()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function addRow(name, description)
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundColor3 = COLORS.Surface2
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, -2, 0, 46)
	row.Parent = list
	corner(row, 4)
	local nameLabel = label(row, name, UDim2.new(0.42, -8, 0, 22), UDim2.fromOffset(10, 3))
	nameLabel.Font = Enum.Font.GothamSemibold
	local descLabel = label(row, description or "", UDim2.new(0.58, -18, 0, 18), UDim2.fromOffset(10, 24))
	descLabel.TextColor3 = COLORS.Muted
	descLabel.TextSize = 11
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd

	if activeTab == "Effects" then
		local remove = button(row, "Remove", UDim2.fromOffset(82, 30), UDim2.new(1, -178, 0, 8), COLORS.Bad)
		local apply = button(row, "Apply", UDim2.fromOffset(82, 30), UDim2.new(1, -90, 0, 8), COLORS.Good)
		apply.Activated:Connect(function() send("AddEffect", name) end)
		remove.Activated:Connect(function() send("RemoveEffect", name) end)
	else
		local give = button(row, "Give", UDim2.fromOffset(82, 30), UDim2.new(1, -90, 0, 8), COLORS.Good)
		give.Activated:Connect(function() send("AddItem", name, tonumber(amountBox.Text) or 1) end)
	end
end

local function rebuild()
	clearRows()
	local query = searchBox.Text:lower()
	local entries = {}
	local source = activeTab == "Effects" and Effects or Items
	for name, definition in pairs(source) do
		if typeof(definition) == "table" then
			local displayName = definition.DisplayName or definition.Name or name
			local haystack = (name .. " " .. tostring(displayName) .. " " .. tostring(definition.Description or definition.Desc or "")):lower()
			if query == "" or haystack:find(query, 1, true) then
				table.insert(entries, {
					Name = name,
					Description = definition.Description or definition.Desc or tostring(displayName),
				})
			end
		end
	end
	table.sort(entries, function(a, b) return a.Name:lower() < b.Name:lower() end)
	for _, entry in ipairs(entries) do addRow(entry.Name, entry.Description) end
	status.Text = string.format("%d %s available.", #entries, activeTab:lower())
	status.TextColor3 = COLORS.Muted
end

local function setTab(tab)
	activeTab = tab
	effectsTab.BackgroundColor3 = tab == "Effects" and COLORS.Accent or COLORS.Surface2
	itemsTab.BackgroundColor3 = tab == "Items" and COLORS.Accent or COLORS.Surface2
	amountBox.Visible = tab == "Items"
	searchBox.PlaceholderText = tab == "Effects" and "Search effects..." or "Search items..."
	rebuild()
end

targetButton.Activated:Connect(function()
	local values = getPlayers()
	local currentIndex = table.find(values, selectedTarget) or 0
	selectedTarget = values[(currentIndex % #values) + 1]
	validateTarget()
end)
effectsTab.Activated:Connect(function() setTab("Effects") end)
itemsTab.Activated:Connect(function() setTab("Items") end)
searchBox:GetPropertyChangedSignal("Text"):Connect(rebuild)
closeButton.Activated:Connect(function() gui.Enabled = false end)
Players.PlayerRemoving:Connect(function(leaving)
	if selectedTarget == leaving then selectedTarget = player; validateTarget() end
end)

AdminRemote.OnClientEvent:Connect(function(action, payload)
	if action ~= "AdminResult" or typeof(payload) ~= "table" then return end
	status.Text = payload.Message or (payload.Ok and "Done." or "Request failed.")
	status.TextColor3 = payload.Ok and COLORS.Good or COLORS.Bad
end)

UserInputService.InputBegan:Connect(function(input, _processed)
	if input.KeyCode ~= Config.ToggleKey then return end
	gui.Enabled = not gui.Enabled
	if gui.Enabled then validateTarget(); rebuild() end
	-- The retired Studio-authored panel may still be toggled by an old
	-- ShowAdminAction binding. Keep it out of the way of this maintained panel.
	task.defer(function()
		local sharedGui = player.PlayerGui:FindFirstChild("SharedGUI")
		local legacyGui = sharedGui and sharedGui:FindFirstChild("AdminGui")
		if legacyGui and legacyGui:IsA("ScreenGui") then legacyGui.Enabled = false end
	end)
end)

setTab("Effects")
