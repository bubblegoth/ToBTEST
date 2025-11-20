--[[
	Magazines.lua
	Magazine parts - affects capacity, reload speed, and fire rate
]]

local Magazines = {
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

return Magazines
