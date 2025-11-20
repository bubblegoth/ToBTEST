--[[
	Combat.lua
	Combat system for Gothic FPS Roguelite
	Handles damage calculation, enemy deaths, and loot drops
]]

local Combat = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================
-- DAMAGE TYPES
-- ============================================================

Combat.DamageTypes = {
	PHYSICAL = "Physical",
	FIRE = "Fire",
	FROST = "Frost",
	SHADOW = "Shadow",
	LIGHT = "Light",
	VOID = "Void"
}

-- ============================================================
-- DAMAGE CALCULATION
-- ============================================================

function Combat:CalculateDamage(attacker, target, baseDamage, damageType, weaponData)
	if not target or not target:FindFirstChild("Humanoid") then
		warn("[Combat] Invalid target")
		return 0
	end

	local finalDamage = baseDamage

	-- Apply elemental bonuses from weapon
	if weaponData then
		if damageType == self.DamageTypes.FIRE and weaponData.FireDamage then
			finalDamage = finalDamage * (1 + weaponData.FireDamage / 100)
		elseif damageType == self.DamageTypes.FROST and weaponData.FrostDamage then
			finalDamage = finalDamage * (1 + weaponData.FrostDamage / 100)
		elseif damageType == self.DamageTypes.SHADOW and weaponData.ShadowDamage then
			finalDamage = finalDamage * (1 + weaponData.ShadowDamage / 100)
		elseif damageType == self.DamageTypes.LIGHT and weaponData.LightDamage then
			finalDamage = finalDamage * (1 + weaponData.LightDamage / 100)
		elseif damageType == self.DamageTypes.VOID and weaponData.VoidDamage then
			finalDamage = finalDamage * (1 + weaponData.VoidDamage / 100)
		end

		-- Apply damage vs specific enemy types
		if weaponData.DamageVsUndead and target:GetAttribute("EnemyType") == "Undead" then
			finalDamage = finalDamage * (1 + weaponData.DamageVsUndead / 100)
		end
	end

	-- Random crit roll (if weapon has crit chance)
	if weaponData and weaponData.CritChance then
		local critRoll = math.random(1, 100)
		if critRoll <= weaponData.CritChance then
			local critMultiplier = 1.5 + ((weaponData.CritDamage or 0) / 100)
			finalDamage = finalDamage * critMultiplier
			print(string.format("[Combat] CRITICAL HIT! %.0fx damage", critMultiplier))
		end
	end

	return math.floor(finalDamage)
end

-- ============================================================
-- DAMAGE APPLICATION
-- ============================================================

function Combat:Damage(attacker, target, amount, damageType, weaponData)
	if not target or not target:FindFirstChild("Humanoid") then
		warn("[Combat] Invalid target for damage")
		return false
	end

	local targetHumanoid = target:FindFirstChild("Humanoid")
	if not targetHumanoid then return false end

	-- Calculate final damage
	local finalDamage = self:CalculateDamage(attacker, target, amount, damageType, weaponData)

	-- Apply damage
	targetHumanoid:TakeDamage(finalDamage)

	print(string.format("[Combat] %s dealt %.0f %s damage to %s",
		attacker and attacker.Name or "Unknown",
		finalDamage,
		damageType or "Physical",
		target.Name))

	-- Handle death
	if targetHumanoid.Health <= 0 then
		self:HandleDeath(attacker, target, weaponData)
	end

	-- Apply status effects
	if weaponData then
		self:ApplyStatusEffects(target, weaponData)
	end

	-- Handle lifesteal/heal on hit
	if attacker and attacker:IsA("Player") and weaponData then
		if weaponData.KillHeal and targetHumanoid.Health <= 0 then
			self:HealPlayer(attacker, weaponData.KillHeal)
		end
	end

	return true
end

-- ============================================================
-- DEATH HANDLING
-- ============================================================

function Combat:HandleDeath(killer, enemy, weaponData)
	if not killer or not killer:IsA("Player") then return end

	print(string.format("[Combat] %s killed %s", killer.Name, enemy.Name))

	-- Grant souls
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(killer)
	if playerStats then
		local baseSouls = enemy:GetAttribute("SoulValue") or 10
		local soulBonus = weaponData and weaponData.SoulGain or 0
		local totalSouls = baseSouls + soulBonus

		playerStats:AddSouls(totalSouls)
		print(string.format("[Combat] %s gained %d Souls", killer.Name, totalSouls))

		-- Update player values
		if _G.UpdatePlayerValues then
			_G.UpdatePlayerValues(killer)
		end
	end

	-- Spawn loot
	local ModularLootGen = require(ReplicatedStorage.src.ModularLootGen)
	if playerStats then
		local currentFloor = playerStats:GetCurrentFloor()
		local playerLevel = killer:GetAttribute("Level") or 1
		ModularLootGen:SpawnLootFromEnemy(enemy, playerLevel, currentFloor)
	end

	-- Destroy enemy after delay
	task.wait(2)
	if enemy.Parent then
		enemy:Destroy()
	end
end

-- ============================================================
-- STATUS EFFECTS
-- ============================================================

function Combat:ApplyStatusEffects(target, weaponData)
	if not target or not weaponData then return end

	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Burn effect
	if weaponData.BurnChance and math.random(1, 100) <= weaponData.BurnChance then
		self:ApplyBurn(target, weaponData.FireDamage or 10, 3)
	end

	-- Slow effect
	if weaponData.SlowChance and math.random(1, 100) <= weaponData.SlowChance then
		self:ApplySlow(target, 0.5, 2)
	end

	-- Chain effect (spread to nearby enemies)
	if weaponData.ChainEffect and weaponData.ChainEffect > 0 then
		self:ApplyChainEffect(target, weaponData.ChainEffect, weaponData.Damage or 10)
	end
end

function Combat:ApplyBurn(target, damage, duration)
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then return end

	print(string.format("[Combat] %s is burning!", target.Name))

	-- Create fire effect
	local fire = Instance.new("Fire")
	fire.Parent = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")

	-- Apply damage over time
	task.spawn(function()
		for i = 1, duration do
			if not target.Parent or humanoid.Health <= 0 then break end
			humanoid:TakeDamage(damage)
			task.wait(1)
		end
		if fire.Parent then fire:Destroy() end
	end)
end

function Combat:ApplySlow(target, slowAmount, duration)
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid then return end

	print(string.format("[Combat] %s is slowed!", target.Name))

	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = originalSpeed * slowAmount

	-- Frost visual effect
	local frost = Instance.new("ParticleEmitter")
	frost.Parent = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
	frost.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	frost.Rate = 20
	frost.Lifetime = NumberRange.new(1, 2)
	frost.Speed = NumberRange.new(1, 3)

	task.delay(duration, function()
		if target.Parent and humanoid then
			humanoid.WalkSpeed = originalSpeed
		end
		if frost.Parent then frost:Destroy() end
	end)
end

function Combat:ApplyChainEffect(originTarget, chainCount, damage)
	local origin = originTarget.PrimaryPart or originTarget:FindFirstChild("HumanoidRootPart")
	if not origin then return end

	-- Find nearby enemies
	local nearbyEnemies = {}
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= originTarget and obj:FindFirstChild("Humanoid") and obj:GetAttribute("IsEnemy") then
			local targetPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
			if targetPart and (targetPart.Position - origin.Position).Magnitude <= 20 then
				table.insert(nearbyEnemies, obj)
			end
		end
	end

	-- Chain to nearby enemies
	for i = 1, math.min(chainCount, #nearbyEnemies) do
		local target = nearbyEnemies[i]
		if target and target:FindFirstChild("Humanoid") then
			target.Humanoid:TakeDamage(damage * 0.5) -- Chain does 50% damage
			print(string.format("[Combat] Chain effect hit %s!", target.Name))

			-- Create lightning visual
			local beam = Instance.new("Beam")
			local att0 = Instance.new("Attachment")
			att0.Parent = origin
			local att1 = Instance.new("Attachment")
			att1.Parent = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")

			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Color = ColorSequence.new(Color3.fromRGB(150, 0, 255))
			beam.Width0 = 0.5
			beam.Width1 = 0.5
			beam.Parent = workspace.Terrain

			game:GetService("Debris"):AddItem(beam, 0.3)
			game:GetService("Debris"):AddItem(att0, 0.3)
			game:GetService("Debris"):AddItem(att1, 0.3)
		end
	end
end

-- ============================================================
-- HEALING
-- ============================================================

function Combat:HealPlayer(player, amount)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
	print(string.format("[Combat] %s healed for %.0f HP", player.Name, amount))
end

-- ============================================================
-- RANGE CHECK
-- ============================================================

function Combat:CanHit(attacker, target, maxRange)
	if not attacker or not target then return false end

	local attackerRoot = attacker:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart

	if not attackerRoot or not targetRoot then return false end

	local distance = (attackerRoot.Position - targetRoot.Position).Magnitude

	return distance <= maxRange
end

return Combat
