local characterUtility = {}

local rows = 5
local columns = 8
local faceSize = Vector3.new(.85,.85,.85) --script.Parent.face.Size
local faces = {Vector2.new(0*64,0*64),Vector2.new(1*64,0*64),Vector2.new(2*64,0*64),Vector2.new(3*64,0*64),Vector2.new(4*64,0*64),Vector2.new(5*64,0*64),Vector2.new(6*64,0*64),Vector2.new(7*64,0*64),
	Vector2.new(0*64,1*64),Vector2.new(1*64,1*64),Vector2.new(2*64,1*64),Vector2.new(3*64,1*64),Vector2.new(4*64,1*64),Vector2.new(5*64,1*64),Vector2.new(6*64,1*64),Vector2.new(7*64,1*64),
	Vector2.new(0*64,2*64),Vector2.new(1*64,2*64),Vector2.new(2*64,2*64),Vector2.new(3*64,2*64),Vector2.new(4*64,2*64),Vector2.new(5*64,2*64),Vector2.new(6*64,2*64),Vector2.new(7*64,2*64),
	Vector2.new(0*64,3*64),Vector2.new(1*64,3*64),Vector2.new(2*64,3*64),Vector2.new(3*64,3*64),Vector2.new(4*64,3*64),Vector2.new(5*64,3*64),Vector2.new(6*64,3*64),Vector2.new(7*64,3*64),
	Vector2.new(0*64,4*64),Vector2.new(1*64,4*64),Vector2.new(2*64,4*64),Vector2.new(3*64,4*64),Vector2.new(4*64,4*64),Vector2.new(5*64,4*64),Vector2.new(6*64,4*64),Vector2.new(7*64,4*64)
}

function characterUtility.ChangeFace(characterModel,face)

	local CurrentColumn = (faces[face].X/64) + 1 
	local CurrentRow =(faces[face].Y/64) + 1 

	characterModel.Face.faceTexture.StudsPerTileU = columns*faceSize.X
	characterModel.Face.faceTexture.StudsPerTileV = rows*faceSize.Y
	characterModel.Face.faceTexture.OffsetStudsU = (faceSize.X*(CurrentColumn))-(faceSize.X/2)
	characterModel.Face.faceTexture.OffsetStudsV = (faceSize.Y*(CurrentRow))-(faceSize.Y/2) + 0.05

end

return characterUtility