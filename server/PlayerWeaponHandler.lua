--[[
════════════════════════════════════════════════════════════════════════════════
Module: PlayerWeaponHandler
Location: ServerScriptService/
Description: Ensures all players spawn with a Common Level 1 Pistol.
             Gothic FPS Roguelite starting weapon system.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[PlayerWeapon] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WeaponGenerator = require(Modules:WaitForChild("WeaponGenerator"))
local WeaponToolBuilder = require(Modules:WaitForChild("WeaponToolBuilder"))

-- ════════════════════════════════════════════════════════════════════════════
-- STARTING WEAPON CONFIG
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	Level = 1,
	Type = "Pistol",
	Rarity = "Common",
	AutoEquip = true,
}

-- ════════════════════════════════════════════════════════════════════════════
-- GIVE STARTING WEAPON
-- ════════════════════════════════════════════════════════════════════════════

local function giveStartingWeapon(player, character)
	-- Wait for character to fully load
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		warn("[PlayerWeapon] No humanoid found for", player.Name)
		return
	end

	-- Wait a moment for character to settle
	task.wait(0.5)

	-- Check if player already has a weapon
	local existingTool = character:FindFirstChildOfClass("Tool")
	if existingTool then
		print("[PlayerWeapon]", player.Name, "already has weapon:", existingTool.Name)
		return
	end

	-- Generate Common Level 1 Pistol
	local weapon = WeaponGenerator:GenerateWeapon(
		Config.Level,    -- Level 1
		Config.Type,     -- Pistol
		Config.Rarity    -- Force Common rarity
	)

	if not weapon then
		warn("[PlayerWeapon] Failed to generate weapon for", player.Name)
		return
	end

	-- Mark as starting weapon
	weapon.IsStartingWeapon = true

	-- Give weapon to player
	local success = WeaponToolBuilder:GiveWeaponToPlayer(player, weapon, Config.AutoEquip)

	if success then
		print(string.format("[PlayerWeapon] ✓ %s received: %s (Common Pistol Lv.1)",
			player.Name, weapon.Name))
	else
		warn("[PlayerWeapon] Failed to give weapon to", player.Name)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
-- ════════════════════════════════════════════════════════════════════════════

local function onPlayerAdded(player)
	-- Give weapon on character spawn
	player.CharacterAdded:Connect(function(character)
		giveStartingWeapon(player, character)
	end)

	-- Give weapon if character already exists
	if player.Character then
		giveStartingWeapon(player, player.Character)
	end
end

-- Connect to existing and new players
Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[PlayerWeapon] ═══════════════════════════════════════")
print("[PlayerWeapon] Starting Weapon System Active")
print("[PlayerWeapon] Config: Common Pistol Level 1")
print("[PlayerWeapon] ═══════════════════════════════════════")
