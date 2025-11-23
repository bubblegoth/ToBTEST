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
local HttpService = game:GetService("HttpService")

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

	-- Store complete weapon data as JSON to preserve EVERYTHING
	local weaponDataJSON = HttpService:JSONEncode(weaponData)
	droppedModel:SetAttribute("WeaponDataJSON", weaponDataJSON)

	-- Store basic attributes for display (used by proximity prompt)
	droppedModel:SetAttribute("WeaponName", weaponData.Name)
	droppedModel:SetAttribute("Level", weaponData.Level)
	droppedModel:SetAttribute("Rarity", weaponData.Rarity)

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

	-- DEBUG: Log current ammo being saved
	print(string.format("[WeaponDrop] Dropping weapon - CurrentAmmo: %s, Capacity: %s",
		tostring(weaponData.CurrentAmmo), tostring(weaponData.Capacity)))

	local character = player.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Calculate drop position (in front of player)
	local dropPosition = rootPart.Position + (rootPart.CFrame.LookVector * Config.DropDistance)

	-- Create the dropped weapon model with proximity prompt
	local droppedModel, prompt = createDroppedWeaponModel(weaponData, dropPosition)

	if not droppedModel then
		warn("[WeaponDrop] Failed to create dropped weapon model")
		return false
	end

	-- Parent to workspace
	droppedModel.Parent = workspace

	-- Start floating animation
	animateDroppedWeapon(droppedModel)

	-- Auto-cleanup after lifetime
	game:GetService("Debris"):AddItem(droppedModel, Config.DropLifetime)

	-- Handle pickup
	prompt.Triggered:Connect(function(triggeringPlayer)
		if not droppedModel.Parent then return end
		pickupWeapon(triggeringPlayer, droppedModel)
	end)

	-- Get inventory and try to unequip from slot (if tracked in inventory system)
	local inventory = PlayerInventory.GetInventory(player)
	if inventory then
		local currentSlot = inventory.CurrentWeaponSlot
		local currentWeaponData = inventory:GetEquippedWeapon(currentSlot)

		-- Only unequip from slot if weapon is registered there
		if currentWeaponData then
			inventory:UnequipWeaponFromSlot(currentSlot)
		end

		-- Clear equipped tool reference
		if inventory.EquippedWeaponTool == tool then
			inventory.EquippedWeaponTool = nil
		end
	end

	-- Destroy the original tool
	tool:Destroy()

	print(string.format("[WeaponDrop] %s dropped %s", player.Name, weaponData.Name))
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP WEAPON
-- ════════════════════════════════════════════════════════════════════════════

function pickupWeapon(player, droppedModel)
	if not droppedModel or not droppedModel.Parent then return end
	if not player or not player.Parent then return end

	-- Restore exact weapon data from JSON
	local weaponDataJSON = droppedModel:GetAttribute("WeaponDataJSON")

	if not weaponDataJSON then
		warn("[WeaponDrop] No weapon data found on dropped model!")
		return
	end

	-- Decode JSON to get exact original weapon data
	local success, weaponData = pcall(function()
		return HttpService:JSONDecode(weaponDataJSON)
	end)

	if not success or not weaponData then
		warn("[WeaponDrop] Failed to decode weapon data:", weaponData)
		return
	end

	-- DEBUG: Log ammo being restored
	print(string.format("[WeaponDrop] Picking up weapon - CurrentAmmo from JSON: %s, Capacity: %s",
		tostring(weaponData.CurrentAmmo), tostring(weaponData.Capacity)))

	-- Give the EXACT same weapon back to player
	local giveSuccess = WeaponToolBuilder:GiveWeaponToPlayer(player, weaponData, true)

	if giveSuccess then
		print(string.format("[WeaponDrop] %s picked up %s (exact same weapon)", player.Name, weaponData.Name))

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
	if not tool or tool.Parent ~= player.Character then
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
