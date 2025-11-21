--[[
	DungeonInstanceManager.lua
	Manages per-player dungeon instances for single-player experience
	Each player gets their own private dungeon floors

	Handles:
	- Creating player-specific dungeon folders
	- Tracking active instances
	- Cleaning up instances on player leave
	- Teleporting players within their instances
	- Managing floor progression per player
]]

local DungeonInstanceManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DungeonGenerator = require(ReplicatedStorage.Modules.DungeonGenerator)
local MazeDungeonGenerator = require(ReplicatedStorage.Modules.MazeDungeonGenerator)
local EnemySpawner = require(ReplicatedStorage.Modules.EnemySpawner)

-- Store active player instances
local PlayerInstances = {}

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
		Seed = tick() + player.UserId -- Unique seed per player
	}

	print("[DungeonInstanceManager] Instance created:", instanceFolder.Name)

	return instanceFolder
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

	local instance = PlayerInstances[player.UserId]

	if not instance then
		warn("[DungeonInstanceManager] ⚠ No instance found for", player.Name, "- Auto-creating instance...")
		DungeonInstanceManager.CreatePlayerInstance(player)
		instance = PlayerInstances[player.UserId]

		if not instance then
			warn("[DungeonInstanceManager] ✗ Failed to create instance for", player.Name)
			return nil, nil
		end
		print("[DungeonInstanceManager] ✓ Instance auto-created successfully")
	else
		print("[DungeonInstanceManager] ✓ Instance found for player")
	end

	-- Check cache first
	if instance.FloorCache[floorNumber] and instance.FloorModels[floorNumber] then
		print("[DungeonInstanceManager] ✓ Using cached floor", floorNumber, "for", player.Name)
		return instance.FloorCache[floorNumber], instance.FloorModels[floorNumber]
	end

	-- Generate new floor
	print("[DungeonInstanceManager] 🔍 Generating NEW floor", floorNumber, "for", player.Name)

	local floorSeed = instance.Seed + floorNumber
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
	local floorOffset = Vector3.new(0, -1000 * floorNumber, 0)
	print("[DungeonInstanceManager] Moving dungeon to offset:", floorOffset)
	print("[DungeonInstanceManager] Dungeon current pivot:", dungeonModel:GetPivot().Position)

	-- Use PivotTo for reliable model positioning (MoveTo doesn't work well with complex models)
	-- Get the current pivot, then ADD the floor offset to move it down
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

	-- Spawn enemies in the dungeon
	print("[DungeonInstanceManager] 🔍 Spawning enemies for floor", floorNumber)
	local enemies, enemyCount = EnemySpawner.SpawnEnemiesInDungeon(dungeonModel, floorNumber, player)
	print("[DungeonInstanceManager] ✓ Spawned", enemyCount, "enemies")

	-- Store dungeon model reference in floor data
	floorData.DungeonModel = dungeonModel
	floorData.Enemies = enemies
	floorData.Seed = floorSeed

	-- Cache the floor
	instance.FloorCache[floorNumber] = floorData
	instance.FloorModels[floorNumber] = dungeonModel
	instance.CurrentFloor = floorNumber

	print(string.format("[DungeonInstanceManager] ✓ Floor %d ready for %s (%d enemies spawned)",
		floorNumber, player.Name, enemyCount))

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

	-- Get player's instance folder
	local instance = PlayerInstances[player.UserId]
	if not instance then
		warn("[DungeonInstanceManager] ✗ No instance found for", player.Name, "- Did CreatePlayerInstance() get called?")
		return false
	end
	print("[DungeonInstanceManager] ✓ Instance found:", instance.Folder.Name)

	-- Find the player spawn point in the generated dungeon
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	local playerSpawn = spawnsFolder and spawnsFolder:FindFirstChild("PlayerSpawn")

	print(string.format("[DungeonInstanceManager] 🔍 Spawn search: spawnsFolder=%s, playerSpawn=%s",
		tostring(spawnsFolder ~= nil), tostring(playerSpawn ~= nil)))

	if not playerSpawn then
		warn("[DungeonInstanceManager] ⚠ No PlayerSpawn found in dungeon floor", floorNumber, "- using fallback position")
		-- Fallback to dungeon center
		local floorOffset = Vector3.new(0, -1000 * floorNumber, 0)
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
	Gets a player's dungeon instance folder
	@param player - The Player object
	@return instanceFolder or nil
]]
function DungeonInstanceManager.GetPlayerInstance(player)
	local instance = PlayerInstances[player.UserId]
	return instance and instance.Folder
end

--[[
	Checks if a player has an active instance
	@param player - The Player object
	@return boolean
]]
function DungeonInstanceManager.HasInstance(player)
	return PlayerInstances[player.UserId] ~= nil
end

--[[
	Clears a specific floor from cache (useful for regeneration)
	@param player - The Player object
	@param floorNumber - Floor to clear
]]
function DungeonInstanceManager.ClearFloorCache(player, floorNumber)
	local instance = PlayerInstances[player.UserId]
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
	Destroys a player's dungeon instance and cleans up
	@param player - The Player object
]]
function DungeonInstanceManager.DestroyPlayerInstance(player)
	local instance = PlayerInstances[player.UserId]

	if not instance then
		return
	end

	print("[DungeonInstanceManager] Destroying instance for", player.Name)

	-- Destroy the folder and all contents
	if instance.Folder then
		instance.Folder:Destroy()
	end

	-- Clear cache
	PlayerInstances[player.UserId] = nil

	print("[DungeonInstanceManager] Instance destroyed for", player.Name)
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

--[[
	Gets the current floor number for a player
	@param player - The Player object
	@return floorNumber or nil
]]
function DungeonInstanceManager.GetPlayerCurrentFloor(player)
	local instance = PlayerInstances[player.UserId]
	return instance and instance.CurrentFloor
end

--[[
	Gets statistics about active instances
	@return stats table
]]
function DungeonInstanceManager.GetInstanceStats()
	local count = 0
	local totalFloorsCached = 0

	for userId, instance in pairs(PlayerInstances) do
		count = count + 1

		-- Count cached floors
		for _ in pairs(instance.FloorCache) do
			totalFloorsCached = totalFloorsCached + 1
		end
	end

	return {
		ActiveInstances = count,
		TotalFloorsCached = totalFloorsCached,
		AverageFloorsPerInstance = count > 0 and (totalFloorsCached / count) or 0
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
	print("Total Floors Cached:", stats.TotalFloorsCached)
	print("Average Floors/Instance:", string.format("%.2f", stats.AverageFloorsPerInstance))

	print("\nPlayer Instances:")
	for userId, instance in pairs(PlayerInstances) do
		print(string.format(
			"  - %s (UserId: %d) - Current Floor: %s - Cached Floors: %d",
			instance.Player.Name,
			userId,
			tostring(instance.CurrentFloor or "None"),
			#instance.FloorCache
		))
	end

	print(string.rep("=", 60) .. "\n")
end

-- ============================================================
-- MODULE RETURN
-- ============================================================

return DungeonInstanceManager
