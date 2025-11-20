--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldGenerator
Location: ReplicatedStorage/src/
Description: Procedurally generates shields from 4 parts with 7 manufacturers each.
             Calculates stats, rarity, and special effects.
Version: 1.0
Last Updated: 2025-11-20
════════════════════════════════════════════════════════════════════════════════

Usage:
    local ShieldGenerator = require(ReplicatedStorage.src.ShieldGenerator)

    -- Generate random shield for level 10
    local shieldData = ShieldGenerator.Generate(10)

    -- Generate specific rarity shield
    local legendaryShield = ShieldGenerator.GenerateWithRarity(10, "Legendary")

Shield Data Structure:
    {
        Level = 10,
        Rarity = "Rare",
        Parts = {
            Capacitor = {Name="Aegis", ...},
            Generator = {Name="Flux", ...},
            Regulator = {Name="Rapid", ...},
            Projector = {Name="Nova", ...}
        },
        Stats = {
            Capacity = 250,
            RechargeRate = 18,
            RechargeDelay = 1.5,
            BreakEffectChance = 0.30,
            BreakEffect = "ExplosivePush"
        },
        Name = "Rare Aegis-Flux Shield Lv.10"
    }
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShieldParts = require(script.Parent.ShieldParts)

local ShieldGenerator = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Base stats (before part modifiers)
	BaseCapacity = 100,
	BaseRechargeRate = 10,
	BaseRechargeDelay = 2.0,

	-- Level scaling
	CapacityPerLevel = 10,      -- +10 capacity per level
	RechargePerLevel = 0.5,     -- +0.5 recharge rate per level

	-- Rarity multipliers
	RarityMultipliers = {
		Common = {Capacity = 0.8, RechargeRate = 0.9, RechargeDelay = 1.1},
		Uncommon = {Capacity = 1.0, RechargeRate = 1.0, RechargeDelay = 1.0},
		Rare = {Capacity = 1.2, RechargeRate = 1.1, RechargeDelay = 0.9},
		Epic = {Capacity = 1.5, RechargeRate = 1.3, RechargeDelay = 0.8},
		Legendary = {Capacity = 2.0, RechargeRate = 1.5, RechargeDelay = 0.7}
	},

	-- Rarity chances (cumulative)
	RarityChances = {
		{Rarity = "Common", Chance = 0.50},      -- 50%
		{Rarity = "Uncommon", Chance = 0.80},    -- 30%
		{Rarity = "Rare", Chance = 0.95},        -- 15%
		{Rarity = "Epic", Chance = 0.99},        -- 4%
		{Rarity = "Legendary", Chance = 1.00}    -- 1%
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- RARITY SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

local function rollRarity()
	local roll = math.random()

	for _, tier in ipairs(Config.RarityChances) do
		if roll <= tier.Chance then
			return tier.Rarity
		end
	end

	return "Common"
end

local function getRarityMultipliers(rarity)
	return Config.RarityMultipliers[rarity] or Config.RarityMultipliers.Common
end

-- ════════════════════════════════════════════════════════════════════════════
-- PART SELECTION
-- ════════════════════════════════════════════════════════════════════════════

local function selectParts()
	return {
		Capacitor = ShieldParts.GetRandomPart("Capacitor"),
		Generator = ShieldParts.GetRandomPart("Generator"),
		Regulator = ShieldParts.GetRandomPart("Regulator"),
		Projector = ShieldParts.GetRandomPart("Projector")
	}
end

local function selectPartsWithBias(rarity)
	-- Higher rarity = better chance for synergistic parts
	local parts = selectParts()

	-- Legendary shields get a reroll if parts don't synergize well
	if rarity == "Legendary" then
		local synergy = calculatePartSynergy(parts)
		if synergy < 0.7 then
			parts = selectParts() -- Reroll once
		end
	end

	return parts
end

-- Calculate how well parts work together (0-1 scale)
function calculatePartSynergy(parts)
	local synergy = 0.5 -- Base synergy

	-- High capacity + high recharge rate = good synergy
	if parts.Capacitor.CapacityMult > 1.2 and parts.Generator.RechargeRateMult > 1.2 then
		synergy = synergy + 0.2
	end

	-- Fast recharge delay + fast recharge rate = good synergy
	if parts.Regulator.RechargeDelayMult < 0.8 and parts.Generator.RechargeRateMult > 1.2 then
		synergy = synergy + 0.2
	end

	-- Special effect + high break chance = good synergy
	if parts.Projector.BreakEffect ~= "None" and parts.Projector.BreakEffectChance > 0.3 then
		synergy = synergy + 0.1
	end

	return math.clamp(synergy, 0, 1)
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

local function calculateStats(level, rarity, parts)
	local rarityMults = getRarityMultipliers(rarity)

	-- Base stats scaled by level
	local baseCapacity = Config.BaseCapacity + (Config.CapacityPerLevel * level)
	local baseRechargeRate = Config.BaseRechargeRate + (Config.RechargePerLevel * level)
	local baseRechargeDelay = Config.BaseRechargeDelay

	-- Apply rarity multipliers
	baseCapacity = baseCapacity * rarityMults.Capacity
	baseRechargeRate = baseRechargeRate * rarityMults.RechargeRate
	baseRechargeDelay = baseRechargeDelay * rarityMults.RechargeDelay

	-- Apply part multipliers
	local finalCapacity = baseCapacity
		* parts.Capacitor.CapacityMult
		* parts.Generator.CapacityMult
		* parts.Regulator.CapacityMult
		* parts.Projector.CapacityMult

	local finalRechargeRate = baseRechargeRate
		* parts.Capacitor.RechargeRateMult
		* parts.Generator.RechargeRateMult
		* parts.Regulator.RechargeRateMult
		* parts.Projector.RechargeRateMult

	local finalRechargeDelay = baseRechargeDelay
		* parts.Capacitor.RechargeDelayMult
		* parts.Generator.RechargeDelayMult
		* parts.Regulator.RechargeDelayMult
		* parts.Projector.RechargeDelayMult

	-- Aggregate break effect chance
	local breakEffectChance =
		parts.Capacitor.BreakEffectChance +
		parts.Generator.BreakEffectChance +
		parts.Regulator.BreakEffectChance +
		parts.Projector.BreakEffectChance

	-- Round to reasonable values
	finalCapacity = math.floor(finalCapacity)
	finalRechargeRate = math.floor(finalRechargeRate * 10) / 10 -- 1 decimal place
	finalRechargeDelay = math.floor(finalRechargeDelay * 10) / 10
	breakEffectChance = math.clamp(breakEffectChance, 0, 1)

	return {
		Capacity = finalCapacity,
		RechargeRate = finalRechargeRate,
		RechargeDelay = finalRechargeDelay,
		BreakEffectChance = breakEffectChance,

		-- Special effects from projector
		BreakEffect = parts.Projector.BreakEffect,
		BreakEffectRadius = parts.Projector.BreakEffectRadius,
		BreakEffectDamage = parts.Projector.BreakEffectDamage,
		BreakEffectDuration = parts.Projector.BreakEffectDuration or 0
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- NAME GENERATION
-- ════════════════════════════════════════════════════════════════════════════

local function generateName(rarity, parts, level)
	-- Format: "[Rarity] Capacitor-Generator Shield Lv.X"
	-- Example: "Legendary Aegis-Flux Shield Lv.10"

	local capacitorName = parts.Capacitor.Name
	local generatorName = parts.Generator.Name

	return string.format("%s %s-%s Shield Lv.%d",
		rarity,
		capacitorName,
		generatorName,
		level
	)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Generates a random shield for the given level
	@param level - Shield level (affects stats)
	@return shieldData - Complete shield data structure
]]
function ShieldGenerator.Generate(level)
	level = level or 1

	-- Roll rarity
	local rarity = rollRarity()

	-- Select parts
	local parts = selectPartsWithBias(rarity)

	-- Calculate stats
	local stats = calculateStats(level, rarity, parts)

	-- Generate name
	local name = generateName(rarity, parts, level)

	-- Build shield data
	local shieldData = {
		Level = level,
		Rarity = rarity,
		Parts = parts,
		Stats = stats,
		Name = name,
		Type = "Shield"
	}

	return shieldData
end

--[[
	Generates a shield with a specific rarity
	@param level - Shield level
	@param rarity - Desired rarity ("Common", "Uncommon", "Rare", "Epic", "Legendary")
	@return shieldData
]]
function ShieldGenerator.GenerateWithRarity(level, rarity)
	level = level or 1
	rarity = rarity or "Common"

	-- Validate rarity
	if not Config.RarityMultipliers[rarity] then
		warn("[ShieldGenerator] Invalid rarity:", rarity, "- defaulting to Common")
		rarity = "Common"
	end

	-- Select parts
	local parts = selectPartsWithBias(rarity)

	-- Calculate stats
	local stats = calculateStats(level, rarity, parts)

	-- Generate name
	local name = generateName(rarity, parts, level)

	-- Build shield data
	local shieldData = {
		Level = level,
		Rarity = rarity,
		Parts = parts,
		Stats = stats,
		Name = name,
		Type = "Shield"
	}

	return shieldData
end

--[[
	Generates a shield from specific part names
	@param level - Shield level
	@param partNames - Table with {Capacitor="Aegis", Generator="Flux", ...}
	@return shieldData or nil if parts not found
]]
function ShieldGenerator.GenerateFromParts(level, partNames)
	level = level or 1

	local parts = {}

	-- Lookup each part
	for partType, partName in pairs(partNames) do
		local part = ShieldParts.GetPartByName(partType, partName)
		if not part then
			warn("[ShieldGenerator] Part not found:", partType, partName)
			return nil
		end
		parts[partType] = part
	end

	-- Auto-determine rarity based on part quality
	local rarity = "Rare" -- Default for custom builds

	-- Calculate stats
	local stats = calculateStats(level, rarity, parts)

	-- Generate name
	local name = generateName(rarity, parts, level)

	return {
		Level = level,
		Rarity = rarity,
		Parts = parts,
		Stats = stats,
		Name = name,
		Type = "Shield"
	}
end

--[[
	Prints shield information for debugging
	@param shieldData - Shield data structure
]]
function ShieldGenerator.PrintShieldInfo(shieldData)
	print("\n" .. string.rep("=", 60))
	print("SHIELD:", shieldData.Name)
	print(string.rep("=", 60))
	print(string.format("Level: %d | Rarity: %s", shieldData.Level, shieldData.Rarity))
	print("\nParts:")
	print(string.format("  Capacitor: %s", shieldData.Parts.Capacitor.Name))
	print(string.format("  Generator: %s", shieldData.Parts.Generator.Name))
	print(string.format("  Regulator: %s", shieldData.Parts.Regulator.Name))
	print(string.format("  Projector: %s", shieldData.Parts.Projector.Name))
	print("\nStats:")
	print(string.format("  Capacity: %d HP", shieldData.Stats.Capacity))
	print(string.format("  Recharge Rate: %.1f HP/s", shieldData.Stats.RechargeRate))
	print(string.format("  Recharge Delay: %.1fs", shieldData.Stats.RechargeDelay))
	print(string.format("  Break Effect Chance: %.0f%%", shieldData.Stats.BreakEffectChance * 100))
	print(string.format("  Break Effect: %s", shieldData.Stats.BreakEffect))
	if shieldData.Stats.BreakEffectRadius > 0 then
		print(string.format("    - Radius: %d studs", shieldData.Stats.BreakEffectRadius))
	end
	if shieldData.Stats.BreakEffectDamage ~= 0 then
		print(string.format("    - Damage: %d", shieldData.Stats.BreakEffectDamage))
	end
	if shieldData.Stats.BreakEffectDuration > 0 then
		print(string.format("    - Duration: %.1fs", shieldData.Stats.BreakEffectDuration))
	end
	print(string.rep("=", 60) .. "\n")
end

--[[
	Configuration setters
]]
function ShieldGenerator.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

function ShieldGenerator.GetConfig()
	return Config
end

return ShieldGenerator
