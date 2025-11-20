--[[
	Barrels.lua
	Barrel parts - affects accuracy, damage, and range
]]

local Barrels = {
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

return Barrels
