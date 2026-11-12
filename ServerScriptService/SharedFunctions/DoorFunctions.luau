local TweenService = game:GetService("TweenService")

local DoorFunctions = {}

local DEFAULT_AUTO_CLOSE_DELAY = 3

----------------------------------------------------------------
-- Attribute helpers
----------------------------------------------------------------

local function getNumberAttribute(instance, name, defaultValue)
	local value = instance:GetAttribute(name)

	if typeof(value) == "number" then
		return value
	end

	return defaultValue
end

local function getStringAttribute(instance, name, defaultValue)
	local value = instance:GetAttribute(name)

	if typeof(value) == "string" then
		return value
	end

	return defaultValue
end

local function getBoolAttribute(instance, name, defaultValue)
	local value = instance:GetAttribute(name)

	if typeof(value) == "boolean" then
		return value
	end

	return defaultValue
end

----------------------------------------------------------------
-- Mover helpers
----------------------------------------------------------------

local function getPivot(root)
	if root:IsA("Model") then
		return root:GetPivot()
	elseif root:IsA("BasePart") then
		return root.CFrame
	else
		error("[SlideDoor] Cannot get pivot from: " .. root:GetFullName())
	end
end

local function collectParts(root)
	local parts = {}

	if root:IsA("BasePart") then
		table.insert(parts, root)
	elseif not root:IsA("Model") then
		error("[SlideDoor] Moving root must be a Model or BasePart: " .. root:GetFullName())
	end

	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("BasePart") then
			table.insert(parts, inst)
		end
	end

	assert(#parts > 0, "[SlideDoor] No BaseParts found under: " .. root:GetFullName())

	return parts
end

local function buildMover(root)
	local mover = {}

	mover.root = root
	mover.parts = collectParts(root)
	mover.offsets = {}

	function mover:refreshOffsets()
		local pivot = getPivot(self.root)

		table.clear(self.offsets)

		for _, part in ipairs(self.parts) do
			if part and part.Parent then
				self.offsets[part] = pivot:ToObjectSpace(part.CFrame)
			end
		end
	end

	function mover:moveTo(targetPivot)
		for _, part in ipairs(self.parts) do
			if part and part.Parent then
				local offset = self.offsets[part]

				if offset then
					part.CFrame = targetPivot * offset
				end
			end
		end
	end

	mover:refreshOffsets()

	return mover
end

local function tweenMover(mover, fromCF, toCF, tweenInfo)
	local cfValue = Instance.new("CFrameValue")
	cfValue.Value = fromCF

	local changedConn
	changedConn = cfValue.Changed:Connect(function(newValue)
		mover:moveTo(newValue)
	end)

	local tween = TweenService:Create(cfValue, tweenInfo, {
		Value = toCF,
	})

	tween.Completed:Once(function()
		if changedConn then
			changedConn:Disconnect()
			changedConn = nil
		end

		mover:moveTo(toCF)
		cfValue:Destroy()
	end)

	tween:Play()

	return tween
end

----------------------------------------------------------------
-- Direction helpers
----------------------------------------------------------------

local function getSlideDirectionVector(door)
	assert(door.PrimaryPart, "[SlideDoor] Door model must have PrimaryPart set")

	local slideDirection = getStringAttribute(door, "SlideDirection", "Right")
	local cf = door.PrimaryPart.CFrame

	if slideDirection == "Right" then
		return cf.RightVector.Unit
	elseif slideDirection == "Left" then
		return (-cf.RightVector).Unit
	elseif slideDirection == "Forward" then
		return cf.LookVector.Unit
	elseif slideDirection == "Backward" then
		return (-cf.LookVector).Unit
	end

	-- Backward compatibility with old Axis/Flip attributes.
	local oldAxis = door:GetAttribute("Axis")
	if oldAxis == "X" or oldAxis == "Z" then
		local dirVector = oldAxis == "Z" and cf.LookVector or cf.RightVector
		local flip = door:GetAttribute("Flip") and -1 or 1

		warn("[SlideDoor] Using old Axis/Flip attributes. Prefer SlideDirection instead.")

		return (dirVector * flip).Unit
	end

	warn("[SlideDoor] Invalid SlideDirection '" .. tostring(slideDirection) .. "'. Defaulting to Right.")
	return cf.RightVector.Unit
end

local function getAxisRotation(axisName, degrees)
	local radians = math.rad(degrees)

	if axisName == "X" or axisName == "Pitch" then
		return CFrame.Angles(radians, 0, 0)
	elseif axisName == "Y" or axisName == "Yaw" then
		return CFrame.Angles(0, radians, 0)
	elseif axisName == "Z" or axisName == "Roll" then
		return CFrame.Angles(0, 0, radians)
	end

	warn("[SlideDoor] Invalid HandleAxis '" .. tostring(axisName) .. "'. Defaulting to X.")
	return CFrame.Angles(radians, 0, 0)
end

----------------------------------------------------------------
-- Handle helpers
----------------------------------------------------------------

local function findHandle(door)
	local handleName = getStringAttribute(door, "HandleName", "Handle")

	local handle = door:FindFirstChild(handleName, true)
	if handle and handle:IsA("BasePart") then
		return handle
	end

	handle = door:FindFirstChild("DoorHandle", true)
	if handle and handle:IsA("BasePart") then
		return handle
	end

	for _, inst in ipairs(door:GetDescendants()) do
		if inst:IsA("BasePart") and string.find(string.lower(inst.Name), "handle") then
			return inst
		end
	end

	return nil
end

local function findHandleHinge(door, handle)
	local hingeName = getStringAttribute(door, "HandleHingeName", "Hinge")

	if handle and handle.Parent then
		local siblingHinge = handle.Parent:FindFirstChild(hingeName)
		if siblingHinge and siblingHinge:IsA("BasePart") then
			return siblingHinge
		end
	end

	local hinge = door:FindFirstChild(hingeName, true)
	if hinge and hinge:IsA("BasePart") then
		return hinge
	end

	return nil
end

local function getHandleWelds(handle)
	local welds = {}

	if not handle or not handle.Parent then
		return welds
	end

	for _, inst in ipairs(handle:GetDescendants()) do
		if inst:IsA("WeldConstraint") then
			table.insert(welds, inst)
		end
	end

	for _, inst in ipairs(handle.Parent:GetDescendants()) do
		if inst:IsA("WeldConstraint") then
			if inst.Part0 == handle or inst.Part1 == handle then
				table.insert(welds, inst)
			end
		end
	end

	return welds
end

local function setHandleWeldsEnabled(handle, enabled)
	for _, weld in ipairs(getHandleWelds(handle)) do
		if weld and weld.Parent then
			weld.Enabled = enabled
		end
	end
end

local function cacheHandleClosedState(door, handle, hinge)
	if not handle or not hinge then
		return
	end

	if not door:GetAttribute("HandleCachedClosed") then
		door:SetAttribute("HandleClosedOffset", hinge.CFrame:ToObjectSpace(handle.CFrame))
		door:SetAttribute("HandleClosedCFrame", handle.CFrame)
		door:SetAttribute("HandleCachedClosed", true)
	end
end

local function hasHandleAnimationAttributes(door)
	return door:GetAttribute("HandleRotation") ~= nil
end

local function setHandleInstant(door, open)
	if not hasHandleAnimationAttributes(door) then
		return
	end

	local handleRotation = door:GetAttribute("HandleRotation")
	if typeof(handleRotation) ~= "number" then
		warn("[SlideDoor] HandleRotation must be a number:", door:GetFullName())
		return
	end

	local handleAxis =
		door:GetAttribute("HandleAxis")
		or door:GetAttribute("HandleDirection")
		or "X"

	local handle = findHandle(door)
	if not handle then
		warn("[SlideDoor] HandleRotation set, but no handle was found:", door:GetFullName())
		return
	end

	local hinge = findHandleHinge(door, handle)
	if not hinge then
		warn("[SlideDoor] Handle found, but no Hinge was found:", door:GetFullName())
		return
	end

	cacheHandleClosedState(door, handle, hinge)

	local closedOffset = door:GetAttribute("HandleClosedOffset")
	local rotation = getAxisRotation(handleAxis, open and handleRotation or 0)

	handle.CFrame = hinge.CFrame * rotation * closedOffset
end

local function tweenHandleRotation(door, open)
	if not hasHandleAnimationAttributes(door) then
		return nil
	end

	local handleRotation = door:GetAttribute("HandleRotation")
	if typeof(handleRotation) ~= "number" then
		warn("[SlideDoor] HandleRotation must be a number:", door:GetFullName())
		return nil
	end

	local handleAxis =
		door:GetAttribute("HandleAxis")
		or door:GetAttribute("HandleDirection")
		or "X"

	local handle = findHandle(door)
	if not handle then
		warn("[SlideDoor] HandleRotation set, but no Handle found:", door:GetFullName())
		return nil
	end

	local hinge = findHandleHinge(door, handle)
	if not hinge then
		warn("[SlideDoor] Handle found, but no Hinge found:", door:GetFullName())
		return nil
	end

	cacheHandleClosedState(door, handle, hinge)

	local closedOffset = door:GetAttribute("HandleClosedOffset")
	local moveTime = getNumberAttribute(door, "HandleMoveTime", 0.2)
	local tweenInfo = TweenInfo.new(moveTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	local rotation = getAxisRotation(handleAxis, open and handleRotation or 0)
	local targetCF = hinge.CFrame * rotation * closedOffset

	-- If the handle has a WeldConstraint to the door, it cannot rotate relative to the door.
	-- Disable the handle weld while open/rotated, then re-enable after it returns closed.
	if open then
		setHandleWeldsEnabled(handle, false)
	end

	local tween = TweenService:Create(handle, tweenInfo, {
		CFrame = targetCF,
	})

	tween.Completed:Once(function()
		handle.CFrame = targetCF

		if not open then
			setHandleWeldsEnabled(handle, true)
		end
	end)

	tween:Play()

	return tween
end

----------------------------------------------------------------
-- Door leaf detection
----------------------------------------------------------------

local function findDoorLeaves(door)
	local leftDoor = door:FindFirstChild("LeftDoor")
	local rightDoor = door:FindFirstChild("RightDoor")

	-- Double sliding door.
	if leftDoor and rightDoor then
		return {
			isDouble = true,
			leftRoot = leftDoor,
			rightRoot = rightDoor,
		}
	end

	-- Your current single-door structure:
	-- Door3
	--   Handle
	--   LeftDoor
	--   Glass
	--   Hinge
	--
	-- Move the whole door model so Handle, Glass, Hinge, and LeftDoor move together.
	if leftDoor and not rightDoor then
		return {
			isDouble = false,
			leftRoot = door,
			rightRoot = nil,
		}
	end

	-- Explicit single moving submodel.
	local slideOpenDoor = door:FindFirstChild("SlideOpenDoor")
	if slideOpenDoor then
		return {
			isDouble = false,
			leftRoot = slideOpenDoor,
			rightRoot = nil,
		}
	end

	local singleDoor = door:FindFirstChild("Door") or door:FindFirstChild("Panel")
	if singleDoor then
		return {
			isDouble = false,
			leftRoot = singleDoor,
			rightRoot = nil,
		}
	end

	if door.PrimaryPart then
		return {
			isDouble = false,
			leftRoot = door.PrimaryPart,
			rightRoot = nil,
		}
	end

	error("[SlideDoor] Could not find usable door leaf under: " .. door:GetFullName())
end

local function playDoorSound(door, soundName)

	local sound = door:FindFirstChild(soundName)
	if sound and sound:IsA("Sound") then
		sound:Play()
	end
end

----------------------------------------------------------------
-- Public function
----------------------------------------------------------------

function DoorFunctions.SlideDoor(door)
	if door:GetAttribute("opening") then
		return
	end

	assert(door and door:IsA("Model"), "[SlideDoor] Door must be a Model")
	assert(door.PrimaryPart, "[SlideDoor] Door model must have PrimaryPart set")

	local leaves = findDoorLeaves(door)

	local slideDistance = getNumberAttribute(door, "SlideDistance", 3.106)
	local speed = getNumberAttribute(door, "Speed", 0.25)
	local autoClose = getBoolAttribute(door, "AutoClose", true)
	local autoCloseDelay = getNumberAttribute(door, "AutoCloseDelay", DEFAULT_AUTO_CLOSE_DELAY)
	local handleBeforeSlide = getBoolAttribute(door, "HandleBeforeSlide", true)

	local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	local leftMover = buildMover(leaves.leftRoot)
	local rightMover = leaves.isDouble and buildMover(leaves.rightRoot) or nil

	-- Cache closed positions once.
	if not door:GetAttribute("CachedClosed") then
		door:SetAttribute("LeftClosedCFrame", getPivot(leaves.leftRoot))

		if leaves.isDouble and leaves.rightRoot then
			door:SetAttribute("RightClosedCFrame", getPivot(leaves.rightRoot))
		end

		door:SetAttribute("CachedClosed", true)
	end

	local leftClosed = door:GetAttribute("LeftClosedCFrame")
	local rightClosed = door:GetAttribute("RightClosedCFrame")

	local dirVector = getSlideDirectionVector(door)
	local offset = dirVector * slideDistance

	local function closeDoor()
		if door:GetAttribute("opening") then
			return
		end

		-- Cancel pending auto-close timers.
		door:SetAttribute("PendingCloseID", nil)

		door:SetAttribute("opening", true)

		-- Turn handle BEFORE closing.
		local handleTween = tweenHandleRotation(door, false)
		if handleTween then
			handleTween.Completed:Wait()
		else
			setHandleInstant(door, false)
		end

		-- Handle just changed relative to door, so refresh offsets before sliding.
		leftMover:refreshOffsets()
		if rightMover then
			rightMover:refreshOffsets()
		end
		
		playDoorSound(leaves.leftRoot, "DoorSound")

		local closeTween1 = tweenMover(leftMover, getPivot(leaves.leftRoot), leftClosed, tweenInfo)

		if leaves.isDouble and rightMover and rightClosed then
			tweenMover(rightMover, getPivot(leaves.rightRoot), rightClosed, tweenInfo)
		end

		closeTween1.Completed:Wait()

		door:SetAttribute("open", false)
		door:SetAttribute("opening", false)
	end

	local function scheduleAutoClose()
		if not autoClose then
			return
		end

		local closeId = os.clock()
		door:SetAttribute("PendingCloseID", closeId)

		task.delay(autoCloseDelay, function()
			if door:GetAttribute("PendingCloseID") ~= closeId then
				return
			end

			if door:GetAttribute("open") ~= true then
				return
			end

			if door:GetAttribute("opening") then
				return
			end

			closeDoor()
		end)
	end


	playDoorSound(leaves.leftRoot, "DoorSound")
	----------------------------------------------------------------
	-- Already open behavior
	----------------------------------------------------------------

	if door:GetAttribute("open") == true then
		if autoClose then
			-- Auto doors stay open and simply refresh the close timer.
			scheduleAutoClose()
		else
			-- Non-auto doors toggle closed when called again.
			closeDoor()
		end

		return
	end

	----------------------------------------------------------------
	-- Open behavior
	----------------------------------------------------------------

	door:SetAttribute("opening", true)

	-- Turn handle before opening.
	if handleBeforeSlide then
		local handleTween = tweenHandleRotation(door, true)
		if handleTween then
			handleTween.Completed:Wait()
		else
			setHandleInstant(door, true)
		end

		-- Handle just changed relative to door, so refresh before sliding.
		leftMover:refreshOffsets()
		if rightMover then
			rightMover:refreshOffsets()
		end
	end

	local leftTargetCF
	local rightTargetCF

	if leaves.isDouble then
		-- Right leaf moves in SlideDirection.
		-- Left leaf moves opposite.
		leftTargetCF = leftClosed + (-offset)
		rightTargetCF = rightClosed + offset
	else
		-- Single door moves exactly in SlideDirection.
		leftTargetCF = leftClosed + offset
	end

	local openTween1 = tweenMover(leftMover, getPivot(leaves.leftRoot), leftTargetCF, tweenInfo)

	if leaves.isDouble and rightMover then
		tweenMover(rightMover, getPivot(leaves.rightRoot), rightTargetCF, tweenInfo)
	end

	openTween1.Completed:Wait()

	-- Optional: turn handle after sliding instead.
	if not handleBeforeSlide then
		local handleTween = tweenHandleRotation(door, true)
		if handleTween then
			handleTween.Completed:Wait()
		else
			setHandleInstant(door, true)
		end
	end

	door:SetAttribute("open", true)
	door:SetAttribute("opening", false)

	if autoClose then
		scheduleAutoClose()
	end
end

return DoorFunctions