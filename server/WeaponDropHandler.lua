--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponDropHandler
Location: ServerScriptService/
Description: Handles weapon dropping and pickup for roguelite gameplay.
             Players can drop weapons (Q key), pick up dropped weapons,
             and swap weapons in their inventory.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

print("[WeaponDrop] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WeaponGenerator = require(Modules:WaitForChild("WeaponGenerator"))
local WeaponToolBuilder = require(Modules:WaitForChild("WeaponToolBuilder"))
local WeaponModelBuilder = require(Modules:WaitForChild("WeaponModelBuilder"))
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))
local ModularLootGen = require(Modules:WaitForChild("ModularLootGen"))

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	DropDistance = 3, -- Studs in front of player
	DropLifetime = 300, -- 5 minutes before auto-cleanup
	PickupDistance = 8, -- Studs to show proximity prompt
	BobAmplitude = 0.3, -- Floating animation
	BobSpeed = 2, -- Floating speed
	RotationSpeed = 30, -- Degrees per second
}

-- ════════════════════════════════════════════════════════════════════════════
-- DROPPED WEAPON CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createDroppedWeaponModel(weaponData, position)
	-- Build the weapon visual model
	local weaponModel = WeaponModelBuilder:BuildWeapon(weaponData)

	if not weaponModel or not weaponModel.PrimaryPart then
		warn("[WeaponDrop] Failed to build weapon model")
		return nil
	end

	-- Create container model
	local droppedModel = Instance.new("Model")
	droppedModel.Name = "DroppedWeapon"

	-- Move weapon model into container
	weaponModel.Parent = droppedModel

	-- Set primary part
	droppedModel.PrimaryPart = weaponModel.PrimaryPart

	-- Make all parts non-collidable but anchored
	for _, part in ipairs(weaponModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = true
		end
	end

	-- Position the model
	droppedModel:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0))

	-- Store weapon data as attributes
	droppedModel:SetAttribute("WeaponName", weaponData.Name)
	droppedModel:SetAttribute("WeaponType", weaponData.Parts.Base.Name)
	droppedModel:SetAttribute("Level", weaponData.Level)
	droppedModel:SetAttribute("Rarity", weaponData.Rarity)
	droppedModel:SetAttribute("Damage", weaponData.Damage)
	droppedModel:SetAttribute("DPS", weaponData.DPS)

	-- Create proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = string.format("[Lv.%d %s] %s", weaponData.Level, weaponData.Rarity, weaponData.Name)
	prompt.MaxActivationDistance = Config.PickupDistance
	prompt.HoldDuration = 0.3
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = droppedModel.PrimaryPart

	-- Add highlight for visibility
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0.3

	-- Color based on rarity
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Uncommon = Color3.fromRGB(50, 205, 50),
		Rare = Color3.fromRGB(30, 144, 255),
		Epic = Color3.fromRGB(138, 43, 226),
		Legendary = Color3.fromRGB(255, 215, 0),
		Mythic = Color3.fromRGB(255, 50, 50)
	}
	highlight.FillColor = rarityColors[weaponData.Rarity] or rarityColors.Common
	highlight.OutlineColor = highlight.FillColor
	highlight.Parent = droppedModel

	return droppedModel, prompt
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLOATING ANIMATION
-- ════════════════════════════════════════════════════════════════════════════

local function animateDroppedWeapon(model)
	local startY = model:GetPivot().Position.Y
	local startTime = tick()

	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		if not model or not model.Parent then
			connection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local bobOffset = math.sin(elapsed * Config.BobSpeed) * Config.BobAmplitude
		local rotation = CFrame.Angles(0, math.rad(elapsed * Config.RotationSpeed), 0)

		local currentCFrame = model:GetPivot()
		local newY = startY + bobOffset
		local newCFrame = CFrame.new(currentCFrame.Position.X, newY, currentCFrame.Position.Z) * rotation

		model:PivotTo(newCFrame)
	end)

	-- Store connection for cleanup
	model:SetAttribute("AnimationConnection", tostring(connection))

	return connection
end

-- ════════════════════════════════════════════════════════════════════════════
-- DROP WEAPON
-- ════════════════════════════════════════════════════════════════════════════

local function dropWeapon(player, tool)
	if not tool or not tool:IsA("Tool") then
		warn("[WeaponDrop] Invalid tool provided")
		return false
	end

	-- Get weapon data from tool
	local weaponData = WeaponToolBuilder:GetWeaponDataFromTool(tool)

	if not weaponData or not weaponData.Parts then
		warn("[WeaponDrop] Tool has no valid weapon data")
		return false
	end

	-- Get inventory and remove weapon data from current slot
	local inventory = PlayerInventory.GetInventory(player)
	local currentWeaponData = inventory:GetCurrentWeapon()

	if not currentWeaponData then
		warn("[WeaponDrop] No weapon in current inventory slot")
		return false
	end

	-- Remove from inventory
	inventory:RemoveWeapon(inventory.CurrentWeaponIndex)

	-- Clear equipped tool reference
	if inventory.EquippedWeaponTool == tool then
		inventory.EquippedWeaponTool = nil
	end

	local character = player.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Calculate drop position (in front of player)
	local dropPosition = rootPart.Position + (rootPart.CFrame.LookVector * Config.DropDistance)

	-- Use ModularLootGen to spawn the dropped weapon (includes tap/hold pickup mechanics)
	ModularLootGen:SpawnWeaponLoot(dropPosition, weaponData.Level, weaponData.Rarity)

	-- Destroy the original tool
	tool:Destroy()

	print(string.format("[WeaponDrop] %s dropped %s (removed from inventory slot %d)", player.Name, weaponData.Name, inventory.CurrentWeaponIndex))
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP WEAPON
-- ════════════════════════════════════════════════════════════════════════════

function pickupWeapon(player, droppedModel, weaponData)
	if not droppedModel or not droppedModel.Parent then return end
	if not player or not player.Parent then return end

	-- Reconstruct full weapon data (droppedModel only has basic attributes)
	local fullWeaponData = WeaponGenerator:GenerateWeapon(
		weaponData.Level,
		weaponData.WeaponType,
		weaponData.Rarity
	)

	-- Copy over exact stats from dropped weapon to preserve it
	fullWeaponData.Name = weaponData.Name
	fullWeaponData.Damage = weaponData.Damage
	fullWeaponData.DPS = weaponData.DPS

	-- Give weapon to player
	local success = WeaponToolBuilder:GiveWeaponToPlayer(player, fullWeaponData, true)

	if success then
		print(string.format("[WeaponDrop] %s picked up %s", player.Name, fullWeaponData.Name))

		-- Destroy dropped model
		droppedModel:Destroy()
	else
		warn("[WeaponDrop] Failed to give weapon to player")
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTE EVENT SETUP
-- ════════════════════════════════════════════════════════════════════════════

-- Create remote event for drop requests
local dropEvent = Instance.new("RemoteEvent")
dropEvent.Name = "DropWeapon"
dropEvent.Parent = ReplicatedStorage

dropEvent.OnServerEvent:Connect(function(player, tool)
	if not tool or not tool.Parent == player.Character then
		warn("[WeaponDrop] Invalid drop request from", player.Name)
		return
	end

	dropWeapon(player, tool)
end)

print("[WeaponDrop] ═══════════════════════════════════════")
print("[WeaponDrop] Weapon Drop System Active")
print("[WeaponDrop] Press Q to drop equipped weapon")
print("[WeaponDrop] Press E to pick up dropped weapons")
print("[WeaponDrop] ═══════════════════════════════════════")
