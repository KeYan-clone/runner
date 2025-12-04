; SearchWindow - Main UI and search matching logic
; Handles the search window display and real-time matching

#Include ..\Utils\StringUtils.ahk
#Include HistoryManager.ahk
#Include AppLauncher.ahk

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

        ; Add keyboard shortcuts from keymap
        if (Type(this.config["keymap"]) = "Map") {
            HotIfWinActive("ahk_id " . this.gui.Hwnd)
            if (this.config["keymap"].Has("launcher_execute")) {
                Hotkey(this.config["keymap"]["launcher_execute"], (*) => this.LaunchSelected())
            }
            if (this.config["keymap"].Has("launcher_next")) {
                Hotkey(this.config["keymap"]["launcher_next"], (*) => this.SelectNext())
            }
            if (this.config["keymap"].Has("launcher_previous")) {
                Hotkey(this.config["keymap"]["launcher_previous"], (*) => this.SelectPrevious())
            }
            HotIf()
        }

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

        ; Search in history
        historyResults := HistoryManager.Search(searchText)
        for entry in historyResults {
            if (Type(entry) = "Map" && entry.Has("url")) {
                displayText := "📜 " . entry["url"]
                if (entry.Has("date")) {
                    displayText .= " (" . entry["date"] . ")"
                }
                this.resultList.Add([displayText])
                this.currentMatches.Push(Map("type", "url", "query", entry["url"]))
            }
        }

        ; Always add URL option
        this.resultList.Add(["🌐 Open as URL: " . searchText])
        this.currentMatches.Push(Map("type", "url", "query", searchText))

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

        ; Use AppLauncher to handle all launches (this will save history for URLs)
        AppLauncher.Launch(selected, this.config)
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
