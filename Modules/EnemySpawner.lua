--[[
════════════════════════════════════════════════════════════════════════════════
Module: EnemySpawner
Location: ReplicatedStorage/Modules/
Description: Spawns enemies in per-player dungeon instances.
             Works with MazeDungeonGenerator spawn markers.
             Integrates MobGenerator and EnemyDeathHandler.
Version: 1.0
Last Updated: 2025-11-20
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemySpawner = {}

-- Load dependencies
local MobGenerator = require(script.Parent.MobGenerator)
local EnemyDeathHandler = require(script.Parent.EnemyDeathHandler)

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════
local Config = {
	-- Scaling
	HealthPerFloor = 15,      -- +15 HP per floor
	DamagePerFloor = 2,       -- +2 damage per floor
	SpeedPerFloor = 0.5,      -- +0.5 speed per floor

	-- Boss scaling
	BossHealthMultiplier = 3,
	BossDamageMultiplier = 2,
	BossScaleMultiplier = 1.5,

	-- Spawning
	SpawnOffset = Vector3.new(0, 1, 0), -- Offset above spawn marker
}

-- ════════════════════════════════════════════════════════════════════════════
-- LEVEL SCALING
-- ════════════════════════════════════════════════════════════════════════════

local function scaleEnemyStats(mob, floorNumber)
	if not mob then return end

	local humanoid = mob:FindFirstChild("Humanoid")
	if not humanoid then return end

	local level = math.abs(floorNumber)

	-- Get base stats
	local baseHealth = mob:GetAttribute("MaxHealth") or 100
	local baseDamage = mob:GetAttribute("Damage") or 10
	local baseSpeed = mob:GetAttribute("Speed") or 16

	-- Calculate scaled stats
	local newHealth = math.floor(baseHealth + (Config.HealthPerFloor * level))
	local newDamage = math.floor(baseDamage + (Config.DamagePerFloor * level))
	local newSpeed = math.floor(baseSpeed + (Config.SpeedPerFloor * level))

	-- Apply to humanoid
	humanoid.MaxHealth = newHealth
	humanoid.Health = newHealth
	humanoid.WalkSpeed = newSpeed

	-- Store attributes
	mob:SetAttribute("Level", level)
	mob:SetAttribute("MaxHealth", newHealth)
	mob:SetAttribute("Health", newHealth)
	mob:SetAttribute("Damage", newDamage)
	mob:SetAttribute("Speed", newSpeed)

	-- Update name
	mob.Name = mob.Name .. " Lv." .. level

	return {
		level = level,
		health = newHealth,
		damage = newDamage,
		speed = newSpeed,
	}
end

local function scaleBoss(mob, floorNumber)
	if not mob then return end

	-- First apply normal scaling
	local stats = scaleEnemyStats(mob, floorNumber)
	if not stats then return end

	local humanoid = mob:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Apply boss multipliers
	local bossHealth = math.floor(stats.health * Config.BossHealthMultiplier)
	local bossDamage = math.floor(stats.damage * Config.BossDamageMultiplier)

	humanoid.MaxHealth = bossHealth
	humanoid.Health = bossHealth

	mob:SetAttribute("MaxHealth", bossHealth)
	mob:SetAttribute("Health", bossHealth)
	mob:SetAttribute("Damage", bossDamage)
	mob:SetAttribute("IsBoss", true)

	-- Make boss bigger
	if mob.PrimaryPart then
		for _, part in ipairs(mob:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Size = part.Size * Config.BossScaleMultiplier
			end
		end
	end

	-- Update name
	mob.Name = "[BOSS] " .. mob.Name

	print(string.format("[EnemySpawner] Boss scaled: HP=%d, DMG=%d", bossHealth, bossDamage))

	return {
		level = stats.level,
		health = bossHealth,
		damage = bossDamage,
		speed = stats.speed,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- SPAWNING
-- ════════════════════════════════════════════════════════════════════════════

local function spawnEnemyAtMarker(spawnMarker, floorNumber, parentFolder, isBoss)
	if not spawnMarker then return nil end

	local spawnPos = spawnMarker.Position + Config.SpawnOffset

	-- Generate mob
	local mob, baseStats = MobGenerator.SpawnAt(spawnPos, parentFolder)

	if not mob then
		warn("[EnemySpawner] Failed to generate mob")
		return nil
	end

	-- Scale by floor
	if isBoss then
		scaleBoss(mob, floorNumber)
	else
		scaleEnemyStats(mob, floorNumber)
	end

	-- Set up death handler
	EnemyDeathHandler.SetupEnemy(mob, parentFolder)

	return mob
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Spawns enemies in a dungeon model
	@param dungeonModel - The dungeon Model created by MazeDungeonGenerator
	@param floorNumber - Floor number for level scaling
	@param player - The player who owns this instance (for tracking)
	@return enemyList, enemyCount
]]
function EnemySpawner.SpawnEnemiesInDungeon(dungeonModel, floorNumber, player)
	if not dungeonModel then
		warn("[EnemySpawner] No dungeon model provided")
		return {}, 0
	end

	print(string.format("[EnemySpawner] Spawning enemies for floor %d (Player: %s)", floorNumber, player and player.Name or "N/A"))

	-- Find spawn markers
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[EnemySpawner] No Spawns folder found in dungeon")
		return {}, 0
	end

	-- Create or find enemies folder
	local enemiesFolder = dungeonModel:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = dungeonModel
	end

	-- Clear existing enemies
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		enemy:Destroy()
	end

	local enemies = {}
	local enemyCount = 0
	local bossCount = 0

	-- Spawn at each marker
	for _, spawn in ipairs(spawnsFolder:GetChildren()) do
		if spawn:GetAttribute("SpawnType") == "Enemy" then
			local isBoss = spawn:GetAttribute("IsBoss") or false

			local mob = spawnEnemyAtMarker(spawn, floorNumber, enemiesFolder, isBoss)

			if mob then
				table.insert(enemies, mob)
				enemyCount = enemyCount + 1

				if isBoss then
					bossCount = bossCount + 1
				end
			end
		end
	end

	print(string.format("[EnemySpawner] ✓ Spawned %d enemies (%d bosses) for floor %d",
		enemyCount, bossCount, floorNumber))

	return enemies, enemyCount
end

--[[
	Gets active enemies for a dungeon
	@param dungeonModel - The dungeon Model
	@return enemies
]]
function EnemySpawner.GetActiveEnemies(dungeonModel)
	if not dungeonModel then return {} end

	local enemiesFolder = dungeonModel:FindFirstChild("Enemies")
	if not enemiesFolder then return {} end

	local activeEnemies = {}

	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		if enemy:IsA("Model") and not enemy:GetAttribute("IsDead") then
			table.insert(activeEnemies, enemy)
		end
	end

	return activeEnemies
end

--[[
	Clears all enemies in a dungeon
	@param dungeonModel - The dungeon Model
]]
function EnemySpawner.ClearEnemies(dungeonModel)
	if not dungeonModel then return end

	local enemiesFolder = dungeonModel:FindFirstChild("Enemies")
	if not enemiesFolder then return end

	local count = 0
	for _, enemy in ipairs(enemiesFolder:GetChildren()) do
		enemy:Destroy()
		count = count + 1
	end

	print(string.format("[EnemySpawner] Cleared %d enemies", count))
end

function EnemySpawner.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

function EnemySpawner.GetConfig()
	return Config
end

-- Initialize death handler
EnemyDeathHandler.Initialize()

return EnemySpawner
