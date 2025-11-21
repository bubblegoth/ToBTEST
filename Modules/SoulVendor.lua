--[[
	SoulVendor.lua
	NPC Soul Vendor for purchasing permanent upgrades in the Church (Floor 0)
	Uses ChurchSystem for upgrade logic
	Part of the Gothic FPS Roguelite Dungeon System

	SETUP INSTRUCTIONS:
	1. Place this script inside the SoulVendor NPC model in workspace
	2. NPC model should have a Humanoid and a primary part (HumanoidRootPart)
	3. Optionally add a ClickDetector or ProximityPrompt for interaction
	4. Create a GUI for displaying upgrades (or use print statements for testing)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module references (adjust paths as needed)
local ChurchSystem = require(ReplicatedStorage.Modules.ChurchSystem)
local DungeonConfig = require(ReplicatedStorage.Modules.DungeonConfig)

-- Script module table (for potential RemoteEvent callbacks)
local SoulVendor = {}

-- NPC Configuration
-- Wait for script to be properly parented to the vendor model
repeat task.wait() until script.Parent and script.Parent:IsA("Model")

local vendor = script.Parent -- The NPC model
local vendorName = "Soul Keeper"
local vendorDialogue = {
	Greeting = "Welcome, lost soul. Spend your Souls wisely...",
	NoSouls = "You have no Souls to offer. Return when you've harvested more.",
	PurchaseSuccess = "Your power grows. May it serve you well in the depths.",
	PurchaseFailed = "You lack the Souls required for this blessing.",
	Farewell = "Go forth into darkness, wanderer.",
}

-- ============================================================
-- NPC SETUP
-- ============================================================

-- Add name tag above NPC
local function setupNameTag()
	local head = vendor:FindFirstChild("Head")
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
		textLabel.Text = vendorName
		textLabel.TextColor3 = Color3.new(0.8, 0.6, 1) -- Purple/ghostly color
		textLabel.TextScaled = true
		textLabel.Font = Enum.Font.GothamBold
		textLabel.Parent = billboard
	end
end

setupNameTag()

-- ============================================================
-- INTERACTION HANDLER
-- ============================================================

local function openUpgradeShop(player)
	-- Get player stats using global function (set by PlayerDataManager)
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)

	if not playerStats then
		warn("PlayerStats not found for", player.Name, "- Is PlayerDataManager running?")
		return
	end

	-- Check if player is on Floor 0 (Church)
	local currentFloor = playerStats:GetCurrentFloor()

	if not ChurchSystem.IsChurchAccessible(currentFloor) then
		-- Player tried to access shop from dungeon
		print(player.Name, "attempted to access Soul Vendor outside Church")
		return
	end

	-- Get player's Soul count
	local souls = playerStats:GetSouls()

	-- Display greeting
	print(string.format("[%s] %s", vendorName, vendorDialogue.Greeting))
	print(string.format("You have %d Souls.", souls))

	-- Get available upgrades
	local availableUpgrades = ChurchSystem.GetAvailableUpgrades(playerStats)

	-- Display shop (for now, print to console - you'll want to create a GUI)
	print("\n=== SOUL UPGRADES ===")

	for i, upgrade in ipairs(availableUpgrades) do
		local status = ""
		if upgrade.IsMaxed then
			status = "[MAX]"
		elseif upgrade.CanAfford then
			status = "[AVAILABLE]"
		else
			status = "[LOCKED]"
		end

		print(string.format(
			"%d. %s %s - Level %d/%d - Cost: %s Souls",
			i,
			status,
			upgrade.Name,
			upgrade.CurrentLevel,
			upgrade.MaxLevel,
			upgrade.NextCost or "MAX"
		))
	end

	-- TODO: Create actual GUI interface for upgrade selection
	-- For now, you can test purchases via server console:
	-- ChurchSystem.PurchaseUpgrade(playerStats, "GunDamage")
end

-- ============================================================
-- CLICK DETECTION
-- ============================================================

-- Add ClickDetector if not present
local clickDetector = vendor:FindFirstChildOfClass("ClickDetector", true)
if not clickDetector then
	local primaryPart = vendor.PrimaryPart or vendor:FindFirstChild("HumanoidRootPart")
	if primaryPart then
		clickDetector = Instance.new("ClickDetector")
		clickDetector.MaxActivationDistance = 15
		clickDetector.Parent = primaryPart
	end
end

if clickDetector then
	clickDetector.MouseClick:Connect(function(player)
		openUpgradeShop(player)
	end)
end

-- ============================================================
-- PROXIMITY PROMPT (Alternative interaction method)
-- ============================================================

local function setupProximityPrompt()
	local primaryPart = vendor.PrimaryPart or vendor:FindFirstChild("HumanoidRootPart")
	if not primaryPart then return end

	if not primaryPart:FindFirstChild("VendorPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "VendorPrompt"
		prompt.ActionText = "Talk to Soul Keeper"
		prompt.ObjectText = "Spend Souls on Upgrades"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.Parent = primaryPart

		prompt.Triggered:Connect(function(player)
			openUpgradeShop(player)
		end)
	end
end

setupProximityPrompt()

-- ============================================================
-- PURCHASE FUNCTION (Called from GUI or RemoteEvent)
-- ============================================================

function SoulVendor.PurchaseUpgrade(player, upgradeID)
	local playerStats = _G.GetPlayerStats and _G.GetPlayerStats(player)

	if not playerStats then
		return false, "Player stats not found"
	end

	-- Check if in Church
	if not ChurchSystem.IsChurchAccessible(playerStats:GetCurrentFloor()) then
		return false, "Can only purchase upgrades in the Church"
	end

	-- Attempt purchase
	local success, message = ChurchSystem.PurchaseUpgrade(playerStats, upgradeID)

	-- Update player values after purchase
	if success and _G.UpdatePlayerValues then
		_G.UpdatePlayerValues(player)
	end

	if success then
		print(string.format("[%s] %s", vendorName, vendorDialogue.PurchaseSuccess))
		print(message)
	else
		print(string.format("[%s] %s", vendorName, vendorDialogue.PurchaseFailed))
		print(message)
	end

	return success, message
end

-- ============================================================
-- REMOTE EVENT SETUP (For GUI communication)
-- ============================================================

-- Create RemoteEvent for client-server communication
local vendorRemote = ReplicatedStorage:FindFirstChild("SoulVendorRemote")
if not vendorRemote then
	vendorRemote = Instance.new("RemoteEvent")
	vendorRemote.Name = "SoulVendorRemote"
	vendorRemote.Parent = ReplicatedStorage
end

-- Handle purchase requests from client
vendorRemote.OnServerEvent:Connect(function(player, action, upgradeID)
	if action == "OpenShop" then
		openUpgradeShop(player)
	elseif action == "Purchase" then
		local success, message = SoulVendor.PurchaseUpgrade(player, upgradeID)
		vendorRemote:FireClient(player, "PurchaseResult", success, message)
	elseif action == "GetUpgrades" then
		local playerStats = player:FindFirstChild("PlayerStats")
		if playerStats then
			local upgrades = ChurchSystem.GetAvailableUpgrades(playerStats)
			vendorRemote:FireClient(player, "UpgradeList", upgrades)
		end
	end
end)

print("Soul Vendor initialized:", vendorName)

return SoulVendor
