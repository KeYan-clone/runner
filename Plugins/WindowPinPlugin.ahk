; WindowPinPlugin - Pin and make window transparent
; Pin the active window on top and toggle transparency separately

#Requires AutoHotkey v2.0
#Include ..\Core\Plugin.ahk

class WindowPinPlugin extends Plugin {
    pinnedWindows := Map()  ; Store pinned window states
    transparentWindows := Map()  ; Store transparent window states
    config := ""

    __New() {
        super.__New()

        this.name := "WindowPin"
        this.version := "1.0.0"
        this.author := "Runner"
        this.description := "Toggle window always on top and transparency separately"
    }

    Init(config) {
        this.config := config
        return true
    }

    Execute(params := "") {
        if (!this.enabled) {
            return
        }

        ; Get active window
        activeWin := WinGetID("A")
        if (!activeWin) {
            MsgBox("No active window found", "Window Pin")
            return
        }

        ; Toggle pin state
        if (this.pinnedWindows.Has(activeWin)) {
            this.UnpinWindow(activeWin)
        } else {
            this.PinWindow(activeWin)
        }
    }

    ToggleTransparency(params := "") {
        if (!this.enabled) {
            return
        }

        ; Get active window
        activeWin := WinGetID("A")
        if (!activeWin) {
            MsgBox("No active window found", "Window Transparency")
            return
        }

        ; Toggle transparency
        if (this.transparentWindows.Has(activeWin)) {
            this.RemoveTransparency(activeWin)
        } else {
            this.SetTransparency(activeWin)
        }
    }

    PinWindow(winId) {
        try {
            ; Set window always on top
            WinSetAlwaysOnTop(1, "ahk_id " . winId)

            ; Store window state
            this.pinnedWindows[winId] := true

            ; Get window title
            winTitle := WinGetTitle("ahk_id " . winId)
            ; TrayTip("Window Pinned", winTitle, 1)
        } catch as err {
            MsgBox("Failed to pin window: " . err.Message, "Window Pin Error")
        }
    }

    UnpinWindow(winId) {
        try {
            ; Remove always on top
            WinSetAlwaysOnTop(0, "ahk_id " . winId)

            ; Remove from tracked windows
            this.pinnedWindows.Delete(winId)

            ; Get window title
            winTitle := WinGetTitle("ahk_id " . winId)
            ; TrayTip("Window Unpinned", winTitle, 1)
        } catch as err {
            MsgBox("Failed to unpin window: " . err.Message, "Window Pin Error")
        }
    }

    SetTransparency(winId) {
        try {
            ; Get transparency value from settings
            transparency := 150  ; Default value
            if (this.config && Type(this.config) = "Map" && this.config.Has("settings")) {
                settings := this.config["settings"]
                if (Type(settings) = "Map" && settings.Has("window_transparency")) {
                    transparency := settings["window_transparency"]
                }
            }

            ; Set transparency
            WinSetTransparent(transparency, "ahk_id " . winId)

            ; Store window state
            this.transparentWindows[winId] := true

            ; Get window title
            winTitle := WinGetTitle("ahk_id " . winId)
            ; TrayTip("Window Transparency Set", winTitle, 1)
        } catch as err {
            MsgBox("Failed to set transparency: " . err.Message, "Window Transparency Error")
        }
    }

    RemoveTransparency(winId) {
        try {
            ; Remove transparency
            WinSetTransparent("Off", "ahk_id " . winId)

            ; Remove from tracked windows
            this.transparentWindows.Delete(winId)

            ; Get window title
            winTitle := WinGetTitle("ahk_id " . winId)
            ; TrayTip("Window Transparency Removed", winTitle, 1)
        } catch as err {
            MsgBox("Failed to remove transparency: " . err.Message, "Window Transparency Error")
        }
    }

    Cleanup() {
        ; Unpin all windows when plugin is unloaded
        for winId in this.pinnedWindows {
            try {
                WinSetAlwaysOnTop(0, "ahk_id " . winId)
            }
        }
        this.pinnedWindows.Clear()

        ; Remove transparency from all windows
        for winId in this.transparentWindows {
            try {
                WinSetTransparent("Off", "ahk_id " . winId)
            }
        }
        this.transparentWindows.Clear()

        return true
    }
}

; Create global instance
global g_WindowPinPlugin := WindowPinPlugin()
