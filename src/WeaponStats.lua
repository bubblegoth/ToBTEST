--[[
	WeaponStats.lua
	Calculates final weapon statistics from parts and modifiers
]]

local WeaponConfig = require(script.Parent.WeaponConfig)

local WeaponStats = {}

-- Default stat structure
local DEFAULT_STATS = {
	-- Base combat stats
	Damage = 0,
	FireRate = 0,
	Accuracy = 0,
	Range = 1.0,
	ReloadTime = 0,
	MagazineSize = 0,

	-- Control stats
	RecoilControl = 1.0,
	AimSpeed = 1.0,
	MovementSpeed = 1.0,

	-- Special stats
	CritChance = 0,
	CritDamage = 0,
	PelletCount = 1,
	ZoomLevel = 1.0,

	-- Level requirement
	Level = 1
}

--[[
	Calculate final weapon stats from parts
	@param body - Body part data
	@param barrel - Barrel part data
	@param grip - Grip part data
	@param stock - Stock part data
	@param magazine - Magazine part data
	@param sight - Sight part data
	@param rarity - Rarity data from WeaponConfig
	@return table - Final calculated stats
]]
function WeaponStats.CalculateStats(body, barrel, grip, stock, magazine, sight, rarity)
	local weaponType = WeaponConfig.WeaponTypes[body.Type]
	if not weaponType then
		warn("Invalid weapon type:", body.Type)
		return DEFAULT_STATS
	end

	-- Start with base stats from weapon type
	local stats = {
		Damage = weaponType.BaseDamage,
		FireRate = weaponType.BaseFireRate,
		Accuracy = weaponType.BaseAccuracy,
		Range = 1.0,
		ReloadTime = weaponType.BaseReloadTime,
		MagazineSize = weaponType.BaseMagazineSize,
		RecoilControl = 1.0,
		AimSpeed = 1.0,
		MovementSpeed = 1.0,
		CritChance = 0,
		CritDamage = 0,
		PelletCount = weaponType.PelletCount or 1,
		ZoomLevel = 1.0,
		Level = 1
	}

	-- Collect all parts for processing
	local parts = {body, barrel, grip, stock, magazine, sight}

	-- Apply modifiers from all parts (multiplicative)
	for _, part in ipairs(parts) do
		if part and part.StatModifiers then
			for statName, modifier in pairs(part.StatModifiers) do
				if stats[statName] then
					stats[statName] = stats[statName] * modifier
				else
					-- For stats that start at 0 (like CritChance), use additive
					if statName == "CritChance" or statName == "CritDamage" then
						stats[statName] = stats[statName] + modifier
					else
						stats[statName] = modifier
					end
				end
			end
		end

		-- Track highest level requirement
		if part and part.MinLevel and part.MinLevel > stats.Level then
			stats.Level = part.MinLevel
		end
	end

	-- Apply rarity multiplier to damage and fire rate
	if rarity then
		stats.Damage = stats.Damage * rarity.StatMultiplier
		stats.FireRate = stats.FireRate * rarity.StatMultiplier

		-- Higher rarities get bonus crit chance
		local rarityBonusCrit = {
			Common = 0,
			Uncommon = 0.02,
			Rare = 0.05,
			Epic = 0.08,
			Legendary = 0.12,
			Mythic = 0.18
		}
		stats.CritChance = stats.CritChance + (rarityBonusCrit[rarity.Name] or 0)
	end

	-- Round certain stats
	stats.MagazineSize = math.floor(stats.MagazineSize + 0.5)
	stats.PelletCount = math.floor(stats.PelletCount + 0.5)
	stats.Damage = math.floor(stats.Damage + 0.5)

	-- Clamp accuracy between 0 and 1
	stats.Accuracy = math.clamp(stats.Accuracy, 0, 1)

	-- Clamp crit chance between 0 and 1
	stats.CritChance = math.clamp(stats.CritChance, 0, 1)

	return stats
end

--[[
	Calculate DPS (Damage Per Second) from stats
	@param stats - Weapon stats table
	@return number - DPS value
]]
function WeaponStats.CalculateDPS(stats)
	local baseDPS = stats.Damage * stats.FireRate

	-- Factor in critical hits
	local critMultiplier = 1 + (stats.CritChance * stats.CritDamage)

	-- Factor in pellet count (for shotguns)
	local pelletMultiplier = stats.PelletCount

	return baseDPS * critMultiplier * pelletMultiplier
end

--[[
	Get a letter grade (F to S) based on stat value and stat type
	@param statName - Name of the stat
	@param value - Value of the stat
	@return string - Letter grade
]]
function WeaponStats.GetStatGrade(statName, value)
	local gradeThresholds = {
		Damage = {S = 100, A = 60, B = 40, C = 25, D = 15},
		FireRate = {S = 10, A = 7, B = 5, C = 3, D = 2},
		Accuracy = {S = 0.95, A = 0.85, B = 0.75, C = 0.65, D = 0.5},
		ReloadTime = {S = 1.5, A = 2.0, B = 2.5, C = 3.0, D = 4.0}, -- Lower is better
		MagazineSize = {S = 50, A = 35, B = 25, C = 15, D = 10},
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

return WeaponStats
