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

local NPCGenerator = require(Modules:WaitForChild("NPCGenerator"))
local NPCConfig = require(Modules:WaitForChild("NPCConfig"))

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	VendorSpawnName = "SoulVendorSpawn", -- Part in workspace to spawn at
	DefaultPosition = CFrame.new(0, 5, 0), -- Fallback if spawn point not found
}

-- ════════════════════════════════════════════════════════════════════════════
-- SPAWN SOUL VENDOR
-- ════════════════════════════════════════════════════════════════════════════

local function SpawnSoulVendor()
	-- Check if already exists (avoid duplicates)
	if workspace:FindFirstChild("Soul Keeper") then
		print("[NPCSpawner] Soul Vendor already exists, skipping spawn")
		return workspace:FindFirstChild("Soul Keeper")
	end

	print("[NPCSpawner] Generating Soul Vendor NPC...")

	-- Generate Soul Vendor data
	local vendorData = NPCGenerator.GenerateNPC("SOUL_VENDOR")
	if not vendorData then
		warn("[NPCSpawner] Failed to generate Soul Vendor data!")
		return nil
	end

	-- Build the actual model
	local vendorModel = NPCGenerator.BuildNPCModel(vendorData, workspace)
	if not vendorModel then
		warn("[NPCSpawner] Failed to build Soul Vendor model!")
		return nil
	end

	-- Position vendor in Church (ON TOP of spawn part)
	local vendorSpawnPoint = workspace:FindFirstChild(Config.VendorSpawnName)
	if vendorSpawnPoint and vendorSpawnPoint:IsA("BasePart") then
		-- Calculate position on top of the spawn part
		local spawnPartTop = vendorSpawnPoint.Position.Y + (vendorSpawnPoint.Size.Y / 2)

		-- Get vendor's HumanoidRootPart to calculate proper height
		local rootPart = vendorModel:FindFirstChild("HumanoidRootPart")
		local vendorHeightOffset = rootPart and (rootPart.Size.Y / 2) or 3

		-- Position vendor on top of spawn part
		local targetPosition = Vector3.new(
			vendorSpawnPoint.Position.X,
			spawnPartTop + vendorHeightOffset,
			vendorSpawnPoint.Position.Z
		)

		vendorModel:SetPrimaryPartCFrame(CFrame.new(targetPosition) * (vendorSpawnPoint.CFrame - vendorSpawnPoint.Position))
		print("[NPCSpawner] Soul Vendor positioned ON TOP of", Config.VendorSpawnName)
	else
		vendorModel:SetPrimaryPartCFrame(Config.DefaultPosition)
		warn("[NPCSpawner]", Config.VendorSpawnName, "not found, using default position")
	end

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

		-- Handle interaction (temporary print for testing)
		prompt.Triggered:Connect(function(player)
			local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)
			if playerStats then
				local souls = playerStats:GetSouls()
				print(string.format("[Soul Keeper] %s interacted (Souls: %d)", player.Name, souls))
				-- TODO: Open upgrade GUI here
			else
				warn("[Soul Keeper] PlayerStats not found for", player.Name)
			end
		end)
	end

	print("[NPCSpawner] ✓ Soul Vendor spawned successfully:", vendorModel.Name)
	return vendorModel
end

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
