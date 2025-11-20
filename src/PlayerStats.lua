--[[
	PlayerStats.lua
	Manages persistent player progression (Souls, Upgrades, Current Run Stats)
	Part of the Gothic FPS Roguelite Dungeon System
]]

local DungeonConfig = require(script.Parent.DungeonConfig)

local PlayerStats = {}
PlayerStats.__index = PlayerStats

-- ============================================================
-- PLAYER STATE INITIALIZATION
-- ============================================================

function PlayerStats.new()
	local self = setmetatable({}, PlayerStats)

	-- Persistent progression (survives death)
	self.Souls = DungeonConfig.PlayerDefaults.StartingSouls
	self.UpgradeLevels = {} -- { CritDamage = 3, GunDamage = 5, ... }
	self.TotalSoulsEarned = 0
	self.TotalDeaths = 0
	self.HighestFloorReached = 1

	-- Current run state (lost on death)
	self.CurrentFloor = DungeonConfig.PlayerDefaults.StartingFloor
	self.CurrentWeapons = {} -- Array of weapon objects
	self.EquippedWeaponIndex = 1
	self.RunSoulsEarned = 0
	self.RunKills = 0

	-- Combat stats (base + upgrades applied)
	self.Stats = self:CalculateStats()

	return self
end

-- ============================================================
-- STAT CALCULATION (BASE + UPGRADES)
-- ============================================================

function PlayerStats:CalculateStats()
	local base = DungeonConfig.PlayerDefaults.BaseStats
	local stats = {
		MaxHealth = base.MaxHealth,
		ShieldCapacity = base.ShieldCapacity,
		ShieldRechargeDelay = base.ShieldRechargeDelay,
		ShieldRechargeRate = base.ShieldRechargeRate,
		MovementSpeed = base.MovementSpeed,

		-- Weapon modifiers (applied to all equipped weapons)
		GunDamage = 0,
		FireRate = 0,
		Accuracy = 0,
		RecoilReduction = 0,
		ReloadSpeed = 0,
		CritDamage = 0,

		-- Elemental modifiers
		ElementalChance = 0,
		ElementalDamage = 0,

		-- Other combat stats
		MeleeDamage = 0,
		GrenadeDamage = 0,
	}

	-- Apply upgrade bonuses
	for _, upgrade in ipairs(DungeonConfig.Upgrades) do
		local level = self.UpgradeLevels[upgrade.ID] or 0
		if level > 0 then
			local bonus = upgrade.BonusPerLevel * level
			stats[upgrade.StatKey] = (stats[upgrade.StatKey] or 0) + bonus
		end
	end

	return stats
end

-- Recalculate stats when upgrades are purchased
function PlayerStats:RefreshStats()
	self.Stats = self:CalculateStats()
end

-- ============================================================
-- SOUL MANAGEMENT
-- ============================================================

function PlayerStats:AddSouls(amount)
	self.Souls = self.Souls + amount
	self.TotalSoulsEarned = self.TotalSoulsEarned + amount
	self.RunSoulsEarned = self.RunSoulsEarned + amount
end

function PlayerStats:SpendSouls(amount)
	if self.Souls >= amount then
		self.Souls = self.Souls - amount
		return true
	end
	return false
end

function PlayerStats:GetSouls()
	return self.Souls
end

-- ============================================================
-- UPGRADE MANAGEMENT
-- ============================================================

function PlayerStats:GetUpgradeLevel(upgradeID)
	return self.UpgradeLevels[upgradeID] or 0
end

function PlayerStats:CanAffordUpgrade(upgradeID)
	local currentLevel = self:GetUpgradeLevel(upgradeID)
	local cost = DungeonConfig.GetUpgradeCost(upgradeID, currentLevel)

	if not cost then
		return false, "Max level reached"
	end

	if self.Souls >= cost then
		return true, cost
	else
		return false, "Not enough Souls"
	end
end

function PlayerStats:PurchaseUpgrade(upgradeID)
	local canAfford, costOrReason = self:CanAffordUpgrade(upgradeID)

	if not canAfford then
		return false, costOrReason
	end

	local cost = costOrReason
	self:SpendSouls(cost)

	local currentLevel = self:GetUpgradeLevel(upgradeID)
	self.UpgradeLevels[upgradeID] = currentLevel + 1

	-- Recalculate stats with new upgrade
	self:RefreshStats()

	return true, self.UpgradeLevels[upgradeID]
end

-- ============================================================
-- WEAPON INVENTORY
-- ============================================================

function PlayerStats:AddWeapon(weapon)
	table.insert(self.CurrentWeapons, weapon)
end

function PlayerStats:RemoveWeapon(index)
	if self.CurrentWeapons[index] then
		table.remove(self.CurrentWeapons, index)

		-- Adjust equipped index if needed
		if self.EquippedWeaponIndex > #self.CurrentWeapons then
			self.EquippedWeaponIndex = math.max(1, #self.CurrentWeapons)
		end
	end
end

function PlayerStats:GetEquippedWeapon()
	return self.CurrentWeapons[self.EquippedWeaponIndex]
end

function PlayerStats:EquipWeapon(index)
	if self.CurrentWeapons[index] then
		self.EquippedWeaponIndex = index
		return true
	end
	return false
end

function PlayerStats:ClearWeapons()
	self.CurrentWeapons = {}
	self.EquippedWeaponIndex = 1
end

-- ============================================================
-- FLOOR PROGRESSION
-- ============================================================

function PlayerStats:AdvanceFloor()
	self.CurrentFloor = self.CurrentFloor + 1

	if self.CurrentFloor > self.HighestFloorReached then
		self.HighestFloorReached = self.CurrentFloor
	end
end

function PlayerStats:GetCurrentFloor()
	return self.CurrentFloor
end

function PlayerStats:ResetToChurch()
	self.CurrentFloor = DungeonConfig.PlayerDefaults.StartingFloor
end

-- ============================================================
-- DEATH HANDLING
-- ============================================================

function PlayerStats:OnDeath()
	-- Clear current run data
	self:ClearWeapons()
	self.RunSoulsEarned = 0
	self.RunKills = 0
	self:ResetToChurch()

	-- Persistent data remains (Souls, Upgrades, HighestFloor)
	self.TotalDeaths = self.TotalDeaths + 1
end

-- ============================================================
-- RUN COMPLETION (REACHED FLOOR 666)
-- ============================================================

function PlayerStats:OnRunComplete()
	-- Player beat the game! Return to Church with all progress intact
	self:ResetToChurch()
end

-- ============================================================
-- STAT TRACKING
-- ============================================================

function PlayerStats:IncrementKills()
	self.RunKills = self.RunKills + 1
end

function PlayerStats:GetRunStats()
	return {
		CurrentFloor = self.CurrentFloor,
		SoulsEarned = self.RunSoulsEarned,
		Kills = self.RunKills,
		WeaponsFound = #self.CurrentWeapons,
	}
end

function PlayerStats:GetLifetimeStats()
	return {
		TotalSoulsEarned = self.TotalSoulsEarned,
		TotalDeaths = self.TotalDeaths,
		HighestFloorReached = self.HighestFloorReached,
		CurrentSouls = self.Souls,
	}
end

-- ============================================================
-- SAVE/LOAD INTERFACE (For DataStore integration)
-- ============================================================

function PlayerStats:GetSaveData()
	return {
		Souls = self.Souls,
		UpgradeLevels = self.UpgradeLevels,
		TotalSoulsEarned = self.TotalSoulsEarned,
		TotalDeaths = self.TotalDeaths,
		HighestFloorReached = self.HighestFloorReached,
	}
end

function PlayerStats:LoadSaveData(data)
	if data then
		self.Souls = data.Souls or 0
		self.UpgradeLevels = data.UpgradeLevels or {}
		self.TotalSoulsEarned = data.TotalSoulsEarned or 0
		self.TotalDeaths = data.TotalDeaths or 0
		self.HighestFloorReached = data.HighestFloorReached or 1

		-- Recalculate stats with loaded upgrades
		self:RefreshStats()
	end
end

return PlayerStats
