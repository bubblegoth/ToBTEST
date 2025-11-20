--[[
	DungeonGenerator.lua
	Procedural dungeon floor generation with random rooms, enemy spawns, and loot
	Part of the Gothic FPS Roguelite Dungeon System
]]

local DungeonConfig = require(script.Parent.DungeonConfig)

local DungeonGenerator = {}

-- RNG seed management
local rng = Random.new()

-- ============================================================
-- SEED MANAGEMENT
-- ============================================================

function DungeonGenerator.SetSeed(seed)
	rng = Random.new(seed)
end

function DungeonGenerator.GetRandomSeed()
	return math.random(1, 999999999)
end

-- ============================================================
-- FLOOR GENERATION
-- ============================================================

function DungeonGenerator.GenerateFloor(floorNumber, seed)
	-- Use seed for deterministic generation (optional)
	if seed then
		rng = Random.new(seed)
	end

	-- Floor 0 is always the Church (safe hub)
	if floorNumber == 0 then
		return DungeonGenerator.GenerateChurchFloor()
	end

	-- Check if this is a boss floor (every 10 floors)
	local isBossFloor = (floorNumber % DungeonConfig.BOSS_FLOOR_INTERVAL == 0)

	-- Calculate room count based on floor
	local baseRooms = DungeonConfig.DIFFICULTY_SCALING.RoomCountBase
	local maxRooms = DungeonConfig.DIFFICULTY_SCALING.RoomCountMax
	local roomsPerFloor = DungeonConfig.DIFFICULTY_SCALING.RoomCountPerFloor
	local roomCount = math.min(
		maxRooms,
		baseRooms + math.floor(floorNumber * roomsPerFloor)
	)
	roomCount = rng:NextInteger(roomCount - 2, roomCount + 2) -- Add variance

	-- Generate random rare enemy % for this floor
	local rareEnemyChance = rng:NextNumber(
		DungeonConfig.RARE_ENEMY_VARIANCE.MinChance,
		DungeonConfig.RARE_ENEMY_VARIANCE.MaxChance
	)

	-- Generate rooms
	local rooms = {}
	for i = 1, roomCount do
		local room = DungeonGenerator.GenerateRoom(floorNumber, isBossFloor, rareEnemyChance, i == roomCount)
		table.insert(rooms, room)
	end

	-- Floor metadata
	local floor = {
		FloorNumber = floorNumber,
		IsBossFloor = isBossFloor,
		RoomCount = #rooms,
		Rooms = rooms,
		RareEnemyChance = rareEnemyChance,
		Seed = seed,
		EnemyLevel = floorNumber, -- Linear scaling: Floor 10 = Level 10 enemies
	}

	return floor
end

-- ============================================================
-- CHURCH FLOOR (FLOOR 0)
-- ============================================================

function DungeonGenerator.GenerateChurchFloor()
	return {
		FloorNumber = 0,
		IsBossFloor = false,
		RoomCount = 1,
		Rooms = {
			{
				ID = "Church_Main",
				Type = "Church",
				IsLootEnabled = false,
				IsSafeZone = true,
				WeaponUsageDisabled = true, -- No weapon usage in Church
				Enemies = {},
				Description = "Safe hub for purchasing upgrades with Souls (Floor 0)",
			}
		},
		RareEnemyChance = 0,
		EnemyLevel = 0,
	}
end

-- ============================================================
-- ROOM GENERATION
-- ============================================================

function DungeonGenerator.GenerateRoom(floorNumber, isBossFloor, rareEnemyChance, isLastRoom)
	local roomType

	-- Force boss room on boss floors (last room)
	if isBossFloor and isLastRoom then
		roomType = DungeonConfig.RoomTypes.BOSS
	else
		-- Weighted random room selection
		local roll = rng:NextNumber(0, 100)
		local cumulative = 0

		for _, rType in pairs(DungeonConfig.RoomTypes) do
			if rType.SpawnChance then
				cumulative = cumulative + rType.SpawnChance
				if roll <= cumulative then
					roomType = rType
					break
				end
			end
		end

		-- Default to combat if no match
		if not roomType then
			roomType = DungeonConfig.RoomTypes.COMBAT
		end
	end

	-- Calculate enemy count based on room type and floor
	local baseEnemies = rng:NextInteger(roomType.MinEnemies, roomType.MaxEnemies)
	local densityMultiplier = roomType.EnemyDensityMultiplier or 1.0
	local floorDensity = DungeonConfig.DIFFICULTY_SCALING.EnemyDensityPerFloor * floorNumber
	local enemyCount = math.floor(baseEnemies + floorDensity * densityMultiplier)

	-- Adjust rare enemy chance based on room type
	local adjustedRareChance = rareEnemyChance
	if roomType.RareEnemyChanceBonus then
		adjustedRareChance = math.min(1.0, adjustedRareChance + roomType.RareEnemyChanceBonus)
	end

	-- Generate room
	local room = {
		ID = string.format("Floor%d_Room%d_%s", floorNumber, rng:NextInteger(1000, 9999), roomType.ID),
		Type = roomType.ID,
		EnemyCount = enemyCount,
		RareEnemyChance = adjustedRareChance,
		IsLootEnabled = roomType.IsLootEnabled and floorNumber >= DungeonConfig.LootRules.WeaponDropsStartFloor,
		IsSafeZone = roomType.IsSafeZone or false,
		IsBossRoom = roomType.IsBossRoom or false,
		SoulDropMultiplier = roomType.SoulDropMultiplier or 1.0,
		Description = roomType.Description,
	}

	return room
end

-- ============================================================
-- ROOM TYPE HELPERS
-- ============================================================

function DungeonGenerator.IsChurchFloor(floorNumber)
	return floorNumber == 0
end

function DungeonGenerator.IsBossFloor(floorNumber)
	return floorNumber % DungeonConfig.BOSS_FLOOR_INTERVAL == 0
end

function DungeonGenerator.GetFloorEnemyLevel(floorNumber)
	return floorNumber * DungeonConfig.DIFFICULTY_SCALING.EnemyLevelPerFloor
end

-- ============================================================
-- FLOOR VALIDATION
-- ============================================================

function DungeonGenerator.IsValidFloor(floorNumber)
	return floorNumber >= 0 and floorNumber <= DungeonConfig.MAX_FLOORS
end

-- ============================================================
-- DISPLAY / DEBUG HELPERS
-- ============================================================

function DungeonGenerator.GetFloorSummary(floor)
	local summary = string.format(
		"=== FLOOR %d ===\n" ..
		"Type: %s\n" ..
		"Rooms: %d\n" ..
		"Enemy Level: %d\n" ..
		"Rare Enemy Chance: %d%%\n" ..
		"Loot Enabled: %s\n",
		floor.FloorNumber,
		floor.IsBossFloor and "BOSS FLOOR" or "Standard",
		floor.RoomCount,
		floor.EnemyLevel,
		math.floor(floor.RareEnemyChance * 100),
		floor.FloorNumber >= DungeonConfig.LootRules.WeaponDropsStartFloor and "Yes" or "No"
	)

	-- Room breakdown
	summary = summary .. "\nRooms:\n"
	for i, room in ipairs(floor.Rooms) do
		summary = summary .. string.format(
			"  %d. %s (%d enemies, %d%% rare)\n",
			i,
			room.Type,
			room.EnemyCount or 0,
			math.floor(room.RareEnemyChance * 100)
		)
	end

	return summary
end

-- ============================================================
-- BATCH GENERATION (FOR TESTING)
-- ============================================================

function DungeonGenerator.GenerateFloors(startFloor, endFloor, seed)
	local floors = {}

	if seed then
		rng = Random.new(seed)
	end

	for floorNum = startFloor, endFloor do
		if DungeonGenerator.IsValidFloor(floorNum) then
			local floor = DungeonGenerator.GenerateFloor(floorNum)
			table.insert(floors, floor)
		end
	end

	return floors
end

return DungeonGenerator
