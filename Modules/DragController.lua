--[[
════════════════════════════════════════════════════════════════════════════════
Module: DragController
Location: StarterPlayer/StarterPlayerScripts/
Description: Handles drag-and-drop operations for inventory items.
             Provides visual feedback and drop zone detection.

Version: 1.0 - Gothic FPS Roguelite
Last Updated: 2025-11-22
════════════════════════════════════════════════════════════════════════════════
--]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DragController = {}

-- Drag state
local isDragging = false
local draggedItem = nil
local draggedFrame = nil
local ghostFrame = nil
local dragStartPos = nil

-- ════════════════════════════════════════════════════════════════════════════
-- CREATE GHOST FRAME (VISUAL FEEDBACK)
-- ════════════════════════════════════════════════════════════════════════════

local function createGhostFrame(originalFrame)
	local ghost = originalFrame:Clone()
	ghost.Name = "DragGhost"
	ghost.ZIndex = 1000
	ghost.Position = UDim2.new(0, 0, 0, 0)
	ghost.AnchorPoint = Vector2.new(0.5, 0.5)
	ghost.BackgroundTransparency = 0.5

	-- Make all descendants semi-transparent
	for _, child in ipairs(ghost:GetDescendants()) do
		if child:IsA("GuiObject") then
			if child.BackgroundTransparency < 1 then
				child.BackgroundTransparency = math.min(1, child.BackgroundTransparency + 0.3)
			end
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = 0.3
			end
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				child.ImageTransparency = 0.3
			end
		end
	end

	-- Add glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(255, 215, 0)
	glow.Thickness = 3
	glow.Transparency = 0.3
	glow.Parent = ghost

	return ghost
end

-- ════════════════════════════════════════════════════════════════════════════
-- DROP ZONE DETECTION
-- ════════════════════════════════════════════════════════════════════════════

local function isMouseOverFrame(frame, mousePos)
	if not frame or not frame.Parent then return false end

	local absPos = frame.AbsolutePosition
	local absSize = frame.AbsoluteSize

	return mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X and
	       mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y
end

local function findDropTarget(mousePos, draggedItemData)
	-- Check if hovering over valid drop zones
	local backpackUI = playerGui:FindFirstChild("BackpackUI")
	if not backpackUI or not backpackUI.Overlay.Visible then return nil end

	local mainFrame = backpackUI.Overlay.MainFrame

	-- Get source type
	local sourceType = draggedItemData.sourceType -- "inventory" or "backpack"
	local itemType = draggedItemData.itemType -- "weapon" or "shield"

	if sourceType == "inventory" then
		-- Dragging from Inventory → can drop to Backpack storage
		if itemType == "weapon" then
			local weaponsScroll = mainFrame:FindFirstChild("WeaponsScroll")
			if weaponsScroll and isMouseOverFrame(weaponsScroll, mousePos) then
				return {
					zone = "backpack_weapons",
					action = "stash"
				}
			end
		elseif itemType == "shield" then
			local shieldsScroll = mainFrame:FindFirstChild("ShieldsScroll")
			if shieldsScroll and isMouseOverFrame(shieldsScroll, mousePos) then
				return {
					zone = "backpack_shields",
					action = "stash"
				}
			end
		end
	elseif sourceType == "backpack" then
		-- Dragging from Backpack → can drop to Inventory slots
		if itemType == "weapon" then
			local invWeaponsContainer = mainFrame:FindFirstChild("InvWeaponsContainer")
			if invWeaponsContainer and isMouseOverFrame(invWeaponsContainer, mousePos) then
				-- Find which slot (1-4) we're hovering over
				for _, child in ipairs(invWeaponsContainer:GetChildren()) do
					if child:IsA("Frame") and isMouseOverFrame(child, mousePos) then
						local slotNum = child.LayoutOrder
						if slotNum and slotNum >= 1 and slotNum <= 4 then
							return {
								zone = "inventory_weapons",
								action = "equip",
								slot = slotNum
							}
						end
					end
				end
				-- Default to first empty slot or current slot
				return {
					zone = "inventory_weapons",
					action = "equip",
					slot = nil -- Server will determine
				}
			end
		elseif itemType == "shield" then
			local invShieldContainer = mainFrame:FindFirstChild("InvShieldContainer")
			if invShieldContainer and isMouseOverFrame(invShieldContainer, mousePos) then
				return {
					zone = "inventory_shield",
					action = "equip"
				}
			end
		end
	end

	return nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- START DRAG
-- ════════════════════════════════════════════════════════════════════════════

function DragController.StartDrag(frame, itemData)
	if isDragging then return false end

	isDragging = true
	draggedItem = itemData
	draggedFrame = frame
	dragStartPos = frame.Position

	-- Create ghost frame
	ghostFrame = createGhostFrame(frame)
	ghostFrame.Parent = playerGui

	-- Hide original frame slightly
	frame.BackgroundTransparency = 0.7

	print("[DragController] Started dragging:", itemData.itemType, itemData.sourceType)
	return true
end

-- ════════════════════════════════════════════════════════════════════════════
-- UPDATE DRAG (FOLLOW MOUSE)
-- ════════════════════════════════════════════════════════════════════════════

function DragController.UpdateDrag(mousePos)
	if not isDragging or not ghostFrame then return end

	-- Move ghost to follow mouse
	ghostFrame.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)

	-- Check if over valid drop zone and highlight
	local dropTarget = findDropTarget(mousePos, draggedItem)

	if dropTarget then
		-- Change ghost color to indicate valid drop
		local stroke = ghostFrame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(50, 255, 50) -- Green
		end
	else
		-- Red for invalid drop
		local stroke = ghostFrame:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(255, 50, 50) -- Red
		end
	end
end

-- ════════════════════════════════════════════════════════════════════════════
-- END DRAG (DROP)
-- ════════════════════════════════════════════════════════════════════════════

function DragController.EndDrag(mousePos, onDropCallback)
	if not isDragging then return end

	local dropTarget = findDropTarget(mousePos, draggedItem)

	-- Restore original frame
	if draggedFrame then
		draggedFrame.BackgroundTransparency = 0
	end

	-- Clean up ghost
	if ghostFrame then
		ghostFrame:Destroy()
		ghostFrame = nil
	end

	-- Execute drop action
	if dropTarget and onDropCallback then
		print("[DragController] Valid drop detected:", dropTarget.zone, dropTarget.action)
		onDropCallback(draggedItem, dropTarget)
	else
		print("[DragController] Invalid drop - returning to origin")
	end

	-- Reset state
	isDragging = false
	draggedItem = nil
	draggedFrame = nil
	dragStartPos = nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- CANCEL DRAG (ESC or invalid operation)
-- ════════════════════════════════════════════════════════════════════════════

function DragController.CancelDrag()
	if not isDragging then return end

	-- Restore original frame
	if draggedFrame then
		draggedFrame.BackgroundTransparency = 0
	end

	-- Clean up ghost
	if ghostFrame then
		ghostFrame:Destroy()
		ghostFrame = nil
	end

	isDragging = false
	draggedItem = nil
	draggedFrame = nil
	dragStartPos = nil

	print("[DragController] Drag cancelled")
end

-- ════════════════════════════════════════════════════════════════════════════
-- GETTERS
-- ════════════════════════════════════════════════════════════════════════════

function DragController.IsDragging()
	return isDragging
end

function DragController.GetDraggedItem()
	return draggedItem
end

return DragController
