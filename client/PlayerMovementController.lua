--[[
════════════════════════════════════════════════════════════════════════════════
PlayerMovementController
Location: StarterPlayer/StarterPlayerScripts
Description: Handles player movement mechanics - sprint, crouch, slide
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

print("[PlayerMovement] Initializing...")

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Walk speeds
	NormalSpeed = 16,
	SprintSpeed = 24,
	CrouchSpeed = 8,

	-- Camera heights
	NormalCameraHeight = 2,
	CrouchCameraHeight = 0.5,
	CameraLerpSpeed = 10,

	-- Slide
	SlideSpeed = 35,
	SlideDuration = 0.8,
	SlideDeceleration = 0.9,
	SlideCooldown = 1.0,
	MinSprintTimeForSlide = 0.3, -- Must sprint for at least this long

	-- Keybinds
	SprintKey = Enum.KeyCode.LeftShift,
	CrouchKey = Enum.KeyCode.LeftControl,
}

-- ════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════

local state = {
	isSprinting = false,
	isCrouching = false,
	isSliding = false,
	sprintStartTime = 0,
	lastSlideTime = 0,
	currentCameraOffset = Config.NormalCameraHeight,
	slideVelocity = nil,
}

-- ════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

local function getCharacter()
	return player.Character
end

local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChild("Humanoid")
end

local function getRootPart()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function isMoving()
	local humanoid = getHumanoid()
	if not humanoid then return false end

	-- Use MoveDirection (older, more compatible) instead of MoveVector
	local moveDir = humanoid.MoveDirection
	if moveDir and moveDir.Magnitude > 0.1 then
		return true
	end

	-- Fallback: Check velocity
	local rootPart = getRootPart()
	if rootPart then
		local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity
		return velocity.Magnitude > 1
	end

	return false
end

local function canSlide()
	local timeSinceLastSlide = tick() - state.lastSlideTime
	local sprintDuration = tick() - state.sprintStartTime

	return state.isSprinting
		and sprintDuration >= Config.MinSprintTimeForSlide
		and timeSinceLastSlide >= Config.SlideCooldown
		and isMoving()
end

-- ════════════════════════════════════════════════════════════════════════════
-- MOVEMENT STATES
-- ════════════════════════════════════════════════════════════════════════════

local function startSprint()
	if state.isCrouching or state.isSliding then return end

	local humanoid = getHumanoid()
	if not humanoid then return end

	state.isSprinting = true
	state.sprintStartTime = tick()
	humanoid.WalkSpeed = Config.SprintSpeed

	print("[PlayerMovement] Sprint started")
end

local function stopSprint()
	if not state.isSprinting then return end

	local humanoid = getHumanoid()
	if not humanoid then return end

	state.isSprinting = false

	if not state.isCrouching and not state.isSliding then
		humanoid.WalkSpeed = Config.NormalSpeed
	end

	print("[PlayerMovement] Sprint stopped")
end

local function startCrouch()
	if state.isSliding then return end

	-- Check if we should slide instead
	if canSlide() then
		startSlide()
		return
	end

	local humanoid = getHumanoid()
	if not humanoid then return end

	state.isCrouching = true
	state.isSprinting = false
	humanoid.WalkSpeed = Config.CrouchSpeed

	print("[PlayerMovement] Crouch started")
end

local function stopCrouch()
	if not state.isCrouching then return end

	local humanoid = getHumanoid()
	if not humanoid then return end

	state.isCrouching = false
	humanoid.WalkSpeed = Config.NormalSpeed

	print("[PlayerMovement] Crouch stopped")
end

local function startSlide()
	if state.isSliding then return end

	local humanoid = getHumanoid()
	local rootPart = getRootPart()
	if not humanoid or not rootPart then return end

	state.isSliding = true
	state.isSprinting = false
	state.isCrouching = true
	state.lastSlideTime = tick()

	-- Apply slide velocity
	local slideDirection = rootPart.CFrame.LookVector
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "SlideVelocity"
	bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
	bodyVelocity.Velocity = slideDirection * Config.SlideSpeed
	bodyVelocity.Parent = rootPart

	state.slideVelocity = bodyVelocity

	-- Set crouch speed
	humanoid.WalkSpeed = Config.CrouchSpeed

	print("[PlayerMovement] Slide started")

	-- Slide timer
	task.spawn(function()
		local startTime = tick()
		while state.isSliding and (tick() - startTime) < Config.SlideDuration do
			if state.slideVelocity and state.slideVelocity.Parent then
				-- Gradually reduce slide velocity
				local progress = (tick() - startTime) / Config.SlideDuration
				local currentSpeed = Config.SlideSpeed * (1 - progress * Config.SlideDeceleration)
				state.slideVelocity.Velocity = slideDirection * math.max(currentSpeed, 0)
			end
			task.wait()
		end

		-- End slide
		if state.slideVelocity and state.slideVelocity.Parent then
			state.slideVelocity:Destroy()
		end
		state.slideVelocity = nil
		state.isSliding = false

		print("[PlayerMovement] Slide ended")
	end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- CAMERA ADJUSTMENT
-- ════════════════════════════════════════════════════════════════════════════

local function updateCamera(dt)
	local humanoid = getHumanoid()
	if not humanoid then return end

	-- Target camera height based on state
	local targetHeight = Config.NormalCameraHeight
	if state.isCrouching or state.isSliding then
		targetHeight = Config.CrouchCameraHeight
	end

	-- Smooth lerp
	state.currentCameraOffset = state.currentCameraOffset + (targetHeight - state.currentCameraOffset) * dt * Config.CameraLerpSpeed

	-- Apply to humanoid camera offset
	humanoid.CameraOffset = Vector3.new(0, state.currentCameraOffset, 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ════════════════════════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Config.SprintKey then
		startSprint()
	elseif input.KeyCode == Config.CrouchKey then
		startCrouch()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Config.SprintKey then
		stopSprint()
	elseif input.KeyCode == Config.CrouchKey then
		stopCrouch()
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- UPDATE LOOP
-- ════════════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function(dt)
	updateCamera(dt)
end)

-- ════════════════════════════════════════════════════════════════════════════
-- CHARACTER SETUP
-- ════════════════════════════════════════════════════════════════════════════

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Reset state
	state.isSprinting = false
	state.isCrouching = false
	state.isSliding = false
	state.currentCameraOffset = Config.NormalCameraHeight

	-- Set default speed
	humanoid.WalkSpeed = Config.NormalSpeed

	print("[PlayerMovement] Character setup complete")
end

-- Setup current character
if player.Character then
	setupCharacter(player.Character)
end

-- Setup future characters
player.CharacterAdded:Connect(setupCharacter)

print("[PlayerMovement] System ready")
print("[PlayerMovement] Controls:")
print("  • Hold SHIFT to Sprint")
print("  • Hold CTRL to Crouch")
print("  • Sprint + CTRL to Slide")

return {}
