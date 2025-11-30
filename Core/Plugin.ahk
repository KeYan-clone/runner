; Plugin - Base class for all plugins
; Abstract class that defines the interface for plugins

#Requires AutoHotkey v2.0

class Plugin {
    name := ""
    version := "1.0.0"
    author := ""
    description := ""
    enabled := true

    ; Constructor - Override to initialize plugin
    __New() {
        ; Child classes should call super.__New() and set properties
        if (Type(this) = "Plugin") {
            throw Error("Plugin is an abstract class and cannot be instantiated directly")
        }
    }

    ; Initialize plugin - Called when plugin is loaded
    ; Override this method to perform initialization
    Init(config) {
        throw Error("Method 'Init' must be implemented by " . Type(this))
    }

    ; Execute plugin main functionality
    ; Override this method to define plugin behavior
    Execute(params := "") {
        throw Error("Method 'Execute' must be implemented by " . Type(this))
    }

    ; Called when plugin is being unloaded
    ; Override this method to perform cleanup
    Cleanup() {
        throw Error("Method 'Cleanup' must be implemented by " . Type(this))
    }

    ; Get plugin information
    GetInfo() {
        return Map(
            "name", this.name,
            "version", this.version,
            "author", this.author,
            "description", this.description,
            "enabled", this.enabled
        )
    }

    ; Enable the plugin
    Enable() {
        this.enabled := true
        return true
    }

    ; Disable the plugin
    Disable() {
        this.enabled := false
        return true
    }

    ; Check if plugin is enabled
    IsEnabled() {
        return this.enabled
    }

    ; Validate plugin configuration
    ; Override this to add custom validation
    ValidateConfig(config) {
        return true
    }

    ; Get plugin settings from config
    ; Override this to define plugin-specific settings
    GetSettings(config) {
        if (config.Has("plugins") && config["plugins"].Has(this.name)) {
            return config["plugins"][this.name]
        }
        return Map()
    }

    ; Get plugin hotkeys
    ; Override this to define plugin hotkeys
    ; Return Map with key: hotkey name, value: callback function
    GetHotkeys() {
        return Map()
    }
}
