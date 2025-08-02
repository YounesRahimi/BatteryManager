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

; Read apps to close from config file
configFile := A_ScriptDir . "\BatteryManager.ini"  ; Use dot for concatenation
appsToClose := ReadAppsFromConfig(configFile)
closedAppsOnce := false


; === TRAY MENU ===
Menu, Tray, Tip, Battery Manager
Menu, Tray, Add, Toggle Mode (Ctrl+Alt+B), ToggleMode
Menu, Tray, Add, Exit, ExitApp
Menu, Tray, Default, Toggle Mode (Ctrl+Alt+B)
Menu, Tray, Click, 1
Menu, Tray, Show

; === GLOBAL HOTKEY ===
Hotkey, %hotkeyToggle%, ToggleMode

Log(msg) {
    global logFile
    FormatTime, timestamp, , yyyy-MM-dd HH:mm:ss
    FileAppend, [%timestamp%] %msg%`n, %logFile%
}

ReadAppsFromConfig(configFilePath) {
    ; Default apps in case config file doesn't exist or is invalid
    defaultApps := ["notepad.exe", "Photos.exe", "Docker Desktop.exe", "WhatsApp.exe", "Code.exe", "Mattermost.exe", "Taskmgr.exe"]
    
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
                file.WriteLine("appsToClose=notepad.exe,Photos.exe,Docker Desktop.exe,WhatsApp.exe,Code.exe,Mattermost.exe,Taskmgr.exe")
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
                    tempFile.WriteLine("appsToClose=notepad.exe,Photos.exe,Docker Desktop.exe,WhatsApp.exe,Code.exe,Mattermost.exe,Taskmgr.exe")
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
    
    Log("Loaded " . appsList.Length() . " apps to close from config file.")
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
    global isSaver, closedAppsOnce, appsToClose
    RunWait, %ComSpec% /c powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a, , Hide
    TrayTip, Battery Manager, Battery Saver activated., 3, 1
    Menu, Tray, Icon, %A_Temp%\BatterySaver.ico
    Log("Switched to Battery Saver plan")
    isSaver := true

    ; Switch Windows visual effects to "Adjust for best performance"
;    ApplyPerformanceProfile("best")
    SetVisualPerformance("best")

    ; Dim screen to 30% brightness
    SetBrightness(30)
    Log("Reduced screen brightness to 30%")

    ; Close apps only the first time
    if (!closedAppsOnce) {
        for index, app in appsToClose {
            CloseAppGracefully(app)
        }
        closedAppsOnce := true
    }


}

; === Add inside SetBalanced() ===
SetBalanced() {
    global isSaver
    RunWait, %ComSpec% /c powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e, , Hide
    TrayTip, Battery Manager, Balanced plan activated., 3, 1
    Menu, Tray, Icon, %A_Temp%\Balanced.ico
    Log("Switched to Balanced plan")
    isSaver := false

    ; Restore to "Let Windows choose what's best"
;    ApplyPerformanceProfile("auto")
    SetVisualPerformance("auto")
    
    ; Restore normal brightness (100%)
    SetBrightness(100)
    Log("Restored normal screen brightness")
}

; === Helper function ===

SetVisualPerformance(mode) {
    if (mode = "best") {
        ; Same best performance settings as before
        DllCall("SystemParametersInfo", "UInt", 0x0048, "UInt", 0, "UInt", 0, "UInt", 3)   ; SPI_SETDRAGFULLWINDOWS
        DllCall("SystemParametersInfo", "UInt", 0x1003, "UInt", 0, "UInt", 0, "UInt", 3)   ; SPI_SETANIMATION
        DllCall("SystemParametersInfo", "UInt", 0x0025, "UInt", 0, "UInt", 0, "UInt", 3)   ; SPI_SETMENUSHOWDELAY
        DllCall("SystemParametersInfo", "UInt", 0x101B, "UInt", 0, "UInt", 0, "UInt", 3)   ; SPI_SETCURSORSHADOW
        DllCall("SystemParametersInfo", "UInt", 0x004B, "UInt", 0, "UInt", 0, "UInt", 3)   ; SPI_SETFONTSMOOTHING

        RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects, VisualFXSetting, 2
        RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\DWM, EnablePeek, 0
        RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\DWM, AlwaysHibernateThumbnails, 0

        DllCall("user32\SendMessageTimeout", "UInt", 0xFFFF, "UInt", 0x001A, "UInt", 0, "UInt", 0, "UInt", 2, "UInt", 5000, "UInt*", 0)

        Log("Visual Effects set to Best Performance via direct API calls")
    } else {
        ; Restore visual effects

        ; SPI_SETDRAGFULLWINDOWS = 0x0025 (hex) or 37 (decimal)
        ; Second parameter: 1 = enable, 0 = disable
        ; "Show window contents while dragging" setting
        DllCall("SystemParametersInfo", "UInt", 0x0025, "UInt", 1, "UInt", 0, "UInt", 3)

        ; Additional visual effects
        DllCall("SystemParametersInfo", "UInt", 0x1003, "UInt", 1, "UInt", 0, "UInt", 3)   ; SPI_SETANIMATION = 1
        DllCall("SystemParametersInfo", "UInt", 0x0049, "UInt", 400, "UInt", 0, "UInt", 3) ; SPI_SETMENUSHOWDELAY = 400ms
        DllCall("SystemParametersInfo", "UInt", 0x101B, "UInt", 1, "UInt", 0, "UInt", 3)   ; SPI_SETCURSORSHADOW = 1
        DllCall("SystemParametersInfo", "UInt", 0x004B, "UInt", 1, "UInt", 0, "UInt", 3)   ; SPI_SETFONTSMOOTHING = 1

        ; Set visual effects mode to "Let Windows choose"
        RegWrite, REG_DWORD, HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects, VisualFXSetting, 0

        ; Additional registry setting for window dragging
        RegWrite, REG_SZ, HKCU\Control Panel\Desktop, DragFullWindows, 1

        ; Refresh the desktop
        DllCall("user32\SendMessageTimeout", "UInt", 0xFFFF, "UInt", 0x001A, "UInt", 0, "UInt", 0, "UInt", 2, "UInt", 5000, "UInt*", 0)

        Log("Visual Effects reset to Windows defaults (Auto) via direct API calls")

    }
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
    ; Restore Visual Effects to Let Windows choose
;    ApplyPerformanceProfile("auto")
    SetVisualPerformance("auto")
    ; Restore normal brightness
    SetBrightness(100)
    ExitApp
return

ExitApp:
    Log("Battery Manager exited")
    ExitApp
