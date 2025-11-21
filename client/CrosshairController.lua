--[[
════════════════════════════════════════════════════════════════════════════════
Module: CrosshairController
Location: StarterPlayer.StarterPlayerScripts/
Description: Gothic-themed crosshair system with dynamic spread.
             Dark, ornate design matching the game's aesthetic.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Mouse = Player:GetMouse()

-- ════════════════════════════════════════════════════════════════════════════
-- GOTHIC CROSSHAIR STYLE
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Colors
	Color = Color3.fromRGB(200, 180, 140), -- Parchment/bone
	OutlineColor = Color3.fromRGB(20, 20, 25), -- Ink black

	-- Sizing
	BaseGap = 6, -- Distance from center
	LineLength = 12, -- Length of each crosshair line
	LineThickness = 2, -- Thickness of crosshair lines
	OutlineThickness = 1, -- Outline thickness
	CenterDotSize = 3, -- Size of center dot

	-- Dynamic spread
	MaxSpreadGap = 20, -- Maximum gap when moving
	SpreadSpeed = 15, -- How fast spread changes
	SpreadDecaySpeed = 10, -- How fast it returns to normal

	-- Visibility
	HideWhenGuiOpen = true, -- Hide when dialog boxes open
}

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE CROSSHAIR GUI
-- ════════════════════════════════════════════════════════════════════════════

local function createCrosshairGUI()
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CrosshairGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100 -- Above most other GUIs
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = PlayerGui

	-- Container at screen center
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 100, 0, 100)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- Function to create a crosshair line with outline
	local function createLine(name, rotation)
		-- Outline (behind)
		local outline = Instance.new("Frame")
		outline.Name = name .. "Outline"
		outline.Size = UDim2.new(0, Config.LineThickness + (Config.OutlineThickness * 2), 0, Config.LineLength)
		outline.BackgroundColor3 = Config.OutlineColor
		outline.BorderSizePixel = 0
		outline.AnchorPoint = Vector2.new(0.5, 1)
		outline.Position = UDim2.new(0.5, 0, 0.5, -Config.BaseGap)
		outline.Rotation = rotation
		outline.ZIndex = 1
		outline.Parent = container

		-- Main line (front)
		local line = Instance.new("Frame")
		line.Name = name
		line.Size = UDim2.new(0, Config.LineThickness, 0, Config.LineLength)
		line.BackgroundColor3 = Config.Color
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 1)
		line.Position = UDim2.new(0.5, 0, 0.5, -Config.BaseGap)
		line.Rotation = rotation
		line.ZIndex = 2
		line.Parent = container

		return line, outline
	end

	-- Create 4 lines (top, right, bottom, left)
	local topLine, topOutline = createLine("TopLine", 0)
	local rightLine, rightOutline = createLine("RightLine", 90)
	local bottomLine, bottomOutline = createLine("BottomLine", 180)
	local leftLine, leftOutline = createLine("LeftLine", 270)

	-- Center dot with outline
	local centerDotOutline = Instance.new("Frame")
	centerDotOutline.Name = "CenterDotOutline"
	centerDotOutline.Size = UDim2.new(0, Config.CenterDotSize + (Config.OutlineThickness * 2), 0, Config.CenterDotSize + (Config.OutlineThickness * 2))
	centerDotOutline.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerDotOutline.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDotOutline.BackgroundColor3 = Config.OutlineColor
	centerDotOutline.BorderSizePixel = 0
	centerDotOutline.ZIndex = 1
	centerDotOutline.Parent = container

	local centerDotOutlineCorner = Instance.new("UICorner")
	centerDotOutlineCorner.CornerRadius = UDim.new(1, 0)
	centerDotOutlineCorner.Parent = centerDotOutline

	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, Config.CenterDotSize, 0, Config.CenterDotSize)
	centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDot.BackgroundColor3 = Config.Color
	centerDot.BorderSizePixel = 0
	centerDot.ZIndex = 2
	centerDot.Parent = container

	local centerDotCorner = Instance.new("UICorner")
	centerDotCorner.CornerRadius = UDim.new(1, 0)
	centerDotCorner.Parent = centerDot

	return {
		ScreenGui = screenGui,
		Container = container,
		Lines = {
			Top = topLine,
			Right = rightLine,
			Bottom = bottomLine,
			Left = leftLine,
		},
		Outlines = {
			Top = topOutline,
			Right = rightOutline,
			Bottom = bottomOutline,
			Left = leftOutline,
		},
		CenterDot = centerDot,
		CenterDotOutline = centerDotOutline,
	}
end

-- ════════════════════════════════════════════════════════════════════════════
-- DYNAMIC CROSSHAIR SPREAD
-- ════════════════════════════════════════════════════════════════════════════

local crosshair = createCrosshairGUI()
local currentGap = Config.BaseGap
local targetGap = Config.BaseGap

-- Update crosshair spread based on movement
local function updateCrosshairSpread(deltaTime)
	local character = Player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	-- Calculate spread based on movement speed (use horizontal velocity)
	local velocity = rootPart.Velocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local moveSpeed = math.min(horizontalSpeed / humanoid.WalkSpeed, 1)
	local isShooting = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

	-- Target gap increases with movement and shooting
	if moveSpeed > 0.1 or isShooting then
		local speedFactor = math.min(moveSpeed, 1)
		targetGap = Config.BaseGap + (Config.MaxSpreadGap - Config.BaseGap) * speedFactor

		if isShooting then
			targetGap = math.max(targetGap, Config.BaseGap + 8)
		end
	else
		targetGap = Config.BaseGap
	end

	-- Smoothly interpolate to target gap
	local speed = (currentGap < targetGap) and Config.SpreadSpeed or Config.SpreadDecaySpeed
	currentGap = currentGap + (targetGap - currentGap) * math.min(deltaTime * speed, 1)

	-- Update line positions
	crosshair.Lines.Top.Position = UDim2.new(0.5, 0, 0.5, -currentGap)
	crosshair.Lines.Right.Position = UDim2.new(0.5, currentGap, 0.5, 0)
	crosshair.Lines.Bottom.Position = UDim2.new(0.5, 0, 0.5, currentGap)
	crosshair.Lines.Left.Position = UDim2.new(0.5, -currentGap, 0.5, 0)

	crosshair.Outlines.Top.Position = UDim2.new(0.5, 0, 0.5, -currentGap)
	crosshair.Outlines.Right.Position = UDim2.new(0.5, currentGap, 0.5, 0)
	crosshair.Outlines.Bottom.Position = UDim2.new(0.5, 0, 0.5, currentGap)
	crosshair.Outlines.Left.Position = UDim2.new(0.5, -currentGap, 0.5, 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- VISIBILITY MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

-- Hide crosshair when GUI dialogs are open
local function updateCrosshairVisibility()
	if not Config.HideWhenGuiOpen then
		crosshair.ScreenGui.Enabled = true
		return
	end

	-- Check if Soul Vendor GUI is open
	local vendorGUI = PlayerGui:FindFirstChild("SoulVendorGUI")
	if vendorGUI and vendorGUI.Enabled then
		crosshair.ScreenGui.Enabled = false
		return
	end

	-- Add other GUI checks here as needed

	crosshair.ScreenGui.Enabled = true
end

-- ════════════════════════════════════════════════════════════════════════════
-- RENDER LOOP
-- ════════════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function(deltaTime)
	updateCrosshairSpread(deltaTime)
	updateCrosshairVisibility()
end)

-- Hide default Roblox crosshair and lock mouse for FPS gameplay
Mouse.Icon = ""
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false

print("[CrosshairController] Gothic crosshair initialized - Mouse locked for FPS gameplay")
