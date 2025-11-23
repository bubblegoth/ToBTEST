--[[
════════════════════════════════════════════════════════════════════════════════
Module: WeaponToolBuilder
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Converts weapon data into functional Roblox Tool instances.
             Integrates 3D models from WeaponModelBuilder.
             Handles weapon equipping, unequipping, and player inventory.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local WeaponToolBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponModelBuilder = require(script.Parent.WeaponModelBuilder)
local WeaponParts = require(script.Parent.WeaponParts)
local PlayerInventory = require(script.Parent.PlayerInventory)

-- ============================================================
-- TOOL CREATION
-- ============================================================

function WeaponToolBuilder:CreateWeaponTool(weaponData)
	local tool = Instance.new("Tool")
	tool.Name = weaponData.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = true
	tool.ToolTip = string.format("[Lv.%d %s] %s", weaponData.Level, weaponData.Rarity, weaponData.Parts.Base.Name)

	-- Grip settings for proper weapon positioning
	tool.GripPos = Vector3.new(0, -0.2, 0.5)
	tool.GripForward = Vector3.new(0, 0, -1)
	tool.GripRight = Vector3.new(1, 0, 0)
	tool.GripUp = Vector3.new(0, 1, 0)

	-- Build 3D weapon model
	local weaponModel = WeaponModelBuilder:BuildWeapon(weaponData)

	if not weaponModel then
		warn("[WeaponToolBuilder] Failed to build weapon model for", weaponData.Name or "Unknown")
		warn("  Creating fallback handle instead")

		-- Create simple fallback handle
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.2, 0.4, 1)
		handle.Material = Enum.Material.Metal
		handle.Color = Color3.fromRGB(100, 100, 100)
		handle.CanCollide = false
		handle.Parent = tool
	else
		-- Use the primary part (body receiver) as the handle
		local handle = weaponModel.PrimaryPart:Clone()
		handle.Name = "Handle"
		handle.Parent = tool

		-- Clone all other parts and weld them to handle
		for _, part in pairs(weaponModel:GetDescendants()) do
			if part:IsA("BasePart") and part ~= weaponModel.PrimaryPart then
				local partClone = part:Clone()
				partClone.Parent = tool

				-- Create weld to preserve position relative to handle
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = partClone
				weld.Parent = partClone
			end
		end

		-- Clean up temporary model
		weaponModel:Destroy()
	end

	-- ============================================================
	-- STORE WEAPON DATA AS ATTRIBUTES
	-- ============================================================

	-- Identity
	tool:SetAttribute("WeaponType", weaponData.Parts.Base.Name)
	tool:SetAttribute("Rarity", weaponData.Rarity)
	tool:SetAttribute("Level", weaponData.Level)
	tool:SetAttribute("Manufacturer", weaponData.Manufacturer)
	tool:SetAttribute("UniqueID", game:GetService("HttpService"):GenerateGUID(false))

	-- Core stats
	tool:SetAttribute("Damage", weaponData.Damage)
	tool:SetAttribute("FireRate", weaponData.FireRate)
	tool:SetAttribute("Capacity", weaponData.Capacity)
	tool:SetAttribute("CurrentAmmo", weaponData.CurrentAmmo or weaponData.Capacity) -- Initialize with full mag
	tool:SetAttribute("Accuracy", weaponData.Accuracy)
	-- NOTE: Spread is calculated from Accuracy using BL2 formula: (100 - Accuracy) / 12
	tool:SetAttribute("Range", weaponData.Range)
	tool:SetAttribute("ReloadTime", weaponData.ReloadTime)
	tool:SetAttribute("Pellets", weaponData.Pellets)
	tool:SetAttribute("DPS", weaponData.DPS)

	-- Spread bloom system
	tool:SetAttribute("BloomPerShot", weaponData.BloomPerShot or 0.5)
	tool:SetAttribute("MaxBloom", weaponData.MaxBloom or 10)

	-- Critical stats
	if weaponData.CritChance and weaponData.CritChance > 0 then
		tool:SetAttribute("CritChance", weaponData.CritChance)
	end
	if weaponData.CritDamage and weaponData.CritDamage > 0 then
		tool:SetAttribute("CritDamage", weaponData.CritDamage)
	end

	-- Special stats
	if weaponData.SoulGain and weaponData.SoulGain > 0 then
		tool:SetAttribute("SoulGain", weaponData.SoulGain)
	end
	if weaponData.KillHeal and weaponData.KillHeal > 0 then
		tool:SetAttribute("KillHeal", weaponData.KillHeal)
	end

	-- Elemental damage
	if weaponData.FireDamage and weaponData.FireDamage > 0 then
		tool:SetAttribute("FireDamage", weaponData.FireDamage)
	end
	if weaponData.FrostDamage and weaponData.FrostDamage > 0 then
		tool:SetAttribute("FrostDamage", weaponData.FrostDamage)
	end
	if weaponData.ShadowDamage and weaponData.ShadowDamage > 0 then
		tool:SetAttribute("ShadowDamage", weaponData.ShadowDamage)
	end
	if weaponData.LightDamage and weaponData.LightDamage > 0 then
		tool:SetAttribute("LightDamage", weaponData.LightDamage)
	end
	if weaponData.VoidDamage and weaponData.VoidDamage > 0 then
		tool:SetAttribute("VoidDamage", weaponData.VoidDamage)
	end

	-- Status effects
	if weaponData.BurnChance and weaponData.BurnChance > 0 then
		tool:SetAttribute("BurnChance", weaponData.BurnChance)
	end
	if weaponData.SlowChance and weaponData.SlowChance > 0 then
		tool:SetAttribute("SlowChance", weaponData.SlowChance)
	end
	if weaponData.ChainEffect and weaponData.ChainEffect > 0 then
		tool:SetAttribute("ChainEffect", weaponData.ChainEffect)
	end

	-- Store part names for UI display
	if weaponData.Parts then
		tool:SetAttribute("Part_Stock", weaponData.Parts.Stock.Name)
		tool:SetAttribute("Part_Body", weaponData.Parts.Body.Name)
		tool:SetAttribute("Part_Barrel", weaponData.Parts.Barrel.Name)
		tool:SetAttribute("Part_Magazine", weaponData.Parts.Magazine.Name)
		tool:SetAttribute("Part_Sight", weaponData.Parts.Sight.Name)
		tool:SetAttribute("Part_Accessory", weaponData.Parts.Accessory.Name)
		tool:SetAttribute("Part_Manufacturer", weaponData.Parts.Manufacturer.Name)
	end

	-- Store full weapon data as JSON (for detailed inspection)
	local HttpService = game:GetService("HttpService")
	local weaponDataCopy = {
		Name = weaponData.Name,
		Level = weaponData.Level,
		Rarity = weaponData.Rarity,
		Manufacturer = weaponData.Manufacturer,
		Damage = weaponData.Damage,
		DPS = weaponData.DPS,
		FireRate = weaponData.FireRate,
		Capacity = weaponData.Capacity,
		Accuracy = weaponData.Accuracy,
		Range = weaponData.Range,
		ReloadTime = weaponData.ReloadTime
	}
	tool:SetAttribute("WeaponDataJSON", HttpService:JSONEncode(weaponDataCopy))

	return tool
end

-- ============================================================
-- GIVE WEAPON TO PLAYER
-- ============================================================

function WeaponToolBuilder:GiveWeaponToPlayer(player, weaponData, autoEquip)
	local tool = self:CreateWeaponTool(weaponData)

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		warn("[WeaponToolBuilder] No backpack found for", player.Name)
		tool:Destroy()
		return false
	end

	tool.Parent = backpack

	-- Register weapon in PlayerInventory system for BackpackUI tracking
	local inventory = PlayerInventory.GetInventory(player)
	if inventory then
		-- Find first empty slot
		local emptySlot = nil
		for slot = 1, 4 do
			if not inventory:GetEquippedWeapon(slot) then
				emptySlot = slot
				break
			end
		end

		if emptySlot then
			-- Register weapon in inventory slot
			local success = inventory:EquipWeaponToSlot(emptySlot, weaponData)
			if success then
				inventory.EquippedWeaponTool = tool
				inventory.CurrentWeaponSlot = emptySlot
				print(string.format("[WeaponToolBuilder] Registered %s in inventory slot %d", weaponData.Name, emptySlot))
			end
		else
			warn("[WeaponToolBuilder] All inventory slots full - weapon not registered in inventory")
		end
	else
		warn("[WeaponToolBuilder] No inventory found for", player.Name)
	end

	-- Auto-equip if requested
	if autoEquip then
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			task.wait(0.1) -- Small delay for tool to register
			humanoid:EquipTool(tool)
		end
	end

	print(string.format("[WeaponToolBuilder] Gave %s to %s", weaponData.Name, player.Name))
	return true
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

function WeaponToolBuilder:GetWeaponDataFromTool(tool)
	if not tool:IsA("Tool") then return nil end

	-- Helper function to find part by name
	local function findPart(partList, name)
		if not partList or not name then return nil end
		for _, part in ipairs(partList) do
			if part.Name == name then
				return part
			end
		end
		return partList[1] -- Fallback to first part if not found
	end

	-- Helper function to find manufacturer by name
	local function findManufacturer(name)
		if not name then return WeaponParts.Manufacturers[1] end
		for _, mfg in ipairs(WeaponParts.Manufacturers) do
			if mfg.Name == name then
				return mfg
			end
		end
		return WeaponParts.Manufacturers[1]
	end

	-- Helper function to find base type by name
	local function findBaseType(name)
		if not name then return WeaponParts.BaseTypes[1] end
		for _, base in ipairs(WeaponParts.BaseTypes) do
			if base.Name == name then
				return base
			end
		end
		return WeaponParts.BaseTypes[1]
	end

	-- Reconstruct Parts from stored attributes
	local Parts = {
		Base = findBaseType(tool:GetAttribute("WeaponType")),
		Manufacturer = findManufacturer(tool:GetAttribute("Part_Manufacturer")),
		Stock = findPart(WeaponParts.Stocks, tool:GetAttribute("Part_Stock")),
		Body = findPart(WeaponParts.Bodies, tool:GetAttribute("Part_Body")),
		Barrel = findPart(WeaponParts.Barrels, tool:GetAttribute("Part_Barrel")),
		Magazine = findPart(WeaponParts.Magazines, tool:GetAttribute("Part_Magazine")),
		Sight = findPart(WeaponParts.Sights, tool:GetAttribute("Part_Sight")),
		Accessory = findPart(WeaponParts.Accessories, tool:GetAttribute("Part_Accessory")),
	}

	local weaponData = {
		Name = tool.Name,
		Level = tool:GetAttribute("Level"),
		Rarity = tool:GetAttribute("Rarity"),
		WeaponType = tool:GetAttribute("WeaponType"),
		Manufacturer = tool:GetAttribute("Manufacturer"),
		Damage = tool:GetAttribute("Damage"),
		FireRate = tool:GetAttribute("FireRate"),
		Capacity = tool:GetAttribute("Capacity"),
		CurrentAmmo = tool:GetAttribute("CurrentAmmo"), -- Preserve current ammo when dropping/picking up
		Accuracy = tool:GetAttribute("Accuracy"),
		-- Spread is calculated from Accuracy using BL2 formula, not stored
		Range = tool:GetAttribute("Range"),
		ReloadTime = tool:GetAttribute("ReloadTime"),
		Pellets = tool:GetAttribute("Pellets"),
		DPS = tool:GetAttribute("DPS"),
		BloomPerShot = tool:GetAttribute("BloomPerShot"),
		MaxBloom = tool:GetAttribute("MaxBloom"),
		CritChance = tool:GetAttribute("CritChance") or 0,
		CritDamage = tool:GetAttribute("CritDamage") or 0,
		SoulGain = tool:GetAttribute("SoulGain") or 0,
		Parts = Parts, -- Include reconstructed Parts for model building
	}

	return weaponData
end

function WeaponToolBuilder:IsWeaponTool(tool)
	return tool:IsA("Tool") and tool:GetAttribute("UniqueID") ~= nil
end

return WeaponToolBuilder
