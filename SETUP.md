# Gothic FPS Roguelite - Setup Guide

Complete step-by-step guide for setting up the game in Roblox Studio.

---

## 📁 File Structure

```
ReplicatedStorage/
└── src/
    ├── WeaponGenerator.lua
    ├── WeaponStats.lua
    ├── WeaponConfig.lua
    ├── WeaponParts.lua
    ├── DungeonConfig.lua
    ├── DungeonGenerator.lua
    ├── DungeonInstanceManager.lua
    ├── EnemySystem.lua
    ├── LootDropper.lua
    ├── PlayerStats.lua
    ├── ChurchSystem.lua
    ├── DeathHandler.lua
    ├── StartingWeapon.lua
    ├── NPCGenerator.lua
    ├── NPCConfig.lua
    └── NPCParts.lua

ServerScriptService/
├── ServerInit (Script)
├── PlayerDataManager (Script)
├── PileOfBones (Script) - Place in Bones_Assortment model
└── SoulVendor (Script) - Auto-created by ServerInit

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
   - WeaponGenerator.lua
   - WeaponStats.lua
   - WeaponConfig.lua
   - WeaponParts.lua
   - DungeonConfig.lua
   - DungeonGenerator.lua
   - DungeonInstanceManager.lua
   - EnemySystem.lua
   - LootDropper.lua
   - PlayerStats.lua
   - ChurchSystem.lua
   - DeathHandler.lua
   - StartingWeapon.lua
   - NPCGenerator.lua
   - NPCConfig.lua
   - NPCParts.lua

---

### **Step 2: Set Up Server Scripts**

1. In **ServerScriptService**, create a **Script** (not LocalScript) named `ServerInit`
2. Paste contents of `src/ServerInit.lua` into it
3. Create another **Script** named `PlayerDataManager`
4. Paste contents of `src/PlayerDataManager.lua` into it

**Important:** These must be regular **Scripts**, not **LocalScripts** or **ModuleScripts**.

---

### **Step 3: Set Up Workspace Objects**

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

### **Step 4: Instanced Dungeon System**

This game uses **per-player instanced dungeons** - each player gets their own private dungeon separate from other players.

#### **How It Works:**

1. **Automatic Instance Creation**
   - When a player joins, `PlayerDataManager` automatically creates a dungeon instance for them
   - Instance is stored in `workspace.DungeonInstances.DungeonInstance_[UserId]`
   - Each player's dungeon is completely isolated from other players

2. **Floor Generation**
   - Floors are generated on-demand as players progress
   - Uses unique seed per player for deterministic generation
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

### **Step 5: Test the Setup**

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
   ```

3. When you spawn, you should:
   - Spawn at `ChurchSpawn` (Floor 0)
   - See the Soul Vendor NPC at the `SoulVendor` spawn point
   - Be able to walk to `Bones_Assortment` to enter dungeon

4. **Test teleporter:**
   - Touch/click `Bones_Assortment`
   - You should teleport to `DungeonSpawn` (Floor 1)
   - You should receive a Common Level 1 Pistol
   - Check Output for confirmation messages

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

### **Build 3D Dungeon Geometry**
Create a `DungeonBuilder.lua` module to convert floor data → actual 3D rooms

### **Create Weapon Tools**
Create a `WeaponBuilder.lua` module to convert weapon data → actual Tool objects

### **Add Enemy AI**
Create AI scripts that use EnemySystem and LootDropper for combat/drops

---

## 📚 Documentation

- **README.md** - Project overview and weapon system docs
- **MODULE_REFERENCE.md** - Complete module documentation
- **QUICKSTART.md** - Quick start guide for weapon generation
- **SETUP.md** - This file (workspace setup)

---

## ✅ Summary

Once setup is complete, your game will have:
- ✅ Procedural weapon generation (Borderlands-style)
- ✅ 666-floor dungeon system
- ✅ **Per-player instanced dungeons** (single-player experience)
- ✅ Soul Vendor NPC (auto-generated)
- ✅ Player progression (Souls, upgrades)
- ✅ Death mechanics (roguelite)
- ✅ Church hub (Floor 0)
- ✅ Dungeon entry teleporter
- ✅ Automatic instance creation/cleanup

**Everything works together automatically!**
