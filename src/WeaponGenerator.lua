--[[
	WeaponGenerator.lua
	BL2-Accurate Weapon Generation System with Gothic Theming

	Generation Order (BL2-accurate):
	1. Roll for Rarity (determines body/material and accessory chance)
	2. Choose Manufacturer (affects all stats and mechanics)
	3. Choose Weapon Type
	4. Select Parts (based on rarity, manufacturer, level)
	5. Roll for Accessory (based on rarity rules)
	6. Choose Element (based on manufacturer and rarity)
	7. Calculate final stats with level scaling (1.13× per level)
	8. Generate prefix from parts (highest priority wins)

	Usage:
		local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

		-- Generate random weapon
		local weapon = WeaponGenerator.GenerateWeapon(10) -- Level 10

		-- Generate specific manufacturer + type
		local weapon = WeaponGenerator.GenerateWeapon(15, "Rifle", "Hellforge")

		-- Generate with forced rarity
		local legendary = WeaponGenerator.GenerateWeapon(20, nil, nil, "Legendary")
]]

local WeaponGenerator = {}

-- Import dependencies
local WeaponConfig = require(script.Parent.WeaponConfig)
local WeaponStats = require(script.Parent.WeaponStats)

-- Import part libraries (combined into single file)
local WeaponParts = require(script.Parent.WeaponParts)
local Bodies = WeaponParts.Bodies
local Barrels = WeaponParts.Barrels
local Grips = WeaponParts.Grips
local Stocks = WeaponParts.Stocks
local Magazines = WeaponParts.Magazines
local Sights = WeaponParts.Sights
local Accessories = WeaponParts.Accessories

-- Random number generator
local rng = Random.new()

--[[
	Set a seed for deterministic weapon generation
]]
function WeaponGenerator.SetSeed(seed)
	rng = Random.new(seed)
end

--[[
	STEP 1: Select a random rarity based on drop weights (BL2: This is FIRST)
]]
local function SelectRarity(forcedRarity)
	if forcedRarity then
		return WeaponConfig.Rarities[forcedRarity]
	end

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

	return WeaponConfig.Rarities.Common
end

--[[
	STEP 2: Select a random manufacturer
]]
local function SelectManufacturer(forcedManufacturer)
	if forcedManufacturer then
		return WeaponConfig.Manufacturers[forcedManufacturer]
	end

	-- Equal weight for all manufacturers
	local manufacturerList = {}
	for _, manufacturer in pairs(WeaponConfig.Manufacturers) do
		table.insert(manufacturerList, manufacturer)
	end

	local index = rng:NextInteger(1, #manufacturerList)
	return manufacturerList[index]
end

--[[
	STEP 3: Select weapon type
]]
local function SelectWeaponType(forcedType)
	if forcedType then
		return forcedType
	end

	local types = {"Pistol", "Rifle", "Shotgun", "SMG", "Sniper"}
	local index = rng:NextInteger(1, #types)
	return types[index]
end

--[[
	STEP 4: Select parts based on level and filters
]]
local function FilterPartsByLevel(parts, level)
	local filtered = {}
	for _, part in ipairs(parts) do
		if part.MinLevel <= level then
			table.insert(filtered, part)
		end
	end
	return #filtered > 0 and filtered or parts
end

local function FilterPartsByType(parts, weaponType)
	local filtered = {}
	for _, part in ipairs(parts) do
		if part.Type == weaponType then
			table.insert(filtered, part)
		end
	end
	return #filtered > 0 and filtered or nil
end

local function SelectRandomPart(parts)
	if not parts or #parts == 0 then return nil end
	return parts[rng:NextInteger(1, #parts)]
end

--[[
	STEP 5: Roll for accessory (BL2 rarity rules)
	- Common: NEVER
	- Uncommon: 30% chance
	- Rare: 50% chance
	- Epic+: ALWAYS
]]
local function RollForAccessory(rarity, weaponType, element, level)
	-- Check if accessory is allowed
	if rarity.HasAccessory == false then
		return nil
	end

	-- Check probability
	if rarity.HasAccessory == "chance" then
		if rng:NextNumber() > rarity.AccessoryChance then
			return nil
		end
	end

	-- Filter accessories
	local available = {}
	for _, acc in ipairs(Accessories) do
		-- Check level
		if acc.MinLevel > level then continue end

		-- Check rarity requirement
		if acc.MinRarity then
			local rarityOrder = {Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6}
			if rarityOrder[rarity.Name] < rarityOrder[acc.MinRarity] then
				continue
			end
		end

		-- Check weapon type applicability
		local applicable = false
		for _, applicableType in ipairs(acc.ApplicableTypes) do
			if applicableType == "All" or applicableType == weaponType then
				applicable = true
				break
			end
		end
		if not applicable then continue end

		-- Check element requirement
		if acc.RequiresElement and (not element or element.Name ~= acc.RequiresElement) then
			continue
		end

		table.insert(available, acc)
	end

	return SelectRandomPart(available)
end

--[[
	STEP 6: Choose element based on manufacturer and rarity
]]
local function ChooseElement(manufacturer, rarity)
	-- Jakobs NEVER has elements
	if manufacturer.Mechanics.Type == "Jakobs" then
		return nil
	end

	-- Torgue is ALWAYS explosive
	if manufacturer.Mechanics.AlwaysExplosive then
		return WeaponConfig.Elements.Apocalyptic
	end

	-- Maliwan is ALWAYS elemental
	if manufacturer.Mechanics.AlwaysElemental then
		local elements = {"Hellfire", "Stormwrath", "Plague", "Curse"}
		local elementName = elements[rng:NextInteger(1, #elements)]
		return WeaponConfig.Elements[elementName]
	end

	-- Legendary+ guaranteed element
	if rarity.GuaranteedElement then
		local elements = {"Hellfire", "Stormwrath", "Plague", "Curse"}
		local elementName = elements[rng:NextInteger(1, #elements)]
		return WeaponConfig.Elements[elementName]
	end

	-- Roll for element based on manufacturer chance
	if rng:NextNumber() < manufacturer.ElementalChance then
		local elements = {"Hellfire", "Stormwrath", "Plague", "Curse"}
		local elementName = elements[rng:NextInteger(1, #elements)]
		return WeaponConfig.Elements[elementName]
	end

	return nil
end

--[[
	STEP 8: Generate prefix from parts (highest priority wins)
	Priority: Accessory > Element > Grip > Barrel
]]
local function GeneratePrefix(accessory, element, grip, barrel)
	-- Accessory prefix has highest priority
	if accessory and accessory.Prefix then
		return accessory.Prefix
	end

	-- Element prefix
	if element and element.Name then
		return element.Name
	end

	-- Grip prefix (if it has one)
	if grip and grip.Prefix then
		return grip.Prefix
	end

	-- Barrel prefix
	if barrel and barrel.Prefix then
		return barrel.Prefix
	end

	-- No prefix
	return nil
end

--[[
	Generate weapon name with prefix
]]
local function GenerateName(prefix, manufacturer, weaponType)
	local name = ""

	-- Add prefix if exists
	if prefix then
		name = prefix .. " "
	end

	-- Add manufacturer
	name = name .. manufacturer.ShortName .. " "

	-- Add weapon type
	name = name .. weaponType

	return name
end

--[[
	Main weapon generation function (BL2-accurate)

	@param level - Weapon level (1-80+)
	@param weaponType - Optional: Force weapon type
	@param manufacturerName - Optional: Force manufacturer
	@param rarityName - Optional: Force rarity
	@return weapon - Complete weapon data
]]
function WeaponGenerator.GenerateWeapon(level, weaponType, manufacturerName, rarityName)
	level = level or 1

	-- STEP 1: Choose rarity FIRST (like BL2)
	local rarity = SelectRarity(rarityName)

	-- STEP 2: Choose manufacturer
	local manufacturer = SelectManufacturer(manufacturerName)

	-- STEP 3: Choose weapon type
	local chosenType = SelectWeaponType(weaponType)

	-- STEP 4: Select parts
	local bodyParts = FilterPartsByType(Bodies, chosenType)
	if not bodyParts then
		warn("No body parts found for type:", chosenType)
		return nil
	end
	local body = SelectRandomPart(FilterPartsByLevel(bodyParts, level))

	local barrel = SelectRandomPart(FilterPartsByLevel(Barrels, level))
	local grip = SelectRandomPart(FilterPartsByLevel(Grips, level))
	local stock = SelectRandomPart(FilterPartsByLevel(Stocks, level))
	local magazine = SelectRandomPart(FilterPartsByLevel(Magazines, level))
	local sight = SelectRandomPart(FilterPartsByLevel(Sights, level))

	-- STEP 6: Choose element
	local element = ChooseElement(manufacturer, rarity)

	-- STEP 5: Roll for accessory (must be after element for element-based accessories)
	local accessory = RollForAccessory(rarity, chosenType, element, level)

	-- STEP 7: Calculate final stats with BL2 level scaling
	local stats = WeaponStats.CalculateStats(
		body, barrel, grip, stock, magazine, sight, accessory,
		manufacturer, rarity, element, level
	)

	-- STEP 8: Generate prefix and name
	local prefix = GeneratePrefix(accessory, element, grip, barrel)
	local name = GenerateName(prefix, manufacturer, chosenType)

	-- Build complete weapon data
	local weapon = {
		-- Identity
		Name = name,
		Prefix = prefix,
		Type = chosenType,
		Rarity = rarity,
		Manufacturer = manufacturer,
		Level = level,

		-- Element
		Element = element,

		-- Parts (for visual representation and mechanics)
		Parts = {
			Body = body,
			Barrel = barrel,
			Grip = grip,
			Stock = stock,
			Magazine = magazine,
			Sight = sight,
			Accessory = accessory
		},

		-- Final stats
		Stats = stats,

		-- Calculated values
		DPS = WeaponStats.CalculateDPS(stats),

		-- Manufacturer mechanics (for gameplay implementation)
		Mechanics = manufacturer.Mechanics,

		-- Generation metadata
		GeneratedAt = os.time(),
		Seed = nil -- Will be set if generated from seed
	}

	return weapon
end

--[[
	Generate multiple weapons at once
]]
function WeaponGenerator.GenerateWeapons(count, level, weaponType, manufacturerName, rarityName)
	local weapons = {}
	for i = 1, count do
		local weapon = WeaponGenerator.GenerateWeapon(level, weaponType, manufacturerName, rarityName)
		if weapon then
			table.insert(weapons, weapon)
		end
	end
	return weapons
end

--[[
	Generate a weapon from a seed (deterministic)
]]
function WeaponGenerator.GenerateWeaponFromSeed(seed, level, weaponType, manufacturerName, rarityName)
	local oldRng = rng
	rng = Random.new(seed)
	local weapon = WeaponGenerator.GenerateWeapon(level, weaponType, manufacturerName, rarityName)
	if weapon then
		weapon.Seed = seed
	end
	rng = oldRng
	return weapon
end

--[[
	Get a formatted weapon description
]]
function WeaponGenerator.GetWeaponDescription(weapon)
	local elementText = weapon.Element and string.format(
		"\n  Element: %s %s",
		weapon.Element.Icon,
		weapon.Element.Name
	) or ""

	local accessoryText = weapon.Parts.Accessory and string.format(
		"\n  Accessory: %s",
		weapon.Parts.Accessory.Name
	) or "\n  Accessory: None"

	local mechanicsText = string.format(
		"\nManufacturer Trait:\n  %s",
		weapon.Manufacturer.Mechanics.Description
	)

	local desc = string.format(
		"=== %s ===\n" ..
		"Manufacturer: %s | Type: %s | Rarity: %s | Level: %d\n" ..
		"%s" ..
		"%s" ..
		"\nStats:\n" ..
		"  Damage: %d\n" ..
		"  Fire Rate: %.1f rounds/sec\n" ..
		"  DPS: %.1f\n" ..
		"  Accuracy: %.0f%%\n" ..
		"  Magazine: %d rounds\n" ..
		"  Reload Time: %.2fs\n" ..
		"  Crit Chance: %.1f%%\n" ..
		"  Crit Multiplier: %.1fx\n" ..
		"%s" ..
		"\nParts:\n" ..
		"  Body: %s\n" ..
		"  Barrel: %s\n" ..
		"  Grip: %s\n" ..
		"  Stock: %s\n" ..
		"  Magazine: %s\n" ..
		"  Sight: %s%s",
		weapon.Name,
		weapon.Manufacturer.Name,
		weapon.Type,
		weapon.Rarity.Name,
		weapon.Level,
		elementText,
		mechanicsText,
		weapon.Stats.Damage,
		weapon.Stats.FireRate,
		weapon.DPS,
		weapon.Stats.Accuracy * 100,
		weapon.Stats.MagazineSize,
		weapon.Stats.ReloadTime,
		weapon.Stats.CritChance * 100,
		weapon.Stats.CritMultiplier,
		"",
		weapon.Parts.Body.Name,
		weapon.Parts.Barrel.Name,
		weapon.Parts.Grip.Name,
		weapon.Parts.Stock.Name,
		weapon.Parts.Magazine.Name,
		weapon.Parts.Sight.Name,
		accessoryText
	)
	return desc
end

return WeaponGenerator
