; PluginLoader - Load and manage plugins
; Handles loading external plugin scripts based on settings

#Requires AutoHotkey v2.0

class PluginLoader {
    static LoadAll(pluginDir, settings := "") {
        fullPath := A_ScriptDir . "\" . pluginDir

        if (!DirExist(fullPath)) {
            return 0
        }

        ; Check plugin settings
        pluginSettings := this.GetPluginSettings(settings)

        if (!pluginSettings["enabled"]) {
            return 0
        }

        loadedCount := 0
        loop files fullPath . "\*.ahk" {
            pluginName := StrReplace(A_LoopFileName, ".ahk", "")

            ; Check if plugin should be loaded
            if (!this.ShouldLoadPlugin(pluginName, pluginSettings)) {
                continue
            }

            try {
                ; Load plugin as standalone script
                Run(A_LoopFileFullPath)
                loadedCount++
            } catch as err {
                ; Silently fail or log error
                ; MsgBox("Failed to load plugin: " . A_LoopFileName . "`n" . err.Message)
            }
        }

        return loadedCount
    }

    static LoadPlugin(pluginPath) {
        if (FileExist(pluginPath)) {
            try {
                Run(pluginPath)
                return true
            } catch as err {
                MsgBox("Failed to load plugin: " . pluginPath . "`n" . err.Message)
                return false
            }
        }
        return false
    }

    static GetPluginSettings(settings) {
        ; Default settings
        defaultSettings := Map(
            "enabled", true,
            "load_all", true,
            "whitelist", []
        )

        if (!settings || Type(settings) != "Map") {
            return defaultSettings
        }

        if (!settings.Has("plugins") || Type(settings["plugins"]) != "Map") {
            return defaultSettings
        }

        pluginConfig := settings["plugins"]
        result := Map()

        result["enabled"] := pluginConfig.Has("enabled") ? pluginConfig["enabled"] : true
        result["load_all"] := pluginConfig.Has("load_all") ? pluginConfig["load_all"] : true
        result["whitelist"] := pluginConfig.Has("whitelist") ? pluginConfig["whitelist"] : []

        return result
    }

    static ShouldLoadPlugin(pluginName, pluginSettings) {
        ; If load_all is true, load all plugins
        if (pluginSettings["load_all"]) {
            return true
        }

        ; Otherwise, only load plugins in whitelist
        whitelist := pluginSettings["whitelist"]
        if (Type(whitelist) != "Array") {
            return false
        }

        for item in whitelist {
            if (item = pluginName) {
                return true
            }
        }

        return false
    }
}
