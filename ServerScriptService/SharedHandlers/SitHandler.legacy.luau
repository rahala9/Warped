local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectsFunctions = require(ServerScriptService.Data.DataEffectsFunctions)

local SitServerEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("SitServer")

local function getCharacterState(player)
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return nil
	end

	return character, humanoid, hrp
end

local function setPromptUiState(prompt, occupied)
	if prompt.Name == "Sit" then
		prompt.ActionText = occupied and "Stand" or "Sit"
		--prompt.KeyboardKeyCode = occupied and Enum.KeyCode.Q or Enum.KeyCode.E
	elseif prompt.Name == "Sleep" then
		prompt.ActionText = occupied and "Wake" or "Sleep"
	end
end

local function enter(player, prompt)
	if prompt:GetAttribute("Owner") then
		return
	end

	local character, humanoid, hrp = getCharacterState(player)
	if not character then
		return
	end

	local enterSpot = prompt.Parent:FindFirstChild("enter")
	if not enterSpot then
		warn("SitHandler server: missing enter part for", prompt:GetFullName())
		return
	end

	local enterEffect = prompt:GetAttribute("EnterEffect")
	local enterAnimation = prompt:GetAttribute("EnterAnimation")

	prompt:SetAttribute("Owner", player.Name)

	if enterEffect and enterEffect ~= "" then
		EffectsFunctions.AddEffect(player, enterEffect, 1, prompt.Parent.Name)
	end

	hrp.Anchored = true
	task.wait()

	character:PivotTo(enterSpot.WorldCFrame)

	if enterAnimation and enterAnimation ~= "" then
		SitServerEvent:FireClient(player, enterAnimation)
	end
end

local function exit(player, prompt)
	if prompt:GetAttribute("Owner") ~= player.Name then
		return
	end

	local character, humanoid, hrp = getCharacterState(player)
	if not character then
		prompt:SetAttribute("Owner", nil)
		SitServerEvent:FireClient(player, "Idle")
		return
	end

	local exitSpot = prompt.Parent:FindFirstChild("exit")
	if not exitSpot then
		warn("SitHandler server: missing exit part for", prompt:GetFullName())
		prompt:SetAttribute("Owner", nil)
		SitServerEvent:FireClient(player, "Idle")
		return
	end

	local exitEffect = prompt:GetAttribute("ExitEffect")
	local exitAnimation = prompt:GetAttribute("ExitAnimation")
	local exitAnimationOffsetY = prompt:GetAttribute("ExitAnimationOffsetY") or 0
	local exitAnimationOffsetZ = prompt:GetAttribute("ExitAnimationOffsetZ") or 0

	if exitEffect and exitEffect ~= "" then
		EffectsFunctions.RemoveEffect(player, exitEffect, prompt.Parent.Name)
	end

	if exitAnimation and exitAnimation ~= "" then
		character:PivotTo(character:GetPivot() * CFrame.new(0, exitAnimationOffsetY, exitAnimationOffsetZ))
	end

	character:PivotTo(exitSpot.WorldCFrame)
	task.wait()
	hrp.Anchored = false

	prompt:SetAttribute("Owner", nil)

	-- Always reset animation on stand/wake
	SitServerEvent:FireClient(player, "Idle")
end

local function onPromptTriggered(promptObject, player)
	if promptObject.Name ~= "Sit" and promptObject.Name ~= "Sleep" then
		return
	end

	promptObject.Enabled = false

	local ok, err = pcall(function()
		local owner = promptObject:GetAttribute("Owner")
		local occupiedByLocalPlayer = owner == player.Name

		if occupiedByLocalPlayer then
			exit(player, promptObject)
			setPromptUiState(promptObject, false)
		else
			enter(player, promptObject)
			setPromptUiState(promptObject, true)
		end
	end)

	promptObject.Enabled = true

	if not ok then
		warn("SitHandler server error:", err)
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)