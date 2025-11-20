--[[
	Bodies.lua
	Weapon body/receiver parts - determines weapon type and base stats
]]

local Bodies = {
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

return Bodies
