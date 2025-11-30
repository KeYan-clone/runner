; PluginLoader - Load and manage plugins
; Handles loading external plugin scripts based on settings

#Requires AutoHotkey v2.0

class PluginLoader {
    static loadedPlugins := []
    static pluginInstances := Map()  ; Store plugin instances by name

    ; Auto-discover and load all plugins from directory
    static AutoLoadPlugins(pluginDir, config, hotkeyManager) {
        fullPath := A_ScriptDir . "\" . pluginDir

        if (!DirExist(fullPath)) {
            return 0
        }

        ; Check plugin settings
        pluginSettings := this.GetPluginSettings(config["settings"])

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

            ; Try to get the global plugin instance
            try {
                ; Construct global variable name (e.g., g_WindowPinPlugin)
                globalVarName := "g_" . pluginName

                ; Check if global instance exists
                if (%globalVarName%) {
                    plugin := %globalVarName%

                    ; Initialize plugin
                    plugin.Init(config)

                    ; Register hotkeys
                    hotkeys := plugin.GetHotkeys()
                    if (Type(hotkeys) = "Map") {
                        for hotkeyName, callback in hotkeys {
                            if (config["keymap"].Has(hotkeyName)) {
                                hotkeyManager.RegisterHotkey(hotkeyName, callback)
                            }
                        }
                    }

                    ; Store plugin
                    this.loadedPlugins.Push(plugin)
                    this.pluginInstances[pluginName] := plugin
                    loadedCount++
                }
            } catch {
                ; Plugin instance not found, skip
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

    ; Register all loaded plugins and their hotkeys
    static RegisterPlugins(plugins, config, hotkeyManager) {
        for plugin in plugins {
            ; Initialize plugin
            try {
                plugin.Init(config)
            } catch as err {
                continue
            }

            ; Get and register hotkeys
            hotkeys := plugin.GetHotkeys()
            if (Type(hotkeys) = "Map") {
                for hotkeyName, callback in hotkeys {
                    if (config["keymap"].Has(hotkeyName)) {
                        hotkeyManager.RegisterHotkey(hotkeyName, callback)
                    }
                }
            }

            ; Store loaded plugin
            this.loadedPlugins.Push(plugin)
        }
    }

    ; Get all loaded plugins
    static GetLoadedPlugins() {
        return this.loadedPlugins
    }
}
