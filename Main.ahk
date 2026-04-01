; Runner - AutoHotkey v2 Application Launcher
; Main Entry Point

#Requires AutoHotkey v2.0
#SingleInstance Force

; Include JSON Parser
#Include Core\JXON.ahk

; Include Core Libraries
#Include Core\HotkeyManager.ahk
#Include Core\SearchWindow.ahk
#Include Core\AppLauncher.ahk
#Include Core\PluginLoader.ahk
#Include Core\Plugin.ahk

; Include all plugins (required for PluginLoader to instantiate them)
#Include Plugins\TranslatePlugin.ahk
#Include Plugins\WindowPinPlugin.ahk
#Include Plugins\AutoClickerPlugin.ahk

; Global Config
global g_Config := Map()
global g_SearchWindow := ""
global g_HotkeyManager := ""
global g_SettingsGui := ""
global g_SettingsControls := Map()

Init()

Init() {
    LoadConfigs()

    ; Set Tray Icon
    if (g_Config["settings"].Has("icon")) {
        iconPath := g_Config["settings"]["icon"]
        if !InStr(iconPath, ":") ; Relative path
            iconPath := A_ScriptDir . "\" . iconPath

        if FileExist(iconPath) {
            TraySetIcon(iconPath)

        }
    }

    ; Init UI
    global g_SearchWindow := SearchWindow(g_Config)

    ; Init Hotkeys
    global g_HotkeyManager := HotkeyManager(g_Config["keymap"])
    g_HotkeyManager.RegisterHotkey("toggle_launcher", (*) => g_SearchWindow.Toggle())
    g_HotkeyManager.RegisterHotkey("reload", (*) => ReloadScript())
    g_HotkeyManager.RegisterHotkey("exit", (*) => ExitWithNotification())
    g_HotkeyManager.RegisterHotkey("open_settings", (*) => OpenSettings())

    ; Auto-discover and load all plugins
    PluginLoader.AutoLoadPlugins("Plugins", g_Config, g_HotkeyManager)

    ; Tray tip
    try {
        hotkey := g_Config["keymap"]["toggle_launcher"]
        TrayTip("Runner Started", "Press " . hotkey . " to launch", 1)
    } catch {
        TrayTip("Runner Started", "Ready to use", 1)
    }
}

LoadConfigs() {
    global g_Config

    g_Config := Map()

    LoadJSONToConfig("apps", "\Config\apps.json")
    LoadJSONToConfig("keymap", "\Config\keymap.json")
    LoadJSONToConfig("settings", "\Config\settings.json")
}

LoadJSONToConfig(name, relativePath) {
    global g_Config

    fullPath := A_ScriptDir . relativePath

    if !FileExist(fullPath) {
        return
    }

    try {
        text := FileRead(fullPath, "UTF-8")

        ; use JXON parser
        value := Jxon_Load(&text)

        g_Config[name] := value
    } catch as err {
        MsgBox("Failed to parse " . name . " (`n" fullPath "`n):`n" err.Message)
    }
}

ReloadScript() {
    Reload()
}

ExitWithNotification() {
    TrayTip("runner", "程序退出", 1)
    ExitApp()
}

OpenSettings() {
    global g_SettingsGui

    if (!g_SettingsGui || !WinExist("ahk_id " . g_SettingsGui.Hwnd)) {
        CreateSettingsGui()
    }

    LoadSettingsIntoGui()
    g_SettingsGui.Show("AutoSize Center")
}

CreateSettingsGui() {
    global g_SettingsGui, g_SettingsControls

    g_SettingsGui := Gui("+AlwaysOnTop", "Runner Settings")
    g_SettingsGui.SetFont("s10", "Microsoft YaHei UI")

    g_SettingsGui.AddText("xm ym w420", "Adjust settings and click Save")

    g_SettingsGui.AddGroupBox("xm y+10 w420 h95", "Window Transparency")
    g_SettingsGui.AddText("xm+12 yp+28", "Transparency:")
    transparencySlider := g_SettingsGui.AddSlider("x+10 yp-3 w250 Range0-255 ToolTip", 150)
    transparencyValue := g_SettingsGui.AddText("x+10 yp+3 w80", "150")
    transparencySlider.OnEvent("Change", (*) => transparencyValue.Value := transparencySlider.Value)

    g_SettingsGui.AddGroupBox("xm y+12 w420 h80", "Launcher Window")
    g_SettingsGui.AddText("xm+12 yp+30", "Width:")
    widthEdit := g_SettingsGui.AddEdit("x+10 yp-3 w90 Number", "600")
    g_SettingsGui.AddText("x+10 yp+3 cGray", "(requires reload to fully apply)")

    saveButton := g_SettingsGui.AddButton("xm y+16 w130", "Save")
    saveButton.OnEvent("Click", SaveSettingsFromGui)

    jsonButton := g_SettingsGui.AddButton("x+10 w130", "Open JSON")
    jsonButton.OnEvent("Click", (*) => OpenSettingsJson())

    closeButton := g_SettingsGui.AddButton("x+10 w130", "Close")
    closeButton.OnEvent("Click", (*) => g_SettingsGui.Hide())

    g_SettingsGui.OnEvent("Close", (*) => g_SettingsGui.Hide())
    g_SettingsGui.OnEvent("Escape", (*) => g_SettingsGui.Hide())

    g_SettingsControls := Map(
        "transparencySlider", transparencySlider,
        "transparencyValue", transparencyValue,
        "widthEdit", widthEdit
    )
}

LoadSettingsIntoGui() {
    global g_Config, g_SettingsControls

    if (!g_Config.Has("settings") || Type(g_Config["settings"]) != "Map") {
        return
    }

    settings := g_Config["settings"]

    transparency := settings.Has("window_transparency") ? settings["window_transparency"] : 150
    transparency := ClampInt(transparency, 0, 255, 150)

    width := settings.Has("width") ? settings["width"] : 600
    width := ClampInt(width, 300, 3000, 600)

    g_SettingsControls["transparencySlider"].Value := transparency
    g_SettingsControls["transparencyValue"].Value := transparency
    g_SettingsControls["widthEdit"].Value := width
}

SaveSettingsFromGui(*) {
    global g_Config, g_SettingsControls

    if (!g_Config.Has("settings") || Type(g_Config["settings"]) != "Map") {
        g_Config["settings"] := Map()
    }

    settings := g_Config["settings"]

    transparency := ClampInt(g_SettingsControls["transparencySlider"].Value, 0, 255, 150)
    width := ClampInt(g_SettingsControls["widthEdit"].Value, 300, 3000, 600)

    settings["window_transparency"] := transparency
    settings["width"] := width

    settingsPath := ResolveSettingsPath()
    json := Jxon_Dump(settings, 4)

    try {
        FileDelete(settingsPath)
    }

    try {
        FileAppend(json, settingsPath, "UTF-8")
        TrayTip("Settings", "Saved. Transparency updated.", 1)
    } catch as err {
        MsgBox("Failed to save settings:`n" . err.Message, "Settings")
    }
}

OpenSettingsJson() {
    settingsPath := ResolveSettingsPath()

    if (!FileExist(settingsPath)) {
        MsgBox("Settings file not found:`n" . settingsPath, "Settings")
        return
    }

    try {
        Run(settingsPath)
    } catch as err {
        MsgBox("Failed to open settings file:`n" . err.Message, "Settings")
    }
}

ResolveSettingsPath() {
    global g_Config

    settingsPath := A_ScriptDir . "\Config\settings.json"

    if (g_Config.Has("settings") && Type(g_Config["settings"]) = "Map" && g_Config["settings"].Has("settings_file")) {
        customPath := Trim(g_Config["settings"]["settings_file"])
        if (customPath != "") {
            settingsPath := InStr(customPath, ":") ? customPath : (A_ScriptDir . "\\" . customPath)
        }
    }

    return settingsPath
}

ClampInt(value, minValue, maxValue, fallback) {
    n := fallback
    try {
        n := Integer(value)
    }

    if (n < minValue)
        return minValue
    if (n > maxValue)
        return maxValue
    return n
}
