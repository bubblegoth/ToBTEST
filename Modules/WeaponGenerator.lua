--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponGenerator
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Procedural Borderlands-style weapon generation system.
             Generates weapons from modular parts with rarity system.
             6 rarities: Common, Uncommon, Rare, Epic, Legendary, Mythic.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local WeaponGenerator = {}

local WeaponParts = require(script.Parent.WeaponParts)
local BL2Calculator = require(script.Parent.BL2Calculator)

-- ============================================================
-- RARITY SYSTEM
-- ============================================================

-- Rarity weights for loot drops
local RarityWeights = {
	Common = 50,
	Uncommon = 30,
	Rare = 15,
	Epic = 4,
	Legendary = 0.9,
	Mythic = 0.1
}

-- Rarity color codes
local RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(50, 205, 50),
	Rare = Color3.fromRGB(30, 144, 255),
	Epic = Color3.fromRGB(138, 43, 226),
	Legendary = Color3.fromRGB(255, 215, 0),
	Mythic = Color3.fromRGB(255, 50, 50)
}

-- Random number generator
local rng = Random.new()

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

function WeaponGenerator.SetSeed(seed)
	rng = Random.new(seed)
end

function WeaponGenerator:RollRarity(luckModifier)
	luckModifier = luckModifier or 0

	local totalWeight = 0
	for _, weight in pairs(RarityWeights) do
		totalWeight = totalWeight + weight
	end

	local roll = rng:NextNumber() * totalWeight * (1 + luckModifier)

	local cumulative = 0
	for rarity, weight in pairs(RarityWeights) do
		cumulative = cumulative + weight
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common"
end

function WeaponGenerator:RarityValue(rarity)
	local values = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6
	}
	return values[rarity] or 1
end

function WeaponGenerator:GetRandomPart(partType, maxRarity, weaponTypeName)
	local parts = WeaponParts[partType]
	if not parts then return nil end

	-- Filter by rarity and weapon type compatibility
	local validParts = {}
	for _, part in ipairs(parts) do
		local rarityValid = self:RarityValue(part.Rarity or "Common") <= self:RarityValue(maxRarity)
		local typeValid = true

		-- Check if part has CompatibleTypes restriction
		if part.CompatibleTypes and weaponTypeName then
			typeValid = false
			for _, compatibleType in ipairs(part.CompatibleTypes) do
				if compatibleType == weaponTypeName then
					typeValid = true
					break
				end
			end
		end

		if rarityValid and typeValid then
			table.insert(validParts, part)
		end
	end

	if #validParts == 0 then return parts[1] end

	return validParts[rng:NextInteger(1, #validParts)]
end

function WeaponGenerator:GetWeaponRarity(parts)
	local highestValue = 0
	local highestRarity = "Common"

	for _, part in pairs(parts) do
		if part and part.Rarity then
			local value = self:RarityValue(part.Rarity)
			if value > highestValue then
				highestValue = value
				highestRarity = part.Rarity
			end
		end
	end

	return highestRarity
end

-- ============================================================
-- WEAPON GENERATION
-- ============================================================

function WeaponGenerator:GenerateWeapon(level, baseTypeName, forcedRarity)
	level = level or 1

	-- Determine overall rarity
	local maxRarity = forcedRarity or self:RollRarity(level / 100)

	-- Select base weapon type
	local baseTypes = WeaponParts.BaseTypes
	local base
	if baseTypeName then
		for _, bt in ipairs(baseTypes) do
			if bt.Name == baseTypeName then
				base = bt
				break
			end
		end
	end
	if not base then
		base = baseTypes[rng:NextInteger(1, #baseTypes)]
	end

	-- Select parts (filtered by weapon type for compatibility)
	local parts = {
		Base = base,
		Manufacturer = WeaponParts.Manufacturers[rng:NextInteger(1, #WeaponParts.Manufacturers)],
		Stock = self:GetRandomPart("Stocks", maxRarity, base.Name),
		Body = self:GetRandomPart("Bodies", maxRarity, base.Name),
		Barrel = self:GetRandomPart("Barrels", maxRarity, base.Name),
		Magazine = self:GetRandomPart("Magazines", maxRarity, base.Name),
		Sight = self:GetRandomPart("Sights", maxRarity, base.Name),
		Accessory = self:GetRandomPart("Accessories", maxRarity, base.Name)
	}

	-- Build weapon stats
	local weapon = self:BuildWeaponStats(parts, level)
	weapon.Parts = parts
	weapon.Level = level
	weapon.Rarity = self:GetWeaponRarity(parts)
	weapon.Manufacturer = parts.Manufacturer.Name

	-- Generate weapon name
	weapon.Name = self:GenerateWeaponName(parts)

	return weapon
end

-- ============================================================
-- STAT CALCULATION (BL2-Accurate with PreAdd/Scale/PostAdd)
-- ============================================================

function WeaponGenerator:BuildWeaponStats(parts, level)
	local base = parts.Base.BaseStats

	-- Collect all parts that modify stats (order matters for BL2 calculations)
	local partsList = {
		parts.Manufacturer, -- Grip in BL2
		parts.Barrel,
		parts.Stock,
		parts.Body,
		parts.Magazine,
		parts.Sight,
		parts.Accessory
	}

	-- Use BL2Calculator for core stats
	local stats = BL2Calculator:CalculateAllStats(base, partsList, level)

	-- BL2Calculator handles:
	-- - Damage (with level scaling)
	-- - FireRate
	-- - Capacity (Magazine)
	-- - Accuracy
	-- - ReloadTime
	-- - DPS
	-- - All additive stats (CritChance, CritDamage, etc.)

	-- Add weapon type name for reference
	stats.WeaponType = parts.Base.Name

	return stats
end

-- ============================================================
-- WEAPON NAMING
-- ============================================================

function WeaponGenerator:GenerateWeaponName(parts)
	local manufacturer = parts.Manufacturer.Name
	local baseName = parts.Base.Name

	-- Get most unique part for flavor
	local flavorPart = parts.Accessory
	if not flavorPart or flavorPart.Name == "None" then
		flavorPart = parts.Barrel
	end

	-- Name formats
	local formats = {
		manufacturer .. " " .. baseName,
		baseName .. " (" .. manufacturer .. ")",
		"The " .. flavorPart.Name:gsub(" ", " ") .. " " .. baseName,
		manufacturer .. "'s " .. baseName
	}

	return formats[rng:NextInteger(1, #formats)]
end

-- ============================================================
-- WEAPON DESCRIPTION
-- ============================================================

function WeaponGenerator:GenerateDescription(weapon)
	local parts = weapon.Parts
	local lines = {
		"Level " .. weapon.Level .. " " .. weapon.Rarity .. " " .. parts.Base.Name,
		"",
		"Manufacturer: " .. parts.Manufacturer.Name,
		"  " .. parts.Manufacturer.Bonus,
		"",
		"Parts:",
		"  Stock: " .. parts.Stock.Name .. " - " .. parts.Stock.Description,
		"  Body: " .. parts.Body.Name .. " - " .. parts.Body.Description,
		"  Barrel: " .. parts.Barrel.Name .. " - " .. parts.Barrel.Description,
		"  Magazine: " .. parts.Magazine.Name .. " - " .. parts.Magazine.Description,
		"  Sight: " .. parts.Sight.Name .. " - " .. parts.Sight.Description,
		"  Accessory: " .. parts.Accessory.Name .. " - " .. parts.Accessory.Description,
		"",
		"Stats:",
		string.format("  Damage: %.0f x%d", weapon.Damage, weapon.Pellets),
		string.format("  DPS: %.0f", weapon.DPS),
		string.format("  Fire Rate: %.2f shots/s", 1/weapon.FireRate),
		string.format("  Accuracy: %.0f%%", weapon.Accuracy),
		string.format("  Magazine: %d rounds", weapon.Capacity),
		string.format("  Range: %.0f studs", weapon.Range),
		string.format("  Reload: %.1fs", weapon.ReloadTime)
	}

	-- Add special stats if they exist (default to 0 if nil)
	if (weapon.CritChance or 0) > 0 then
		table.insert(lines, string.format("  Crit Chance: +%.0f%%", weapon.CritChance))
	end
	if (weapon.CritDamage or 0) > 0 then
		table.insert(lines, string.format("  Crit Damage: +%.0f%%", weapon.CritDamage))
	end
	if (weapon.SoulGain or 0) > 0 then
		table.insert(lines, string.format("  Soul Gain: +%.0f", weapon.SoulGain))
	end
	if (weapon.KillHeal or 0) > 0 then
		table.insert(lines, string.format("  Heal on Kill: +%.0f", weapon.KillHeal))
	end

	-- Add elemental damage (default to 0 if nil to prevent comparison errors)
	if (weapon.FireDamage or 0) > 0 then
		table.insert(lines, string.format("  Fire Damage: +%.0f%%", weapon.FireDamage))
	end
	if (weapon.FrostDamage or 0) > 0 then
		table.insert(lines, string.format("  Frost Damage: +%.0f%%", weapon.FrostDamage))
	end
	if (weapon.ShadowDamage or 0) > 0 then
		table.insert(lines, string.format("  Shadow Damage: +%.0f%%", weapon.ShadowDamage))
	end
	if (weapon.LightDamage or 0) > 0 then
		table.insert(lines, string.format("  Light Damage: +%.0f%%", weapon.LightDamage))
	end
	if (weapon.VoidDamage or 0) > 0 then
		table.insert(lines, string.format("  Void Damage: +%.0f%%", weapon.VoidDamage))
	end

	return table.concat(lines, "\n")
end

-- ============================================================
-- WEAPON CARD (UI DATA)
-- ============================================================

function WeaponGenerator:GetWeaponCard(weapon)
	return {
		Name = weapon.Name,
		Level = weapon.Level,
		Rarity = weapon.Rarity,
		Color = RarityColors[weapon.Rarity],
		Type = weapon.Parts.Base.Name,
		Manufacturer = weapon.Parts.Manufacturer.Name,
		ManufacturerColor = weapon.Parts.Manufacturer.Color,
		Description = self:GenerateDescription(weapon),
		Stats = {
			Damage = weapon.Damage,
			DPS = weapon.DPS,
			FireRate = 1 / weapon.FireRate,
			Accuracy = weapon.Accuracy,
			Capacity = weapon.Capacity,
			Range = weapon.Range,
			ReloadTime = weapon.ReloadTime
		}
	}
end

-- ============================================================
-- WEAPON COMPARISON
-- ============================================================

function WeaponGenerator:CompareWeapons(weapon1, weapon2)
	local comparison = {}

	local stats = {"Damage", "DPS", "FireRate", "Accuracy", "Capacity", "Range", "ReloadTime"}

	for _, stat in ipairs(stats) do
		local val1 = weapon1[stat] or 0
		local val2 = weapon2[stat] or 0
		local diff = val2 - val1

		-- For FireRate and ReloadTime, lower is better
		local better = diff > 0
		if stat == "FireRate" or stat == "ReloadTime" then
			better = diff < 0
		end

		comparison[stat] = {
			Current = val1,
			New = val2,
			Difference = diff,
			Better = better
		}
	end

	return comparison
end

-- ============================================================
-- BATCH GENERATION (TESTING)
-- ============================================================

function WeaponGenerator:GenerateMultiple(count, level)
	local weapons = {}
	for i = 1, count do
		table.insert(weapons, self:GenerateWeapon(level))
	end
	return weapons
end

function WeaponGenerator:GenerateByRarity(rarity, level)
	return self:GenerateWeapon(level, nil, rarity)
end

return WeaponGenerator
