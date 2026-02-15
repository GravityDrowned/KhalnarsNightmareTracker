-- Khalnar's Nightmare Tracker
-- Event handling & stack logic
-- Module initialization
KNC.Tracking = KNC.Tracking or {}
function KNC.Tracking.Initialize()
    -- Setup tracking variables
    KNC.currentTarget = nil
    KNC.currentStacks = 0
    KNC.enemyStacks = {}
    KNC.MAX_STACKS = 5
    KNC.KHALNAR_ABILITY_ID = 163598 -- Placeholder, needs actual ID

    -- Register event handlers
    EVENT_MANAGER:RegisterForEvent("KNC_CombatEvent", EVENT_COMBAT_EVENT, KNC.Tracking.OnCombatEvent)
    EVENT_MANAGER:RegisterForEvent("KNC_TargetChanged", EVENT_RETICLE_TARGET_CHANGED, KNC.Tracking.OnTargetChanged)
    EVENT_MANAGER:RegisterForEvent("KNC_EffectChanged", EVENT_EFFECT_CHANGED, KNC.Tracking.OnEffectChanged)

    -- Set up cleanup timer
    zo_callLater(function() KNC.Tracking.CleanupOldStacks() end, 30000)
end
-- Event handler for combat events
function KNC.Tracking.OnCombatEvent(eventCode, sourceUnitTag, sourceName, sourceDisplayName, targetUnitTag, targetName, targetDisplayName, abilityName, abilityId, actionSlotType, result, isError, hitValue, powerType, powerValue, damageType, damageOverTime, critical, glancing, crushing, missType, abilityActionSlotType, abilityId, sourceUnit, targetUnit)
    if not KNC.variables.enabled then return end

    -- Only process player actions
    if sourceUnitTag ~= "player" then return end

    -- Look for light attacks
    if KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId) then
        -- Check if we have a valid target
        local target = targetName or GetUnitName("reticleover")
        if not target then return end

        -- Increment stacks for the current target
        KNC.Tracking.IncrementStacks(target)
    end
end
-- Event handler for target changes
function KNC.Tracking.OnTargetChanged(eventCode)
    if not KNC.variables.enabled then return end

    -- Save the current target's stacks
    if KNC.currentTarget then
        KNC.enemyStacks[KNC.currentTarget] = {
            stacks = KNC.currentStacks,
            timestamp = GetGameTimeMilliseconds()
        }
    end

    -- Load new target's stacks or reset to zero
    local newTarget = GetUnitName("reticleover")
    if newTarget then
        KNC.currentTarget = newTarget
        if KNC.enemyStacks[newTarget] then
            KNC.currentStacks = KNC.enemyStacks[newTarget].stacks
        else
            KNC.currentStacks = 0
        end
    else
        KNC.currentTarget = nil
        KNC.currentStacks = 0
    end

    -- Update UI
    KNC.Interface.UpdateUI()
end
-- Event handler for effect changes (for debuff tracking)
function KNC.Tracking.OnEffectChanged(eventCode, unitTag, effectName, effectId, result, stackCount)
    if not KNC.variables.enabled then return end

    -- Only process our specific debuff
    if effectId == KNC.KHALNAR_ABILITY_ID then
        if result == EFFECT_RESULT_GAINED or result == EFFECT_RESULT_UPDATED then
            -- Sync with game effects
            KNC.currentStacks = stackCount
            KNC.Interface.UpdateUI()
        elseif result == EFFECT_RESULT_FADED then
            -- Reset stacks when debuff fades
            KNC.currentStacks = 0
            KNC.Interface.UpdateUI()
        end
    end
end
-- Increment stacks for current target
function KNC.Tracking.IncrementStacks(targetName)
    if KNC.currentStacks < KNC.MAX_STACKS then
        KNC.currentStacks = KNC.currentStacks + 1

        if KNC.variables.debugMode then
            d("Khalnar's Nightmare - Stacks incremented for " .. targetName .. ": " .. KNC.currentStacks .. "/" .. KNC.MAX_STACKS)
        end

        -- Trigger proc when 5 stacks reached
        if KNC.currentStacks >= KNC.MAX_STACKS then
            KNC.Tracking.ProcSet()
        end

        -- Update UI
        KNC.Interface.UpdateUI()
    end
end
-- Handle set proc
function KNC.Tracking.ProcSet()
    if KNC.variables.debugMode then
        d("Khalnar's Nightmare - Set procced!")
    end

    -- Optionally trigger any effect here when set procs
end
-- Reset stacks for current target
function KNC.Tracking.ResetStacks()
    KNC.currentStacks = 0
    KNC.Interface.UpdateUI()

    if KNC.variables.debugMode then
        d("Khalnar's Nightmare - Stacks reset")
    end
end
-- Check if combat event represents a light attack
function KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId)
    -- Method 1: Check action slot type
    if abilityActionSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK then
        return true
    end

    -- Method 2: Check for no ability (abilityId == 0)
    -- and basic damage result
    if (not abilityId or abilityId == 0) and
       (result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE) then
        return true
    end

    return false
end
-- Cleanup old enemy stack data
function KNC.Tracking.CleanupOldStacks()
    local currentTime = GetGameTimeMilliseconds()
    local cutoffTime = currentTime - 300000 -- 5 minutes ago

    for enemyName, data in pairs(KNC.enemyStacks) do
        if data.timestamp < cutoffTime then
            KNC.enemyStacks[enemyName] = nil
        end
    end

    -- Restart timer
    zo_callLater(function() KNC.Tracking.CleanupOldStacks() end, 30000)
end