--[[
	DungeonSystemDemo.lua
	Demonstration of the complete Gothic FPS Roguelite Dungeon System
	Shows integration of all modules: Dungeon Generation, Enemies, Loot, Church, Death
]]

local DungeonGenerator = require(script.Parent.Parent.src.DungeonGenerator)
local EnemySystem = require(script.Parent.Parent.src.EnemySystem)
local LootDropper = require(script.Parent.Parent.src.LootDropper)
local PlayerStats = require(script.Parent.Parent.src.PlayerStats)
local ChurchSystem = require(script.Parent.Parent.src.ChurchSystem)
local DeathHandler = require(script.Parent.Parent.src.DeathHandler)

print("\n" .. string.rep("=", 60))
print("GOTHIC FPS ROGUELITE DUNGEON SYSTEM - COMPLETE DEMO")
print(string.rep("=", 60) .. "\n")

-- ============================================================
-- 1. INITIALIZE PLAYER
-- ============================================================

print("=== INITIALIZING PLAYER ===\n")

local player = PlayerStats.new()
print("New player created at Floor 1 (The Church)")
print("Starting Souls:", player:GetSouls())
print("Starting Weapons:", #player.CurrentWeapons, "\n")

-- ============================================================
-- 2. CHURCH - VIEW AVAILABLE UPGRADES
-- ============================================================

print("=== THE CHURCH (FLOOR 1) ===\n")

print("You start in the Church with no Souls...")
print(ChurchSystem.GetPlayerStatsOverview(player))

print("\nNo upgrades available yet. Let's venture into the dungeon!\n")

-- ============================================================
-- 3. GENERATE & EXPLORE FLOOR 2
-- ============================================================

print(string.rep("=", 60))
print("=== DESCENDING TO FLOOR 2 ===")
print(string.rep("=", 60) .. "\n")

player:AdvanceFloor()
local floor2 = DungeonGenerator.GenerateFloor(2)

print(DungeonGenerator.GetFloorSummary(floor2))

-- Simulate clearing a room
print("\n--- ROOM 1: COMBAT ---\n")

local room1 = floor2.Rooms[1]
local enemies = EnemySystem.SpawnEnemiesForRoom(room1, 2)

print(string.format("Spawned %d enemies:", #enemies))
for i, enemy in ipairs(enemies) do
	print(string.format("  %d. %s", i, EnemySystem.GetEnemyDescription(enemy)))
end

-- Kill enemies and collect loot
print("\n--- COMBAT RESULTS ---\n")

for i, enemy in ipairs(enemies) do
	-- Simulate killing enemy
	EnemySystem.DamageEnemy(enemy, enemy.MaxHealth)
	print(string.format("Killed %s (Lv.%d)", enemy.Type, enemy.Level))

	-- Roll for loot
	local drops = LootDropper.ProcessEnemyDeath(enemy, 2)

	if drops then
		if drops.Souls > 0 then
			player:AddSouls(drops.Souls)
			print(string.format("  + %d Souls", drops.Souls))
		end

		for _, weapon in ipairs(drops.Weapons) do
			player:AddWeapon(weapon)
			print(string.format("  + [Lv.%d %s] %s", weapon.Level, weapon.Rarity, weapon.Name))
		end
	end
end

print(string.format("\nTotal Souls: %d", player:GetSouls()))
print(string.format("Total Weapons: %d", #player.CurrentWeapons))

-- ============================================================
-- 4. CONTINUE TO FLOOR 10 (BOSS FLOOR)
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== FAST-FORWARD TO FLOOR 10 (BOSS FLOOR) ===")
print(string.rep("=", 60) .. "\n")

-- Simulate progressing to floor 10
for i = 3, 10 do
	player:AdvanceFloor()

	-- Simulate earning some Souls per floor
	local soulsEarned = math.random(10, 30)
	player:AddSouls(soulsEarned)
	player:IncrementKills()
end

local floor10 = DungonGenerator.GenerateFloor(10)

print(DungeonGenerator.GetFloorSummary(floor10))

-- Find boss room
local bossRoom = nil
for _, room in ipairs(floor10.Rooms) do
	if room.IsBossRoom then
		bossRoom = room
		break
	end
end

if bossRoom then
	print("\n--- BOSS ENCOUNTER ---\n")

	local bossEnemies = EnemySystem.SpawnEnemiesForRoom(bossRoom, 10)
	local boss = bossEnemies[1]

	print("Boss spawned:")
	print(EnemySystem.GetEnemyDescription(boss))

	-- Kill boss
	print("\n*** BOSS DEFEATED ***\n")
	EnemySystem.DamageEnemy(boss, boss.MaxHealth)

	-- Boss loot
	local bossDrops = LootDropper.ProcessEnemyDeath(boss, 10)

	print(LootDropper.GetLootSummary(bossDrops))

	if bossDrops.Souls > 0 then
		player:AddSouls(bossDrops.Souls)
	end

	for _, weapon in ipairs(bossDrops.Weapons) do
		player:AddWeapon(weapon)
	end
end

print(string.format("\nRun Stats After Floor 10:"))
print(string.format("  Souls: %d", player:GetSouls()))
print(string.format("  Weapons: %d", #player.CurrentWeapons))
print(string.format("  Kills: %d", player:GetRunStats().Kills))

-- ============================================================
-- 5. PLAYER DIES - RETURN TO CHURCH
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== PLAYER DEATH ===")
print(string.rep("=", 60) .. "\n")

print("Oh no! You died on Floor 15...\n")

-- Simulate death
player.CurrentFloor = 15
local deathResult = DeathHandler.OnPlayerDeath(player)

print(deathResult.Message)

-- ============================================================
-- 6. BACK AT CHURCH - PURCHASE UPGRADES
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== BACK AT THE CHURCH ===")
print(string.rep("=", 60) .. "\n")

print(ChurchSystem.GetShopSummary(player))

-- Purchase some upgrades
print("\n--- PURCHASING UPGRADES ---\n")

local upgradesToBuy = {"GunDamage", "MaxHealth", "CritDamage"}

for _, upgradeID in ipairs(upgradesToBuy) do
	local success, message = ChurchSystem.PurchaseUpgrade(player, upgradeID)

	if success then
		print(string.format("✓ %s", message))
	else
		print(string.format("✗ Failed to purchase %s: %s", upgradeID, message))
	end
end

print(string.format("\nSouls Remaining: %d", player:GetSouls()))

-- View updated stats
print("\n" .. ChurchSystem.GetPlayerStatsOverview(player))

-- ============================================================
-- 7. START NEW RUN
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== STARTING NEW RUN ===")
print(string.rep("=", 60) .. "\n")

print("Beginning new descent with upgraded stats...")
print("Your permanent upgrades will apply to all weapons you find!\n")

-- ============================================================
-- 8. FLOOR 666 (VICTORY)
-- ============================================================

print(string.rep("=", 60))
print("=== HYPOTHETICAL: FLOOR 666 CLEARED ===")
print(string.rep("=", 60) .. "\n")

-- Simulate reaching Floor 666
player.CurrentFloor = 666
player:AddSouls(5000) -- Massive Soul reward

local victoryResult = DeathHandler.OnRunComplete(player)

print(victoryResult.Message)

-- ============================================================
-- 9. LOOT DROP SIMULATION
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== LOOT DROP STATISTICS (1000 iterations) ===")
print(string.rep("=", 60) .. "\n")

print("--- Normal Enemy (Floor 10) ---")
local normalResults = LootDropper.SimulateLootDrops("Normal", 10, 10, 1000)
LootDropper.PrintSimulationResults(normalResults)

print("\n--- Rare Enemy (Floor 10) ---")
local rareResults = LootDropper.SimulateLootDrops("Rare", 10, 10, 1000)
LootDropper.PrintSimulationResults(rareResults)

print("\n--- Boss Enemy (Floor 10) ---")
local bossResults = LootDropper.SimulateLootDrops("Boss", 10, 10, 1000)
LootDropper.PrintSimulationResults(bossResults)

-- ============================================================
-- 10. FLOOR GENERATION SHOWCASE
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== FLOOR GENERATION SHOWCASE ===")
print(string.rep("=", 60) .. "\n")

local showcaseFloors = {1, 2, 10, 50, 100, 500, 666}

for _, floorNum in ipairs(showcaseFloors) do
	local floor = DungeonGenerator.GenerateFloor(floorNum)
	print(DungeonGenerator.GetFloorSummary(floor))
	print("")
end

-- ============================================================
-- SUMMARY
-- ============================================================

print(string.rep("=", 60))
print("=== DUNGEON SYSTEM DEMO COMPLETE ===")
print(string.rep("=", 60))

print("\nAll systems operational:")
print("  ✓ Dungeon Generation (666 floors)")
print("  ✓ Enemy Spawning (Normal, Rare, Boss)")
print("  ✓ Loot Drops (Weapons Floor 2+, Souls from Rare/Boss)")
print("  ✓ Player Progression (Persistent Souls & Upgrades)")
print("  ✓ Church System (14 permanent upgrades)")
print("  ✓ Death Handling (Roguelite persistence)")
print("\nReady for integration into your Gothic FPS!")
