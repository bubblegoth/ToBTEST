--[[
	WeaponGenerator.lua
	Main weapon generation system - builds weapons on the fly from random parts

	Usage:
		local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

		-- Generate a random weapon
		local weapon = WeaponGenerator.GenerateWeapon()

		-- Generate a weapon for a specific level
		local weapon = WeaponGenerator.GenerateWeapon(15)

		-- Generate a weapon of specific type and level
		local weapon = WeaponGenerator.GenerateWeapon(20, "Rifle")
]]

local WeaponGenerator = {}

-- Import dependencies
local WeaponConfig = require(script.Parent.WeaponConfig)
local WeaponStats = require(script.Parent.WeaponStats)

-- Import part libraries
local WeaponParts = script.Parent.WeaponParts
local Bodies = require(WeaponParts.Bodies)
local Barrels = require(WeaponParts.Barrels)
local Grips = require(WeaponParts.Grips)
local Stocks = require(WeaponParts.Stocks)
local Magazines = require(WeaponParts.Magazines)
local Sights = require(WeaponParts.Sights)

-- Random number generator (can be seeded for deterministic generation)
local rng = Random.new()

--[[
	Set a seed for deterministic weapon generation
	@param seed - Random seed value
]]
function WeaponGenerator.SetSeed(seed)
	rng = Random.new(seed)
end

--[[
	Select a random rarity based on drop weights
	@return table - Rarity data
]]
local function SelectRarity()
	local totalWeight = 0
	for _, rarity in pairs(WeaponConfig.Rarities) do
		totalWeight = totalWeight + rarity.DropWeight
	end

	local roll = rng:NextNumber(0, totalWeight)
	local currentWeight = 0

	for _, rarity in pairs(WeaponConfig.Rarities) do
		currentWeight = currentWeight + rarity.DropWeight
		if roll <= currentWeight then
			return rarity
		end
	end

	-- Fallback to Common
	return WeaponConfig.Rarities.Common
end

--[[
	Filter parts by level requirement
	@param parts - Array of parts
	@param level - Player/enemy level
	@return table - Filtered parts array
]]
local function FilterPartsByLevel(parts, level)
	local filtered = {}
	for _, part in ipairs(parts) do
		if part.MinLevel <= level then
			table.insert(filtered, part)
		end
	end
	return filtered
end

--[[
	Select a random part from an array
	@param parts - Array of parts
	@return table - Selected part
]]
local function SelectRandomPart(parts)
	if #parts == 0 then
		return nil
	end
	local index = rng:NextInteger(1, #parts)
	return parts[index]
end

--[[
	Generate a weapon name from parts and rarity
	@param body - Body part
	@param rarity - Rarity data
	@return string - Generated weapon name
]]
local function GenerateName(body, rarity)
	local adjectives = WeaponConfig.GothicNames.Adjectives
	local nouns = WeaponConfig.GothicNames.Nouns

	local adjective = adjectives[rng:NextInteger(1, #adjectives)]
	local noun = nouns[rng:NextInteger(1, #nouns)]

	local name = ""

	-- Add rarity prefix for higher rarities
	if rarity.NamePrefix and rarity.NamePrefix ~= "" then
		name = rarity.NamePrefix .. " "
	end

	-- Combine adjective and noun
	name = name .. adjective .. " " .. noun

	return name
end

--[[
	Generate a complete weapon with random parts
	@param level - Optional level requirement (defaults to 1)
	@param weaponType - Optional weapon type (Pistol, Rifle, Shotgun, SMG, Sniper)
	@return table - Complete weapon data
]]
function WeaponGenerator.GenerateWeapon(level, weaponType)
	level = level or 1

	-- Select rarity first
	local rarity = SelectRarity()

	-- Filter and select body based on weapon type and level
	local availableBodies = FilterPartsByLevel(Bodies, level)
	if weaponType then
		local filtered = {}
		for _, body in ipairs(availableBodies) do
			if body.Type == weaponType then
				table.insert(filtered, body)
			end
		end
		availableBodies = filtered
	end

	if #availableBodies == 0 then
		warn("No valid bodies found for level", level, "and type", weaponType)
		return nil
	end

	local body = SelectRandomPart(availableBodies)

	-- Select other parts based on level
	local barrel = SelectRandomPart(FilterPartsByLevel(Barrels, level))
	local grip = SelectRandomPart(FilterPartsByLevel(Grips, level))
	local stock = SelectRandomPart(FilterPartsByLevel(Stocks, level))
	local magazine = SelectRandomPart(FilterPartsByLevel(Magazines, level))
	local sight = SelectRandomPart(FilterPartsByLevel(Sights, level))

	-- Calculate final stats
	local stats = WeaponStats.CalculateStats(body, barrel, grip, stock, magazine, sight, rarity)

	-- Generate weapon name
	local name = GenerateName(body, rarity)

	-- Build complete weapon data
	local weapon = {
		-- Identity
		Name = name,
		Type = body.Type,
		Rarity = rarity,
		Level = stats.Level,

		-- Parts (for visual representation)
		Parts = {
			Body = body,
			Barrel = barrel,
			Grip = grip,
			Stock = stock,
			Magazine = magazine,
			Sight = sight
		},

		-- Final stats
		Stats = stats,

		-- Calculated values
		DPS = WeaponStats.CalculateDPS(stats),

		-- Generation timestamp
		GeneratedAt = os.time()
	}

	return weapon
end

--[[
	Generate multiple weapons at once
	@param count - Number of weapons to generate
	@param level - Optional level requirement
	@param weaponType - Optional weapon type
	@return table - Array of generated weapons
]]
function WeaponGenerator.GenerateWeapons(count, level, weaponType)
	local weapons = {}
	for i = 1, count do
		local weapon = WeaponGenerator.GenerateWeapon(level, weaponType)
		if weapon then
			table.insert(weapons, weapon)
		end
	end
	return weapons
end

--[[
	Generate a weapon from a seed (deterministic)
	@param seed - Random seed
	@param level - Optional level requirement
	@param weaponType - Optional weapon type
	@return table - Generated weapon
]]
function WeaponGenerator.GenerateWeaponFromSeed(seed, level, weaponType)
	local oldRng = rng
	rng = Random.new(seed)
	local weapon = WeaponGenerator.GenerateWeapon(level, weaponType)
	rng = oldRng
	return weapon
end

--[[
	Get a formatted weapon description
	@param weapon - Weapon data
	@return string - Formatted description
]]
function WeaponGenerator.GetWeaponDescription(weapon)
	local desc = string.format(
		"=== %s ===\n" ..
		"Type: %s | Rarity: %s | Level: %d\n" ..
		"\nStats:\n" ..
		"  Damage: %d\n" ..
		"  Fire Rate: %.1f rounds/sec\n" ..
		"  DPS: %.1f\n" ..
		"  Accuracy: %.0f%%\n" ..
		"  Magazine: %d rounds\n" ..
		"  Reload Time: %.2fs\n" ..
		"  Crit Chance: %.1f%%\n" ..
		"  Crit Damage: %.0f%%\n" ..
		"\nParts:\n" ..
		"  Body: %s\n" ..
		"  Barrel: %s\n" ..
		"  Grip: %s\n" ..
		"  Stock: %s\n" ..
		"  Magazine: %s\n" ..
		"  Sight: %s",
		weapon.Name,
		weapon.Type,
		weapon.Rarity.Name,
		weapon.Level,
		weapon.Stats.Damage,
		weapon.Stats.FireRate,
		weapon.DPS,
		weapon.Stats.Accuracy * 100,
		weapon.Stats.MagazineSize,
		weapon.Stats.ReloadTime,
		weapon.Stats.CritChance * 100,
		weapon.Stats.CritDamage * 100,
		weapon.Parts.Body.Name,
		weapon.Parts.Barrel.Name,
		weapon.Parts.Grip.Name,
		weapon.Parts.Stock.Name,
		weapon.Parts.Magazine.Name,
		weapon.Parts.Sight.Name
	)
	return desc
end

return WeaponGenerator
