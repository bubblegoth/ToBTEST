--[[
════════════════════════════════════════════════════════════════════════════════
DIAGNOSTIC TEST - Dungeon Teleport
════════════════════════════════════════════════════════════════════════════════

Run this in Command Bar after clicking Bones_Assortment:
Print dungeon position info
════════════════════════════════════════════════════════════════════════════════
--]]

local player = game.Players:GetChildren()[1]
print("=== DUNGEON TELEPORT DEBUG ===")
print("Player:", player.Name)

local instance = workspace.DungeonInstances:FindFirstChild("DungeonInstance_" .. player.UserId)
if instance then
	print("✓ Instance exists:", instance.Name)

	for _, child in ipairs(instance:GetChildren()) do
		print("  Floor:", child.Name)

		if child:IsA("Model") then
			local spawns = child:FindFirstChild("Spawns")
			if spawns then
				print("    ✓ Spawns folder found")
				local playerSpawn = spawns:FindFirstChild("PlayerSpawn")
				if playerSpawn then
					print("    ✓ PlayerSpawn:", playerSpawn.Position)
				else
					print("    ✗ No PlayerSpawn!")
				end
			else
				print("    ✗ No Spawns folder!")
			end

			-- Check model position
			local primaryPart = child.PrimaryPart
			if primaryPart then
				print("    Model position:", primaryPart.Position)
			end
		end
	end
else
	print("✗ No instance found for player!")
end

print("Player position:", player.Character.HumanoidRootPart.Position)
print("===============================")
