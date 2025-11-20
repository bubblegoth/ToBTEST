--[[
	DeathHandler.lua
	Handles player death, run completion, and persistence (Souls/Upgrades)
	Part of the Gothic FPS Roguelite Dungeon System
]]

local DeathHandler = {}

-- ============================================================
-- DEATH PROCESSING
-- ============================================================

function DeathHandler.OnPlayerDeath(playerStats)
	if not playerStats then
		warn("DeathHandler: No playerStats provided")
		return nil
	end

	-- Capture run summary before clearing
	local runSummary = {
		FloorReached = playerStats:GetCurrentFloor(),
		SoulsEarned = playerStats:GetRunStats().SoulsEarned,
		Kills = playerStats:GetRunStats().Kills,
		WeaponsFound = #playerStats.CurrentWeapons,
		HighestFloor = playerStats.HighestFloorReached,
	}

	-- Process death (clears weapons, resets to Church)
	playerStats:OnDeath()

	-- Generate death summary
	local deathMessage = DeathHandler.GetDeathSummary(runSummary, playerStats)

	return {
		RunSummary = runSummary,
		Message = deathMessage,
		PersistentSouls = playerStats:GetSouls(),
		IsGameOver = false,
	}
end

-- ============================================================
-- RUN COMPLETION (FLOOR 666 CLEARED)
-- ============================================================

function DeathHandler.OnRunComplete(playerStats)
	if not playerStats then
		warn("DeathHandler: No playerStats provided")
		return nil
	end

	-- Capture victory summary
	local victorySummary = {
		FloorReached = 666,
		SoulsEarned = playerStats:GetRunStats().SoulsEarned,
		Kills = playerStats:GetRunStats().Kills,
		WeaponsFound = #playerStats.CurrentWeapons,
		TotalDeaths = playerStats.TotalDeaths,
	}

	-- Process completion (returns to Church, keeps all progress)
	playerStats:OnRunComplete()

	-- Generate victory message
	local victoryMessage = DeathHandler.GetVictorySummary(victorySummary, playerStats)

	return {
		VictorySummary = victorySummary,
		Message = victoryMessage,
		PersistentSouls = playerStats:GetSouls(),
		IsGameOver = true,
		IsVictory = true,
	}
end

-- ============================================================
-- DEATH SUMMARY
-- ============================================================

function DeathHandler.GetDeathSummary(runSummary, playerStats)
	local lifetimeStats = playerStats:GetLifetimeStats()

	local summary = string.format(
		"=== YOU DIED ===\n\n" ..
		"Floor Reached: %d\n" ..
		"Souls Earned This Run: %d\n" ..
		"Enemies Killed: %d\n" ..
		"Weapons Found: %d\n\n" ..
		"=== PERSISTENT PROGRESS ===\n" ..
		"Total Souls: %d (KEPT)\n" ..
		"Highest Floor Ever: %d\n" ..
		"Total Deaths: %d\n\n" ..
		"All weapons have been lost.\n" ..
		"Return to the Church to spend your Souls on permanent upgrades.\n",
		runSummary.FloorReached,
		runSummary.SoulsEarned,
		runSummary.Kills,
		runSummary.WeaponsFound,
		lifetimeStats.CurrentSouls,
		lifetimeStats.HighestFloorReached,
		lifetimeStats.TotalDeaths
	)

	return summary
end

-- ============================================================
-- VICTORY SUMMARY
-- ============================================================

function DeathHandler.GetVictorySummary(victorySummary, playerStats)
	local lifetimeStats = playerStats:GetLifetimeStats()

	local summary = string.format(
		"=== VICTORY! ===\n" ..
		"You have descended all 666 floors and emerged triumphant!\n\n" ..
		"=== FINAL RUN STATS ===\n" ..
		"Souls Earned This Run: %d\n" ..
		"Enemies Killed: %d\n" ..
		"Weapons Found: %d\n\n" ..
		"=== LIFETIME STATS ===\n" ..
		"Total Souls: %d\n" ..
		"Total Deaths: %d\n" ..
		"Lifetime Souls Earned: %d\n\n" ..
		"You may continue exploring or return to the Church.\n",
		victorySummary.SoulsEarned,
		victorySummary.Kills,
		victorySummary.WeaponsFound,
		lifetimeStats.CurrentSouls,
		lifetimeStats.TotalDeaths,
		lifetimeStats.TotalSoulsEarned
	)

	return summary
end

-- ============================================================
-- RESPAWN LOGIC
-- ============================================================

function DeathHandler.Respawn(playerStats)
	if not playerStats then
		warn("DeathHandler: No playerStats provided")
		return false
	end

	-- Ensure player is at Church (Floor 1)
	if playerStats:GetCurrentFloor() ~= 1 then
		playerStats:ResetToChurch()
	end

	-- Player is ready to start new run
	return true, "Respawned at the Church (Floor 1). Ready to begin new descent."
end

-- ============================================================
-- PERSISTENCE HELPERS
-- ============================================================

function DeathHandler.ShouldPersist(dataType)
	-- What gets saved vs what gets lost
	local persistentData = {
		Souls = true,
		UpgradeLevels = true,
		TotalSoulsEarned = true,
		TotalDeaths = true,
		HighestFloorReached = true,
	}

	local lostOnDeath = {
		CurrentWeapons = false,
		CurrentFloor = false,
		RunSoulsEarned = false,
		RunKills = false,
		EquippedWeaponIndex = false,
	}

	if persistentData[dataType] then
		return true, "Persistent"
	elseif lostOnDeath[dataType] then
		return false, "Lost on death"
	else
		return false, "Unknown data type"
	end
end

function DeathHandler.GetPersistenceInfo()
	return {
		Persistent = {
			"Souls",
			"UpgradeLevels",
			"TotalSoulsEarned",
			"TotalDeaths",
			"HighestFloorReached",
		},
		LostOnDeath = {
			"CurrentWeapons",
			"CurrentFloor (reset to 1)",
			"RunSoulsEarned (stat tracking only)",
			"RunKills (stat tracking only)",
			"EquippedWeaponIndex",
		},
	}
end

-- ============================================================
-- DEATH SCREEN HELPERS (FOR UI)
-- ============================================================

function DeathHandler.GetDeathScreenData(playerStats)
	local runStats = playerStats:GetRunStats()
	local lifetimeStats = playerStats:GetLifetimeStats()

	return {
		-- Run data
		FloorReached = runStats.CurrentFloor,
		RunSouls = runStats.SoulsEarned,
		RunKills = runStats.Kills,
		WeaponsLost = runStats.WeaponsFound,

		-- Persistent data
		TotalSouls = lifetimeStats.CurrentSouls,
		HighestFloor = lifetimeStats.HighestFloorReached,
		TotalDeaths = lifetimeStats.TotalDeaths,
		LifetimeSouls = lifetimeStats.TotalSoulsEarned,

		-- Options
		CanRespawn = true,
		RespawnLocation = "The Church (Floor 1)",
	}
end

return DeathHandler
