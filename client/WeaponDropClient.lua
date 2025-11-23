--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponDropClient
Location: StarterPlayer/StarterPlayerScripts/
Description: Client-side weapon drop controls.
             Allows players to drop equipped weapons with Q key.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("[WeaponDropClient] Initializing...")

-- Wait for drop event (no timeout - wait indefinitely)
local dropEvent = ReplicatedStorage:WaitForChild("DropWeapon")
print("[WeaponDropClient] Found DropWeapon RemoteEvent")

-- ════════════════════════════════════════════════════════════════════════════
-- DROP WEAPON FUNCTION
-- ════════════════════════════════════════════════════════════════════════════

local function dropCurrentWeapon()
	local character = player.Character
	if not character then return end

	-- Find currently equipped tool
	local equippedTool = character:FindFirstChildOfClass("Tool")

	if not equippedTool then
		print("[WeaponDropClient] No weapon equipped to drop")
		return
	end

	-- Check if it's a weapon (has UniqueID attribute)
	if not equippedTool:GetAttribute("UniqueID") then
		print("[WeaponDropClient] Equipped tool is not a weapon")
		return
	end

	-- CRITICAL: Get current ammo from ProjectileShooter and send it to server
	-- This avoids attribute replication lag issues
	local currentAmmo = nil
	if _G.ProjectileShooter_GetCurrentAmmo then
		currentAmmo = _G.ProjectileShooter_GetCurrentAmmo()
		print("[WeaponDropClient] Got current ammo:", currentAmmo)
	end

	print("[WeaponDropClient] Dropping weapon:", equippedTool.Name)

	-- Send drop request to server with current ammo
	dropEvent:FireServer(equippedTool, currentAmmo)
end

-- ════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ════════════════════════════════════════════════════════════════════════════

local function isAnyGUIOpen()
	-- Check if BackpackUI or SoulVendorGUI is open
	return (_G.BackpackUIOpen == true) or (_G.SoulVendorGUIOpen == true)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- DEBUG: Log Q key presses to diagnose issues
	if input.KeyCode == Enum.KeyCode.Q then
		print("[WeaponDropClient] Q pressed - gameProcessed:", gameProcessed, "GUI open:", isAnyGUIOpen())
	end

	if gameProcessed then return end
	if isAnyGUIOpen() then return end  -- Don't drop weapon if GUI is open

	-- Q key to drop weapon
	if input.KeyCode == Enum.KeyCode.Q then
		print("[WeaponDropClient] Attempting to drop weapon...")
		dropCurrentWeapon()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)

print("[WeaponDropClient] Ready - Press Q to drop weapon")
