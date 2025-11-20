--[[
	StartingWeapon.lua
	Handles giving player their starting weapon when entering Floor 1
	Common Level 1 Pistol - guaranteed on dungeon entry
	Part of the Gothic FPS Roguelite Dungeon System
]]

local WeaponGenerator = require(script.Parent.WeaponGenerator)

local StartingWeapon = {}

-- ============================================================
-- STARTING WEAPON CONFIGURATION
-- ============================================================

StartingWeapon.Config = {
	Level = 1,
	Type = "Pistol",
	Manufacturer = nil, -- Random manufacturer
	Rarity = "Common", -- Always Common
	GivenOnFloor = 1, -- Player receives this on Floor 1 entry
}

-- ============================================================
-- GENERATE STARTING WEAPON
-- ============================================================

function StartingWeapon.Generate()
	-- Generate a Common Level 1 Pistol
	local weapon = WeaponGenerator.GenerateWeapon(
		StartingWeapon.Config.Level,
		StartingWeapon.Config.Type,
		StartingWeapon.Config.Manufacturer,
		StartingWeapon.Config.Rarity
	)

	-- Mark as starting weapon for identification
	weapon.IsStartingWeapon = true

	return weapon
end

-- ============================================================
-- GIVE STARTING WEAPON TO PLAYER
-- ============================================================

function StartingWeapon.GiveToPlayer(playerStats)
	-- Generate starting weapon
	local weapon = StartingWeapon.Generate()

	-- Add to player inventory
	playerStats:AddWeapon(weapon)

	return weapon
end

-- ============================================================
-- CHECK IF PLAYER SHOULD RECEIVE STARTING WEAPON
-- ============================================================

function StartingWeapon.ShouldReceiveStartingWeapon(playerStats, enteringFloor)
	-- Player should receive starting weapon when:
	-- 1. Entering Floor 1 (from Floor 0)
	-- 2. Has no weapons currently

	if enteringFloor ~= StartingWeapon.Config.GivenOnFloor then
		return false
	end

	if #playerStats.CurrentWeapons > 0 then
		return false -- Player already has weapons
	end

	return true
end

-- ============================================================
-- HANDLE FLOOR ENTRY
-- ============================================================

function StartingWeapon.OnFloorEntry(playerStats, enteringFloor)
	if StartingWeapon.ShouldReceiveStartingWeapon(playerStats, enteringFloor) then
		local weapon = StartingWeapon.GiveToPlayer(playerStats)

		return true, weapon
	end

	return false, nil
end

-- ============================================================
-- GET STARTING WEAPON INFO (for display)
-- ============================================================

function StartingWeapon.GetInfo()
	return {
		Name = "Common Level 1 Pistol",
		Description = "A basic sidearm provided to all who descend into the dungeon.",
		Level = StartingWeapon.Config.Level,
		Type = StartingWeapon.Config.Type,
		Rarity = StartingWeapon.Config.Rarity,
		FloorGiven = StartingWeapon.Config.GivenOnFloor,
	}
end

-- ============================================================
-- DISPLAY STARTING WEAPON MESSAGE
-- ============================================================

function StartingWeapon.GetWelcomeMessage(weapon)
	return string.format(
		"=== ENTERING THE DUNGEON ===\n\n" ..
		"You have been given a starting weapon:\n" ..
		"  %s\n\n" ..
		"Manufacturer: %s\n" ..
		"Type: %s\n" ..
		"Rarity: %s\n" ..
		"Level: %d\n\n" ..
		"Weapons will begin dropping from enemies on Floor 2.\n" ..
		"Good luck, wanderer...",
		weapon.Name,
		weapon.Manufacturer,
		weapon.Type,
		weapon.Rarity,
		weapon.Level
	)
end

return StartingWeapon
