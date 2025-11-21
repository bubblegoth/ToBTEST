--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponConfig
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Gothic FPS weapon generation configuration (BL2-accurate).
             Defines rarities, manufacturers, weapon types, elemental effects.
             Generation flow: Rarity → Manufacturer → Parts.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local WeaponConfig = {}

-- Rarity definitions (chosen FIRST in BL2 system)
WeaponConfig.Rarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(160, 160, 160),
		DamageBonus = 0, -- Each rarity = ~2 levels of damage
		DropWeight = 50,
		BodyType = 1,
		MaterialType = 1,
		HasAccessory = false, -- White weapons NEVER have accessories
		MinParts = 4,
		MaxParts = 5
	},
	Uncommon = {
		Name = "Uncommon",
		Color = Color3.fromRGB(100, 200, 100),
		DamageBonus = 2, -- +2 levels worth of damage
		DropWeight = 30,
		BodyType = 2,
		MaterialType = 2,
		HasAccessory = "chance", -- 30% chance
		AccessoryChance = 0.3,
		MinParts = 5,
		MaxParts = 6
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(100, 150, 255),
		DamageBonus = 4,
		DropWeight = 15,
		BodyType = 2,
		MaterialType = 3,
		HasAccessory = "chance", -- 50% chance
		AccessoryChance = 0.5,
		MinParts = 5,
		MaxParts = 7
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(190, 90, 255),
		DamageBonus = 6,
		DropWeight = 4,
		BodyType = 3,
		MaterialType = 4,
		HasAccessory = true, -- Purple+ ALWAYS have accessories
		MinParts = 6,
		MaxParts = 7
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 165, 0),
		DamageBonus = 10,
		DropWeight = 0.9,
		BodyType = 4,
		MaterialType = 5,
		HasAccessory = true,
		MinParts = 7,
		MaxParts = 7,
		GuaranteedElement = true
	},
	Mythic = {
		Name = "Mythic",
		Color = Color3.fromRGB(0, 255, 255),
		DamageBonus = 14,
		DropWeight = 0.1,
		BodyType = 4,
		MaterialType = 6,
		HasAccessory = true,
		MinParts = 7,
		MaxParts = 7,
		GuaranteedElement = true,
		BonusStat = 1.15 -- Mythics get 15% bonus to all stats
	}
}

-- Gothic-themed manufacturers (BL2-accurate mechanics)
WeaponConfig.Manufacturers = {
	["Heretics Forge"] = {
		Name = "Heretic's Forge",
		ShortName = "Heretic",
		Theme = "Crude weapons forged by the damned",
		Color = Color3.fromRGB(140, 100, 70),

		-- BL2 Bandit mechanics
		Mechanics = {
			Type = "Bandit",
			Description = "Massive magazines with crude construction"
		},

		StatModifiers = {
			MagazineSize = 1.7, -- 70% larger magazines
			ReloadTime = 1.4,   -- 40% slower reload
			Accuracy = 0.85,    -- Poor accuracy
			Damage = 0.95       -- Slightly lower damage
		},

		ElementalChance = 0.3 -- 30% chance for elemental
	},

	["Inquisition Arms"] = {
		Name = "Inquisition Arms",
		ShortName = "Inquisition",
		Theme = "Precise weapons of holy judgment",
		Color = Color3.fromRGB(180, 180, 200),

		-- BL2 Dahl mechanics
		Mechanics = {
			Type = "Dahl",
			Description = "Burst-fire when aiming, semi/full-auto from hip",
			BurstCount = 3,
			BurstFireRateMultiplier = 1.5
		},

		StatModifiers = {
			Accuracy = 1.1,
			RecoilControl = 1.15,
			Damage = 1.0,
			FireRate = 1.0
		},

		ElementalChance = 0.4
	},

	["Divine Instruments"] = {
		Name = "Divine Instruments",
		ShortName = "Divine",
		Theme = "Blessed weapons that improve as you fire",
		Color = Color3.fromRGB(255, 220, 120),

		-- BL2 Hyperion mechanics
		Mechanics = {
			Type = "Hyperion",
			Description = "Reverse recoil - accuracy improves during sustained fire",
			AccuracyGainPerShot = 0.02,
			MaxAccuracyBonus = 0.3
		},

		StatModifiers = {
			Accuracy = 0.85,  -- Starts poor
			RecoilControl = 0.8, -- Starts with high recoil
			Damage = 1.05,
			FireRate = 1.0
		},

		ElementalChance = 0.5
	},

	["Gravestone & Sons"] = {
		Name = "Gravestone & Sons",
		ShortName = "Gravestone",
		Theme = "Time-tested weapons of great power",
		Color = Color3.fromRGB(120, 90, 60),

		-- BL2 Jakobs mechanics
		Mechanics = {
			Type = "Jakobs",
			Description = "High damage, always semi-automatic, never elemental",
			FireMode = "SemiAuto",
			CanCritRicochet = true
		},

		StatModifiers = {
			Damage = 1.4,      -- Very high damage
			FireRate = 0.7,    -- Slower fire rate
			Accuracy = 1.1,
			RecoilControl = 0.8,
			MagazineSize = 0.7
		},

		ElementalChance = 0 -- NEVER elemental
	},

	["Hellforge"] = {
		Name = "Hellforge",
		ShortName = "Hellforge",
		Theme = "Infernal weapons imbued with dark magic",
		Color = Color3.fromRGB(200, 50, 50),

		-- BL2 Maliwan mechanics
		Mechanics = {
			Type = "Maliwan",
			Description = "Always elemental, sometimes consumes extra ammo",
			AlwaysElemental = true,
			ExtraAmmoChance = 0.3, -- 30% chance to use 2 ammo/shot
			ElementalDamageBonus = 1.3
		},

		StatModifiers = {
			Damage = 0.9,      -- Lower base damage
			ElementalDamage = 1.3, -- But higher elemental
			FireRate = 0.95,
			Accuracy = 1.05
		},

		ElementalChance = 1.0 -- ALWAYS elemental
	},

	["Wraith Industries"] = {
		Name = "Wraith Industries",
		ShortName = "Wraith",
		Theme = "Ethereal weapons that explode when discarded",
		Color = Color3.fromRGB(150, 220, 255),

		-- BL2 Tediore mechanics
		Mechanics = {
			Type = "Tediore",
			Description = "Throw weapon on reload - explodes based on remaining ammo",
			ThrowReload = true,
			ThrowDamagePerBullet = 1.5
		},

		StatModifiers = {
			ReloadTime = 0.7,  -- Very fast reload
			Damage = 0.95,
			FireRate = 1.0,
			MagazineSize = 0.9
		},

		ElementalChance = 0.5
	},

	["Apocalypse Armaments"] = {
		Name = "Apocalypse Armaments",
		ShortName = "Apocalypse",
		Theme = "Overwhelming destructive firepower",
		Color = Color3.fromRGB(255, 140, 0),

		-- BL2 Torgue mechanics
		Mechanics = {
			Type = "Torgue",
			Description = "Always explosive, highest damage per shot, gyrojet projectiles",
			AlwaysExplosive = true,
			GyrojetProjectiles = true, -- Slow projectiles that gain speed
			SplashDamage = 0.8 -- 80% splash damage
		},

		StatModifiers = {
			Damage = 1.5,      -- Highest base damage
			FireRate = 0.7,    -- Slower fire rate
			Accuracy = 0.85,   -- Poor accuracy
			ReloadTime = 1.2,
			MagazineSize = 0.8
		},

		ElementalChance = 0 -- Always explosive instead
	},

	["Reaper Munitions"] = {
		Name = "Reaper Munitions",
		ShortName = "Reaper",
		Theme = "Rapid-fire instruments of harvest",
		Color = Color3.fromRGB(180, 50, 50),

		-- BL2 Vladof mechanics
		Mechanics = {
			Type = "Vladof",
			Description = "Extremely high fire rate, good all-around stats",
			BonusFireRate = true
		},

		StatModifiers = {
			FireRate = 1.5,    -- 50% higher fire rate
			Damage = 0.9,      -- Slightly lower damage
			Accuracy = 1.0,
			ReloadTime = 0.95,
			MagazineSize = 1.2
		},

		ElementalChance = 0.5
	}
}

-- Elemental damage types (Gothic-themed)
WeaponConfig.Elements = {
	Hellfire = {
		Name = "Hellfire",
		Color = Color3.fromRGB(255, 100, 0),
		DamageType = "Fire",
		EffectiveAgainst = "Flesh",
		WeakAgainst = "Armor",
		StatusEffect = "Burning",
		DOTDuration = 3,
		DOTDamage = 0.04, -- 4% of damage per second
		ProcChance = 0.15,
		Icon = "🔥"
	},

	Stormwrath = {
		Name = "Stormwrath",
		Color = Color3.fromRGB(100, 200, 255),
		DamageType = "Shock",
		EffectiveAgainst = "Shields",
		WeakAgainst = "Flesh",
		StatusEffect = "Electrocuted",
		DOTDuration = 2,
		DOTDamage = 0.03,
		ProcChance = 0.2,
		ShieldMultiplier = 1.75, -- 75% bonus vs shields
		Icon = "⚡"
	},

	Plague = {
		Name = "Plague",
		Color = Color3.fromRGB(120, 200, 50),
		DamageType = "Corrosive",
		EffectiveAgainst = "Armor",
		WeakAgainst = "Shields",
		StatusEffect = "Corroding",
		DOTDuration = 4,
		DOTDamage = 0.05, -- Strongest DOT
		ProcChance = 0.15,
		ArmorMultiplier = 1.75,
		Icon = "☠️"
	},

	Apocalyptic = {
		Name = "Apocalyptic",
		Color = Color3.fromRGB(255, 200, 0),
		DamageType = "Explosive",
		EffectiveAgainst = "All",
		StatusEffect = "None",
		SplashRadius = 3,
		SplashDamage = 0.8, -- 80% damage in AOE
		ProcChance = 1.0, -- Always
		Icon = "💥"
	},

	Curse = {
		Name = "Curse",
		Color = Color3.fromRGB(180, 100, 255),
		DamageType = "Slag",
		StatusEffect = "Cursed",
		CurseDuration = 8,
		CursedDamageMultiplier = 2.0, -- Take double damage from other sources
		DOTDamage = 0, -- No DOT, just debuff
		ProcChance = 0.25,
		Icon = "🌙"
	}
}

-- Weapon type base stats
WeaponConfig.WeaponTypes = {
	Pistol = {
		Name = "Pistol",
		BaseFireRate = 3,
		BaseDamage = 15,
		BaseAccuracy = 0.85,
		BaseReloadTime = 1.5,
		BaseMagazineSize = 12,
		BaseCritMultiplier = 2.0
	},
	Rifle = {
		Name = "Rifle",
		BaseFireRate = 6,
		BaseDamage = 25,
		BaseAccuracy = 0.9,
		BaseReloadTime = 2.5,
		BaseMagazineSize = 30,
		BaseCritMultiplier = 2.0
	},
	Shotgun = {
		Name = "Shotgun",
		BaseFireRate = 1.5,
		BaseDamage = 60,
		BaseAccuracy = 0.6,
		BaseReloadTime = 3,
		BaseMagazineSize = 8,
		PelletCount = 8,
		BaseCritMultiplier = 1.5
	},
	SMG = {
		Name = "SMG",
		BaseFireRate = 10,
		BaseDamage = 12,
		BaseAccuracy = 0.75,
		BaseReloadTime = 2,
		BaseMagazineSize = 40,
		BaseCritMultiplier = 1.8
	},
	Sniper = {
		Name = "Sniper",
		BaseFireRate = 0.8,
		BaseDamage = 100,
		BaseAccuracy = 0.98,
		BaseReloadTime = 3.5,
		BaseMagazineSize = 5,
		BaseCritMultiplier = 4.0
	}
}

-- Level scaling constant (BL2-accurate)
WeaponConfig.LEVEL_SCALE_MULTIPLIER = 1.13 -- 1.13× per level

-- Prefix priority (highest tier wins)
WeaponConfig.PrefixPriority = {
	"Accessory",
	"Element",
	"Grip",
	"Barrel"
}

return WeaponConfig
