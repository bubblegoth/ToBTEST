--[[
	NPCParts.lua
	Combined NPC parts module - all body parts in one file
	Part of the Gothic FPS Roguelite Dungeon System

	Similar structure to WeaponParts - randomized component selection
]]

local NPCParts = {}

-- ============================================================
-- HEADS
-- ============================================================

NPCParts.Heads = {
	{
		Id = "HEAD_SKULL",
		Name = "Bleached Skull",
		MeshId = "rbxassetid://0", -- Replace with actual mesh ID
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(220, 220, 220),
		Material = Enum.Material.Limestone,
		Description = "A bare skull, all flesh long rotted away"
	},
	{
		Id = "HEAD_HOODED",
		Name = "Hooded Visage",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Fabric,
		Description = "Face concealed beneath a dark hood"
	},
	{
		Id = "HEAD_WRAPPED",
		Name = "Bandage-Wrapped",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(180, 170, 150),
		Material = Enum.Material.Fabric,
		Description = "Ancient wrappings cover the face"
	},
	{
		Id = "HEAD_CROWNED",
		Name = "Crowned Skull",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.2, 1.2, 1.2),
		Color = Color3.fromRGB(200, 180, 140),
		Material = Enum.Material.Metal,
		Description = "A skull adorned with a tarnished crown"
	},
	{
		Id = "HEAD_HORNED",
		Name = "Horned Demon",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.3, 1.3, 1.3),
		Color = Color3.fromRGB(120, 20, 20),
		Material = Enum.Material.Slate,
		Description = "Twisted horns emerge from the skull"
	},
}

-- ============================================================
-- TORSOS
-- ============================================================

NPCParts.Torsos = {
	{
		Id = "TORSO_ROBES_DARK",
		Name = "Dark Robes",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1.2, 1),
		Color = Color3.fromRGB(30, 30, 40),
		Material = Enum.Material.Fabric,
		Description = "Tattered dark robes, worn by time"
	},
	{
		Id = "TORSO_SKELETAL",
		Name = "Exposed Ribcage",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(220, 220, 220),
		Material = Enum.Material.Limestone,
		Description = "Bare bones with no flesh remaining"
	},
	{
		Id = "TORSO_ARMOR_RUSTED",
		Name = "Rusted Plate",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(100, 70, 50),
		Material = Enum.Material.CorrodedMetal,
		Description = "Ancient armor, corroded by centuries"
	},
	{
		Id = "TORSO_HOLY_VESTMENTS",
		Name = "Holy Vestments",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1.3, 1),
		Color = Color3.fromRGB(150, 140, 130),
		Material = Enum.Material.Fabric,
		Description = "Sacred robes of a fallen priest"
	},
	{
		Id = "TORSO_LEATHER_WORN",
		Name = "Worn Leather",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1.1, 1),
		Color = Color3.fromRGB(80, 60, 40),
		Material = Enum.Material.Leather,
		Description = "Cracked leather vest, barely holding together"
	},
}

-- ============================================================
-- ARMS
-- ============================================================

NPCParts.Arms = {
	{
		Id = "ARMS_SKELETAL",
		Name = "Bone Arms",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(220, 220, 220),
		Material = Enum.Material.Limestone,
		Description = "Skeletal arms with exposed joints"
	},
	{
		Id = "ARMS_WRAPPED",
		Name = "Cloth-Wrapped",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(180, 170, 150),
		Material = Enum.Material.Fabric,
		Description = "Arms wrapped in ancient cloth"
	},
	{
		Id = "ARMS_GAUNTLETS",
		Name = "Iron Gauntlets",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(80, 80, 90),
		Material = Enum.Material.Metal,
		Description = "Heavy iron gauntlets covering skeletal hands"
	},
	{
		Id = "ARMS_CLAWED",
		Name = "Clawed Appendages",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.2, 1.2, 1.2),
		Color = Color3.fromRGB(100, 30, 30),
		Material = Enum.Material.Slate,
		Description = "Twisted claws instead of hands"
	},
}

-- ============================================================
-- LEGS
-- ============================================================

NPCParts.Legs = {
	{
		Id = "LEGS_SKELETAL",
		Name = "Bone Legs",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(220, 220, 220),
		Material = Enum.Material.Limestone,
		Description = "Skeletal legs with exposed femurs"
	},
	{
		Id = "LEGS_ROBED",
		Name = "Robed Legs",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1.1, 1),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.Fabric,
		Description = "Legs hidden beneath flowing robes"
	},
	{
		Id = "LEGS_ARMORED",
		Name = "Plated Legs",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(100, 70, 50),
		Material = Enum.Material.CorrodedMetal,
		Description = "Corroded leg armor"
	},
	{
		Id = "LEGS_TATTERED",
		Name = "Tattered Pants",
		MeshId = "rbxassetid://0",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(80, 60, 40),
		Material = Enum.Material.Fabric,
		Description = "Torn pants barely covering the bones"
	},
}

-- ============================================================
-- ACCESSORIES (Optional)
-- ============================================================

NPCParts.Accessories = {
	{
		Id = "ACC_NONE",
		Name = "None",
		Description = "No accessory"
	},
	{
		Id = "ACC_LANTERN",
		Name = "Soul Lantern",
		MeshId = "rbxassetid://0",
		AttachmentPoint = "LeftHand",
		Scale = Vector3.new(0.5, 0.5, 0.5),
		Color = Color3.fromRGB(100, 200, 255),
		Material = Enum.Material.Neon,
		Light = {
			Enabled = true,
			Brightness = 5,
			Range = 20,
			Color = Color3.fromRGB(100, 200, 255)
		},
		Description = "A glowing lantern containing trapped souls"
	},
	{
		Id = "ACC_SCYTHE",
		Name = "Reaper's Scythe",
		MeshId = "rbxassetid://0",
		AttachmentPoint = "RightHand",
		Scale = Vector3.new(1.5, 1.5, 1.5),
		Color = Color3.fromRGB(40, 40, 40),
		Material = Enum.Material.Metal,
		Description = "A curved scythe for harvesting souls"
	},
	{
		Id = "ACC_TOME",
		Name = "Ancient Tome",
		MeshId = "rbxassetid://0",
		AttachmentPoint = "LeftHand",
		Scale = Vector3.new(0.7, 0.7, 0.7),
		Color = Color3.fromRGB(100, 50, 50),
		Material = Enum.Material.Fabric,
		Description = "A weathered book of dark knowledge"
	},
	{
		Id = "ACC_CHAINS",
		Name = "Soul Chains",
		MeshId = "rbxassetid://0",
		AttachmentPoint = "Torso",
		Scale = Vector3.new(1, 1, 1),
		Color = Color3.fromRGB(80, 80, 90),
		Material = Enum.Material.Metal,
		Description = "Chains binding lost souls"
	},
	{
		Id = "ACC_CROWN_THORNS",
		Name = "Crown of Thorns",
		MeshId = "rbxassetid://0",
		AttachmentPoint = "Head",
		Scale = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(60, 40, 40),
		Material = Enum.Material.Metal,
		Description = "A cruel crown of twisted thorns"
	},
}

return NPCParts
