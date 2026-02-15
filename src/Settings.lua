-- Khalnar's Nightmare Tracker
-- Settings panel integration
-- Module initialization
KNC.Settings = KNC.Settings or {}
function KNC.Settings.Initialize()
    -- Register settings with LibAddonMenu
    if LibAddonMenu2 then
        local optionsData = {
            {
                type = "checkbox",
                name = "Enable Addon",
                tooltip = "Enable or disable the addon",
                getFunc = function() return KNC.variables.enabled end,
                setFunc = function(value) KNC.variables.enabled = value end,
                default = true,
            },
            {
                type = "checkbox",
                name = "Always Show Display",
                tooltip = "Always show the display even when no stacks",
                getFunc = function() return KNC.variables.alwaysShow end,
                setFunc = function(value) KNC.variables.alwaysShow = value end,
                default = false,
            },
            {
                type = "checkbox",
                name = "Unlock Position",
                tooltip = "Allow dragging the display to a custom position",
                getFunc = function() return KNC.variables.unlocked end,
                setFunc = function(value)
                    KNC.variables.unlocked = value
                    KNC.container:SetMovable(not value)
                    KNC.container:SetMouseEnabled(not value)
                end,
                default = false,
            },
            {
                type = "button",
                name = "Reset Position",
                func = function()
                    KNC.variables.positionLeft = GuiRoot:GetWidth() / 2
                    KNC.variables.positionTop = GuiRoot:GetHeight() / 2 + 200
                    KNC.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, KNC.variables.positionLeft, KNC.variables.positionTop)
                end,
            },
            {
                type = "slider",
                name = "Display Size",
                min = 32,
                max = 128,
                step = 8,
                getFunc = function() return KNC.variables.size end,
                setFunc = function(value)
                    KNC.variables.size = value
                    KNC.container:SetDimensions(value, value)
                    KNC.texture:SetDimensions(value, value)
                end,
                default = 64,
            },
            {
                type = "checkbox",
                name = "Debug Mode",
                tooltip = "Enable debug logging",
                getFunc = function() return KNC.variables.debugMode end,
                setFunc = function(value) KNC.variables.debugMode = value end,
                default = false,
            },
            {
                type = "description",
                text = "Tracks bone stacks for Khalnar's Nightmare monster set.\nAfter 5 light attacks, the set will proc with bonus effects.",
            }
        }

        LibAddonMenu2:RegisterOptionControls("KNC_Settings", optionsData)
    end
end