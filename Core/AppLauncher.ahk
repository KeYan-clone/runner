; AppLauncher - Execute launch operations
; Handles launching applications and opening web pages

#Requires AutoHotkey v2.0
#Include ..\Utils\StringUtils.ahk
#Include HistoryManager.ahk

class AppLauncher {
    static Launch(app, config := "") {
        if (!app) {
            return false
        }

        ; Check if it's a URL direct access
        if (Type(app) = "Map" && app.Has("type") && app["type"] = "url") {
            result := this.OpenDirectURL(app["query"])
            if (result) {
                HistoryManager.AddURL(app["query"])
            }
            return result
        }

        ; Check if it's a web search
        if (Type(app) = "Map" && app.Has("type") && app["type"] = "web_search") {
            return this.WebSearch(app["query"], config)
        }

        ; Launch local application
        if (app.Has("path")) {
            try {
                path := app["path"]
                args := app.Has("args") ? app["args"] : ""
                workdir := app.Has("workdir") ? app["workdir"] : ""
                appName := app.Has("name") ? app["name"] : ""

                pid := 0
                if (workdir != "" && args != "") {
                    pid := Run(path . " " . args, workdir)
                } else if (workdir != "") {
                    pid := Run(path, workdir)
                } else if (args != "") {
                    pid := Run(path . " " . args)
                } else {
                    pid := Run(path)
                }

                ; Do not automatically activate windows after launch
                ; Some apps spawn child processes or reuse existing instances,
                ; so activating by PID/title can target the wrong window.
                return true
            } catch as err {
                appName := app.Has("name") ? app["name"] : "application"
                MsgBox("Failed to launch " . appName . ":`n" . err.Message)
                return false
            }
        }

        return false
    }

    static OpenDirectURL(query) {
        ; Direct URL access - add http:// if no protocol
        url := query
        if (!RegExMatch(url, "i)^https?://")) {
            url := "http://" . url
        }

        try {
            Run(url)
            return true
        } catch as err {
            MsgBox("Failed to open URL: " . err.Message)
            return false
        }
    }

    static WebSearch(query, config := "") {
        ; Use search engine
        searchEngine := "https://www.google.com/search?q="
        if (config && Type(config) = "Map" && config.Has("settings")) {
            settings := config["settings"]
            if (Type(settings) = "Map" && settings.Has("search_engine")) {
                searchEngine := settings["search_engine"]
            }
        }
        url := searchEngine . StringUtils.UrlEncode(query)

        try {
            Run(url)
            return true
        } catch as err {
            MsgBox("Failed to open browser: " . err.Message)
            return false
        }
    }

}
