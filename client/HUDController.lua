--[[
	HUDController.lua
	Client-side HUD that displays player stats
	Place this in StarterPlayer.StarterPlayerScripts

	REVISION: DOOM/BORDERLANDS STYLE
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

-- BORDERLANDS/INDUSTRIAL STYLE
local COLOR_PRIMARY = Color3.fromRGB(255, 255, 255) -- White Text
local COLOR_SECONDARY = Color3.fromRGB(150, 150, 150) -- Dim Gray
local COLOR_ACCENT = Color3.fromRGB(255, 170, 0) -- Bright Orange/Yellow (Eridium/Rare Loot)
local COLOR_HEALTH = Color3.fromRGB(80, 200, 80) -- Bright Green/Lime
local COLOR_BACKGROUND = Color3.fromRGB(50, 50, 50) -- Dark Industrial Gray
local FONT = Enum.Font.RobotoMono -- Monospaced font for industrial feel

-- Helper function to create text labels
local function createLabel(name, position, anchorPoint, textColor, textSize)
	local frame = Instance.new("Frame")
	frame.Name = name .. "Frame"
	frame.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	frame.Position = position
	frame.Size = UDim2.new(0, 250, 0, 45)
	frame.BackgroundTransparency = 0.1
	frame.BackgroundColor3 = COLOR_BACKGROUND
	frame.BorderSizePixel = 1
	frame.BorderColor3 = COLOR_PRIMARY
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
	UDim2.new(0.5, 0, 0, 5),
	Vector2.new(0.5, 0),
	COLOR_PRIMARY,
	28
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

	healthLabel.Text = string.format("SHIELD/HP: %d / %d", health, maxHealth)

	-- Change color if health is low
	if health / maxHealth <= 0.25 then
		healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red for critical health
	else
		healthLabel.TextColor3 = COLOR_HEALTH
	end
end

local function updateSouls()
	local playerStats = Player:FindFirstChild("PlayerStats")
	if not playerStats then return end

	local soulsValue = playerStats:FindFirstChild("Souls")
	if not soulsValue then return end

	soulsLabel.Text = string.format("⚡ %d E-Bits", soulsValue.Value)
end

local function updateFloor()
	local playerStats = Player:FindFirstChild("PlayerStats")
	if not playerStats then return end

	local floorValue = playerStats:FindFirstChild("CurrentFloor")
	if not floorValue then return end

	local floor = floorValue.Value

	if floor == 0 then
		floorLabel.Text = "[ZONE: SANCTUARY]"
	else
		floorLabel.Text = string.format("[ZONE: THE VAULT - LVL %d]", floor)
	end
end

local currentAmmoData = {
	MagAmmo = 0,
	PoolAmmo = 0,
	MagSize = 0,
	IsReloading = false,
}

local function updateAmmo()
	if currentAmmoData.IsReloading then
		ammoLabel.Text = "RELOADING"
		ammoLabel.TextColor3 = COLOR_SECONDARY
	elseif currentAmmoData.MagSize == 0 then
		ammoLabel.Text = "FISTS READY"
		ammoLabel.TextColor3 = COLOR_SECONDARY
	else
		ammoLabel.Text = string.format("%d / %d", currentAmmoData.MagAmmo, currentAmmoData.PoolAmmo)

		-- Color based on ammo status
		if currentAmmoData.MagAmmo == 0 then
			ammoLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red when empty
		elseif currentAmmoData.MagAmmo <= currentAmmoData.MagSize * 0.3 then
			ammoLabel.TextColor3 = COLOR_ACCENT -- Orange/Yellow when low
		else
			ammoLabel.TextColor3 = COLOR_PRIMARY -- White/Normal color
		end
	end
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

-- Listen for ammo updates from ProjectileShooter
task.spawn(function()
	-- Wait for AmmoUpdateEvent to be created by ProjectileShooter
	local maxWait = 10
	local waited = 0
	while not _G.AmmoUpdateEvent and waited < maxWait do
		task.wait(0.5)
		waited = waited + 0.5
	end

	if _G.AmmoUpdateEvent then
		print("[HUD] AmmoUpdateEvent found, setting up ammo listener")
		_G.AmmoUpdateEvent.Event:Connect(function(ammoData)
			currentAmmoData = ammoData
			updateAmmo()
		end)
	else
		warn("[HUD] AmmoUpdateEvent not found after", maxWait, "seconds - ammo display will not update")
	end
end)

-- Update HUD every second as a fallback
task.spawn(function()
	while true do
		task.wait(1)
		updateAllHUD()
	end
end)

print("[HUD] HUD Controller initialized successfully")
