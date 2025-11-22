--[[
════════════════════════════════════════════════════════════════════════════════
Module: BL2Calculator
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Authentic Borderlands 2 stat calculation system.
             Implements PreAdd/Scale/PostAdd formula for weapon stats.
             Based on bl2.parts data and BL2 calculation mechanics.

Formula: Final = [(Base + PreAdd) × (1 + Positive Scale)÷(1 − Negative Scale)] + PostAdd

Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local BL2Calculator = {}

--[[
	BL2 Calculation System:
	The game uses four types of bonuses:

	1. PreAdd - Added to base value first
	2. Scale - Multiplies (Base + PreAdd) - can be positive or negative
	3. PostAdd - Added after all scaling
	4. Grade - Special initialization bonuses (evaluated before other modifiers)

	Formula: Final = [(Base + PreAdd) × (1 + Positive Scale)÷(1 − Negative Scale)] + PostAdd
]]

-- ════════════════════════════════════════════════════════════════════════════
-- BONUS ACCUMULATOR
-- ════════════════════════════════════════════════════════════════════════════

local function accumulateBonuses(parts, statName)
	local bonuses = {
		PreAdd = 0,
		PositiveScale = 0,
		NegativeScale = 0,
		PostAdd = 0
	}

	for _, part in ipairs(parts) do
		if part and part.Modifiers then
			local modifiers = part.Modifiers

			-- Handle different modifier naming conventions
			local scaleKey = statName .. "Scale"
			local preAddKey = statName .. "PreAdd"
			local postAddKey = statName .. "PostAdd"
			local addKey = statName .. "Add"

			-- Accumulate PreAdd bonuses
			if modifiers[preAddKey] then
				bonuses.PreAdd = bonuses.PreAdd + modifiers[preAddKey]
			elseif modifiers[addKey] then
				bonuses.PreAdd = bonuses.PreAdd + modifiers[addKey]
			end

			-- Accumulate Scale bonuses
			if modifiers[scaleKey] then
				local scale = modifiers[scaleKey]
				if scale > 1.0 then
					-- Positive scale (multiply)
					bonuses.PositiveScale = bonuses.PositiveScale + (scale - 1.0)
				elseif scale < 1.0 then
					-- Negative scale (divide) - convert to negative scale value
					bonuses.NegativeScale = bonuses.NegativeScale + (1.0 - scale)
				end
			end

			-- Accumulate PostAdd bonuses
			if modifiers[postAddKey] then
				bonuses.PostAdd = bonuses.PostAdd + modifiers[postAddKey]
			end
		end
	end

	return bonuses
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Calculate a single stat using BL2 formula
	@param baseValue - The base stat value
	@param parts - Array of weapon parts with Modifiers
	@param statName - Name of the stat (e.g., "Damage", "FireRate", "Accuracy")
	@return finalValue - Calculated stat value
]]
function BL2Calculator:CalculateStat(baseValue, parts, statName)
	local bonuses = accumulateBonuses(parts, statName)

	-- Apply BL2 formula: Final = [(Base + PreAdd) × (1 + PositiveScale)÷(1 − NegativeScale)] + PostAdd
	local intermediate = baseValue + bonuses.PreAdd
	intermediate = intermediate * (1 + bonuses.PositiveScale)

	-- Prevent division by zero or negative
	if bonuses.NegativeScale < 1.0 then
		intermediate = intermediate / (1 - bonuses.NegativeScale)
	else
		-- Cap negative scale to prevent inverse stats
		intermediate = intermediate / 0.01
	end

	local final = intermediate + bonuses.PostAdd

	return final
end

-- ════════════════════════════════════════════════════════════════════════════
-- BATCH STAT CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Calculate all weapon stats from base stats and parts
	@param baseStats - Table of base weapon stats
	@param parts - Array of weapon parts (includes: Manufacturer, Stock, Body, Barrel, Magazine, Sight, Accessory)
	@param level - Weapon level for scaling
	@return stats - Complete calculated stats table
]]
function BL2Calculator:CalculateAllStats(baseStats, parts, level)
	local stats = {}

	-- Core combat stats (use BL2 formula)
	stats.Damage = self:CalculateStat(baseStats.Damage, parts, "Damage")
	stats.FireRate = self:CalculateStat(baseStats.FireRate, parts, "FireRate")
	stats.Capacity = self:CalculateStat(baseStats.Capacity, parts, "Magazine")
	stats.Accuracy = self:CalculateStat(baseStats.Accuracy, parts, "Accuracy")
	stats.ReloadTime = self:CalculateStat(baseStats.ReloadTime, parts, "Reload")

	-- Copy direct stats
	stats.Range = baseStats.Range or 300
	stats.Pellets = baseStats.Pellets or 1
	stats.BloomPerShot = baseStats.BloomPerShot or 0.5
	stats.MaxBloom = baseStats.MaxBloom or 10
	stats.CurrentAmmo = math.floor(stats.Capacity)

	-- Accumulate additive stats (crit, special effects, etc.)
	stats.CritChance = 0
	stats.CritDamage = 0
	stats.HeadshotBonus = 0
	stats.Stability = 0
	stats.RecoilReduction = 0
	stats.ElementalDamage = 0
	stats.ElementalChance = 1.0
	stats.SplashDamage = 0
	stats.PenetrationChance = 0
	stats.SoulGain = 0
	stats.KillHeal = 0

	for _, part in ipairs(parts) do
		if part and part.Modifiers then
			local mods = part.Modifiers

			-- Additive stats
			if mods.CritChance then stats.CritChance = stats.CritChance + mods.CritChance end
			if mods.CritDamage then stats.CritDamage = stats.CritDamage + mods.CritDamage end
			if mods.HeadshotBonus then stats.HeadshotBonus = stats.HeadshotBonus + mods.HeadshotBonus end
			if mods.Stability then stats.Stability = stats.Stability + mods.Stability end
			if mods.RecoilReduction then stats.RecoilReduction = stats.RecoilReduction + mods.RecoilReduction end
			if mods.ElementalDamage then stats.ElementalDamage = stats.ElementalDamage + mods.ElementalDamage end
			if mods.ElementalChance then stats.ElementalChance = stats.ElementalChance * mods.ElementalChance end
			if mods.SplashDamage then stats.SplashDamage = stats.SplashDamage + mods.SplashDamage end
			if mods.PenetrationChance then stats.PenetrationChance = stats.PenetrationChance + mods.PenetrationChance end
			if mods.SoulGain then stats.SoulGain = stats.SoulGain + mods.SoulGain end
			if mods.KillHeal then stats.KillHeal = stats.KillHeal + mods.KillHeal end
			if mods.Range then stats.Range = stats.Range + mods.Range end
		end
	end

	-- Apply level scaling to damage (BL2 formula: 1.13^level)
	-- Note: WeaponStats.lua already does this, so we'll keep it consistent
	local levelMod = 1.13 ^ (level - 1)
	stats.Damage = math.floor(stats.Damage * levelMod)

	-- Round and clamp values
	stats.Capacity = math.max(1, math.floor(stats.Capacity))
	stats.Accuracy = math.clamp(stats.Accuracy, 0, 100)
	stats.FireRate = math.max(0.05, stats.FireRate)
	stats.ReloadTime = math.max(0.5, stats.ReloadTime)
	stats.Pellets = math.max(1, math.floor(stats.Pellets))

	-- Calculate DPS
	stats.DPS = math.floor((stats.Damage * stats.Pellets) / stats.FireRate)

	return stats
end

-- ════════════════════════════════════════════════════════════════════════════
-- STAT EXPLANATION (DEBUG)
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Explain how a stat was calculated (for debugging)
	@param baseValue - The base stat value
	@param parts - Array of weapon parts
	@param statName - Name of the stat
	@return explanation - String explaining the calculation
]]
function BL2Calculator:ExplainCalculation(baseValue, parts, statName)
	local bonuses = accumulateBonuses(parts, statName)

	local lines = {
		string.format("%s Calculation:", statName),
		string.format("  Base: %.2f", baseValue),
		string.format("  PreAdd: %.2f", bonuses.PreAdd),
		string.format("  Positive Scale: %.2f%% (+%.2f)", bonuses.PositiveScale * 100, bonuses.PositiveScale),
		string.format("  Negative Scale: %.2f%% (-%.2f)", bonuses.NegativeScale * 100, bonuses.NegativeScale),
		string.format("  PostAdd: %.2f", bonuses.PostAdd),
		string.format("  Formula: [(%.2f + %.2f) × %.2f ÷ %.2f] + %.2f",
			baseValue,
			bonuses.PreAdd,
			1 + bonuses.PositiveScale,
			1 - bonuses.NegativeScale,
			bonuses.PostAdd
		),
		string.format("  Final: %.2f", self:CalculateStat(baseValue, parts, statName))
	}

	return table.concat(lines, "\n")
end

return BL2Calculator
