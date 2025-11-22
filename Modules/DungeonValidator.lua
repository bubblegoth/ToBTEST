--[[
════════════════════════════════════════════════════════════════════════════════
Module: DungeonValidator
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Validates dungeon connectivity using flood-fill algorithm.
             Ensures all rooms are reachable, marks boss room at furthest point.
             Quality assurance for procedurally generated dungeons.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local DungeonValidator = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Validation thresholds
	MinReachableRooms = 3,        -- Minimum rooms that must be reachable
	MaxValidationAttempts = 5,    -- Max attempts to validate/regenerate

	-- Distance calculation
	RoomDistanceThreshold = 50,   -- Studs - rooms closer than this are considered connected
	PathfindingMaxDepth = 100,    -- Max flood-fill depth

	-- Boss room requirements
	MinBossRoomDistance = 100,    -- Minimum studs from spawn to boss room

	-- Spawn point validation
	SpawnClearanceRadius = 3,     -- Studs - required clearance around spawn points
	SpawnHeightCheck = 8,         -- Studs - check this height above spawn
	MaxObstructionPercent = 0.3,  -- Max 30% obstruction allowed in clearance area
}

-- ════════════════════════════════════════════════════════════════════════════
-- ROOM DETECTION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Extracts room data from a dungeon model
	@param dungeonModel - The dungeon model
	@return rooms table {position, connections, parts, isReachable, distance}
]]
local function extractRooms(dungeonModel)
	local rooms = {}
	local roomId = 1

	-- Find all floor parts (represent rooms/cells)
	for _, part in ipairs(dungeonModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:lower():find("floor") then
			-- Check if this is a new room or part of existing room
			local isNewRoom = true
			for _, room in ipairs(rooms) do
				local distance = (room.Position - part.Position).Magnitude
				if distance < Config.RoomDistanceThreshold then
					-- Add to existing room
					table.insert(room.Parts, part)
					-- Update center position (average)
					local totalPos = Vector3.new(0, 0, 0)
					for _, p in ipairs(room.Parts) do
						totalPos = totalPos + p.Position
					end
					room.Position = totalPos / #room.Parts
					isNewRoom = false
					break
				end
			end

			if isNewRoom then
				table.insert(rooms, {
					Id = roomId,
					Position = part.Position,
					Parts = {part},
					Connections = {},
					IsReachable = false,
					Distance = math.huge,
					IsSpawnRoom = false,
					IsBossRoom = false,
				})
				roomId = roomId + 1
			end
		end
	end

	print(string.format("[DungeonValidator] Detected %d rooms", #rooms))
	return rooms
end

--[[
	Finds connections between rooms
	@param rooms - Table of room data
	@return rooms with connections populated
]]
local function findRoomConnections(rooms)
	-- Simple distance-based connection detection
	for i, room1 in ipairs(rooms) do
		for j, room2 in ipairs(rooms) do
			if i ~= j then
				local distance = (room1.Position - room2.Position).Magnitude

				-- Rooms are connected if they're close enough
				if distance < Config.RoomDistanceThreshold * 2 then
					table.insert(room1.Connections, room2.Id)
				end
			end
		end
	end

	return rooms
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLOOD-FILL VALIDATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Performs flood-fill from spawn room to mark all reachable rooms
	@param rooms - Table of room data
	@param spawnRoomId - ID of the spawn room
	@return reachableCount, rooms with distances
]]
local function floodFill(rooms, spawnRoomId)
	if not rooms[spawnRoomId] then
		warn("[DungeonValidator] Invalid spawn room ID")
		return 0, rooms
	end

	-- Initialize
	local queue = {spawnRoomId}
	local visited = {}

	-- Set spawn room
	rooms[spawnRoomId].IsReachable = true
	rooms[spawnRoomId].Distance = 0
	rooms[spawnRoomId].IsSpawnRoom = true
	visited[spawnRoomId] = true

	local reachableCount = 1
	local depth = 0

	-- Flood-fill BFS
	while #queue > 0 and depth < Config.PathfindingMaxDepth do
		local currentId = table.remove(queue, 1)
		local currentRoom = rooms[currentId]

		-- Visit all connected rooms
		for _, connectedId in ipairs(currentRoom.Connections) do
			if not visited[connectedId] then
				visited[connectedId] = true

				local connectedRoom = rooms[connectedId]
				connectedRoom.IsReachable = true
				connectedRoom.Distance = currentRoom.Distance + 1

				table.insert(queue, connectedId)
				reachableCount = reachableCount + 1
			end
		end

		depth = depth + 1
	end

	return reachableCount, rooms
end

--[[
	Finds the furthest reachable room from spawn (for boss placement)
	@param rooms - Table of room data
	@return bossRoom
]]
local function findBossRoom(rooms)
	local furthestRoom = nil
	local maxDistance = 0

	for _, room in ipairs(rooms) do
		if room.IsReachable and not room.IsSpawnRoom and room.Distance > maxDistance then
			maxDistance = room.Distance
			furthestRoom = room
		end
	end

	if furthestRoom then
		furthestRoom.IsBossRoom = true
		print(string.format("[DungeonValidator] Boss room at distance %d from spawn", furthestRoom.Distance))
	end

	return furthestRoom
end

-- ════════════════════════════════════════════════════════════════════════════
-- SPAWN POINT VALIDATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Validates a single spawn point for clearance
	@param position - Vector3 position to check
	@param dungeonModel - The dungeon model (to exclude from raycast)
	@return isValid, obstructionPercent
]]
local function validateSpawnPoint(position, dungeonModel)
	local Region3 = workspace.Region3
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {dungeonModel}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	-- Check for floor below (raycast down)
	local floorCheck = workspace:Raycast(
		position,
		Vector3.new(0, -10, 0),
		raycastParams
	)

	if not floorCheck then
		return false, 1.0, "No floor beneath spawn point"
	end

	-- Check clearance in cylinder around spawn point
	local checkPoints = 12 -- Sample points in circle
	local obstructedCount = 0
	local totalChecks = 0

	-- Check horizontal clearance at multiple heights
	for height = 0, Config.SpawnHeightCheck, 2 do
		for i = 1, checkPoints do
			local angle = (i / checkPoints) * math.pi * 2
			local offset = Vector3.new(
				math.cos(angle) * Config.SpawnClearanceRadius,
				height,
				math.sin(angle) * Config.SpawnClearanceRadius
			)

			local checkPos = position + offset
			local result = workspace:Raycast(
				position + Vector3.new(0, height, 0),
				offset,
				raycastParams
			)

			totalChecks = totalChecks + 1
			if result and result.Instance and result.Instance:IsDescendantOf(dungeonModel) then
				-- Hit a wall or obstacle in the dungeon
				obstructedCount = obstructedCount + 1
			end
		end
	end

	local obstructionPercent = obstructedCount / totalChecks

	local isValid = obstructionPercent <= Config.MaxObstructionPercent
	local reason = isValid and "Clear" or string.format("%.0f%% obstructed", obstructionPercent * 100)

	return isValid, obstructionPercent, reason
end

--[[
	Validates all spawn points in a dungeon
	@param dungeonModel - The dungeon model
	@return validSpawns, invalidSpawns, invalidSpawnData
]]
local function validateAllSpawnPoints(dungeonModel)
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[DungeonValidator] No Spawns folder found")
		return {}, {}, {}
	end

	local validSpawns = {}
	local invalidSpawns = {}
	local invalidSpawnData = {}

	for _, spawn in ipairs(spawnsFolder:GetChildren()) do
		if spawn:IsA("BasePart") then
			local spawnType = spawn:GetAttribute("SpawnType") or "Unknown"
			local isBoss = spawn:GetAttribute("IsBoss") or false

			-- Validate spawn point
			local isValid, obstructionPercent, reason = validateSpawnPoint(spawn.Position, dungeonModel)

			if isValid then
				table.insert(validSpawns, spawn)
			else
				table.insert(invalidSpawns, spawn)
				table.insert(invalidSpawnData, {
					Spawn = spawn,
					Position = spawn.Position,
					Type = spawnType,
					IsBoss = isBoss,
					Obstruction = obstructionPercent,
					Reason = reason
				})

				warn(string.format("[DungeonValidator] Invalid spawn: %s at %s - %s",
					spawnType,
					tostring(spawn.Position),
					reason
				))
			end
		end
	end

	print(string.format("[DungeonValidator] Spawn validation: %d valid, %d invalid",
		#validSpawns, #invalidSpawns))

	return validSpawns, invalidSpawns, invalidSpawnData
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Validates a dungeon's connectivity
	@param dungeonModel - The dungeon model to validate
	@param spawnPosition - Position of player spawn
	@return isValid, validationData
]]
function DungeonValidator:ValidateDungeon(dungeonModel, spawnPosition)
	if not dungeonModel then
		warn("[DungeonValidator] No dungeon model provided")
		return false, nil
	end

	print("[DungeonValidator] Starting validation...")

	-- Extract rooms from dungeon
	local rooms = extractRooms(dungeonModel)

	if #rooms < Config.MinReachableRooms then
		warn(string.format("[DungeonValidator] Not enough rooms detected: %d (min %d)", #rooms, Config.MinReachableRooms))
		return false, {
			Reason = "InsufficientRooms",
			RoomCount = #rooms
		}
	end

	-- Find spawn room (closest to spawn position)
	local spawnRoomId = 1
	local minDistance = math.huge
	for i, room in ipairs(rooms) do
		local distance = (room.Position - spawnPosition).Magnitude
		if distance < minDistance then
			minDistance = distance
			spawnRoomId = i
		end
	end

	print(string.format("[DungeonValidator] Spawn room: %d", spawnRoomId))

	-- Find connections between rooms
	rooms = findRoomConnections(rooms)

	-- Flood-fill from spawn
	local reachableCount, validatedRooms = floodFill(rooms, spawnRoomId)

	print(string.format("[DungeonValidator] Reachable rooms: %d / %d", reachableCount, #rooms))

	-- Check if enough rooms are reachable
	if reachableCount < Config.MinReachableRooms then
		warn(string.format("[DungeonValidator] Insufficient reachable rooms: %d (min %d)", reachableCount, Config.MinReachableRooms))
		return false, {
			Reason = "InsufficientReachableRooms",
			ReachableCount = reachableCount,
			TotalRooms = #rooms
		}
	end

	-- Find boss room (furthest from spawn)
	local bossRoom = findBossRoom(validatedRooms)

	if not bossRoom then
		warn("[DungeonValidator] No valid boss room found")
		return false, {
			Reason = "NoBossRoom"
		}
	end

	-- Check boss room distance
	if bossRoom.Distance < Config.MinBossRoomDistance / Config.RoomDistanceThreshold then
		warn(string.format("[DungeonValidator] Boss room too close to spawn: %d", bossRoom.Distance))
		return false, {
			Reason = "BossRoomTooClose",
			Distance = bossRoom.Distance
		}
	end

	-- Validate spawn points (enemies and portals)
	local validSpawns, invalidSpawns, invalidSpawnData = validateAllSpawnPoints(dungeonModel)

	if #invalidSpawns > 0 then
		warn(string.format("[DungeonValidator] Found %d invalid spawn points (inside walls or obstructed)", #invalidSpawns))
		-- Still pass validation but warn - invalid spawns will be skipped during spawning
		-- Could optionally fail here if you want stricter validation:
		-- return false, {
		-- 	Reason = "InvalidSpawnPoints",
		-- 	InvalidSpawns = #invalidSpawns,
		-- 	InvalidSpawnData = invalidSpawnData
		-- }
	end

	-- Success!
	print("[DungeonValidator] ✓ Dungeon validation PASSED")

	return true, {
		TotalRooms = #rooms,
		ReachableRooms = reachableCount,
		UnreachableRooms = #rooms - reachableCount,
		SpawnRoom = validatedRooms[spawnRoomId],
		BossRoom = bossRoom,
		Rooms = validatedRooms,
		ValidSpawns = validSpawns,
		InvalidSpawns = invalidSpawns,
		InvalidSpawnData = invalidSpawnData,
	}
end

--[[
	Marks the boss room with visual indicators
	@param bossRoom - The boss room data
	@param dungeonModel - The dungeon model
]]
function DungeonValidator:MarkBossRoom(bossRoom, dungeonModel)
	if not bossRoom or not dungeonModel then return end

	print("[DungeonValidator] Marking boss room...")

	-- Create boss room marker
	local marker = Instance.new("Part")
	marker.Name = "BossRoomMarker"
	marker.Size = Vector3.new(10, 0.5, 10)
	marker.Position = bossRoom.Position + Vector3.new(0, 0.25, 0)
	marker.Anchored = true
	marker.CanCollide = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(150, 0, 0)
	marker.Transparency = 0.5
	marker.Parent = dungeonModel

	-- Add attribute
	marker:SetAttribute("IsBossRoom", true)

	-- Add point light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 0, 0)
	light.Brightness = 5
	light.Range = 40
	light.Parent = marker

	-- Pulse effect
	task.spawn(function()
		while marker.Parent do
			marker.Transparency = 0.5 + math.sin(tick() * 2) * 0.2
			light.Brightness = 5 + math.sin(tick() * 2) * 2
			task.wait()
		end
	end)
end

--[[
	Validates and marks a dungeon
	@param dungeonModel - The dungeon model
	@param spawnPosition - Player spawn position
	@return isValid, validationData
]]
function DungeonValidator:ValidateAndMark(dungeonModel, spawnPosition)
	local isValid, data = self:ValidateDungeon(dungeonModel, spawnPosition)

	if isValid and data.BossRoom then
		self:MarkBossRoom(data.BossRoom, dungeonModel)
	end

	return isValid, data
end

--[[
	Prints validation report
	@param validationData - Data from ValidateDungeon
]]
function DungeonValidator:PrintReport(validationData)
	if not validationData then
		print("[DungeonValidator] No validation data")
		return
	end

	print("\n" .. string.rep("=", 60))
	print("DUNGEON VALIDATION REPORT")
	print(string.rep("=", 60))

	if validationData.Reason then
		print("Status: FAILED")
		print("Reason:", validationData.Reason)
		if validationData.RoomCount then
			print("Room Count:", validationData.RoomCount)
		end
		if validationData.ReachableCount then
			print("Reachable:", validationData.ReachableCount, "/", validationData.TotalRooms)
		end
	else
		print("Status: PASSED")
		print("Total Rooms:", validationData.TotalRooms)
		print("Reachable Rooms:", validationData.ReachableRooms)
		print("Unreachable Rooms:", validationData.UnreachableRooms)
		print("Boss Room Distance:", validationData.BossRoom.Distance)

		-- Spawn validation results
		if validationData.ValidSpawns then
			print("\nSpawn Point Validation:")
			print("  Valid Spawns:", #validationData.ValidSpawns)
			print("  Invalid Spawns:", #validationData.InvalidSpawns)

			if #validationData.InvalidSpawns > 0 then
				print("  ⚠️ WARNING: Some spawns are obstructed or inside walls!")
				for i, invalidData in ipairs(validationData.InvalidSpawnData) do
					print(string.format("    - %s: %s (%.0f%% obstructed)",
						invalidData.Type,
						invalidData.Reason,
						invalidData.Obstruction * 100
					))
				end
			else
				print("  ✓ All spawn points clear")
			end
		end
	end

	print(string.rep("=", 60) .. "\n")
end

--[[
	Checks if a specific spawn point is valid (public helper)
	@param position - Vector3 position to check
	@param dungeonModel - The dungeon model
	@return isValid, reason
]]
function DungeonValidator:IsSpawnPointValid(position, dungeonModel)
	local isValid, obstructionPercent, reason = validateSpawnPoint(position, dungeonModel)
	return isValid, reason
end

--[[
	Filters a list of spawn points to only include valid ones
	@param spawns - Array of spawn parts
	@param dungeonModel - The dungeon model
	@return validSpawns array
]]
function DungeonValidator:FilterValidSpawns(spawns, dungeonModel)
	local validSpawns = {}

	for _, spawn in ipairs(spawns) do
		if spawn:IsA("BasePart") then
			local isValid = validateSpawnPoint(spawn.Position, dungeonModel)
			if isValid then
				table.insert(validSpawns, spawn)
			end
		end
	end

	return validSpawns
end

return DungeonValidator
