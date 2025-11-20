--[[
	NPCGeneratorDemo.lua
	Example demonstrating NPC generation system
	Shows how to generate Soul Vendor and enemies
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NPCGenerator = require(ReplicatedStorage.src.NPCGenerator)

print("\n" .. string.rep("=", 60))
print("NPC GENERATOR DEMONSTRATION")
print(string.rep("=", 60) .. "\n")

-- ============================================================
-- EXAMPLE 1: Generate Soul Vendor
-- ============================================================

print("=== EXAMPLE 1: Soul Vendor ===\n")

local soulVendor = NPCGenerator.GenerateNPC("SOUL_VENDOR")

print(NPCGenerator.GetNPCDescription(soulVendor))

-- Build actual model (spawns in workspace)
--[[
local vendorModel = NPCGenerator.BuildNPCModel(soulVendor, workspace)
vendorModel:SetPrimaryPartCFrame(CFrame.new(0, 5, 0)) -- Position at origin
print("Soul Vendor spawned in workspace!")
]]

-- ============================================================
-- EXAMPLE 2: Generate Enemies
-- ============================================================

print("\n\n=== EXAMPLE 2: Enemy Generation ===\n")

local enemyTypes = {"Cultist", "Wraith", "Knight", "Demon"}

for _, enemyType in ipairs(enemyTypes) do
	local enemy = NPCGenerator.GenerateEnemy(enemyType, 10)
	print(NPCGenerator.GetNPCDescription(enemy))
	print("\n")
end

-- ============================================================
-- EXAMPLE 3: Enemy Wave (Different Levels)
-- ============================================================

print("\n" .. string.rep("=", 60))
print("=== EXAMPLE 3: Enemy Wave (Levels 1-5) ===")
print(string.rep("=", 60) .. "\n")

for level = 1, 5 do
	local cultist = NPCGenerator.GenerateEnemy("Cultist", level)

	print(string.format(
		"Level %d Cultist - HP: %d, Damage: %d",
		level,
		cultist.Stats.MaxHealth,
		cultist.Stats.Damage
	))
end

-- ============================================================
-- EXAMPLE 4: Spawn Multiple NPCs
-- ============================================================

print("\n\n=== EXAMPLE 4: Spawning Wave in Workspace ===\n")

--[[
-- Spawn 5 enemies in a line
for i = 1, 5 do
	local enemy = NPCGenerator.GenerateEnemy("Cultist", 5)
	local model = NPCGenerator.BuildNPCModel(enemy, workspace)
	model:SetPrimaryPartCFrame(CFrame.new(i * 5, 5, 0)) -- Space them 5 studs apart
	print(string.format("Spawned %s at position %d", enemy.Name, i))
end
]]

print("Uncomment the code above to spawn enemies in workspace!")

-- ============================================================
-- EXAMPLE 5: Generate Boss (High Level)
-- ============================================================

print("\n\n=== EXAMPLE 5: Boss Enemy (Level 50) ===\n")

local boss = NPCGenerator.GenerateEnemy("Knight", 50)

print(NPCGenerator.GetNPCDescription(boss))
print(string.format(
	"\n*** BOSS STATS ***\n" ..
	"HP: %d\n" ..
	"Damage: %d\n" ..
	"This is a formidable foe!",
	boss.Stats.MaxHealth,
	boss.Stats.Damage
))

-- ============================================================
-- EXAMPLE 6: Randomized Generation
-- ============================================================

print("\n\n=== EXAMPLE 6: Random Enemy Generation ===\n")

for i = 1, 3 do
	local randomType = enemyTypes[math.random(1, #enemyTypes)]
	local randomLevel = math.random(1, 20)

	local enemy = NPCGenerator.GenerateEnemy(randomType, randomLevel)

	print(string.format(
		"%d. [Lv.%d] %s - %s/%s %s",
		i,
		randomLevel,
		enemy.Name,
		enemy.Parts.Head.Name,
		enemy.Parts.Torso.Name,
		enemy.Parts.Accessory and ("with " .. enemy.Parts.Accessory.Name) or ""
	))
end

-- ============================================================
-- EXAMPLE 7: Usage in Actual Game
-- ============================================================

print("\n\n=== EXAMPLE 7: Game Integration ===\n")

print([[
-- In your game code:

-- 1. Spawn Soul Vendor in Church
local vendor = NPCGenerator.GenerateNPC("SOUL_VENDOR")
local vendorModel = NPCGenerator.BuildNPCModel(vendor, workspace.Church)
vendorModel:SetPrimaryPartCFrame(workspace.Church.VendorSpawn.CFrame)

-- Attach SoulVendor.lua script to the model
local vendorScript = ReplicatedStorage.src.SoulVendor:Clone()
vendorScript.Parent = vendorModel

-- 2. Spawn enemies in dungeon floor
local floor = DungeonGenerator.GenerateFloor(5)
for _, room in ipairs(floor.Rooms) do
    local enemies = EnemySystem.SpawnEnemiesForRoom(room, floor.FloorNumber)

    for _, enemyData in ipairs(enemies) do
        -- Generate NPC model for enemy
        local npc = NPCGenerator.GenerateEnemy(enemyData.Type, enemyData.Level)
        local model = NPCGenerator.BuildNPCModel(npc, workspace.Dungeon)

        -- Position in room
        model:SetPrimaryPartCFrame(room.SpawnPoint.CFrame)

        -- Add AI script
        local aiScript = ReplicatedStorage.EnemyAI:Clone()
        aiScript.Parent = model
    end
end
]])

print("\n" .. string.rep("=", 60))
print("NPC GENERATOR DEMO COMPLETE")
print(string.rep("=", 60))
