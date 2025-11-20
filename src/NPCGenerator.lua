--[[
	NPCGenerator.lua
	Procedural NPC generation system with randomized body parts
	Similar to WeaponGenerator - selects parts and returns NPC data
	Part of the Gothic FPS Roguelite Dungeon System

	Usage:
		local NPCGenerator = require(ReplicatedStorage.src.NPCGenerator)

		-- Generate Soul Vendor
		local vendor = NPCGenerator.GenerateNPC("SoulVendor")

		-- Generate enemy for floor
		local enemy = NPCGenerator.GenerateEnemy("Cultist", 10)

		-- Build actual model
		local model = NPCGenerator.BuildNPCModel(vendor, workspace)
]]

local NPCGenerator = {}

-- Import dependencies
local NPCConfig = require(script.Parent.NPCConfig)
local NPCParts = require(script.Parent.NPCParts)

-- Random number generator
local rng = Random.new()

-- ============================================================
-- SEED MANAGEMENT
-- ============================================================

function NPCGenerator.SetSeed(seed)
	rng = Random.new(seed)
end

-- ============================================================
-- NPC GENERATION
-- ============================================================

function NPCGenerator.GenerateNPC(npcTypeID, level)
	level = level or 1

	-- Get NPC type configuration
	local npcType = NPCConfig.NPCTypes[npcTypeID]
	if not npcType then
		warn("Invalid NPC type:", npcTypeID)
		return nil
	end

	-- Select parts based on preferences
	local head = NPCGenerator.SelectPart(NPCParts.Heads, npcType.PreferredParts.Heads)
	local torso = NPCGenerator.SelectPart(NPCParts.Torsos, npcType.PreferredParts.Torsos)
	local arms = NPCGenerator.SelectPart(NPCParts.Arms, npcType.PreferredParts.Arms)
	local legs = NPCGenerator.SelectPart(NPCParts.Legs, npcType.PreferredParts.Legs)

	-- Roll for accessory (50% chance)
	local accessory = nil
	if rng:NextNumber() < 0.5 then
		accessory = NPCGenerator.SelectPart(NPCParts.Accessories, npcType.PreferredParts.Accessories)
	end

	-- Calculate stats
	local stats = NPCGenerator.CalculateStats(npcType, level)

	-- Create NPC data object
	local npc = {
		ID = string.format("%s_%d", npcType.ID, rng:NextInteger(1000, 9999)),
		Type = npcType.ID,
		Name = npcType.Name,
		Description = npcType.Description,
		Level = level,

		-- Parts
		Parts = {
			Head = head,
			Torso = torso,
			Arms = arms,
			Legs = legs,
			Accessory = accessory,
		},

		-- Stats
		Stats = stats,

		-- Behavior
		IsHostile = npcType.IsHostile,
		IsInteractable = npcType.IsInteractable,
		Dialogue = npcType.Dialogue,

		-- Special properties
		Transparency = npcType.Transparency or 0,
		CanFly = npcType.CanFly or false,

		-- Loot
		SoulDropChance = npcType.SoulDropChance,
		WeaponDropChance = npcType.WeaponDropChance,
	}

	return npc
end

-- ============================================================
-- PART SELECTION
-- ============================================================

function NPCGenerator.SelectPart(partList, preferredIDs)
	if not preferredIDs or #preferredIDs == 0 then
		-- Random from entire list
		return partList[rng:NextInteger(1, #partList)]
	end

	-- Filter to preferred parts
	local candidates = {}
	for _, part in ipairs(partList) do
		for _, preferredID in ipairs(preferredIDs) do
			if part.Id == preferredID then
				table.insert(candidates, part)
				break
			end
		end
	end

	-- If no matches found, use entire list
	if #candidates == 0 then
		candidates = partList
	end

	return candidates[rng:NextInteger(1, #candidates)]
end

-- ============================================================
-- STAT CALCULATION
-- ============================================================

function NPCGenerator.CalculateStats(npcType, level)
	local stats = {
		MaxHealth = 100,
		CurrentHealth = 100,
		Damage = 10,
		WalkSpeed = 16,
		AttackSpeed = 1.0,
	}

	-- Non-hostile NPCs use fixed stats
	if not npcType.IsHostile then
		stats.MaxHealth = npcType.Health or 9999
		stats.CurrentHealth = stats.MaxHealth
		stats.WalkSpeed = npcType.WalkSpeed or 0
		return stats
	end

	-- Enemy scaling by level
	stats.MaxHealth = npcType.BaseHealth + (npcType.HealthPerLevel * (level - 1))
	stats.CurrentHealth = stats.MaxHealth
	stats.Damage = npcType.BaseDamage + (npcType.DamagePerLevel * (level - 1))
	stats.WalkSpeed = npcType.BaseWalkSpeed or 16
	stats.AttackSpeed = npcType.BaseAttackSpeed or 1.0

	return stats
end

-- ============================================================
-- ENEMY GENERATION (Convenience wrapper)
-- ============================================================

function NPCGenerator.GenerateEnemy(enemyTypeID, level)
	local fullTypeID = "ENEMY_" .. string.upper(enemyTypeID)
	return NPCGenerator.GenerateNPC(fullTypeID, level)
end

-- ============================================================
-- BUILD NPC MODEL (Convert data → actual Roblox model)
-- ============================================================

function NPCGenerator.BuildNPCModel(npcData, parent)
	local model = Instance.new("Model")
	model.Name = npcData.Name
	model.Parent = parent

	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = npcData.Stats.MaxHealth
	humanoid.Health = npcData.Stats.CurrentHealth
	humanoid.WalkSpeed = npcData.Stats.WalkSpeed
	humanoid.Parent = model

	-- Create body parts
	local parts = {}

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = NPCConfig.DefaultSize.Head
	head.Color = npcData.Parts.Head.Color
	head.Material = npcData.Parts.Head.Material
	head.Transparency = npcData.Transparency
	head.Parent = model
	parts.Head = head

	-- Torso (HumanoidRootPart)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = NPCConfig.DefaultSize.Torso
	torso.Color = npcData.Parts.Torso.Color
	torso.Material = npcData.Parts.Torso.Material
	torso.Transparency = npcData.Transparency
	torso.Parent = model
	parts.Torso = torso

	model.PrimaryPart = torso

	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = NPCConfig.DefaultSize.LeftArm
	leftArm.Color = npcData.Parts.Arms.Color
	leftArm.Material = npcData.Parts.Arms.Material
	leftArm.Transparency = npcData.Transparency
	leftArm.Parent = model
	parts.LeftArm = leftArm

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = NPCConfig.DefaultSize.RightArm
	rightArm.Color = npcData.Parts.Arms.Color
	rightArm.Material = npcData.Parts.Arms.Material
	rightArm.Transparency = npcData.Transparency
	rightArm.Parent = model
	parts.RightArm = rightArm

	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Size = NPCConfig.DefaultSize.LeftLeg
	leftLeg.Color = npcData.Parts.Legs.Color
	leftLeg.Material = npcData.Parts.Legs.Material
	leftLeg.Transparency = npcData.Transparency
	leftLeg.Parent = model
	parts.LeftLeg = leftLeg

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLeg"
	rightLeg.Size = NPCConfig.DefaultSize.RightLeg
	rightLeg.Color = npcData.Parts.Legs.Color
	rightLeg.Material = npcData.Parts.Legs.Material
	rightLeg.Transparency = npcData.Transparency
	rightLeg.Parent = model
	parts.RightLeg = rightLeg

	-- Position parts (basic R15 positions)
	torso.CFrame = CFrame.new(0, 3, 0)
	head.CFrame = torso.CFrame + Vector3.new(0, 2.5, 0)
	leftArm.CFrame = torso.CFrame + Vector3.new(-1.5, 0, 0)
	rightArm.CFrame = torso.CFrame + Vector3.new(1.5, 0, 0)
	leftLeg.CFrame = torso.CFrame + Vector3.new(-0.5, -2, 0)
	rightLeg.CFrame = torso.CFrame + Vector3.new(0.5, -2, 0)

	-- Create welds (Motor6D for animation support)
	NPCGenerator.CreateJoints(model, parts)

	-- Add accessory if present
	if npcData.Parts.Accessory and npcData.Parts.Accessory.Id ~= "ACC_NONE" then
		NPCGenerator.AttachAccessory(model, parts, npcData.Parts.Accessory)
	end

	-- Store NPC data in the model
	local npcDataValue = Instance.new("StringValue")
	npcDataValue.Name = "NPCData"
	npcDataValue.Value = game:GetService("HttpService"):JSONEncode({
		Type = npcData.Type,
		Level = npcData.Level,
		IsHostile = npcData.IsHostile,
	})
	npcDataValue.Parent = model

	return model
end

-- ============================================================
-- CREATE JOINTS (For animations)
-- ============================================================

function NPCGenerator.CreateJoints(model, parts)
	local function createMotor6D(name, part0, part1, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0 or CFrame.new()
		motor.C1 = c1 or CFrame.new()
		motor.Parent = part0
		return motor
	end

	-- Neck (Head to Torso)
	createMotor6D("Neck", parts.Torso, parts.Head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))

	-- Shoulders
	createMotor6D("Left Shoulder", parts.Torso, parts.LeftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0, 0.5, 0))
	createMotor6D("Right Shoulder", parts.Torso, parts.RightArm, CFrame.new(1, 0.5, 0), CFrame.new(0, 0.5, 0))

	-- Hips
	createMotor6D("Left Hip", parts.Torso, parts.LeftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	createMotor6D("Right Hip", parts.Torso, parts.RightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
end

-- ============================================================
-- ATTACH ACCESSORY
-- ============================================================

function NPCGenerator.AttachAccessory(model, parts, accessory)
	if not accessory.MeshId or accessory.MeshId == "rbxassetid://0" then
		return -- No mesh, skip
	end

	local accPart = Instance.new("Part")
	accPart.Name = accessory.Name
	accPart.Size = Vector3.new(1, 1, 1) * accessory.Scale
	accPart.Color = accessory.Color
	accPart.Material = accessory.Material
	accPart.CanCollide = false
	accPart.Parent = model

	-- Add mesh
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = accessory.MeshId
	mesh.Scale = accessory.Scale
	mesh.Parent = accPart

	-- Add light if specified
	if accessory.Light and accessory.Light.Enabled then
		local light = Instance.new("PointLight")
		light.Brightness = accessory.Light.Brightness
		light.Range = accessory.Light.Range
		light.Color = accessory.Light.Color
		light.Parent = accPart
	end

	-- Attach to appropriate part
	local attachTo = parts[accessory.AttachmentPoint] or parts.Torso
	local weld = Instance.new("Weld")
	weld.Part0 = attachTo
	weld.Part1 = accPart
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = attachTo
end

-- ============================================================
-- GET NPC DESCRIPTION
-- ============================================================

function NPCGenerator.GetNPCDescription(npc)
	local description = string.format(
		"=== %s (Level %d) ===\n" ..
		"Type: %s\n" ..
		"%s\n\n" ..
		"Parts:\n" ..
		"  Head: %s\n" ..
		"  Torso: %s\n" ..
		"  Arms: %s\n" ..
		"  Legs: %s\n" ..
		"  Accessory: %s\n\n" ..
		"Stats:\n" ..
		"  Health: %d\n" ..
		"  Damage: %d\n" ..
		"  Speed: %d\n" ..
		"  Attack Speed: %.1f\n\n" ..
		"Hostile: %s\n" ..
		"Interactable: %s",
		npc.Name,
		npc.Level,
		npc.Type,
		npc.Description,
		npc.Parts.Head.Name,
		npc.Parts.Torso.Name,
		npc.Parts.Arms.Name,
		npc.Parts.Legs.Name,
		npc.Parts.Accessory and npc.Parts.Accessory.Name or "None",
		npc.Stats.MaxHealth,
		npc.Stats.Damage or 0,
		npc.Stats.WalkSpeed,
		npc.Stats.AttackSpeed or 0,
		npc.IsHostile and "Yes" or "No",
		npc.IsInteractable and "Yes" or "No"
	)

	return description
end

return NPCGenerator
