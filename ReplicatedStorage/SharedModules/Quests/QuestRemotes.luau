--[[
	QuestRemotes
	Creates and manages all quest-related RemoteEvents and RemoteFunctions.
	Lives in ReplicatedStorage.SharedModules.Quests.QuestRemotes

	Events:
		QuestStateChanged  – server → client, full player quest data
		QuestToast         – server → client, toast notification

	Functions:
		GetQuestSnapshot   – client → server, returns full quest data on demand
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local QuestRemotes = {}

function QuestRemotes.GetFolder()
	local folder = ReplicatedStorage:FindFirstChild("QuestRemotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "QuestRemotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

function QuestRemotes.GetRemoteEvent(name)
	local folder = QuestRemotes.GetFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

function QuestRemotes.GetRemoteFunction(name)
	local folder = QuestRemotes.GetFolder()
	local remote = folder:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
	end

	return remote
end

function QuestRemotes.Init()
	QuestRemotes.GetRemoteEvent("QuestStateChanged")
	QuestRemotes.GetRemoteEvent("QuestToast")
	QuestRemotes.GetRemoteFunction("GetQuestSnapshot")
end

return QuestRemotes
