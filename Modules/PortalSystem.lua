--[[
════════════════════════════════════════════════════════════════════════════════
Module: PortalSystem
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Creates and manages entrance/exit portals for floor transitions.
             Handles teleportation between floors in dungeon descent.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local PortalSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	-- Portal appearance
	PortalSize = Vector3.new(6, 10, 1),
	PortalColor = {
		Entrance = Color3.fromRGB(100, 150, 255), -- Blue (going back up)
		Exit = Color3.fromRGB(255, 80, 80),       -- Red (descending)
	},

	-- Visual effects
	RotationSpeed = 0.5,  -- Radians per second
	PulseSpeed = 2,       -- Brightness pulse speed
	ParticleRate = 20,

	-- Interaction
	ActivationDistance = 10,
	CooldownTime = 2,     -- Seconds between portal uses
}

-- Track active portals
local ActivePortals = {}
local PlayerCooldowns = {}

-- ════════════════════════════════════════════════════════════════════════════
-- PORTAL CREATION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Creates a portal at a specific location
	@param position - CFrame for portal location
	@param portalType - "Entrance" or "Exit"
	@param targetFloor - Floor number this portal leads to
	@param parentFolder - Parent folder for the portal
	@return portal model
]]
function PortalSystem:CreatePortal(position, portalType, targetFloor, parentFolder)
	local portal = Instance.new("Model")
	portal.Name = portalType .. "Portal_" .. targetFloor
	portal.Parent = parentFolder or workspace

	-- Main portal frame (transparent, for collision)
	local frame = Instance.new("Part")
	frame.Name = "PortalFrame"
	frame.Size = Config.PortalSize
	frame.CFrame = position
	frame.Anchored = true
	frame.CanCollide = false
	frame.Transparency = 1
	frame.Parent = portal

	-- Visual portal surface (glowing effect)
	local surface = Instance.new("Part")
	surface.Name = "PortalSurface"
	surface.Size = Vector3.new(Config.PortalSize.X * 0.9, Config.PortalSize.Y * 0.9, 0.5)
	surface.CFrame = position
	surface.Anchored = true
	surface.CanCollide = false
	surface.Material = Enum.Material.Neon
	surface.Color = Config.PortalColor[portalType]
	surface.Transparency = 0.3
	surface.Parent = portal

	-- Add swirling effect with texture
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.AlwaysOnTop = false
	surfaceGui.Parent = surface

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://6552204699" -- Swirl effect
	imageLabel.ImageColor3 = Config.PortalColor[portalType]
	imageLabel.ImageTransparency = 0.5
	imageLabel.Parent = surfaceGui

	-- Portal light
	local light = Instance.new("PointLight")
	light.Color = Config.PortalColor[portalType]
	light.Brightness = 5
	light.Range = 30
	light.Shadows = true
	light.Parent = surface

	-- Touch detection part
	local touchPart = Instance.new("Part")
	touchPart.Name = "TouchPart"
	touchPart.Size = Config.PortalSize
	touchPart.CFrame = position
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.Transparency = 1
	touchPart.Parent = portal

	-- Store portal data
	portal:SetAttribute("PortalType", portalType)
	portal:SetAttribute("TargetFloor", targetFloor)
	portal:SetAttribute("IsPortal", true)

	-- Add to tracking
	table.insert(ActivePortals, portal)

	-- Start visual effects
	self:StartPortalEffects(portal, surface, imageLabel, light)

	-- Add proximity prompt for interaction
	self:AddProximityPrompt(touchPart, portalType, targetFloor)

	print(string.format("[PortalSystem] Created %s portal to floor %d", portalType, targetFloor))

	return portal
end

--[[
	Creates entrance and exit portals for a floor
	@param dungeonModel - The dungeon model
	@param currentFloor - Current floor number
	@param spawnPosition - Player spawn position
	@return entrancePortal, exitPortal
]]
function PortalSystem:CreateFloorPortals(dungeonModel, currentFloor, spawnPosition)
	if not dungeonModel then
		warn("[PortalSystem] No dungeon model provided")
		return nil, nil
	end

	-- Find spawn markers
	local spawnsFolder = dungeonModel:FindFirstChild("Spawns")
	if not spawnsFolder then
		warn("[PortalSystem] No Spawns folder found in dungeon")
		return nil, nil
	end

	-- Entrance portal (goes back to previous floor)
	local entrancePortal = nil
	if currentFloor > 1 then
		local entrancePos = spawnPosition or (spawnsFolder:FindFirstChild("PlayerSpawn") and spawnsFolder.PlayerSpawn.CFrame)
		if entrancePos then
			-- Place entrance portal behind spawn point
			local backOffset = entrancePos * CFrame.new(0, 0, 10)
			entrancePortal = self:CreatePortal(backOffset, "Entrance", currentFloor - 1, dungeonModel)
		end
	end

	-- Exit portal (goes to next floor) - place at furthest point from spawn
	local exitPos = self:FindFurthestSpawn(spawnsFolder, spawnPosition)
	if exitPos then
		local exitPortal = self:CreatePortal(exitPos, "Exit", currentFloor + 1, dungeonModel)
		return entrancePortal, exitPortal
	end

	return entrancePortal, nil
end

--[[
	Finds the spawn point furthest from the player spawn
	@param spawnsFolder - Folder containing spawn markers
	@param playerSpawn - Player spawn CFrame
	@return furthest spawn CFrame
]]
function PortalSystem:FindFurthestSpawn(spawnsFolder, playerSpawn)
	if not spawnsFolder or not playerSpawn then return nil end

	local playerPos = playerSpawn.Position
	local furthestSpawn = nil
	local maxDistance = 0

	for _, spawn in ipairs(spawnsFolder:GetChildren()) do
		if spawn:IsA("BasePart") and spawn:GetAttribute("SpawnType") == "Enemy" then
			local distance = (spawn.Position - playerPos).Magnitude
			if distance > maxDistance then
				maxDistance = distance
				furthestSpawn = spawn
			end
		end
	end

	return furthestSpawn and furthestSpawn.CFrame
end

-- ════════════════════════════════════════════════════════════════════════════
-- PORTAL EFFECTS
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Starts visual effects for a portal
	@param portal - The portal model
	@param surface - The portal surface part
	@param imageLabel - The swirl image
	@param light - The point light
]]
function PortalSystem:StartPortalEffects(portal, surface, imageLabel, light)
	-- Rotation animation
	task.spawn(function()
		while portal.Parent do
			local rotation = CFrame.Angles(0, 0, tick() * Config.RotationSpeed)
			surface.CFrame = surface.CFrame * rotation
			imageLabel.Rotation = (tick() * 30) % 360
			task.wait()
		end
	end)

	-- Pulse animation
	task.spawn(function()
		while portal.Parent do
			local pulse = math.sin(tick() * Config.PulseSpeed) * 0.15 + 0.85
			light.Brightness = 5 * pulse
			surface.Transparency = 0.3 + (0.2 * (1 - pulse))
			task.wait()
		end
	end)

	-- Add particle effect
	local particles = Instance.new("ParticleEmitter")
	particles.Rate = Config.ParticleRate
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Speed = NumberRange.new(2, 5)
	particles.Color = ColorSequence.new(surface.Color)
	particles.Size = NumberSequence.new(0.5)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.EmissionDirection = Enum.NormalId.Front
	particles.Parent = surface
end

-- ════════════════════════════════════════════════════════════════════════════
-- INTERACTION
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Adds proximity prompt to a portal
	@param touchPart - The touch detection part
	@param portalType - "Entrance" or "Exit"
	@param targetFloor - Target floor number
]]
function PortalSystem:AddProximityPrompt(touchPart, portalType, targetFloor)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = portalType == "Entrance" and "Return" or "Descend"
	prompt.ObjectText = string.format("Floor %d", targetFloor)
	prompt.MaxActivationDistance = Config.ActivationDistance
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = touchPart

	-- Handle portal activation
	prompt.Triggered:Connect(function(player)
		self:UsePortal(player, targetFloor, portalType)
	end)
end

--[[
	Handles player using a portal
	@param player - The player
	@param targetFloor - Target floor number
	@param portalType - "Entrance" or "Exit"
]]
function PortalSystem:UsePortal(player, targetFloor, portalType)
	-- Check cooldown
	if PlayerCooldowns[player.UserId] and tick() - PlayerCooldowns[player.UserId] < Config.CooldownTime then
		warn("[PortalSystem] Portal on cooldown for", player.Name)
		return
	end

	print(string.format("[PortalSystem] %s using %s portal to floor %d", player.Name, portalType, targetFloor))

	-- Mark cooldown
	PlayerCooldowns[player.UserId] = tick()

	-- Play portal effect on player
	self:PlayPortalTransition(player)

	-- Teleport player (this will be handled by DungeonInstanceManager)
	local DungeonInstanceManager = require(ReplicatedStorage.Modules.DungeonInstanceManager)
	local success = DungeonInstanceManager.TeleportToFloor(player, targetFloor)

	if not success then
		warn("[PortalSystem] Failed to teleport", player.Name, "to floor", targetFloor)
	end
end

--[[
	Plays portal transition effect on player
	@param player - The player
]]
function PortalSystem:PlayPortalTransition(player)
	local character = player.Character
	if not character then return end

	-- Create flash effect
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Brightness = 0
	flash.Contrast = 0
	flash.Parent = game.Lighting

	-- Flash in
	local tweenIn = TweenService:Create(flash, TweenInfo.new(0.3), {Brightness = 1})
	tweenIn:Play()

	task.wait(0.3)

	-- Flash out
	local tweenOut = TweenService:Create(flash, TweenInfo.new(0.5), {Brightness = 0})
	tweenOut:Play()

	task.wait(0.5)
	flash:Destroy()
end

-- ════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Removes a portal from the world
	@param portal - The portal model
]]
function PortalSystem:RemovePortal(portal)
	if not portal then return end

	-- Remove from tracking
	for i, p in ipairs(ActivePortals) do
		if p == portal then
			table.remove(ActivePortals, i)
			break
		end
	end

	portal:Destroy()
	print("[PortalSystem] Removed portal")
end

--[[
	Removes all portals
]]
function PortalSystem:ClearAllPortals()
	for _, portal in ipairs(ActivePortals) do
		if portal.Parent then
			portal:Destroy()
		end
	end
	ActivePortals = {}
	print("[PortalSystem] Cleared all portals")
end

return PortalSystem
