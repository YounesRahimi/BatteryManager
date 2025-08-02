# Battery Manager - Release Notes

# Battery Manager v0.0.2 - Release Notes
## What's New
### 🔋 Improved Power Management
- Added automatic screen brightness control that adjusts based on power state
- Configurable brightness level when in battery saver mode via settings file

### ⚡ Performance Optimizations
- New visual performance settings that automatically optimize Windows for battery life
- Toggle between "Best Performance" and "Auto" visual settings when switching power modes

### 🛠️ Configuration Enhancements
- Added support for reading settings from INI configuration file
- Configurable options for:
    - Apps to automatically close when entering battery saver mode
    - Screen brightness level in battery saver mode
    - Enable/disable performance optimization features

### 🔄 Startup Integration
- Added ability to toggle automatic startup with Windows
- "Start at login" option available in the tray menu

### 📝 Improved Logging
- Enhanced logging system for better troubleshooting
- Timestamps added to all log entries

### 🖥️ Multi-Monitor Support
- Added support for brightness control across multiple monitors

### 🧹 Cleanup on Exit
- System settings are now properly restored when exiting the application

## Bug Fixes
- Fixed issue with power state detection
- Improved debouncing to prevent rapid switching between power modes
- More reliable app closing functionality

**Battery Manager** helps optimize your laptop's power usage by automatically switching between power plans, adjusting visual settings, and managing resource-intensive applications when on battery power.

---------------------

## Version 0.0.1 (Initial Release) - June 2023

We're excited to announce the first release of Battery Manager, a lightweight utility designed to optimize your laptop's power settings automatically.

### Overview
Battery Manager is an AutoHotkey script that intelligently manages your laptop's power settings based on whether it's plugged in or running on battery. It helps extend battery life by automatically switching power plans, adjusting visual effects, controlling screen brightness, and optionally closing power-hungry applications when unplugged.

### Key Features
- **Automatic Power Plan Switching**: Seamlessly switches between Balanced and Battery Saver power plans
- **Visual Effects Management**: Optimizes Windows visual effects for better performance on battery
- **Screen Brightness Control**: Automatically dims screen to 30% on battery, restores to 100% when plugged in
- **Application Management**: Optionally closes specified power-hungry applications when on battery
- **System Tray Integration**: Easy access via system tray icon with menu options
- **Hotkey Support**: Quick toggle between power modes using Ctrl+Alt+B
- **Configurable**: Customize which applications to close via simple configuration file

### Installation
1. Install [AutoHotkey](https://www.autohotkey.com/) if you don't have it already
2. Download the Battery Manager package
3. Double-click on `BatteryManager.ahk` to run the script
4. (Optional) Add to your Windows startup folder for automatic startup

### Requirements
- Windows 10 or 11
- AutoHotkey v1.1 or later
- Administrator privileges (for changing power plans)

### Known Limitations
- Currently only supports Windows operating systems
- Some laptops may have manufacturer-specific power management that could conflict
- Application closing feature only works for standard Windows applications

### What's Next
We're planning to add the following features in upcoming releases:
- Custom brightness levels for battery and AC modes
- More granular control over which visual effects to disable
- Battery level notifications
- Improved logging and diagnostics

### Feedback
This is our initial release and we welcome your feedback and suggestions for improvement.

---

Battery Manager is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
