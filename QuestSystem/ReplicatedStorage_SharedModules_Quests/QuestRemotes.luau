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

function QuestRemotes.Init()
	QuestRemotes.GetRemoteEvent("QuestStateChanged")
	QuestRemotes.GetRemoteEvent("QuestToast")
end

return QuestRemotes