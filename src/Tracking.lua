--[[
    Khalnar's Nightmare Tracker
    Tracking.lua - Event handling and stack logic
    
    This module is responsible for:
    - Registering and handling ESO combat events
    - Detecting player light attacks
    - Managing per-enemy stack state
    - Tracking target changes
    - Synchronizing with the game's effect system
    - Cleaning up stale cached data
    
    The core mechanic: Khalnar's Nightmare applies a stacking debuff to enemies
    with each light attack. After 5 stacks, the set procs. This module reads
    the debuff stacks directly from targets and maintains state when switching.
]]

--------------------------------------------------------------------------------
-- MODULE INITIALIZATION
--------------------------------------------------------------------------------

--- Tracking module namespace
-- @table KNC.Tracking
KNC.Tracking = KNC.Tracking or {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

--- Maximum number of stacks before the set procs
local MAX_STACKS = 5

--- Ability ID for Khalnar's Nightmare debuff on enemies
-- Verified ID: 133505 (this is the debuff that stacks on targets, not the proc buff)
local KHALNAR_ABILITY_ID = 133505

--- How often to run garbage collection on stale enemy data (in milliseconds)
local CLEANUP_INTERVAL_MS = 30000  -- 30 seconds

--- How long to keep enemy stack data before considering it stale (in milliseconds)
local CACHE_EXPIRY_MS = 300000     -- 5 minutes

--- Last time we polled for debuff stacks (throttling mechanism)
local lastPollTime = 0

--- How often to poll for debuff updates (milliseconds)
local POLL_INTERVAL_MS = 100  -- Poll every 100ms

--- Cooldown state tracking
-- These track whether the set is on cooldown after proccing
local cooldownActive = false     -- Is the set currently on cooldown?
local cooldownEndTime = 0        -- Game time (ms) when cooldown ends

--- Cooldown duration constants
local COOLDOWN_DURATION_MS = 5000  -- 5 seconds total cooldown
local SKELETON_DELAY_MS = 1000     -- 1 second until skeleton spawns

--------------------------------------------------------------------------------
-- STATE VARIABLES
--------------------------------------------------------------------------------

-- These are initialized in Initialize() and stored on the KNC global table
-- for access by other modules:
--
-- KNC.currentTarget   - string|nil: Name of the current target
-- KNC.currentStacks   - number: Stack count for current target (0-5)
-- KNC.enemyStacks     - table: Cache of {enemyName -> {stacks, timestamp}}
-- KNC.MAX_STACKS      - number: Exposed constant for other modules
-- KNC.KHALNAR_ABILITY_ID - number: Exposed constant for other modules

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

--- Initializes the tracking module
-- Sets up state variables, registers event handlers, and starts the cleanup timer.
-- Called once during addon initialization from Main.lua.
function KNC.Tracking.Initialize()
    -- Initialize state variables on the global KNC table
    KNC.currentTarget = nil     -- No target initially
    KNC.currentStacks = 0       -- No stacks initially
    KNC.enemyStacks = {}        -- Empty cache
    
    -- Expose constants for other modules
    KNC.MAX_STACKS = MAX_STACKS
    KNC.KHALNAR_ABILITY_ID = KHALNAR_ABILITY_ID
    
    -- Expose cooldown constants for Interface module
    KNC.COOLDOWN_DURATION_MS = COOLDOWN_DURATION_MS
    KNC.SKELETON_DELAY_MS = SKELETON_DELAY_MS

    -- Register event handlers
    -- Combat events: detect light attacks
    EVENT_MANAGER:RegisterForEvent(
        "KNC_CombatEvent", 
        EVENT_COMBAT_EVENT, 
        KNC.Tracking.OnCombatEvent
    )
    
    -- Target changes: save/load per-enemy stacks
    EVENT_MANAGER:RegisterForEvent(
        "KNC_TargetChanged", 
        EVENT_RETICLE_TARGET_CHANGED, 
        KNC.Tracking.OnTargetChanged
    )
    
    -- Effect changes: sync with game's effect system
    EVENT_MANAGER:RegisterForEvent(
        "KNC_EffectChanged", 
        EVENT_EFFECT_CHANGED, 
        KNC.Tracking.OnEffectChanged
    )

    -- Start periodic cleanup of stale enemy data
    zo_callLater(function() KNC.Tracking.CleanupOldStacks() end, CLEANUP_INTERVAL_MS)
    
    -- Register continuous polling for debuff stacks
    -- This runs every frame but is throttled internally to 100ms
    EVENT_MANAGER:RegisterForUpdate(
        "KNC_PollStacks",
        0,  -- Every frame (throttled internally)
        KNC.Tracking.PollTargetStacks
    )
    
    if KNC.variables.debugMode then
        d("[KNC] Tracking module initialized")
    end
end

--------------------------------------------------------------------------------
-- DEBUFF POLLING
--------------------------------------------------------------------------------

--- Scans the current target for existing Khalnar debuff stacks
-- Returns the current stack count from the game's effect system
-- @return number Stack count (0 if no debuff found)
function KNC.Tracking.GetTargetDebuffStacks()
    -- Scan all debuffs on the reticle target
    for i = 1, GetNumBuffs("reticleover") do
        local name, startTime, endTime, buffSlot, stackCount, iconFilename, 
              buffType, effectType, abilityType, statusEffectType, abilityId, 
              canClickOff, castByPlayer = GetUnitBuffInfo("reticleover", i)
        
        -- Found Khalnar's debuff cast by us
        if abilityId == KNC.KHALNAR_ABILITY_ID and castByPlayer then
            return stackCount or 0
        end
    end
    
    -- No debuff found
    return 0
end

--- Updates stack count by polling the target's debuffs
-- Called periodically to ensure we catch all changes, including when
-- the debuff is consumed at 5 stacks (proc).
-- Throttled to avoid performance impact.
function KNC.Tracking.PollTargetStacks()
    -- Throttle polling
    local currentTime = GetGameTimeMilliseconds()
    if currentTime - lastPollTime < POLL_INTERVAL_MS then
        return
    end
    lastPollTime = currentTime
    
    -- Check if cooldown just expired (will update cooldownActive internally)
    local cooldownBefore = cooldownActive
    local cooldownRemaining = KNC.Tracking.GetCooldownRemaining()
    
    -- If cooldown just ended, update UI
    if cooldownBefore and not cooldownActive then
        KNC.Interface.UpdateUI()
    end
    
    -- Handle no-target case
    if not KNC.currentTarget or KNC.currentTarget == "" then
        -- No target: ensure stacks are 0
        if KNC.currentStacks ~= 0 then
            KNC.currentStacks = 0
        end
        
        -- Always update UI to show cooldown even without a target
        -- This ensures the cooldown overlay remains visible when target dies
        KNC.Interface.UpdateUI()
        
        -- Skip debuff polling (no target to poll)
        return
    end
    
    -- Poll actual debuff stacks
    local actualStacks = KNC.Tracking.GetTargetDebuffStacks()
    
    -- Update if changed
    if actualStacks ~= KNC.currentStacks then
        local previousStacks = KNC.currentStacks
        KNC.currentStacks = actualStacks
        
        if KNC.variables.debugMode then
            d("[KNC] Poll update: " .. previousStacks .. " -> " .. actualStacks)
        end
        
        -- Detect proc (stacks consumed)
        if previousStacks >= KNC.MAX_STACKS and actualStacks == 0 then
            KNC.Tracking.OnProcTriggered()
        end
        
        KNC.Interface.UpdateUI()
    end
end

--- Gets the remaining cooldown time in milliseconds
-- Also updates cooldown state if it has expired
-- @return number Remaining cooldown in milliseconds (0 if not on cooldown)
function KNC.Tracking.GetCooldownRemaining()
    if not cooldownActive then
        return 0
    end
    
    local currentTime = GetGameTimeMilliseconds()
    local remaining = cooldownEndTime - currentTime
    
    if remaining <= 0 then
        -- Cooldown expired
        cooldownActive = false
        cooldownEndTime = 0
        
        if KNC.variables.debugMode then
            d("[KNC] Cooldown ended - ready to proc again!")
        end
        
        return 0
    end
    
    return remaining
end

--- Checks if the set is currently on cooldown
-- @return boolean True if on cooldown, false otherwise
function KNC.Tracking.IsOnCooldown()
    KNC.Tracking.GetCooldownRemaining()  -- Updates state if expired
    return cooldownActive
end

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

--- Handles combat events to detect light attacks
-- This is the primary tracking mechanism. We filter for player light attacks
-- and increment the stack count for the target.
--
-- @param eventCode number Event identifier
-- @param sourceUnitTag string "player", "group1", etc.
-- @param sourceName string Localized source name
-- @param sourceDisplayName string Source @name
-- @param targetUnitTag string Target unit tag
-- @param targetName string Localized target name
-- @param targetDisplayName string Target @name
-- @param abilityName string Name of the ability
-- @param abilityId number Ability ID
-- @param actionSlotType number Action slot type
-- @param result number Action result code (damage, heal, etc.)
-- @param isError boolean Error flag
-- @param hitValue number Damage/heal value
-- @param powerType number Power type
-- @param powerValue number Power value
-- @param damageType number Damage type
-- @param damageOverTime boolean DoT flag
-- @param critical boolean Critical hit flag
-- @param glancing boolean Glancing blow flag
-- @param crushing boolean Crushing blow flag
-- @param missType number Miss type
-- @param abilityActionSlotType number Ability action slot type
-- @param abilityIdDuplicate number Duplicate ability ID (ESO API quirk)
-- @param sourceUnit number Source unit ID
-- @param targetUnit number Target unit ID
function KNC.Tracking.OnCombatEvent(eventCode, sourceUnitTag, sourceName, 
    sourceDisplayName, targetUnitTag, targetName, targetDisplayName, 
    abilityName, abilityId, actionSlotType, result, isError, hitValue, 
    powerType, powerValue, damageType, damageOverTime, critical, glancing, 
    crushing, missType, abilityActionSlotType, abilityIdDuplicate, 
    sourceUnit, targetUnit)
    
    -- Early exit: addon disabled
    if not KNC.variables.enabled then 
        return 
    end

    -- Only process player actions (not pets, companions, etc.)
    if sourceUnitTag ~= "player" then 
        return 
    end

    -- Check if this combat event represents a light attack
    if KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId) then
        -- Get the target name, fall back to reticle target if not in event
        local target = targetName or GetUnitName("reticleover")
        
        -- Must have a valid target to track
        if not target or target == "" then 
            return 
        end

        -- Update the current target if it changed
        if KNC.currentTarget ~= target then
            KNC.currentTarget = target
        end

        -- Poll the actual debuff stacks from the game immediately
        -- This ensures instant feedback after each light attack
        local actualStacks = KNC.Tracking.GetTargetDebuffStacks()
        
        if actualStacks ~= KNC.currentStacks then
            local previousStacks = KNC.currentStacks
            KNC.currentStacks = actualStacks
            
            if KNC.variables.debugMode then
                d("[KNC] Stacks: " .. previousStacks .. " -> " .. actualStacks .. " on " .. target)
            end
            
            -- Check if set procced (stacks consumed: was at max, now 0)
            if previousStacks >= KNC.MAX_STACKS and actualStacks == 0 then
                KNC.Tracking.OnProcTriggered()
            end
            
            KNC.Interface.UpdateUI()
        end
    end
end

--- Handles target changes to preserve per-enemy stack state
-- When the player switches targets, we save the current target's stacks
-- and load the new target's cached stacks (or reset to 0).
--
-- @param eventCode number Event identifier
function KNC.Tracking.OnTargetChanged(eventCode)
    -- Early exit: addon disabled
    if not KNC.variables.enabled then 
        return 
    end

    -- Save the current target's stacks to cache
    if KNC.currentTarget and KNC.currentTarget ~= "" then
        KNC.enemyStacks[KNC.currentTarget] = {
            stacks = KNC.currentStacks,
            timestamp = GetGameTimeMilliseconds()
        }
        
        if KNC.variables.debugMode then
            d("[KNC] Saved stacks for " .. KNC.currentTarget .. ": " .. KNC.currentStacks)
        end
    end

    -- Get the new target
    local newTarget = GetUnitName("reticleover")
    
    if newTarget and newTarget ~= "" then
        -- Have a new target: check for existing debuff stacks
        KNC.currentTarget = newTarget
        
        -- First check if there's an active debuff on the new target
        local debuffStacks = KNC.Tracking.GetTargetDebuffStacks()
        
        if debuffStacks > 0 then
            -- Target already has debuff stacks from us
            KNC.currentStacks = debuffStacks
            
            if KNC.variables.debugMode then
                d("[KNC] Target has existing debuff: " .. newTarget .. " (" .. debuffStacks .. " stacks)")
            end
        elseif KNC.enemyStacks[newTarget] then
            -- Fall back to cached stacks if no active debuff
            KNC.currentStacks = KNC.enemyStacks[newTarget].stacks
            
            if KNC.variables.debugMode then
                d("[KNC] Loaded cached stacks for " .. newTarget .. ": " .. KNC.currentStacks)
            end
        else
            -- New target with no history
            KNC.currentStacks = 0
            
            if KNC.variables.debugMode then
                d("[KNC] New target: " .. newTarget .. " (0 stacks)")
            end
        end
    else
        -- No target: clear current tracking (but cache is preserved)
        KNC.currentTarget = nil
        KNC.currentStacks = 0
    end

    -- Update the UI to reflect the new state
    KNC.Interface.UpdateUI()
end

--- Handles effect changes to sync with game's effect system
-- NOTE: This event does NOT reliably fire for enemy debuffs ("reticleover"),
-- only for player/group effects. Kept as fallback for edge cases.
-- Primary tracking is done via polling in PollTargetStacks.
--
-- @param eventCode number Event identifier
-- @param unitTag string Affected unit tag
-- @param effectName string Effect name
-- @param effectId number Effect ability ID
-- @param result number EFFECT_RESULT_* constant
-- @param stackCount number Current stack count from game
function KNC.Tracking.OnEffectChanged(eventCode, unitTag, effectName, effectId, result, stackCount)
    -- Early exit: addon disabled
    if not KNC.variables.enabled then 
        return 
    end

    -- Only track the debuff on our reticle target (enemy)
    if unitTag ~= "reticleover" then
        return
    end

    -- Only process the Khalnar's Nightmare debuff
    if effectId ~= KNC.KHALNAR_ABILITY_ID then 
        return 
    end
    
    if result == EFFECT_RESULT_GAINED or result == EFFECT_RESULT_UPDATED then
        -- Debuff gained or stacks updated: sync directly from game
        local previousStacks = KNC.currentStacks
        KNC.currentStacks = stackCount
        
        if KNC.variables.debugMode and previousStacks ~= stackCount then
            d("[KNC] Debuff stacks on target: " .. previousStacks .. " -> " .. stackCount)
        end
        
        KNC.Interface.UpdateUI()
        
    elseif result == EFFECT_RESULT_FADED then
        -- Debuff faded: reset stacks (target died or debuff expired)
        if KNC.variables.debugMode then
            d("[KNC] Debuff faded - stacks reset")
        end
        
        KNC.currentStacks = 0
        KNC.Interface.UpdateUI()
    end
end

--------------------------------------------------------------------------------
-- STACK MANAGEMENT
--------------------------------------------------------------------------------

--- Increments the stack count for the current target
-- DEPRECATED: Manual counting replaced by debuff polling.
-- Kept for reference but no longer called.
--
-- @param targetName string Name of the target being attacked
function KNC.Tracking.IncrementStacks(targetName)
    -- Don't exceed max stacks
    if KNC.currentStacks >= KNC.MAX_STACKS then 
        return 
    end
    
    -- Increment the counter
    KNC.currentStacks = KNC.currentStacks + 1

    if KNC.variables.debugMode then
        d("[KNC] Stacks: " .. KNC.currentStacks .. "/" .. KNC.MAX_STACKS .. " on " .. targetName)
    end

    -- Check for proc (5 stacks reached)
    if KNC.currentStacks >= KNC.MAX_STACKS then
        KNC.Tracking.OnProcTriggered()
    end

    -- Update the UI
    KNC.Interface.UpdateUI()
end

--- Called when the set procs (5 stacks reached)
-- Starts the cooldown timer and schedules skeleton spawn notification.
function KNC.Tracking.OnProcTriggered()
    if KNC.variables.debugMode then
        d("[KNC] *** SET PROCCED! ***")
    end
    
    -- Start cooldown timer
    cooldownActive = true
    cooldownEndTime = GetGameTimeMilliseconds() + COOLDOWN_DURATION_MS
    
    -- Schedule skeleton spawn notification (optional)
    zo_callLater(function()
        if KNC.variables.debugMode then
            d("[KNC] Skeleton spawning!")
        end
        -- Extension point: add skeleton spawn visual/sound effects
    end, SKELETON_DELAY_MS)
    
    -- Update UI to show cooldown overlay
    KNC.Interface.UpdateUI()
    
    -- Extension point: add proc effects here
    -- Examples:
    --   PlaySound(SOUNDS.ABILITY_ULTIMATE_READY)
    --   CreateProcAnimation()
    --   FireCustomEvent("KNC_SET_PROCCED")
end

--- Alias for backward compatibility
-- The original function name was ProcSet
KNC.Tracking.ProcSet = KNC.Tracking.OnProcTriggered

--- Resets the stack count to 0
-- Can be called via slash command or programmatically.
function KNC.Tracking.ResetStacks()
    local previousStacks = KNC.currentStacks
    KNC.currentStacks = 0
    
    if KNC.variables.debugMode then
        d("[KNC] Stacks reset: " .. previousStacks .. " -> 0")
    end
    
    -- Update UI to reflect reset
    KNC.Interface.UpdateUI()
end

--------------------------------------------------------------------------------
-- LIGHT ATTACK DETECTION
--------------------------------------------------------------------------------

--- Determines if a combat event represents a light attack
-- Uses multiple heuristics since ESO doesn't have a single definitive
-- way to identify light attacks.
--
-- Detection methods:
-- 1. Check if abilityActionSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK
-- 2. Check for abilityId == 0 with a damage result (basic attack pattern)
--
-- @param result number Combat action result code
-- @param abilityName string Name of the ability
-- @param abilityActionSlotType number Action slot type from event
-- @param abilityId number Ability ID from event
-- @return boolean True if this event represents a light attack
function KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId)
    -- Method 1: Explicit light attack slot type
    -- This is the most reliable method when available
    if abilityActionSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK then
        return true
    end

    -- Method 2: Basic attack pattern
    -- Light attacks often have abilityId == 0 or nil with a damage result
    -- This catches cases where the slot type isn't set
    local isDamageResult = (result == ACTION_RESULT_DAMAGE or 
                           result == ACTION_RESULT_CRITICAL_DAMAGE)
    
    if (not abilityId or abilityId == 0) and isDamageResult then
        return true
    end

    -- Not detected as a light attack
    return false
end

--------------------------------------------------------------------------------
-- CACHE MANAGEMENT
--------------------------------------------------------------------------------

--- Cleans up stale enemy stack data
-- Runs periodically to prevent memory growth from accumulated enemy data.
-- Removes entries that haven't been updated in CACHE_EXPIRY_MS milliseconds.
function KNC.Tracking.CleanupOldStacks()
    local currentTime = GetGameTimeMilliseconds()
    local cutoffTime = currentTime - CACHE_EXPIRY_MS
    local cleanedCount = 0

    -- Iterate through cache and remove old entries
    for enemyName, data in pairs(KNC.enemyStacks) do
        if data.timestamp < cutoffTime then
            KNC.enemyStacks[enemyName] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if KNC.variables.debugMode and cleanedCount > 0 then
        d("[KNC] Cleaned up " .. cleanedCount .. " stale cache entries")
    end

    -- Schedule next cleanup
    zo_callLater(function() KNC.Tracking.CleanupOldStacks() end, CLEANUP_INTERVAL_MS)
end
