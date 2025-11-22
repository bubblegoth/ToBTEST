--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponModelBuilder
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Procedurally builds 3D weapon models from weapon data.
             Creates visual representations with gothic materials.
             Generates floating loot cards and viewmodels.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local WeaponModelBuilder = {}

local TweenService = game:GetService("TweenService")

-- ============================================================
-- MANUFACTURER MATERIALS (Gothic Themed)
-- ============================================================

local ManufacturerMaterials = {
	["Sanctum Armory"] = {
		Primary = Enum.Material.Metal,
		Secondary = Enum.Material.SmoothPlastic,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(200, 200, 200),
		Color2 = Color3.fromRGB(220, 220, 220),
		Glow = Color3.fromRGB(255, 255, 255)
	},
	["Bone & Iron Works"] = {
		Primary = Enum.Material.CorrodedMetal,
		Secondary = Enum.Material.Concrete,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(80, 60, 50),
		Color2 = Color3.fromRGB(150, 140, 130),
		Glow = Color3.fromRGB(200, 180, 160)
	},
	["Crypt Forges"] = {
		Primary = Enum.Material.Metal,
		Secondary = Enum.Material.DiamondPlate,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(80, 80, 100),
		Color2 = Color3.fromRGB(120, 120, 140),
		Glow = Color3.fromRGB(150, 180, 200)
	},
	["Reaper Industries"] = {
		Primary = Enum.Material.Metal,
		Secondary = Enum.Material.SmoothPlastic,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(40, 40, 40),
		Color2 = Color3.fromRGB(60, 60, 60),
		Glow = Color3.fromRGB(100, 100, 100)
	},
	["Wraith Manufacturing"] = {
		Primary = Enum.Material.Glass,
		Secondary = Enum.Material.SmoothPlastic,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(150, 180, 200),
		Color2 = Color3.fromRGB(180, 200, 220),
		Glow = Color3.fromRGB(200, 220, 255)
	},
	["Cathedral Arms"] = {
		Primary = Enum.Material.Metal,
		Secondary = Enum.Material.SmoothPlastic,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(200, 180, 120),
		Color2 = Color3.fromRGB(255, 215, 0),
		Glow = Color3.fromRGB(255, 255, 200)
	},
	["Tomb Makers"] = {
		Primary = Enum.Material.CorrodedMetal,
		Secondary = Enum.Material.Fabric,
		Accent = Enum.Material.Neon,
		Color1 = Color3.fromRGB(60, 0, 60),
		Color2 = Color3.fromRGB(100, 0, 100),
		Glow = Color3.fromRGB(150, 0, 150)
	}
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
-- COMPONENT BUILDERS
-- ============================================================

function WeaponModelBuilder:BuildStock(stockData, materials, parent, basePos)
	local stockModel = Instance.new("Model")
	stockModel.Name = "Stock"
	stockModel.Parent = parent

	local size = Vector3.new(0.15, 0.25, 0.4)
	local offset = CFrame.new(0, 0, 0.5)

	if stockData.Name:find("Heavy") then
		size = Vector3.new(0.2, 0.3, 0.5)
	elseif stockData.Name:find("Light") or stockData.Name:find("Skeleton") then
		size = Vector3.new(0.1, 0.2, 0.3)
	elseif stockData.Name:find("No Stock") then
		size = Vector3.new(0.05, 0.15, 0.15)
	end

	local stockBody = CreatePart("StockBody", size, basePos * offset, materials.Color1, materials.Primary, stockModel)

	if not stockData.Name:find("No Stock") then
		local pad = CreatePart("StockPad", Vector3.new(size.X + 0.05, size.Y + 0.05, 0.1),
			stockBody.CFrame * CFrame.new(0, 0, size.Z/2 + 0.05), materials.Color2, materials.Secondary, stockModel)
		WeldParts(stockBody, pad)
	end

	stockModel.PrimaryPart = stockBody
	return stockModel
end

function WeaponModelBuilder:BuildBody(bodyData, materials, parent, basePos, weaponType)
	local bodyModel = Instance.new("Model")
	bodyModel.Name = "Body"
	bodyModel.Parent = parent

	-- Base size varies by weapon type
	local size = Vector3.new(0.15, 0.2, 0.6) -- Default for Rifle/Assault Rifle

	if weaponType == "Pistol" or weaponType == "Revolver" then
		size = Vector3.new(0.1, 0.15, 0.35) -- Compact pistol body
	elseif weaponType == "Shotgun" then
		size = Vector3.new(0.18, 0.25, 0.7) -- Bulky shotgun body
	elseif weaponType == "Sniper Rifle" then
		size = Vector3.new(0.12, 0.18, 0.8) -- Long sniper body
	elseif weaponType == "SMG" then
		size = Vector3.new(0.12, 0.16, 0.4) -- Compact SMG body
	end

	-- Modify size based on body type
	if bodyData.Name:find("Heavy") or bodyData.Name:find("Reinforced") then
		size = size * Vector3.new(1.2, 1.25, 1.15) -- 20-25% larger
	elseif bodyData.Name:find("Lightweight") then
		size = size * Vector3.new(0.8, 0.75, 0.85) -- 15-25% smaller
	end

	local receiver = CreatePart("Receiver", size, basePos, materials.Color1, materials.Primary, bodyModel)

	local detailSize = Vector3.new(size.X - 0.02, 0.05, size.Z - 0.1)
	local detail = CreatePart("ReceiverDetail", detailSize,
		receiver.CFrame * CFrame.new(0, size.Y/2 - 0.025, 0), materials.Color2, materials.Secondary, bodyModel)
	WeldParts(receiver, detail)

	if bodyData.Name:find("Cathedral") or bodyData.Name:find("Revenant") then
		local glow = CreatePart("BodyGlow", Vector3.new(0.02, 0.02, size.Z * 0.6),
			receiver.CFrame * CFrame.new(size.X/2 + 0.01, 0, 0), materials.Glow, Enum.Material.Neon, bodyModel)
		glow.Transparency = 0.3
		WeldParts(receiver, glow)
	end

	bodyModel.PrimaryPart = receiver
	return bodyModel
end

function WeaponModelBuilder:BuildBarrel(barrelData, materials, weaponType, parent, basePos)
	local barrelModel = Instance.new("Model")
	barrelModel.Name = "Barrel"
	barrelModel.Parent = parent

	local length = 0.8
	local width = 0.08

	if weaponType == "Pistol" or weaponType == "Revolver" then
		length = 0.5
		width = 0.06
	elseif weaponType == "Shotgun" then
		length = 0.7
		width = 0.12
	elseif weaponType == "Sniper Rifle" then
		length = 1.2
		width = 0.06
	elseif weaponType == "SMG" then
		length = 0.4
		width = 0.05
	end

	if barrelData.Name:find("Long") then
		length = length * 1.3
	elseif barrelData.Name:find("Short") then
		length = length * 0.7
	end

	-- Calculate connection gap based on weapon type body size
	local bodyGap = 0.3 -- Default for rifles (body Z = 0.6)
	if weaponType == "Pistol" or weaponType == "Revolver" then
		bodyGap = 0.175 -- Pistol body Z = 0.35
	elseif weaponType == "Shotgun" then
		bodyGap = 0.35 -- Shotgun body Z = 0.7
	elseif weaponType == "Sniper Rifle" then
		bodyGap = 0.4 -- Sniper body Z = 0.8
	elseif weaponType == "SMG" then
		bodyGap = 0.2 -- SMG body Z = 0.4
	end

	local barrel = CreatePart("BarrelTube", Vector3.new(width, width, length),
		basePos * CFrame.new(0, 0, -length/2 - bodyGap), materials.Color1, materials.Primary, barrelModel)

	local muzzle = CreatePart("Muzzle", Vector3.new(width + 0.02, width + 0.02, 0.08),
		barrel.CFrame * CFrame.new(0, 0, -length/2 - 0.04), materials.Color2, materials.Secondary, barrelModel)
	WeldParts(barrel, muzzle)

	if barrelData.Name:find("Sanctified") or barrelData.Name:find("Void") then
		local glow = CreatePart("BarrelGlow", Vector3.new(width - 0.01, width - 0.01, length - 0.1),
			barrel.CFrame, materials.Glow, Enum.Material.Neon, barrelModel)
		glow.Transparency = 0.5
		WeldParts(barrel, glow)
	end

	barrelModel.PrimaryPart = barrel
	return barrelModel
end

function WeaponModelBuilder:BuildMagazine(magData, materials, parent, basePos)
	local magModel = Instance.new("Model")
	magModel.Name = "Magazine"
	magModel.Parent = parent

	local size = Vector3.new(0.1, 0.3, 0.12)

	if magData.Name:find("Drum") then
		size = Vector3.new(0.2, 0.2, 0.2)
	elseif magData.Name:find("Extended") then
		size = Vector3.new(0.1, 0.4, 0.12)
	elseif magData.Name:find("Compact") or magData.Name:find("Speed") then
		size = Vector3.new(0.08, 0.2, 0.1)
	end

	local mag = CreatePart("MagBody", size, basePos * CFrame.new(0, -0.2, 0), materials.Color2, materials.Secondary, magModel)

	if magData.Name:find("Soul") or magData.Name:find("Infinite") then
		local reservoir = CreatePart("SoulReservoir", Vector3.new(size.X - 0.02, size.Y - 0.02, size.Z - 0.02),
			mag.CFrame, materials.Glow, Enum.Material.Neon, magModel)
		reservoir.Transparency = 0.3
		WeldParts(mag, reservoir)

		local pulse = TweenService:Create(reservoir, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.7})
		pulse:Play()
	end

	magModel.PrimaryPart = mag
	return magModel
end

function WeaponModelBuilder:BuildSight(sightData, materials, parent, basePos)
	local sightModel = Instance.new("Model")
	sightModel.Name = "Sight"
	sightModel.Parent = parent

	local height = 0.1
	local width = 0.08

	if sightData.Name:find("Iron") then
		height = 0.05
		width = 0.04
	elseif sightData.Name:find("4x") or sightData.Name:find("8x") or sightData.Name:find("God") then
		height = 0.15
		width = 0.12
	end

	local mount = CreatePart("SightMount", Vector3.new(0.08, 0.03, 0.15),
		basePos * CFrame.new(0, 0.15, -0.15), materials.Color1, materials.Primary, sightModel)

	local housing = CreatePart("SightHousing", Vector3.new(width, height, width),
		mount.CFrame * CFrame.new(0, height/2 + 0.02, 0), materials.Color2, materials.Secondary, sightModel)
	WeldParts(mount, housing)

	if not sightData.Name:find("Iron") then
		local lens = CreatePart("Lens", Vector3.new(width - 0.02, height - 0.02, 0.01),
			housing.CFrame * CFrame.new(0, 0, -width/2), Color3.fromRGB(100, 150, 255), Enum.Material.Glass, sightModel)
		lens.Transparency = 0.3
		WeldParts(mount, lens)
	end

	if sightData.Name:find("Specter") or sightData.Name:find("God") then
		local glow = CreatePart("SightGlow", Vector3.new(width + 0.02, height + 0.02, width + 0.02),
			housing.CFrame, materials.Glow, Enum.Material.Neon, sightModel)
		glow.Transparency = 0.7
		WeldParts(mount, glow)
	end

	sightModel.PrimaryPart = mount
	return sightModel
end

function WeaponModelBuilder:BuildAccessory(accessoryData, materials, parent, basePos)
	if accessoryData.Name == "None" then
		return nil
	end

	local accessoryModel = Instance.new("Model")
	accessoryModel.Name = "Accessory"
	accessoryModel.Parent = parent

	local offset = CFrame.new(0, -0.08, -0.4)

	if accessoryData.Name:find("Foregrip") then
		local grip = CreatePart("Foregrip", Vector3.new(0.06, 0.15, 0.06),
			basePos * offset, materials.Color2, materials.Secondary, accessoryModel)
		accessoryModel.PrimaryPart = grip

	elseif accessoryData.Name:find("Laser") then
		local laser = CreatePart("LaserMount", Vector3.new(0.04, 0.04, 0.08),
			basePos * offset, materials.Color1, materials.Primary, accessoryModel)

		local beam = CreatePart("LaserBeam", Vector3.new(0.01, 0.01, 0.02),
			laser.CFrame * CFrame.new(0, 0, -0.05), Color3.fromRGB(255, 0, 0), Enum.Material.Neon, accessoryModel)
		WeldParts(laser, beam)

		accessoryModel.PrimaryPart = laser

	elseif accessoryData.Name:find("Bayonet") or accessoryData.Name:find("Skull") then
		local blade = CreatePart("Bayonet", Vector3.new(0.02, 0.04, 0.25),
			basePos * CFrame.new(0, 0, -0.8), materials.Glow, Enum.Material.Neon, accessoryModel)
		accessoryModel.PrimaryPart = blade

	elseif accessoryData.Name:find("Converter") or accessoryData.Name:find("Coil") or accessoryData.Name:find("Catalyst") or accessoryData.Name:find("Amplifier") or accessoryData.Name:find("Resonator") or accessoryData.Name:find("Siphon") then
		local element = CreatePart("ElementCore", Vector3.new(0.08, 0.08, 0.12),
			basePos * offset, materials.Glow, Enum.Material.Neon, accessoryModel)
		element.Transparency = 0.3

		local pulse = TweenService:Create(element, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.7})
		pulse:Play()

		accessoryModel.PrimaryPart = element
	end

	return accessoryModel
end

-- ============================================================
-- MAIN BUILD FUNCTION
-- ============================================================

function WeaponModelBuilder:BuildWeapon(weaponData)
	-- Validate weapon data
	if not weaponData then
		warn("[WeaponModelBuilder] BuildWeapon called with nil weaponData")
		return nil
	end

	if not weaponData.Parts then
		warn("[WeaponModelBuilder] weaponData missing Parts field - cannot build model")
		warn("  weaponData.Name:", weaponData.Name or "nil")
		warn("  This usually means weaponData was reconstructed from attributes without the full Parts table")
		return nil
	end

	if not weaponData.Parts.Base then
		warn("[WeaponModelBuilder] weaponData.Parts missing Base - cannot build model")
		return nil
	end

	local weaponModel = Instance.new("Model")
	weaponModel.Name = weaponData.Name or "UnknownWeapon"

	local materials = ManufacturerMaterials[weaponData.Manufacturer] or ManufacturerMaterials["Sanctum Armory"]

	local basePos = CFrame.new(0, 0, 0)
	local weaponType = weaponData.Parts.Base.Name

	-- Build all components
	local body = self:BuildBody(weaponData.Parts.Body, materials, weaponModel, basePos, weaponType)
	local stock = self:BuildStock(weaponData.Parts.Stock, materials, weaponModel, basePos)
	local barrel = self:BuildBarrel(weaponData.Parts.Barrel, materials, weaponType, weaponModel, basePos)
	local magazine = self:BuildMagazine(weaponData.Parts.Magazine, materials, weaponModel, basePos)
	local sight = self:BuildSight(weaponData.Parts.Sight, materials, weaponModel, basePos)
	local accessory = self:BuildAccessory(weaponData.Parts.Accessory, materials, weaponModel, basePos)

	-- Set primary part
	weaponModel.PrimaryPart = body.PrimaryPart

	-- Weld everything to body
	if stock.PrimaryPart then WeldParts(body.PrimaryPart, stock.PrimaryPart) end
	if barrel.PrimaryPart then WeldParts(body.PrimaryPart, barrel.PrimaryPart) end
	if magazine.PrimaryPart then WeldParts(body.PrimaryPart, magazine.PrimaryPart) end
	if sight.PrimaryPart then WeldParts(body.PrimaryPart, sight.PrimaryPart) end
	if accessory and accessory.PrimaryPart then WeldParts(body.PrimaryPart, accessory.PrimaryPart) end

	-- Store weapon data as attribute
	weaponModel:SetAttribute("WeaponLevel", weaponData.Level)
	weaponModel:SetAttribute("WeaponRarity", weaponData.Rarity)
	weaponModel:SetAttribute("WeaponDamage", weaponData.Damage)

	return weaponModel
end

return WeaponModelBuilder
