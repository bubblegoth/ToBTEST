--[[
	WeaponParts.lua
	Combined weapon parts module - all parts in one file
	Part of the Gothic FPS Weapon Generation System
]]

local WeaponParts = {}

-- ============================================================
-- BODIES
-- ============================================================

WeaponParts.Bodies = {
	-- PISTOL BODIES
	{
		Id = "BODY_PISTOL_REVENANT",
		Name = "Revenant Frame",
		Type = "Pistol",
		StatModifiers = {
			Damage = 1.1,
			FireRate = 0.9,
			Accuracy = 1.05,
			ReloadTime = 1.0,
			MagazineSize = 0.8
		},
		MinLevel = 1,
		Description = "A ghostly frame that hits harder but fires slower"
	},
	{
		Id = "BODY_PISTOL_QUICKSILVER",
		Name = "Quicksilver Frame",
		Type = "Pistol",
		StatModifiers = {
			Damage = 0.9,
			FireRate = 1.3,
			Accuracy = 0.95,
			ReloadTime = 0.85,
			MagazineSize = 1.1
		},
		MinLevel = 5,
		Description = "Fast and fluid, sacrifices power for speed"
	},

	-- RIFLE BODIES
	{
		Id = "BODY_RIFLE_INQUISITOR",
		Name = "Inquisitor Frame",
		Type = "Rifle",
		StatModifiers = {
			Damage = 1.05,
			FireRate = 1.0,
			Accuracy = 1.15,
			ReloadTime = 1.0,
			MagazineSize = 1.0
		},
		MinLevel = 1,
		Description = "Precise and judgmental, delivers holy justice"
	},
	{
		Id = "BODY_RIFLE_DAMNATION",
		Name = "Damnation Frame",
		Type = "Rifle",
		StatModifiers = {
			Damage = 1.25,
			FireRate = 0.8,
			Accuracy = 0.9,
			ReloadTime = 1.15,
			MagazineSize = 0.9
		},
		MinLevel = 10,
		Description = "Devastating power at the cost of fire rate"
	},

	-- SHOTGUN BODIES
	{
		Id = "BODY_SHOTGUN_REAPER",
		Name = "Reaper Frame",
		Type = "Shotgun",
		StatModifiers = {
			Damage = 1.2,
			FireRate = 0.85,
			Accuracy = 0.9,
			ReloadTime = 1.1,
			MagazineSize = 0.75,
			PelletCount = 1.2
		},
		MinLevel = 1,
		Description = "Harvests souls with devastating spread"
	},
	{
		Id = "BODY_SHOTGUN_CRUSADER",
		Name = "Crusader Frame",
		Type = "Shotgun",
		StatModifiers = {
			Damage = 1.0,
			FireRate = 1.1,
			Accuracy = 1.1,
			ReloadTime = 0.9,
			MagazineSize = 1.2,
			PelletCount = 0.9
		},
		MinLevel = 8,
		Description = "Balanced holy weapon for righteous combat"
	},

	-- SMG BODIES
	{
		Id = "BODY_SMG_SPECTRE",
		Name = "Spectre Frame",
		Type = "SMG",
		StatModifiers = {
			Damage = 0.95,
			FireRate = 1.25,
			Accuracy = 0.85,
			ReloadTime = 0.8,
			MagazineSize = 1.3
		},
		MinLevel = 1,
		Description = "Ethereal and rapid, like a ghost in combat"
	},
	{
		Id = "BODY_SMG_VORTEX",
		Name = "Vortex Frame",
		Type = "SMG",
		StatModifiers = {
			Damage = 0.85,
			FireRate = 1.5,
			Accuracy = 0.8,
			ReloadTime = 0.75,
			MagazineSize = 1.5
		},
		MinLevel = 12,
		Description = "Spiraling chaos, maximum fire rate"
	},

	-- SNIPER BODIES
	{
		Id = "BODY_SNIPER_HARBINGER",
		Name = "Harbinger Frame",
		Type = "Sniper",
		StatModifiers = {
			Damage = 1.3,
			FireRate = 0.9,
			Accuracy = 1.1,
			ReloadTime = 1.0,
			MagazineSize = 0.8
		},
		MinLevel = 1,
		Description = "Announces death from afar"
	},
	{
		Id = "BODY_SNIPER_ECLIPSE",
		Name = "Eclipse Frame",
		Type = "Sniper",
		StatModifiers = {
			Damage = 1.5,
			FireRate = 0.7,
			Accuracy = 1.2,
			ReloadTime = 1.2,
			MagazineSize = 0.6
		},
		MinLevel = 15,
		Description = "Darkens the sky with devastating precision"
	}


}

-- ============================================================
-- BARRELS
-- ============================================================

WeaponParts.Barrels = {
	{
		Id = "BARREL_SHORT_PROFANE",
		Name = "Profane Short Barrel",
		StatModifiers = {
			Damage = 0.9,
			Accuracy = 0.85,
			Range = 0.7,
			FireRate = 1.1
		},
		MinLevel = 1,
		Description = "Unholy compact barrel, mobile but imprecise"
	},
	{
		Id = "BARREL_STANDARD_SANCTIFIED",
		Name = "Sanctified Barrel",
		StatModifiers = {
			Damage = 1.0,
			Accuracy = 1.0,
			Range = 1.0,
			FireRate = 1.0
		},
		MinLevel = 1,
		Description = "Blessed standard barrel, balanced in all aspects"
	},
	{
		Id = "BARREL_LONG_CATHEDRAL",
		Name = "Cathedral Long Barrel",
		StatModifiers = {
			Damage = 1.15,
			Accuracy = 1.2,
			Range = 1.4,
			FireRate = 0.9
		},
		MinLevel = 5,
		Description = "Elongated holy barrel, precise but slower"
	},
	{
		Id = "BARREL_RIFLED_CRYPT",
		Name = "Crypt Rifled Barrel",
		StatModifiers = {
			Damage = 1.1,
			Accuracy = 1.3,
			Range = 1.2,
			FireRate = 0.95
		},
		MinLevel = 8,
		Description = "Spiraling grooves from the crypts, extremely accurate"
	},
	{
		Id = "BARREL_HEAVY_DREADNOUGHT",
		Name = "Dreadnought Heavy Barrel",
		StatModifiers = {
			Damage = 1.3,
			Accuracy = 1.1,
			Range = 1.1,
			FireRate = 0.8,
			ReloadTime = 1.1
		},
		MinLevel = 10,
		Description = "Massive barrel for devastating impact"
	},
	{
		Id = "BARREL_FLUTED_PHANTOM",
		Name = "Phantom Fluted Barrel",
		StatModifiers = {
			Damage = 0.95,
			Accuracy = 1.15,
			Range = 1.1,
			FireRate = 1.15,
			ReloadTime = 0.95
		},
		MinLevel = 12,
		Description = "Lightweight ghostly barrel with fluting"
	},
	{
		Id = "BARREL_HELLFIRE",
		Name = "Hellfire Scorched Barrel",
		StatModifiers = {
			Damage = 1.25,
			Accuracy = 0.9,
			Range = 0.95,
			FireRate = 1.0,
			CritChance = 0.05
		},
		MinLevel = 15,
		Description = "Burned by infernal flames, adds critical strike chance"
	},
	{
		Id = "BARREL_FROZEN_SOUL",
		Name = "Frozen Soul Barrel",
		StatModifiers = {
			Damage = 1.05,
			Accuracy = 1.25,
			Range = 1.3,
			FireRate = 0.85,
			CritDamage = 0.15
		},
		MinLevel = 18,
		Description = "Frozen by restless spirits, enhances critical damage"
	}


}

-- ============================================================
-- GRIPS
-- ============================================================

WeaponParts.Grips = {
	{
		Id = "GRIP_WOODEN_COFFIN",
		Name = "Coffin Wood Grip",
		StatModifiers = {
			Accuracy = 0.95,
			RecoilControl = 0.9,
			AimSpeed = 1.0
		},
		MinLevel = 1,
		Description = "Carved from ancient coffins, crude but effective"
	},
	{
		Id = "GRIP_BONE_CARVED",
		Name = "Bone-Carved Grip",
		StatModifiers = {
			Accuracy = 1.0,
			RecoilControl = 1.0,
			AimSpeed = 1.05
		},
		MinLevel = 1,
		Description = "Crafted from consecrated bones"
	},
	{
		Id = "GRIP_LEATHER_WRAPPED",
		Name = "Leather-Wrapped Grip",
		StatModifiers = {
			Accuracy = 1.1,
			RecoilControl = 1.15,
			AimSpeed = 0.95
		},
		MinLevel = 5,
		Description = "Bound in holy leather for superior control"
	},
	{
		Id = "GRIP_IRON_MAIDEN",
		Name = "Iron Maiden Grip",
		StatModifiers = {
			Accuracy = 1.05,
			RecoilControl = 1.25,
			AimSpeed = 0.85,
			Damage = 1.05
		},
		MinLevel = 10,
		Description = "Spiked iron grip, painful but effective"
	},
	{
		Id = "GRIP_ETHEREAL",
		Name = "Ethereal Grip",
		StatModifiers = {
			Accuracy = 1.15,
			RecoilControl = 1.05,
			AimSpeed = 1.2,
			ReloadTime = 0.95
		},
		MinLevel = 12,
		Description = "Nearly weightless, feels like holding air"
	},
	{
		Id = "GRIP_GARGOYLE",
		Name = "Gargoyle Stone Grip",
		StatModifiers = {
			Accuracy = 0.9,
			RecoilControl = 1.4,
			AimSpeed = 0.75,
			Damage = 1.1
		},
		MinLevel = 15,
		Description = "Heavy stone grip, immovable when firing"
	},
	{
		Id = "GRIP_VELVET_CRIMSON",
		Name = "Crimson Velvet Grip",
		StatModifiers = {
			Accuracy = 1.2,
			RecoilControl = 1.1,
			AimSpeed = 1.1,
			CritChance = 0.03
		},
		MinLevel = 18,
		Description = "Luxurious velvet soaked in ancient blood"
	},
	{
		Id = "GRIP_WRAITH_TOUCH",
		Name = "Wraith's Touch Grip",
		StatModifiers = {
			Accuracy = 1.25,
			RecoilControl = 0.95,
			AimSpeed = 1.3,
			MovementSpeed = 1.1
		},
		MinLevel = 20,
		Description = "Touched by wraiths, enhances agility"
	}


}

-- ============================================================
-- STOCKS
-- ============================================================

WeaponParts.Stocks = {
	{
		Id = "STOCK_NONE",
		Name = "No Stock",
		StatModifiers = {
			RecoilControl = 0.7,
			Accuracy = 0.85,
			AimSpeed = 1.3,
			MovementSpeed = 1.15
		},
		MinLevel = 1,
		Description = "No stock, maximum mobility"
	},
	{
		Id = "STOCK_FOLDING_RAVEN",
		Name = "Raven Folding Stock",
		StatModifiers = {
			RecoilControl = 0.9,
			Accuracy = 0.95,
			AimSpeed = 1.15,
			MovementSpeed = 1.05
		},
		MinLevel = 1,
		Description = "Collapsible stock with raven motifs"
	},
	{
		Id = "STOCK_FIXED_CATHEDRAL",
		Name = "Cathedral Fixed Stock",
		StatModifiers = {
			RecoilControl = 1.15,
			Accuracy = 1.1,
			AimSpeed = 0.95,
			MovementSpeed = 0.95
		},
		MinLevel = 5,
		Description = "Solid stock carved with holy architecture"
	},
	{
		Id = "STOCK_HEAVY_TOMBSTONE",
		Name = "Tombstone Heavy Stock",
		StatModifiers = {
			RecoilControl = 1.35,
			Accuracy = 1.2,
			AimSpeed = 0.8,
			MovementSpeed = 0.85,
			Damage = 1.05
		},
		MinLevel = 10,
		Description = "Weighted with tombstone marble, very stable"
	},
	{
		Id = "STOCK_SKELETAL",
		Name = "Skeletal Stock",
		StatModifiers = {
			RecoilControl = 1.05,
			Accuracy = 1.05,
			AimSpeed = 1.1,
			MovementSpeed = 1.1,
			ReloadTime = 0.95
		},
		MinLevel = 12,
		Description = "Lightweight bone framework"
	},
	{
		Id = "STOCK_PRECISION_SAINT",
		Name = "Saint's Precision Stock",
		StatModifiers = {
			RecoilControl = 1.25,
			Accuracy = 1.3,
			AimSpeed = 0.9,
			MovementSpeed = 0.9,
			CritDamage = 0.1
		},
		MinLevel = 15,
		Description = "Blessed stock for righteous accuracy"
	},
	{
		Id = "STOCK_DAMNED_COMPOSITE",
		Name = "Damned Composite Stock",
		StatModifiers = {
			RecoilControl = 1.1,
			Accuracy = 1.15,
			AimSpeed = 1.05,
			MovementSpeed = 1.05,
			FireRate = 1.05
		},
		MinLevel = 18,
		Description = "Composite materials from the damned"
	}


}

-- ============================================================
-- MAGAZINES
-- ============================================================

WeaponParts.Magazines = {
	{
		Id = "MAG_COMPACT_CRYPT",
		Name = "Crypt Compact Magazine",
		StatModifiers = {
			MagazineSize = 0.7,
			ReloadTime = 0.8,
			MovementSpeed = 1.1,
			AimSpeed = 1.05
		},
		MinLevel = 1,
		Description = "Small capacity, quick reloads"
	},
	{
		Id = "MAG_STANDARD_SANCTUM",
		Name = "Sanctum Standard Magazine",
		StatModifiers = {
			MagazineSize = 1.0,
			ReloadTime = 1.0,
			MovementSpeed = 1.0,
			AimSpeed = 1.0
		},
		MinLevel = 1,
		Description = "Balanced holy magazine"
	},
	{
		Id = "MAG_EXTENDED_OSSUARY",
		Name = "Ossuary Extended Magazine",
		StatModifiers = {
			MagazineSize = 1.5,
			ReloadTime = 1.2,
			MovementSpeed = 0.95,
			AimSpeed = 0.95
		},
		MinLevel = 5,
		Description = "Holds more souls at a cost"
	},
	{
		Id = "MAG_DRUM_CHARNEL",
		Name = "Charnel House Drum",
		StatModifiers = {
			MagazineSize = 2.0,
			ReloadTime = 1.5,
			MovementSpeed = 0.85,
			AimSpeed = 0.85,
			FireRate = 0.95
		},
		MinLevel = 10,
		Description = "Massive capacity, heavy and slow"
	},
	{
		Id = "MAG_QUICKDRAW_PHANTOM",
		Name = "Phantom Quickdraw Magazine",
		StatModifiers = {
			MagazineSize = 0.9,
			ReloadTime = 0.6,
			MovementSpeed = 1.05,
			AimSpeed = 1.1,
			FireRate = 1.1
		},
		MinLevel = 12,
		Description = "Ghostly fast reloads and handling"
	},
	{
		Id = "MAG_BLESSED_CAPACITY",
		Name = "Blessed High-Capacity Magazine",
		StatModifiers = {
			MagazineSize = 1.8,
			ReloadTime = 1.0,
			MovementSpeed = 0.95,
			AimSpeed = 0.95
		},
		MinLevel = 15,
		Description = "Divinely efficient capacity without penalty"
	},
	{
		Id = "MAG_CURSED_INFINITE",
		Name = "Cursed Void Magazine",
		StatModifiers = {
			MagazineSize = 1.3,
			ReloadTime = 0.85,
			MovementSpeed = 1.0,
			FireRate = 1.05,
			CritChance = 0.05
		},
		MinLevel = 18,
		Description = "Touched by the void, mysteriously efficient"
	},
	{
		Id = "MAG_HELLFORGE",
		Name = "Hellforge Magazine",
		StatModifiers = {
			MagazineSize = 1.2,
			ReloadTime = 0.9,
			FireRate = 1.15,
			Damage = 1.05
		},
		MinLevel = 20,
		Description = "Forged in hell, feeds rounds with supernatural speed"
	}


}

-- ============================================================
-- SIGHTS
-- ============================================================

WeaponParts.Sights = {
	{
		Id = "SIGHT_IRON_GRAVESTONE",
		Name = "Gravestone Iron Sights",
		StatModifiers = {
			Accuracy = 1.0,
			AimSpeed = 1.1,
			ZoomLevel = 1.0
		},
		MinLevel = 1,
		Description = "Simple iron sights shaped like gravestones"
	},
	{
		Id = "SIGHT_REFLEX_SPIRIT",
		Name = "Spirit Reflex Sight",
		StatModifiers = {
			Accuracy = 1.1,
			AimSpeed = 1.15,
			ZoomLevel = 1.2,
			CritChance = 0.02
		},
		MinLevel = 5,
		Description = "Ethereal reflex sight with ghostly reticle"
	},
	{
		Id = "SIGHT_HOLO_CATHEDRAL",
		Name = "Cathedral Holographic Sight",
		StatModifiers = {
			Accuracy = 1.15,
			AimSpeed = 1.05,
			ZoomLevel = 1.3,
			Range = 1.1
		},
		MinLevel = 8,
		Description = "Projects holy symbols as targeting reticle"
	},
	{
		Id = "SIGHT_SCOPE_ORACLE",
		Name = "Oracle's Scope",
		StatModifiers = {
			Accuracy = 1.3,
			AimSpeed = 0.8,
			ZoomLevel = 2.5,
			Range = 1.4,
			CritDamage = 0.15
		},
		MinLevel = 10,
		Description = "Sees the future, predicts enemy movement"
	},
	{
		Id = "SIGHT_THERMAL_WRAITH",
		Name = "Wraith Thermal Sight",
		StatModifiers = {
			Accuracy = 1.2,
			AimSpeed = 0.95,
			ZoomLevel = 1.8,
			Range = 1.2
		},
		MinLevel = 12,
		Description = "Sees the heat signatures of the living"
	},
	{
		Id = "SIGHT_SNIPER_REAPER",
		Name = "Reaper's Precision Scope",
		StatModifiers = {
			Accuracy = 1.5,
			AimSpeed = 0.7,
			ZoomLevel = 4.0,
			Range = 1.8,
			CritChance = 0.1,
			CritDamage = 0.25
		},
		MinLevel = 15,
		Description = "Death sees all from afar"
	},
	{
		Id = "SIGHT_QUICKDOT_HELLFIRE",
		Name = "Hellfire Quick Dot",
		StatModifiers = {
			Accuracy = 1.05,
			AimSpeed = 1.3,
			ZoomLevel = 1.1,
			FireRate = 1.1,
			CritChance = 0.05
		},
		MinLevel = 18,
		Description = "Blazing fast target acquisition"
	},
	{
		Id = "SIGHT_ARCANE_LENS",
		Name = "Arcane Lens Sight",
		StatModifiers = {
			Accuracy = 1.25,
			AimSpeed = 1.0,
			ZoomLevel = 2.0,
			Range = 1.3,
			Damage = 1.1
		},
		MinLevel = 20,
		Description = "Magical lens that enhances bullet lethality"
	}


}

-- ============================================================
-- ACCESSORIES
-- ============================================================

WeaponParts.Accessories = {
	-- UNIVERSAL ACCESSORIES (all weapon types)
	{
		Id = "ACC_BAYONET_CURSED",
		Name = "Cursed Bayonet",
		Prefix = "Impaling",
		ApplicableTypes = {"Rifle", "Shotgun", "SMG"},
		MinLevel = 1,
		StatModifiers = {
			MeleeDamage = 2.5,
			Damage = 1.05
		},
		Description = "Wicked blade for close encounters"
	},

	{
		Id = "ACC_FOREGRIP_TOMBSTONE",
		Name = "Tombstone Foregrip",
		Prefix = "Stabilized",
		ApplicableTypes = {"Rifle", "SMG", "Sniper"},
		MinLevel = 1,
		StatModifiers = {
			Accuracy = 1.2,
			RecoilControl = 1.3,
			AimSpeed = 0.95
		},
		Description = "Stone grip for maximum stability"
	},

	{
		Id = "ACC_SCOPE_ORACLE",
		Name = "Oracle's Magnifier",
		Prefix = "Prescient",
		ApplicableTypes = {"Rifle", "Sniper"},
		MinLevel = 5,
		StatModifiers = {
			Accuracy = 1.15,
			ZoomLevel = 1.8,
			CritDamage = 0.2
		},
		Description = "See the future trajectory"
	},

	{
		Id = "ACC_STOCK_GARGOYLE",
		Name = "Gargoyle Brace",
		Prefix = "Anchored",
		ApplicableTypes = {"Rifle", "Shotgun", "Sniper"},
		MinLevel = 3,
		StatModifiers = {
			RecoilControl = 1.4,
			Accuracy = 1.1,
			MovementSpeed = 0.9
		},
		Description = "Stone-carved stock that won't budge"
	},

	{
		Id = "ACC_LASER_SIGHT_WRAITH",
		Name = "Wraith Marker",
		Prefix = "Phantom",
		ApplicableTypes = {"Pistol", "SMG", "Rifle"},
		MinLevel = 8,
		StatModifiers = {
			Accuracy = 1.25,
			AimSpeed = 1.2,
			CritChance = 0.05
		},
		Description = "Ethereal laser marks your prey"
	},

	-- DRUM MAGAZINES (high capacity)
	{
		Id = "ACC_DRUM_CHARNEL",
		Name = "Charnel Drum",
		Prefix = "Relentless",
		ApplicableTypes = {"Rifle", "SMG", "Shotgun"},
		MinLevel = 10,
		StatModifiers = {
			MagazineSize = 2.0,
			ReloadTime = 1.4,
			MovementSpeed = 0.9
		},
		Description = "Massive capacity, heavy burden"
	},

	-- EXTENDED BARRELS
	{
		Id = "ACC_BARREL_CATHEDRAL",
		Name = "Cathedral Extension",
		Prefix = "Holy",
		ApplicableTypes = {"Pistol", "Rifle", "Sniper"},
		MinLevel = 5,
		StatModifiers = {
			Damage = 1.2,
			Accuracy = 1.15,
			Range = 1.5,
			FireRate = 0.9
		},
		Description = "Elongated blessed barrel"
	},

	-- MUZZLE BRAKES / COMPENSATORS
	{
		Id = "ACC_COMPENSATOR_REAPER",
		Name = "Reaper's Brake",
		Prefix = "Controlled",
		ApplicableTypes = {"Pistol", "Rifle", "SMG"},
		MinLevel = 7,
		StatModifiers = {
			RecoilControl = 1.5,
			Accuracy = 1.2,
			Damage = 0.95
		},
		Description = "Tames the wildest recoil"
	},

	-- ELEMENTAL AMPLIFIERS
	{
		Id = "ACC_HELLFIRE_CORE",
		Name = "Hellfire Core",
		Prefix = "Scorching",
		ApplicableTypes = {"All"},
		MinLevel = 12,
		RequiresElement = "Hellfire",
		StatModifiers = {
			ElementalDamage = 1.4,
			DOTDamage = 1.3,
			ProcChance = 0.1
		},
		Description = "Amplifies infernal power"
	},

	{
		Id = "ACC_STORM_CAPACITOR",
		Name = "Storm Capacitor",
		Prefix = "Electrified",
		ApplicableTypes = {"All"},
		MinLevel = 12,
		RequiresElement = "Stormwrath",
		StatModifiers = {
			ElementalDamage = 1.4,
			DOTDamage = 1.3,
			ProcChance = 0.12,
			ShieldMultiplier = 0.2
		},
		Description = "Overcharges shock damage"
	},

	{
		Id = "ACC_PLAGUE_INJECTOR",
		Name = "Plague Injector",
		Prefix = "Virulent",
		ApplicableTypes = {"All"},
		MinLevel = 12,
		RequiresElement = "Plague",
		StatModifiers = {
			ElementalDamage = 1.4,
			DOTDuration = 1.5,
			ProcChance = 0.1,
			ArmorMultiplier = 0.2
		},
		Description = "Spreads corruption faster"
	},

	-- EXPLOSIVE ENHANCEMENTS
	{
		Id = "ACC_APOCALYPSE_CORE",
		Name = "Doomsday Core",
		Prefix = "Cataclysmic",
		ApplicableTypes = {"All"},
		MinLevel = 15,
		RequiresElement = "Apocalyptic",
		StatModifiers = {
			Damage = 1.3,
			SplashRadius = 1.5,
			SplashDamage = 1.3
		},
		Description = "Maximize explosive devastation"
	},

	-- CRITICAL HIT ACCESSORIES
	{
		Id = "ACC_EXECUTIONERS_MARK",
		Name = "Executioner's Mark",
		Prefix = "Lethal",
		ApplicableTypes = {"Pistol", "Rifle", "Sniper"},
		MinLevel = 10,
		StatModifiers = {
			CritChance = 0.15,
			CritDamage = 0.3,
			Damage = 0.95
		},
		Description = "Marks vital points with precision"
	},

	-- FIRE RATE BOOSTERS
	{
		Id = "ACC_RAPID_MECHANISM",
		Name = "Spectral Mechanism",
		Prefix = "Rapid",
		ApplicableTypes = {"Pistol", "SMG", "Rifle"},
		MinLevel = 8,
		StatModifiers = {
			FireRate = 1.4,
			Accuracy = 0.9,
			RecoilControl = 0.85
		},
		Description = "Ghostly fast cycling"
	},

	-- DAMAGE BOOSTERS
	{
		Id = "ACC_GRIM_HARVESTER",
		Name = "Grim Harvester",
		Prefix = "Devastating",
		ApplicableTypes = {"Shotgun", "Sniper", "Rifle"},
		MinLevel = 12,
		StatModifiers = {
			Damage = 1.35,
			FireRate = 0.85,
			MagazineSize = 0.9
		},
		Description = "Raw killing power"
	},

	-- UNIQUE LEGENDARY ACCESSORIES
	{
		Id = "ACC_LEGENDARY_SOULREAPER",
		Name = "Soul Reaper Mechanism",
		Prefix = "Soul-Reaping",
		ApplicableTypes = {"All"},
		MinLevel = 20,
		MinRarity = "Legendary",
		StatModifiers = {
			Damage = 1.3,
			CritChance = 0.1,
			CritDamage = 0.5,
			FireRate = 1.15,
			LifeSteal = 0.05 -- 5% life steal
		},
		Description = "Harvests souls with every kill"
	},

	{
		Id = "ACC_LEGENDARY_APOCALYPSE",
		Name = "Apocalypse Engine",
		Prefix = "Apocalyptic",
		ApplicableTypes = {"All"},
		MinLevel = 20,
		MinRarity = "Legendary",
		StatModifiers = {
			Damage = 1.5,
			SplashDamage = 2.0,
			SplashRadius = 2.0,
			FireRate = 0.7,
			MagazineSize = 0.6
		},
		Description = "Brings the end times"
	},

	{
		Id = "ACC_LEGENDARY_DIVINE_FURY",
		Name = "Divine Fury Core",
		Prefix = "Furious",
		ApplicableTypes = {"All"},
		MinLevel = 20,
		MinRarity = "Legendary",
		StatModifiers = {
			FireRate = 1.8,
			Damage = 1.2,
			Accuracy = 1.2,
			MagazineSize = 1.3,
			ReloadTime = 0.7
		},
		Description = "Holy wrath incarnate"
	},

	-- SHOTGUN-SPECIFIC
	{
		Id = "ACC_SHOT_SPREADER_WRAITH",
		Name = "Wraith Spreader",
		Prefix = "Scattered",
		ApplicableTypes = {"Shotgun"},
		MinLevel = 5,
		StatModifiers = {
			PelletCount = 1.5,
			Damage = 0.85,
			Accuracy = 0.8
		},
		Description = "More pellets, wider spread"
	},

	{
		Id = "ACC_SHOT_CHOKE_STONE",
		Name = "Tombstone Choke",
		Prefix = "Focused",
		ApplicableTypes = {"Shotgun"},
		MinLevel = 7,
		StatModifiers = {
			Accuracy = 1.5,
			Range = 1.4,
			PelletCount = 0.75
		},
		Description = "Tighter spread, longer range"
	},

	-- SNIPER-SPECIFIC
	{
		Id = "ACC_SNIPER_ORACLE_LENS",
		Name = "Oracle's Perfect Lens",
		Prefix = "Omniscient",
		ApplicableTypes = {"Sniper"},
		MinLevel = 10,
		StatModifiers = {
			Accuracy = 1.3,
			CritDamage = 0.5,
			ZoomLevel = 2.0,
			AimSpeed = 0.8
		},
		Description = "See and destroy from impossible distances"
	},

	-- PISTOL-SPECIFIC
	{
		Id = "ACC_PISTOL_DUAL_HAMMER",
		Name = "Dual-Strike Hammer",
		Prefix = "Double-Tap",
		ApplicableTypes = {"Pistol"},
		MinLevel = 8,
		StatModifiers = {
			FireRate = 1.5,
			Damage = 1.1,
			Accuracy = 0.9
		},
		Description = "Fires twice per trigger pull"
	}


}

return WeaponParts
