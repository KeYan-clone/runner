# MyLauncher (AHK v2)

这是一个基于 AutoHotkey v2 编写的轻量级应用程序启动器。它允许用户通过快捷键呼出一个搜索框，**快速启动应用程序**或**进行网络搜索**。


## 目录结构

```text
├── Main.ahk               # 主程序入口
├── README.md              # 说明文档
├── Config/                # 配置文件目录
│   ├── keymap.json        # 热键配置
│   ├── apps.json          # 应用程序列表
│   ├── settings.json      # 全局设置（如窗口宽度、搜索引擎）
│
├── Core/                  # 核心逻辑库
│   ├── HotkeyManager.ahk  # 负责注册和管理全局热键
│   ├── SearchWindow.ahk   # 搜索框 UI 及搜索匹配逻辑
│   ├── AppLauncher.ahk    # 执行启动程序或打开网页的逻辑
│   ├── PluginLoader.ahk   # 插件加载器
│   └── JXON.ahk           # JSON 解析工具类
│
└── Plugins/               # 插件目录
    └── search_web.ahk     # 示例插件
```
## 配置文件说明

### Config/apps.json
定义可启动的应用程序。
```json
[
    {
        "name": "Notepad",
        "path": "notepad.exe",
        "keywords": ["np", "note", "txt"]
    }
]
```

### Config/keymap.json
定义全局快捷键。
```json
{
    "toggle_launcher": "!Space",  // Alt + Space
    "reload": "^!r"               // Ctrl + Alt + R (重载脚本)
}
```

### Config/settings.json
全局设置。
```json
{
    "width": 600,
    "search_engine": "https://www.google.com/search?q="
}
```
## 特别感谢
本项目的JSON解析库使用的是`TheArkive`所开发![仓库链接](https://github.com/TheArkive/JXON_ahk2)
