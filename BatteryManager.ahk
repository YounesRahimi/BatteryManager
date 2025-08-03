#Persistent
#SingleInstance Force
#NoEnv

; Embed icons in the executable
FileInstall, Balanced.ico, %A_Temp%\Balanced.ico, 1
FileInstall, BatterySaver.ico, %A_Temp%\BatterySaver.ico, 1

SetTimer, MonitorPower, 2000  ; Check every 2 seconds

; === CONFIG ===
hotkeyToggle := "^!b"
lowBatteryThreshold := 20
debounceTimeMs := 5000
logFile := A_ScriptDir "\BatteryManager.log"
lastPowerState := ""
lastChangeTime := 0
isSaver := false

; Read apps and settings from config file
configFile := A_ScriptDir . "\BatteryManager.ini"  ; Use dot for concatenation
appsToClose := ReadAppsFromConfig(configFile)
closedAppsOnce := false

; configSettings is now populated by ReadAppsFromConfig with:
; - configSettings.appsToClose: List of apps to close
; - configSettings.batteryBrightness: Screen brightness in battery saver mode
; - configSettings.enableOptimization: Flag to control performance optimization


; Function to check if app is set to start with Windows
IsStartupEnabled() {
    RegRead, startupPath, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, BatteryManager
    return (startupPath != "")
}

; Function to toggle startup status
ToggleStartup() {
    global silentStartup
    
    if (IsStartupEnabled()) {
        ; Remove from startup
        RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, BatteryManager
        Menu, Tray, Rename, Don't Start at Login, Start at login
        
        ; Only show notification if not in silent mode
        if (!silentStartup) {
            TrayTip, Battery Manager, Will not start automatically with Windows., 3, 1
        }
        
        Log("Removed from Windows startup")
    } else {
        ; Add to startup
        RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, BatteryManager, %A_ScriptFullPath%
        Menu, Tray, Rename, Start at login, Don't Start at Login
        
        ; Only show notification if not in silent mode
        if (!silentStartup) {
            TrayTip, Battery Manager, Will start automatically with Windows., 3, 1
        }
        
        Log("Added to Windows startup")
    }
    
    ; Ensure future actions aren't silent
    silentStartup := false
}

; === TRAY MENU ===
Menu, Tray, NoStandard  ; Remove standard menu items
Menu, Tray, Tip, Battery Manager
Menu, Tray, Add, Toggle Mode (Ctrl+Alt+B), ToggleMode
; Add startup menu item with appropriate initial text
if (IsStartupEnabled()) {
    Menu, Tray, Add, Don't Start at Login, ToggleStartup
} else {
    Menu, Tray, Add, Start at login, ToggleStartup
}
Menu, Tray, Add, Exit, ExitApp
Menu, Tray, Default, Toggle Mode (Ctrl+Alt+B)
Menu, Tray, Click, 1
; Menu, Tray, Show  ; Removed to start silently

; === GLOBAL HOTKEY ===
Hotkey, %hotkeyToggle%, ToggleMode

; Silent startup mode flag
silentStartup := true  ; Set to true to prevent notifications on initial startup

Log(msg) {
    global logFile
    FormatTime, timestamp, , yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] %msg%`n, %logFile%
}

ReadAppsFromConfig(configFilePath) {
    ; Default apps in case config file doesn't exist or is invalid
    defaultApps := ["notepad.exe", "Photos.exe", "Docker Desktop.exe", "WhatsApp.exe", "Code.exe", "Mattermost.exe", "Taskmgr.exe", "BingWallpaper.exe", "BingWallpaper.exe"]
    defaultBrightness := 30
    defaultEnableOptimization := 1
    
    ; Create a global object to store all config
    global configSettings := {}
    configSettings.appsToClose := defaultApps
    configSettings.batteryBrightness := defaultBrightness
    configSettings.enableOptimization := defaultEnableOptimization
    
    ; Check if config file exists
    if (!FileExist(configFilePath)) {
        ; First attempt: Try to create the directory if it doesn't exist
        SplitPath, configFilePath,, dirPath
        if (dirPath != "" && !InStr(FileExist(dirPath), "D")) {
            FileCreateDir, %dirPath%
            Log("Created directory: " . dirPath)
        }
        
        ; Try using FileOpen (more robust method)
        try {
            file := FileOpen(configFilePath, "w")
            if (file) {
                file.WriteLine("[Settings]")
                file.WriteLine("appsToClose=notepad.exe,Photos.exe,Docker Desktop.exe,WhatsApp.exe,Code.exe,Mattermost.exe,Taskmgr.exe,BingWallpaper.exe,filezilla.exe")
                file.WriteLine("batteryBrightness=30")
                file.WriteLine("enableOptimization=1")
                file.Close()
                Log("Config file created successfully at: " . configFilePath)
            } else {
                Log("Failed to open config file for writing: " . configFilePath . " (Error: " . A_LastError . ")")
                
                ; Fallback: Try to create in user's temp directory
                tempConfigPath := A_Temp . "\BatteryManager.ini"
                Log("Attempting to create config in temp directory: " . tempConfigPath)
                
                tempFile := FileOpen(tempConfigPath, "w")
                if (tempFile) {
                    tempFile.WriteLine("[Settings]")
                    tempFile.WriteLine("appsToClose=notepad.exe,Photos.exe,Docker Desktop.exe,WhatsApp.exe,Code.exe,Mattermost.exe,Taskmgr.exe,BingWallpaper.exe,filezilla.exe")
                    tempFile.WriteLine("batteryBrightness=30")
                    tempFile.WriteLine("enableOptimization=1")
                    tempFile.Close()
                    Log("Created temporary config file at: " . tempConfigPath)
                    
                    ; Return the path to the successful file
                    configFilePath := tempConfigPath
                } else {
                    Log("Failed to create even in temp directory. Error: " . A_LastError)
                }
            }
        } catch e {
            Log("Exception when creating config file: " . e.message)
            return defaultApps
        }
        
    }
    
    ; Read apps from config
    IniRead, appsStr, %configFilePath%, Settings, appsToClose, ""
    
    ; If nothing was read or section is missing, return defaults
    if (appsStr = "" || appsStr = "ERROR") {
        Log("No apps found in config file. Using defaults.")
        return defaultApps
    }
    
    ; Parse comma-separated list into array
    appsList := []
    Loop, Parse, appsStr, `,, %A_Space%
    {
        appsList.Push(A_LoopField)
    }
    
    ; If we got an empty array, return defaults
    if (appsList.Length() = 0) {
        Log("Empty apps list in config file. Using defaults.")
        return defaultApps
    }
    
    ; Read brightness setting (30% is default if not found)
    IniRead, brightness, %configFilePath%, Settings, batteryBrightness, %defaultBrightness%
    configSettings.batteryBrightness := brightness
    
    ; Read optimization flag (1 = enabled by default)
    IniRead, enableOpt, %configFilePath%, Settings, enableOptimization, %defaultEnableOptimization%
    configSettings.enableOptimization := enableOpt
    
    Log("Loaded " . appsList.Length() . " apps to close from config file.")
    Log("Loaded brightness setting: " . brightness . "% and optimization flag: " . enableOpt)
    
    configSettings.appsToClose := appsList
    return appsList
}

ToggleMode() {
    global isSaver
    if (isSaver) {
        SetBalanced()
    } else {
        SetBatterySaver()
    }
}

CloseAppGracefully(app) {
    ; Try graceful close by sending WM_CLOSE to windows
    SplitPath, app,,, ext, name
    WinClose, ahk_exe %app%
    Sleep, 2000
    ; If still running, force close
    Process, Exist, %app%
    if (ErrorLevel) {
        Process, Close, %app%
        Log("Forced closed " app)
    } else {
        Log("Closed " app " gracefully")
    }
}

; === Add inside SetBatterySaver() ===
SetBatterySaver() {
    global isSaver, closedAppsOnce, appsToClose, configSettings, silentStartup
    RunWait, %ComSpec% /c powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a, , Hide
    
    ; Only show TrayTip if not in silent startup mode
    if (!silentStartup) {
        TrayTip, Battery Manager, Battery Saver activated., 3, 1
    }
    
    Menu, Tray, Icon, %A_Temp%\BatterySaver.ico
    Log("Switched to Battery Saver plan")
    isSaver := true

    ; Switch Windows visual effects to "Adjust for best performance" if optimization is enabled
    if (configSettings.enableOptimization) {
        SetVisualPerformance("best")
    }

    ; Dim screen to configured brightness level
    brightness := configSettings.batteryBrightness
    SetBrightness(brightness)
    Log("Reduced screen brightness to " . brightness . "%")

    ; Close apps only the first time
    if (!closedAppsOnce) {
        for index, app in appsToClose {
            CloseAppGracefully(app)
        }
        closedAppsOnce := true
    }
    
    ; Reset silent startup flag after first mode change
    silentStartup := false
}

; === Add inside SetBalanced() ===
SetBalanced() {
    global isSaver, configSettings, silentStartup
    RunWait, %ComSpec% /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e, , Hide
    
    ; Only show TrayTip if not in silent startup mode
    if (!silentStartup) {
        TrayTip, Battery Manager, Balanced plan activated., 3, 1
    }
    
    Menu, Tray, Icon, %A_Temp%\Balanced.ico
    Log("Switched to Balanced plan")
    isSaver := false

    ; Restore to "Let Windows choose what's best" if optimization was enabled
    if (configSettings.enableOptimization) {
        SetVisualPerformance("auto")
    }
    
    ; Restore normal brightness (100%)
    SetBrightness(100)
    Log("Restored normal screen brightness")
    
    ; Reset silent startup flag after first mode change
    silentStartup := false
}

; === Helper function ===

SetVisualPerformance(mode) {
    global silentStartup
    ; Open the Performance Options dialog
    if (!silentStartup) {
     Run, C:\Windows\System32\SystemPropertiesPerformance.exe
    }

    ; TODO open the C:\Windows\System32\SystemPropertiesPerformance.exe
    if (mode = "best") {
        ; TODO click on  "Adjust for best performance" radio button

        Log("Visual Effects set to Best Performance with all animations disabled")
    } else {
        ; Restore visual effects
        ; TODO click on  "Let Windows choose what's best for my computer"  radio button
        Log("Visual Effects reset to Windows defaults (Auto) with animations enabled")
    }

        ; TODO click on  "Apply"  and then "OK" buttons.
}

MonitorPower:
    ; Get current power state
    powerLineStatus := GetPowerStatus()
    currentTime := A_TickCount

    ; Debounce flap
    If (powerLineStatus != lastPowerState && (currentTime - lastChangeTime > debounceTimeMs)) {
        lastPowerState := powerLineStatus
        lastChangeTime := currentTime

        if (powerLineStatus == "Battery") {
            SetBatterySaver()
        } else if (powerLineStatus == "AC") {
            SetBalanced()
        }
    }

    ; Check battery level
    batt := GetBatteryLevel()
    if (powerLineStatus == "Battery" && batt < lowBatteryThreshold) {
        ; Do Nothing for now
    }
Return

GetPowerStatus() {
    VarSetCapacity(SYSTEM_POWER_STATUS, 12, 0)
    DllCall("kernel32.dll\GetSystemPowerStatus", "UInt", &SYSTEM_POWER_STATUS)
    return NumGet(SYSTEM_POWER_STATUS, 0, "UChar") == 1 ? "AC" : "Battery"
}

GetBatteryLevel() {
    VarSetCapacity(SYSTEM_POWER_STATUS, 12, 0)
    DllCall("kernel32.dll\GetSystemPowerStatus", "UInt", &SYSTEM_POWER_STATUS)
    Return NumGet(SYSTEM_POWER_STATUS, 1, "UChar")  ; Battery Life Percent
}

SetBrightness(brightness) {
    ; brightness should be between 0 and 100
    if (brightness < 0)
        brightness := a0
    if (brightness > 100)
        brightness := 100
        
    for i, device in GetMonitors() {
        brightness_value := brightness
        
        ; WmiMonitorBrightnessMethods class to set brightness
        service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
        monitors := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=TRUE")
        
        for monitor in monitors {
            monitor.WmiSetBrightness(1, brightness_value)
            Log("Set brightness to " . brightness_value . "% on monitor " . i)
        }
    }
}

GetMonitors() {
    monitors := []
    service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
    monitorInfo := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBasicDisplayParams WHERE Active=TRUE")
    
    for monitor in monitorInfo {
        monitors.Push(monitor)
    }
    
    return monitors
}


; === Add this to your script top (OnExit handler) ===
OnExit, RestoreDefaults

; === Existing functions remain, just add this one ===
RestoreDefaults:
    Log("Exiting tool, restoring defaults...")
    ; Switch back to Balanced plan
    RunWait, %ComSpec% /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e, , Hide
    ; Restore Visual Effects to Let Windows choose if optimization was enabled
    if (configSettings.enableOptimization) {
        SetVisualPerformance("auto")
    }
    ; Restore normal brightness
    SetBrightness(100)
    ExitApp
return

ExitApp:
    Log("Battery Manager exited")
    ExitApp
