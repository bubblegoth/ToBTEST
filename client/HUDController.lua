--[[
    DARKEST DUNGEON x BLOOD CATHEDRAL HUD
    Parchment scrolls, torch-flicker, segmented vigour, gothic ink
    The Ancestor approves. Bring light to the darkness.
]]

print("🗡️ [HUD] Starting Darkest HUD initialization...")

local success, err = pcall(function()

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("🗡️ [HUD] Services loaded, creating ScreenGui...")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DarkestHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

print("🗡️ [HUD] ScreenGui created")

-- DARKEST DUNGEON PALETTE: Sepia, torchlight, blood ink
local C = {
	Parchment  = Color3.fromRGB(194, 172, 139),  -- Aged paper
	DarkP      = Color3.fromRGB(132, 112, 88),   -- Burnt edges
	Ink        = Color3.fromRGB(66, 44, 22),     -- Dark brown ink
	LightInk   = Color3.fromRGB(220, 200, 160),  -- Faded text
	TorchGlow  = Color3.fromRGB(255, 220, 140),  -- Flickering flame
	BloodInk   = Color3.fromRGB(160, 40, 40),    -- Affliction red
	Abyss      = Color3.fromRGB(25, 20, 35),     -- Void background
}

-- Safe fonts that definitely exist in Roblox
local FONT_TITLE  = Enum.Font.SpecialElite  -- Typewriter/gothic style
local FONT_NUM    = Enum.Font.GothamBold     -- Bold numerals
local FONT_DESC   = Enum.Font.Gotham         -- Clean details

print("🗡️ [HUD] Colors and fonts defined")

-- PARCEL: Parchment frame helper
local function parchmentFrame(parent, size, pos, anchor)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = pos
	frame.AnchorPoint = anchor or Vector2.new(0,0)
	frame.BackgroundColor3 = C.Parchment
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Ink
	stroke.Thickness = 3
	stroke.Parent = frame

	-- Burnt edge gradient
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.Parchment),
		ColorSequenceKeypoint.new(0.3, C.DarkP),
		ColorSequenceKeypoint.new(1, C.Parchment)
	})
	grad.Rotation = 90
	grad.Parent = frame

	return frame
end

print("🗡️ [HUD] Creating vignette...")

-- TORCHLIGHT VIGNETTE (flickering overlay)
local vignette = Instance.new("Frame")
vignette.Name = "TorchVignette"
vignette.Size = UDim2.new(1.2, 0, 1.2, 0)
vignette.Position = UDim2.new(-0.1, 0, -0.1, 0)
vignette.BackgroundColor3 = C.Abyss
vignette.BackgroundTransparency = 0.4
vignette.ZIndex = -1
vignette.Parent = screenGui

local vgrad = Instance.new("UIGradient")
vgrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(40, 35, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
})
vgrad.Rotation = 0
vgrad.Parent = vignette

local vcorner = Instance.new("UICorner")
vcorner.CornerRadius = UDim.new(1, 0)
vcorner.Parent = vignette

print("🗡️ [HUD] Creating VIGOUR bar...")

-- VIGOUR BAR (Bottom-Left, segmented scroll)
local vigourScroll = parchmentFrame(screenGui, UDim2.new(0, 480, 0, 110), UDim2.new(0, 30, 1, -130), Vector2.new(0,1))

local vigourBg = Instance.new("Frame")
vigourBg.Size = UDim2.new(1, -20, 0, 45)
vigourBg.Position = UDim2.new(0, 10, 0, 55)
vigourBg.BackgroundColor3 = C.DarkP
vigourBg.Parent = vigourScroll
local bgCorner = Instance.new("UICorner", vigourBg); bgCorner.CornerRadius = UDim.new(0, 8)

local vigourFill = Instance.new("Frame")
vigourFill.Name = "Fill"
vigourFill.Size = UDim2.new(1, -10, 1, -10)
vigourFill.Position = UDim2.new(0, 5, 0, 5)
vigourFill.BackgroundColor3 = C.LightInk
vigourFill.BorderSizePixel = 0
vigourFill.Parent = vigourBg
local fillCorner = Instance.new("UICorner", vigourFill); fillCorner.CornerRadius = UDim.new(0, 6)

-- Segment dividers (4 segments)
for i = 1, 3 do
	local seg = Instance.new("Frame")
	seg.Size = UDim2.new(0, 2, 1, 0)
	seg.Position = UDim2.new(i/4, -1, 0, 0)
	seg.BackgroundColor3 = C.Ink
	seg.BorderSizePixel = 0
	seg.Parent = vigourBg
end

local vigourText = Instance.new("TextLabel")
vigourText.Size = UDim2.new(1, -20, 0, 45)
vigourText.Position = UDim2.new(0, 10, 0, 5)
vigourText.BackgroundTransparency = 1
vigourText.Font = FONT_TITLE
vigourText.TextSize = 32
vigourText.TextColor3 = C.Ink
vigourText.TextStrokeTransparency = 0.5
vigourText.TextStrokeColor3 = C.Abyss
vigourText.Text = "VIGOUR"
vigourText.TextXAlignment = Enum.TextXAlignment.Left
vigourText.Parent = vigourScroll

local vigourNums = Instance.new("TextLabel")
vigourNums.Size = UDim2.new(1, -20, 0, 35)
vigourNums.Position = UDim2.new(0, 10, 0, 45)
vigourNums.BackgroundTransparency = 1
vigourNums.Font = FONT_NUM
vigourNums.TextSize = 28
vigourNums.TextColor3 = C.TorchGlow
vigourNums.TextStrokeTransparency = 0.4
vigourNums.TextStrokeColor3 = C.Abyss
vigourNums.Text = "66 / 100"
vigourNums.TextXAlignment = Enum.TextXAlignment.Right
vigourNums.Parent = vigourScroll

print("🗡️ [HUD] Creating POWDER counter...")

-- QUARTERS (Bottom-Right, massive gothic nums)
local quartersScroll = parchmentFrame(screenGui, UDim2.new(0, 420, 0, 140), UDim2.new(1, -50, 1, -110), Vector2.new(1,1))

local quartersBig = Instance.new("TextLabel")
quartersBig.Size = UDim2.new(1, 0, 0, 100)
quartersBig.Position = UDim2.new(0, 0, 0, 10)
quartersBig.BackgroundTransparency = 1
quartersBig.Font = FONT_NUM
quartersBig.TextSize = 120
quartersBig.TextColor3 = C.TorchGlow
quartersBig.TextStrokeTransparency = 0.3
quartersBig.TextStrokeColor3 = C.Abyss
quartersBig.Text = "33"
quartersBig.TextXAlignment = Enum.TextXAlignment.Right
quartersBig.TextYAlignment = Enum.TextYAlignment.Bottom
quartersBig.Parent = quartersScroll

local quartersRes = Instance.new("TextLabel")
quartersRes.Size = UDim2.new(1, 0, 0, 40)
quartersRes.Position = UDim2.new(0, 0, 1, -40)
quartersRes.BackgroundTransparency = 1
quartersRes.Font = FONT_TITLE
quartersRes.TextSize = 26
quartersRes.TextColor3 = C.Ink
quartersRes.TextStrokeTransparency = 0.6
quartersRes.TextStrokeColor3 = C.Abyss
quartersRes.Text = "POWDER"
quartersRes.TextXAlignment = Enum.TextXAlignment.Center
quartersRes.Parent = quartersScroll

local quartersPool = Instance.new("TextLabel")
quartersPool.Size = UDim2.new(1, 0, 0, 30)
quartersPool.Position = UDim2.new(0, 0, 1, -10)
quartersPool.BackgroundTransparency = 1
quartersPool.Font = FONT_DESC
quartersPool.TextSize = 22
quartersPool.TextColor3 = C.LightInk
quartersPool.Text = "/ 240"
quartersPool.TextXAlignment = Enum.TextXAlignment.Right
quartersPool.Parent = quartersScroll

print("🗡️ [HUD] Creating ESTEEM display...")

-- ESTEEM (Top-Right scroll)
local esteemScroll = parchmentFrame(screenGui, UDim2.new(0, 380, 0, 80), UDim2.new(1, -40, 0, 40), Vector2.new(1,0))

local esteemText = Instance.new("TextLabel")
esteemText.Size = UDim2.new(1,0,1,0)
esteemText.BackgroundTransparency = 1
esteemText.Font = FONT_TITLE
esteemText.TextSize = 34
esteemText.TextColor3 = C.TorchGlow
esteemText.TextStrokeTransparency = 0.5
esteemText.TextStrokeColor3 = C.Abyss
esteemText.Text = "ESTEEM: 66,666"
esteemText.TextXAlignment = Enum.TextXAlignment.Right
esteemText.Parent = esteemScroll

print("🗡️ [HUD] Creating REGION banner...")

-- REGION BANNER (Top-Center, grand inscription)
local regionBanner = parchmentFrame(screenGui, UDim2.new(0, 850, 0, 90), UDim2.new(0.5, 0, 0, 30), Vector2.new(0.5,0))

local regionText = Instance.new("TextLabel")
regionText.Size = UDim2.new(1, -40, 1, 0)
regionText.Position = UDim2.new(0, 20, 0, 0)
regionText.BackgroundTransparency = 1
regionText.Font = FONT_TITLE
regionText.TextSize = 48
regionText.TextColor3 = C.Ink
regionText.TextStrokeTransparency = 0.3
regionText.TextStrokeColor3 = C.Abyss
regionText.Text = "CRYPT OF THE BLOOD SAINT — REGION XIII"
regionText.TextXAlignment = Enum.TextXAlignment.Center
regionText.Parent = regionBanner

print("🗡️ [HUD] Setting up torch flicker effect...")

-- TORCH FLICKER EFFECT
local torchTime = 0
RunService.Heartbeat:Connect(function(dt)
	torchTime += dt * 4
	local flicker = 0.92 + 0.08 * math.sin(torchTime)
	local glowVar = 0.7 + 0.3 * math.sin(torchTime * 1.3)

	-- Flicker vignette
	vignette.BackgroundTransparency = 0.35 + 0.15 * (1 - flicker)

	-- Torch glow on texts
	quartersBig.TextColor3 = Color3.new(C.TorchGlow.R * glowVar, C.TorchGlow.G * glowVar, C.TorchGlow.B * glowVar)
	esteemText.TextColor3 = Color3.new(C.TorchGlow.R * glowVar, C.TorchGlow.G * glowVar, C.TorchGlow.B * glowVar)
	vigourNums.TextColor3 = Color3.new(C.TorchGlow.R * flicker, C.TorchGlow.G * flicker, C.TorchGlow.B * flicker)
end)

-- LOW AFFLICTION PULSE
local afflicted = false

-- UPDATE FUNCTIONS
local currentAmmoData = {MagAmmo = 0, PoolAmmo = 0, MagSize = 1, IsReloading = false}

local function updateVigour()
	local hum = Player.Character and Player.Character:FindFirstChild("Humanoid")
	if not hum then return end
	local hp, maxhp = math.floor(hum.Health), math.floor(hum.MaxHealth)
	vigourNums.Text = hp .. " / " .. maxhp
	local ratio = hp / maxhp
	vigourFill.Size = UDim2.new(math.max(ratio, 0.02), -10, 1, -10)

	local isAfflicted = ratio <= 0.25
	if isAfflicted ~= afflicted then
		afflicted = isAfflicted
		if afflicted then
			vigourFill.BackgroundColor3 = C.BloodInk
			vigourNums.TextColor3 = C.BloodInk
			vigourText.Text = "AFFLICTED!"
		else
			vigourFill.BackgroundColor3 = C.LightInk
			vigourNums.TextColor3 = C.TorchGlow
			vigourText.Text = "VIGOUR"
		end
	end
end

local function updateQuarters()
	local d = currentAmmoData
	if d.IsReloading then
		quartersBig.Text = "..."
		quartersRes.Text = "RELOADING"
		quartersBig.TextColor3 = C.BloodInk
	elseif d.MagSize == 0 then
		quartersBig.Text = "FISTS"
		quartersRes.Text = "ONLY"
		quartersPool.Text = ""
	else
		quartersBig.Text = tostring(d.MagAmmo)
		quartersRes.Text = "POWDER"
		quartersPool.Text = "/ " .. d.PoolAmmo
		local low = d.MagAmmo <= d.MagSize * 0.25
		quartersBig.TextColor3 = low and C.BloodInk or C.TorchGlow
	end
end

local function updateEsteem()
	local stats = Player:FindFirstChild("PlayerStats")
	if stats then
		local souls = stats:FindFirstChild("Souls")
		if souls then esteemText.Text = "ESTEEM: " .. souls.Value end
	end
end

local function updateRegion()
	local stats = Player:FindFirstChild("PlayerStats")
	if stats then
		local floor = stats:FindFirstChild("CurrentFloor")
		if floor then
			local f = floor.Value
			if f == 0 then
				regionText.Text = "SANCTUARY OF LIGHT — PROLOGUE"
			else
				regionText.Text = "CRYPT OF THE BLOOD SAINT — REGION " .. f
			end
		end
	end
end

print("🗡️ [HUD] Setting up character listeners...")

-- BINDINGS
Player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.HealthChanged:Connect(updateVigour)
	updateVigour()
end)

if Player.Character then
	task.spawn(updateVigour)
end

print("🗡️ [HUD] Setting up update loops...")

task.spawn(function()
	while task.wait(0.3) do
		updateEsteem()
		updateRegion()
		updateQuarters()
	end
end)

task.spawn(function()
	local waited = 0
	while waited < 15 and not _G.AmmoUpdateEvent do
		task.wait(0.5)
		waited += 0.5
	end
	if _G.AmmoUpdateEvent then
		print("🗡️ [HUD] AmmoUpdateEvent connected")
		_G.AmmoUpdateEvent.Event:Connect(function(data)
			currentAmmoData = data
			updateQuarters()
		end)
	else
		warn("🗡️ [HUD] AmmoUpdateEvent not found - ammo display will not update")
	end
end)

print("🗡️ DARKEST HUD AWAKENED 🗡️ — RISE, HERO! BRING TORCHLIGHT TO THE VOID.")

end) -- end pcall

if not success then
	warn("🗡️ [HUD] ERROR INITIALIZING HUD:")
	warn(err)
end
