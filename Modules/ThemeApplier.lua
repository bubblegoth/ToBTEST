--[[
════════════════════════════════════════════════════════════════════════════════
Module: ThemeApplier
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Applies visual themes to dungeon instances based on depth.
             Colors, lighting, materials, atmosphere for 5 themed regions.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local ThemeApplier = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local DifficultyScaler = require(ReplicatedStorage.Modules.DifficultyScaler)

-- ════════════════════════════════════════════════════════════════════════════
-- MATERIAL THEMES
-- ════════════════════════════════════════════════════════════════════════════

local MaterialThemes = {
	["Upper Catacombs"] = {
		Floor = Enum.Material.Slate,
		Wall = Enum.Material.Brick,
		Ceiling = Enum.Material.Cobblestone,
		Detail = Enum.Material.Wood,
	},
	["Deep Crypts"] = {
		Floor = Enum.Material.Cobblestone,
		Wall = Enum.Material.Slate,
		Ceiling = Enum.Material.Slate,
		Detail = Enum.Material.CorrodedMetal,
	},
	["Abyssal Halls"] = {
		Floor = Enum.Material.SmoothPlastic,
		Wall = Enum.Material.Fabric,
		Ceiling = Enum.Material.SmoothPlastic,
		Detail = Enum.Material.Metal,
	},
	["Void Depths"] = {
		Floor = Enum.Material.Neon,
		Wall = Enum.Material.ForceField,
		Ceiling = Enum.Material.Glass,
		Detail = Enum.Material.Neon,
	},
	["Hell's Threshold"] = {
		Floor = Enum.Material.Basalt,
		Wall = Enum.Material.Basalt,
		Ceiling = Enum.Material.Basalt,
		Detail = Enum.Material.Neon,
	}
}

-- ════════════════════════════════════════════════════════════════════════════
-- THEME APPLICATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Applies a theme to a dungeon model
	@param dungeonModel - The dungeon model to theme
	@param floorNumber - The floor number for theme selection
]]
function ThemeApplier:ApplyTheme(dungeonModel, floorNumber)
	if not dungeonModel then
		warn("[ThemeApplier] No dungeon model provided")
		return
	end

	-- Get theme data from DifficultyScaler
	local theme = DifficultyScaler:GetTheme(floorNumber)
	local materials = MaterialThemes[theme.Name] or MaterialThemes["Upper Catacombs"]

	print(string.format("[ThemeApplier] Applying theme '%s' to dungeon (Floor %d)", theme.Name, floorNumber))

	-- Apply colors and materials to all parts
	local partCount = 0
	for _, descendant in ipairs(dungeonModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			self:ApplyPartTheme(descendant, theme, materials)
			partCount = partCount + 1
		end
	end

	-- Add atmospheric effects
	self:AddAtmosphericEffects(dungeonModel, theme)

	print(string.format("[ThemeApplier] Themed %d parts with '%s' palette", partCount, theme.Name))
end

--[[
	Applies theme to a single part based on its role
	@param part - The part to theme
	@param theme - The theme data
	@param materials - Material theme table
]]
function ThemeApplier:ApplyPartTheme(part, theme, materials)
	-- Determine part role by name
	local partName = part.Name:lower()
	local palette = theme.ColorPalette

	-- Apply material and color based on part role
	if partName:find("floor") or partName:find("ground") then
		part.Material = materials.Floor
		part.Color = palette.Primary
	elseif partName:find("wall") then
		part.Material = materials.Wall
		part.Color = palette.Secondary
	elseif partName:find("ceiling") or partName:find("roof") then
		part.Material = materials.Ceiling
		part.Color = palette.Primary
	elseif partName:find("pillar") or partName:find("column") then
		part.Material = materials.Detail
		part.Color = palette.Accent
	elseif partName:find("door") or partName:find("gate") then
		part.Material = materials.Detail
		part.Color = palette.Secondary
	else
		-- Default to primary theme color
		part.Color = palette.Primary
	end

	-- Adjust reflectance for deeper floors (darker, grimier)
	local depthFactor = math.min(part:GetAttribute("FloorNumber") or 1, 666) / 666
	part.Reflectance = math.max(0, 0.1 - (depthFactor * 0.1))
end

--[[
	Adds atmospheric effects to a dungeon
	@param dungeonModel - The dungeon model
	@param theme - The theme data
]]
function ThemeApplier:AddAtmosphericEffects(dungeonModel, theme)
	-- Add ambient lighting
	local ambient = Instance.new("Atmosphere")
	ambient.Density = 0.3 + (0.002 * theme.FloorStart) -- Denser fog at deeper levels
	ambient.Offset = 0.25
	ambient.Color = theme.LightingPreset.Ambient
	ambient.Decay = theme.LightingPreset.Ambient
	ambient.Glare = 0
	ambient.Haze = 1 + (0.001 * theme.FloorStart)
	ambient.Parent = dungeonModel

	-- Add point lights in corners for atmosphere
	self:AddSceneLights(dungeonModel, theme)
end

--[[
	Adds atmospheric point lights throughout the dungeon
	@param dungeonModel - The dungeon model
	@param theme - The theme data
]]
function ThemeApplier:AddSceneLights(dungeonModel, theme)
	-- Find floor parts to place lights
	local floors = {}
	for _, part in ipairs(dungeonModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:lower():find("floor") then
			table.insert(floors, part)
		end
	end

	-- Place lights at regular intervals
	local lightInterval = math.max(3, #floors // 10) -- Roughly 10 lights per dungeon
	for i = 1, #floors, lightInterval do
		local floor = floors[i]

		-- Create light holder (invisible part above floor)
		local lightHolder = Instance.new("Part")
		lightHolder.Name = "LightHolder"
		lightHolder.Size = Vector3.new(0.5, 0.5, 0.5)
		lightHolder.Position = floor.Position + Vector3.new(0, 5, 0)
		lightHolder.Anchored = true
		lightHolder.CanCollide = false
		lightHolder.Transparency = 1
		lightHolder.Parent = dungeonModel

		-- Create point light
		local light = Instance.new("PointLight")
		light.Color = theme.ColorPalette.Accent
		light.Brightness = theme.LightingPreset.Brightness
		light.Range = 20
		light.Shadows = true
		light.Parent = lightHolder

		-- Add subtle flicker effect (for torches/candles feel)
		task.spawn(function()
			while lightHolder.Parent do
				light.Brightness = theme.LightingPreset.Brightness + (math.random() * 0.3 - 0.15)
				task.wait(0.1 + math.random() * 0.2)
			end
		end)
	end
end

--[[
	Applies lighting settings to the entire game environment
	(Use with caution - affects global lighting)
	@param floorNumber - The floor number
]]
function ThemeApplier:ApplyGlobalLighting(floorNumber)
	local theme = DifficultyScaler:GetTheme(floorNumber)
	local preset = theme.LightingPreset

	-- Only apply to instanced lighting if possible
	-- This is a simplified version - in production you'd want per-instance lighting
	warn("[ThemeApplier] Global lighting changes affect all players - use with caution")

	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.OutdoorAmbient
	Lighting.Brightness = preset.Brightness
	Lighting.FogEnd = preset.FogEnd
	Lighting.FogColor = preset.Ambient

	print(string.format("[ThemeApplier] Applied global lighting for '%s'", theme.Name))
end

--[[
	Creates themed particle effects for a dungeon
	@param dungeonModel - The dungeon model
	@param floorNumber - The floor number
]]
function ThemeApplier:AddParticleEffects(dungeonModel, floorNumber)
	local theme = DifficultyScaler:GetTheme(floorNumber)

	-- Different particle effects per theme
	local particleTypes = {
		["Upper Catacombs"] = "Dust",      -- Floating dust particles
		["Deep Crypts"] = "Mist",          -- Low-lying mist
		["Abyssal Halls"] = "Smoke",       -- Dark smoke
		["Void Depths"] = "Sparkles",      -- Void energy
		["Hell's Threshold"] = "Fire",     -- Embers and ash
	}

	local particleType = particleTypes[theme.Name]

	if not particleType then return end

	print(string.format("[ThemeApplier] Adding %s particles to dungeon", particleType))

	-- Find a central location for particles
	local center = dungeonModel:GetPivot().Position

	-- Create particle emitter holder
	local emitterHolder = Instance.new("Part")
	emitterHolder.Name = "ParticleEmitter"
	emitterHolder.Size = Vector3.new(1, 1, 1)
	emitterHolder.Position = center + Vector3.new(0, 10, 0)
	emitterHolder.Anchored = true
	emitterHolder.CanCollide = false
	emitterHolder.Transparency = 1
	emitterHolder.Parent = dungeonModel

	-- Create particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 10
	emitter.Lifetime = NumberRange.new(5, 8)
	emitter.Speed = NumberRange.new(0.5, 2)
	emitter.Color = ColorSequence.new(theme.ColorPalette.Accent)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Size = NumberSequence.new(2)
	emitter.Parent = emitterHolder
end

-- ════════════════════════════════════════════════════════════════════════════
-- UTILITY
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Gets the current theme name for a floor
	@param floorNumber - The floor number
	@return themeName
]]
function ThemeApplier:GetThemeName(floorNumber)
	local theme = DifficultyScaler:GetTheme(floorNumber)
	return theme.Name
end

return ThemeApplier
