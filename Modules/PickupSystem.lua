--[[
════════════════════════════════════════════════════════════════════════════════
Module: PickupSystem
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Health and ammo pickup system from enemy drops.
             Shiny spheres that fall to ground, auto-pickup or vacuum to player.
Version: 2.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

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
	PickupSize = Vector3.new(1.2, 1.2, 1.2),

	-- Physics
	DropHeight = 3, -- Initial spawn height above ground
	VacuumSpeed = 25, -- Speed at which pickups fly to player
	VacuumRange = 15, -- Range to vacuum pickups when out of combat
	AutoPickupRange = 3, -- Range to auto-pickup when walking over
	CombatCooldown = 3, -- Seconds after damage before out of combat

	-- Despawn
	DespawnTime = 30, -- Seconds before pickup despawns

	-- Colors
	HealthColor = Color3.fromRGB(200, 50, 50),   -- Bright red
	AmmoColor = Color3.fromRGB(220, 180, 60),    -- Bright gold
}

-- Track player combat state
local playerLastDamageTime = {}

-- ════════════════════════════════════════════════════════════════════════════
-- COMBAT STATE
-- ════════════════════════════════════════════════════════════════════════════

function PickupSystem.MarkPlayerInCombat(player)
	playerLastDamageTime[player.UserId] = tick()
end

local function isPlayerInCombat(player)
	local lastDamage = playerLastDamageTime[player.UserId]
	if not lastDamage then return false end
	return (tick() - lastDamage) < Config.CombatCooldown
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP CREATION
-- ════════════════════════════════════════════════════════════════════════════

local function createPickupSphere(pickupType, position)
	local color = pickupType == "Health" and Config.HealthColor or Config.AmmoColor

	-- Main pickup sphere
	local sphere = Instance.new("Part")
	sphere.Name = pickupType .. "Pickup"
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Config.PickupSize
	sphere.Position = position + Vector3.new(0, Config.DropHeight, 0)
	sphere.Color = color
	sphere.Material = Enum.Material.Neon
	sphere.CanCollide = false -- No collision
	sphere.Anchored = false -- Let it fall
	sphere.CastShadow = false
	sphere:SetAttribute("PickupType", pickupType)
	sphere:SetAttribute("IsGrounded", false)

	-- Point light for glow
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 4
	light.Range = 20
	light.Parent = sphere

	-- Add BodyVelocity to control fall (prevent bouncing/rolling)
	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(0, 0, 0) -- Initially no force
	bodyVel.Velocity = Vector3.new(0, 0, 0)
	bodyVel.Parent = sphere

	return sphere, bodyVel
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP PHYSICS & ANIMATION
-- ════════════════════════════════════════════════════════════════════════════

local function animatePickup(sphere, bodyVel)
	local startTime = tick()
	local vacuumTarget = nil

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not sphere.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local elapsed = tick() - startTime

		-- Pulsing light effect
		local light = sphere:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = 4 + math.sin(elapsed * 4) * 1.5
		end

		-- Check if grounded (raycast down)
		if not sphere:GetAttribute("IsGrounded") then
			local ray = Ray.new(sphere.Position, Vector3.new(0, -2, 0))
			local hit, hitPos = workspace:FindPartOnRay(ray, sphere)
			if hit then
				-- Hit ground, anchor it
				sphere.Anchored = true
				sphere.Position = hitPos + Vector3.new(0, sphere.Size.Y/2, 0)
				sphere:SetAttribute("IsGrounded", true)
				if bodyVel then bodyVel:Destroy() end
			end
		else
			-- Grounded - check for vacuum or auto-pickup
			local closestPlayer = nil
			local closestDist = math.huge

			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				if character and character.PrimaryPart then
					local dist = (character.PrimaryPart.Position - sphere.Position).Magnitude

					-- Auto-pickup in combat (walk over)
					if dist <= Config.AutoPickupRange then
						closestPlayer = player
						closestDist = 0
						break
					end

					-- Vacuum out of combat
					if not isPlayerInCombat(player) and dist <= Config.VacuumRange then
						if dist < closestDist then
							closestPlayer = player
							closestDist = dist
						end
					end
				end
			end

			-- Vacuum to player
			if closestPlayer and closestDist > Config.AutoPickupRange then
				local character = closestPlayer.Character
				if character and character.PrimaryPart then
					sphere.Anchored = false
					local direction = (character.PrimaryPart.Position - sphere.Position).Unit
					sphere.CFrame = sphere.CFrame + direction * Config.VacuumSpeed * 0.016

					-- Re-check distance for pickup
					if (character.PrimaryPart.Position - sphere.Position).Magnitude <= Config.AutoPickupRange then
						vacuumTarget = closestPlayer
					end
				end
			elseif closestPlayer and closestDist <= Config.AutoPickupRange then
				-- Trigger pickup
				vacuumTarget = closestPlayer
			end

			-- Execute pickup
			if vacuumTarget then
				local success = onPickupTouched(sphere, vacuumTarget, sphere:GetAttribute("PickupType"))
				if success then
					if connection then connection:Disconnect() end
					sphere:Destroy()
					return
				end
			end
		end
	end)

	return connection
end

-- ════════════════════════════════════════════════════════════════════════════
-- PICKUP LOGIC
-- ════════════════════════════════════════════════════════════════════════════

function onPickupTouched(part, player, pickupType)
	local character = player.Character
	if not character then return false end

	if pickupType == "Health" then
		-- Heal player
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health < humanoid.MaxHealth then
			local newHealth = math.min(humanoid.Health + Config.HealthRestoreAmount, humanoid.MaxHealth)
			humanoid.Health = newHealth

			print(string.format("[Pickup] %s picked up Health (+%d HP)", player.Name, Config.HealthRestoreAmount))

			-- Play pickup sound
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://5063796048"
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
			local currentPool = tool:GetAttribute("PoolAmmo") or 0
			tool:SetAttribute("PoolAmmo", currentPool + Config.AmmoRestoreAmount)

			print(string.format("[Pickup] %s picked up Ammo (+%d rounds)", player.Name, Config.AmmoRestoreAmount))

			-- Play pickup sound
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxassetid://876939830"
			sound.Volume = 0.5
			sound.Parent = part
			sound:Play()
			Debris:AddItem(sound, 1)

			return true
		else
			-- No weapon equipped, still allow pickup
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
	local sphere, bodyVel = createPickupSphere("Health", position)
	sphere.Parent = parent or workspace

	-- Start animation/vacuum system
	local connection = animatePickup(sphere, bodyVel)

	-- Auto-despawn
	task.delay(Config.DespawnTime, function()
		if sphere.Parent then
			if connection then connection:Disconnect() end
			sphere:Destroy()
		end
	end)

	return sphere
end

function PickupSystem.SpawnAmmoPickup(position, parent)
	local sphere, bodyVel = createPickupSphere("Ammo", position)
	sphere.Parent = parent or workspace

	-- Start animation/vacuum system
	local connection = animatePickup(sphere, bodyVel)

	-- Auto-despawn
	task.delay(Config.DespawnTime, function()
		if sphere.Parent then
			if connection then connection:Disconnect() end
			sphere:Destroy()
		end
	end)

	return sphere
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
