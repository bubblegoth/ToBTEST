--[[
════════════════════════════════════════════════════════════════════════════════
Module: ShieldModelBuilder
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Builds 3D shield models from procedurally generated shield data.
             Creates visual shield devices that attach to player's waist/hip.

Version: 1.0
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local ShieldModelBuilder = {}

-- ============================================================
-- RARITY COLORS
-- ============================================================

local RarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(50, 205, 50),
	Rare = Color3.fromRGB(30, 144, 255),
	Epic = Color3.fromRGB(138, 43, 226),
	Legendary = Color3.fromRGB(255, 215, 0)
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function CreatePart(name, size, cframe, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = false
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function WeldParts(part0, part1)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part1
	return weld
end

-- ============================================================
-- SHIELD MODEL BUILDING
-- ============================================================

function ShieldModelBuilder:BuildShield(shieldData)
	-- Validate shield data
	if not shieldData then
		warn("[ShieldModelBuilder] BuildShield called with nil shieldData")
		return nil
	end

	if not shieldData.Parts then
		warn("[ShieldModelBuilder] shieldData missing Parts field")
		return nil
	end

	local shieldModel = Instance.new("Model")
	shieldModel.Name = shieldData.Name or "Shield Generator"

	-- Get part colors/materials from shield parts
	local capacitorData = shieldData.Parts.Capacitor
	local generatorData = shieldData.Parts.Generator
	local projectorData = shieldData.Parts.Projector

	local rarityColor = RarityColors[shieldData.Rarity] or RarityColors.Common

	-- Base position
	local basePos = CFrame.new(0, 0, 0)

	-- ========================================
	-- Core/Central Hub
	-- ========================================
	local core = CreatePart("Core", Vector3.new(0.4, 0.5, 0.15), basePos,
		capacitorData.Color, capacitorData.Material, shieldModel)
	shieldModel.PrimaryPart = core

	-- Add glow effect to core
	local coreLight = Instance.new("PointLight")
	coreLight.Brightness = 1
	coreLight.Range = 3
	coreLight.Color = rarityColor
	coreLight.Parent = core

	-- ========================================
	-- Projector Emitters (Top/Bottom)
	-- ========================================
	local topEmitter = CreatePart("TopEmitter", Vector3.new(0.25, 0.08, 0.08),
		core.CFrame * CFrame.new(0, 0.3, 0), projectorData.Color, projectorData.Material, shieldModel)
	WeldParts(core, topEmitter)

	local bottomEmitter = CreatePart("BottomEmitter", Vector3.new(0.25, 0.08, 0.08),
		core.CFrame * CFrame.new(0, -0.3, 0), projectorData.Color, projectorData.Material, shieldModel)
	WeldParts(core, bottomEmitter)

	-- ========================================
	-- Generator Coils (Side Rings)
	-- ========================================
	local leftCoil = CreatePart("LeftCoil", Vector3.new(0.06, 0.35, 0.35),
		core.CFrame * CFrame.new(-0.22, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		generatorData.Color, generatorData.Material, shieldModel)
	leftCoil.Shape = Enum.PartType.Cylinder
	WeldParts(core, leftCoil)

	local rightCoil = CreatePart("RightCoil", Vector3.new(0.06, 0.35, 0.35),
		core.CFrame * CFrame.new(0.22, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		generatorData.Color, generatorData.Material, shieldModel)
	rightCoil.Shape = Enum.PartType.Cylinder
	WeldParts(core, rightCoil)

	-- ========================================
	-- Attachment Point (for player waist)
	-- ========================================
	local attachment = Instance.new("Attachment")
	attachment.Name = "ShieldAttachment"
	attachment.Position = Vector3.new(0, 0, 0.1) -- Offset slightly forward
	attachment.Parent = core

	-- ========================================
	-- Special Effects Based on Projector Type
	-- ========================================
	if shieldData.Stats.BreakEffect ~= "None" then
		-- Add special effect particles
		local particles = Instance.new("ParticleEmitter")
		particles.Enabled = true
		particles.Rate = 5
		particles.Lifetime = NumberRange.new(0.5, 1.0)
		particles.Speed = NumberRange.new(0.5, 1.0)
		particles.Color = ColorSequence.new(projectorData.Color)
		particles.Size = NumberSequence.new(0.2, 0.1)
		particles.Transparency = NumberSequence.new(0.5, 1)
		particles.LightEmission = 0.8
		particles.Parent = core

		-- Effect-specific particles
		if shieldData.Stats.BreakEffect == "ExplosivePush" then
			particles.Texture = "rbxasset://textures/particles/fire_main.dds"
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
		elseif shieldData.Stats.BreakEffect == "SlowAura" then
			particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
			particles.Color = ColorSequence.new(Color3.fromRGB(150, 200, 255))
		elseif shieldData.Stats.BreakEffect == "FireDOT" then
			particles.Texture = "rbxasset://textures/particles/fire_main.dds"
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
		end
	end

	-- ========================================
	-- Rarity Glow
	-- ========================================
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.8
	highlight.OutlineTransparency = 0.5
	highlight.FillColor = rarityColor
	highlight.OutlineColor = rarityColor
	highlight.Parent = shieldModel

	-- ========================================
	-- Store Shield Data
	-- ========================================
	shieldModel:SetAttribute("Level", shieldData.Level)
	shieldModel:SetAttribute("Rarity", shieldData.Rarity)
	shieldModel:SetAttribute("Capacity", shieldData.Stats.Capacity)
	shieldModel:SetAttribute("RechargeRate", shieldData.Stats.RechargeRate)
	shieldModel:SetAttribute("RechargeDelay", shieldData.Stats.RechargeDelay)

	return shieldModel
end

-- ============================================================
-- BUILD SHIELD WITH ENERGY FIELD EFFECT
-- ============================================================

function ShieldModelBuilder:BuildShieldWithField(shieldData)
	local model = self:BuildShield(shieldData)
	if not model then return nil end

	-- Add energy field sphere (optional, for when shield is active)
	local field = Instance.new("Part")
	field.Name = "EnergyField"
	field.Size = Vector3.new(5, 5, 5)
	field.Shape = Enum.PartType.Ball
	field.Material = Enum.Material.ForceField
	field.Color = RarityColors[shieldData.Rarity] or RarityColors.Common
	field.Transparency = 0.9
	field.CanCollide = false
	field.Anchored = false
	field.Parent = model

	-- Weld field to core
	WeldParts(model.PrimaryPart, field)

	-- Field is hidden by default (only shows when shield is taking damage)
	field.Transparency = 1

	return model
end

return ShieldModelBuilder
