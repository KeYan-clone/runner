; TranslatePlugin - Translate selected text using API
; Automatically translate selected English text to Chinese

#Requires AutoHotkey v2.0
#Include ..\Core\Plugin.ahk
#Include ..\Utils\StringUtils.ahk
#Include ..\Utils\HttpUtils.ahk

class TranslatePlugin extends Plugin {
    config := ""
    translationWindow := ""

    __New() {
        super.__New()

        this.name := "Translate"
        this.version := "1.0.0"
        this.author := "Runner"
        this.description := "Translate selected text from English to Chinese using API"
    }

    Init(config) {
        this.config := config
        this.CreateTranslationWindow()
        return true
    }

    GetHotkeys() {
        return Map(
            "translate", (*) => this.Execute()
        )
    }

    Execute(params := "") {
        if (!this.enabled) {
            return
        }

        ; Get selected text
        selectedText := this.GetSelectedText()

        if (!selectedText || Trim(selectedText) = "") {
            TrayTip("Translation", "No text selected", 1)
            return
        }

        ; Show translating message
        this.ShowTranslation("Translating...")

        ; Translate the text
        translation := this.Translate(selectedText)

        if (translation) {
            this.ShowTranslation(translation)
        } else {
            this.ShowTranslation("Translation failed")
        }
    }

    GetSelectedText() {
        ; Save current clipboard
        savedClipboard := ClipboardAll()
        A_Clipboard := ""

        ; Copy selected text
        Send("^c")

        ; Wait for clipboard
        if (!ClipWait(0.5)) {
            A_Clipboard := savedClipboard
            return ""
        }

        selectedText := A_Clipboard

        ; Restore clipboard
        A_Clipboard := savedClipboard

        return selectedText
    }

    Translate(text) {
        ; Get API settings
        if (!Type(this.config["settings"]) = "Map" || !this.config["settings"].Has("translation")) {
            MsgBox("Translation API not configured in settings.json", "Translation Error")
            return ""
        }

        translationConfig := this.config["settings"]["translation"]

        ; Check API URL and key
        if (!translationConfig.Has("api_url") || !translationConfig.Has("api_key")) {
            MsgBox("API URL or API Key not specified in settings.json", "Translation Error")
            return ""
        }

        apiUrl := translationConfig["api_url"]
        apiKey := translationConfig["api_key"]

        ; Make translation request
        return this.TranslateWithAPI(text, apiUrl, apiKey)
    }

    TranslateWithAPI(text, apiUrl, apiKey) {
        ; Build request URL
        url := apiUrl . "?text=" . StringUtils.UrlEncode(text) . "&key=" . apiKey

        try {
            response := HttpUtils.Get(url)

            ; Try to parse as JSON
            try {
                result := Jxon_Load(&response)

                ; Common response formats
                if (result.Has("translation")) {
                    return result["translation"]
                } else if (result.Has("result")) {
                    return result["result"]
                } else if (result.Has("data") && Type(result["data"]) = "String") {
                    return result["data"]
                }
            }

            ; If not JSON, return raw response
            return response
        } catch as err {
            return "Request failed: " . err.Message
        }
    }

    CreateTranslationWindow() {
        ; Create a draggable, semi-transparent window
        this.translationWindow := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "Translation")
        this.translationWindow.BackColor := "0x1E1E1E"

        ; Make background semi-transparent (0-255, 0=invisible, 255=opaque)
        WinSetTransparent(230, this.translationWindow)

        ; Set larger, bold font for better visibility
        this.translationWindow.SetFont("s12 bold cWhite", "Microsoft YaHei UI")

        ; Add text control with padding
        this.translationWindow.Add("Text", "w400 h100 vTranslationText BackgroundTrans", "")

        ; Make window draggable by clicking anywhere
        this.translationWindow.OnEvent("Click", (*) => this.StartDrag())

        ; Initially hide
        this.translationWindow.Show("Hide")
    }

    StartDrag() {
        ; Enable dragging when clicking on the window
        PostMessage(0xA1, 2, 0, , "ahk_id " . this.translationWindow.Hwnd)
    }
    ShowTranslation(text) {
        ; Update text
        this.translationWindow["TranslationText"].Value := text

        ; Get mouse position
        MouseGetPos(&x, &y)

        ; Show window near mouse
        this.translationWindow.Show("x" . (x + 10) . " y" . (y + 10) . " AutoSize")

        ; Auto hide after 5 seconds
        SetTimer(() => this.translationWindow.Hide(), -5000)
    }

    Cleanup() {
        if (this.translationWindow) {
            this.translationWindow.Destroy()
        }
    }
}

; Create global instance
global g_TranslatePlugin := TranslatePlugin()
