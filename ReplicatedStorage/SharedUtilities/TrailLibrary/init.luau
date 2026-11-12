-- Modules
local InwardTrailModule = require(script.InwardTrail)
local SpiralTrailModule = require(script.SpiralTrail)

-- In case I want to add more trails I don't want things to look messy in the Modules folder.
return {
	InwardTrail = InwardTrailModule,
	SpiralTrail = SpiralTrailModule
}