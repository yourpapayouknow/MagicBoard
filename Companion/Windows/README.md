# MagicBoard Windows 被控端伴侣服务 (Windows Companion Service)

MagicBoard Windows 伴侣服务是运行在被控 Windows 主机上的轻量级守护程序。它接收来自 iPad 键盘端发送的 MBCP 二进制 UDP 报文，并使用 Windows 官方推荐的 `SendInput` API 将击键与修饰键注入 Windows 系统键盘事件队列。

---

## 🌟 核心特性

- **双实现方案**：
  - **原生单文件版 (`magicboard-companion-win.exe`)**：纯 C 语言编写，编译后仅约 50KB，绿色免安装，启动极速，无任何运行时依赖。
  - **Python 备用版 (`magicboard_companion.py`)**：基于标准库 `ctypes` 调用 Windows `user32.dll`，无需 `pip install` 任何第三方包。
- **协议标准**：MBCP v1（固定 16 字节大端对齐二进制 UDP 报文）。
- **完整按键映射**：支持国际标准 USB HID Usage (Page 0x07) 到 Windows Virtual-Key 与硬件扫描码（通过 `MapVirtualKeyW` 生成），完美兼容桌面软件、终端、浏览器及大部分游戏。
- **UIPI 提权突破**：自动检测当前进程完整性级别（Integrity Level），提供 `--elevate` 参数一键触发 Windows UAC 提权重启，突破 UIPI 隔离，允许向任务管理器与管理员终端注入按键。
- **防卡键安全看门狗**：内置 1.5 秒断网检测看门狗线程。若 iPad 端网络中断或异常退出导致按键处于按下状态，1.5 秒内自动安全释放所有按键。
- **Pulse 单包脉冲**：支持单包脉冲按键（KeyDown + 延时 + KeyUp），高频输入更稳定。
- **防火墙一键放行**：内置放行指引，支持 `--add-firewall` 一键创建入站 UDP 规则。

---

## 🚀 快速开始

### 方式一：运行 C 原生可执行文件（推荐）

#### 1. 编译
在 Windows 终端（PowerShell 7）中执行：
```powershell
pwsh -File build-win.ps1
```
或直接使用 MinGW-W64 GCC：
```powershell
gcc -O2 -Wall -o magicboard-companion-win.exe magicboard-companion-win.c -lws2_32 -luser32 -lshell32
```

#### 2. 启动服务
```powershell
# 推荐：以管理员权限启动以突破 UIPI 隔离
.\magicboard-companion-win.exe --elevate

# 指定自定义端口 (默认 52088)
.\magicboard-companion-win.exe -p 52088
```

---

### 方式二：运行 Python 3 备用脚本

无需安装任何第三方库（仅使用 Python 3 标准库）：
```powershell
# 启动伴侣服务
python magicboard_companion.py

# 自动请求 UAC 管理员提权
python magicboard_companion.py --elevate
```

---

## 🛡️ 防火墙放行设置

若 iPad 与 Windows 处于同一局域网但无法连通，通常是 Windows Defender 防火墙拦截了 UDP 入站流量。

### 一键放行指令
在**管理员权限**的 PowerShell 中执行：
```powershell
New-NetFirewallRule -DisplayName "MagicBoard Companion" -Direction Inbound -LocalPort 52088 -Protocol UDP -Action Allow
```
或者直接使用伴侣自带参数自动添加：
```powershell
.\magicboard-companion-win.exe --add-firewall
# 或
python magicboard_companion.py --add-firewall
```

---

## 🧪 自动化测试

运行伴侣测试套件：
```powershell
# 1. 运行协议与映射单元测试
python test_companion_win.py --unit-tests

# 2. 对正在运行的伴侣服务进行实测 (测试 Win、Alt、Ctrl、Esc、Tab、F1~F12、看门狗等)
python test_companion_win.py --live --host 127.0.0.1 --port 52088
```

---

## ⚙️ 命令行参数说明

| 参数 | 缩写 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `--port <port>` | `-p` | `52088` | 指定 UDP 监听端口 |
| `--elevate` | `-e` | - | 若当前非管理员，自动弹出 UAC 提权并以管理员运行 |
| `--add-firewall` | - | - | 自动向 Windows 防火墙添加入站放行规则并退出 |
| `--mock` | - | - | (仅 Python 版) 启用模拟测试模式（不实际注入系统键鼠） |
| `--help` | `-h` | - | 显示帮助信息 |
