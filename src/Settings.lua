-- Khalnar's Nightmare Tracker
-- Settings panel integration
-- Module initialization
function KNC.Settings.Initialize()
    -- Register settings with LibAddonMenu
    if LibAddonMenu2 then
        local panel = LibAddonMenu2:RegisterAddonPanel("KNC_Settings", "Khalnar's Nightmare Tracker")

        -- Register options
        LibAddonMenu2:RegisterOption(panel, {
            type = "checkbox",
            name = "Enable Addon",
            getFunc = function() return KNC.variables.enabled end,
            setFunc = function(value) KNC.variables.enabled = value end,
            default = true,
        })

        LibAddonMenu2:RegisterOption(panel, {
            type = "checkbox",
            name = "Always Show Display",
            getFunc = function() return KNC.variables.alwaysShow end,
            setFunc = function(value) KNC.variables.alwaysShow = value end,
            default = false,
        })

        LibAddonMenu2:RegisterOption(panel, {
            type = "checkbox",
            name = "Unlock Position",
            getFunc = function() return KNC.variables.unlocked end,
            setFunc = function(value)
                KNC.variables.unlocked = value
                KNC.container:SetMovable(not value)
                KNC.container:SetMouseEnabled(not value)
            end,
            default = false,
        })

        LibAddonMenu2:RegisterOption(panel, {
            type = "button",
            name = "Reset Position",
            func = function()
                KNC.variables.positionLeft = GuiRoot:GetWidth() / 2
                KNC.variables.positionTop = GuiRoot:GetHeight() / 2 + 200
                KNC.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, KNC.variables.positionLeft, KNC.variables.positionTop)
            end,
        })

        LibAddonMenu2:RegisterOption(panel, {
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
        })

        LibAddonMenu2:RegisterOption(panel, {
            type = "checkbox",
            name = "Debug Mode",
            getFunc = function() return KNC.variables.debugMode end,
            setFunc = function(value) KNC.variables.debugMode = value end,
            default = false,
        })

        LibAddonMenu2:RegisterOption(panel, {
            type = "description",
            text = "Tracks bone stacks for Khalnar's Nightmare monster set.\nAfter 5 light attacks, the set will proc with bonus effects.",
        })
    end
end