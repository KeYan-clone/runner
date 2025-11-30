; AppLauncher - Execute launch operations
; Handles launching applications and opening web pages

#Requires AutoHotkey v2.0
#Include ..\Utils\StringUtils.ahk

class AppLauncher {
    static Launch(app, config := "") {
        if (!app) {
            return false
        }

        ; Check if it's a URL direct access
        if (Type(app) = "Map" && app.Has("type") && app["type"] = "url") {
            return this.OpenDirectURL(app["query"])
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
