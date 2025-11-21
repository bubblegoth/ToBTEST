--[[
════════════════════════════════════════════════════════════════════════════════
Module: ServerInit
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Server initialization system - runs once on server start.
             Spawns Soul Vendor in Church, sets up global game systems.
             Not per-player - executes once for the entire server.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Note: Soul Vendor spawning is now handled by server/NPCSpawner.lua
-- Old NPCGenerator and SoulVendor imports removed

print("[ServerInit] Initializing game systems...")

-- ============================================================
-- SPAWN SOUL VENDOR (DISABLED - Now handled by NPCSpawner.lua)
-- ============================================================

--[[
	Soul Vendor spawning has been moved to server/NPCSpawner.lua
	which uses MobGenerator and the new SoulVendorGUI system.
	This old function is kept for reference but should not be used.
]]

local function SpawnSoulVendor()
	print("[ServerInit] Soul Vendor spawning is now handled by NPCSpawner.lua")
	-- Old spawning code removed - see server/NPCSpawner.lua instead
end

-- ============================================================
-- INITIALIZE ON SERVER START
-- ============================================================

local function Initialize()
	-- Wait for workspace to load
	wait(1)

	-- NOTE: Dungeons are positioned horizontally (X-axis) instead of vertically (Y-axis)
	-- to avoid Roblox's FallenPartsDestroyHeight limitation in Studio Play mode
	-- Floor N is at position X = N * 10000, Y = 0, Z = 0
	print("[ServerInit] Dungeon positioning: Horizontal offset (Floor N at X = N * 10000)")

	-- Soul Vendor is now spawned by server/NPCSpawner.lua (not here)
	print("[ServerInit] Soul Vendor handled by NPCSpawner.lua")

	-- TODO: Add other initialization here
	-- - Spawn starting enemies (if any)
	-- - Set up dungeon entrance
	-- - Initialize player data management

	print("[ServerInit] Game initialization complete!")
end

-- Run initialization
Initialize()
