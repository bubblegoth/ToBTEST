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
	MaxWeaponSlots = 4,
	MaxShieldSlots = 1,
}

-- ============================================================
-- CONSTRUCTOR
-- ============================================================

function PlayerInventory.new(player)
	local self = setmetatable({}, PlayerInventory)

	self.Player = player
	self.Weapons = {} -- Array of weapon DATA (max 4) - NOT Tools, just data tables
	self.Shield = nil -- Single shield data (nil = no shield equipped)
	self.CurrentWeaponIndex = 1 -- Which weapon slot is currently equipped (1-4)
	self.EquippedWeaponTool = nil -- The actual Tool instance for currently equipped weapon

	return self
end

-- ============================================================
-- WEAPON MANAGEMENT (Stores weapon DATA, not Tools)
-- ============================================================

--[[
	Add weapon data to inventory
	@param weaponData - Complete weapon data table (NOT a Tool)
	@param slotIndex - Optional specific slot to add to (1-4)
	@return success, slotIndex
]]
function PlayerInventory:AddWeapon(weaponData, slotIndex)
	-- Check if inventory is full
	if #self.Weapons >= Config.MaxWeaponSlots and not slotIndex then
		warn("[PlayerInventory] Weapon slots full! Cannot add weapon.")
		return false, nil
	end

	-- Add to specific slot or first empty slot
	if slotIndex then
		if slotIndex < 1 or slotIndex > Config.MaxWeaponSlots then
			warn("[PlayerInventory] Invalid slot index:", slotIndex)
			return false, nil
		end
		self.Weapons[slotIndex] = weaponData
		print(string.format("[PlayerInventory] Added weapon to slot %d: %s", slotIndex, weaponData.Name))
		return true, slotIndex
	else
		table.insert(self.Weapons, weaponData)
		local addedSlot = #self.Weapons
		print(string.format("[PlayerInventory] Added weapon to slot %d: %s", addedSlot, weaponData.Name))
		return true, addedSlot
	end
end

--[[
	Remove weapon data from inventory slot
	@param slotIndex - Slot to remove from (1-4)
	@return weaponData - The removed weapon data
]]
function PlayerInventory:RemoveWeapon(slotIndex)
	if slotIndex < 1 or slotIndex > #self.Weapons then
		warn("[PlayerInventory] Invalid weapon slot:", slotIndex)
		return nil
	end

	local weapon = table.remove(self.Weapons, slotIndex)

	-- Adjust current weapon index if needed
	if self.CurrentWeaponIndex > #self.Weapons and #self.Weapons > 0 then
		self.CurrentWeaponIndex = #self.Weapons
	elseif #self.Weapons == 0 then
		self.CurrentWeaponIndex = 1
	end

	-- Unequip tool if this was the equipped weapon
	if slotIndex == self.CurrentWeaponIndex and self.EquippedWeaponTool then
		self.EquippedWeaponTool:Destroy()
		self.EquippedWeaponTool = nil
	end

	print(string.format("[PlayerInventory] Removed weapon from slot %d", slotIndex))
	return weapon
end

--[[
	Get weapon data from specific slot
	@param slotIndex - Slot to get (1-4)
	@return weaponData
]]
function PlayerInventory:GetWeapon(slotIndex)
	return self.Weapons[slotIndex]
end

--[[
	Get currently equipped weapon data
	@return weaponData
]]
function PlayerInventory:GetCurrentWeapon()
	return self.Weapons[self.CurrentWeaponIndex]
end

--[[
	Get currently equipped weapon Tool instance
	@return Tool
]]
function PlayerInventory:GetEquippedTool()
	return self.EquippedWeaponTool
end

--[[
	Switch to different weapon slot
	@param slotIndex - Slot to switch to (1-4)
	@return success
]]
function PlayerInventory:SwitchWeapon(slotIndex)
	if slotIndex < 1 or slotIndex > #self.Weapons then
		warn("[PlayerInventory] Cannot switch to slot:", slotIndex)
		return false
	end

	if slotIndex == self.CurrentWeaponIndex then
		print("[PlayerInventory] Already on slot", slotIndex)
		return true
	end

	self.CurrentWeaponIndex = slotIndex
	print(string.format("[PlayerInventory] Switched to weapon slot %d", slotIndex))
	return true
end

function PlayerInventory:GetWeaponCount()
	return #self.Weapons
end

function PlayerInventory:IsWeaponSlotFull()
	return #self.Weapons >= Config.MaxWeaponSlots
end

--[[
	Get all weapon data in inventory
	@return table - Array of weapon data
]]
function PlayerInventory:GetAllWeapons()
	return self.Weapons
end

-- ============================================================
-- SHIELD MANAGEMENT
-- ============================================================

function PlayerInventory:EquipShield(shieldData)
	if self.Shield then
		warn("[PlayerInventory] Shield already equipped! Unequip first.")
		return false
	end

	self.Shield = shieldData
	print(string.format("[PlayerInventory] Equipped shield: %s", shieldData.Name))

	return true
end

function PlayerInventory:UnequipShield()
	if not self.Shield then
		warn("[PlayerInventory] No shield equipped")
		return nil
	end

	local shield = self.Shield
	self.Shield = nil
	print("[PlayerInventory] Unequipped shield")

	return shield
end

function PlayerInventory:GetShield()
	return self.Shield
end

function PlayerInventory:HasShield()
	return self.Shield ~= nil
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
