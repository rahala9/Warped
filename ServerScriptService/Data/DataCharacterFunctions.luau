--Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--Remote Events
local CharacterChangedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("CharacterChanged")

--Functions
--local AttributeFunctions = require(ServerScriptService.Data.DataAttributesFunctions)

--Definition Modules
local CharacterInfoDef = require(ServerStorage.Data.Templates.Character)
local ProfileTemplate = require(game.ServerScriptService:WaitForChild("Data"):WaitForChild("Templates").ProfileTemplate)

--AssetsAssets

--Modules
local Data = require(ServerScriptService.Data.Data)

local functions = {}

local girlsOutfitsCount = 24
local boysOutfitsCount = 30
local currentOutfitsCount = boysOutfitsCount

local girlsHairCount = 37
local boysHairCount = 30
local currentHairCount = boysHairCount

local boyHoods = {[8]="",[18]=""}
local girlHoods = {[4]=""}
local currentHoods = girlHoods

local faceSize = Vector3.new(.85,.85,.85) --script.Parent.face.Size
local rows = 5
local columns = 8

local faces = {Vector2.new(0*64,0*64),Vector2.new(1*64,0*64),Vector2.new(2*64,0*64),Vector2.new(3*64,0*64),Vector2.new(4*64,0*64),Vector2.new(5*64,0*64),Vector2.new(6*64,0*64),Vector2.new(7*64,0*64),
	Vector2.new(0*64,1*64),Vector2.new(1*64,1*64),Vector2.new(2*64,1*64),Vector2.new(3*64,1*64),Vector2.new(4*64,1*64),Vector2.new(5*64,1*64),Vector2.new(6*64,1*64),Vector2.new(7*64,1*64),
	Vector2.new(0*64,2*64),Vector2.new(1*64,2*64),Vector2.new(2*64,2*64),Vector2.new(3*64,2*64),Vector2.new(4*64,2*64),Vector2.new(5*64,2*64),Vector2.new(6*64,2*64),Vector2.new(7*64,2*64),
	Vector2.new(0*64,3*64),Vector2.new(1*64,3*64),Vector2.new(2*64,3*64),Vector2.new(3*64,3*64),Vector2.new(4*64,3*64),Vector2.new(5*64,3*64),Vector2.new(6*64,3*64),Vector2.new(7*64,3*64),
	Vector2.new(0*64,4*64),Vector2.new(1*64,4*64),Vector2.new(2*64,4*64),Vector2.new(3*64,4*64),Vector2.new(4*64,4*64),Vector2.new(5*64,4*64),Vector2.new(6*64,4*64),Vector2.new(7*64,4*64)
}

--function functions.DevSetGender(player,gender)
--	local profile = Data[player]
--	if (profile == nil) then return nil end
	
--	profile.Data.Character.Gender = gender
--end

function functions.SetGender(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	--TODO a bit more difficult since the whole character model is different
	local char = player.Character
	local gender = profile.Data.Character.Gender
	
	if (gender == "Girls") then
		--newCharacter:Destroy()
		--newCharacter = ReplicatedStorage:WaitForChild("CharacterCreatorGirls"):Clone()
		--newCharacter:SetPrimaryPartCFrame(CFrame.new(Vector3.new(282, 30.5, 143.5)) * CFrame.Angles(0,math.rad(-90),0))


		--face = newCharacter:WaitForChild("face")
		--skull = newCharacter:WaitForChild("skull")
		--scalp = newCharacter:WaitForChild("scalp")
		
		--player.Character = replicatedStorage:WaitForChild("GirlStarter"):Clone()
		--player.Character.Humanoid.HipHeight = 2.65

		currentHairCount = girlsHairCount
		currentOutfitsCount = girlsOutfitsCount
		currentHoods = girlHoods


		--newCharacter.Parent = workspace

	else
		--newCharacter:Destroy()
		--newCharacter = ReplicatedStorage:WaitForChild("CharacterCreatorBoys"):Clone()
		--newCharacter:SetPrimaryPartCFrame(CFrame.new(Vector3.new(282, 30.5, 143.5)) * CFrame.Angles(0,math.rad(-90),0))


		--face = newCharacter:WaitForChild("face")
		--skull = newCharacter:WaitForChild("skull")
		--scalp = newCharacter:WaitForChild("scalp")

		currentHairCount = boysHairCount
		currentOutfitsCount = boysOutfitsCount
		currentHoods = boyHoods
		

		--newCharacter.Parent = workspace
	end
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.SetOutfit(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	local char = player.Character
	
	local outfit = profile.Data.Character.Outfit
	
	for i = 1, currentOutfitsCount do
		
		if (outfit == i) then
			char["kid"..outfit].Transparency = 0;
			char["kid"..outfit.."b"].Transparency = 0;

			if (char:FindFirstChild("kid"..outfit.."c") ~= nil) then
				char["kid"..outfit.."c"].Transparency = 0;
			end
		else
			if (char:FindFirstChild("kid"..i) ~= nil) then
				char["kid"..i]:Destroy()
				char["kid"..i.."b"]:Destroy()

				if (char:FindFirstChild("kid"..i.."c") ~= nil) then
					char["kid"..i.."c"]:Destroy()
				end
			end
			
		end
	end
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.GetFaceColumnRow(player)
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	local face = faces[profile.Data.Character.Face]
	local CurrentColumn = (face.X/64) + 1 
	local CurrentRow =(face.Y/64) + 1 
	
	return CurrentColumn,CurrentRow
end

function functions.SetFace(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	local char = player.Character
	local face = faces[profile.Data.Character.Face]
	local CurrentColumn = (face.X/64) + 1 
	local CurrentRow =(face.Y/64) + 1 

	char.face.faceTexture.StudsPerTileU = columns*faceSize.X
	char.face.faceTexture.StudsPerTileV = rows*faceSize.Y
	char.face.faceTexture.OffsetStudsU = (faceSize.X*(CurrentColumn))-(faceSize.X/2)
	char.face.faceTexture.OffsetStudsV = (faceSize.Y*(CurrentRow))-(faceSize.Y/2) + 0.05
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.SetHair(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end

	local char = player.Character
	local hair = profile.Data.Character.Hair
	local outfit = profile.Data.Character.Outfit

	for i = 1, currentHairCount do
		
		if ((hair == i)) then
			
			if ( not currentHoods[outfit]) then
				char["hair"..hair].Transparency = 0

				if (char:FindFirstChild("hair"..hair.."a") ~= nil) then
					char["hair"..hair.."a"].Transparency = 0
				end

				if (char:FindFirstChild("hair"..hair.."b") ~= nil) then
					char["hair"..hair.."b"].Transparency = 0
				end

				if (char:FindFirstChild("hair"..hair.."c") ~= nil) then
					char["hair"..hair.."c"].Transparency = 0
				end
			else
				if (char:FindFirstChild("hair"..hair) ~= nil) then
					char["hair"..hair].Transparency = 1

					if (char:FindFirstChild("hair"..hair.."a") ~= nil) then
						char["hair"..hair.."a"].Transparency = 1
					end

					if (char:FindFirstChild("hair"..hair.."b") ~= nil) then
						char["hair"..hair.."b"].Transparency = 1
					end

					if (char:FindFirstChild("hair"..hair.."c") ~= nil) then
						char["hair"..hair.."c"].Transparency = 1
					end
				end
				
			end
			

		else
			if (char:FindFirstChild("hair"..i) ~= nil) then
				char["hair"..i]:Destroy()	

				if (char:FindFirstChild("hair"..i.."a") ~= nil) then
					char["hair"..i.."a"]:Destroy()
				end

				if (char:FindFirstChild("hair"..i.."b") ~= nil) then
					char["hair"..i.."b"]:Destroy()
				end

				if (char:FindFirstChild("hair"..i.."c") ~= nil) then
					char["hair"..i.."c"]:Destroy()
				end
			end
			
		end		
	end

	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.GetHair(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	return profile.Data.Character.Hair
end

function functions.SetHairColor(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	local char = player.Character
	local hair = profile.Data.Character.Hair
	local hairHue = profile.Data.Character.HairHue
	local hairSaturation = profile.Data.Character.HairSaturation
	local hairValue = profile.Data.Character.HairValue
	
	if (char:FindFirstChild("hair"..hair.."a") ~= nil) then
		char["hair"..hair.."a"].Color = Color3.fromHSV(hairHue, hairSaturation, hairValue);
	end
	
	char["hair"..hair].Color = Color3.fromHSV(hairHue, hairSaturation, hairValue);
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.SetSkinColor(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end

	local char = player.Character
	local outfit = profile.Data.Character.Outfit
	local skinHue = profile.Data.Character.SkinHue
	local skinSaturation = profile.Data.Character.SkinSaturation
	local skinValue = profile.Data.Character.SkinValue
	
	--char["neck"].Color = Color3.fromHSV(skinHue, skinSaturation, skinValue);
	char["face"].Color = Color3.fromHSV(skinHue, skinSaturation, skinValue);
	--char["scalp"].Color = Color3.fromHSV(skinHue, skinSaturation, skinValue);
	--char["skull"].Color = Color3.fromHSV(skinHue, skinSaturation, skinValue);
	--char["kid"..outfit.."b"].Color = Color3.fromHSV(skinHue, skinSaturation, skinValue);
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.SetAccessoryColor(player)
	
	local profile = Data[player]
	if (profile == nil) then return nil end
	
	local char = player.Character
	local hair = profile.Data.Character.Hair
	local accessoryHue = profile.Data.Character.AccessoryHue
	local accessorySaturation = profile.Data.Character.AccessorySaturation
	local accessoryValue = profile.Data.Character.AccessoryValue
	
	if (char:FindFirstChild("hair"..hair.."b") ~= nil) then
		char["hair"..hair.."b"].Color = Color3.fromHSV(accessoryHue, accessorySaturation, accessoryValue);
	end
	
	CharacterChangedEvent:FireClient(player,profile.Data.Character)
end

function functions.IsNewCharacter(player)
	local profile = Data[player]
	if (profile == nil) then
		return true 
	end
	
	--If we load data and this profile never had character set 
	if (profile.Data.Character["Gender"] == "") then
		return true
	end
	
	return false
	
end


function functions.SetupNewCharacter(player)
	local profile = Data[player]
	if (profile == nil) then return nil end

	local joinData = player:GetJoinData()
	

	if ((joinData.TeleportData ~= nil) and (joinData.TeleportData["gender"] ~= nil)) then
		
		--Logger.Debug("Setting up new Player for:"..player.Name)
		
		--Reset the player data to the template
		profile.Data = ProfileTemplate
		
		profile.Data.Character = {}
		profile.Data.Character["Gender"]=joinData.TeleportData["gender"]
		profile.Data.Character["Outfit"]=joinData.TeleportData["outfit"]
		profile.Data.Character["Face"]=joinData.TeleportData["face"]
		profile.Data.Character["Hair"]=joinData.TeleportData["hair"]
		profile.Data.Character["HairHue"]=joinData.TeleportData["hairHue"]
		profile.Data.Character["HairSaturation"]=joinData.TeleportData["hairSaturation"]
		profile.Data.Character["HairValue"]=joinData.TeleportData["hairValue"]
		profile.Data.Character["SkinHue"]=joinData.TeleportData["skinHue"]
		profile.Data.Character["SkinSaturation"]=joinData.TeleportData["skinSaturation"]
		profile.Data.Character["SkinValue"]=joinData.TeleportData["skinValue"]
		profile.Data.Character["AccessoryHue"]=joinData.TeleportData["accessoryHue"]
		profile.Data.Character["AccessorySaturation"]=joinData.TeleportData["accessorySaturation"]
		profile.Data.Character["AccessoryValue"]=joinData.TeleportData["accessoryValue"]
		profile.Data.Character["Class"]=joinData.TeleportData["class"]
		
		--Logger.Debug("TELEPORT DATA IN SetupNewCharacter Class:"..profile.Data.Character["Class"])
		--Logger.Debug("TELEPORT DATA IN SetupNewCharacter Class:"..joinData.TeleportData["class"])
		
		CharacterChangedEvent:FireClient(player,profile.Data.Character)
		
		--Give class specific benefits to attributes
		--if (profile.Data.Character["Class"] == "The Artsy") then
		--	AttributeFunctions.SetWisdom(player,3)
		--elseif (profile.Data.Character["Class"] == "The Jocks") then
		--	AttributeFunctions.SetStrength(player,3)
		--elseif (profile.Data.Character["Class"] == "The Nerds") then
		--	AttributeFunctions.SetIntelligence(player,3)
		--elseif (profile.Data.Character["Class"] == "The Rebels") then
		--	AttributeFunctions.SetPerception(player,3)
		--elseif (profile.Data.Character["Class"] == "The Popular") then
		--	AttributeFunctions.SetCharisma(player,3)
		--end
	end
end


function functions.UpdateCharacter(player,characterInfo)
	
	local profile = Data[player]
	if (profile == nil) then return nil end

	local joinData = player:GetJoinData()

	if (characterInfo[player.Name] and characterInfo[player.Name]["gender"])
	then

		profile.Data.Character = characterInfo
		
		if ((joinData.TeleportData ~= nil) and (joinData.TeleportData["gender"] ~= nil)) then

			profile.Data.Character = {}
			profile.Data.Character["Gender"]=joinData.TeleportData["gender"]
			profile.Data.Character["Outfit"]=joinData.TeleportData["outfit"]
			profile.Data.Character["Face"]=joinData.TeleportData["face"]
			profile.Data.Character["Hair"]=joinData.TeleportData["hair"]
			profile.Data.Character["HairHue"]=joinData.TeleportData["hairHue"]
			profile.Data.Character["HairSaturation"]=joinData.TeleportData["hairSaturation"]
			profile.Data.Character["HairValue"]=joinData.TeleportData["hairValue"]
			profile.Data.Character["SkinHue"]=joinData.TeleportData["skinHue"]
			profile.Data.Character["SkinSaturation"]=joinData.TeleportData["skinSaturation"]
			profile.Data.Character["SkinValue"]=joinData.TeleportData["skinValue"]
			profile.Data.Character["AccessoryHue"]=joinData.TeleportData["accessoryHue"]
			profile.Data.Character["AccessorySaturation"]=joinData.TeleportData["accessorySaturation"]
			profile.Data.Character["AccessoryValue"]=joinData.TeleportData["accessoryValue"]
			profile.Data.Character["Class"]=joinData.TeleportData["class"]
			
			CharacterChangedEvent:FireClient(player,profile.Data.Character)
		end

	else

		--Set character according to characterInfo
		if ((joinData.TeleportData ~= nil) and (joinData.TeleportData["gender"] ~= nil)) then

			profile.Data.Character = {}
			profile.Data.Character["Gender"]=joinData.TeleportData["gender"]
			profile.Data.Character["Outfit"]=joinData.TeleportData["outfit"]
			profile.Data.Character["Face"]=joinData.TeleportData["face"]
			profile.Data.Character["Hair"]=joinData.TeleportData["hair"]
			profile.Data.Character["HairHue"]=joinData.TeleportData["hairHue"]
			profile.Data.Character["HairSaturation"]=joinData.TeleportData["hairSaturation"]
			profile.Data.Character["HairValue"]=joinData.TeleportData["hairValue"]
			profile.Data.Character["SkinHue"]=joinData.TeleportData["skinHue"]
			profile.Data.Character["SkinSaturation"]=joinData.TeleportData["skinSaturation"]
			profile.Data.Character["SkinValue"]=joinData.TeleportData["skinValue"]
			profile.Data.Character["AccessoryHue"]=joinData.TeleportData["accessoryHue"]
			profile.Data.Character["AccessorySaturation"]=joinData.TeleportData["accessorySaturation"]
			profile.Data.Character["AccessoryValue"]=joinData.TeleportData["accessoryValue"]
			profile.Data.Character["Class"]=joinData.TeleportData["class"]
			
			CharacterChangedEvent:FireClient(player,profile.Data.Character)

		else
			profile.Data.Character = CharacterInfoDef

			CharacterChangedEvent:FireClient(player,profile.Data.Character)

		end

	end
	
	
	
	--local characterStore = DataStore2("Character",player)
	--characterStore:Set(PlayerCharacterInfo)
end

function functions.SetCharacter(player)
	
	--functions.SetGender(player)
	--functions.SetOutfit(player)
	functions.SetFace(player)
	--functions.SetHair(player)
	--functions.SetHairColor(player)
	functions.SetSkinColor(player)
	--functions.SetAccessoryColor(player)
	
end

function functions.GetClass(player)
	local profile = Data[player]
	if (profile == nil) then
		return "" 
	else
		return profile.Data.Character.Class
	end
end

return functions