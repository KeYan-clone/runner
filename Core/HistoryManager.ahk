; HistoryManager - Manage URL history
; Records and retrieves URL access history

#Requires AutoHotkey v2.0
#Include JXON.ahk

class HistoryManager {
    static historyFile := A_ScriptDir . "\Config\history.json"
    static maxHistorySize := 100

    ; Load history from file
    static Load() {
        if (!FileExist(this.historyFile)) {
            return []
        }

        try {
            content := FileRead(this.historyFile, "UTF-8")
            history := Jxon_Load(&content)
            return (history is Array) ? history : []
        } catch {
            return []
        }
    }

    ; Save history to file
    static Save(history) {
        try {
            json := Jxon_Dump(history, 4)
            if (FileExist(this.historyFile)) {
                FileDelete(this.historyFile)
            }
            FileAppend(json, this.historyFile, "UTF-8")
            return true
        } catch {
            return false
        }
    }

    ; Add URL to history
    static AddURL(url) {
        history := this.Load()

        ; Create history entry
        entry := Map(
            "url", url,
            "timestamp", A_Now,
            "date", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        )

        ; Remove duplicate if exists
        for i, item in history {
            if (Type(item) = "Map" && item.Has("url") && item["url"] = url) {
                history.RemoveAt(i)
                break
            }
        }

        ; Add to beginning
        history.InsertAt(1, entry)

        ; Limit size
        while (history.Length > this.maxHistorySize) {
            history.Pop()
        }

        this.Save(history)
    }

    ; Get recent history (limit count)
    static GetRecent(count := 10) {
        history := this.Load()
        result := []

        loop Min(count, history.Length) {
            result.Push(history[A_Index])
        }

        return result
    }

    ; Search history by keyword
    static Search(keyword) {
        history := this.Load()
        result := []

        for entry in history {
            if (Type(entry) = "Map" && entry.Has("url") && InStr(entry["url"], keyword)) {
                result.Push(entry)
            }
        }

        return result
    }

    ; Clear all history
    static Clear() {
        try {
            if (FileExist(this.historyFile)) {
                FileDelete(this.historyFile)
            }
            return true
        } catch {
            return false
        }
    }
}
