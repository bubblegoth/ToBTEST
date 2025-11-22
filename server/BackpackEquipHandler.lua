--[[
════════════════════════════════════════════════════════════════════════════════
Module: BackpackEquipHandler
Location: ServerScriptService/
Description: Handles equipping items from Backpack storage to Inventory slots.
             Listens for RemoteEvent from BackpackUI client.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[BackpackEquip] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))
local WeaponToolBuilder = require(Modules:WaitForChild("WeaponToolBuilder"))

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE REMOTE EVENT
-- ════════════════════════════════════════════════════════════════════════════

local equipEvent = Instance.new("RemoteEvent")
equipEvent.Name = "EquipFromBackpack"
equipEvent.Parent = ReplicatedStorage

-- ════════════════════════════════════════════════════════════════════════════
-- EQUIP WEAPON FROM BACKPACK
-- ════════════════════════════════════════════════════════════════════════════

local function equipWeaponFromBackpack(player, backpackIndex)
	local inventory = PlayerInventory.GetInventory(player)

	if not inventory then
		warn("[BackpackEquip] No inventory found for", player.Name)
		return false
	end

	-- Get weapon from backpack
	local weaponData = inventory.BackpackWeapons[backpackIndex]
	if not weaponData then
		warn("[BackpackEquip] No weapon at backpack index", backpackIndex)
		return false
	end

	-- Find empty inventory slot (or use slot 1 if full)
	local targetSlot = nil
	for i = 1, 4 do
		if not inventory.EquippedWeapons[i] then
			targetSlot = i
			break
		end
	end

	-- If no empty slot, swap with current equipped slot
	if not targetSlot then
		targetSlot = inventory.CurrentWeaponSlot
		print(string.format("[BackpackEquip] No empty slots - swapping with slot %d", targetSlot))

		-- Unequip current weapon to backpack
		local currentWeapon = inventory:UnequipWeaponFromSlot(targetSlot)
		if currentWeapon then
			inventory:AddWeaponToBackpack(currentWeapon)
			print(string.format("[BackpackEquip] Moved %s to backpack", currentWeapon.Name))
		end
	end

	-- Remove from backpack
	table.remove(inventory.BackpackWeapons, backpackIndex)

	-- Equip to inventory slot
	local success = inventory:EquipWeaponToSlot(targetSlot, weaponData)

	if success then
		print(string.format("[BackpackEquip] %s equipped %s to slot %d",
			player.Name, weaponData.Name, targetSlot))

		-- Give player the Tool
		WeaponToolBuilder:GiveWeaponToPlayer(player, weaponData, true)

		return true
	else
		warn("[BackpackEquip] Failed to equip weapon to slot", targetSlot)
		-- Put it back in backpack
		table.insert(inventory.BackpackWeapons, backpackIndex, weaponData)
		return false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- EQUIP SHIELD FROM BACKPACK
-- ════════════════════════════════════════════════════════════════════════════

local function equipShieldFromBackpack(player, backpackIndex)
	local inventory = PlayerInventory.GetInventory(player)

	if not inventory then
		warn("[BackpackEquip] No inventory found for", player.Name)
		return false
	end

	-- Get shield from backpack
	local shieldData = inventory.BackpackShields[backpackIndex]
	if not shieldData then
		warn("[BackpackEquip] No shield at backpack index", backpackIndex)
		return false
	end

	-- If player already has shield equipped, move it to backpack
	local currentShield = inventory:GetShield()
	if currentShield then
		inventory:AddShieldToBackpack(currentShield)
		print(string.format("[BackpackEquip] Moved %s to backpack", currentShield.Name))
	end

	-- Remove from backpack
	table.remove(inventory.BackpackShields, backpackIndex)

	-- Equip shield
	local success = inventory:EquipShield(shieldData)

	if success then
		print(string.format("[BackpackEquip] %s equipped shield: %s",
			player.Name, shieldData.Name))
		return true
	else
		warn("[BackpackEquip] Failed to equip shield")
		-- Put it back in backpack
		table.insert(inventory.BackpackShields, backpackIndex, shieldData)
		return false
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTE EVENT HANDLER
-- ════════════════════════════════════════════════════════════════════════════

equipEvent.OnServerEvent:Connect(function(player, itemType, backpackIndex)
	if not player or not itemType or not backpackIndex then
		warn("[BackpackEquip] Invalid equip request")
		return
	end

	if itemType == "weapon" then
		equipWeaponFromBackpack(player, backpackIndex)
	elseif itemType == "shield" then
		equipShieldFromBackpack(player, backpackIndex)
	else
		warn("[BackpackEquip] Unknown item type:", itemType)
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- UNEQUIP TO BACKPACK
-- ════════════════════════════════════════════════════════════════════════════

local unequipEvent = Instance.new("RemoteEvent")
unequipEvent.Name = "UnequipToBackpack"
unequipEvent.Parent = ReplicatedStorage

local function unequipWeaponToBackpack(player, inventorySlot)
	local inventory = PlayerInventory.GetInventory(player)

	if not inventory then
		warn("[BackpackEquip] No inventory found for", player.Name)
		return false
	end

	-- Get weapon from inventory slot
	local weaponData = inventory:GetEquippedWeapon(inventorySlot)
	if not weaponData then
		warn("[BackpackEquip] No weapon in slot", inventorySlot)
		return false
	end

	-- Check backpack space
	if #inventory.BackpackWeapons >= 30 then
		warn("[BackpackEquip] Backpack full! Cannot unequip weapon")
		return false
	end

	-- Unequip from inventory
	local unequippedData = inventory:UnequipWeaponFromSlot(inventorySlot)

	if unequippedData then
		-- Add to backpack
		inventory:AddWeaponToBackpack(unequippedData)

		-- Destroy the Tool from player
		local backpack = player:FindFirstChild("Backpack")
		local character = player.Character

		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("UniqueID") == weaponData.UniqueID then
					tool:Destroy()
					break
				end
			end
		end

		if character then
			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") and tool:GetAttribute("UniqueID") == weaponData.UniqueID then
					tool:Destroy()
					break
				end
			end
		end

		print(string.format("[BackpackEquip] %s stashed %s to backpack",
			player.Name, unequippedData.Name))
		return true
	else
		warn("[BackpackEquip] Failed to unequip weapon from slot", inventorySlot)
		return false
	end
end

local function unequipShieldToBackpack(player)
	local inventory = PlayerInventory.GetInventory(player)

	if not inventory then
		warn("[BackpackEquip] No inventory found for", player.Name)
		return false
	end

	-- Get shield
	local shieldData = inventory:GetShield()
	if not shieldData then
		warn("[BackpackEquip] No shield equipped")
		return false
	end

	-- Check backpack space
	if #inventory.BackpackShields >= 10 then
		warn("[BackpackEquip] Backpack full! Cannot unequip shield")
		return false
	end

	-- Unequip shield
	inventory:UnequipShield()

	-- Add to backpack
	inventory:AddShieldToBackpack(shieldData)

	print(string.format("[BackpackEquip] %s stashed shield %s to backpack",
		player.Name, shieldData.Name))
	return true
end

unequipEvent.OnServerEvent:Connect(function(player, itemType, inventorySlot)
	if not player or not itemType then
		warn("[BackpackEquip] Invalid unequip request")
		return
	end

	if itemType == "weapon" then
		unequipWeaponToBackpack(player, inventorySlot)
	elseif itemType == "shield" then
		unequipShieldToBackpack(player)
	else
		warn("[BackpackEquip] Unknown item type:", itemType)
	end
end)

print("[BackpackEquip] ═══════════════════════════════════════")
print("[BackpackEquip] Backpack Equip System Active")
print("[BackpackEquip] Players can equip/unequip items")
print("[BackpackEquip] ═══════════════════════════════════════")
