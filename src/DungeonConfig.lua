--[[
	DungeonConfig.lua
	Configuration for dungeon generation, enemy spawning, loot drops, and progression
	Part of the Gothic FPS Roguelite Dungeon System
]]

local DungeonConfig = {}

-- ============================================================
-- DUNGEON STRUCTURE
-- ============================================================

DungeonConfig.MAX_FLOORS = 666 -- Maximum dungeon depth (very Gothic!)
DungeonConfig.STARTING_FLOOR = 0 -- Church/Hub floor (Floor 0 - no combat, no loot)

-- Floor difficulty scaling (linear)
DungeonConfig.DIFFICULTY_SCALING = {
	EnemyLevelPerFloor = 1.0, -- Floor 5 = Level 5 enemies
	EnemyDensityBase = 5, -- Base number of enemies per room
	EnemyDensityPerFloor = 0.5, -- Additional enemies per floor (Floor 10 = 10 enemies)
	RoomCountBase = 5, -- Minimum rooms per floor
	RoomCountMax = 15, -- Maximum rooms per floor
	RoomCountPerFloor = 0.1, -- Additional rooms every 10 floors
}

-- Boss floor frequency
DungeonConfig.BOSS_FLOOR_INTERVAL = 10 -- Boss floor every 10 floors (10, 20, 30...)

-- ============================================================
-- ROOM TYPES
-- ============================================================

DungeonConfig.RoomTypes = {
	CHURCH = {
		ID = "Church",
		Description = "Safe hub for purchasing upgrades with Souls (Floor 0 only)",
		AllowedFloors = {0}, -- Only on Floor 0
		IsLootEnabled = false,
		IsSpawnEnabled = false,
		IsSafeZone = true,
		WeaponUsageDisabled = true, -- No weapon usage in Church
	},

	COMBAT = {
		ID = "Combat",
		Description = "Standard combat room with normal and rare enemies",
		SpawnChance = 70, -- 70% of rooms
		MinEnemies = 3,
		MaxEnemies = 8,
		IsLootEnabled = true,
	},

	AMBUSH = {
		ID = "Ambush",
		Description = "High-density combat room with more enemies",
		SpawnChance = 15, -- 15% of rooms
		MinEnemies = 8,
		MaxEnemies = 15,
		EnemyDensityMultiplier = 1.5,
		IsLootEnabled = true,
	},

	TREASURE = {
		ID = "Treasure",
		Description = "Loot goblin room - high rare enemy %, more Souls",
		SpawnChance = 10, -- 10% of rooms
		MinEnemies = 5,
		MaxEnemies = 10,
		RareEnemyChanceBonus = 0.5, -- +50% rare enemy chance
		SoulDropMultiplier = 1.5,
		IsLootEnabled = true,
	},

	BOSS = {
		ID = "Boss",
		Description = "Boss encounter room (every 10 floors)",
		SpawnChance = 5, -- 5% of rooms (also forced on boss floors)
		MinEnemies = 1, -- Just the boss
		MaxEnemies = 1,
		IsBossRoom = true,
		IsLootEnabled = true,
	},
}

-- ============================================================
-- ENEMY CONFIGURATION
-- ============================================================

DungeonConfig.EnemyTypes = {
	NORMAL = {
		ID = "Normal",
		Weight = 70, -- 70% of spawns
		HealthMultiplier = 1.0,
		DamageMultiplier = 1.0,
		SoulDropChance = 0.0, -- Normal enemies don't drop Souls
		WeaponDropChance = 0.25, -- 25% chance to drop weapon (Floor 2+)
	},

	RARE = {
		ID = "Rare",
		Description = "Tougher enemy with Soul drops",
		Weight = 25, -- 25% of spawns (can be modified by room type)
		HealthMultiplier = 2.5,
		DamageMultiplier = 1.5,
		SoulDropChance = 0.75, -- 75% chance to drop Souls
		SoulDropMin = 1,
		SoulDropMax = 5,
		WeaponDropChance = 0.50, -- 50% chance to drop weapon (Floor 2+)
		WeaponRarityBonus = 1, -- +1 rarity tier
	},

	BOSS = {
		ID = "Boss",
		Description = "Boss enemy - guaranteed Soul drops, high weapon chance",
		Weight = 5, -- 5% of spawns (only in boss rooms)
		HealthMultiplier = 10.0,
		DamageMultiplier = 2.0,
		SoulDropChance = 1.0, -- 100% drop Souls
		SoulDropMin = 10,
		SoulDropMax = 50,
		WeaponDropChance = 1.0, -- 100% weapon drop (Floor 2+)
		WeaponRarityBonus = 2, -- +2 rarity tiers
	},
}

-- Per-floor random rare enemy % variance
DungeonConfig.RARE_ENEMY_VARIANCE = {
	MinChance = 0.1, -- 10% minimum rare enemy chance per floor
	MaxChance = 0.8, -- 80% maximum (loot goblin floors!)
}

-- ============================================================
-- LOOT CONFIGURATION
-- ============================================================

DungeonConfig.LootRules = {
	-- No loot on Floor 0 (Church) or Floor 1 (player gets starting pistol)
	WeaponDropsStartFloor = 2, -- Weapon drops from enemies start on Floor 2+

	-- Weapon drop level = floor number
	WeaponLevelMatchesFloor = true,

	-- Soul drops (only from Rare/Boss enemies)
	SoulDropsEnabled = true,
}

-- ============================================================
-- SOUL & UPGRADE ECONOMY
-- ============================================================

-- Permanent upgrades available at the Church
DungeonConfig.Upgrades = {
	{
		ID = "CritDamage",
		Name = "Critical Hit Damage",
		Description = "Increases critical hit damage multiplier",
		BaseCost = 10,
		CostMultiplier = 2.5, -- Exponential: 10, 25, 62, 155, 387...
		BonusPerLevel = 0.1, -- +10% crit damage per level
		MaxLevel = 20,
		StatKey = "CritDamage",
	},
	{
		ID = "ElementalChance",
		Name = "Elemental Effect Chance",
		Description = "Increases chance to proc elemental effects",
		BaseCost = 15,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.05, -- +5% elemental proc chance per level
		MaxLevel = 20,
		StatKey = "ElementalChance",
	},
	{
		ID = "ElementalDamage",
		Name = "Elemental Effect Damage",
		Description = "Increases elemental damage over time",
		BaseCost = 15,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.15, -- +15% elemental damage per level
		MaxLevel = 20,
		StatKey = "ElementalDamage",
	},
	{
		ID = "FireRate",
		Name = "Fire Rate",
		Description = "Increases weapon fire rate",
		BaseCost = 20,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.05, -- +5% fire rate per level
		MaxLevel = 20,
		StatKey = "FireRate",
	},
	{
		ID = "Accuracy",
		Name = "Gun Accuracy",
		Description = "Increases weapon accuracy",
		BaseCost = 10,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.05, -- +5% accuracy per level
		MaxLevel = 20,
		StatKey = "Accuracy",
	},
	{
		ID = "GunDamage",
		Name = "Gun Damage",
		Description = "Increases all weapon damage",
		BaseCost = 25,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.08, -- +8% gun damage per level
		MaxLevel = 20,
		StatKey = "GunDamage",
	},
	{
		ID = "GrenadeDamage",
		Name = "Grenade Damage",
		Description = "Increases grenade and explosive damage",
		BaseCost = 15,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.1, -- +10% grenade damage per level
		MaxLevel = 20,
		StatKey = "GrenadeDamage",
	},
	{
		ID = "MaxHealth",
		Name = "Maximum Health",
		Description = "Increases maximum health pool",
		BaseCost = 20,
		CostMultiplier = 2.5,
		BonusPerLevel = 50, -- +50 max health per level
		MaxLevel = 20,
		StatKey = "MaxHealth",
	},
	{
		ID = "MeleeDamage",
		Name = "Melee Damage",
		Description = "Increases melee attack damage",
		BaseCost = 10,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.15, -- +15% melee damage per level
		MaxLevel = 20,
		StatKey = "MeleeDamage",
	},
	{
		ID = "RecoilReduction",
		Name = "Recoil Reduction",
		Description = "Reduces weapon recoil and kick",
		BaseCost = 15,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.05, -- +5% recoil reduction per level
		MaxLevel = 20,
		StatKey = "RecoilReduction",
	},
	{
		ID = "ReloadSpeed",
		Name = "Reload Speed",
		Description = "Increases weapon reload speed",
		BaseCost = 15,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.05, -- +5% reload speed per level
		MaxLevel = 20,
		StatKey = "ReloadSpeed",
	},
	{
		ID = "ShieldCapacity",
		Name = "Shield Capacity",
		Description = "Increases maximum shield capacity",
		BaseCost = 20,
		CostMultiplier = 2.5,
		BonusPerLevel = 50, -- +50 shield capacity per level
		MaxLevel = 20,
		StatKey = "ShieldCapacity",
	},
	{
		ID = "ShieldRechargeDelay",
		Name = "Shield Recharge Delay",
		Description = "Reduces delay before shield starts recharging",
		BaseCost = 25,
		CostMultiplier = 2.5,
		BonusPerLevel = -0.1, -- -0.1s recharge delay per level
		MaxLevel = 10,
		StatKey = "ShieldRechargeDelay",
	},
	{
		ID = "ShieldRechargeRate",
		Name = "Shield Recharge Rate",
		Description = "Increases shield recharge rate",
		BaseCost = 20,
		CostMultiplier = 2.5,
		BonusPerLevel = 0.1, -- +10% recharge rate per level
		MaxLevel = 20,
		StatKey = "ShieldRechargeRate",
	},
}

-- Helper function to calculate upgrade cost
function DungeonConfig.GetUpgradeCost(upgradeID, currentLevel)
	for _, upgrade in ipairs(DungeonConfig.Upgrades) do
		if upgrade.ID == upgradeID then
			if currentLevel >= upgrade.MaxLevel then
				return nil -- Max level reached
			end
			return math.floor(upgrade.BaseCost * (upgrade.CostMultiplier ^ currentLevel))
		end
	end
	return nil
end

-- ============================================================
-- PLAYER STARTING STATS
-- ============================================================

DungeonConfig.PlayerDefaults = {
	StartingFloor = 0, -- Always start in the Church (Floor 0)
	StartingSouls = 0,
	StartingWeapons = {}, -- No weapons until Floor 1 (given Common Lv1 Pistol)

	BaseStats = {
		MaxHealth = 100,
		ShieldCapacity = 50,
		ShieldRechargeDelay = 3.0, -- Seconds before recharge starts
		ShieldRechargeRate = 10, -- Shield per second
		MovementSpeed = 16, -- Studs per second (Roblox default)
	},
}

return DungeonConfig
