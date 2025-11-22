--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldCard
Location: ReplicatedStorage/Modules/
Description: Borderlands-style shield stat card UI generator.
             Creates detailed stat displays for shields with rarity colors.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local ShieldCard = {}

-- ════════════════════════════════════════════════════════════════════════════
-- RARITY COLORS
-- ════════════════════════════════════════════════════════════════════════════

local RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(50, 205, 50),
	Rare = Color3.fromRGB(30, 144, 255),
	Epic = Color3.fromRGB(138, 43, 226),
	Legendary = Color3.fromRGB(255, 215, 0)
}

-- ════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

local function createStatLabel(parent, yPos, statName, statValue, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -20, 0, 20)
	frame.Position = UDim2.new(0, 10, 0, yPos)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = statName
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(statValue)
	valueLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 14
	valueLabel.TextStrokeTransparency = 0.5
	valueLabel.Parent = frame

	return frame
end

local function createDivider(parent, yPos)
	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -20, 0, 2)
	divider.Position = UDim2.new(0, 10, 0, yPos)
	divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	divider.BorderSizePixel = 0
	divider.Parent = parent
	return divider
end

-- ════════════════════════════════════════════════════════════════════════════
-- SHIELD CARD CREATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Creates a Borderlands-style shield card UI
	@param shieldData - Complete shield data structure
	@param parent - Parent GUI element (optional)
	@return Frame - The shield card frame
]]
function ShieldCard.Create(shieldData, parent)
	if not shieldData then
		warn("[ShieldCard] No shield data provided")
		return nil
	end

	local rarityColor = RARITY_COLORS[shieldData.Rarity] or RARITY_COLORS.Common

	-- Main card frame
	local card = Instance.new("Frame")
	card.Name = "ShieldCard"
	card.Size = UDim2.new(0, 350, 0, 280)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	card.BorderSizePixel = 0
	card.Parent = parent

	-- Rarity border
	local border = Instance.new("UIStroke")
	border.Color = rarityColor
	border.Thickness = 3
	border.Parent = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	-- Header background
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = rarityColor
	header.BackgroundTransparency = 0.8
	header.BorderSizePixel = 0
	header.Parent = card

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	-- Shield name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = shieldData.Name
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = card

	-- Shield type and level
	local typeLabel = Instance.new("TextLabel")
	typeLabel.Size = UDim2.new(1, -20, 0, 20)
	typeLabel.Position = UDim2.new(0, 10, 0, 30)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = string.format("%s Shield | Level %d", shieldData.Rarity, shieldData.Level)
	typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	typeLabel.Font = Enum.Font.Gotham
	typeLabel.TextSize = 14
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.TextStrokeTransparency = 0.5
	typeLabel.Parent = card

	-- Stats section
	local yOffset = 70

	-- Main stats
	createStatLabel(card, yOffset, "Capacity", string.format("%d HP", shieldData.Stats.Capacity), Color3.fromRGB(100, 200, 255))
	yOffset = yOffset + 25

	createStatLabel(card, yOffset, "Recharge Rate", string.format("%.1f HP/s", shieldData.Stats.RechargeRate), Color3.fromRGB(150, 255, 150))
	yOffset = yOffset + 25

	createStatLabel(card, yOffset, "Recharge Delay", string.format("%.1fs", shieldData.Stats.RechargeDelay), Color3.fromRGB(255, 255, 100))
	yOffset = yOffset + 25

	-- Divider
	createDivider(card, yOffset)
	yOffset = yOffset + 10

	-- Special effect
	createStatLabel(card, yOffset, "Break Effect", shieldData.Stats.BreakEffect, Color3.fromRGB(255, 150, 50))
	yOffset = yOffset + 25

	createStatLabel(card, yOffset, "Effect Chance", string.format("%.0f%%", shieldData.Stats.BreakEffectChance * 100), Color3.fromRGB(255, 100, 100))
	yOffset = yOffset + 25

	-- Divider
	createDivider(card, yOffset)
	yOffset = yOffset + 10

	-- Parts info
	local partsText = "Standard Shield Generator"
	if shieldData.Parts then
		partsText = string.format("%s Capacitor\n%s Generator",
			shieldData.Parts.Capacitor and shieldData.Parts.Capacitor.Name or "Unknown",
			shieldData.Parts.Generator and shieldData.Parts.Generator.Name or "Unknown"
		)
	end

	local partsLabel = Instance.new("TextLabel")
	partsLabel.Size = UDim2.new(1, -20, 0, 40)
	partsLabel.Position = UDim2.new(0, 10, 0, yOffset)
	partsLabel.BackgroundTransparency = 1
	partsLabel.Text = partsText
	partsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	partsLabel.Font = Enum.Font.GothamMedium
	partsLabel.TextSize = 12
	partsLabel.TextXAlignment = Enum.TextXAlignment.Left
	partsLabel.TextYAlignment = Enum.TextYAlignment.Top
	partsLabel.TextStrokeTransparency = 0.7
	partsLabel.Parent = card

	return card
end

--[[
	Creates a compact shield card for backpack/inventory display
	@param shieldData - Complete shield data structure
	@param parent - Parent GUI element (optional)
	@return Frame - The compact shield card frame
]]
function ShieldCard.CreateCompact(shieldData, parent)
	if not shieldData then
		warn("[ShieldCard] No shield data provided")
		return nil
	end

	local rarityColor = RARITY_COLORS[shieldData.Rarity] or RARITY_COLORS.Common

	-- Main card frame (smaller)
	local card = Instance.new("Frame")
	card.Name = "ShieldCardCompact"
	card.Size = UDim2.new(0, 200, 0, 120)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	card.BorderSizePixel = 0
	card.Parent = parent

	-- Rarity border
	local border = Instance.new("UIStroke")
	border.Color = rarityColor
	border.Thickness = 2
	border.Parent = card

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	-- Shield name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = shieldData.Name
	nameLabel.TextColor3 = rarityColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextScaled = true
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = card

	-- Type and level
	local typeLabel = Instance.new("TextLabel")
	typeLabel.Size = UDim2.new(1, -10, 0, 15)
	typeLabel.Position = UDim2.new(0, 5, 0, 25)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = string.format("Lv.%d Shield", shieldData.Level)
	typeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	typeLabel.Font = Enum.Font.Gotham
	typeLabel.TextSize = 11
	typeLabel.TextXAlignment = Enum.TextXAlignment.Left
	typeLabel.TextStrokeTransparency = 0.5
	typeLabel.Parent = card

	-- Key stats (compact)
	local statsText = string.format(
		"Capacity: %d HP\nRecharge: %.1f HP/s\nDelay: %.1fs\nEffect: %s",
		shieldData.Stats.Capacity,
		shieldData.Stats.RechargeRate,
		shieldData.Stats.RechargeDelay,
		shieldData.Stats.BreakEffect
	)

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -10, 0, 60)
	statsLabel.Position = UDim2.new(0, 5, 0, 45)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = statsText
	statsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 11
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.TextStrokeTransparency = 0.5
	statsLabel.Parent = card

	return card
end

return ShieldCard
