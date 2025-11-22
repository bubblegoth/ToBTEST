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
-- MANUFACTURERS (Grips) - Gothic Themed
-- ============================================================

WeaponParts.Manufacturers = {
	{
		Name = "Sanctum Armory",
		Bonus = "Precision and reliability",
		Color = Color3.fromRGB(220, 220, 220),
		Modifiers = {DamageBonus = 0, CritChance = 5, Accuracy = 10}
	},
	{
		Name = "Bone & Iron Works",
		Bonus = "Raw destructive power",
		Color = Color3.fromRGB(80, 60, 50),
		Modifiers = {DamageBonus = 0.15, Recoil = 10}
	},
	{
		Name = "Crypt Forges",
		Bonus = "Ancient craftsmanship",
		Color = Color3.fromRGB(100, 100, 120),
		Modifiers = {DamageBonus = 0.05, Durability = 20}
	},
	{
		Name = "Reaper Industries",
		Bonus = "Speed and lethality",
		Color = Color3.fromRGB(40, 40, 40),
		Modifiers = {FireRateBonus = 0.2, Damage = -5}
	},
	{
		Name = "Wraith Manufacturing",
		Bonus = "Spectral efficiency",
		Color = Color3.fromRGB(150, 180, 200),
		Modifiers = {ReloadSpeed = 20, EquipSpeed = 15}
	},
	{
		Name = "Cathedral Arms",
		Bonus = "Divine judgment",
		Color = Color3.fromRGB(255, 215, 0),
		Modifiers = {CritDamage = 25, Accuracy = 15}
	},
	{
		Name = "Tomb Makers",
		Bonus = "Eternal darkness",
		Color = Color3.fromRGB(60, 0, 60),
		Modifiers = {DamageBonus = 0.10, MagazineCapacity = 15}
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
-- BODIES - Fire Rate and Damage
-- ============================================================

WeaponParts.Bodies = {
	{
		Name = "Heavy Frame",
		Rarity = "Common",
		Modifiers = {
			Damage = 5,
			FireRate = 0.05, -- Slower by 0.05s
			Weight = 20
		},
		Description = "Hits like a battering ram"
	},
	{
		Name = "Standard Frame",
		Rarity = "Common",
		Modifiers = {
			Damage = 0,
			FireRate = 0,
			Weight = 0
		},
		Description = "Reliable and consistent"
	},
	{
		Name = "Lightweight Frame",
		Rarity = "Uncommon",
		Modifiers = {
			Damage = -3,
			FireRate = -0.08, -- Faster by 0.08s
			Weight = -15,
			Mobility = 10
		},
		Description = "Rapid fire, lower impact"
	},
	{
		Name = "Reinforced Frame",
		Rarity = "Rare",
		Modifiers = {
			Damage = 8,
			FireRate = 0.03, -- Slower by 0.03s
			Durability = 30,
			Weight = 15
		},
		Description = "Built to endure and punish"
	},
	{
		Name = "Revenant Frame",
		Rarity = "Epic",
		Modifiers = {
			Damage = 12,
			FireRate = -0.05, -- Faster by 0.05s
			CritChance = 10,
			SoulGain = 2
		},
		Description = "Forged from spectral essence"
	},
	{
		Name = "Cathedral Frame",
		Rarity = "Legendary",
		Modifiers = {
			Damage = 15,
			Accuracy = 25,
			CritDamage = 50,
			Range = 30
		},
		Description = "Divine craftsmanship incarnate"
	}
}

-- ============================================================
-- BARRELS - Damage, Accuracy, Range
-- ============================================================

WeaponParts.Barrels = {
	{
		Name = "Long Barrel",
		Rarity = "Common",
		Modifiers = {
			Damage = 3,
			Accuracy = 15,
			Range = 40,
			FireRate = 0.05 -- Slower by 0.05s
		},
		Description = "Precision at distance"
	},
	{
		Name = "Standard Barrel",
		Rarity = "Common",
		Modifiers = {
			Damage = 0,
			Accuracy = 5,
			Range = 15
		},
		Description = "Balanced performance"
	},
	{
		Name = "Short Barrel",
		Rarity = "Uncommon",
		Modifiers = {
			Damage = -2,
			Accuracy = -10,
			Range = -20,
			FireRate = -0.06, -- Faster by 0.06s
			Mobility = 15
		},
		Description = "Close quarters combat"
	},
	{
		Name = "Rifled Barrel",
		Rarity = "Rare",
		Modifiers = {
			Damage = 5,
			Accuracy = 25,
			Range = 30,
			CritChance = 10
		},
		Description = "Surgical precision"
	},
	{
		Name = "Vented Barrel",
		Rarity = "Epic",
		Modifiers = {
			Damage = 8,
			Accuracy = 20,
			FireRate = -0.03, -- Faster by 0.03s
			RecoilReduction = 20
		},
		Description = "Sustained high performance"
	},
	{
		Name = "Sanctified Barrel",
		Rarity = "Legendary",
		Modifiers = {
			Damage = 12,
			Accuracy = 30,
			Range = 50,
			CritDamage = 30
		},
		Description = "Blessed by forgotten rites"
	},
	{
		Name = "Void Barrel",
		Rarity = "Mythic",
		Modifiers = {
			Damage = 20,
			Accuracy = 40,
			Range = 80,
			PenetrationChance = 50
		},
		Description = "Pierces the veil of reality"
	}
}

-- ============================================================
-- MAGAZINES - Capacity, Reload Speed
-- ============================================================

WeaponParts.Magazines = {
	{
		Name = "Drum Magazine",
		Rarity = "Common",
		Modifiers = {
			Capacity = 6, -- +50% for pistol (12→18), balanced for all weapon types
			ReloadSpeed = -40,
			EquipSpeed = -30,
			Weight = 25
		},
		Description = "Extended firepower, slower handling"
	},
	{
		Name = "Extended Magazine",
		Rarity = "Common",
		Modifiers = {
			Capacity = 4, -- +33% for pistol (12→16)
			ReloadSpeed = -20,
			EquipSpeed = -15,
			Weight = 10
		},
		Description = "More ammo, slower handling"
	},
	{
		Name = "Standard Magazine",
		Rarity = "Common",
		Modifiers = {
			Capacity = 0,
			ReloadSpeed = 0,
			EquipSpeed = 0
		},
		Description = "Balanced capacity"
	},
	{
		Name = "Compact Magazine",
		Rarity = "Uncommon",
		Modifiers = {
			Capacity = -3, -- -25% for pistol (12→9)
			ReloadSpeed = 25,
			EquipSpeed = 20,
			Damage = 2 -- Reduced from 10
		},
		Description = "Quick handling, fewer rounds"
	},
	{
		Name = "Speed Loader",
		Rarity = "Rare",
		Modifiers = {
			Capacity = -4, -- -33% for pistol (12→8)
			ReloadSpeed = 50,
			EquipSpeed = 30,
			Damage = 3 -- Reduced from 15
		},
		Description = "Lightning fast reloads"
	},
	{
		Name = "Soul Reservoir",
		Rarity = "Epic",
		Modifiers = {
			Capacity = 8, -- +66% for pistol (12→20)
			ReloadSpeed = 20,
			SoulGain = 5
		},
		Description = "Draws power from fallen enemies"
	},
	{
		Name = "Infinite Coil",
		Rarity = "Legendary",
		Modifiers = {
			Capacity = 12, -- +100% for pistol (12→24)
			ReloadSpeed = 40,
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
