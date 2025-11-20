--[[
	BL2SystemShowcase.lua
	Demonstrates the BL2-accurate Gothic weapon generation system

	New Features:
	- 8 Gothic manufacturers with unique mechanics
	- Rarity-first generation (BL2-accurate)
	- 5 elemental damage types
	- 25+ accessories (rarity-dependent)
	- Part-based prefix system
	- 1.13× exponential level scaling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

print("===========================================")
print("BL2-ACCURATE GOTHIC WEAPON SYSTEM SHOWCASE")
print("===========================================\n")

-- Example 1: Basic weapon generation
print("=== EXAMPLE 1: Basic Generation ===")
local weapon1 = WeaponGenerator.GenerateWeapon(10)
print(WeaponGenerator.GetWeaponDescription(weapon1))
print("\n")

-- Example 2: Manufacturer showcase - Generate one of each
print("=== EXAMPLE 2: Manufacturer Showcase ===")
local manufacturers = {
	"Heretics Forge",
	"Inquisition Arms",
	"Divine Instruments",
	"Gravestone & Sons",
	"Hellforge",
	"Wraith Industries",
	"Apocalypse Armaments",
	"Reaper Munitions"
}

for _, mfg in ipairs(manufacturers) do
	local weapon = WeaponGenerator.GenerateWeapon(15, "Rifle", mfg)
	print(string.format("%s - %s", weapon.Name, weapon.Manufacturer.Mechanics.Description))
end
print("\n")

-- Example 3: Rarity comparison (level scaling demonstration)
print("=== EXAMPLE 3: Rarity & Level Scaling ===")
local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}
for _, rarity in ipairs(rarities) do
	local weapon = WeaponGenerator.GenerateWeapon(20, "Pistol", nil, rarity)
	print(string.format("%s | Damage: %d | DPS: %.0f",
		weapon.Rarity.Name,
		weapon.Stats.Damage,
		weapon.DPS
	))
end
print("\n")

-- Example 4: Elemental damage showcase
print("=== EXAMPLE 4: Elemental Weapons ===")
-- Generate Hellforge weapons (always elemental)
local elementalWeapons = WeaponGenerator.GenerateWeapons(5, 25, nil, "Hellforge")
for _, weapon in ipairs(elementalWeapons) do
	if weapon.Element then
		print(string.format("%s %s - %s (%s damage)",
			weapon.Element.Icon,
			weapon.Name,
			weapon.Element.Name,
			weapon.Element.EffectiveAgainst
		))
	end
end
print("\n")

-- Example 5: Accessory demonstration
print("=== EXAMPLE 5: Accessories (Epic+ Always Have Them) ===")
local epicWeapons = WeaponGenerator.GenerateWeapons(5, 20, nil, nil, "Epic")
for _, weapon in ipairs(epicWeapons) do
	local accName = weapon.Parts.Accessory and weapon.Parts.Accessory.Name or "None"
	print(string.format("%s - Accessory: %s",
		weapon.Name,
		accName
	))
end
print("\n")

-- Example 6: Level scaling demonstration (BL2's 1.13× per level)
print("=== EXAMPLE 6: Level Scaling (1.13× per level) ===")
print("Same weapon type/rarity at different levels:")
for level = 1, 50, 10 do
	local weapon = WeaponGenerator.GenerateWeapon(level, "Rifle", "Reaper Munitions", "Common")
	print(string.format("Level %2d: %5d damage | %6.0f DPS",
		level,
		weapon.Stats.Damage,
		weapon.DPS
	))
end
print("\n")

-- Example 7: Manufacturer-specific mechanics
print("=== EXAMPLE 7: Unique Manufacturer Mechanics ===\n")

print("Gravestone & Sons (Jakobs) - NEVER elemental:")
local jakobs = WeaponGenerator.GenerateWeapons(10, 20, nil, "Gravestone & Sons")
local elementalCount = 0
for _, w in ipairs(jakobs) do
	if w.Element then elementalCount = elementalCount + 1 end
end
print(string.format("  Generated 10 weapons, %d had elements (should be 0)\n", elementalCount))

print("Hellforge (Maliwan) - ALWAYS elemental:")
local maliwan = WeaponGenerator.GenerateWeapons(10, 20, nil, "Hellforge")
elementalCount = 0
for _, w in ipairs(maliwan) do
	if w.Element then elementalCount = elementalCount + 1 end
end
print(string.format("  Generated 10 weapons, %d had elements (should be 10)\n", elementalCount))

print("Apocalypse Armaments (Torgue) - ALWAYS explosive:")
local torgue = WeaponGenerator.GenerateWeapons(10, 20, nil, "Apocalypse Armaments")
local explosiveCount = 0
for _, w in ipairs(torgue) do
	if w.Element and w.Element.Name == "Apocalyptic" then
		explosiveCount = explosiveCount + 1
	end
end
print(string.format("  Generated 10 weapons, %d were explosive (should be 10)\n", explosiveCount))

-- Example 8: Prefix system demonstration
print("\n=== EXAMPLE 8: Prefix System (Priority: Accessory > Element > Grip > Barrel) ===")
local prefixWeapons = WeaponGenerator.GenerateWeapons(5, 30, nil, nil, "Legendary")
for _, weapon in ipairs(prefixWeapons) do
	local prefix = weapon.Prefix or "None"
	local source = "Unknown"

	if weapon.Parts.Accessory and weapon.Parts.Accessory.Prefix == prefix then
		source = "Accessory"
	elseif weapon.Element and weapon.Element.Name == prefix then
		source = "Element"
	end

	print(string.format('"%s" - Prefix "%s" from %s',
		weapon.Name,
		prefix,
		source
	))
end
print("\n")

-- Example 9: Boss loot generation (force legendary)
print("=== EXAMPLE 9: Boss Loot Drop (Legendary Weapons) ===")
local bossLoot = WeaponGenerator.GenerateWeapons(3, 50, nil, nil, "Legendary")
for i, weapon in ipairs(bossLoot) do
	print(string.format("\nBoss Drop #%d:", i))
	print(string.format("  %s", weapon.Name))
	print(string.format("  Manufacturer: %s", weapon.Manufacturer.Name))
	print(string.format("  Element: %s", weapon.Element and weapon.Element.Icon.." "..weapon.Element.Name or "None"))
	print(string.format("  DPS: %.0f | Magazine: %d | Reload: %.1fs",
		weapon.DPS,
		weapon.Stats.MagazineSize,
		weapon.Stats.ReloadTime
	))
end
print("\n")

-- Example 10: Weapon comparison
print("=== EXAMPLE 10: Weapon Comparison ===")
local WeaponStats = require(ReplicatedStorage.WeaponSystem.WeaponStats)
local w1 = WeaponGenerator.GenerateWeapon(30, "Sniper")
local w2 = WeaponGenerator.GenerateWeapon(30, "Sniper")

print(string.format("Weapon 1: %s (DPS: %.0f)", w1.Name, w1.DPS))
print(string.format("Weapon 2: %s (DPS: %.0f)", w2.Name, w2.DPS))

local better = WeaponStats.CompareWeapons(w1, w2)
if better == 1 then
	print("→ Weapon 1 is better!")
elseif better == 2 then
	print("→ Weapon 2 is better!")
else
	print("→ They're equal!")
end
print("\n")

-- Example 11: Deterministic generation (same seed = same weapon)
print("=== EXAMPLE 11: Deterministic Generation (Seeds) ===")
local seed = 42
local weaponA = WeaponGenerator.GenerateWeaponFromSeed(seed, 25, "Shotgun")
local weaponB = WeaponGenerator.GenerateWeaponFromSeed(seed, 25, "Shotgun")

print(string.format("Weapon A: %s", weaponA.Name))
print(string.format("Weapon B: %s", weaponB.Name))
print(string.format("Are they identical? %s", weaponA.Name == weaponB.Name and "YES ✓" or "NO ✗"))
print("\n")

-- Example 12: Stats breakdown
print("=== EXAMPLE 12: Detailed Weapon Stats ===")
local detailedWeapon = WeaponGenerator.GenerateWeapon(40, "Rifle", "Divine Instruments", "Epic")
print(WeaponGenerator.GetWeaponDescription(detailedWeapon))

print("\n===========================================")
print("SHOWCASE COMPLETE")
print("===========================================")
