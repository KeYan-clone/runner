; TranslatePlugin - Translate selected text using API
; Automatically translate selected English text to Chinese

#Requires AutoHotkey v2.0
#Include ..\Core\Plugin.ahk
#Include ..\Utils\StringUtils.ahk
#Include ..\Utils\HttpUtils.ahk
#Include ..\Utils\MD5Utils.ahk

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

        ; Check API URL, appid and key
        if (!translationConfig.Has("api_url") || !translationConfig.Has("appid") || !translationConfig.Has("api_key")) {
            MsgBox("API URL, appid or api_key not specified in settings.json", "Translation Error")
            return ""
        }

        apiUrl := translationConfig["api_url"]
        ; 关键修复：去除 appid 和 apiKey 上的潜在空白字符
        appid := Trim(translationConfig["appid"])
        apiKey := Trim(translationConfig["api_key"])

        ; Make translation request
        return this.TranslateWithAPI(text, apiUrl, appid, apiKey)
    }

    TranslateWithAPI(text, apiUrl, appid, apiKey) {
        ; 百度翻译API参数
        salt := this.GenerateSalt()
        from := "auto"
        to := "zh"

        ; 签名计算：MD5(appid+q+salt+密钥)
        signStr := appid . text . salt . apiKey
        sign := this.MD5(signStr)

        ; 构造请求URL（所有参数拼接在URL后面）
        requestUrl := apiUrl
            . "?q=" . StringUtils.UrlEncode(text)
            . "&from=" . from
            . "&to=" . to
            . "&appid=" . appid
            . "&salt=" . salt
            . "&sign=" . sign

        try {
            response := HttpUtils.Get(requestUrl)
            result := Jxon_load(&response)

            if (result.Has("error_code")) {
                if (result.Has("error_msg"))
                    return "Error " . result["error_code"] . ": " . result["error_msg"]
                return "Error: " . result["error_code"]
            }

            if (result.Has("trans_result") && result["trans_result"] is Array) {
                ; 只显示译文，多个结果用换行分隔
                out := ""
                for item in result["trans_result"] {
                    if (out != "")
                        out .= "\n"
                    out .= item["dst"]
                }
                return out
            }
            return "No translation result"
        } catch as err {
            return "Request failed: " . err.Message
        }
    }

    ; 生成随机salt
    GenerateSalt() {
        return Format("{:06d}", Random(100000, 999999))
    }

    ; MD5计算 - 使用 MD5Utils 库
    MD5(str) {
        ; 移除了阻塞的 MsgBox 调试信息，使用高性能的 MD5Utils.Hash
        result := MD5Utils.Hash(str)
        return result
    }

    CreateTranslationWindow() {
        ; Create a resizable, draggable window with close button
        this.translationWindow := Gui("+AlwaysOnTop +Resize +MinSize300x100", "Translation")
        this.translationWindow.BackColor := "1E1E1E"

        ; Set larger, bold font for better visibility
        this.translationWindow.SetFont("s12 cWhite", "Microsoft YaHei UI")

        ; Add edit control for displaying translation (read-only, multi-line, word wrap)
        editCtrl := this.translationWindow.Add("Edit",
            "w500 h200 vTranslationText ReadOnly Multi Wrap Background1E1E1E cWhite", "")

        ; Press Escape to close the window
        this.translationWindow.OnEvent("Escape", (*) => this.translationWindow.Hide())
        this.translationWindow.OnEvent("Close", (*) => this.translationWindow.Hide())

        ; Handle window resize to adjust edit control
        this.translationWindow.OnEvent("Size", (*) => this.ResizeControls())

        ; Initially hide
        this.translationWindow.Show("Hide")

        ; Make background semi-transparent (0-255, 0=invisible, 255=opaque)
        WinSetTransparent(230, this.translationWindow.Hwnd)
    }

    ResizeControls() {
        ; Get client area size
        this.translationWindow.GetClientPos(, , &w, &h)
        ; Resize edit control to fill window with 10px margin
        try {
            this.translationWindow["TranslationText"].Move(10, 10, w - 20, h - 20)
        }
    }

    ShowTranslation(text) {
        ; Update text first
        this.translationWindow["TranslationText"].Value := text

        ; Get mouse position
        MouseGetPos(&x, &y)

        ; Calculate window position (offset from mouse)
        winX := x + 15
        winY := y + 15

        ; Show window with NoActivate to prevent focus stealing
        this.translationWindow.Show("NA w520 h220")

        ; Move window to mouse position using WinMove
        WinMove(winX, winY, 520, 220, this.translationWindow.Hwnd)
    }

    Cleanup() {
        if (this.translationWindow) {
            this.translationWindow.Destroy()
        }
    }
}
