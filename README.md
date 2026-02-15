# Khalnar's Nightmare Tracker

[![ESO API Version](https://img.shields.io/badge/ESO%20API-101044%20%7C%20101045-blue)]()
[![Version](https://img.shields.io/badge/Version-1.0.0-green)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)]()

A lightweight Elder Scrolls Online addon that tracks the bone stack counter for the **Khalnar's Nightmare** monster set, helping you maximize your proc uptime and damage output.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Slash Commands](#slash-commands)
- [Settings](#settings)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Support](#support)
- [Credits](#credits)

---

## Overview

### What is Khalnar's Nightmare?

Khalnar's Nightmare is a monster set in Elder Scrolls Online that activates after performing **5 light attacks** on an enemy. Each light attack adds a "bone stack" to your target, and when you reach 5 stacks, the set procs with powerful bonus effects.

### Why Use This Addon?

Without a visual tracker, it's difficult to know:
- How many stacks you've built on your current target
- When the set is about to proc
- If your stacks reset when switching targets

**Khalnar's Nightmare Tracker** solves these problems by displaying a clear, color-coded visual indicator showing your current stack count.

```
+-------------------+
|                   |
|    [Icon: 3/5]    |  <-- Yellow = Getting Close!
|                   |
+-------------------+
```

---

## Features

- **Real-time Stack Tracking** - Monitors your light attacks and displays current bone stacks (0-5)
- **Color-Coded Display** - Visual feedback based on stack level:
  - Green (1-2 stacks): Building up
  - Yellow (3-4 stacks): Almost ready
  - Red (5 stacks): Set proc!
- **Per-Enemy Tracking** - Remembers stacks for each enemy when switching targets
- **Movable UI** - Position the display anywhere on your screen
- **Configurable Size** - Adjust display size from 32px to 128px
- **Always Show Option** - Keep the display visible even with 0 stacks
- **Debug Mode** - Detailed logging for troubleshooting
- **Minimal Performance Impact** - Efficient event-based tracking

---

## Installation

### Method 1: Manual Installation

1. Download the latest release
2. Extract the `KhalnarsNightmareTracker` folder
3. Copy the folder to your ESO addons directory:
   - **Windows**: `Documents\Elder Scrolls Online\live\AddOns\`
   - **Mac**: `~/Documents/Elder Scrolls Online/live/AddOns/`
4. Restart ESO or type `/reloadui` in chat

### Method 2: Minion (Addon Manager)

1. Open Minion
2. Search for "Khalnar's Nightmare Tracker"
3. Click Install
4. Restart ESO or type `/reloadui`

### Dependencies

This addon requires:
- **LibAddonMenu-2.0** (version 30 or higher) - For the settings panel

> **Note**: LibAddonMenu-2.0 is typically installed automatically by Minion or can be downloaded separately from ESOUI.

### Verifying Installation

1. Log into ESO
2. Open the Addon Manager (before character select)
3. Ensure "Khalnar's Nightmare Tracker" is checked
4. Ensure "LibAddonMenu-2.0" is also enabled

---

## Usage

### Basic Usage

1. **Equip the Khalnar's Nightmare monster set**
2. **Enter combat** with an enemy
3. **Perform light attacks** - the tracker will appear and count your stacks
4. **Watch the color change** as you approach 5 stacks
5. When the display turns **red**, your set has procced!

### Understanding the Display

| Stack Count | Color  | Meaning                    |
|-------------|--------|----------------------------|
| 0           | Hidden | No stacks (unless "Always Show" enabled) |
| 1-2         | Green  | Building stacks            |
| 3-4         | Yellow | Almost at proc threshold   |
| 5           | Red    | Set procced!               |

### Positioning the Display

1. Open Settings (ESC > Settings > Addons > Khalnar's Nightmare Tracker)
2. Check "Unlock Position"
3. Drag the display to your preferred location
4. Uncheck "Unlock Position" to lock it in place

---

## Slash Commands

All commands use the `/knc` prefix:

| Command        | Description                              | Example        |
|----------------|------------------------------------------|----------------|
| `/knc`         | Show addon status                        | `/knc`         |
| `/knc toggle`  | Enable/disable the addon                 | `/knc toggle`  |
| `/knc reset`   | Reset current stack count to 0           | `/knc reset`   |
| `/knc debug`   | Toggle debug mode for troubleshooting    | `/knc debug`   |

### Example Output

```
/knc
> Khalnar's Nightmare Tracker - Status: true

/knc toggle
> Khalnar's Nightmare Tracker - Enabled: false

/knc debug
> Khalnar's Nightmare Tracker - Debug Mode: true
```

---

## Settings

Access settings via: **ESC > Settings > Addons > Khalnar's Nightmare Tracker**

| Setting             | Type     | Default | Description                                           |
|---------------------|----------|---------|-------------------------------------------------------|
| Enable Addon        | Checkbox | On      | Master toggle for the addon                           |
| Always Show Display | Checkbox | Off     | Show the tracker even when you have 0 stacks          |
| Unlock Position     | Checkbox | Off     | Allow dragging the display to reposition it           |
| Reset Position      | Button   | -       | Reset display to center-bottom of screen              |
| Display Size        | Slider   | 64px    | Size of the tracker icon (32-128 pixels)              |
| Debug Mode          | Checkbox | Off     | Enable detailed logging to chat                       |

---

## FAQ

### How do I find the correct ability ID for Khalnar's Nightmare?

The addon uses ability ID `163598` as a placeholder. To find the actual ID:

1. Enable debug mode: `/knc debug`
2. Equip the set and enter combat
3. Watch chat for ability IDs when the set procs
4. Note: The correct ID may need to be updated in `src/Tracking.lua`

Alternatively, use an addon like **DebugInfo** or check UESP's ESO data files.

### Why isn't the tracker showing up?

Check the following:
1. Is the addon enabled? Type `/knc` to check status
2. Do you have the Khalnar's Nightmare set equipped?
3. Is "Always Show Display" disabled and you have 0 stacks?
4. Try `/reloadui` to refresh the UI

### The stack count seems incorrect. What's wrong?

The addon tracks light attacks via combat events. If the count seems off:
1. Enable debug mode (`/knc debug`) to see tracking logs
2. Check if you're switching targets frequently (stacks are per-enemy)
3. The set may have internal mechanics that differ from light attack counting

### Can I use this with other tracking addons?

Yes! Khalnar's Nightmare Tracker is designed to coexist with other addons like:
- Srendarr (buff/debuff tracking)
- Action Duration Reminder
- Buff Timers

### How do I reset the display position if it's off-screen?

1. Open Settings (ESC > Settings > Addons > Khalnar's Nightmare Tracker)
2. Click "Reset Position"
3. The display will return to screen center

### Does this work with all ESO game modes?

Yes, the addon works in:
- Overland/Questing
- Dungeons
- Trials
- PvP (Cyrodiil, Battlegrounds)
- Arenas

---

## Troubleshooting

### Common Issues

| Issue                          | Solution                                              |
|--------------------------------|-------------------------------------------------------|
| "LibAddonMenu-2.0 not found"   | Install LibAddonMenu-2.0 via Minion                   |
| Display stuck on screen        | Use `/knc reset` or disable "Always Show"             |
| No settings panel              | Ensure LibAddonMenu-2.0 is enabled and updated        |
| Stacks not counting            | Check if addon is enabled, verify set is equipped     |
| UI errors on login             | Try `/reloadui` or reinstall the addon                |

### Debug Mode

Enable debug mode to see detailed tracking information:

```
/knc debug
> Khalnar's Nightmare Tracker - Debug Mode: true
```

With debug mode enabled, you'll see messages like:
```
Khalnar's Nightmare - Stacks incremented for Mudcrab: 3/5
Khalnar's Nightmare - Stacks incremented for Mudcrab: 4/5
Khalnar's Nightmare - Stacks incremented for Mudcrab: 5/5
Khalnar's Nightmare - Set procced!
```

### Reporting Bugs

When reporting issues, please include:
1. ESO game version
2. Addon version (1.0.0)
3. Debug mode output (if applicable)
4. Steps to reproduce the issue
5. Any error messages from the UI error window

---

## Support

- **Bug Reports**: Open an issue on GitHub or comment on ESOUI
- **Feature Requests**: Welcome! Open an issue describing your idea
- **Questions**: Check the FAQ above or ask in the comments

---

## Credits

### Development

This addon was developed by analyzing and learning from these excellent ESO addons:

- **[GrimFocusCounter](https://www.esoui.com/)** - UI patterns and stack tracking logic
- **[Srendarr](https://www.esoui.com/downloads/info655-Srendarr-AuraBuffDebuffTracker.html)** - Debuff tracking and effect change patterns
- **[SquishyAutoMarker](https://www.esoui.com/)** - Target tracking and reticle change patterns

Thank you to all the addon developers who share their work with the ESO community!

### Libraries

- **LibAddonMenu-2.0** by Seerah, sirinsidiator, and others

### Special Thanks

- The ESO addon development community
- ESOUI.com for hosting addons
- ZeniMax Online Studios for the robust addon API

---

## License

This addon is released under the MIT License. See LICENSE file for details.

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

**Current Version**: 1.0.0

---

*Made with love for the Elder Scrolls Online community*
