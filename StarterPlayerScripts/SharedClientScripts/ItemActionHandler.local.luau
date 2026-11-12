local replicatedStorage = game:GetService("ReplicatedStorage")
local ItemActionEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ItemAction")

local CurrentPlayer = game.Players.LocalPlayer

--TODO use this to run item action on client instead of server...but need way to wait until over before attaching bone
ItemActionEvent.OnClientEvent:Connect(function(playerItemName,itemActionModuleName)
	local openModule = CurrentPlayer.Character[playerItemName]:FindFirstChild(itemActionModuleName)

	if (openModule) then
		require(openModule).Open()
	end
end)
