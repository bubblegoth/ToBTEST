--[[
════════════════════════════════════════════════════════════════════════════════
Module: ChurchSystem
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Church hub system for purchasing permanent upgrades with Souls.
             Floor 0 safe zone - accessible after death or run completion.
             Manages upgrade shop, purchase validation, and stat bonuses.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local DungeonConfig = require(script.Parent.DungeonConfig)

local ChurchSystem = {}

-- ============================================================
-- UPGRADE SHOP INTERFACE
-- ============================================================

function ChurchSystem.GetAvailableUpgrades(playerStats)
	local upgrades = {}

	for _, upgradeConfig in ipairs(DungeonConfig.Upgrades) do
		local currentLevel = playerStats:GetUpgradeLevel(upgradeConfig.ID)
		local nextCost = DungeonConfig.GetUpgradeCost(upgradeConfig.ID, currentLevel)
		local isMaxed = (currentLevel >= upgradeConfig.MaxLevel)
		local canAfford = nextCost and playerStats:GetSouls() >= nextCost

		local upgrade = {
			ID = upgradeConfig.ID,
			Name = upgradeConfig.Name,
			Description = upgradeConfig.Description,
			CurrentLevel = currentLevel,
			MaxLevel = upgradeConfig.MaxLevel,
			NextCost = nextCost,
			BonusPerLevel = upgradeConfig.BonusPerLevel,
			CurrentBonus = upgradeConfig.BonusPerLevel * currentLevel,
			NextBonus = upgradeConfig.BonusPerLevel * (currentLevel + 1),
			IsMaxed = isMaxed,
			CanAfford = canAfford,
			StatKey = upgradeConfig.StatKey,
		}

		table.insert(upgrades, upgrade)
	end

	return upgrades
end

-- ============================================================
-- PURCHASE UPGRADE
-- ============================================================

function ChurchSystem.PurchaseUpgrade(playerStats, upgradeID)
	local success, result = playerStats:PurchaseUpgrade(upgradeID)

	if success then
		local newLevel = result
		return true, string.format("Upgraded %s to level %d", upgradeID, newLevel)
	else
		return false, result -- Error message
	end
end

-- ============================================================
-- UPGRADE DISPLAY
-- ============================================================

function ChurchSystem.GetUpgradeDisplay(upgrade)
	if upgrade.IsMaxed then
		return string.format(
			"[MAX] %s\n" ..
			"Level: %d / %d\n" ..
			"Bonus: %s\n" ..
			"Description: %s\n",
			upgrade.Name,
			upgrade.CurrentLevel,
			upgrade.MaxLevel,
			ChurchSystem.FormatBonus(upgrade.CurrentBonus, upgrade.StatKey),
			upgrade.Description
		)
	else
		return string.format(
			"%s %s\n" ..
			"Level: %d / %d\n" ..
			"Current: %s\n" ..
			"Next: %s (+%s)\n" ..
			"Cost: %d Souls\n" ..
			"Description: %s\n",
			upgrade.CanAfford and "[CAN AFFORD]" or "[LOCKED]",
			upgrade.Name,
			upgrade.CurrentLevel,
			upgrade.MaxLevel,
			ChurchSystem.FormatBonus(upgrade.CurrentBonus, upgrade.StatKey),
			ChurchSystem.FormatBonus(upgrade.NextBonus, upgrade.StatKey),
			ChurchSystem.FormatBonus(upgrade.BonusPerLevel, upgrade.StatKey),
			upgrade.NextCost,
			upgrade.Description
		)
	end
end

function ChurchSystem.FormatBonus(value, statKey)
	-- Percentage stats
	if statKey == "GunDamage" or
	   statKey == "FireRate" or
	   statKey == "Accuracy" or
	   statKey == "CritDamage" or
	   statKey == "ElementalChance" or
	   statKey == "ElementalDamage" or
	   statKey == "RecoilReduction" or
	   statKey == "ReloadSpeed" or
	   statKey == "MeleeDamage" or
	   statKey == "GrenadeDamage" or
	   statKey == "ShieldRechargeRate" then
		return string.format("+%.1f%%", value * 100)
	end

	-- Flat value stats
	if statKey == "MaxHealth" or statKey == "ShieldCapacity" then
		return string.format("+%.0f", value)
	end

	-- Negative stats (reduction)
	if statKey == "ShieldRechargeDelay" then
		return string.format("%.1fs", value)
	end

	-- Default
	return tostring(value)
end

-- ============================================================
-- CHURCH SHOP SUMMARY
-- ============================================================

function ChurchSystem.GetShopSummary(playerStats)
	local upgrades = ChurchSystem.GetAvailableUpgrades(playerStats)
	local playerSouls = playerStats:GetSouls()

	local summary = string.format(
		"=== THE CHURCH - SOUL UPGRADES ===\n" ..
		"Your Souls: %d\n\n",
		playerSouls
	)

	-- Group by affordability
	local affordable = {}
	local locked = {}
	local maxed = {}

	for _, upgrade in ipairs(upgrades) do
		if upgrade.IsMaxed then
			table.insert(maxed, upgrade)
		elseif upgrade.CanAfford then
			table.insert(affordable, upgrade)
		else
			table.insert(locked, upgrade)
		end
	end

	-- Display affordable upgrades first
	if #affordable > 0 then
		summary = summary .. "=== AVAILABLE UPGRADES ===\n"
		for _, upgrade in ipairs(affordable) do
			summary = summary .. ChurchSystem.GetUpgradeDisplay(upgrade) .. "\n"
		end
	end

	-- Then locked
	if #locked > 0 then
		summary = summary .. "=== LOCKED (Not Enough Souls) ===\n"
		for _, upgrade in ipairs(locked) do
			summary = summary .. ChurchSystem.GetUpgradeDisplay(upgrade) .. "\n"
		end
	end

	-- Then maxed
	if #maxed > 0 then
		summary = summary .. "=== MAXED UPGRADES ===\n"
		for _, upgrade in ipairs(maxed) do
			summary = summary .. ChurchSystem.GetUpgradeDisplay(upgrade) .. "\n"
		end
	end

	return summary
end

-- ============================================================
-- PLAYER STAT OVERVIEW (WITH UPGRADES APPLIED)
-- ============================================================

function ChurchSystem.GetPlayerStatsOverview(playerStats)
	local stats = playerStats.Stats
	local lifetimeStats = playerStats:GetLifetimeStats()

	local overview = string.format(
		"=== YOUR STATS ===\n" ..
		"Souls: %d\n" ..
		"Highest Floor: %d\n" ..
		"Total Deaths: %d\n" ..
		"Lifetime Souls: %d\n\n" ..
		"=== COMBAT STATS ===\n" ..
		"Max Health: %d\n" ..
		"Shield Capacity: %d\n" ..
		"Shield Recharge: %.1fs delay, %d/s rate\n\n" ..
		"=== WEAPON BONUSES ===\n" ..
		"Gun Damage: +%.1f%%\n" ..
		"Fire Rate: +%.1f%%\n" ..
		"Accuracy: +%.1f%%\n" ..
		"Reload Speed: +%.1f%%\n" ..
		"Recoil Reduction: +%.1f%%\n" ..
		"Critical Damage: +%.1f%%\n\n" ..
		"=== ELEMENTAL BONUSES ===\n" ..
		"Elemental Chance: +%.1f%%\n" ..
		"Elemental Damage: +%.1f%%\n\n" ..
		"=== OTHER ===\n" ..
		"Melee Damage: +%.1f%%\n" ..
		"Grenade Damage: +%.1f%%\n",
		lifetimeStats.CurrentSouls,
		lifetimeStats.HighestFloorReached,
		lifetimeStats.TotalDeaths,
		lifetimeStats.TotalSoulsEarned,
		stats.MaxHealth,
		stats.ShieldCapacity,
		stats.ShieldRechargeDelay,
		stats.ShieldRechargeRate,
		stats.GunDamage * 100,
		stats.FireRate * 100,
		stats.Accuracy * 100,
		stats.ReloadSpeed * 100,
		stats.RecoilReduction * 100,
		stats.CritDamage * 100,
		stats.ElementalChance * 100,
		stats.ElementalDamage * 100,
		stats.MeleeDamage * 100,
		stats.GrenadeDamage * 100
	)

	return overview
end

-- ============================================================
-- CHURCH ACCESSIBILITY
-- ============================================================

function ChurchSystem.IsChurchAccessible(currentFloor)
	-- Church is only on Floor 0
	return currentFloor == 0
end

function ChurchSystem.GetChurchMessage(currentFloor)
	if ChurchSystem.IsChurchAccessible(currentFloor) then
		return "Welcome to the Church. Spend your Souls on permanent upgrades."
	else
		return "The Church is only accessible from Floor 0 (after death or run completion)."
	end
end

return ChurchSystem
