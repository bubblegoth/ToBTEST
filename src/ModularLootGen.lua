--[[
	ModularLootGen.lua
	Handles weapon loot drops with visual effects
	Gothic FPS Roguelite - Integrates with dungeon system
]]

local ModularLootGen = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WeaponGenerator = require(script.Parent.WeaponGenerator)
local WeaponModelBuilder = require(script.Parent.WeaponModelBuilder)

-- ============================================================
-- WEAPON LOOT SPAWNING
-- ============================================================

function ModularLootGen:SpawnWeaponLoot(position, level, forcedRarity)
	-- Generate weapon
	local weapon = WeaponGenerator:GenerateWeapon(level, nil, forcedRarity)
	local weaponCard = WeaponGenerator:GetWeaponCard(weapon)

	-- Build 3D model
	local weaponModel = WeaponModelBuilder:BuildWeapon(weapon)
	weaponModel:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 3, 0)))

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
	lootDrop.Position = position + Vector3.new(0, 3, 0)
	lootDrop.Anchored = true
	lootDrop.CanCollide = false
	lootDrop.Transparency = 1
	lootDrop.Parent = workspace

	-- Store weapon data
	lootDrop:SetAttribute("WeaponData", game:GetService("HttpService"):JSONEncode(weapon))

	-- Create floating animation
	local originalY = position.Y + 3
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
-- ENEMY DROP INTEGRATION
-- ============================================================

function ModularLootGen:SpawnLootFromEnemy(enemy, playerLevel, floorNumber)
	if not enemy or not enemy.PrimaryPart then return end

	local position = enemy.PrimaryPart.Position
	local enemyLevel = enemy:GetAttribute("Level") or floorNumber or 1

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
end

return ModularLootGen
