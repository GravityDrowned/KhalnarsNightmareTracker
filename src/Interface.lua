--[[
    Khalnar's Nightmare Tracker
    Interface.lua - UI rendering and display
    
    This module is responsible for:
    - Creating and configuring UI elements
    - Updating the display based on current state
    - Handling user positioning (drag and drop)
    - Managing visibility based on settings and state
    
    UI Structure:
    - KNCContainer (TopLevelWindow): Main container, movable
      - KNC_Texture (CT_TEXTURE): Icon background, color-coded
      - KNC_Label (CT_LABEL): Stack count text overlay
]]

--------------------------------------------------------------------------------
-- MODULE INITIALIZATION
--------------------------------------------------------------------------------

--- Interface module namespace
-- @table KNC.Interface
KNC.Interface = KNC.Interface or {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

--- Texture path for the display icon
-- NOTE: This is a placeholder. The actual texture needs to be created.
local TEXTURE_PATH = "KhalnarsNightmareTracker/textures/khalnar_icon.dds"

--- Fallback texture if custom texture is missing
local FALLBACK_TEXTURE = "/esoui/art/icons/ability_debuff_major_defile.dds"

--- Font for the stack count label
local STACK_FONT = "ZoFontWinH4"

--- Color definitions for different stack levels
-- Each entry is {red, green, blue, alpha}
local COLORS = {
    LOW = {0, 1, 0, 1},      -- Green: 1-2 stacks (building)
    MEDIUM = {1, 1, 0, 1},   -- Yellow: 3-4 stacks (almost ready)
    HIGH = {1, 0, 0, 1},     -- Red: 5 stacks (procced!)
    DEFAULT = {1, 1, 1, 1},  -- White: default/text color
}

--------------------------------------------------------------------------------
-- UI ELEMENT REFERENCES
--------------------------------------------------------------------------------

-- These are stored on the KNC global for access by other modules:
--
-- KNC.container - TopLevelWindow: Main container
-- KNC.texture   - CT_TEXTURE: Icon texture
-- KNC.label     - CT_LABEL: Stack count text

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

--- Initializes the interface module
-- Creates all UI elements and configures their initial state.
-- Called once during addon initialization from Main.lua.
function KNC.Interface.Initialize()
    -- Create the main container window
    KNC.container = WINDOW_MANAGER:CreateTopLevelWindow("KNCContainer")
    
    -- Configure container properties
    KNC.container:SetDimensions(KNC.variables.size, KNC.variables.size)
    KNC.container:SetClampedToScreen(true)  -- Prevent dragging off-screen
    KNC.container:SetMouseEnabled(not KNC.variables.unlocked)  -- Enable drag when unlocked
    KNC.container:SetMovable(not KNC.variables.unlocked)       -- Note: logic is inverted in settings
    
    -- Create the icon texture
    -- This provides visual feedback and color-coding
    KNC.texture = WINDOW_MANAGER:CreateControl("KNC_Texture", KNC.container, CT_TEXTURE)
    KNC.texture:SetAnchor(TOPLEFT, KNC.container, TOPLEFT, 0, 0)
    KNC.texture:SetDimensions(KNC.variables.size, KNC.variables.size)
    
    -- Try to set custom texture, fall back if missing
    -- Note: SetTexture will silently fail if file doesn't exist
    KNC.texture:SetTexture(TEXTURE_PATH)
    
    -- Create the stack count label
    -- This overlays the texture to show the numeric count
    KNC.label = WINDOW_MANAGER:CreateControl("KNC_Label", KNC.container, CT_LABEL)
    KNC.label:SetAnchor(CENTER, KNC.container, CENTER, 0, 0)
    KNC.label:SetFont(STACK_FONT)
    KNC.label:SetColor(unpack(COLORS.DEFAULT))
    KNC.label:SetText("")
    
    -- Ensure label is above texture
    KNC.label:SetDrawLevel(2)
    KNC.texture:SetDrawLevel(1)

    -- Position the container based on saved settings
    KNC.container:ClearAnchors()
    KNC.container:SetAnchor(
        TOPLEFT, 
        GuiRoot, 
        TOPLEFT, 
        KNC.variables.positionLeft, 
        KNC.variables.positionTop
    )

    -- Hide initially - UpdateUI will show when appropriate
    KNC.container:SetHidden(true)

    -- Register handler for position changes (drag and drop)
    KNC.container:SetHandler("OnMoveStop", function()
        KNC.Interface.OnPositionChanged()
    end)
    
    if KNC.variables.debugMode then
        d("[KNC] Interface module initialized")
    end
end

--------------------------------------------------------------------------------
-- DISPLAY UPDATE
--------------------------------------------------------------------------------

--- Updates the UI display based on current state
-- This is the main update function, called whenever state changes:
-- - Stack count changes
-- - Target changes
-- - Settings changes (enabled, alwaysShow)
--
-- Determines visibility and applies color-coding based on stack level.
function KNC.Interface.UpdateUI()
    -- Safety check: ensure UI elements exist
    if not KNC.container then 
        return 
    end
    
    -- If addon is disabled, hide everything
    if not KNC.variables.enabled then
        KNC.container:SetHidden(true)
        return
    end

    -- Determine visibility:
    -- Show if we have stacks OR if alwaysShow is enabled
    local shouldShow = KNC.currentStacks > 0 or KNC.variables.alwaysShow
    
    if shouldShow then
        -- Show the display
        KNC.container:SetHidden(false)
        
        -- Update the label text
        KNC.label:SetText(tostring(KNC.currentStacks))
        
        -- Determine color based on stack count
        local color = KNC.Interface.GetColorForStacks(KNC.currentStacks)
        KNC.texture:SetColor(unpack(color))
        
    else
        -- Hide the display
        KNC.container:SetHidden(true)
    end
end

--- Gets the appropriate color for a given stack count
-- Color coding provides at-a-glance status:
-- - Green (1-2): Building stacks
-- - Yellow (3-4): Almost at proc
-- - Red (5): Set procced!
--
-- @param stacks number Current stack count (0-5)
-- @return table Color as {r, g, b, a}
function KNC.Interface.GetColorForStacks(stacks)
    if stacks >= 5 then
        -- Full stacks - proc imminent/happened
        return COLORS.HIGH
    elseif stacks >= 3 then
        -- Medium stacks - getting close
        return COLORS.MEDIUM
    elseif stacks >= 1 then
        -- Low stacks - just starting
        return COLORS.LOW
    else
        -- Zero stacks - use default
        return COLORS.DEFAULT
    end
end

--------------------------------------------------------------------------------
-- POSITION HANDLING
--------------------------------------------------------------------------------

--- Handles position changes when user drags the display
-- Saves the new position to SavedVariables for persistence.
function KNC.Interface.OnPositionChanged()
    -- Only save if position unlocked (user can drag)
    if KNC.variables.unlocked then
        return  -- Note: This check seems inverted, see notes below
    end
    
    -- Get current position
    local _, _, _, _, offsetX, offsetY = KNC.container:GetAnchor(0)
    
    -- Fallback: get position directly if anchor method fails
    if not offsetX or not offsetY then
        offsetX = KNC.container:GetLeft()
        offsetY = KNC.container:GetTop()
    end
    
    -- Save to SavedVariables
    if offsetX and offsetY then
        KNC.variables.positionLeft = offsetX
        KNC.variables.positionTop = offsetY
        
        if KNC.variables.debugMode then
            d("[KNC] Position saved: " .. offsetX .. ", " .. offsetY)
        end
    end
end

--------------------------------------------------------------------------------
-- PUBLIC UTILITY FUNCTIONS
--------------------------------------------------------------------------------

--- Resets the display position to default (center-bottom of screen)
-- Called from settings panel "Reset Position" button.
function KNC.Interface.ResetPosition()
    -- Calculate default position
    local defaultLeft = GuiRoot:GetWidth() / 2
    local defaultTop = GuiRoot:GetHeight() / 2 + 200
    
    -- Update SavedVariables
    KNC.variables.positionLeft = defaultLeft
    KNC.variables.positionTop = defaultTop
    
    -- Update display position
    KNC.container:ClearAnchors()
    KNC.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, defaultLeft, defaultTop)
    
    if KNC.variables.debugMode then
        d("[KNC] Position reset to default")
    end
end

--- Updates the display size
-- Called when size setting changes.
--
-- @param newSize number New size in pixels (32-128)
function KNC.Interface.SetSize(newSize)
    -- Validate size
    newSize = math.max(32, math.min(128, newSize))
    
    -- Update SavedVariables
    KNC.variables.size = newSize
    
    -- Resize container and texture
    KNC.container:SetDimensions(newSize, newSize)
    KNC.texture:SetDimensions(newSize, newSize)
    
    if KNC.variables.debugMode then
        d("[KNC] Size set to " .. newSize)
    end
end

--- Sets whether the display position is locked
-- When unlocked, user can drag the display.
--
-- @param locked boolean True to lock position, false to allow dragging
function KNC.Interface.SetPositionLocked(locked)
    KNC.container:SetMovable(not locked)
    KNC.container:SetMouseEnabled(not locked)
    KNC.variables.unlocked = not locked
    
    if KNC.variables.debugMode then
        d("[KNC] Position " .. (locked and "locked" or "unlocked"))
    end
end
