--[[
════════════════════════════════════════════════════════════════════════════════
Module: PlayerHealthHandler
Location: ServerScriptService/server/
Description: Manages player health and shield mechanics.
             Handles damage absorption, shield recharge, and break effects.
Version: 1.0
Last Updated: 2025-11-20
════════════════════════════════════════════════════════════════════════════════

Features:
- Shield-first damage absorption
- Automatic shield recharge (delay + rate)
- Break effects when shield breaks (Nova explosion, Frost slow, etc.)
- Health regeneration
- Integration with PlayerStats for equipped shields

Usage:
    -- Damage is applied automatically through Humanoid.TakeDamage
    -- Shield recharge happens automatically
    -- Break effects trigger when shield HP reaches 0
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerHealthHandler = {}

-- Try to load PlayerStats (for equipped shield data)
local PlayerStats = nil
pcall(function()
	PlayerStats = require(ReplicatedStorage.Modules.PlayerStats)
end)

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Default shield stats (if no shield equipped)
	DefaultShield = {
		Capacity = 50,
		RechargeRate = 5,
		RechargeDelay = 3.0,
		BreakEffectChance = 0.0,
		BreakEffect = "None"
	},

	-- Health regeneration
	HealthRegenRate = 1, -- HP per second
	HealthRegenDelay = 5.0, -- Seconds after last damage

	-- Shield visuals
	ShieldVisualEnabled = true,
	ShieldColor = Color3.fromRGB(100, 200, 255),

	-- Update frequency
	UpdateInterval = 0.1, -- Update shields every 0.1s
}

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER DATA
-- ════════════════════════════════════════════════════════════════════════════

local PlayerData = {} -- [UserId] = {ShieldHP, LastDamageTime, ...}

local function getOrCreatePlayerData(player)
	if not PlayerData[player.UserId] then
		-- Get equipped shield stats from PlayerStats if available
		local shieldStats = Config.DefaultShield

		if PlayerStats then
			local equippedShield = PlayerStats.GetEquippedShield(player)
			if equippedShield and equippedShield.Stats then
				shieldStats = equippedShield.Stats
			end
		end

		PlayerData[player.UserId] = {
			Player = player,
			ShieldHP = shieldStats.Capacity,
			MaxShieldHP = shieldStats.Capacity,
			ShieldStats = shieldStats,
			LastDamageTime = 0,
			IsRecharging = false,
			ShieldBroken = false
		}
	end

	return PlayerData[player.UserId]
end

local function removePlayerData(player)
	PlayerData[player.UserId] = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD VISUALS
-- ════════════════════════════════════════════════════════════════════════════

local function updateShieldVisual(player, shieldPercent)
	if not Config.ShieldVisualEnabled then return end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Find or create shield visual
	local shieldVisual = humanoidRootPart:FindFirstChild("ShieldVisual")

	if shieldPercent > 0 then
		-- Create visual if it doesn't exist
		if not shieldVisual then
			shieldVisual = Instance.new("Part")
			shieldVisual.Name = "ShieldVisual"
			shieldVisual.Shape = Enum.PartType.Ball
			shieldVisual.Size = Vector3.new(6, 6, 6)
			shieldVisual.Transparency = 0.7
			shieldVisual.CanCollide = false
			shieldVisual.CanQuery = false
			shieldVisual.Anchored = false
			shieldVisual.Material = Enum.Material.ForceField
			shieldVisual.Color = Config.ShieldColor
			shieldVisual.CastShadow = false

			-- Weld to HumanoidRootPart
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = humanoidRootPart
			weld.Part1 = shieldVisual
			weld.Parent = shieldVisual

			shieldVisual.Parent = humanoidRootPart
		end

		-- Update transparency based on shield percent
		shieldVisual.Transparency = 0.5 + (0.4 * (1 - shieldPercent))
	else
		-- Remove visual if shield is depleted
		if shieldVisual then
			shieldVisual:Destroy()
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD BREAK EFFECTS
-- ════════════════════════════════════════════════════════════════════════════

local function applyBreakEffect(player, shieldStats)
	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local effect = shieldStats.BreakEffect
	local chance = shieldStats.BreakEffectChance or 0

	-- Roll for effect activation
	if math.random() > chance then return end

	print(string.format("[PlayerHealth] %s shield break effect: %s", player.Name, effect))

	local position = humanoidRootPart.Position

	-- Apply effect based on type
	if effect == "ExplosivePush" then
		-- Push nearby enemies away
		local radius = shieldStats.BreakEffectRadius or 15
		local damage = shieldStats.BreakEffectDamage or 30

		for _, enemy in ipairs(workspace:GetDescendants()) do
			if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:GetAttribute("IsEnemy") then
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if enemyRoot then
					local distance = (enemyRoot.Position - position).Magnitude
					if distance <= radius then
						-- Apply damage
						enemy.Humanoid:TakeDamage(damage)

						-- Apply knockback
						local direction = (enemyRoot.Position - position).Unit
						local force = Instance.new("BodyVelocity")
						force.Velocity = direction * 50
						force.MaxForce = Vector3.new(50000, 50000, 50000)
						force.Parent = enemyRoot
						game:GetService("Debris"):AddItem(force, 0.2)
					end
				end
			end
		end

	elseif effect == "DamageReflect" then
		-- Reflect damage to nearby enemies
		local radius = shieldStats.BreakEffectRadius or 10
		local damage = shieldStats.BreakEffectDamage or 50

		for _, enemy in ipairs(workspace:GetDescendants()) do
			if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:GetAttribute("IsEnemy") then
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if enemyRoot and (enemyRoot.Position - position).Magnitude <= radius then
					enemy.Humanoid:TakeDamage(damage)
				end
			end
		end

	elseif effect == "SlowAura" then
		-- Slow nearby enemies
		local radius = shieldStats.BreakEffectRadius or 20
		local duration = shieldStats.BreakEffectDuration or 3.0

		for _, enemy in ipairs(workspace:GetDescendants()) do
			if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:GetAttribute("IsEnemy") then
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if enemyRoot and (enemyRoot.Position - position).Magnitude <= radius then
					local humanoid = enemy.Humanoid
					local originalSpeed = humanoid.WalkSpeed

					humanoid.WalkSpeed = originalSpeed * 0.3 -- 70% slow

					task.delay(duration, function()
						if humanoid then
							humanoid.WalkSpeed = originalSpeed
						end
					end)
				end
			end
		end

	elseif effect == "FireDOT" then
		-- Burn nearby enemies over time
		local radius = shieldStats.BreakEffectRadius or 12
		local damage = shieldStats.BreakEffectDamage or 10
		local duration = shieldStats.BreakEffectDuration or 5.0

		for _, enemy in ipairs(workspace:GetDescendants()) do
			if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:GetAttribute("IsEnemy") then
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if enemyRoot and (enemyRoot.Position - position).Magnitude <= radius then
					-- Apply DOT
					task.spawn(function()
						local humanoid = enemy.Humanoid
						local elapsed = 0
						while elapsed < duration and humanoid and humanoid.Health > 0 do
							humanoid:TakeDamage(damage / 5) -- Damage spread over duration
							elapsed = elapsed + 1
							task.wait(1)
						end
					end)
				end
			end
		end

	elseif effect == "Teleport" then
		-- Teleport player short distance
		local distance = shieldStats.BreakEffectRadius or 30
		local direction = humanoidRootPart.CFrame.LookVector
		local newPosition = position + (direction * -distance) -- Teleport backwards

		humanoidRootPart.CFrame = CFrame.new(newPosition)

	elseif effect == "HealBurst" then
		-- Heal player
		local healAmount = math.abs(shieldStats.BreakEffectDamage or 20)
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- DAMAGE HANDLING
-- ════════════════════════════════════════════════════════════════════════════

function PlayerHealthHandler.ApplyDamage(player, damage)
	local data = getOrCreatePlayerData(player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Update last damage time
	data.LastDamageTime = tick()
	data.IsRecharging = false

	-- Apply to shield first
	if data.ShieldHP > 0 then
		local shieldDamage = math.min(damage, data.ShieldHP)
		data.ShieldHP = data.ShieldHP - shieldDamage
		damage = damage - shieldDamage

		-- Check if shield broke
		if data.ShieldHP <= 0 and not data.ShieldBroken then
			data.ShieldBroken = true
			print(string.format("[PlayerHealth] %s shield broken!", player.Name))

			-- Apply break effect
			applyBreakEffect(player, data.ShieldStats)

			-- Update visual
			updateShieldVisual(player, 0)
		else
			-- Update visual
			local shieldPercent = data.ShieldHP / data.MaxShieldHP
			updateShieldVisual(player, shieldPercent)
		end
	end

	-- Apply remaining damage to health
	if damage > 0 then
		humanoid:TakeDamage(damage)
	end

	print(string.format("[PlayerHealth] %s took %d damage (Shield: %d/%d | Health: %d/%d)",
		player.Name, damage, data.ShieldHP, data.MaxShieldHP, humanoid.Health, humanoid.MaxHealth))
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD RECHARGE
-- ════════════════════════════════════════════════════════════════════════════

local function updateShieldRecharge(player, data, deltaTime)
	local now = tick()
	local timeSinceLastDamage = now - data.LastDamageTime

	-- Check if we should start recharging
	if timeSinceLastDamage >= data.ShieldStats.RechargeDelay then
		if not data.IsRecharging and data.ShieldHP < data.MaxShieldHP then
			data.IsRecharging = true
			print(string.format("[PlayerHealth] %s shield recharging...", player.Name))
		end

		-- Recharge shield
		if data.IsRecharging and data.ShieldHP < data.MaxShieldHP then
			local rechargeAmount = data.ShieldStats.RechargeRate * deltaTime
			data.ShieldHP = math.min(data.ShieldHP + rechargeAmount, data.MaxShieldHP)

			-- Mark shield as no longer broken
			if data.ShieldHP > 0 then
				data.ShieldBroken = false
			end

			-- Update visual
			local shieldPercent = data.ShieldHP / data.MaxShieldHP
			updateShieldVisual(player, shieldPercent)

			-- Stop recharging when full
			if data.ShieldHP >= data.MaxShieldHP then
				data.IsRecharging = false
				print(string.format("[PlayerHealth] %s shield fully recharged", player.Name))
			end
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- HEALTH REGENERATION
-- ════════════════════════════════════════════════════════════════════════════

local function updateHealthRegen(player, data, deltaTime)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local now = tick()
	local timeSinceLastDamage = now - data.LastDamageTime

	-- Regenerate health if enough time has passed
	if timeSinceLastDamage >= Config.HealthRegenDelay then
		if humanoid.Health < humanoid.MaxHealth then
			local regenAmount = Config.HealthRegenRate * deltaTime
			humanoid.Health = math.min(humanoid.Health + regenAmount, humanoid.MaxHealth)
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- UPDATE LOOP
-- ════════════════════════════════════════════════════════════════════════════

local lastUpdateTime = tick()

RunService.Heartbeat:Connect(function()
	local now = tick()
	local deltaTime = now - lastUpdateTime

	-- Throttle updates
	if deltaTime < Config.UpdateInterval then return end

	lastUpdateTime = now

	-- Update all players
	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerData[player.UserId]
		if data then
			updateShieldRecharge(player, data, deltaTime)
			updateHealthRegen(player, data, deltaTime)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD EQUIPMENT
-- ════════════════════════════════════════════════════════════════════════════

function PlayerHealthHandler.EquipShield(player, shieldData)
	local data = getOrCreatePlayerData(player)

	if not shieldData or not shieldData.Stats then
		warn("[PlayerHealth] Invalid shield data for", player.Name)
		return
	end

	print(string.format("[PlayerHealth] %s equipped shield: %s", player.Name, shieldData.Name or "Unknown"))

	-- Update shield stats
	data.ShieldStats = shieldData.Stats
	data.MaxShieldHP = shieldData.Stats.Capacity
	data.ShieldHP = shieldData.Stats.Capacity -- Fully recharge on equip
	data.ShieldBroken = false
	data.IsRecharging = false

	-- Update visual
	updateShieldVisual(player, 1.0)
end

function PlayerHealthHandler.GetShieldInfo(player)
	local data = PlayerData[player.UserId]
	if not data then return nil end

	return {
		ShieldHP = data.ShieldHP,
		MaxShieldHP = data.MaxShieldHP,
		ShieldPercent = data.ShieldHP / data.MaxShieldHP,
		IsRecharging = data.IsRecharging,
		Stats = data.ShieldStats
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
-- ════════════════════════════════════════════════════════════════════════════

local function onPlayerAdded(player)
	-- Initialize player data
	getOrCreatePlayerData(player)

	-- Wait for character
	player.CharacterAdded:Connect(function(character)
		-- Re-initialize on respawn
		local data = getOrCreatePlayerData(player)
		data.ShieldHP = data.MaxShieldHP
		data.LastDamageTime = 0
		data.IsRecharging = false
		data.ShieldBroken = false

		-- Update visual
		updateShieldVisual(player, 1.0)
	end)
end

local function onPlayerRemoving(player)
	removePlayerData(player)
end

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function PlayerHealthHandler.Initialize()
	-- Connect player events
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Initialize existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	print("[PlayerHealth] Initialized")
end

function PlayerHealthHandler.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

function PlayerHealthHandler.GetConfig()
	return Config
end

return PlayerHealthHandler
