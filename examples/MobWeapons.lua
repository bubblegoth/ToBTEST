--[[
	MobWeapons.lua
	Example demonstrating weapon generation for enemies/mobs
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

--[[
	Generate a weapon for an enemy based on their level and type
]]
local function GenerateMobWeapon(mobLevel, mobType)
	-- Different mob types prefer different weapons
	local weaponTypePreferences = {
		["Cultist"] = {"Pistol", "Rifle"},
		["Demon"] = {"Shotgun", "SMG"},
		["Wraith"] = {"Sniper", "Rifle"},
		["Necromancer"] = {"Rifle", "SMG"},
		["Knight"] = {"Shotgun", "Rifle"}
	}

	local preferences = weaponTypePreferences[mobType] or {"Pistol", "Rifle", "Shotgun"}
	local weaponType = preferences[math.random(1, #preferences)]

	-- Generate weapon at mob's level
	return WeaponGenerator.GenerateWeapon(mobLevel, weaponType)
end

--[[
	Example: Spawning enemies with appropriate weapons
]]
local function SpawnEnemyWave(waveNumber)
	print(string.format("\n=== Spawning Wave %d ===", waveNumber))

	-- Wave difficulty scales level
	local baseLevel = waveNumber * 2

	-- Different enemy types in the wave
	local enemyTypes = {
		{Type = "Cultist", Count = 3, LevelRange = {0, 2}},
		{Type = "Demon", Count = 2, LevelRange = {-1, 3}},
		{Type = "Knight", Count = 1, LevelRange = {1, 4}}
	}

	for _, enemyGroup in ipairs(enemyTypes) do
		for i = 1, enemyGroup.Count do
			-- Calculate this enemy's level
			local levelOffset = math.random(enemyGroup.LevelRange[1], enemyGroup.LevelRange[2])
			local enemyLevel = math.max(1, baseLevel + levelOffset)

			-- Generate weapon for this enemy
			local weapon = GenerateMobWeapon(enemyLevel, enemyGroup.Type)

			print(string.format(
				"\n%s (Level %d) spawned with:",
				enemyGroup.Type,
				enemyLevel
			))
			print(string.format(
				"  %s - %s %s (DPS: %.1f)",
				weapon.Name,
				weapon.Rarity.Name,
				weapon.Type,
				weapon.DPS
			))
		end
	end
end

--[[
	Example: Boss weapon generation (higher rarity chance)
]]
local function GenerateBossWeapon(bossLevel)
	-- Bosses get better weapons - generate multiple and pick the best
	local candidates = {}

	for i = 1, 5 do
		local weapon = WeaponGenerator.GenerateWeapon(bossLevel)
		table.insert(candidates, weapon)
	end

	-- Sort by rarity (higher rarity = better)
	local rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6}
	table.sort(candidates, function(a, b)
		return rarityOrder[a.Rarity.Name] > rarityOrder[b.Rarity.Name]
	end)

	return candidates[1] -- Return the best one
end

-- Run examples
print("=== Example 1: Enemy Wave ===")
SpawnEnemyWave(1)
SpawnEnemyWave(5)

print("\n\n=== Example 2: Boss Weapon ===")
local bossWeapon = GenerateBossWeapon(20)
print(WeaponGenerator.GetWeaponDescription(bossWeapon))

--[[
	Example: Weapon drops on enemy death
]]
local function OnEnemyDeath(enemyWeapon, dropChance)
	dropChance = dropChance or 0.3 -- 30% chance to drop weapon

	if math.random() < dropChance then
		print("\n💀 Enemy dropped their weapon!")
		print(string.format("  %s (%s)", enemyWeapon.Name, enemyWeapon.Rarity.Name))
		return enemyWeapon
	else
		print("\n💀 Enemy died but dropped no weapon")
		return nil
	end
end

-- Example weapon drop
print("\n\n=== Example 3: Weapon Drop System ===")
local enemyWeapon = GenerateMobWeapon(10, "Cultist")
print("Enemy had:", enemyWeapon.Name)
local droppedWeapon = OnEnemyDeath(enemyWeapon, 0.5)
