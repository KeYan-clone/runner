; HttpUtils - HTTP request utilities
; Helper functions for making HTTP requests

#Requires AutoHotkey v2.0

class HttpUtils {
    ; Make HTTP GET request
    static Get(url) {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        return whr.ResponseText
    }

    ; Make HTTP POST request
    static Post(url, data, contentType := "application/json") {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, false)
        whr.SetRequestHeader("Content-Type", contentType)
        whr.Send(data)
        return whr.ResponseText
    }
}
