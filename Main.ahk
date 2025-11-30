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

; Global Config
global g_Config := Map()
global g_SearchWindow := ""
global g_HotkeyManager := ""

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
