--[[
════════════════════════════════════════════════════════════════════════════════
Module: ServerDamageHandler
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Server-side damage processing for projectile hits.
             Validates hits, applies damage through Combat module.
             Handles RemoteEvent communication from client shots.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Combat = require(ReplicatedStorage.Modules.Combat)

-- ============================================================
-- REMOTE EVENT SETUP
-- ============================================================

local damageEvent = Instance.new("RemoteEvent")
damageEvent.Name = "DealDamage"
damageEvent.Parent = ReplicatedStorage

-- ============================================================
-- ANTI-CHEAT CONFIGURATION
-- ============================================================

local Config = {
	-- Rate limiting
	MaxDamagePerSecond = 20, -- Max damage events per second per player
	FireRateTolerance = 0.05, -- Tolerance for fire rate (seconds)

	-- Damage validation
	MaxDamagePerShot = 500, -- Maximum damage a single shot can deal
	MaxRange = 2000, -- Maximum range for damage to be valid (studs)

	-- Logging
	LogSuspiciousActivity = true,
}

-- ============================================================
-- PLAYER TRACKING
-- ============================================================

local lastFireTime = {} -- [UserId] = tick()
local damageCount = {} -- [UserId] = {count, resetTime}

-- ============================================================
-- VALIDATION FUNCTIONS
-- ============================================================

local function isRateLimited(player)
	local now = tick()
	local userId = player.UserId

	-- Initialize damage counter
	if not damageCount[userId] then
		damageCount[userId] = {count = 0, resetTime = now + 1}
	end

	-- Reset counter every second
	if now >= damageCount[userId].resetTime then
		damageCount[userId] = {count = 0, resetTime = now + 1}
	end

	-- Check if exceeded limit
	if damageCount[userId].count >= Config.MaxDamagePerSecond then
		if Config.LogSuspiciousActivity then
			warn(string.format("[AntiCheat] %s exceeded damage rate limit (%d/s)",
				player.Name, Config.MaxDamagePerSecond))
		end
		return true
	end

	-- Increment counter
	damageCount[userId].count = damageCount[userId].count + 1
	return false
end

local function validateFireRate(player, weaponFireRate)
	local now = tick()
	local userId = player.UserId
	local lastFire = lastFireTime[userId] or 0

	local timeSinceLastFire = now - lastFire

	-- Check if firing too fast
	if timeSinceLastFire < (weaponFireRate - Config.FireRateTolerance) then
		if Config.LogSuspiciousActivity then
			warn(string.format("[AntiCheat] %s firing too fast (%.3fs < %.2fs)",
				player.Name, timeSinceLastFire, weaponFireRate))
		end
		return false
	end

	lastFireTime[userId] = now
	return true
end

local function validateDamage(damage)
	if type(damage) ~= "number" then
		return false, "Damage must be a number"
	end

	if damage < 0 then
		return false, "Negative damage not allowed"
	end

	if damage > Config.MaxDamagePerShot then
		if Config.LogSuspiciousActivity then
			warn(string.format("[AntiCheat] Damage too high: %.0f (max: %d)",
				damage, Config.MaxDamagePerShot))
		end
		return false, "Damage exceeds maximum"
	end

	return true
end

local function validateRange(attacker, target)
	if not attacker.Character or not target then
		return false
	end

	local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart

	if not attackerRoot or not targetRoot then
		return false
	end

	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude

	if distance > Config.MaxRange then
		if Config.LogSuspiciousActivity then
			warn(string.format("[AntiCheat] %s shot from too far away: %.0f studs (max: %d)",
				attacker.Name, distance, Config.MaxRange))
		end
		return false
	end

	return true
end

-- ============================================================
-- DAMAGE EVENT HANDLER
-- ============================================================

damageEvent.OnServerEvent:Connect(function(player, target, damage, damageType, weaponData)
	-- Validate player and character
	if not player or not player.Character then return end

	-- Validate target
	if not target or not target:FindFirstChild("Humanoid") then
		warn("[ServerDamageHandler] Invalid target from", player.Name)
		return
	end

	-- Rate limiting
	if isRateLimited(player) then
		return
	end

	-- Validate damage value
	local validDamage, damageError = validateDamage(damage)
	if not validDamage then
		warn(string.format("[ServerDamageHandler] Invalid damage from %s: %s",
			player.Name, damageError))
		return
	end

	-- Validate range
	if not validateRange(player, target) then
		return
	end

	-- Validate fire rate (if weaponData provided)
	if weaponData and weaponData.FireRate then
		if not validateFireRate(player, weaponData.FireRate) then
			return
		end
	end

	-- Clamp damage to reasonable value
	damage = math.clamp(damage, 0, Config.MaxDamagePerShot)

	-- Apply damage through Combat module
	local success = Combat:Damage(player, target, damage, damageType, weaponData)

	if success then
		print(string.format("[ServerDamageHandler] %s → %s: %.0f %s damage",
			player.Name,
			target.Name,
			damage,
			damageType or "Physical"))
	end
end)

-- ============================================================
-- CLEANUP
-- ============================================================

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastFireTime[player.UserId] = nil
	damageCount[player.UserId] = nil
end)

-- ============================================================
-- INITIALIZATION
-- ============================================================

print("════════════════════════════════════════════════════════")
print("[ServerDamageHandler] Initialized")
print(string.format("  Max Damage/Second: %d", Config.MaxDamagePerSecond))
print(string.format("  Max Damage/Shot: %d", Config.MaxDamagePerShot))
print(string.format("  Max Range: %d studs", Config.MaxRange))
print("════════════════════════════════════════════════════════")
