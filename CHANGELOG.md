# Changelog

All notable changes to Khalnar's Nightmare Tracker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-XX-XX

### Added

#### Core Features
- **Stack Tracking**: Real-time tracking of Khalnar's Nightmare bone stacks (0-5)
- **Light Attack Detection**: Automatic detection of player light attacks via combat events
- **Per-Enemy Tracking**: Maintains stack count separately for each enemy
- **Target Switch Support**: Preserves and restores stacks when switching between enemies

#### User Interface
- **Visual Indicator**: Icon-based display showing current stack count
- **Color-Coded Display**: 
  - Green (1-2 stacks) - Building
  - Yellow (3-4 stacks) - Almost ready
  - Red (5 stacks) - Set procced!
- **Movable Position**: Drag and drop to reposition the display
- **Configurable Size**: Adjustable icon size (32px to 128px)
- **Show/Hide Logic**: Automatically shows when stacks > 0

#### Settings Panel
- **LibAddonMenu Integration**: Full settings panel in ESO options
- **Enable Toggle**: Master on/off switch
- **Always Show Option**: Keep display visible at 0 stacks
- **Position Lock**: Lock/unlock display position
- **Reset Position Button**: Return display to default location
- **Size Slider**: Adjust display dimensions
- **Debug Mode Toggle**: Enable verbose logging

#### Slash Commands
- `/knc` - Show addon status
- `/knc toggle` - Enable/disable addon
- `/knc reset` - Reset stack count
- `/knc debug` - Toggle debug logging

#### Technical Features
- **Event-Based Architecture**: Efficient event-driven design
- **Account-Wide Settings**: Settings persist across characters
- **Memory Management**: Automatic cleanup of stale enemy data (5-minute expiry)
- **Effect Synchronization**: Syncs with game effect system for accuracy

### Dependencies
- LibAddonMenu-2.0 (v30 or higher)

### API Support
- ESO API 101044
- ESO API 101045

---

## Known Issues

### Version 1.0.0

1. **Placeholder Ability ID**
   - The Khalnar's Nightmare ability ID (`163598`) is a placeholder
   - May need adjustment based on actual game data
   - Tracking relies primarily on light attack detection

2. **Missing Texture Asset**
   - `textures/khalnar_icon.dds` needs to be created
   - Currently may show default/missing texture

3. **Settings Panel Registration**
   - Panel metadata not fully registered
   - Settings controls may not appear in addon menu

4. **Target Name Collisions**
   - Enemies with identical names share stack tracking
   - Could affect accuracy with multiple same-named enemies

5. **No Sound Notifications**
   - No audio feedback when set procs
   - Planned for future release

---

## Planned Features

### Version 1.1.0 (Planned)

- [ ] Sound notification on proc
- [ ] Custom texture support
- [ ] Opacity/transparency setting
- [ ] Animation effects at 5 stacks
- [ ] Combat-only mode (auto-hide out of combat)

### Version 1.2.0 (Planned)

- [ ] Multiple set support
- [ ] Proc history/statistics
- [ ] Export settings to string
- [ ] Keybind support
- [ ] Localization (German, French, etc.)

---

## Version History Summary

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2024-XX-XX | Initial release |

---

## Upgrade Notes

### Upgrading from Pre-Release to 1.0.0

If you were using a development version:

1. Delete the old addon folder
2. Install version 1.0.0 fresh
3. Your settings will be preserved in SavedVariables
4. Run `/reloadui` to ensure clean load

---

## Credits

### Development

This addon was built by studying and learning from these excellent reference addons:

- **GrimFocusCounter** - UI patterns and stack visualization
- **Srendarr** - Buff/debuff tracking methodology
- **SquishyAutoMarker** - Target tracking patterns

### Libraries

- **LibAddonMenu-2.0** - Settings panel framework

### Contributors

- **YourName** - Original author

---

## Support

- **Bug Reports**: Please include version number and debug output
- **Feature Requests**: Welcome! Describe your use case
- **Questions**: Check the FAQ in README.md first

---

*For detailed technical changes, see commit history.*
