# Gothic FPS Roguelite - Setup Guide

Complete step-by-step guide for setting up the game in Roblox Studio.

---

## 📁 File Structure

```
ReplicatedStorage/
└── src/
    ├── WeaponGenerator.lua (ENHANCED)
    ├── WeaponStats.lua
    ├── WeaponConfig.lua
    ├── WeaponParts.lua (ENHANCED - All parts in one file)
    ├── WeaponModelBuilder.lua (NEW - Builds 3D weapon models)
    ├── WeaponToolBuilder.lua (NEW - Creates functional weapon Tools)
    ├── ModularLootGen.lua (NEW - Visual weapon drops)
    ├── Combat.lua (NEW - Damage & combat system)
    ├── ServerDamageHandler.lua (NEW - Server damage processing)
    ├── DungeonConfig.lua
    ├── DungeonGenerator.lua
    ├── DungeonInstanceManager.lua (UPDATED - Enemy spawning)
    ├── MazeDungeonGenerator.lua (NEW - Builds 3D dungeon geometry)
    ├── MobGenerator.lua (NEW - Procedural enemy generation)
    ├── EnemySpawner.lua (NEW - Spawns enemies in instances)
    ├── EnemyDeathHandler.lua (NEW - Death/loot/cleanup)
    ├── ShieldParts.lua (NEW - Shield part manufacturers)
    ├── ShieldGenerator.lua (NEW - Procedural shield generation)
    ├── EnemySystem.lua
    ├── LootDropper.lua (UPDATED - Now uses ModularLootGen)
    ├── PlayerStats.lua
    ├── ChurchSystem.lua
    ├── DeathHandler.lua
    ├── StartingWeapon.lua
    ├── NPCGenerator.lua
    ├── NPCConfig.lua
    └── NPCParts.lua

ServerScriptService/
└── server/
    ├── ServerInit (Script)
    ├── PlayerDataManager (Script)
    ├── ServerDamageHandler (Script)
    ├── PlayerHealthHandler (Script) - NEW - Shield & health management
    ├── EnemyAIManager (Script) - NEW - DOOM-style AI system
    ├── PileOfBones (Script) - Place in Bones_Assortment model
    └── SoulVendor (Script) - Auto-created by ServerInit

StarterPlayer/
└── StarterCharacterScripts/
    └── ProjectileShooter (LocalScript) - Handles weapon shooting

Workspace/
├── Church (Model) - Your existing Church model
├── Bones_Assortment (Model/Part) - Teleporter to dungeon
├── SoulVendor (Part) - Spawn point for vendor NPC
├── ChurchSpawn (SpawnLocation or Part) - Player spawn point
└── DungeonSpawn (Part) - Floor 1 spawn under map
```

---

## 🎯 Step-by-Step Setup

### **Step 1: Import Modules to ReplicatedStorage**

1. Open Roblox Studio
2. Create a folder in **ReplicatedStorage** named `src`
3. Copy all files from `/src/` into `ReplicatedStorage.src/`:
   - WeaponGenerator.lua (ENHANCED)
   - WeaponStats.lua
   - WeaponConfig.lua
   - WeaponParts.lua (ENHANCED)
   - WeaponModelBuilder.lua (NEW)
   - WeaponToolBuilder.lua (NEW)
   - ModularLootGen.lua (NEW)
   - Combat.lua (NEW)
   - ServerDamageHandler.lua (NEW)
   - DungeonConfig.lua
   - DungeonGenerator.lua
   - DungeonInstanceManager.lua (UPDATED)
   - MazeDungeonGenerator.lua (NEW)
   - MobGenerator.lua (NEW)
   - EnemySpawner.lua (NEW)
   - EnemyDeathHandler.lua (NEW)
   - ShieldParts.lua (NEW)
   - ShieldGenerator.lua (NEW)
   - EnemySystem.lua
   - LootDropper.lua (UPDATED)
   - PlayerStats.lua
   - ChurchSystem.lua
   - DeathHandler.lua
   - StartingWeapon.lua
   - NPCGenerator.lua
   - NPCConfig.lua
   - NPCParts.lua

---

### **Step 2: Set Up Server Scripts**

1. In **ServerScriptService**, create a folder named `server`
2. Copy all files from `/server/` into `ServerScriptService.server/`:
   - ServerInit.lua (Script)
   - PlayerDataManager.lua (Script)
   - ServerDamageHandler.lua (Script)
   - PlayerHealthHandler.lua (Script) - Shield & health management
   - EnemyAIManager.lua (Script) - DOOM-style AI for enemies
   - PileOfBones.lua (Script) - Place in Bones_Assortment model

**Important:** These must be regular **Scripts**, not **LocalScripts** or **ModuleScripts**.

---

### **Step 3: Set Up Client Scripts**

1. In **StarterPlayer**, expand **StarterCharacterScripts**
2. Create a **LocalScript** (not Script) named `ProjectileShooter`
3. Paste contents of `client/ProjectileShooter.lua` into it

**Important:** This must be a **LocalScript** in **StarterCharacterScripts** so it runs for each player.

**What this does:**
- Handles weapon shooting with projectile ballistics
- Creates physical bullets with travel time and bullet drop
- Reads weapon stats from equipped Tools
- Manages ammo and reloading
- Sends hit detection to server

---

### **Step 4: Set Up Workspace Objects**

#### **A. Church (Your existing model)**
- Should already exist in workspace
- No changes needed

#### **B. Soul Vendor Spawn Point**
1. Create a **Part** in workspace
2. Name it exactly: `SoulVendor`
3. Position it where you want the vendor NPC to stand in the Church
4. Make it invisible: Set `Transparency = 1`
5. Set `CanCollide = false`
6. **Important:** This is just a spawn marker, the NPC will be auto-generated

#### **C. Bones_Assortment (Teleporter)**
1. Your existing `Bones_Assortment` model/part should already be in workspace
2. Inside `Bones_Assortment`, add a **Script** (not LocalScript)
3. Paste contents of `src/PileOfBones.lua` into it

#### **D. Church Spawn (Player Spawn Point)**
1. Create a **Part** or **SpawnLocation** in workspace
2. Name it exactly: `ChurchSpawn`
3. Position it where players should spawn in the Church (Floor 0)
4. If using Part: Set `Transparency = 1`, `CanCollide = false`
5. If using SpawnLocation: Set Team to Neutral

#### **E. Dungeon Spawn (Floor 1 Starting Point)**
1. Create a **Part** in workspace
2. Name it exactly: `DungeonSpawn`
3. Position it **under the map** (where Floor 1 dungeon starts)
4. Make it invisible: Set `Transparency = 1`
5. Set `CanCollide = false`

---

### **Step 5: Instanced Dungeon System**

This game uses **per-player instanced dungeons** - each player gets their own private dungeon separate from other players.

#### **How It Works:**

1. **Automatic Instance Creation**
   - When a player joins, `PlayerDataManager` automatically creates a dungeon instance for them
   - Instance is stored in `workspace.DungeonInstances.DungeonInstance_[UserId]`
   - Each player's dungeon is completely isolated from other players

2. **Floor Generation**
   - Floors are generated on-demand as players progress
   - Uses unique seed per player for deterministic generation
   - **MazeDungeonGenerator** builds actual 3D geometry (walls, floors, ceilings, lighting)
   - Uses recursive backtracker algorithm for guaranteed connectivity
   - Automatically carves rooms into maze for interesting layouts
   - Floors are cached for performance (won't regenerate if player returns)

3. **Teleportation**
   - `PileOfBones` uses `DungeonInstanceManager.TeleportToFloor(player, floorNumber)`
   - Floor 0 (Church) is shared by all players
   - Floors 1-666 are private to each player

4. **Cleanup**
   - When a player leaves, their dungeon instance is automatically destroyed
   - Prevents memory leaks and clutter in workspace

#### **Instance Folder Structure:**

```
Workspace/
├── Church (Shared)
├── ChurchSpawn (Shared)
├── Bones_Assortment (Shared)
├── SoulVendor (Shared)
└── DungeonInstances/ (Auto-created)
    ├── DungeonInstance_123456 (Player 1's dungeon)
    ├── DungeonInstance_789012 (Player 2's dungeon)
    └── ...
```

**Note:** You don't need to create the `DungeonInstances` folder - it's created automatically by `DungeonInstanceManager`.

---

### **Step 6: Test the Setup**

1. Click **Play** in Studio
2. **Check Output for**:
   ```
   [ServerInit] Initializing game systems...
   [ServerInit] Generating Soul Vendor NPC...
   [ServerInit] Soul Vendor spawned successfully: Soul Keeper
   [ServerInit] Game initialization complete!
   [PlayerDataManager] Loading...
   [PlayerDataManager] Ready!
   [DungeonInstanceManager] Created DungeonInstances folder in workspace
   [PlayerDataManager] Player joined: [YourName]
   [DungeonInstanceManager] Creating dungeon instance for [YourName]
   [DungeonInstanceManager] Instance created: DungeonInstance_[UserId]
   [PlayerDataManager] Player data initialized for [YourName]
   [ServerDamageHandler] Initialized
   [ProjectileShooter] Initialized - Ready to shoot!
   ```

3. When you spawn, you should:
   - Spawn at `ChurchSpawn` (Floor 0)
   - See the Soul Vendor NPC at the `SoulVendor` spawn point
   - Be able to walk to `Bones_Assortment` to enter dungeon

4. **Test teleporter:**
   - Touch/click `Bones_Assortment`
   - You should teleport to Floor 1 with **actual 3D dungeon geometry**
   - You should see maze corridors, rooms, walls, floors, and lighting
   - You should see **procedurally generated enemies** spawned in rooms!
   - You should receive a Common Level 1 Pistol
   - Check Output for:
     ```
     [MazeDungeon] Generating maze dungeon...
     [MazeDungeon] ✓ Dungeon complete!
     [EnemySpawner] Spawning enemies for floor 1...
     [MobGenerator] Created 'Dark Fiend Lv.1': HP=115, SPD=16, DMG=12...
     [EnemySpawner] ✓ Spawned 8 enemies (0 bosses) for floor 1
     [DungeonInstanceManager] ✓ Floor 1 ready for [YourName] (8 enemies spawned)
     [PileOfBones] YourName entered Floor 1 - The Dungeon Begins
     ```

5. **Test shooting enemies:**
   - Left-click to shoot (hold for automatic)
   - Enemies will have varied appearances (different body parts)
   - When enemy dies, you'll see fade-out effect
   - 40% chance to drop a weapon (glowing pickup)
   - Check Output for death messages

---

## 🔧 Troubleshooting

### **Problem: "PlayerStats not found" error**

**Cause:** PlayerDataManager isn't running

**Fix:**
1. Make sure `PlayerDataManager` is a **Script** (not LocalScript)
2. Make sure it's in **ServerScriptService**
3. Check Output for "[PlayerDataManager] Ready!" message

---

### **Problem: Soul Vendor doesn't spawn**

**Cause:** SoulVendor spawn point not found or misnamed

**Fix:**
1. Check workspace for a Part named exactly `SoulVendor` (case-sensitive)
2. Check Output for "[ServerInit] SoulVendor spawn point not found"
3. If missing, vendor spawns at (0, 5, 0) by default

---

### **Problem: Player spawns at wrong location**

**Cause:** ChurchSpawn not found

**Fix:**
1. Check workspace for a Part/SpawnLocation named exactly `ChurchSpawn`
2. Make sure it's positioned in the Church (Floor 0)
3. If missing, player spawns at (0, 10, 0) by default

---

### **Problem: Teleporter doesn't work**

**Cause:** PileOfBones script not attached correctly

**Fix:**
1. Make sure the **Script** is **inside** the Bones_Assortment model/part
2. Make sure it's a regular **Script**, not a LocalScript
3. Check that script.Parent correctly references the clickable part

---

### **Problem: "Module not found" errors**

**Cause:** Modules not in correct location

**Fix:**
1. All modules must be in `ReplicatedStorage.src/`
2. Check spelling and capitalization (Lua is case-sensitive)
3. Verify folder structure matches Step 1

---

## 🎮 Testing Checklist

- [ ] Soul Vendor NPC spawns in Church
- [ ] Player spawns at ChurchSpawn
- [ ] Can interact with/see Soul Vendor
- [ ] Bones_Assortment teleports player
- [ ] Player receives Common Lv1 Pistol on Floor 1
- [ ] Floor number updates (check Output)
- [ ] No errors in Output window

---

## 🚀 Next Steps (Optional)

### **Enable DataStore Persistence**
Uncomment the DataStore code in `PlayerDataManager.lua` (lines with `-- TODO`)

### **Create Death Screen UI**
Hook into `OnPlayerDeath` function in PlayerDataManager

### **Integrate Enemy AI with Damage System**
Connect EnemyAI attacks to PlayerHealthHandler for player damage

### **Create HUD for Shields**
Add shield bar to UI showing current shield HP and recharge status

### **Build HUD/UI**
Create ScreenGui for health bar, ammo counter, floor number, souls display

### **Floor Progression System**
Add way to advance floors (portal after clearing all enemies?)

---

## 📚 Documentation

- **README.md** - Project overview and weapon system docs
- **MODULE_REFERENCE.md** - Complete module documentation
- **QUICKSTART.md** - Quick start guide for weapon generation
- **SETUP.md** - This file (workspace setup)

---

## ✅ Summary

Once setup is complete, your game will have:
- ✅ **Enhanced procedural weapon generation** (Borderlands-style with 7 part types)
- ✅ **3D weapon models** (Auto-built from weapon data with manufacturer theming)
- ✅ **Visual weapon drops** (Floating weapons with rarity-colored beams)
- ✅ **Projectile-based shooting system** (Physical bullets with ballistics)
- ✅ **Combat system** (Damage calculation, elemental effects, status effects)
- ✅ **3D dungeon geometry** (Maze-based with rooms, lighting, spawn points)
- ✅ **Procedural enemy generation** (Mix-and-match body parts, varied stats)
- ✅ **Automatic enemy spawning** (Per-player instances, scaled by floor)
- ✅ **Enemy death handling** (Loot drops, fade effects, cleanup)
- ✅ **DOOM-style enemy AI** (Attack tokens, optimal positioning, flanking)
- ✅ **Procedural shield generation** (4 parts, 7 manufacturers, special effects)
- ✅ **Shield system** (Recharge mechanics, break effects, visual feedback)
- ✅ 666-floor dungeon system
- ✅ **Per-player instanced dungeons** (single-player experience)
- ✅ Soul Vendor NPC (auto-generated)
- ✅ Player progression (Souls, upgrades, weapon inventory)
- ✅ Death mechanics (roguelite)
- ✅ Church hub (Floor 0)
- ✅ Dungeon entry teleporter
- ✅ Automatic instance creation/cleanup

**Core Features:**
- 🎨 Procedural 3D weapon models with gothic theming
- 💎 Rarity-based loot drops with visual effects
- 🔫 **Projectile ballistics** (bullet drop, travel time, tracers)
- ⚔️ Complete combat system with elemental damage
- 🔥 Status effects (Burn, Freeze, Chain Lightning)
- 🏰 **3D dungeon generation** (maze algorithm with rooms, full geometry)
- 👹 **Procedural enemy generation** (5 head types, 5 torso types, 5 arm types, 5 leg types)
- 🎯 **Enemy variety** (625+ unique combinations, stat-based variations)
- ⚡ **Automatic spawning & scaling** (enemies scale with floor number)
- 💀 **Death handling** (40% loot drop, fade effects, auto-cleanup)
- 🤖 **DOOM-style AI** (max 3 simultaneous attackers, optimal range positioning, flanking)
- 🛡️ **Procedural shields** (4 parts: Capacitor, Generator, Regulator, Projector)
- ⚡ **Shield break effects** (Nova explosion, Frost slow, Fire DOT, Teleport, etc.)
- 🔋 **Shield recharge** (configurable delay and rate per shield)
- 🚪 Per-player instanced dungeons (single-player isolation)
- 📦 Weapon inventory management
- 🎯 Crit chance, lifesteal, and special effects
- 🛡️ Anti-cheat protection (rate limiting, damage validation)
- 🎮 Ammo system with reloading

**Everything works together automatically!**
