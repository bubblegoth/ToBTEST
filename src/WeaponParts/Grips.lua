--[[
	Grips.lua
	Grip parts - affects recoil control, handling, and stability
]]

local Grips = {
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

return Grips
