; AutoClickerPlugin - Auto clicker with customizable settings
; Support custom key binding and click interval

#Requires AutoHotkey v2.0
#Include ..\Core\Plugin.ahk

class AutoClickerPlugin extends Plugin {
    config := ""
    configWindow := ""
    isClicking := false
    clickInterval := 100  ; Default: 100ms
    clickKey := "LButton"  ; Default: Left Mouse Button
    clickThread := ""

    ; GUI Controls
    guiObj := ""
    keyInput := ""
    intervalInput := ""
    statusText := ""

    __New() {
        super.__New()

        this.name := "AutoClicker"
        this.version := "1.0.0"
        this.author := "Runner"
        this.description := "Auto clicker with customizable key and interval"
    }

    Init(config) {
        this.config := config
        this.LoadSettings()
        return true
    }

    GetHotkeys() {
        return Map(
            "auto_clicker", (*) => this.Execute()
        )
    }

    Execute(params := "") {
        if (!this.enabled) {
            return
        }

        ; Show configuration window
        this.ShowConfigWindow()
    }

    LoadSettings() {
        ; Load saved settings from config if available
        if (this.config.Has("auto_clicker")) {
            settings := this.config["auto_clicker"]
            if (settings.Has("interval")) {
                this.clickInterval := settings["interval"]
            }
            if (settings.Has("key")) {
                this.clickKey := settings["key"]
            }
        }
    }

    SaveSettings() {
        ; Save settings to config
        if (!this.config.Has("auto_clicker")) {
            this.config["auto_clicker"] := Map()
        }
        this.config["auto_clicker"]["interval"] := this.clickInterval
        this.config["auto_clicker"]["key"] := this.clickKey
    }

    ShowConfigWindow() {
        ; If window exists, just activate it
        if (this.guiObj) {
            try {
                this.guiObj.Show()
                return
            }
        }

        ; Create new window
        this.guiObj := Gui("+AlwaysOnTop -MinimizeBox", "Auto Clicker Configuration")
        this.guiObj.SetFont("s10", "Microsoft YaHei UI")

        ; Header
        this.guiObj.AddText("xm ym w400", "Configure Auto Clicker Settings")
        this.guiObj.AddText("xm y+5 w400 cGray", "按F8开始/停止连点")

        ; Click Key Setting
        this.guiObj.AddGroupBox("xm y+15 w400 h80", "Click Key")
        this.guiObj.AddText("xm+10 yp+25 w120", "Key to Click:")
        this.keyInput := this.guiObj.AddDropDownList("x+10 yp-3 w250 Choose" . this.GetKeyIndex(),
        ["LButton (Left Mouse)", "RButton (Right Mouse)", "MButton (Middle Mouse)",
            "Space", "Enter", "F1", "F2", "F3", "F4", "F5"])

        ; Click Interval Setting
        this.guiObj.AddGroupBox("xm y+15 w400 h80", "Click Interval")
        this.guiObj.AddText("xm+10 yp+25 w120", "Interval (ms):")
        this.intervalInput := this.guiObj.AddEdit("x+10 yp-3 w100 Number", this.clickInterval)
        this.guiObj.AddUpDown("Range1-10000", this.clickInterval)
        this.guiObj.AddText("x+10 yp+3 cGray", "(1-10000ms)")

        ; Status Display
        this.guiObj.AddGroupBox("xm y+15 w400 h80", "Status")
        statusColor := this.isClicking ? "Green" : "Red"
        statusText := this.isClicking ? "● Running" : "● Stopped"
        this.statusText := this.guiObj.AddText("xm+10 yp+30 w380 c" . statusColor, statusText)

        ; Buttons
        this.guiObj.AddButton("xm y+20 w190", "Start/Stop (F8)").OnEvent("Click", (*) => this.ToggleClicking())
        this.guiObj.AddButton("x+20 w190", "Save & Close").OnEvent("Click", (*) => this.SaveAndClose())

        ; Hotkey to toggle clicking
        this.guiObj.AddText("xm y+10 w400 cGray Center", "Tips: You can press F8 anywhere to toggle auto clicker")

        ; Set up F8 hotkey
        HotIfWinExist("Auto Clicker Configuration ahk_class AutoHotkeyGUI")
        Hotkey("F8", (*) => this.ToggleClicking(), "On")
        HotIfWinExist()

        ; Global F8 when clicker is running
        Hotkey("F8", (*) => this.ToggleClicking(), "On")

        ; Window close event
        this.guiObj.OnEvent("Close", (*) => this.HideWindow())

        ; Show window
        this.guiObj.Show("w420 h420")
    }

    GetKeyIndex() {
        keyMap := Map(
            "LButton", 1,
            "RButton", 2,
            "MButton", 3,
            "Space", 4,
            "Enter", 5,
            "F1", 6,
            "F2", 7,
            "F3", 8,
            "F4", 9,
            "F5", 10
        )
        return keyMap.Has(this.clickKey) ? keyMap[this.clickKey] : 1
    }

    ParseKeyFromDropdown(index) {
        keys := ["LButton", "RButton", "MButton", "Space", "Enter", "F1", "F2", "F3", "F4", "F5"]
        return keys[index]
    }

    ToggleClicking(*) {
        if (this.isClicking) {
            this.StopClicking()
        } else {
            this.StartClicking()
        }
    }

    StartClicking() {
        if (this.isClicking) {
            return
        }

        ; Update settings from GUI
        if (this.guiObj && this.keyInput && this.intervalInput) {
            selectedIndex := this.keyInput.Value
            this.clickKey := this.ParseKeyFromDropdown(selectedIndex)
            interval := this.intervalInput.Value
            if (interval >= 1 && interval <= 10000) {
                this.clickInterval := interval
            }
        }

        this.isClicking := true

        ; Update status text
        if (this.statusText) {
            this.statusText.Value := "● Running"
            this.statusText.SetFont("cGreen")
        }

        ; Start clicking loop
        this.ClickLoop()

        TrayTip("Auto Clicker", "Started clicking " . this.clickKey . " every " . this.clickInterval .
            "ms`nPress F8 to stop", 2)
    }

    StopClicking() {
        if (!this.isClicking) {
            return
        }

        this.isClicking := false

        ; Update status text
        if (this.statusText) {
            this.statusText.Value := "● Stopped"
            this.statusText.SetFont("cRed")
        }

        TrayTip("Auto Clicker", "Stopped clicking", 1)
    }

    ClickLoop() {
        if (!this.isClicking) {
            return
        }

        ; Perform click based on key type
        if (this.clickKey = "LButton") {
            Click("Left")
        } else if (this.clickKey = "RButton") {
            Click("Right")
        } else if (this.clickKey = "MButton") {
            Click("Middle")
        } else {
            Send("{" . this.clickKey . "}")
        }

        ; Schedule next click
        SetTimer(() => this.ClickLoop(), -this.clickInterval)
    }

    SaveAndClose(*) {
        ; Update settings from GUI
        if (this.keyInput && this.intervalInput) {
            selectedIndex := this.keyInput.Value
            this.clickKey := this.ParseKeyFromDropdown(selectedIndex)
            interval := this.intervalInput.Value
            if (interval >= 1 && interval <= 10000) {
                this.clickInterval := interval
            }
        }

        this.SaveSettings()
        TrayTip("Auto Clicker", "Settings saved successfully", 1)
        this.HideWindow()
    }

    HideWindow(*) {
        if (this.guiObj) {
            this.guiObj.Hide()
        }
    }

    Cleanup() {
        ; Stop clicking if active
        this.StopClicking()

        ; Destroy GUI
        if (this.guiObj) {
            this.guiObj.Destroy()
            this.guiObj := ""
        }

        ; Remove F8 hotkey
        try {
            Hotkey("F8", "Off")
        }
    }
}
