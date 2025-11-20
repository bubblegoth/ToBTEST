# Gothic FPS Roguelite - Complete Module Reference

**Version:** 1.0
**Project:** Gothic-themed Borderlands-inspired procedural weapon + roguelite dungeon system for Roblox

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Module List by Category](#module-list-by-category)
3. [Complete Game Flow](#complete-game-flow)
4. [Module Details](#module-details)
5. [Integration Guide](#integration-guide)

---

## System Overview

This project consists of **two major systems**:

### 1. **Weapon Generation System** (Complete)
Borderlands 2-accurate procedural weapon generation with:
- 7 Gothic-themed manufacturers
- 5 weapon types (Pistol, Rifle, Shotgun, SMG, Sniper)
- 6 rarity tiers (Common → Mythic)
- 5 elemental damage types
- BL2-accurate stat calculations and level scaling

### 2. **Dungeon & Progression System** (Complete)
Roguelite dungeon crawler with:
- 666 procedurally generated floors
- 3 enemy types (Normal, Rare, Boss)
- Loot drops (Weapons from Floor 2+, Souls from Rare/Boss)
- 14 permanent upgrades purchased with Souls
- Death mechanics (lose weapons, keep Souls/upgrades)
- Church hub system (Floor 1)

---

## Module List by Category

### **Core Weapon System** (7 modules)

| Module | Location | Controls |
|--------|----------|----------|
| **WeaponGenerator.lua** | `/Modules/` | Weapon generation orchestration, 8-step BL2 process |
| **WeaponStats.lua** | `/Modules/` | Stat calculation, DPS, level scaling, weapon comparison |
| **WeaponConfig.lua** | `/Modules/` | Rarities, manufacturers, elements, weapon types, constants |
| **Bodies.lua** | `/Modules/WeaponParts/` | Weapon type determination (Pistol/Rifle/etc) |
| **Barrels.lua** | `/Modules/WeaponParts/` | Damage, accuracy, range, fire rate |
| **Grips.lua** | `/Modules/WeaponParts/` | Recoil control, handling, aiming |
| **Stocks.lua** | `/Modules/WeaponParts/` | Stability, accuracy, movement trade-offs |
| **Magazines.lua** | `/Modules/WeaponParts/` | Capacity, reload speed, mobility penalties |
| **Sights.lua** | `/Modules/WeaponParts/` | Accuracy, zoom, critical hit bonuses |
| **Accessories.lua** | `/Modules/WeaponParts/` | Optional attachments (rarity-dependent) |

### **Dungeon & Progression System** (7 modules)

| Module | Location | Controls |
|--------|----------|----------|
| **DungeonConfig.lua** | `/Modules/` | Floor rules, room types, enemy types, upgrade definitions |
| **DungeonGenerator.lua** | `/Modules/` | Procedural floor generation (666 floors) |
| **EnemySystem.lua** | `/Modules/` | Enemy spawning, stats, types (Normal/Rare/Boss) |
| **LootDropper.lua** | `/Modules/` | Loot drop logic, weapon generation integration |
| **PlayerStats.lua** | `/Modules/` | Persistent progression (Souls, upgrades, run stats) |
| **ChurchSystem.lua** | `/Modules/` | Upgrade shop, Soul spending, stat overview |
| **DeathHandler.lua** | `/Modules/` | Death mechanics, run completion, persistence |

### **Examples & Documentation** (5 files)

| File | Location | Purpose |
|------|----------|---------|
| **BasicUsage.lua** | `/examples/` | Basic weapon generation examples |
| **BL2SystemShowcase.lua** | `/examples/` | Manufacturer mechanics demonstration |
| **MobWeapons.lua** | `/examples/` | Enemy weapon generation |
| **VisualWeaponBuilder.lua** | `/examples/` | 3D weapon model building |
| **DungeonSystemDemo.lua** | `/examples/` | **Complete dungeon system walkthrough** |

---

## Complete Game Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PLAYER SPAWNS IN CHURCH                   │
│                        (FLOOR 1)                             │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> PlayerStats.new() - Initialize player
                  ├─> ChurchSystem - View available upgrades
                  └─> No Souls yet - venture into dungeon
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  DESCEND TO FLOOR 2+                         │
│                (Weapons Start Dropping)                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> DungeonGenerator.GenerateFloor(floorNum)
                  │   └─> Generates random rooms
                  │   └─> Calculates rare enemy % for floor
                  │   └─> Determines if boss floor (every 10)
                  │
                  ├─> EnemySystem.SpawnEnemiesForRoom(room, floor)
                  │   └─> Spawns Normal/Rare/Boss enemies
                  │   └─> Scales stats by level (linear)
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   COMBAT & LOOT DROPS                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> EnemySystem.DamageEnemy(enemy, damage)
                  │   └─> Reduce enemy health
                  │   └─> Mark as dead when HP = 0
                  │
                  ├─> LootDropper.ProcessEnemyDeath(enemy, floor)
                  │   ├─> Roll for Soul drop (Rare/Boss only)
                  │   │   └─> PlayerStats:AddSouls(amount)
                  │   │
                  │   └─> Roll for weapon drop (Floor 2+, % chance)
                  │       └─> WeaponGenerator.GenerateWeapon(level)
                  │           ├─> Rare/Boss: +1/+2 rarity bonus
                  │           └─> PlayerStats:AddWeapon(weapon)
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│               FLOOR CLEARED - ADVANCE                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> PlayerStats:AdvanceFloor()
                  ├─> Repeat for next floor (up to 666)
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   PLAYER DEATH                               │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> DeathHandler.OnPlayerDeath(playerStats)
                  │   ├─> Capture run summary
                  │   ├─> PlayerStats:OnDeath()
                  │   │   ├─> Clear all weapons ❌
                  │   │   ├─> Reset to Floor 1
                  │   │   └─> KEEP Souls & Upgrades ✓
                  │   │
                  │   └─> Display death summary
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              RETURN TO CHURCH (FLOOR 1)                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─> ChurchSystem.GetAvailableUpgrades(player)
                  │   └─> Show all 14 permanent upgrades
                  │
                  ├─> ChurchSystem.PurchaseUpgrade(player, upgradeID)
                  │   ├─> Spend Souls (exponential cost: 10, 25, 62...)
                  │   ├─> PlayerStats:PurchaseUpgrade(upgradeID)
                  │   └─> PlayerStats:RefreshStats()
                  │
                  ├─> Upgrades apply to ALL future weapons
                  │
                  └─> Start new run with permanent bonuses
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│              FLOOR 666 CLEARED (VICTORY)                     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  └─> DeathHandler.OnRunComplete(playerStats)
                      └─> Return to Church with all progress intact
```

---

## Module Details

### **1. WeaponGenerator.lua** - Weapon Orchestrator

**Primary Role:** Entry point for all weapon generation

**Key Functions:**
- `GenerateWeapon(level, weaponType, manufacturerName, rarityName)` - Main generation
- `GenerateWeapons(count, level, ...)` - Batch generation
- `GenerateWeaponFromSeed(seed, level, ...)` - Deterministic generation
- `GetWeaponDescription(weapon)` - Formatted display
- `SetSeed(seed)` - Control RNG

**Controls:**
- Rarity selection (weighted drop rates)
- Manufacturer selection
- Weapon type selection
- Part selection (Bodies → Barrels → Grips → Stocks → Magazines → Sights)
- Accessory rolling (rarity-dependent: 0% Common, 30% Uncommon, 50% Rare, 100% Epic+)
- Element assignment (manufacturer & rarity rules)
- Final stat calculation (via WeaponStats)
- Prefix and name generation

**Output:** Complete weapon object with Name, Type, Rarity, Manufacturer, Level, Element, Parts, Stats, DPS, Mechanics

---

### **2. WeaponStats.lua** - Stat Calculator

**Primary Role:** All stat calculations and weapon comparisons

**Key Functions:**
- `CalculateStats(body, barrel, grip, stock, magazine, sight, accessory, manufacturer, rarity, element, level)`
- `CalculateDPS(stats)` - DPS with crit and elemental factors
- `GetStatGrade(statName, value)` - Letter grades (F-S)
- `CompareWeapons(weapon1, weapon2)` - Determine better weapon

**Controls:**
- Base stat initialization from weapon types
- Part modifier application (multiplicative: Damage, FireRate, Accuracy, etc.)
- Manufacturer modifier application
- Level scaling: `BaseStat × (1.13^(level-1))`
- Rarity bonuses: Each tier ≈ 2 levels of damage
- Element effects (DOT, multipliers)
- DPS formula: `BaseDPS × (1 + CritChance × (CritMult - 1)) × Pellets + ElementalDPS`

**Formulas:**
- **Level Scaling:** 1.13× per level (BL2-accurate)
- **Rarity Damage:** Common 1.0×, Uncommon 1.15×, Rare 1.35×, Epic 1.6×, Legendary 2.0×, Mythic 2.5×
- **DPS:** Damage × FireRate × (Crit factor) × Pellets + Elemental DPS

---

### **3. WeaponConfig.lua** - Game Balance Database

**Primary Role:** Central configuration for all weapon mechanics

**Defines:**

#### **Rarities (6 tiers)**
- Drop rates: Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 0.9%, Mythic 0.1%
- Damage multipliers: 1.0× → 2.5×
- Accessory rules: Common never, Uncommon 30%, Rare 50%, Epic+ always

#### **Manufacturers (7 Gothic-themed)**
1. **Heretic's Forge** (Bandit) - Large magazines, poor accuracy
2. **Inquisition Arms** (Dahl) - Burst-fire, accurate
3. **Divine Instruments** (Hyperion) - Reverse recoil
4. **Gravestone & Sons** (Jakobs) - High damage, semi-auto, no elements
5. **Hellforge** (Maliwan) - Always elemental, lower base damage
6. **Wraith Industries** (Tediore) - Throw on reload
7. **Apocalypse Armaments** (Torgue) - Always explosive, highest damage

#### **Elements (5 types)**
- **Hellfire** (Fire) - 3s DOT, vs flesh
- **Stormwrath** (Shock) - 2s DOT, 1.75× vs shields
- **Plague** (Corrosive) - 4s DOT, 1.75× vs armor
- **Apocalyptic** (Explosive) - Splash damage
- **Curse** - Doubles damage taken

#### **Weapon Types (5 classes)**
- Pistol, Rifle, Shotgun, SMG, Sniper (each with base stats)

#### **Constants**
- `LEVEL_SCALE_MULTIPLIER = 1.13`

---

### **4. WeaponParts Modules** (7 files)

| Part | Affects | Examples |
|------|---------|----------|
| **Bodies** | Weapon type, base frame | Revenant Frame, Quicksilver Frame |
| **Barrels** | Damage, accuracy, range, fire rate | Cathedral Long Barrel, Profane Short Barrel |
| **Grips** | Recoil, handling, ADS speed | Bone-Carved Grip, Iron Maiden Grip |
| **Stocks** | Stability, accuracy, movement | Tombstone Heavy Stock, No Stock |
| **Magazines** | Capacity, reload speed | Charnel House Drum, Crypt Compact Magazine |
| **Sights** | Accuracy, zoom, crit bonuses | Oracle's Scope, Spirit Reflex Sight |
| **Accessories** | Special bonuses, prefix priority | Cursed Bayonet, Tombstone Foregrip |

**All parts include:**
- Stat modifiers (multiplicative or additive)
- Level requirements
- Gothic-themed names and descriptions

---

### **5. DungeonConfig.lua** - Dungeon Balance Database

**Primary Role:** Configuration for dungeon generation and progression

**Defines:**

#### **Dungeon Structure**
- `MAX_FLOORS = 666` (very Gothic!)
- Linear difficulty scaling: Floor 10 = Level 10 enemies
- Enemy density increases per floor
- Boss floors every 10 floors (10, 20, 30...)

#### **Room Types (5 types)**
- **Church** (Floor 1 only) - Safe hub, no enemies
- **Combat** (70%) - Standard rooms, 3-8 enemies
- **Ambush** (15%) - High density, 8-15 enemies
- **Treasure** (10%) - Loot goblins, +50% rare enemy chance
- **Boss** (5% + forced on boss floors) - Single boss

#### **Enemy Types (3 types)**
- **Normal** (70%) - 1.0× health, 25% weapon drop, NO Souls
- **Rare** (25%) - 2.5× health, 50% weapon drop, 75% Soul drop (1-5), +1 rarity
- **Boss** (5%) - 10× health, 100% weapon/Soul drop (10-50 Souls), +2 rarity

#### **Loot Rules**
- Floor 1: NO loot (tutorial/Church)
- Floor 2+: Weapon drops enabled (% chance by enemy type)
- Weapon level = floor number
- Souls only from Rare/Boss enemies

#### **Upgrades (14 permanent)**
- Critical Hit Damage, Elemental Chance/Damage, Fire Rate, Gun Accuracy, Gun Damage
- Grenade Damage, Max Health, Melee Damage, Recoil Reduction, Reload Speed
- Shield Capacity, Shield Recharge Delay, Shield Recharge Rate

**Upgrade Costs:** Exponential (Base × 2.5^level)
- Example: Gun Damage costs 25, 62, 155, 387, 967 Souls for levels 1-5

---

### **6. DungeonGenerator.lua** - Procedural Floor Generator

**Primary Role:** Creates random dungeon floors with rooms and enemy spawns

**Key Functions:**
- `GenerateFloor(floorNumber, seed)` - Generate single floor
- `GenerateChurchFloor()` - Floor 1 special case
- `GenerateRoom(floorNumber, isBossFloor, rareEnemyChance, isLastRoom)` - Room generation
- `GetFloorSummary(floor)` - Display floor info

**Controls:**
- Floor type determination (Church vs standard vs boss)
- Room count calculation (scales with floor)
- Room type selection (weighted random)
- Per-floor rare enemy % variance (10%-80%, "loot goblin floors")
- Enemy count per room (scales with floor difficulty)
- Boss room placement (last room on boss floors)

**Output:** Floor object with FloorNumber, Rooms[], RareEnemyChance, EnemyLevel

---

### **7. EnemySystem.lua** - Enemy Spawner & Stats

**Primary Role:** Enemy creation, stats, and combat

**Key Functions:**
- `SpawnEnemiesForRoom(room, floorNumber)` - Populate room with enemies
- `CreateEnemy(enemyType, level)` - Generate single enemy
- `DamageEnemy(enemy, damage)` - Apply damage and check death
- `RollLoot(enemy, floorNumber)` - Determine loot drops

**Controls:**
- Enemy type selection (Normal/Rare based on room's rare chance)
- Stat scaling by level:
  - Health = 100 × level × type multiplier
  - Damage = 10 × level × type multiplier
- Boss spawning in boss rooms
- Loot drop chances by enemy type

**Output:** Enemy object with ID, Type, Level, Health, Damage, Loot config

---

### **8. LootDropper.lua** - Loot Drop Processor

**Primary Role:** Integrates EnemySystem with WeaponGenerator for loot drops

**Key Functions:**
- `ProcessEnemyDeath(enemy, floorNumber, roomMultiplier)` - Roll and generate loot
- `GenerateWeaponDrop(level, rarityBonus)` - Create weapon with rarity bonus
- `ProcessRoomClear(enemies, floorNumber, roomMultiplier)` - Batch loot processing

**Controls:**
- Soul drop rolling (Rare/Boss only)
- Weapon drop rolling (Floor 2+, % by enemy type)
- Weapon generation via WeaponGenerator
- Rarity upgrades for Rare/Boss enemies:
  - Rare: +1 rarity tier (Common → Uncommon, Rare → Epic)
  - Boss: +2 rarity tiers (Common → Rare, Rare → Legendary)
- Room multipliers (e.g., Treasure rooms = 1.5× Souls)

**Output:** Drops object with Souls, Weapons[], EnemyType, EnemyLevel

---

### **9. PlayerStats.lua** - Persistent Progression Tracker

**Primary Role:** Manages player progression, Souls, upgrades, and run state

**Key Functions:**
- `PlayerStats.new()` - Initialize player
- `AddSouls(amount)` / `SpendSouls(amount)` - Soul management
- `PurchaseUpgrade(upgradeID)` - Buy permanent upgrade
- `AddWeapon(weapon)` / `ClearWeapons()` - Inventory management
- `OnDeath()` - Death handling (clear weapons, persist Souls/upgrades)
- `CalculateStats()` - Base stats + upgrade bonuses

**Controls:**
- Persistent data: Souls, UpgradeLevels, HighestFloorReached, TotalDeaths
- Run data: CurrentFloor, CurrentWeapons, RunKills, RunSouls
- Combat stats: MaxHealth, ShieldCapacity, ShieldRecharge, GunDamage, etc.
- Upgrade application to all stats

**Persistent vs Lost on Death:**
- ✓ **Kept:** Souls, Upgrades, Lifetime stats
- ✗ **Lost:** Weapons, Current floor, Run stats

---

### **10. ChurchSystem.lua** - Upgrade Shop Hub

**Primary Role:** Church interface for purchasing permanent upgrades

**Key Functions:**
- `GetAvailableUpgrades(playerStats)` - List all upgrades with affordability
- `PurchaseUpgrade(playerStats, upgradeID)` - Buy upgrade
- `GetShopSummary(playerStats)` - Display shop interface
- `GetPlayerStatsOverview(playerStats)` - Show current stats with upgrades

**Controls:**
- Upgrade availability display (affordable, locked, maxed)
- Soul spending validation
- Stat bonus formatting (percentages vs flat values)
- Upgrade purchase flow

**Display Format:**
- Grouped by: Affordable → Locked → Maxed
- Shows: Current level, next cost, current bonus, next bonus

---

### **11. DeathHandler.lua** - Death & Victory Processor

**Primary Role:** Handles death mechanics, run completion, and persistence

**Key Functions:**
- `OnPlayerDeath(playerStats)` - Process death, capture run summary
- `OnRunComplete(playerStats)` - Floor 666 cleared (victory)
- `Respawn(playerStats)` - Reset to Church for new run

**Controls:**
- Run summary capture (floor reached, Souls earned, kills, weapons)
- Weapon clearing (all lost on death)
- Floor reset (return to Church/Floor 1)
- Persistence validation (what gets kept vs lost)
- Death/victory messages

**Persistence Rules:**
- **Persistent:** Souls, UpgradeLevels, TotalSoulsEarned, TotalDeaths, HighestFloorReached
- **Lost on Death:** CurrentWeapons, CurrentFloor, RunKills, RunSouls

---

## Integration Guide

### **Weapon System Only (Standalone)**

```lua
local WeaponGenerator = require(src.WeaponGenerator)

-- Generate weapon
local weapon = WeaponGenerator.GenerateWeapon(10, "Rifle")
print(WeaponGenerator.GetWeaponDescription(weapon))
```

### **Full Dungeon + Weapon System**

```lua
-- Initialize player
local player = PlayerStats.new()

-- Generate floor
local floor = DungeonGenerator.GenerateFloor(2)

-- Spawn enemies in room
local room = floor.Rooms[1]
local enemies = EnemySystem.SpawnEnemiesForRoom(room, 2)

-- Combat loop
for _, enemy in ipairs(enemies) do
    -- Damage enemy
    EnemySystem.DamageEnemy(enemy, enemy.MaxHealth)

    -- Process loot
    local drops = LootDropper.ProcessEnemyDeath(enemy, 2)

    if drops then
        player:AddSouls(drops.Souls)

        for _, weapon in ipairs(drops.Weapons) do
            player:AddWeapon(weapon)
        end
    end
end

-- Death handling
if playerDied then
    local deathResult = DeathHandler.OnPlayerDeath(player)
    print(deathResult.Message)
end

-- Church upgrades
if player:GetCurrentFloor() == 1 then
    ChurchSystem.PurchaseUpgrade(player, "GunDamage")
end
```

---

## Summary

**Total Modules:** 17 (10 weapon + 7 dungeon)

**Key Systems:**
1. ✓ Weapon generation (Borderlands 2-accurate)
2. ✓ Dungeon generation (666 floors, procedural)
3. ✓ Enemy spawning (Normal/Rare/Boss)
4. ✓ Loot drops (Weapons Floor 2+, Souls from Rare/Boss)
5. ✓ Persistent progression (Souls, 14 upgrades)
6. ✓ Death mechanics (roguelite: lose weapons, keep upgrades)
7. ✓ Church hub (Floor 1, upgrade shop)

**Ready for:** Full Gothic FPS implementation in Roblox Studio!
