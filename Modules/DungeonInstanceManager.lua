--[[
════════════════════════════════════════════════════════════════════════════════
Module: DungeonInstanceManager
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Dungeon instance manager for solo and party (up to 4 players) play.
             Creates private dungeon folders at X = Floor × 10000.
             Handles instance cleanup, floor progression, teleportation.
             Integrates with PartyManager for co-op instances.
Version: 2.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local DungeonInstanceManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DungeonGenerator = require(ReplicatedStorage.Modules.DungeonGenerator)
local MazeDungeonGenerator = require(ReplicatedStorage.Modules.MazeDungeonGenerator)
local EnemySpawner = require(ReplicatedStorage.Modules.EnemySpawner)
local PartyManager = require(ReplicatedStorage.Modules.PartyManager)
local DifficultyScaler = require(ReplicatedStorage.Modules.DifficultyScaler)
local ThemeApplier = require(ReplicatedStorage.Modules.ThemeApplier)
local PortalSystem = require(ReplicatedStorage.Modules.PortalSystem)
local DungeonValidator = require(ReplicatedStorage.Modules.DungeonValidator)

-- Store active instances
local PlayerInstances = {} -- [UserId] = instance data (solo play)
local PartyInstances = {} -- [PartyID] = instance data (party play)

-- Configuration
local INSTANCE_FOLDER_NAME = "DungeonInstances"
local SPAWN_OFFSET = Vector3.new(0, 3, 0) -- Offset above spawn point

-- ============================================================
-- INITIALIZATION
-- ============================================================

-- Create main dungeon instances folder in workspace
local function GetInstancesFolder()
	local folder = workspace:FindFirstChild(INSTANCE_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = INSTANCE_FOLDER_NAME
		folder.Parent = workspace
		print("[DungeonInstanceManager] Created DungeonInstances folder in workspace")
	end
	return folder
end

-- ============================================================
-- INSTANCE RETRIEVAL HELPERS
-- ============================================================

--[[
	Gets the appropriate instance for a player (party or solo)
	@param player - The Player object
	@return instance data, isParty
]]
local function GetPlayerInstanceData(player)
	-- Check if player is in a party
	if PartyManager:IsInParty(player) then
		local partyID = PartyManager:GetPartyID(player)
		if partyID and PartyInstances[partyID] then
			return PartyInstances[partyID], true
		end
	end

	-- Fall back to solo instance
	if PlayerInstances[player.UserId] then
		return PlayerInstances[player.UserId], false
	end

	return nil, false
end

--[[
	Gets or creates the appropriate instance for a player
	@param player - The Player object
	@return instanceFolder, isParty
]]
local function GetOrCreateInstance(player)
	-- Check if player is in a party
	if PartyManager:IsInParty(player) then
		local partyID = PartyManager:GetPartyID(player)
		if partyID then
			-- Check if party instance exists
			if PartyInstances[partyID] then
				return PartyInstances[partyID], true
			end
			-- Create party instance
			return DungeonInstanceManager.CreatePartyInstance(partyID), true
		end
	end

	-- Solo play - check if instance exists
	if PlayerInstances[player.UserId] then
		return PlayerInstances[player.UserId], false
	end

	-- Create solo instance
	return DungeonInstanceManager.CreatePlayerInstance(player), false
end

-- ============================================================
-- INSTANCE CREATION
-- ============================================================

--[[
	Creates a new dungeon instance for a player
	@param player - The Player object
	@return instanceFolder - The folder containing this player's dungeon
]]
function DungeonInstanceManager.CreatePlayerInstance(player)
	-- Check if instance already exists
	if PlayerInstances[player.UserId] then
		warn("[DungeonInstanceManager] Instance already exists for", player.Name)
		return PlayerInstances[player.UserId].Folder
	end

	print("[DungeonInstanceManager] Creating dungeon instance for", player.Name)

	-- Create player's dungeon folder
	local instanceFolder = Instance.new("Folder")
	instanceFolder.Name = "DungeonInstance_" .. player.UserId
	instanceFolder.Parent = GetInstancesFolder()

	-- Store instance data
	PlayerInstances[player.UserId] = {
		Folder = instanceFolder,
		Player = player,
		CurrentFloor = nil, -- Will be generated on demand
		FloorCache = {}, -- Cache generated floors (data)
		FloorModels = {}, -- Cache generated floor 3D models
		Seed = math.random(1, 1000000) -- Unique seed per player
	}

	print("[DungeonInstanceManager] Instance created:", instanceFolder.Name)

	return PlayerInstances[player.UserId]
end

--[[
	Creates a new dungeon instance for a party
	@param partyID - The party ID
	@return instanceData - The party instance data
]]
function DungeonInstanceManager.CreatePartyInstance(partyID)
	-- Check if instance already exists
	if PartyInstances[partyID] then
		warn("[DungeonInstanceManager] Party instance already exists for", partyID)
		return PartyInstances[partyID]
	end

	print("[DungeonInstanceManager] Creating party dungeon instance for", partyID)

	-- Create party's dungeon folder
	local instanceFolder = Instance.new("Folder")
	instanceFolder.Name = "PartyInstance_" .. partyID
	instanceFolder.Parent = GetInstancesFolder()

	-- Store instance data
	PartyInstances[partyID] = {
		Folder = instanceFolder,
		PartyID = partyID,
		CurrentFloor = nil,
		FloorCache = {},
		FloorModels = {},
		Seed = math.random(1, 1000000) -- Unique seed per party
	}

	print("[DungeonInstanceManager] Party instance created:", instanceFolder.Name)

	return PartyInstances[partyID]
end

-- ============================================================
-- FLOOR GENERATION
-- ============================================================

--[[
	Generates or retrieves a floor for a player's instance
	@param player - The Player object
	@param floorNumber - Floor number to generate
	@return floorData, floorModel - Generated floor data and 3D model
]]
function DungeonInstanceManager.GetOrGenerateFloor(player, floorNumber)
	print(string.format("[DungeonInstanceManager] 🔍 GetOrGenerateFloor called for %s, floor %d", player.Name, floorNumber))

	-- Get or create the appropriate instance (party or solo)
	local instance, isParty = GetOrCreateInstance(player)

	if not instance then
		warn("[DungeonInstanceManager] ✗ Failed to get or create instance for", player.Name)
		return nil, nil
	end

	if isParty then
		print("[DungeonInstanceManager] ✓ Using party instance")
	else
		print("[DungeonInstanceManager] ✓ Using solo instance")
	end

	-- Check cache first
	if instance.FloorCache[floorNumber] and instance.FloorModels[floorNumber] then
		print("[DungeonInstanceManager] ✓ Using cached floor", floorNumber, "for", player.Name)
		return instance.FloorCache[floorNumber], instance.FloorModels[floorNumber]
	end

	-- Generate new floor
	print("[DungeonInstanceManager] 🔍 Generating NEW floor", floorNumber, "for", player.Name)

	-- Enhanced seed calculation for better randomization
	local floorSeed = instance.Seed * 7919 + floorNumber * 104729 + math.random(1, 10000)
	print("[DungeonInstanceManager] Floor seed:", floorSeed)

	local floorData = DungeonGenerator.GenerateFloor(floorNumber, floorSeed)
	print("[DungeonInstanceManager] ✓ DungeonGenerator.GenerateFloor completed")

	-- Build 3D dungeon geometry using MazeDungeonGenerator
	print("[DungeonInstanceManager] 🔍 Building 3D geometry for floor", floorNumber)
	local dungeonModel = MazeDungeonGenerator.Generate(floorSeed, instance.Folder)

	if not dungeonModel then
		warn("[DungeonInstanceManager] ✗ Failed to build dungeon geometry for floor", floorNumber)
		return floorData, nil
	end
	print("[DungeonInstanceManager] ✓ Dungeon model created:", dungeonModel.Name)

	-- Position the dungeon at the correct offset for this floor
	-- Use horizontal spacing instead of vertical (Y) to avoid Roblox's kill plane at Y = -500
	-- Each floor is offset 10,000 studs to the side to prevent overlap
	local floorOffset = Vector3.new(floorNumber * 10000, 0, 0)
	print("[DungeonInstanceManager] Moving dungeon to offset:", floorOffset)
	print("[DungeonInstanceManager] Dungeon current pivot:", dungeonModel:GetPivot().Position)

	-- Use PivotTo for reliable model positioning (MoveTo doesn't work well with complex models)
	-- Get the current pivot, then ADD the floor offset to move it horizontally
	local currentPivot = dungeonModel:GetPivot()
	local newPosition = currentPivot.Position + floorOffset
	local targetPivot = CFrame.new(newPosition) * (currentPivot - currentPivot.Position)
	dungeonModel:PivotTo(targetPivot)

	print("[DungeonInstanceManager] ✓ Dungeon positioned at:", newPosition)

	-- Verify spawn markers moved correctly
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	if spawnsFolder then
		local playerSpawn = spawnsFolder:FindFirstChild("PlayerSpawn")
		if playerSpawn then
			print("[DungeonInstanceManager] PlayerSpawn after move:", playerSpawn.Position)
		end
		local firstEnemySpawn = spawnsFolder:FindFirstChildOfClass("Part")
		if firstEnemySpawn and firstEnemySpawn:GetAttribute("SpawnType") == "Enemy" then
			print("[DungeonInstanceManager] First enemy spawn after move:", firstEnemySpawn.Position)
		end
	end

	-- Apply visual theme to dungeon
	print("[DungeonInstanceManager] 🔍 Applying visual theme for floor", floorNumber)
	ThemeApplier:ApplyTheme(dungeonModel, floorNumber)
	print("[DungeonInstanceManager] ✓ Theme applied")

	-- Validate dungeon connectivity
	print("[DungeonInstanceManager] 🔍 Validating dungeon connectivity...")
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	local playerSpawn = spawnsFolder and spawnsFolder:FindFirstChild("PlayerSpawn")
	local spawnPos = playerSpawn and playerSpawn.Position or dungeonModel:GetPivot().Position

	local isValid, validationData = DungeonValidator:ValidateAndMark(dungeonModel, spawnPos)
	if not isValid then
		warn("[DungeonInstanceManager] ⚠ Dungeon failed validation:", validationData.Reason)
		DungeonValidator:PrintReport(validationData)
		-- Continue anyway but log the issue
	else
		print("[DungeonInstanceManager] ✓ Dungeon validated successfully")
	end

	-- Spawn enemies in the dungeon with difficulty scaling
	print("[DungeonInstanceManager] 🔍 Spawning enemies for floor", floorNumber)
	local enemies, enemyCount = EnemySpawner.SpawnEnemiesInDungeon(dungeonModel, floorNumber, player)

	-- Apply difficulty scaling to all spawned enemies
	local difficulty = DifficultyScaler:GetFloorDifficulty(floorNumber)
	for _, enemy in ipairs(enemies) do
		if enemy and enemy:FindFirstChild("Humanoid") then
			local isBoss = difficulty.IsBossFloor and validationData and validationData.BossRoom
				and (enemy.PrimaryPart.Position - validationData.BossRoom.Position).Magnitude < 50
			DifficultyScaler:ApplyEnemyScaling(enemy:FindFirstChild("Humanoid"), floorNumber, isBoss)
		end
	end
	print("[DungeonInstanceManager] ✓ Spawned and scaled", enemyCount, "enemies")

	-- Create entrance and exit portals
	print("[DungeonInstanceManager] 🔍 Creating floor transition portals...")
	local spawnCFrame = playerSpawn and playerSpawn.CFrame or CFrame.new(spawnPos)
	local entrancePortal, exitPortal = PortalSystem:CreateFloorPortals(dungeonModel, floorNumber, spawnCFrame)
	print(string.format("[DungeonInstanceManager] ✓ Created portals (Entrance: %s, Exit: %s)",
		tostring(entrancePortal ~= nil), tostring(exitPortal ~= nil)))

	-- Store dungeon model reference in floor data
	floorData.DungeonModel = dungeonModel
	floorData.Enemies = enemies
	floorData.Seed = floorSeed
	floorData.Difficulty = difficulty
	floorData.ValidationData = validationData
	floorData.EntrancePortal = entrancePortal
	floorData.ExitPortal = exitPortal

	-- Cache the floor
	instance.FloorCache[floorNumber] = floorData
	instance.FloorModels[floorNumber] = dungeonModel
	instance.CurrentFloor = floorNumber

	print(string.format("[DungeonInstanceManager] ✓ Floor %d ready for %s (%d enemies, Theme: %s)",
		floorNumber, player.Name, enemyCount, difficulty.Theme.Name))

	return floorData, dungeonModel
end

-- ============================================================
-- PLAYER TELEPORTATION
-- ============================================================

--[[
	Teleports player to a specific floor in their dungeon instance
	@param player - The Player object
	@param floorNumber - Floor to teleport to
	@return success - Whether teleport was successful
]]
function DungeonInstanceManager.TeleportToFloor(player, floorNumber)
	print(string.format("[DungeonInstanceManager] 🔍 DEBUG: TeleportToFloor called for %s to floor %d", player.Name, floorNumber))

	local character = player.Character
	if not character then
		warn("[DungeonInstanceManager] ✗ Character not found for", player.Name)
		return false
	end
	print("[DungeonInstanceManager] ✓ Character found")

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("[DungeonInstanceManager] ✗ HumanoidRootPart not found for", player.Name)
		return false
	end
	print("[DungeonInstanceManager] ✓ HumanoidRootPart found at position:", humanoidRootPart.Position)

	-- Floor 0 = Church (shared, not instanced)
	if floorNumber == 0 then
		local churchSpawn = workspace:FindFirstChild("ChurchSpawn")
		if churchSpawn then
			humanoidRootPart.CFrame = churchSpawn.CFrame + SPAWN_OFFSET
			print("[DungeonInstanceManager] Teleported", player.Name, "to Church")
			return true
		else
			warn("[DungeonInstanceManager] ChurchSpawn not found")
			humanoidRootPart.CFrame = CFrame.new(0, 10, 0)
			return false
		end
	end

	print("[DungeonInstanceManager] 🔍 Calling GetOrGenerateFloor...")

	-- Get or generate the floor
	local floorData, dungeonModel = DungeonInstanceManager.GetOrGenerateFloor(player, floorNumber)

	print(string.format("[DungeonInstanceManager] 🔍 GetOrGenerateFloor returned: floorData=%s, dungeonModel=%s",
		tostring(floorData ~= nil), tostring(dungeonModel ~= nil)))

	if not floorData or not dungeonModel then
		warn("[DungeonInstanceManager] ✗ Failed to generate floor", floorNumber)
		return false
	end
	print("[DungeonInstanceManager] ✓ Floor generated successfully")

	-- Get player's instance (party or solo)
	local instance, isParty = GetPlayerInstanceData(player)
	if not instance then
		warn("[DungeonInstanceManager] ✗ No instance found for", player.Name)
		return false
	end
	print("[DungeonInstanceManager] ✓ Instance found:", instance.Folder.Name, "(Party:", isParty, ")")

	-- Find the player spawn point in the generated dungeon
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	local playerSpawn = spawnsFolder and spawnsFolder:FindFirstChild("PlayerSpawn")

	print(string.format("[DungeonInstanceManager] 🔍 Spawn search: spawnsFolder=%s, playerSpawn=%s",
		tostring(spawnsFolder ~= nil), tostring(playerSpawn ~= nil)))

	if not playerSpawn then
		warn("[DungeonInstanceManager] ⚠ No PlayerSpawn found in dungeon floor", floorNumber, "- using fallback position")
		-- Fallback to dungeon center (using horizontal offset to avoid kill plane)
		local floorOffset = Vector3.new(floorNumber * 10000, 0, 0)
		local targetPos = floorOffset + SPAWN_OFFSET
		print("[DungeonInstanceManager] Teleporting to fallback position:", targetPos)
		humanoidRootPart.CFrame = CFrame.new(targetPos)
		print("[DungeonInstanceManager] Player new position:", humanoidRootPart.Position)
	else
		-- Teleport to actual spawn point
		local targetPos = playerSpawn.CFrame.Position + SPAWN_OFFSET
		print("[DungeonInstanceManager] Teleporting to PlayerSpawn:", targetPos)
		humanoidRootPart.CFrame = playerSpawn.CFrame + SPAWN_OFFSET
		print("[DungeonInstanceManager] Player new position:", humanoidRootPart.Position)
	end

	print(string.format(
		"[DungeonInstanceManager] ✓ Teleported %s to Floor %d (Instance: %s)",
		player.Name,
		floorNumber,
		instance.Folder.Name
	))

	return true
end

-- ============================================================
-- INSTANCE MANAGEMENT
-- ============================================================

--[[
	Gets a player's dungeon instance folder (party or solo)
	@param player - The Player object
	@return instanceFolder or nil
]]
function DungeonInstanceManager.GetPlayerInstance(player)
	local instance, isParty = GetPlayerInstanceData(player)
	return instance and instance.Folder
end

--[[
	Checks if a player has an active instance (party or solo)
	@param player - The Player object
	@return boolean
]]
function DungeonInstanceManager.HasInstance(player)
	local instance = GetPlayerInstanceData(player)
	return instance ~= nil
end

--[[
	Clears a specific floor from cache (useful for regeneration)
	@param player - The Player object
	@param floorNumber - Floor to clear
]]
function DungeonInstanceManager.ClearFloorCache(player, floorNumber)
	local instance = GetPlayerInstanceData(player)
	if not instance then return end

	-- Destroy 3D model if it exists
	if instance.FloorModels[floorNumber] then
		instance.FloorModels[floorNumber]:Destroy()
		instance.FloorModels[floorNumber] = nil
	end

	-- Clear data cache
	if instance.FloorCache[floorNumber] then
		instance.FloorCache[floorNumber] = nil
	end

	print("[DungeonInstanceManager] Cleared floor cache", floorNumber, "for", player.Name)
end

--[[
	Destroys a player's solo dungeon instance and cleans up
	@param player - The Player object
]]
function DungeonInstanceManager.DestroyPlayerInstance(player)
	local instance = PlayerInstances[player.UserId]

	if not instance then
		return
	end

	print("[DungeonInstanceManager] Destroying solo instance for", player.Name)

	-- Destroy the folder and all contents
	if instance.Folder then
		instance.Folder:Destroy()
	end

	-- Clear cache
	PlayerInstances[player.UserId] = nil

	print("[DungeonInstanceManager] Solo instance destroyed for", player.Name)
end

--[[
	Destroys a party's dungeon instance and cleans up
	@param partyID - The party ID
]]
function DungeonInstanceManager.DestroyPartyInstance(partyID)
	local instance = PartyInstances[partyID]

	if not instance then
		return
	end

	print("[DungeonInstanceManager] Destroying party instance", partyID)

	-- Destroy the folder and all contents
	if instance.Folder then
		instance.Folder:Destroy()
	end

	-- Clear cache
	PartyInstances[partyID] = nil

	print("[DungeonInstanceManager] Party instance destroyed", partyID)
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

--[[
	Gets the current floor number for a player (party or solo)
	@param player - The Player object
	@return floorNumber or nil
]]
function DungeonInstanceManager.GetPlayerCurrentFloor(player)
	local instance = GetPlayerInstanceData(player)
	return instance and instance.CurrentFloor
end

--[[
	Gets statistics about active instances
	@return stats table
]]
function DungeonInstanceManager.GetInstanceStats()
	local soloCount = 0
	local partyCount = 0
	local totalFloorsCached = 0

	-- Count solo instances
	for userId, instance in pairs(PlayerInstances) do
		soloCount = soloCount + 1

		-- Count cached floors
		for _ in pairs(instance.FloorCache) do
			totalFloorsCached = totalFloorsCached + 1
		end
	end

	-- Count party instances
	for partyID, instance in pairs(PartyInstances) do
		partyCount = partyCount + 1

		-- Count cached floors
		for _ in pairs(instance.FloorCache) do
			totalFloorsCached = totalFloorsCached + 1
		end
	end

	local totalInstances = soloCount + partyCount

	return {
		ActiveInstances = totalInstances,
		SoloInstances = soloCount,
		PartyInstances = partyCount,
		TotalFloorsCached = totalFloorsCached,
		AverageFloorsPerInstance = totalInstances > 0 and (totalFloorsCached / totalInstances) or 0
	}
end

-- ============================================================
-- DEBUG
-- ============================================================

function DungeonInstanceManager.PrintDebugInfo()
	print("\n" .. string.rep("=", 60))
	print("DUNGEON INSTANCE MANAGER - DEBUG INFO")
	print(string.rep("=", 60))

	local stats = DungeonInstanceManager.GetInstanceStats()
	print("Active Instances:", stats.ActiveInstances)
	print("  - Solo Instances:", stats.SoloInstances)
	print("  - Party Instances:", stats.PartyInstances)
	print("Total Floors Cached:", stats.TotalFloorsCached)
	print("Average Floors/Instance:", string.format("%.2f", stats.AverageFloorsPerInstance))

	print("\nSolo Player Instances:")
	for userId, instance in pairs(PlayerInstances) do
		local cachedFloors = 0
		for _ in pairs(instance.FloorCache) do
			cachedFloors = cachedFloors + 1
		end
		print(string.format(
			"  - %s (UserId: %d) - Current Floor: %s - Cached Floors: %d",
			instance.Player.Name,
			userId,
			tostring(instance.CurrentFloor or "None"),
			cachedFloors
		))
	end

	print("\nParty Instances:")
	for partyID, instance in pairs(PartyInstances) do
		local cachedFloors = 0
		for _ in pairs(instance.FloorCache) do
			cachedFloors = cachedFloors + 1
		end
		print(string.format(
			"  - %s - Current Floor: %s - Cached Floors: %d",
			partyID,
			tostring(instance.CurrentFloor or "None"),
			cachedFloors
		))
	end

	print(string.rep("=", 60) .. "\n")
end

-- ============================================================
-- MODULE RETURN
-- ============================================================

return DungeonInstanceManager
