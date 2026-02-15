# Khalnar's Nightmare Tracker - Technical Documentation

> **Target Audience**: Developers who want to understand, modify, or extend the addon

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Code Structure](#code-structure)
3. [Module Documentation](#module-documentation)
4. [Data Flow](#data-flow)
5. [ESO API Usage](#eso-api-usage)
6. [Event System](#event-system)
7. [State Management](#state-management)
8. [UI System](#ui-system)
9. [Integration Points](#integration-points)
10. [Design Patterns](#design-patterns)
11. [Known Limitations](#known-limitations)
12. [Development Guide](#development-guide)

---

## Architecture Overview

### High-Level Design

Khalnar's Nightmare Tracker follows a **modular architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│                        ESO Game Engine                          │
│                    (Event System & API)                         │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Main.lua (Entry Point)                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - Addon initialization                                 │    │
│  │  - SavedVariables setup                                 │    │
│  │  - Slash command routing                                │    │
│  │  - Module orchestration                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌───────────────┐ ┌───────────────┐
│  Tracking.lua   │ │ Interface.lua │ │ Settings.lua  │
│  ─────────────  │ │ ───────────── │ │ ───────────── │
│  - Combat events│ │ - UI creation │ │ - LAM panel   │
│  - Stack logic  │ │ - Rendering   │ │ - Config      │
│  - Target track │ │ - Positioning │ │ - Callbacks   │
└────────┬────────┘ └───────┬───────┘ └───────────────┘
         │                  │
         └──────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Defaults.lua                                │
│                  (Configuration defaults)                       │
└─────────────────────────────────────────────────────────────────┘
```

### Design Philosophy

1. **Event-Driven**: React to ESO events rather than polling
2. **Modular**: Each module handles a specific responsibility
3. **Stateful**: Maintain per-enemy stack tracking
4. **Configurable**: User preferences via SavedVariables
5. **Minimal**: Only essential functionality, low overhead

---

## Code Structure

### File Organization

```
KhalnarsNightmareTracker/
├── KhalnarsNightmareTracker.txt    # Addon manifest
├── src/
│   ├── Main.lua                     # Entry point, initialization
│   ├── Defaults.lua                 # Default configuration values
│   ├── Tracking.lua                 # Combat event handling, stack logic
│   ├── Interface.lua                # UI rendering and display
│   └── Settings.lua                 # LibAddonMenu integration
├── textures/
│   └── khalnar_icon.dds             # Display texture (placeholder)
├── README.md                        # User documentation
├── TECHNICAL.md                     # This file
├── API.md                           # API reference
└── CHANGELOG.md                     # Version history
```

### Load Order

The manifest file (`KhalnarsNightmareTracker.txt`) defines the load order:

```
src/Main.lua       # 1. Creates KNC global, sets up SavedVariables
src/Defaults.lua   # 2. Exports default configuration (currently unused)
src/Tracking.lua   # 3. Defines tracking module
src/Interface.lua  # 4. Defines interface module
src/Settings.lua   # 5. Defines settings module
```

> **Note**: Module initialization occurs in `OnAddOnLoaded`, not during file load.

---

## Module Documentation

### Main.lua - Entry Point

**Location**: `src/Main.lua`

**Responsibilities**:
- Create global `KNC` namespace
- Initialize SavedVariables with defaults
- Register `EVENT_ADD_ON_LOADED` handler
- Orchestrate module initialization
- Handle slash commands

#### Global Table Structure

```lua
KNC = {
    -- SavedVariables (persisted)
    variables = {
        enabled = true,
        alwaysShow = false,
        unlocked = false,
        size = 64,
        positionLeft = <screen_center>,
        positionTop = <screen_center + 200>,
        debugMode = false,
    },
    
    -- Runtime state (transient)
    currentTarget = nil,     -- Current target name
    currentStacks = 0,       -- Current stack count
    enemyStacks = {},        -- Per-enemy stack cache
    MAX_STACKS = 5,          -- Maximum stacks before proc
    KHALNAR_ABILITY_ID = 163598,  -- Set ability ID
    
    -- UI Elements
    container = nil,         -- Top-level window
    texture = nil,           -- Icon texture
    label = nil,             -- Stack count label
    
    -- Modules
    Tracking = {},           -- Tracking module
    Interface = {},          -- Interface module
    Settings = {},           -- Settings module
}
```

#### Key Functions

##### `OnAddOnLoaded(eventCode, addOnName)`

Internal event handler that initializes the addon when ESO loads it.

```lua
-- Called by ESO when any addon loads
-- Filters for our addon by name
-- Initializes all modules in sequence
-- Unregisters itself to prevent duplicate calls
```

**Sequence**:
1. Check if `addOnName == "KhalnarsNightmareTracker"`
2. Call `KNC.Tracking.Initialize()`
3. Call `KNC.Interface.Initialize()`
4. Call `KNC.Settings.Initialize()`
5. Register `/knc` slash command
6. Unregister event handler

##### `KNC.SlashCommand(input)`

Handles all `/knc` commands.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| input | string | Full command input after `/knc` |

**Commands**:
| Input | Action |
|-------|--------|
| (empty) | Display addon status |
| "reset" | Reset stacks to 0 |
| "toggle" | Toggle addon enabled state |
| "debug" | Toggle debug mode |
| (other) | Show help text |

---

### Tracking.lua - Event Handling & Stack Logic

**Location**: `src/Tracking.lua`

**Responsibilities**:
- Register and handle combat events
- Track light attacks per target
- Manage stack state
- Handle target switching
- Sync with game effect system
- Clean up stale data

#### Key Functions

##### `KNC.Tracking.Initialize()`

Sets up the tracking module.

```lua
function KNC.Tracking.Initialize()
    -- Initialize state variables
    KNC.currentTarget = nil
    KNC.currentStacks = 0
    KNC.enemyStacks = {}
    KNC.MAX_STACKS = 5
    KNC.KHALNAR_ABILITY_ID = 163598
    
    -- Register event handlers
    EVENT_MANAGER:RegisterForEvent("KNC_CombatEvent", 
        EVENT_COMBAT_EVENT, KNC.Tracking.OnCombatEvent)
    EVENT_MANAGER:RegisterForEvent("KNC_TargetChanged", 
        EVENT_RETICLE_TARGET_CHANGED, KNC.Tracking.OnTargetChanged)
    EVENT_MANAGER:RegisterForEvent("KNC_EffectChanged", 
        EVENT_EFFECT_CHANGED, KNC.Tracking.OnEffectChanged)
    
    -- Start cleanup timer
    zo_callLater(function() KNC.Tracking.CleanupOldStacks() end, 30000)
end
```

##### `KNC.Tracking.OnCombatEvent(...)`

Handles all combat events, filtering for player light attacks.

**Parameters** (from ESO API):
| Name | Type | Description |
|------|------|-------------|
| eventCode | number | Event identifier |
| sourceUnitTag | string | "player", "group1", etc. |
| sourceName | string | Source unit name |
| targetUnitTag | string | Target unit tag |
| targetName | string | Target unit name |
| abilityName | string | Name of ability used |
| abilityId | number | Ability ID |
| result | number | Action result code |
| ... | various | Additional combat data |

**Logic Flow**:
```
┌──────────────────────┐
│   Combat Event       │
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│ Addon enabled?       │──No──> Return
└──────────┬───────────┘
           │ Yes
           ▼
┌──────────────────────┐
│ Source is player?    │──No──> Return
└──────────┬───────────┘
           │ Yes
           ▼
┌──────────────────────┐
│ Is light attack?     │──No──> Return
└──────────┬───────────┘
           │ Yes
           ▼
┌──────────────────────┐
│ Valid target?        │──No──> Return
└──────────┬───────────┘
           │ Yes
           ▼
┌──────────────────────┐
│ Increment stacks     │
└──────────────────────┘
```

##### `KNC.Tracking.OnTargetChanged(eventCode)`

Handles target switching, preserving per-enemy stack state.

**Logic**:
1. Save current target's stacks to `enemyStacks` cache
2. Get new target name via `GetUnitName("reticleover")`
3. Load cached stacks for new target (or reset to 0)
4. Update UI

##### `KNC.Tracking.OnEffectChanged(...)`

Syncs with game's effect system for accuracy.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| eventCode | number | Event identifier |
| unitTag | string | Affected unit tag |
| effectName | string | Effect name |
| effectId | number | Effect ability ID |
| result | number | EFFECT_RESULT_* constant |
| stackCount | number | Current stack count |

**Behavior**:
- `EFFECT_RESULT_GAINED/UPDATED`: Sync stacks from game
- `EFFECT_RESULT_FADED`: Reset stacks to 0

##### `KNC.Tracking.IncrementStacks(targetName)`

Increments stack count and triggers UI update.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| targetName | string | Name of the target |

**Logic**:
```lua
if KNC.currentStacks < KNC.MAX_STACKS then
    KNC.currentStacks = KNC.currentStacks + 1
    
    if KNC.currentStacks >= KNC.MAX_STACKS then
        KNC.Tracking.ProcSet()
    end
    
    KNC.Interface.UpdateUI()
end
```

##### `KNC.Tracking.ProcSet()`

Called when 5 stacks are reached.

**Current Implementation**: Debug logging only
**Future Extension Point**: Add sound, visual effects, etc.

##### `KNC.Tracking.ResetStacks()`

Manually resets stack count to 0.

##### `KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId)`

Determines if a combat event represents a light attack.

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| result | number | Combat result code |
| abilityName | string | Ability name |
| abilityActionSlotType | number | Action slot type |
| abilityId | number | Ability ID |

**Returns**: `boolean` - True if light attack

**Detection Methods**:
1. Check `abilityActionSlotType == ACTION_SLOT_TYPE_LIGHT_ATTACK`
2. Check `abilityId == 0` with damage result

##### `KNC.Tracking.CleanupOldStacks()`

Periodic garbage collection for stale enemy stack data.

**Behavior**:
- Runs every 30 seconds
- Removes entries older than 5 minutes
- Self-scheduling via `zo_callLater`

---

### Interface.lua - UI Rendering

**Location**: `src/Interface.lua`

**Responsibilities**:
- Create UI elements
- Update display based on state
- Handle positioning
- Manage visibility

#### UI Hierarchy

```
GuiRoot
└── KNCContainer (TopLevelWindow)
    ├── KNC_Texture (CT_TEXTURE) - Icon
    └── KNC_Label (CT_LABEL) - Stack count
```

#### Key Functions

##### `KNC.Interface.Initialize()`

Creates all UI elements.

```lua
function KNC.Interface.Initialize()
    -- Create container window
    KNC.container = WINDOW_MANAGER:CreateTopLevelWindow("KNCContainer")
    KNC.container:SetDimensions(KNC.variables.size, KNC.variables.size)
    KNC.container:SetClampedToScreen(true)
    KNC.container:SetMovable(not KNC.variables.unlocked)
    KNC.container:SetMouseEnabled(not KNC.variables.unlocked)
    
    -- Create texture
    KNC.texture = KNC.container:CreateControl("KNC_Texture", CT_TEXTURE)
    KNC.texture:SetAnchor(TOPLEFT, KNC.container, TOPLEFT, 0, 0)
    KNC.texture:SetDimensions(KNC.variables.size, KNC.variables.size)
    KNC.texture:SetTexture("KhalnarsNightmareTracker/textures/khalnar_icon.dds")
    
    -- Create label
    KNC.label = KNC.container:CreateControl("KNC_Label", CT_LABEL)
    KNC.label:SetAnchor(CENTER, KNC.container, CENTER, 0, 0)
    KNC.label:SetFont("ZoFontWinH4")
    KNC.label:SetColor(1, 1, 1, 1)
    KNC.label:SetText("")
    
    -- Position and hide
    KNC.container:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 
        KNC.variables.positionLeft, KNC.variables.positionTop)
    KNC.container:SetHidden(true)
    
    -- Register move handler
    KNC.container:SetHandler("OnMoveStop", KNC.Interface.OnPositionChanged)
end
```

##### `KNC.Interface.UpdateUI()`

Updates display based on current state.

**Color Logic**:
| Stack Count | RGB Values | Color |
|-------------|------------|-------|
| 0 | Hidden | - |
| 1-2 | (0, 1, 0) | Green |
| 3-4 | (1, 1, 0) | Yellow |
| 5 | (1, 0, 0) | Red |

**Visibility Logic**:
- Show if `stacks > 0` OR `alwaysShow == true`
- Hide if `enabled == false`

##### `KNC.Interface.OnPositionChanged(eventCode, window)`

Saves new position when user drags the display.

---

### Settings.lua - Settings Panel

**Location**: `src/Settings.lua`

**Responsibilities**:
- Register with LibAddonMenu-2.0
- Define settings controls
- Handle setting changes

#### Key Functions

##### `KNC.Settings.Initialize()`

Registers the settings panel with LibAddonMenu.

**Panel Controls**:

| Control Type | Name | Setting |
|--------------|------|---------|
| checkbox | Enable Addon | `enabled` |
| checkbox | Always Show Display | `alwaysShow` |
| checkbox | Unlock Position | `unlocked` |
| button | Reset Position | (action) |
| slider | Display Size | `size` |
| checkbox | Debug Mode | `debugMode` |
| description | (help text) | - |

**Note**: The settings panel only appears if LibAddonMenu2 is loaded.

---

### Defaults.lua - Configuration Defaults

**Location**: `src/Defaults.lua`

**Purpose**: Defines default values for SavedVariables.

```lua
return {
    enabled = true,
    alwaysShow = false,
    unlocked = false,
    size = 64,
    positionLeft = GuiRoot:GetWidth() / 2,
    positionTop = GuiRoot:GetHeight() / 2 + 200,
    debugMode = false,
}
```

> **Note**: Currently, `Main.lua` duplicates these defaults inline. This file is available for future refactoring to use `require()` or similar patterns.

---

## Data Flow

### Light Attack Detection Flow

```
┌────────────────────┐
│ Player Light Attack│
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ ESO Combat Event   │
│ EVENT_COMBAT_EVENT │
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ OnCombatEvent()    │
│ Filter & Validate  │
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ IsLightAttack()    │
│ Detection Logic    │
└─────────┬──────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
┌───────┐   ┌───────┐
│ Yes   │   │ No    │
└───┬───┘   └───────┘
    ▼
┌────────────────────┐
│ IncrementStacks()  │
└─────────┬──────────┘
          ▼
┌────────────────────┐
│ UpdateUI()         │
└────────────────────┘
```

### Target Switch Flow

```
┌────────────────────────────────────┐
│ Player Changes Target              │
└─────────────┬──────────────────────┘
              ▼
┌────────────────────────────────────┐
│ EVENT_RETICLE_TARGET_CHANGED       │
└─────────────┬──────────────────────┘
              ▼
┌────────────────────────────────────┐
│ OnTargetChanged()                  │
└─────────────┬──────────────────────┘
              ▼
┌────────────────────────────────────┐
│ Save old target stacks to cache    │
│ enemyStacks[oldTarget] = {         │
│   stacks: n, timestamp: now        │
│ }                                  │
└─────────────┬──────────────────────┘
              ▼
┌────────────────────────────────────┐
│ Load new target stacks from cache  │
│ currentStacks = enemyStacks[new]   │
│ or 0 if not found                  │
└─────────────┬──────────────────────┘
              ▼
┌────────────────────────────────────┐
│ UpdateUI()                         │
└────────────────────────────────────┘
```

### Configuration Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SavedVariables                           │
│           (KhalnarsNightmareVariables.lua)                  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼ Load on Startup
┌─────────────────────────────────────────────────────────────┐
│                  ZO_SavedVars:NewAccountWide                │
│                   Creates KNC.variables                     │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
┌─────────────────┐ ┌───────────────┐ ┌───────────────┐
│  Tracking.lua   │ │ Interface.lua │ │ Settings.lua  │
│  Reads enabled, │ │ Reads size,   │ │ Reads/Writes  │
│  debugMode      │ │ position,     │ │ all settings  │
│                 │ │ alwaysShow    │ │               │
└─────────────────┘ └───────────────┘ └───────────────┘
```

---

## ESO API Usage

### Event System

| Event | Purpose | Handler |
|-------|---------|---------|
| `EVENT_ADD_ON_LOADED` | Addon initialization | `OnAddOnLoaded` |
| `EVENT_COMBAT_EVENT` | Light attack detection | `OnCombatEvent` |
| `EVENT_RETICLE_TARGET_CHANGED` | Target switching | `OnTargetChanged` |
| `EVENT_EFFECT_CHANGED` | Effect sync | `OnEffectChanged` |

### Window Management

| API | Purpose |
|-----|---------|
| `WINDOW_MANAGER:CreateTopLevelWindow()` | Create container |
| `control:CreateControl()` | Create child controls |
| `control:SetAnchor()` | Position elements |
| `control:SetDimensions()` | Set size |
| `control:SetHandler()` | Register callbacks |

### Game State APIs

| API | Purpose |
|-----|---------|
| `GetUnitName("reticleover")` | Get current target name |
| `GetGameTimeMilliseconds()` | Timestamps for cleanup |
| `GuiRoot:GetWidth/Height()` | Screen dimensions |

### Utility Functions

| API | Purpose |
|-----|---------|
| `zo_callLater(func, ms)` | Delayed execution |
| `d(message)` | Debug output to chat |
| `ZO_SavedVars:NewAccountWide()` | Persistent storage |

### Constants Used

| Constant | Value | Purpose |
|----------|-------|---------|
| `ACTION_SLOT_TYPE_LIGHT_ATTACK` | - | Light attack detection |
| `ACTION_RESULT_DAMAGE` | - | Damage result check |
| `ACTION_RESULT_CRITICAL_DAMAGE` | - | Crit damage check |
| `EFFECT_RESULT_GAINED` | - | Effect started |
| `EFFECT_RESULT_UPDATED` | - | Effect updated |
| `EFFECT_RESULT_FADED` | - | Effect ended |
| `CT_TEXTURE` | - | Texture control type |
| `CT_LABEL` | - | Label control type |
| `TOPLEFT`, `CENTER` | - | Anchor points |

---

## Event System

### Event Registration

```lua
-- Pattern: EVENT_MANAGER:RegisterForEvent(namespace, event, handler)
EVENT_MANAGER:RegisterForEvent("KNC_CombatEvent", 
    EVENT_COMBAT_EVENT, KNC.Tracking.OnCombatEvent)
```

### Event Unregistration

```lua
-- Used after initialization to prevent duplicate calls
EVENT_MANAGER:UnregisterForEvent("KNC_AddOnLoaded", EVENT_ADD_ON_LOADED)
```

### Event Handler Signature

Combat events have extensive parameters:

```lua
function OnCombatEvent(
    eventCode,           -- Event ID
    sourceUnitTag,       -- Source unit ("player", "group1", etc.)
    sourceName,          -- Source name (localized)
    sourceDisplayName,   -- Source @name
    targetUnitTag,       -- Target unit
    targetName,          -- Target name
    targetDisplayName,   -- Target @name
    abilityName,         -- Ability name
    abilityId,           -- Ability ID (number)
    actionSlotType,      -- Action slot type
    result,              -- Action result code
    isError,             -- Error flag
    hitValue,            -- Damage/heal value
    powerType,           -- Power type
    powerValue,          -- Power value
    damageType,          -- Damage type
    damageOverTime,      -- DoT flag
    critical,            -- Critical hit flag
    glancing,            -- Glancing blow flag
    crushing,            -- Crushing blow flag
    missType,            -- Miss type
    abilityActionSlotType, -- Ability action slot type
    abilityId,           -- Duplicate ability ID
    sourceUnit,          -- Source unit
    targetUnit           -- Target unit
)
```

---

## State Management

### State Variables

```lua
-- Current tracking state
KNC.currentTarget = nil    -- string: Current target name
KNC.currentStacks = 0      -- number: Current stack count (0-5)

-- Per-enemy cache
KNC.enemyStacks = {
    ["Enemy Name"] = {
        stacks = 3,                    -- Stack count
        timestamp = 1234567890123      -- Last update time (ms)
    },
    -- ...
}

-- Constants
KNC.MAX_STACKS = 5
KNC.KHALNAR_ABILITY_ID = 163598
```

### State Transitions

```
State: NO_TARGET
  ├─ Target acquired ──> State: TRACKING (stacks = cached or 0)
  
State: TRACKING
  ├─ Light attack ──> Increment stacks
  ├─ 5 stacks ──> Proc set, stay in TRACKING
  ├─ Target lost ──> State: NO_TARGET (save stacks to cache)
  └─ Target changed ──> Save stacks, load new target's stacks
```

### Cache Lifecycle

1. **Creation**: When switching away from a target
2. **Access**: When switching to a target
3. **Update**: On each light attack
4. **Cleanup**: Every 30 seconds, entries older than 5 minutes removed

---

## UI System

### Control Hierarchy

```lua
-- Container (TopLevelWindow)
KNC.container = WINDOW_MANAGER:CreateTopLevelWindow("KNCContainer")
    -- Properties
    SetDimensions(64, 64)
    SetClampedToScreen(true)
    SetMovable(true/false)
    SetMouseEnabled(true/false)

-- Texture (child of container)
KNC.texture = container:CreateControl("KNC_Texture", CT_TEXTURE)
    -- Properties
    SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
    SetDimensions(64, 64)
    SetTexture("path/to/texture.dds")
    SetColor(r, g, b, a)

-- Label (child of container)
KNC.label = container:CreateControl("KNC_Label", CT_LABEL)
    -- Properties
    SetAnchor(CENTER, container, CENTER, 0, 0)
    SetFont("ZoFontWinH4")
    SetColor(1, 1, 1, 1)
    SetText("0")
```

### Update Flow

```lua
function KNC.Interface.UpdateUI()
    if not KNC.variables.enabled then
        KNC.container:SetHidden(true)
        return
    end
    
    if KNC.currentStacks > 0 or KNC.variables.alwaysShow then
        KNC.container:SetHidden(false)
        KNC.label:SetText(tostring(KNC.currentStacks))
        
        -- Color based on stack level
        local r, g, b = GetColorForStacks(KNC.currentStacks)
        KNC.texture:SetColor(r, g, b, 1)
    else
        KNC.container:SetHidden(true)
    end
end
```

### Positioning

- **Initial Position**: Center-bottom of screen
- **User Positioning**: Drag when "Unlock Position" enabled
- **Position Persistence**: Saved in `variables.positionLeft/Top`
- **Reset**: Via settings button, resets to initial position

---

## Integration Points

### LibAddonMenu-2.0

```lua
-- Check for library availability
if LibAddonMenu2 then
    -- Define panel metadata (would need to be added)
    local panel = {
        type = "panel",
        name = "Khalnar's Nightmare Tracker",
        displayName = "Khalnar's Nightmare Tracker",
        author = "YourName",
        version = "1.0.0",
        registerForRefresh = true,
        registerForDefaults = true,
    }
    
    -- Register panel
    LibAddonMenu2:RegisterAddonPanel("KNC_SettingsPanel", panel)
    
    -- Register controls
    LibAddonMenu2:RegisterOptionControls("KNC_Settings", optionsData)
end
```

### SavedVariables

**File**: `KhalnarsNightmareVariables.lua` (auto-created by ESO)

**Location**: `Documents/Elder Scrolls Online/live/SavedVariables/`

```lua
-- Example saved data structure
KhalnarsNightmareVariables = {
    ["Default"] = {
        ["@AccountName"] = {
            ["$AccountWide"] = {
                enabled = true,
                alwaysShow = false,
                unlocked = false,
                size = 64,
                positionLeft = 960,
                positionTop = 740,
                debugMode = false,
            }
        }
    }
}
```

---

## Design Patterns

### Patterns Borrowed from Reference Addons

#### From GrimFocusCounter

1. **Stack Counter UI**: Simple number display with color coding
2. **Movable Window**: User-positionable display
3. **Slash Commands**: `/command` pattern for control

#### From Srendarr

1. **Effect Change Handling**: Using `EVENT_EFFECT_CHANGED` for sync
2. **Debuff Tracking**: Monitoring specific ability IDs
3. **Color-Coded States**: Visual feedback for different states

#### From SquishyAutoMarker

1. **Target Tracking**: Using `EVENT_RETICLE_TARGET_CHANGED`
2. **Per-Target State**: Maintaining data per enemy
3. **State Caching**: Preserving state when switching targets

### Module Pattern

```lua
-- Module initialization pattern
KNC.ModuleName = KNC.ModuleName or {}

function KNC.ModuleName.Initialize()
    -- Setup code
end

function KNC.ModuleName.PublicFunction()
    -- Public API
end
```

### Event Filtering Pattern

```lua
function OnEvent(eventCode, ...)
    -- Guard clauses for early return
    if not KNC.variables.enabled then return end
    if sourceUnitTag ~= "player" then return end
    if not IsRelevantEvent(...) then return end
    
    -- Main logic
    ProcessEvent(...)
end
```

---

## Known Limitations

### Current Constraints

1. **Ability ID Placeholder**
   - `KHALNAR_ABILITY_ID = 163598` is a placeholder
   - Needs verification with actual game data
   - May need update after game patches

2. **Light Attack Detection**
   - Relies on heuristics (action slot type, ability ID = 0)
   - May not catch all edge cases
   - Different weapon types may vary

3. **Target Name Collision**
   - Uses target name as cache key
   - Multiple enemies with same name share stacks
   - Could use unit ID instead for precision

4. **No Texture Asset**
   - References `khalnar_icon.dds` which needs creation
   - Falls back to default if missing

5. **Settings Panel Registration**
   - Missing `RegisterAddonPanel` call
   - Settings may not appear in addon menu

### TODOs

1. **Verify Khalnar's Nightmare ability ID**
2. **Create custom texture asset**
3. **Add sound notification option**
4. **Consider unit ID instead of name for tracking**
5. **Add combat state checking**
6. **Complete LAM panel registration**
7. **Add localization support**

### Performance Considerations

1. **Event Volume**: Combat events fire frequently; filtering early is critical
2. **Cache Cleanup**: Runs every 30 seconds to prevent memory growth
3. **UI Updates**: Only update when state changes

---

## Development Guide

### Setting Up Development Environment

1. **Install ESO** and locate your addon directory
2. **Clone/copy** addon to `AddOns/KhalnarsNightmareTracker/`
3. **Enable** in-game via addon manager
4. **Use** `/reloadui` to reload after changes

### Testing Changes

1. **Enable debug mode**: `/knc debug`
2. **Equip** Khalnar's Nightmare set (or any set for testing)
3. **Enter combat** and perform light attacks
4. **Watch chat** for debug output
5. **Verify** UI updates correctly

### Code Style

- Use `KNC` prefix for all globals
- CamelCase for function names
- camelCase for local variables
- UPPER_CASE for constants
- Comments for non-obvious logic

### Adding New Features

1. Determine which module owns the feature
2. Add state to `KNC` if needed
3. Add SavedVariables default if configurable
4. Add settings control if user-facing
5. Update UI if visible change
6. Test with debug mode
7. Update documentation

---

## Appendix

### ESO Control Types

| Constant | Description |
|----------|-------------|
| `CT_TEXTURE` | Image display |
| `CT_LABEL` | Text display |
| `CT_BUTTON` | Clickable button |
| `CT_BACKDROP` | Background panel |

### Font Strings

| Font | Description |
|------|-------------|
| `ZoFontWinH4` | Large heading |
| `ZoFontGame` | Standard game text |
| `ZoFontGameSmall` | Small game text |

### Useful Debug Commands

```lua
-- Print all registered events
/script d(EVENT_COMBAT_EVENT)

-- Check addon status
/knc

-- Enable verbose logging
/knc debug

-- Manually trigger UI update
/script KNC.Interface.UpdateUI()

-- Check current stacks
/script d(KNC.currentStacks)
```

---

*Last Updated: Version 1.0.0*
