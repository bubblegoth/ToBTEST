--[[
════════════════════════════════════════════════════════════════════════════════
Module: PileOfBones
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Church teleporter system (Bones_Assortment interaction).
             Teleports player from Floor 0 to Floor 1 dungeon start.
             Triggers starting weapon spawn via StartingWeapon module.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (adjust paths as needed)
local PlayerStats = require(ReplicatedStorage.Modules.PlayerStats)
local WeaponGenerator = require(ReplicatedStorage.Modules.WeaponGenerator)
local DungeonGenerator = require(ReplicatedStorage.Modules.DungeonGenerator)
local DungeonInstanceManager = require(ReplicatedStorage.Modules.DungeonInstanceManager)
local StartingWeapon = require(ReplicatedStorage.Modules.StartingWeapon)

-- Cooldown to prevent spam
local cooldowns = {}
local COOLDOWN_TIME = 2 -- seconds

-- Module export
local PileOfBones = {}

-- ============================================================
-- TELEPORT FUNCTION
-- ============================================================

local function teleportToDungeon(player)
	-- Cooldown check
	if cooldowns[player.UserId] and tick() - cooldowns[player.UserId] < COOLDOWN_TIME then
		return
	end
	cooldowns[player.UserId] = tick()

	-- Get player stats using global function (set by PlayerDataManager)
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)

	if not playerStats then
		warn("[Bones_Assortment] PlayerStats not found for", player.Name, "- Is PlayerDataManager running?")
		return
	end

	-- Check if player is currently on Floor 0 (Church)
	local currentFloor = playerStats:GetCurrentFloor()

	if currentFloor ~= 0 then
		-- Player is already in dungeon, teleport to next floor
		local nextFloor = currentFloor + 1

		if nextFloor > 666 then
			-- Completed all floors
			print(string.format("[Bones_Assortment] %s has completed all 666 floors!", player.Name))
			return
		end

		-- Advance to next floor
		playerStats:AdvanceFloor()

		-- Update player values (syncs with Value objects)
		if _G.UpdatePlayerValues then
			_G.UpdatePlayerValues(player)
		end

		-- Teleport to next floor in player's dungeon instance
		local success = DungeonInstanceManager.TeleportToFloor(player, nextFloor)

		if success then
			print(string.format("[Bones_Assortment] %s descended to Floor %d", player.Name, nextFloor))
		else
			warn("[Bones_Assortment] Failed to teleport", player.Name, "to Floor", nextFloor)
		end

		-- TODO: Build Floor geometry from floor data
		-- You'll need a DungeonBuilder module to convert floor data into 3D maze
	else
		-- Player is in Church (Floor 0), entering dungeon for first time
		playerStats:AdvanceFloor() -- Advances from 0 to 1

		-- Update player values (syncs with Value objects)
		if _G.UpdatePlayerValues then
			_G.UpdatePlayerValues(player)
		end

		-- Give starting weapon using StartingWeapon module
		local receivedWeapon, weapon = StartingWeapon.OnFloorEntry(player, playerStats, 1)

		if receivedWeapon then
			print(string.format("[Bones_Assortment] %s received starting weapon: %s", player.Name, weapon.Name or "Unknown"))

			-- Try to show welcome message, but don't let it stop teleportation
			local success, welcomeMsg = pcall(function()
				return StartingWeapon.GetWelcomeMessage(weapon)
			end)

			if success then
				print(welcomeMsg)
			else
				warn("[Bones_Assortment] Could not generate welcome message:", welcomeMsg)
				print("=== ENTERING THE DUNGEON ===\nYou have been given a starting weapon. Good luck, wanderer...")
			end

			-- TODO: Convert weapon data into actual tool/gun and give to player
			-- You'll need to create a WeaponBuilder module to turn weapon data into 3D tool
		else
			print(string.format("[Bones_Assortment] %s already has weapons, no starting weapon given", player.Name))
		end

		-- Teleport to Floor 1 in player's dungeon instance
		local success = DungeonInstanceManager.TeleportToFloor(player, 1)

		if success then
			print(string.format("[Bones_Assortment] %s entered Floor 1 - The Dungeon Begins", player.Name))
		else
			warn("[Bones_Assortment] Failed to teleport", player.Name, "to Floor 1")
		end

		-- TODO: Build Floor 1 geometry from floor data
		-- You'll need a DungeonBuilder module to convert floor data into 3D maze
	end
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

--[[
	Initializes the Bones_Assortment teleporter
	@param bonesAssortment Instance - The part/model in workspace to use as teleporter
]]
function PileOfBones.Initialize(bonesAssortment)
	if not bonesAssortment then
		warn("[PileOfBones] No Bones_Assortment part provided!")
		return false
	end

	-- Option 1: Touch-based (walk over to trigger)
	if bonesAssortment:IsA("BasePart") then
		bonesAssortment.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then return end

			local player = Players:GetPlayerFromCharacter(character)
			if player then
				teleportToDungeon(player)
			end
		end)
	end

	-- Option 2: ClickDetector (click to trigger)
	local clickDetector = bonesAssortment:FindFirstChildOfClass("ClickDetector")
	if not clickDetector then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.Parent = bonesAssortment
		clickDetector.MaxActivationDistance = 10 -- 10 studs
	end

	clickDetector.MouseClick:Connect(function(player)
		teleportToDungeon(player)
	end)

	-- Option 3: ProximityPrompt (hold to trigger)
	if not bonesAssortment:FindFirstChild("ProximityPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Touch the Bones"
		prompt.ObjectText = "Descend into the Dungeon"
		prompt.HoldDuration = 1 -- Hold for 1 second
		prompt.Parent = bonesAssortment

		prompt.Triggered:Connect(function(player)
			teleportToDungeon(player)
		end)
	end

	print("[Bones_Assortment] Teleporter initialized")
	return true
end

-- ============================================================
-- MODULE RETURN
-- ============================================================

return PileOfBones
