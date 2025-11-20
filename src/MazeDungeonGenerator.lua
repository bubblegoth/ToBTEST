--[[
════════════════════════════════════════════════════════════════════════════════
Module: MazeDungeonGenerator
Location: ReplicatedStorage/src/
Description: Generates dungeons using maze algorithms (Recursive Backtracker).
             Creates guaranteed-connected layouts with rooms carved into the maze.
Version: 1.0
Last Updated: 2025-11-15

This approach is MORE RELIABLE than BSP because:
- Mathematically guaranteed connectivity
- Simple algorithm that rarely fails
- Easy to add rooms by "expanding" maze cells
════════════════════════════════════════════════════════════════════════════════
--]]

local Workspace = game:GetService("Workspace")
local MazeDungeonGenerator = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════
local Config = {
	-- Maze grid settings
	MazeWidth = 15,  -- Number of cells wide
	MazeHeight = 15, -- Number of cells tall
	CellSize = 20,   -- Each maze cell is 20x20 studs

	-- Room settings (rooms are carved from multiple maze cells)
	MinRooms = 4,
	MaxRooms = 8,
	MinRoomCells = 2,  -- Minimum cells per room (2x2 = 4 cells)
	MaxRoomCells = 4,  -- Maximum cells per room (4x4 = 16 cells)

	-- Physical settings
	WallHeight = 16,
	WallThickness = 2,
	FloorThickness = 2,
	CorridorWidth = 8,

	-- Materials
	FloorMaterial = Enum.Material.Cobblestone,
	WallMaterial = Enum.Material.Brick,
	FloorColor = Color3.fromRGB(60, 55, 50),
	WallColor = Color3.fromRGB(80, 75, 70),

	-- Spawning
	SpawnEnemies = true,
	SpawnLoot = true,
	EnemiesPerRoom = {Min = 1, Max = 4},
	LootChance = 0.5,

	-- Extra connections (breaks perfect maze for more interesting layout)
	ExtraConnectionChance = 0.1,
}

-- ════════════════════════════════════════════════════════════════════════════
-- MAZE GENERATION (Recursive Backtracker / DFS)
-- ════════════════════════════════════════════════════════════════════════════
local function createMazeGrid()
	local grid = {}
	for x = 1, Config.MazeWidth do
		grid[x] = {}
		for y = 1, Config.MazeHeight do
			grid[x][y] = {
				visited = false,
				walls = {N = true, S = true, E = true, W = true},
				isRoom = false,
				roomId = nil,
			}
		end
	end
	return grid
end

local function getUnvisitedNeighbors(grid, x, y)
	local neighbors = {}

	-- North
	if y > 1 and not grid[x][y-1].visited then
		table.insert(neighbors, {x = x, y = y-1, dir = "N", opposite = "S"})
	end
	-- South
	if y < Config.MazeHeight and not grid[x][y+1].visited then
		table.insert(neighbors, {x = x, y = y+1, dir = "S", opposite = "N"})
	end
	-- East
	if x < Config.MazeWidth and not grid[x+1][y].visited then
		table.insert(neighbors, {x = x+1, y = y, dir = "E", opposite = "W"})
	end
	-- West
	if x > 1 and not grid[x-1][y].visited then
		table.insert(neighbors, {x = x-1, y = y, dir = "W", opposite = "E"})
	end

	return neighbors
end

local function generateMaze()
	local grid = createMazeGrid()
	local stack = {}

	-- Start from random cell
	local startX = math.random(1, Config.MazeWidth)
	local startY = math.random(1, Config.MazeHeight)

	grid[startX][startY].visited = true
	table.insert(stack, {x = startX, y = startY})

	local visitedCount = 1
	local totalCells = Config.MazeWidth * Config.MazeHeight

	-- Recursive backtracker algorithm
	while #stack > 0 do
		local current = stack[#stack]
		local neighbors = getUnvisitedNeighbors(grid, current.x, current.y)

		if #neighbors > 0 then
			-- Pick random unvisited neighbor
			local next = neighbors[math.random(1, #neighbors)]

			-- Remove walls between current and next
			grid[current.x][current.y].walls[next.dir] = false
			grid[next.x][next.y].walls[next.opposite] = false

			-- Mark as visited and push to stack
			grid[next.x][next.y].visited = true
			table.insert(stack, {x = next.x, y = next.y})
			visitedCount = visitedCount + 1
		else
			-- Backtrack
			table.remove(stack)
		end
	end

	print(string.format("[MazeDungeon] Generated maze: %dx%d, visited %d/%d cells",
		Config.MazeWidth, Config.MazeHeight, visitedCount, totalCells))

	-- Add some extra connections to break perfect maze (optional, makes it less frustrating)
	local extraConnections = 0
	for x = 1, Config.MazeWidth do
		for y = 1, Config.MazeHeight do
			if math.random() < Config.ExtraConnectionChance then
				-- Randomly remove a wall
				local dirs = {"N", "S", "E", "W"}
				local dir = dirs[math.random(1, 4)]

				local nx, ny = x, y
				if dir == "N" and y > 1 then ny = y - 1
				elseif dir == "S" and y < Config.MazeHeight then ny = y + 1
				elseif dir == "E" and x < Config.MazeWidth then nx = x + 1
				elseif dir == "W" and x > 1 then nx = x - 1
				else continue end

				if grid[x][y].walls[dir] then
					grid[x][y].walls[dir] = false
					local opposite = (dir == "N" and "S") or (dir == "S" and "N") or (dir == "E" and "W") or "E"
					grid[nx][ny].walls[opposite] = false
					extraConnections = extraConnections + 1
				end
			end
		end
	end

	print(string.format("[MazeDungeon] Added %d extra connections", extraConnections))

	return grid
end

-- ════════════════════════════════════════════════════════════════════════════
-- ROOM PLACEMENT (Carve rooms into the maze)
-- ════════════════════════════════════════════════════════════════════════════
local function carveRooms(grid)
	local rooms = {}
	local roomCount = math.random(Config.MinRooms, Config.MaxRooms)

	for i = 1, roomCount do
		local attempts = 0
		local placed = false

		while attempts < 20 and not placed do
			attempts = attempts + 1

			-- Random room size
			local roomW = math.random(Config.MinRoomCells, Config.MaxRoomCells)
			local roomH = math.random(Config.MinRoomCells, Config.MaxRoomCells)

			-- Random position (leaving border)
			local startX = math.random(2, math.max(2, Config.MazeWidth - roomW - 1))
			local startY = math.random(2, math.max(2, Config.MazeHeight - roomH - 1))

			-- Check if area is free
			local canPlace = true
			for x = startX, startX + roomW - 1 do
				for y = startY, startY + roomH - 1 do
					if x > Config.MazeWidth or y > Config.MazeHeight then
						canPlace = false
						break
					end
					if grid[x][y].isRoom then
						canPlace = false
						break
					end
				end
				if not canPlace then break end
			end

			if canPlace then
				-- Carve out the room (remove internal walls)
				local room = {
					id = i,
					startX = startX,
					startY = startY,
					width = roomW,
					height = roomH,
					cells = {},
					centerX = (startX + roomW/2 - 0.5) * Config.CellSize,
					centerY = (startY + roomH/2 - 0.5) * Config.CellSize,
				}

				for x = startX, startX + roomW - 1 do
					for y = startY, startY + roomH - 1 do
						grid[x][y].isRoom = true
						grid[x][y].roomId = i
						table.insert(room.cells, {x = x, y = y})

						-- Remove internal walls
						if x < startX + roomW - 1 then
							grid[x][y].walls.E = false
							grid[x+1][y].walls.W = false
						end
						if y < startY + roomH - 1 then
							grid[x][y].walls.S = false
							grid[x][y+1].walls.N = false
						end
					end
				end

				table.insert(rooms, room)
				placed = true
				print(string.format("[MazeDungeon] Carved room %d: %dx%d at grid (%d,%d)",
					i, roomW, roomH, startX, startY))
			end
		end
	end

	print(string.format("[MazeDungeon] Carved %d rooms into maze", #rooms))
	return rooms
end

-- ════════════════════════════════════════════════════════════════════════════
-- 3D BUILDER
-- ════════════════════════════════════════════════════════════════════════════
local Builder = {}

function Builder.createFloor(worldX, worldY, width, height, parent, name)
	local floor = Instance.new("Part")
	floor.Name = name or "Floor"
	floor.Size = Vector3.new(width, Config.FloorThickness, height)
	floor.Position = Vector3.new(worldX + width/2, -Config.FloorThickness/2, worldY + height/2)
	floor.Anchored = true
	floor.Material = Config.FloorMaterial
	floor.Color = Config.FloorColor
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = parent
	return floor
end

function Builder.createWall(x, y, z, sizeX, sizeY, sizeZ, parent, name)
	local wall = Instance.new("Part")
	wall.Name = name or "Wall"
	wall.Size = Vector3.new(sizeX, sizeY, sizeZ)
	wall.Position = Vector3.new(x, y, z)
	wall.Anchored = true
	wall.Material = Config.WallMaterial
	wall.Color = Config.WallColor
	wall.Parent = parent
	return wall
end

function Builder.createCeiling(worldX, worldY, width, height, parent)
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(width, Config.FloorThickness, height)
	ceiling.Position = Vector3.new(worldX + width/2, Config.WallHeight + Config.FloorThickness/2, worldY + height/2)
	ceiling.Anchored = true
	ceiling.Material = Config.WallMaterial
	ceiling.Color = Config.WallColor
	ceiling.Parent = parent
	return ceiling
end

function Builder.buildMazeCell(grid, x, y, parent)
	local cell = grid[x][y]
	local worldX = (x - 1) * Config.CellSize
	local worldY = (y - 1) * Config.CellSize

	local cellFolder = Instance.new("Folder")
	cellFolder.Name = string.format("Cell_%d_%d", x, y)
	cellFolder.Parent = parent

	-- Floor
	Builder.createFloor(worldX, worldY, Config.CellSize, Config.CellSize, cellFolder, "Floor")

	-- Ceiling
	Builder.createCeiling(worldX, worldY, Config.CellSize, Config.CellSize, cellFolder)

	-- Add light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 150)
	light.Brightness = 0.8
	light.Range = Config.CellSize * 1.5

	local lightPart = Instance.new("Part")
	lightPart.Name = "LightHolder"
	lightPart.Size = Vector3.new(1, 1, 1)
	lightPart.Position = Vector3.new(worldX + Config.CellSize/2, Config.WallHeight - 1, worldY + Config.CellSize/2)
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Transparency = 1
	lightPart.Parent = cellFolder
	light.Parent = lightPart

	-- Walls (only build if wall exists)
	local wallH = Config.WallHeight
	local wallT = Config.WallThickness
	local cellS = Config.CellSize

	-- North wall
	if cell.walls.N then
		Builder.createWall(
			worldX + cellS/2, wallH/2, worldY - wallT/2,
			cellS + wallT, wallH, wallT,
			cellFolder, "Wall_N"
		)
	end

	-- South wall
	if cell.walls.S then
		Builder.createWall(
			worldX + cellS/2, wallH/2, worldY + cellS + wallT/2,
			cellS + wallT, wallH, wallT,
			cellFolder, "Wall_S"
		)
	end

	-- West wall
	if cell.walls.W then
		Builder.createWall(
			worldX - wallT/2, wallH/2, worldY + cellS/2,
			wallT, wallH, cellS,
			cellFolder, "Wall_W"
		)
	end

	-- East wall
	if cell.walls.E then
		Builder.createWall(
			worldX + cellS + wallT/2, wallH/2, worldY + cellS/2,
			wallT, wallH, cellS,
			cellFolder, "Wall_E"
		)
	end

	return cellFolder
end

function Builder.createSpawnPoint(worldX, worldY, parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlayerSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(worldX, 1, worldY)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Enabled = true
	spawn.Parent = parent

	print(string.format("[MazeDungeon] Created PlayerSpawn at (%.1f, %.1f)", worldX, worldY))
	return spawn
end

function Builder.createEnemySpawn(worldX, worldY, parent)
	local spawn = Instance.new("Part")
	spawn.Name = "EnemySpawn"
	spawn.Size = Vector3.new(2, 0.5, 2)
	spawn.Position = Vector3.new(worldX, 0.5, worldY)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 0.8
	spawn.Color = Color3.fromRGB(255, 0, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = parent
	spawn:SetAttribute("SpawnType", "Enemy")
	return spawn
end

function Builder.createLootSpawn(worldX, worldY, parent)
	local spawn = Instance.new("Part")
	spawn.Name = "LootSpawn"
	spawn.Size = Vector3.new(2, 0.5, 2)
	spawn.Position = Vector3.new(worldX, 0.5, worldY)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 0.8
	spawn.Color = Color3.fromRGB(255, 255, 0)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = parent
	spawn:SetAttribute("SpawnType", "Loot")
	return spawn
end

function Builder.createBossMarker(worldX, worldY, parent)
	local marker = Instance.new("Part")
	marker.Name = "BossMarker"
	marker.Size = Vector3.new(8, 1, 8)
	marker.Position = Vector3.new(worldX, 0.5, worldY)
	marker.Anchored = true
	marker.CanCollide = false
	marker.Transparency = 0.5
	marker.Color = Color3.fromRGB(255, 0, 255)
	marker.Material = Enum.Material.Neon
	marker.Parent = parent
	marker:SetAttribute("IsBossRoom", true)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 0, 255)
	light.Brightness = 3
	light.Range = 15
	light.Parent = marker

	return marker
end

function Builder.createPerimeter(parent, width, height)
	local wallHeight = 50
	local thickness = 10

	-- North
	local north = Instance.new("Part")
	north.Name = "Perimeter_N"
	north.Size = Vector3.new(width + thickness*2, wallHeight, thickness)
	north.Position = Vector3.new(width/2, wallHeight/2, -thickness/2)
	north.Anchored = true
	north.Transparency = 1
	north.CanCollide = true
	north.Parent = parent

	-- South
	local south = Instance.new("Part")
	south.Name = "Perimeter_S"
	south.Size = Vector3.new(width + thickness*2, wallHeight, thickness)
	south.Position = Vector3.new(width/2, wallHeight/2, height + thickness/2)
	south.Anchored = true
	south.Transparency = 1
	south.CanCollide = true
	south.Parent = parent

	-- West
	local west = Instance.new("Part")
	west.Name = "Perimeter_W"
	west.Size = Vector3.new(thickness, wallHeight, height + thickness*2)
	west.Position = Vector3.new(-thickness/2, wallHeight/2, height/2)
	west.Anchored = true
	west.Transparency = 1
	west.CanCollide = true
	west.Parent = parent

	-- East
	local east = Instance.new("Part")
	east.Name = "Perimeter_E"
	east.Size = Vector3.new(thickness, wallHeight, height + thickness*2)
	east.Position = Vector3.new(width + thickness/2, wallHeight/2, height/2)
	east.Anchored = true
	east.Transparency = 1
	east.CanCollide = true
	east.Parent = parent
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════
function MazeDungeonGenerator.Generate(seed, parent)
	if seed then
		math.randomseed(seed)
	else
		math.randomseed(tick())
	end

	print("[MazeDungeon] ═══════════════════════════════════════")
	print("[MazeDungeon] Generating maze dungeon...")

	-- Step 1: Generate maze
	local grid = generateMaze()

	-- Step 2: Carve rooms into maze
	local rooms = carveRooms(grid)

	if #rooms < 2 then
		warn("[MazeDungeon] Not enough rooms generated!")
		return nil
	end

	-- Step 3: Create 3D structure
	local dungeonModel = Instance.new("Model")
	dungeonModel.Name = "GeneratedDungeon"
	dungeonModel.Parent = parent or workspace

	local cellsFolder = Instance.new("Folder")
	cellsFolder.Name = "Cells"
	cellsFolder.Parent = dungeonModel

	local roomsFolder = Instance.new("Folder")
	roomsFolder.Name = "Rooms"
	roomsFolder.Parent = dungeonModel

	local spawnsFolder = Instance.new("Folder")
	spawnsFolder.Name = "Spawns"
	spawnsFolder.Parent = dungeonModel

	-- Build all maze cells
	print("[MazeDungeon] Building 3D maze structure...")
	for x = 1, Config.MazeWidth do
		for y = 1, Config.MazeHeight do
			Builder.buildMazeCell(grid, x, y, cellsFolder)
		end
	end

	-- Add perimeter
	local totalWidth = Config.MazeWidth * Config.CellSize
	local totalHeight = Config.MazeHeight * Config.CellSize
	Builder.createPerimeter(dungeonModel, totalWidth, totalHeight)

	-- Step 4: Set up rooms (spawn, enemies, loot)
	print("[MazeDungeon] Setting up room contents...")

	-- First room = spawn
	local spawnRoom = rooms[1]
	Builder.createSpawnPoint(spawnRoom.centerX, spawnRoom.centerY, spawnsFolder)

	local spawnRoomFolder = Instance.new("Folder")
	spawnRoomFolder.Name = "SpawnRoom"
	spawnRoomFolder:SetAttribute("CenterX", spawnRoom.centerX)
	spawnRoomFolder:SetAttribute("CenterY", spawnRoom.centerY)
	spawnRoomFolder:SetAttribute("IsSpawnRoom", true)
	spawnRoomFolder.Parent = roomsFolder

	-- Last room = boss
	local bossRoom = rooms[#rooms]
	Builder.createBossMarker(bossRoom.centerX, bossRoom.centerY, spawnsFolder)
	Builder.createEnemySpawn(bossRoom.centerX, bossRoom.centerY, spawnsFolder) -- Boss spawn

	local bossRoomFolder = Instance.new("Folder")
	bossRoomFolder.Name = "BossRoom"
	bossRoomFolder:SetAttribute("CenterX", bossRoom.centerX)
	bossRoomFolder:SetAttribute("CenterY", bossRoom.centerY)
	bossRoomFolder:SetAttribute("IsBossRoom", true)
	bossRoomFolder:SetAttribute("IsGoalRoom", true)
	bossRoomFolder.Parent = roomsFolder

	-- Middle rooms = enemies and loot
	for i = 2, #rooms - 1 do
		local room = rooms[i]
		local roomFolder = Instance.new("Folder")
		roomFolder.Name = "Room_" .. i
		roomFolder:SetAttribute("CenterX", room.centerX)
		roomFolder:SetAttribute("CenterY", room.centerY)
		roomFolder.Parent = roomsFolder

		-- Enemies
		if Config.SpawnEnemies then
			local enemyCount = math.random(Config.EnemiesPerRoom.Min, Config.EnemiesPerRoom.Max)
			for e = 1, enemyCount do
				local offsetX = math.random(-room.width * Config.CellSize/3, room.width * Config.CellSize/3)
				local offsetY = math.random(-room.height * Config.CellSize/3, room.height * Config.CellSize/3)
				Builder.createEnemySpawn(room.centerX + offsetX, room.centerY + offsetY, spawnsFolder)
			end
		end

		-- Loot
		if Config.SpawnLoot and math.random() < Config.LootChance then
			Builder.createLootSpawn(room.centerX, room.centerY, spawnsFolder)
		end
	end

	-- Set attributes
	dungeonModel:SetAttribute("RoomCount", #rooms)
	dungeonModel:SetAttribute("MazeWidth", Config.MazeWidth)
	dungeonModel:SetAttribute("MazeHeight", Config.MazeHeight)
	dungeonModel:SetAttribute("CellSize", Config.CellSize)
	dungeonModel:SetAttribute("Seed", seed or 0)
	dungeonModel:SetAttribute("Algorithm", "Maze_RecursiveBacktracker")

	print("[MazeDungeon] ═══════════════════════════════════════")
	print(string.format("[MazeDungeon] ✓ Dungeon complete!"))
	print(string.format("[MazeDungeon]   • %d rooms carved into maze", #rooms))
	print(string.format("[MazeDungeon]   • %dx%d maze grid (%d cells)", Config.MazeWidth, Config.MazeHeight, Config.MazeWidth * Config.MazeHeight))
	print(string.format("[MazeDungeon]   • Spawn room: (%.0f, %.0f)", spawnRoom.centerX, spawnRoom.centerY))
	print(string.format("[MazeDungeon]   • Boss room: (%.0f, %.0f)", bossRoom.centerX, bossRoom.centerY))
	print("[MazeDungeon] ═══════════════════════════════════════")

	return dungeonModel
end

function MazeDungeonGenerator.Clear()
	local existing = Workspace:FindFirstChild("GeneratedDungeon")
	if existing then
		existing:Destroy()
		print("[MazeDungeon] Cleared existing dungeon")
	end
end

function MazeDungeonGenerator.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

function MazeDungeonGenerator.GetConfig()
	return Config
end

function MazeDungeonGenerator.GetSpawnPoints(dungeonModel)
	local spawns = {
		PlayerSpawns = {},
		EnemySpawns = {},
		LootSpawns = {},
	}

	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	if not spawnsFolder then return spawns end

	for _, spawn in ipairs(spawnsFolder:GetChildren()) do
		if spawn.Name == "PlayerSpawn" then
			table.insert(spawns.PlayerSpawns, spawn)
		elseif spawn:GetAttribute("SpawnType") == "Enemy" then
			table.insert(spawns.EnemySpawns, spawn)
		elseif spawn:GetAttribute("SpawnType") == "Loot" then
			table.insert(spawns.LootSpawns, spawn)
		end
	end

	return spawns
end

function MazeDungeonGenerator.GetRooms(dungeonModel)
	local roomsFolder = dungeonModel:FindFirstChild("Rooms")
	if not roomsFolder then return {} end
	return roomsFolder:GetChildren()
end

return MazeDungeonGenerator
