--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldDropClient
Location: StarterPlayer/StarterPlayerScripts/
Description: Client-side shield drop controls.
             Allows players to drop equipped shields with X key.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("[ShieldDropClient] Initializing...")

-- Wait for drop event
local dropEvent = ReplicatedStorage:WaitForChild("DropShield", 10)

if not dropEvent then
	warn("[ShieldDropClient] DropShield RemoteEvent not found!")
	return
end

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))

-- ════════════════════════════════════════════════════════════════════════════
-- DROP SHIELD FUNCTION
-- ════════════════════════════════════════════════════════════════════════════

local function dropCurrentShield()
	-- Check if player has a shield equipped
	local inventory = PlayerInventory.GetInventory(player)

	if not inventory:HasShield() then
		print("[ShieldDropClient] No shield equipped to drop")
		return
	end

	local shield = inventory:GetShield()
	print("[ShieldDropClient] Dropping shield:", shield.Name)

	-- Send drop request to server
	dropEvent:FireServer()
end

-- ════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ════════════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- X key to drop shield
	if input.KeyCode == Enum.KeyCode.X then
		dropCurrentShield()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)

print("[ShieldDropClient] Ready - Press X to drop shield")
