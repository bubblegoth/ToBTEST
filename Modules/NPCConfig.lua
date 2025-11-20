--[[
	NPCConfig.lua
	Configuration for NPC types, stats, and appearance rules
	Part of the Gothic FPS Roguelite Dungeon System
]]

local NPCConfig = {}

-- ============================================================
-- NPC TYPES
-- ============================================================

NPCConfig.NPCTypes = {
	SOUL_VENDOR = {
		ID = "SoulVendor",
		Name = "Soul Keeper",
		Description = "Ancient vendor who trades in Souls",

		-- Appearance preferences
		PreferredParts = {
			Heads = {"HEAD_CROWNED", "HEAD_HOODED"},
			Torsos = {"TORSO_HOLY_VESTMENTS", "TORSO_ROBES_DARK"},
			Arms = {"ARMS_WRAPPED", "ARMS_SKELETAL"},
			Legs = {"LEGS_ROBED", "LEGS_SKELETAL"},
			Accessories = {"ACC_LANTERN", "ACC_TOME"},
		},

		-- Stats
		Health = 9999, -- Invincible
		WalkSpeed = 0, -- Stationary
		IsHostile = false,
		IsInteractable = true,

		-- Dialogue
		Dialogue = {
			Greeting = "Welcome, lost soul. Spend your Souls wisely...",
			NoSouls = "You have no Souls to offer. Return when you've harvested more.",
			PurchaseSuccess = "Your power grows. May it serve you well in the depths.",
			PurchaseFailed = "You lack the Souls required for this blessing.",
			Farewell = "Go forth into darkness, wanderer.",
		},
	},

	ENEMY_CULTIST = {
		ID = "Cultist",
		Name = "Hollow Cultist",
		Description = "Corrupted worshiper of darkness",

		PreferredParts = {
			Heads = {"HEAD_HOODED", "HEAD_WRAPPED"},
			Torsos = {"TORSO_ROBES_DARK", "TORSO_LEATHER_WORN"},
			Arms = {"ARMS_WRAPPED", "ARMS_SKELETAL"},
			Legs = {"LEGS_ROBED", "LEGS_TATTERED"},
			Accessories = {"ACC_NONE", "ACC_TOME"},
		},

		-- Combat stats (base)
		BaseHealth = 50,
		BaseDamage = 10,
		BaseWalkSpeed = 12,
		BaseAttackSpeed = 1.5,

		-- Scaling per level
		HealthPerLevel = 10,
		DamagePerLevel = 2,

		IsHostile = true,
		IsInteractable = false,

		-- Loot
		SoulDropChance = 0.0,
		WeaponDropChance = 0.25,
	},

	ENEMY_WRAITH = {
		ID = "Wraith",
		Name = "Phantom Wraith",
		Description = "Spectral entity bound to the dungeon",

		PreferredParts = {
			Heads = {"HEAD_SKULL", "HEAD_HOODED"},
			Torsos = {"TORSO_ROBES_DARK", "TORSO_SKELETAL"},
			Arms = {"ARMS_SKELETAL", "ARMS_CLAWED"},
			Legs = {"LEGS_SKELETAL", "LEGS_ROBED"},
			Accessories = {"ACC_CHAINS", "ACC_NONE"},
		},

		BaseHealth = 40,
		BaseDamage = 12,
		BaseWalkSpeed = 16, -- Faster than cultists
		BaseAttackSpeed = 2.0,

		HealthPerLevel = 8,
		DamagePerLevel = 2.5,

		IsHostile = true,
		IsInteractable = false,

		-- Special properties
		Transparency = 0.3, -- Semi-transparent
		CanFly = true,

		SoulDropChance = 0.0,
		WeaponDropChance = 0.25,
	},

	ENEMY_KNIGHT = {
		ID = "Knight",
		Name = "Fallen Knight",
		Description = "Undead warrior clad in rusted armor",

		PreferredParts = {
			Heads = {"HEAD_CROWNED", "HEAD_SKULL"},
			Torsos = {"TORSO_ARMOR_RUSTED", "TORSO_SKELETAL"},
			Arms = {"ARMS_GAUNTLETS", "ARMS_SKELETAL"},
			Legs = {"LEGS_ARMORED", "LEGS_SKELETAL"},
			Accessories = {"ACC_SCYTHE", "ACC_NONE"},
		},

		BaseHealth = 80,
		BaseDamage = 15,
		BaseWalkSpeed = 10, -- Slower, heavy armor
		BaseAttackSpeed = 1.0,

		HealthPerLevel = 15,
		DamagePerLevel = 3,

		IsHostile = true,
		IsInteractable = false,

		SoulDropChance = 0.0,
		WeaponDropChance = 0.30,
	},

	ENEMY_DEMON = {
		ID = "Demon",
		Name = "Lesser Demon",
		Description = "Twisted creature from the abyss",

		PreferredParts = {
			Heads = {"HEAD_HORNED", "HEAD_SKULL"},
			Torsos = {"TORSO_SKELETAL", "TORSO_LEATHER_WORN"},
			Arms = {"ARMS_CLAWED", "ARMS_SKELETAL"},
			Legs = {"LEGS_SKELETAL", "LEGS_TATTERED"},
			Accessories = {"ACC_CHAINS", "ACC_NONE"},
		},

		BaseHealth = 60,
		BaseDamage = 18,
		BaseWalkSpeed = 14,
		BaseAttackSpeed = 1.8,

		HealthPerLevel = 12,
		DamagePerLevel = 3.5,

		IsHostile = true,
		IsInteractable = false,

		SoulDropChance = 0.0,
		WeaponDropChance = 0.25,
	},
}

-- ============================================================
-- NPC SIZE CONFIGURATION
-- ============================================================

NPCConfig.DefaultSize = {
	Head = Vector3.new(2, 1, 1),
	Torso = Vector3.new(2, 2, 1),
	LeftArm = Vector3.new(1, 2, 1),
	RightArm = Vector3.new(1, 2, 1),
	LeftLeg = Vector3.new(1, 2, 1),
	RightLeg = Vector3.new(1, 2, 1),
}

-- ============================================================
-- COLOR THEMES
-- ============================================================

NPCConfig.ColorThemes = {
	GOTHIC = {
		Primary = Color3.fromRGB(40, 40, 50),
		Secondary = Color3.fromRGB(80, 70, 60),
		Accent = Color3.fromRGB(120, 20, 20),
	},
	HOLY = {
		Primary = Color3.fromRGB(200, 190, 180),
		Secondary = Color3.fromRGB(150, 140, 130),
		Accent = Color3.fromRGB(200, 180, 140),
	},
	DEMONIC = {
		Primary = Color3.fromRGB(100, 20, 20),
		Secondary = Color3.fromRGB(80, 30, 30),
		Accent = Color3.fromRGB(200, 50, 50),
	},
	SPECTRAL = {
		Primary = Color3.fromRGB(100, 100, 150),
		Secondary = Color3.fromRGB(120, 120, 180),
		Accent = Color3.fromRGB(150, 200, 255),
	},
}

return NPCConfig
