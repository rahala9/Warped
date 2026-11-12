-- Place this in a LocalScript (e.g., StarterPlayerScripts or StarterGui)

local ProximityPromptService = game:GetService("ProximityPromptService")



local camera = game.Workspace.CurrentCamera -- Get the player's camera
local cameras = workspace:WaitForChild("Areas"):WaitForChild("MessHall"):WaitForChild("MessHallOffice"):WaitForChild("MessHallSecurityDesk"):WaitForChild("MessHallCameras"):WaitForChild("CameraParts"):GetChildren() -- Get all the camera parts in the folder
local currentCameraIndex = 1 -- Start with the first camera

--local colorCorrection = Instance.new("ColorCorrectionEffect") -- Create a ColorCorrectionEffect
--colorCorrection.Parent = camera -- Set the effect to the player's camera
local colorCorrection = game:GetService("Lighting").ColorCorrection


local userInputService = game:GetService("UserInputService")

local function applyBlackAndWhiteEffect()
	colorCorrection.Saturation = -1 -- Set saturation to -1 to make the colors grayscale
	colorCorrection.Contrast = 0.1 -- Slightly increase contrast for effect
	colorCorrection.Brightness = .3 -- Keep brightness normal
end

local function removeBlackAndWhiteEffect()
	colorCorrection.Saturation = 0
	colorCorrection.Contrast = 0
	colorCorrection.Brightness = 0
end

-- Function to switch to a new camera
local function switchToCamera(cameraPart)
	if cameraPart and cameraPart:IsA("Part") then
		camera.CameraType = Enum.CameraType.Scriptable -- Set camera to Scriptable mode
		camera.CFrame = cameraPart.CFrame -- Set the camera's CFrame to the camera part's CFrame
	end
end

-- Function to cycle through cameras
local function cycleCameras(actionName, userInputState, input)
	
	if (userInputState == Enum.UserInputState.Begin) then
		currentCameraIndex = currentCameraIndex + 1

		-- If index is greater than the number of cameras, go back to the first camera
		if currentCameraIndex > #cameras then
			currentCameraIndex = 1
		end

		switchToCamera(cameras[currentCameraIndex])
	end
	
	return Enum.ContextActionResult.Pass	
end

-- Detect when the "C" key is pressed to switch cameras
--userInputService.InputBegan:Connect(function(input)
--	if input.KeyCode == Enum.KeyCode.U then
--		cycleCameras()
--	end
--end)


-- Optionally reset the camera to default when the player leaves or script ends
--game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
--	camera.CameraType = Enum.CameraType.Custom -- Reset to default camera behavior
--end)

local viewing = false


local function stopViewing()
	game:GetService("ContextActionService"):UnbindAction("CycleCameras")
	game:GetService("ContextActionService"):UnbindAction("StopViewing")
	
	camera.CameraType = Enum.CameraType.Custom -- Reset to default camera behavior
	
	removeBlackAndWhiteEffect()
	
	viewing = false
	
	return Enum.ContextActionResult.Pass	

end


local function onPromptTriggered(promptObject, player)

	if (promptObject.Name ~= "ViewCameras") then
		return
	end
	
	if (viewing) then
		return
	end
	
	applyBlackAndWhiteEffect()
	
	game:GetService("ContextActionService"):BindAction("CycleCameras", cycleCameras, false, Enum.KeyCode.R)
	game:GetService("ContextActionService"):BindAction("StopViewing", stopViewing, false, Enum.KeyCode.Q)

	
	-- Set the initial camera to the first one
	switchToCamera(cameras[currentCameraIndex])


end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)