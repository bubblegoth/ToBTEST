--[[
════════════════════════════════════════════════════════════════════════════════
Module: ModularLootGen
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Weapon loot drop system with visual effects and pickups.
             Spawns floating weapon cards with rarity-colored beams.
             Integrates with PickupSystem for health/ammo drops.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local ModularLootGen = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WeaponGenerator = require(script.Parent.WeaponGenerator)
local WeaponModelBuilder = require(script.Parent.WeaponModelBuilder)
local WeaponToolBuilder = require(script.Parent.WeaponToolBuilder)
local ShieldGenerator = require(script.Parent.ShieldGenerator)
local ShieldModelBuilder = require(script.Parent.ShieldModelBuilder)
local PlayerInventory = require(script.Parent.PlayerInventory)
local PickupSystem = require(script.Parent.PickupSystem)

-- ============================================================
-- WEAPON LOOT SPAWNING
-- ============================================================

function ModularLootGen:SpawnWeaponLoot(position, level, forcedRarity)
	-- Generate weapon
	local weapon = WeaponGenerator:GenerateWeapon(level, nil, forcedRarity)
	local weaponCard = WeaponGenerator:GetWeaponCard(weapon)

	-- Build 3D model (spawn closer to ground since enemies are elevated)
	local weaponModel = WeaponModelBuilder:BuildWeapon(weapon)
	weaponModel:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 1, 0)))

	-- Make all parts non-collidable and anchored for display
	for _, part in pairs(weaponModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	weaponModel.Parent = workspace

	-- Create invisible collision part for pickup
	local lootDrop = Instance.new("Part")
	lootDrop.Name = "WeaponLoot"
	lootDrop.Size = Vector3.new(2, 2, 2)
	lootDrop.Position = position + Vector3.new(0, 1, 0)
	lootDrop.Anchored = true
	lootDrop.CanCollide = false
	lootDrop.Transparency = 1
	lootDrop.Parent = workspace

	-- Store weapon data
	lootDrop:SetAttribute("WeaponData", game:GetService("HttpService"):JSONEncode(weapon))

	-- Create floating animation (lower height)
	local originalY = position.Y + 1
	local floatConnection
	floatConnection = RunService.Heartbeat:Connect(function()
		if not lootDrop.Parent or not weaponModel.Parent then
			if floatConnection then floatConnection:Disconnect() end
			return
		end

		local time = tick()
		local newY = originalY + math.sin(time * 2) * 0.5
		local rotation = CFrame.Angles(0, time * 0.5, 0)

		weaponModel:SetPrimaryPartCFrame(CFrame.new(position.X, newY, position.Z) * rotation)
		lootDrop.Position = Vector3.new(position.X, newY, position.Z)
	end)

	-- Create beam effect
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = lootDrop
	attachment0.Position = Vector3.new(0, 1, 0)

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = lootDrop
	attachment1.Position = Vector3.new(0, 20, 0)

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(weaponCard.Color)
	beam.Width0 = 2
	beam.Width1 = 0
	beam.Transparency = NumberSequence.new(0.5)
	beam.Parent = lootDrop

	-- Create point light
	local light = Instance.new("PointLight")
	light.Color = weaponCard.Color
	light.Brightness = 3
	light.Range = 20
	light.Parent = lootDrop

	-- Create UI billboard
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 300, 0, 100)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = lootDrop

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponCard.Name
	nameLabel.TextColor3 = weaponCard.Color
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboardGui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 20)
	rarityLabel.Position = UDim2.new(0, 0, 0, 35)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = weaponCard.Rarity .. " " .. weaponCard.Type
	rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.Parent = billboardGui

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 0, 20)
	levelLabel.Position = UDim2.new(0, 0, 0, 60)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level " .. weaponCard.Level
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextStrokeTransparency = 0.5
	levelLabel.Parent = billboardGui

	-- Create proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = weaponCard.Name
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = lootDrop

	prompt.Triggered:Connect(function(player)
		self:PickupWeapon(player, lootDrop, weapon)
		if weaponModel.Parent then
			weaponModel:Destroy()
		end
		if floatConnection then
			floatConnection:Disconnect()
		end
	end)

	-- Auto-despawn after 60 seconds
	task.delay(60, function()
		if lootDrop.Parent then
			if floatConnection then floatConnection:Disconnect() end
			lootDrop:Destroy()
		end
		if weaponModel.Parent then
			weaponModel:Destroy()
		end
	end)

	print(string.format("[ModularLootGen] Spawned %s %s (Level %d) at %s",
		weaponCard.Rarity, weaponCard.Type, weaponCard.Level, tostring(position)))

	return lootDrop
end

-- ============================================================
-- PICKUP HANDLING
-- ============================================================

function ModularLootGen:PickupWeapon(player, lootDrop, weaponData)
	print(string.format("[ModularLootGen] %s picked up: %s", player.Name, weaponData.Name))

	-- Add to player's weapons (integrate with PlayerStats)
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
	if playerStats then
		-- Add weapon to player's inventory
		playerStats:AddWeapon(weaponData)
		print(string.format("[ModularLootGen] Added %s to %s's inventory", weaponData.Name, player.Name))
	else
		warn("[ModularLootGen] PlayerStats not found for", player.Name)
	end

	-- Give player the actual Tool
	local success = WeaponToolBuilder:GiveWeaponToPlayer(player, weaponData, false)
	if success then
		print(string.format("[ModularLootGen] Gave Tool to %s", player.Name))
	end

	-- Play pickup sound
	local pickupSound = Instance.new("Sound")
	pickupSound.SoundId = "rbxassetid://876939830"
	pickupSound.Volume = 0.5
	pickupSound.Parent = lootDrop
	pickupSound:Play()

	Debris:AddItem(pickupSound, 1)

	-- Destroy loot drop
	lootDrop:Destroy()
end

-- ============================================================
-- SHIELD LOOT SPAWNING
-- ============================================================

function ModularLootGen:SpawnShieldLoot(position, level, forcedRarity)
	-- Generate shield
	local shield = ShieldGenerator.GenerateWithRarity(level, forcedRarity)

	-- Build 3D model
	local shieldModel = ShieldModelBuilder:BuildShield(shield)
	if not shieldModel or not shieldModel.PrimaryPart then
		warn("[ModularLootGen] Failed to build shield model")
		return nil
	end

	shieldModel:PivotTo(CFrame.new(position + Vector3.new(0, 1, 0)))

	-- Make all parts non-collidable and anchored for display
	for _, part in pairs(shieldModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	shieldModel.Parent = workspace

	-- Create invisible collision part for pickup
	local lootDrop = Instance.new("Part")
	lootDrop.Name = "ShieldLoot"
	lootDrop.Size = Vector3.new(2, 2, 2)
	lootDrop.Position = position + Vector3.new(0, 1, 0)
	lootDrop.Anchored = true
	lootDrop.CanCollide = false
	lootDrop.Transparency = 1
	lootDrop.Parent = workspace

	-- Store shield data as attributes
	lootDrop:SetAttribute("ShieldName", shield.Name)
	lootDrop:SetAttribute("Level", shield.Level)
	lootDrop:SetAttribute("Rarity", shield.Rarity)
	lootDrop:SetAttribute("Capacity", shield.Stats.Capacity)
	lootDrop:SetAttribute("RechargeRate", shield.Stats.RechargeRate)
	lootDrop:SetAttribute("RechargeDelay", shield.Stats.RechargeDelay)
	lootDrop:SetAttribute("BreakEffect", shield.Stats.BreakEffect)
	lootDrop:SetAttribute("BreakEffectChance", shield.Stats.BreakEffectChance)

	-- Create floating animation
	local originalY = position.Y + 1
	local floatConnection
	floatConnection = RunService.Heartbeat:Connect(function()
		if not lootDrop.Parent or not shieldModel.Parent then
			if floatConnection then floatConnection:Disconnect() end
			return
		end

		local time = tick()
		local newY = originalY + math.sin(time * 2) * 0.5
		local rotation = CFrame.Angles(0, time * 0.5, 0)

		shieldModel:PivotTo(CFrame.new(position.X, newY, position.Z) * rotation)
		lootDrop.Position = Vector3.new(position.X, newY, position.Z)
	end)

	-- Rarity colors
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Uncommon = Color3.fromRGB(50, 205, 50),
		Rare = Color3.fromRGB(30, 144, 255),
		Epic = Color3.fromRGB(138, 43, 226),
		Legendary = Color3.fromRGB(255, 215, 0)
	}
	local shieldColor = rarityColors[shield.Rarity] or rarityColors.Common

	-- Create beam effect
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = lootDrop
	attachment0.Position = Vector3.new(0, 1, 0)

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = lootDrop
	attachment1.Position = Vector3.new(0, 20, 0)

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Color = ColorSequence.new(shieldColor)
	beam.Width0 = 2
	beam.Width1 = 0
	beam.Transparency = NumberSequence.new(0.5)
	beam.Parent = lootDrop

	-- Create point light
	local light = Instance.new("PointLight")
	light.Color = shieldColor
	light.Brightness = 3
	light.Range = 20
	light.Parent = lootDrop

	-- Create UI billboard
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 300, 0, 100)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = lootDrop

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = shield.Name
	nameLabel.TextColor3 = shieldColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboardGui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 20)
	rarityLabel.Position = UDim2.new(0, 0, 0, 35)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = shield.Rarity .. " Shield"
	rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextStrokeTransparency = 0.5
	rarityLabel.Parent = billboardGui

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 0, 20)
	levelLabel.Position = UDim2.new(0, 0, 0, 60)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = string.format("Level %d | %d Capacity", shield.Level, shield.Stats.Capacity)
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextScaled = true
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextStrokeTransparency = 0.5
	levelLabel.Parent = billboardGui

	-- Create proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = shield.Name
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = lootDrop

	prompt.Triggered:Connect(function(player)
		self:PickupShield(player, lootDrop, shield)
		if shieldModel.Parent then
			shieldModel:Destroy()
		end
		if floatConnection then
			floatConnection:Disconnect()
		end
	end)

	-- Auto-despawn after 60 seconds
	task.delay(60, function()
		if lootDrop.Parent then
			if floatConnection then floatConnection:Disconnect() end
			lootDrop:Destroy()
		end
		if shieldModel.Parent then
			shieldModel:Destroy()
		end
	end)

	print(string.format("[ModularLootGen] Spawned %s Shield (Level %d, Capacity: %d) at %s",
		shield.Rarity, shield.Level, shield.Stats.Capacity, tostring(position)))

	return lootDrop
end

-- ============================================================
-- SHIELD PICKUP HANDLING
-- ============================================================

function ModularLootGen:PickupShield(player, lootDrop, shieldData)
	print(string.format("[ModularLootGen] %s attempting to pick up: %s", player.Name, shieldData.Name))

	-- Get player inventory
	local inventory = PlayerInventory.GetInventory(player)

	-- Check if player already has a shield
	if inventory:HasShield() then
		warn(string.format("[ModularLootGen] %s already has a shield equipped. Drop current shield first (X key)", player.Name))

		-- Show feedback to player
		if player and player:FindFirstChild("PlayerGui") then
			local message = Instance.new("Message")
			message.Text = "Shield slot full! Press X to drop current shield"
			message.Parent = player.PlayerGui
			Debris:AddItem(message, 3)
		end

		return
	end

	-- Add to inventory
	local success = inventory:EquipShield(shieldData)

	if success then
		-- Equip shield visually and functionally
		if _G.EquipPlayerShield then
			_G.EquipPlayerShield(player, shieldData)
		end

		print(string.format("[ModularLootGen] Equipped %s to %s", shieldData.Name, player.Name))

		-- Play pickup sound
		local pickupSound = Instance.new("Sound")
		pickupSound.SoundId = "rbxassetid://876939830"
		pickupSound.Volume = 0.5
		pickupSound.Parent = lootDrop
		pickupSound:Play()

		Debris:AddItem(pickupSound, 1)

		-- Destroy loot drop
		lootDrop:Destroy()
	else
		warn("[ModularLootGen] Failed to equip shield to player")
	end
end

-- ============================================================
-- ENEMY DROP INTEGRATION
-- ============================================================

function ModularLootGen:SpawnLootFromEnemy(enemy, playerLevel, floorNumber)
	if not enemy or not enemy.PrimaryPart then return end

	local position = enemy.PrimaryPart.Position
	local enemyLevel = enemy:GetAttribute("Level") or floorNumber or 1

	-- FLOOR 1: Only drop health/ammo (no weapons until Floor 2)
	if (floorNumber or 1) == 1 then
		print("[ModularLootGen] Floor 1 - No weapon drops (health/ammo only)")
		PickupSystem.SpawnPickupsFromEnemy(position, floorNumber, enemy.Parent)
		return
	end

	-- ALL FLOORS: Always roll for health/ammo pickups
	PickupSystem.SpawnPickupsFromEnemy(position, floorNumber, enemy.Parent)

	-- Drop chance based on floor number (increases with progression)
	local baseDropChance = 0.3
	local floorBonus = (floorNumber or 1) * 0.005 -- +0.5% per floor
	local dropChance = math.min(0.8, baseDropChance + floorBonus)

	if math.random() < dropChance then
		-- Level of dropped weapon is based on floor and enemy level
		local lootLevel = math.floor((playerLevel + enemyLevel + (floorNumber or 1)) / 3)

		-- Rare enemies have better loot
		local forcedRarity = nil
		local enemyType = enemy:GetAttribute("Type")
		if enemyType == "Rare" then
			-- 50% chance for Epic+
			if math.random() < 0.5 then
				forcedRarity = math.random() < 0.8 and "Rare" or "Epic"
			end
		elseif enemyType == "Boss" then
			-- Bosses always drop Epic+
			forcedRarity = math.random() < 0.7 and "Epic" or "Legendary"
		end

		self:SpawnWeaponLoot(position, lootLevel, forcedRarity)
	end

	-- Shield drops (lower chance than weapons, only Floor 3+)
	if (floorNumber or 1) >= 3 then
		local shieldDropChance = 0.10 -- 10% base chance for shields
		local floorBonus = (floorNumber or 1) * 0.002 -- +0.2% per floor
		shieldDropChance = math.min(0.25, shieldDropChance + floorBonus)

		if math.random() < shieldDropChance then
			-- Level of dropped shield is based on floor and enemy level
			local lootLevel = math.floor((playerLevel + enemyLevel + (floorNumber or 1)) / 3)

			-- Rare enemies have better shield drops
			local forcedRarity = nil
			local enemyType = enemy:GetAttribute("Type")
			if enemyType == "Rare" then
				-- 40% chance for Rare+
				if math.random() < 0.4 then
					forcedRarity = math.random() < 0.7 and "Rare" or "Epic"
				end
			elseif enemyType == "Boss" then
				-- Bosses always drop Epic+ shields
				forcedRarity = math.random() < 0.6 and "Epic" or "Legendary"
			end

			-- Spawn shield slightly offset from weapon drop
			local shieldPos = position + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
			self:SpawnShieldLoot(shieldPos, lootLevel, forcedRarity)
		end
	end
end

return ModularLootGen
