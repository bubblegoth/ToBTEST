--[[
════════════════════════════════════════════════════════════════════════════════
Module: ViewmodelController
Location: ReplicatedStorage/src/ (LocalScript in StarterPlayer/StarterPlayerScripts)
Description: First-person weapon viewmodel with procedural model building,
             sway, bobbing, and animation support.

Version: 2.2 - Adapted for src/ architecture
Last Updated: 2025-11-20
════════════════════════════════════════════════════════════════════════════════
--]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Try to load WeaponModelBuilder (optional dependency)
local WeaponModelBuilder
pcall(function()
	WeaponModelBuilder = require(ReplicatedStorage.src.WeaponModelBuilder)
end)

-- Viewmodel constants (fallback if WeaponConstants not available)
local VIEW_MODEL_OFFSET = CFrame.new(0.5, -0.5, -1.5)
local VIEW_MODEL_ADS_OFFSET = CFrame.new(0, -0.3, -0.8)
local VIEW_MODEL_INSPECT_OFFSET = CFrame.new(0, -0.2, -1.2) * CFrame.Angles(0, math.rad(45), 0)
local VIEW_MODEL_LERP_SPEED = 10
local INSPECT_ROTATE_SPEED = 0.5

local BOB_PATTERNS = {
	Idle = { amplitude = 0.02, frequency = 1 },
	Walking = { amplitude = 0.05, frequency = 4 },
	Sprinting = { amplitude = 0.08, frequency = 6 },
	Airborne = { amplitude = 0.01, frequency = 0.5 }
}

local ViewmodelController = {}
ViewmodelController.__index = ViewmodelController

-- ════════════════════════════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ════════════════════════════════════════════════════════════════════════════

function ViewmodelController.new(weaponDataOrController)
	local self = setmetatable({}, ViewmodelController)

	-- Get player directly (more reliable)
	self.player = Players.LocalPlayer

	-- Determine if we received weapon data or a controller
	if weaponDataOrController then
		if weaponDataOrController.tool then
			-- It's a controller, extract data
			self.controller = weaponDataOrController
			self.weaponData = weaponDataOrController.weaponData or nil
		elseif weaponDataOrController.WeaponType then
			-- It's raw weapon data
			self.weaponData = weaponDataOrController
			self.controller = nil
		else
			warn("ViewmodelController: Invalid input - expected weapon data or controller")
			self.weaponData = nil
		end
	else
		warn("ViewmodelController: No weapon data provided")
		self.weaponData = nil
	end

	-- Viewmodel state
	self.viewmodel = nil
	self.viewmodelOffset = Vector3.new(0, 0, 0)
	self.targetOffset = Vector3.new(0, 0, 0)

	-- Animation tracking
	self.swayCFrame = CFrame.new()
	self.bobCFrame = CFrame.new()
	self.currentCFrame = VIEW_MODEL_OFFSET
	self.targetCFrame = VIEW_MODEL_OFFSET

	-- State tracking
	self.isAiming = false
	self.isInspecting = false
	self.enabled = false

	-- Render connection
	self.renderConnection = nil

	return self
end

-- ════════════════════════════════════════════════════════════════════════════
-- VIEWMODEL CREATION
-- ════════════════════════════════════════════════════════════════════════════

function ViewmodelController:createProceduralViewmodel()
	if not self.weaponData then
		warn("ViewmodelController: Cannot create viewmodel - no weapon data")
		return self:createFallbackViewmodel()
	end

	if not WeaponModelBuilder then
		warn("ViewmodelController: WeaponModelBuilder not available, using fallback")
		return self:createFallbackViewmodel()
	end

	-- Use WeaponModelBuilder to create procedural model
	local model = WeaponModelBuilder.BuildWeaponModel(self.weaponData)
	if not model then
		warn("ViewmodelController: WeaponModelBuilder failed, using fallback")
		return self:createFallbackViewmodel()
	end

	model.Name = "Viewmodel"

	-- Make all parts non-colliding and massless for viewmodel
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Massless = true
			part.CastShadow = false
			part.LocalTransparencyModifier = 0
		end
	end

	return model
end

function ViewmodelController:createFallbackViewmodel()
	local viewmodelModel = Instance.new("Model")
	viewmodelModel.Name = "Viewmodel"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.3, 0.3, 1.5)
	handle.Material = Enum.Material.Metal
	handle.BrickColor = BrickColor.new("Really black")
	handle.CanCollide = false
	handle.Anchored = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = viewmodelModel

	-- Add simple barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.15, 0.15, 1.2)
	barrel.Material = Enum.Material.Metal
	barrel.Color = Color3.fromRGB(60, 60, 65)
	barrel.CanCollide = false
	barrel.Anchored = false
	barrel.Massless = true
	barrel.CastShadow = false
	barrel.CFrame = handle.CFrame * CFrame.new(0, 0.1, -1)
	barrel.Parent = viewmodelModel

	local barrelWeld = Instance.new("WeldConstraint")
	barrelWeld.Part0 = handle
	barrelWeld.Part1 = barrel
	barrelWeld.Parent = barrel

	viewmodelModel.PrimaryPart = handle
	return viewmodelModel
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

function ViewmodelController:enable()
	if self.enabled then return end
	self.enabled = true

	self:destroyViewmodel()

	-- Create the viewmodel
	self.viewmodel = self:createProceduralViewmodel()
	if not self.viewmodel then return end

	-- Parent to camera
	self.viewmodel.Parent = Workspace.CurrentCamera

	-- Reset state
	self.targetCFrame = VIEW_MODEL_OFFSET
	self.currentCFrame = VIEW_MODEL_OFFSET
	self.isAiming = false
	self.isInspecting = false
	self.viewmodelOffset = Vector3.new(0, 0, 0)
	self.targetOffset = Vector3.new(0, 0, 0)
	self.bobCFrame = CFrame.new()

	-- Start render loop
	if not self.renderConnection then
		self:startRenderLoop()
	end
end

function ViewmodelController:enableViewmodel()
	return self:enable()
end

function ViewmodelController:disable()
	if not self.enabled then return end
	self.enabled = false

	self:destroyViewmodel()
end

function ViewmodelController:disableViewmodel()
	return self:disable()
end

function ViewmodelController:applyShootKick()
	if not self.viewmodel then return end

	-- Apply recoil kick backward
	self.targetOffset = Vector3.new(0, 0.05, 0.15)

	-- Return to normal position after recoil
	task.delay(0.08, function()
		if self then
			self.targetOffset = Vector3.new(0, 0, 0)
		end
	end)
end

function ViewmodelController:playFireAnimation()
	return self:applyShootKick()
end

function ViewmodelController:startInspect()
	if not self.viewmodel or self.isInspecting then return end

	self.isInspecting = true
	self.targetCFrame = VIEW_MODEL_INSPECT_OFFSET
end

function ViewmodelController:stopInspect()
	if not self.isInspecting then return end

	self.isInspecting = false

	if self.isAiming then
		self.targetCFrame = VIEW_MODEL_ADS_OFFSET
	else
		self.targetCFrame = VIEW_MODEL_OFFSET
	end
end

function ViewmodelController:setAiming(aiming)
	if self.isInspecting then return end

	self.isAiming = aiming
	if aiming then
		self.targetCFrame = VIEW_MODEL_ADS_OFFSET
	else
		self.targetCFrame = VIEW_MODEL_OFFSET
	end
end

function ViewmodelController:playReloadAnimation()
	if not self.viewmodel then return end

	-- Lower weapon during reload
	self.targetOffset = Vector3.new(0, -0.2, 0)

	local reloadTime = 2.0 -- Default reload time
	task.delay(reloadTime * 0.8, function()
		if self and self.enabled then
			self.targetOffset = Vector3.new(0, 0, 0)
		end
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- RENDER LOOP
-- ════════════════════════════════════════════════════════════════════════════

function ViewmodelController:startRenderLoop()
	if self.renderConnection then
		self.renderConnection:Disconnect()
	end

	self.renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		self:update(deltaTime)
	end)
end

function ViewmodelController:update(deltaTime)
	if not self.enabled then return end
	if not self.viewmodel then return end
	if not self.viewmodel.PrimaryPart then return end
	if not Workspace.CurrentCamera then return end

	local character = self.player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not humanoidRootPart then
		return
	end

	-- Smoothly interpolate to target CFrame
	local lerpSpeed = math.min(deltaTime * VIEW_MODEL_LERP_SPEED, 1)
	self.currentCFrame = self.currentCFrame:Lerp(self.targetCFrame, lerpSpeed)

	-- Apply bobbing based on movement
	local movementState = self:getMovementState()
	self:applyBob(deltaTime, movementState)

	-- Smooth offset transition (for recoil)
	self.viewmodelOffset = self.viewmodelOffset:Lerp(self.targetOffset, deltaTime * 15)

	-- Apply inspection rotation if inspecting
	local inspectRotation = CFrame.new()
	if self.isInspecting then
		inspectRotation = CFrame.Angles(0, tick() * INSPECT_ROTATE_SPEED, 0)
	end

	-- Calculate final CFrame (FIXED - convert Vector3 offset to CFrame)
	local baseCFrame = Workspace.CurrentCamera.CFrame * self.currentCFrame
	local offsetCFrame = CFrame.new(self.viewmodelOffset)
	local finalCFrame = baseCFrame * self.bobCFrame * offsetCFrame * inspectRotation

	-- Apply to viewmodel
	self.viewmodel:PivotTo(finalCFrame)
end

function ViewmodelController:getMovementState()
	if not self.player or not self.player.Character then
		return "Idle"
	end

	local character = self.player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not humanoidRootPart then
		return "Idle"
	end

	local velocity = humanoidRootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return "Airborne"
	elseif horizontalSpeed > 14 then
		return "Sprinting"
	elseif horizontalSpeed > 2 then
		return "Walking"
	else
		return "Idle"
	end
end

function ViewmodelController:applyBob(deltaTime, movementState)
	local bobPattern = BOB_PATTERNS[movementState]
	if not bobPattern then
		self.bobCFrame = CFrame.new()
		return
	end

	if bobPattern.amplitude == 0 then
		self.bobCFrame = CFrame.new()
		return
	end

	local character = self.player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local velocity = humanoidRootPart.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	-- Calculate bob based on movement speed and time
	local time = tick()
	local amplitude = bobPattern.amplitude * math.min(speed / 16, 1)
	local bobX = math.sin(time * bobPattern.frequency) * amplitude
	local bobY = math.abs(math.cos(time * bobPattern.frequency * 2)) * amplitude * 0.5

	self.bobCFrame = CFrame.new(bobX, bobY, 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════════════════════════════

function ViewmodelController:destroyViewmodel()
	if self.viewmodel then
		self.viewmodel:Destroy()
		self.viewmodel = nil
	end

	if self.renderConnection then
		self.renderConnection:Disconnect()
		self.renderConnection = nil
	end

	-- Reset state
	self.viewmodelOffset = Vector3.new(0, 0, 0)
	self.targetOffset = Vector3.new(0, 0, 0)
	self.swayCFrame = CFrame.new()
	self.bobCFrame = CFrame.new()
	self.currentCFrame = VIEW_MODEL_OFFSET
	self.targetCFrame = VIEW_MODEL_OFFSET
	self.isAiming = false
	self.isInspecting = false
end

function ViewmodelController:destroy()
	self.enabled = false
	self:destroyViewmodel()
end

-- ════════════════════════════════════════════════════════════════════════════

return ViewmodelController
