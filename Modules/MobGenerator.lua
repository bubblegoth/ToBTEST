--[[
════════════════════════════════════════════════════════════════════════════════
Module: MobGenerator
Location: ReplicatedStorage/Modules/
Description: Generates randomized mobs by assembling different body parts.
             Creates variety through mix-and-match limbs, torsos, and heads.
Version: 1.0
Last Updated: 2025-11-15

SETUP:
Option 1: Use procedural generation (default) - creates simple geometric mobs
Option 2: Create prefab parts in ReplicatedStorage/MobParts/ folders:
          - Heads/
          - Torsos/
          - Arms/
          - Legs/
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MobGenerator = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════
local Config = {
	-- Base stats (modified by parts)
	BaseHealth = 100,
	BaseSpeed = 16,
	BaseDamage = 10,

	-- Size variation
	ScaleMin = 0.8,
	ScaleMax = 1.3,

	-- Colors for procedural generation
	SkinColors = {
		Color3.fromRGB(139, 69, 19),   -- Brown
		Color3.fromRGB(85, 107, 47),   -- Olive
		Color3.fromRGB(128, 128, 128), -- Gray
		Color3.fromRGB(60, 60, 60),    -- Dark gray
		Color3.fromRGB(139, 0, 0),     -- Dark red
		Color3.fromRGB(75, 0, 130),    -- Indigo
		Color3.fromRGB(47, 79, 79),    -- Dark slate
	},

	-- Part materials
	Materials = {
		Enum.Material.SmoothPlastic,
		Enum.Material.Slate,
		Enum.Material.Concrete,
		Enum.Material.Cobblestone,
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- PART DEFINITIONS (Procedural)
-- ════════════════════════════════════════════════════════════════════════════

-- Head types with stat modifiers
local HeadTypes = {
	{
		name = "Round",
		build = function(parent, color, material)
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(2, 2, 2)
			head.Color = color
			head.Material = material
			head.Parent = parent
			return head, {health = 0, speed = 0, damage = 0}
		end
	},
	{
		name = "Horned",
		build = function(parent, color, material)
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(2, 2, 2)
			head.Color = color
			head.Material = material
			head.Parent = parent

			-- Add horns
			local horn1 = Instance.new("Part")
			horn1.Name = "Horn_L"
			horn1.Size = Vector3.new(0.3, 1.2, 0.3)
			horn1.Color = Color3.fromRGB(200, 200, 180)
			horn1.Material = Enum.Material.SmoothPlastic
			horn1.Parent = parent

			local weld1 = Instance.new("Weld")
			weld1.Part0 = head
			weld1.Part1 = horn1
			weld1.C0 = CFrame.new(-0.6, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-20))
			weld1.Parent = horn1

			local horn2 = Instance.new("Part")
			horn2.Name = "Horn_R"
			horn2.Size = Vector3.new(0.3, 1.2, 0.3)
			horn2.Color = Color3.fromRGB(200, 200, 180)
			horn2.Material = Enum.Material.SmoothPlastic
			horn2.Parent = parent

			local weld2 = Instance.new("Weld")
			weld2.Part0 = head
			weld2.Part1 = horn2
			weld2.C0 = CFrame.new(0.6, 0.8, 0) * CFrame.Angles(0, 0, math.rad(20))
			weld2.Parent = horn2

			return head, {health = 0, speed = -2, damage = 5} -- Horns = more damage, slower
		end
	},
	{
		name = "Skull",
		build = function(parent, color, material)
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Size = Vector3.new(2, 2.2, 2)
			head.Color = Color3.fromRGB(220, 220, 200) -- Bone color
			head.Material = Enum.Material.SmoothPlastic
			head.Parent = parent

			-- Eye sockets
			local eye1 = Instance.new("Part")
			eye1.Name = "Eye_L"
			eye1.Shape = Enum.PartType.Ball
			eye1.Size = Vector3.new(0.6, 0.6, 0.3)
			eye1.Color = Color3.fromRGB(0, 0, 0)
			eye1.Material = Enum.Material.Neon
			eye1.Parent = parent

			local weld1 = Instance.new("Weld")
			weld1.Part0 = head
			weld1.Part1 = eye1
			weld1.C0 = CFrame.new(-0.4, 0.3, -0.9)
			weld1.Parent = eye1

			local eye2 = eye1:Clone()
			eye2.Name = "Eye_R"
			eye2.Parent = parent

			local weld2 = Instance.new("Weld")
			weld2.Part0 = head
			weld2.Part1 = eye2
			weld2.C0 = CFrame.new(0.4, 0.3, -0.9)
			weld2.Parent = eye2

			return head, {health = -20, speed = 2, damage = 0} -- Undead = less health, faster
		end
	},
	{
		name = "Cyclops",
		build = function(parent, color, material)
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(2.5, 2.5, 2.5) -- Bigger head
			head.Color = color
			head.Material = material
			head.Parent = parent

			-- Single big eye
			local eye = Instance.new("Part")
			eye.Name = "Eye"
			eye.Shape = Enum.PartType.Ball
			eye.Size = Vector3.new(1, 1, 0.5)
			eye.Color = Color3.fromRGB(255, 255, 0)
			eye.Material = Enum.Material.Neon
			eye.Parent = parent

			local weld = Instance.new("Weld")
			weld.Part0 = head
			weld.Part1 = eye
			weld.C0 = CFrame.new(0, 0.2, -1.2)
			weld.Parent = eye

			return head, {health = 30, speed = -4, damage = 8} -- Big and slow
		end
	},
	{
		name = "Spiky",
		build = function(parent, color, material)
			local head = Instance.new("Part")
			head.Name = "Head"
			head.Shape = Enum.PartType.Ball
			head.Size = Vector3.new(2, 2, 2)
			head.Color = color
			head.Material = material
			head.Parent = parent

			-- Add spikes
			for i = 1, 5 do
				local spike = Instance.new("Part")
				spike.Name = "Spike_" .. i
				spike.Size = Vector3.new(0.3, 0.8, 0.3)
				spike.Color = color
				spike.Material = material
				spike.Parent = parent

				local angle = (i / 5) * math.pi * 2
				local weld = Instance.new("Weld")
				weld.Part0 = head
				weld.Part1 = spike
				weld.C0 = CFrame.new(math.cos(angle) * 0.3, 1, math.sin(angle) * 0.3)
				weld.Parent = spike
			end

			return head, {health = 10, speed = 0, damage = 3}
		end
	},
}

-- Torso types
local TorsoTypes = {
	{
		name = "Normal",
		build = function(parent, color, material)
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(2, 2.5, 1)
			torso.Color = color
			torso.Material = material
			torso.Parent = parent
			return torso, {health = 0, speed = 0, damage = 0}
		end
	},
	{
		name = "Bulky",
		build = function(parent, color, material)
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(3, 3, 1.5)
			torso.Color = color
			torso.Material = material
			torso.Parent = parent
			return torso, {health = 50, speed = -6, damage = 5} -- Tank
		end
	},
	{
		name = "Thin",
		build = function(parent, color, material)
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(1.5, 2.8, 0.8)
			torso.Color = color
			torso.Material = material
			torso.Parent = parent
			return torso, {health = -20, speed = 6, damage = -2} -- Fast but weak
		end
	},
	{
		name = "Armored",
		build = function(parent, color, material)
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(2.2, 2.5, 1.2)
			torso.Color = Color3.fromRGB(100, 100, 100) -- Armor color
			torso.Material = Enum.Material.Metal
			torso.Parent = parent

			-- Shoulder pads
			local pad1 = Instance.new("Part")
			pad1.Name = "ShoulderPad_L"
			pad1.Size = Vector3.new(0.8, 0.4, 1)
			pad1.Color = Color3.fromRGB(80, 80, 80)
			pad1.Material = Enum.Material.Metal
			pad1.Parent = parent

			local weld1 = Instance.new("Weld")
			weld1.Part0 = torso
			weld1.Part1 = pad1
			weld1.C0 = CFrame.new(-1.3, 1, 0)
			weld1.Parent = pad1

			local pad2 = pad1:Clone()
			pad2.Name = "ShoulderPad_R"
			pad2.Parent = parent

			local weld2 = Instance.new("Weld")
			weld2.Part0 = torso
			weld2.Part1 = pad2
			weld2.C0 = CFrame.new(1.3, 1, 0)
			weld2.Parent = pad2

			return torso, {health = 40, speed = -4, damage = 0}
		end
	},
	{
		name = "Hunched",
		build = function(parent, color, material)
			local torso = Instance.new("Part")
			torso.Name = "Torso"
			torso.Size = Vector3.new(2.2, 2, 1.8)
			torso.Color = color
			torso.Material = material
			torso.Parent = parent

			-- Hunch/back protrusion
			local hunch = Instance.new("Part")
			hunch.Name = "Hunch"
			hunch.Shape = Enum.PartType.Ball
			hunch.Size = Vector3.new(1.5, 1.5, 1.5)
			hunch.Color = color
			hunch.Material = material
			hunch.Parent = parent

			local weld = Instance.new("Weld")
			weld.Part0 = torso
			weld.Part1 = hunch
			weld.C0 = CFrame.new(0, 0.5, 0.8)
			weld.Parent = hunch

			return torso, {health = 20, speed = -2, damage = 3}
		end
	},
}

-- Arm types
local ArmTypes = {
	{
		name = "Normal",
		build = function(parent, color, material, torso)
			local armL = Instance.new("Part")
			armL.Name = "Arm_L"
			armL.Size = Vector3.new(0.8, 2.5, 0.8)
			armL.Color = color
			armL.Material = material
			armL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = armL
			weldL.C0 = CFrame.new(-torso.Size.X/2 - 0.5, 0, 0)
			weldL.Parent = armL

			local armR = armL:Clone()
			armR.Name = "Arm_R"
			armR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = armR
			weldR.C0 = CFrame.new(torso.Size.X/2 + 0.5, 0, 0)
			weldR.Parent = armR

			return {armL, armR}, {health = 0, speed = 0, damage = 0}
		end
	},
	{
		name = "Long",
		build = function(parent, color, material, torso)
			local armL = Instance.new("Part")
			armL.Name = "Arm_L"
			armL.Size = Vector3.new(0.6, 4, 0.6) -- Extra long
			armL.Color = color
			armL.Material = material
			armL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = armL
			weldL.C0 = CFrame.new(-torso.Size.X/2 - 0.4, -0.5, 0)
			weldL.Parent = armL

			local armR = armL:Clone()
			armR.Name = "Arm_R"
			armR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = armR
			weldR.C0 = CFrame.new(torso.Size.X/2 + 0.4, -0.5, 0)
			weldR.Parent = armR

			return {armL, armR}, {health = 0, speed = 2, damage = 5} -- Longer reach
		end
	},
	{
		name = "Clawed",
		build = function(parent, color, material, torso)
			local armL = Instance.new("Part")
			armL.Name = "Arm_L"
			armL.Size = Vector3.new(0.8, 2.5, 0.8)
			armL.Color = color
			armL.Material = material
			armL.Parent = parent

			-- Claws
			for i = 1, 3 do
				local claw = Instance.new("Part")
				claw.Name = "Claw_L_" .. i
				claw.Size = Vector3.new(0.15, 0.8, 0.15)
				claw.Color = Color3.fromRGB(50, 50, 50)
				claw.Material = Enum.Material.SmoothPlastic
				claw.Parent = parent

				local clawWeld = Instance.new("Weld")
				clawWeld.Part0 = armL
				clawWeld.Part1 = claw
				clawWeld.C0 = CFrame.new((i-2) * 0.25, -1.5, 0) * CFrame.Angles(math.rad(-20), 0, 0)
				clawWeld.Parent = claw
			end

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = armL
			weldL.C0 = CFrame.new(-torso.Size.X/2 - 0.5, 0, 0)
			weldL.Parent = armL

			local armR = Instance.new("Part")
			armR.Name = "Arm_R"
			armR.Size = Vector3.new(0.8, 2.5, 0.8)
			armR.Color = color
			armR.Material = material
			armR.Parent = parent

			for i = 1, 3 do
				local claw = Instance.new("Part")
				claw.Name = "Claw_R_" .. i
				claw.Size = Vector3.new(0.15, 0.8, 0.15)
				claw.Color = Color3.fromRGB(50, 50, 50)
				claw.Material = Enum.Material.SmoothPlastic
				claw.Parent = parent

				local clawWeld = Instance.new("Weld")
				clawWeld.Part0 = armR
				clawWeld.Part1 = claw
				clawWeld.C0 = CFrame.new((i-2) * 0.25, -1.5, 0) * CFrame.Angles(math.rad(-20), 0, 0)
				clawWeld.Parent = claw
			end

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = armR
			weldR.C0 = CFrame.new(torso.Size.X/2 + 0.5, 0, 0)
			weldR.Parent = armR

			return {armL, armR}, {health = 0, speed = 0, damage = 10}
		end
	},
	{
		name = "Bulky",
		build = function(parent, color, material, torso)
			local armL = Instance.new("Part")
			armL.Name = "Arm_L"
			armL.Size = Vector3.new(1.2, 2.2, 1.2)
			armL.Color = color
			armL.Material = material
			armL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = armL
			weldL.C0 = CFrame.new(-torso.Size.X/2 - 0.7, 0, 0)
			weldL.Parent = armL

			local armR = armL:Clone()
			armR.Name = "Arm_R"
			armR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = armR
			weldR.C0 = CFrame.new(torso.Size.X/2 + 0.7, 0, 0)
			weldR.Parent = armR

			return {armL, armR}, {health = 20, speed = -3, damage = 8}
		end
	},
	{
		name = "None", -- No arms!
		build = function(parent, color, material, torso)
			return {}, {health = -10, speed = 4, damage = -5}
		end
	},
}

-- Leg types
local LegTypes = {
	{
		name = "Normal",
		build = function(parent, color, material, torso)
			local legL = Instance.new("Part")
			legL.Name = "Leg_L"
			legL.Size = Vector3.new(0.9, 2.5, 0.9)
			legL.Color = color
			legL.Material = material
			legL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = legL
			weldL.C0 = CFrame.new(-0.5, -torso.Size.Y/2 - 1.25, 0)
			weldL.Parent = legL

			local legR = legL:Clone()
			legR.Name = "Leg_R"
			legR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = legR
			weldR.C0 = CFrame.new(0.5, -torso.Size.Y/2 - 1.25, 0)
			weldR.Parent = legR

			return {legL, legR}, {health = 0, speed = 0, damage = 0}
		end
	},
	{
		name = "Thick",
		build = function(parent, color, material, torso)
			local legL = Instance.new("Part")
			legL.Name = "Leg_L"
			legL.Size = Vector3.new(1.3, 2.2, 1.3)
			legL.Color = color
			legL.Material = material
			legL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = legL
			weldL.C0 = CFrame.new(-0.7, -torso.Size.Y/2 - 1.1, 0)
			weldL.Parent = legL

			local legR = legL:Clone()
			legR.Name = "Leg_R"
			legR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = legR
			weldR.C0 = CFrame.new(0.7, -torso.Size.Y/2 - 1.1, 0)
			weldR.Parent = legR

			return {legL, legR}, {health = 30, speed = -4, damage = 0}
		end
	},
	{
		name = "Digitigrade", -- Reverse knee like a werewolf
		build = function(parent, color, material, torso)
			local legL_upper = Instance.new("Part")
			legL_upper.Name = "Leg_L_Upper"
			legL_upper.Size = Vector3.new(0.8, 1.5, 0.8)
			legL_upper.Color = color
			legL_upper.Material = material
			legL_upper.Parent = parent

			local legL_lower = Instance.new("Part")
			legL_lower.Name = "Leg_L_Lower"
			legL_lower.Size = Vector3.new(0.6, 2, 0.6)
			legL_lower.Color = color
			legL_lower.Material = material
			legL_lower.Parent = parent

			local weldL1 = Instance.new("Weld")
			weldL1.Part0 = torso
			weldL1.Part1 = legL_upper
			weldL1.C0 = CFrame.new(-0.5, -torso.Size.Y/2 - 0.75, 0) * CFrame.Angles(math.rad(-30), 0, 0)
			weldL1.Parent = legL_upper

			local weldL2 = Instance.new("Weld")
			weldL2.Part0 = legL_upper
			weldL2.Part1 = legL_lower
			weldL2.C0 = CFrame.new(0, -1.5, 0.3) * CFrame.Angles(math.rad(60), 0, 0)
			weldL2.Parent = legL_lower

			-- Right leg
			local legR_upper = legL_upper:Clone()
			legR_upper.Name = "Leg_R_Upper"
			legR_upper.Parent = parent

			local legR_lower = legL_lower:Clone()
			legR_lower.Name = "Leg_R_Lower"
			legR_lower.Parent = parent

			local weldR1 = Instance.new("Weld")
			weldR1.Part0 = torso
			weldR1.Part1 = legR_upper
			weldR1.C0 = CFrame.new(0.5, -torso.Size.Y/2 - 0.75, 0) * CFrame.Angles(math.rad(-30), 0, 0)
			weldR1.Parent = legR_upper

			local weldR2 = Instance.new("Weld")
			weldR2.Part0 = legR_upper
			weldR2.Part1 = legR_lower
			weldR2.C0 = CFrame.new(0, -1.5, 0.3) * CFrame.Angles(math.rad(60), 0, 0)
			weldR2.Parent = legR_lower

			return {legL_upper, legL_lower, legR_upper, legR_lower}, {health = 0, speed = 8, damage = 0} -- Fast!
		end
	},
	{
		name = "Spider", -- 4 legs
		build = function(parent, color, material, torso)
			local legs = {}

			for i = 1, 4 do
				local leg = Instance.new("Part")
				leg.Name = "SpiderLeg_" .. i
				leg.Size = Vector3.new(0.4, 3, 0.4)
				leg.Color = color
				leg.Material = material
				leg.Parent = parent

				local angle = ((i - 1) / 4) * math.pi - math.pi/2 -- Spread around
				local xOffset = math.cos(angle) * (torso.Size.X/2 + 0.3)
				local zOffset = math.sin(angle) * 0.8

				local weld = Instance.new("Weld")
				weld.Part0 = torso
				weld.Part1 = leg
				weld.C0 = CFrame.new(xOffset, -torso.Size.Y/2, zOffset) *
					CFrame.Angles(math.rad(20), angle, math.rad(30))
				weld.Parent = leg

				table.insert(legs, leg)
			end

			return legs, {health = 0, speed = 4, damage = 0}
		end
	},
	{
		name = "Stumpy",
		build = function(parent, color, material, torso)
			local legL = Instance.new("Part")
			legL.Name = "Leg_L"
			legL.Size = Vector3.new(1, 1.2, 1)
			legL.Color = color
			legL.Material = material
			legL.Parent = parent

			local weldL = Instance.new("Weld")
			weldL.Part0 = torso
			weldL.Part1 = legL
			weldL.C0 = CFrame.new(-0.6, -torso.Size.Y/2 - 0.6, 0)
			weldL.Parent = legL

			local legR = legL:Clone()
			legR.Name = "Leg_R"
			legR.Parent = parent

			local weldR = Instance.new("Weld")
			weldR.Part0 = torso
			weldR.Part1 = legR
			weldR.C0 = CFrame.new(0.6, -torso.Size.Y/2 - 0.6, 0)
			weldR.Parent = legR

			return {legL, legR}, {health = 10, speed = -8, damage = 0} -- Very slow
		end
	},
}

-- ════════════════════════════════════════════════════════════════════════════
-- MOB NAME GENERATION
-- ════════════════════════════════════════════════════════════════════════════
local Prefixes = {"Cursed", "Vile", "Shadow", "Blood", "Bone", "Dark", "Plague", "Rot", "Doom", "Wretched"}
local Suffixes = {"Fiend", "Lurker", "Stalker", "Horror", "Beast", "Brute", "Crawler", "Shambler", "Wraith", "Ghoul"}

local function generateMobName()
	local prefix = Prefixes[math.random(1, #Prefixes)]
	local suffix = Suffixes[math.random(1, #Suffixes)]
	return prefix .. " " .. suffix
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════
function MobGenerator.Generate(options)
	options = options or {}

	local mobModel = Instance.new("Model")
	mobModel.Name = options.name or generateMobName()

	-- Select random color and material
	local skinColor = options.color or Config.SkinColors[math.random(1, #Config.SkinColors)]
	local material = options.material or Config.Materials[math.random(1, #Config.Materials)]

	-- Track stat modifiers
	local stats = {
		health = Config.BaseHealth,
		speed = Config.BaseSpeed,
		damage = Config.BaseDamage,
	}

	-- Build torso first (anchor point)
	local torsoType = TorsoTypes[math.random(1, #TorsoTypes)]
	local torso, torsoStats = torsoType.build(mobModel, skinColor, material)
	stats.health = stats.health + torsoStats.health
	stats.speed = stats.speed + torsoStats.speed
	stats.damage = stats.damage + torsoStats.damage

	-- Build head
	local headType = HeadTypes[math.random(1, #HeadTypes)]
	local head, headStats = headType.build(mobModel, skinColor, material)
	stats.health = stats.health + headStats.health
	stats.speed = stats.speed + headStats.speed
	stats.damage = stats.damage + headStats.damage

	-- Attach head to torso
	local headWeld = Instance.new("Weld")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(0, torso.Size.Y/2 + head.Size.Y/2, 0)
	headWeld.Parent = head

	-- Build arms
	local armType = ArmTypes[math.random(1, #ArmTypes)]
	local arms, armStats = armType.build(mobModel, skinColor, material, torso)
	stats.health = stats.health + armStats.health
	stats.speed = stats.speed + armStats.speed
	stats.damage = stats.damage + armStats.damage

	-- Build legs
	local legType = LegTypes[math.random(1, #LegTypes)]
	local legs, legStats = legType.build(mobModel, skinColor, material, torso)
	stats.health = stats.health + legStats.health
	stats.speed = stats.speed + legStats.speed
	stats.damage = stats.damage + legStats.damage

	-- Apply scale
	local scale = options.scale or (Config.ScaleMin + math.random() * (Config.ScaleMax - Config.ScaleMin))
	for _, part in ipairs(mobModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scale
		end
	end

	-- Scale stats with size
	stats.health = math.floor(stats.health * scale)
	stats.damage = math.floor(stats.damage * scale)

	-- Ensure minimum values
	stats.health = math.max(10, stats.health)
	stats.speed = math.max(4, stats.speed)
	stats.damage = math.max(1, stats.damage)

	-- Set PrimaryPart
	mobModel.PrimaryPart = torso

	-- Store attributes
	mobModel:SetAttribute("Health", stats.health)
	mobModel:SetAttribute("MaxHealth", stats.health)
	mobModel:SetAttribute("Speed", stats.speed)
	mobModel:SetAttribute("Damage", stats.damage)
	mobModel:SetAttribute("HeadType", headType.name)
	mobModel:SetAttribute("TorsoType", torsoType.name)
	mobModel:SetAttribute("ArmType", armType.name)
	mobModel:SetAttribute("LegType", legType.name)
	mobModel:SetAttribute("Scale", scale)

	-- Add humanoid for pathfinding/animation
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = stats.health
	humanoid.Health = stats.health
	humanoid.WalkSpeed = stats.speed
	humanoid.Parent = mobModel

	-- Create HumanoidRootPart for proper character handling
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1) * scale
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = mobModel

	local hrpWeld = Instance.new("Weld")
	hrpWeld.Part0 = hrp
	hrpWeld.Part1 = torso
	hrpWeld.C0 = CFrame.new(0, 0, 0)
	hrpWeld.Parent = hrp

	mobModel.PrimaryPart = hrp

	print(string.format("[MobGenerator] Created '%s': HP=%d, SPD=%d, DMG=%d (Head:%s, Torso:%s, Arms:%s, Legs:%s)",
		mobModel.Name, stats.health, stats.speed, stats.damage,
		headType.name, torsoType.name, armType.name, legType.name))

	return mobModel, stats
end

function MobGenerator.SpawnAt(position, parent, options)
	local mob, stats = MobGenerator.Generate(options)
	if mob and mob.PrimaryPart then
		mob:SetPrimaryPartCFrame(CFrame.new(position))
		mob.Parent = parent or workspace
	end
	return mob, stats
end

function MobGenerator.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

function MobGenerator.GetConfig()
	return Config
end

return MobGenerator
