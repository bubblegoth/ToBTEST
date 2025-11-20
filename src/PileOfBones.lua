--[[
	PileOfBones.lua
	Teleporter script for the Pile of Bones in the Church (Floor 0)
	Teleports player to dungeon (Floor 1+) and gives starting weapon
	Part of the Gothic FPS Roguelite Dungeon System

	SETUP INSTRUCTIONS:
	1. Place this script inside the PileOfBones model in workspace
	2. Set pileOfBones variable to reference the clickable part
	3. Set dungeonSpawnLocation to the spawn point under the map (Floor 1 start)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (adjust paths as needed)
local PlayerStats = require(ReplicatedStorage.src.PlayerStats)
local WeaponGenerator = require(ReplicatedStorage.src.WeaponGenerator)
local DungeonGenerator = require(ReplicatedStorage.src.DungeonGenerator)
local StartingWeapon = require(ReplicatedStorage.src.StartingWeapon)

-- Configuration
local pileOfBones = script.Parent -- The part/model the player clicks
local dungeonSpawnLocation = workspace.DungeonSpawn -- Set this to your Floor 1 spawn point

-- Cooldown to prevent spam
local cooldowns = {}
local COOLDOWN_TIME = 2 -- seconds

-- ============================================================
-- TELEPORT FUNCTION
-- ============================================================

local function teleportToDungeon(player)
	-- Cooldown check
	if cooldowns[player.UserId] and tick() - cooldowns[player.UserId] < COOLDOWN_TIME then
		return
	end
	cooldowns[player.UserId] = tick()

	-- Get player character
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Get or initialize player stats (server-side)
	local playerStats = player:FindFirstChild("PlayerStats") -- Assuming you store this in player object

	if not playerStats then
		warn("PlayerStats not found for", player.Name)
		return
	end

	-- Check if player is currently on Floor 0 (Church)
	local currentFloor = playerStats.CurrentFloor.Value

	if currentFloor ~= 0 then
		-- Player is already in dungeon, teleport to next floor
		local nextFloor = currentFloor + 1

		if nextFloor > 666 then
			-- Completed all floors
			print(player.Name, "has completed all 666 floors!")
			return
		end

		-- Advance to next floor
		playerStats.CurrentFloor.Value = nextFloor

		-- Generate next floor (you'll need to build the 3D geometry here)
		local floor = DungeonGenerator.GenerateFloor(nextFloor)

		-- Teleport to next floor spawn (implement your spawn logic)
		humanoidRootPart.CFrame = dungeonSpawnLocation.CFrame + Vector3.new(0, nextFloor * 100, 0) -- Example: stack floors vertically

		print(player.Name, "descended to Floor", nextFloor)
	else
		-- Player is in Church (Floor 0), entering dungeon for first time
		playerStats.CurrentFloor.Value = 1

		-- Give starting weapon using StartingWeapon module
		local receivedWeapon, weapon = StartingWeapon.OnFloorEntry(playerStats, 1)

		if receivedWeapon then
			print(player.Name, "received starting weapon:", weapon.Name)
			print(StartingWeapon.GetWelcomeMessage(weapon))

			-- TODO: Convert weapon data into actual tool/gun and give to player
			-- You'll need to create a WeaponBuilder module to turn weapon data into 3D tool
		else
			print(player.Name, "already has weapons, no starting weapon given")
		end

		-- Teleport to Floor 1 spawn
		humanoidRootPart.CFrame = dungeonSpawnLocation.CFrame

		-- Generate Floor 1
		local floor1 = DungeonGenerator.GenerateFloor(1)
		print(player.Name, "entered Floor 1 - The Dungeon Begins")

		-- TODO: Build Floor 1 geometry from floor data
		-- You'll need a DungeonBuilder module to convert floor data into 3D maze
	end
end

-- ============================================================
-- TOUCH/CLICK DETECTION
-- ============================================================

-- Option 1: Touch-based (walk over to trigger)
if pileOfBones:IsA("BasePart") then
	pileOfBones.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if player then
			teleportToDungeon(player)
		end
	end)
end

-- Option 2: ClickDetector (click to trigger)
local clickDetector = pileOfBones:FindFirstChildOfClass("ClickDetector")
if not clickDetector then
	clickDetector = Instance.new("ClickDetector")
	clickDetector.Parent = pileOfBones
	clickDetector.MaxActivationDistance = 10 -- 10 studs
end

clickDetector.MouseClick:Connect(function(player)
	teleportToDungeon(player)
end)

print("PileOfBones teleporter initialized")

-- ============================================================
-- VISUAL FEEDBACK (Optional)
-- ============================================================

-- Add a hover prompt
if not pileOfBones:FindFirstChild("ProximityPrompt") then
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Touch the Bones"
	prompt.ObjectText = "Descend into the Dungeon"
	prompt.HoldDuration = 1 -- Hold for 1 second
	prompt.Parent = pileOfBones

	prompt.Triggered:Connect(function(player)
		teleportToDungeon(player)
	end)
end
