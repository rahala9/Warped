local SwitchConfigurations = {}

-- Define terminal types and their behaviors
SwitchConfigurations.Switches = {
	
	["LaserTrap1Switch"] = {
		switchType = "TwoPositionLever",
		target = "LaserTrap1",
		action = "ToggleLaserTrap",
		switchHandlePath = "workspace.Areas.StarhopStation.TEST.SecretPassage.LaserTrap1Lever.Body.Handle",
		targetPath = "workspace.Areas.StarhopStation.TEST.SecretPassage.LaserTrap1",
		messages = {"Laser trap toggled"}
	},
	
	["ElevatorUp"] = {
		switchType = "InvisiblePushButton",
		target = "ElevatorPlatform",
		action = "PlatformUp",
		floors = {Vector3.new(0,5.46,0),Vector3.new(0,28.46,0),Vector3.new(0,43.46,0),Vector3.new(0,54.46,0)},
		targetPath = "workspace.Areas.StarhopStation.Commissary.ElevatorPlatform.Platform",
		messages = {"Going Up"}
		
	},
	
	["ElevatorDown"] = {
		switchType = "InvisiblePushButton",
		target = "ElevatorPlatform",
		action = "PlatformDown",
		floors = {Vector3.new(0,5.46,0),Vector3.new(0,28.46,0),Vector3.new(0,43.46,0),Vector3.new(0,54.46,0)},
		targetPath = "workspace.Areas.StarhopStation.Commissary.ElevatorPlatform.Platform",
		messages = {"Going Down"}
	},
	
	["PowerCoreOn"] = {
		switchType = "VerticalInsert",
		target = "PowerCore1",
		action = "PowerCoreOn",
		floors = {Vector3.new(0,0,0),Vector3.new(0,3.93,0)},
		movementMode = "Tween",
		speed = 2,
		responsiveness = 25,
		arrivalTolerance = 0.08,
		timeout = 5,
		switchOnPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerBase.PowerCoreOn",
		switchOffPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerBase.PowerCoreOff",
		targetPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerCell",
		messages = {"Power Core On"},
		powerCoreId = "PowerCore1"
	},
	
	["PowerCoreOff"] = {
		switchType = "VerticalInsert",
		target = "PowerCore1",
		action = "PowerCoreOff",
		floors = {Vector3.new(0,0,0),Vector3.new(0,3.93,0)},
		movementMode = "Tween",
		speed = 2,
		responsiveness = 25,
		arrivalTolerance = 0.08,
		timeout = 5,
		switchOnPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerBase.PowerCoreOn",
		switchOffPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerBase.PowerCoreOff",
		targetPath = "workspace.Areas.StarhopStation.TEST.PowerCore1.PowerCell",
		messages = {"Power Core Off"},
		powerCoreId = "PowerCore1"
	},

}

return SwitchConfigurations