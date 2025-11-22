--[[
════════════════════════════════════════════════════════════════════════════════
Script: ViewmodelManager
Location: StarterPlayer > StarterCharacterScripts
Type: LocalScript
Description: Manages weapon viewmodel lifecycle - creates, updates, and destroys
             viewmodels when weapons are equipped/unequipped.
             Exports viewmodel controller to _G for ProjectileShooter access.

Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

print("[ViewmodelManager] Initializing...")

-- Load ViewmodelController module
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ViewmodelController = require(Modules:WaitForChild("ViewmodelController"))

-- Current viewmodel instance
local currentViewModel = nil
local currentWeapon = nil

-- ════════════════════════════════════════════════════════════════════════════
-- VIEWMODEL LIFECYCLE
-- ════════════════════════════════════════════════════════════════════════════

local function createViewmodel(tool)
	-- Destroy existing viewmodel
	if currentViewModel then
		currentViewModel:destroy()
		currentViewModel = nil
	end

	-- Get weapon data from tool attributes
	local weaponData = {
		Name = tool.Name,
		WeaponType = tool:GetAttribute("WeaponType"),
		Parts = {} -- ViewmodelController will try to build from this
	}

	-- Try to reconstruct Parts from tool attributes if available
	local WeaponToolBuilder = Modules:FindFirstChild("WeaponToolBuilder")
	if WeaponToolBuilder then
		local builder = require(WeaponToolBuilder)
		weaponData = builder:GetWeaponDataFromTool(tool)
	end

	-- Create viewmodel controller
	currentViewModel = ViewmodelController.new(weaponData)
	currentWeapon = tool

	-- Enable the viewmodel
	currentViewModel:enable()

	print(string.format("[ViewmodelManager] Created viewmodel for %s", tool.Name))
end

local function destroyViewmodel()
	if currentViewModel then
		currentViewModel:destroy()
		currentViewModel = nil
	end
	currentWeapon = nil
	print("[ViewmodelManager] Destroyed viewmodel")
end

-- ════════════════════════════════════════════════════════════════════════════
-- WEAPON DETECTION
-- ════════════════════════════════════════════════════════════════════════════

local function onWeaponEquipped(tool)
	-- Only handle tools with UniqueID (our custom weapons)
	if not tool:IsA("Tool") or not tool:GetAttribute("UniqueID") then
		return
	end

	-- Small delay to ensure tool is fully equipped
	task.wait(0.05)

	createViewmodel(tool)
end

local function onWeaponUnequipped(tool)
	if tool == currentWeapon then
		destroyViewmodel()
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLING
-- ════════════════════════════════════════════════════════════════════════════

local function setupCharacter(char)
	character = char

	-- Destroy any existing viewmodel on respawn
	destroyViewmodel()

	-- Watch for tools being equipped
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onWeaponEquipped(child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onWeaponUnequipped(child)
		end
	end)

	-- Check if player already has a weapon equipped
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("UniqueID") then
			onWeaponEquipped(child)
			break
		end
	end
end

-- Setup current character
setupCharacter(character)

-- Handle character respawns
player.CharacterAdded:Connect(setupCharacter)

-- ════════════════════════════════════════════════════════════════════════════
-- EXPORT TO GLOBAL
-- ════════════════════════════════════════════════════════════════════════════

-- Export ViewmodelController class and current instance to _G
_G.ViewmodelController = currentViewModel -- Current instance (can be nil)
_G.ViewmodelClass = ViewmodelController -- Class for creating new instances

-- Update _G when viewmodel changes
local originalCreate = createViewmodel
createViewmodel = function(tool)
	originalCreate(tool)
	_G.ViewmodelController = currentViewModel
end

local originalDestroy = destroyViewmodel
destroyViewmodel = function()
	originalDestroy()
	_G.ViewmodelController = nil
end

print("[ViewmodelManager] ═══════════════════════════════════════")
print("[ViewmodelManager] Viewmodel System Active")
print("[ViewmodelManager] Exported to _G.ViewmodelController")
print("[ViewmodelManager] ═══════════════════════════════════════")
