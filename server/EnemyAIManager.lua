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
		optimalRange = 5, minRange = 0, maxRange = 8,
		moveSpeed = 18, attackCooldown = 1.2, damage = 15,
		aggressionLevel = 0.9, flankingTendency = 0.6,
		retreatThreshold = 0.2, attackRange = 6,
	},
	Ranged = {
		optimalRange = 25, minRange = 15, maxRange = 35,
		moveSpeed = 14, attackCooldown = 2.0, damage = 20,
		aggressionLevel = 0.4, flankingTendency = 0.3,
		retreatThreshold = 0.4, attackRange = 40,
	},
	Heavy = {
		optimalRange = 10, minRange = 0, maxRange = 15,
		moveSpeed = 10, attackCooldown = 3.0, damage = 35,
		aggressionLevel = 1.0, flankingTendency = 0.2,
		retreatThreshold = 0.1, attackRange = 12,
	},
	Flanker = {
		optimalRange = 12, minRange = 8, maxRange = 20,
		moveSpeed = 22, attackCooldown = 1.5, damage = 12,
		aggressionLevel = 0.7, flankingTendency = 0.95,
		retreatThreshold = 0.3, attackRange = 15,
	},
	Sniper = {
		optimalRange = 50, minRange = 30, maxRange = 70,
		moveSpeed = 12, attackCooldown = 4.0, damage = 40,
		aggressionLevel = 0.2, flankingTendency = 0.5,
		retreatThreshold = 0.5, attackRange = 80,
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

	print(string.format("[EnemyAI] Attached %s AI to %s", self.archetypeName, enemyModel.Name))

	return self
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
	if targetRoot then
		self.rootPart.CFrame = CFrame.new(self.rootPart.Position,
			Vector3.new(targetRoot.Position.X, self.rootPart.Position.Y, targetRoot.Position.Z))
	end

	targetHumanoid:TakeDamage(self.archetype.damage)
	self.lastAttackTime = tick()

	if self.hasAttackToken then
		task.delay(0.5, function()
			AttackTokenManager:releaseToken(self.id)
			self.hasAttackToken = false
		end)
	end
end

function EnemyAI:changeState(newState)
	if self.currentState == newState then return end
	self.currentState = newState
	self.stateTime = 0

	if newState == AIStates.ATTACK then
		self.humanoid.WalkSpeed = 0
	elseif newState == AIStates.CHASE then
		self.humanoid.WalkSpeed = self.archetype.moveSpeed * 1.2
	else
		self.humanoid.WalkSpeed = self.archetype.moveSpeed
	end
end

function EnemyAI:update(deltaTime)
	self.stateTime = self.stateTime + deltaTime

	if self.humanoid.Health <= 0 then
		self:changeState(AIStates.DEAD)
		AttackTokenManager:removeEnemy(self.id)
		return
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
