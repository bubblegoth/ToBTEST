--[[
	Accessories.lua
	Optional weapon attachments (BL2-accurate)

	Accessory Rules (like BL2):
	- Common (White): NEVER has accessory
	- Uncommon (Green): 30% chance
	- Rare (Blue): 50% chance
	- Epic+ (Purple/Orange/Cyan): ALWAYS has accessory

	Accessories provide the highest-priority prefix
]]

local Accessories = {
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

return Accessories
