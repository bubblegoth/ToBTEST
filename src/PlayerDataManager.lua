--[[
	PlayerDataManager.lua
	Manages player data initialization, persistence, and tracking
	Place this in ServerScriptService

	Handles:
	- Player data initialization when they join
	- Storing PlayerStats in player object
	- DataStore save/load (optional)
	- Death handling integration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references
local PlayerStats = require(ReplicatedStorage.src.PlayerStats)
local DeathHandler = require(ReplicatedStorage.src.DeathHandler)

print("[PlayerDataManager] Loading...")

-- Store active player data
local PlayerDataCache = {}

-- ============================================================
-- PLAYER JOINED
-- ============================================================

Players.PlayerAdded:Connect(function(player)
	print("[PlayerDataManager] Player joined:", player.Name)

	-- Initialize PlayerStats
	local playerData = PlayerStats.new()

	-- Store in player object for easy access by other scripts
	-- We'll store it as a Folder with Values for compatibility
	local dataFolder = Instance.new("Folder")
	dataFolder.Name = "PlayerStats"
	dataFolder.Parent = player

	-- Create values for scripts that expect .Value properties
	local currentFloorValue = Instance.new("IntValue")
	currentFloorValue.Name = "CurrentFloor"
	currentFloorValue.Value = playerData:GetCurrentFloor()
	currentFloorValue.Parent = dataFolder

	local soulsValue = Instance.new("IntValue")
	soulsValue.Name = "Souls"
	soulsValue.Value = playerData:GetSouls()
	soulsValue.Parent = dataFolder

	-- Store the actual PlayerStats module in cache
	PlayerDataCache[player.UserId] = {
		Stats = playerData,
		Values = {
			CurrentFloor = currentFloorValue,
			Souls = soulsValue,
		}
	}

	-- TODO: Load from DataStore
	-- local success, savedData = pcall(function()
	--     return DataStore:GetAsync("Player_" .. player.UserId)
	-- end)
	-- if success and savedData then
	--     playerData:LoadSaveData(savedData)
	-- end

	print("[PlayerDataManager] Player data initialized for", player.Name)

	-- Spawn player at Church (Floor 0)
	player.CharacterAdded:Connect(function(character)
		wait(0.1) -- Let character load
		OnCharacterSpawned(player, character)
	end)
end)

-- ============================================================
-- CHARACTER SPAWNED
-- ============================================================

function OnCharacterSpawned(player, character)
	local playerData = GetPlayerData(player)
	if not playerData then return end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoidRootPart then return end

	-- Always spawn at Church (Floor 0)
	local churchSpawn = workspace:FindFirstChild("ChurchSpawn")
	if churchSpawn then
		humanoidRootPart.CFrame = churchSpawn.CFrame + Vector3.new(0, 3, 0)
		print("[PlayerDataManager] Spawned", player.Name, "at Church")
	else
		warn("[PlayerDataManager] ChurchSpawn not found in workspace!")
		humanoidRootPart.CFrame = CFrame.new(0, 10, 0)
	end

	-- Set up death detection
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			OnPlayerDeath(player)
		end)
	end
end

-- ============================================================
-- PLAYER DEATH
-- ============================================================

function OnPlayerDeath(player)
	local playerData = GetPlayerData(player)
	if not playerData then return end

	print("[PlayerDataManager] Player died:", player.Name)

	-- Process death using DeathHandler
	local deathResult = DeathHandler.OnPlayerDeath(playerData.Stats)

	if deathResult then
		print(deathResult.Message)

		-- Update values
		UpdatePlayerValues(player)

		-- TODO: Show death screen UI
		-- TODO: Auto-respawn after delay
	end
end

-- ============================================================
-- PLAYER LEAVING
-- ============================================================

Players.PlayerRemoving:Connect(function(player)
	print("[PlayerDataManager] Player leaving:", player.Name)

	local playerData = GetPlayerData(player)
	if not playerData then return end

	-- TODO: Save to DataStore
	-- local saveData = playerData.Stats:GetSaveData()
	-- local success, err = pcall(function()
	--     DataStore:SetAsync("Player_" .. player.UserId, saveData)
	-- end)
	-- if success then
	--     print("[PlayerDataManager] Saved data for", player.Name)
	-- else
	--     warn("[PlayerDataManager] Failed to save data for", player.Name, ":", err)
	-- end

	-- Clean up cache
	PlayerDataCache[player.UserId] = nil
end)

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function GetPlayerData(player)
	return PlayerDataCache[player.UserId]
end

function UpdatePlayerValues(player)
	local playerData = GetPlayerData(player)
	if not playerData then return end

	-- Sync the Values with the actual PlayerStats module
	playerData.Values.CurrentFloor.Value = playerData.Stats:GetCurrentFloor()
	playerData.Values.Souls.Value = playerData.Stats:GetSouls()
end

-- Export functions for other scripts
_G.GetPlayerStats = function(player)
	local data = GetPlayerData(player)
	return data and data.Stats
end

_G.UpdatePlayerValues = UpdatePlayerValues

print("[PlayerDataManager] Ready!")
