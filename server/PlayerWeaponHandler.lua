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
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))

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

	-- Check if player is on Floor 1+ (not in Church/Floor 0)
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
	if playerStats then
		local currentFloor = playerStats:GetCurrentFloor()
		if currentFloor == 0 then
			print("[PlayerWeapon]", player.Name, "is in Church (Floor 0) - no starting weapon")
			return
		end
		print("[PlayerWeapon]", player.Name, "is on Floor", currentFloor)
	else
		-- If no PlayerStats yet, assume Floor 0 and don't give weapon
		print("[PlayerWeapon] No PlayerStats for", player.Name, "- assuming Church, no weapon")
		return
	end

	-- Clear all old weapons from backpack and character on respawn
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("UniqueID") then
				item:Destroy()
			end
		end
	end

	-- Clear weapons from character
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") and item:GetAttribute("UniqueID") then
			item:Destroy()
		end
	end

	print("[PlayerWeapon] Cleared old weapons for", player.Name, "- giving fresh starting weapon")

	-- Clear all ammo from inventory weapons on respawn
	local inventory = PlayerInventory.GetInventory(player)
	if inventory then
		inventory:ResetAllAmmo()
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
