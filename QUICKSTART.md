# Quick Start Guide

Get the weapon generation system up and running in 5 minutes!

## Step 1: Installation

1. Copy the `src` folder into your Roblox project's `ReplicatedStorage`
2. Rename it to `WeaponSystem`

Your hierarchy should look like:
```
ReplicatedStorage
└── WeaponSystem
    ├── WeaponGenerator
    ├── WeaponStats
    ├── WeaponConfig
    └── WeaponParts
        ├── Bodies
        ├── Barrels
        ├── Grips
        ├── Stocks
        ├── Magazines
        └── Sights
```

## Step 2: Generate Your First Weapon

Create a `Script` in `ServerScriptService`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

-- Generate a weapon
local weapon = WeaponGenerator.GenerateWeapon()

-- Print weapon details
print(WeaponGenerator.GetWeaponDescription(weapon))
```

Run your game and check the Output - you should see a weapon description!

## Step 3: Generate Weapons for Different Levels

```lua
-- Level 1 pistol (starter weapon)
local starterWeapon = WeaponGenerator.GenerateWeapon(1, "Pistol")

-- Level 10 random weapon
local midGameWeapon = WeaponGenerator.GenerateWeapon(10)

-- Level 20 sniper rifle (endgame)
local endGameSniper = WeaponGenerator.GenerateWeapon(20, "Sniper")

-- Print them all
for _, w in ipairs({starterWeapon, midGameWeapon, endGameSniper}) do
    print(WeaponGenerator.GetWeaponDescription(w))
    print("\n---\n")
end
```

## Step 4: Using Weapon Data

Access the generated weapon's properties:

```lua
local weapon = WeaponGenerator.GenerateWeapon(15)

-- Basic info
print("Name:", weapon.Name)                    -- "Cursed Eternal Reaper"
print("Type:", weapon.Type)                    -- "Rifle"
print("Rarity:", weapon.Rarity.Name)           -- "Epic"
print("Color:", weapon.Rarity.Color)           -- Color3 for UI

-- Combat stats
print("Damage:", weapon.Stats.Damage)          -- 87
print("Fire Rate:", weapon.Stats.FireRate)     -- 9.2 rounds/sec
print("DPS:", weapon.DPS)                      -- 800.4
print("Accuracy:", weapon.Stats.Accuracy)      -- 0.89 (89%)
print("Magazine:", weapon.Stats.MagazineSize)  -- 42 rounds
print("Reload:", weapon.Stats.ReloadTime)      -- 2.3 seconds

-- Special stats
print("Crit Chance:", weapon.Stats.CritChance * 100 .. "%")    -- 12%
print("Crit Damage:", weapon.Stats.CritDamage * 100 .. "%")    -- 25%

-- Parts (for building 3D models)
print("Body:", weapon.Parts.Body.Name)
print("Barrel:", weapon.Parts.Barrel.Name)
-- etc...
```

## Step 5: Generate Loot Drops

Create weapon drops for enemies:

```lua
local function OnEnemyDeath(enemyLevel, dropPosition)
    -- 40% chance to drop a weapon
    if math.random() < 0.4 then
        local weapon = WeaponGenerator.GenerateWeapon(enemyLevel)

        print("Enemy dropped:", weapon.Name)
        print("Rarity:", weapon.Rarity.Name)
        print("DPS:", weapon.DPS)

        -- Spawn weapon pickup at position (you implement this)
        SpawnWeaponPickup(dropPosition, weapon)
    end
end
```

## Next Steps

### For Player Weapons
- See `examples/BasicUsage.lua` for more generation options
- See `examples/VisualWeaponBuilder.lua` for creating 3D weapon models
- Integrate with your FPS system using weapon.Stats

### For Enemy Weapons
- See `examples/MobWeapons.lua` for enemy weapon generation
- Enemies can use the same weapon.Stats for their attacks
- Scale enemy weapons by level for progression

### Customization
- Read `README.md` for full documentation
- Edit part files in `WeaponParts/` to add new parts
- Modify `WeaponConfig.lua` to adjust rarities and weapon types
- Add your own Gothic names in `WeaponConfig.GothicNames`

## Common Patterns

### Compare Weapons (which is better?)
```lua
local currentWeapon = player.CurrentWeapon
local newWeapon = WeaponGenerator.GenerateWeapon(playerLevel)

if newWeapon.DPS > currentWeapon.DPS then
    print("New weapon is better!")
    player.CurrentWeapon = newWeapon
end
```

### Generate Boss Loot
```lua
-- Generate 5 weapons and pick the rarest
local weapons = WeaponGenerator.GenerateWeapons(5, bossLevel)
local rarityValues = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6}

table.sort(weapons, function(a, b)
    return rarityValues[a.Rarity.Name] > rarityValues[b.Rarity.Name]
end)

local bossLoot = weapons[1] -- The rarest weapon
```

### Display Weapon in UI
```lua
local function ShowWeaponInUI(weapon, frame)
    frame.WeaponName.Text = weapon.Name
    frame.WeaponName.TextColor3 = weapon.Rarity.Color

    frame.DamageLabel.Text = "Damage: " .. weapon.Stats.Damage
    frame.FireRateLabel.Text = "Fire Rate: " .. weapon.Stats.FireRate
    frame.DPSLabel.Text = "DPS: " .. math.floor(weapon.DPS)

    -- Create rarity border
    frame.BorderColor3 = weapon.Rarity.Color
end
```

## Testing

Run these tests to verify everything works:

```lua
-- Test 1: Generate 100 weapons and check rarities
local rarityCount = {}
for i = 1, 100 do
    local weapon = WeaponGenerator.GenerateWeapon(10)
    local rarity = weapon.Rarity.Name
    rarityCount[rarity] = (rarityCount[rarity] or 0) + 1
end

print("Rarity Distribution:")
for rarity, count in pairs(rarityCount) do
    print(string.format("  %s: %d%%", rarity, count))
end

-- Test 2: Verify all weapon types work
local types = {"Pistol", "Rifle", "Shotgun", "SMG", "Sniper"}
for _, weaponType in ipairs(types) do
    local weapon = WeaponGenerator.GenerateWeapon(10, weaponType)
    print(weaponType, "✓", weapon.Name)
end

-- Test 3: Verify level scaling
for level = 1, 20, 5 do
    local weapon = WeaponGenerator.GenerateWeapon(level)
    print(string.format("Level %d: %s (DPS: %.1f)", level, weapon.Name, weapon.DPS))
end
```

## Need Help?

- Check `README.md` for full documentation
- Look at files in `examples/` folder for more code samples
- All weapons are automatically balanced - no manual tuning needed!

Happy weapon generating! 🔫
