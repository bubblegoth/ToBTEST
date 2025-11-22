--[[
════════════════════════════════════════════════════════════════════════════════
Module: InventoryUI
Location: StarterPlayer/StarterPlayerScripts/
Description: Client-side inventory UI with Borderlands-style weapon/shield cards.
             Press I key to toggle inventory display.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[InventoryUI] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WeaponCard = require(Modules:WaitForChild("WeaponCard"))
local ShieldCard = require(Modules:WaitForChild("ShieldCard"))
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))
local WeaponToolBuilder = require(Modules:WaitForChild("WeaponToolBuilder"))

-- ════════════════════════════════════════════════════════════════════════════
-- UI CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createInventoryUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.Parent = screenGui

	-- Main inventory frame
	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0, 900, 0, 600)
	inventoryFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = inventoryFrame

	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(100, 100, 100)
	border.Thickness = 2
	border.Parent = inventoryFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "INVENTORY"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 32
	title.TextStrokeTransparency = 0.5
	title.Parent = inventoryFrame

	-- Close instruction
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(0, 200, 0, 30)
	closeLabel.Position = UDim2.new(1, -210, 0, 10)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Text = "Press I to close"
	closeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeLabel.Font = Enum.Font.Gotham
	closeLabel.TextSize = 16
	closeLabel.TextXAlignment = Enum.TextXAlignment.Right
	closeLabel.TextStrokeTransparency = 0.7
	closeLabel.Parent = inventoryFrame

	-- Weapons section
	local weaponsLabel = Instance.new("TextLabel")
	weaponsLabel.Size = UDim2.new(1, -40, 0, 30)
	weaponsLabel.Position = UDim2.new(0, 20, 0, 60)
	weaponsLabel.BackgroundTransparency = 1
	weaponsLabel.Text = "WEAPONS (4 slots)"
	weaponsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponsLabel.Font = Enum.Font.GothamBold
	weaponsLabel.TextSize = 20
	weaponsLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponsLabel.TextStrokeTransparency = 0.5
	weaponsLabel.Parent = inventoryFrame

	-- Weapons container
	local weaponsContainer = Instance.new("Frame")
	weaponsContainer.Name = "WeaponsContainer"
	weaponsContainer.Size = UDim2.new(1, -40, 0, 280)
	weaponsContainer.Position = UDim2.new(0, 20, 0, 100)
	weaponsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	weaponsContainer.BorderSizePixel = 0
	weaponsContainer.Parent = inventoryFrame

	local weaponsCorner = Instance.new("UICorner")
	weaponsCorner.CornerRadius = UDim.new(0, 8)
	weaponsCorner.Parent = weaponsContainer

	-- Grid layout for weapons
	local weaponsLayout = Instance.new("UIGridLayout")
	weaponsLayout.CellSize = UDim2.new(0, 210, 0, 130)
	weaponsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	weaponsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	weaponsLayout.Parent = weaponsContainer

	local weaponsPadding = Instance.new("UIPadding")
	weaponsPadding.PaddingTop = UDim.new(0, 10)
	weaponsPadding.PaddingLeft = UDim.new(0, 10)
	weaponsPadding.Parent = weaponsContainer

	-- Shield section
	local shieldLabel = Instance.new("TextLabel")
	shieldLabel.Size = UDim2.new(1, -40, 0, 30)
	shieldLabel.Position = UDim2.new(0, 20, 0, 390)
	shieldLabel.BackgroundTransparency = 1
	shieldLabel.Text = "SHIELD (1 slot)"
	shieldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	shieldLabel.Font = Enum.Font.GothamBold
	shieldLabel.TextSize = 20
	shieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	shieldLabel.TextStrokeTransparency = 0.5
	shieldLabel.Parent = inventoryFrame

	-- Shield container
	local shieldContainer = Instance.new("Frame")
	shieldContainer.Name = "ShieldContainer"
	shieldContainer.Size = UDim2.new(1, -40, 0, 150)
	shieldContainer.Position = UDim2.new(0, 20, 0, 430)
	shieldContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	shieldContainer.BorderSizePixel = 0
	shieldContainer.Parent = inventoryFrame

	local shieldCorner = Instance.new("UICorner")
	shieldCorner.CornerRadius = UDim.new(0, 8)
	shieldCorner.Parent = shieldContainer

	local shieldPadding = Instance.new("UIPadding")
	shieldPadding.PaddingTop = UDim.new(0, 10)
	shieldPadding.PaddingLeft = UDim.new(0, 10)
	shieldPadding.Parent = shieldContainer

	return screenGui
end

-- ════════════════════════════════════════════════════════════════════════════
-- INVENTORY UPDATE
-- ════════════════════════════════════════════════════════════════════════════

local function updateInventoryDisplay(screenGui)
	local inventory = PlayerInventory.GetInventory(player)

	-- Clear existing cards
	local weaponsContainer = screenGui.Overlay.InventoryFrame.WeaponsContainer
	for _, child in ipairs(weaponsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local shieldContainer = screenGui.Overlay.InventoryFrame.ShieldContainer
	for _, child in ipairs(shieldContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get all equipped weapons from inventory (stored as data, not Tools)
	local allWeapons = inventory:GetAllEquippedWeapons()
	local currentWeaponSlot = inventory.CurrentWeaponSlot

	-- Create weapon cards
	for i = 1, 4 do
		local weaponData = allWeapons[i]

		if weaponData then
			-- Create weapon card
			local card = WeaponCard.CreateCompact(weaponData, weaponsContainer)
			card.LayoutOrder = i

			-- Add slot number
			local slotLabel = Instance.new("TextLabel")
			slotLabel.Size = UDim2.new(0, 25, 0, 25)
			slotLabel.Position = UDim2.new(0, 5, 0, 5)
			slotLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			slotLabel.BackgroundTransparency = 0.5
			slotLabel.Text = tostring(i)
			slotLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			slotLabel.Font = Enum.Font.GothamBold
			slotLabel.TextSize = 14
			slotLabel.BorderSizePixel = 0
			slotLabel.Parent = card

			local slotCorner = Instance.new("UICorner")
			slotCorner.CornerRadius = UDim.new(0, 4)
			slotCorner.Parent = slotLabel

			-- Add unequip button (top-right)
			local unequipButton = Instance.new("TextButton")
			unequipButton.Size = UDim2.new(0, 60, 0, 20)
			unequipButton.Position = UDim2.new(1, -65, 0, 5)
			unequipButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			unequipButton.BackgroundTransparency = 0.2
			unequipButton.BorderSizePixel = 0
			unequipButton.Text = "STASH"
			unequipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			unequipButton.Font = Enum.Font.GothamBold
			unequipButton.TextSize = 9
			unequipButton.TextStrokeTransparency = 0.5
			unequipButton.AutoButtonColor = true
			unequipButton.Parent = card

			local unequipCorner = Instance.new("UICorner")
			unequipCorner.CornerRadius = UDim.new(0, 4)
			unequipCorner.Parent = unequipButton

			-- Click handler
			unequipButton.MouseButton1Click:Connect(function()
				local unequipEvent = ReplicatedStorage:WaitForChild("UnequipToBackpack")
				unequipEvent:FireServer("weapon", i)

				-- Refresh UI after short delay
				task.wait(0.1)
				if isOpen then
					updateInventoryDisplay(screenGui)
				end
			end)

			-- Add equipped indicator
			if i == currentWeaponSlot then
				local equippedLabel = Instance.new("TextLabel")
				equippedLabel.Size = UDim2.new(1, 0, 0, 15)
				equippedLabel.Position = UDim2.new(0, 0, 1, -15)
				equippedLabel.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
				equippedLabel.BackgroundTransparency = 0.3
				equippedLabel.Text = "EQUIPPED"
				equippedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				equippedLabel.Font = Enum.Font.GothamBold
				equippedLabel.TextSize = 11
				equippedLabel.TextStrokeTransparency = 0.5
				equippedLabel.BorderSizePixel = 0
				equippedLabel.Parent = card
			end
		else
			-- Empty slot
			local emptySlot = Instance.new("Frame")
			emptySlot.Name = "EmptySlot"
			emptySlot.Size = UDim2.new(0, 200, 0, 120)
			emptySlot.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			emptySlot.BorderSizePixel = 0
			emptySlot.LayoutOrder = i
			emptySlot.Parent = weaponsContainer

			local emptyCorner = Instance.new("UICorner")
			emptyCorner.CornerRadius = UDim.new(0, 6)
			emptyCorner.Parent = emptySlot

			local emptyBorder = Instance.new("UIStroke")
			emptyBorder.Color = Color3.fromRGB(80, 80, 80)
			emptyBorder.Thickness = 2
			emptyBorder.Transparency = 0.5
			emptyBorder.Parent = emptySlot

			-- Slot number for empty slot
			local slotLabel = Instance.new("TextLabel")
			slotLabel.Size = UDim2.new(0, 25, 0, 25)
			slotLabel.Position = UDim2.new(0, 5, 0, 5)
			slotLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			slotLabel.BackgroundTransparency = 0.5
			slotLabel.Text = tostring(i)
			slotLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
			slotLabel.Font = Enum.Font.GothamBold
			slotLabel.TextSize = 14
			slotLabel.BorderSizePixel = 0
			slotLabel.Parent = emptySlot

			local slotCorner = Instance.new("UICorner")
			slotCorner.CornerRadius = UDim.new(0, 4)
			slotCorner.Parent = slotLabel

			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.Size = UDim2.new(1, 0, 1, 0)
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Text = "EMPTY"
			emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
			emptyLabel.Font = Enum.Font.GothamBold
			emptyLabel.TextSize = 16
			emptyLabel.TextStrokeTransparency = 0.7
			emptyLabel.Parent = emptySlot
		end
	end

	-- Add shield card
	local shield = inventory:GetShield()
	if shield then
		local card = ShieldCard.CreateCompact(shield, shieldContainer)

		-- Add unequip button (top-right)
		local unequipButton = Instance.new("TextButton")
		unequipButton.Size = UDim2.new(0, 60, 0, 20)
		unequipButton.Position = UDim2.new(1, -65, 0, 5)
		unequipButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		unequipButton.BackgroundTransparency = 0.2
		unequipButton.BorderSizePixel = 0
		unequipButton.Text = "STASH"
		unequipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		unequipButton.Font = Enum.Font.GothamBold
		unequipButton.TextSize = 9
		unequipButton.TextStrokeTransparency = 0.5
		unequipButton.AutoButtonColor = true
		unequipButton.Parent = card

		local unequipCorner = Instance.new("UICorner")
		unequipCorner.CornerRadius = UDim.new(0, 4)
		unequipCorner.Parent = unequipButton

		-- Click handler
		unequipButton.MouseButton1Click:Connect(function()
			local unequipEvent = ReplicatedStorage:WaitForChild("UnequipToBackpack")
			unequipEvent:FireServer("shield", 1)

			-- Refresh UI after short delay
			task.wait(0.1)
			if isOpen then
				updateInventoryDisplay(screenGui)
			end
		end)

		-- Add equipped indicator
		local equippedLabel = Instance.new("TextLabel")
		equippedLabel.Size = UDim2.new(1, 0, 0, 15)
		equippedLabel.Position = UDim2.new(0, 0, 1, -15)
		equippedLabel.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		equippedLabel.BackgroundTransparency = 0.3
		equippedLabel.Text = "EQUIPPED"
		equippedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		equippedLabel.Font = Enum.Font.GothamBold
		equippedLabel.TextSize = 11
		equippedLabel.TextStrokeTransparency = 0.5
		equippedLabel.BorderSizePixel = 0
		equippedLabel.Parent = card
	else
		-- Empty shield slot
		local emptySlot = Instance.new("Frame")
		emptySlot.Name = "EmptyShieldSlot"
		emptySlot.Size = UDim2.new(0, 200, 0, 120)
		emptySlot.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		emptySlot.BorderSizePixel = 0
		emptySlot.Parent = shieldContainer

		local emptyCorner = Instance.new("UICorner")
		emptyCorner.CornerRadius = UDim.new(0, 6)
		emptyCorner.Parent = emptySlot

		local emptyBorder = Instance.new("UIStroke")
		emptyBorder.Color = Color3.fromRGB(80, 80, 80)
		emptyBorder.Thickness = 2
		emptyBorder.Transparency = 0.5
		emptyBorder.Parent = emptySlot

		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "NO SHIELD"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.Font = Enum.Font.GothamBold
		emptyLabel.TextSize = 16
		emptyLabel.TextStrokeTransparency = 0.7
		emptyLabel.Parent = emptySlot
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

local inventoryUI = createInventoryUI()
local isOpen = false

-- Toggle inventory
local function toggleInventory()
	isOpen = not isOpen
	inventoryUI.Overlay.Visible = isOpen

	if isOpen then
		updateInventoryDisplay(inventoryUI)
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- I key to toggle inventory
	if input.KeyCode == Enum.KeyCode.I then
		toggleInventory()
	end
end)

print("[InventoryUI] Ready - Press I to open inventory")
