--[[
	ProjectileShooter.lua
	Client-side projectile-based weapon shooting system
	Uses physical projectiles with ballistics, not hitscan
	Gothic FPS Roguelite - Weapon Combat System

	Place this LocalScript inside StarterPlayer > StarterCharacterScripts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = script.Parent -- Get character from script parent (more reliable)
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- ============================================================
-- SINGLETON PROTECTION - Prevent duplicate instances
-- ============================================================

if _G.ProjectileShooterActive then
	warn("[ProjectileShooter] ⚠️ Duplicate instance detected - terminating old instance")
	if _G.ProjectileShooterCleanup then
		_G.ProjectileShooterCleanup()
	end
end

_G.ProjectileShooterActive = true

-- Store cleanup function for next instance to call
local connections = {}
_G.ProjectileShooterCleanup = function()
	print("[ProjectileShooter] Cleaning up connections...")
	for _, conn in ipairs(connections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	connections = {}
	_G.ProjectileShooterActive = false
end

-- Export function to save current ammo to tool (called before dropping weapon)
_G.ProjectileShooter_SaveAmmo = function()
	if currentWeapon and ammoInMag then
		currentWeapon:SetAttribute("CurrentAmmo", ammoInMag)
		print(string.format("[ProjectileShooter] Saved ammo to tool (on demand): %d", ammoInMag))
		return true
	end
	return false
end

-- Clean up when character is destroyed
humanoid.Died:Connect(function()
	if _G.ProjectileShooterCleanup then
		_G.ProjectileShooterCleanup()
	end
end)

-- ViewmodelController is set by ViewmodelManager LocalScript
-- We'll access it via _G.ViewmodelController when needed (it may be nil if no weapon equipped)
-- No need to block waiting for it - just check before using

-- ============================================================
-- CONFIGURATION
-- ============================================================

local Config = {
	-- Projectile physics
	GravityMultiplier = 0.5, -- Bullet drop (1 = normal gravity, 0 = none)
	ProjectileSize = Vector3.new(0.2, 0.2, 0.6), -- Bullet size
	ProjectileLifetime = 5, -- Seconds before despawn

	-- Visual settings
	TracerEnabled = true,
	TracerLength = 3,
	MuzzleFlashEnabled = true,

	-- Ammo management
	InfiniteAmmo = false, -- Ammo pool system enabled

	-- Reloading
	AutoReload = true,
}

-- ============================================================
-- WEAPON STATE
-- ============================================================

local currentWeapon = nil
local weaponStats = {}
local ammoInMag = 0
local ammoPool = 0 -- Reserve ammo pool
local isReloading = false
local lastFireTime = 0
local canFire = true

-- ADS and combat state
local isAiming = false
local lastMeleeTime = 0
local defaultWalkSpeed = humanoid.WalkSpeed -- Store original walk speed for ADS

-- Spread bloom system
local currentBloom = 0 -- Current bloom accumulation (degrees)
local bloomDecayRate = 2.0 -- Bloom decay per second when not firing
local lastBloomDecayTime = tick()

-- ============================================================
-- AMMO POOL CONFIGURATION (by weapon type)
-- ============================================================

local AmmoPoolSizes = {
	Pistol = 120,      -- 120 rounds reserve
	Revolver = 72,     -- 72 rounds reserve
	SMG = 240,         -- 240 rounds reserve
	Rifle = 180,       -- 180 rounds reserve
	Shotgun = 48,      -- 48 shells reserve
	Sniper = 60,       -- 60 rounds reserve
	HeavyWeapon = 300, -- 300 rounds reserve
	Default = 150,     -- Fallback
}

-- ============================================================
-- REMOTE EVENTS
-- ============================================================

-- Wait for the DealDamage RemoteEvent (created by ServerDamageHandler)
local damageEvent = ReplicatedStorage:WaitForChild("DealDamage", 10)
if not damageEvent then
	warn("[ProjectileShooter] ✗ DealDamage RemoteEvent not found after 10 second wait!")
else
	print("[ProjectileShooter] ✓ DealDamage RemoteEvent connected")
end

-- Create ammo update event for HUD
local ammoUpdateEvent = Instance.new("BindableEvent")
ammoUpdateEvent.Name = "AmmoUpdate"

-- Export for HUD to access
_G.AmmoUpdateEvent = ammoUpdateEvent

-- ============================================================
-- AMMO DISPLAY UPDATE
-- ============================================================

function updateAmmoDisplay()
	-- Fire event with current ammo data for HUD to consume
	ammoUpdateEvent:Fire({
		MagAmmo = ammoInMag,
		PoolAmmo = ammoPool,
		MagSize = weaponStats.Capacity or 0,
		IsReloading = isReloading,
	})
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function getWeaponStats(tool)
	return {
		Damage = tool:GetAttribute("Damage") or 20,
		FireRate = tool:GetAttribute("FireRate") or 0.3,
		Capacity = tool:GetAttribute("Capacity") or 12,
		Accuracy = tool:GetAttribute("Accuracy") or 70,
		Spread = tool:GetAttribute("Spread") or 5, -- Base spread in degrees
		Range = tool:GetAttribute("Range") or 500,
		ReloadTime = tool:GetAttribute("ReloadTime") or 2,
		Pellets = tool:GetAttribute("Pellets") or 1,
		BloomPerShot = tool:GetAttribute("BloomPerShot") or 0.5, -- Degrees added per shot
		MaxBloom = tool:GetAttribute("MaxBloom") or 10, -- Maximum bloom accumulation

		-- Projectile speed (studs per second)
		ProjectileSpeed = tool:GetAttribute("Range") or 500, -- Use range as speed baseline

		-- Special stats
		CritChance = tool:GetAttribute("CritChance") or 0,
		CritDamage = tool:GetAttribute("CritDamage") or 0,
		FireDamage = tool:GetAttribute("FireDamage") or 0,
		FrostDamage = tool:GetAttribute("FrostDamage") or 0,
		ShadowDamage = tool:GetAttribute("ShadowDamage") or 0,
		BurnChance = tool:GetAttribute("BurnChance") or 0,
		SlowChance = tool:GetAttribute("SlowChance") or 0,
	}
end

local function getAccuracySpread()
	--[[
		BORDERLANDS 2 AUTHENTIC ACCURACY SYSTEM

		Formula: Spread (degrees) = (100 - Accuracy) / 12
		- 100 Accuracy = 0° base spread (laser accurate)
		- 88 Accuracy = 1° base spread
		- 70 Accuracy = 2.5° base spread
		- 50 Accuracy = 4.17° base spread

		Hip-fire cone: baseSpread + accuracyPool + bloom
		ADS cone: baseSpread + bloom (accuracyPool removed)

		This matches Borderlands 2's accuracy mechanics exactly.
	]]

	-- Borderlands 2 formula: convert Accuracy stat to spread (degrees)
	local accuracy = weaponStats.Accuracy or 70
	local baseSpread = (100 - accuracy) / 12

	-- AccuracyPool: additional hip-fire inaccuracy (removed when ADS)
	-- Higher values = more penalty for hip-firing
	local accuracyPool = 2.0 -- degrees (standard for most weapons)

	-- Calculate total spread
	local totalSpread
	if isAiming then
		-- ADS: Base spread + bloom (no accuracy pool)
		totalSpread = baseSpread + currentBloom
	else
		-- Hip-fire: Base spread + accuracy pool + bloom
		totalSpread = baseSpread + accuracyPool + currentBloom
	end

	-- Return final spread in radians
	return math.rad(totalSpread)
end

local function applySpread(direction, spreadRadians)
	if spreadRadians <= 0 then return direction end

	-- Random spread within cone
	local randomAngle = math.random() * math.pi * 2
	local randomRadius = math.random() * spreadRadians

	-- Create perpendicular vectors for spread
	local right = direction:Cross(Vector3.new(0, 1, 0)).Unit
	local up = direction:Cross(right).Unit

	-- Apply spread
	local spread = (right * math.cos(randomAngle) + up * math.sin(randomAngle)) * math.tan(randomRadius)
	return (direction + spread).Unit
end

local function updateBloomDecay()
	--[[
		Bloom decays over time when not firing
		Called continuously to reduce bloom accumulation
	]]
	local now = tick()
	local deltaTime = now - lastBloomDecayTime
	lastBloomDecayTime = now

	if currentBloom > 0 then
		-- Decay bloom over time
		currentBloom = math.max(0, currentBloom - (bloomDecayRate * deltaTime))
	end
end

local function addBloom()
	--[[
		Increases bloom when firing
		Capped at MaxBloom from weapon stats
	]]
	local bloomIncrease = weaponStats.BloomPerShot or 0.5
	local maxBloom = weaponStats.MaxBloom or 10

	currentBloom = math.min(maxBloom, currentBloom + bloomIncrease)
end

-- ============================================================
-- PROJECTILE CREATION
-- ============================================================

local function createProjectile(origin, direction, damage, weaponData)
	local projectile = Instance.new("Part")
	projectile.Name = "Projectile"
	projectile.Size = Config.ProjectileSize
	projectile.CFrame = CFrame.new(origin, origin + direction)
	projectile.CanCollide = false
	projectile.Massless = true
	projectile.Material = Enum.Material.Neon

	-- Color based on damage type
	if weaponData.FireDamage and weaponData.FireDamage > 0 then
		projectile.Color = Color3.fromRGB(255, 100, 0)
	elseif weaponData.FrostDamage and weaponData.FrostDamage > 0 then
		projectile.Color = Color3.fromRGB(100, 200, 255)
	elseif weaponData.ShadowDamage and weaponData.ShadowDamage > 0 then
		projectile.Color = Color3.fromRGB(80, 0, 80)
	else
		projectile.Color = Color3.fromRGB(255, 255, 150)
	end

	-- Add velocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bodyVelocity.Velocity = direction * weaponData.ProjectileSpeed
	bodyVelocity.Parent = projectile

	-- Add gravity (bullet drop)
	if Config.GravityMultiplier > 0 then
		local bodyForce = Instance.new("BodyForce")
		bodyForce.Force = Vector3.new(0, -workspace.Gravity * projectile:GetMass() * Config.GravityMultiplier, 0)
		bodyForce.Parent = projectile
	end

	-- Add light
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 10
	light.Color = projectile.Color
	light.Parent = projectile

	-- Store data
	projectile:SetAttribute("Damage", damage)
	projectile:SetAttribute("OwnerUserId", player.UserId)
	projectile:SetAttribute("WeaponType", currentWeapon:GetAttribute("WeaponType"))

	-- Tracer trail
	if Config.TracerEnabled then
		local attachment0 = Instance.new("Attachment")
		attachment0.Parent = projectile

		local attachment1 = Instance.new("Attachment")
		attachment1.Position = Vector3.new(0, 0, -Config.TracerLength)
		attachment1.Parent = projectile

		local trail = Instance.new("Trail")
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1
		trail.Color = ColorSequence.new(projectile.Color)
		trail.Transparency = NumberSequence.new(0.5, 1)
		trail.Lifetime = 0.1
		trail.Parent = projectile
	end

	projectile.Parent = workspace

	-- Auto-despawn
	Debris:AddItem(projectile, Config.ProjectileLifetime)

	return projectile
end

-- ============================================================
-- HIT DETECTION (SERVER-SIDE)
-- ============================================================

local function setupProjectileHitDetection(projectile, damage, weaponData)
	local hasHit = false

	projectile.Touched:Connect(function(hit)
		if hasHit then return end

		-- Ignore player's own character
		if hit:IsDescendantOf(character) then return end

		-- Check if hit an enemy
		local hitModel = hit.Parent
		local humanoid = hitModel and hitModel:FindFirstChild("Humanoid")
		local isEnemy = hitModel and hitModel:GetAttribute("IsEnemy")

		-- Debug: Log what we hit
		if hitModel and humanoid then
			print(string.format("[ProjectileShooter] Hit %s - IsEnemy: %s", hitModel.Name, tostring(isEnemy)))
		end

		if hitModel and humanoid and isEnemy then
			hasHit = true
			print(string.format("[ProjectileShooter] ✓ HIT ENEMY: %s - Sending %d damage", hitModel.Name, damage))

			-- Determine damage type
			local damageType = "Physical"
			if weaponData.FireDamage > 0 then
				damageType = "Fire"
			elseif weaponData.FrostDamage > 0 then
				damageType = "Frost"
			elseif weaponData.ShadowDamage > 0 then
				damageType = "Shadow"
			end

			-- Send damage to server
			if damageEvent then
				damageEvent:FireServer(hitModel, damage, damageType, weaponData)
			else
				warn("[ProjectileShooter] ✗ Cannot send damage - damageEvent is nil!")
			end

			-- Visual impact effect
			local impact = Instance.new("Part")
			impact.Size = Vector3.new(0.5, 0.5, 0.5)
			impact.Position = projectile.Position
			impact.Anchored = true
			impact.CanCollide = false
			impact.Material = Enum.Material.Neon
			impact.Color = projectile.Color
			impact.Transparency = 0.5
			impact.Parent = workspace

			Debris:AddItem(impact, 0.2)

			-- Destroy projectile
			projectile:Destroy()

		elseif hit.CanCollide then
			-- Hit terrain/wall
			hasHit = true

			-- Bullet hole decal
			local hole = Instance.new("Part")
			hole.Size = Vector3.new(0.1, 0.1, 0.1)
			hole.Position = projectile.Position
			hole.Anchored = true
			hole.CanCollide = false
			hole.Transparency = 1
			hole.Parent = workspace

			local decal = Instance.new("Decal")
			decal.Texture = "rbxasset://textures/SplatDecal.png"
			decal.Face = Enum.NormalId.Front
			decal.Parent = hole

			Debris:AddItem(hole, 10)

			projectile:Destroy()
		end
	end)
end

-- ============================================================
-- MUZZLE FLASH
-- ============================================================

local function createMuzzleFlash()
	if not Config.MuzzleFlashEnabled then return end

	local handle = currentWeapon:FindFirstChild("Handle")
	if not handle then return end

	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Size = Vector3.new(0.5, 0.5, 0.5)
	flash.Transparency = 0.5
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 200, 100)
	flash.CanCollide = false
	flash.Anchored = false
	flash.CFrame = handle.CFrame * CFrame.new(0, 0, -2)
	flash.Parent = workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = flash
	weld.Parent = flash

	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range = 15
	light.Color = flash.Color
	light.Parent = flash

	Debris:AddItem(flash, 0.05)
end

-- ============================================================
-- ADS (AIM DOWN SIGHTS)
-- ============================================================

local function toggleADS(aimState)
	isAiming = aimState

	-- Update ViewmodelController offset
	local viewmodel = _G.ViewmodelController
	if viewmodel and viewmodel.setAiming then
		viewmodel:setAiming(isAiming)
	end

	-- Reduce movement speed while aiming
	if humanoid then
		if isAiming then
			humanoid.WalkSpeed = defaultWalkSpeed * 0.6 -- 40% slower when ADS
		else
			humanoid.WalkSpeed = defaultWalkSpeed -- Restore normal speed
		end
	end

	print(string.format("[ProjectileShooter] ADS: %s | WalkSpeed: %.1f", isAiming and "ON" or "OFF", humanoid.WalkSpeed))
end

-- ============================================================
-- MELEE ATTACK
-- ============================================================

local function meleeAttack()
	local now = tick()
	if now - lastMeleeTime < 0.6 then return end -- 0.6 second cooldown
	lastMeleeTime = now

	print("[ProjectileShooter] Melee attack!")

	-- Raycast forward for melee range
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector
	local meleeRange = 5 -- 5 studs

	local ray = Ray.new(origin, direction * meleeRange)
	local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {character})

	if hit then
		local hitModel = hit.Parent
		local humanoid = hitModel and hitModel:FindFirstChild("Humanoid")
		local isEnemy = hitModel and hitModel:GetAttribute("IsEnemy")

		if humanoid and isEnemy then
			-- Calculate melee damage (50% of weapon damage)
			local meleeDamage = math.floor((weaponStats.Damage or 20) * 0.5)

			print(string.format("[ProjectileShooter] ✓ MELEE HIT: %s - %d damage", hitModel.Name, meleeDamage))

			-- Send damage to server
			if damageEvent then
				damageEvent:FireServer(hitModel, meleeDamage, "Physical", weaponStats)
			end

			-- Visual impact
			local impact = Instance.new("Part")
			impact.Size = Vector3.new(1, 1, 1)
			impact.Position = position
			impact.Anchored = true
			impact.CanCollide = false
			impact.Material = Enum.Material.Neon
			impact.Color = Color3.fromRGB(255, 255, 200)
			impact.Transparency = 0.3
			impact.Shape = Enum.PartType.Ball
			impact.Parent = workspace

			Debris:AddItem(impact, 0.3)
		end
	end

	-- Apply melee animation to viewmodel (punch forward)
	local viewmodel = _G.ViewmodelController
	if viewmodel and viewmodel.playMelee then
		viewmodel:playMelee()
	end
end

-- ============================================================
-- SHOOTING
-- ============================================================

local function isAnyGUIOpen()
	-- Check if BackpackUI or SoulVendorGUI is open
	return (_G.BackpackUIOpen == true) or (_G.SoulVendorGUIOpen == true)
end

local function fireWeapon()
	if not canFire or isReloading then return end
	if isAnyGUIOpen() then return end  -- Don't fire if GUI is open
	if ammoInMag <= 0 then
		if Config.AutoReload then
			reload()
		end
		return
	end

	-- Fire rate check
	local now = tick()
	if now - lastFireTime < weaponStats.FireRate then
		return
	end
	lastFireTime = now

	-- Consume ammo
	if not Config.InfiniteAmmo then
		ammoInMag = ammoInMag - 1
		-- Update tool attribute so ammo persists when dropped
		if currentWeapon then
			currentWeapon:SetAttribute("CurrentAmmo", ammoInMag)
		end
		updateAmmoDisplay()
	end

	-- Calculate shot origin and direction
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	-- Calculate spread (includes base spread, accuracy, bloom, and ADS modifier)
	local spread = getAccuracySpread()

	-- Fire pellets (shotguns fire multiple)
	for i = 1, weaponStats.Pellets do
		local pelletDirection = applySpread(direction, spread)

		-- Create projectile
		local projectile = createProjectile(origin, pelletDirection, weaponStats.Damage, weaponStats)

		-- Setup hit detection
		setupProjectileHitDetection(projectile, weaponStats.Damage, weaponStats)
	end

	-- Add bloom after firing (spread increases with consecutive shots)
	addBloom()

	-- Muzzle flash
	createMuzzleFlash()

	-- Apply recoil animation
	local viewmodel = _G.ViewmodelController
	if viewmodel and viewmodel.applyShootKick then
		viewmodel:applyShootKick()
	end

	-- Play shoot sound (you can add custom sounds here)
	-- local shootSound = currentWeapon:FindFirstChild("ShootSound")
	-- if shootSound then shootSound:Play() end

	print(string.format("[ProjectileShooter] Fired! Ammo: %d/%d | Bloom: %.2f°", ammoInMag, weaponStats.Capacity, currentBloom))
end

-- ============================================================
-- RELOADING
-- ============================================================

function reload()
	if isReloading or ammoInMag >= weaponStats.Capacity then return end
	if ammoPool <= 0 then
		print("[ProjectileShooter] ⚠ No ammo in reserve!")
		return
	end

	isReloading = true
	canFire = false

	-- Trigger reload animation
	local viewmodel = _G.ViewmodelController
	if viewmodel and viewmodel.playReloadAnimation then
		viewmodel:playReloadAnimation()
	end

	print(string.format("[ProjectileShooter] Reloading... (%.1fs)", weaponStats.ReloadTime))

	task.wait(weaponStats.ReloadTime)

	-- Calculate how much ammo we need to fill the magazine
	local ammoNeeded = weaponStats.Capacity - ammoInMag
	local ammoToAdd = math.min(ammoNeeded, ammoPool)

	-- Transfer ammo from pool to magazine
	ammoInMag = ammoInMag + ammoToAdd
	ammoPool = ammoPool - ammoToAdd

	-- Update tool attribute so ammo persists when dropped
	if currentWeapon then
		currentWeapon:SetAttribute("CurrentAmmo", ammoInMag)
	end

	isReloading = false
	canFire = true

	print(string.format("[ProjectileShooter] Reload complete! Ammo: %d / %d", ammoInMag, ammoPool))
	updateAmmoDisplay()
end

-- ============================================================
-- WEAPON EQUIP/UNEQUIP
-- ============================================================

local function onWeaponEquipped(tool)
	currentWeapon = tool
	weaponStats = getWeaponStats(tool)

	-- Read current ammo from tool attribute (preserves ammo when picking up dropped weapons)
	local savedAmmo = tool:GetAttribute("CurrentAmmo")
	if savedAmmo and savedAmmo > 0 then
		ammoInMag = savedAmmo
		print(string.format("[ProjectileShooter] Restored ammo from tool: %d", ammoInMag))
	else
		-- New weapon or no saved ammo - start with full magazine
		ammoInMag = weaponStats.Capacity
	end

	isReloading = false
	canFire = true
	lastFireTime = 0

	-- Reset bloom when equipping new weapon
	currentBloom = 0
	lastBloomDecayTime = tick()

	-- Initialize ammo pool based on weapon type
	local weaponType = tool:GetAttribute("WeaponType") or "Default"
	ammoPool = AmmoPoolSizes[weaponType] or AmmoPoolSizes.Default

	print(string.format("[ProjectileShooter] Equipped: %s", tool.Name))
	print(string.format("  Damage: %.0f | Fire Rate: %.2fs | Accuracy: %.0f%% | Spread: %.1f°",
		weaponStats.Damage, weaponStats.FireRate, weaponStats.Accuracy, weaponStats.Spread))
	print(string.format("  Ammo: %d / %d | Bloom: %.1f° per shot (max %.1f°)",
		ammoInMag, ammoPool, weaponStats.BloomPerShot, weaponStats.MaxBloom))

	updateAmmoDisplay()
end

local function onWeaponUnequipped()
	-- Save current ammo to tool attribute before unequipping
	if currentWeapon then
		currentWeapon:SetAttribute("CurrentAmmo", ammoInMag)
		print(string.format("[ProjectileShooter] Saved ammo to tool: %d", ammoInMag))
	end

	currentWeapon = nil
	weaponStats = {}
	canFire = false
	ammoInMag = 0
	ammoPool = 0

	-- Update HUD to show no weapon equipped
	updateAmmoDisplay()

	print("[ProjectileShooter] Weapon unequipped")
end

-- ============================================================
-- INPUT HANDLING
-- ============================================================

local mouseHeld = false

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not _G.ProjectileShooterActive then return end -- Ignore if cleaned up
	if gameProcessed then return end
	if isAnyGUIOpen() then return end  -- Ignore input if GUI is open

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Left click - Fire
		mouseHeld = true
		if currentWeapon then
			fireWeapon()
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		-- Right click - ADS
		if currentWeapon then
			toggleADS(true)
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		-- R - Reload
		if currentWeapon then
			reload()
		end
	elseif input.KeyCode == Enum.KeyCode.V then
		-- V - Melee attack
		if currentWeapon then
			meleeAttack()
		end
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if not _G.ProjectileShooterActive then return end -- Ignore if cleaned up
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseHeld = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		-- Release right click - Exit ADS
		if currentWeapon then
			toggleADS(false)
		end
	end
end))

-- Continuous fire while mouse held + bloom decay
table.insert(connections, RunService.RenderStepped:Connect(function()
	if not _G.ProjectileShooterActive then return end -- Ignore if cleaned up

	-- Clear mouseHeld if GUI is open (prevents firing if GUI opened while holding mouse)
	if isAnyGUIOpen() then
		mouseHeld = false
	end

	-- Update bloom decay (happens continuously)
	updateBloomDecay()

	-- Handle continuous fire
	if mouseHeld and currentWeapon and canFire then
		fireWeapon()
	end
end))

-- ============================================================
-- TOOL DETECTION
-- ============================================================

table.insert(connections, character.ChildAdded:Connect(function(child)
	if not _G.ProjectileShooterActive then return end -- Ignore if cleaned up
	if child:IsA("Tool") and child:GetAttribute("UniqueID") then
		task.wait(0.1) -- Wait for tool to fully equip
		onWeaponEquipped(child)
	end
end))

table.insert(connections, character.ChildRemoved:Connect(function(child)
	if not _G.ProjectileShooterActive then return end -- Ignore if cleaned up
	if child:IsA("Tool") and child == currentWeapon then
		onWeaponUnequipped()
	end
end))

-- Check for already equipped weapon
for _, child in pairs(character:GetChildren()) do
	if child:IsA("Tool") and child:GetAttribute("UniqueID") then
		onWeaponEquipped(child)
		break
	end
end

print("[ProjectileShooter] Initialized - Ready to shoot!")
