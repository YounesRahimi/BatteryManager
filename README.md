# Battery Manager

An AutoHotkey script that automatically manages your laptop's power settings based on whether it's plugged in or running on battery. It helps extend battery life by automatically switching power plans, adjusting visual effects, controlling screen brightness, and optionally closing power-hungry applications when unplugged.

## Features

- **Automatic Power Plan Switching**: Switches between Balanced and Battery Saver power plans when AC adapter is connected or disconnected
- **Visual Effects Management**: Adjusts Windows visual effects for better performance on battery
- **Screen Brightness Control**: Reduces screen brightness to 30% on battery, restores to 100% when plugged in
- **Application Management**: Optionally closes specified applications when switching to battery mode
- **System Tray Integration**: Provides a system tray icon with menu options
- **Hotkey Support**: Toggle between power modes using Ctrl+Alt+B
- **Logging**: Logs all activities to a log file for troubleshooting
- **Configurable**: Customize which applications to close via configuration file

## Installation

1. Install [AutoHotkey](https://www.autohotkey.com/) if you don't have it already
2. Download or clone this repository
3. Double-click on `BatteryManager.ahk` to run the script
4. (Optional) Add the script to your Windows startup folder to run it automatically when Windows starts

## Usage

Once running, Battery Manager will automatically:
- Switch to Battery Saver mode when your laptop is unplugged
- Switch to Balanced mode when your laptop is plugged in
- Show a notification when power mode changes
- Display an icon in the system tray indicating the current power mode

### System Tray Menu

Right-click on the Battery Manager icon in the system tray to access these options:
- **Toggle Mode (Ctrl+Alt+B)**: Manually switch between Balanced and Battery Saver modes
- **Exit**: Close the Battery Manager application

### Hotkeys

- **Ctrl+Alt+B**: Toggle between Balanced and Battery Saver modes

## Configuration

You can customize which applications to close when switching to battery mode by editing the `BatteryManager.ini` file:

```ini
[Settings]
appsToClose=notepad.exe,Photos.exe,Docker Desktop.exe,WhatsApp.exe,Code.exe,Mattermost.exe,Taskmgr.exe
```

Add or remove application executable names from the comma-separated list.

## How It Works

Battery Manager:
1. Monitors your laptop's power status (AC vs Battery)
2. When unplugged, it:
   - Switches to the Battery Saver power plan
   - Reduces visual effects for better performance
   - Dims the screen to 30% brightness
   - Closes specified applications (only once per session)
3. When plugged in, it:
   - Switches to the Balanced power plan
   - Restores normal visual effects
   - Restores screen brightness to 100%

## Requirements

- Windows 10 or 11
- AutoHotkey v1.1 or later
- Administrator privileges (for changing power plans)

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
