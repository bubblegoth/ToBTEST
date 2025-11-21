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
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- Get ViewmodelController for animations (from global, set by ViewmodelController LocalScript)
local ViewmodelController
repeat
	ViewmodelController = _G.ViewmodelController
	if not ViewmodelController then task.wait(0.1) end
until ViewmodelController

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
		Range = tool:GetAttribute("Range") or 500,
		ReloadTime = tool:GetAttribute("ReloadTime") or 2,
		Pellets = tool:GetAttribute("Pellets") or 1,

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

local function getAccuracySpread(accuracy)
	-- Convert accuracy (0-100) to spread in degrees
	local spread = (100 - accuracy) * 0.05 -- 0 accuracy = 5 degrees, 100 accuracy = 0 degrees
	return math.rad(spread)
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
-- SHOOTING
-- ============================================================

local function fireWeapon()
	if not canFire or isReloading then return end
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
		updateAmmoDisplay()
	end

	-- Calculate shot origin and direction
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	-- Apply accuracy spread
	local spread = getAccuracySpread(weaponStats.Accuracy)

	-- Fire pellets (shotguns fire multiple)
	for i = 1, weaponStats.Pellets do
		local pelletDirection = applySpread(direction, spread)

		-- Create projectile
		local projectile = createProjectile(origin, pelletDirection, weaponStats.Damage, weaponStats)

		-- Setup hit detection
		setupProjectileHitDetection(projectile, weaponStats.Damage, weaponStats)
	end

	-- Muzzle flash
	createMuzzleFlash()

	-- Apply recoil animation
	if ViewmodelController and ViewmodelController.ApplyRecoil then
		ViewmodelController:ApplyRecoil(1.0) -- Full recoil intensity
	end

	-- Play shoot sound (you can add custom sounds here)
	-- local shootSound = currentWeapon:FindFirstChild("ShootSound")
	-- if shootSound then shootSound:Play() end

	print(string.format("[ProjectileShooter] Fired! Ammo: %d/%d", ammoInMag, weaponStats.Capacity))
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
	if ViewmodelController and ViewmodelController.PlayReload then
		ViewmodelController:PlayReload()
	end

	print(string.format("[ProjectileShooter] Reloading... (%.1fs)", weaponStats.ReloadTime))

	task.wait(weaponStats.ReloadTime)

	-- Calculate how much ammo we need to fill the magazine
	local ammoNeeded = weaponStats.Capacity - ammoInMag
	local ammoToAdd = math.min(ammoNeeded, ammoPool)

	-- Transfer ammo from pool to magazine
	ammoInMag = ammoInMag + ammoToAdd
	ammoPool = ammoPool - ammoToAdd

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
	ammoInMag = weaponStats.Capacity
	isReloading = false
	canFire = true
	lastFireTime = 0

	-- Initialize ammo pool based on weapon type
	local weaponType = tool:GetAttribute("WeaponType") or "Default"
	ammoPool = AmmoPoolSizes[weaponType] or AmmoPoolSizes.Default

	print(string.format("[ProjectileShooter] Equipped: %s", tool.Name))
	print(string.format("  Damage: %.0f | Fire Rate: %.2fs | Accuracy: %.0f%%",
		weaponStats.Damage, weaponStats.FireRate, weaponStats.Accuracy))
	print(string.format("  Ammo: %d / %d", ammoInMag, ammoPool))

	updateAmmoDisplay()
end

local function onWeaponUnequipped()
	currentWeapon = nil
	weaponStats = {}
	canFire = false

	print("[ProjectileShooter] Weapon unequipped")
end

-- ============================================================
-- INPUT HANDLING
-- ============================================================

local mouseHeld = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseHeld = true
		if currentWeapon then
			fireWeapon()
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		if currentWeapon then
			reload()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		mouseHeld = false
	end
end)

-- Continuous fire while mouse held
RunService.RenderStepped:Connect(function()
	if mouseHeld and currentWeapon and canFire then
		fireWeapon()
	end
end)

-- ============================================================
-- TOOL DETECTION
-- ============================================================

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") and child:GetAttribute("UniqueID") then
		task.wait(0.1) -- Wait for tool to fully equip
		onWeaponEquipped(child)
	end
end)

character.ChildRemoved:Connect(function(child)
	if child:IsA("Tool") and child == currentWeapon then
		onWeaponUnequipped()
	end
end)

-- Check for already equipped weapon
for _, child in pairs(character:GetChildren()) do
	if child:IsA("Tool") and child:GetAttribute("UniqueID") then
		onWeaponEquipped(child)
		break
	end
end

print("[ProjectileShooter] Initialized - Ready to shoot!")
