# Runner (AHK v2)

这是一个基于 AutoHotkey v2 编写的轻量级应用程序启动器。它允许用户通过快捷键呼出一个搜索框，**快速启动应用程序**或**进行网络搜索**，并支持插件扩展。


## 目录结构

```text
├── Main.ahk               # 主程序入口
├── README.md              # 说明文档
├── runner.ico             # 应用图标
│
├── Config/                # 配置文件目录
│   ├── keymap.json        # 热键配置
│   ├── apps.json          # 应用程序列表
│   └── settings.json      # 全局设置（如窗口宽度、搜索引擎、翻译API）
│
├── Core/                  # 核心逻辑库
│   ├── HotkeyManager.ahk  # 负责注册和管理全局热键
│   ├── SearchWindow.ahk   # 搜索框 UI 及搜索匹配逻辑
│   ├── AppLauncher.ahk    # 执行启动程序或打开网页的逻辑
│   ├── PluginLoader.ahk   # 插件加载器
│   ├── Plugin.ahk         # 插件基类
│   └── JXON.ahk           # JSON 解析工具类
│
├── Utils/                 # 工具类库
│   ├── StringUtils.ahk    # 字符串工具（URL编码等）
│   └── HttpUtils.ahk      # HTTP 请求工具
│
└── Plugins/               # 插件目录
    ├── WindowPinPlugin.ahk    # 窗口置顶和透明度插件
    └── TranslatePlugin.ahk    # 翻译插件
```

## 功能特性

- **快速启动** - 通过模糊匹配快速找到并启动应用程序
- **网页搜索** - 直接访问 URL 或使用搜索引擎搜索
- **插件系统** - 支持自定义插件扩展功能
- **窗口管理** - 窗口置顶、透明度调节
- **文本翻译** - 选中文本快速翻译（支持自定义API）
- **全局热键** - 可自定义所有快捷键

## 配置文件说明

### Config/apps.json
定义可启动的应用程序。
```json
{
    "notepad": {
        "name": "Notepad",
        "path": "notepad.exe",
        "keywords": ["np", "note", "txt"]
    },
    "vscode": {
        "name": "Visual Studio Code",
        "path": "C:\\Users\\YourName\\apps\\Microsoft VS Code\\Code.exe",
        "keywords": ["code", "vscode"]
    }
}
```

### Config/keymap.json
定义全局快捷键。
```json
{
    "toggle_launcher": "CapsLock & o",     // 打开启动器
    "reload": "^!r",                       // 重载脚本
    "exit": "CapsLock & q",                // 退出程序
    "window_pin": "CapsLock & p",          // 窗口置顶
    "window_transparency": "CapsLock & t", // 窗口透明
    "translate": "CapsLock & d",           // 翻译选中文本
    "launcher_execute": "CapsLock & Enter",// 启动器中执行
    "launcher_next": "Down",               // 下一项
    "launcher_previous": "Up"              // 上一项
}
```

### Config/settings.json
全局设置。
```json
{
    "width": 600,
    "icon": "runner.ico",
    "search_engine": "https://cn.bing.com/search?q=",
    "window_transparency": 150,
    "translation": {
        "api_url": "https://api.example.com/translate",
        "api_key": "your_api_key_here"
    },
    "plugins": {
        "enabled": true,
        "load_all": true,
        "whitelist": ["WindowPinPlugin", "TranslatePlugin"]
    }
}
```

## 插件开发

插件需要继承 `Plugin` 基类并实现以下方法：

```ahk
class MyPlugin extends Plugin {
    __New() {
        super.__New()
        this.name := "MyPlugin"
        this.description := "My custom plugin"
    }

    Init(config) {
        // 初始化逻辑
        return true
    }

    GetHotkeys() {
        // 返回插件的热键映射
        return Map(
            "my_hotkey", (*) => this.Execute()
        )
    }

    Execute(params := "") {
        // 插件主要功能
    }

    Cleanup() {
        // 清理逻辑
    }
}
```

## 特别感谢
本项目的JSON解析库使用的是 `TheArkive` 所开发 [JXON_ahk2](https://github.com/TheArkive/JXON_ahk2)
