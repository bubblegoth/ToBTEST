--[[
════════════════════════════════════════════════════════════════════════════════
Module: EnemySystem
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Enemy spawning and stat calculation system.
             Manages enemy types (Normal, Rare, Boss) with scaling stats.
             Handles room-based enemy distribution and difficulty scaling.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local DungeonConfig = require(script.Parent.DungeonConfig)

local EnemySystem = {}

-- RNG for enemy spawning
local rng = Random.new()

-- ============================================================
-- SEED MANAGEMENT
-- ============================================================

function EnemySystem.SetSeed(seed)
	rng = Random.new(seed)
end

-- ============================================================
-- ENEMY SPAWNING
-- ============================================================

function EnemySystem.SpawnEnemiesForRoom(room, floorNumber)
	if room.IsSafeZone or room.EnemyCount == 0 then
		return {}
	end

	local enemies = {}

	-- Boss room: spawn single boss
	if room.IsBossRoom then
		local boss = EnemySystem.CreateEnemy("Boss", floorNumber)
		table.insert(enemies, boss)
		return enemies
	end

	-- Standard room: spawn mix of normal/rare enemies
	for i = 1, room.EnemyCount do
		local enemyType = EnemySystem.RollEnemyType(room.RareEnemyChance)
		local enemy = EnemySystem.CreateEnemy(enemyType, floorNumber)
		table.insert(enemies, enemy)
	end

	return enemies
end

-- ============================================================
-- ENEMY TYPE SELECTION
-- ============================================================

function EnemySystem.RollEnemyType(rareChance)
	local roll = rng:NextNumber(0, 1)

	if roll < rareChance then
		return "Rare"
	else
		return "Normal"
	end
end

-- ============================================================
-- ENEMY CREATION
-- ============================================================

function EnemySystem.CreateEnemy(enemyType, level)
	local config = DungeonConfig.EnemyTypes[string.upper(enemyType)]

	if not config then
		warn("Invalid enemy type:", enemyType, "- defaulting to Normal")
		config = DungeonConfig.EnemyTypes.NORMAL
		enemyType = "Normal"
	end

	-- Base stats (scale with level)
	local baseHealth = 100
	local baseDamage = 10

	local enemy = {
		ID = string.format("%s_%d_%d", enemyType, level, rng:NextInteger(1000, 9999)),
		Type = enemyType,
		Level = level,

		-- Combat stats (scaled by level and type)
		MaxHealth = baseHealth * level * config.HealthMultiplier,
		CurrentHealth = nil, -- Set to MaxHealth when spawned
		Damage = baseDamage * level * config.DamageMultiplier,

		-- Loot configuration
		SoulDropChance = config.SoulDropChance,
		SoulDropMin = config.SoulDropMin or 0,
		SoulDropMax = config.SoulDropMax or 0,
		WeaponDropChance = config.WeaponDropChance,
		WeaponRarityBonus = config.WeaponRarityBonus or 0,

		-- State
		IsAlive = true,
		IsBoss = (enemyType == "Boss"),
		IsRare = (enemyType == "Rare"),
	}

	enemy.CurrentHealth = enemy.MaxHealth

	return enemy
end

-- ============================================================
-- ENEMY STAT CALCULATION
-- ============================================================

function EnemySystem.GetEnemyStats(enemy)
	return {
		ID = enemy.ID,
		Type = enemy.Type,
		Level = enemy.Level,
		Health = string.format("%d / %d", enemy.CurrentHealth, enemy.MaxHealth),
		Damage = enemy.Damage,
		SoulDropChance = string.format("%d%%", enemy.SoulDropChance * 100),
		WeaponDropChance = string.format("%d%%", enemy.WeaponDropChance * 100),
	}
end

-- ============================================================
-- ENEMY DAMAGE & DEATH
-- ============================================================

function EnemySystem.DamageEnemy(enemy, damage)
	if not enemy.IsAlive then
		return false, "Enemy already dead"
	end

	enemy.CurrentHealth = math.max(0, enemy.CurrentHealth - damage)

	if enemy.CurrentHealth <= 0 then
		enemy.IsAlive = false
		return true, "Enemy killed"
	end

	return true, string.format("Enemy took %d damage (%d HP remaining)", damage, enemy.CurrentHealth)
end

function EnemySystem.IsEnemyAlive(enemy)
	return enemy.IsAlive and enemy.CurrentHealth > 0
end

-- ============================================================
-- LOOT DROP ROLLING
-- ============================================================

function EnemySystem.RollLoot(enemy, floorNumber)
	if not enemy or enemy.IsAlive then
		return nil
	end

	local loot = {
		Souls = 0,
		ShouldDropWeapon = false,
		WeaponLevel = floorNumber,
		WeaponRarityBonus = enemy.WeaponRarityBonus,
	}

	-- Roll for Soul drop
	if enemy.SoulDropChance > 0 then
		local soulRoll = rng:NextNumber(0, 1)
		if soulRoll <= enemy.SoulDropChance then
			loot.Souls = rng:NextInteger(enemy.SoulDropMin, enemy.SoulDropMax)
		end
	end

	-- Roll for weapon drop (only on Floor 2+)
	if floorNumber >= DungeonConfig.LootRules.WeaponDropsStartFloor then
		if enemy.WeaponDropChance > 0 then
			local weaponRoll = rng:NextNumber(0, 1)
			if weaponRoll <= enemy.WeaponDropChance then
				loot.ShouldDropWeapon = true
			end
		end
	end

	return loot
end

-- ============================================================
-- ENEMY DISPLAY / DEBUG
-- ============================================================

function EnemySystem.GetEnemyDescription(enemy)
	local healthBar = string.format("[%d / %d HP]", enemy.CurrentHealth, enemy.MaxHealth)
	local status = enemy.IsAlive and "ALIVE" or "DEAD"

	local description = string.format(
		"[Lv.%d %s] %s %s\n" ..
		"Damage: %d\n" ..
		"Soul Drop: %d%% (%d-%d)\n" ..
		"Weapon Drop: %d%%",
		enemy.Level,
		enemy.Type,
		healthBar,
		status,
		enemy.Damage,
		enemy.SoulDropChance * 100,
		enemy.SoulDropMin,
		enemy.SoulDropMax,
		enemy.WeaponDropChance * 100
	)

	return description
end

-- ============================================================
-- BATCH ENEMY GENERATION (FOR TESTING)
-- ============================================================

function EnemySystem.GenerateEnemies(count, enemyType, level)
	local enemies = {}

	for i = 1, count do
		local enemy = EnemySystem.CreateEnemy(enemyType, level)
		table.insert(enemies, enemy)
	end

	return enemies
end

return EnemySystem
