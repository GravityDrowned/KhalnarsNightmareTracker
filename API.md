# Khalnar's Nightmare Tracker - API Reference

> **Target Audience**: Developers integrating with or extending the addon

---

## Table of Contents

1. [Global Namespace](#global-namespace)
2. [Public API](#public-api)
3. [Events](#events)
4. [Configuration](#configuration)
5. [Extension Points](#extension-points)
6. [Module Reference](#module-reference)
7. [Constants](#constants)

---

## Global Namespace

The addon exposes a single global table: `KNC`

### Structure Overview

```lua
KNC = {
    -- Persisted Configuration
    variables = SavedVariables,
    
    -- Runtime State
    currentTarget = string | nil,
    currentStacks = number,
    enemyStacks = table,
    MAX_STACKS = number,
    KHALNAR_ABILITY_ID = number,
    
    -- UI Elements
    container = Control,
    texture = Control,
    label = Control,
    
    -- Modules
    Tracking = Module,
    Interface = Module,
    Settings = Module,
    
    -- Functions
    SlashCommand = function,
    IsLightAttack = function,
}
```

---

## Public API

### KNC.SlashCommand

Handles slash command input.

```lua
function KNC.SlashCommand(input: string): void
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `input` | `string` | Command arguments (everything after `/knc `) |

**Example:**

```lua
-- Programmatically toggle the addon
KNC.SlashCommand("toggle")

-- Reset stacks
KNC.SlashCommand("reset")

-- Enable debug mode
KNC.SlashCommand("debug")
```

---

### KNC:IsLightAttack

Determines if combat event parameters represent a light attack.

```lua
function KNC:IsLightAttack(
    result: number,
    abilityName: string,
    abilityActionSlotType: number,
    abilityId: number
): boolean
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `result` | `number` | Combat action result code |
| `abilityName` | `string` | Name of the ability |
| `abilityActionSlotType` | `number` | Action slot type constant |
| `abilityId` | `number` | Ability identifier |

**Returns:** `boolean` - `true` if the event represents a light attack

**Example:**

```lua
-- In a combat event handler
if KNC:IsLightAttack(result, abilityName, abilityActionSlotType, abilityId) then
    -- Handle light attack
end
```

---

## Events

### ESO Events Consumed

The addon listens to these ESO events:

| Event | Namespace | Handler |
|-------|-----------|---------|
| `EVENT_ADD_ON_LOADED` | `KNC_AddOnLoaded` | `OnAddOnLoaded` (internal) |
| `EVENT_COMBAT_EVENT` | `KNC_CombatEvent` | `KNC.Tracking.OnCombatEvent` |
| `EVENT_RETICLE_TARGET_CHANGED` | `KNC_TargetChanged` | `KNC.Tracking.OnTargetChanged` |
| `EVENT_EFFECT_CHANGED` | `KNC_EffectChanged` | `KNC.Tracking.OnEffectChanged` |

### Custom Events

**Currently, the addon does not fire custom events.**

Future versions may add:
- `KNC_STACKS_CHANGED` - When stack count changes
- `KNC_SET_PROCCED` - When 5 stacks reached
- `KNC_TARGET_CHANGED` - When tracking target changes

---

## Configuration

### SavedVariables

**Variable Name:** `KhalnarsNightmareVariables`

**Storage Type:** Account-wide

**Structure:**

```lua
KNC.variables = {
    -- Master enable/disable
    enabled = boolean,     -- default: true
    
    -- Display options
    alwaysShow = boolean,  -- default: false
    unlocked = boolean,    -- default: false
    size = number,         -- default: 64 (pixels, range: 32-128)
    
    -- Position (in pixels from top-left)
    positionLeft = number, -- default: screen_width / 2
    positionTop = number,  -- default: screen_height / 2 + 200
    
    -- Debug
    debugMode = boolean,   -- default: false
}
```

### Accessing Configuration

```lua
-- Read a setting
local isEnabled = KNC.variables.enabled

-- Modify a setting (persists automatically)
KNC.variables.debugMode = true

-- After modifying display settings, update UI
KNC.variables.size = 96
KNC.container:SetDimensions(96, 96)
KNC.texture:SetDimensions(96, 96)
```

### Default Values

Located in `src/Defaults.lua`:

```lua
{
    enabled = true,
    alwaysShow = false,
    unlocked = false,
    size = 64,
    positionLeft = GuiRoot:GetWidth() / 2,
    positionTop = GuiRoot:GetHeight() / 2 + 200,
    debugMode = false,
}
```

---

## Extension Points

### Adding Custom Proc Handlers

Override or extend `KNC.Tracking.ProcSet`:

```lua
-- Store original function
local originalProcSet = KNC.Tracking.ProcSet

-- Extend with custom behavior
function KNC.Tracking.ProcSet()
    -- Call original
    originalProcSet()
    
    -- Add custom behavior
    PlaySound(SOUNDS.ABILITY_ULTIMATE_READY)
    d("Custom: Khalnar's Nightmare procced!")
end
```

### Adding Custom UI Elements

Create child controls of `KNC.container`:

```lua
-- Add a background behind the icon
local background = KNC.container:CreateControl("KNC_Background", CT_BACKDROP)
background:SetAnchor(TOPLEFT, KNC.container, TOPLEFT, -5, -5)
background:SetAnchor(BOTTOMRIGHT, KNC.container, BOTTOMRIGHT, 5, 5)
background:SetEdgeColor(1, 1, 1, 1)
background:SetCenterColor(0, 0, 0, 0.5)

-- Move behind existing elements
background:SetDrawLevel(0)
KNC.texture:SetDrawLevel(1)
KNC.label:SetDrawLevel(2)
```

### Hooking Into State Changes

Hook `KNC.Interface.UpdateUI` for state change notifications:

```lua
local originalUpdateUI = KNC.Interface.UpdateUI

function KNC.Interface.UpdateUI()
    -- Get state before update
    local previousStacks = KNC.currentStacks
    
    -- Call original
    originalUpdateUI()
    
    -- React to changes
    if KNC.currentStacks ~= previousStacks then
        -- Custom handling
        MyAddon.OnStacksChanged(previousStacks, KNC.currentStacks)
    end
end
```

### Adding Settings

Extend the settings panel:

```lua
-- After KNC.Settings.Initialize() runs
local additionalSettings = {
    {
        type = "checkbox",
        name = "Play Sound on Proc",
        tooltip = "Play a sound when 5 stacks are reached",
        getFunc = function() return KNC.variables.playSound end,
        setFunc = function(value) KNC.variables.playSound = value end,
        default = true,
    },
}

-- Note: Would need to modify Settings.lua to add these
```

---

## Module Reference

### KNC.Tracking

Stack tracking and combat event handling.

#### Functions

##### `KNC.Tracking.Initialize()`

Initializes the tracking module.

```lua
function KNC.Tracking.Initialize(): void
```

**Side Effects:**
- Sets up state variables on `KNC`
- Registers event handlers
- Starts cleanup timer

---

##### `KNC.Tracking.OnCombatEvent(...)`

Handles `EVENT_COMBAT_EVENT`.

```lua
function KNC.Tracking.OnCombatEvent(
    eventCode: number,
    sourceUnitTag: string,
    sourceName: string,
    sourceDisplayName: string,
    targetUnitTag: string,
    targetName: string,
    targetDisplayName: string,
    abilityName: string,
    abilityId: number,
    actionSlotType: number,
    result: number,
    isError: boolean,
    hitValue: number,
    powerType: number,
    powerValue: number,
    damageType: number,
    damageOverTime: boolean,
    critical: boolean,
    glancing: boolean,
    crushing: boolean,
    missType: number,
    abilityActionSlotType: number,
    abilityId: number,
    sourceUnit: number,
    targetUnit: number
): void
```

---

##### `KNC.Tracking.OnTargetChanged(eventCode)`

Handles `EVENT_RETICLE_TARGET_CHANGED`.

```lua
function KNC.Tracking.OnTargetChanged(eventCode: number): void
```

**Behavior:**
1. Saves current target's stacks to cache
2. Loads new target's stacks from cache (or 0)
3. Updates UI

---

##### `KNC.Tracking.OnEffectChanged(...)`

Handles `EVENT_EFFECT_CHANGED`.

```lua
function KNC.Tracking.OnEffectChanged(
    eventCode: number,
    unitTag: string,
    effectName: string,
    effectId: number,
    result: number,
    stackCount: number
): void
```

**Behavior:**
- Syncs stacks with game effect system
- Only processes `KHALNAR_ABILITY_ID`

---

##### `KNC.Tracking.IncrementStacks(targetName)`

Increments stack count for current target.

```lua
function KNC.Tracking.IncrementStacks(targetName: string): void
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `targetName` | `string` | Name of the target |

**Behavior:**
- Increments `KNC.currentStacks` (max 5)
- Triggers `ProcSet()` at 5 stacks
- Updates UI

---

##### `KNC.Tracking.ProcSet()`

Called when 5 stacks are reached.

```lua
function KNC.Tracking.ProcSet(): void
```

**Current Implementation:** Debug logging only

**Extension Point:** Override for custom behavior (sounds, alerts, etc.)

---

##### `KNC.Tracking.ResetStacks()`

Resets current stack count to 0.

```lua
function KNC.Tracking.ResetStacks(): void
```

**Behavior:**
- Sets `KNC.currentStacks = 0`
- Updates UI
- Logs if debug mode enabled

---

##### `KNC.Tracking.CleanupOldStacks()`

Garbage collects stale enemy stack data.

```lua
function KNC.Tracking.CleanupOldStacks(): void
```

**Behavior:**
- Removes cache entries older than 5 minutes
- Self-schedules every 30 seconds

---

### KNC.Interface

UI rendering and display management.

#### Functions

##### `KNC.Interface.Initialize()`

Creates and sets up UI elements.

```lua
function KNC.Interface.Initialize(): void
```

**Creates:**
- `KNC.container` - TopLevelWindow
- `KNC.texture` - Icon texture
- `KNC.label` - Stack count label

---

##### `KNC.Interface.UpdateUI()`

Updates display based on current state.

```lua
function KNC.Interface.UpdateUI(): void
```

**Behavior:**
- Shows/hides container based on state
- Updates label text
- Sets texture color based on stack count

---

##### `KNC.Interface.OnPositionChanged(eventCode, window)`

Saves position when user drags display.

```lua
function KNC.Interface.OnPositionChanged(
    eventCode: number,
    window: Control
): void
```

---

### KNC.Settings

Settings panel integration.

#### Functions

##### `KNC.Settings.Initialize()`

Registers settings with LibAddonMenu.

```lua
function KNC.Settings.Initialize(): void
```

**Behavior:**
- Creates settings controls if LibAddonMenu2 exists
- Registers option controls

---

## Constants

### Tracking Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `KNC.MAX_STACKS` | `5` | Maximum stack count |
| `KNC.KHALNAR_ABILITY_ID` | `163598` | Ability ID to track (placeholder) |

### Cleanup Constants

| Constant | Value | Description |
|----------|-------|-------------|
| Cleanup interval | `30000` | Cleanup runs every 30 seconds (ms) |
| Cache expiry | `300000` | Entries expire after 5 minutes (ms) |

### Display Constants

| Constant | Value | Description |
|----------|-------|-------------|
| Min size | `32` | Minimum display size (pixels) |
| Max size | `128` | Maximum display size (pixels) |
| Default size | `64` | Default display size (pixels) |
| Size step | `8` | Size slider increment (pixels) |

### Color Constants

| Stack Range | RGB | Color Name |
|-------------|-----|------------|
| 1-2 | `(0, 1, 0)` | Green |
| 3-4 | `(1, 1, 0)` | Yellow |
| 5 | `(1, 0, 0)` | Red |

---

## Type Definitions

### EnemyStackData

```lua
-- Structure stored in KNC.enemyStacks[enemyName]
EnemyStackData = {
    stacks = number,      -- 0-5
    timestamp = number,   -- GetGameTimeMilliseconds()
}
```

### SavedVariables

```lua
SavedVariables = {
    enabled = boolean,
    alwaysShow = boolean,
    unlocked = boolean,
    size = number,
    positionLeft = number,
    positionTop = number,
    debugMode = boolean,
}
```

---

## Usage Examples

### Reading Current State

```lua
-- Get current stacks
local stacks = KNC.currentStacks

-- Get current target
local target = KNC.currentTarget

-- Check if enabled
local isEnabled = KNC.variables.enabled

-- Get cached stacks for an enemy
local enemyData = KNC.enemyStacks["Mudcrab"]
if enemyData then
    d("Mudcrab has " .. enemyData.stacks .. " stacks")
end
```

### Modifying Behavior

```lua
-- Disable the addon programmatically
KNC.variables.enabled = false
KNC.Interface.UpdateUI()

-- Force a stack reset
KNC.Tracking.ResetStacks()

-- Manually set stacks (for testing)
KNC.currentStacks = 3
KNC.Interface.UpdateUI()
```

### Creating an Integration

```lua
-- Example: Integration with another addon
local function OnKhalnarsProc()
    -- Your addon's response to Khalnar's proc
    MyAddon.NotifyProc("Khalnar's Nightmare")
end

-- Hook into the proc function
local originalProcSet = KNC.Tracking.ProcSet
KNC.Tracking.ProcSet = function()
    originalProcSet()
    OnKhalnarsProc()
end
```

---

## Compatibility Notes

### ESO API Versions

- **Minimum:** 101044
- **Maximum:** 101045

### Dependencies

- **LibAddonMenu-2.0** (v30+) - Required for settings panel

### Known Conflicts

None currently documented.

---

*Last Updated: Version 1.0.0*
