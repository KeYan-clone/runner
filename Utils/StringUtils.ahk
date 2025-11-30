; StringUtils - String manipulation utilities
; Helper functions for string operations

#Requires AutoHotkey v2.0

class StringUtils {
    ; URL encode a string using UTF-8 encoding
    static UrlEncode(str) {
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
}
