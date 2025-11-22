--[[
════════════════════════════════════════════════════════════════════════════════
Module: PlayerInventory
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Player inventory system with 4 weapon slots and 1 shield slot.
             Handles equipping, unequipping, and slot management.

Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local PlayerInventory = {}
PlayerInventory.__index = PlayerInventory

-- Private player inventory storage
local playerInventories = {}

-- ============================================================
-- CONFIGURATION
-- ============================================================

local Config = {
	-- INVENTORY (Equipped Loadout)
	MaxWeaponSlots = 4,
	MaxShieldSlots = 1,

	-- BACKPACK (Raw Storage)
	MaxBackpackWeapons = 30,
	MaxBackpackShields = 10,
}

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

function PlayerInventory.new(player)
	local self = setmetatable({}, PlayerInventory)

	self.Player = player

	-- BACKPACK (Raw Storage - NO gameplay effect until equipped)
	self.Backpack = {
		Weapons = {}, -- Array of ALL weapon data (up to MaxBackpackWeapons)
		Shields = {}, -- Array of ALL shield data (up to MaxBackpackShields)
	}

	-- INVENTORY (Equipped Loadout - Direct gameplay effect)
	self.Inventory = {
		Weapons = {
			[1] = nil, -- Weapon slot 1
			[2] = nil, -- Weapon slot 2
			[3] = nil, -- Weapon slot 3
			[4] = nil, -- Weapon slot 4
		},
		Shield = nil, -- Equipped shield
	}

	self.CurrentWeaponSlot = 1 -- Which inventory slot is equipped (1-4)
	self.EquippedWeaponTool = nil -- The actual Tool instance for equipped weapon

	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- BACKPACK (Raw Storage)
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Add weapon to backpack storage
	@param weaponData - Weapon data table
	@return success, backpackIndex
]]
function PlayerInventory:AddWeaponToBackpack(weaponData)
	if #self.Backpack.Weapons >= Config.MaxBackpackWeapons then
		warn("[PlayerInventory] Backpack full! Cannot store more weapons.")
		return false, nil
	end

	table.insert(self.Backpack.Weapons, weaponData)
	local index = #self.Backpack.Weapons
	print(string.format("[PlayerInventory] Added %s to backpack (%d/%d)", weaponData.Name, index, Config.MaxBackpackWeapons))
	return true, index
end

--[[
	Remove weapon from backpack
	@param backpackIndex - Index in backpack array
	@return weaponData
]]
function PlayerInventory:RemoveWeaponFromBackpack(backpackIndex)
	if backpackIndex < 1 or backpackIndex > #self.Backpack.Weapons then
		warn("[PlayerInventory] Invalid backpack index:", backpackIndex)
		return nil
	end

	local weaponData = table.remove(self.Backpack.Weapons, backpackIndex)
	print(string.format("[PlayerInventory] Removed %s from backpack", weaponData.Name))
	return weaponData
end

function PlayerInventory:GetBackpackWeapon(index)
	return self.Backpack.Weapons[index]
end

function PlayerInventory:GetAllBackpackWeapons()
	return self.Backpack.Weapons
end

function PlayerInventory:IsBackpackFull()
	return #self.Backpack.Weapons >= Config.MaxBackpackWeapons
end

function PlayerInventory:GetBackpackWeaponCount()
	return #self.Backpack.Weapons
end

-- ════════════════════════════════════════════════════════════════════════════
-- INVENTORY (Equipped Loadout)
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Equip weapon to inventory slot (from backpack or pickup)
	@param slotIndex - Inventory slot (1-4)
	@param weaponData - Weapon data to equip
	@return success
]]
function PlayerInventory:EquipWeaponToSlot(slotIndex, weaponData)
	if slotIndex < 1 or slotIndex > Config.MaxWeaponSlots then
		warn("[PlayerInventory] Invalid inventory slot:", slotIndex)
		return false
	end

	if self.Inventory.Weapons[slotIndex] then
		warn(string.format("[PlayerInventory] Slot %d already occupied. Unequip first.", slotIndex))
		return false
	end

	self.Inventory.Weapons[slotIndex] = weaponData
	print(string.format("[PlayerInventory] Equipped %s to slot %d", weaponData.Name, slotIndex))
	return true
end

--[[
	Unequip weapon from inventory slot (returns to backpack)
	@param slotIndex - Inventory slot (1-4)
	@return weaponData
]]
function PlayerInventory:UnequipWeaponFromSlot(slotIndex)
	if slotIndex < 1 or slotIndex > Config.MaxWeaponSlots then
		warn("[PlayerInventory] Invalid inventory slot:", slotIndex)
		return nil
	end

	local weaponData = self.Inventory.Weapons[slotIndex]
	if not weaponData then
		warn(string.format("[PlayerInventory] Slot %d is already empty", slotIndex))
		return nil
	end

	self.Inventory.Weapons[slotIndex] = nil

	-- Unequip tool if this was the current slot
	if slotIndex == self.CurrentWeaponSlot and self.EquippedWeaponTool then
		self.EquippedWeaponTool:Destroy()
		self.EquippedWeaponTool = nil
	end

	print(string.format("[PlayerInventory] Unequipped %s from slot %d", weaponData.Name, slotIndex))
	return weaponData
end

--[[
	Get weapon equipped in specific inventory slot
	@param slotIndex - Inventory slot (1-4)
	@return weaponData or nil
]]
function PlayerInventory:GetEquippedWeapon(slotIndex)
	return self.Inventory.Weapons[slotIndex]
end

--[[
	Get currently active weapon
	@return weaponData or nil
]]
function PlayerInventory:GetCurrentWeapon()
	return self.Inventory.Weapons[self.CurrentWeaponSlot]
end

--[[
	Get the Tool instance for equipped weapon
	@return Tool or nil
]]
function PlayerInventory:GetEquippedTool()
	return self.EquippedWeaponTool
end

--[[
	Switch to different inventory slot
	@param slotIndex - Slot to switch to (1-4)
	@return success
]]
function PlayerInventory:SwitchToSlot(slotIndex)
	if slotIndex < 1 or slotIndex > Config.MaxWeaponSlots then
		warn("[PlayerInventory] Invalid slot:", slotIndex)
		return false
	end

	if not self.Inventory.Weapons[slotIndex] then
		warn(string.format("[PlayerInventory] Slot %d is empty", slotIndex))
		return false
	end

	if slotIndex == self.CurrentWeaponSlot then
		print(string.format("[PlayerInventory] Already on slot %d", slotIndex))
		return true
	end

	self.CurrentWeaponSlot = slotIndex
	print(string.format("[PlayerInventory] Switched to slot %d", slotIndex))
	return true
end

--[[
	Get all equipped weapons (4 slots)
	@return table - Indexed table with slots 1-4
]]
function PlayerInventory:GetAllEquippedWeapons()
	return self.Inventory.Weapons
end

--[[
	Count how many inventory slots are filled
	@return number (0-4)
]]
function PlayerInventory:GetEquippedWeaponCount()
	local count = 0
	for i = 1, Config.MaxWeaponSlots do
		if self.Inventory.Weapons[i] then
			count = count + 1
		end
	end
	return count
end

--[[
	Check if all inventory slots are full
	@return boolean
]]
function PlayerInventory:IsInventoryFull()
	return self:GetEquippedWeaponCount() >= Config.MaxWeaponSlots
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD BACKPACK
-- ════════════════════════════════════════════════════════════════════════════

function PlayerInventory:AddShieldToBackpack(shieldData)
	if #self.Backpack.Shields >= Config.MaxBackpackShields then
		warn("[PlayerInventory] Shield backpack full!")
		return false, nil
	end

	table.insert(self.Backpack.Shields, shieldData)
	local index = #self.Backpack.Shields
	print(string.format("[PlayerInventory] Added %s to shield backpack (%d/%d)", shieldData.Name, index, Config.MaxBackpackShields))
	return true, index
end

function PlayerInventory:RemoveShieldFromBackpack(backpackIndex)
	if backpackIndex < 1 or backpackIndex > #self.Backpack.Shields then
		warn("[PlayerInventory] Invalid shield backpack index:", backpackIndex)
		return nil
	end

	local shieldData = table.remove(self.Backpack.Shields, backpackIndex)
	print(string.format("[PlayerInventory] Removed %s from shield backpack", shieldData.Name))
	return shieldData
end

function PlayerInventory:GetAllBackpackShields()
	return self.Backpack.Shields
end

function PlayerInventory:IsShieldBackpackFull()
	return #self.Backpack.Shields >= Config.MaxBackpackShields
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD INVENTORY
-- ════════════════════════════════════════════════════════════════════════════

function PlayerInventory:EquipShield(shieldData)
	if self.Inventory.Shield then
		warn("[PlayerInventory] Shield already equipped! Unequip first.")
		return false
	end

	self.Inventory.Shield = shieldData
	print(string.format("[PlayerInventory] Equipped shield: %s", shieldData.Name))

	return true
end

function PlayerInventory:UnequipShield()
	if not self.Inventory.Shield then
		warn("[PlayerInventory] No shield equipped")
		return nil
	end

	local shield = self.Inventory.Shield
	self.Inventory.Shield = nil
	print("[PlayerInventory] Unequipped shield")

	return shield
end

function PlayerInventory:GetShield()
	return self.Inventory.Shield
end

function PlayerInventory:HasShield()
	return self.Inventory.Shield ~= nil
end

-- ============================================================
-- SERIALIZATION (for saving/loading)
-- ============================================================

function PlayerInventory:Serialize()
	local data = {
		Weapons = {},
		Shield = self.Shield,
		CurrentWeaponIndex = self.CurrentWeaponIndex
	}

	-- Note: Actual weapon Tools can't be serialized directly
	-- You'd need to convert them to data tables first
	for i, weapon in ipairs(self.Weapons) do
		data.Weapons[i] = {
			Name = weapon.Name,
			-- Add other weapon attributes...
		}
	end

	return data
end

-- ============================================================
-- GLOBAL PLAYER INVENTORY ACCESS
-- ============================================================

function PlayerInventory.GetInventory(player)
	if not playerInventories[player.UserId] then
		playerInventories[player.UserId] = PlayerInventory.new(player)
	end

	return playerInventories[player.UserId]
end

function PlayerInventory.RemoveInventory(player)
	playerInventories[player.UserId] = nil
end

return PlayerInventory
