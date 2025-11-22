--[[
════════════════════════════════════════════════════════════════════════════════
Script: EnemyAIManager
Location: ServerScriptService/
Type: Server Script (NOT ModuleScript)
Description: Automatically attaches DOOM-style AI to enemies spawned by your
             dungeon generator. Monitors workspace for new enemies and gives
             them intelligent behaviors.

Version: 1.0
Last Updated: 2025-11-15
════════════════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load weapon generation modules (optional - for giving enemies actual weapons)
local WeaponGenerator, WeaponToolBuilder
pcall(function()
	local Modules = ReplicatedStorage:WaitForChild("Modules", 2)
	if Modules then
		WeaponGenerator = require(Modules:FindFirstChild("WeaponGenerator"))
		WeaponToolBuilder = require(Modules:FindFirstChild("WeaponToolBuilder"))
	end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- ANIMATION SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

--[[
	Default Roblox Animation IDs - These are fallback animations
	Replace these with your custom animation IDs for better results
]]
local DefaultAnimations = {
	-- Universal animations
	Idle = "rbxassetid://507766388",      -- Default idle
	Walk = "rbxassetid://507777826",      -- Default walk
	Run = "rbxassetid://507767714",       -- Default run
	Jump = "rbxassetid://507765000",      -- Default jump
	Fall = "rbxassetid://507767968",      -- Default fall

	-- Combat animations
	MeleeAttack1 = "rbxassetid://522635514",  -- Slash animation
	MeleeAttack2 = "rbxassetid://522638767",  -- Punch animation
	RangedAttack = "rbxassetid://522639910",  -- Point/shoot animation

	-- Reactions
	Hit = "rbxassetid://507768133",       -- Getting hit
	Death = "rbxassetid://507766951",     -- Death/ragdoll
}

--[[
	Animation Controller Class
	Manages animation playback for an enemy
]]
local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(humanoid, archetypeName)
	local self = setmetatable({}, AnimationController)

	self.humanoid = humanoid
	self.animator = humanoid:FindFirstChildOfClass("Animator")

	-- Create Animator if it doesn't exist
	if not self.animator then
		self.animator = Instance.new("Animator")
		self.animator.Parent = humanoid
	end

	self.archetypeName = archetypeName
	self.loadedAnimations = {}
	self.currentAnimation = nil
	self.currentTrack = nil

	-- Load all animations
	self:loadAnimations()

	return self
end

function AnimationController:loadAnimations()
	-- Load animation tracks
	for animName, animId in pairs(DefaultAnimations) do
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		animation.Name = animName

		local success, track = pcall(function()
			return self.animator:LoadAnimation(animation)
		end)

		if success and track then
			self.loadedAnimations[animName] = track
		else
			warn("[AnimationController] Failed to load animation:", animName)
		end
	end

	-- Set animation priorities
	if self.loadedAnimations.Idle then
		self.loadedAnimations.Idle.Priority = Enum.AnimationPriority.Idle
	end
	if self.loadedAnimations.Walk then
		self.loadedAnimations.Walk.Priority = Enum.AnimationPriority.Movement
	end
	if self.loadedAnimations.Run then
		self.loadedAnimations.Run.Priority = Enum.AnimationPriority.Movement
	end

	-- Attack animations should override movement
	for _, animName in ipairs({"MeleeAttack1", "MeleeAttack2", "RangedAttack"}) do
		if self.loadedAnimations[animName] then
			self.loadedAnimations[animName].Priority = Enum.AnimationPriority.Action
		end
	end

	-- Death should override everything
	if self.loadedAnimations.Death then
		self.loadedAnimations.Death.Priority = Enum.AnimationPriority.Action4
	end
end

function AnimationController:play(animationName, fadeTime, speed, looped)
	fadeTime = fadeTime or 0.1
	speed = speed or 1.0
	looped = looped ~= false -- Default true

	local track = self.loadedAnimations[animationName]
	if not track then
		return
	end

	-- Don't restart if already playing the same animation
	if self.currentTrack == track and self.currentTrack.IsPlaying then
		return
	end

	-- Stop current animation
	if self.currentTrack and self.currentTrack.IsPlaying then
		self.currentTrack:Stop(fadeTime)
	end

	-- Play new animation
	track.Looped = looped
	track:Play(fadeTime)
	track:AdjustSpeed(speed)

	self.currentAnimation = animationName
	self.currentTrack = track

	return track
end

function AnimationController:stop(animationName, fadeTime)
	fadeTime = fadeTime or 0.1

	if animationName then
		local track = self.loadedAnimations[animationName]
		if track and track.IsPlaying then
			track:Stop(fadeTime)
		end
	else
		-- Stop all animations
		for _, track in pairs(self.loadedAnimations) do
			if track.IsPlaying then
				track:Stop(fadeTime)
			end
		end
	end
end

function AnimationController:playAttack(isMelee)
	local attackAnim

	if isMelee then
		-- Alternate between melee attacks for variety
		attackAnim = math.random() > 0.5 and "MeleeAttack1" or "MeleeAttack2"
	else
		attackAnim = "RangedAttack"
	end

	local track = self:play(attackAnim, 0.05, 1.2, false) -- Fast fade, 20% faster, non-looping

	return track
end

function AnimationController:playMovement(speed)
	-- Determine animation based on movement speed
	local animToPlay

	if speed < 1 then
		animToPlay = "Idle"
	elseif speed < 18 then
		animToPlay = "Walk"
	else
		animToPlay = "Run"
	end

	-- Adjust animation speed based on actual walk speed
	local animSpeed = 1.0
	if animToPlay == "Walk" then
		animSpeed = speed / 16 -- Normalize to default walk speed
	elseif animToPlay == "Run" then
		animSpeed = speed / 20 -- Normalize to default run speed
	end

	local track = self:play(animToPlay, 0.2, animSpeed, true)
	return track
end

function AnimationController:playDeath()
	self:stop(nil, 0.1) -- Stop all animations quickly
	local track = self:play("Death", 0.05, 1.0, false)
	return track
end

function AnimationController:playHitReaction()
	-- Brief hit reaction without stopping current animation
	local track = self.loadedAnimations.Hit
	if track then
		track.Looped = false
		track.Priority = Enum.AnimationPriority.Action2 -- High priority but not highest
		track:Play(0.05)
		track:AdjustSpeed(1.5) -- Play faster for snappy reaction
	end
end

function AnimationController:getCurrentAnimationName()
	return self.currentAnimation
end

function AnimationController:destroy()
	self:stop(nil, 0)
	for _, track in pairs(self.loadedAnimations) do
		track:Destroy()
	end
	self.loadedAnimations = {}
	self.currentTrack = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- GLOBAL ATTACK TOKEN SYSTEM
-- ════════════════════════════════════════════════════════════════════════════
local AttackTokenManager = {
	maxTokens = 3,
	activeTokens = {},
	tokenQueue = {},
	tokenDuration = 2.0,
}

function AttackTokenManager:requestToken(enemyId, priority)
	if self.activeTokens[enemyId] then return true end

	local tokenCount = 0
	for _ in pairs(self.activeTokens) do tokenCount = tokenCount + 1 end

	if tokenCount < self.maxTokens then
		self.activeTokens[enemyId] = tick()
		return true
	end

	local inQueue = false
	for _, entry in ipairs(self.tokenQueue) do
		if entry.id == enemyId then inQueue = true break end
	end

	if not inQueue then
		table.insert(self.tokenQueue, {id = enemyId, priority = priority or 0})
		table.sort(self.tokenQueue, function(a, b) return a.priority > b.priority end)
	end

	return false
end

function AttackTokenManager:releaseToken(enemyId)
	self.activeTokens[enemyId] = nil
	if #self.tokenQueue > 0 then
		local next = table.remove(self.tokenQueue, 1)
		self.activeTokens[next.id] = tick()
	end
end

function AttackTokenManager:update()
	local currentTime = tick()
	local toRelease = {}
	for enemyId, startTime in pairs(self.activeTokens) do
		if currentTime - startTime > self.tokenDuration then
			table.insert(toRelease, enemyId)
		end
	end
	for _, enemyId in ipairs(toRelease) do
		self:releaseToken(enemyId)
	end
end

function AttackTokenManager:removeEnemy(enemyId)
	self.activeTokens[enemyId] = nil
	for i, entry in ipairs(self.tokenQueue) do
		if entry.id == enemyId then
			table.remove(self.tokenQueue, i)
			break
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- ENEMY ARCHETYPES
-- ════════════════════════════════════════════════════════════════════════════
local EnemyArchetypes = {
	Melee = {
		optimalRange = 4, minRange = 0, maxRange = 10,
		moveSpeed = 20, attackCooldown = 1.0, damage = 15,
		aggressionLevel = 0.9, flankingTendency = 0.6,
		retreatThreshold = 0.2, attackRange = 10,  -- Increased from 6 to 10
	},
	Ranged = {
		optimalRange = 25, minRange = 15, maxRange = 35,
		moveSpeed = 14, attackCooldown = 1.5, damage = 12,  -- Faster fire rate, lower damage per shot
		aggressionLevel = 0.4, flankingTendency = 0.3,
		retreatThreshold = 0.4, attackRange = 40,
		spread = 0.15,  -- Accuracy: 0 = perfect, 1 = very inaccurate
		burstCount = 3,  -- Fire in bursts
		burstDelay = 0.1,  -- Time between shots in burst
	},
	Heavy = {
		optimalRange = 8, minRange = 0, maxRange = 15,
		moveSpeed = 12, attackCooldown = 2.5, damage = 35,
		aggressionLevel = 1.0, flankingTendency = 0.2,
		retreatThreshold = 0.1, attackRange = 12,
	},
	Flanker = {
		optimalRange = 12, minRange = 8, maxRange = 20,
		moveSpeed = 22, attackCooldown = 1.2, damage = 12,
		aggressionLevel = 0.7, flankingTendency = 0.95,
		retreatThreshold = 0.3, attackRange = 15,
		spread = 0.2,  -- Less accurate while moving
		burstCount = 2,
		burstDelay = 0.15,
	},
	Sniper = {
		optimalRange = 50, minRange = 30, maxRange = 70,
		moveSpeed = 12, attackCooldown = 3.0, damage = 30,  -- Reduced from 40
		aggressionLevel = 0.2, flankingTendency = 0.5,
		retreatThreshold = 0.5, attackRange = 80,
		spread = 0.05,  -- Very accurate
		burstCount = 1,  -- Single shot
		burstDelay = 0,
	},
}

-- Map enemy body parts to archetypes (customize for MobGenerator enemies)
local function determineArchetypeFromParts(enemyModel)
	-- Try to read from attributes first
	local torsoType = enemyModel:GetAttribute("TorsoType")
	local legType = enemyModel:GetAttribute("LegType")
	local armType = enemyModel:GetAttribute("ArmType")

	-- Match by body composition
	if torsoType == "Bulky" or torsoType == "Armored" then return "Heavy" end
	if legType == "Spider" or legType == "Digitigrade" then return "Flanker" end
	if armType == "Long" or armType == "Clawed" then return "Melee" end
	if torsoType == "Thin" then return "Flanker" end
	if armType == "None" then return "Ranged" end  -- No arms = uses ranged attacks

	-- Default based on model name
	local name = enemyModel.Name:lower()
	if name:find("hulk") or name:find("heavy") or name:find("boss") then return "Heavy" end
	if name:find("stalker") or name:find("spider") then return "Flanker" end
	if name:find("crawler") or name:find("fiend") then return "Melee" end
	if name:find("marksman") or name:find("sniper") then return "Sniper" end

	-- Random fallback for variety
	local archetypes = {"Melee", "Ranged", "Flanker"}
	return archetypes[math.random(1, #archetypes)]
end

local AIStates = {
	IDLE = "Idle", CHASE = "Chase", POSITION = "Position",
	ATTACK = "Attack", FLANK = "Flank", RETREAT = "Retreat", DEAD = "Dead",
}

-- ════════════════════════════════════════════════════════════════════════════
-- ENEMY AI CLASS
-- ════════════════════════════════════════════════════════════════════════════

local EnemyAI = {}
EnemyAI.__index = EnemyAI

function EnemyAI.new(enemyModel)
	local self = setmetatable({}, EnemyAI)

	self.model = enemyModel
	self.humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
	self.rootPart = enemyModel:FindFirstChild("HumanoidRootPart") or enemyModel.PrimaryPart

	if not self.humanoid or not self.rootPart then
		warn("[EnemyAI] Invalid enemy:", enemyModel.Name, "- missing Humanoid or RootPart")
		return nil
	end

	-- Determine archetype
	local archetypeName = determineArchetypeFromParts(enemyModel)
	self.archetype = EnemyArchetypes[archetypeName] or EnemyArchetypes.Melee
	self.archetypeName = archetypeName

	-- State
	self.currentState = AIStates.IDLE
	self.stateTime = 0
	self.target = nil
	self.lastAttackTime = 0
	self.hasAttackToken = false

	-- Pathfinding
	self.pathWaypoints = {}
	self.currentWaypointIndex = 1
	self.lastPathfindTime = 0
	self.stuckCheckPosition = self.rootPart.Position
	self.stuckTime = 0

	-- Unique ID
	self.id = enemyModel:GetAttribute("UniqueID") or game:GetService("HttpService"):GenerateGUID(false)
	enemyModel:SetAttribute("UniqueID", self.id)
	enemyModel:SetAttribute("AIArchetype", self.archetypeName)
	enemyModel:SetAttribute("HasAI", true)

	-- Configure humanoid
	self.humanoid.WalkSpeed = self.archetype.moveSpeed

	-- Create animation controller
	self.animController = AnimationController.new(self.humanoid, self.archetypeName)
	print(string.format("[EnemyAI] Created animation controller for %s", enemyModel.Name))

	-- Give weapon to ranged enemies
	local isRangedEnemy = (self.archetypeName == "Ranged" or self.archetypeName == "Sniper" or self.archetypeName == "Flanker")
	if isRangedEnemy and WeaponGenerator and WeaponToolBuilder then
		task.spawn(function()
			self:equipWeapon()
		end)
	end

	print(string.format("[EnemyAI] Attached %s AI to %s", self.archetypeName, enemyModel.Name))

	return self
end

function EnemyAI:equipWeapon()
	-- Get enemy level from attributes or default to 1
	local level = self.model:GetAttribute("Level") or 1

	-- Generate appropriate weapon for enemy archetype
	local weaponType
	if self.archetypeName == "Sniper" then
		weaponType = "Rifle"
	elseif self.archetypeName == "Flanker" then
		weaponType = math.random() > 0.5 and "SMG" or "Shotgun"
	else  -- Ranged
		weaponType = "Pistol"
	end

	local rarity = math.random() > 0.7 and "Uncommon" or "Common"

	local weapon = WeaponGenerator:GenerateWeapon(level, weaponType, rarity)
	if not weapon then
		warn("[EnemyAI] Failed to generate weapon for", self.model.Name)
		return
	end

	-- Mark as enemy weapon
	weapon.IsEnemyWeapon = true

	-- Create weapon tool and equip it
	local weaponTool = WeaponToolBuilder:CreateWeaponTool(weapon)
	if weaponTool then
		weaponTool.Parent = self.model
		self.humanoid:EquipTool(weaponTool)
		self.equippedWeapon = weaponTool
		self.weaponData = weapon
		print(string.format("[EnemyAI] Equipped %s with %s (%s %s)",
			self.model.Name, weapon.Name, rarity, weaponType))
	end
end

function EnemyAI:findNearestPlayer()
	local nearestPlayer, nearestDistance = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local playerHumanoid = player.Character:FindFirstChild("Humanoid")
			if playerHumanoid and playerHumanoid.Health > 0 then
				local distance = (player.Character.HumanoidRootPart.Position - self.rootPart.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestPlayer = player.Character
				end
			end
		end
	end
	return nearestPlayer, nearestDistance
end

function EnemyAI:hasLineOfSight(targetPosition)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, 1, 0)
	local rayDirection = (targetPosition - rayOrigin).Unit * 100
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {self.model}
	local result = Workspace:Raycast(rayOrigin, rayDirection, params)
	if result then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		if hitModel and hitModel:FindFirstChild("Humanoid") then
			return true, result.Position
		end
		return false, result.Position
	end
	return true, targetPosition
end

function EnemyAI:getDistanceToTarget()
	if not self.target then return math.huge end
	local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return math.huge end
	return (targetRoot.Position - self.rootPart.Position).Magnitude
end

function EnemyAI:calculateOptimalPosition()
	if not self.target then return self.rootPart.Position end
	local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return self.rootPart.Position end

	local targetPos = targetRoot.Position
	local myPos = self.rootPart.Position
	local direction = (targetPos - myPos).Unit
	local desiredDistance = self.archetype.optimalRange + (math.random() - 0.5) * 5
	local optimalPos = targetPos - direction * desiredDistance

	if math.random() < self.archetype.flankingTendency then
		local sideOffset = self.rootPart.CFrame.RightVector * (math.random() > 0.5 and 10 or -10)
		optimalPos = optimalPos + sideOffset
	end

	return Vector3.new(optimalPos.X, myPos.Y, optimalPos.Z)
end

function EnemyAI:findFlankingPosition()
	if not self.target then return self.rootPart.Position end
	local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return self.rootPart.Position end

	local targetPos = targetRoot.Position
	local targetLook = targetRoot.CFrame.LookVector
	local positions = {
		targetPos - targetLook * self.archetype.optimalRange,
		targetPos - targetRoot.CFrame.RightVector * self.archetype.optimalRange,
		targetPos + targetRoot.CFrame.RightVector * self.archetype.optimalRange,
	}

	local bestPos, bestScore = positions[1], 0
	for _, pos in ipairs(positions) do
		local score = (pos - self.rootPart.Position).Magnitude
		if score > bestScore then bestScore, bestPos = score, pos end
	end

	return Vector3.new(bestPos.X, self.rootPart.Position.Y, bestPos.Z)
end

function EnemyAI:pathfindTo(targetPosition)
	if tick() - self.lastPathfindTime < 0.5 then return end
	self.lastPathfindTime = tick()

	local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
	local success = pcall(function() path:ComputeAsync(self.rootPart.Position, targetPosition) end)

	if success and path.Status == Enum.PathStatus.Success then
		self.pathWaypoints = path:GetWaypoints()
		self.currentWaypointIndex = 2
	else
		self.pathWaypoints = {{Position = targetPosition}}
		self.currentWaypointIndex = 1
	end
end

function EnemyAI:moveAlongPath()
	if #self.pathWaypoints == 0 or self.currentWaypointIndex > #self.pathWaypoints then
		return false
	end

	local waypoint = self.pathWaypoints[self.currentWaypointIndex]
	local waypointPos = waypoint.Position or waypoint

	if (waypointPos - self.rootPart.Position).Magnitude < 3 then
		self.currentWaypointIndex = self.currentWaypointIndex + 1
		if self.currentWaypointIndex > #self.pathWaypoints then return false end
		waypoint = self.pathWaypoints[self.currentWaypointIndex]
		waypointPos = waypoint.Position or waypoint
	end

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	self.humanoid:MoveTo(waypointPos)
	return true
end

function EnemyAI:canAttack()
	if not self.target then return false end
	local distance = self:getDistanceToTarget()
	if distance > self.archetype.attackRange then return false end
	if tick() - self.lastAttackTime < self.archetype.attackCooldown then return false end

	local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return false end
	local hasLOS = self:hasLineOfSight(targetRoot.Position)
	return hasLOS
end

function EnemyAI:performAttack()
	if not self.target then return end
	local targetHumanoid = self.target:FindFirstChild("Humanoid")
	if not targetHumanoid then return end

	local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end

	-- Face target
	self.rootPart.CFrame = CFrame.new(self.rootPart.Position,
		Vector3.new(targetRoot.Position.X, self.rootPart.Position.Y, targetRoot.Position.Z))

	-- RANGED ATTACK: Projectile with spread and bursts
	if self.archetypeName == "Ranged" or self.archetypeName == "Sniper" or self.archetypeName == "Flanker" then
		-- Play ranged attack animation
		local attackTrack = self.animController:playAttack(false)

		-- Small delay before firing for animation windup
		task.delay(0.15, function()
			self:performRangedAttack(targetRoot, targetHumanoid)
		end)
	else
		-- MELEE ATTACK: Play animation and deal damage at peak
		local attackTrack = self.animController:playAttack(true)

		-- Deal damage at animation peak (around 40% through animation)
		task.delay(0.25, function()
			self:performMeleeDamage(targetRoot, targetHumanoid)
		end)
	end

	self.lastAttackTime = tick()

	if self.hasAttackToken then
		task.delay(0.5, function()
			AttackTokenManager:releaseToken(self.id)
			self.hasAttackToken = false
		end)
	end
end

function EnemyAI:performMeleeDamage(targetRoot, targetHumanoid)
	-- Check if target still exists
	if not self.target or not self.target.Parent then return end
	if not targetRoot or not targetRoot.Parent then return end
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end

	-- MELEE ATTACK: Improved hit detection with range check
	local distance = (targetRoot.Position - self.rootPart.Position).Magnitude
	if distance <= self.archetype.attackRange then
		-- Verify target is still in front of us
		local toTarget = (targetRoot.Position - self.rootPart.Position).Unit
		local lookDirection = self.rootPart.CFrame.LookVector
		local dot = toTarget:Dot(lookDirection)

		if dot > 0.5 then  -- Target is in front (within 60 degree cone)
			-- Deal damage through shield system if player has shield
			local damage = self.archetype.damage
			if _G.AbsorbShieldDamage and game.Players:GetPlayerFromCharacter(self.target) then
				local player = game.Players:GetPlayerFromCharacter(self.target)
				damage = _G.AbsorbShieldDamage(player, damage)
			end

			-- Apply remaining damage to health
			if damage > 0 then
				targetHumanoid:TakeDamage(damage)

				-- Play hit reaction on player if they have animation controller
				if self.target:FindFirstChild("Humanoid") then
					-- Could trigger player hit reaction here
				end
			end

			print(string.format("[EnemyAI] %s melee hit %s for %d damage (dist: %.1f)",
				self.archetypeName, self.target.Name, self.archetype.damage, distance))
		else
			print(string.format("[EnemyAI] %s melee MISSED - target not in front (dot: %.2f)",
				self.archetypeName, dot))
		end
	else
		print(string.format("[EnemyAI] %s melee MISSED - out of range (dist: %.1f > %.1f)",
			self.archetypeName, distance, self.archetype.attackRange))
	end
end

function EnemyAI:performRangedAttack(targetRoot, targetHumanoid)
	local burstCount = self.archetype.burstCount or 1
	local burstDelay = self.archetype.burstDelay or 0
	local spread = self.archetype.spread or 0.05

	-- Fire burst
	for shotNum = 1, burstCount do
		task.spawn(function()
			-- Slight delay for each shot in burst
			if shotNum > 1 then
				task.wait(burstDelay * (shotNum - 1))
			end

			-- Calculate aim with target leading
			local targetVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.zero
			local projectileSpeed = 120
			local distance = (targetRoot.Position - self.rootPart.Position).Magnitude
			local timeToHit = distance / projectileSpeed
			local leadPosition = targetRoot.Position + (targetVelocity * timeToHit * 0.4)

			-- Apply spread/inaccuracy
			local spreadX = (math.random() - 0.5) * spread * distance
			local spreadY = (math.random() - 0.5) * spread * distance
			local spreadZ = (math.random() - 0.5) * spread * distance
			local aimPosition = leadPosition + Vector3.new(spreadX, spreadY, spreadZ)

			-- Spawn muzzle flash
			local muzzleFlash = Instance.new("Part")
			muzzleFlash.Name = "MuzzleFlash"
			muzzleFlash.Shape = Enum.PartType.Ball
			muzzleFlash.Size = Vector3.new(1, 1, 1)
			muzzleFlash.Color = Color3.fromRGB(255, 200, 100)
			muzzleFlash.Material = Enum.Material.Neon
			muzzleFlash.Anchored = true
			muzzleFlash.CanCollide = false
			muzzleFlash.Transparency = 0.3
			muzzleFlash.CFrame = self.rootPart.CFrame * CFrame.new(0, 1.5, -1)
			muzzleFlash.Parent = workspace
			game:GetService("Debris"):AddItem(muzzleFlash, 0.1)

			-- Spawn projectile
			local projectile = Instance.new("Part")
			projectile.Name = "EnemyProjectile"
			projectile.Shape = Enum.PartType.Ball
			projectile.Size = Vector3.new(0.5, 0.5, 0.5)
			projectile.Color = Color3.fromRGB(255, 100, 100)
			projectile.Material = Enum.Material.Neon
			projectile.Anchored = false
			projectile.CanCollide = false
			projectile.CFrame = self.rootPart.CFrame * CFrame.new(0, 1.5, -1)
			projectile.Parent = workspace

			-- Add glow
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 80, 80)
			light.Brightness = 3
			light.Range = 8
			light.Parent = projectile

			-- Store damage data
			projectile:SetAttribute("Damage", self.archetype.damage)
			projectile:SetAttribute("IsEnemyProjectile", true)
			projectile:SetAttribute("OwnerID", self.id)

			-- Launch
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVelocity.Velocity = (aimPosition - projectile.Position).Unit * projectileSpeed
			bodyVelocity.Parent = projectile

			-- Collision detection
			local hitConnection
			hitConnection = projectile.Touched:Connect(function(hit)
				if hit:IsDescendantOf(self.model) then return end

				local hitModel = hit.Parent
				if hitModel and hitModel:FindFirstChild("Humanoid") then
					local hitHumanoid = hitModel:FindFirstChild("Humanoid")
					if hitHumanoid and hitHumanoid.Health > 0 then
						-- Deal damage through shield system if player has shield
						local damage = self.archetype.damage
						if _G.AbsorbShieldDamage and game.Players:GetPlayerFromCharacter(hitModel) then
							local player = game.Players:GetPlayerFromCharacter(hitModel)
							damage = _G.AbsorbShieldDamage(player, damage)
						end

						-- Apply remaining damage to health
						if damage > 0 then
							hitHumanoid:TakeDamage(damage)
						end

						print(string.format("[EnemyAI] %s projectile hit %s for %d damage",
							self.archetypeName, hitModel.Name, self.archetype.damage))
					end
				end

				hitConnection:Disconnect()
				projectile:Destroy()
			end)

			-- Auto-destroy after 3 seconds
			task.delay(3, function()
				if projectile.Parent then projectile:Destroy() end
			end)
		end)
	end
end

function EnemyAI:changeState(newState)
	if self.currentState == newState then return end

	local oldState = self.currentState
	self.currentState = newState
	self.stateTime = 0

	-- Update walk speed based on state
	if newState == AIStates.ATTACK then
		self.humanoid.WalkSpeed = 0
	elseif newState == AIStates.CHASE then
		self.humanoid.WalkSpeed = self.archetype.moveSpeed * 1.2
	elseif newState == AIStates.RETREAT then
		self.humanoid.WalkSpeed = self.archetype.moveSpeed * 1.1 -- Faster retreat
	elseif newState == AIStates.DEAD then
		self.humanoid.WalkSpeed = 0
		-- Play death animation
		self.animController:playDeath()
		print(string.format("[EnemyAI] %s died - playing death animation", self.model.Name))
	else
		self.humanoid.WalkSpeed = self.archetype.moveSpeed
	end

	-- Update movement animation immediately when state changes
	if newState ~= AIStates.ATTACK and newState ~= AIStates.DEAD then
		self.animController:playMovement(self.humanoid.WalkSpeed)
	end

	print(string.format("[EnemyAI] %s: %s → %s", self.model.Name, oldState, newState))
end

function EnemyAI:update(deltaTime)
	self.stateTime = self.stateTime + deltaTime

	if self.humanoid.Health <= 0 then
		self:changeState(AIStates.DEAD)
		AttackTokenManager:removeEnemy(self.id)
		return
	end

	-- Update movement animation periodically (every 0.5 seconds)
	if self.currentState ~= AIStates.ATTACK and self.currentState ~= AIStates.DEAD then
		if not self.lastAnimUpdate or tick() - self.lastAnimUpdate > 0.5 then
			self.animController:playMovement(self.humanoid.WalkSpeed)
			self.lastAnimUpdate = tick()
		end
	end

	if not self.target or not self.target.Parent then
		self.target = self:findNearestPlayer()
		if not self.target then
			self:changeState(AIStates.IDLE)
			return
		end
	end

	local targetHumanoid = self.target:FindFirstChild("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		self.target = nil
		self:changeState(AIStates.IDLE)
		return
	end

	local distance = self:getDistanceToTarget()
	local healthPercent = self.humanoid.Health / self.humanoid.MaxHealth

	if self.currentState == AIStates.IDLE then
		if distance < 60 then self:changeState(AIStates.CHASE) end

	elseif self.currentState == AIStates.CHASE then
		if distance <= self.archetype.maxRange and distance >= self.archetype.minRange then
			if self:canAttack() and AttackTokenManager:requestToken(self.id, distance) then
				self.hasAttackToken = true
				self:changeState(AIStates.ATTACK)
			elseif math.random() < self.archetype.flankingTendency then
				self:changeState(AIStates.FLANK)
			else
				self:changeState(AIStates.POSITION)
			end
		elseif distance > self.archetype.maxRange then
			self:pathfindTo(self.target.HumanoidRootPart.Position)
			self:moveAlongPath()
		elseif distance < self.archetype.minRange and self.archetype.aggressionLevel < 0.7 then
			self:changeState(AIStates.RETREAT)
		end

	elseif self.currentState == AIStates.POSITION then
		self:pathfindTo(self:calculateOptimalPosition())
		if not self:moveAlongPath() or self.stateTime > 3 then
			if self:canAttack() and AttackTokenManager:requestToken(self.id, distance) then
				self.hasAttackToken = true
				self:changeState(AIStates.ATTACK)
			else
				self:changeState(AIStates.CHASE)
			end
		end

	elseif self.currentState == AIStates.FLANK then
		self:pathfindTo(self:findFlankingPosition())
		if not self:moveAlongPath() or self.stateTime > 4 then
			if self:canAttack() and AttackTokenManager:requestToken(self.id, distance) then
				self.hasAttackToken = true
				self:changeState(AIStates.ATTACK)
			else
				self:changeState(AIStates.CHASE)
			end
		end

	elseif self.currentState == AIStates.ATTACK then
		if self:canAttack() then self:performAttack() end
		if self.stateTime > 0.5 then
			if healthPercent < self.archetype.retreatThreshold then
				self:changeState(AIStates.RETREAT)
			else
				self:changeState(AIStates.POSITION)
			end
		end

	elseif self.currentState == AIStates.RETREAT then
		local targetRoot = self.target:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			local awayDirection = (self.rootPart.Position - targetRoot.Position).Unit
			self.humanoid:MoveTo(self.rootPart.Position + awayDirection * 20)
		end
		if self.stateTime > 3 or distance > self.archetype.maxRange then
			self:changeState(AIStates.POSITION)
		end
	end

	-- Stuck detection
	local movedDistance = (self.rootPart.Position - self.stuckCheckPosition).Magnitude
	if movedDistance < 1 then
		self.stuckTime = self.stuckTime + deltaTime
		if self.stuckTime > 2 then
			self.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			self.stuckTime = 0
			self.lastPathfindTime = 0
		end
	else
		self.stuckTime = 0
		self.stuckCheckPosition = self.rootPart.Position
	end
end

function EnemyAI:destroy()
	AttackTokenManager:removeEnemy(self.id)

	-- Cleanup animation controller
	if self.animController then
		self.animController:destroy()
		self.animController = nil
	end

	self.target = nil
	self.model = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- AUTO-ATTACH SYSTEM
-- ════════════════════════════════════════════════════════════════════════════

local ActiveEnemies = {}

local function isEnemy(model)
	if not model:IsA("Model") then return false end
	if not model:FindFirstChildOfClass("Humanoid") then return false end

	-- Not a player
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == model then return false end
	end

	-- Already has AI
	if model:GetAttribute("HasAI") then return false end

	-- Check attributes
	if model:GetAttribute("Level") then return true end
	if model:GetAttribute("EnemyType") then return true end
	if model:GetAttribute("IsBoss") ~= nil then return true end
	if model:GetAttribute("IsEnemy") then return true end

	-- Check by name
	local name = model.Name:lower()
	local enemyPatterns = {
		"enemy", "crawler", "fiend", "hulk", "stalker", "demon", "boss",
		"minion", "mob", "cursed", "vile", "shadow", "blood", "bone",
		"dark", "plague", "rot", "doom", "wretched", "lurker", "horror",
		"beast", "brute", "shambler", "wraith", "ghoul"
	}
	for _, pattern in ipairs(enemyPatterns) do
		if string.find(name, pattern) then return true end
	end

	return false
end

local function attachAIToEnemy(enemyModel)
	local ai = EnemyAI.new(enemyModel)
	if ai then
		ActiveEnemies[ai.id] = ai

		enemyModel.Destroying:Connect(function()
			if ActiveEnemies[ai.id] then
				ai:destroy()
				ActiveEnemies[ai.id] = nil
			end
		end)
	end
end

-- Initial scan
local function scanForEnemies(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if isEnemy(child) then
			attachAIToEnemy(child)
		end
	end
end

scanForEnemies(Workspace)

-- Watch for new enemies
Workspace.DescendantAdded:Connect(function(descendant)
	task.delay(0.1, function()
		if isEnemy(descendant) then
			attachAIToEnemy(descendant)
		end
	end)
end)

-- Main update loop
local lastUpdate = tick()
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	local deltaTime = currentTime - lastUpdate
	lastUpdate = currentTime

	AttackTokenManager:update()

	for id, ai in pairs(ActiveEnemies) do
		if ai.model and ai.model.Parent and ai.humanoid and ai.humanoid.Health > 0 then
			ai:update(deltaTime)
		else
			ai:destroy()
			ActiveEnemies[id] = nil
		end
	end
end)

print("[EnemyAIManager] ═══════════════════════════════════════")
print("[EnemyAIManager] Auto-Attach AI System Active")
print("[EnemyAIManager] Attack Tokens:", AttackTokenManager.maxTokens)
print("[EnemyAIManager] Monitoring workspace for enemies...")
print("[EnemyAIManager] ═══════════════════════════════════════")
