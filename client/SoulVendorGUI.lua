--[[
════════════════════════════════════════════════════════════════════════════════
Module: SoulVendorGUI
Location: StarterPlayer.StarterPlayerScripts/
Description: Client-side GUI for Soul Vendor upgrade purchases.
             Shows 3 upgrade options, handles purchase interactions.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Store mouse state
local previousMouseBehavior = nil

-- Create RemoteEvent for communication
local SoulVendorRemote = ReplicatedStorage:WaitForChild("SoulVendorRemote", 10)
if not SoulVendorRemote then
	warn("[SoulVendorGUI] SoulVendorRemote not found!")
	return
end

-- ════════════════════════════════════════════════════════════════════════════
-- GOTHIC STYLE COLORS
-- ════════════════════════════════════════════════════════════════════════════

local Colors = {
	Parchment = Color3.fromRGB(200, 180, 140),
	Ink = Color3.fromRGB(20, 20, 25),
	DarkParchment = Color3.fromRGB(120, 100, 70),
	Gold = Color3.fromRGB(200, 170, 80),
	Red = Color3.fromRGB(180, 50, 50),
	Green = Color3.fromRGB(80, 150, 80),
}

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE GUI
-- ════════════════════════════════════════════════════════════════════════════

local function createVendorGUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SoulVendorGUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- Hidden by default
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Background overlay (dim)
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = screenGui

	-- Main dialog frame (parchment scroll)
	local dialogFrame = Instance.new("Frame")
	dialogFrame.Name = "DialogFrame"
	dialogFrame.Size = UDim2.new(0, 700, 0, 500)
	dialogFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	dialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	dialogFrame.BackgroundColor3 = Colors.Parchment
	dialogFrame.BorderSizePixel = 0
	dialogFrame.ZIndex = 2
	dialogFrame.Parent = screenGui

	-- Dialog frame border
	local dialogBorder = Instance.new("UIStroke")
	dialogBorder.Color = Colors.Ink
	dialogBorder.Thickness = 4
	dialogBorder.Parent = dialogFrame

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 12)
	dialogCorner.Parent = dialogFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "SOUL KEEPER - CHOOSE YOUR BLESSING"
	title.Font = Enum.Font.SpecialElite
	title.TextSize = 26
	title.TextColor3 = Colors.Ink
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 3
	title.Parent = dialogFrame

	-- Souls display
	local soulsLabel = Instance.new("TextLabel")
	soulsLabel.Name = "SoulsLabel"
	soulsLabel.Size = UDim2.new(1, -40, 0, 30)
	soulsLabel.Position = UDim2.new(0, 20, 0, 70)
	soulsLabel.BackgroundTransparency = 1
	soulsLabel.Text = "Your Souls: 0"
	soulsLabel.Font = Enum.Font.GothamBold
	soulsLabel.TextSize = 18
	soulsLabel.TextColor3 = Colors.Gold
	soulsLabel.TextXAlignment = Enum.TextXAlignment.Center
	soulsLabel.ZIndex = 3
	soulsLabel.Parent = dialogFrame

	-- Container for upgrade options
	local optionsContainer = Instance.new("Frame")
	optionsContainer.Name = "OptionsContainer"
	optionsContainer.Size = UDim2.new(1, -40, 0, 300)
	optionsContainer.Position = UDim2.new(0, 20, 0, 120)
	optionsContainer.BackgroundTransparency = 1
	optionsContainer.ZIndex = 3
	optionsContainer.Parent = dialogFrame

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 200, 0, 45)
	closeButton.Position = UDim2.new(0.5, 0, 1, -65)
	closeButton.AnchorPoint = Vector2.new(0.5, 0)
	closeButton.BackgroundColor3 = Colors.DarkParchment
	closeButton.Text = "LEAVE"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 20
	closeButton.TextColor3 = Colors.Parchment
	closeButton.ZIndex = 3
	closeButton.Parent = dialogFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Colors.Ink
	closeStroke.Thickness = 2
	closeStroke.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	return screenGui
end

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE UPGRADE OPTION BUTTON
-- ════════════════════════════════════════════════════════════════════════════

local function createUpgradeOption(upgradeData, index, parent)
	local yPosition = (index - 1) * 100

	-- Option frame
	local optionFrame = Instance.new("Frame")
	optionFrame.Name = "Option" .. index
	optionFrame.Size = UDim2.new(1, 0, 0, 90)
	optionFrame.Position = UDim2.new(0, 0, 0, yPosition)
	optionFrame.BackgroundColor3 = Colors.DarkParchment
	optionFrame.BorderSizePixel = 0
	optionFrame.ZIndex = 4
	optionFrame.Parent = parent

	local optionCorner = Instance.new("UICorner")
	optionCorner.CornerRadius = UDim.new(0, 8)
	optionCorner.Parent = optionFrame

	local optionStroke = Instance.new("UIStroke")
	optionStroke.Color = Colors.Ink
	optionStroke.Thickness = 3
	optionStroke.Parent = optionFrame

	-- Upgrade name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.6, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 15, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = upgradeData.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Colors.Parchment
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 5
	nameLabel.Parent = optionFrame

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(0.6, -20, 0, 20)
	descLabel.Position = UDim2.new(0, 15, 0, 40)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = upgradeData.Description
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextColor3 = Colors.Parchment
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextTransparency = 0.3
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.ZIndex = 5
	descLabel.Parent = optionFrame

	-- Current level / Next bonus
	local bonusLabel = Instance.new("TextLabel")
	bonusLabel.Name = "BonusLabel"
	bonusLabel.Size = UDim2.new(0.6, -20, 0, 20)
	bonusLabel.Position = UDim2.new(0, 15, 0, 62)
	bonusLabel.BackgroundTransparency = 1
	bonusLabel.Text = string.format("Lv.%d → Lv.%d: %s",
		upgradeData.CurrentLevel,
		upgradeData.CurrentLevel + 1,
		upgradeData.BonusText or "+???")
	bonusLabel.Font = Enum.Font.Gotham
	bonusLabel.TextSize = 14
	bonusLabel.TextColor3 = Colors.Green
	bonusLabel.TextXAlignment = Enum.TextXAlignment.Left
	bonusLabel.ZIndex = 5
	bonusLabel.Parent = optionFrame

	-- Purchase button
	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Name = "PurchaseButton"
	purchaseButton.Size = UDim2.new(0.35, -20, 0, 70)
	purchaseButton.Position = UDim2.new(0.65, 0, 0, 10)
	purchaseButton.BackgroundColor3 = upgradeData.CanAfford and Colors.Gold or Colors.Red
	purchaseButton.Text = upgradeData.CanAfford and
		string.format("PURCHASE\n%d SOULS", upgradeData.Cost) or
		string.format("LOCKED\n%d SOULS", upgradeData.Cost)
	purchaseButton.Font = Enum.Font.GothamBold
	purchaseButton.TextSize = 16
	purchaseButton.TextColor3 = Colors.Ink
	purchaseButton.ZIndex = 5
	purchaseButton.Active = upgradeData.CanAfford
	purchaseButton.Parent = optionFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = purchaseButton

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Colors.Ink
	buttonStroke.Thickness = 2
	buttonStroke.Parent = purchaseButton

	-- Purchase click handler
	if upgradeData.CanAfford then
		purchaseButton.MouseButton1Click:Connect(function()
			print("[SoulVendorGUI] Purchasing:", upgradeData.ID)
			SoulVendorRemote:FireServer("Purchase", upgradeData.ID)
		end)
	end

	return optionFrame
end

-- ════════════════════════════════════════════════════════════════════════════
-- GUI MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

local vendorGUI = createVendorGUI()

local function showVendorGUI(upgradeOptions, playerSouls)
	local dialogFrame = vendorGUI.DialogFrame
	local optionsContainer = dialogFrame.OptionsContainer
	local soulsLabel = dialogFrame.SoulsLabel

	-- Update souls display
	soulsLabel.Text = string.format("Your Souls: %d", playerSouls)

	-- Clear existing options
	for _, child in ipairs(optionsContainer:GetChildren()) do
		child:Destroy()
	end

	-- Create new options
	for i, upgrade in ipairs(upgradeOptions) do
		createUpgradeOption(upgrade, i, optionsContainer)
	end

	-- Save current mouse behavior and unlock for GUI
	previousMouseBehavior = UserInputService.MouseBehavior
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	-- Show GUI
	vendorGUI.Enabled = true
end

local function hideVendorGUI()
	vendorGUI.Enabled = false

	-- Restore previous mouse behavior
	if previousMouseBehavior then
		UserInputService.MouseBehavior = previousMouseBehavior
		UserInputService.MouseIconEnabled = false
		previousMouseBehavior = nil
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SERVER COMMUNICATION
-- ════════════════════════════════════════════════════════════════════════════

-- Listen for server sending upgrade options
SoulVendorRemote.OnClientEvent:Connect(function(action, ...)
	if action == "ShowUpgrades" then
		local upgradeOptions, playerSouls = ...
		showVendorGUI(upgradeOptions, playerSouls)
	elseif action == "PurchaseResult" then
		local success, message = ...
		if success then
			print("[SoulVendorGUI] ✓ Purchase successful:", message)
			-- Request updated upgrades
			SoulVendorRemote:FireServer("RequestUpgrades")
		else
			warn("[SoulVendorGUI] ✗ Purchase failed:", message)
		end
	elseif action == "Close" then
		hideVendorGUI()
	end
end)

print("[SoulVendorGUI] Client GUI initialized")
