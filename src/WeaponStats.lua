--[[
	WeaponStats.lua
	BL2-Accurate Stat Calculation System

	Calculates final weapon statistics from:
	- Base weapon type stats
	- Manufacturer modifiers
	- Part modifiers (barrel, grip, stock, magazine, sight, accessory)
	- Rarity bonuses (damage boost like +2 levels per rarity tier)
	- Element damage
	- Level scaling (1.13× per level - BL2 formula)
]]

local WeaponConfig = require(script.Parent.WeaponConfig)

local WeaponStats = {}

--[[
	Calculate BL2-accurate level scaling
	Formula: BaseDamage * (1.13 ^ (level - 1))

	This means:
	- Level 1: 1.0×
	- Level 10: 3.0×
	- Level 20: 8.95×
	- Level 50: 247.7×
	- Level 80: 5787.2×
]]
local function ApplyLevelScaling(baseStat, level)
	return baseStat * (WeaponConfig.LEVEL_SCALE_MULTIPLIER ^ (level - 1))
end

--[[
	Apply rarity damage bonus (each rarity tier = ~2 levels of damage)
]]
local function ApplyRarityBonus(damage, rarity)
	if not rarity or not rarity.DamageBonus then
		return damage
	end

	-- Each rarity bonus level adds equivalent of 2 weapon levels
	local bonusMultiplier = WeaponConfig.LEVEL_SCALE_MULTIPLIER ^ rarity.DamageBonus
	return damage * bonusMultiplier
end

--[[
	Main stat calculation function (BL2-accurate)

	@param body - Body part
	@param barrel - Barrel part
	@param grip - Grip part
	@param stock - Stock part
	@param magazine - Magazine part
	@param sight - Sight part
	@param accessory - Accessory part (optional)
	@param manufacturer - Manufacturer data
	@param rarity - Rarity data
	@param element - Element data (optional)
	@param level - Weapon level
	@return stats - Complete stat table
]]
function WeaponStats.CalculateStats(body, barrel, grip, stock, magazine, sight, accessory, manufacturer, rarity, element, level)
	-- Get base weapon type stats
	local weaponType = WeaponConfig.WeaponTypes[body.Type]
	if not weaponType then
		warn("Invalid weapon type:", body.Type)
		return nil
	end

	-- Initialize stats from weapon type base
	local stats = {
		-- Combat stats
		Damage = weaponType.BaseDamage,
		FireRate = weaponType.BaseFireRate,
		Accuracy = weaponType.BaseAccuracy,
		Range = 1.0,
		ReloadTime = weaponType.BaseReloadTime,
		MagazineSize = weaponType.BaseMagazineSize,
		CritMultiplier = weaponType.BaseCritMultiplier,

		-- Control stats
		RecoilControl = 1.0,
		AimSpeed = 1.0,
		MovementSpeed = 1.0,

		-- Special stats
		CritChance = 0,
		CritDamage = 0,
		PelletCount = weaponType.PelletCount or 1,
		ZoomLevel = 1.0,

		-- Element stats (if applicable)
		ElementalDamage = 0,
		DOTDamage = 0,
		DOTDuration = 0,
		ProcChance = 0,

		-- Misc
		MeleeDamage = 1.0,
		LifeSteal = 0,
		SplashDamage = 0,
		SplashRadius = 0
	}

	-- Collect all modifying parts
	local parts = {body, barrel, grip, stock, magazine, sight}
	if accessory then
		table.insert(parts, accessory)
	end

	-- Apply part modifiers (multiplicative)
	for _, part in ipairs(parts) do
		if part and part.StatModifiers then
			for statName, modifier in pairs(part.StatModifiers) do
				if stats[statName] ~= nil then
					-- Multiplicative for most stats
					if type(stats[statName]) == "number" then
						if statName == "CritChance" or statName == "CritDamage" or statName == "LifeSteal" then
							-- Additive for these stats
							stats[statName] = stats[statName] + modifier
						else
							stats[statName] = stats[statName] * modifier
						end
					end
				else
					-- New stat from part
					stats[statName] = modifier
				end
			end
		end
	end

	-- Apply manufacturer modifiers
	if manufacturer and manufacturer.StatModifiers then
		for statName, modifier in pairs(manufacturer.StatModifiers) do
			if stats[statName] ~= nil then
				if statName == "ElementalDamage" then
					stats[statName] = modifier -- Special case
				elseif type(stats[statName]) == "number" then
					stats[statName] = stats[statName] * modifier
				end
			else
				stats[statName] = modifier
			end
		end
	end

	-- Apply level scaling to damage (BL2 formula: 1.13^level)
	stats.Damage = ApplyLevelScaling(stats.Damage, level)

	-- Apply rarity damage bonus (each tier = ~2 levels)
	stats.Damage = ApplyRarityBonus(stats.Damage, rarity)

	-- Apply mythic bonus (15% to all stats)
	if rarity and rarity.BonusStat then
		stats.Damage = stats.Damage * rarity.BonusStat
		stats.FireRate = stats.FireRate * rarity.BonusStat
		stats.Accuracy = stats.Accuracy * rarity.BonusStat
	end

	-- Apply element effects
	if element then
		-- Element adds DOT and proc chance
		stats.ElementalDamage = stats.Damage * (stats.ElementalDamage or 0.5) -- Default 50% of damage as elemental
		stats.DOTDamage = element.DOTDamage or 0
		stats.DOTDuration = element.DOTDuration or 0
		stats.ProcChance = (element.ProcChance or 0.15) + (stats.ProcChance or 0)

		-- Element multipliers
		if element.ShieldMultiplier then
			stats.ShieldMultiplier = element.ShieldMultiplier
		end
		if element.ArmorMultiplier then
			stats.ArmorMultiplier = element.ArmorMultiplier
		end
		if element.SplashDamage then
			stats.SplashDamage = element.SplashDamage
			stats.SplashRadius = element.SplashRadius or 3
		end
	end

	-- Round certain stats
	stats.MagazineSize = math.floor(stats.MagazineSize + 0.5)
	stats.PelletCount = math.max(1, math.floor(stats.PelletCount + 0.5))
	stats.Damage = math.floor(stats.Damage + 0.5)
	if stats.ElementalDamage > 0 then
		stats.ElementalDamage = math.floor(stats.ElementalDamage + 0.5)
	end

	-- Clamp values
	stats.Accuracy = math.clamp(stats.Accuracy, 0, 1)
	stats.CritChance = math.clamp(stats.CritChance, 0, 1)
	stats.ProcChance = math.clamp(stats.ProcChance, 0, 1)

	return stats
end

--[[
	Calculate DPS (Damage Per Second)
	Takes into account: damage, fire rate, crit chance/damage, pellets
]]
function WeaponStats.CalculateDPS(stats)
	if not stats then return 0 end

	-- Base DPS
	local baseDPS = stats.Damage * stats.FireRate

	-- Factor in critical hits
	-- Average damage = base * (1 + critChance * critMultiplier)
	local critMultiplier = stats.CritChance * (stats.CritMultiplier - 1)
	local effectiveDamageMultiplier = 1 + critMultiplier

	-- Factor in pellet count (for shotguns)
	local pelletMultiplier = stats.PelletCount or 1

	-- Calculate effective DPS
	local effectiveDPS = baseDPS * effectiveDamageMultiplier * pelletMultiplier

	-- Add elemental DPS if applicable
	if stats.ElementalDamage and stats.ElementalDamage > 0 then
		-- Element adds both direct damage and DOT
		local elementDirectDPS = stats.ElementalDamage * stats.FireRate * stats.ProcChance
		local elementDOTDPS = 0

		if stats.DOTDuration and stats.DOTDuration > 0 and stats.DOTDamage then
			-- DOT damage per second = (damage * dotDamage) over duration
			elementDOTDPS = (stats.Damage * stats.DOTDamage) * stats.ProcChance
		end

		effectiveDPS = effectiveDPS + elementDirectDPS + elementDOTDPS
	end

	-- Add splash damage if applicable (explosive weapons)
	if stats.SplashDamage and stats.SplashDamage > 0 then
		effectiveDPS = effectiveDPS * (1 + stats.SplashDamage)
	end

	return effectiveDPS
end

--[[
	Get stat grade letter (F to S)
]]
function WeaponStats.GetStatGrade(statName, value)
	local gradeThresholds = {
		Damage = {S = 1000, A = 500, B = 250, C = 100, D = 50},
		FireRate = {S = 12, A = 9, B = 6, C = 4, D = 2},
		Accuracy = {S = 0.95, A = 0.85, B = 0.75, C = 0.65, D = 0.5},
		ReloadTime = {S = 1.5, A = 2.0, B = 2.5, C = 3.0, D = 4.0}, -- Lower is better
		MagazineSize = {S = 60, A = 40, B = 25, C = 15, D = 10},
		DPS = {S = 10000, A = 5000, B = 2500, C = 1000, D = 500}
	}

	local thresholds = gradeThresholds[statName]
	if not thresholds then return "?" end

	-- For reload time, lower is better
	if statName == "ReloadTime" then
		if value <= thresholds.S then return "S" end
		if value <= thresholds.A then return "A" end
		if value <= thresholds.B then return "B" end
		if value <= thresholds.C then return "C" end
		if value <= thresholds.D then return "D" end
		return "F"
	else
		-- For other stats, higher is better
		if value >= thresholds.S then return "S" end
		if value >= thresholds.A then return "A" end
		if value >= thresholds.B then return "B" end
		if value >= thresholds.C then return "C" end
		if value >= thresholds.D then return "D" end
		return "F"
	end
end

--[[
	Compare two weapons and return which is better
	Returns: 1 if weapon1 is better, 2 if weapon2 is better, 0 if equal
]]
function WeaponStats.CompareWeapons(weapon1, weapon2)
	if not weapon1 or not weapon2 then return 0 end

	local dps1 = weapon1.DPS or WeaponStats.CalculateDPS(weapon1.Stats)
	local dps2 = weapon2.DPS or WeaponStats.CalculateDPS(weapon2.Stats)

	if dps1 > dps2 then
		return 1
	elseif dps2 > dps1 then
		return 2
	else
		return 0
	end
end

return WeaponStats
