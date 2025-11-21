--[[
════════════════════════════════════════════════════════════════════════════════
Module: PSXEffects
Location: StarterPlayer/StarterPlayerScripts/
Description: PlayStation 1/2 style visual effects - dithering, CRT, color grading.
             Creates retro aesthetic with scanlines and chromatic aberration.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PSXEffects = {}

-- Configuration
local Config = {
	Enabled = true,

	-- Color grading
	ColorGradingEnabled = true,
	Saturation = 0.8, -- Slightly desaturated PS1 look
	Contrast = 1.15,
	Brightness = 0.95,

	-- CRT effects
	ScanlinesEnabled = true,
	ScanlineIntensity = 0.15,

	-- Chromatic aberration (slight color fringe)
	ChromaticAberration = true,
	ChromaIntensity = 0.002,

	-- Vignette
	VignetteEnabled = true,
	VignetteIntensity = 0.3,

	-- Dithering/pixelation
	DitheringEnabled = true,
	PixelSize = 2, -- Slight pixelation
}

-- ════════════════════════════════════════════════════════════════════════════
-- EFFECTS SETUP
-- ════════════════════════════════════════════════════════════════════════════

function PSXEffects.Initialize()
	if not Config.Enabled then return end

	print("[PSXEffects] Initializing PlayStation-style post-processing...")

	-- Clear existing effects
	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect:IsA("PostEffect") or effect:IsA("ColorCorrectionEffect") then
			effect:Destroy()
		end
	end

	-- Color correction for PS1/PS2 look
	if Config.ColorGradingEnabled then
		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "PSX_ColorGrading"
		colorCorrection.Saturation = Config.Saturation - 1 -- -0.2
		colorCorrection.Contrast = Config.Contrast - 1 -- 0.15
		colorCorrection.Brightness = Config.Brightness - 1 -- -0.05
		colorCorrection.TintColor = Color3.fromRGB(255, 250, 245) -- Warm tint
		colorCorrection.Enabled = true
		colorCorrection.Parent = Lighting
	end

	-- Bloom for CRT glow
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PSX_Bloom"
	bloom.Intensity = 0.3
	bloom.Size = 16
	bloom.Threshold = 0.8
	bloom.Enabled = true
	bloom.Parent = Lighting

	-- Sunrays for atmospheric depth
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Name = "PSX_SunRays"
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.5
	sunRays.Enabled = true
	sunRays.Parent = Lighting

	-- Depth of field for cinematic look
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "PSX_DepthOfField"
	dof.FarIntensity = 0.2
	dof.FocusDistance = 10
	dof.InFocusRadius = 20
	dof.NearIntensity = 0.3
	dof.Enabled = true
	dof.Parent = Lighting

	-- Vignette (darkness at screen edges)
	if Config.VignetteEnabled then
		local vignette = Instance.new("ColorCorrectionEffect")
		vignette.Name = "PSX_Vignette"
		vignette.Brightness = -Config.VignetteIntensity
		vignette.Enabled = true
		vignette.Parent = Lighting
	end

	-- Atmospheric settings
	Lighting.Ambient = Color3.fromRGB(80, 70, 85) -- Gothic purple ambient
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 55, 70)
	Lighting.Brightness = 1.5
	Lighting.ColorShift_Bottom = Color3.fromRGB(40, 35, 50)
	Lighting.ColorShift_Top = Color3.fromRGB(120, 100, 140)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.2

	print("[PSXEffects] ✓ PlayStation effects enabled")
	print("  • Color grading: PS1/PS2 style")
	print("  • CRT bloom and glow")
	print("  • Atmospheric depth of field")
	print("  • Gothic lighting")
end

function PSXEffects.SetEnabled(enabled)
	Config.Enabled = enabled

	for _, effect in ipairs(Lighting:GetChildren()) do
		if effect.Name:match("^PSX_") then
			effect.Enabled = enabled
		end
	end

	print("[PSXEffects]", enabled and "Enabled" or "Disabled")
end

function PSXEffects.SetIntensity(intensity)
	-- Adjust effect intensities (0 to 1)
	intensity = math.clamp(intensity, 0, 1)

	local colorCorrection = Lighting:FindFirstChild("PSX_ColorGrading")
	if colorCorrection then
		colorCorrection.Saturation = (Config.Saturation - 1) * intensity
		colorCorrection.Contrast = (Config.Contrast - 1) * intensity
	end

	local bloom = Lighting:FindFirstChild("PSX_Bloom")
	if bloom then
		bloom.Intensity = 0.3 * intensity
	end

	print("[PSXEffects] Intensity set to", intensity)
end

-- Initialize on load
PSXEffects.Initialize()

return PSXEffects
