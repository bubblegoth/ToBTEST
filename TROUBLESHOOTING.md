# Troubleshooting Guide - Nothing Working, No Errors

This guide will help you fix the "nothing works but no errors" issue.

## Root Cause

**The server scripts are in the wrong location!** Server scripts need to be in `ServerScriptService` as regular **Scripts**, not in `ReplicatedStorage.Modules` as ModuleScripts.

---

## Quick Fix Checklist

### ✅ Step 1: Verify ReplicatedStorage.Modules Setup

In **ReplicatedStorage**, you should have a folder called `Modules` containing these **ModuleScripts**:

**Core Modules (should be ModuleScripts):**
- ChurchSystem.lua
- Combat.lua
- DeathHandler.lua
- DungeonConfig.lua
- DungeonGenerator.lua
- DungeonInstanceManager.lua
- EnemyDeathHandler.lua
- EnemySpawner.lua
- EnemySystem.lua
- LootDropper.lua
- MazeDungeonGenerator.lua
- MobGenerator.lua
- ModularLootGen.lua
- NPCConfig.lua
- NPCGenerator.lua
- NPCParts.lua
- PlayerStats.lua
- ShieldGenerator.lua
- ShieldParts.lua
- StartingWeapon.lua
- WeaponConfig.lua
- WeaponGenerator.lua
- WeaponModelBuilder.lua
- WeaponParts.lua
- WeaponStats.lua
- WeaponToolBuilder.lua

**⚠️ IMPORTANT:** These should all be **ModuleScripts** (blue icon in Roblox Studio).

---

### ✅ Step 2: Move Server Scripts to ServerScriptService

The following scripts need to be **regular Scripts** (NOT ModuleScripts) in **ServerScriptService**:

**From Modules/ folder (currently in wrong location):**
1. **ServerInit.lua** → Move to `ServerScriptService` as a **Script**
2. **PlayerDataManager.lua** → Move to `ServerScriptService` as a **Script**
3. **ServerDamageHandler.lua** → Move to `ServerScriptService` as a **Script**
4. **SoulVendor.lua** → Move to `ServerScriptService` as a **Script** (or this gets auto-created)

**From server/ folder (new files):**
5. **PlayerHealthHandler.lua** → Add to `ServerScriptService` as a **Script**
6. **EnemyAIManager.lua** → Add to `ServerScriptService` as a **Script**

**Special case:**
7. **PileOfBones.lua** → This should be a **Script** inside your `Bones_Assortment` model in Workspace

---

### ✅ Step 3: Verify Workspace Objects

Check that these exist in **Workspace**:

1. **ChurchSpawn** (Part or SpawnLocation) - Where players spawn in Church
2. **SoulVendor** (Part, Transparency=1) - Where NPC vendor spawns
3. **Bones_Assortment** (Model/Part) - Teleporter to dungeon
   - Should contain the **PileOfBones** Script inside it
4. **DungeonSpawn** (Part) - Floor 1 starting point (under map)

---

### ✅ Step 4: Check Client Scripts

In **StarterPlayer → StarterCharacterScripts**:

1. **ProjectileShooter** should be a **LocalScript**

---

## Correct File Structure

```
ReplicatedStorage/
└── Modules/ (Folder)
    └── [25+ ModuleScripts - core game modules]
    ⚠️ NO SERVER SCRIPTS HERE!

ServerScriptService/
├── ServerInit (Script) ⭐ Runs first
├── PlayerDataManager (Script) ⭐ Critical
├── ServerDamageHandler (Script)
├── PlayerHealthHandler (Script) ⭐ NEW
└── EnemyAIManager (Script) ⭐ NEW

Workspace/
├── ChurchSpawn (Part/SpawnLocation)
├── SoulVendor (Part)
├── DungeonSpawn (Part)
└── Bones_Assortment (Model)
    └── PileOfBones (Script) ⭐ Inside the model

StarterPlayer/
└── StarterCharacterScripts/
    └── ProjectileShooter (LocalScript)
```

---

## Step-by-Step Fix

### 1. Open Roblox Studio
### 2. Check Output Window
- Open **View → Output** (or press F9)
- Look for initialization messages

### 3. Fix ServerScriptService

**Delete these from ReplicatedStorage.Modules if they exist:**
- ServerInit
- PlayerDataManager
- ServerDamageHandler
- SoulVendor

**Then create new Scripts in ServerScriptService:**

#### A. Create ServerInit (Script)
1. Right-click **ServerScriptService**
2. Insert Object → **Script** (NOT ModuleScript)
3. Rename to `ServerInit`
4. Paste contents from `Modules/ServerInit.lua`

#### B. Create PlayerDataManager (Script)
1. Right-click **ServerScriptService**
2. Insert Object → **Script**
3. Rename to `PlayerDataManager`
4. Paste contents from `Modules/PlayerDataManager.lua`

#### C. Create ServerDamageHandler (Script)
1. Right-click **ServerScriptService**
2. Insert Object → **Script**
3. Rename to `ServerDamageHandler`
4. Paste contents from `Modules/ServerDamageHandler.lua`

#### D. Create PlayerHealthHandler (Script)
1. Right-click **ServerScriptService**
2. Insert Object → **Script**
3. Rename to `PlayerHealthHandler`
4. Paste contents from `server/PlayerHealthHandler.lua`

#### E. Create EnemyAIManager (Script)
1. Right-click **ServerScriptService**
2. Insert Object → **Script**
3. Rename to `EnemyAIManager`
4. Paste contents from `server/EnemyAIManager.lua`

### 4. Fix PileOfBones

1. Find **Bones_Assortment** in Workspace
2. Right-click it → Insert Object → **Script**
3. Rename to `PileOfBones`
4. Paste contents from `Modules/PileOfBones.lua`
5. **Make sure the script is INSIDE Bones_Assortment, not outside it**

### 5. Test Again

Click **Play** and check Output window for:

```
[ServerInit] Initializing game systems...
[ServerInit] Generating Soul Vendor NPC...
[PlayerDataManager] Loading...
[PlayerDataManager] Ready!
[DungeonInstanceManager] Created DungeonInstances folder in workspace
```

If you see these messages, the systems are running!

---

## Common Issues

### Issue: "module not found" errors

**Cause:** Scripts trying to require from wrong location

**Fix:** Make sure all `require()` statements use `ReplicatedStorage.Modules`:
```lua
local WeaponGenerator = require(game.ReplicatedStorage.Modules.WeaponGenerator)
```

NOT:
```lua
local WeaponGenerator = require(game.ReplicatedStorage.src.WeaponGenerator) -- Wrong!
```

---

### Issue: ServerInit doesn't run

**Symptoms:** No output messages, nothing happens

**Fix:**
1. Check that ServerInit is a **Script** (green icon), not ModuleScript (blue icon)
2. Check that it's in **ServerScriptService**, not ReplicatedStorage
3. Check that it's not disabled (should not be grayed out)

---

### Issue: Soul Vendor doesn't spawn

**Cause:** SoulVendor spawn point missing

**Fix:**
1. Create a Part in Workspace named exactly `SoulVendor`
2. Set Transparency = 1
3. Set CanCollide = false
4. Position where you want vendor to stand

---

### Issue: Teleporter doesn't work

**Cause:** PileOfBones script not inside Bones_Assortment

**Fix:**
1. Make sure PileOfBones is a **Script** (not LocalScript or ModuleScript)
2. Make sure it's **inside** the Bones_Assortment model
3. Make sure it's not disabled

---

### Issue: PlayerHealthHandler not found

**Cause:** New script not added yet

**Fix:**
1. Copy `server/PlayerHealthHandler.lua` content
2. Create new **Script** in ServerScriptService
3. Rename to `PlayerHealthHandler`
4. Paste contents
5. Make sure it calls `PlayerHealthHandler.Initialize()` at the bottom

---

## What Should Happen When Working

### On Game Start:
1. ServerInit runs → Creates Soul Vendor NPC
2. PlayerDataManager runs → Sets up player data tracking
3. ServerDamageHandler runs → Sets up damage validation
4. PlayerHealthHandler runs → Sets up shield/health system
5. EnemyAIManager runs → Sets up AI for enemies

### When Player Joins:
1. Player spawns at ChurchSpawn
2. PlayerDataManager creates dungeon instance for player
3. ProjectileShooter (LocalScript) loads on client

### When Player Touches Bones_Assortment:
1. PileOfBones script runs
2. Teleports player to Floor 1
3. MazeDungeonGenerator creates 3D dungeon
4. EnemySpawner spawns enemies
5. EnemyAIManager attaches AI to enemies
6. Player receives starting weapon

---

## Quick Diagnostic Test

Paste this into **Command Bar** in Studio (View → Command Bar):

```lua
print("=== DIAGNOSTICS ===")
print("Modules folder exists:", game.ReplicatedStorage:FindFirstChild("Modules") ~= nil)
print("ServerInit exists:", game.ServerScriptService:FindFirstChild("ServerInit") ~= nil)
print("PlayerDataManager exists:", game.ServerScriptService:FindFirstChild("PlayerDataManager") ~= nil)
print("ChurchSpawn exists:", workspace:FindFirstChild("ChurchSpawn") ~= nil)
print("===================")
```

Expected output:
```
=== DIAGNOSTICS ===
Modules folder exists: true
ServerInit exists: true
PlayerDataManager exists: true
ChurchSpawn exists: true
===================
```

If any are `false`, that's what needs to be fixed first!

---

## Still Not Working?

1. **Take a screenshot of your Explorer window** showing:
   - ReplicatedStorage.Modules contents
   - ServerScriptService contents
   - Workspace objects

2. **Copy ALL Output window text** after clicking Play

3. **Check these:**
   - Are there any red icons (disabled scripts)?
   - Are there any yellow warning triangles?
   - Is HTTP Requests enabled? (Game Settings → Security → Allow HTTP Requests = ON)

---

## Nuclear Option: Fresh Start

If nothing works, try this complete reset:

1. **Clear ServerScriptService** - Delete everything except the default "Script"
2. **Clear ReplicatedStorage.Modules** - Delete the Modules folder
3. **Follow SETUP.md from Step 1** - Rebuild from scratch
4. **Test after each step** - Verify each system works before moving on

This ensures nothing is misconfigured.
