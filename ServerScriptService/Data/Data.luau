
----- Loaded Modules -----

local ProfileService = require(game.ServerScriptService:WaitForChild("SharedServices").ProfileService)
local ProfileTemplate = require(game.ServerScriptService:WaitForChild("Data"):WaitForChild("Templates").ProfileTemplate)
local ProfileLoadedEvent = game.ServerStorage:WaitForChild("SharedServerEvents"):WaitForChild("ProfileLoaded")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerLoadedEvent = ReplicatedStorage:WaitForChild("SharedRemotes"):WaitForChild("ServerLoaded")

local DataStoreService = game:GetService("DataStoreService")

----- Private Variables -----

local Players = game:GetService("Players")

---- Set your specific date here
--local specificMonth = 6 -- June
--local specificDay = 15 -- 15th
--local specificYear = 2024 -- Year 2024

---- Function to generate keys for all dates up to the specific date in the format PlayerDataMMDDYYYY(A-Z)
--local function generateDateKeys()
--	local keys = {}
--	for month = 1, specificMonth do
--		for day = 1, (month == specificMonth and specificDay or 31) do
--			local dateStr = string.format("%02d%02d%d", month, day, specificYear)
--			for charCode = 65, 90 do -- ASCII codes for A-Z
--				local key = "PlayerData" .. dateStr .. string.char(charCode)
--				table.insert(keys, key)
--			end
--		end
--	end
--	return keys
--end

--local function cleanupDataStores()
--	local keys = generateDateKeys()
	
--	for _, key in pairs(keys) do
--		local ProfileStore = ProfileService.GetProfileStore(
--			key,
--			ProfileTemplate
--		)

--		local success = ProfileStore:WipeProfileAsync(key)

--		wait(.1)
		
--		--local success, err = pcall(function()
--		--	dataStore:RemoveAsync(key)
--		--end)
--		--if success then
--		--	Logger.Debug("Successfully deleted key:", key)
--		--else
--		--	warn("Failed to delete key:", key, err)
--		--end
--	end
--end

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerDataWarped041326M",
	ProfileTemplate
)

--Logger.Debug("TEST DS ACTUAL ONE:",ProfileStore)



----Clean all previous datastores based on pattern
--cleanupDataStores()



local CachedProfiles = {} -- [player] = profile

local function NormalizeInventorySlots(profile)
	for _, item in pairs(profile.Data.Inventory.Items) do
		item.Slot = tonumber(item.Slot)
	end
end

local function DataCleanup(profile)
	NormalizeInventorySlots(profile)
end

local function PlayerAdded(player)
	
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			CachedProfiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			CachedProfiles[player] = profile
			-- A profile has been successfully loaded:
			
			local character = player.Character or player.CharacterAdded:Wait()		
			
			--Logger.Debug("PROFILE LOADED FIRED")
			
			DataCleanup(profile)
			
			ProfileLoadedEvent:Fire(player)

			ServerLoadedEvent:FireClient(player)
			
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick() 
	end
end

----- Initialize -----

-- In case Players have joined the server earlier than this script ran:
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

----- Connections -----

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = CachedProfiles[player]
	if profile ~= nil then
		profile:Release()
	end
end)

return CachedProfiles