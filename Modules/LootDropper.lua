--[[
	LootDropper.lua
	Handles loot drops from enemies (Weapons Floor 2+, Souls from Rare/Boss)
	Now delegates to ModularLootGen for visual weapon drops
	Part of the Gothic FPS Roguelite Dungeon System
]]

local DungeonConfig = require(script.Parent.DungeonConfig)
local EnemySystem = require(script.Parent.EnemySystem)
local WeaponGenerator = require(script.Parent.WeaponGenerator)
local ModularLootGen = require(script.Parent.ModularLootGen)

local LootDropper = {}

-- ============================================================
-- LOOT DROP PROCESSING
-- ============================================================

function LootDropper.ProcessEnemyDeath(enemy, floorNumber, roomMultiplier)
	if not enemy or enemy.IsAlive then
		return nil
	end

	-- Roll for loot using EnemySystem
	local lootRoll = EnemySystem.RollLoot(enemy, floorNumber)

	if not lootRoll then
		return nil
	end

	local drops = {
		Souls = 0,
		Weapons = {},
		EnemyType = enemy.Type,
		EnemyLevel = enemy.Level,
	}

	-- Apply room multiplier for Soul drops (e.g., Treasure rooms)
	local soulMultiplier = roomMultiplier or 1.0
	drops.Souls = math.floor(lootRoll.Souls * soulMultiplier)

	-- Generate weapon if dropped
	if lootRoll.ShouldDropWeapon then
		local weapon = LootDropper.GenerateWeaponDrop(
			lootRoll.WeaponLevel,
			lootRoll.WeaponRarityBonus
		)

		if weapon then
			table.insert(drops.Weapons, weapon)
		end
	end

	return drops
end

-- ============================================================
-- WEAPON DROP GENERATION
-- ============================================================

function LootDropper.GenerateWeaponDrop(level, rarityBonus)
	rarityBonus = rarityBonus or 0

	-- Generate base weapon at enemy level
	local weapon = WeaponGenerator.GenerateWeapon(level)

	-- Apply rarity bonus if enemy was Rare/Boss
	if rarityBonus > 0 then
		weapon = LootDropper.UpgradeWeaponRarity(weapon, rarityBonus, level)
	end

	return weapon
end

-- ============================================================
-- RARITY UPGRADE (RARE/BOSS BONUS)
-- ============================================================

function LootDropper.UpgradeWeaponRarity(weapon, rarityTiersToIncrease, level)
	-- Rarity tier ordering
	local rarityOrder = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"}

	-- Find current rarity index
	local currentIndex = 1
	for i, rarity in ipairs(rarityOrder) do
		if weapon.Rarity == rarity then
			currentIndex = i
			break
		end
	end

	-- Upgrade rarity
	local newIndex = math.min(#rarityOrder, currentIndex + rarityTiersToIncrease)
	local newRarity = rarityOrder[newIndex]

	-- Regenerate weapon with forced rarity
	local upgradedWeapon = WeaponGenerator.GenerateWeapon(
		level,
		weapon.Type, -- Keep same weapon type
		nil, -- Random manufacturer
		newRarity -- Force upgraded rarity
	)

	return upgradedWeapon
end

-- ============================================================
-- BATCH LOOT PROCESSING (FOR ROOM CLEARS)
-- ============================================================

function LootDropper.ProcessRoomClear(enemies, floorNumber, roomMultiplier)
	local totalDrops = {
		TotalSouls = 0,
		TotalWeapons = {},
		DropsByEnemy = {},
	}

	for _, enemy in ipairs(enemies) do
		if not enemy.IsAlive then
			local drops = LootDropper.ProcessEnemyDeath(enemy, floorNumber, roomMultiplier)

			if drops then
				totalDrops.TotalSouls = totalDrops.TotalSouls + drops.Souls

				for _, weapon in ipairs(drops.Weapons) do
					table.insert(totalDrops.TotalWeapons, weapon)
				end

				table.insert(totalDrops.DropsByEnemy, {
					EnemyID = enemy.ID,
					EnemyType = enemy.Type,
					Drops = drops,
				})
			end
		end
	end

	return totalDrops
end

-- ============================================================
-- LOOT SUMMARY / DISPLAY
-- ============================================================

function LootDropper.GetLootSummary(drops)
	if not drops then
		return "No loot dropped"
	end

	local summary = string.format(
		"=== LOOT DROPPED ===\n" ..
		"Souls: %d\n" ..
		"Weapons: %d\n",
		drops.Souls or drops.TotalSouls or 0,
		#(drops.Weapons or drops.TotalWeapons or {})
	)

	-- List weapons
	local weapons = drops.Weapons or drops.TotalWeapons or {}
	if #weapons > 0 then
		summary = summary .. "\nWeapons Dropped:\n"
		for i, weapon in ipairs(weapons) do
			summary = summary .. string.format(
				"  %d. [Lv.%d %s] %s (%s %s)\n",
				i,
				weapon.Level,
				weapon.Rarity,
				weapon.Name,
				weapon.Manufacturer,
				weapon.Type
			)
		end
	end

	return summary
end

-- ============================================================
-- LOOT RULES VALIDATION
-- ============================================================

function LootDropper.IsLootEnabledOnFloor(floorNumber)
	return floorNumber >= DungeonConfig.LootRules.WeaponDropsStartFloor
end

function LootDropper.CanEnemyDropSouls(enemy)
	return enemy and (enemy.IsRare or enemy.IsBoss) and enemy.SoulDropChance > 0
end

function LootDropper.CanEnemyDropWeapon(enemy, floorNumber)
	return enemy and
	       LootDropper.IsLootEnabledOnFloor(floorNumber) and
	       enemy.WeaponDropChance > 0
end

-- ============================================================
-- DEBUG / TESTING HELPERS
-- ============================================================

function LootDropper.SimulateLootDrops(enemyType, level, floorNumber, iterations)
	iterations = iterations or 100

	local results = {
		TotalSouls = 0,
		TotalWeapons = 0,
		SoulDropCount = 0,
		WeaponDropCount = 0,
		Iterations = iterations,
	}

	for i = 1, iterations do
		local enemy = EnemySystem.CreateEnemy(enemyType, level)
		enemy.IsAlive = false -- Mark as dead for loot rolling

		local drops = LootDropper.ProcessEnemyDeath(enemy, floorNumber)

		if drops then
			if drops.Souls > 0 then
				results.TotalSouls = results.TotalSouls + drops.Souls
				results.SoulDropCount = results.SoulDropCount + 1
			end

			if #drops.Weapons > 0 then
				results.TotalWeapons = results.TotalWeapons + #drops.Weapons
				results.WeaponDropCount = results.WeaponDropCount + 1
			end
		end
	end

	-- Calculate averages
	results.AverageSoulsPerDrop = results.SoulDropCount > 0 and (results.TotalSouls / results.SoulDropCount) or 0
	results.SoulDropRate = (results.SoulDropCount / iterations) * 100
	results.WeaponDropRate = (results.WeaponDropCount / iterations) * 100

	return results
end

function LootDropper.PrintSimulationResults(results)
	print(string.format(
		"\n=== LOOT DROP SIMULATION (%d iterations) ===\n" ..
		"Soul Drops: %d (%.1f%% drop rate)\n" ..
		"Total Souls: %d (avg %.1f per drop)\n" ..
		"Weapon Drops: %d (%.1f%% drop rate)\n" ..
		"Total Weapons: %d\n",
		results.Iterations,
		results.SoulDropCount,
		results.SoulDropRate,
		results.TotalSouls,
		results.AverageSoulsPerDrop,
		results.WeaponDropCount,
		results.WeaponDropRate,
		results.TotalWeapons
	))
end

-- ============================================================
-- MODULAR LOOT GEN INTEGRATION (VISUAL DROPS)
-- ============================================================

--[[
	Spawns a visual weapon drop in the world using ModularLootGen
	This creates floating 3D weapon models that players can pick up
]]
function LootDropper.SpawnVisualWeaponDrop(position, level, floorNumber, forcedRarity)
	return ModularLootGen:SpawnWeaponLoot(position, level, forcedRarity)
end

--[[
	Handles enemy death with visual loot spawning
	Use this when an enemy dies to spawn loot in the world
]]
function LootDropper.HandleEnemyDeathWithLoot(enemy, playerLevel, floorNumber)
	if not enemy or not enemy.PrimaryPart then return end

	-- Use ModularLootGen to handle enemy loot spawning
	ModularLootGen:SpawnLootFromEnemy(enemy, playerLevel, floorNumber)
end

return LootDropper
