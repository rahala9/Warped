local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):wait()

local replicatedStorage = game:GetService("ReplicatedStorage")
local MouseAttachmentEvent = replicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("MouseAttachment")
local plug = replicatedStorage:WaitForChild("SharedClientAssets"):WaitForChild("plug")

local mouse = game.Players.LocalPlayer:GetMouse()
local item = nil
local mouseMoveEvent = nil
local plugVisual = nil

local function makeAttachment(part, pos)
	local attachment = Instance.new("Attachment") 
	local pos = pos or Vector3.new()

	attachment.Position = pos
	attachment.Parent = part

	return attachment
end

local function connectWithRopeConstraint(player,attachItem,attachment0,attachment1)
	local newRope = Instance.new("RopeConstraint")
	--local dist = (part0.Position - part1.Position).Magnitude

	--local RightHand = player.Character:FindFirstChild("RightHand")
	--local RightGrip = RightHand:FindFirstChild("RightGripAttachment")



	--local attachment0 = makeAttachment(part0)
	--local attachment1 = attachment2

	newRope.Attachment0 = attachment0
	newRope.Attachment1 = attachment1

	newRope.Visible = true
	newRope.Length = 5 --dist
	newRope.Thickness = .3
	newRope.Color = BrickColor.White()

	newRope.Parent = attachItem
end

MouseAttachmentEvent.OnClientEvent:Connect(function(attachItem)
	
	if (attachItem == nil) then
		
		if (mouseMoveEvent ~= nil) then
			mouseMoveEvent:Disconnect()
		end
		
		mouseMoveEvent = nil
		
		item:Destroy()
		plugVisual:Destroy()
		item = nil
		plugVisual = nil
		
		return
	end
	
	
	item = Instance.new("Part")
	item.Name = "MouseFollowPart"
	item.CanCollide = false
	item.Anchored = true
	item.Size = Vector3.new(.5,.5,.5)
	item.Transparency = 1
	
	item.Parent = attachItem
	
	plugVisual = plug:Clone()
	plugVisual.CanCollide = false
	plugVisual.Anchored = true
	plugVisual.Parent = item
	
	--local weld = Instance.new("WeldConstraint")
	--weld.Part0 = plugVisual
	--weld.Part1 = item
	--weld.Parent = plugVisual
	
	local attachment = Instance.new("Attachment") 
	attachment.Position = item.Position
	attachment.Parent = item

	connectWithRopeConstraint(player,attachItem,attachItem.ClickPart.Attachment,attachment)
	
	mouseMoveEvent = mouse.Move:Connect(function()
		if item ~= nil then --this event will be always firing, but we wanna change the target's position only when clicking, that's why we check if down is true
			item.Position = Vector3.new(-39,mouse.Hit.Position.Y-1,mouse.Hit.Position.Z) --the part that sets the position!
			plugVisual.Position = item.Position
		end 
	end) 
end)
