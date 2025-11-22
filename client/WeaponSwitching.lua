--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponSwitching
Location: StarterPlayer/StarterPlayerScripts/
Description: Client-side weapon switching with keys 1-4.
             Handles Tool creation/destruction for equipped weapons.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("[WeaponSwitching] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))
local WeaponToolBuilder = require(Modules:WaitForChild("WeaponToolBuilder"))

-- ════════════════════════════════════════════════════════════════════════════
-- WEAPON SWITCHING
-- ════════════════════════════════════════════════════════════════════════════

local function switchToWeapon(slotIndex)
	local inventory = PlayerInventory.GetInventory(player)

	-- Check if slot has a weapon equipped
	local weaponData = inventory:GetEquippedWeapon(slotIndex)
	if not weaponData then
		print(string.format("[WeaponSwitching] Slot %d is empty", slotIndex))
		return
	end

	-- Check if already on this slot
	if inventory.CurrentWeaponSlot == slotIndex then
		print(string.format("[WeaponSwitching] Weapon slot %d already active", slotIndex))
		return
	end

	-- Switch to new weapon slot
	inventory:SwitchToSlot(slotIndex)

	-- Destroy old equipped tool
	if inventory.EquippedWeaponTool then
		inventory.EquippedWeaponTool:Destroy()
		inventory.EquippedWeaponTool = nil
	end

	-- Create new weapon tool
	local weaponTool = WeaponToolBuilder:BuildWeaponTool(weaponData)
	if not weaponTool then
		warn(string.format("[WeaponSwitching] Failed to build weapon tool for slot %d", slotIndex))
		return
	end

	-- Store and equip
	inventory.EquippedWeaponTool = weaponTool
	weaponTool.Parent = character

	print(string.format("[WeaponSwitching] Switched to weapon slot %d: %s", slotIndex, weaponData.Name))
end

-- ════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ════════════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Keys 1-4 to switch weapons
	if input.KeyCode == Enum.KeyCode.One then
		switchToWeapon(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		switchToWeapon(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		switchToWeapon(3)
	elseif input.KeyCode == Enum.KeyCode.Four then
		switchToWeapon(4)
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
end)

print("[WeaponSwitching] Ready - Press 1-4 to switch weapons")
