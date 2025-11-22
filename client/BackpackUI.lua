--[[
════════════════════════════════════════════════════════════════════════════════
Module: BackpackUI
Location: StarterPlayer/StarterPlayerScripts/
Description: Client-side Backpack UI showing all stored weapons/shields.
             Press B key to toggle backpack storage display.
             Shows items stored in Backpack layer (not equipped in Inventory).

Version: 1.0 - Gothic FPS Roguelite
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

	-- Main backpack frame
	local backpackFrame = Instance.new("Frame")
	backpackFrame.Name = "BackpackFrame"
	backpackFrame.Size = UDim2.new(0, 1000, 0, 700)
	backpackFrame.Position = UDim2.new(0.5, -500, 0.5, -350)
	backpackFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	backpackFrame.BorderSizePixel = 0
	backpackFrame.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = backpackFrame

	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(150, 100, 50)
	border.Thickness = 3
	border.Parent = backpackFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "BACKPACK STORAGE"
	title.TextColor3 = Color3.fromRGB(200, 150, 100)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 32
	title.TextStrokeTransparency = 0.5
	title.Parent = backpackFrame

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 20)
	subtitle.Position = UDim2.new(0, 0, 0, 45)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Items stored but not equipped"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 14
	subtitle.TextStrokeTransparency = 0.7
	subtitle.Parent = backpackFrame

	-- Close instruction
	local closeLabel = Instance.new("TextLabel")
	closeLabel.Size = UDim2.new(0, 200, 0, 30)
	closeLabel.Position = UDim2.new(1, -210, 0, 10)
	closeLabel.BackgroundTransparency = 1
	closeLabel.Text = "Press B to close"
	closeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeLabel.Font = Enum.Font.Gotham
	closeLabel.TextSize = 16
	closeLabel.TextXAlignment = Enum.TextXAlignment.Right
	closeLabel.TextStrokeTransparency = 0.7
	closeLabel.Parent = backpackFrame

	-- Weapons section
	local weaponsLabel = Instance.new("TextLabel")
	weaponsLabel.Size = UDim2.new(1, -40, 0, 30)
	weaponsLabel.Position = UDim2.new(0, 20, 0, 70)
	weaponsLabel.BackgroundTransparency = 1
	weaponsLabel.Text = "WEAPONS (0/30)"
	weaponsLabel.Name = "WeaponsLabel"
	weaponsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponsLabel.Font = Enum.Font.GothamBold
	weaponsLabel.TextSize = 20
	weaponsLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponsLabel.TextStrokeTransparency = 0.5
	weaponsLabel.Parent = backpackFrame

	-- Weapons scrolling frame
	local weaponsScroll = Instance.new("ScrollingFrame")
	weaponsScroll.Name = "WeaponsScroll"
	weaponsScroll.Size = UDim2.new(1, -40, 0, 380)
	weaponsScroll.Position = UDim2.new(0, 20, 0, 110)
	weaponsScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	weaponsScroll.BorderSizePixel = 0
	weaponsScroll.ScrollBarThickness = 8
	weaponsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	weaponsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	weaponsScroll.Parent = backpackFrame

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

	-- Shield section
	local shieldLabel = Instance.new("TextLabel")
	shieldLabel.Size = UDim2.new(1, -40, 0, 30)
	shieldLabel.Position = UDim2.new(0, 20, 0, 500)
	shieldLabel.BackgroundTransparency = 1
	shieldLabel.Text = "SHIELDS (0/10)"
	shieldLabel.Name = "ShieldLabel"
	shieldLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	shieldLabel.Font = Enum.Font.GothamBold
	shieldLabel.TextSize = 20
	shieldLabel.TextXAlignment = Enum.TextXAlignment.Left
	shieldLabel.TextStrokeTransparency = 0.5
	shieldLabel.Parent = backpackFrame

	-- Shields scrolling frame
	local shieldsScroll = Instance.new("ScrollingFrame")
	shieldsScroll.Name = "ShieldsScroll"
	shieldsScroll.Size = UDim2.new(1, -40, 0, 150)
	shieldsScroll.Position = UDim2.new(0, 20, 0, 540)
	shieldsScroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	shieldsScroll.BorderSizePixel = 0
	shieldsScroll.ScrollBarThickness = 8
	shieldsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shieldsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shieldsScroll.Parent = backpackFrame

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
-- BACKPACK UPDATE
-- ════════════════════════════════════════════════════════════════════════════

local function updateBackpackDisplay(screenGui)
	local inventory = PlayerInventory.GetInventory(player)

	local backpackFrame = screenGui.Overlay.BackpackFrame

	-- Clear existing cards
	local weaponsContainer = backpackFrame.WeaponsScroll.WeaponsContainer
	for _, child in ipairs(weaponsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local shieldsContainer = backpackFrame.ShieldsScroll.ShieldsContainer
	for _, child in ipairs(shieldsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Get backpack items (not equipped items)
	local backpackWeapons = inventory.BackpackWeapons or {}
	local backpackShields = inventory.BackpackShields or {}

	-- Update weapons label
	local weaponsLabel = backpackFrame.WeaponsLabel
	weaponsLabel.Text = string.format("WEAPONS (%d/30)", #backpackWeapons)

	-- Create weapon cards
	if #backpackWeapons > 0 then
		for i, weaponData in ipairs(backpackWeapons) do
			local card = WeaponCard.CreateCompact(weaponData, weaponsContainer)
			card.LayoutOrder = i

			-- Add index number
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

			-- Make card clickable to equip
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

			-- Click handler
			equipButton.MouseButton1Click:Connect(function()
				local equipEvent = ReplicatedStorage:WaitForChild("EquipFromBackpack")
				equipEvent:FireServer("weapon", i)

				-- Refresh UI after short delay
				task.wait(0.1)
				if isOpen then
					updateBackpackDisplay(screenGui)
				end
			end)
		end
	else
		-- Empty message
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No weapons in Backpack\n\nTap E on loot to stash items here"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 16
		emptyLabel.TextWrapped = true
		emptyLabel.TextStrokeTransparency = 0.7
		emptyLabel.Parent = weaponsContainer
	end

	-- Update shields label
	local shieldLabel = backpackFrame.ShieldLabel
	shieldLabel.Text = string.format("SHIELDS (%d/10)", #backpackShields)

	-- Create shield cards
	if #backpackShields > 0 then
		for i, shieldData in ipairs(backpackShields) do
			local card = ShieldCard.CreateCompact(shieldData, shieldsContainer)
			card.LayoutOrder = i

			-- Add index number
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

			-- Make card clickable to equip
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

			-- Click handler
			equipButton.MouseButton1Click:Connect(function()
				local equipEvent = ReplicatedStorage:WaitForChild("EquipFromBackpack")
				equipEvent:FireServer("shield", i)

				-- Refresh UI after short delay
				task.wait(0.1)
				if isOpen then
					updateBackpackDisplay(screenGui)
				end
			end)
		end
	else
		-- Empty message
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 100)
		emptyLabel.Position = UDim2.new(0, 10, 0, 20)
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
local isOpen = false

-- Toggle backpack
local function toggleBackpack()
	isOpen = not isOpen
	backpackUI.Overlay.Visible = isOpen

	if isOpen then
		updateBackpackDisplay(backpackUI)
	end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- B key to toggle backpack
	if input.KeyCode == Enum.KeyCode.B then
		toggleBackpack()
	end
end)

print("[BackpackUI] Ready - Press B to open Backpack storage")
