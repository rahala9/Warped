local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("LaserSliceSystem")
local Config = require(sharedFolder:WaitForChild("Config"))

local BakedSliceProvider = {}

function BakedSliceProvider.Render(character: Model, payload)
	local templates = sharedFolder:FindFirstChild(Config.Baked.TemplateFolderName)
	if not templates then
		warn("[LaserSliceSystem] Missing baked template folder", Config.Baked.TemplateFolderName)
		return nil
	end

	local templateKey = payload.TemplateKey or Config.Baked.DefaultTemplate
	local template = templates:FindFirstChild(templateKey)
	if not template or not template:IsA("Model") then
		warn("[LaserSliceSystem] Missing baked template", templateKey)
		return nil
	end

	local clone = template:Clone()
	clone.Name = character.Name .. "_BakedLaserSlices"
	clone:PivotTo(character:GetPivot())
	clone.Parent = workspace
	return clone
end

return BakedSliceProvider
