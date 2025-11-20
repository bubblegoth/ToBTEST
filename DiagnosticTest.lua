--[[
════════════════════════════════════════════════════════════════════════════════
DIAGNOSTIC TEST SCRIPT
════════════════════════════════════════════════════════════════════════════════

INSTRUCTIONS:
1. Copy this entire script
2. In Roblox Studio, create a new Script in ServerScriptService
3. Name it "DiagnosticTest"
4. Paste this code
5. Click Play
6. Check the Output window
7. Share the output to help diagnose the issue

This script tests ALL systems and reports what's working and what's broken.
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

print("\n" .. string.rep("=", 80))
print("GOTHIC FPS ROGUELITE - DIAGNOSTIC TEST")
print(string.rep("=", 80))
print("Testing all systems...\n")

local passCount = 0
local failCount = 0

local function TEST(name, condition, errorMsg)
	if condition then
		print("✓ PASS:", name)
		passCount = passCount + 1
		return true
	else
		warn("✗ FAIL:", name, "→", errorMsg or "Check failed")
		failCount = failCount + 1
		return false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 1: FOLDER STRUCTURE
-- ════════════════════════════════════════════════════════════════════════════

print("\n[1] TESTING FOLDER STRUCTURE")
print(string.rep("-", 80))

TEST(
	"ReplicatedStorage.Modules exists",
	ReplicatedStorage:FindFirstChild("Modules") ~= nil,
	"Modules folder not found in ReplicatedStorage"
)

TEST(
	"Workspace objects exist",
	workspace:FindFirstChild("ChurchSpawn") ~= nil or workspace:FindFirstChild("SpawnLocation") ~= nil,
	"ChurchSpawn or SpawnLocation not found in Workspace"
)

TEST(
	"Bones_Assortment exists",
	workspace:FindFirstChild("Bones_Assortment") ~= nil,
	"Bones_Assortment not found in Workspace (dungeon teleporter)"
)

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 2: SERVER SCRIPTS
-- ════════════════════════════════════════════════════════════════════════════

print("\n[2] TESTING SERVER SCRIPTS")
print(string.rep("-", 80))

TEST(
	"ServerInit exists",
	ServerScriptService:FindFirstChild("ServerInit") ~= nil,
	"ServerInit not found - should be a Script in ServerScriptService"
)

TEST(
	"PlayerDataManager exists",
	ServerScriptService:FindFirstChild("PlayerDataManager") ~= nil,
	"PlayerDataManager not found - should be a Script in ServerScriptService"
)

TEST(
	"ServerDamageHandler exists",
	ServerScriptService:FindFirstChild("ServerDamageHandler") ~= nil,
	"ServerDamageHandler not found - should be a Script in ServerScriptService"
)

TEST(
	"PlayerHealthHandler exists",
	ServerScriptService:FindFirstChild("PlayerHealthHandler") ~= nil,
	"PlayerHealthHandler not found - NEW script needed in ServerScriptService"
)

TEST(
	"EnemyAIManager exists",
	ServerScriptService:FindFirstChild("EnemyAIManager") ~= nil,
	"EnemyAIManager not found - NEW script needed in ServerScriptService"
)

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 3: MODULE SCRIPTS
-- ════════════════════════════════════════════════════════════════════════════

print("\n[3] TESTING CORE MODULES")
print(string.rep("-", 80))

local modules = ReplicatedStorage:FindFirstChild("Modules")
if modules then
	local requiredModules = {
		"WeaponGenerator",
		"WeaponModelBuilder",
		"DungeonInstanceManager",
		"MazeDungeonGenerator",
		"MobGenerator",
		"EnemySpawner",
		"ShieldGenerator",
		"ShieldParts",
		"PlayerStats",
		"NPCGenerator"
	}

	for _, moduleName in ipairs(requiredModules) do
		TEST(
			"Module: " .. moduleName,
			modules:FindFirstChild(moduleName) ~= nil,
			moduleName .. ".lua not found in Modules folder"
		)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 4: MODULE LOADING TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[4] TESTING MODULE LOADING")
print(string.rep("-", 80))

local function tryRequire(moduleName)
	local success, result = pcall(function()
		return require(ReplicatedStorage.Modules[moduleName])
	end)

	TEST(
		"Load: " .. moduleName,
		success,
		success and "Loaded successfully" or ("Error: " .. tostring(result))
	)

	return success, result
end

if modules then
	tryRequire("DungeonConfig")
	tryRequire("WeaponGenerator")
	tryRequire("ShieldGenerator")
	tryRequire("PlayerStats")
	tryRequire("MazeDungeonGenerator")
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 5: DUNGEON SYSTEM TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[5] TESTING DUNGEON SYSTEM")
print(string.rep("-", 80))

local dungeonSuccess, DungeonInstanceManager = tryRequire("DungeonInstanceManager")

if dungeonSuccess then
	TEST(
		"DungeonInstances folder created",
		workspace:FindFirstChild("DungeonInstances") ~= nil,
		"DungeonInstances folder should be auto-created in workspace"
	)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 6: WEAPON SYSTEM TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[6] TESTING WEAPON SYSTEM")
print(string.rep("-", 80))

local weaponSuccess, WeaponGenerator = tryRequire("WeaponGenerator")

if weaponSuccess then
	local testSuccess, testWeapon = pcall(function()
		return WeaponGenerator.GenerateWeapon("Pistol", 1, "Common")
	end)

	TEST(
		"Generate weapon",
		testSuccess and testWeapon ~= nil,
		testSuccess and "Weapon generated" or ("Error: " .. tostring(testWeapon))
	)

	if testSuccess and testWeapon then
		print("   Generated:", testWeapon.Name)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 7: SHIELD SYSTEM TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[7] TESTING SHIELD SYSTEM")
print(string.rep("-", 80))

local shieldSuccess, ShieldGenerator = tryRequire("ShieldGenerator")

if shieldSuccess then
	local testSuccess, testShield = pcall(function()
		return ShieldGenerator.Generate(1)
	end)

	TEST(
		"Generate shield",
		testSuccess and testShield ~= nil,
		testSuccess and "Shield generated" or ("Error: " .. tostring(testShield))
	)

	if testSuccess and testShield then
		print("   Generated:", testShield.Name)
		print("   Capacity:", testShield.Stats.Capacity)
		print("   Recharge Rate:", testShield.Stats.RechargeRate)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 8: ENEMY SYSTEM TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[8] TESTING ENEMY SYSTEM")
print(string.rep("-", 80))

local mobSuccess, MobGenerator = tryRequire("MobGenerator")

if mobSuccess then
	local testSuccess, testEnemy = pcall(function()
		local container = Instance.new("Folder")
		return MobGenerator.Generate({
			level = 1,
			parent = container
		})
	end)

	TEST(
		"Generate enemy",
		testSuccess,
		testSuccess and "Enemy generated" or ("Error: " .. tostring(testEnemy))
	)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 9: PLAYER STATS TEST
-- ════════════════════════════════════════════════════════════════════════════

print("\n[9] TESTING PLAYER STATS")
print(string.rep("-", 80))

local statsSuccess, PlayerStats = tryRequire("PlayerStats")

if statsSuccess then
	local testSuccess, testStats = pcall(function()
		return PlayerStats.new()
	end)

	TEST(
		"Create PlayerStats",
		testSuccess and testStats ~= nil,
		testSuccess and "PlayerStats created" or ("Error: " .. tostring(testStats))
	)

	if testSuccess and testStats then
		print("   Starting Souls:", testStats.Souls)
		print("   Starting Floor:", testStats.CurrentFloor)
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- FINAL SUMMARY
-- ════════════════════════════════════════════════════════════════════════════

print("\n" .. string.rep("=", 80))
print("DIAGNOSTIC COMPLETE")
print(string.rep("=", 80))
print(string.format("✓ Passed: %d tests", passCount))
print(string.format("✗ Failed: %d tests", failCount))

if failCount == 0 then
	print("\n🎉 ALL SYSTEMS OPERATIONAL!")
	print("Your game should work correctly.")
else
	print("\n⚠️  ISSUES DETECTED!")
	print("Fix the failed tests above to get your game working.")
	print("\nCommon fixes:")
	print("1. Move server scripts from Modules/ to ServerScriptService/")
	print("2. Make sure all scripts are the correct type (Script vs ModuleScript)")
	print("3. Check that workspace objects exist (ChurchSpawn, Bones_Assortment)")
	print("4. Add new server scripts: PlayerHealthHandler, EnemyAIManager")
end

print(string.rep("=", 80) .. "\n")
