--[[
	Sights.lua
	Sight parts - affects accuracy, zoom, and aim speed
]]

local Sights = {
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

return Sights
