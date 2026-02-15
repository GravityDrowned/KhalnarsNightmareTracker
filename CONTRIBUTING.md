# Contributing to Khalnar's Nightmare Tracker

Thank you for your interest in contributing to Khalnar's Nightmare Tracker! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment](#development-environment)
3. [Code Style Guidelines](#code-style-guidelines)
4. [Testing Changes](#testing-changes)
5. [Pull Request Process](#pull-request-process)
6. [Issue Reporting Guidelines](#issue-reporting-guidelines)
7. [Development Workflow](#development-workflow)

---

## Getting Started

### Prerequisites

- Elder Scrolls Online installed and working
- Text editor (VS Code, Sublime Text, etc.)
- Basic understanding of Lua programming
- Familiarity with ESO addon structure

### Quick Start

1. Fork the repository (if using GitHub)
2. Clone to your ESO addons folder:
   ```
   Documents/Elder Scrolls Online/live/AddOns/KhalnarsNightmareTracker/
   ```
3. Make your changes
4. Test in-game
5. Submit a pull request

---

## Development Environment

### Folder Structure

```
Documents/
└── Elder Scrolls Online/
    └── live/
        ├── AddOns/
        │   └── KhalnarsNightmareTracker/  <-- Your working copy
        │       ├── src/
        │       │   ├── Main.lua
        │       │   ├── Defaults.lua
        │       │   ├── Tracking.lua
        │       │   ├── Interface.lua
        │       │   └── Settings.lua
        │       ├── textures/
        │       ├── KhalnarsNightmareTracker.txt
        │       └── ...
        └── SavedVariables/
            └── KhalnarsNightmareVariables.lua  <-- Settings storage
```

### Required Tools

| Tool | Purpose | Required |
|------|---------|----------|
| ESO | Testing environment | Yes |
| Text Editor | Code editing | Yes |
| Git | Version control | Recommended |
| Lua Language Server | Linting/autocomplete | Optional |

### Recommended VS Code Extensions

- **Lua** by sumneko - Language support
- **ESO Lua** - ESO API autocomplete (if available)
- **GitLens** - Git integration

### Enabling Error Reporting

In ESO, enable the Lua error window:
1. Go to Settings > Gameplay > Interface
2. Enable "Show Lua Errors"

This will display any runtime errors from your changes.

---

## Code Style Guidelines

### General Principles

1. **Clarity over cleverness** - Write readable code
2. **Consistency** - Match existing code patterns
3. **Minimal scope** - Keep variables as local as possible
4. **Document complexity** - Comment non-obvious logic

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Global Table | UPPER_CASE prefix | `KNC` |
| Module | PascalCase | `KNC.Tracking` |
| Function | PascalCase | `KNC.Tracking.Initialize` |
| Local Variable | camelCase | `currentTarget` |
| Constant | UPPER_SNAKE_CASE | `MAX_STACKS` |
| Event Handler | OnEventName | `OnCombatEvent` |

### Code Examples

#### Good

```lua
-- Clear function with descriptive name
function KNC.Tracking.IncrementStacks(targetName)
    -- Guard clause for max stacks
    if KNC.currentStacks >= KNC.MAX_STACKS then 
        return 
    end
    
    KNC.currentStacks = KNC.currentStacks + 1
    
    -- Log if debug mode enabled
    if KNC.variables.debugMode then
        d("Stacks: " .. KNC.currentStacks)
    end
    
    KNC.Interface.UpdateUI()
end
```

#### Avoid

```lua
-- Unclear, no comments, magic numbers
function KNC.Tracking.Inc(t)
    if KNC.currentStacks < 5 then KNC.currentStacks = KNC.currentStacks + 1 if KNC.variables.debugMode then d("S:"..KNC.currentStacks) end KNC.Interface.UpdateUI() end
end
```

### Function Documentation

Use LuaDoc-style comments for public functions:

```lua
--- Increments the stack count for the current target.
-- Triggers a proc when reaching MAX_STACKS.
-- @param targetName string The name of the target enemy
-- @return nil
function KNC.Tracking.IncrementStacks(targetName)
    -- Implementation
end
```

### File Headers

Each Lua file should have a header comment:

```lua
-- Khalnar's Nightmare Tracker
-- [Module Name] - Brief description
-- 
-- Detailed description of module responsibility
```

### Indentation

- Use **spaces** (not tabs)
- **4 spaces** per indent level
- Align continuation lines

### Line Length

- Prefer lines under **100 characters**
- Break long lines at logical points

### Comments

```lua
-- Single line comment for brief notes

--[[
    Multi-line comment for longer explanations
    or temporary code blocks
]]

--- LuaDoc comment for function documentation
-- @param name type Description
-- @return type Description
```

---

## Testing Changes

### Basic Testing Workflow

1. **Save your changes**
2. **In ESO chat**, type `/reloadui`
3. **Test the feature** you modified
4. **Check for errors** in the Lua error window
5. **Enable debug mode**: `/knc debug`
6. **Watch chat** for debug output

### Testing Checklist

Before submitting changes, test:

- [ ] Addon loads without errors
- [ ] Stack tracking works correctly
- [ ] Target switching preserves stacks
- [ ] UI displays correctly
- [ ] Settings save and load
- [ ] Slash commands work
- [ ] No performance issues

### Debug Commands

```
/knc              -- Check addon status
/knc debug        -- Enable verbose logging
/knc reset        -- Reset stacks
/reloadui         -- Reload all addons
```

### Testing Scenarios

| Scenario | How to Test |
|----------|-------------|
| Light attack tracking | Attack a dummy, watch stack counter |
| Target switch | Switch between enemies, verify stack preservation |
| Set proc | Reach 5 stacks, verify proc handling |
| Settings | Change each setting, verify effect |
| Position | Drag display, reload UI, verify position saved |

### Simulating Combat

Use target dummies in:
- Housing (place a dummy)
- Guild halls
- Certain cities (Stormhaven, Elden Root, etc.)

---

## Pull Request Process

### Before Submitting

1. **Test thoroughly** - Ensure no regressions
2. **Update documentation** - If adding features
3. **Follow code style** - Match existing patterns
4. **Write clear commits** - Descriptive messages

### Commit Message Format

```
[Module] Brief description of change

Longer description if needed, explaining:
- Why the change was made
- Any important implementation details
- Breaking changes if any

Fixes #123 (if applicable)
```

**Examples:**

```
[Tracking] Add sound notification on proc

Added optional sound effect when 5 stacks are reached.
Configurable via new setting "Play Sound on Proc".

[Interface] Fix display not hiding when disabled

The container was not properly hidden when toggling
the addon off via /knc toggle.

Fixes #42
```

### Pull Request Template

When creating a PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing Done
- [ ] Tested in-game
- [ ] No Lua errors
- [ ] Debug mode tested
- [ ] Settings persistence verified

## Screenshots (if UI changes)
[Add screenshots here]

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No console errors
- [ ] Tested on multiple characters (if relevant)
```

### Review Process

1. Submit PR with description
2. Maintainer reviews code
3. Address any feedback
4. Maintainer merges when approved

---

## Issue Reporting Guidelines

### Before Reporting

1. **Check existing issues** - Avoid duplicates
2. **Try latest version** - Bug may be fixed
3. **Reproduce the issue** - Confirm it's consistent
4. **Gather information** - See template below

### Bug Report Template

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- ESO Version: [e.g., Update 42]
- Addon Version: [e.g., 1.0.0]
- Other Addons: [list any that might conflict]
- Platform: [PC/Mac]

## Debug Output
```
Paste debug mode output here
```

## Additional Context
Any other relevant information
```

### Feature Request Template

```markdown
## Feature Description
What feature would you like?

## Use Case
Why would this be useful?

## Proposed Solution
How might this work?

## Alternatives Considered
Other approaches you've thought of

## Additional Context
Any mockups, examples, or references
```

---

## Development Workflow

### Adding a New Feature

1. **Plan**: Define what the feature does
2. **Identify module**: Which file(s) to modify
3. **Add state**: If needed, add to `KNC` table
4. **Add SavedVariables**: If configurable
5. **Implement logic**: Core functionality
6. **Update UI**: If visible change
7. **Add settings**: If user-configurable
8. **Add slash command**: If CLI accessible
9. **Test**: Thorough testing
10. **Document**: Update docs

### Module Responsibilities

| Module | What Goes Here |
|--------|----------------|
| Main.lua | Initialization, slash commands |
| Tracking.lua | Combat events, stack logic |
| Interface.lua | UI elements, rendering |
| Settings.lua | LibAddonMenu integration |
| Defaults.lua | Default configuration values |

### Common Patterns

**Adding a new setting:**

```lua
-- 1. Add default in Main.lua SavedVariables
KNC.variables = ZO_SavedVars:NewAccountWide(..., {
    newSetting = false,  -- Add default
})

-- 2. Add control in Settings.lua
{
    type = "checkbox",
    name = "New Setting",
    tooltip = "Description",
    getFunc = function() return KNC.variables.newSetting end,
    setFunc = function(value) KNC.variables.newSetting = value end,
    default = false,
},

-- 3. Use in relevant module
if KNC.variables.newSetting then
    -- Feature code
end
```

**Adding an event handler:**

```lua
-- In Initialize function
EVENT_MANAGER:RegisterForEvent(
    "KNC_EventName",        -- Unique namespace
    EVENT_CONSTANT,         -- ESO event
    KNC.Module.OnEventName  -- Handler function
)

-- Handler function
function KNC.Module.OnEventName(eventCode, ...)
    if not KNC.variables.enabled then return end
    -- Handle event
end
```

---

## Resources

### ESO Addon Development

- [ESOUI Wiki](https://wiki.esoui.com/Main_Page) - API documentation
- [ESOUI Forums](https://www.esoui.com/forums/) - Community help
- [ESO API Reference](https://wiki.esoui.com/Category:API) - Function reference

### Lua Resources

- [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/)
- [Programming in Lua](https://www.lua.org/pil/) - Free book

### Libraries

- [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu.html) - Settings panels

---

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Look at similar code in the project
3. Open a discussion issue
4. Ask in ESOUI addon forums

---

*Thank you for contributing to Khalnar's Nightmare Tracker!*
