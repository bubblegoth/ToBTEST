--[[
════════════════════════════════════════════════════════════════════════════════
Module: BackpackUI
Location: StarterPlayer/StarterPlayerScripts/
Description: Unified Inventory & Backpack UI (Borderlands-style).
             Press B key to view both equipped items and storage.
             Shows Inventory (equipped) at top, Backpack (storage) below.

Version: 2.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[BackpackUI] Initializing...")

-- Load modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local WeaponCard = require(Modules:WaitForChild("WeaponCard"))
local ShieldCard = require(Modules:WaitForChild("ShieldCard"))
local PlayerInventory = require(Modules:WaitForChild("PlayerInventory"))

-- ════════════════════════════════════════════════════════════════════════════
-- UI CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createBackpackUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BackpackUI"
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

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 1100, 0, 800)
	mainFrame.Position = UDim2.new(0.5, -550, 0.5, -400)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(200, 150, 100)
	border.Thickness = 3
	border.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "INVENTORY & BACKPACK"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextStrokeTransparency = 0.5
	title.Parent = mainFrame

	-- Close instruction
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(0, 200, 0, 30)
	closeLabel.Position = UDim2.new(1, -210, 0, 5)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Text = "Press B to close"
	closeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeLabel.Font = Enum.Font.Gotham
	closeLabel.TextSize = 14
	closeLabel.TextXAlignment = Enum.TextXAlignment.Right
	closeLabel.TextStrokeTransparency = 0.7
	closeLabel.Parent = mainFrame

	-- ═══════════════════════════════════════════════════════════════════════
	-- INVENTORY SECTION (EQUIPPED ITEMS)
	-- ═══════════════════════════════════════════════════════════════════════

	local inventoryLabel = Instance.new("TextLabel")
	inventoryLabel.Size = UDim2.new(1, -40, 0, 25)
	inventoryLabel.Position = UDim2.new(0, 20, 0, 45)
	inventoryLabel.BackgroundTransparency = 1
	inventoryLabel.Text = "═══ INVENTORY (EQUIPPED) ═══"
	inventoryLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	inventoryLabel.Font = Enum.Font.GothamBold
	inventoryLabel.TextSize = 18
	inventoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	inventoryLabel.TextStrokeTransparency = 0.5
	inventoryLabel.Parent = mainFrame

	-- Inventory weapons container
	local invWeaponsContainer = Instance.new("Frame")
	invWeaponsContainer.Name = "InvWeaponsContainer"
	invWeaponsContainer.Size = UDim2.new(1, -40, 0, 140)
	invWeaponsContainer.Position = UDim2.new(0, 20, 0, 75)
	invWeaponsContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	invWeaponsContainer.BorderSizePixel = 0
	invWeaponsContainer.Parent = mainFrame

	local invWeaponsCorner = Instance.new("UICorner")
	invWeaponsCorner.CornerRadius = UDim.new(0, 8)
	invWeaponsCorner.Parent = invWeaponsContainer

	local invWeaponsLayout = Instance.new("UIGridLayout")
	invWeaponsLayout.CellSize = UDim2.new(0, 260, 0, 130)
	invWeaponsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	invWeaponsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	invWeaponsLayout.Parent = invWeaponsContainer

	local invWeaponsPadding = Instance.new("UIPadding")
	invWeaponsPadding.PaddingTop = UDim.new(0, 5)
	invWeaponsPadding.PaddingLeft = UDim.new(0, 10)
	invWeaponsPadding.Parent = invWeaponsContainer

	-- Inventory shield label
	local invShieldLabel = Instance.new("TextLabel")
	invShieldLabel.Size = UDim2.new(1, -40, 0, 20)
	invShieldLabel.Position = UDim2.new(0, 20, 0, 225)
	invShieldLabel.BackgroundTransparency = 1
	invShieldLabel.Text = "Shield"
	invShieldLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	invShieldLabel.Font = Enum.Font.GothamBold
	invShieldLabel.TextSize = 14
	invShieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	invShieldLabel.TextStrokeTransparency = 0.5
	invShieldLabel.Parent = mainFrame

	-- Inventory shield container
	local invShieldContainer = Instance.new("Frame")
	invShieldContainer.Name = "InvShieldContainer"
	invShieldContainer.Size = UDim2.new(0, 260, 0, 130)
	invShieldContainer.Position = UDim2.new(0, 20, 0, 250)
	invShieldContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	invShieldContainer.BorderSizePixel = 0
	invShieldContainer.Parent = mainFrame

	local invShieldCorner = Instance.new("UICorner")
	invShieldCorner.CornerRadius = UDim.new(0, 8)
	invShieldCorner.Parent = invShieldContainer

	-- ═══════════════════════════════════════════════════════════════════════
	-- BACKPACK SECTION (STORAGE)
	-- ═══════════════════════════════════════════════════════════════════════

	local backpackLabel = Instance.new("TextLabel")
	backpackLabel.Size = UDim2.new(1, -40, 0, 25)
	backpackLabel.Position = UDim2.new(0, 20, 0, 390)
	backpackLabel.BackgroundTransparency = 1
	backpackLabel.Text = "═══ BACKPACK (STORAGE) ═══"
	backpackLabel.TextColor3 = Color3.fromRGB(200, 150, 100)
	backpackLabel.Font = Enum.Font.GothamBold
	backpackLabel.TextSize = 18
	backpackLabel.TextXAlignment = Enum.TextXAlignment.Left
	backpackLabel.TextStrokeTransparency = 0.5
	backpackLabel.Parent = mainFrame

	-- Backpack weapons label
	local weaponsLabel = Instance.new("TextLabel")
	weaponsLabel.Size = UDim2.new(1, -40, 0, 20)
	weaponsLabel.Position = UDim2.new(0, 20, 0, 420)
	weaponsLabel.BackgroundTransparency = 1
	weaponsLabel.Text = "WEAPONS (0/30)"
	weaponsLabel.Name = "WeaponsLabel"
	weaponsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	weaponsLabel.Font = Enum.Font.GothamBold
	weaponsLabel.TextSize = 14
	weaponsLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponsLabel.TextStrokeTransparency = 0.5
	weaponsLabel.Parent = mainFrame

	-- Backpack weapons scrolling frame
	local weaponsScroll = Instance.new("ScrollingFrame")
	weaponsScroll.Name = "WeaponsScroll"
	weaponsScroll.Size = UDim2.new(1, -40, 0, 180)
	weaponsScroll.Position = UDim2.new(0, 20, 0, 445)
	weaponsScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	weaponsScroll.BorderSizePixel = 0
	weaponsScroll.ScrollBarThickness = 8
	weaponsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	weaponsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	weaponsScroll.Parent = mainFrame

	local weaponsCorner = Instance.new("UICorner")
	weaponsCorner.CornerRadius = UDim.new(0, 8)
	weaponsCorner.Parent = weaponsScroll

	-- Weapons container
	local weaponsContainer = Instance.new("Frame")
	weaponsContainer.Name = "WeaponsContainer"
	weaponsContainer.Size = UDim2.new(1, -20, 1, 0)
	weaponsContainer.BackgroundTransparency = 1
	weaponsContainer.AutomaticSize = Enum.AutomaticSize.Y
	weaponsContainer.Parent = weaponsScroll

	-- Grid layout for weapons
	local weaponsLayout = Instance.new("UIGridLayout")
	weaponsLayout.CellSize = UDim2.new(0, 210, 0, 130)
	weaponsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	weaponsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	weaponsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	weaponsLayout.Parent = weaponsContainer

	local weaponsPadding = Instance.new("UIPadding")
	weaponsPadding.PaddingTop = UDim.new(0, 10)
	weaponsPadding.PaddingLeft = UDim.new(0, 10)
	weaponsPadding.PaddingBottom = UDim.new(0, 10)
	weaponsPadding.Parent = weaponsContainer

	-- Backpack shields label
	local shieldLabel = Instance.new("TextLabel")
	shieldLabel.Size = UDim2.new(1, -40, 0, 20)
	shieldLabel.Position = UDim2.new(0, 20, 0, 635)
	shieldLabel.BackgroundTransparency = 1
	shieldLabel.Text = "SHIELDS (0/10)"
	shieldLabel.Name = "ShieldLabel"
	shieldLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	shieldLabel.Font = Enum.Font.GothamBold
	shieldLabel.TextSize = 14
	shieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	shieldLabel.TextStrokeTransparency = 0.5
	shieldLabel.Parent = mainFrame

	-- Backpack shields scrolling frame
	local shieldsScroll = Instance.new("ScrollingFrame")
	shieldsScroll.Name = "ShieldsScroll"
	shieldsScroll.Size = UDim2.new(1, -40, 0, 130)
	shieldsScroll.Position = UDim2.new(0, 20, 0, 660)
	shieldsScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	shieldsScroll.BorderSizePixel = 0
	shieldsScroll.ScrollBarThickness = 8
	shieldsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shieldsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shieldsScroll.Parent = mainFrame

	local shieldsCorner = Instance.new("UICorner")
	shieldsCorner.CornerRadius = UDim.new(0, 8)
	shieldsCorner.Parent = shieldsScroll

	-- Shields container
	local shieldsContainer = Instance.new("Frame")
	shieldsContainer.Name = "ShieldsContainer"
	shieldsContainer.Size = UDim2.new(1, -20, 1, 0)
	shieldsContainer.BackgroundTransparency = 1
	shieldsContainer.AutomaticSize = Enum.AutomaticSize.Y
	shieldsContainer.Parent = shieldsScroll

	-- Grid layout for shields
	local shieldsLayout = Instance.new("UIGridLayout")
	shieldsLayout.CellSize = UDim2.new(0, 210, 0, 130)
	shieldsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	shieldsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shieldsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	shieldsLayout.Parent = shieldsContainer

	local shieldsPadding = Instance.new("UIPadding")
	shieldsPadding.PaddingTop = UDim.new(0, 10)
	shieldsPadding.PaddingLeft = UDim.new(0, 10)
	shieldsPadding.PaddingBottom = UDim.new(0, 10)
	shieldsPadding.Parent = shieldsContainer

	return screenGui
end

-- ════════════════════════════════════════════════════════════════════════════
-- UPDATE DISPLAY
-- ════════════════════════════════════════════════════════════════════════════

local function updateDisplay(screenGui)
	local inventory = PlayerInventory.GetInventory(player)
	local mainFrame = screenGui.Overlay.MainFrame

	-- ═══════════════════════════════════════════════════════════════════════
	-- UPDATE INVENTORY (EQUIPPED) SECTION
	-- ═══════════════════════════════════════════════════════════════════════

	local invWeaponsContainer = mainFrame.InvWeaponsContainer
	for _, child in ipairs(invWeaponsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local invShieldContainer = mainFrame.InvShieldContainer
	for _, child in ipairs(invShieldContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get equipped weapons
	local allWeapons = inventory:GetAllEquippedWeapons()
	local currentWeaponSlot = inventory.CurrentWeaponSlot

	-- Create weapon cards (4 slots)
	for i = 1, 4 do
		local weaponData = allWeapons[i]

		if weaponData then
			local card = WeaponCard.CreateCompact(weaponData, invWeaponsContainer)
			card.LayoutOrder = i

			-- Slot number
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

			-- Unequip button
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

			unequipButton.MouseButton1Click:Connect(function()
				local unequipEvent = ReplicatedStorage:WaitForChild("UnequipToBackpack")
				unequipEvent:FireServer("weapon", i)
				task.wait(0.1)
				if isOpen then
					updateDisplay(screenGui)
				end
			end)

			-- Equipped indicator
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
			emptySlot.Size = UDim2.new(0, 250, 0, 120)
			emptySlot.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			emptySlot.BorderSizePixel = 0
			emptySlot.LayoutOrder = i
			emptySlot.Parent = invWeaponsContainer

			local emptyCorner = Instance.new("UICorner")
			emptyCorner.CornerRadius = UDim.new(0, 6)
			emptyCorner.Parent = emptySlot

			local emptyBorder = Instance.new("UIStroke")
			emptyBorder.Color = Color3.fromRGB(80, 80, 80)
			emptyBorder.Thickness = 2
			emptyBorder.Transparency = 0.5
			emptyBorder.Parent = emptySlot

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

	-- Shield
	local shield = inventory:GetShield()
	if shield then
		local card = ShieldCard.CreateCompact(shield, invShieldContainer)

		-- Unequip button
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

		unequipButton.MouseButton1Click:Connect(function()
			local unequipEvent = ReplicatedStorage:WaitForChild("UnequipToBackpack")
			unequipEvent:FireServer("shield", 1)
			task.wait(0.1)
			if isOpen then
				updateDisplay(screenGui)
			end
		end)

		-- Equipped indicator
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
		emptySlot.Size = UDim2.new(1, -10, 1, -10)
		emptySlot.Position = UDim2.new(0, 5, 0, 5)
		emptySlot.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		emptySlot.BorderSizePixel = 0
		emptySlot.Parent = invShieldContainer

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

	-- ═══════════════════════════════════════════════════════════════════════
	-- UPDATE BACKPACK (STORAGE) SECTION
	-- ═══════════════════════════════════════════════════════════════════════

	local weaponsContainer = mainFrame.WeaponsScroll.WeaponsContainer
	for _, child in ipairs(weaponsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local shieldsContainer = mainFrame.ShieldsScroll.ShieldsContainer
	for _, child in ipairs(shieldsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get backpack items
	local backpackWeapons = inventory.BackpackWeapons or {}
	local backpackShields = inventory.BackpackShields or {}

	-- Update labels
	mainFrame.WeaponsLabel.Text = string.format("WEAPONS (%d/30)", #backpackWeapons)
	mainFrame.ShieldLabel.Text = string.format("SHIELDS (%d/10)", #backpackShields)

	-- Create weapon cards
	if #backpackWeapons > 0 then
		for i, weaponData in ipairs(backpackWeapons) do
			local card = WeaponCard.CreateCompact(weaponData, weaponsContainer)
			card.LayoutOrder = i

			-- Index number
			local indexLabel = Instance.new("TextLabel")
			indexLabel.Size = UDim2.new(0, 25, 0, 25)
			indexLabel.Position = UDim2.new(0, 5, 0, 5)
			indexLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			indexLabel.BackgroundTransparency = 0.5
			indexLabel.Text = tostring(i)
			indexLabel.TextColor3 = Color3.fromRGB(200, 150, 100)
			indexLabel.Font = Enum.Font.GothamBold
			indexLabel.TextSize = 14
			indexLabel.BorderSizePixel = 0
			indexLabel.Parent = card

			local indexCorner = Instance.new("UICorner")
			indexCorner.CornerRadius = UDim.new(0, 4)
			indexCorner.Parent = indexLabel

			-- Equip button
			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(1, 0, 0, 25)
			equipButton.Position = UDim2.new(0, 0, 1, -25)
			equipButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			equipButton.BackgroundTransparency = 0.3
			equipButton.BorderSizePixel = 0
			equipButton.Text = "EQUIP TO INVENTORY"
			equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipButton.Font = Enum.Font.GothamBold
			equipButton.TextSize = 11
			equipButton.TextStrokeTransparency = 0.5
			equipButton.AutoButtonColor = true
			equipButton.Parent = card

			equipButton.MouseButton1Click:Connect(function()
				local equipEvent = ReplicatedStorage:WaitForChild("EquipFromBackpack")
				equipEvent:FireServer("weapon", i)
				task.wait(0.1)
				if isOpen then
					updateDisplay(screenGui)
				end
			end)
		end
	else
		-- Empty message
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 20)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No weapons in Backpack\n\nTap E on loot to stash items here"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 16
		emptyLabel.TextWrapped = true
		emptyLabel.TextStrokeTransparency = 0.7
		emptyLabel.Parent = weaponsContainer
	end

	-- Create shield cards
	if #backpackShields > 0 then
		for i, shieldData in ipairs(backpackShields) do
			local card = ShieldCard.CreateCompact(shieldData, shieldsContainer)
			card.LayoutOrder = i

			-- Index number
			local indexLabel = Instance.new("TextLabel")
			indexLabel.Size = UDim2.new(0, 25, 0, 25)
			indexLabel.Position = UDim2.new(0, 5, 0, 5)
			indexLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
			indexLabel.BackgroundTransparency = 0.5
			indexLabel.Text = tostring(i)
			indexLabel.TextColor3 = Color3.fromRGB(100, 150, 200)
			indexLabel.Font = Enum.Font.GothamBold
			indexLabel.TextSize = 14
			indexLabel.BorderSizePixel = 0
			indexLabel.Parent = card

			local indexCorner = Instance.new("UICorner")
			indexCorner.CornerRadius = UDim.new(0, 4)
			indexCorner.Parent = indexLabel

			-- Equip button
			local equipButton = Instance.new("TextButton")
			equipButton.Size = UDim2.new(1, 0, 0, 25)
			equipButton.Position = UDim2.new(0, 0, 1, -25)
			equipButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
			equipButton.BackgroundTransparency = 0.3
			equipButton.BorderSizePixel = 0
			equipButton.Text = "EQUIP SHIELD"
			equipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipButton.Font = Enum.Font.GothamBold
			equipButton.TextSize = 11
			equipButton.TextStrokeTransparency = 0.5
			equipButton.AutoButtonColor = true
			equipButton.Parent = card

			equipButton.MouseButton1Click:Connect(function()
				local equipEvent = ReplicatedStorage:WaitForChild("EquipFromBackpack")
				equipEvent:FireServer("shield", i)
				task.wait(0.1)
				if isOpen then
					updateDisplay(screenGui)
				end
			end)
		end
	else
		-- Empty message
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 80)
		emptyLabel.Position = UDim2.new(0, 10, 0, 10)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No shields in Backpack\n\nTap E on shield loot to stash"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 16
		emptyLabel.TextWrapped = true
		emptyLabel.TextStrokeTransparency = 0.7
		emptyLabel.Parent = shieldsContainer
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

local backpackUI = createBackpackUI()
isOpen = false

-- Toggle backpack
local function toggleBackpack()
	isOpen = not isOpen
	backpackUI.Overlay.Visible = isOpen

	if isOpen then
		updateDisplay(backpackUI)
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- B key to toggle
	if input.KeyCode == Enum.KeyCode.B then
		toggleBackpack()
	end
end)

print("[BackpackUI] Ready - Press B to open Inventory & Backpack")
