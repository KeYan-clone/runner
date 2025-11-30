; MD5Utils - MD5 hash calculation utilities
; Optimized implementation using Windows CryptoAPI (advapi32.dll)

#Requires AutoHotkey v2.0

class MD5Utils {
    /**
     * 计算字符串的 MD5
     * @param {String} str - 输入字符串
     * @returns {String} - 32位小写十六进制 MD5
     */
    static Hash(str) {
        try {
            ; 1. 将字符串转换为 UTF-8 二进制数据
            ; API 签名计算通常不包含末尾的 Null 终止符，所以这里减去 1
            ; 如果 str 为空，StrPut 返回 1，长度变为 0，这是允许的
            bufLen := StrPut(str, "UTF-8")
            dataSize := bufLen - 1

            inputBuf := Buffer(dataSize > 0 ? dataSize : 0)

            if (dataSize > 0) {
                StrPut(str, inputBuf, "UTF-8")
            }

            ; 2. 调用底层 API 计算 MD5
            return this.CalcBufferMD5(inputBuf, dataSize)
        } catch as err {
            ; 错误处理（通常不会发生，除非系统极其异常）
            return ""
        }
    }

    /**
     * 内部方法：计算二进制 Buffer 的 MD5
     */
    static CalcBufferMD5(bufferObj, size) {
        ; Windows CryptoAPI 常量
        static PROV_RSA_FULL := 1
        static CALG_MD5      := 0x8003
        static HP_HASHVAL    := 0x0002
        static CRYPT_VERIFYCONTEXT := 0xF0000000

        hProv := 0
        hHash := 0
        hashVal := ""

        try {
            ; 获取加密服务提供者上下文 (CSP)
            ; 使用 VERIFYCONTEXT 标志，不需要访问私钥容器，速度更快且无需权限
            if !DllCall("advapi32\CryptAcquireContextW", "Ptr*", &hProv, "Ptr", 0, "Ptr", 0, "UInt", PROV_RSA_FULL, "UInt", CRYPT_VERIFYCONTEXT)
                throw Error("CryptAcquireContext failed")

            ; 创建 MD5 哈希对象
            if !DllCall("advapi32\CryptCreateHash", "Ptr", hProv, "UInt", CALG_MD5, "Ptr", 0, "UInt", 0, "Ptr*", &hHash)
                throw Error("CryptCreateHash failed")

            ; 传入数据进行哈希计算
            if !DllCall("advapi32\CryptHashData", "Ptr", hHash, "Ptr", bufferObj, "UInt", size, "UInt", 0)
                throw Error("CryptHashData failed")

            ; 获取哈希结果的长度 (MD5 固定为 16 字节)
            hashLen := 0
            DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", HP_HASHVAL, "Ptr", 0, "UInt*", &hashLen, "UInt", 0)

            ; 获取哈希结果数据
            hashData := Buffer(hashLen)
            if !DllCall("advapi32\CryptGetHashParam", "Ptr", hHash, "UInt", HP_HASHVAL, "Ptr", hashData, "UInt*", &hashLen, "UInt", 0)
                throw Error("CryptGetHashParam failed")

            ; 将二进制数据转换为十六进制字符串
            Loop hashLen {
                ; 逐字节读取并格式化为 2 位小写十六进制
                hashVal .= Format("{:02x}", NumGet(hashData, A_Index - 1, "UChar"))
            }
        } finally {
            ; 清理资源，防止内存泄漏
            if hHash
                DllCall("advapi32\CryptDestroyHash", "Ptr", hHash)
            if hProv
                DllCall("advapi32\CryptReleaseContext", "Ptr", hProv, "UInt", 0)
        }

        return hashVal
    }
}
