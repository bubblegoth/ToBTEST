--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldManager
Location: ServerScriptService/
Description: Manages player shields - damage absorption, recharging, and visual
             attachment to player's waist. Handles shield break effects.

Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[ShieldManager] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ShieldModelBuilder = require(Modules:WaitForChild("ShieldModelBuilder"))
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER SHIELD DATA
-- ════════════════════════════════════════════════════════════════════════════

local playerShields = {} -- [player] = {shieldData, currentHP, lastDamageTime, model}

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD ATTACHMENT
-- ════════════════════════════════════════════════════════════════════════════

local function attachShieldToPlayer(player, shieldModel)
	local character = player.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Find or create waist attachment point
	local waistAttachment = rootPart:FindFirstChild("WaistAttachment")
	if not waistAttachment then
		waistAttachment = Instance.new("Attachment")
		waistAttachment.Name = "WaistAttachment"
		waistAttachment.Position = Vector3.new(0.6, -0.3, 0) -- Right hip
		waistAttachment.Parent = rootPart
	end

	-- Position shield at waist
	if shieldModel.PrimaryPart then
		-- Create weld to attach shield to character
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = shieldModel.PrimaryPart
		weld.Parent = shieldModel.PrimaryPart

		-- Position offset (right hip)
		shieldModel:PivotTo(rootPart.CFrame * CFrame.new(0.6, -0.3, 0.2) * CFrame.Angles(0, math.rad(90), 0))
	end

	shieldModel.Parent = character
	print(string.format("[ShieldManager] Attached shield to %s's waist", player.Name))

	return true
end

local function detachShieldFromPlayer(player)
	local character = player.Character
	if not character then return end

	-- Find and remove shield model
	local shieldModel = character:FindFirstChild("ShieldGenerator")
	if shieldModel then
		shieldModel:Destroy()
		print(string.format("[ShieldManager] Detached shield from %s", player.Name))
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- EQUIP/UNEQUIP SHIELD
-- ════════════════════════════════════════════════════════════════════════════

local function equipShield(player, shieldData)
	-- Create 3D shield model
	local shieldModel = ShieldModelBuilder:BuildShield(shieldData)
	if not shieldModel then
		warn("[ShieldManager] Failed to build shield model")
		return false
	end

	-- Attach to player's waist
	if not attachShieldToPlayer(player, shieldModel) then
		warn("[ShieldManager] Failed to attach shield to player")
		shieldModel:Destroy()
		return false
	end

	-- Initialize shield data
	playerShields[player] = {
		shieldData = shieldData,
		currentHP = shieldData.Stats.Capacity,
		lastDamageTime = 0,
		model = shieldModel,
		isBroken = false
	}

	print(string.format("[ShieldManager] %s equipped shield: %s (Capacity: %d)",
		player.Name, shieldData.Name, shieldData.Stats.Capacity))

	return true
end

local function unequipShield(player)
	-- Remove shield data
	playerShields[player] = nil

	-- Detach visual model
	detachShieldFromPlayer(player)

	print(string.format("[ShieldManager] %s unequipped shield", player.Name))
end

-- ════════════════════════════════════════════════════════════════════════════
-- DAMAGE ABSORPTION
-- ════════════════════════════════════════════════════════════════════════════

local function absorbDamage(player, damage)
	local shieldInfo = playerShields[player]
	if not shieldInfo or shieldInfo.isBroken then
		return damage -- No shield or broken, take full damage
	end

	local shieldData = shieldInfo.shieldData

	-- Shield absorbs damage
	local absorbedDamage = math.min(damage, shieldInfo.currentHP)
	local remainingDamage = damage - absorbedDamage

	shieldInfo.currentHP = shieldInfo.currentHP - absorbedDamage
	shieldInfo.lastDamageTime = tick()

	print(string.format("[ShieldManager] %s shield absorbed %d damage (%d HP remaining)",
		player.Name, absorbedDamage, shieldInfo.currentHP))

	-- Check if shield broke
	if shieldInfo.currentHP <= 0 then
		shieldInfo.isBroken = true
		handleShieldBreak(player, shieldInfo)
	else
		-- Flash shield when taking damage
		flashShield(shieldInfo.model)
	end

	return remainingDamage
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD BREAK EFFECTS
-- ════════════════════════════════════════════════════════════════════════════

local function handleShieldBreak(player, shieldInfo)
	local shieldData = shieldInfo.shieldData

	print(string.format("[ShieldManager] %s's shield broke! Effect: %s",
		player.Name, shieldData.Stats.BreakEffect))

	-- Roll for break effect
	if math.random() <= shieldData.Stats.BreakEffectChance then
		applyBreakEffect(player, shieldData.Stats)
	end

	-- Visual effect
	if shieldInfo.model and shieldInfo.model.PrimaryPart then
		-- Shield break particle effect
		local explosion = Instance.new("Explosion")
		explosion.Position = shieldInfo.model.PrimaryPart.Position
		explosion.BlastRadius = shieldData.Stats.BreakEffectRadius or 10
		explosion.BlastPressure = 0 -- No physics force
		explosion.DestroyJointRadiusPercent = 0
		explosion.Parent = workspace

		-- Remove visual after 0.5s
		task.delay(0.5, function()
			if shieldInfo.model then
				shieldInfo.model.Parent = nil
			end
		end)
	end
end

local function applyBreakEffect(player, stats)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Apply effect based on type
	if stats.BreakEffect == "ExplosivePush" then
		-- Push nearby enemies away
		local explosion = Instance.new("Explosion")
		explosion.Position = rootPart.Position
		explosion.BlastRadius = stats.BreakEffectRadius
		explosion.BlastPressure = 50000
		explosion.Parent = workspace

	elseif stats.BreakEffect == "DamageReflect" then
		-- Damage nearby enemies (simplified)
		-- TODO: Implement proper damage reflection

	elseif stats.BreakEffect == "SlowAura" then
		-- Slow nearby enemies (simplified)
		-- TODO: Implement slow effect

	elseif stats.BreakEffect == "FireDOT" then
		-- Burn nearby enemies (simplified)
		-- TODO: Implement fire DOT

	elseif stats.BreakEffect == "HealBurst" then
		-- Heal player
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = math.min(humanoid.Health - stats.BreakEffectDamage, humanoid.MaxHealth)
			print(string.format("[ShieldManager] Healed %s for %d HP", player.Name, -stats.BreakEffectDamage))
		end
	end
end

local function flashShield(shieldModel)
	if not shieldModel or not shieldModel:FindFirstChild("Core") then return end

	local core = shieldModel.Core

	-- Flash transparency
	local originalTransparency = core.Transparency
	core.Transparency = 0.3

	task.delay(0.1, function()
		if core then
			core.Transparency = originalTransparency
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD RECHARGING
-- ════════════════════════════════════════════════════════════════════════════

local function updateShieldRecharge()
	for player, shieldInfo in pairs(playerShields) do
		if not player.Parent then
			-- Player left, cleanup
			playerShields[player] = nil
			continue
		end

		local shieldData = shieldInfo.shieldData
		local timeSinceDamage = tick() - shieldInfo.lastDamageTime

		-- Check if shield is broken and recharge delay has passed
		if shieldInfo.isBroken and timeSinceDamage >= shieldData.Stats.RechargeDelay then
			-- Start recharging broken shield
			shieldInfo.isBroken = false
			shieldInfo.currentHP = 0
			print(string.format("[ShieldManager] %s's shield starting recharge", player.Name))

			-- Restore visual
			if shieldInfo.model then
				shieldInfo.model.Parent = player.Character
			end
		end

		-- Recharge shield if delay has passed and not at full
		if not shieldInfo.isBroken and
			shieldInfo.currentHP < shieldData.Stats.Capacity and
			timeSinceDamage >= shieldData.Stats.RechargeDelay then

			-- Recharge
			local rechargeAmount = shieldData.Stats.RechargeRate * 0.1 -- 0.1 second intervals
			shieldInfo.currentHP = math.min(shieldInfo.currentHP + rechargeAmount, shieldData.Stats.Capacity)

			-- Debug (only print when fully recharged)
			if shieldInfo.currentHP >= shieldData.Stats.Capacity then
				print(string.format("[ShieldManager] %s's shield fully recharged", player.Name))
			end
		end
	end
end

-- Start recharge loop
RunService.Heartbeat:Connect(function()
	updateShieldRecharge()
end)

-- ════════════════════════════════════════════════════════════════════════════
-- DAMAGE INTERCEPTION
-- ════════════════════════════════════════════════════════════════════════════

-- Hook into damage system
_G.AbsorbShieldDamage = function(player, damage)
	return absorbDamage(player, damage)
end

_G.EquipPlayerShield = function(player, shieldData)
	return equipShield(player, shieldData)
end

_G.UnequipPlayerShield = function(player)
	return unequipShield(player)
end

_G.GetPlayerShieldHP = function(player)
	local shieldInfo = playerShields[player]
	if shieldInfo then
		return shieldInfo.currentHP, shieldInfo.shieldData.Stats.Capacity
	end
	return 0, 0
end

-- ════════════════════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
-- ════════════════════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(player)
	playerShields[player] = nil
end)

print("[ShieldManager] ═══════════════════════════════════════")
print("[ShieldManager] Shield System Active")
print("[ShieldManager] Shields absorb damage before health")
print("[ShieldManager] Shields recharge after delay")
print("[ShieldManager] ═══════════════════════════════════════")
