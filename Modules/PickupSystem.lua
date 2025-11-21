--[[
════════════════════════════════════════════════════════════════════════════════
Module: PickupSystem
Location: ReplicatedStorage/Modules/
Description: Handles health and ammo pickups that drop from enemies.
            Gothic visual style with floating animations.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local PickupSystem = {}

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Drop rates
	HealthDropChance = 0.15, -- 15% chance per enemy
	AmmoDropChance = 0.25,   -- 25% chance per enemy

	-- Pickup values
	HealthRestoreAmount = 25, -- HP restored per health pickup
	AmmoRestoreAmount = 30,   -- Ammo restored per ammo pickup

	-- Visual
	PickupSize = Vector3.new(1.5, 1.5, 1.5),
	FloatHeight = 2,
	FloatSpeed = 2,
	FloatAmplitude = 0.5,
	RotationSpeed = 1,

	-- Despawn
	DespawnTime = 30, -- Seconds before pickup despawns

	-- Colors
	HealthColor = Color3.fromRGB(180, 50, 50),   -- Dark red
	AmmoColor = Color3.fromRGB(200, 150, 50),    -- Brass/gold
}

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createPickupModel(pickupType, position)
	local color = pickupType == "Health" and Config.HealthColor or Config.AmmoColor
	local icon = pickupType == "Health" and "+" or "●"

	-- Create container
	local model = Instance.new("Model")
	model.Name = pickupType .. "Pickup"

	-- Main pickup part (invisible collision)
	local part = Instance.new("Part")
	part.Name = "PickupPart"
	part.Size = Config.PickupSize
	part.Position = position + Vector3.new(0, Config.FloatHeight, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part:SetAttribute("PickupType", pickupType)
	part.Parent = model

	-- Visual crystal/orb
	local visual = Instance.new("Part")
	visual.Name = "Visual"
	visual.Shape = Enum.PartType.Ball
	visual.Size = Config.PickupSize * 0.8
	visual.Position = part.Position
	visual.Anchored = true
	visual.CanCollide = false
	visual.Color = color
	visual.Material = Enum.Material.Neon
	visual.CastShadow = false
	visual.Parent = model

	-- Inner glow
	local innerGlow = Instance.new("Part")
	innerGlow.Name = "InnerGlow"
	innerGlow.Shape = Enum.PartType.Ball
	innerGlow.Size = Config.PickupSize * 0.5
	innerGlow.Position = part.Position
	innerGlow.Anchored = true
	innerGlow.CanCollide = false
	innerGlow.Color = Color3.new(1, 1, 1)
	innerGlow.Material = Enum.Material.Neon
	innerGlow.Transparency = 0.3
	innerGlow.CastShadow = false
	innerGlow.Parent = model

	-- Point light
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 3
	light.Range = 15
	light.Parent = visual

	-- Billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = icon
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = billboard

	model.PrimaryPart = part
	return model, part, visual, innerGlow
end

-- ════════════════════════════════════════════════════════════════════════════
-- FLOATING ANIMATION
-- ════════════════════════════════════════════════════════════════════════════

local function animatePickup(model, part, visual, innerGlow, basePosition)
	local startTime = tick()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not part.Parent or not model.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local elapsed = tick() - startTime

		-- Floating motion
		local floatOffset = math.sin(elapsed * Config.FloatSpeed) * Config.FloatAmplitude
		local newY = basePosition.Y + Config.FloatHeight + floatOffset

		-- Rotation
		local rotation = CFrame.Angles(0, elapsed * Config.RotationSpeed, 0)

		local newPos = Vector3.new(basePosition.X, newY, basePosition.Z)
		part.Position = newPos
		visual.CFrame = CFrame.new(newPos) * rotation
		innerGlow.CFrame = CFrame.new(newPos) * rotation * CFrame.Angles(math.rad(45), 0, 0)

		-- Pulsing light
		local light = visual:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = 3 + math.sin(elapsed * 3) * 1
		end
	end)

	return connection
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP LOGIC
-- ════════════════════════════════════════════════════════════════════════════

local function onPickupTouched(part, player, pickupType)
	local character = player.Character
	if not character then return end

	if pickupType == "Health" then
		-- Heal player
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health < humanoid.MaxHealth then
			local newHealth = math.min(humanoid.Health + Config.HealthRestoreAmount, humanoid.MaxHealth)
			humanoid.Health = newHealth

			print(string.format("[Pickup] %s picked up Health (+%d HP)", player.Name, Config.HealthRestoreAmount))

			-- Play pickup sound
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://5063796048" -- Health pickup sound
			sound.Volume = 0.5
			sound.Parent = part
			sound:Play()
			Debris:AddItem(sound, 1)

			return true
		end
	elseif pickupType == "Ammo" then
		-- Find current weapon and restore ammo
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			-- Add ammo to reserve pool
			local currentPool = tool:GetAttribute("PoolAmmo") or 0
			tool:SetAttribute("PoolAmmo", currentPool + Config.AmmoRestoreAmount)

			print(string.format("[Pickup] %s picked up Ammo (+%d rounds)", player.Name, Config.AmmoRestoreAmount))

			-- Play pickup sound
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://876939830" -- Ammo pickup sound
			sound.Volume = 0.5
			sound.Parent = part
			sound:Play()
			Debris:AddItem(sound, 1)

			return true
		else
			-- No weapon equipped, still allow pickup and store for later
			print(string.format("[Pickup] %s picked up Ammo (no weapon equipped)", player.Name))
			return true
		end
	end

	return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

function PickupSystem.SpawnHealthPickup(position, parent)
	local model, part, visual, innerGlow = createPickupModel("Health", position)
	model.Parent = parent or workspace

	-- Animation
	local connection = animatePickup(model, part, visual, innerGlow, position)

	-- Touch detection (using Region3 for better performance)
	local touchConnection
	touchConnection = RunService.Heartbeat:Connect(function()
		if not part.Parent or not model.Parent then
			if touchConnection then touchConnection:Disconnect() end
			if connection then connection:Disconnect() end
			return
		end

		-- Check for nearby players
		local region = Region3.new(part.Position - Vector3.new(2, 2, 2), part.Position + Vector3.new(2, 2, 2))
		region = region:ExpandToGrid(4)

		for _, part in ipairs(workspace:FindPartsInRegion3(region, nil, 100)) do
			local player = game.Players:GetPlayerFromCharacter(part.Parent)
			if player then
				local success = onPickupTouched(part, player, "Health")
				if success then
					-- Destroy pickup
					if touchConnection then touchConnection:Disconnect() end
					if connection then connection:Disconnect() end
					model:Destroy()
					return
				end
			end
		end
	end)

	-- Auto-despawn
	task.delay(Config.DespawnTime, function()
		if model.Parent then
			if touchConnection then touchConnection:Disconnect() end
			if connection then connection:Disconnect() end
			model:Destroy()
		end
	end)

	return model
end

function PickupSystem.SpawnAmmoPickup(position, parent)
	local model, part, visual, innerGlow = createPickupModel("Ammo", position)
	model.Parent = parent or workspace

	-- Animation
	local connection = animatePickup(model, part, visual, innerGlow, position)

	-- Touch detection
	local touchConnection
	touchConnection = RunService.Heartbeat:Connect(function()
		if not part.Parent or not model.Parent then
			if touchConnection then touchConnection:Disconnect() end
			if connection then connection:Disconnect() end
			return
		end

		-- Check for nearby players
		local region = Region3.new(part.Position - Vector3.new(2, 2, 2), part.Position + Vector3.new(2, 2, 2))
		region = region:ExpandToGrid(4)

		for _, part in ipairs(workspace:FindPartsInRegion3(region, nil, 100)) do
			local player = game.Players:GetPlayerFromCharacter(part.Parent)
			if player then
				local success = onPickupTouched(part, player, "Ammo")
				if success then
					-- Destroy pickup
					if touchConnection then touchConnection:Disconnect() end
					if connection then connection:Disconnect() end
					model:Destroy()
					return
				end
			end
		end
	end)

	-- Auto-despawn
	task.delay(Config.DespawnTime, function()
		if model.Parent then
			if touchConnection then touchConnection:Disconnect() end
			if connection then connection:Disconnect() end
			model:Destroy()
		end
	end)

	return model
end

function PickupSystem.SpawnPickupsFromEnemy(enemyPosition, floorNumber, parent)
	local pickups = {}

	-- Roll for health drop
	if math.random() < Config.HealthDropChance then
		local offset = Vector3.new((math.random() - 0.5) * 3, 0, (math.random() - 0.5) * 3)
		local pickup = PickupSystem.SpawnHealthPickup(enemyPosition + offset, parent)
		table.insert(pickups, pickup)
	end

	-- Roll for ammo drop
	if math.random() < Config.AmmoDropChance then
		local offset = Vector3.new((math.random() - 0.5) * 3, 0, (math.random() - 0.5) * 3)
		local pickup = PickupSystem.SpawnAmmoPickup(enemyPosition + offset, parent)
		table.insert(pickups, pickup)
	end

	return pickups
end

function PickupSystem.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
end

print("[PickupSystem] Module loaded")
return PickupSystem
