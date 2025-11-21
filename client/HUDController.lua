--[[
	HUDController.lua
	Client-side HUD that displays player stats
	Place this in StarterPlayer.StarterPlayerScripts

	Displays:
	- Health (top-left)
	- Ammo (bottom-right) - mag/pool or ∞
	- Souls (top-right)
	- Current Floor (top-center)
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("[HUD] Initializing HUD Controller...")

-- ============================================================
-- HUD CREATION
-- ============================================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Gothic color scheme
local COLOR_PRIMARY = Color3.fromRGB(200, 200, 200) -- Light gray text
local COLOR_SECONDARY = Color3.fromRGB(150, 150, 150) -- Dim gray
local COLOR_ACCENT = Color3.fromRGB(220, 180, 100) -- Gold accent
local COLOR_HEALTH = Color3.fromRGB(180, 50, 50) -- Dark red
local COLOR_BACKGROUND = Color3.fromRGB(20, 20, 20) -- Very dark background
local FONT = Enum.Font.SourceSansBold

-- Helper function to create text labels
local function createLabel(name, position, anchorPoint, textColor, textSize)
	local frame = Instance.new("Frame")
	frame.Name = name .. "Frame"
	frame.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	frame.Position = position
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = COLOR_BACKGROUND
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -10, 1, -10)
	label.Position = UDim2.new(0, 5, 0, 5)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextSize = textSize or 20
	label.TextColor3 = textColor or COLOR_PRIMARY
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = "..."
	label.Parent = frame

	return label
end

-- Health (Top-Left)
local healthLabel = createLabel(
	"Health",
	UDim2.new(0, 10, 0, 10),
	Vector2.new(0, 0),
	COLOR_HEALTH,
	24
)

-- Souls (Top-Right)
local soulsLabel = createLabel(
	"Souls",
	UDim2.new(1, -10, 0, 10),
	Vector2.new(1, 0),
	COLOR_ACCENT,
	22
)
soulsLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Floor (Top-Center)
local floorLabel = createLabel(
	"Floor",
	UDim2.new(0.5, 0, 0, 10),
	Vector2.new(0.5, 0),
	COLOR_PRIMARY,
	26
)
floorLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Ammo (Bottom-Right)
local ammoLabel = createLabel(
	"Ammo",
	UDim2.new(1, -10, 1, -60),
	Vector2.new(1, 1),
	COLOR_PRIMARY,
	28
)
ammoLabel.TextXAlignment = Enum.TextXAlignment.Right

print("[HUD] GUI elements created")

-- ============================================================
-- UPDATE FUNCTIONS
-- ============================================================

local function updateHealth()
	local character = Player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local health = math.floor(humanoid.Health)
	local maxHealth = math.floor(humanoid.MaxHealth)

	healthLabel.Text = string.format("HP: %d / %d", health, maxHealth)
end

local function updateSouls()
	local playerStats = Player:FindFirstChild("PlayerStats")
	if not playerStats then return end

	local soulsValue = playerStats:FindFirstChild("Souls")
	if not soulsValue then return end

	soulsLabel.Text = string.format("⚡ %d Souls", soulsValue.Value)
end

local function updateFloor()
	local playerStats = Player:FindFirstChild("PlayerStats")
	if not playerStats then return end

	local floorValue = playerStats:FindFirstChild("CurrentFloor")
	if not floorValue then return end

	local floor = floorValue.Value

	if floor == 0 then
		floorLabel.Text = "⛪ Church"
	else
		floorLabel.Text = string.format("🏰 Floor %d", floor)
	end
end

local function updateAmmo()
	-- TODO: Implement ammo pool system
	-- For now, show unlimited ammo
	ammoLabel.Text = "∞ Ammo"

	-- Future implementation will show: "12 / 48" (mag / pool)
end

local function updateAllHUD()
	updateHealth()
	updateSouls()
	updateFloor()
	updateAmmo()
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================

local function onCharacterAdded(character)
	print("[HUD] Character added, setting up HUD listeners")

	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		-- Update health when it changes
		humanoid.HealthChanged:Connect(updateHealth)
		updateHealth()
	end

	-- Initial update
	updateAllHUD()
end

-- ============================================================
-- INITIALIZATION
-- ============================================================

-- Set up for current character if it exists
if Player.Character then
	onCharacterAdded(Player.Character)
end

-- Set up for future character spawns
Player.CharacterAdded:Connect(onCharacterAdded)

-- Wait for PlayerStats to be created
local playerStats = Player:WaitForChild("PlayerStats", 10)
if playerStats then
	print("[HUD] PlayerStats found, setting up listeners")

	-- Update when souls change
	local soulsValue = playerStats:WaitForChild("Souls", 5)
	if soulsValue then
		soulsValue.Changed:Connect(updateSouls)
		updateSouls()
	end

	-- Update when floor changes
	local floorValue = playerStats:WaitForChild("CurrentFloor", 5)
	if floorValue then
		floorValue.Changed:Connect(updateFloor)
		updateFloor()
	end
else
	warn("[HUD] PlayerStats not found after 10 seconds!")
end

-- Update HUD every second as a fallback
task.spawn(function()
	while true do
		task.wait(1)
		updateAllHUD()
	end
end)

print("[HUD] HUD Controller initialized successfully")
