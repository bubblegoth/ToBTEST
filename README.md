# Gothic FPS Weapon Generation System

A Borderlands-inspired procedural weapon generation system for Roblox Studio, designed for a dark Gothic-themed First Person Shooter.

## Features

- **Modular Weapon Parts System**: Weapons are built from 6 component types (Body, Barrel, Grip, Stock, Magazine, Sight)
- **Procedural Generation**: Weapons are automatically generated on the fly with randomized parts
- **Rarity System**: 6 rarity tiers (Common → Mythic) affecting stats and drop rates
- **Gothic Theme**: Dark, atmospheric naming and aesthetics
- **Level-Based Progression**: Parts unlock at different levels
- **Stat Calculation**: Complex stat system with multiplicative modifiers
- **Shared System**: Same weapon generation for players and mobs/enemies

## Quick Start

### Installation

1. Place the `src` folder into your Roblox project's `ReplicatedStorage`
2. Rename the folder to `WeaponSystem`
3. (Optional) Use Rojo to sync the project - see `default.project.json`

### Basic Usage

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

-- Generate a random weapon
local weapon = WeaponGenerator.GenerateWeapon()

-- Generate a weapon for a specific level
local leveledWeapon = WeaponGenerator.GenerateWeapon(15)

-- Generate a specific weapon type
local sniper = WeaponGenerator.GenerateWeapon(20, "Sniper")

-- Get weapon details
print(WeaponGenerator.GetWeaponDescription(weapon))
```

## Weapon Structure

### Generated Weapon Object

```lua
{
    Name = "Unholy Eternal Reaper",           -- Generated Gothic name
    Type = "Rifle",                            -- Weapon type
    Rarity = {...},                            -- Rarity data with color and multipliers
    Level = 15,                                -- Minimum level requirement

    Parts = {                                  -- Individual parts (for visuals)
        Body = {...},
        Barrel = {...},
        Grip = {...},
        Stock = {...},
        Magazine = {...},
        Sight = {...}
    },

    Stats = {                                  -- Final calculated stats
        Damage = 125,
        FireRate = 8.5,
        Accuracy = 0.92,
        Range = 1.4,
        ReloadTime = 2.1,
        MagazineSize = 35,
        RecoilControl = 1.15,
        AimSpeed = 1.05,
        MovementSpeed = 1.0,
        CritChance = 0.15,
        CritDamage = 0.25,
        PelletCount = 1,
        ZoomLevel = 1.8
    },

    DPS = 1062.5,                              -- Calculated damage per second
    GeneratedAt = 1234567890                   -- Timestamp
}
```

## Weapon Types

### Available Types

| Type    | Base Fire Rate | Base Damage | Base Accuracy | Magazine Size | Special        |
|---------|----------------|-------------|---------------|---------------|----------------|
| Pistol  | 3.0 rps        | 15          | 85%           | 12            | Balanced       |
| Rifle   | 6.0 rps        | 25          | 90%           | 30            | Versatile      |
| Shotgun | 1.5 rps        | 60          | 60%           | 8             | 8 Pellets      |
| SMG     | 10.0 rps       | 12          | 75%           | 40            | High fire rate |
| Sniper  | 0.8 rps        | 100         | 98%           | 5             | Precision      |

## Rarity System

### Rarity Tiers

| Rarity    | Color                  | Stat Multiplier | Drop Weight | Bonus Crit | Prefix       |
|-----------|------------------------|-----------------|-------------|------------|--------------|
| Common    | Gray (150,150,150)     | 1.0x            | 50%         | 0%         | -            |
| Uncommon  | Green (100,200,100)    | 1.15x           | 30%         | 2%         | Refined      |
| Rare      | Blue (100,150,255)     | 1.35x           | 15%         | 5%         | Superior     |
| Epic      | Purple (200,100,255)   | 1.6x            | 4%          | 8%         | Cursed       |
| Legendary | Orange (255,180,50)    | 2.0x            | 0.9%        | 12%        | Unholy       |
| Mythic    | Red (255,50,50)        | 2.5x            | 0.1%        | 18%        | Apocalyptic  |

## Weapon Parts

### Part Types and Effects

#### 1. Body (Receiver/Frame)
- **Determines**: Weapon type (Pistol, Rifle, etc.)
- **Affects**: All base stats
- **Examples**: Revenant Frame, Inquisitor Frame, Reaper Frame

#### 2. Barrel
- **Affects**: Damage, Accuracy, Range, Fire Rate
- **Examples**: Cathedral Long Barrel, Hellfire Scorched Barrel, Frozen Soul Barrel

#### 3. Grip
- **Affects**: Accuracy, Recoil Control, Aim Speed
- **Examples**: Bone-Carved Grip, Iron Maiden Grip, Wraith's Touch Grip

#### 4. Stock
- **Affects**: Recoil Control, Accuracy, Aim Speed, Movement Speed
- **Examples**: Cathedral Fixed Stock, Tombstone Heavy Stock, Skeletal Stock

#### 5. Magazine
- **Affects**: Magazine Size, Reload Time, Movement Speed
- **Examples**: Ossuary Extended Magazine, Phantom Quickdraw Magazine, Hellforge Magazine

#### 6. Sight
- **Affects**: Accuracy, Aim Speed, Zoom Level, Range
- **Examples**: Spirit Reflex Sight, Oracle's Scope, Reaper's Precision Scope

### Stat Modifiers

Parts use **multiplicative modifiers**:
- `1.0` = No change
- `> 1.0` = Increase (e.g., `1.2` = +20%)
- `< 1.0` = Decrease (e.g., `0.8` = -20%)

Special stats (CritChance, CritDamage) use **additive modifiers**.

## Advanced Usage

### Deterministic Generation

```lua
-- Generate the same weapon every time with a seed
local weapon = WeaponGenerator.GenerateWeaponFromSeed(12345, 10, "Rifle")
```

### Batch Generation

```lua
-- Generate multiple weapons at once
local weapons = WeaponGenerator.GenerateWeapons(10, 15) -- 10 weapons, level 15
```

### Enemy/Mob Weapons

```lua
-- Generate appropriate weapon for an enemy
local function GiveMobWeapon(mob, mobLevel, mobType)
    local weaponType = mobType == "Sniper" and "Sniper" or "Rifle"
    local weapon = WeaponGenerator.GenerateWeapon(mobLevel, weaponType)

    -- Apply weapon to mob (implementation depends on your combat system)
    mob:SetWeapon(weapon)
end
```

### Custom Seed System

```lua
-- Use custom RNG for control
WeaponGenerator.SetSeed(os.time()) -- Time-based randomness
```

## Gothic Name Generation

Weapon names are procedurally generated using:
- **Rarity Prefix**: Higher rarities add prefixes (e.g., "Unholy", "Cursed")
- **Adjective**: Gothic-themed adjectives (e.g., "Eternal", "Forsaken", "Spectral")
- **Noun**: Dark nouns (e.g., "Reaper", "Inquisitor", "Wraith")

**Examples**:
- "Eternal Reaper"
- "Cursed Spectral Punisher"
- "Apocalyptic Ancient Obliterator"

## Integration Examples

### Player Weapon Pickup

```lua
local function OnPlayerPickupWeapon(player, weapon)
    -- Compare with current weapon
    local currentWeapon = player.CurrentWeapon

    if not currentWeapon or weapon.DPS > currentWeapon.DPS then
        print("Better weapon! DPS:", weapon.DPS, "vs", currentWeapon and currentWeapon.DPS or 0)
        player.CurrentWeapon = weapon
    end
end
```

### Loot Drop System

```lua
local function SpawnLootChest(position, level)
    local weapons = WeaponGenerator.GenerateWeapons(3, level)

    -- Sort by rarity
    table.sort(weapons, function(a, b)
        return a.Rarity.DropWeight < b.Rarity.DropWeight
    end)

    -- Display to player
    for i, weapon in ipairs(weapons) do
        print(string.format("%d. %s (%s)", i, weapon.Name, weapon.Rarity.Name))
    end
end
```

### Enemy Wave System

```lua
local function SpawnEnemyWithWeapon(enemyType, level, position)
    -- Create enemy
    local enemy = CreateEnemy(enemyType, position)

    -- Generate and equip weapon
    local weapon = WeaponGenerator.GenerateWeapon(level)
    enemy:EquipWeapon(weapon)

    -- Enemy drops weapon on death (30% chance)
    enemy.OnDeath:Connect(function()
        if math.random() < 0.3 then
            DropWeaponPickup(position, weapon)
        end
    end)
end
```

## File Structure

```
ToBTEST/
├── default.project.json          # Rojo project configuration
├── README.md                      # This file
├── src/
│   ├── WeaponGenerator.lua        # Main generator module
│   ├── WeaponStats.lua            # Stat calculation system
│   ├── WeaponConfig.lua           # Configuration and rarities
│   └── WeaponParts/
│       ├── Bodies.lua             # Body/receiver parts
│       ├── Barrels.lua            # Barrel parts
│       ├── Grips.lua              # Grip parts
│       ├── Stocks.lua             # Stock parts
│       ├── Magazines.lua          # Magazine parts
│       └── Sights.lua             # Sight parts
└── examples/
    ├── BasicUsage.lua             # Basic usage examples
    └── MobWeapons.lua             # Mob/enemy weapon examples
```

## Extending the System

### Adding New Parts

1. Open the relevant part file (e.g., `Barrels.lua`)
2. Add a new part entry:

```lua
{
    Id = "BARREL_CUSTOM_NAME",
    Name = "My Custom Barrel",
    StatModifiers = {
        Damage = 1.2,
        Accuracy = 1.1,
        Range = 1.3
    },
    MinLevel = 10,
    Description = "A powerful custom barrel"
}
```

### Adding New Weapon Types

1. Open `WeaponConfig.lua`
2. Add to `WeaponConfig.WeaponTypes`:

```lua
HeavyMG = {
    Name = "Heavy MG",
    BaseFireRate = 12,
    BaseDamage = 18,
    BaseAccuracy = 0.7,
    BaseReloadTime = 4,
    BaseMagazineSize = 100
}
```

3. Create body parts with `Type = "HeavyMG"` in `Bodies.lua`

### Modifying Rarities

Edit `WeaponConfig.lua` to adjust rarity properties:

```lua
Legendary = {
    Name = "Legendary",
    Color = Color3.fromRGB(255, 180, 50),
    StatMultiplier = 2.5,        -- Change multiplier
    DropWeight = 2.0,             -- Increase drop rate
    NamePrefix = "Legendary"      -- Change prefix
}
```

## Performance Notes

- Weapon generation is **very fast** (< 1ms per weapon)
- Safe to generate weapons on demand (player pickup, enemy spawn, loot drops)
- Consider caching enemy weapons if spawning thousands of identical enemies
- Part filtering by level is optimized for performance

## Future Enhancements

Potential additions to the system:
- Weapon attachments/modifications
- Unique legendary effects (special abilities)
- Elemental damage types (Fire, Ice, Lightning, Holy, Unholy)
- Weapon skin/visual customization
- Weapon crafting/upgrading system
- Set bonuses for matching parts
- Weapon enchantments

## Credits

Created for a dark Gothic-themed FPS in Roblox Studio, inspired by:
- **Borderlands** - Modular weapon part system
- **Diablo** - Loot rarity and stat systems
- **Dark Gothic Aesthetic** - Naming and theme

## License

Feel free to use and modify this system for your Roblox projects!
