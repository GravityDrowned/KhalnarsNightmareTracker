--[[
    Khalnar's Nightmare Tracker
    Main.lua - Entry point and initialization
    
    This is the main entry point for the addon. It handles:
    - Global namespace creation (KNC)
    - SavedVariables initialization
    - Module initialization orchestration
    - Slash command registration and handling
    
    Load Order: This file must be loaded FIRST in the manifest.
]]

--------------------------------------------------------------------------------
-- ADDON METADATA
--------------------------------------------------------------------------------

local ADDON_NAME = "KhalnarsNightmareTracker"
local ADDON_VERSION = "1.0.0"
local SAVED_VARS_VERSION = 1

--------------------------------------------------------------------------------
-- GLOBAL NAMESPACE
--------------------------------------------------------------------------------

--- Global addon table - all modules and state hang off this table
-- @table KNC
-- @field variables SavedVariables configuration
-- @field Tracking Tracking module (combat events, stack logic)
-- @field Interface Interface module (UI rendering)
-- @field Settings Settings module (LibAddonMenu integration)
KNC = {}

--------------------------------------------------------------------------------
-- DEFAULT CONFIGURATION
--------------------------------------------------------------------------------

--- Default values for SavedVariables
-- These are used when the user has no saved settings
local defaults = {
    enabled = true,           -- Master enable/disable toggle
    alwaysShow = false,       -- Show display even at 0 stacks
    unlocked = false,         -- Allow dragging to reposition
    size = 64,                -- Display size in pixels (32-128)
    positionLeft = GuiRoot:GetWidth() / 2,   -- X position from left
    positionTop = GuiRoot:GetHeight() / 2 + 200,  -- Y position from top
    debugMode = false,        -- Enable verbose logging
}

--------------------------------------------------------------------------------
-- SAVED VARIABLES INITIALIZATION
--------------------------------------------------------------------------------

--- Account-wide saved variables
-- Persists settings across all characters on the account
-- @field enabled boolean Master toggle
-- @field alwaysShow boolean Show at 0 stacks
-- @field unlocked boolean Position unlocked for dragging
-- @field size number Display size in pixels
-- @field positionLeft number X position
-- @field positionTop number Y position
-- @field debugMode boolean Debug logging enabled
KNC.variables = ZO_SavedVars:NewAccountWide(
    "KhalnarsNightmareVariables",  -- SavedVariables name (matches manifest)
    SAVED_VARS_VERSION,             -- Version for migration
    nil,                            -- Profile name (nil = default)
    defaults                        -- Default values
)

--------------------------------------------------------------------------------
-- ADDON INITIALIZATION
--------------------------------------------------------------------------------

--- Internal event handler for addon loading
-- Called by ESO when any addon finishes loading. We filter for our addon
-- and then initialize all modules in the correct order.
-- @param eventCode number The event code (EVENT_ADD_ON_LOADED)
-- @param addOnName string The name of the addon that just loaded
-- @local
local function OnAddOnLoaded(eventCode, addOnName)
    -- Only process our own addon
    if addOnName ~= ADDON_NAME then 
        return 
    end
    
    -- Initialize modules in dependency order:
    -- 1. Tracking - sets up state and event handlers
    -- 2. Interface - creates UI elements (depends on tracking state)
    -- 3. Settings - registers LAM panel (depends on both)
    KNC.Tracking.Initialize()
    KNC.Interface.Initialize()
    KNC.Settings.Initialize()
    
    -- Register the slash command for user interaction
    SLASH_COMMANDS["/knc"] = KNC.SlashCommand
    
    -- Unregister this handler to prevent being called again
    -- (EVENT_ADD_ON_LOADED fires for every addon)
    EVENT_MANAGER:UnregisterForEvent("KNC_AddOnLoaded", EVENT_ADD_ON_LOADED)
    
    -- Startup message (only in debug mode)
    if KNC.variables.debugMode then
        d("[KNC] Khalnar's Nightmare Tracker v" .. ADDON_VERSION .. " loaded")
    end
end

--------------------------------------------------------------------------------
-- SLASH COMMAND HANDLER
--------------------------------------------------------------------------------

--- Handles all /knc slash commands
-- Parses the input string and executes the appropriate action.
-- 
-- Commands:
--   /knc          - Show addon status
--   /knc toggle   - Enable/disable addon
--   /knc reset    - Reset stack count to 0
--   /knc debug    - Toggle debug logging
--
-- @param input string The text after "/knc " (may be empty)
function KNC.SlashCommand(input)
    -- Parse input into space-separated arguments
    local args = {}
    for arg in string.gmatch(input, "%S+") do
        table.insert(args, arg)
    end
    
    -- No arguments: show status
    if #args == 0 then
        d("Khalnar's Nightmare Tracker - Status: " .. tostring(KNC.variables.enabled))
        d("  Current Stacks: " .. tostring(KNC.currentStacks or 0))
        d("  Debug Mode: " .. tostring(KNC.variables.debugMode))
        return
    end
    
    -- Process command (case-insensitive)
    local cmd = string.lower(args[1])
    
    if cmd == "reset" then
        -- Reset stack count
        KNC.Tracking.ResetStacks()
        d("Khalnar's Nightmare Tracker - Stacks reset")
        
    elseif cmd == "toggle" then
        -- Toggle enabled state
        KNC.variables.enabled = not KNC.variables.enabled
        KNC.Interface.UpdateUI()  -- Immediately reflect change
        d("Khalnar's Nightmare Tracker - Enabled: " .. tostring(KNC.variables.enabled))
        
    elseif cmd == "debug" then
        -- Toggle debug mode
        KNC.variables.debugMode = not KNC.variables.debugMode
        d("Khalnar's Nightmare Tracker - Debug Mode: " .. tostring(KNC.variables.debugMode))
        
    else
        -- Unknown command: show help
        d("Khalnar's Nightmare Tracker - Usage:")
        d("  /knc - Show status")
        d("  /knc reset - Reset stacks")
        d("  /knc toggle - Toggle addon")
        d("  /knc debug - Toggle debug mode")
    end
end

--------------------------------------------------------------------------------
-- EVENT REGISTRATION
--------------------------------------------------------------------------------

-- Register for addon loaded event
-- This kicks off the entire initialization process when ESO loads our addon
EVENT_MANAGER:RegisterForEvent("KNC_AddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
