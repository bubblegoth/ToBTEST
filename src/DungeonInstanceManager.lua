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
local DungeonGenerator = require(ReplicatedStorage.src.DungeonGenerator)

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
		FloorCache = {}, -- Cache generated floors
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
	@return floorData - Generated floor data
]]
function DungeonInstanceManager.GetOrGenerateFloor(player, floorNumber)
	local instance = PlayerInstances[player.UserId]

	if not instance then
		warn("[DungeonInstanceManager] No instance found for", player.Name)
		return nil
	end

	-- Check cache first
	if instance.FloorCache[floorNumber] then
		print("[DungeonInstanceManager] Using cached floor", floorNumber, "for", player.Name)
		return instance.FloorCache[floorNumber]
	end

	-- Generate new floor
	print("[DungeonInstanceManager] Generating floor", floorNumber, "for", player.Name)

	local floorSeed = instance.Seed + floorNumber
	local floorData = DungeonGenerator.GenerateFloor(floorNumber, floorSeed)

	-- Cache the floor
	instance.FloorCache[floorNumber] = floorData
	instance.CurrentFloor = floorNumber

	return floorData
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
	local character = player.Character
	if not character then
		warn("[DungeonInstanceManager] Character not found for", player.Name)
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("[DungeonInstanceManager] HumanoidRootPart not found for", player.Name)
		return false
	end

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

	-- Get or generate the floor
	local floorData = DungeonInstanceManager.GetOrGenerateFloor(player, floorNumber)

	if not floorData then
		warn("[DungeonInstanceManager] Failed to generate floor", floorNumber)
		return false
	end

	-- Get player's instance folder
	local instance = PlayerInstances[player.UserId]
	if not instance then
		warn("[DungeonInstanceManager] No instance found for", player.Name)
		return false
	end

	-- Calculate spawn position in player's instance
	-- Each floor is offset vertically to prevent collision
	local floorOffset = Vector3.new(0, -1000 * floorNumber, 0)

	-- Use DungeonSpawn as base position
	local dungeonSpawn = workspace:FindFirstChild("DungeonSpawn")
	local basePosition = dungeonSpawn and dungeonSpawn.Position or Vector3.new(0, -1000, 0)

	local spawnPosition = basePosition + floorOffset + SPAWN_OFFSET

	-- Teleport player
	humanoidRootPart.CFrame = CFrame.new(spawnPosition)

	print(string.format(
		"[DungeonInstanceManager] Teleported %s to Floor %d (Instance: %s)",
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
	if instance and instance.FloorCache[floorNumber] then
		instance.FloorCache[floorNumber] = nil
		print("[DungeonInstanceManager] Cleared floor cache", floorNumber, "for", player.Name)
	end
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
