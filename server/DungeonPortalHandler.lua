--[[
════════════════════════════════════════════════════════════════════════════════
Script: DungeonPortalHandler
Location: ServerScriptService/
Description: Server-side handler for dungeon portal teleportation.
             Listens for portal interaction requests from clients and
             teleports players to the appropriate dungeon floor.
Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load modules
local DungeonInstanceManager = require(ReplicatedStorage.Modules.DungeonInstanceManager)

print("[DungeonPortalHandler] Initializing...")

-- Create RemoteEvent for portal teleportation
local portalTeleportEvent = Instance.new("RemoteEvent")
portalTeleportEvent.Name = "PortalTeleport"
portalTeleportEvent.Parent = ReplicatedStorage

-- ════════════════════════════════════════════════════════════════════════════
-- PORTAL TELEPORTATION HANDLER
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Handles portal teleportation requests from clients
	@param player - The player requesting teleportation
	@param targetFloor - The floor to teleport to
	@param portalType - "Entrance" or "Exit"
]]
portalTeleportEvent.OnServerEvent:Connect(function(player, targetFloor, portalType)
	-- Validate input
	if type(targetFloor) ~= "number" then
		warn("[DungeonPortalHandler] Invalid target floor from", player.Name, ":", targetFloor)
		return
	end

	print(string.format("[DungeonPortalHandler] %s requesting teleport to floor %d via %s portal",
		player.Name, targetFloor, portalType or "Unknown"))

	-- Verify player has a character
	if not player.Character then
		warn("[DungeonPortalHandler] No character found for", player.Name)
		return
	end

	-- Teleport the player
	local success = DungeonInstanceManager.TeleportToFloor(player, targetFloor)

	if success then
		print(string.format("[DungeonPortalHandler] ✓ Successfully teleported %s to floor %d",
			player.Name, targetFloor))
	else
		warn(string.format("[DungeonPortalHandler] ✗ Failed to teleport %s to floor %d",
			player.Name, targetFloor))
	end
end)

print("[DungeonPortalHandler] ✓ Ready - Listening for portal teleportation requests")
