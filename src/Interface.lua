-- Khalnar's Nightmare Tracker
-- UI rendering & display
-- Module initialization
KNC.Interface = KNC.Interface or {}
function KNC.Interface.Initialize()
    -- Create UI elements
    KNC.container = WINDOW_MANAGER:CreateTopLevelWindow("KNCContainer")
    KNC.container:SetDimensions(KNC.variables.size, KNC.variables.size)
    KNC.container:SetClampedToScreen(true)
    KNC.container:SetMovable(not KNC.variables.unlocked)
    KNC.container:SetMouseEnabled(not KNC.variables.unlocked)

    -- Create texture control for visual indicator
    KNC.texture = KNC.container:CreateControl("KNC_Texture", CT_TEXTURE)
    KNC.texture:SetAnchor(TOPLEFT, KNC.container, TOPLEFT, 0, 0)
    KNC.texture:SetDimensions(KNC.variables.size, KNC.variables.size)
    KNC.texture:SetTexture("KhalnarsNightmareTracker/textures/khalnar_icon.dds") -- Placeholder

    -- Create label for stack count
    KNC.label = KNC.container:CreateControl("KNC_Label", CT_LABEL)
    KNC.label:SetAnchor(CENTER, KNC.container, CENTER, 0, 0)
    KNC.label:SetFont("ZoFontWinH4")
    KNC.label:SetColor(1, 1, 1, 1)
    KNC.label:SetText("")

    -- Position container
    KNC.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, KNC.variables.positionLeft, KNC.variables.positionTop)

    -- Hide initially
    KNC.container:SetHidden(true)

    -- Register for move events if unlocked
    KNC.container:SetHandler("OnMoveStop", function() KNC.Interface.OnPositionChanged() end)
end
-- Update UI display based on current stacks
function KNC.Interface.UpdateUI()
    if not KNC.variables.enabled then
        KNC.container:SetHidden(true)
        return
    end

    -- Show only when stacks > 0 or alwaysShow is enabled
    if KNC.currentStacks > 0 or KNC.variables.alwaysShow then
        KNC.container:SetHidden(false)
        KNC.label:SetText(tostring(KNC.currentStacks))

        -- Update texture color based on stack level
        local r, g, b = 1, 1, 1
        if KNC.currentStacks >= 5 then
            -- Full stack - red color
            r, g, b = 1, 0, 0
        elseif KNC.currentStacks >= 3 then
            -- Medium stack - yellow color
            r, g, b = 1, 1, 0
        else
            -- Low stack - green color
            r, g, b = 0, 1, 0
        end

        KNC.texture:SetColor(r, g, b, 1)
    else
        KNC.container:SetHidden(true)
    end
end
-- Handle position changes
function KNC.Interface.OnPositionChanged(eventCode, window)
    if not KNC.variables.unlocked then return end

    local left, top = window:GetAnchor(TOPLEFT)
    KNC.variables.positionLeft = left
    KNC.variables.positionTop = top
end