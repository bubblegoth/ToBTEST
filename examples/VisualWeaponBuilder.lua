--[[
	VisualWeaponBuilder.lua
	Example showing how to build 3D weapon models from generated parts

	This demonstrates how to integrate the weapon generation system
	with actual 3D weapon models in Roblox
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponGenerator = require(ReplicatedStorage.WeaponSystem.WeaponGenerator)

--[[
	SETUP:
	In ReplicatedStorage, create a folder called "WeaponPartModels" with subfolders:
	- Bodies/
	- Barrels/
	- Grips/
	- Stocks/
	- Magazines/
	- Sights/

	Each part should have a Model named after its Id (e.g., "BODY_RIFLE_INQUISITOR")
	The models should have attachment points for connecting parts:
	- BarrelAttach, GripAttach, StockAttach, MagazineAttach, SightAttach
]]

local WeaponPartModels = ReplicatedStorage:WaitForChild("WeaponPartModels")

--[[
	Build a 3D weapon model from generated weapon data
	@param weaponData - Generated weapon from WeaponGenerator
	@param parent - Parent instance for the weapon model
	@return Model - Assembled weapon model
]]
local function BuildWeaponModel(weaponData, parent)
	local weaponModel = Instance.new("Model")
	weaponModel.Name = weaponData.Name
	weaponModel.Parent = parent

	-- Create a folder for metadata
	local statsFolder = Instance.new("Folder")
	statsFolder.Name = "WeaponData"
	statsFolder.Parent = weaponModel

	-- Store weapon stats as Attributes for easy access
	weaponModel:SetAttribute("WeaponType", weaponData.Type)
	weaponModel:SetAttribute("Rarity", weaponData.Rarity.Name)
	weaponModel:SetAttribute("Level", weaponData.Level)
	weaponModel:SetAttribute("Damage", weaponData.Stats.Damage)
	weaponModel:SetAttribute("FireRate", weaponData.Stats.FireRate)
	weaponModel:SetAttribute("DPS", weaponData.DPS)
	weaponModel:SetAttribute("Accuracy", weaponData.Stats.Accuracy)
	weaponModel:SetAttribute("MagazineSize", weaponData.Stats.MagazineSize)
	weaponModel:SetAttribute("ReloadTime", weaponData.Stats.ReloadTime)

	-- Function to clone and attach a part
	local function AttachPart(partType, partData, attachmentPoint)
		local partFolder = WeaponPartModels:FindFirstChild(partType)
		if not partFolder then
			warn("Part folder not found:", partType)
			return nil
		end

		local partModel = partFolder:FindFirstChild(partData.Id)
		if not partModel then
			warn("Part model not found:", partData.Id, "in", partType)
			return nil
		end

		local clonedPart = partModel:Clone()
		clonedPart.Parent = weaponModel

		-- Apply rarity color tint
		for _, descendant in ipairs(clonedPart:GetDescendants()) do
			if descendant:IsA("BasePart") then
				-- Blend the part's color with rarity color
				local rarityColor = weaponData.Rarity.Color
				descendant.Color = descendant.Color:Lerp(rarityColor, 0.2)
			end
		end

		return clonedPart
	end

	-- Assemble the weapon parts in order
	local body = AttachPart("Bodies", weaponData.Parts.Body)
	if not body then
		warn("Failed to create weapon body")
		return nil
	end

	-- Attach barrel to body
	local barrel = AttachPart("Barrels", weaponData.Parts.Barrel)
	if barrel and body:FindFirstChild("BarrelAttach") then
		barrel:SetPrimaryPartCFrame(body.BarrelAttach.WorldCFrame)
		barrel.PrimaryPart.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body.PrimaryPart
		weld.Part1 = barrel.PrimaryPart
		weld.Parent = barrel.PrimaryPart
	end

	-- Attach grip to body
	local grip = AttachPart("Grips", weaponData.Parts.Grip)
	if grip and body:FindFirstChild("GripAttach") then
		grip:SetPrimaryPartCFrame(body.GripAttach.WorldCFrame)
		grip.PrimaryPart.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body.PrimaryPart
		weld.Part1 = grip.PrimaryPart
		weld.Parent = grip.PrimaryPart
	end

	-- Attach stock to body
	local stock = AttachPart("Stocks", weaponData.Parts.Stock)
	if stock and body:FindFirstChild("StockAttach") then
		stock:SetPrimaryPartCFrame(body.StockAttach.WorldCFrame)
		stock.PrimaryPart.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body.PrimaryPart
		weld.Part1 = stock.PrimaryPart
		weld.Parent = stock.PrimaryPart
	end

	-- Attach magazine to body
	local magazine = AttachPart("Magazines", weaponData.Parts.Magazine)
	if magazine and body:FindFirstChild("MagazineAttach") then
		magazine:SetPrimaryPartCFrame(body.MagazineAttach.WorldCFrame)
		magazine.PrimaryPart.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body.PrimaryPart
		weld.Part1 = magazine.PrimaryPart
		weld.Parent = magazine.PrimaryPart
	end

	-- Attach sight to body
	local sight = AttachPart("Sights", weaponData.Parts.Sight)
	if sight and body:FindFirstChild("SightAttach") then
		sight:SetPrimaryPartCFrame(body.SightAttach.WorldCFrame)
		sight.PrimaryPart.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body.PrimaryPart
		weld.Part1 = sight.PrimaryPart
		weld.Parent = sight.PrimaryPart
	end

	-- Add a name tag above the weapon showing rarity
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 200, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = weaponModel

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 0.5
	nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	nameLabel.TextColor3 = weaponData.Rarity.Color
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = weaponData.Name
	nameLabel.Parent = billboardGui

	-- Set primary part for the whole weapon
	weaponModel.PrimaryPart = body.PrimaryPart

	return weaponModel
end

--[[
	Example: Create a weapon pickup in the world
]]
local function CreateWeaponPickup(position, level)
	-- Generate a random weapon
	local weaponData = WeaponGenerator.GenerateWeapon(level)

	-- Create the 3D model
	local weaponModel = BuildWeaponModel(weaponData, workspace)
	if weaponModel then
		weaponModel:SetPrimaryPartCFrame(CFrame.new(position))

		-- Add pickup functionality
		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = "Pickup " .. weaponData.Rarity.Name .. " " .. weaponData.Type
		proximityPrompt.ObjectText = weaponData.Name
		proximityPrompt.Parent = weaponModel.PrimaryPart

		proximityPrompt.Triggered:Connect(function(player)
			print(player.Name, "picked up", weaponData.Name)
			-- Add to player inventory here
			weaponModel:Destroy()
		end)

		-- Make it spin for visual effect
		local spin = Instance.new("BodyAngularVelocity")
		spin.AngularVelocity = Vector3.new(0, 2, 0)
		spin.MaxTorque = Vector3.new(0, math.huge, 0)
		spin.Parent = weaponModel.PrimaryPart

		return weaponModel, weaponData
	end
end

--[[
	Example: Equip weapon to player
]]
local function EquipWeaponToPlayer(player, weaponData)
	local character = player.Character
	if not character then return end

	-- Build the weapon model
	local weaponModel = BuildWeaponModel(weaponData, character)
	if weaponModel then
		-- Position in player's hand
		local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
		if rightHand then
			weaponModel.PrimaryPart.CFrame = rightHand.CFrame

			-- Weld to hand
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rightHand
			weld.Part1 = weaponModel.PrimaryPart
			weld.Parent = weaponModel.PrimaryPart

			-- Create tool for weapon
			local tool = Instance.new("Tool")
			tool.Name = weaponData.Name
			tool.RequiresHandle = false
			tool.CanBeDropped = true
			tool.Parent = player.Backpack

			-- Store reference to weapon data
			tool:SetAttribute("WeaponDataRef", weaponData.Name)

			print(string.format(
				"Equipped %s: %d damage, %.1f fire rate, %.1f DPS",
				weaponData.Name,
				weaponData.Stats.Damage,
				weaponData.Stats.FireRate,
				weaponData.DPS
			))
		end
	end
end

-- Example usage
print("=== Visual Weapon Building Examples ===\n")

-- Example 1: Create weapon pickups at different levels
print("Creating weapon pickups...")
local pickup1 = CreateWeaponPickup(Vector3.new(0, 5, 0), 1)
local pickup2 = CreateWeaponPickup(Vector3.new(10, 5, 0), 10)
local pickup3 = CreateWeaponPickup(Vector3.new(20, 5, 0), 20)

-- Example 2: Equip a weapon to the first player
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait a moment for character to load
		wait(1)

		-- Generate and equip a starter weapon
		local starterWeapon = WeaponGenerator.GenerateWeapon(1, "Pistol")
		EquipWeaponToPlayer(player, starterWeapon)
	end)
end)

return {
	BuildWeaponModel = BuildWeaponModel,
	CreateWeaponPickup = CreateWeaponPickup,
	EquipWeaponToPlayer = EquipWeaponToPlayer
}
