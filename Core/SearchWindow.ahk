; SearchWindow - Main UI and search matching logic
; Handles the search window display and real-time matching

class SearchWindow {
    gui := ""
    searchBox := ""
    resultList := ""
    config := ""
    currentMatches := []

    __New(config) {
        this.config := config
        this.CreateGui()
    }

    CreateGui() {
        ; Get window width from settings
        width := 600
        if (Type(this.config["settings"]) = "Map" && this.config["settings"].Has("width")) {
            width := this.config["settings"]["width"]
        }

        ; Create the main window
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Runner")
        this.gui.BackColor := "White"
        this.gui.SetFont("s10", "Segoe UI")

        ; Add search input box
        this.searchBox := this.gui.Add("Edit", "w" . (width - 20) . " x10 y10")
        this.searchBox.OnEvent("Change", (*) => this.OnType())

        ; Add result list
        this.resultList := this.gui.Add("ListBox", "w" . (width - 20) . " x10 y45 r10")
        this.resultList.OnEvent("DoubleClick", (*) => this.LaunchSelected())

        ; Set up hotkeys for navigation
        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => this.Hide())

        ; Add keyboard shortcuts
        HotIfWinActive("ahk_id " . this.gui.Hwnd)
        Hotkey("Enter", (*) => this.LaunchSelected())
        Hotkey("Down", (*) => this.SelectNext())
        Hotkey("Up", (*) => this.SelectPrevious())
        HotIf()

        ; Resize window
        this.gui.Show("w" . width . " h260 Hide")
    }

    Toggle() {
        if (WinExist("ahk_id " . this.gui.Hwnd)) {
            if (WinActive("ahk_id " . this.gui.Hwnd)) {
                this.Hide()
            } else {
                this.Show()
            }
        } else {
            this.Show()
        }
    }

    Show() {
        ; Clear search box
        this.searchBox.Value := ""
        this.resultList.Delete()
        this.currentMatches := []

        ; Show window in center of screen
        this.gui.Show("AutoSize Center")

        ; Focus on search box
        ControlFocus(this.searchBox)
    }

    Hide() {
        this.gui.Hide()
    }

    OnType() {
        searchText := Trim(this.searchBox.Value)

        ; Clear current results
        this.resultList.Delete()
        this.currentMatches := []

        if (searchText = "") {
            return
        }

        ; Search through apps
        if (Type(this.config["apps"]) = "Map") {
            for appKey, app in this.config["apps"] {
                if (this.MatchApp(app, searchText)) {
                    displayText := app.Has("name") ? app["name"] : "Unknown"
                    this.resultList.Add([displayText])
                    this.currentMatches.Push(app)
                }
            }
        }

        ; Always add web search option
        this.resultList.Add(["🔍 Search Web for '" . searchText . "'"])
        this.currentMatches.Push(Map("type", "web_search", "query", searchText))

        ; Select first item
        if (this.currentMatches.Length > 0) {
            this.resultList.Choose(1)
        }
    }

    MatchApp(app, searchText) {
        searchLower := StrLower(searchText)

        ; Check name with fuzzy matching
        if (app.Has("name")) {
            ; First try exact substring match
            if (InStr(StrLower(app["name"]), searchLower)) {
                return true
            }
            ; Then try fuzzy match (character sequence)
            if (this.FuzzyMatch(app["name"], searchText)) {
                return true
            }
        }

        ; Check keywords
        if (app.Has("keywords") && Type(app["keywords"]) = "Array") {
            for keyword in app["keywords"] {
                ; Try exact substring match
                if (InStr(StrLower(keyword), searchLower)) {
                    return true
                }
                ; Try fuzzy match
                if (this.FuzzyMatch(keyword, searchText)) {
                    return true
                }
            }
        }

        return false
    }

    ; Fuzzy matching: checks if search chars appear in order in target
    ; e.g., "pws" matches "PowerShell"
    FuzzyMatch(target, search) {
        target := StrLower(target)
        search := StrLower(search)

        searchPos := 1
        targetPos := 1

        while (searchPos <= StrLen(search) && targetPos <= StrLen(target)) {
            if (SubStr(search, searchPos, 1) = SubStr(target, targetPos, 1)) {
                searchPos++
            }
            targetPos++
        }

        ; All search characters found in order
        return (searchPos > StrLen(search))
    }

    LaunchSelected() {
        selectedIndex := this.resultList.Value

        if (selectedIndex = 0 || selectedIndex > this.currentMatches.Length) {
            return
        }

        selected := this.currentMatches[selectedIndex]

        ; Hide window first
        this.Hide()

        ; Launch the app or perform web search
        if (Type(selected) = "Map" && selected.Has("type") && selected["type"] = "web_search") {
            query := selected["query"]

            ; Check if it looks like a URL or IP address
            if (RegExMatch(query, "i)^(https?://|www\.|localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")) {
                ; Direct URL/IP - open as-is
                url := query
                ; Add http:// if no protocol specified
                if (!RegExMatch(url, "i)^https?://")) {
                    url := "http://" . url
                }
            } else {
                ; Use search engine from settings
                searchEngine := "https://www.google.com/search?q="  ; Default
                if (Type(this.config["settings"]) = "Map" && this.config["settings"].Has("search_engine")) {
                    searchEngine := this.config["settings"]["search_engine"]
                }
                url := searchEngine . this.UrlEncode(query)
            }

            try {
                Run(url)
            } catch as err {
                MsgBox("Failed to open browser: " . err.Message)
            }
        } else {
            ; Launch local app
            if (selected.Has("path")) {
                try {
                    Run(selected["path"])
                } catch as err {
                    MsgBox("Failed to launch '" . selected["name"] . "': " . err.Message)
                }
            }
        }
    }

    UrlEncode(str) {
        ; Convert string to UTF-8 bytes and encode
        encoded := ""

        ; Use VarSetStrCapacity and StrPut for proper UTF-8 conversion
        bufferSize := StrPut(str, "UTF-8")
        buf := Buffer(bufferSize)
        StrPut(str, buf, "UTF-8")

        ; Process each byte
        loop bufferSize - 1 {  ; -1 to skip null terminator
            byte := NumGet(buf, A_Index - 1, "UChar")
            char := Chr(byte)

            ; Keep unreserved characters as-is
            if (char ~= "[A-Za-z0-9\-_.~]") {
                encoded .= char
            } else if (char = " ") {
                encoded .= "+"
            } else {
                ; Encode as %XX
                encoded .= Format("%{:02X}", byte)
            }
        }
        return encoded
    }

    SelectNext() {
        current := this.resultList.Value
        if (current = 0 && this.currentMatches.Length > 0) {
            this.resultList.Choose(1)
        } else if (current < this.currentMatches.Length) {
            this.resultList.Choose(current + 1)
        }
    }

    SelectPrevious() {
        current := this.resultList.Value
        if (current > 1) {
            this.resultList.Choose(current - 1)
        }
    }
}
