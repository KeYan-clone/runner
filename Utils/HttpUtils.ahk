; HttpUtils - HTTP request utilities
; Helper functions for making HTTP requests

#Requires AutoHotkey v2.0

class HttpUtils {
    static DEFAULT_TIMEOUT_MS := 5000

    ; Make HTTP GET request with UTF-8 encoding support
    static Get(url, timeoutMs := "") {
        whr := this.CreateRequest("GET", url, timeoutMs)
        try {
            whr.Send()
        } catch as err {
            throw Error("Network request failed: " . err.Message)
        }

        this.ThrowIfHttpError(whr)

        ; Get response as binary and convert from UTF-8
        responseBody := whr.ResponseBody
        return this.BinaryToUtf8(responseBody)
    }

    ; Make HTTP POST request with UTF-8 encoding support
    static Post(url, data, contentType := "application/json", timeoutMs := "") {
        whr := this.CreateRequest("POST", url, timeoutMs)
        whr.SetRequestHeader("Content-Type", contentType . "; charset=UTF-8")
        try {
            whr.Send(data)
        } catch as err {
            throw Error("Network request failed: " . err.Message)
        }

        this.ThrowIfHttpError(whr)

        ; Get response as binary and convert from UTF-8
        responseBody := whr.ResponseBody
        return this.BinaryToUtf8(responseBody)
    }

    static CreateRequest(method, url, timeoutMs := "") {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open(method, url, false)

        effectiveTimeout := (timeoutMs = "") ? this.DEFAULT_TIMEOUT_MS : timeoutMs
        ; Set all timeout stages (resolve/connect/send/receive) to avoid long hangs.
        whr.SetTimeouts(effectiveTimeout, effectiveTimeout, effectiveTimeout, effectiveTimeout)

        return whr
    }

    static ThrowIfHttpError(whr) {
        status := 0
        try {
            status := whr.Status
        } catch {
            throw Error("Network request failed: no HTTP response")
        }

        if (status < 200 || status >= 300) {
            statusText := ""
            try {
                statusText := whr.StatusText
            }
            if (statusText != "") {
                throw Error("HTTP " . status . " " . statusText)
            }
            throw Error("HTTP " . status)
        }
    }

    ; Convert binary response to UTF-8 string
    static BinaryToUtf8(binaryData) {
        ; Use ADODB.Stream to convert binary to UTF-8 text
        stream := ComObject("ADODB.Stream")
        stream.Type := 1  ; Binary
        stream.Open()
        stream.Write(binaryData)
        stream.Position := 0
        stream.Type := 2  ; Text
        stream.Charset := "UTF-8"
        text := stream.ReadText()
        stream.Close()
        return text
    }
}
