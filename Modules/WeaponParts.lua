--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponParts
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Borderlands-style modular weapon part database.
             Defines manufacturers, barrels, grips, stocks, magazines, sights.
             Gothic-themed manufacturers (Sanctum Armory, Abyssal Forge, etc).
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local WeaponParts = {}

-- ============================================================
-- MANUFACTURERS (Grips) - Gothic Themed with BL2-Accurate Multipliers
-- ============================================================
--[[
	BL2 Grip Multipliers Reference (from bl2.parts):
	- Jakobs: ×1.12 damage, ×1.09 fire interval
	- Torgue: ×1.09 damage, ×1.15 impulse accuracy
	- Vladof: ÷1.06 damage, ÷1.12 fire interval
	- Dahl: ÷1.06 damage, ÷1.15 impulse accuracy
	- Hyperion: ÷1.09 damage, ÷1.15 spread
	- Maliwan: ×1.15 status modifier
	- Bandit: ×1.35 magazine, ×1.1 reload time
	- Tediore: ÷1.14 magazine, ÷1.2 reload time
--]]

WeaponParts.Manufacturers = {
	{
		Name = "Cathedral Arms", -- Mapped to Jakobs (high damage, accuracy)
		BL2Style = "Jakobs",
		Bonus = "Divine judgment - High damage, precision",
		Color = Color3.fromRGB(255, 215, 0),
		Modifiers = {
			DamageScale = 1.12, -- ×1.12 damage
			FireRateScale = 1.09, -- ×1.09 fire interval (slower)
			CritChance = 10 -- Gothic bonus
		}
	},
	{
		Name = "Bone & Iron Works", -- Mapped to Torgue (raw power, explosive)
		BL2Style = "Torgue",
		Bonus = "Raw destructive power - Explosive damage",
		Color = Color3.fromRGB(80, 60, 50),
		Modifiers = {
			DamageScale = 1.09, -- ×1.09 damage
			AccuracyScale = 0.85, -- Worse accuracy (1/1.15)
			SplashDamage = 15 -- Gothic bonus
		}
	},
	{
		Name = "Reaper Industries", -- Mapped to Vladof (fire rate)
		BL2Style = "Vladof",
		Bonus = "Speed and lethality - Rapid fire",
		Color = Color3.fromRGB(40, 40, 40),
		Modifiers = {
			DamageScale = 0.943, -- ÷1.06 damage (1/1.06 = 0.943)
			FireRateScale = 0.893 -- ÷1.12 fire interval (faster) (1/1.12 = 0.893)
		}
	},
	{
		Name = "Sanctum Armory", -- Mapped to Dahl (accuracy, control)
		BL2Style = "Dahl",
		Bonus = "Precision and reliability - Controlled bursts",
		Color = Color3.fromRGB(220, 220, 220),
		Modifiers = {
			DamageScale = 0.943, -- ÷1.06 damage
			AccuracyScale = 1.15, -- Better accuracy (÷spread = better)
			RecoilReduction = 15 -- Gothic bonus
		}
	},
	{
		Name = "Crypt Forges", -- Mapped to Hyperion (accuracy gets better)
		BL2Style = "Hyperion",
		Bonus = "Ancient craftsmanship - Improves as you fire",
		Color = Color3.fromRGB(100, 100, 120),
		Modifiers = {
			DamageScale = 0.917, -- ÷1.09 damage (1/1.09 = 0.917)
			AccuracyScale = 1.15, -- Better spread
			Stability = 20 -- Gothic bonus
		}
	},
	{
		Name = "Wraith Manufacturing", -- Mapped to Maliwan (elemental)
		BL2Style = "Maliwan",
		Bonus = "Spectral efficiency - Elemental mastery",
		Color = Color3.fromRGB(150, 180, 200),
		Modifiers = {
			ElementalChance = 1.15, -- ×1.15 status modifier
			ElementalDamage = 20, -- Gothic bonus
			ReloadSpeed = 10
		}
	},
	{
		Name = "Tomb Makers", -- Mapped to Bandit (big mags, slow reload)
		BL2Style = "Bandit",
		Bonus = "Eternal darkness - Massive magazines",
		Color = Color3.fromRGB(60, 0, 60),
		Modifiers = {
			MagazineScale = 1.35, -- ×1.35 magazine
			ReloadScale = 1.1 -- ×1.1 reload time (slower)
		}
	}
}

-- ============================================================
-- WEAPON BASE TYPES (Chassis)
-- ============================================================

WeaponParts.BaseTypes = {
	{
		Name = "Pistol",
		BaseStats = {
			Damage = 20,
			FireRate = 0.3,
			Capacity = 12,
			Accuracy = 70, -- BL2 Formula: Spread = (100-70)/12 = 2.5°
			Range = 300,
			ReloadTime = 1.5,
			Pellets = 1,
			BloomPerShot = 0.6, -- Moderate bloom per shot
			MaxBloom = 12 -- Max bloom accumulation
		}
	},
	{
		Name = "Revolver",
		BaseStats = {
			Damage = 45,
			FireRate = 0.6,
			Capacity = 6,
			Accuracy = 85, -- BL2 Formula: Spread = (100-85)/12 = 1.25°
			Range = 400,
			ReloadTime = 2.5,
			Pellets = 1,
			BloomPerShot = 0.3, -- Low bloom
			MaxBloom = 6 -- Low max bloom
		}
	},
	{
		Name = "SMG",
		BaseStats = {
			Damage = 12,
			FireRate = 0.08,
			Capacity = 30,
			Accuracy = 50, -- BL2 Formula: Spread = (100-50)/12 = 4.17°
			Range = 200,
			ReloadTime = 1.8,
			Pellets = 1,
			BloomPerShot = 1.0, -- High bloom - gets inaccurate quickly
			MaxBloom = 20 -- High max bloom
		}
	},
	{
		Name = "Assault Rifle",
		BaseStats = {
			Damage = 25,
			FireRate = 0.15,
			Capacity = 30,
			Accuracy = 65, -- BL2 Formula: Spread = (100-65)/12 = 2.92°
			Range = 500,
			ReloadTime = 2.0,
			Pellets = 1,
			BloomPerShot = 0.7, -- Medium bloom
			MaxBloom = 15 -- Medium max bloom
		}
	},
	{
		Name = "Shotgun",
		BaseStats = {
			Damage = 60,
			FireRate = 0.8,
			Capacity = 8,
			Accuracy = 30, -- BL2 Formula: Spread = (100-30)/12 = 5.83°
			Range = 150,
			ReloadTime = 3.0,
			Pellets = 8,
			BloomPerShot = 0.2, -- Low bloom - already inaccurate
			MaxBloom = 5 -- Low max bloom
		}
	},
	{
		Name = "Sniper Rifle",
		BaseStats = {
			Damage = 100,
			FireRate = 1.2,
			Capacity = 5,
			Accuracy = 95, -- BL2 Formula: Spread = (100-95)/12 = 0.42°
			Range = 1000,
			ReloadTime = 2.5,
			Pellets = 1,
			BloomPerShot = 0.2, -- Very low bloom
			MaxBloom = 3 -- Very low max bloom
		}
	}
}

-- ============================================================
-- STOCKS - Stability and Handling
-- ============================================================

WeaponParts.Stocks = {
	{
		Name = "Heavy Stock",
		Rarity = "Common",
		CompatibleTypes = {"Assault Rifle", "Sniper Rifle", "Shotgun"},
		Modifiers = {
			Stability = 30,
			Accuracy = 20,
			RecoilReduction = 25,
			ReloadSpeed = -15,
			EquipSpeed = -20
		},
		Description = "Solid and stable, but slow"
	},
	{
		Name = "Standard Stock",
		Rarity = "Common",
		CompatibleTypes = {"Assault Rifle", "SMG", "Sniper Rifle", "Shotgun"},
		Modifiers = {
			Stability = 15,
			Accuracy = 10,
			RecoilReduction = 10
		},
		Description = "Balanced performance"
	},
	{
		Name = "Light Stock",
		Rarity = "Uncommon",
		CompatibleTypes = {"SMG", "Assault Rifle"},
		Modifiers = {
			Stability = 5,
			ReloadSpeed = 15,
			EquipSpeed = 20
		},
		Description = "Fast handling, less control"
	},
	{
		Name = "Skeleton Stock",
		Rarity = "Rare",
		CompatibleTypes = {"SMG", "Assault Rifle"},
		Modifiers = {
			Stability = -5,
			Accuracy = -10,
			ReloadSpeed = 30,
			EquipSpeed = 35
		},
		Description = "Lightning fast, minimal stability"
	},
	{
		Name = "No Stock",
		Rarity = "Epic",
		CompatibleTypes = {"SMG"},
		Modifiers = {
			Stability = -20,
			Accuracy = -20,
			RecoilReduction = -25,
			ReloadSpeed = 50,
			EquipSpeed = 60,
			MobilityBonus = 10
		},
		Description = "Maximum speed, chaotic accuracy"
	},
	{
		Name = "Cursed Bone Stock",
		Rarity = "Legendary",
		CompatibleTypes = {"Sniper Rifle", "Assault Rifle"},
		Modifiers = {
			Stability = 40,
			Accuracy = 30,
			RecoilReduction = 35,
			CritChance = 10
		},
		Description = "Ancient bones whisper of precision"
	},
	-- Pistol/Revolver Grips (no stocks for handguns)
	{
		Name = "Standard Grip",
		Rarity = "Common",
		CompatibleTypes = {"Pistol", "Revolver"},
		Modifiers = {
			Stability = 10,
			Accuracy = 5
		},
		Description = "Comfortable ergonomic grip"
	},
	{
		Name = "Rubberized Grip",
		Rarity = "Uncommon",
		CompatibleTypes = {"Pistol", "Revolver"},
		Modifiers = {
			Stability = 15,
			RecoilReduction = 10,
			Accuracy = 8
		},
		Description = "Enhanced recoil control"
	},
	{
		Name = "Competition Grip",
		Rarity = "Rare",
		CompatibleTypes = {"Pistol", "Revolver"},
		Modifiers = {
			Stability = 20,
			Accuracy = 15,
			CritChance = 5
		},
		Description = "Precision shooting grip"
	},
	{
		Name = "Cursed Bone Grip",
		Rarity = "Legendary",
		CompatibleTypes = {"Pistol", "Revolver"},
		Modifiers = {
			Stability = 25,
			Accuracy = 20,
			CritChance = 10,
			CritDamage = 15
		},
		Description = "Whispers guide your aim"
	}
}

-- ============================================================
-- BODIES - Fire Rate and Damage (BL2-Style Rarity Scaling)
-- ============================================================
--[[
	BL2 Body/Rarity Multipliers (from bl2.parts):
	- Uncommon: ×1.21 magazine, ×1.24 damage, ÷1.15 spread
	- Rare: ×1.35 magazine, ×1.48 damage, ÷1.25 spread
	- Very Rare: ×1.49 magazine, ×1.72 damage, ÷1.35 spread

	Bodies in BL2 determine rarity bonuses. We use similar scaling for gothic bodies.
--]]

WeaponParts.Bodies = {
	{
		Name = "Standard Frame",
		Rarity = "Common",
		Modifiers = {
			-- No modifiers - baseline
		},
		Description = "Reliable and consistent"
	},
	{
		Name = "Reinforced Frame",
		Rarity = "Uncommon",
		Modifiers = {
			DamageScale = 1.24, -- ×1.24 damage (BL2 Uncommon body)
			MagazineScale = 1.21, -- ×1.21 magazine
			AccuracyScale = 1.15 -- ÷1.15 spread (better)
		},
		Description = "Enhanced construction"
	},
	{
		Name = "Heavy Frame",
		Rarity = "Rare",
		Modifiers = {
			DamageScale = 1.48, -- ×1.48 damage (BL2 Rare body)
			MagazineScale = 1.35, -- ×1.35 magazine
			AccuracyScale = 1.25, -- ÷1.25 spread (better)
			FireRateScale = 1.05 -- Slightly slower
		},
		Description = "Built to punish"
	},
	{
		Name = "Revenant Frame",
		Rarity = "Epic",
		Modifiers = {
			DamageScale = 1.72, -- ×1.72 damage (BL2 Very Rare body)
			MagazineScale = 1.49, -- ×1.49 magazine
			AccuracyScale = 1.35, -- ÷1.35 spread (better)
			CritChance = 10,
			SoulGain = 2
		},
		Description = "Forged from spectral essence"
	},
	{
		Name = "Cathedral Frame",
		Rarity = "Legendary",
		Modifiers = {
			DamageScale = 2.0, -- ×2.0 damage (legendary tier)
			MagazineScale = 1.6,
			AccuracyScale = 1.5,
			CritDamage = 50,
			Range = 30
		},
		Description = "Divine craftsmanship incarnate"
	},
	{
		Name = "Void Frame",
		Rarity = "Mythic",
		Modifiers = {
			DamageScale = 2.5, -- ×2.5 damage (mythic tier)
			MagazineScale = 1.8,
			AccuracyScale = 1.8,
			CritChance = 15,
			CritDamage = 75,
			PenetrationChance = 25
		},
		Description = "Reality-bending construction"
	}
}

-- ============================================================
-- BARRELS - Damage, Accuracy, Range (BL2-Accurate Multipliers)
-- ============================================================
--[[
	BL2 Barrel Multipliers Reference (from bl2.parts):
	PISTOLS:
	- Jakobs: ×1.18 damage, ÷1.4 spread, ×1.36 fire interval
	- Torgue: ×1.24 damage, ×1.09 fire interval
	- Vladof: ÷1.3 fire interval, ×1.28 magazine
	- Dahl: ÷1.09 damage, ×1.2 spread
	- Hyperion: ÷1.12 damage, ÷1.35 spread
	- Maliwan: ×1.15 status damage, ÷1.1 spread
	- Bandit: ×1.06 damage, ×1.15 spread

	RIFLES:
	- Jakobs: ×1.18 damage, ÷1.3 spread, ×1.18 fire interval
	- Vladof: ÷1.15 fire interval, ×1.25 spread
	- Bandit: ×1.06 damage, ×1.15 spread
	- Dahl: ÷1.09 damage, ×1.2 spread

	Note: In BL2, barrels are manufacturer-specific. For roguelite variety,
	we use generic barrels with rarity-based scaling.
--]]

WeaponParts.Barrels = {
	{
		Name = "Jakobs Barrel", -- High damage, slow fire, accurate
		Rarity = "Rare",
		Modifiers = {
			DamageScale = 1.18, -- ×1.18 damage
			AccuracyScale = 1.35, -- ÷1.35 spread (better accuracy)
			FireRateScale = 1.27, -- ×1.27 fire interval (slower)
			CritChance = 5
		},
		Description = "High damage, slow fire"
	},
	{
		Name = "Torgue Barrel", -- Explosive damage
		Rarity = "Rare",
		Modifiers = {
			DamageScale = 1.24, -- ×1.24 damage
			FireRateScale = 1.09, -- ×1.09 fire interval
			SplashDamage = 20
		},
		Description = "Explosive power"
	},
	{
		Name = "Vladof Barrel", -- Fast fire rate
		Rarity = "Uncommon",
		Modifiers = {
			FireRateScale = 0.77, -- ÷1.3 fire interval (faster)
			MagazineScale = 1.28, -- ×1.28 magazine
			DamageScale = 0.95 -- Slight damage penalty for balance
		},
		Description = "Rapid fire"
	},
	{
		Name = "Dahl Barrel", -- Balanced, burst-friendly
		Rarity = "Common",
		Modifiers = {
			DamageScale = 0.917, -- ÷1.09 damage (1/1.09)
			AccuracyScale = 0.83, -- ×1.2 spread (worse)
			RecoilReduction = 10
		},
		Description = "Controlled bursts"
	},
	{
		Name = "Hyperion Barrel", -- Accuracy focused
		Rarity = "Uncommon",
		Modifiers = {
			DamageScale = 0.893, -- ÷1.12 damage (1/1.12)
			AccuracyScale = 1.35, -- ÷1.35 spread (very accurate)
			Stability = 15
		},
		Description = "Laser accuracy"
	},
	{
		Name = "Maliwan Barrel", -- Elemental
		Rarity = "Rare",
		Modifiers = {
			ElementalDamage = 15,
			AccuracyScale = 1.1, -- ÷1.1 spread
			ElementalChance = 1.15
		},
		Description = "Elemental mastery"
	},
	{
		Name = "Bandit Barrel", -- Slight damage boost
		Rarity = "Common",
		Modifiers = {
			DamageScale = 1.06, -- ×1.06 damage
			AccuracyScale = 0.87 -- ×1.15 spread (worse)
		},
		Description = "Raw and unrefined"
	},
	{
		Name = "Sanctified Barrel", -- Legendary crit barrel
		Rarity = "Legendary",
		Modifiers = {
			DamageScale = 1.25,
			AccuracyScale = 1.4,
			CritDamage = 30,
			CritChance = 10
		},
		Description = "Blessed by forgotten rites"
	},
	{
		Name = "Void Barrel", -- Mythic penetration barrel
		Rarity = "Mythic",
		Modifiers = {
			DamageScale = 1.5,
			AccuracyScale = 1.5,
			PenetrationChance = 50,
			Range = 80
		},
		Description = "Pierces the veil of reality"
	}
}

-- ============================================================
-- MAGAZINES - Capacity, Reload Speed (BL2-Style Scaling)
-- ============================================================

WeaponParts.Magazines = {
	{
		Name = "Drum Magazine",
		Rarity = "Common",
		Modifiers = {
			MagazineScale = 1.5, -- ×1.5 capacity (+50%)
			ReloadScale = 1.4 -- ×1.4 reload time (slower)
		},
		Description = "Extended firepower, slower handling"
	},
	{
		Name = "Extended Magazine",
		Rarity = "Common",
		Modifiers = {
			MagazineScale = 1.33, -- ×1.33 capacity (+33%)
			ReloadScale = 1.2 -- ×1.2 reload time (slower)
		},
		Description = "More ammo, slower handling"
	},
	{
		Name = "Standard Magazine",
		Rarity = "Common",
		Modifiers = {
			-- No modifiers - baseline
		},
		Description = "Balanced capacity"
	},
	{
		Name = "Compact Magazine",
		Rarity = "Uncommon",
		Modifiers = {
			MagazineScale = 0.75, -- ×0.75 capacity (-25%)
			ReloadScale = 0.75, -- ÷1.33 reload time (faster)
			DamageScale = 1.05 -- Small damage boost
		},
		Description = "Quick handling, fewer rounds"
	},
	{
		Name = "Speed Loader",
		Rarity = "Rare",
		Modifiers = {
			MagazineScale = 0.67, -- ×0.67 capacity (-33%)
			ReloadScale = 0.5, -- ÷2 reload time (very fast)
			DamageScale = 1.08 -- Slight damage boost
		},
		Description = "Lightning fast reloads"
	},
	{
		Name = "Soul Reservoir",
		Rarity = "Epic",
		Modifiers = {
			MagazineScale = 1.66, -- ×1.66 capacity (+66%)
			ReloadScale = 0.8, -- ÷1.25 reload time (faster)
			SoulGain = 5
		},
		Description = "Draws power from fallen enemies"
	},
	{
		Name = "Infinite Coil",
		Rarity = "Legendary",
		Modifiers = {
			MagazineScale = 2.0, -- ×2.0 capacity (+100%)
			ReloadScale = 0.6, -- ÷1.67 reload time (much faster)
			NoReloadChance = 25
		},
		Description = "The magazine that never empties"
	}
}

-- ============================================================
-- SIGHTS - Zoom, Accuracy, Critical
-- ============================================================

WeaponParts.Sights = {
	{
		Name = "Iron Sights",
		Rarity = "Common",
		Modifiers = {
			ZoomLevel = 1.2,
			AimAccuracy = 10,
			FOVReduction = 10
		},
		Description = "Basic targeting"
	},
	{
		Name = "Red Dot Sight",
		Rarity = "Uncommon",
		Modifiers = {
			ZoomLevel = 1.5,
			AimAccuracy = 20,
			FOVReduction = 15,
			TargetAcquisition = 15
		},
		Description = "Fast target acquisition"
	},
	{
		Name = "Holographic Sight",
		Rarity = "Rare",
		Modifiers = {
			ZoomLevel = 1.8,
			AimAccuracy = 30,
			FOVReduction = 20,
			TargetTracking = 10
		},
		Description = "Clear sight picture"
	},
	{
		Name = "4x Scope",
		Rarity = "Rare",
		Modifiers = {
			ZoomLevel = 4.0,
			AimAccuracy = 50,
			FOVReduction = 50,
			CritDamage = 15
		},
		Description = "Medium range precision"
	},
	{
		Name = "8x Sniper Scope",
		Rarity = "Epic",
		Modifiers = {
			ZoomLevel = 8.0,
			AimAccuracy = 80,
			FOVReduction = 70,
			CritDamage = 30,
			HeadshotBonus = 50
		},
		Description = "Long range domination"
	},
	{
		Name = "Specter Sight",
		Rarity = "Legendary",
		Modifiers = {
			ZoomLevel = 3.0,
			AimAccuracy = 60,
			FOVReduction = 40,
			EnemyHighlight = true,
			WeakpointVision = true,
			CritChance = 15
		},
		Description = "See through the darkness"
	},
	{
		Name = "God's Eye",
		Rarity = "Mythic",
		Modifiers = {
			ZoomLevel = 10.0,
			AimAccuracy = 100,
			FOVReduction = 80,
			CritDamage = 100,
			AutoAim = true,
			TimeSlowOnADS = true
		},
		Description = "The all-seeing divine lens"
	}
}

-- ============================================================
-- ACCESSORIES - Special Effects
-- ============================================================

WeaponParts.Accessories = {
	{
		Name = "None",
		Rarity = "Common",
		Modifiers = {},
		Description = "No accessory"
	},
	{
		Name = "Foregrip",
		Rarity = "Uncommon",
		Modifiers = {
			Stability = 20,
			RecoilReduction = 15,
			AimSpeed = 10
		},
		Description = "Better weapon control"
	},
	{
		Name = "Laser Sight",
		Rarity = "Uncommon",
		Modifiers = {
			HipfireAccuracy = 40,
			TargetAcquisition = 20
		},
		Description = "Accurate from the hip"
	},
	{
		Name = "Skull Bayonet",
		Rarity = "Rare",
		Modifiers = {
			MeleeDamage = 50,
			MeleeRange = 2,
			Intimidation = 10
		},
		Description = "Gothic melee attachment"
	},
	{
		Name = "Soul Siphon",
		Rarity = "Rare",
		Modifiers = {
			SoulGain = 15,
			Damage = 10,
			KillHeal = 5
		},
		Description = "Harvest souls with each kill"
	},
	{
		Name = "Fire Converter",
		Rarity = "Epic",
		Modifiers = {
			FireDamage = 25,
			BurnChance = 30,
			MagazineCapacity = -20
		},
		Description = "Sets enemies ablaze"
	},
	{
		Name = "Frost Coil",
		Rarity = "Epic",
		Modifiers = {
			FrostDamage = 20,
			SlowChance = 40,
			FireRate = -10
		},
		Description = "Freezes targets"
	},
	{
		Name = "Shadow Catalyst",
		Rarity = "Legendary",
		Modifiers = {
			ShadowDamage = 30,
			ChainEffect = 3,
			Damage = 20
		},
		Description = "Spreads darkness to nearby foes"
	},
	{
		Name = "Divine Amplifier",
		Rarity = "Legendary",
		Modifiers = {
			LightDamage = 40,
			DamageVsUndead = 50,
			Healing = 10,
			CritChance = 10
		},
		Description = "Channels divine light"
	},
	{
		Name = "Void Resonator",
		Rarity = "Mythic",
		Modifiers = {
			VoidDamage = 50,
			ChainLightning = 5,
			CritDamage = 40,
			ExplosionOnKill = true
		},
		Description = "Tears through reality"
	}
}

return WeaponParts
