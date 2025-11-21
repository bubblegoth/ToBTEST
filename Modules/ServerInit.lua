--[[
	ServerInit.lua
	Server initialization script - spawns Soul Vendor and sets up game
	Place this in ServerScriptService

	This script runs ONCE when the server starts, not per-player
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for modules to load
local NPCGenerator = require(ReplicatedStorage.Modules.NPCGenerator)
local SoulVendorScript = script.Parent:FindFirstChild("SoulVendor") -- Assumes SoulVendor.lua is in ServerScriptService

print("[ServerInit] Initializing game systems...")

-- ============================================================
-- SPAWN SOUL VENDOR
-- ============================================================

local function SpawnSoulVendor()
	-- Check if Soul Vendor already exists (avoid duplicates)
	if workspace:FindFirstChild("Soul Keeper") then
		print("[ServerInit] Soul Vendor already exists, skipping spawn")
		return workspace:FindFirstChild("Soul Keeper")
	end

	print("[ServerInit] Generating Soul Vendor NPC...")

	-- Generate Soul Vendor data
	local vendorData = NPCGenerator.GenerateNPC("SOUL_VENDOR")

	-- Build the actual model
	local vendorModel = NPCGenerator.BuildNPCModel(vendorData, workspace)

	-- Position in Church (adjust this to match your Church location)
	local vendorSpawnPoint = workspace:FindFirstChild("SoulVendor") -- Part named "SoulVendor" in workspace
	if vendorSpawnPoint then
		vendorModel:SetPrimaryPartCFrame(vendorSpawnPoint.CFrame)
		print("[ServerInit] Soul Vendor positioned at SoulVendor part")
	else
		-- Default position if spawn point not found
		vendorModel:SetPrimaryPartCFrame(CFrame.new(0, 5, 0))
		warn("[ServerInit] SoulVendor spawn point not found in workspace, using default position (0, 5, 0)")
	end

	-- Make vendor invincible and non-collidable with players
	for _, part in ipairs(vendorModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false -- Allow physics but...
			part.CanCollide = true -- Solid but not pushable
		end
	end

	local humanoid = vendorModel:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 9999
		humanoid.Health = 9999
		humanoid.WalkSpeed = 0 -- Stationary
		humanoid.JumpPower = 0 -- Can't jump
	end

	-- Anchor the root part to keep vendor in place
	local rootPart = vendorModel:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.Anchored = true
	end

	-- Attach Soul Vendor interaction script
	if SoulVendorScript then
		local scriptClone = SoulVendorScript:Clone()
		scriptClone.Parent = vendorModel
		scriptClone.Enabled = true
		print("[ServerInit] SoulVendor script attached")
	else
		warn("[ServerInit] SoulVendor.lua script not found in ServerScriptService!")
	end

	print("[ServerInit] Soul Vendor spawned successfully:", vendorModel.Name)

	return vendorModel
end

-- ============================================================
-- INITIALIZE ON SERVER START
-- ============================================================

local function Initialize()
	-- Wait for workspace to load
	wait(1)

	-- CRITICAL: Disable Roblox's kill plane for deep dungeons
	-- Dungeons go down to Y = -666000 (Floor 666), default kill plane is Y = -500
	workspace.FallenPartsDestroyHeight = -700000
	print("[ServerInit] Set FallenPartsDestroyHeight to -700000 (dungeons go to Y = -666000)")

	-- Spawn Soul Vendor
	SpawnSoulVendor()

	-- TODO: Add other initialization here
	-- - Spawn starting enemies (if any)
	-- - Set up dungeon entrance
	-- - Initialize player data management

	print("[ServerInit] Game initialization complete!")
end

-- Run initialization
Initialize()
