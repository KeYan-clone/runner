; HttpUtils - HTTP request utilities
; Helper functions for making HTTP requests

#Requires AutoHotkey v2.0

class HttpUtils {
    ; Make HTTP GET request with UTF-8 encoding support
    static Get(url) {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()

        ; Get response as binary and convert from UTF-8
        responseBody := whr.ResponseBody
        return this.BinaryToUtf8(responseBody)
    }

    ; Make HTTP POST request with UTF-8 encoding support
    static Post(url, data, contentType := "application/json") {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, false)
        whr.SetRequestHeader("Content-Type", contentType . "; charset=UTF-8")
        whr.Send(data)

        ; Get response as binary and convert from UTF-8
        responseBody := whr.ResponseBody
        return this.BinaryToUtf8(responseBody)
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
