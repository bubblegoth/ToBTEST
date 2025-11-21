--[[
════════════════════════════════════════════════════════════════════════════════
Module: EnemyDeathHandler
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Handles enemy death - cleanup, loot drops, XP rewards.
             Cleans up damage numbers, spawns weapon drops based on level.
Version: 1.0
Last Updated: 2025-11-15
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local EnemyDeathHandler = {}

-- Try to load optional modules
local ModularLootGen = nil
local WeaponGenerator = nil
local PickupSystem = nil

local function loadModules()
	-- Try to load from Modules folder (our structure)
	local Modules = ReplicatedStorage:FindFirstChild("Modules")
	if Modules then
		if Modules:FindFirstChild("ModularLootGen") then
			ModularLootGen = require(Modules.ModularLootGen)
			print("[EnemyDeath] Loaded ModularLootGen")
		end
		if Modules:FindFirstChild("WeaponGenerator") then
			WeaponGenerator = require(Modules.WeaponGenerator)
			print("[EnemyDeath] Loaded WeaponGenerator")
		end
		if Modules:FindFirstChild("PickupSystem") then
			PickupSystem = require(Modules.PickupSystem)
			print("[EnemyDeath] Loaded PickupSystem")
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Loot
	BaseDropChance = 0.4,         -- 40% base chance to drop weapon
	BossDropChance = 1.0,         -- 100% for bosses
	MultiDropChance = 0.1,        -- 10% chance for additional drop

	-- Death effects
	DeathFadeTime = 2.0,          -- Seconds to fade out corpse
	CorpseLingerTime = 5.0,       -- Seconds before corpse is removed

	-- Damage number cleanup
	CleanupRadius = 20,           -- Studs around enemy to clean damage numbers

	-- Drop positioning
	DropHeight = 3,               -- How high above ground to spawn drops
	DropSpread = 5,               -- Random spread for multiple drops
}

-- ════════════════════════════════════════════════════════════════════════════
-- DAMAGE NUMBER CLEANUP
-- ════════════════════════════════════════════════════════════════════════════

local function cleanupDamageNumbers(position)
	-- Find and remove all damage number GUIs near the enemy
	local cleanedCount = 0

	-- Check workspace for BillboardGuis (common for damage numbers)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BillboardGui") and obj.Name == "DamageNumber" then
			-- Check if it's near the death position
			if obj.Adornee and obj.Adornee:IsA("BasePart") then
				local dist = (obj.Adornee.Position - position).Magnitude
				if dist < Config.CleanupRadius then
					obj:Destroy()
					cleanedCount = cleanedCount + 1
				end
			elseif obj.Parent and obj.Parent:IsA("BasePart") then
				local dist = (obj.Parent.Position - position).Magnitude
				if dist < Config.CleanupRadius then
					obj:Destroy()
					cleanedCount = cleanedCount + 1
				end
			end
		end
	end

	-- Also check for parts named "DamageNumber" or similar
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name == "DamageNumber" or obj.Name:find("Damage")) then
			local dist = (obj.Position - position).Magnitude
			if dist < Config.CleanupRadius then
				obj:Destroy()
				cleanedCount = cleanedCount + 1
			end
		end
	end

	if cleanedCount > 0 then
		print(string.format("[EnemyDeath] Cleaned up %d damage numbers", cleanedCount))
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- LOOT DROPS
-- ════════════════════════════════════════════════════════════════════════════

local function getDropPosition(basePosition)
	local offset = Vector3.new(
		(math.random() - 0.5) * Config.DropSpread * 2,
		Config.DropHeight,
		(math.random() - 0.5) * Config.DropSpread * 2
	)
	return basePosition + offset
end

local function createWeaponDrop(position, level, parent)
	-- Try using ModularLootGen if available
	if ModularLootGen and WeaponGenerator then
		local weaponData = WeaponGenerator.Generate(level)
		local lootDrop = ModularLootGen.CreateLootDrop(weaponData, position, parent or workspace)
		return lootDrop
	end

	-- Fallback: create simple placeholder
	warn("[EnemyDeath] ModularLootGen not available, creating placeholder drop")
	local drop = Instance.new("Part")
	drop.Name = "WeaponDrop_Lv" .. level
	drop.Size = Vector3.new(2, 1, 4)
	drop.Position = position
	drop.Anchored = false
	drop.CanCollide = true
	drop.Color = Color3.fromRGB(255, 200, 0)
	drop.Material = Enum.Material.Neon
	drop.Parent = parent or workspace

	-- Add info
	drop:SetAttribute("IsWeaponDrop", true)
	drop:SetAttribute("Level", level)
	drop:SetAttribute("Rarity", "Common")

	-- Add pickup prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt.ObjectText = "Weapon Lv." .. level
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.Parent = drop

	-- Auto-despawn after 60 seconds
	Debris:AddItem(drop, 60)

	return drop
end

local function rollForDrops(enemyModel, position, parent)
	local drops = {}

	local level = enemyModel:GetAttribute("Level") or 1
	local isBoss = enemyModel:GetAttribute("IsBoss") or false
	local floorNumber = enemyModel:GetAttribute("FloorNumber") or 1

	-- FLOOR 1: Only drop health/ammo (no weapons until Floor 2)
	if floorNumber == 1 then
		print("[EnemyDeath] Floor 1 - No weapon drops (health/ammo only)")
		if PickupSystem then
			PickupSystem.SpawnPickupsFromEnemy(position, floorNumber, parent)
		end
		return drops
	end

	-- ALL FLOORS: Always spawn health/ammo pickups
	if PickupSystem then
		PickupSystem.SpawnPickupsFromEnemy(position, floorNumber, parent)
	end

	-- FLOOR 2+: Normal weapon drops
	-- Determine drop chance
	local dropChance = Config.BaseDropChance
	if isBoss then
		dropChance = Config.BossDropChance
	end

	-- Roll for primary drop
	if math.random() < dropChance then
		local dropPos = getDropPosition(position)
		local drop = createWeaponDrop(dropPos, level, parent)
		if drop then
			table.insert(drops, drop)
			print(string.format("[EnemyDeath] Dropped %s at level %d", drop.Name, level))
		end
	end

	-- Roll for additional drops (rare)
	if math.random() < Config.MultiDropChance then
		local dropPos = getDropPosition(position)
		local drop = createWeaponDrop(dropPos, level, parent)
		if drop then
			table.insert(drops, drop)
			print(string.format("[EnemyDeath] Bonus drop: %s", drop.Name))
		end
	end

	-- Bosses always drop extra
	if isBoss then
		for i = 1, 2 do -- 2 extra drops for boss
			local dropPos = getDropPosition(position)
			local drop = createWeaponDrop(dropPos, level, parent)
			if drop then
				table.insert(drops, drop)
			end
		end
	end

	return drops
end

-- ════════════════════════════════════════════════════════════════════════════
-- DEATH EFFECTS
-- ════════════════════════════════════════════════════════════════════════════

local function applyDeathEffects(enemyModel)
	-- Fade out the enemy
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < Config.DeathFadeTime do
			local alpha = (tick() - startTime) / Config.DeathFadeTime

			for _, part in ipairs(enemyModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = math.min(part.Transparency + 0.02, alpha)
				end
			end

			task.wait(0.05)
		end
	end)
end

local function disableEnemy(enemyModel)
	-- Stop enemy from doing anything
	local humanoid = enemyModel:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = 0
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end

	-- Disable collision and queries (can't be shot anymore!)
	for _, part in ipairs(enemyModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false -- Important: prevents raycast/projectile hits!
			part.Anchored = true
		end
	end

	-- Mark as dead
	enemyModel:SetAttribute("IsDead", true)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

function EnemyDeathHandler.Initialize()
	loadModules()
	print("[EnemyDeath] Initialized")
end

function EnemyDeathHandler.OnEnemyDeath(enemyModel, killerPlayer, parentFolder)
	if not enemyModel then return end
	if enemyModel:GetAttribute("IsDead") then return end -- Already dead

	local enemyName = enemyModel.Name
	local level = enemyModel:GetAttribute("Level") or 1
	local position = enemyModel.PrimaryPart and enemyModel.PrimaryPart.Position or Vector3.new(0, 5, 0)

	print(string.format("[EnemyDeath] %s (Lv.%d) died", enemyName, level))

	-- 1. Disable the enemy immediately
	disableEnemy(enemyModel)

	-- 2. Clean up damage numbers
	cleanupDamageNumbers(position)

	-- 3. Apply death effects (fade out)
	applyDeathEffects(enemyModel)

	-- 4. Drop loot (in same parent folder as dungeon for per-player instances)
	local drops = rollForDrops(enemyModel, position, parentFolder)

	-- 5. Award XP to killer (if applicable)
	if killerPlayer then
		-- You'd fire a remote event here to update player XP
		print(string.format("[EnemyDeath] %s killed %s", killerPlayer.Name, enemyName))
	end

	-- 6. Schedule cleanup
	Debris:AddItem(enemyModel, Config.CorpseLingerTime)

	-- 7. Fire death event (for other systems to hook into)
	local deathEvent = enemyModel:FindFirstChild("Died")
	if deathEvent and deathEvent:IsA("BindableEvent") then
		deathEvent:Fire(killerPlayer)
	end

	return {
		enemy = enemyName,
		level = level,
		drops = drops,
		position = position,
	}
end

-- Hook into humanoid death automatically
function EnemyDeathHandler.SetupEnemy(enemyModel, parentFolder)
	if not enemyModel then return end

	local humanoid = enemyModel:FindFirstChild("Humanoid")
	if not humanoid then
		warn("[EnemyDeath] No humanoid found in", enemyModel.Name)
		return
	end

	-- Create death event
	local diedEvent = Instance.new("BindableEvent")
	diedEvent.Name = "Died"
	diedEvent.Parent = enemyModel

	-- Listen for death
	humanoid.Died:Connect(function()
		EnemyDeathHandler.OnEnemyDeath(enemyModel, nil, parentFolder)
	end)

	-- Also listen for health reaching zero (backup)
	humanoid.HealthChanged:Connect(function(newHealth)
		if newHealth <= 0 and not enemyModel:GetAttribute("IsDead") then
			EnemyDeathHandler.OnEnemyDeath(enemyModel, nil, parentFolder)
		end
	end)

	print(string.format("[EnemyDeath] Set up death handler for %s", enemyModel.Name))
end

function EnemyDeathHandler.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

return EnemyDeathHandler
