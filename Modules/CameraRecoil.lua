--[[
════════════════════════════════════════════════════════════════════════════════
Module: CameraRecoil
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Camera recoil system with accumulative kick and smooth recovery.
             Matches the blaster framework pattern - applies recoil each frame
             and lerps back to zero.

Usage:
    local CameraRecoil = require(ReplicatedStorage.Modules.CameraRecoil)
    CameraRecoil.AddRecoil(Vector2.new(2, 0.5)) -- Add vertical and horizontal kick

Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Recoil recovery speed (higher = faster recovery)
	RecoverySpeed = 15,

	-- FOV kick on shoot
	FOVKickAmount = 2,
	FOVRecoverySpeed = 10,

	-- Default FOV (will be updated when ADS changes)
	BaseFOV = 70,

	-- Render priority (after camera, before final render)
	RenderPriority = Enum.RenderPriority.Camera.Value + 2,

	-- Bind name for RenderStepped
	BindName = "WeaponCameraRecoil",
}

-- ════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════

local currentRecoil = Vector2.new(0, 0) -- X = horizontal, Y = vertical
local currentFOVKick = 0
local enabled = false

-- ════════════════════════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

--[[
    Linear interpolation helper
    @param a number - Start value
    @param b number - End value
    @param t number - Interpolation factor (0-1)
    @return number
]]
local function lerp(a, b, t)
	return a + (b - a) * t
end

--[[
    Update function called every render frame
    Applies accumulated recoil to camera and recovers over time
    @param deltaTime number
]]
local function onRenderStepped(deltaTime)
	-- Apply recoil rotation to camera
	-- Matches blaster convention: Y = pitch (vertical), X = yaw (horizontal)
	camera.CFrame = camera.CFrame * CFrame.Angles(currentRecoil.Y * deltaTime, currentRecoil.X * deltaTime, 0)

	-- Recover recoil over time (lerp towards zero)
	local recoveryFactor = math.min(deltaTime * Config.RecoverySpeed, 1)
	currentRecoil = currentRecoil:Lerp(Vector2.zero, recoveryFactor)
end

-- ════════════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ════════════════════════════════════════════════════════════════════════════

local CameraRecoil = {}

--[[
    Adds recoil to the camera (accumulative)
    @param recoilAmount Vector2 - X = horizontal (yaw), Y = vertical (pitch) in radians
]]
function CameraRecoil.AddRecoil(recoilAmount)
	currentRecoil = currentRecoil + recoilAmount
	currentFOVKick = Config.FOVKickAmount
end

--[[
    Adds recoil with random variation
    @param minRecoil Vector2 - Minimum recoil values
    @param maxRecoil Vector2 - Maximum recoil values
]]
function CameraRecoil.AddRandomRecoil(minRecoil, maxRecoil)
	local xDif = maxRecoil.X - minRecoil.X
	local yDif = maxRecoil.Y - minRecoil.Y

	local x = minRecoil.X + math.random() * xDif
	local y = minRecoil.Y + math.random() * yDif

	-- Convert to radians and apply (negative Y for upward kick)
	local recoil = Vector2.new(math.rad(y), math.rad(-x))
	CameraRecoil.AddRecoil(recoil)
end

--[[
    Sets the base FOV (for ADS support)
    @param fov number
]]
function CameraRecoil.SetBaseFOV(fov)
	Config.BaseFOV = fov
end

--[[
    Gets the current base FOV
    @return number
]]
function CameraRecoil.GetBaseFOV()
	return Config.BaseFOV
end

--[[
    Resets all recoil immediately
]]
function CameraRecoil.Reset()
	currentRecoil = Vector2.zero
	currentFOVKick = 0
end

--[[
    Sets the recovery speed
    @param speed number
]]
function CameraRecoil.SetRecoverySpeed(speed)
	Config.RecoverySpeed = speed
end

--[[
    Gets current recoil amount (for debugging)
    @return Vector2
]]
function CameraRecoil.GetCurrentRecoil()
	return currentRecoil
end

--[[
    Enables the recoil system
]]
function CameraRecoil.Enable()
	if enabled then return end
	enabled = true

	Config.BaseFOV = camera.FieldOfView

	RunService:BindToRenderStep(Config.BindName, Config.RenderPriority, onRenderStepped)
end

--[[
    Disables the recoil system
]]
function CameraRecoil.Disable()
	if not enabled then return end
	enabled = false

	RunService:UnbindFromRenderStep(Config.BindName)
	CameraRecoil.Reset()
end

--[[
    Checks if recoil system is enabled
    @return boolean
]]
function CameraRecoil.IsEnabled()
	return enabled
end

-- ════════════════════════════════════════════════════════════════════════════
-- AUTO-INITIALIZE
-- ════════════════════════════════════════════════════════════════════════════

-- Enable by default
CameraRecoil.Enable()

-- ════════════════════════════════════════════════════════════════════════════

return CameraRecoil
