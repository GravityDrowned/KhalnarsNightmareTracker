# Khalnar's Nightmare Tracker - Architecture Overview

This document provides a high-level architectural overview of the addon, including visual diagrams and data flow explanations.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ELDER SCROLLS ONLINE                              │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ESO EVENT SYSTEM                            │   │
│  │                                                                     │   │
│  │   EVENT_COMBAT_EVENT    EVENT_RETICLE_TARGET_CHANGED               │   │
│  │   EVENT_EFFECT_CHANGED  EVENT_ADD_ON_LOADED                        │   │
│  └─────────────────────────────────┬───────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    KHALNAR'S NIGHTMARE TRACKER                      │   │
│  │                                                                     │   │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │   │
│  │   │  Main.lua   │  │ Tracking.lua│  │Interface.lua│               │   │
│  │   │             │  │             │  │             │               │   │
│  │   │ - Init      │  │ - Events    │  │ - UI        │               │   │
│  │   │ - Slash Cmd │  │ - Stacks    │  │ - Display   │               │   │
│  │   │ - Config    │  │ - Targets   │  │ - Colors    │               │   │
│  │   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘               │   │
│  │          │                │                │                       │   │
│  │          └────────────────┼────────────────┘                       │   │
│  │                           │                                         │   │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │   │
│  │   │Settings.lua │  │ Defaults.lua│  │   textures/ │               │   │
│  │   │             │  │             │  │             │               │   │
│  │   │ - LAM Panel │  │ - Defaults  │  │ - Icons     │               │   │
│  │   └─────────────┘  └─────────────┘  └─────────────┘               │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                       SAVED VARIABLES                                │   │
│  │                  KhalnarsNightmareVariables.lua                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Module Relationships

```
                              ┌─────────────┐
                              │   Main.lua  │
                              │  (Entry)    │
                              └──────┬──────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
              ▼                      ▼                      ▼
       ┌─────────────┐        ┌─────────────┐        ┌─────────────┐
       │ Tracking.lua│        │Interface.lua│        │ Settings.lua│
       │             │        │             │        │             │
       │  Depends:   │        │  Depends:   │        │  Depends:   │
       │  - Main     │        │  - Main     │        │  - Main     │
       │             │◄───────│  - Tracking │        │  - Interface│
       │             │        │             │        │  - LAM      │
       └─────────────┘        └─────────────┘        └─────────────┘
              │                      ▲
              │                      │
              └──────────────────────┘
                    Updates UI
```

### Dependency Matrix

| Module | Main | Tracking | Interface | Settings | LAM |
|--------|:----:|:--------:|:---------:|:--------:|:---:|
| Main.lua | - | Creates | Creates | Creates | No |
| Tracking.lua | Reads vars | - | Calls UpdateUI | No | No |
| Interface.lua | Reads vars | Reads stacks | - | No | No |
| Settings.lua | Reads vars | No | Calls funcs | - | Yes |

---

## Event Flow

### Initialization Sequence

```
┌─────────┐  Load    ┌─────────────────┐
│  ESO    │ ───────► │ Main.lua loaded │
│  Game   │          │ KNC table init  │
└─────────┘          └────────┬────────┘
                              │
                              ▼
┌─────────────────────────────────────────┐
│ Other modules loaded (Tracking, etc.)  │
│ Module tables created but not init'd   │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ EVENT_ADD_ON_LOADED fires               │
│ OnAddOnLoaded handler executes          │
└────────────────────┬────────────────────┘
                     │
     ┌───────────────┼───────────────┐
     ▼               ▼               ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│Tracking │    │Interface│    │Settings │
│  Init   │    │  Init   │    │  Init   │
└─────────┘    └─────────┘    └─────────┘
     │               │               │
     ▼               ▼               ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Events  │    │   UI    │    │  LAM    │
│Registered│   │ Created │    │Registered│
└─────────┘    └─────────┘    └─────────┘
```

### Combat Event Flow

```
┌──────────────────────┐
│  Player Light Attack │
│   on Enemy Target    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ ESO fires            │
│ EVENT_COMBAT_EVENT   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ OnCombatEvent()      │
│ receives 20+ params  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐     ┌──────────────────────┐
│ Guard Clauses:       │ No  │ Event Ignored        │
│ - enabled?           │────►│ (early return)       │
│ - sourceUnitTag?     │     └──────────────────────┘
│ - is light attack?   │
└──────────┬───────────┘
           │ Yes
           ▼
┌──────────────────────┐
│ IncrementStacks()    │
│ currentStacks++      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐     ┌──────────────────────┐
│ stacks >= 5?         │ Yes │ OnProcTriggered()    │
│                      │────►│ (set procced!)       │
└──────────┬───────────┘     └──────────────────────┘
           │ No
           ▼
┌──────────────────────┐
│ UpdateUI()           │
│ - show display       │
│ - set label text     │
│ - apply color        │
└──────────────────────┘
```

### Target Change Flow

```
┌────────────────────────┐
│ Player switches target │
│ (looks at new enemy)   │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ ESO fires              │
│ RETICLE_TARGET_CHANGED │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ OnTargetChanged()      │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Save current target    │
│ stacks to cache:       │
│ enemyStacks[name] = {  │
│   stacks: N,           │
│   timestamp: now       │
│ }                      │
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│ Get new target name    │
│ via GetUnitName()      │
└───────────┬────────────┘
            │
    ┌───────┴───────┐
    ▼               ▼
┌────────┐     ┌────────┐
│ Target │     │   No   │
│ Found  │     │ Target │
└───┬────┘     └───┬────┘
    │              │
    ▼              ▼
┌────────────┐ ┌────────────┐
│ Load from  │ │ Clear      │
│ cache or 0 │ │ tracking   │
└───┬────────┘ └───┬────────┘
    │              │
    └───────┬──────┘
            │
            ▼
┌────────────────────────┐
│ UpdateUI()             │
└────────────────────────┘
```

---

## Data Structures

### Global State (KNC Table)

```
KNC = {
    ┌─────────────────────────────────────────────────┐
    │ SAVED VARIABLES (persisted)                     │
    │ ───────────────────────────────                 │
    │ variables = {                                   │
    │   enabled: boolean        -- Master toggle      │
    │   alwaysShow: boolean     -- Show at 0 stacks   │
    │   unlocked: boolean       -- Position unlocked  │
    │   size: number            -- 32-128 pixels      │
    │   positionLeft: number    -- X position         │
    │   positionTop: number     -- Y position         │
    │   debugMode: boolean      -- Verbose logging    │
    │ }                                               │
    └─────────────────────────────────────────────────┘
    
    ┌─────────────────────────────────────────────────┐
    │ RUNTIME STATE (transient)                       │
    │ ─────────────────────────                       │
    │ currentTarget: string|nil   -- Current enemy    │
    │ currentStacks: number       -- 0-5              │
    │ MAX_STACKS: 5               -- Constant         │
    │ KHALNAR_ABILITY_ID: 163598  -- Constant         │
    └─────────────────────────────────────────────────┘
    
    ┌─────────────────────────────────────────────────┐
    │ ENEMY CACHE (transient)                         │
    │ ───────────────────────                         │
    │ enemyStacks = {                                 │
    │   ["Enemy Name"] = {                            │
    │     stacks: number,        -- 0-5               │
    │     timestamp: number      -- ms since epoch    │
    │   },                                            │
    │   ...                                           │
    │ }                                               │
    └─────────────────────────────────────────────────┘
    
    ┌─────────────────────────────────────────────────┐
    │ UI ELEMENTS (created at init)                   │
    │ ─────────────────────────────                   │
    │ container: Control         -- TopLevelWindow    │
    │ texture: Control           -- CT_TEXTURE        │
    │ label: Control             -- CT_LABEL          │
    └─────────────────────────────────────────────────┘
    
    ┌─────────────────────────────────────────────────┐
    │ MODULES (namespaces)                            │
    │ ──────────────────                              │
    │ Tracking: table            -- Combat/stacks     │
    │ Interface: table           -- UI rendering      │
    │ Settings: table            -- LAM integration   │
    └─────────────────────────────────────────────────┘
}
```

### Enemy Stack Cache Entry

```
enemyStacks["Mudcrab"] = {
    stacks = 3,                    -- Current stack count
    timestamp = 1234567890123      -- GetGameTimeMilliseconds()
}
```

**Cache Lifecycle:**
1. **Created** when switching away from a target
2. **Updated** timestamp on each stack increment
3. **Read** when switching to a previously-seen target
4. **Deleted** after 5 minutes of inactivity (cleanup)

---

## UI Hierarchy

```
GuiRoot (ESO Root)
│
└── KNCContainer (TopLevelWindow)
    │   - Dimensions: size x size (default 64x64)
    │   - Movable: when unlocked
    │   - Clamped to screen
    │
    ├── KNC_Texture (CT_TEXTURE)
    │   │   - Anchor: TOPLEFT to container
    │   │   - Dimensions: size x size
    │   │   - Texture: khalnar_icon.dds
    │   │   - Color: varies by stack count
    │   │
    │   └── Draw Level: 1
    │
    └── KNC_Label (CT_LABEL)
        │   - Anchor: CENTER to container
        │   - Font: ZoFontWinH4
        │   - Text: "0" to "5"
        │   - Color: white
        │
        └── Draw Level: 2 (above texture)
```

### Color Coding

```
Stacks:  0      1-2     3-4     5
         │       │       │       │
         ▼       ▼       ▼       ▼
       Hidden  Green  Yellow   Red
               (0,1,0) (1,1,0) (1,0,0)
               
         │       │       │       │
         ▼       ▼       ▼       ▼
       [---]   [  1  ] [  4  ] [  5  ]
                 │       │       │
              Building Almost  Proc!
```

---

## Settings Panel Structure

```
┌─────────────────────────────────────────────────────┐
│ Settings > Addons > Khalnar's Nightmare Tracker    │
├─────────────────────────────────────────────────────┤
│                                                     │
│ ═══════════════════════════════════════════════    │
│ General Settings                                    │
│ ═══════════════════════════════════════════════    │
│                                                     │
│ [✓] Enable Addon                                   │
│     Master toggle for the addon                    │
│                                                     │
│ [ ] Always Show Display                            │
│     Show tracker at 0 stacks                       │
│                                                     │
│ ═══════════════════════════════════════════════    │
│ Display Settings                                    │
│ ═══════════════════════════════════════════════    │
│                                                     │
│ [✓] Lock Position                                  │
│     Prevent dragging                               │
│                                                     │
│ [Reset Position]                                   │
│                                                     │
│ Display Size: [────●─────] 64                      │
│               32        128                         │
│                                                     │
│ ═══════════════════════════════════════════════    │
│ Debug                                               │
│ ═══════════════════════════════════════════════    │
│                                                     │
│ [ ] Debug Mode                                     │
│     Enable verbose logging                         │
│                                                     │
│ ═══════════════════════════════════════════════    │
│ About                                               │
│ ═══════════════════════════════════════════════    │
│                                                     │
│ Khalnar's Nightmare Tracker monitors your light   │
│ attacks and displays the current bone stack...     │
│                                                     │
│ Slash Commands:                                    │
│ /knc - Show status                                 │
│ /knc toggle - Enable/disable                       │
│ /knc reset - Reset stacks                          │
│ /knc debug - Toggle debug mode                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Performance Considerations

### Event Filtering Strategy

```
EVENT_COMBAT_EVENT (high frequency)
         │
         ▼
    ┌────────────┐
    │ enabled?   │ ─ No ─► return (fast path)
    └────┬───────┘
         │ Yes
         ▼
    ┌────────────┐
    │ player?    │ ─ No ─► return (fast path)
    └────┬───────┘
         │ Yes
         ▼
    ┌────────────┐
    │ light atk? │ ─ No ─► return (fast path)
    └────┬───────┘
         │ Yes
         ▼
    [Heavy processing only for actual light attacks]
```

### Memory Management

```
┌──────────────────────────────────────────────┐
│ enemyStacks cache                            │
│                                              │
│ Entry added ──────► Timestamp recorded       │
│                            │                 │
│                     30 sec │ (cleanup runs)  │
│                            ▼                 │
│              ┌───────────────────────┐       │
│              │ Entry age > 5 min?   │       │
│              └───────────┬───────────┘       │
│                          │                   │
│                 Yes      │      No           │
│                  │       │       │           │
│                  ▼       │       ▼           │
│            Delete entry  │  Keep entry       │
│                          │                   │
└──────────────────────────┴───────────────────┘
```

---

## Extension Points

### Where to Add New Features

| Feature | Module | Functions to Modify |
|---------|--------|---------------------|
| Sound on proc | Tracking.lua | `OnProcTriggered()` |
| Animation | Interface.lua | `UpdateUI()` |
| New setting | Settings.lua | `CreateOptionsData()` + Main.lua defaults |
| New slash cmd | Main.lua | `SlashCommand()` |
| New event | Tracking.lua | `Initialize()` + new handler |
| Custom texture | Interface.lua | `TEXTURE_PATH` constant |

### Hook Pattern

```lua
-- Safe extension pattern
local originalFunction = KNC.Tracking.OnProcTriggered

KNC.Tracking.OnProcTriggered = function()
    -- Call original
    originalFunction()
    
    -- Add custom behavior
    PlaySound(SOUNDS.ABILITY_ULTIMATE_READY)
end
```

---

## File Quick Reference

| File | Lines | Purpose |
|------|-------|---------|
| Main.lua | ~150 | Entry, init, slash commands |
| Tracking.lua | ~280 | Events, stacks, targets |
| Interface.lua | ~180 | UI, display, colors |
| Settings.lua | ~200 | LAM panel, controls |
| Defaults.lua | ~50 | Default configuration |

---

*Last Updated: Version 1.0.0*
