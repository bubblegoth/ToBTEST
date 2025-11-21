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

	-- Success!
	print("[DungeonValidator] ✓ Dungeon validation PASSED")

	return true, {
		TotalRooms = #rooms,
		ReachableRooms = reachableCount,
		UnreachableRooms = #rooms - reachableCount,
		SpawnRoom = validatedRooms[spawnRoomId],
		BossRoom = bossRoom,
		Rooms = validatedRooms,
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
	end

	print(string.rep("=", 60) .. "\n")
end

return DungeonValidator
