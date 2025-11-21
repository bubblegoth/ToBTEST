--[[
════════════════════════════════════════════════════════════════════════════════
FirstPersonCamera
Location: StarterPlayer/StarterPlayerScripts
Description: Forces first-person camera for FPS gameplay
Version: 1.0
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for player to load
repeat task.wait() until player.Character

-- Force first-person camera
player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMaxZoomDistance = 0.5
player.CameraMinZoomDistance = 0.5

-- Reapply on respawn
player.CharacterAdded:Connect(function(character)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player.CameraMinZoomDistance = 0.5

	-- Hide character limbs from first-person view (optional)
	character:WaitForChild("Humanoid")

	-- Make character parts invisible to local player only
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.LocalTransparencyModifier = 1
		end
	end

	-- Keep updating transparency for new parts
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.LocalTransparencyModifier = 1
		end
	end)
end)

print("[FirstPersonCamera] First-person mode enabled")
