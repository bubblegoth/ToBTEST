--[[
════════════════════════════════════════════════════════════════════════════════
Module: DifficultyScaler
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Calculates difficulty scaling for 666-floor descent.
             Scales enemy stats, loot drops, dungeon size based on depth.
             Progressive difficulty curve with 5 themed regions.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local DifficultyScaler = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Total floors in the descent
	MaxFloors = 666,

	-- Enemy scaling
	BaseEnemyHealth = 100,
	BaseEnemyDamage = 10,
	HealthScalingFactor = 1.015,  -- 1.5% per floor
	DamageScalingFactor = 1.012,  -- 1.2% per floor

	-- Spawn scaling
	BaseEnemyCount = 3,
	MaxEnemyCount = 15,
	EnemyCountGrowth = 0.02,  -- Growth per floor

	-- Loot scaling
	BaseLootChance = 0.3,
	MaxLootChance = 0.8,
	LootChanceGrowth = 0.0005,  -- Growth per floor

	-- Dungeon size scaling
	BaseDungeonSize = 5,  -- Base room count
	MaxDungeonSize = 20,  -- Maximum room count
	SizeGrowthFactor = 0.015,  -- Growth per floor

	-- Boss floors (every 10 floors)
	BossFloorInterval = 10,
}

-- ════════════════════════════════════════════════════════════════════════════
-- THEME REGIONS (5 zones across 666 floors)
-- ════════════════════════════════════════════════════════════════════════════

local ThemeRegions = {
	{
		Name = "Upper Catacombs",
		FloorStart = 1,
		FloorEnd = 133,
		Description = "Ancient crypts and burial chambers",
		ColorPalette = {
			Primary = Color3.fromRGB(70, 60, 55),    -- Stone gray
			Secondary = Color3.fromRGB(90, 80, 70),  -- Weathered stone
			Accent = Color3.fromRGB(180, 160, 140),  -- Bone white
		},
		LightingPreset = {
			Ambient = Color3.fromRGB(40, 35, 30),
			OutdoorAmbient = Color3.fromRGB(40, 35, 30),
			Brightness = 1.5,
			FogEnd = 100,
		}
	},
	{
		Name = "Deep Crypts",
		FloorStart = 134,
		FloorEnd = 266,
		Description = "Decaying tombs and ossuary halls",
		ColorPalette = {
			Primary = Color3.fromRGB(50, 45, 45),    -- Dark stone
			Secondary = Color3.fromRGB(60, 50, 45),  -- Aged stone
			Accent = Color3.fromRGB(120, 100, 80),   -- Old bone
		},
		LightingPreset = {
			Ambient = Color3.fromRGB(30, 25, 25),
			OutdoorAmbient = Color3.fromRGB(30, 25, 25),
			Brightness = 1.2,
			FogEnd = 80,
		}
	},
	{
		Name = "Abyssal Halls",
		FloorStart = 267,
		FloorEnd = 399,
		Description = "Twisted passages and nightmare chambers",
		ColorPalette = {
			Primary = Color3.fromRGB(35, 30, 35),    -- Deep shadow
			Secondary = Color3.fromRGB(45, 35, 40),  -- Void stone
			Accent = Color3.fromRGB(80, 60, 70),     -- Cursed bone
		},
		LightingPreset = {
			Ambient = Color3.fromRGB(20, 15, 20),
			OutdoorAmbient = Color3.fromRGB(20, 15, 20),
			Brightness = 0.9,
			FogEnd = 60,
		}
	},
	{
		Name = "Void Depths",
		FloorStart = 400,
		FloorEnd = 532,
		Description = "Reality-warped corridors of madness",
		ColorPalette = {
			Primary = Color3.fromRGB(25, 20, 30),    -- Void black
			Secondary = Color3.fromRGB(30, 25, 35),  -- Shadow stone
			Accent = Color3.fromRGB(60, 40, 60),     -- Void essence
		},
		LightingPreset = {
			Ambient = Color3.fromRGB(15, 10, 15),
			OutdoorAmbient = Color3.fromRGB(15, 10, 15),
			Brightness = 0.6,
			FogEnd = 40,
		}
	},
	{
		Name = "Hell's Threshold",
		FloorStart = 533,
		FloorEnd = 666,
		Description = "Infernal depths at the edge of damnation",
		ColorPalette = {
			Primary = Color3.fromRGB(40, 15, 10),    -- Charred stone
			Secondary = Color3.fromRGB(50, 20, 15),  -- Burnt rock
			Accent = Color3.fromRGB(180, 60, 30),    -- Ember glow
		},
		LightingPreset = {
			Ambient = Color3.fromRGB(30, 10, 5),
			OutdoorAmbient = Color3.fromRGB(30, 10, 5),
			Brightness = 0.8,
			FogEnd = 50,
		}
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- DIFFICULTY CALCULATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Gets the theme region for a given floor
	@param floorNumber - The floor number
	@return theme data
]]
function DifficultyScaler:GetTheme(floorNumber)
	for _, theme in ipairs(ThemeRegions) do
		if floorNumber >= theme.FloorStart and floorNumber <= theme.FloorEnd then
			return theme
		end
	end

	-- Default to first theme if out of range
	return ThemeRegions[1]
end

--[[
	Calculates enemy health for a given floor
	@param floorNumber - The floor number
	@param baseHealth - Optional base health override
	@return scaledHealth
]]
function DifficultyScaler:GetEnemyHealth(floorNumber, baseHealth)
	baseHealth = baseHealth or Config.BaseEnemyHealth
	local multiplier = Config.HealthScalingFactor ^ floorNumber
	return math.floor(baseHealth * multiplier)
end

--[[
	Calculates enemy damage for a given floor
	@param floorNumber - The floor number
	@param baseDamage - Optional base damage override
	@return scaledDamage
]]
function DifficultyScaler:GetEnemyDamage(floorNumber, baseDamage)
	baseDamage = baseDamage or Config.BaseEnemyDamage
	local multiplier = Config.DamageScalingFactor ^ floorNumber
	return math.floor(baseDamage * multiplier)
end

--[[
	Calculates enemy spawn count for a given floor
	@param floorNumber - The floor number
	@return enemyCount
]]
function DifficultyScaler:GetEnemyCount(floorNumber)
	local growth = 1 + (floorNumber * Config.EnemyCountGrowth)
	local count = math.floor(Config.BaseEnemyCount * growth)
	return math.min(count, Config.MaxEnemyCount)
end

--[[
	Calculates loot drop chance for a given floor
	@param floorNumber - The floor number
	@return dropChance (0.0 to 1.0)
]]
function DifficultyScaler:GetLootChance(floorNumber)
	local chance = Config.BaseLootChance + (floorNumber * Config.LootChanceGrowth)
	return math.min(chance, Config.MaxLootChance)
end

--[[
	Calculates dungeon size (room count) for a given floor
	@param floorNumber - The floor number
	@return roomCount
]]
function DifficultyScaler:GetDungeonSize(floorNumber)
	local growth = 1 + (floorNumber * Config.SizeGrowthFactor)
	local size = math.floor(Config.BaseDungeonSize * growth)
	return math.min(size, Config.MaxDungeonSize)
end

--[[
	Checks if a floor is a boss floor
	@param floorNumber - The floor number
	@return isBossFloor
]]
function DifficultyScaler:IsBossFloor(floorNumber)
	return floorNumber % Config.BossFloorInterval == 0
end

--[[
	Gets complete difficulty data for a floor
	@param floorNumber - The floor number
	@return difficultyData table
]]
function DifficultyScaler:GetFloorDifficulty(floorNumber)
	local theme = self:GetTheme(floorNumber)
	local isBoss = self:IsBossFloor(floorNumber)

	return {
		FloorNumber = floorNumber,
		Theme = theme,

		-- Enemy stats
		EnemyHealth = self:GetEnemyHealth(floorNumber),
		EnemyDamage = self:GetEnemyDamage(floorNumber),
		EnemyCount = self:GetEnemyCount(floorNumber),

		-- Loot
		LootChance = self:GetLootChance(floorNumber),

		-- Dungeon
		DungeonSize = self:GetDungeonSize(floorNumber),

		-- Special
		IsBossFloor = isBoss,
		BossHealthMultiplier = isBoss and 5.0 or 1.0,
		BossDamageMultiplier = isBoss and 2.0 or 1.0,
	}
end

--[[
	Applies difficulty scaling to an enemy humanoid
	@param humanoid - The Humanoid instance
	@param floorNumber - The floor number
	@param isBoss - Is this a boss enemy
]]
function DifficultyScaler:ApplyEnemyScaling(humanoid, floorNumber, isBoss)
	if not humanoid or not humanoid:IsA("Humanoid") then
		warn("[DifficultyScaler] Invalid humanoid")
		return
	end

	local difficulty = self:GetFloorDifficulty(floorNumber)

	-- Scale health
	local health = difficulty.EnemyHealth
	if isBoss then
		health = health * difficulty.BossHealthMultiplier
	end
	humanoid.MaxHealth = health
	humanoid.Health = health

	-- Store damage in attribute (for damage calculation)
	local damage = difficulty.EnemyDamage
	if isBoss then
		damage = damage * difficulty.BossDamageMultiplier
	end
	humanoid.Parent:SetAttribute("BaseDamage", damage)
	humanoid.Parent:SetAttribute("FloorLevel", floorNumber)
	humanoid.Parent:SetAttribute("IsBoss", isBoss)

	print(string.format("[DifficultyScaler] Scaled %s for floor %d: HP=%d, DMG=%d",
		isBoss and "BOSS" or "enemy",
		floorNumber,
		health,
		damage
	))
end

-- ════════════════════════════════════════════════════════════════════════════
-- DEBUG INFO
-- ════════════════════════════════════════════════════════════════════════════

function DifficultyScaler:PrintFloorInfo(floorNumber)
	local difficulty = self:GetFloorDifficulty(floorNumber)

	print("\n" .. string.rep("=", 60))
	print(string.format("FLOOR %d - %s", floorNumber, difficulty.Theme.Name))
	print(string.rep("=", 60))
	print(string.format("Theme: %s (%d-%d)",
		difficulty.Theme.Name,
		difficulty.Theme.FloorStart,
		difficulty.Theme.FloorEnd
	))
	print(string.format("Description: %s", difficulty.Theme.Description))
	print(string.rep("-", 60))
	print(string.format("Enemy Health: %d HP", difficulty.EnemyHealth))
	print(string.format("Enemy Damage: %d", difficulty.EnemyDamage))
	print(string.format("Enemy Count: %d", difficulty.EnemyCount))
	print(string.format("Loot Chance: %.1f%%", difficulty.LootChance * 100))
	print(string.format("Dungeon Size: %d rooms", difficulty.DungeonSize))
	print(string.format("Boss Floor: %s", difficulty.IsBossFloor and "YES" or "No"))
	print(string.rep("=", 60) .. "\n")
end

return DifficultyScaler
