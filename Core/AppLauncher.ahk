; AppLauncher - Execute launch operations
; Handles launching applications and opening web pages

#Requires AutoHotkey v2.0

class AppLauncher {
    static Launch(app, config := "") {
        if (!app) {
            return false
        }

        ; Check if it's a web search/URL
        if (Type(app) = "Map" && app.Has("type") && app["type"] = "web_search") {
            return this.OpenURL(app["query"], config)
        }

        ; Launch local application
        if (app.Has("path")) {
            try {
                path := app["path"]
                args := app.Has("args") ? app["args"] : ""
                workdir := app.Has("workdir") ? app["workdir"] : ""

                if (workdir != "" && args != "") {
                    Run(path . " " . args, workdir)
                } else if (workdir != "") {
                    Run(path, workdir)
                } else if (args != "") {
                    Run(path . " " . args)
                } else {
                    Run(path)
                }
                return true
            } catch as err {
                appName := app.Has("name") ? app["name"] : "application"
                MsgBox("Failed to launch " . appName . ":`n" . err.Message)
                return false
            }
        }

        return false
    }

    static OpenURL(query, config := "") {
        ; Check if it looks like a URL or IP address
        if (RegExMatch(query, "i)^(https?://|www\.|localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")) {
            ; Direct URL/IP - open as-is
            url := query
            ; Add http:// if no protocol specified
            if (!RegExMatch(url, "i)^https?://")) {
                url := "http://" . url
            }
        } else {
            ; Use search engine
            searchEngine := "https://www.google.com/search?q="
            if (config && Type(config) = "Map" && config.Has("settings")) {
                settings := config["settings"]
                if (Type(settings) = "Map" && settings.Has("search_engine")) {
                    searchEngine := settings["search_engine"]
                }
            }
            url := searchEngine . this.UrlEncode(query)
        }

        try {
            Run(url)
            return true
        } catch as err {
            MsgBox("Failed to open URL: " . err.Message)
            return false
        }
    }

    static UrlEncode(str) {
        encoded := ""
        loop parse str {
            char := A_LoopField
            if (char ~= "[A-Za-z0-9\-_.~]") {
                encoded .= char
            } else if (char = " ") {
                encoded .= "+"
            } else {
                encoded .= Format("%{:02X}", Ord(char))
            }
        }
        return encoded
    }
}
