--[[
════════════════════════════════════════════════════════════════════════════════
Module: NPCSpawner
Location: ServerScriptService/
Description: Spawns Soul Vendor NPC in the Church (Floor 0) on server start.
             Gothic FPS Roguelite - Church upgrade vendor.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

print("[NPCSpawner] Initializing...")

-- Wait for modules to load
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
if not Modules then
	warn("[NPCSpawner] Modules folder not found in ReplicatedStorage!")
	return
end

local MobGenerator = require(Modules:WaitForChild("MobGenerator"))
local ChurchSystem = require(Modules:WaitForChild("ChurchSystem"))

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	VendorSpawnName = "SoulVendorSpawn", -- Part in workspace to spawn at
	DefaultPosition = CFrame.new(0, 5, 0), -- Fallback if spawn point not found
	UpgradeChoiceCount = 3, -- Number of upgrades to present per interaction
}

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTE EVENT SETUP
-- ════════════════════════════════════════════════════════════════════════════

local SoulVendorRemote = ReplicatedStorage:FindFirstChild("SoulVendorRemote")
if not SoulVendorRemote then
	SoulVendorRemote = Instance.new("RemoteEvent")
	SoulVendorRemote.Name = "SoulVendorRemote"
	SoulVendorRemote.Parent = ReplicatedStorage
	print("[NPCSpawner] Created SoulVendorRemote")
end

-- ════════════════════════════════════════════════════════════════════════════
-- UPGRADE SELECTION LOGIC
-- ════════════════════════════════════════════════════════════════════════════

local function formatBonus(value, statKey)
	-- Percentage stats
	if statKey == "GunDamage" or statKey == "FireRate" or statKey == "Accuracy" or
	   statKey == "CritDamage" or statKey == "ElementalChance" or statKey == "ElementalDamage" or
	   statKey == "RecoilReduction" or statKey == "ReloadSpeed" or statKey == "MeleeDamage" or
	   statKey == "GrenadeDamage" or statKey == "ShieldRechargeRate" then
		return string.format("+%.1f%%", value * 100)
	end

	-- Flat value stats
	if statKey == "MaxHealth" or statKey == "ShieldCapacity" then
		return string.format("+%.0f", value)
	end

	-- Default
	return tostring(value)
end

local function selectRandomUpgrades(playerStats, count)
	local allUpgrades = ChurchSystem.GetAvailableUpgrades(playerStats)
	local selected = {}

	-- Filter out maxed upgrades
	local available = {}
	for _, upgrade in ipairs(allUpgrades) do
		if not upgrade.IsMaxed then
			table.insert(available, upgrade)
		end
	end

	-- If fewer available than requested, return all available
	if #available <= count then
		return available
	end

	-- Randomly select upgrades
	local indices = {}
	for i = 1, #available do
		table.insert(indices, i)
	end

	-- Fisher-Yates shuffle
	for i = #indices, 2, -1 do
		local j = math.random(i)
		indices[i], indices[j] = indices[j], indices[i]
	end

	-- Take first 'count' upgrades
	for i = 1, count do
		table.insert(selected, available[indices[i]])
	end

	return selected
end

local function prepareUpgradeData(upgrade)
	return {
		ID = upgrade.ID,
		Name = upgrade.Name,
		Description = upgrade.Description,
		CurrentLevel = upgrade.CurrentLevel,
		Cost = upgrade.NextCost,
		BonusText = formatBonus(upgrade.BonusPerLevel, upgrade.StatKey),
		CanAfford = upgrade.CanAfford,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- SPAWN SOUL VENDOR
-- ════════════════════════════════════════════════════════════════════════════

local function SpawnSoulVendor()
	-- Check if already exists (avoid duplicates)
	if workspace:FindFirstChild("Soul Keeper") then
		print("[NPCSpawner] Soul Vendor already exists, skipping spawn")
		return workspace:FindFirstChild("Soul Keeper")
	end

	print("[NPCSpawner] Generating Soul Vendor NPC using MobGenerator...")

	-- Generate Soul Vendor with ghostly/mystical appearance using MobGenerator
	local vendorModel, stats = MobGenerator.Generate({
		name = "Soul Keeper",
		color = Color3.fromRGB(150, 100, 200), -- Purple/ghostly color
		material = Enum.Material.Neon, -- Ethereal glow
		scale = 1.2, -- Slightly larger than normal mobs
	})

	if not vendorModel then
		warn("[NPCSpawner] Failed to generate Soul Vendor!")
		return nil
	end

	-- Position vendor in Church (ON TOP of spawn part)
	local vendorSpawnPoint = workspace:FindFirstChild(Config.VendorSpawnName)
	if vendorSpawnPoint and vendorSpawnPoint:IsA("BasePart") then
		-- Parent to workspace first so physics can settle
		vendorModel.Parent = workspace

		local rootPart = vendorModel:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			warn("[NPCSpawner] No HumanoidRootPart found in vendor model")
			return nil
		end

		-- Position temporarily to let physics settle and get accurate measurements
		vendorModel:SetPrimaryPartCFrame(CFrame.new(0, 100, 0))
		task.wait(0.1)

		-- Get bounding box to find actual bottom of model
		local modelCFrame, modelSize = vendorModel:GetBoundingBox()
		local modelBottomY = modelCFrame.Y - (modelSize.Y / 2) -- Actual lowest point
		local rootPartY = rootPart.Position.Y

		-- Calculate offset: how far root part is above model's bottom
		local bottomOffset = rootPartY - modelBottomY

		-- Calculate where top of spawn part is
		local spawnPartTop = vendorSpawnPoint.Position.Y + (vendorSpawnPoint.Size.Y / 2)

		-- Position root part so model's bottom sits exactly on spawn part top
		local targetY = spawnPartTop + bottomOffset
		local targetPosition = Vector3.new(
			vendorSpawnPoint.Position.X,
			targetY,
			vendorSpawnPoint.Position.Z
		)

		-- Set final position with rotation from spawn part
		vendorModel:SetPrimaryPartCFrame(CFrame.new(targetPosition) * (vendorSpawnPoint.CFrame - vendorSpawnPoint.Position))

		print(string.format("[NPCSpawner] Soul Vendor positioned: ModelBottom=%.2f, RootPart=%.2f, Offset=%.2f, TargetY=%.2f",
			modelBottomY, rootPartY, bottomOffset, targetY))
	else
		vendorModel.Parent = workspace
		vendorModel:SetPrimaryPartCFrame(Config.DefaultPosition)
		warn("[NPCSpawner]", Config.VendorSpawnName, "not found, using default position")
	end

	-- Remove IsEnemy attribute (MobGenerator sets this, but vendor is not an enemy)
	vendorModel:SetAttribute("IsEnemy", nil)

	-- Make vendor invincible and stationary
	local humanoid = vendorModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 9999
		humanoid.Health = 9999
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	-- Anchor root part to keep vendor in place
	local rootPart = vendorModel:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.Anchored = true
	end

	-- Set vendor parts to non-collidable with players (but visible)
	for _, part in ipairs(vendorModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			part.Anchored = false
			part.CanCollide = false
		end
	end

	-- Add name tag
	local head = vendorModel:FindFirstChild("Head")
	if head and not head:FindFirstChild("NameTag") then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "NameTag"
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "Soul Keeper"
		textLabel.TextColor3 = Color3.fromRGB(200, 150, 255) -- Purple/ghostly
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.TextStrokeTransparency = 0.5
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.Parent = billboard
	end

	-- Add proximity prompt for interaction
	if rootPart and not rootPart:FindFirstChild("VendorPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "VendorPrompt"
		prompt.ActionText = "Talk"
		prompt.ObjectText = "Soul Keeper - Spend Souls on Upgrades"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = rootPart

		-- Handle interaction - show 3 random upgrades
		prompt.Triggered:Connect(function(player)
			local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
			if not playerStats then
				warn("[Soul Keeper] PlayerStats not found for", player.Name)
				return
			end

			-- Check if player is in Church (Floor 0)
			local currentFloor = playerStats:GetCurrentFloor()
			if currentFloor ~= 0 then
				print("[Soul Keeper]", player.Name, "tried to access vendor outside Church")
				return
			end

			-- Select 3 random upgrades
			local selectedUpgrades = selectRandomUpgrades(playerStats, Config.UpgradeChoiceCount)
			local upgradeData = {}

			for _, upgrade in ipairs(selectedUpgrades) do
				table.insert(upgradeData, prepareUpgradeData(upgrade))
			end

			-- Send to client
			local souls = playerStats:GetSouls()
			print(string.format("[Soul Keeper] %s opened shop (Souls: %d, Options: %d)",
				player.Name, souls, #upgradeData))
			SoulVendorRemote:FireClient(player, "ShowUpgrades", upgradeData, souls)
		end)
	end

	print("[NPCSpawner] ✓ Soul Vendor spawned successfully:", vendorModel.Name)
	return vendorModel
end

-- ════════════════════════════════════════════════════════════════════════════
-- PURCHASE HANDLER
-- ════════════════════════════════════════════════════════════════════════════

SoulVendorRemote.OnServerEvent:Connect(function(player, action, upgradeID)
	if action == "Purchase" then
		local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
		if not playerStats then
			warn("[Soul Keeper] PlayerStats not found for", player.Name)
			SoulVendorRemote:FireClient(player, "PurchaseResult", false, "Player data not found")
			return
		end

		-- Check if in Church
		if playerStats:GetCurrentFloor() ~= 0 then
			SoulVendorRemote:FireClient(player, "PurchaseResult", false, "Can only purchase in Church")
			return
		end

		-- Attempt purchase using ChurchSystem
		local success, message = ChurchSystem.PurchaseUpgrade(playerStats, upgradeID)

		if success then
			print(string.format("[Soul Keeper] %s purchased %s", player.Name, upgradeID))

			-- Update player values
			if _G.UpdatePlayerValues then
				_G.UpdatePlayerValues(player)
			end

			-- Send new upgrade options
			local selectedUpgrades = selectRandomUpgrades(playerStats, Config.UpgradeChoiceCount)
			local upgradeData = {}
			for _, upgrade in ipairs(selectedUpgrades) do
				table.insert(upgradeData, prepareUpgradeData(upgrade))
			end

			local souls = playerStats:GetSouls()
			SoulVendorRemote:FireClient(player, "ShowUpgrades", upgradeData, souls)
			SoulVendorRemote:FireClient(player, "PurchaseResult", true, message)
		else
			print(string.format("[Soul Keeper] %s purchase failed: %s", player.Name, message))
			SoulVendorRemote:FireClient(player, "PurchaseResult", false, message)
		end

	elseif action == "RequestUpgrades" then
		-- Player requested updated upgrade list
		local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
		if playerStats then
			local selectedUpgrades = selectRandomUpgrades(playerStats, Config.UpgradeChoiceCount)
			local upgradeData = {}
			for _, upgrade in ipairs(selectedUpgrades) do
				table.insert(upgradeData, prepareUpgradeData(upgrade))
			end

			local souls = playerStats:GetSouls()
			SoulVendorRemote:FireClient(player, "ShowUpgrades", upgradeData, souls)
		end
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZE ON SERVER START
-- ════════════════════════════════════════════════════════════════════════════

local function Initialize()
	-- Wait for workspace to settle
	task.wait(2)

	-- Spawn Soul Vendor
	local success, result = pcall(SpawnSoulVendor)

	if not success then
		warn("[NPCSpawner] Error spawning Soul Vendor:", result)
	end

	print("[NPCSpawner] Initialization complete")
end

-- Run initialization
Initialize()

print("[NPCSpawner] ═══════════════════════════════════════")
print("[NPCSpawner] NPC Spawner Active")
print("[NPCSpawner] Soul Vendor spawned in Church (Floor 0)")
print("[NPCSpawner] ═══════════════════════════════════════")
