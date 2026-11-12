--[[
	DialogRemotes
	Creates and manages dialog-related RemoteEvents.

	Events:
		DialogOpened     – server → client: send node data to display
		DialogClosed     – server → client: tell client to close dialog UI
		RequestDialog    – client → server: player wants to talk to an NPC
		SelectOption     – client → server: player picked a dialog option
		CloseDialog      – client → server: player closed the dialog
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DialogRemotes = {}

function DialogRemotes.GetFolder()
	local folder = ReplicatedStorage:FindFirstChild("DialogRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "DialogRemotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

function DialogRemotes.GetRemoteEvent(name)
	local folder = DialogRemotes.GetFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

function DialogRemotes.Init()
	DialogRemotes.DialogOpened = DialogRemotes.GetRemoteEvent("DialogOpened")
	DialogRemotes.DialogClosed = DialogRemotes.GetRemoteEvent("DialogClosed")
	DialogRemotes.RequestDialog = DialogRemotes.GetRemoteEvent("RequestDialog")
	DialogRemotes.SelectOption = DialogRemotes.GetRemoteEvent("SelectOption")
	DialogRemotes.CloseDialog = DialogRemotes.GetRemoteEvent("CloseDialog")
end

return DialogRemotes
