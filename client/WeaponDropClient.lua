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

-- Wait for drop event
local dropEvent = ReplicatedStorage:WaitForChild("DropWeapon", 10)

if not dropEvent then
	warn("[WeaponDropClient] DropWeapon RemoteEvent not found!")
	return
end

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

	print("[WeaponDropClient] Dropping weapon:", equippedTool.Name)

	-- Send drop request to server
	dropEvent:FireServer(equippedTool)
end

-- ════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ════════════════════════════════════════════════════════════════════════════

local function isAnyGUIOpen()
	-- Check if BackpackUI or SoulVendorGUI is open
	return (_G.BackpackUIOpen == true) or (_G.SoulVendorGUIOpen == true)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isAnyGUIOpen() then return end  -- Don't drop weapon if GUI is open

	-- Q key to drop weapon
	if input.KeyCode == Enum.KeyCode.Q then
		dropCurrentWeapon()
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)

print("[WeaponDropClient] Ready - Press Q to drop weapon")
