-- Khalnar's Nightmare Tracker
-- Entry point and initialization

-- Global table initialization
KNC = {}

-- Saved variables setup
KNC.variables = ZO_SavedVars:NewAccountWide("KhalnarsNightmareVariables", 1, nil, {
    enabled = true,
    alwaysShow = false,
    unlocked = false,
    size = 64,
    positionLeft = GuiRoot:GetWidth() / 2,
    positionTop = GuiRoot:GetHeight() / 2 + 200,
    debugMode = false,
})

-- Event handler for addon loading
local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName == "KhalnarsNightmareTracker" then
        -- Initialize tracking module
        KNC.Tracking.Initialize()
        
        -- Initialize interface module
        KNC.Interface.Initialize()
        
        -- Initialize settings module
        KNC.Settings.Initialize()
        
        -- Register slash command
        SLASH_COMMANDS["/knc"] = KNC.SlashCommand
        
        -- Unregister this handler to prevent multiple calls
        EVENT_MANAGER:UnregisterForEvent("KNC_AddOnLoaded", EVENT_ADD_ON_LOADED)
    end
end

-- Slash command handler
function KNC.SlashCommand(input)
    local args = {}
    for arg in string.gmatch(input, "%S+") do
        table.insert(args, arg)
    end
    
    if #args == 0 then
        d("Khalnar's Nightmare Tracker - Status: " .. tostring(KNC.variables.enabled))
        return
    end
    
    local cmd = string.lower(args[1])
    
    if cmd == "reset" then
        KNC.Tracking.ResetStacks()
        d("Khalnar's Nightmare Tracker - Stacks reset")
    elseif cmd == "toggle" then
        KNC.variables.enabled = not KNC.variables.enabled
        d("Khalnar's Nightmare Tracker - Enabled: " .. tostring(KNC.variables.enabled))
    elseif cmd == "debug" then
        KNC.variables.debugMode = not KNC.variables.debugMode
        d("Khalnar's Nightmare Tracker - Debug Mode: " .. tostring(KNC.variables.debugMode))
    else
        d("Khalnar's Nightmare Tracker - Usage:")
        d("/knc - Show status")
        d("/knc reset - Reset stacks")
        d("/knc toggle - Toggle addon")
        d("/knc debug - Toggle debug mode")
    end
end

-- Register event for addon loading
EVENT_MANAGER:RegisterForEvent("KNC_AddOnLoaded", EVENT_ADD_ON_LOADED, OnAddOnLoaded)
