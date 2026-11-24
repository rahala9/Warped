local Config = {}

Config.TagName = "RestStation"
Config.DefinitionAttribute = "RestDefinition"
Config.EnabledAttribute = "RestEnabled"
Config.OccupantAttribute = "RestOccupantUserId"
Config.RestingAttribute = "Resting"

Config.RestPointName = "RestPoint"
Config.ExitPointName = "ExitPoint"
Config.PromptName = "RestPrompt"

Config.StateRemoteName = "RestStateChanged"
Config.ExitRemoteName = "RequestRestExit"

Config.DefaultPromptDistance = 10
Config.DistanceTolerance = 4
Config.ExitKey = Enum.KeyCode.E
Config.ExitGamepadKey = Enum.KeyCode.ButtonB

-- Definitions are shared by every station of that type. Attachment placement,
-- not per-chair configuration, controls the exact character position/rotation.
Config.Definitions = {
	Chair = {
		EnterText = "Sit",
		ExitText = "Stand",
		ObjectText = "Chair",
		AnimationId = "rbxassetid://99211309716235", --82670185019554",
	},
	ChairForward = {
		EnterText = "Sit",
		ExitText = "Stand",
		ObjectText = "Chair",
		AnimationId = "rbxassetid://137665163986879",
	},
	TableChair = {
		EnterText = "Sit",
		ExitText = "Stand",
		ObjectText = "Table",
		AnimationId = "rbxassetid://12389770058",
	},
	Bed = {
		EnterText = "Sleep",
		ExitText = "Wake",
		ObjectText = "Bed",
		AnimationId = "rbxassetid://8949463565",
	},
	RelaxedChair = {
		EnterText = "Relax",
		ExitText = "Stand",
		ObjectText = "Chair",
		-- Camp's original proven Relaxing pose. The later 99208674530252
		-- replacement produces the forward-reaching pose on Warped's rig.
		AnimationId = "rbxassetid://82670185019554",
	},
}

return Config
