--[[
════════════════════════════════════════════════════════════════════════════════
Module: PartyManager
Location: ReplicatedStorage/Modules/
Type: ModuleScript
Description: Manages player parties for co-op dungeon instances.
             Supports up to 4 players per party with leader management.
Version: 1.0
Last Updated: 2025-11-21
════════════════════════════════════════════════════════════════════════════════
--]]

local PartyManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ════════════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local Config = {
	MaxPartySize = 4,
	InviteTimeout = 30, -- Seconds before invite expires
}

-- ════════════════════════════════════════════════════════════════════════════
-- STATE
-- ════════════════════════════════════════════════════════════════════════════

-- Party data structure:
-- {
--   PartyID = string (UserId of leader),
--   Leader = Player,
--   Members = {Player1, Player2, ...},
--   Created = tick()
-- }

local Parties = {} -- [PartyID] = PartyData
local PlayerParties = {} -- [UserId] = PartyID
local PendingInvites = {} -- [targetUserId] = {inviterUserId, partyID, expiresAt}

-- ════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════

local function generatePartyID(leaderUserId)
	return "Party_" .. leaderUserId .. "_" .. tick()
end

local function getPlayerByUserId(userId)
	return Players:GetPlayerByUserId(userId)
end

local function isInParty(player)
	return PlayerParties[player.UserId] ~= nil
end

local function getPartySize(partyID)
	local party = Parties[partyID]
	if not party then return 0 end
	return #party.Members
end

-- ════════════════════════════════════════════════════════════════════════════
-- PARTY CREATION & MANAGEMENT
-- ════════════════════════════════════════════════════════════════════════════

function PartyManager:CreateParty(leader)
	if not leader or not leader:IsA("Player") then
		warn("[PartyManager] Invalid leader")
		return nil
	end

	-- Leave current party if in one
	if isInParty(leader) then
		self:LeaveParty(leader)
	end

	local partyID = generatePartyID(leader.UserId)

	Parties[partyID] = {
		PartyID = partyID,
		Leader = leader,
		Members = {leader},
		Created = tick(),
	}

	PlayerParties[leader.UserId] = partyID

	print(string.format("[PartyManager] %s created party %s", leader.Name, partyID))

	return partyID
end

function PartyManager:DisbandParty(partyID)
	local party = Parties[partyID]
	if not party then
		warn("[PartyManager] Party not found:", partyID)
		return false
	end

	-- Remove all members from tracking
	for _, member in ipairs(party.Members) do
		PlayerParties[member.UserId] = nil
	end

	Parties[partyID] = nil

	print(string.format("[PartyManager] Disbanded party %s", partyID))

	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- INVITES
-- ════════════════════════════════════════════════════════════════════════════

function PartyManager:InvitePlayer(inviter, targetPlayer)
	if not inviter or not targetPlayer then
		warn("[PartyManager] Invalid invite parameters")
		return false
	end

	-- Check if inviter is in a party
	local partyID = PlayerParties[inviter.UserId]
	if not partyID then
		-- Create a party if inviter doesn't have one
		partyID = self:CreateParty(inviter)
	end

	local party = Parties[partyID]
	if not party then
		warn("[PartyManager] Party not found")
		return false
	end

	-- Only leader can invite
	if party.Leader.UserId ~= inviter.UserId then
		warn("[PartyManager] Only party leader can invite")
		return false
	end

	-- Check party size
	if getPartySize(partyID) >= Config.MaxPartySize then
		warn("[PartyManager] Party is full")
		return false
	end

	-- Check if target is already in a party
	if isInParty(targetPlayer) then
		warn("[PartyManager] Target player is already in a party")
		return false
	end

	-- Check if invite already exists
	if PendingInvites[targetPlayer.UserId] then
		warn("[PartyManager] Player already has a pending invite")
		return false
	end

	-- Create invite
	PendingInvites[targetPlayer.UserId] = {
		inviterUserId = inviter.UserId,
		partyID = partyID,
		expiresAt = tick() + Config.InviteTimeout,
	}

	print(string.format("[PartyManager] %s invited %s to party %s", inviter.Name, targetPlayer.Name, partyID))

	-- Auto-expire invite
	task.delay(Config.InviteTimeout, function()
		if PendingInvites[targetPlayer.UserId] and PendingInvites[targetPlayer.UserId].partyID == partyID then
			PendingInvites[targetPlayer.UserId] = nil
			print(string.format("[PartyManager] Invite to %s expired", targetPlayer.Name))
		end
	end)

	return true
end

function PartyManager:AcceptInvite(player)
	if not player then return false end

	local invite = PendingInvites[player.UserId]
	if not invite then
		warn("[PartyManager] No pending invite")
		return false
	end

	-- Check if invite expired
	if tick() > invite.expiresAt then
		PendingInvites[player.UserId] = nil
		warn("[PartyManager] Invite expired")
		return false
	end

	local partyID = invite.partyID
	local party = Parties[partyID]

	if not party then
		PendingInvites[player.UserId] = nil
		warn("[PartyManager] Party no longer exists")
		return false
	end

	-- Check party size again
	if getPartySize(partyID) >= Config.MaxPartySize then
		PendingInvites[player.UserId] = nil
		warn("[PartyManager] Party is now full")
		return false
	end

	-- Leave current party if in one
	if isInParty(player) then
		self:LeaveParty(player)
	end

	-- Add to party
	table.insert(party.Members, player)
	PlayerParties[player.UserId] = partyID
	PendingInvites[player.UserId] = nil

	print(string.format("[PartyManager] %s joined party %s", player.Name, partyID))

	return true
end

function PartyManager:DeclineInvite(player)
	if not player then return false end

	if PendingInvites[player.UserId] then
		PendingInvites[player.UserId] = nil
		print(string.format("[PartyManager] %s declined invite", player.Name))
		return true
	end

	return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- LEAVING & KICKING
-- ════════════════════════════════════════════════════════════════════════════

function PartyManager:LeaveParty(player)
	if not player then return false end

	local partyID = PlayerParties[player.UserId]
	if not partyID then
		warn("[PartyManager] Player not in a party")
		return false
	end

	local party = Parties[partyID]
	if not party then
		PlayerParties[player.UserId] = nil
		return false
	end

	-- Remove from members
	for i, member in ipairs(party.Members) do
		if member.UserId == player.UserId then
			table.remove(party.Members, i)
			break
		end
	end

	PlayerParties[player.UserId] = nil

	print(string.format("[PartyManager] %s left party %s", player.Name, partyID))

	-- If leader left, promote next member or disband
	if party.Leader.UserId == player.UserId then
		if #party.Members > 0 then
			party.Leader = party.Members[1]
			print(string.format("[PartyManager] %s is now party leader", party.Leader.Name))
		else
			-- Party is empty, disband it
			self:DisbandParty(partyID)
		end
	end

	return true
end

function PartyManager:KickPlayer(leader, targetPlayer)
	if not leader or not targetPlayer then return false end

	local partyID = PlayerParties[leader.UserId]
	if not partyID then
		warn("[PartyManager] Leader not in a party")
		return false
	end

	local party = Parties[partyID]
	if not party or party.Leader.UserId ~= leader.UserId then
		warn("[PartyManager] Only party leader can kick")
		return false
	end

	-- Cannot kick yourself
	if leader.UserId == targetPlayer.UserId then
		warn("[PartyManager] Use LeaveParty to leave")
		return false
	end

	-- Check if target is in the party
	if PlayerParties[targetPlayer.UserId] ~= partyID then
		warn("[PartyManager] Target not in this party")
		return false
	end

	-- Remove target
	self:LeaveParty(targetPlayer)

	print(string.format("[PartyManager] %s kicked %s from party", leader.Name, targetPlayer.Name))

	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- QUERIES
-- ════════════════════════════════════════════════════════════════════════════

function PartyManager:GetParty(player)
	if not player then return nil end

	local partyID = PlayerParties[player.UserId]
	if not partyID then return nil end

	return Parties[partyID]
end

function PartyManager:GetPartyMembers(player)
	local party = self:GetParty(player)
	if not party then return {} end

	return party.Members
end

function PartyManager:IsInParty(player)
	if not player then return false end
	return isInParty(player)
end

function PartyManager:IsPartyLeader(player)
	if not player then return false end

	local party = self:GetParty(player)
	if not party then return false end

	return party.Leader.UserId == player.UserId
end

function PartyManager:GetPartySize(player)
	local party = self:GetParty(player)
	if not party then return 0 end

	return #party.Members
end

function PartyManager:GetPartyID(player)
	if not player then return nil end
	return PlayerParties[player.UserId]
end

-- ════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════════════════════════════

-- Handle player leaving game
local function onPlayerRemoving(player)
	if isInParty(player) then
		PartyManager:LeaveParty(player)
	end

	-- Clear any pending invites
	if PendingInvites[player.UserId] then
		PendingInvites[player.UserId] = nil
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════════════════════════

function PartyManager:Initialize()
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	print("[PartyManager] Initialized")
end

return PartyManager
