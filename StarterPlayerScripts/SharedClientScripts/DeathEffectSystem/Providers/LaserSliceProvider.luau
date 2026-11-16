local sharedClientScripts = script.Parent.Parent.Parent
local laserProviderFolder = sharedClientScripts
	:WaitForChild("LaserSliceSystem")
	:WaitForChild("Providers")
local LaserProvider = require(laserProviderFolder:WaitForChild("SlicedCrewSliceProvider"))

return {
	Render = function(character: Model, payload)
		return LaserProvider.Render(character, payload)
	end,
}
