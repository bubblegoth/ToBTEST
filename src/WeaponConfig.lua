--[[
	WeaponConfig.lua
	Configuration for the Gothic FPS Weapon Generation System

	Defines rarities, weapon types, and global settings
]]

local WeaponConfig = {}

-- Rarity definitions with stat multipliers and drop rates
WeaponConfig.Rarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(150, 150, 150),
		StatMultiplier = 1.0,
		DropWeight = 50,
		NamePrefix = ""
	},
	Uncommon = {
		Name = "Uncommon",
		Color = Color3.fromRGB(100, 200, 100),
		StatMultiplier = 1.15,
		DropWeight = 30,
		NamePrefix = "Refined"
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(100, 150, 255),
		StatMultiplier = 1.35,
		DropWeight = 15,
		NamePrefix = "Superior"
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(200, 100, 255),
		StatMultiplier = 1.6,
		DropWeight = 4,
		NamePrefix = "Cursed"
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 180, 50),
		StatMultiplier = 2.0,
		DropWeight = 0.9,
		NamePrefix = "Unholy"
	},
	Mythic = {
		Name = "Mythic",
		Color = Color3.fromRGB(255, 50, 50),
		StatMultiplier = 2.5,
		DropWeight = 0.1,
		NamePrefix = "Apocalyptic"
	}
}

-- Weapon type categories
WeaponConfig.WeaponTypes = {
	Pistol = {
		Name = "Pistol",
		BaseFireRate = 3,
		BaseDamage = 15,
		BaseAccuracy = 0.85,
		BaseReloadTime = 1.5,
		BaseMagazineSize = 12
	},
	Rifle = {
		Name = "Rifle",
		BaseFireRate = 6,
		BaseDamage = 25,
		BaseAccuracy = 0.9,
		BaseReloadTime = 2.5,
		BaseMagazineSize = 30
	},
	Shotgun = {
		Name = "Shotgun",
		BaseFireRate = 1.5,
		BaseDamage = 60,
		BaseAccuracy = 0.6,
		BaseReloadTime = 3,
		BaseMagazineSize = 8,
		PelletCount = 8
	},
	SMG = {
		Name = "SMG",
		BaseFireRate = 10,
		BaseDamage = 12,
		BaseAccuracy = 0.75,
		BaseReloadTime = 2,
		BaseMagazineSize = 40
	},
	Sniper = {
		Name = "Sniper",
		BaseFireRate = 0.8,
		BaseDamage = 100,
		BaseAccuracy = 0.98,
		BaseReloadTime = 3.5,
		BaseMagazineSize = 5
	}
}

-- Gothic-themed name components
WeaponConfig.GothicNames = {
	Adjectives = {
		"Eternal", "Forsaken", "Corrupted", "Blessed", "Damned",
		"Ancient", "Spectral", "Infernal", "Divine", "Profane",
		"Shadowed", "Hallowed", "Wretched", "Sacred", "Vile",
		"Malevolent", "Benevolent", "Eldritch", "Arcane", "Runed"
	},
	Nouns = {
		"Reaper", "Condemner", "Absolver", "Punisher", "Redeemer",
		"Executioner", "Harvester", "Obliterator", "Purifier", "Decimator",
		"Inquisitor", "Crusader", "Zealot", "Martyr", "Heretic",
		"Prophet", "Apostate", "Revenant", "Wraith", "Lich"
	}
}

return WeaponConfig
