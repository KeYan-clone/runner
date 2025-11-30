; StringUtils - String manipulation utilities
; Helper functions for string operations

#Requires AutoHotkey v2.0

class StringUtils {
    ; URL encode a string using UTF-8 encoding
    static UrlEncode(str) {
        encoded := ""

        ; Convert string to UTF-8 bytes
        bufferSize := StrPut(str, "UTF-8")
        buf := Buffer(bufferSize)
        StrPut(str, buf, "UTF-8")

        ; Process each byte (exclude null terminator)
        loop bufferSize - 1 {
            byte := NumGet(buf, A_Index - 1, "UChar")

            ; Check if byte represents unreserved character
            ; ASCII: A-Z (65-90), a-z (97-122), 0-9 (48-57), - (45), _ (95), . (46), ~ (126)
            if ((byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || (byte >= 48 && byte <= 57) || byte = 45 ||
            byte = 95 || byte = 46 || byte = 126) {
                encoded .= Chr(byte)
            } else {
                ; Encode all other bytes as %XX
                encoded .= Format("%{:02X}", byte)
            }
        }
        return encoded
    }
}
