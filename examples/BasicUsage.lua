--[[
	BasicUsage.lua
	Example demonstrating basic weapon generation usage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

-- Example 1: Generate a random weapon
print("=== Example 1: Random Weapon ===")
local weapon1 = WeaponGenerator.GenerateWeapon()
print(WeaponGenerator.GetWeaponDescription(weapon1))

-- Example 2: Generate a weapon for level 10
print("\n=== Example 2: Level 10 Weapon ===")
local weapon2 = WeaponGenerator.GenerateWeapon(10)
print(WeaponGenerator.GetWeaponDescription(weapon2))

-- Example 3: Generate a specific type
print("\n=== Example 3: Level 15 Sniper Rifle ===")
local weapon3 = WeaponGenerator.GenerateWeapon(15, "Sniper")
print(WeaponGenerator.GetWeaponDescription(weapon3))

-- Example 4: Generate multiple weapons (loot drop)
print("\n=== Example 4: Generate 5 Random Weapons ===")
local weapons = WeaponGenerator.GenerateWeapons(5, 8)
for i, weapon in ipairs(weapons) do
	print(string.format("\nWeapon %d: %s (%s %s)",
		i, weapon.Name, weapon.Rarity.Name, weapon.Type))
	print(string.format("  DPS: %.1f | Level: %d", weapon.DPS, weapon.Level))
end

-- Example 5: Deterministic generation (same seed = same weapon)
print("\n=== Example 5: Deterministic Generation ===")
local seed = 12345
local weaponA = WeaponGenerator.GenerateWeaponFromSeed(seed, 10, "Rifle")
local weaponB = WeaponGenerator.GenerateWeaponFromSeed(seed, 10, "Rifle")
print("Weapon A:", weaponA.Name)
print("Weapon B:", weaponB.Name)
print("Are they identical?", weaponA.Name == weaponB.Name)
