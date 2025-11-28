; HotkeyManager - Manages global hotkeys
; Responsible for registering and managing hotkeys based on configuration

#Requires AutoHotkey v2.0

class HotkeyManager {
    keymapConfig := Map()
    registeredHotkeys := Map()

    __New(keymapConfig) {
        this.keymapConfig := keymapConfig
    }

    RegisterHotkey(name, callback) {
        ; Get the hotkey combination from config
        if (!this.keymapConfig.Has(name)) {
            return false
        }

        hotkeyCombo := this.keymapConfig[name]

        ; Register the hotkey
        try {
            Hotkey(hotkeyCombo, callback)
            this.registeredHotkeys[name] := hotkeyCombo
            return true
        } catch as err {
            MsgBox("Failed to register hotkey '" . name . "' (" . hotkeyCombo . "): " . err.Message)
            return false
        }
    }

    UnregisterHotkey(name) {
        if (!this.registeredHotkeys.Has(name)) {
            return false
        }

        hotkeyCombo := this.registeredHotkeys[name]
        try {
            Hotkey(hotkeyCombo, "Off")
            this.registeredHotkeys.Delete(name)
            return true
        } catch as err {
            MsgBox("Failed to unregister hotkey '" . name . "': " . err.Message)
            return false
        }
    }

    GetRegisteredHotkeys() {
        return this.registeredHotkeys
    }

    ReloadHotkeys(newKeymapConfig) {
        ; Unregister all current hotkeys
        for name, combo in this.registeredHotkeys.Clone() {
            this.UnregisterHotkey(name)
        }

        ; Update config
        this.keymapConfig := newKeymapConfig
    }
}
