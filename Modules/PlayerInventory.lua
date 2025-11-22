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
	self.Weapons = {} -- Array of weapon Tools (max 4)
	self.Shield = nil -- Single shield (nil = no shield equipped)
	self.CurrentWeaponIndex = 1 -- Which weapon slot is currently equipped (1-4)

	return self
end

-- ============================================================
-- WEAPON MANAGEMENT
-- ============================================================

function PlayerInventory:AddWeapon(weaponTool)
	-- Check if inventory is full
	if #self.Weapons >= Config.MaxWeaponSlots then
		warn("[PlayerInventory] Weapon slots full! Cannot add weapon.")
		return false
	end

	-- Add to first empty slot
	table.insert(self.Weapons, weaponTool)
	print(string.format("[PlayerInventory] Added weapon to slot %d: %s", #self.Weapons, weaponTool.Name))

	return true
end

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

	print(string.format("[PlayerInventory] Removed weapon from slot %d", slotIndex))
	return weapon
end

function PlayerInventory:GetWeapon(slotIndex)
	return self.Weapons[slotIndex]
end

function PlayerInventory:GetCurrentWeapon()
	return self.Weapons[self.CurrentWeaponIndex]
end

function PlayerInventory:SwapWeapon(slotIndex)
	if slotIndex < 1 or slotIndex > #self.Weapons then
		warn("[PlayerInventory] Cannot swap to slot:", slotIndex)
		return false
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
