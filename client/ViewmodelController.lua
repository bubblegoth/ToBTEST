--[[
════════════════════════════════════════════════════════════════════════════════
Module: ViewmodelController  
Location: StarterPlayer/StarterPlayerScripts/
Description: Handles first-person viewmodel rendering with anchor-weld system.
             Gothic pistol fallback with proper camera tracking.

Version: 2.0 - Gothic FPS Roguelite
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[Viewmodel] Initializing...")

-- Configuration
local Config = {
	HipFireOffset = CFrame.new(0.7, -0.5, -1.2) * CFrame.Angles(math.rad(-2), math.rad(-3), 0),
	ADSOffset = CFrame.new(0, -0.3, -0.8),
	TargetOffset = CFrame.new(0.7, -0.5, -1.2) * CFrame.Angles(math.rad(-2), math.rad(-3), 0),
	CurrentOffset = CFrame.new(0.7, -0.5, -1.2) * CFrame.Angles(math.rad(-2), math.rad(-3), 0),
	OffsetLerpSpeed = 12,

	-- Enhanced sway (PlayStation style)
	SwayEnabled = true,
	SwayAmount = 0.035, -- Increased for more noticeable movement
	SwaySpeed = 6, -- Slower, more weighted feel
	SwaySmoothing = 0.15, -- Smooth out sway

	-- Head bob
	BobEnabled = true,
	BobAmount = 0.08, -- More pronounced
	BobSpeed = 12,

	-- Recoil
	RecoilEnabled = true,
	RecoilAmount = 0.15,
	RecoilSpeed = 15,
	RecoilRecovery = 8,

	-- Reload animation
	ReloadEnabled = true,
	ReloadDuration = 1.5,
}

-- State
local currentViewmodel = nil
local currentTool = nil
local renderConnection = nil
local swayOffset = CFrame.new()
local bobOffset = 0
local lastCameraRotation = camera.CFrame.Rotation

-- Animation state
local recoilOffset = CFrame.new()
local currentRecoil = 0
local reloadProgress = 0
local isReloading = false
local meleeProgress = 0
local isMelee = false

local ViewmodelController = {}

-- ════════════════════════════════════════════════════════════════════════════
-- ANIMATION FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

-- Apply recoil kick
function ViewmodelController:ApplyRecoil(intensity)
	if not Config.RecoilEnabled then return end
	intensity = intensity or 1
	currentRecoil = Config.RecoilAmount * intensity
end

-- Start reload animation
function ViewmodelController:PlayReload()
	if not Config.ReloadEnabled or isReloading then return end

	isReloading = true
	reloadProgress = 0

	task.spawn(function()
		local startTime = tick()
		while isReloading and (tick() - startTime) < Config.ReloadDuration do
			reloadProgress = (tick() - startTime) / Config.ReloadDuration
			task.wait()
		end
		isReloading = false
		reloadProgress = 0
	end)
end

-- Set ADS state
function ViewmodelController:SetAiming(aimState)
	if aimState then
		-- Transition to ADS offset
		Config.TargetOffset = Config.ADSOffset
	else
		-- Return to hip fire offset
		Config.TargetOffset = Config.HipFireOffset
	end
end

-- Play melee animation
function ViewmodelController:PlayMelee()
	if isMelee then return end

	isMelee = true
	meleeProgress = 0

	task.spawn(function()
		local duration = 0.4 -- Quick melee
		local startTime = tick()
		while isMelee and (tick() - startTime) < duration do
			meleeProgress = (tick() - startTime) / duration
			task.wait()
		end
		isMelee = false
		meleeProgress = 0
	end)
end

-- Create gothic pistol fallback
local function createGothicPistol()
	local model = Instance.new("Model")
	model.Name = "GothicPistol"

	local gothic = {
		Wood = Color3.fromRGB(45, 30, 22),
		Metal = Color3.fromRGB(35, 35, 40),
		Brass = Color3.fromRGB(140, 110, 70),
		Iron = Color3.fromRGB(55, 50, 45),
	}

	-- Handle (grip)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, 0.6, 0.4)
	handle.Material = Enum.Material.Wood
	handle.Color = gothic.Wood
	handle.CanCollide = false
	handle.Anchored = false
	handle.Massless = true
	handle.CastShadow = false
	handle.Parent = model

	-- Barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.12, 0.12, 1.4)
	barrel.Material = Enum.Material.Metal
	barrel.Color = gothic.Metal
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.CastShadow = false
	barrel.CFrame = handle.CFrame * CFrame.new(0, 0.15, -0.9)
	barrel.Parent = model

	local barrelWeld = Instance.new("WeldConstraint")
	barrelWeld.Part0 = handle
	barrelWeld.Part1 = barrel
	barrelWeld.Parent = barrel

	-- Frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(0.3, 0.25, 0.6)
	frame.Material = Enum.Material.DiamondPlate
	frame.Color = gothic.Iron
	frame.CanCollide = false
	frame.Massless = true
	frame.CastShadow = false
	frame.CFrame = handle.CFrame * CFrame.new(0, 0.15, -0.3)
	frame.Parent = model

	local frameWeld = Instance.new("WeldConstraint")
	frameWeld.Part0 = handle
	frameWeld.Part1 = frame
	frameWeld.Parent = frame

	-- Front sight
	local sight = Instance.new("Part")
	sight.Name = "Sight"
	sight.Size = Vector3.new(0.08, 0.15, 0.08)
	sight.Material = Enum.Material.Metal
	sight.Color = gothic.Brass
	sight.CanCollide = false
	sight.Massless = true
	sight.CastShadow = false
	sight.CFrame = barrel.CFrame * CFrame.new(0, 0.12, -0.6)
	sight.Parent = model

	local sightWeld = Instance.new("WeldConstraint")
	sightWeld.Part0 = barrel
	sightWeld.Part1 = sight
	sightWeld.Parent = sight

	-- Trigger guard
	local trigger = Instance.new("Part")
	trigger.Name = "TriggerGuard"
	trigger.Size = Vector3.new(0.05, 0.15, 0.25)
	trigger.Material = Enum.Material.Metal
	trigger.Color = gothic.Brass
	trigger.CanCollide = false
	trigger.Massless = true
	trigger.CastShadow = false
	trigger.CFrame = handle.CFrame * CFrame.new(0, -0.05, -0.1)
	trigger.Parent = model

	local triggerWeld = Instance.new("WeldConstraint")
	triggerWeld.Part0 = handle
	triggerWeld.Part1 = trigger
	triggerWeld.Parent = trigger

	model.PrimaryPart = handle
	return model
end

-- Prepare parts for viewmodel
local function prepareViewmodelParts(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			part.CastShadow = false
			part.LocalTransparencyModifier = 0
		end
	end
end

-- Create anchor
local function createViewmodelAnchor()
	local anchor = Instance.new("Part")
	anchor.Name = "ViewmodelAnchor"
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Parent = camera
	return anchor
end

-- Calculate sway (PlayStation style - smooth and weighted)
local function calculateSway(dt)
	if not Config.SwayEnabled then return CFrame.new() end

	local currentRotation = camera.CFrame.Rotation
	local rotationDelta = lastCameraRotation:ToObjectSpace(currentRotation)
	lastCameraRotation = currentRotation

	local _, yaw, roll = rotationDelta:ToEulerAnglesYXZ()

	-- More exaggerated sway for cinematic PS1/PS2 feel
	local targetSway = CFrame.Angles(
		roll * Config.SwayAmount * 3,   -- Pitch (up/down)
		-yaw * Config.SwayAmount * 12,  -- Yaw (left/right) - more noticeable
		roll * Config.SwayAmount * 6    -- Roll (tilt)
	)

	-- Smooth interpolation with dampening
	swayOffset = swayOffset:Lerp(targetSway, Config.SwaySmoothing)
	swayOffset = swayOffset:Lerp(CFrame.new(), dt * Config.SwaySpeed)

	return swayOffset
end

-- Calculate bob (enhanced for PlayStation feel)
local function calculateBob(dt)
	if not Config.BobEnabled then return CFrame.new() end

	local character = player.Character
	if not character then return CFrame.new() end

	local velocity = character:FindFirstChild("HumanoidRootPart")
	if velocity then
		local speed = velocity.AssemblyLinearVelocity.Magnitude
		if speed > 1 then
			bobOffset = bobOffset + dt * Config.BobSpeed * (speed / 16)
			local bobY = math.sin(bobOffset) * Config.BobAmount
			local bobX = math.cos(bobOffset * 0.5) * Config.BobAmount * 0.5
			local bobZ = math.sin(bobOffset * 0.5) * Config.BobAmount * 0.3 -- Forward/back movement
			return CFrame.new(bobX, bobY, bobZ)
		end
	end

	bobOffset = bobOffset * 0.95
	return CFrame.new()
end

-- Calculate recoil
local function calculateRecoil(dt)
	if not Config.RecoilEnabled then return CFrame.new() end

	-- Recover from recoil
	if currentRecoil > 0 then
		currentRecoil = math.max(0, currentRecoil - dt * Config.RecoilRecovery)
	end

	-- Apply recoil kick (up and back)
	local recoilKick = CFrame.Angles(
		-currentRecoil * 2,  -- Pitch up
		(math.random() - 0.5) * currentRecoil * 0.5, -- Random horizontal
		0
	) * CFrame.new(0, 0, currentRecoil * 0.3) -- Pull back

	recoilOffset = recoilOffset:Lerp(recoilKick, dt * Config.RecoilSpeed)

	return recoilOffset
end

-- Calculate reload animation
local function calculateReload()
	if not isReloading or not Config.ReloadEnabled then return CFrame.new() end

	-- Sine wave for smooth reload motion (dip down and rotate)
	local progress = reloadProgress
	local curve = math.sin(progress * math.pi) -- 0 -> 1 -> 0

	return CFrame.new(0, -curve * 0.5, 0) * CFrame.Angles(curve * 0.3, 0, curve * 0.2)
end

-- Calculate melee animation
local function calculateMelee()
	if not isMelee then return CFrame.new() end

	-- Fast punch forward
	local progress = meleeProgress
	local curve = math.sin(progress * math.pi) -- 0 -> 1 -> 0

	-- Forward thrust with slight upward angle
	return CFrame.new(0, curve * 0.3, -curve * 1.2) * CFrame.Angles(-curve * 0.4, 0, 0)
end

-- Equip viewmodel
function ViewmodelController:EquipViewmodel(tool)
	self:UnequipViewmodel()
	if not tool then return end

	currentTool = tool

	-- Hide the tool's parts so only the viewmodel shows
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		end
	end

	-- Create gothic pistol
	local model = createGothicPistol()
	if not model then
		warn("[Viewmodel] Failed to create model")
		return
	end

	prepareViewmodelParts(model)

	local anchor = createViewmodelAnchor()

	if model.PrimaryPart then
		model.PrimaryPart.Anchored = false

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = anchor
		weld.Part1 = model.PrimaryPart
		weld.Parent = model.PrimaryPart

		model:PivotTo(anchor.CFrame)
	end

	model.Parent = camera
	currentViewmodel = model
	model:SetAttribute("AnchorPart", anchor.Name)

	-- Render loop (with all animations)
	renderConnection = RunService.RenderStepped:Connect(function(dt)
		if not currentViewmodel or not currentViewmodel.Parent then
			self:UnequipViewmodel()
			return
		end

		Config.CurrentOffset = Config.CurrentOffset:Lerp(Config.TargetOffset, math.min(dt * Config.OffsetLerpSpeed, 1))

		-- Calculate all animation offsets
		local sway = calculateSway(dt)
		local bob = calculateBob(dt)
		local recoil = calculateRecoil(dt)
		local reload = calculateReload()
		local melee = calculateMelee()

		-- Combine all animations
		local finalCFrame = camera.CFrame * Config.CurrentOffset * sway * bob * recoil * reload * melee
		anchor.CFrame = finalCFrame
	end)

	print("[Viewmodel] Equipped:", tool.Name)
end

-- Unequip viewmodel
function ViewmodelController:UnequipViewmodel()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if currentViewmodel then
		local anchorName = currentViewmodel:GetAttribute("AnchorPart")
		if anchorName then
			local anchor = camera:FindFirstChild(anchorName)
			if anchor then anchor:Destroy() end
		end

		currentViewmodel:Destroy()
		currentViewmodel = nil
	end

	-- Restore tool visibility
	if currentTool then
		for _, part in ipairs(currentTool:GetDescendants()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			end
		end
	end

	currentTool = nil
end

-- Auto-setup
local function setupCharacter(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("UniqueID") then
			ViewmodelController:EquipViewmodel(child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == currentTool then
			ViewmodelController:UnequipViewmodel()
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("UniqueID") then
			ViewmodelController:EquipViewmodel(child)
			break
		end
	end
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	ViewmodelController:UnequipViewmodel()
	task.wait(0.1)
	setupCharacter(character)
end)

print("[Viewmodel] System ready")

-- Export to global for access from other LocalScripts
_G.ViewmodelController = ViewmodelController

return ViewmodelController
