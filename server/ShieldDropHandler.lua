--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldDropHandler
Location: ServerScriptService/
Description: Handles shield dropping and pickup for roguelite gameplay.
             Players can drop shields, pick up dropped shields,
             and swap shields in their inventory.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

print("[ShieldDrop] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ShieldModelBuilder = require(Modules:WaitForChild("ShieldModelBuilder"))
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))

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
-- DROPPED SHIELD CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createDroppedShieldModel(shieldData, position)
	-- Build the shield visual model
	local shieldModel = ShieldModelBuilder:BuildShield(shieldData)

	if not shieldModel or not shieldModel.PrimaryPart then
		warn("[ShieldDrop] Failed to build shield model")
		return nil
	end

	-- Create container model
	local droppedModel = Instance.new("Model")
	droppedModel.Name = "DroppedShield"

	-- Move shield model into container
	shieldModel.Parent = droppedModel

	-- Set primary part
	droppedModel.PrimaryPart = shieldModel.PrimaryPart

	-- Make all parts non-collidable but anchored
	for _, part in ipairs(shieldModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = true
		end
	end

	-- Position the model
	droppedModel:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0))

	-- Store shield data as attributes
	droppedModel:SetAttribute("ShieldName", shieldData.Name)
	droppedModel:SetAttribute("Level", shieldData.Level)
	droppedModel:SetAttribute("Rarity", shieldData.Rarity)
	droppedModel:SetAttribute("Capacity", shieldData.Stats.Capacity)
	droppedModel:SetAttribute("RechargeRate", shieldData.Stats.RechargeRate)
	droppedModel:SetAttribute("RechargeDelay", shieldData.Stats.RechargeDelay)
	droppedModel:SetAttribute("BreakEffect", shieldData.Stats.BreakEffect)
	droppedModel:SetAttribute("BreakEffectChance", shieldData.Stats.BreakEffectChance)

	-- Create proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickupPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = string.format("[Lv.%d %s] %s", shieldData.Level, shieldData.Rarity, shieldData.Name)
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
		Legendary = Color3.fromRGB(255, 215, 0)
	}
	highlight.FillColor = rarityColors[shieldData.Rarity] or rarityColors.Common
	highlight.OutlineColor = highlight.FillColor
	highlight.Parent = droppedModel

	return droppedModel, prompt
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLOATING ANIMATION
-- ════════════════════════════════════════════════════════════════════════════

local function animateDroppedShield(model)
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
-- DROP SHIELD
-- ════════════════════════════════════════════════════════════════════════════

local function dropShield(player, shieldData)
	if not shieldData then
		warn("[ShieldDrop] No shield data provided")
		return false
	end

	local character = player.Character
	if not character then return false end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	-- Calculate drop position (in front of player)
	local dropPosition = rootPart.Position + (rootPart.CFrame.LookVector * Config.DropDistance)
	dropPosition = Vector3.new(dropPosition.X, dropPosition.Y + 1, dropPosition.Z) -- Slight elevation

	-- Create dropped shield model
	local droppedModel, prompt = createDroppedShieldModel(shieldData, dropPosition)

	if not droppedModel then
		warn("[ShieldDrop] Failed to create dropped shield model")
		return false
	end

	-- Parent to workspace
	droppedModel.Parent = workspace

	-- Start floating animation
	animateDroppedShield(droppedModel)

	-- Handle pickup
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered and playerWhoTriggered.Parent then
			pickupShield(playerWhoTriggered, droppedModel, shieldData)
		end
	end)

	-- Auto-cleanup after lifetime
	Debris:AddItem(droppedModel, Config.DropLifetime)

	print(string.format("[ShieldDrop] %s dropped %s", player.Name, shieldData.Name))
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP SHIELD
-- ════════════════════════════════════════════════════════════════════════════

function pickupShield(player, droppedModel, shieldData)
	if not droppedModel or not droppedModel.Parent then return end
	if not player or not player.Parent then return end

	-- Reconstruct shield data from attributes
	local reconstructedShieldData = {
		Name = droppedModel:GetAttribute("ShieldName"),
		Level = droppedModel:GetAttribute("Level"),
		Rarity = droppedModel:GetAttribute("Rarity"),
		Stats = {
			Capacity = droppedModel:GetAttribute("Capacity"),
			RechargeRate = droppedModel:GetAttribute("RechargeRate"),
			RechargeDelay = droppedModel:GetAttribute("RechargeDelay"),
			BreakEffect = droppedModel:GetAttribute("BreakEffect"),
			BreakEffectChance = droppedModel:GetAttribute("BreakEffectChance"),
			BreakEffectRadius = shieldData.Stats.BreakEffectRadius,
			BreakEffectDamage = shieldData.Stats.BreakEffectDamage,
		},
		Parts = shieldData.Parts, -- Keep original parts data
	}

	-- Check if player already has a shield
	local inventory = PlayerInventory.GetInventory(player)
	if inventory:HasShield() then
		-- Drop current shield first
		local currentShield = inventory:UnequipShield()
		if currentShield then
			-- Unequip from visual/gameplay
			if _G.UnequipPlayerShield then
				_G.UnequipPlayerShield(player)
			end

			-- Drop the old shield at player's position
			dropShield(player, currentShield)
		end
	end

	-- Add to inventory
	local success = inventory:EquipShield(reconstructedShieldData)

	if success then
		-- Equip shield visually and functionally
		if _G.EquipPlayerShield then
			_G.EquipPlayerShield(player, reconstructedShieldData)
		end

		print(string.format("[ShieldDrop] %s picked up %s", player.Name, reconstructedShieldData.Name))

		-- Destroy dropped model
		droppedModel:Destroy()
	else
		warn("[ShieldDrop] Failed to equip shield to player")
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- REMOTE EVENT SETUP
-- ════════════════════════════════════════════════════════════════════════════

-- Create remote event for drop requests
local dropEvent = Instance.new("RemoteEvent")
dropEvent.Name = "DropShield"
dropEvent.Parent = ReplicatedStorage

dropEvent.OnServerEvent:Connect(function(player)
	-- Get player's current shield from inventory
	local inventory = PlayerInventory.GetInventory(player)
	local shield = inventory:GetShield()

	if not shield then
		warn("[ShieldDrop] Player has no shield to drop:", player.Name)
		return
	end

	-- Unequip shield
	inventory:UnequipShield()

	-- Unequip visually/functionally
	if _G.UnequipPlayerShield then
		_G.UnequipPlayerShield(player)
	end

	-- Drop shield
	dropShield(player, shield)
end)

print("[ShieldDrop] ═══════════════════════════════════════")
print("[ShieldDrop] Shield Drop System Active")
print("[ShieldDrop] Press X to drop equipped shield")
print("[ShieldDrop] Press E to pick up dropped shields")
print("[ShieldDrop] ═══════════════════════════════════════")
